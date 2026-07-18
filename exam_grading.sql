-- =========================================================================
-- Exam Grading System - Database Schema
-- Fully Normalized Structure
-- Compatible with MySQL / MariaDB (XAMPP / phpMyAdmin)
-- =========================================================================

-- Disable foreign key checks during table creation/drops to avoid constraint errors
SET FOREIGN_KEY_CHECKS = 0;

-- =======================================================
-- Drop existing tables (in reverse order of dependencies)
-- =======================================================
DROP TABLE IF EXISTS `exams_detail`;
DROP TABLE IF EXISTS `results`;
DROP TABLE IF EXISTS `exam_answer_keys`;
DROP TABLE IF EXISTS `exams`;
DROP TABLE IF EXISTS `student_enrollments`;
DROP TABLE IF EXISTS `subjects_sec`;
DROP TABLE IF EXISTS `students`;
DROP TABLE IF EXISTS `subjects`;
DROP TABLE IF EXISTS `system_logs`;
DROP TABLE IF EXISTS `templates`;
DROP TABLE IF EXISTS `users`;

-- =======================================================
-- Level 0
-- =======================================================

-- 1. users (ข้อมูลผู้ใช้งาน)
CREATE TABLE `users` (
  `user_id` varchar(100) NOT NULL,
  `username` varchar(100) NOT NULL,
  `password` varchar(255) NOT NULL,
  `email` varchar(100) NOT NULL,
  `displayName` varchar(200) DEFAULT NULL,
  `photoURL` varchar(500) DEFAULT NULL,
  `role` varchar(20) DEFAULT 'user',
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 2. templates (รูปแบบกระดาษคำตอบ)
CREATE TABLE `templates` (
  `template_id` varchar(50) NOT NULL,
  `template_name` varchar(100) NOT NULL,
  `max_questions` int(11) NOT NULL,
  `image_path` varchar(255) DEFAULT NULL,
  `config_json` text DEFAULT NULL,
  PRIMARY KEY (`template_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =======================================================
-- Level 1
-- =======================================================

-- 3. system_logs (ประวัติการทำงานของระบบ)
CREATE TABLE `system_logs` (
  `log_id` varchar(50) NOT NULL,
  `action` varchar(255) NOT NULL,
  `displayName` varchar(200) DEFAULT NULL,
  `role` varchar(20) DEFAULT NULL,
  `action_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `user_id` varchar(100) DEFAULT NULL,
  PRIMARY KEY (`log_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 4. subjects (รายวิชา)
CREATE TABLE `subjects` (
  `subject_id` varchar(50) NOT NULL,
  `subject_name` varchar(200) NOT NULL,
  `semester` int(11) DEFAULT NULL,
  `year` int(11) DEFAULT NULL,
  `instructor` varchar(200) DEFAULT NULL,
  `user_id` varchar(100) NOT NULL,
  PRIMARY KEY (`subject_id`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 5. students (ทะเบียนประวัตินักเรียน)
CREATE TABLE `students` (
  `student_code` varchar(50) NOT NULL,
  `student_name` varchar(200) NOT NULL,
  `user_id` varchar(100) NOT NULL,
  PRIMARY KEY (`student_code`),
  FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =======================================================
-- Level 2
-- =======================================================

-- 6. subjects_sec (กลุ่มเรียน / เซกชัน)
CREATE TABLE `subjects_sec` (
  `section_id` int(11) NOT NULL AUTO_INCREMENT,
  `section_name` varchar(50) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `subject_id` varchar(50) NOT NULL,
  `user_id` varchar(100) NOT NULL,
  PRIMARY KEY (`section_id`),
  FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =======================================================
-- Level 3
-- =======================================================

-- 7. student_enrollments (การลงทะเบียนเรียนรายวิชาและเซกชัน)
CREATE TABLE `student_enrollments` (
  `enrollment_id` int(11) NOT NULL AUTO_INCREMENT,
  `student_code` varchar(50) NOT NULL,
  `subject_id` varchar(50) NOT NULL,
  `section_id` int(11) NOT NULL,
  `user_id` varchar(100) NOT NULL,
  PRIMARY KEY (`enrollment_id`),
  FOREIGN KEY (`student_code`) REFERENCES `students` (`student_code`) ON DELETE CASCADE,
  FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`) ON DELETE CASCADE,
  FOREIGN KEY (`section_id`) REFERENCES `subjects_sec` (`section_id`) ON DELETE CASCADE,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 8. exams (การสอบ)
CREATE TABLE `exams` (
  `exam_id` varchar(100) NOT NULL,
  `exam_name` varchar(200) NOT NULL,
  `questions` int(11) NOT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `subject_id` varchar(50) NOT NULL,
  `section_id` int(11) NOT NULL,
  `template_id` varchar(50) NOT NULL,
  `user_id` varchar(100) NOT NULL,
  PRIMARY KEY (`exam_id`),
  FOREIGN KEY (`subject_id`) REFERENCES `subjects` (`subject_id`) ON DELETE CASCADE,
  FOREIGN KEY (`section_id`) REFERENCES `subjects_sec` (`section_id`) ON DELETE CASCADE,
  FOREIGN KEY (`template_id`) REFERENCES `templates` (`template_id`) ON DELETE RESTRICT,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =======================================================
-- Level 4
-- =======================================================

-- 9. exam_answer_keys (เฉลยข้อสอบรายข้อ)
CREATE TABLE `exam_answer_keys` (
  `answer_key_id` int(11) NOT NULL AUTO_INCREMENT,
  `question_no` int(11) NOT NULL,
  `correct_answer` ENUM('A', 'B', 'C', 'D', 'E') NOT NULL,
  `exam_id` varchar(100) NOT NULL,
  PRIMARY KEY (`answer_key_id`),
  FOREIGN KEY (`exam_id`) REFERENCES `exams` (`exam_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- 10. results (คะแนนและภาพกระดาษคำตอบ)
CREATE TABLE `results` (
  `result_id` varchar(100) NOT NULL,
  `score` float NOT NULL,
  `total` int(11) NOT NULL,
  `percent` float NOT NULL,
  `flagged` tinyint(1) DEFAULT 0,
  `imageURL` varchar(500) DEFAULT NULL,
  `created_at` datetime DEFAULT CURRENT_TIMESTAMP,
  `exam_id` varchar(100) NOT NULL,
  `student_code` varchar(50) NOT NULL,
  `template_id` varchar(50) NOT NULL,
  `user_id` varchar(100) NOT NULL,
  PRIMARY KEY (`result_id`),
  FOREIGN KEY (`exam_id`) REFERENCES `exams` (`exam_id`) ON DELETE CASCADE,
  FOREIGN KEY (`student_code`) REFERENCES `students` (`student_code`) ON DELETE CASCADE,
  FOREIGN KEY (`template_id`) REFERENCES `templates` (`template_id`) ON DELETE RESTRICT,
  FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- =======================================================
-- Level 5
-- =======================================================

-- 11. exams_detail (สถิติตอบคำถามรายข้อของผู้เข้าสอบแต่ละคน)
CREATE TABLE `exams_detail` (
  `exam_detail_id` int(11) NOT NULL AUTO_INCREMENT,
  `question_no` int(11) NOT NULL,
  `correct_answer` ENUM('A', 'B', 'C', 'D', 'E') DEFAULT NULL,
  `student_answer` ENUM('A', 'B', 'C', 'D', 'E') DEFAULT NULL,
  `status_answer` varchar(20) DEFAULT NULL,
  `result_id` varchar(100) NOT NULL,
  PRIMARY KEY (`exam_detail_id`),
  FOREIGN KEY (`result_id`) REFERENCES `results` (`result_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- Re-enable foreign key checks
SET FOREIGN_KEY_CHECKS = 1;
