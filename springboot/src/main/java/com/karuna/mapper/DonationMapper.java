package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.DonationDto;
import com.karuna.entity.Donation;

@Mapper(config = DomainMapperConfig.class)
public interface DonationMapper {
	@Mapping(source = "donor.id", target = "donorId")
	@Mapping(source = "rescueCase.id", target = "caseId")
	@Mapping(source = "donationStatus", target = "status")
	DonationDto.Response toResponse(Donation donation);

	@Mapping(source = "rescueCase.id", target = "caseId")
	@Mapping(source = "donationStatus", target = "status")
	DonationDto.Summary toSummary(Donation donation);

	@Mapping(source = "status", target = "donationStatus")
	Donation toEntity(DonationDto.Request request);

	@Mapping(source = "status", target = "donationStatus")
	void updateEntity(DonationDto.Update request, @MappingTarget Donation donation);
}
