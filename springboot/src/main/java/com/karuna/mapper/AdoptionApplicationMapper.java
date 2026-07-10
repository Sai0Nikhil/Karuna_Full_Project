package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.AdoptionApplicationDto;
import com.karuna.entity.AdoptionApplication;

@Mapper(config = DomainMapperConfig.class)
public interface AdoptionApplicationMapper {
	@Mapping(source = "rescueCase.id", target = "caseId")
	@Mapping(source = "animal.id", target = "animalId")
	@Mapping(source = "applicant.id", target = "applicantId")
	@Mapping(source = "decidedBy.id", target = "decidedById")
	@Mapping(source = "adoptionStatus", target = "status")
	AdoptionApplicationDto.Response toResponse(AdoptionApplication adoptionApplication);

	@Mapping(source = "rescueCase.id", target = "caseId")
	@Mapping(source = "animal.id", target = "animalId")
	@Mapping(source = "adoptionStatus", target = "status")
	AdoptionApplicationDto.Summary toSummary(AdoptionApplication adoptionApplication);

	AdoptionApplication toEntity(AdoptionApplicationDto.Request request);

	@Mapping(source = "status", target = "adoptionStatus")
	void updateEntity(AdoptionApplicationDto.Update request, @MappingTarget AdoptionApplication adoptionApplication);
}
