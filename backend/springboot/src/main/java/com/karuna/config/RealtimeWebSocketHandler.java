package com.karuna.config;

import com.karuna.service.RealtimeBroadcaster;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;
import org.springframework.web.socket.handler.TextWebSocketHandler;

@Component
public class RealtimeWebSocketHandler extends TextWebSocketHandler {

	private final RealtimeBroadcaster broadcaster;

	public RealtimeWebSocketHandler(RealtimeBroadcaster broadcaster) {
		this.broadcaster = broadcaster;
	}

	@Override
	public void afterConnectionEstablished(WebSocketSession session) throws Exception {
		broadcaster.register(session);
	}

	@Override
	public void afterConnectionClosed(WebSocketSession session, org.springframework.web.socket.CloseStatus status) throws Exception {
		broadcaster.unregister(session);
	}

	@Override
	protected void handleTextMessage(WebSocketSession session, TextMessage message) {
		// Subscribe-only websocket.
	}
}