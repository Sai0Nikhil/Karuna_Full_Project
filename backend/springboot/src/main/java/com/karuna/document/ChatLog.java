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
@Document(collection = "chat_logs")
public class ChatLog {

	@Id
	private String id;

	@Indexed
	private Long userId;

	@Indexed
	private Long caseId;

	private String channel;
	private String direction;
	private String message;
	private Map<String, Object> metadata;

	@CreatedDate
	private LocalDateTime createdAt;
}
