-- Migration 003: Add preferred_segment to user_goal
-- Allows users to configure which time segment each goal should be scheduled in.
-- Values: '上班前', '午休', '下班后', or NULL (falls back to type-based default).
ALTER TABLE `user_goal`
    ADD COLUMN `preferred_segment` VARCHAR(20) DEFAULT NULL COMMENT '首选时段: 上班前/午休/下班后';
