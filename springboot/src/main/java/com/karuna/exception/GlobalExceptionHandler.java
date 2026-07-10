package com.karuna.exception;

import java.util.LinkedHashMap;
import java.util.Map;

import org.slf4j.MDC;
import org.springframework.dao.DataAccessException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.AuthenticationException;
import org.springframework.validation.FieldError;
import org.springframework.web.HttpMediaTypeNotSupportedException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.MissingServletRequestParameterException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.context.request.ServletWebRequest;
import org.springframework.web.context.request.WebRequest;
import org.springframework.web.method.annotation.MethodArgumentTypeMismatchException;
import org.springframework.http.converter.HttpMessageNotReadableException;

import jakarta.validation.ConstraintViolationException;

@RestControllerAdvice
public class GlobalExceptionHandler {

	@ExceptionHandler(BusinessException.class)
	public ResponseEntity<ApiErrorResponse> handleBusinessException(BusinessException ex, WebRequest request) {
		return build(ex.getStatus(), ex.getCode(), ex.getMessage(), request);
	}

	@ExceptionHandler(MethodArgumentNotValidException.class)
	public ResponseEntity<ApiErrorResponse> handleValidation(MethodArgumentNotValidException ex, WebRequest request) {
		Map<String, String> errors = new LinkedHashMap<>();
		for (FieldError fieldError : ex.getBindingResult().getFieldErrors()) {
			errors.put(fieldError.getField(), fieldError.getDefaultMessage());
		}
		ApiErrorResponse response = ApiErrorResponse.of(
				HttpStatus.BAD_REQUEST,
				"VALIDATION_FAILED",
				"Request validation failed",
				path(request),
				traceId(),
				errors);
		return ResponseEntity.badRequest().body(response);
	}

	@ExceptionHandler(ConstraintViolationException.class)
	public ResponseEntity<ApiErrorResponse> handleConstraintViolation(ConstraintViolationException ex, WebRequest request) {
		Map<String, String> errors = new LinkedHashMap<>();
		ex.getConstraintViolations().forEach(violation ->
				errors.put(violation.getPropertyPath().toString(), violation.getMessage()));
		ApiErrorResponse response = ApiErrorResponse.of(
				HttpStatus.BAD_REQUEST,
				"VALIDATION_FAILED",
				"Request validation failed",
				path(request),
				traceId(),
				errors);
		return ResponseEntity.badRequest().body(response);
	}

	@ExceptionHandler({
			IllegalArgumentException.class,
			HttpMessageNotReadableException.class,
			MethodArgumentTypeMismatchException.class,
			MissingServletRequestParameterException.class
	})
	public ResponseEntity<ApiErrorResponse> handleBadRequest(Exception ex, WebRequest request) {
		return build(HttpStatus.BAD_REQUEST, "BAD_REQUEST", readableMessage(ex), request);
	}

	@ExceptionHandler(HttpRequestMethodNotSupportedException.class)
	public ResponseEntity<ApiErrorResponse> handleMethodNotAllowed(HttpRequestMethodNotSupportedException ex, WebRequest request) {
		return build(HttpStatus.METHOD_NOT_ALLOWED, "METHOD_NOT_ALLOWED", ex.getMessage(), request);
	}

	@ExceptionHandler(HttpMediaTypeNotSupportedException.class)
	public ResponseEntity<ApiErrorResponse> handleUnsupportedMediaType(HttpMediaTypeNotSupportedException ex, WebRequest request) {
		return build(HttpStatus.UNSUPPORTED_MEDIA_TYPE, "UNSUPPORTED_MEDIA_TYPE", ex.getMessage(), request);
	}

	@ExceptionHandler(AuthenticationException.class)
	public ResponseEntity<ApiErrorResponse> handleAuthentication(AuthenticationException ex, WebRequest request) {
		return build(HttpStatus.UNAUTHORIZED, "AUTHENTICATION_REQUIRED", readableMessage(ex), request);
	}

	@ExceptionHandler(AccessDeniedException.class)
	public ResponseEntity<ApiErrorResponse> handleAuthorization(AccessDeniedException ex, WebRequest request) {
		return build(HttpStatus.FORBIDDEN, "ACCESS_DENIED", readableMessage(ex), request);
	}

	@ExceptionHandler(DataIntegrityViolationException.class)
	public ResponseEntity<ApiErrorResponse> handleDataIntegrity(DataIntegrityViolationException ex, WebRequest request) {
		return build(HttpStatus.CONFLICT, "DATABASE_CONSTRAINT_VIOLATION", "Database constraint violation", request);
	}

	@ExceptionHandler(DataAccessException.class)
	public ResponseEntity<ApiErrorResponse> handleDataAccess(DataAccessException ex, WebRequest request) {
		return build(HttpStatus.SERVICE_UNAVAILABLE, "DATABASE_ERROR", "Database operation failed", request);
	}

	@ExceptionHandler(RuntimeException.class)
	public ResponseEntity<ApiErrorResponse> handleRuntime(RuntimeException ex, WebRequest request) {
		return build(HttpStatus.INTERNAL_SERVER_ERROR, "INTERNAL_SERVER_ERROR", "Unexpected server error", request);
	}

	private ResponseEntity<ApiErrorResponse> build(HttpStatus status, String code, String message, WebRequest request) {
		return ResponseEntity.status(status).body(ApiErrorResponse.of(status, code, message, path(request), traceId()));
	}

	private String path(WebRequest request) {
		if (request instanceof ServletWebRequest servletWebRequest) {
			return servletWebRequest.getRequest().getRequestURI();
		}
		return "";
	}

	private String traceId() {
		return MDC.get("traceId");
	}

	private String readableMessage(Exception ex) {
		String message = ex.getMessage();
		return message == null || message.isBlank() ? "Request could not be processed" : message;
	}
}
