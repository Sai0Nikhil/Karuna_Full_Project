package com.karuna.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.karuna.dto.domain.AnalyticsDto;
import com.karuna.entity.User;
import com.karuna.repository.UserRepository;
import com.karuna.security.auth.SecurityUtils;
import com.karuna.service.AnalyticsService;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.media.Content;
import io.swagger.v3.oas.annotations.media.Schema;
import io.swagger.v3.oas.annotations.responses.ApiResponse;
import io.swagger.v3.oas.annotations.responses.ApiResponses;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;

@RestController
@RequestMapping("/api/analytics")
@Tag(name = "Analytics", description = "Read-only analytics and dashboard statistics for ADMIN and NGO users")
public class AnalyticsController {

	private final AnalyticsService analyticsService;
	private final UserRepository userRepository;

	public AnalyticsController(AnalyticsService analyticsService, UserRepository userRepository) {
		this.analyticsService = analyticsService;
		this.userRepository = userRepository;
	}

	@GetMapping("/dashboard")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Get dashboard summary", description = "Returns aggregate counts and amounts across all modules. Requires ADMIN or NGO role.")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Dashboard statistics",
					content = @Content(schema = @Schema(implementation = AnalyticsDto.DashboardResponse.class))),
			@ApiResponse(responseCode = "401", description = "Authentication required",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class))),
			@ApiResponse(responseCode = "403", description = "Access denied",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	})
	public ResponseEntity<AnalyticsDto.DashboardResponse> getDashboard() {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(analyticsService.getDashboard());
	}

	@GetMapping("/cases")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Get rescue case analytics", description = "Returns case analytics including trends, NGO/volunteer distribution, locations, and resolution times. Requires ADMIN or NGO role.")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Case analytics",
					content = @Content(schema = @Schema(implementation = AnalyticsDto.CaseAnalyticsResponse.class))),
			@ApiResponse(responseCode = "401", description = "Authentication required",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class))),
			@ApiResponse(responseCode = "403", description = "Access denied",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	})
	public ResponseEntity<AnalyticsDto.CaseAnalyticsResponse> getCaseAnalytics() {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(analyticsService.getCaseAnalytics());
	}

	@GetMapping("/animals")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Get animal analytics", description = "Returns animal distribution by species, condition, rescue case, and location. Requires ADMIN or NGO role.")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Animal analytics",
					content = @Content(schema = @Schema(implementation = AnalyticsDto.AnimalAnalyticsResponse.class))),
			@ApiResponse(responseCode = "401", description = "Authentication required",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class))),
			@ApiResponse(responseCode = "403", description = "Access denied",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	})
	public ResponseEntity<AnalyticsDto.AnimalAnalyticsResponse> getAnimalAnalytics() {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(analyticsService.getAnimalAnalytics());
	}

	@GetMapping("/donations")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Get donation analytics", description = "Returns donation statistics including totals, averages, currency breakdown, monthly trends, and NGO distribution. Requires ADMIN or NGO role.")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Donation analytics",
					content = @Content(schema = @Schema(implementation = AnalyticsDto.DonationAnalyticsResponse.class))),
			@ApiResponse(responseCode = "401", description = "Authentication required",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class))),
			@ApiResponse(responseCode = "403", description = "Access denied",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	})
	public ResponseEntity<AnalyticsDto.DonationAnalyticsResponse> getDonationAnalytics() {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(analyticsService.getDonationAnalytics());
	}

	@GetMapping("/adoptions")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Get adoption analytics", description = "Returns adoption application statistics including approval/rejection/completion rates and distribution by animal and NGO. Requires ADMIN or NGO role.")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Adoption analytics",
					content = @Content(schema = @Schema(implementation = AnalyticsDto.AdoptionAnalyticsResponse.class))),
			@ApiResponse(responseCode = "401", description = "Authentication required",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class))),
			@ApiResponse(responseCode = "403", description = "Access denied",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	})
	public ResponseEntity<AnalyticsDto.AdoptionAnalyticsResponse> getAdoptionAnalytics() {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(analyticsService.getAdoptionAnalytics());
	}

	@GetMapping("/volunteers")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Get volunteer analytics", description = "Returns volunteer statistics including availability status, average assigned cases, and cases per volunteer. Requires ADMIN or NGO role.")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Volunteer analytics",
					content = @Content(schema = @Schema(implementation = AnalyticsDto.VolunteerAnalyticsResponse.class))),
			@ApiResponse(responseCode = "401", description = "Authentication required",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class))),
			@ApiResponse(responseCode = "403", description = "Access denied",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	})
	public ResponseEntity<AnalyticsDto.VolunteerAnalyticsResponse> getVolunteerAnalytics() {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(analyticsService.getVolunteerAnalytics());
	}

	@GetMapping("/veterinarians")
	@PreAuthorize("hasAnyRole('ADMIN','NGO')")
	@Operation(summary = "Get veterinarian analytics", description = "Returns veterinarian statistics including active count, average cases per veterinarian, and specialization distribution. Requires ADMIN or NGO role.")
	@SecurityRequirement(name = "bearerAuth")
	@ApiResponses(value = {
			@ApiResponse(responseCode = "200", description = "Veterinarian analytics",
					content = @Content(schema = @Schema(implementation = AnalyticsDto.VeterinarianAnalyticsResponse.class))),
			@ApiResponse(responseCode = "401", description = "Authentication required",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class))),
			@ApiResponse(responseCode = "403", description = "Access denied",
					content = @Content(schema = @Schema(implementation = com.karuna.exception.ApiErrorResponse.class)))
	})
	public ResponseEntity<AnalyticsDto.VeterinarianAnalyticsResponse> getVeterinarianAnalytics() {
		User currentUser = SecurityUtils.requireCurrentUser(userRepository);
		return ResponseEntity.ok(analyticsService.getVeterinarianAnalytics());
	}
}
