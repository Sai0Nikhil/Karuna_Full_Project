package com.karuna.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class ResetPasswordRequestDTO {

	@NotBlank
	private String token;

	@NotBlank
	@Size(min = 8, max = 128)
	private String newPassword;

	@NotBlank
	@Size(min = 8, max = 128)
	private String confirmPassword;

	@AssertTrue(message = "Passwords must match")
	public boolean isPasswordConfirmed() {
		if (newPassword == null || confirmPassword == null) {
			return false;
		}
		return newPassword.equals(confirmPassword);
	}

	public String getToken() {
		return token;
	}

	public void setToken(String token) {
		this.token = token;
	}

	public String getNewPassword() {
		return newPassword;
	}

	public void setNewPassword(String newPassword) {
		this.newPassword = newPassword;
	}

	public String getConfirmPassword() {
		return confirmPassword;
	}

	public void setConfirmPassword(String confirmPassword) {
		this.confirmPassword = confirmPassword;
	}
}
