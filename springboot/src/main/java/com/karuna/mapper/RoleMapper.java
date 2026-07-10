package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.RoleDto;
import com.karuna.entity.Role;

@Mapper(config = DomainMapperConfig.class)
public interface RoleMapper {
	RoleDto.Response toResponse(Role role);

	RoleDto.Summary toSummary(Role role);

	Role toEntity(RoleDto.Request request);

	void updateEntity(RoleDto.Update request, @MappingTarget Role role);
}
