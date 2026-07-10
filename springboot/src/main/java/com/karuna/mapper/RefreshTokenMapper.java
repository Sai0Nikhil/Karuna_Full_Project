package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.RefreshTokenDto;
import com.karuna.entity.RefreshToken;

@Mapper(config = DomainMapperConfig.class)
public interface RefreshTokenMapper {
	@Mapping(source = "user.id", target = "userId")
	RefreshTokenDto.Response toResponse(RefreshToken refreshToken);

	@Mapping(source = "user.id", target = "userId")
	RefreshTokenDto.Summary toSummary(RefreshToken refreshToken);

	RefreshToken toEntity(RefreshTokenDto.Request request);

	void updateEntity(RefreshTokenDto.Update request, @MappingTarget RefreshToken refreshToken);
}
