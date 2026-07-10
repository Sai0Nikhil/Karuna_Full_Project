package com.karuna.repository;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.karuna.entity.Notification;
import com.karuna.entity.enums.NotificationStatus;
import com.karuna.entity.enums.NotificationType;

@Repository
public interface NotificationRepository extends JpaRepository<Notification, Long> {

	List<Notification> findByRecipientId(Long recipientId);

	List<Notification> findByRecipientIdAndStatus(Long recipientId, NotificationStatus status);

	List<Notification> findByType(NotificationType type);

	List<Notification> findByStatus(NotificationStatus status);

	Page<Notification> findByRecipientId(Long recipientId, Pageable pageable);

	long countByRecipientIdAndStatus(Long recipientId, NotificationStatus status);
}
