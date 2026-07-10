package com.karuna.repository;

import java.math.BigDecimal;

public interface DonationNgoCount {

	Long getNgoId();

	String getNgoName();

	long getCount();

	BigDecimal getTotal();
}
