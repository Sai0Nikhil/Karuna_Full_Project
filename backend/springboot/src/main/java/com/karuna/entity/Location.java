package com.karuna.entity;

import java.math.BigDecimal;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.Table;
import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
@Entity
@Table(name = "locations")
public class Location extends BaseEntity {

	@NotBlank
	@Size(max = 255)
	@Column(nullable = false)
	private String label;

	@Size(max = 255)
	@Column(name = "address_line_1")
	private String addressLine1;

	@Size(max = 255)
	@Column(name = "address_line_2")
	private String addressLine2;

	@Size(max = 120)
	private String city;

	@Size(max = 120)
	private String state;

	@Size(max = 30)
	@Column(name = "postal_code")
	private String postalCode;

	@Size(max = 120)
	private String country = "India";

	@DecimalMin("-90.0")
	@DecimalMax("90.0")
	@Column(precision = 9, scale = 6)
	private BigDecimal latitude;

	@DecimalMin("-180.0")
	@DecimalMax("180.0")
	@Column(precision = 9, scale = 6)
	private BigDecimal longitude;
}
