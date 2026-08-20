package com.karuna.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.karuna.entity.Veterinarian;

@Repository
public interface VeterinarianRepository extends JpaRepository<Veterinarian, Long>, JpaSpecificationExecutor<Veterinarian> {

	Optional<Veterinarian> findByUserId(Long userId);

	Optional<Veterinarian> findByLicenseNumber(String licenseNumber);

	boolean existsByLicenseNumber(String licenseNumber);

	long countByActiveTrue();

	@Query("select coalesce(avg(size(v.treatments)), 0) from Veterinarian v where v.active = true")
	Double findAverageCasesPerVeterinarian();

	@Query("select v.specialization as specialization, count(v) as count from Veterinarian v where v.active = true and v.specialization is not null group by v.specialization")
	List<VeterinarianSpecializationCount> countBySpecialization();

	@Query("select v.id as veterinarianId, v.specialization as specialization, size(v.treatments) as caseCount from Veterinarian v where v.active = true group by v.id, v.specialization order by size(v.treatments) desc")
	List<VeterinarianCaseCount> findCaseCountsByVeterinarian();
}
