package com.karuna.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.EntityGraph;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import com.karuna.entity.RescueCase;
import com.karuna.entity.enums.CaseStatus;
import com.karuna.entity.enums.PriorityLevel;

@Repository
public interface CaseRepository extends JpaRepository<RescueCase, Long>, JpaSpecificationExecutor<RescueCase> {

	@EntityGraph(attributePaths = {"reporter", "animal", "ngo", "primaryVolunteer"})
	List<RescueCase> findByStatus(CaseStatus status);

	@EntityGraph(attributePaths = {"reporter", "animal", "ngo", "primaryVolunteer"})
	Page<RescueCase> findByStatus(CaseStatus status, Pageable pageable);

	@EntityGraph(attributePaths = {"reporter", "animal", "ngo", "primaryVolunteer"})
	List<RescueCase> findByReporterId(Long reporterId);

	@EntityGraph(attributePaths = {"reporter", "animal", "ngo", "primaryVolunteer"})
	Page<RescueCase> findByReporterId(Long reporterId, Pageable pageable);

	@EntityGraph(attributePaths = {"reporter", "animal", "ngo", "primaryVolunteer"})
	List<RescueCase> findByNgoId(Long ngoId);

	List<RescueCase> findByPriority(PriorityLevel priority);

	List<RescueCase> findByAnimalId(Long animalId);

	long countByStatus(CaseStatus status);

	long countByPrimaryVolunteerIdAndStatusNotIn(Long primaryVolunteerId, java.util.Collection<CaseStatus> statuses);

	long countByNgoId(Long ngoId);

	long countByPrimaryVolunteerId(Long primaryVolunteerId);

	long countByCreatedAtAfter(LocalDateTime createdAt);

	long countByPriority(PriorityLevel priority);

	@Query("select c.location as location, count(c) as count from RescueCase c where c.location is not null group by c.location")
	List<CaseLocationCount> countByLocation();

	@Query("select function('to_char', c.createdAt, 'YYYY-MM') as month, count(c) as count from RescueCase c group by function('to_char', c.createdAt, 'YYYY-MM') order by month")
	List<CaseMonthCount> countByMonth();

	@Query("select coalesce(avg(extract(epoch from c.updatedAt - c.createdAt)), 0) from RescueCase c where c.status in :statuses")
	Double findAverageResolutionSeconds(@Param("statuses") List<CaseStatus> statuses);

	@Query("select c.ngo.id as ngoId, c.ngo.name as ngoName, count(c) as count from RescueCase c where c.ngo is not null group by c.ngo.id, c.ngo.name order by count(c) desc")
	List<CaseNgoCount> findCaseCountsByNgo();

	@Query("select c.primaryVolunteer.id as volunteerId, count(c) as count from RescueCase c where c.primaryVolunteer is not null group by c.primaryVolunteer.id order by count(c) desc")
	List<CaseVolunteerCount> findCaseCountsByVolunteer();
}
