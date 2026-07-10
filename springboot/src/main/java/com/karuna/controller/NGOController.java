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

import com.karuna.dto.domain.NgoDto;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.service.NGOService;

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
@RequestMapping("/api/ngos")
@Tag(name = "NGOs", description = "NGO records, search, filtering, and assignments")
public class NGOController {

	private final NGOService ngoService;

	public NGOController(NGOService ngoService) {
		this.ngoService = ngoService;
	}

	@PostMapping
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Create an NGO record")
	@SecurityRequirement(name = "bearerAuth")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "NGO details",
			content = @Content(schema = @Schema(implementation = NgoDto.Request.class),
					examples = @ExampleObject(value = """
							{
							  "name": "Animal Rescue Foundation",
							  "registrationNumber": "NGO-REG-001",
							  "email": "contact@arf.org",
							  "phoneNumber": "+919999999999",
							  "description": "Urban animal rescue",
							  "headquartersLocationId": 1
							}""")))
	@ApiResponse(responseCode = "200", description = "NGO created",
			content = @Content(schema = @Schema(implementation = NgoDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Validation failed",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "409", description = "Duplicate registration number",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<NgoDto.Response> create(@Valid @RequestBody NgoDto.Request request) {
		return ResponseEntity.ok(ngoService.create(request));
	}

	@GetMapping
	@SecurityRequirements
	@Operation(summary = "List NGOs with filtering, pagination, and sorting")
	@ApiResponse(responseCode = "200", description = "Paged list of NGOs",
			content = @Content(schema = @Schema(implementation = NgoDto.Response.class)))
	public ResponseEntity<Page<NgoDto.Response>> list(
			@RequestParam(required = false) String keyword,
			@RequestParam(required = false) Long locationId,
			@RequestParam(required = false) Boolean active,
			@RequestParam(required = false) Boolean verified,
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(ngoService.list(keyword, locationId, active, verified, pageable));
	}

	@GetMapping("/search")
	@SecurityRequirements
	@Operation(summary = "Search NGOs by keyword and filters")
	@ApiResponse(responseCode = "200", description = "Paged search results",
			content = @Content(schema = @Schema(implementation = NgoDto.Response.class)))
	public ResponseEntity<Page<NgoDto.Response>> search(
			@RequestParam(required = false) String keyword,
			@RequestParam(required = false) Long locationId,
			@RequestParam(required = false) Boolean active,
			@RequestParam(required = false) Boolean verified,
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(ngoService.list(keyword, locationId, active, verified, pageable));
	}

	@GetMapping("/{id}")
	@SecurityRequirements
	@Operation(summary = "Get an NGO by id")
	@ApiResponse(responseCode = "200", description = "NGO details",
			content = @Content(schema = @Schema(implementation = NgoDto.Response.class)))
	@ApiResponse(responseCode = "404", description = "NGO not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<NgoDto.Response> get(@PathVariable Long id) {
		return ResponseEntity.ok(ngoService.get(id));
	}

	@PutMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Update an NGO record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "NGO updated",
			content = @Content(schema = @Schema(implementation = NgoDto.Response.class)))
	public ResponseEntity<NgoDto.Response> update(@PathVariable Long id, @Valid @RequestBody NgoDto.Update request) {
		return ResponseEntity.ok(ngoService.update(id, request));
	}

	@PatchMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Partially update an NGO record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "NGO updated",
			content = @Content(schema = @Schema(implementation = NgoDto.Response.class)))
	public ResponseEntity<NgoDto.Response> partialUpdate(@PathVariable Long id, @Valid @RequestBody NgoDto.Update request) {
		return ResponseEntity.ok(ngoService.update(id, request));
	}

	@DeleteMapping("/{id}")
	@PreAuthorize("hasRole('ADMIN')")
	@Operation(summary = "Soft-delete an NGO record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "NGO deleted",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class)))
	public ResponseEntity<MessageResponseDTO> delete(@PathVariable Long id) {
		return ResponseEntity.ok(ngoService.delete(id));
	}

	@PostMapping("/{id}/assign-case/{caseId}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Assign an NGO to a rescue case")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "NGO assigned to case",
			content = @Content(schema = @Schema(implementation = NgoDto.Response.class)))
	public ResponseEntity<NgoDto.Response> assignCase(@PathVariable Long id, @PathVariable Long caseId) {
		return ResponseEntity.ok(ngoService.assignCase(id, caseId));
	}

	@PostMapping("/{id}/assign-volunteer/{volunteerId}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Assign a volunteer to an NGO")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Volunteer assigned to NGO",
			content = @Content(schema = @Schema(implementation = NgoDto.Response.class)))
	public ResponseEntity<NgoDto.Response> assignVolunteer(@PathVariable Long id, @PathVariable Long volunteerId) {
		return ResponseEntity.ok(ngoService.assignVolunteer(id, volunteerId));
	}

	@PostMapping("/{id}/assign-veterinarian/{vetId}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Link a veterinarian to an NGO (validation only; no direct FK in schema)")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Veterinarian reference validated",
			content = @Content(schema = @Schema(implementation = NgoDto.Response.class)))
	public ResponseEntity<NgoDto.Response> assignVeterinarian(@PathVariable Long id, @PathVariable Long vetId) {
		return ResponseEntity.ok(ngoService.assignVeterinarian(id, vetId));
	}
}
