package com.karuna.controller;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.karuna.dto.CaseAssignmentDTO;
import com.karuna.dto.CaseStatusChangeDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.domain.RescueCaseDto;
import com.karuna.entity.User;
import com.karuna.entity.Volunteer;
import com.karuna.entity.RescueCase;
import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.enums.PriorityLevel;
import com.karuna.repository.UserRepository;
import com.karuna.repository.VolunteerRepository;
import com.karuna.repository.CaseRepository;
import com.karuna.security.auth.SecurityUtils;
import com.karuna.service.RescueCaseService;
import com.karuna.service.VolunteerService;
import com.karuna.mapper.RescueCaseMapper;
import com.karuna.exception.ResourceNotFoundException;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/cases")
@Tag(name = "Rescue Cases", description = "Rescue case management, search, assignment, and status workflow")
public class RescueCaseController {

	private final RescueCaseService rescueCaseService;
	private final UserRepository userRepository;
	private final VolunteerRepository volunteerRepository;
	private final CaseRepository caseRepository;
	private final VolunteerService volunteerService;
	private final RescueCaseMapper rescueCaseMapper;

	public RescueCaseController(RescueCaseService rescueCaseService,
								UserRepository userRepository,
								VolunteerRepository volunteerRepository,
								CaseRepository caseRepository,
								VolunteerService volunteerService,
								RescueCaseMapper rescueCaseMapper) {
		this.rescueCaseService = rescueCaseService;
		this.userRepository = userRepository;
		this.volunteerRepository = volunteerRepository;
		this.caseRepository = caseRepository;
		this.volunteerService = volunteerService;
		this.rescueCaseMapper = rescueCaseMapper;
	}

	@PostMapping
	@Operation(summary = "Create a new rescue case")
	public ResponseEntity<RescueCaseDto.Response> create(@Valid @RequestBody RescueCaseDto.Request request) {
		User reporter = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(rescueCaseService.create(request, reporter));
	}

	@GetMapping
	@Operation(summary = "List rescue cases with filtering, pagination, and sorting")
	public ResponseEntity<Page<RescueCaseDto.Response>> list(
			@RequestParam(required = false) CaseStatus status,
			@RequestParam(required = false) PriorityLevel priority,
			@RequestParam(required = false) Long reporterId,
			@RequestParam(required = false) Long ngoId,
			@RequestParam(required = false) Long volunteerId,
			@RequestParam(required = false) String search,
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(
				rescueCaseService.list(status, priority, reporterId, ngoId, volunteerId, search, pageable));
	}

	@GetMapping("/{id}")
	@Operation(summary = "Get a rescue case by id")
	public ResponseEntity<RescueCaseDto.Response> get(@PathVariable Long id) {
		return ResponseEntity.ok(rescueCaseService.get(id));
	}

	@PutMapping("/{id}")
	@Operation(summary = "Update a rescue case")
	public ResponseEntity<RescueCaseDto.Response> update(
			@PathVariable Long id,
			@Valid @RequestBody RescueCaseDto.Update request) {
		return ResponseEntity.ok(rescueCaseService.update(id, request));
	}

	@PatchMapping("/{id}")
	@Operation(summary = "Partially update a rescue case")
	public ResponseEntity<RescueCaseDto.Response> partialUpdate(
			@PathVariable Long id,
			@Valid @RequestBody RescueCaseDto.Update request) {
		return ResponseEntity.ok(rescueCaseService.update(id, request));
	}

	@DeleteMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO','VET')")
	@Operation(summary = "Soft-delete a rescue case")
	public ResponseEntity<MessageResponseDTO> delete(@PathVariable Long id) {
		return ResponseEntity.ok(rescueCaseService.delete(id));
	}

	@PostMapping("/{id}/assign")
	@PreAuthorize("hasAnyRole('ADMIN','NGO','VET')")
	@Operation(summary = "Assign an NGO and/or primary volunteer to a rescue case")
	public ResponseEntity<RescueCaseDto.Response> assign(
			@PathVariable Long id,
			@Valid @RequestBody CaseAssignmentDTO request) {
		return ResponseEntity.ok(rescueCaseService.assign(id, request));
	}

	@PostMapping("/{id}/status")
	@Operation(summary = "Transition a rescue case to a new status")
	public ResponseEntity<RescueCaseDto.Response> changeStatus(
			@PathVariable Long id,
			@Valid @RequestBody CaseStatusChangeDTO request) {
		return ResponseEntity.ok(rescueCaseService.changeStatus(id, request));
	}

	@PutMapping("/{id}/status")
	@Operation(summary = "Transition a rescue case to a new status via PUT (Flutter compatibility)")
	public ResponseEntity<RescueCaseDto.Response> changeStatusPut(
			@PathVariable Long id,
			@Valid @RequestBody CaseStatusChangeDTO request) {
		return ResponseEntity.ok(rescueCaseService.changeStatus(id, request));
	}

	@PostMapping("/{id}/accept")
	@PreAuthorize("hasAnyRole('ADMIN','VOLUNTEER')")
	@Operation(summary = "Accept an open rescue case for the currently logged-in volunteer")
	public ResponseEntity<RescueCaseDto.Response> accept(@PathVariable Long id) {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		Volunteer volunteer = volunteerRepository.findByUserId(currentUser.getId())
				.orElseThrow(() -> new ResourceNotFoundException("Volunteer profile not found for user: " + currentUser.getId()));
		volunteerService.assignCase(volunteer.getId(), id);
		
		RescueCase rescueCase = caseRepository.findById(id)
				.orElseThrow(() -> new ResourceNotFoundException("Rescue case not found: " + id));
		if (rescueCase.getCaseStatus() == CaseStatus.REPORTED) {
			rescueCase.setCaseStatus(CaseStatus.ASSIGNED);
			caseRepository.save(rescueCase);
		}
		return ResponseEntity.ok(rescueCaseMapper.toResponse(rescueCase));
	}

	@PutMapping("/{id}/accept")
	@PreAuthorize("hasAnyRole('ADMIN','VOLUNTEER')")
	@Operation(summary = "Accept an open rescue case via PUT (Flutter compatibility)")
	public ResponseEntity<RescueCaseDto.Response> acceptPut(@PathVariable Long id) {
		return accept(id);
	}

	@GetMapping("/my")
	@Operation(summary = "Get cases reported by the currently logged-in user")
	public ResponseEntity<Page<RescueCaseDto.Response>> myCases(
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		User reporter = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(
				rescueCaseService.list(null, null, reporter.getId(), null, null, null, pageable));
	}

	@GetMapping("/open")
	@Operation(summary = "Get all open (REPORTED status) cases")
	public ResponseEntity<Page<RescueCaseDto.Response>> openCases(
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(
				rescueCaseService.list(com.karuna.entity.enums.CaseStatus.REPORTED, null, null, null, null, null, pageable));
	}
}
