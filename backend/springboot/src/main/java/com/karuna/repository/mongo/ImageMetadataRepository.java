package com.karuna.repository.mongo;

import com.karuna.document.ImageMetadata;
import org.springframework.data.mongodb.repository.MongoRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ImageMetadataRepository extends MongoRepository<ImageMetadata, String> {
    Optional<ImageMetadata> findByCaseId(Long caseId);
}
