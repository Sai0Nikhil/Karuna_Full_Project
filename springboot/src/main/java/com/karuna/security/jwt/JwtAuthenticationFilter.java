package com.karuna.security.jwt;

import java.io.IOException;

import org.springframework.lang.NonNull;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.karuna.security.auth.KarunaUserDetailsService;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

	private final JwtService jwtService;
	private final KarunaUserDetailsService userDetailsService;

	public JwtAuthenticationFilter(JwtService jwtService, KarunaUserDetailsService userDetailsService) {
		this.jwtService = jwtService;
		this.userDetailsService = userDetailsService;
	}

	@Override
	protected void doFilterInternal(
			@NonNull HttpServletRequest request,
			@NonNull HttpServletResponse response,
			@NonNull FilterChain filterChain) throws ServletException, IOException {
		jwtService.resolveBearerToken(request.getHeader("Authorization")).ifPresent(token -> {
			if (SecurityContextHolder.getContext().getAuthentication() != null) {
				return;
			}
			if (!jwtService.validateToken(token) || !jwtService.isAccessToken(token)) {
				return;
			}
			String email = jwtService.extractUsername(token).orElse(null);
			if (email == null) {
				return;
			}
			try {
				UserDetails userDetails = userDetailsService.loadUserByUsername(email);
				UsernamePasswordAuthenticationToken authentication = new UsernamePasswordAuthenticationToken(
						userDetails,
						null,
						userDetails.getAuthorities());
				authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
				SecurityContextHolder.getContext().setAuthentication(authentication);
			} catch (UsernameNotFoundException ignored) {
				SecurityContextHolder.clearContext();
			}
		});

		filterChain.doFilter(request, response);
	}
}
