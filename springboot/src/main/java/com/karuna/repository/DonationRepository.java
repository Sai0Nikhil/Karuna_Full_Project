package com.karuna.repository;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import com.karuna.entity.Donation;
import com.karuna.entity.enums.DonationStatus;

@Repository
public interface DonationRepository extends JpaRepository<Donation, Long>, JpaSpecificationExecutor<Donation> {

	List<Donation> findByDonorId(Long donorId);

	Page<Donation> findByDonorId(Long donorId, Pageable pageable);

	List<Donation> findByRescueCaseId(Long rescueCaseId);

	List<Donation> findByStatus(DonationStatus status);

	Page<Donation> findByStatus(DonationStatus status, Pageable pageable);

	long countByStatus(DonationStatus status);

	BigDecimal sumAmountByStatus(DonationStatus status);

	java.util.Optional<Donation> findByPaymentReference(String paymentReference);

	long countByCreatedAtAfter(LocalDateTime createdAt);

	@Query("select d.currency as currency, count(d) as count, sum(d.amount) as total from Donation d group by d.currency")
	List<DonationCurrencyStat> aggregateByCurrency();

	@Query("select function('to_char', d.createdAt, 'YYYY-MM') as month, count(d) as count, sum(d.amount) as total from Donation d group by function('to_char', d.createdAt, 'YYYY-MM') order by month")
	List<DonationMonthCount> countByMonth();

	@Query("select rc.ngo.id as ngoId, rc.ngo.name as ngoName, count(d) as count, sum(d.amount) as total from Donation d join d.rescueCase rc where rc.ngo is not null group by rc.ngo.id, rc.ngo.name order by sum(d.amount) desc")
	List<DonationNgoCount> countByNgo();

	@Query("select coalesce(avg(d.amount), 0) from Donation d")
	BigDecimal findAverageAmount();

	@Query("select coalesce(max(d.amount), 0) from Donation d")
	BigDecimal findMaxAmount();
}
