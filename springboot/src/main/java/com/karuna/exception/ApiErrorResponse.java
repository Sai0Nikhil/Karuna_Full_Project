package com.karuna.exception;

import java.time.Instant;
import java.util.Map;

import org.springframework.http.HttpStatus;

import com.fasterxml.jackson.annotation.JsonInclude;

@JsonInclude(JsonInclude.Include.NON_EMPTY)
public record ApiErrorResponse(
		Instant timestamp,
		int status,
		String error,
		String code,
		String message,
		String path,
		String traceId,
		Map<String, String> validationErrors) {

	public static ApiErrorResponse of(HttpStatus status, String code, String message, String path, String traceId) {
		return of(status, code, message, path, traceId, Map.of());
	}

	public static ApiErrorResponse of(
			HttpStatus status,
			String code,
			String message,
			String path,
			String traceId,
			Map<String, String> validationErrors) {
		return new ApiErrorResponse(
				Instant.now(),
				status.value(),
				status.getReasonPhrase(),
				code,
				message,
				path,
				traceId,
				validationErrors == null ? Map.of() : validationErrors);
	}
}
