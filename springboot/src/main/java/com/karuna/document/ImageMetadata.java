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
@Document(collection = "image_metadata")
public class ImageMetadata {

	@Id
	private String id;

	@Indexed
	private Long caseId;

	@Indexed
	private Long animalId;

	private String originalFileName;
	private String contentType;
	private Long sizeBytes;
	private Integer width;
	private Integer height;
	private String checksum;
	private String storageKey;
	private Map<String, Object> labels;

	@CreatedDate
	private LocalDateTime createdAt;
}
