package com.karuna.service;

import java.time.Instant;
import java.time.LocalDateTime;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicLong;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.karuna.entity.RescueCase;
import com.karuna.exception.BusinessException;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.repository.CaseRepository;

import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;

@Service
public class KarunaMemoryStore {

	private static final List<String> STATUS_FLOW = List.of("reported", "assigned", "collected", "at_clinic", "in_treatment", "discharged");

	private final AtomicLong caseIds = new AtomicLong(1000);
	private final AtomicLong donationIds = new AtomicLong(5000);
	private final AtomicLong adoptionIds = new AtomicLong(7000);
	private final Map<Long, CaseRecord> cases = new ConcurrentHashMap<>();
	private final RealtimeBroadcaster broadcaster;
    private final CaseRepository caseRepository;
    private final ObjectMapper objectMapper;

	public KarunaMemoryStore(RealtimeBroadcaster broadcaster, CaseRepository caseRepository, ObjectMapper objectMapper) {
		this.broadcaster = broadcaster;
		this.caseRepository = caseRepository;
		this.objectMapper = objectMapper;
	}

	@PostConstruct
	public void seed() {
		if (!cases.isEmpty()) {
			return;
		}

		loadPersistedCases();
		if (!cases.isEmpty()) {
			return;
		}

		CaseRecord one = createSeedCase("Asha", "asha@example.com", "9876543210",
				"https://images.unsplash.com/photo-1517841905240-472988babdf9?w=800",
				"Vijayawada market road", 16.5062, 80.6480, "dog", "wound", "critical",
				"Deep leg wound with heavy bleeding",
				List.of("Keep the animal calm and away from traffic", "Apply gentle pressure with a clean cloth", "Move to veterinary care immediately"),
				"reported", null, "Karuna Volunteers", 5000);

		CaseRecord two = createSeedCase("Rahul", "rahul@example.com", "9123456780",
				"https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=800",
				"Guntur bus stand", 16.3067, 80.4365, "cat", "fracture", "urgent",
				"Front paw injury and dehydration",
				List.of("Offer water if the animal can swallow", "Stabilize the limb without forcing movement", "Transport carefully for X-ray"),
				"assigned", "Anita", "PawCare NGO", 3200);

		CaseRecord three = createSeedCase("Meera", "meera@example.com", "9988776655",
				"https://images.unsplash.com/photo-1450778869180-41d0601e046e?w=800",
				"Nellore river side", 14.4426, 79.9865, "cow", "weakness", "routine",
				"Recovered and awaiting adoption",
				List.of("Monitor appetite", "Keep in a shaded area", "Share post-treatment updates"),
				"discharged", "Sanjay", "Green Hope Trust", 1800);

		addDonationInternal(one, "Priya", 1200, "Stay strong", "UPI", "Covers wound dressing kit");
		addDonationInternal(two, "Nikhil", 800, "For transport", "Card", "Supports emergency transit");
		addAdoptionInternal(three, "Anu", "anu@example.com", "I can care for a rescued cow on my farm.", null);
		persistAllCases();
	}

	public List<Map<String, Object>> listCases() {
		return cases.values().stream()
				.sorted(Comparator.comparing(CaseRecord::getCreatedAt).reversed())
				.map(this::toView)
				.toList();
	}

	public List<Map<String, Object>> listOpenCases() {
		return listCases().stream()
				.filter(caseView -> {
					String status = String.valueOf(caseView.get("status"));
					return !List.of("adopted", "released").contains(status);
				})
				.toList();
	}

	public List<Map<String, Object>> listMyCases(String email, String role, String name) {
		if (email == null && name == null) {
			return List.of();
		}
		String normalizedRole = role == null ? "" : role.toUpperCase();
		return listCases().stream()
				.filter(caseView -> {
					String reporterEmail = Optional.ofNullable(caseView.get("reporterEmail")).map(Object::toString).orElse("");
					String reporterName = Optional.ofNullable(caseView.get("reporterName")).map(Object::toString).orElse("");
					String assignedResponder = Optional.ofNullable(caseView.get("assignedResponder")).map(Object::toString).orElse("");
					String ngo = Optional.ofNullable(caseView.get("ngo")).map(Object::toString).orElse("");
					if ("CITIZEN".equals(normalizedRole)) {
						return (email != null && email.equalsIgnoreCase(reporterEmail)) || (name != null && name.equalsIgnoreCase(reporterName));
					}
					if ("NGO".equals(normalizedRole) || "VET".equals(normalizedRole) || "VOLUNTEER".equals(normalizedRole)) {
						return name != null && (name.equalsIgnoreCase(assignedResponder) || name.equalsIgnoreCase(ngo));
					}
					return false;
				})
				.toList();
	}

	public Map<String, Object> getCase(long id) {
		return toView(requireCase(id));
	}

	public Map<String, Object> createCase(String reporterName, String reporterEmail, String reporterContact, Map<String, Object> body) {
		CaseRecord record = new CaseRecord();
		record.id = caseIds.incrementAndGet();
		record.createdAt = Instant.now();
		record.updatedAt = record.createdAt;
		record.reporterName = firstNonBlank(reporterName, asString(body.get("reporterName")), "Anonymous Citizen");
		record.reporterEmail = firstNonBlank(reporterEmail, asString(body.get("reporterEmail")));
		record.reporterContact = firstNonBlank(reporterContact, asString(body.get("reporterContact")));
		record.imageDataUrl = firstNonBlank(asString(body.get("imageDataUrl")), asString(body.get("image")), "");
		record.locationLabel = firstNonBlank(asString(body.get("locationLabel")), extractLocationLabel(body.get("location")), asString(body.get("location")), "Unknown location");
		record.latitude = asDouble(body.get("latitude"));
		record.longitude = asDouble(body.get("longitude"));
		record.species = firstNonBlank(asString(body.get("species")), "unknown");
		record.injuryType = firstNonBlank(asString(body.get("injuryType")), "unknown");
		record.severity = normalizeSeverity(firstNonBlank(asString(body.get("severity")), "routine"));
		record.probableCondition = firstNonBlank(asString(body.get("probableCondition")), asString(body.get("description")), "Injured animal reported");
		record.firstAidSteps = parseStringList(body.get("firstAidSteps"));
		record.status = "reported";
		record.assignedResponder = asString(body.get("assignedResponder"));
		record.ngo = asString(body.get("ngo"));
		record.estimatedCostInr = asInt(body.get("estimatedCostInr"), 1500);
		record.events.add(new CaseEvent(Instant.now(), "created", record.reporterName, "Case opened"));
		cases.put(record.id, record);
		persistCase(record);
		broadcaster.broadcast("case.created", record.id, toView(record));
		return toView(record);
	}

	public Map<String, Object> assignCase(long caseId, String responder, String ngo) {
		CaseRecord record = requireCase(caseId);
		record.status = "assigned";
		record.assignedResponder = firstNonBlank(responder, record.assignedResponder, "Unassigned responder");
		record.ngo = firstNonBlank(ngo, record.ngo, "Karuna Volunteers");
		record.updatedAt = Instant.now();
		record.events.add(new CaseEvent(Instant.now(), "assigned", record.ngo, "Dispatched to " + record.assignedResponder));
		persistCase(record);
		broadcaster.broadcast("case.assigned", record.id, toView(record));
		return toView(record);
	}

	public Map<String, Object> advanceStatus(long caseId, String to, String actor, String note) {
		CaseRecord record = requireCase(caseId);
		String next = normalizeStatus(to, record.status);
		record.status = next;
		record.updatedAt = Instant.now();
		record.events.add(new CaseEvent(Instant.now(), "status", firstNonBlank(actor, "NGO"), note == null || note.isBlank() ? "→ " + next : "→ " + next + " (" + note + ")"));
		if (note != null && !note.isBlank()) {
			record.notes.add(note);
		}
		persistCase(record);
		broadcaster.broadcast("case.status", record.id, toView(record));
		return toView(record);
	}

	public Map<String, Object> addNote(long caseId, String actor, String note) {
		if (note == null || note.isBlank()) {
			throw new BusinessException("Note cannot be blank");
		}
		CaseRecord record = requireCase(caseId);
		String cleanNote = note.trim();
		record.notes.add(cleanNote);
		record.updatedAt = Instant.now();
		record.events.add(new CaseEvent(Instant.now(), "note", firstNonBlank(actor, "NGO"), cleanNote));
		persistCase(record);
		broadcaster.broadcast("case.note", record.id, toView(record));
		return toView(record);
	}

	public Map<String, Object> addDonation(long caseId, String donorName, int amountInr, String message, String paymentMethod, String billOffsetDetails) {
		CaseRecord record = requireCase(caseId);
		DonationRecord donation = addDonationInternal(record, donorName, amountInr, message, paymentMethod, billOffsetDetails);
		persistCase(record);
		broadcaster.broadcast("case.donation", record.id, toView(record));
		return toDonationView(donation);
	}

	public List<Map<String, Object>> listDonations() {
		List<Map<String, Object>> donations = new ArrayList<>();
		for (CaseRecord record : cases.values()) {
			donations.addAll(toDonationViews(record.donations));
		}
		return donations;
	}

	public List<Map<String, Object>> listDonationsForCase(long caseId) {
		return toDonationViews(requireCase(caseId).donations);
	}

	public List<Map<String, Object>> listAdoptionsForCase(long caseId) {
		return toAdoptionViews(requireCase(caseId).adoptionApplications);
	}

	public Map<String, Object> applyForAdoption(long caseId, String applicantName, String contact, String reason, String adopterIdUrl) {
		CaseRecord record = requireCase(caseId);
		AdoptionRecord application = addAdoptionInternal(record, applicantName, contact, reason, adopterIdUrl);
		record.updatedAt = Instant.now();
		persistCase(record);
		broadcaster.broadcast("case.adoption_application", record.id, toView(record));
		return toAdoptionView(application);
	}

	public Map<String, Object> decideAdoption(long adoptionId, String status) {
		AdoptionRecord application = findAdoption(adoptionId);
		application.status = normalizeAdoptionStatus(status);
		application.updatedAt = Instant.now();
		CaseRecord record = requireCase(application.caseId);
		record.updatedAt = Instant.now();
		if ("approved".equals(application.status)) {
			record.status = "adopted";
		}
		record.events.add(new CaseEvent(Instant.now(), "adoption_decision", application.applicantName, application.status));
		persistCase(record);
		broadcaster.broadcast("case.adoption_decision", record.id, toView(record));
		return toAdoptionView(application);
	}

	public Map<String, Object> addCheckin(long adoptionId, String text, String photoUrl) {
		AdoptionRecord application = findAdoption(adoptionId);
		String entry = text == null ? "" : text.trim();
		if (photoUrl != null && !photoUrl.isBlank()) {
			entry = entry.isBlank() ? photoUrl : entry + " | " + photoUrl;
		}
		if (!entry.isBlank()) {
			application.checkins.add(entry);
		}
		application.updatedAt = Instant.now();
		CaseRecord record = requireCase(application.caseId);
		record.updatedAt = Instant.now();
		record.events.add(new CaseEvent(Instant.now(), "note", application.applicantName, "Adoption check-in"));
		persistCase(record);
		broadcaster.broadcast("case.updated", record.id, toView(record));
		return toAdoptionView(application);
	}

	public Map<String, Object> triage(Map<String, Object> input) {
		String description = firstNonBlank(asString(input.get("description")), asString(input.get("probableCondition")), "animal reported in distress");
		String lower = description.toLowerCase();
		String severity = lower.contains("bleed") || lower.contains("fracture") || lower.contains("hit") || lower.contains("severe") ? "high"
				: lower.contains("limp") || lower.contains("wound") || lower.contains("injur") ? "medium"
				: "low";
		List<String> firstAidSteps = new ArrayList<>();
		firstAidSteps.add("Keep the animal calm and away from traffic");
		switch (severity) {
			case "high" -> {
				firstAidSteps.add("Apply pressure with a clean cloth if there is bleeding");
				firstAidSteps.add("Move to veterinary care immediately");
			}
			case "medium" -> {
				firstAidSteps.add("Avoid forcing the injured limb");
				firstAidSteps.add("Transport carefully for medical review");
			}
			default -> {
				firstAidSteps.add("Offer clean water if the animal can safely drink");
				firstAidSteps.add("Observe for changes until help arrives");
			}
		}
		Map<String, Object> result = new LinkedHashMap<>();
		result.put("animal", firstNonBlank(asString(input.get("species")), "animal"));
		result.put("isInjured", true);
		result.put("injurySeverity", severity);
		result.put("probableCondition", firstNonBlank(asString(input.get("description")), description));
		Map<String, Object> meds = new LinkedHashMap<>();
		meds.put("tablets", List.of());
		meds.put("ointments", List.of());
		result.put("recommendedMedicines", meds);
		result.put("firstAidSteps", firstAidSteps);
		result.put("nextSteps", List.of("Call the nearest NGO", "Share the case with the responder", "Track treatment progress"));
		result.put("disclaimer", "This triage is informational and not a substitute for veterinary diagnosis.");
		result.put("localSupport", List.of());
		result.put("severity", switch (severity) {
			case "high" -> "critical";
			case "medium" -> "urgent";
			default -> "routine";
		});
		return result;
	}

	public Map<String, Object> healthSnapshot() {
		Map<String, Object> health = new LinkedHashMap<>();
		health.put("ok", true);
		health.put("cases", cases.size());
		health.put("openCases", listOpenCases().size());
		return health;
	}

	private void loadPersistedCases() {
		for (RescueCase rescueCase : caseRepository.findAll()) {
			if (rescueCase.getPayloadJson() == null || rescueCase.getPayloadJson().isBlank()) {
				continue;
			}
			try {
				Map<String, Object> payload = objectMapper.readValue(rescueCase.getPayloadJson(), new TypeReference<Map<String, Object>>() {});
				CaseRecord record = fromView(payload);
				cases.put(record.id, record);
				caseIds.set(Math.max(caseIds.get(), record.id + 1));
				donationIds.set(Math.max(donationIds.get(), maxDonationId(record) + 1));
				adoptionIds.set(Math.max(adoptionIds.get(), maxAdoptionId(record) + 1));
			} catch (JsonProcessingException | IllegalArgumentException ignored) {
				// Skip malformed snapshots; the demo seed below will replenish data if needed.
			}
		}
	}

	private void persistAllCases() {
		for (CaseRecord record : cases.values()) {
			persistCase(record);
		}
	}

	private void persistCase(CaseRecord record) {
		try {
			RescueCase rescueCase = caseRepository.findById(record.id).orElseGet(RescueCase::new);
			rescueCase.setId(record.id);
			rescueCase.setTitle(record.probableCondition);
			rescueCase.setDescription(record.probableCondition);
			rescueCase.setStatus(record.status);
			rescueCase.setLocation(record.locationLabel);
			rescueCase.setAnimalType(record.species);
			rescueCase.setSeverity(record.severity);
			rescueCase.setPayloadJson(objectMapper.writeValueAsString(toView(record)));
			if (rescueCase.getCreatedAt() == null) {
				rescueCase.setCreatedAt(toLocalDateTime(record.createdAt));
			}
			rescueCase.setUpdatedAt(toLocalDateTime(record.updatedAt));
			caseRepository.save(rescueCase);
		} catch (JsonProcessingException ex) {
			throw new RuntimeException("Failed to persist case snapshot", ex);
		}
	}

	private LocalDateTime toLocalDateTime(Instant instant) {
		return LocalDateTime.ofInstant(instant == null ? Instant.now() : instant, ZoneOffset.UTC);
	}

	private long maxDonationId(CaseRecord record) {
		return record.donations.stream().mapToLong(donation -> donation.id).max().orElse(5000);
	}

	private long maxAdoptionId(CaseRecord record) {
		return record.adoptionApplications.stream().mapToLong(application -> application.id).max().orElse(7000);
	}

	private CaseRecord fromView(Map<String, Object> view) {
		CaseRecord record = new CaseRecord();
		record.id = asLong(view.get("id"), caseIds.getAndIncrement());
		record.createdAt = Instant.parse(asString(view.get("createdAt"), Instant.now().toString()));
		record.updatedAt = Instant.parse(asString(view.get("updatedAt"), record.createdAt.toString()));
		record.reporterName = asString(view.get("reporterName"), "Anonymous Citizen");
		record.reporterEmail = asString(view.get("reporterEmail"), null);
		record.reporterContact = asString(view.get("reporterContact"), null);
		record.imageDataUrl = asString(view.get("imageDataUrl"), "");
		record.locationLabel = asString(view.get("locationLabel"), "Unknown location");
		record.latitude = asDouble(view.get("location") instanceof Map<?, ?> location ? location.get("lat") : null);
		record.longitude = asDouble(view.get("location") instanceof Map<?, ?> location ? location.get("lon") : null);
		record.species = asString(view.get("species"), "unknown");
		record.injuryType = asString(view.get("injuryType"), "unknown");
		record.severity = asString(view.get("severity"), "routine");
		record.probableCondition = asString(view.get("probableCondition"), "Injured animal reported");
		record.firstAidSteps = toStringList(view.get("firstAidSteps"));
		record.status = asString(view.get("status"), "reported");
		record.assignedResponder = asString(view.get("assignedResponder"), null);
		record.ngo = asString(view.get("ngo"), null);
		record.estimatedCostInr = asInt(view.get("estimatedCostInr"), 1500);
		record.notes = toStringList(view.get("notes"));
		record.events = new ArrayList<>();
		Object eventsValue = view.get("events");
		if (eventsValue instanceof List<?> eventsList) {
			for (Object item : eventsList) {
				if (item instanceof Map<?, ?> eventMap) {
					record.events.add(new CaseEvent(
						Instant.parse(asString(eventMap.get("ts"), Instant.now().toString())),
						asString(eventMap.get("type"), "note"),
						asString(eventMap.get("actor"), "NGO"),
						asString(eventMap.get("details"), "")
					));
				}
			}
		}
		record.donations = new ArrayList<>();
		Object donationsValue = view.get("donations");
		if (donationsValue instanceof List<?> donationsList) {
			for (Object item : donationsList) {
				if (item instanceof Map<?, ?> donationMap) {
					DonationRecord donation = new DonationRecord();
					donation.id = asLong(donationMap.get("id"), donationIds.getAndIncrement());
					donation.ts = Instant.parse(asString(donationMap.get("ts"), Instant.now().toString()));
					donation.caseId = asLong(donationMap.get("caseId"), record.id);
					donation.donorName = asString(donationMap.get("donorName"), "Anonymous donor");
					donation.amountInr = asInt(donationMap.get("amountInr"), 1);
					donation.message = asString(donationMap.get("message"), null);
					donation.paymentMethod = asString(donationMap.get("paymentMethod"), null);
					donation.billOffsetDetails = asString(donationMap.get("billOffsetDetails"), null);
					record.donations.add(donation);
				}
			}
		}
		record.adoptionApplications = new ArrayList<>();
		Object adoptionsValue = view.get("adoptionApplications");
		if (adoptionsValue instanceof List<?> adoptionList) {
			for (Object item : adoptionList) {
				if (item instanceof Map<?, ?> adoptionMap) {
					AdoptionRecord adoption = new AdoptionRecord();
					adoption.id = asLong(adoptionMap.get("id"), adoptionIds.getAndIncrement());
					adoption.ts = Instant.parse(asString(adoptionMap.get("ts"), Instant.now().toString()));
					adoption.caseId = asLong(adoptionMap.get("caseId"), record.id);
					adoption.applicantName = asString(adoptionMap.get("applicantName"), "Adopter");
					adoption.contact = asString(adoptionMap.get("contact"), "");
					adoption.reason = asString(adoptionMap.get("reason"), "Interested in adoption");
					adoption.status = asString(adoptionMap.get("status"), "pending");
					adoption.adopterIdUrl = asString(adoptionMap.get("adopterIdUrl"), null);
					adoption.checkins = toStringList(adoptionMap.get("checkins"));
					adoption.updatedAt = Instant.parse(asString(adoptionMap.get("updatedAt"), adoption.ts.toString()));
					record.adoptionApplications.add(adoption);
				}
			}
		}
		return record;
	}

	private String asString(Object value, String fallback) {
		return value == null ? fallback : String.valueOf(value);
	}

	private long asLong(Object value, long fallback) {
		if (value instanceof Number number) {
			return number.longValue();
		}
		try {
			return value == null ? fallback : Long.parseLong(String.valueOf(value));
		} catch (NumberFormatException ex) {
			return fallback;
		}
	}

	private List<String> toStringList(Object value) {
		List<String> out = new ArrayList<>();
		if (value instanceof List<?> list) {
			for (Object item : list) {
				out.add(String.valueOf(item));
			}
		}
		return out;
	}

	private CaseRecord createSeedCase(String reporterName, String reporterEmail, String reporterContact, String imageDataUrl, String locationLabel, Double latitude, Double longitude, String species, String injuryType, String severity, String probableCondition, List<String> firstAidSteps, String status, String assignedResponder, String ngo, int estimatedCostInr) {
		CaseRecord record = new CaseRecord();
		record.id = caseIds.incrementAndGet();
		record.createdAt = Instant.now().minusSeconds((caseIds.get() - 1000) * 3600L);
		record.updatedAt = record.createdAt;
		record.reporterName = reporterName;
		record.reporterEmail = reporterEmail;
		record.reporterContact = reporterContact;
		record.imageDataUrl = imageDataUrl;
		record.locationLabel = locationLabel;
		record.latitude = latitude;
		record.longitude = longitude;
		record.species = species;
		record.injuryType = injuryType;
		record.severity = severity;
		record.probableCondition = probableCondition;
		record.firstAidSteps = new ArrayList<>(firstAidSteps);
		record.status = status;
		record.assignedResponder = assignedResponder;
		record.ngo = ngo;
		record.estimatedCostInr = estimatedCostInr;
		record.events.add(new CaseEvent(record.createdAt, "created", reporterName, "Demo case seeded"));
		cases.put(record.id, record);
		return record;
	}

	private DonationRecord addDonationInternal(CaseRecord record, String donorName, int amountInr, String message, String paymentMethod, String billOffsetDetails) {
		DonationRecord donation = new DonationRecord();
		donation.id = donationIds.incrementAndGet();
		donation.ts = Instant.now();
		donation.caseId = record.id;
		donation.donorName = firstNonBlank(donorName, "Anonymous donor");
		donation.amountInr = Math.max(1, amountInr);
		donation.message = message;
		donation.paymentMethod = paymentMethod;
		donation.billOffsetDetails = billOffsetDetails;
		record.donations.add(donation);
		record.events.add(new CaseEvent(Instant.now(), "donation", donation.donorName, "₹" + donation.amountInr + " donated"));
		record.updatedAt = Instant.now();
		return donation;
	}

	private AdoptionRecord addAdoptionInternal(CaseRecord record, String applicantName, String contact, String reason, String adopterIdUrl) {
		AdoptionRecord adoption = new AdoptionRecord();
		adoption.id = adoptionIds.incrementAndGet();
		adoption.ts = Instant.now();
		adoption.caseId = record.id;
		adoption.applicantName = firstNonBlank(applicantName, "Adopter");
		adoption.contact = firstNonBlank(contact, "");
		adoption.reason = firstNonBlank(reason, "Interested in adoption");
		adoption.status = "pending";
		adoption.adopterIdUrl = adopterIdUrl;
		record.adoptionApplications.add(adoption);
		record.events.add(new CaseEvent(Instant.now(), "adoption_application", adoption.applicantName, "Applied to adopt"));
		record.updatedAt = Instant.now();
		return adoption;
	}

	private CaseRecord requireCase(long id) {
		CaseRecord record = cases.get(id);
		if (record == null) {
			throw new ResourceNotFoundException("Case not found");
		}
		return record;
	}

	private AdoptionRecord findAdoption(long adoptionId) {
		return cases.values().stream()
				.flatMap(record -> record.adoptionApplications.stream())
				.filter(application -> application.id == adoptionId)
				.findFirst()
				.orElseThrow(() -> new ResourceNotFoundException("Adoption application not found"));
	}

	private Map<String, Object> toView(CaseRecord record) {
		Map<String, Object> view = new LinkedHashMap<>();
		view.put("id", record.id);
		view.put("createdAt", iso(record.createdAt));
		view.put("updatedAt", iso(record.updatedAt));
		view.put("reporterName", record.reporterName);
		view.put("reporterContact", record.reporterContact);
		view.put("reporterEmail", record.reporterEmail);
		view.put("imageDataUrl", record.imageDataUrl);
		view.put("locationLabel", record.locationLabel);
		Map<String, Object> location = new LinkedHashMap<>();
		location.put("label", record.locationLabel);
		location.put("lat", record.latitude);
		location.put("lon", record.longitude);
		view.put("location", location);
		view.put("species", record.species);
		view.put("injuryType", record.injuryType);
		view.put("severity", record.severity);
		view.put("probableCondition", record.probableCondition);
		view.put("firstAidSteps", new ArrayList<>(record.firstAidSteps));
		view.put("status", record.status);
		view.put("assignedResponder", record.assignedResponder);
		view.put("responderName", record.assignedResponder);
		view.put("ngo", record.ngo);
		view.put("estimatedCostInr", record.estimatedCostInr);
		view.put("donations", toDonationViews(record.donations));
		view.put("adoptionApplications", toAdoptionViews(record.adoptionApplications));
		view.put("adoptions", toAdoptionViews(record.adoptionApplications));
		view.put("events", record.events.stream().map(this::toEventView).toList());
		view.put("notes", new ArrayList<>(record.notes));
		return view;
	}

	private Map<String, Object> toDonationView(DonationRecord donation) {
		Map<String, Object> view = new LinkedHashMap<>();
		view.put("id", donation.id);
		view.put("ts", iso(donation.ts));
		view.put("caseId", donation.caseId);
		view.put("donorName", donation.donorName);
		view.put("amountInr", donation.amountInr);
		view.put("message", donation.message);
		view.put("paymentMethod", donation.paymentMethod);
		view.put("billOffsetDetails", donation.billOffsetDetails);
		return view;
	}

	private List<Map<String, Object>> toDonationViews(List<DonationRecord> donations) {
		return donations.stream().map(this::toDonationView).toList();
	}

	private Map<String, Object> toAdoptionView(AdoptionRecord adoption) {
		Map<String, Object> view = new LinkedHashMap<>();
		view.put("id", adoption.id);
		view.put("ts", iso(adoption.ts));
		view.put("updatedAt", iso(adoption.updatedAt));
		view.put("caseId", adoption.caseId);
		view.put("applicantName", adoption.applicantName);
		view.put("contact", adoption.contact);
		view.put("reason", adoption.reason);
		view.put("status", adoption.status);
		view.put("adopterIdUrl", adoption.adopterIdUrl);
		view.put("checkinsLogs", String.join("\n", adoption.checkins));
		view.put("checkins", new ArrayList<>(adoption.checkins));
		return view;
	}

	private List<Map<String, Object>> toAdoptionViews(List<AdoptionRecord> adoptions) {
		return adoptions.stream().map(this::toAdoptionView).toList();
	}

	private Map<String, Object> toEventView(CaseEvent event) {
		Map<String, Object> view = new LinkedHashMap<>();
		view.put("ts", iso(event.ts));
		view.put("type", event.type);
		view.put("actor", event.actor);
		view.put("details", event.details);
		return view;
	}

	private String normalizeSeverity(String severity) {
		String value = severity == null ? "routine" : severity.toLowerCase();
		if (!List.of("critical", "urgent", "routine").contains(value)) {
			return "routine";
		}
		return value;
	}

	private String normalizeStatus(String requested, String fallback) {
		String value = firstNonBlank(requested, fallback, "reported").toLowerCase();
		return STATUS_FLOW.contains(value) ? value : fallback;
	}

	private String normalizeAdoptionStatus(String status) {
		String value = firstNonBlank(status, "pending").toLowerCase();
		return List.of("pending", "approved", "rejected").contains(value) ? value : "pending";
	}

	private String iso(Instant instant) {
		return instant == null ? Instant.now().toString() : instant.toString();
	}

	private String firstNonBlank(String... values) {
		for (String value : values) {
			if (value != null && !value.isBlank()) {
				return value;
			}
		}
		return null;
	}

	private String asString(Object value) {
		return value == null ? null : String.valueOf(value);
	}

	private String extractLocationLabel(Object value) {
		if (value instanceof Map<?, ?> map) {
			Object label = map.get("label");
			if (label != null && !String.valueOf(label).isBlank()) {
				return String.valueOf(label);
			}
		}
		return null;
	}

	private int asInt(Object value, int fallback) {
		if (value == null) {
			return fallback;
		}
		if (value instanceof Number number) {
			return number.intValue();
		}
		try {
			return Integer.parseInt(String.valueOf(value));
		} catch (NumberFormatException ex) {
			return fallback;
		}
	}

	private Double asDouble(Object value) {
		if (value == null) {
			return null;
		}
		if (value instanceof Number number) {
			return number.doubleValue();
		}
		try {
			return Double.parseDouble(String.valueOf(value));
		} catch (NumberFormatException ex) {
			return null;
		}
	}

	private List<String> parseStringList(Object value) {
		if (value == null) {
			return new ArrayList<>();
		}
		if (value instanceof List<?> list) {
			return list.stream().map(String::valueOf).toList();
		}
		String text = String.valueOf(value).trim();
		if (text.isBlank()) {
			return new ArrayList<>();
		}
		if (text.startsWith("[") && text.endsWith("]")) {
			String trimmed = text.substring(1, text.length() - 1).trim();
			if (trimmed.isBlank()) {
				return new ArrayList<>();
			}
			String[] parts = trimmed.split(",");
			List<String> steps = new ArrayList<>();
			for (String part : parts) {
				String cleaned = part.trim();
				if (cleaned.startsWith("\"") && cleaned.endsWith("\"") && cleaned.length() > 1) {
					cleaned = cleaned.substring(1, cleaned.length() - 1);
				}
				if (!cleaned.isBlank()) {
					steps.add(cleaned);
				}
			}
			return steps;
		}
		return List.of(text);
	}

	private static final class CaseRecord {
		private long id;
		private Instant createdAt;
		private Instant updatedAt;
		private String reporterName;
		private String reporterEmail;
		private String reporterContact;
		private String imageDataUrl;
		private String locationLabel;
		private Double latitude;
		private Double longitude;
		private String species;
		private String injuryType;
		private String severity;
		private String probableCondition;
		private List<String> firstAidSteps = new ArrayList<>();
		private String status;
		private String assignedResponder;
		private String ngo;
		private int estimatedCostInr;
		private List<DonationRecord> donations = new ArrayList<>();
		private List<AdoptionRecord> adoptionApplications = new ArrayList<>();
		private List<CaseEvent> events = new ArrayList<>();
		private List<String> notes = new ArrayList<>();

		private Instant getCreatedAt() {
			return createdAt;
		}
	}

	private static final class DonationRecord {
		private long id;
		private Instant ts;
		private long caseId;
		private String donorName;
		private int amountInr;
		private String message;
		private String paymentMethod;
		private String billOffsetDetails;
	}

	private static final class AdoptionRecord {
		private long id;
		private Instant ts;
		private long caseId;
		private String applicantName;
		private String contact;
		private String reason;
		private String status;
		private String adopterIdUrl;
		private List<String> checkins = new ArrayList<>();
		private Instant updatedAt;
	}

	private static final class CaseEvent {
		private final Instant ts;
		private final String type;
		private final String actor;
		private final String details;

		private CaseEvent(Instant ts, String type, String actor, String details) {
			this.ts = ts;
			this.type = type;
			this.actor = actor;
			this.details = details;
		}
	}
}
