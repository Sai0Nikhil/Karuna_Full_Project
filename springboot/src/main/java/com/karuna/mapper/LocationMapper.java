package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.LocationDto;
import com.karuna.entity.Location;

@Mapper(config = DomainMapperConfig.class)
public interface LocationMapper {
	LocationDto.Response toResponse(Location location);

	LocationDto.Summary toSummary(Location location);

	Location toEntity(LocationDto.Request request);

	void updateEntity(LocationDto.Update request, @MappingTarget Location location);
}
