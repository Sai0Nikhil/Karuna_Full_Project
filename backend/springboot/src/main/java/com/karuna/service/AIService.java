package com.karuna.service;

import com.karuna.entity.RescueCase;
import com.karuna.exception.ResourceNotFoundException;
import com.karuna.repository.CaseRepository;
import com.karuna.repository.mongo.AiPredictionRepository;
import com.karuna.repository.mongo.ChatLogRepository;
import com.karuna.document.AiPrediction;
import com.karuna.document.ChatLog;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.HttpEntity;

import java.util.List;
import java.util.Map;

/**
 * Hybrid AI Triage Service with MongoDB persistence.
 */
@Service
public class AIService {

    private final CaseRepository caseRepository;
    private final AiPredictionRepository aiPredictionRepository;
    private final ChatLogRepository chatLogRepository;

    public AIService(CaseRepository caseRepository,
                     AiPredictionRepository aiPredictionRepository,
                     ChatLogRepository chatLogRepository) {
        this.caseRepository = caseRepository;
        this.aiPredictionRepository = aiPredictionRepository;
        this.chatLogRepository = chatLogRepository;
    }

    // ─── Triage from text description ────────────────────────────────────────

    public Map<String, Object> analyzeText(String species, String injuryType,
                                           String description, String locationLabel) {
        String severity = classifySeverity(injuryType, description);
        String condition = buildCondition(species, injuryType, description);
        List<String> steps = firstAidSteps(species, injuryType, severity, "English");
        int cost = estimateCost(severity);

        Map<String, Object> result = Map.of(
            "severity", severity,
            "probableCondition", condition,
            "injuryType", injuryType != null ? injuryType : "unknown",
            "firstAidSteps", steps,
            "estimatedCostInr", cost,
            "aiSummary", "Rule-based triage (YOLOv8 fallback)",
            "confidence", "medium",
            "species", species != null ? species : "unknown"
        );

        // Save AI Prediction to MongoDB
        try {
            AiPrediction prediction = new AiPrediction();
            prediction.setProvider("rule-based");
            prediction.setModel("Triage-GB-V1");
            prediction.setPredictionType("text-triage");
            prediction.setConfidenceScore(0.85);
            prediction.setInputMetadata(Map.of("species", species != null ? species : "unknown", "injuryType", injuryType != null ? injuryType : "unknown"));
            prediction.setOutput(result);
            prediction.setCreatedAt(java.time.LocalDateTime.now());
            aiPredictionRepository.save(prediction);
        } catch (Exception e) {
            System.err.println("Could not save AI prediction to MongoDB: " + e.getMessage());
        }

        return result;
    }

    // ─── Triage from photo (calls local YOLOv8 Python service) ─────────────

    public Map<String, Object> analyzePhoto(String imageDataUrl, Double lat,
                                            Double lon, String description) {
        if (imageDataUrl == null || imageDataUrl.isBlank()) {
            return analyzeText("dog", "injury", description, null);
        }

        try {
            byte[] imageBytes;
            if (imageDataUrl.contains(",")) {
                // Base64 data URL: data:image/jpeg;base64,xxxx
                String base64Content = imageDataUrl.split(",")[1];
                imageBytes = java.util.Base64.getDecoder().decode(base64Content);
            } else {
                // Try decoding directly or fallback
                imageBytes = java.util.Base64.getDecoder().decode(imageDataUrl);
            }

            // Call Python FastAPI service
            return callPythonPredict(imageBytes, description);
        } catch (Exception e) {
            System.err.println("Failed to call Python YOLOv8 service: " + e.getMessage());
            String injuryType = extractInjuryFromDescription(description);
            return analyzeText("dog", injuryType, description, null);
        }
    }

    private Map<String, Object> callPythonPredict(byte[] imageBytes, String description) {
        RestTemplate restTemplate = new RestTemplate();
        // Fallback to container name if in docker, localhost if running locally
        String url = "http://ai-service:8000/predict";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.MULTIPART_FORM_DATA);

        LinkedMultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        
        ByteArrayResource fileResource = new ByteArrayResource(imageBytes) {
            @Override
            public String getFilename() {
                return "image.jpg";
            }
        };
        body.add("file", fileResource);
        
        if (description != null) {
            body.add("description", description);
        }

        HttpEntity<LinkedMultiValueMap<String, Object>> requestEntity = 
            new HttpEntity<>(body, headers);

        try {
            ResponseEntity<Map> response = restTemplate.postForEntity(url, requestEntity, Map.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map<String, Object> responseBody = (Map<String, Object>) response.getBody();
                
                // Save AI Prediction to MongoDB
                try {
                    AiPrediction prediction = new AiPrediction();
                    prediction.setProvider("yolov8-fastapi");
                    prediction.setModel("yolov8n-injury");
                    prediction.setPredictionType("photo-triage");
                    prediction.setConfidenceScore(0.92);
                    prediction.setInputMetadata(Map.of("hasDescription", description != null));
                    prediction.setOutput(responseBody);
                    prediction.setCreatedAt(java.time.LocalDateTime.now());
                    aiPredictionRepository.save(prediction);
                } catch (Exception mongoEx) {
                    System.err.println("Failed to log AI Prediction to MongoDB: " + mongoEx.getMessage());
                }

                return responseBody;
            }
        } catch (Exception e) {
            System.err.println("Error during rest call to python AI service: " + e.getMessage());
            // Try localhost if ai-service fails (local run outside Docker)
            try {
                ResponseEntity<Map> response = restTemplate.postForEntity("http://localhost:8000/predict", requestEntity, Map.class);
                if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                    Map<String, Object> responseBody = (Map<String, Object>) response.getBody();
                    
                    try {
                        AiPrediction prediction = new AiPrediction();
                        prediction.setProvider("yolov8-fastapi");
                        prediction.setModel("yolov8n-injury");
                        prediction.setPredictionType("photo-triage");
                        prediction.setConfidenceScore(0.92);
                        prediction.setInputMetadata(Map.of("hasDescription", description != null));
                        prediction.setOutput(responseBody);
                        prediction.setCreatedAt(java.time.LocalDateTime.now());
                        aiPredictionRepository.save(prediction);
                    } catch (Exception mongoEx) {
                        System.err.println("Failed to log AI Prediction to MongoDB: " + mongoEx.getMessage());
                    }

                    return responseBody;
                }
            } catch (Exception ex2) {
                System.err.println("Error during local fallback call to python AI service: " + ex2.getMessage());
            }
        }
        
        // Fallback
        String injuryType = extractInjuryFromDescription(description);
        return analyzeText("dog", injuryType, description, null);
    }

    // ─── First aid guidance ───────────────────────────────────────────────────

    public Map<String, Object> getFirstAid(String species, String injuryDescription,
                                           String locationContext, String language) {
        String desc = injuryDescription != null ? injuryDescription.toLowerCase() : "";
        Map<String, Object> result;

        if (desc.contains("give") || desc.contains("medicine") || desc.contains("pill") || 
            desc.contains("tablet") || desc.contains("dose") || desc.contains("administer") || 
            desc.contains("bun") || desc.contains("powder") || desc.contains("drug")) {
            
            result = Map.of(
                "immediateSteps", List.of(
                    "Hide it in food: Hiding tablets inside a small piece of bread bun, cheese, or peanut butter is the easiest method.",
                    "Powder/Crush it: Ask your vet if the tablet can be crushed. If yes, grind it into powder and mix it with a spoonful of wet food or water.",
                    "Syringe administration: For liquid suspensions, use a needleless plastic syringe slipped inside the side of the mouth behind the canine teeth.",
                    "Hold & Stroke: If giving directly, place the pill deep on the back of the tongue, hold the muzzle shut, and gently stroke the throat to trigger swallowing."
                ),
                "doNotDo", List.of(
                    "Do NOT force-feed tablets if the animal is highly panicked or aggressive to avoid bites.",
                    "Do NOT tilt the animal's head straight upwards when syringe-feeding, as they may aspirate liquid into their lungs.",
                    "Do NOT give human painkillers (like Tylenol or Advil) as they are highly toxic to dogs and cats."
                ),
                "whenToCallVet", "Call a vet immediately if you suspect accidental overdose or poison ingestion.",
                "estimatedWaitAdvice", "You can also search the official FDA Vet Drug Database directly in the Vet tab of our app."
            );
        } else {
            String injury = extractInjuryFromDescription(injuryDescription);
            String severity = classifySeverity(injury, injuryDescription);
            String lang = language != null ? language : "English";
            List<String> steps = firstAidSteps(species, injury, severity, lang);

            result = Map.of(
                "immediateSteps", steps,
                "doNotDo", doNotDo(species, injury),
                "whenToCallVet", "Call a vet immediately if animal is unconscious, bleeding heavily, or cannot move.",
                "estimatedWaitAdvice", "Keep the animal calm and shaded while waiting for help."
            );
        }

        // Save ChatLog to MongoDB
        try {
            ChatLog log = new ChatLog();
            log.setDirection("inbound_outbound");
            log.setChannel("sita_assistant");
            log.setMessage("User queried first aid. Species: " + species + ", InjuryDescription: " + injuryDescription);
            log.setMetadata(Map.of("response", result));
            log.setCreatedAt(java.time.LocalDateTime.now());
            chatLogRepository.save(log);
        } catch (Exception e) {
            System.err.println("Could not save ChatLog to MongoDB: " + e.getMessage());
        }

        return result;
    }

    // ─── Case summary for NGO dashboard ──────────────────────────────────────

    public Map<String, Object> getCaseSummary(Long caseId) {
        RescueCase rc = caseRepository.findById(caseId)
            .orElseThrow(() -> new ResourceNotFoundException("Case not found: " + caseId));

        String headline = (rc.getSpecies() != null ? capitalize(rc.getSpecies()) : "Animal")
            + " — " + (rc.getTitle() != null ? rc.getTitle() : "Rescue Case #" + caseId);
        String summary = buildSummaryText(rc);
        String urgency = urgencyNote(rc.getPriority());
        String progress = progressNote(rc.getCaseStatus());
        String next = recommendedNext(rc.getCaseStatus());

        return Map.of(
            "headline", headline,
            "summary", summary,
            "urgencyNote", urgency,
            "progressNote", progress,
            "recommendedNextStep", next
        );
    }

    // ─── Rule-based helpers ───────────────────────────────────────────────────

    private String classifySeverity(String injuryType, String description) {
        String combined = ((injuryType != null ? injuryType : "") + " " +
            (description != null ? description : "")).toLowerCase();
        if (combined.contains("bleed") || combined.contains("critical") ||
            combined.contains("unconscious") || combined.contains("fracture") ||
            combined.contains("broken") || combined.contains("severe")) {
            return "critical";
        }
        if (combined.contains("wound") || combined.contains("limp") ||
            combined.contains("injury") || combined.contains("hurt") ||
            combined.contains("pain") || combined.contains("urgent")) {
            return "urgent";
        }
        return "routine";
    }

    private String extractInjuryFromDescription(String description) {
        if (description == null) return "injury";
        String d = description.toLowerCase();
        if (d.contains("bleed")) return "bleeding";
        if (d.contains("fracture") || d.contains("broken") || d.contains("limp")) return "fracture";
        if (d.contains("wound")) return "wound";
        if (d.contains("emaciat") || d.contains("starv") || d.contains("weak")) return "emaciation";
        if (d.contains("eye")) return "eye_injury";
        return "injury";
    }

    private String buildCondition(String species, String injuryType, String description) {
        String s = species != null ? capitalize(species) : "Animal";
        String i = injuryType != null ? injuryType.replace("_", " ") : "injury";
        if (description != null && !description.isBlank()) {
            return s + " with " + i + ": " + description;
        }
        return s + " with " + i + " requiring veterinary attention";
    }

    private List<String> firstAidSteps(String species, String injuryType, String severity, String language) {
        String injury = injuryType != null ? injuryType.toLowerCase() : "injury";
        if (injury.contains("bleed")) {
            return List.of(
                "Stay calm and approach the animal slowly to avoid panic",
                "Apply gentle pressure with a clean cloth to the wound",
                "Do NOT remove any embedded objects",
                "Keep the animal warm and still",
                "Transport to a veterinarian immediately"
            );
        }
        if (injury.contains("fracture") || injury.contains("broken")) {
            return List.of(
                "Do NOT try to straighten or splint the limb yourself",
                "Support the animal gently without putting pressure on injured limb",
                "Keep the animal as still as possible",
                "Cover with a blanket to prevent shock",
                "Call a vet or NGO for safe transport"
            );
        }
        if (injury.contains("emaciat") || injury.contains("weak")) {
            return List.of(
                "Offer small amounts of water using a syringe or dropper",
                "Do NOT give solid food until vet clears it",
                "Keep the animal in a shaded, quiet place",
                "Monitor breathing and consciousness"
            );
        }
        // default
        return List.of(
            "Keep calm and avoid startling the animal",
            "Prevent the animal from moving unnecessarily",
            "Keep in a shaded, quiet area",
            "Contact a local NGO or veterinary clinic",
            "Monitor the animal until help arrives"
        );
    }

    private List<String> doNotDo(String species, String injuryType) {
        return List.of(
            "Do not force-feed the animal",
            "Do not apply antiseptic without vet guidance",
            "Do not leave the animal alone in traffic",
            "Do not attempt to remove embedded objects"
        );
    }

    private int estimateCost(String severity) {
        return switch (severity) {
            case "critical" -> 5000;
            case "urgent" -> 2500;
            default -> 1000;
        };
    }

    private String urgencyNote(com.karuna.entity.enums.PriorityLevel level) {
        if (level == null) return "Priority not set";
        return switch (level) {
            case CRITICAL -> "🔴 Critical — immediate intervention required";
            case HIGH, URGENT -> "🟡 Urgent — respond within 2 hours";
            default -> "🟢 Routine — respond within 24 hours";
        };
    }

    private String progressNote(com.karuna.entity.enums.CaseStatus status) {
        if (status == null) return "Status unknown";
        return switch (status) {
            case REPORTED -> "Case reported — awaiting assignment";
            case ASSIGNED -> "Volunteer assigned — en route";
            case COLLECTED -> "Animal collected — moving to clinic";
            case AT_CLINIC -> "At veterinary clinic";
            case IN_TREATMENT -> "Under active treatment";
            case DISCHARGED -> "Discharged — ready for adoption/release";
            default -> status.name();
        };
    }

    private String recommendedNext(com.karuna.entity.enums.CaseStatus status) {
        if (status == null) return "Assign a volunteer";
        return switch (status) {
            case REPORTED -> "Assign nearest available volunteer";
            case ASSIGNED -> "Confirm collection and update status";
            case COLLECTED -> "Update clinic arrival status";
            case AT_CLINIC -> "Begin treatment and document findings";
            case IN_TREATMENT -> "Update discharge date when ready";
            case DISCHARGED -> "List for adoption or arrange release";
            default -> "Update case status";
        };
    }

    public Map<String, Object> predictPain(Map<String, Object> body) {
        RestTemplate restTemplate = new RestTemplate();
        String url = "http://ai-service:8000/predict-pain";

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);

        HttpEntity<Map<String, Object>> requestEntity = new HttpEntity<>(body, headers);

        try {
            ResponseEntity<Map> response = restTemplate.postForEntity(url, requestEntity, Map.class);
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map<String, Object> responseBody = (Map<String, Object>) response.getBody();
                
                try {
                    AiPrediction prediction = new AiPrediction();
                    prediction.setProvider("pain-rf-v1");
                    prediction.setModel("RandomForest-Pain");
                    prediction.setPredictionType("pain-assessment");
                    prediction.setConfidenceScore(responseBody.get("confidence") != null ? Double.parseDouble(responseBody.get("confidence").toString()) : 0.89);
                    prediction.setInputMetadata(body);
                    prediction.setOutput(responseBody);
                    prediction.setCreatedAt(java.time.LocalDateTime.now());
                    aiPredictionRepository.save(prediction);
                } catch (Exception mongoEx) {
                    System.err.println("Could not save Pain prediction to MongoDB: " + mongoEx.getMessage());
                }
                
                return responseBody;
            }
        } catch (Exception e) {
            System.err.println("Failed to call Python Pain Index service: " + e.getMessage());
        }

        // Rule-based fallback if Python service is down
        int gcpsScore = 0;
        gcpsScore += body.get("gcps1") != null ? Integer.parseInt(body.get("gcps1").toString()) : 0;
        gcpsScore += body.get("gcps2") != null ? Integer.parseInt(body.get("gcps2").toString()) : 0;
        gcpsScore += body.get("gcps3") != null ? Integer.parseInt(body.get("gcps3").toString()) : 0;
        gcpsScore += body.get("gcps4") != null ? Integer.parseInt(body.get("gcps4").toString()) : 0;
        
        Double temp = body.get("temperature") != null ? Double.parseDouble(body.get("temperature").toString()) : 38.5;
        Double hr = body.get("heartRate") != null ? Double.parseDouble(body.get("heartRate").toString()) : 100.0;
        
        String level = "mild";
        if (gcpsScore >= 3 || temp > 39.5 || hr > 130) {
            level = "severe";
        } else if (gcpsScore >= 1 || temp > 39.0 || hr > 110) {
            level = "moderate";
        }
        
        String advice = "No immediate pain medication indicated. Monitor closely (Fallback).";
        if (level.equals("moderate")) {
            advice = "Moderate pain detected. Keep the animal warm, calm, and consult a vet for mild pain management options (Fallback).";
        } else if (level.equals("severe")) {
            advice = "WARNING: Severe clinical pain detected. Administer direct animal analgesics under vet supervision immediately (Fallback)!";
        }

        return Map.of(
            "painLevel", level,
            "confidence", 0.64,
            "advice", advice,
            "parameters", Map.of("temperature", temp, "heartRate", hr)
        );
    }

    private String buildSummaryText(RescueCase rc) {
        StringBuilder sb = new StringBuilder();
        if (rc.getSpecies() != null) sb.append(capitalize(rc.getSpecies())).append(" ");
        if (rc.getInjuryType() != null) sb.append("with ").append(rc.getInjuryType()).append(" ");
        if (rc.getLocationLabel() != null) sb.append("at ").append(rc.getLocationLabel()).append(". ");
        if (rc.getProbableCondition() != null) sb.append(rc.getProbableCondition());
        if (sb.length() == 0) sb.append(rc.getTitle() != null ? rc.getTitle() : "Rescue case");
        return sb.toString().trim();
    }

    private String capitalize(String s) {
        if (s == null || s.isEmpty()) return s;
        return Character.toUpperCase(s.charAt(0)) + s.substring(1).toLowerCase();
    }
}
