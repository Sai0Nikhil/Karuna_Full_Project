package com.karuna.repository;

import java.math.BigDecimal;

public interface DonationMonthCount {

	String getMonth();

	long getCount();

	BigDecimal getTotal();
}
