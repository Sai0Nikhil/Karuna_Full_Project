package com.karuna.payment;

public record PaymentResponse(
		boolean success,
		String transactionId,
		String status,
		String message) {
}
