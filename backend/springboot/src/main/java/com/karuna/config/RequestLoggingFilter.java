package com.karuna.config;


import java.io.IOException;
import java.util.Optional;
import java.util.UUID;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.slf4j.MDC;
import org.springframework.core.Ordered;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
@Order(Ordered.HIGHEST_PRECEDENCE)
public class RequestLoggingFilter extends OncePerRequestFilter {

	private static final Logger log = LoggerFactory.getLogger(RequestLoggingFilter.class);
	private static final String TRACE_ID = "traceId";

	@Override
	protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
			throws ServletException, IOException {
		long start = System.nanoTime();
		String traceId = Optional.ofNullable(request.getHeader("X-Request-Id"))
				.filter(value -> !value.isBlank())
				.orElseGet(() -> UUID.randomUUID().toString());
		MDC.put(TRACE_ID, traceId);
		response.setHeader("X-Request-Id", traceId);
		try {
			filterChain.doFilter(request, response);
		} finally {
			long durationMs = (System.nanoTime() - start) / 1_000_000;
			if (log.isInfoEnabled()) {
				log.atInfo()
						.addKeyValue("method", request.getMethod())
						.addKeyValue("path", request.getRequestURI())
						.addKeyValue("status", response.getStatus())
						.addKeyValue("durationMs", durationMs)
						.addKeyValue("remoteAddress", request.getRemoteAddr())
						.log("http_request_completed");
			}
			MDC.remove(TRACE_ID);
		}
	}
}

