package com.karuna.dto;

import jakarta.validation.constraints.NotBlank;

public class GoogleAuthRequestDTO {

    @NotBlank
    private String idToken;

    private String role; // optional role for signup (defaults to CITIZEN)

    public String getIdToken() {
        return idToken;
    }

    public void setIdToken(String idToken) {
        this.idToken = idToken;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }
}
