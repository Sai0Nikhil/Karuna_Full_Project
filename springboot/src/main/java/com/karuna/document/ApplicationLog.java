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
@Document(collection = "application_logs")
public class ApplicationLog {

	@Id
	private String id;

	@Indexed
	private String level;

	@Indexed
	private String loggerName;

	private String traceId;
	private String message;
	private String exceptionClass;
	private String stackTrace;
	private Map<String, Object> context;

	@CreatedDate
	private LocalDateTime createdAt;
}
