package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.AnimalDto;
import com.karuna.entity.Animal;

@Mapper(config = DomainMapperConfig.class)
public interface AnimalMapper {
	@Mapping(source = "lastKnownLocation.id", target = "lastKnownLocationId")
	AnimalDto.Response toResponse(Animal animal);

	AnimalDto.Summary toSummary(Animal animal);

	Animal toEntity(AnimalDto.Request request);

	void updateEntity(AnimalDto.Update request, @MappingTarget Animal animal);
}
