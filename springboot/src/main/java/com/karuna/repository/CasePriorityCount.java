package com.karuna.repository;

import java.math.BigDecimal;

public interface CasePriorityCount {

	com.karuna.entity.enums.PriorityLevel getPriority();

	long getCount();
}
