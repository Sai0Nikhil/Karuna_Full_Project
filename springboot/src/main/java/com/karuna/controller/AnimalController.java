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

import com.karuna.dto.domain.AnimalDto;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.entity.enums.AnimalCondition;
import com.karuna.entity.enums.AnimalSpecies;
import com.karuna.service.AnimalService;

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
@RequestMapping("/api/animals")
@Tag(name = "Animals", description = "Animal records, search, filtering, and rescue case assignment")
public class AnimalController {

	private final AnimalService animalService;

	public AnimalController(AnimalService animalService) {
		this.animalService = animalService;
	}

	@PostMapping
	@PreAuthorize("isAuthenticated()")
	@Operation(summary = "Create an animal record")
	@SecurityRequirement(name = "bearerAuth")
	@io.swagger.v3.oas.annotations.parameters.RequestBody(description = "Animal details",
			content = @Content(schema = @Schema(implementation = AnimalDto.Request.class),
					examples = @ExampleObject(value = """
							{
							  "name": "Buddy",
							  "species": "DOG",
							  "breed": "Indian Pariah",
							  "condition": "INJURED",
							  "color": "Brown",
							  "sex": "MALE",
							  "estimatedAge": "2 years",
							  "lastKnownLocationId": 1
							}""")))
	@ApiResponse(responseCode = "200", description = "Animal created",
			content = @Content(schema = @Schema(implementation = AnimalDto.Response.class)))
	@ApiResponse(responseCode = "400", description = "Validation failed",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	@ApiResponse(responseCode = "401", description = "Authentication required",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AnimalDto.Response> create(@Valid @RequestBody AnimalDto.Request request) {
		return ResponseEntity.ok(animalService.create(request));
	}

	@GetMapping
	@SecurityRequirements
	@Operation(summary = "List animals with filtering, pagination, and sorting")
	@ApiResponse(responseCode = "200", description = "Paged list of animals",
			content = @Content(schema = @Schema(implementation = AnimalDto.Response.class)))
	public ResponseEntity<Page<AnimalDto.Response>> list(
			@RequestParam(required = false) AnimalSpecies species,
			@RequestParam(required = false) AnimalCondition condition,
			@RequestParam(required = false) Long locationId,
			@RequestParam(required = false) Long caseId,
			@RequestParam(required = false) String keyword,
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(animalService.list(species, condition, locationId, caseId, keyword, pageable));
	}

	@GetMapping("/search")
	@SecurityRequirements
	@Operation(summary = "Search animals by keyword and filters")
	@ApiResponse(responseCode = "200", description = "Paged search results",
			content = @Content(schema = @Schema(implementation = AnimalDto.Response.class)))
	public ResponseEntity<Page<AnimalDto.Response>> search(
			@RequestParam(required = false) AnimalSpecies species,
			@RequestParam(required = false) AnimalCondition condition,
			@RequestParam(required = false) Long locationId,
			@RequestParam(required = false) Long caseId,
			@RequestParam(required = false) String keyword,
			@PageableDefault(size = 20, sort = "createdAt", direction = Sort.Direction.DESC) Pageable pageable) {
		return ResponseEntity.ok(animalService.list(species, condition, locationId, caseId, keyword, pageable));
	}

	@GetMapping("/{id}")
	@SecurityRequirements
	@Operation(summary = "Get an animal by id")
	@ApiResponse(responseCode = "200", description = "Animal details",
			content = @Content(schema = @Schema(implementation = AnimalDto.Response.class)))
	@ApiResponse(responseCode = "404", description = "Animal not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AnimalDto.Response> get(@PathVariable Long id) {
		return ResponseEntity.ok(animalService.get(id));
	}

	@PutMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO','VET','VOLUNTEER')")
	@Operation(summary = "Update an animal record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Animal updated",
			content = @Content(schema = @Schema(implementation = AnimalDto.Response.class)))
	@ApiResponse(responseCode = "403", description = "Insufficient permissions",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AnimalDto.Response> update(
			@PathVariable Long id,
			@Valid @RequestBody AnimalDto.Update request) {
		return ResponseEntity.ok(animalService.update(id, request));
	}

	@PatchMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO','VET','VOLUNTEER')")
	@Operation(summary = "Partially update an animal record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Animal updated",
			content = @Content(schema = @Schema(implementation = AnimalDto.Response.class)))
	public ResponseEntity<AnimalDto.Response> partialUpdate(
			@PathVariable Long id,
			@Valid @RequestBody AnimalDto.Update request) {
		return ResponseEntity.ok(animalService.update(id, request));
	}

	@DeleteMapping("/{id}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Soft-delete an animal record")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Animal deleted",
			content = @Content(schema = @Schema(implementation = MessageResponseDTO.class)))
	@ApiResponse(responseCode = "403", description = "Insufficient permissions",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<MessageResponseDTO> delete(@PathVariable Long id) {
		return ResponseEntity.ok(animalService.delete(id));
	}

	@PostMapping("/{id}/assign-case/{caseId}")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Assign an animal to a rescue case")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Animal assigned to case",
			content = @Content(schema = @Schema(implementation = AnimalDto.Response.class)))
	@ApiResponse(responseCode = "404", description = "Animal or rescue case not found",
			content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	public ResponseEntity<AnimalDto.Response> assignCase(
			@PathVariable Long id,
			@PathVariable Long caseId) {
		return ResponseEntity.ok(animalService.assignToCase(id, caseId));
	}

	@DeleteMapping("/{id}/assign-case")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Detach an animal from all rescue cases")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponse(responseCode = "200", description = "Animal detached from cases",
			content = @Content(schema = @Schema(implementation = AnimalDto.Response.class)))
	public ResponseEntity<AnimalDto.Response> detachCase(@PathVariable Long id) {
		return ResponseEntity.ok(animalService.detachFromCase(id));
	}
}
