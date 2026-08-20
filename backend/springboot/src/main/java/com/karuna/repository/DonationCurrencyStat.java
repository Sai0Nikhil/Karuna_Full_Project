package com.karuna.repository;

import java.math.BigDecimal;

public interface DonationCurrencyStat {

	String getCurrency();

	Long getCount();

	BigDecimal getTotal();
}
