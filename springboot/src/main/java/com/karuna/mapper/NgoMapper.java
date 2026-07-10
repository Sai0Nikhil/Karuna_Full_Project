package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.NgoDto;
import com.karuna.entity.NGO;

@Mapper(config = DomainMapperConfig.class)
public interface NgoMapper {
	@Mapping(source = "headquartersLocation.id", target = "headquartersLocationId")
	NgoDto.Response toResponse(NGO ngo);

	NgoDto.Summary toSummary(NGO ngo);

	NGO toEntity(NgoDto.Request request);

	void updateEntity(NgoDto.Update request, @MappingTarget NGO ngo);
}
