package com.karuna.service;

import java.util.Optional;
import java.util.List;
import com.karuna.entity.enums.VolunteerStatus;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.dto.CaseAssignmentDTO;
import com.karuna.dto.CaseStatusChangeDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.domain.RescueCaseDto;
import com.karuna.entity.Animal;
import com.karuna.entity.Location;
import com.karuna.entity.NGO;
import com.karuna.entity.RescueCase;
import com.karuna.entity.User;
import com.karuna.entity.Volunteer;
import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.enums.PriorityLevel;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.mapper.RescueCaseMapper;
import com.karuna.repository.AnimalRepository;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.LocationRepository;
import com.karuna.repository.NGORepository;
import com.karuna.repository.VolunteerRepository;
import com.karuna.repository.specification.RescueCaseSpecification;
import com.karuna.repository.mongo.ApplicationLogRepository;
import com.karuna.repository.mongo.TriageFeedbackRepository;
import com.karuna.document.ApplicationLog;
import com.karuna.document.TriageFeedback;

@Service
public class RescueCaseService {

	private final CaseRepository caseRepository;
	private final RescueCaseMapper rescueCaseMapper;
	private final AnimalRepository animalRepository;
	private final NGORepository ngoRepository;
	private final VolunteerRepository volunteerRepository;
	private final LocationRepository locationRepository;
	private final ApplicationLogRepository applicationLogRepository;
	private final TriageFeedbackRepository triageFeedbackRepository;
	private final RealtimeBroadcaster realtimeBroadcaster;

	public RescueCaseService(CaseRepository caseRepository,
							 RescueCaseMapper rescueCaseMapper,
							 AnimalRepository animalRepository,
							 NGORepository ngoRepository,
							 VolunteerRepository volunteerRepository,
							 LocationRepository locationRepository,
							 ApplicationLogRepository applicationLogRepository,
							 TriageFeedbackRepository triageFeedbackRepository,
							 RealtimeBroadcaster realtimeBroadcaster) {
		this.caseRepository = caseRepository;
		this.rescueCaseMapper = rescueCaseMapper;
		this.animalRepository = animalRepository;
		this.ngoRepository = ngoRepository;
		this.volunteerRepository = volunteerRepository;
		this.locationRepository = locationRepository;
		this.applicationLogRepository = applicationLogRepository;
		this.triageFeedbackRepository = triageFeedbackRepository;
		this.realtimeBroadcaster = realtimeBroadcaster;
	}

	@Transactional
	public RescueCaseDto.Response create(RescueCaseDto.Request request, User reporter) {
		RescueCase entity = rescueCaseMapper.toEntity(request);
		entity.setReporter(reporter);
		applyAssociations(entity, request.animalId(), request.ngoId(), request.primaryVolunteerId(), request.locationId());
		if (entity.getCaseStatus() == null || entity.getCaseStatus() == CaseStatus.REPORTED) {
			entity.setCaseStatus(CaseStatus.REPORTED);
			// Trigger matching engine to auto-dispatch the case
			autoDispatch(entity);
		}
		
		RescueCaseDto.Response response = rescueCaseMapper.toResponse(caseRepository.save(entity));
		
		// Broadcast new case creation over WebSockets
		try {
			realtimeBroadcaster.broadcast("CASE_CREATED", response.id(), response);
		} catch (Exception wsEx) {
			System.err.println("Failed to broadcast CASE_CREATED: " + wsEx.getMessage());
		}

		// Log case creation to MongoDB
		try {
			ApplicationLog log = new ApplicationLog();
			log.setLevel("INFO");
			log.setLoggerName("RescueCaseService");
			log.setMessage("Created rescue case with title: " + entity.getTitle() + ", status: " + entity.getCaseStatus());
			log.setCreatedAt(java.time.LocalDateTime.now());
			applicationLogRepository.save(log);
		} catch (Exception ex) {
			System.err.println("Failed to log case creation to MongoDB: " + ex.getMessage());
		}

		logTriageFeedback(entity);
		return response;
	}

	@Transactional(readOnly = true)
	public RescueCaseDto.Response get(Long id) {
		return rescueCaseMapper.toResponse(findOrThrow(id));
	}

	@Transactional(readOnly = true)
	public Page<RescueCaseDto.Response> list(
			CaseStatus status,
			PriorityLevel priority,
			Long reporterId,
			Long ngoId,
			Long volunteerId,
			String search,
			Pageable pageable) {
		var specification = RescueCaseSpecification.withFilters(status, priority, reporterId, ngoId, volunteerId, search);
		return caseRepository.findAll(specification, pageable).map(rescueCaseMapper::toResponse);
	}

	@Transactional
	public RescueCaseDto.Response update(Long id, RescueCaseDto.Update request) {
		RescueCase entity = findOrThrow(id);
		rescueCaseMapper.updateEntity(request, entity);
		if (request.ngoId() != null) {
			entity.setNgo(resolveNgo(request.ngoId()));
		}
		if (request.primaryVolunteerId() != null) {
			entity.setPrimaryVolunteer(resolveVolunteer(request.primaryVolunteerId()));
		}
		if (request.locationId() != null) {
			entity.setGeoLocation(resolveLocation(request.locationId()));
		}
		if (request.active() != null) {
			entity.setActive(request.active());
		}
		
		RescueCaseDto.Response response = rescueCaseMapper.toResponse(caseRepository.save(entity));
		
		// Broadcast update
		try {
			realtimeBroadcaster.broadcast("CASE_UPDATED", response.id(), response);
		} catch (Exception wsEx) {
			System.err.println("Failed to broadcast CASE_UPDATED: " + wsEx.getMessage());
		}

		logTriageFeedback(entity);
		return response;
	}

	@Transactional
	public MessageResponseDTO delete(Long id) {
		caseRepository.delete(findOrThrow(id));
		return new MessageResponseDTO("Rescue case deleted successfully");
	}

	@Transactional
	public RescueCaseDto.Response assign(Long id, CaseAssignmentDTO request) {
		RescueCase entity = findOrThrow(id);
		if (request.getNgoId() != null) {
			entity.setNgo(resolveNgo(request.getNgoId()));
		}
		if (request.getPrimaryVolunteerId() != null) {
			Volunteer volunteer = resolveVolunteer(request.getPrimaryVolunteerId());
			entity.setPrimaryVolunteer(volunteer);
			entity.getAssignedVolunteers().add(volunteer);
		}
		
		RescueCaseDto.Response response = rescueCaseMapper.toResponse(caseRepository.save(entity));
		
		// Broadcast assignment update
		try {
			realtimeBroadcaster.broadcast("CASE_UPDATED", response.id(), response);
		} catch (Exception wsEx) {
			System.err.println("Failed to broadcast CASE_UPDATED on assign: " + wsEx.getMessage());
		}

		return response;
	}

	@Transactional
	public RescueCaseDto.Response changeStatus(Long id, CaseStatusChangeDTO request) {
		RescueCase entity = findOrThrow(id);
		CaseStatus oldStatus = entity.getCaseStatus();
		RescueCaseStatusMachine.validate(oldStatus, request.getStatus());
		entity.setCaseStatus(request.getStatus());
		
		RescueCaseDto.Response response = rescueCaseMapper.toResponse(caseRepository.save(entity));
		
		// Broadcast status change update
		try {
			realtimeBroadcaster.broadcast("CASE_UPDATED", response.id(), response);
		} catch (Exception wsEx) {
			System.err.println("Failed to broadcast CASE_UPDATED on changeStatus: " + wsEx.getMessage());
		}

		// Log status transition to MongoDB
		try {
			ApplicationLog log = new ApplicationLog();
			log.setLevel("INFO");
			log.setLoggerName("RescueCaseService");
			log.setMessage("Updated rescue case status from " + oldStatus + " to " + request.getStatus());
			log.setCreatedAt(java.time.LocalDateTime.now());
			applicationLogRepository.save(log);
		} catch (Exception ex) {
			System.err.println("Failed to log status update to MongoDB: " + ex.getMessage());
		}

		return response;
	}

	private RescueCase findOrThrow(Long id) {
		return caseRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Rescue case not found with id " + id));
	}

	private void applyAssociations(RescueCase entity, Long animalId, Long ngoId, Long volunteerId, Long locationId) {
		if (animalId != null) {
			entity.setAnimal(resolveAnimal(animalId));
		}
		if (ngoId != null) {
			entity.setNgo(resolveNgo(ngoId));
		}
		if (volunteerId != null) {
			entity.setPrimaryVolunteer(resolveVolunteer(volunteerId));
		}
		if (locationId != null) {
			entity.setGeoLocation(resolveLocation(locationId));
		}
	}

	private Animal resolveAnimal(Long id) {
		return animalRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Animal not found with id " + id));
	}

	private NGO resolveNgo(Long id) {
		return ngoRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("NGO not found with id " + id));
	}

	private Volunteer resolveVolunteer(Long id) {
		return volunteerRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Volunteer not found with id " + id));
	}

	private Location resolveLocation(Long id) {
		return locationRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Location not found with id " + id));
	}

	private void autoDispatch(RescueCase entity) {
		if (entity.getLatitude() == null || entity.getLongitude() == null) {
			return; // No GPS, cannot auto-match
		}

		List<Volunteer> availableVolunteers = volunteerRepository.findByStatus(VolunteerStatus.AVAILABLE);
		if (availableVolunteers.isEmpty()) {
			return; // No available volunteers
		}

		Volunteer bestVolunteer = null;
		double bestScore = -1.0;

		for (Volunteer v : availableVolunteers) {
			if (v.getServiceLocation() == null ||
				v.getServiceLocation().getLatitude() == null ||
				v.getServiceLocation().getLongitude() == null) {
				continue;
			}

			// 1. Calculate distance in km (Haversine Formula)
			double vLat = v.getServiceLocation().getLatitude().doubleValue();
			double vLon = v.getServiceLocation().getLongitude().doubleValue();
			double cLat = entity.getLatitude();
			double cLon = entity.getLongitude();

			double distance = haversine(cLat, cLon, vLat, vLon);

			// Don't dispatch if volunteer is too far (e.g. > 50km)
			if (distance > 50.0) {
				continue;
			}

			// 2. Active caseload load penalty
			int activeCases = (v.getPrimaryCases() != null ? v.getPrimaryCases().size() : 0) +
							  (v.getAssignedCases() != null ? v.getAssignedCases().size() : 0);

			// 3. Compute match score
			// Score formula: 100 / (1 + distance) + 20 / (1 + activeCases)
			// Higher score is better. Closer is better, lower caseload is better.
			double score = (100.0 / (1.0 + distance)) + (20.0 / (1.0 + activeCases));

			// 4. Skills bias (bonus)
			// If priority is critical/high and volunteer has medical/vet/advanced skills
			if (entity.getPriority() == PriorityLevel.CRITICAL || entity.getPriority() == PriorityLevel.HIGH) {
				String skills = v.getSkills() != null ? v.getSkills().toLowerCase() : "";
				if (skills.contains("advanced") || skills.contains("vet") || skills.contains("medical") || skills.contains("first aid")) {
					score += 15.0; // Skills bonus
				}
			}

			if (score > bestScore) {
				bestScore = score;
				bestVolunteer = v;
			}
		}

		if (bestVolunteer != null) {
			entity.setPrimaryVolunteer(bestVolunteer);
			entity.setCaseStatus(CaseStatus.ASSIGNED);
			entity.getAssignedVolunteers().add(bestVolunteer);
			
			// Auto-associate with the volunteer's first NGO if any
			if (!bestVolunteer.getNgos().isEmpty()) {
				entity.setNgo(bestVolunteer.getNgos().iterator().next());
			}
		}
	}

	private double haversine(double lat1, double lon1, double lat2, double lon2) {
		double R = 6371; // Earth's radius in km
		double dLat = Math.toRadians(lat2 - lat1);
		double dLon = Math.toRadians(lon2 - lon1);
		double a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
		           Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2)) *
		           Math.sin(dLon / 2) * Math.sin(dLon / 2);
		double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
		return R * c;
	}

	private void logTriageFeedback(RescueCase entity) {
		try {
			if (entity.getPriority() != null && entity.getSpecies() != null) {
				TriageFeedback feedback = new TriageFeedback();
				feedback.setCaseId(entity.getId());
				feedback.setSpecies(entity.getSpecies());
				feedback.setInjury(entity.getInjuryType() != null ? entity.getInjuryType() : "injury");
				feedback.setDesc(entity.getDescription() != null ? entity.getDescription() : "");
				
				// Map priority level to severity string
				String severity = "routine";
				if (entity.getPriority() == PriorityLevel.CRITICAL) {
					severity = "critical";
				} else if (entity.getPriority() == PriorityLevel.HIGH || entity.getPriority() == PriorityLevel.URGENT) {
					severity = "urgent";
				}
				feedback.setSeverity(severity);
				feedback.setCreatedAt(java.time.LocalDateTime.now());
				
				triageFeedbackRepository.save(feedback);
			}
		} catch (Exception ex) {
			System.err.println("Could not save triage feedback to MongoDB: " + ex.getMessage());
		}
	}
}
