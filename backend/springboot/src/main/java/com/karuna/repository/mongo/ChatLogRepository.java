package com.karuna.repository.mongo;

import com.karuna.document.ChatLog;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ChatLogRepository extends MongoRepository<ChatLog, String> {
    List<ChatLog> findByUserId(Long userId);
    List<ChatLog> findByCaseId(Long caseId);
}
