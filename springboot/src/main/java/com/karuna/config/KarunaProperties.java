package com.karuna.config;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.validation.annotation.Validated;

@Validated
@ConfigurationProperties(prefix = "karuna")
public class KarunaProperties {

	private final Cache cache = new Cache();
	private final Cors cors = new Cors();
	private final Jwt jwt = new Jwt();
	private final OpenApi openApi = new OpenApi();
	private final Security security = new Security();
	private final WebSocket webSocket = new WebSocket();
	private final Assignment assignment = new Assignment();

	public Cache getCache() {
		return cache;
	}

	public Cors getCors() {
		return cors;
	}

	public Jwt getJwt() {
		return jwt;
	}

	public OpenApi getOpenApi() {
		return openApi;
	}

	public Security getSecurity() {
		return security;
	}

	public WebSocket getWebSocket() {
		return webSocket;
	}

	public Assignment getAssignment() {
		return assignment;
	}

	public static class Cache {
		private List<String> cacheNames = new ArrayList<>();

		public List<String> getCacheNames() {
			return clean(cacheNames);
		}

		public void setCacheNames(List<String> cacheNames) {
			this.cacheNames = cacheNames;
		}
	}

	public static class Cors {
		private List<String> allowedOrigins = new ArrayList<>();
		private List<String> allowedOriginPatterns = new ArrayList<>();
		private List<String> allowedMethods = new ArrayList<>();
		private List<String> allowedHeaders = new ArrayList<>();
		private List<String> exposedHeaders = new ArrayList<>();
		private boolean allowCredentials;
		private long maxAge;

		public List<String> getAllowedOrigins() {
			return clean(allowedOrigins);
		}

		public void setAllowedOrigins(List<String> allowedOrigins) {
			this.allowedOrigins = allowedOrigins;
		}

		public List<String> getAllowedOriginPatterns() {
			return clean(allowedOriginPatterns);
		}

		public void setAllowedOriginPatterns(List<String> allowedOriginPatterns) {
			this.allowedOriginPatterns = allowedOriginPatterns;
		}

		public List<String> getAllowedMethods() {
			return clean(allowedMethods);
		}

		public void setAllowedMethods(List<String> allowedMethods) {
			this.allowedMethods = allowedMethods;
		}

		public List<String> getAllowedHeaders() {
			return clean(allowedHeaders);
		}

		public void setAllowedHeaders(List<String> allowedHeaders) {
			this.allowedHeaders = allowedHeaders;
		}

		public List<String> getExposedHeaders() {
			return clean(exposedHeaders);
		}

		public void setExposedHeaders(List<String> exposedHeaders) {
			this.exposedHeaders = exposedHeaders;
		}

		public boolean isAllowCredentials() {
			return allowCredentials;
		}

		public void setAllowCredentials(boolean allowCredentials) {
			this.allowCredentials = allowCredentials;
		}

		public long getMaxAge() {
			return maxAge;
		}

		public void setMaxAge(long maxAge) {
			this.maxAge = maxAge;
		}
	}

	public static class Jwt {
		private String secret;
		private Duration accessTokenExpiration = Duration.ofMinutes(15);
		private Duration refreshTokenExpiration = Duration.ofDays(7);
		private String issuer;
		private String audience;

		public String getSecret() {
			return secret;
		}

		public void setSecret(String secret) {
			this.secret = secret;
		}

		public Duration getAccessTokenExpiration() {
			return accessTokenExpiration;
		}

		public void setAccessTokenExpiration(Duration accessTokenExpiration) {
			this.accessTokenExpiration = accessTokenExpiration;
		}

		public Duration getRefreshTokenExpiration() {
			return refreshTokenExpiration;
		}

		public void setRefreshTokenExpiration(Duration refreshTokenExpiration) {
			this.refreshTokenExpiration = refreshTokenExpiration;
		}

		public String getIssuer() {
			return issuer;
		}

		public void setIssuer(String issuer) {
			this.issuer = issuer;
		}

		public String getAudience() {
			return audience;
		}

		public void setAudience(String audience) {
			this.audience = audience;
		}
	}

	public static class OpenApi {
		private String title;
		private String description;
		private String version;
		private String serverUrl;
		private String contactName;
		private String licenseName;
		private boolean bearerAuthEnabled;

		public String getTitle() {
			return title;
		}

		public void setTitle(String title) {
			this.title = title;
		}

		public String getDescription() {
			return description;
		}

		public void setDescription(String description) {
			this.description = description;
		}

		public String getVersion() {
			return version;
		}

		public void setVersion(String version) {
			this.version = version;
		}

		public String getServerUrl() {
			return serverUrl;
		}

		public void setServerUrl(String serverUrl) {
			this.serverUrl = serverUrl;
		}

		public String getContactName() {
			return contactName;
		}

		public void setContactName(String contactName) {
			this.contactName = contactName;
		}

		public String getLicenseName() {
			return licenseName;
		}

		public void setLicenseName(String licenseName) {
			this.licenseName = licenseName;
		}

		public boolean isBearerAuthEnabled() {
			return bearerAuthEnabled;
		}

		public void setBearerAuthEnabled(boolean bearerAuthEnabled) {
			this.bearerAuthEnabled = bearerAuthEnabled;
		}
	}

	public static class Security {
		private final Password password = new Password();
		private final Login login = new Login();
		private final Verification verification = new Verification();

		public Password getPassword() {
			return password;
		}

		public Login getLogin() {
			return login;
		}

		public Verification getVerification() {
			return verification;
		}

		public static class Password {
			private int minLength = 8;
			private int maxLength = 128;
			private boolean requireUppercase;
			private boolean requireLowercase;
			private boolean requireDigit;
			private boolean requireSpecialCharacter;

			public int getMinLength() {
				return minLength;
			}

			public void setMinLength(int minLength) {
				this.minLength = minLength;
			}

			public int getMaxLength() {
				return maxLength;
			}

			public void setMaxLength(int maxLength) {
				this.maxLength = maxLength;
			}

			public boolean isRequireUppercase() {
				return requireUppercase;
			}

			public void setRequireUppercase(boolean requireUppercase) {
				this.requireUppercase = requireUppercase;
			}

			public boolean isRequireLowercase() {
				return requireLowercase;
			}

			public void setRequireLowercase(boolean requireLowercase) {
				this.requireLowercase = requireLowercase;
			}

			public boolean isRequireDigit() {
				return requireDigit;
			}

			public void setRequireDigit(boolean requireDigit) {
				this.requireDigit = requireDigit;
			}

			public boolean isRequireSpecialCharacter() {
				return requireSpecialCharacter;
			}

			public void setRequireSpecialCharacter(boolean requireSpecialCharacter) {
				this.requireSpecialCharacter = requireSpecialCharacter;
			}
		}

		public static class Login {
			private int maxFailedAttempts = 5;
			private Duration lockDuration = Duration.ofMinutes(15);

			public int getMaxFailedAttempts() {
				return maxFailedAttempts;
			}

			public void setMaxFailedAttempts(int maxFailedAttempts) {
				this.maxFailedAttempts = maxFailedAttempts;
			}

			public Duration getLockDuration() {
				return lockDuration;
			}

			public void setLockDuration(Duration lockDuration) {
				this.lockDuration = lockDuration;
			}
		}

		public static class Verification {
			private Duration emailVerificationExpiration = Duration.ofHours(24);
			private Duration passwordResetExpiration = Duration.ofHours(1);

			public Duration getEmailVerificationExpiration() {
				return emailVerificationExpiration;
			}

			public void setEmailVerificationExpiration(Duration emailVerificationExpiration) {
				this.emailVerificationExpiration = emailVerificationExpiration;
			}

			public Duration getPasswordResetExpiration() {
				return passwordResetExpiration;
			}

			public void setPasswordResetExpiration(Duration passwordResetExpiration) {
				this.passwordResetExpiration = passwordResetExpiration;
			}
		}
	}

	public static class WebSocket {
		private String endpoint;
		private List<String> allowedOrigins = new ArrayList<>();
		private List<String> allowedOriginPatterns = new ArrayList<>();

		public String getEndpoint() {
			return endpoint;
		}

		public void setEndpoint(String endpoint) {
			this.endpoint = endpoint;
		}

		public List<String> getAllowedOrigins() {
			return clean(allowedOrigins);
		}

		public void setAllowedOrigins(List<String> allowedOrigins) {
			this.allowedOrigins = allowedOrigins;
		}

		public List<String> getAllowedOriginPatterns() {
			return clean(allowedOriginPatterns);
		}

		public void setAllowedOriginPatterns(List<String> allowedOriginPatterns) {
			this.allowedOriginPatterns = allowedOriginPatterns;
		}
	}

	public static class Assignment {
		private int maxActiveCases = 5;

		public int getMaxActiveCases() {
			return maxActiveCases;
		}

		public void setMaxActiveCases(int maxActiveCases) {
			this.maxActiveCases = maxActiveCases;
		}
	}

	private static List<String> clean(List<String> values) {
		if (values == null) {
			return List.of();
		}
		return values.stream()
				.map(value -> value == null ? "" : value.trim())
				.filter(value -> !value.isBlank())
				.toList();
	}
}
