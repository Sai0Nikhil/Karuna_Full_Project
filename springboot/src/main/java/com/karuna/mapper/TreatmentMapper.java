package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.TreatmentDto;
import com.karuna.entity.Treatment;

@Mapper(config = DomainMapperConfig.class)
public interface TreatmentMapper {
	@Mapping(source = "animal.id", target = "animalId")
	@Mapping(source = "rescueCase.id", target = "caseId")
	@Mapping(source = "veterinarian.id", target = "veterinarianId")
	TreatmentDto.Response toResponse(Treatment treatment);

	@Mapping(source = "animal.id", target = "animalId")
	@Mapping(source = "rescueCase.id", target = "caseId")
	TreatmentDto.Summary toSummary(Treatment treatment);

	Treatment toEntity(TreatmentDto.Request request);

	void updateEntity(TreatmentDto.Update request, @MappingTarget Treatment treatment);
}
