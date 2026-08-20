package com.karuna.controller;

import com.karuna.document.TriageFeedback;
import com.karuna.repository.mongo.TriageFeedbackRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.client.RestTemplate;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/admin")
@PreAuthorize("hasAnyRole('ADMIN','NGO')")
@Tag(name = "Admin Utilities", description = "Administrative tools, database triggers, and model training")
public class AdminController {

    private final TriageFeedbackRepository triageFeedbackRepository;

    public AdminController(TriageFeedbackRepository triageFeedbackRepository) {
        this.triageFeedbackRepository = triageFeedbackRepository;
    }

    @PostMapping("/ai/retrain")
    @Operation(summary = "Retrain the local triage model using MongoDB feedback logs")
    public ResponseEntity<Map<String, Object>> retrainModel() {
        List<TriageFeedback> feedbackLogs = triageFeedbackRepository.findAll();
        
        if (feedbackLogs.isEmpty()) {
            return ResponseEntity.ok(Map.of(
                "status", "ignored",
                "message", "No feedback logs found in MongoDB to train on. Model is still running on baseline data."
            ));
        }

        // Format logs for FastAPI payload
        List<Map<String, String>> payload = new ArrayList<>();
        for (TriageFeedback log : feedbackLogs) {
            Map<String, String> item = new HashMap<>();
            item.put("species", log.getSpecies());
            item.put("injury", log.getInjury());
            item.put("desc", log.getDesc());
            item.put("severity", log.getSeverity());
            payload.add(item);
        }

        RestTemplate restTemplate = new RestTemplate();
        
        // Try container name first, then host fallback
        String[] urls = {
            "http://ai-service:8000/retrain",
            "http://localhost:8000/retrain"
        };

        Map<String, Object> finalResponse = null;
        Exception lastException = null;

        for (String url : urls) {
            try {
                ResponseEntity<Map> response = restTemplate.postForEntity(url, payload, Map.class);
                if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                    finalResponse = (Map<String, Object>) response.getBody();
                    break;
                }
            } catch (Exception ex) {
                lastException = ex;
            }
        }

        if (finalResponse != null) {
            return ResponseEntity.ok(finalResponse);
        } else {
            return ResponseEntity.internalServerError().body(Map.of(
                "status", "error",
                "message", "Failed to connect to local AI service for training: " + 
                           (lastException != null ? lastException.getMessage() : "unknown error")
            ));
        }
    }
}
