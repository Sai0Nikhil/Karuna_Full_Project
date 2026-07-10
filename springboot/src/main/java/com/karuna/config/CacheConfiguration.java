package com.karuna.config;


import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.concurrent.ConcurrentMapCacheManager;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
@EnableCaching
public class CacheConfiguration {

	@Bean
	public CacheManager cacheManager(KarunaProperties properties) {
		ConcurrentMapCacheManager cacheManager = new ConcurrentMapCacheManager();
		cacheManager.setAllowNullValues(false);
		if (!properties.getCache().getCacheNames().isEmpty()) {
			cacheManager.setCacheNames(properties.getCache().getCacheNames());
		}
		return cacheManager;
	}
}

