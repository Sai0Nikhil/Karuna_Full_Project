package com.karuna.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.karuna.entity.Location;

@Repository
public interface LocationRepository extends JpaRepository<Location, Long> {

	List<Location> findByCity(String city);

	List<Location> findByState(String state);

	List<Location> findByCountry(String country);
}
