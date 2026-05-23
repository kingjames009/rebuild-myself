package com.rebuildmyself.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.ApplicationArguments;
import org.springframework.boot.ApplicationRunner;
import org.springframework.core.io.ClassPathResource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.nio.charset.StandardCharsets;
import java.util.List;

@Component
public class DataInitializer implements ApplicationRunner {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);
    private final JdbcTemplate jdbc;

    public DataInitializer(JdbcTemplate jdbc) {
        this.jdbc = jdbc;
    }

    @Override
    public void run(ApplicationArguments args) throws Exception {
        initReminderText();
    }

    private void initReminderText() {
        try {
            List<Integer> count = jdbc.queryForList(
                "SELECT 1 FROM information_schema.tables WHERE table_schema = DATABASE() AND table_name = 'reminder_text'",
                Integer.class);
            if (!count.isEmpty()) {
                log.info("reminder_text table already exists, skip migration");
                return;
            }

            String sql = new String(
                new ClassPathResource("db/migration_001_reminders.sql").getInputStream().readAllBytes(),
                StandardCharsets.UTF_8);
            String[] statements = sql.split(";");
            for (String stmt : statements) {
                String trimmed = stmt.trim();
                if (!trimmed.isEmpty() && !trimmed.startsWith("--")) {
                    jdbc.execute(trimmed);
                }
            }
            log.info("reminder_text table created and seeded successfully");
        } catch (Exception e) {
            log.warn("Failed to init reminder_text table (non-fatal): {}", e.getMessage());
        }
    }
}
