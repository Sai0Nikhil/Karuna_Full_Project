package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.VolunteerDto;
import com.karuna.entity.Volunteer;

@Mapper(config = DomainMapperConfig.class)
public interface VolunteerMapper {
	@Mapping(source = "user.id", target = "userId")
	@Mapping(source = "serviceLocation.id", target = "serviceLocationId")
	VolunteerDto.Response toResponse(Volunteer volunteer);

	@Mapping(source = "user.id", target = "userId")
	VolunteerDto.Summary toSummary(Volunteer volunteer);

	Volunteer toEntity(VolunteerDto.Request request);

	void updateEntity(VolunteerDto.Update request, @MappingTarget Volunteer volunteer);
}
