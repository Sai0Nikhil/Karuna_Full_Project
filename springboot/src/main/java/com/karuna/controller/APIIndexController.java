package com.karuna.controller;

import java.time.Instant;
import java.util.Map;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.http.HttpServletRequest;

import org.springframework.boot.web.servlet.error.ErrorController;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class APIIndexController implements ErrorController {

	@GetMapping({"/", "/api"})
	public Map<String, Object> index() {
		return Map.of(
				"service", "Karuna Spring Backend",
				"ok", true,
				"frontend", Map.of(
						"citizen", "http://localhost:3001",
						"ngo", "http://localhost:3002"
				),
				"endpoints", Map.of(
						"health", "/api/health",
						"auth", "/api/auth/login, /api/auth/register",
						"cases", "/api/cases, /api/cases/open, /api/cases/my",
						"donations", "/api/donations",
						"adoptions", "/api/adoptions",
						"ai", "/api/ai/triage",
						"openapi", "/v3/api-docs",
						"swaggerUi", "/swagger-ui.html",
						"websocket", "/ws"
				)
		);
	}

	@RequestMapping("/error")
	public ResponseEntity<Map<String, Object>> error(HttpServletRequest request) {
		Object statusValue = request.getAttribute(RequestDispatcher.ERROR_STATUS_CODE);
		int statusCode = statusValue == null ? 500 : Integer.parseInt(statusValue.toString());
		HttpStatus status = HttpStatus.resolve(statusCode);
		if (status == null) {
			status = HttpStatus.INTERNAL_SERVER_ERROR;
		}
		String path = String.valueOf(request.getAttribute(RequestDispatcher.ERROR_REQUEST_URI));
		return ResponseEntity.status(status).body(Map.of(
				"timestamp", Instant.now().toString(),
				"status", status.value(),
				"error", status.getReasonPhrase(),
				"path", path,
				"message", "No route is mapped for this path. Open /api for the backend index or use the React apps on ports 3001 and 3002."
		));
	}
}
