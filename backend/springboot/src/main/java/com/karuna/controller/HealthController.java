package com.karuna.controller;

import java.util.Map;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.karuna.service.KarunaMemoryStore;

@RestController
@RequestMapping("/api")
public class HealthController {

	private final KarunaMemoryStore store;

	public HealthController(KarunaMemoryStore store) {
		this.store = store;
	}

	@GetMapping("/health")
	public ResponseEntity<Map<String, Object>> health() {
		Map<String, Object> health = store.healthSnapshot();
		health.put("localAiServiceEnabled", true);
		return ResponseEntity.ok(health);
	}
}
