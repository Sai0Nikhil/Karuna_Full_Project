package com.karuna.repository.mongo;

import com.karuna.document.ApplicationLog;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ApplicationLogRepository extends MongoRepository<ApplicationLog, String> {
    List<ApplicationLog> findByLevel(String level);
}
