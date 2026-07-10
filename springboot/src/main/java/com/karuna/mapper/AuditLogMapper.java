package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

import com.karuna.dto.domain.AuditLogDto;
import com.karuna.entity.AuditLog;

@Mapper(config = DomainMapperConfig.class)
public interface AuditLogMapper {
	@Mapping(source = "actor.id", target = "actorUserId")
	AuditLogDto.Response toResponse(AuditLog auditLog);

	@Mapping(source = "actor.id", target = "actorUserId")
	AuditLogDto.Summary toSummary(AuditLog auditLog);

	AuditLog toEntity(AuditLogDto.Request request);
}
