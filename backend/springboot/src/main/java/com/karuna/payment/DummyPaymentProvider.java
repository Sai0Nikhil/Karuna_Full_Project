package com.karuna.payment;

import java.util.UUID;

import org.springframework.stereotype.Component;

@Component
public class DummyPaymentProvider implements PaymentProvider {

	@Override
	public PaymentResponse process(PaymentRequest request) {
		String transactionId = "DUMMY-" + UUID.randomUUID().toString().replace("-", "").substring(0, 24);
		return new PaymentResponse(true, transactionId, "PENDING", "Dummy payment provider (no real charge)");
	}
}
