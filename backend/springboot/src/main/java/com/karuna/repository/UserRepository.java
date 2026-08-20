package com.karuna.repository;

import java.util.Optional;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import com.karuna.entity.User;
import com.karuna.entity.enums.UserRole;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {

	Optional<User> findByEmail(String email);

	boolean existsByEmail(String email);

	boolean existsByPhoneNumber(String phoneNumber);

	Page<User> findByPrimaryRole(UserRole primaryRole, Pageable pageable);

	Page<User> findByActive(boolean active, Pageable pageable);
}
