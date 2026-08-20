package com.karuna.dto;

import jakarta.validation.constraints.AssertTrue;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class ChangePasswordRequestDTO {

	@NotBlank
	@Size(max = 128)
	private String currentPassword;

	@NotBlank
	@Size(min = 8, max = 128)
	private String newPassword;

	@NotBlank
	@Size(min = 8, max = 128)
	private String confirmPassword;

	@AssertTrue(message = "New password must differ from current password")
	public boolean isNewPasswordDifferent() {
		if (currentPassword == null || newPassword == null) {
			return true;
		}
		return !currentPassword.equals(newPassword);
	}

	@AssertTrue(message = "Passwords must match")
	public boolean isPasswordConfirmed() {
		if (newPassword == null || confirmPassword == null) {
			return false;
		}
		return newPassword.equals(confirmPassword);
	}

	public String getCurrentPassword() {
		return currentPassword;
	}

	public void setCurrentPassword(String currentPassword) {
		this.currentPassword = currentPassword;
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
