package com.karuna.service;

import java.io.IOException;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CopyOnWriteArraySet;

import org.springframework.stereotype.Service;
import org.springframework.web.socket.TextMessage;
import org.springframework.web.socket.WebSocketSession;

import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class RealtimeBroadcaster {

	private final ObjectMapper objectMapper;
	private final Set<WebSocketSession> sessions = new CopyOnWriteArraySet<>();

	public RealtimeBroadcaster(ObjectMapper objectMapper) {
		this.objectMapper = objectMapper;
	}

	public void register(WebSocketSession session) {
		sessions.add(session);
		send(session, helloEvent());
	}

	public void unregister(WebSocketSession session) {
		sessions.remove(session);
	}

	public void broadcast(String type, Long caseId, Object payload) {
		Map<String, Object> message = new LinkedHashMap<>();
		message.put("type", type);
		if (caseId != null) {
			message.put("caseId", String.valueOf(caseId));
		}
		if (payload != null) {
			message.put("payload", payload);
		}
		for (WebSocketSession session : sessions) {
			send(session, message);
		}
	}

	private Map<String, Object> helloEvent() {
		Map<String, Object> message = new LinkedHashMap<>();
		message.put("type", "hello");
		message.put("connections", sessions.size());
		return message;
	}

	private void send(WebSocketSession session, Map<String, Object> payload) {
		if (session == null || !session.isOpen()) {
			return;
		}
		try {
			session.sendMessage(new TextMessage(objectMapper.writeValueAsString(payload)));
		} catch (IOException ignored) {
			try {
				session.close();
			} catch (IOException ignoredClose) {
			}
		}
	}
}