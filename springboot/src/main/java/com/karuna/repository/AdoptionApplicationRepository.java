package com.karuna.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.karuna.entity.AdoptionApplication;
import com.karuna.entity.enums.AdoptionStatus;

@Repository
public interface AdoptionApplicationRepository extends JpaRepository<AdoptionApplication, Long>, JpaSpecificationExecutor<AdoptionApplication> {

	List<AdoptionApplication> findByApplicantId(Long applicantId);

	List<AdoptionApplication> findByRescueCaseId(Long caseId);

	Page<AdoptionApplication> findByRescueCaseId(Long caseId, Pageable pageable);

	List<AdoptionApplication> findByStatus(AdoptionStatus status);

	Page<AdoptionApplication> findByApplicantId(Long applicantId, Pageable pageable);

	long countByStatus(AdoptionStatus status);

	long countByCreatedAtAfter(LocalDateTime createdAt);

	boolean existsByAnimalIdAndStatus(Long animalId, AdoptionStatus status);

	List<AdoptionApplication> findByApplicantIdAndAnimalIdAndStatusIn(Long applicantId, Long animalId, List<AdoptionStatus> statuses);

	long countByAnimalId(Long animalId);

	long countByRescueCaseId(Long caseId);

	@Query("select a.animal.id as animalId, count(ad) as count from AdoptionApplication ad join ad.animal a where a.id is not null group by a.id order by count(ad) desc")
	List<AdoptionAnimalCount> countByAnimal();

	@Query("select rc.ngo.id as ngoId, rc.ngo.name as ngoName, count(ad) as count from AdoptionApplication ad join ad.rescueCase rc where rc.ngo is not null group by rc.ngo.id, rc.ngo.name order by count(ad) desc")
	List<AdoptionNgoCount> countByNgo();
}
