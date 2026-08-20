package com.karuna.dto;

import com.karuna.entity.enums.VolunteerStatus;

import jakarta.validation.constraints.NotNull;

public class VolunteerAvailabilityDTO {

	@NotNull
	private VolunteerStatus status;

	public VolunteerStatus getStatus() {
		return status;
	}

	public void setStatus(VolunteerStatus status) {
		this.status = status;
	}
}
