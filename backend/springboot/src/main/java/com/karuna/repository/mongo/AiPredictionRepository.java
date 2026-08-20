package com.karuna.repository.mongo;

import com.karuna.document.AiPrediction;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface AiPredictionRepository extends MongoRepository<AiPrediction, String> {
    Optional<AiPrediction> findByCaseId(Long caseId);
}
