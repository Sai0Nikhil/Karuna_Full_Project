package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.VeterinarianDto;
import com.karuna.entity.Veterinarian;

@Mapper(config = DomainMapperConfig.class)
public interface VeterinarianMapper {
	@Mapping(source = "user.id", target = "userId")
	@Mapping(source = "clinicLocation.id", target = "clinicLocationId")
	VeterinarianDto.Response toResponse(Veterinarian veterinarian);

	@Mapping(source = "user.id", target = "userId")
	VeterinarianDto.Summary toSummary(Veterinarian veterinarian);

	Veterinarian toEntity(VeterinarianDto.Request request);

	void updateEntity(VeterinarianDto.Update request, @MappingTarget Veterinarian veterinarian);
}
