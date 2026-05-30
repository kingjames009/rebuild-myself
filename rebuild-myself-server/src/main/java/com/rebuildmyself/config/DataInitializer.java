package com.rebuildmyself.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.Resource;
import org.springframework.core.io.support.PathMatchingResourcePatternResolver;
import org.springframework.core.io.support.ResourcePatternResolver;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.Statement;
import java.util.Arrays;
import java.util.Comparator;

@Component
public class DataInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);
    private final DataSource dataSource;

    public DataInitializer(DataSource dataSource) {
        this.dataSource = dataSource;
    }

    @Override
    public void run(ApplicationArguments args) {
        try {
            runMigrations();
        } catch (Exception e) {
            log.error("DataInitializer failed: {}", e.getMessage(), e);
        }
    }

    private void runMigrations() throws Exception {
        ResourcePatternResolver resolver = new PathMatchingResourcePatternResolver();
        Resource[] resources = resolver.getResources("classpath:db/migration_*.sql");
        Arrays.sort(resources, Comparator.comparing(Resource::getFilename));

        if (resources.length == 0) {
            log.info("No migration SQL files found");
            return;
        }

        log.info("Found {} migration file(s)", resources.length);
        for (Resource resource : resources) {
            executeMigration(resource);
        }
    }

    private void executeMigration(Resource resource) throws Exception {
        String filename = resource.getFilename();
        log.info("Executing migration: {}", filename);

        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(resource.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                String trimmed = line.trim();
                if (trimmed.isEmpty() || trimmed.startsWith("--")) continue;
                sb.append(trimmed).append(' ');
            }
        }

        String[] statements = sb.toString().split(";");
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            for (String sql : statements) {
                String trimmed = sql.trim();
                if (trimmed.isEmpty()) continue;
                try {
                    stmt.execute(trimmed);
                } catch (Exception e) {
                    log.warn("SQL statement failed (may be ok): {} — SQL: {}...",
                        e.getMessage(), trimmed.substring(0, Math.min(80, trimmed.length())));
                }
            }
        }
        log.info("Migration {} completed", filename);
    }
}
