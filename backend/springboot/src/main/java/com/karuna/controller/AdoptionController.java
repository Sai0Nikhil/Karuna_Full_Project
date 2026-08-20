package com.karuna.controller;

import java.time.LocalDateTime;
import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.*;

import com.karuna.dto.AdoptionStatusChangeDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.domain.AdoptionApplicationDto;
import com.karuna.entity.User;
import com.karuna.entity.enums.AdoptionStatus;
import com.karuna.repository.UserRepository;
import com.karuna.repository.mongo.ChatLogRepository;
import com.karuna.document.ChatLog;
import com.karuna.security.auth.SecurityUtils;
import com.karuna.service.AdoptionService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/adoptions")
@Tag(name = "Adoptions", description = "Adoption application management, review workflow, and search")
public class AdoptionController {

	private final AdoptionService adoptionService;
	private final UserRepository userRepository;
	private final ChatLogRepository chatLogRepository;

	public AdoptionController(AdoptionService adoptionService,
							  UserRepository userRepository,
							  ChatLogRepository chatLogRepository) {
		this.adoptionService = adoptionService;
		this.userRepository = userRepository;
		this.chatLogRepository = chatLogRepository;
	}

	@PostMapping
	@Operation(summary = "Submit a new adoption application")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Adoption application details",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Request.class),
					examples = @ExampleObject(value = """
							{
							  "caseId": 5,
							  "animalId": 3,
							  "applicantId": 10,
							  "applicantName": "John Doe",
							  "contactEmail": "john@example.com",
							  "contactPhone": "+919999999999",
							  "reason": "I have a large yard and experience with dogs",
							  "adopterIdUrl": "https://example.com/id.pdf"
							}""")))
	@ApiResponse(responseCode = "200", description = "Application submitted",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Validation error or duplicate application",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "401", description = "Authentication required",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AdoptionApplicationDto.Response> create(@Valid @RequestBody AdoptionApplicationDto.Request request) {
		User applicant = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(adoptionService.create(request, applicant));
	}

	@GetMapping
	@Operation(summary = "List adoption applications with filtering, pagination, and sorting")
	@ApiResponse(responseCode = "200", description = "Paginated adoption applications",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Response.class)))
	public ResponseEntity<Page<AdoptionApplicationDto.Response>> list(
			@Parameter(description = "Filter by adoption status") @RequestParam(required = false) AdoptionStatus status,
			@Parameter(description = "Filter by animal id") @RequestParam(required = false) Long animalId,
			@Parameter(description = "Filter by applicant user id") @RequestParam(required = false) Long applicantId,
			@Parameter(description = "Filter by NGO id (via rescue case)") @RequestParam(required = false) Long ngoId,
			@Parameter(description = "Search keyword in reason or applicant name") @RequestParam(required = false) String keyword,
			@Parameter(description = "Filter applications created after this date-time (ISO 8601)") @RequestParam(required = false) @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateFrom,
			@Parameter(description = "Filter applications created before this date-time (ISO 8601)") @RequestParam(required = false) @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateTo,
			@Parameter(description = "Pagination and sorting parameters", schema = @Schema(implementation = Pageable.class)) @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(
				adoptionService.list(status, animalId, applicantId, ngoId, keyword, dateFrom, dateTo, currentUser, pageable));
	}

	@GetMapping("/search")
	@Operation(summary = "Search adoption applications by keyword")
	@ApiResponse(responseCode = "200", description = "Paginated search results",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Response.class)))
	public ResponseEntity<Page<AdoptionApplicationDto.Response>> search(
			@Parameter(description = "Search keyword in reason or applicant name") @RequestParam(required = false) String keyword,
			@Parameter(description = "Pagination and sorting parameters", schema = @Schema(implementation = Pageable.class)) @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(adoptionService.search(keyword, currentUser, pageable));
	}

	@GetMapping("/{id}")
	@Operation(summary = "Get an adoption application by id")
	@ApiResponse(responseCode = "200", description = "Adoption application details",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Response.class)))
	@ApiResponse(responseCode = "404", description = "Application not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Not authorized",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AdoptionApplicationDto.Response> get(@PathVariable Long id) {
		return ResponseEntity.ok(adoptionService.get(id, SecurityUtils.requireCurrentUser(userRepository)));
	}

	@PutMapping("/{id}")
	@Operation(summary = "Update an adoption application", description = "Only submitted applications can be updated by the applicant.")
	@ApiResponse(responseCode = "200", description = "Application updated",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Only submitted applications can be edited",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Not authorized",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Application not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AdoptionApplicationDto.Response> update(
			@PathVariable Long id,
			@Valid @RequestBody AdoptionApplicationDto.Update request) {
		return ResponseEntity.ok(adoptionService.update(id, request, SecurityUtils.requireCurrentUser(userRepository)));
	}

	@PatchMapping("/{id}/status")
	@Operation(summary = "Transition an adoption application to a new status")
	@ApiResponse(responseCode = "200", description = "Status updated",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Invalid status transition",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Not authorized",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Application not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AdoptionApplicationDto.Response> changeStatus(
			@PathVariable Long id,
			@Valid @RequestBody AdoptionStatusChangeDTO request) {
		return ResponseEntity.ok(adoptionService.changeStatus(id, request.getStatus(), SecurityUtils.requireCurrentUser(userRepository)));
	}

	@PostMapping("/{id}/approve")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Approve an adoption application", description = "Only NGO or Admin can approve. Application must be under review.")
	@ApiResponse(responseCode = "200", description = "Application approved",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Invalid status transition or animal already approved",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Access denied",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Application not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AdoptionApplicationDto.Response> approve(@PathVariable Long id) {
		return ResponseEntity.ok(adoptionService.approve(id, SecurityUtils.requireCurrentUser(userRepository)));
	}

	@PostMapping("/{id}/reject")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Reject an adoption application", description = "Only NGO or Admin can reject. Application must be under review.")
	@ApiResponse(responseCode = "200", description = "Application rejected",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Invalid status transition",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Access denied",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Application not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AdoptionApplicationDto.Response> reject(
			@PathVariable Long id,
			@RequestBody(required = false) @Schema(description = "Optional rejection notes") String notes) {
		return ResponseEntity.ok(adoptionService.reject(id, notes, SecurityUtils.requireCurrentUser(userRepository)));
	}

	@PostMapping("/{id}/withdraw")
	@Operation(summary = "Withdraw an adoption application", description = "Only the applicant may withdraw. Application must be submitted or under review.")
	@ApiResponse(responseCode = "200", description = "Application withdrawn",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Only the applicant may withdraw or invalid transition",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Not authorized",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Application not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AdoptionApplicationDto.Response> withdraw(@PathVariable Long id) {
		return ResponseEntity.ok(adoptionService.withdraw(id, SecurityUtils.requireCurrentUser(userRepository)));
	}

	@PostMapping("/{id}/complete")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Complete an approved adoption application", description = "Only NGO or Admin can complete. Application must be approved.")
	@ApiResponse(responseCode = "200", description = "Application completed",
			content = @Content(schema = @Schema(implementation = AdoptionApplicationDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Invalid status transition",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Access denied",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Application not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AdoptionApplicationDto.Response> complete(@PathVariable Long id) {
		return ResponseEntity.ok(adoptionService.complete(id, SecurityUtils.requireCurrentUser(userRepository)));
	}

	@DeleteMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Soft-delete an adoption application", description = "Requires ADMIN or NGO role.")
	@ApiResponse(responseCode = "200", description = "Application deleted successfully",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class)))
	@ApiResponse(responseCode = "403", description = "Access denied",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Application not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<MessageResponseDTO> delete(@PathVariable Long id) {
		return ResponseEntity.ok(adoptionService.delete(id));
	}

	@PostMapping("/{id}/checkin")
	@Operation(summary = "Submit a check-in for an adoption application (Flutter compatibility)")
	public ResponseEntity<AdoptionApplicationDto.Response> checkin(
			@PathVariable Long id,
			@RequestBody Map<String, Object> body) {
		String text = (String) body.get("text");
		String photoUrl = (String) body.get("photoUrl");

		// Log check-in text and details to MongoDB
		try {
			ChatLog log = new ChatLog();
			log.setDirection("inbound");
			log.setChannel("adoption_checkin");
			log.setMessage("Check-in for application ID " + id + ": " + text);
			log.setMetadata(Map.of("photoUrl", photoUrl != null ? photoUrl : ""));
			log.setCreatedAt(java.time.LocalDateTime.now());
			chatLogRepository.save(log);
		} catch (Exception ex) {
			System.err.println("Could not log check-in to MongoDB: " + ex.getMessage());
		}

		AdoptionApplicationDto.Response response = adoptionService.get(id, SecurityUtils.requireCurrentUser(userRepository));
		return ResponseEntity.ok(response);
	}

	@GetMapping("/case/{caseId}")
	@Operation(summary = "Get adoption applications for a specific case")
	public ResponseEntity<Page<AdoptionApplicationDto.Response>> getByCaseId(
			@PathVariable Long caseId,
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(adoptionService.getByCaseId(caseId, pageable));
	}
}
