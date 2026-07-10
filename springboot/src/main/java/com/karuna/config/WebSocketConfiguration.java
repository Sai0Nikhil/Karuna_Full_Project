package com.karuna.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistration;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;

@Configuration
@EnableWebSocket
public class WebSocketConfiguration implements WebSocketConfigurer {

	private final RealtimeWebSocketHandler realtimeWebSocketHandler;
	private final KarunaProperties properties;

	public WebSocketConfiguration(RealtimeWebSocketHandler realtimeWebSocketHandler, KarunaProperties properties) {
		this.realtimeWebSocketHandler = realtimeWebSocketHandler;
		this.properties = properties;
	}

	@Override
	public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
		KarunaProperties.WebSocket webSocket = properties.getWebSocket();
		WebSocketHandlerRegistration registration = registry.addHandler(realtimeWebSocketHandler, webSocket.getEndpoint());
		if (!webSocket.getAllowedOriginPatterns().isEmpty()) {
			registration.setAllowedOriginPatterns(webSocket.getAllowedOriginPatterns().toArray(String[]::new));
		} else if (!webSocket.getAllowedOrigins().isEmpty()) {
			registration.setAllowedOrigins(webSocket.getAllowedOrigins().toArray(String[]::new));
		}
	}
}
