package com.karuna.dto;

import jakarta.validation.constraints.NotBlank;

public class VerifyEmailRequestDTO {

	@NotBlank
	private String token;

	public String getToken() {
		return token;
	}

	public void setToken(String token) {
		this.token = token;
	}
}
