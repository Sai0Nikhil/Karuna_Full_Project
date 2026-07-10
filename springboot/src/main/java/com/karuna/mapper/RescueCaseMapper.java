package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.RescueCaseDto;
import com.karuna.entity.RescueCase;

@Mapper(config = DomainMapperConfig.class)
public interface RescueCaseMapper {
	@Mapping(source = "caseStatus", target = "status")
	@Mapping(source = "reporter.id", target = "reporterId")
	@Mapping(source = "animal.id", target = "animalId")
	@Mapping(source = "ngo.id", target = "ngoId")
	@Mapping(source = "primaryVolunteer.id", target = "primaryVolunteerId")
	@Mapping(source = "geoLocation.id", target = "locationId")
	RescueCaseDto.Response toResponse(RescueCase rescueCase);

	@Mapping(source = "caseStatus", target = "status")
	@Mapping(source = "ngo.id", target = "ngoId")
	RescueCaseDto.Summary toSummary(RescueCase rescueCase);

	@Mapping(source = "status", target = "caseStatus")
	RescueCase toEntity(RescueCaseDto.Request request);

	@Mapping(source = "status", target = "caseStatus")
	void updateEntity(RescueCaseDto.Update request, @MappingTarget RescueCase rescueCase);
}
