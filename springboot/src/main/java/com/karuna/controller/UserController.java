package com.karuna.controller;

import com.karuna.entity.User;
import com.karuna.repository.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/users")
public class UserController {

	private final UserRepository userRepository;

	public UserController(UserRepository userRepository) {
		this.userRepository = userRepository;
	}

	@GetMapping("/responders")
	public ResponseEntity<List<Map<String, Object>>> responders() {
		List<Map<String, Object>> responders = userRepository.findAll().stream()
				.filter(user -> isResponder(user.getRole()))
				.map(this::toSummary)
				.toList();
		return ResponseEntity.ok(responders);
	}

	private boolean isResponder(String role) {
		if (role == null) {
			return false;
		}
		String normalized = role.toUpperCase();
		return normalized.equals("NGO") || normalized.equals("VET") || normalized.equals("VOLUNTEER");
	}

	private Map<String, Object> toSummary(User user) {
		return Map.of(
				"id", user.getId(),
				"name", user.getName(),
				"email", user.getEmail(),
				"role", user.getRole()
		);
	}
}
