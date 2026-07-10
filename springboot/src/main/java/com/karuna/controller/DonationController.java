package com.karuna.controller;

import java.math.BigDecimal;
import java.time.LocalDateTime;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.web.PageableDefault;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PatchMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import com.karuna.dto.DonationStatusChangeDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.domain.DonationDto;
import com.karuna.dto.domain.DonationSummaryDto;
import com.karuna.entity.User;
import com.karuna.entity.enums.DonationStatus;
import com.karuna.repository.UserRepository;
import com.karuna.security.auth.SecurityUtils;
import com.karuna.service.DonationService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/donations")
@Tag(name = "Donations", description = "Donation management, search, status workflow, and statistics")
public class DonationController {

	private final DonationService donationService;
	private final UserRepository userRepository;

	public DonationController(DonationService donationService, UserRepository userRepository) {
		this.donationService = donationService;
		this.userRepository = userRepository;
	}

	@PostMapping
	@Operation(summary = "Create a new donation", description = "Creates a donation for the authenticated user. Status is set to PENDING.")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Donation details",
			content = @Content(schema = @Schema(implementation = DonationDto.Request.class),
					examples = @ExampleObject(value = """
							{
							  "donorId": 5,
							  "caseId": 3,
							  "amount": 500.00,
							  "currency": "INR",
							  "paymentReference": "txn-123",
							  "paymentProvider": "DummyPaymentProvider",
							  "message": "Help the animal"
							}""")))
	@ApiResponse(responseCode = "200", description = "Donation created successfully",
			content = @Content(schema = @Schema(implementation = DonationDto.Response.class),
					examples = @ExampleObject(value = """
							{
							  "id": 1,
							  "donorId": 5,
							  "caseId": 3,
							  "amount": 500.00,
							  "currency": "INR",
							  "status": "PENDING",
							  "paymentReference": "txn-123",
							  "paymentProvider": "DummyPaymentProvider",
							  "message": "Help the animal",
							  "createdAt": "2025-01-01T10:00:00",
							  "updatedAt": "2025-01-01T10:00:00",
							  "version": 0
							}""")))
	@ApiResponse(responseCode = "400", description = "Validation error",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "401", description = "Authentication required",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<DonationDto.Response> create(@Valid @RequestBody DonationDto.Request request) {
		User donor = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(donationService.create(request, donor));
	}

	@GetMapping
	@Operation(summary = "List donations with filtering, pagination, and sorting", description = "Returns a paginated list of donations. Citizens see only their own donations. NGOs and Admins see all donations filtered by the provided parameters.")
	@ApiResponse(responseCode = "200", description = "Paginated donation list",
			content = @Content(schema = @Schema(implementation = DonationDto.Response.class)))
	public ResponseEntity<Page<DonationDto.Response>> list(
			@Parameter(description = "Filter by donation status") @RequestParam(required = false) DonationStatus status,
			@Parameter(description = "Filter by currency (case-insensitive)") @RequestParam(required = false) String currency,
			@Parameter(description = "Filter by donor user id") @RequestParam(required = false) Long donorId,
			@Parameter(description = "Filter by NGO id (via rescue case)") @RequestParam(required = false) Long ngoId,
			@Parameter(description = "Filter by rescue case id") @RequestParam(required = false) Long caseId,
			@Parameter(description = "Search keyword in donation message") @RequestParam(required = false) String keyword,
			@Parameter(description = "Minimum donation amount") @RequestParam(required = false) BigDecimal amountMin,
			@Parameter(description = "Maximum donation amount") @RequestParam(required = false) BigDecimal amountMax,
			@Parameter(description = "Filter donations created after this date-time (ISO 8601)") @RequestParam(required = false) @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateFrom,
			@Parameter(description = "Filter donations created before this date-time (ISO 8601)") @RequestParam(required = false) @org.springframework.format.annotation.DateTimeFormat(iso = org.springframework.format.annotation.DateTimeFormat.ISO.DATE_TIME) LocalDateTime dateTo,
			@Parameter(description = "Pagination and sorting parameters", schema = @Schema(implementation = Pageable.class)) @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(
				donationService.list(status, currency, donorId, ngoId, caseId, keyword, amountMin, amountMax, dateFrom,
						dateTo, currentUser, pageable));
	}

	@GetMapping("/search")
	@Operation(summary = "Search donations by keyword", description = "Searches donations by message keyword with pagination and sorting.")
	@ApiResponse(responseCode = "200", description = "Paginated search results",
			content = @Content(schema = @Schema(implementation = DonationDto.Response.class)))
	public ResponseEntity<Page<DonationDto.Response>> search(
			@Parameter(description = "Search keyword in donation message") @RequestParam(required = false) String keyword,
			@Parameter(description = "Pagination and sorting parameters", schema = @Schema(implementation = Pageable.class)) @PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(donationService.search(keyword, currentUser, pageable));
	}

	@GetMapping("/{id}")
	@Operation(summary = "Get a donation by id")
	@ApiResponse(responseCode = "200", description = "Donation details",
			content = @Content(schema = @Schema(implementation = DonationDto.Response.class)))
	@ApiResponse(responseCode = "404", description = "Donation not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Not authorized to view this donation",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<DonationDto.Response> get(@PathVariable Long id) {
		return ResponseEntity.ok(donationService.get(id, SecurityUtils.requireCurrentUser(userRepository)));
	}

	@PutMapping("/{id}")
	@Operation(summary = "Update a donation", description = "Only pending donations can be updated. Only the donor or an admin can update.")
	@ApiResponse(responseCode = "200", description = "Donation updated",
			content = @Content(schema = @Schema(implementation = DonationDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Only pending donations can be edited",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Not authorized",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Donation not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<DonationDto.Response> update(
			@PathVariable Long id,
			@Valid @RequestBody DonationDto.Update request) {
		return ResponseEntity.ok(donationService.update(id, request, SecurityUtils.requireCurrentUser(userRepository)));
	}

	@DeleteMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Soft-delete a donation", description = "Requires ADMIN or NGO role.")
	@ApiResponse(responseCode = "200", description = "Donation deleted successfully",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class)))
	@ApiResponse(responseCode = "403", description = "Access denied",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Donation not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<MessageResponseDTO> delete(@PathVariable Long id) {
		return ResponseEntity.ok(donationService.delete(id));
	}

	@PatchMapping("/{id}/status")
	@Operation(summary = "Transition a donation to a new status", description = "Validates the status transition using the donation status machine. Only ADMIN or the donor can change status.")
	@ApiResponse(responseCode = "200", description = "Status updated",
			content = @Content(schema = @Schema(implementation = DonationDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Invalid status transition",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Not authorized",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Donation not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<DonationDto.Response> changeStatus(
			@PathVariable Long id,
			@Valid @RequestBody DonationStatusChangeDTO request) {
		return ResponseEntity.ok(donationService.changeStatus(id, request, SecurityUtils.requireCurrentUser(userRepository)));
	}

	@PostMapping("/{id}/cancel")
	@Operation(summary = "Cancel a pending donation", description = "Only pending donations can be cancelled. Only the donor or an admin can cancel.")
	@ApiResponse(responseCode = "200", description = "Donation cancelled",
			content = @Content(schema = @Schema(implementation = DonationDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Only pending donations can be cancelled",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "403", description = "Not authorized",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "404", description = "Donation not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<DonationDto.Response> cancel(@PathVariable Long id) {
		return ResponseEntity.ok(donationService.cancel(id, SecurityUtils.requireCurrentUser(userRepository)));
	}

	@GetMapping("/summary")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Get donation statistics summary", description = "Requires ADMIN or NGO role. Returns aggregate donation statistics.")
	@ApiResponse(responseCode = "200", description = "Donation summary statistics",
			content = @Content(schema = @Schema(implementation = DonationSummaryDto.Response.class)))
	@ApiResponse(responseCode = "403", description = "Access denied",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<DonationSummaryDto.Response> summary() {
		return ResponseEntity.ok(donationService.summary());
	}
}
