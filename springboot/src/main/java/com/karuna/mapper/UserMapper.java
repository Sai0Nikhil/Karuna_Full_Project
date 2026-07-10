package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.UserDto;
import com.karuna.entity.User;

@Mapper(config = DomainMapperConfig.class)
public interface UserMapper {
	@Mapping(source = "userRole", target = "role")
	@Mapping(source = "location.id", target = "locationId")
	UserDto.Response toResponse(User user);

	@Mapping(source = "userRole", target = "role")
	UserDto.Summary toSummary(User user);

	@Mapping(source = "role", target = "userRole")
	User toEntity(UserDto.Request request);

	@Mapping(source = "role", target = "userRole")
	void updateEntity(UserDto.Update request, @MappingTarget User user);
}
