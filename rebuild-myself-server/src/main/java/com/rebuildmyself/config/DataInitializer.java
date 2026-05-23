package com.rebuildmyself.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.sql.Connection;
import java.sql.Statement;

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
            initReminderText();
        } catch (Exception e) {
            log.error("DataInitializer failed: {}", e.getMessage(), e);
        }
    }

    private void initReminderText() throws Exception {
        // Check if table already exists by trying a simple query
        try (Connection conn = dataSource.getConnection();
             Statement stmt = conn.createStatement()) {
            stmt.executeQuery("SELECT 1 FROM reminder_text LIMIT 1");
            log.info("reminder_text already exists, skip migration");
            return;
        } catch (Exception e) {
            log.info("reminder_text not found, creating... ({}: {})",
                e.getClass().getSimpleName(), e.getMessage());
        }

        // Read and execute migration SQL
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(
                    new ClassPathResource("db/migration_001_reminders.sql").getInputStream(),
                    StandardCharsets.UTF_8))) {
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
        log.info("reminder_text migration completed");
    }
}
