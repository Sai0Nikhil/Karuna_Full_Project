package com.karuna.dto;

import com.karuna.entity.enums.CaseStatus;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Size;

public class CaseStatusChangeDTO {

	@NotNull
	private CaseStatus status;

	@Size(max = 1000)
	private String note;

	public CaseStatus getStatus() {
		return status;
	}

	public void setStatus(CaseStatus status) {
		this.status = status;
	}

	public String getNote() {
		return note;
	}

	public void setNote(String note) {
		this.note = note;
	}
}
