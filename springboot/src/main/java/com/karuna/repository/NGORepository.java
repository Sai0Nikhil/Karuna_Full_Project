package com.karuna.repository;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.stereotype.Repository;

import com.karuna.entity.NGO;

@Repository
public interface NGORepository extends JpaRepository<NGO, Long>, JpaSpecificationExecutor<NGO> {

	Optional<NGO> findByRegistrationNumber(String registrationNumber);

	Optional<NGO> findByEmail(String email);

	Page<NGO> findByVerified(boolean verified, Pageable pageable);

	boolean existsByRegistrationNumber(String registrationNumber);

	long count();

	long countByVerifiedTrue();

	long countByActiveTrue();
}
