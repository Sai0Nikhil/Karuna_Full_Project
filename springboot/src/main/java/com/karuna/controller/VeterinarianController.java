package com.karuna.controller;

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

import com.karuna.dto.domain.VeterinarianDto;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.service.VeterinarianService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.ExampleObject;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.security.SecurityRequirements;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/veterinarians")
@Tag(name = "Veterinarians", description = "Veterinarian records, search, filtering, and case assignment")
public class VeterinarianController {

	private final VeterinarianService veterinarianService;

	public VeterinarianController(VeterinarianService veterinarianService) {
		this.veterinarianService = veterinarianService;
	}

	@PostMapping
	@PreAuthorize("hasAnyRole('ADMIN','VET')")
	@Operation(summary = "Create a veterinarian record")
	@SecurityRequirement(name = "bearerAuth")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Veterinarian details",
			content = @Content(schema = @Schema(implementation = VeterinarianDto.Request.class),
					examples = @ExampleObject(value = """
							{
							  "userId": 20,
							  "licenseNumber": "VET-LIC-001",
							  "clinicName": "City Animal Clinic",
							  "specialization": "Surgery",
							  "email": "vet@clinic.org",
							  "phoneNumber": "+917777777777",
							  "clinicLocationId": 1
							}""")))
	@ApiResponse(responseCode = "200", description = "Veterinarian created",
			content = @Content(schema = @Schema(implementation = VeterinarianDto.Response.class)))
	@ApiResponse(responseCode = "409", description = "Duplicate license number",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<VeterinarianDto.Response> create(@Valid @RequestBody VeterinarianDto.Request request) {
		return ResponseEntity.ok(veterinarianService.create(request));
	}

	@GetMapping
	@SecurityRequirements
	@Operation(summary = "List veterinarians with filtering, pagination, and sorting")
	@ApiResponse(responseCode = "200", description = "Paged list of veterinarians",
			content = @Content(schema = @Schema(implementation = VeterinarianDto.Response.class)))
	public ResponseEntity<Page<VeterinarianDto.Response>> list(
			@RequestParam(required = false) String specialization,
			@RequestParam(required = false) Long locationId,
			@RequestParam(required = false) String keyword,
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(veterinarianService.list(specialization, locationId, keyword, pageable));
	}

	@GetMapping("/search")
	@SecurityRequirements
	@Operation(summary = "Search veterinarians by keyword and filters")
	@ApiResponse(responseCode = "200", description = "Paged search results",
			content = @Content(schema = @Schema(implementation = VeterinarianDto.Response.class)))
	public ResponseEntity<Page<VeterinarianDto.Response>> search(
			@RequestParam(required = false) String specialization,
			@RequestParam(required = false) Long locationId,
			@RequestParam(required = false) String keyword,
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(veterinarianService.list(specialization, locationId, keyword, pageable));
	}

	@GetMapping("/{id}")
	@SecurityRequirements
	@Operation(summary = "Get a veterinarian by id")
	@ApiResponse(responseCode = "200", description = "Veterinarian details",
			content = @Content(schema = @Schema(implementation = VeterinarianDto.Response.class)))
	@ApiResponse(responseCode = "404", description = "Veterinarian not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<VeterinarianDto.Response> get(@PathVariable Long id) {
		return ResponseEntity.ok(veterinarianService.get(id));
	}

	@PutMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','VET')")
	@Operation(summary = "Update a veterinarian record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Veterinarian updated",
			content = @Content(schema = @Schema(implementation = VeterinarianDto.Response.class)))
	public ResponseEntity<VeterinarianDto.Response> update(@PathVariable Long id, @Valid @RequestBody VeterinarianDto.Update request) {
		return ResponseEntity.ok(veterinarianService.update(id, request));
	}

	@PatchMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','VET')")
	@Operation(summary = "Partially update a veterinarian record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Veterinarian updated",
			content = @Content(schema = @Schema(implementation = VeterinarianDto.Response.class)))
	public ResponseEntity<VeterinarianDto.Response> partialUpdate(@PathVariable Long id, @Valid @RequestBody VeterinarianDto.Update request) {
		return ResponseEntity.ok(veterinarianService.update(id, request));
	}

	@DeleteMapping("/{id}")
	@PreAuthorize("hasRole('ADMIN')")
	@Operation(summary = "Soft-delete a veterinarian record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Veterinarian deleted",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class)))
	public ResponseEntity<MessageResponseDTO> delete(@PathVariable Long id) {
		return ResponseEntity.ok(veterinarianService.delete(id));
	}

	@PostMapping("/{id}/assign-case/{caseId}")
	@PreAuthorize("hasAnyRole('ADMIN','VET')")
	@Operation(summary = "Link a veterinarian to a rescue case (validation only; linkage via Treatment)")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Veterinarian and case validated",
			content = @Content(schema = @Schema(implementation = VeterinarianDto.Response.class)))
	public ResponseEntity<VeterinarianDto.Response> assignCase(@PathVariable Long id, @PathVariable Long caseId) {
		return ResponseEntity.ok(veterinarianService.assignCase(id, caseId));
	}
}
