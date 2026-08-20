package com.karuna.config;

import java.util.List;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.util.StringUtils;

import io.swagger.v3.oas.models.Components;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Contact;
import io.swagger.v3.oas.models.info.Info;
import io.swagger.v3.oas.models.info.License;
import io.swagger.v3.oas.models.security.SecurityRequirement;
import io.swagger.v3.oas.models.security.SecurityScheme;
import io.swagger.v3.oas.models.servers.Server;

@Configuration
public class OpenApiConfiguration {

	private static final String BEARER_AUTH = "bearerAuth";

	@Bean
	public OpenAPI karunaOpenApi(KarunaProperties properties) {
		KarunaProperties.OpenApi settings = properties.getOpenApi();
		OpenAPI openApi = new OpenAPI()
				.info(new Info()
						.title(settings.getTitle())
						.version(settings.getVersion())
						.description(settings.getDescription())
						.contact(new Contact().name(settings.getContactName()))
						.license(new License().name(settings.getLicenseName())));

		if (StringUtils.hasText(settings.getServerUrl())) {
			openApi.servers(List.of(new Server().url(settings.getServerUrl()).description("Configured API server")));
		}

		if (settings.isBearerAuthEnabled()) {
			openApi
					.components(new Components().addSecuritySchemes(BEARER_AUTH,
							new SecurityScheme()
									.name(BEARER_AUTH)
									.type(SecurityScheme.Type.HTTP)
									.scheme("bearer")
									.bearerFormat("JWT")))
					.addSecurityItem(new SecurityRequirement().addList(BEARER_AUTH));
		}

		return openApi;
	}
}
