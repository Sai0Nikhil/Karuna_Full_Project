package com.karuna.exception;

import org.springframework.http.HttpStatus;

public class AccountLockedException extends BusinessException {

	public AccountLockedException(String message) {
		super(HttpStatus.FORBIDDEN, "ACCOUNT_LOCKED", message);
	}
}
