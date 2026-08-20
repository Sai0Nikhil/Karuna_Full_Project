package com.karuna.dto;

import com.karuna.entity.enums.DonationStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class DonationStatusChangeDTO {

	@NotNull
	private DonationStatus status;

	@Size(max = 500)
	private String note;

	public DonationStatus getStatus() {
		return status;
	}

	public void setStatus(DonationStatus status) {
		this.status = status;
	}

	public String getNote() {
		return note;
	}

	public void setNote(String note) {
		this.note = note;
	}
}
