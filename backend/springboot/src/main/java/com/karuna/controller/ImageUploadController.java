package com.karuna.controller;

import com.karuna.document.ImageMetadata;
import com.karuna.repository.mongo.ImageMetadataRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/upload")
@Tag(name = "File Upload", description = "Image upload for animal rescue cases")
public class ImageUploadController {

    private final ImageMetadataRepository imageMetadataRepository;

    @Value("${karuna.upload.dir:uploads}")
    private String uploadDir;

    @Value("${karuna.upload.base-url:http://localhost:8081}")
    private String baseUrl;

    public ImageUploadController(ImageMetadataRepository imageMetadataRepository) {
        this.imageMetadataRepository = imageMetadataRepository;
    }

    @PostMapping("/image")
    @Operation(summary = "Upload a case image — returns the image URL")
    public ResponseEntity<Map<String, String>> uploadImage(
            @RequestParam("file") MultipartFile file) throws IOException {

        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body(Map.of("error", "File is empty"));
        }

        // Validate content type
        String contentType = file.getContentType();
        if (contentType == null || !contentType.startsWith("image/")) {
            return ResponseEntity.badRequest().body(Map.of("error", "Only image files are allowed"));
        }

        // Create upload directory
        Path dir = Paths.get(uploadDir);
        Files.createDirectories(dir);

        // Generate unique filename
        String ext = getExtension(file.getOriginalFilename());
        String filename = UUID.randomUUID() + ext;
        Path dest = dir.resolve(filename);
        file.transferTo(dest);

        String imageUrl = baseUrl + "/uploads/" + filename;

        // Save ImageMetadata log to MongoDB
        try {
            ImageMetadata metadata = new ImageMetadata();
            metadata.setOriginalFileName(file.getOriginalFilename());
            metadata.setContentType(contentType);
            metadata.setSizeBytes(file.getSize());
            metadata.setStorageKey(filename);
            metadata.setCreatedAt(java.time.LocalDateTime.now());
            imageMetadataRepository.save(metadata);
        } catch (Exception e) {
            System.err.println("Could not save ImageMetadata to MongoDB: " + e.getMessage());
        }

        return ResponseEntity.ok(Map.of(
            "imageUrl", imageUrl,
            "filename", filename
        ));
    }

    private String getExtension(String filename) {
        if (filename == null || !filename.contains(".")) return ".jpg";
        return filename.substring(filename.lastIndexOf('.'));
    }
}
