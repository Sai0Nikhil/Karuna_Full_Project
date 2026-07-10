package com.karuna.dto;

import jakarta.validation.constraints.Positive;

public class CaseAssignmentDTO {

	@Positive
	private Long ngoId;

	@Positive
	private Long primaryVolunteerId;

	public Long getNgoId() {
		return ngoId;
	}

	public void setNgoId(Long ngoId) {
		this.ngoId = ngoId;
	}

	public Long getPrimaryVolunteerId() {
		return primaryVolunteerId;
	}

	public void setPrimaryVolunteerId(Long primaryVolunteerId) {
		this.primaryVolunteerId = primaryVolunteerId;
	}
}
