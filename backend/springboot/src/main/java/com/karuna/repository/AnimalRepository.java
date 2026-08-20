package com.karuna.repository;

import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.karuna.entity.Animal;
import com.karuna.entity.enums.AnimalCondition;
import com.karuna.entity.enums.AnimalSpecies;

@Repository
public interface AnimalRepository extends JpaRepository<Animal, Long>, JpaSpecificationExecutor<Animal> {

	Page<Animal> findBySpecies(AnimalSpecies species, Pageable pageable);

	Page<Animal> findByCondition(AnimalCondition condition, Pageable pageable);

	long countBySpecies(AnimalSpecies species);

	long countByCondition(AnimalCondition condition);

	long countByCreatedAtAfter(LocalDateTime createdAt);

	long countByRescueCasesIsNotEmpty();

	@Query("select rc.id as caseId, count(a) as count from Animal a join a.rescueCases rc group by rc.id order by count(a) desc")
	List<AnimalRescueCaseCount> countByRescueCase();

	@Query("select a.lastKnownLocation.city as location, count(a) as count from Animal a where a.lastKnownLocation is not null and a.lastKnownLocation.city is not null group by a.lastKnownLocation.city")
	List<AnimalLocationCount> countByLastKnownLocation();
}
