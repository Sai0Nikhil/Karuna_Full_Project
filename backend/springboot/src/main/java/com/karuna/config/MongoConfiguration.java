package com.karuna.config;


import org.bson.UuidRepresentation;
import org.springframework.boot.autoconfigure.mongo.MongoClientSettingsBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.config.EnableMongoAuditing;

@Configuration
@EnableMongoAuditing
public class MongoConfiguration {

	@Bean
	public MongoClientSettingsBuilderCustomizer mongoClientSettingsBuilderCustomizer() {
		return builder -> builder.uuidRepresentation(UuidRepresentation.STANDARD);
	}
}

