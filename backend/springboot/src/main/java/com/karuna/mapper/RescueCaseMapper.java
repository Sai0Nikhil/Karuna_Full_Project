package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;
import org.mapstruct.Named;

import com.karuna.dto.domain.RescueCaseDto;
import com.karuna.entity.RescueCase;
import com.karuna.entity.enums.PriorityLevel;

@Mapper(config = DomainMapperConfig.class)
public interface RescueCaseMapper {

	@Mapping(source = "caseStatus", target = "caseStatus")
	@Mapping(source = "caseStatus", target = "status", qualifiedByName = "statusToString")
	@Mapping(source = "priority", target = "priorityLevel")
	@Mapping(source = "priority", target = "severity", qualifiedByName = "priorityToSeverity")
	@Mapping(source = "reporter.id", target = "reporterId")
	@Mapping(source = "reporter.name", target = "reporterName")
	@Mapping(source = "reporter.email", target = "reporterContact")
	@Mapping(source = "animal.id", target = "animalId")
	@Mapping(source = "ngo.id", target = "ngoId")
	@Mapping(source = "ngo.name", target = "ngo")
	@Mapping(source = "primaryVolunteer.id", target = "primaryVolunteerId")
	@Mapping(source = "primaryVolunteer.user.name", target = "assignedResponder")
	@Mapping(source = "geoLocation.id", target = "locationId")
	@Mapping(source = "imageUrl", target = "imageUrl")
	@Mapping(source = "imageUrl", target = "imageDataUrl")
	RescueCaseDto.Response toResponse(RescueCase rescueCase);

	@Mapping(source = "caseStatus", target = "status")
	@Mapping(source = "ngo.id", target = "ngoId")
	RescueCaseDto.Summary toSummary(RescueCase rescueCase);

	@Mapping(source = "status", target = "caseStatus")
	RescueCase toEntity(RescueCaseDto.Request request);

	@Mapping(source = "status", target = "caseStatus")
	void updateEntity(RescueCaseDto.Update request, @MappingTarget RescueCase rescueCase);

	@Named("statusToString")
	default String statusToString(com.karuna.entity.enums.CaseStatus status) {
		return status == null ? null : status.name().toLowerCase();
	}

	@Named("priorityToSeverity")
	default String priorityToSeverity(PriorityLevel level) {
		if (level == null) return "routine";
		return switch (level) {
			case CRITICAL -> "critical";
			case HIGH, URGENT -> "urgent";
			default -> "routine";
		};
	}
}
