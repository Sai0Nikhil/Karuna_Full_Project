package com.karuna.payment;

public interface PaymentProvider {

	PaymentResponse process(PaymentRequest request);
}
