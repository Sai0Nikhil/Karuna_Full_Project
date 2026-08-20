package com.karuna.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.*;

@Service
public class VetDrugService {

    private static final String FDA_API_URL = "https://api.fda.gov/animalandveterinary/event.json";

    public List<Map<String, Object>> searchDrugs(String query) {
        if (query == null || query.isBlank()) {
            return Collections.emptyList();
        }

        List<Map<String, Object>> drugList = new ArrayList<>();
        try {
            // Encode search string to avoid HTTP request breaking
            String cleanQuery = query.trim().replace("\"", "");
            String searchParam = "drug.active_ingredients.name:\"" + cleanQuery + "\"" +
                    " OR drug.brand_name:\"" + cleanQuery + "\"";
            String url = FDA_API_URL + "?search=" + URLEncoder.encode(searchParam, StandardCharsets.UTF_8) + "&limit=15";

            RestTemplate restTemplate = new RestTemplate();
            ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                Map<String, Object> body = response.getBody();
                List<Map<String, Object>> results = (List<Map<String, Object>>) body.get("results");
                if (results != null) {
                    // Map to hold unique drugs found in the logs to prevent duplicates
                    Map<String, Map<String, Object>> uniqueDrugs = new LinkedHashMap<>();

                    for (Map<String, Object> event : results) {
                        List<Map<String, Object>> drugs = (List<Map<String, Object>>) event.get("drug");
                        List<Map<String, Object>> reactions = (List<Map<String, Object>>) event.get("reaction");

                        if (drugs == null) continue;

                        // Gather reactions list for this event
                        List<String> eventReactions = new ArrayList<>();
                        if (reactions != null) {
                            for (Map<String, Object> react : reactions) {
                                String term = (String) react.get("veddra_term_name");
                                if (term != null && !term.isBlank()) {
                                    eventReactions.add(term);
                                }
                            }
                        }

                        for (Map<String, Object> d : drugs) {
                            String brandName = (String) d.get("brand_name");
                            String dosageForm = (String) d.get("dosage_form");
                            String route = (String) d.get("route");

                            List<Map<String, Object>> ingredientsList = (List<Map<String, Object>>) d.get("active_ingredients");
                            String activeIngredient = "Unknown";
                            if (ingredientsList != null && !ingredientsList.isEmpty()) {
                                Map<String, Object> firstIngredient = ingredientsList.get(0);
                                activeIngredient = (String) firstIngredient.get("name");
                            }

                            String key = (brandName != null ? brandName.toUpperCase() : "") + "|" + activeIngredient.toUpperCase();
                            if (brandName == null || brandName.isBlank()) {
                                continue;
                            }

                            if (!uniqueDrugs.containsKey(key)) {
                                Map<String, Object> drugInfo = new HashMap<>();
                                drugInfo.put("brandName", brandName);
                                drugInfo.put("activeIngredient", activeIngredient);
                                drugInfo.put("dosageForm", dosageForm != null ? dosageForm : "N/A");
                                drugInfo.put("route", route != null ? route : "N/A");

                                Map<String, Object> manufacturer = (Map<String, Object>) d.get("manufacturer");
                                drugInfo.put("manufacturer", manufacturer != null ? manufacturer.get("name") : "Unknown");

                                Set<String> commonReactions = new LinkedHashSet<>(eventReactions);
                                drugInfo.put("commonReactions", commonReactions);

                                uniqueDrugs.put(key, drugInfo);
                            } else {
                                // Accumulate common reactions
                                Map<String, Object> existingDrug = uniqueDrugs.get(key);
                                Set<String> reactionsSet = (Set<String>) existingDrug.get("commonReactions");
                                if (reactionsSet != null) {
                                    reactionsSet.addAll(eventReactions);
                                }
                            }
                        }
                    }

                    // Convert to sorted list and cap reactions
                    for (Map<String, Object> drug : uniqueDrugs.values()) {
                        Set<String> reactionsSet = (Set<String>) drug.get("commonReactions");
                        List<String> reactionsList = new ArrayList<>(reactionsSet);
                        // Capping reactions to top 5 to keep the UI clean
                        drug.put("commonReactions", reactionsList.subList(0, Math.min(reactionsList.size(), 5)));
                        drugList.add(drug);
                    }
                }
            }
        } catch (Exception e) {
            System.err.println("Failed to query openFDA veterinary drug events: " + e.getMessage());
        }

        return drugList;
    }
}
