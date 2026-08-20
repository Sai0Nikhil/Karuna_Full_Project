package com.karuna.document;

import java.time.LocalDateTime;
import java.util.Map;

import org.springframework.data.annotation.CreatedDate;
import org.springframework.data.annotation.Id;
import org.springframework.data.mongodb.core.index.Indexed;
import org.springframework.data.mongodb.core.mapping.Document;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Document(collection = "ai_predictions")
public class AiPrediction {

	@Id
	private String id;

	@Indexed
	private Long caseId;

	@Indexed
	private Long animalId;

	private String provider;
	private String model;
	private String predictionType;
	private Double confidenceScore;
	private Map<String, Object> inputMetadata;
	private Map<String, Object> output;

	@CreatedDate
	private LocalDateTime createdAt;
}
