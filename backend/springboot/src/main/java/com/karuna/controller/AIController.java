package com.karuna.controller;

import com.karuna.service.AIService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/ai")
@Tag(name = "AI Triage", description = "Rule-based triage engine (YOLOv8 in Phase 3)")
public class AIController {

    private final AIService aiService;

    public AIController(AIService aiService) {
        this.aiService = aiService;
    }

    /** Health check — indicates whether AI providers are configured */
    @GetMapping("/health")
    @Operation(summary = "AI service health status")
    public ResponseEntity<Map<String, Object>> health() {
        return ResponseEntity.ok(Map.of(
            "status", "ok",
            "provider", "rule-based",
            "yolov8Ready", false,
            "message", "Phase 1 rule-based triage active. YOLOv8 integration pending Phase 3."
        ));
    }

    /**
     * Analyze a case from text input (species + injury type + description).
     * Called by Flutter Report Flow step 2 (before photo upload).
     */
    @PostMapping("/analyze")
    @Operation(summary = "Text-based triage: species + injury type → severity + first aid")
    public ResponseEntity<Map<String, Object>> analyze(@RequestBody Map<String, Object> body) {
        String species = (String) body.getOrDefault("species", "dog");
        String injuryType = (String) body.getOrDefault("injuryType", "");
        String description = (String) body.getOrDefault("description", "");
        String locationLabel = (String) body.getOrDefault("locationLabel", "");
        return ResponseEntity.ok(aiService.analyzeText(species, injuryType, description, locationLabel));
    }

    /**
     * Analyze a photo (base64 or URL) for triage.
     * Phase 3: will call YOLOv8 Python service.
     */
    @PostMapping("/analyze-photo")
    @Operation(summary = "Photo-based triage (rule-based stub; YOLOv8 in Phase 3)")
    public ResponseEntity<Map<String, Object>> analyzePhoto(@RequestBody Map<String, Object> body) {
        String imageDataUrl = (String) body.getOrDefault("imageDataUrl", "");
        Double lat = body.get("lat") != null ? Double.parseDouble(body.get("lat").toString()) : null;
        Double lon = body.get("lon") != null ? Double.parseDouble(body.get("lon").toString()) : null;
        String description = (String) body.getOrDefault("description", "");
        return ResponseEntity.ok(aiService.analyzePhoto(imageDataUrl, lat, lon, description));
    }

    /**
     * First aid guidance endpoint — used by FirstAidScreen and Sita chatbot.
     */
    @PostMapping("/firstaid")
    @Operation(summary = "Get multilingual first aid steps for a species + injury scenario")
    public ResponseEntity<Map<String, Object>> firstAid(@RequestBody Map<String, Object> body) {
        String species = (String) body.getOrDefault("species", "dog");
        String injuryDescription = (String) body.getOrDefault("injuryDescription", "");
        String locationContext = (String) body.getOrDefault("locationContext", "");
        String language = (String) body.getOrDefault("language", "English");
        return ResponseEntity.ok(aiService.getFirstAid(species, injuryDescription, locationContext, language));
    }

    /**
     * AI-generated case summary for NGO dashboard.
     */
    @GetMapping("/summary/{caseId}")
    @Operation(summary = "Generate a case summary for NGO dashboard")
    public ResponseEntity<Map<String, Object>> summary(@PathVariable Long caseId) {
        return ResponseEntity.ok(aiService.getCaseSummary(caseId));
    }

    /**
     * Predict clinical pain severity level for an animal based on breed, weight, vitals, and GCPS checklist.
     */
    @PostMapping("/pain-index")
    @Operation(summary = "Canine clinical pain index evaluation based on vitals and GCPS scale")
    public ResponseEntity<Map<String, Object>> painIndex(@RequestBody Map<String, Object> body) {
        return ResponseEntity.ok(aiService.predictPain(body));
    }

    /**
     * Legacy triage endpoint (kept for backward compatibility).
     */
    @PostMapping("/triage")
    @Operation(summary = "Legacy triage endpoint (use /analyze instead)")
    public ResponseEntity<Map<String, Object>> triage(@RequestBody Map<String, Object> body) {
        return analyze(body);
    }
}
