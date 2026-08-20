package com.karuna.repository.mongo;

import com.karuna.document.TriageFeedback;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface TriageFeedbackRepository extends MongoRepository<TriageFeedback, String> {
}
