package com.karuna.dto;

import com.karuna.entity.enums.AdoptionStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class AdoptionStatusChangeDTO {

	@NotNull
	private AdoptionStatus status;

	@Size(max = 5000)
	private String notes;

	public AdoptionStatus getStatus() {
		return status;
	}

	public void setStatus(AdoptionStatus status) {
		this.status = status;
	}

	public String getNotes() {
		return notes;
	}

	public void setNotes(String notes) {
		this.notes = notes;
	}
}
