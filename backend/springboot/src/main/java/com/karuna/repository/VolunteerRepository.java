package com.karuna.repository;

import java.util.List;
import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.karuna.entity.Volunteer;
import com.karuna.entity.enums.VolunteerStatus;

@Repository
public interface VolunteerRepository extends JpaRepository<Volunteer, Long>, JpaSpecificationExecutor<Volunteer> {

	Optional<Volunteer> findByUserId(Long userId);

	List<Volunteer> findByStatus(VolunteerStatus status);

	List<Volunteer> findByNgoId(Long ngoId);

	List<Volunteer> findByNgoIdAndStatus(Long ngoId, VolunteerStatus status);

	Page<Volunteer> findByStatus(VolunteerStatus status, Pageable pageable);

	boolean existsByUserId(Long userId);

	long countByStatus(VolunteerStatus status);

	long countByNgoIdAndStatus(Long ngoId, VolunteerStatus status);

	@Query("select coalesce(avg(size(v.primaryCases) + size(v.assignedCases)), 0) from Volunteer v where v.active = true")
	Double findAverageAssignedCases();

	@Query("select v.id as volunteerId, u.name as userName, size(v.primaryCases) + size(v.assignedCases) as caseCount from Volunteer v join v.user u where v.active = true group by v.id, u.name order by size(v.primaryCases) + size(v.assignedCases) desc")
	List<VolunteerCaseCount> findCaseCountsByVolunteer();
}
