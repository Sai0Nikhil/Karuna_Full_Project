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

import com.karuna.dto.CaseAssignmentDTO;
import com.karuna.dto.CaseStatusChangeDTO;
import com.karuna.dto.MessageResponseDTO;
import com.karuna.dto.domain.RescueCaseDto;
import com.karuna.entity.User;
import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.enums.PriorityLevel;
import com.karuna.repository.UserRepository;
import com.karuna.security.auth.SecurityUtils;
import com.karuna.service.RescueCaseService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/cases")
@Tag(name = "Rescue Cases", description = "Rescue case management, search, assignment, and status workflow")
public class RescueCaseController {

	private final RescueCaseService rescueCaseService;
	private final UserRepository userRepository;

	public RescueCaseController(RescueCaseService rescueCaseService, UserRepository userRepository) {
		this.rescueCaseService = rescueCaseService;
		this.userRepository = userRepository;
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
}
