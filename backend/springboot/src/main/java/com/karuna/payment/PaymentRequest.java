package com.karuna.payment;

import java.math.BigDecimal;

public record PaymentRequest(
		BigDecimal amount,
		String currency,
		String provider,
		String reference,
		java.util.Map<String, String> metadata) {
}
