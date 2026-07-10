package com.karuna.repository;

import java.util.Optional;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.karuna.entity.VerificationToken;
import com.karuna.entity.VerificationTokenType;

@Repository
public interface VerificationTokenRepository extends JpaRepository<VerificationToken, Long> {
	Optional<VerificationToken> findByTokenHash(String tokenHash);

	boolean existsByUserIdAndType(Long userId, VerificationTokenType type);

	java.util.List<VerificationToken> findByUserIdAndTypeAndUsedAtIsNullAndRevokedAtIsNull(
			Long userId,
			VerificationTokenType type);
}

