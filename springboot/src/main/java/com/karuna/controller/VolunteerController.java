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

import com.karuna.dto.VolunteerAvailabilityDTO;
import com.karuna.dto.domain.VolunteerDto;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.entity.enums.VolunteerStatus;
import com.karuna.service.VolunteerService;

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
@RequestMapping("/api/volunteers")
@Tag(name = "Volunteers", description = "Volunteer records, availability, and case assignment")
public class VolunteerController {

	private final VolunteerService volunteerService;

	public VolunteerController(VolunteerService volunteerService) {
		this.volunteerService = volunteerService;
	}

	@PostMapping
	@PreAuthorize("hasAnyRole('ADMIN','VOLUNTEER')")
	@Operation(summary = "Create a volunteer record")
	@SecurityRequirement(name = "bearerAuth")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Volunteer details",
			content = @Content(schema = @Schema(implementation = VolunteerDto.Request.class),
					examples = @ExampleObject(value = """
							{
							  "userId": 10,
							  "phoneNumber": "+919888888888",
							  "status": "AVAILABLE",
							  "skills": "Rescue, Transport",
							  "serviceLocationId": 1
							}""")))
	@ApiResponse(responseCode = "200", description = "Volunteer created",
			content = @Content(schema = @Schema(implementation = VolunteerDto.Response.class)))
	@ApiResponse(responseCode = "409", description = "Volunteer already exists for user",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<VolunteerDto.Response> create(@Valid @RequestBody VolunteerDto.Request request) {
		return ResponseEntity.ok(volunteerService.create(request));
	}

	@GetMapping
	@SecurityRequirements
	@Operation(summary = "List volunteers with filtering, pagination, and sorting")
	@ApiResponse(responseCode = "200", description = "Paged list of volunteers",
			content = @Content(schema = @Schema(implementation = VolunteerDto.Response.class)))
	public ResponseEntity<Page<VolunteerDto.Response>> list(
			@RequestParam(required = false) VolunteerStatus status,
			@RequestParam(required = false) Long locationId,
			@RequestParam(required = false) Long ngoId,
			@RequestParam(required = false) String keyword,
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(volunteerService.list(status, locationId, ngoId, keyword, pageable));
	}

	@GetMapping("/search")
	@SecurityRequirements
	@Operation(summary = "Search volunteers by keyword and filters")
	@ApiResponse(responseCode = "200", description = "Paged search results",
			content = @Content(schema = @Schema(implementation = VolunteerDto.Response.class)))
	public ResponseEntity<Page<VolunteerDto.Response>> search(
			@RequestParam(required = false) VolunteerStatus status,
			@RequestParam(required = false) Long locationId,
			@RequestParam(required = false) Long ngoId,
			@RequestParam(required = false) String keyword,
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(volunteerService.list(status, locationId, ngoId, keyword, pageable));
	}

	@GetMapping("/{id}")
	@SecurityRequirements
	@Operation(summary = "Get a volunteer by id")
	@ApiResponse(responseCode = "200", description = "Volunteer details",
			content = @Content(schema = @Schema(implementation = VolunteerDto.Response.class)))
	@ApiResponse(responseCode = "404", description = "Volunteer not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<VolunteerDto.Response> get(@PathVariable Long id) {
		return ResponseEntity.ok(volunteerService.get(id));
	}

	@PutMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','VOLUNTEER')")
	@Operation(summary = "Update a volunteer record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Volunteer updated",
			content = @Content(schema = @Schema(implementation = VolunteerDto.Response.class)))
	public ResponseEntity<VolunteerDto.Response> update(@PathVariable Long id, @Valid @RequestBody VolunteerDto.Update request) {
		return ResponseEntity.ok(volunteerService.update(id, request));
	}

	@PatchMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','VOLUNTEER')")
	@Operation(summary = "Partially update a volunteer record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Volunteer updated",
			content = @Content(schema = @Schema(implementation = VolunteerDto.Response.class)))
	public ResponseEntity<VolunteerDto.Response> partialUpdate(@PathVariable Long id, @Valid @RequestBody VolunteerDto.Update request) {
		return ResponseEntity.ok(volunteerService.update(id, request));
	}

	@DeleteMapping("/{id}")
	@PreAuthorize("hasRole('ADMIN')")
	@Operation(summary = "Soft-delete a volunteer record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Volunteer deleted",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class)))
	public ResponseEntity<MessageResponseDTO> delete(@PathVariable Long id) {
		return ResponseEntity.ok(volunteerService.delete(id));
	}

	@PatchMapping("/{id}/availability")
	@PreAuthorize("hasAnyRole('ADMIN','VOLUNTEER')")
	@Operation(summary = "Update volunteer availability status")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Availability updated",
			content = @Content(schema = @Schema(implementation = VolunteerDto.Response.class)))
	public ResponseEntity<VolunteerDto.Response> availability(
			@PathVariable Long id,
			@Valid @RequestBody VolunteerAvailabilityDTO request) {
		return ResponseEntity.ok(volunteerService.setAvailability(id, request));
	}

	@PostMapping("/{id}/assign-case/{caseId}")
	@PreAuthorize("hasAnyRole('ADMIN','VOLUNTEER')")
	@Operation(summary = "Assign a volunteer to a rescue case")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Volunteer assigned to case",
			content = @Content(schema = @Schema(implementation = VolunteerDto.Response.class)))
	@ApiResponse(responseCode = "409", description = "Volunteer unavailable or at capacity",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<VolunteerDto.Response> assignCase(@PathVariable Long id, @PathVariable Long caseId) {
		return ResponseEntity.ok(volunteerService.assignCase(id, caseId));
	}
}
