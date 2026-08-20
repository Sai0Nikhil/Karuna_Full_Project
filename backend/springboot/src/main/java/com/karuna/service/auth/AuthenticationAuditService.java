package com.karuna.service.auth;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import com.karuna.entity.AuditLog;
import com.karuna.entity.User;
import com.karuna.repository.AuditLogRepository;

@Service
public class AuthenticationAuditService {

	public static final String ACTION_REGISTER = "AUTH_REGISTER";
	public static final String ACTION_LOGIN_SUCCESS = "AUTH_LOGIN_SUCCESS";
	public static final String ACTION_LOGIN_FAILURE = "AUTH_LOGIN_FAILURE";
	public static final String ACTION_REFRESH = "AUTH_REFRESH";
	public static final String ACTION_LOGOUT = "AUTH_LOGOUT";
	public static final String ACTION_PASSWORD_CHANGE = "AUTH_PASSWORD_CHANGE";
	public static final String ACTION_PASSWORD_RESET = "AUTH_PASSWORD_RESET";
	public static final String ACTION_PASSWORD_RESET_REQUEST = "AUTH_PASSWORD_RESET_REQUEST";
	public static final String ACTION_EMAIL_VERIFICATION = "AUTH_EMAIL_VERIFICATION";

	private static final String ENTITY_TYPE = "USER";

	private final AuditLogRepository auditLogRepository;

	public AuthenticationAuditService(AuditLogRepository auditLogRepository) {
		this.auditLogRepository = auditLogRepository;
	}

	@Transactional
	public void registration(User user, ClientContext clientContext) {
		save(user, ACTION_REGISTER, null, clientContext);
	}

	@Transactional
	public void loginSuccess(User user, ClientContext clientContext) {
		save(user, ACTION_LOGIN_SUCCESS, null, clientContext);
	}

	@Transactional
	public void loginFailure(User user, ClientContext clientContext, String reason) {
		save(user, ACTION_LOGIN_FAILURE, reason, clientContext);
	}

	@Transactional
	public void refresh(User user, ClientContext clientContext) {
		save(user, ACTION_REFRESH, null, clientContext);
	}

	@Transactional
	public void logout(User user, ClientContext clientContext) {
		save(user, ACTION_LOGOUT, null, clientContext);
	}

	@Transactional
	public void passwordChange(User user, ClientContext clientContext) {
		save(user, ACTION_PASSWORD_CHANGE, null, clientContext);
	}

	@Transactional
	public void passwordReset(User user, ClientContext clientContext) {
		save(user, ACTION_PASSWORD_RESET, null, clientContext);
	}

	@Transactional
	public void passwordResetRequested(User user, ClientContext clientContext) {
		save(user, ACTION_PASSWORD_RESET_REQUEST, null, clientContext);
	}

	@Transactional
	public void emailVerification(User user, ClientContext clientContext) {
		save(user, ACTION_EMAIL_VERIFICATION, null, clientContext);
	}

	private void save(User actor, String action, String metadata, ClientContext clientContext) {
		AuditLog auditLog = new AuditLog();
		auditLog.setActor(actor);
		auditLog.setAction(action);
		auditLog.setEntityType(ENTITY_TYPE);
		auditLog.setEntityId(String.valueOf(actor.getId()));
		auditLog.setMetadata(metadata);
		if (clientContext != null) {
			auditLog.setIpAddress(clientContext.ipAddress());
			auditLog.setUserAgent(clientContext.userAgent());
		}
		auditLogRepository.save(auditLog);
	}
}
