package com.karuna.repository;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.karuna.entity.AuditLog;

@Repository
public interface AuditLogRepository extends JpaRepository<AuditLog, Long> {

	List<AuditLog> findByActorId(String actorId);

	List<AuditLog> findByAction(String action);

	Page<AuditLog> findByAction(String action, Pageable pageable);

	Page<AuditLog> findByActorId(String actorId, Pageable pageable);
}
