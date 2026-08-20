package com.karuna.repository;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.karuna.entity.Treatment;
import com.karuna.entity.enums.TreatmentStatus;

@Repository
public interface TreatmentRepository extends JpaRepository<Treatment, Long> {

	List<Treatment> findByAnimalId(Long animalId);

	List<Treatment> findByRescueCaseId(Long rescueCaseId);

	List<Treatment> findByVeterinarianId(Long veterinarianId);

	List<Treatment> findByStatus(TreatmentStatus status);

	Page<Treatment> findByRescueCaseId(Long rescueCaseId, Pageable pageable);

	long countByStatus(TreatmentStatus status);
}
