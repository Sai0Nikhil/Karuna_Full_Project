package com.karuna.controller;

import com.karuna.service.KarunaMemoryStore;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.Map;

@RestController
@RequestMapping("/api/ai")
public class AIController {

	private final KarunaMemoryStore store;

	@Value("${karuna.ai.claude.key:}")
	private String claudeKey;

	@Value("${karuna.ai.gemini.key:}")
	private String geminiKey;

	public AIController(KarunaMemoryStore store) {
		this.store = store;
	}

	@GetMapping("/health")
	public ResponseEntity<Map<String, Object>> health() {
		Map<String, Object> health = store.healthSnapshot();
		health.put("claudeEnabled", claudeKey != null && !claudeKey.isBlank());
		health.put("geminiEnabled", geminiKey != null && !geminiKey.isBlank());
		return ResponseEntity.ok(health);
	}

	@PostMapping("/triage")
	public ResponseEntity<Map<String, Object>> triage(@RequestBody Map<String, Object> body) {
		return ResponseEntity.ok(store.triage(body));
	}
}
