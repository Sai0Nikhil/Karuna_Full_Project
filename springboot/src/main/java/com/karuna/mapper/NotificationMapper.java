package com.karuna.mapper;

import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.MappingTarget;

import com.karuna.dto.domain.NotificationDto;
import com.karuna.entity.Notification;

@Mapper(config = DomainMapperConfig.class)
public interface NotificationMapper {
	@Mapping(source = "recipient.id", target = "recipientId")
	NotificationDto.Response toResponse(Notification notification);

	@Mapping(source = "recipient.id", target = "recipientId")
	NotificationDto.Summary toSummary(Notification notification);

	Notification toEntity(NotificationDto.Request request);

	void updateEntity(NotificationDto.Update request, @MappingTarget Notification notification);
}
