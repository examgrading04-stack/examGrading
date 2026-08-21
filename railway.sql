/*
 Navicat Premium Dump SQL

 Source Server         : examGradingDB
 Source Server Type    : MySQL
 Source Server Version : 90400 (9.4.0)
 Source Host           : altaria.proxy.rlwy.net:18318
 Source Schema         : railway

 Target Server Type    : MySQL
 Target Server Version : 90400 (9.4.0)
 File Encoding         : 65001

 Date: 21/08/2026 15:48:28
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for exam_answer_keys
-- ----------------------------
DROP TABLE IF EXISTS `exam_answer_keys`;
CREATE TABLE `exam_answer_keys`  (
  `answer_key_id` int NOT NULL AUTO_INCREMENT,
  `question_no` int NOT NULL,
  `correct_answer` enum('A','B','C','D','E') CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `score` float NOT NULL DEFAULT 1,
  `exam_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`answer_key_id`, `user_id`) USING BTREE,
  INDEX `exam_answer_keys_ibfk_1`(`exam_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `exam_answer_keys_ibfk_2`(`user_id` ASC) USING BTREE,
  CONSTRAINT `exam_answer_keys_ibfk_1` FOREIGN KEY (`exam_id`, `user_id`) REFERENCES `exams` (`exam_id`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `exam_answer_keys_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 341 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of exam_answer_keys
-- ----------------------------
INSERT INTO `exam_answer_keys` VALUES (231, 1, 'E', 2, '1201111_1_Test', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (232, 2, 'D', 2, '1201111_1_Test', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (233, 3, 'C', 2, '1201111_1_Test', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (234, 4, 'B', 2, '1201111_1_Test', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (235, 5, 'A', 2, '1201111_1_Test', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (236, 6, 'E', 2, '1201111_1_Test', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (237, 7, 'D', 2, '1201111_1_Test', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (238, 8, 'C', 2, '1201111_1_Test', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (239, 9, 'B', 2, '1201111_1_Test', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (240, 10, 'A', 2, '1201111_1_Test', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (281, 1, 'B', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (282, 2, 'B', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (283, 3, 'B', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (284, 4, 'B', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (285, 5, 'C', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (286, 6, 'C', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (287, 7, 'C', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (288, 8, 'C', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (289, 9, 'A', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (290, 10, 'A', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (291, 11, 'A', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (292, 12, 'B', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (293, 13, 'C', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (294, 14, 'D', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (295, 15, 'E', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (296, 16, 'A', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (297, 17, 'B', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (298, 18, 'C', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (299, 19, 'D', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');
INSERT INTO `exam_answer_keys` VALUES (300, 20, 'E', 1, '1201413_1_Pro2', '66011211135@msu.ac.th');

-- ----------------------------
-- Table structure for exams
-- ----------------------------
DROP TABLE IF EXISTS `exams`;
CREATE TABLE `exams`  (
  `exam_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `exam_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `questions` int NOT NULL,
  `created_at` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `subject_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `section_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `template_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `is_custom_score` tinyint(1) NULL DEFAULT 0,
  `default_score` float NULL DEFAULT 1,
  `exam_date` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`exam_id`, `user_id`) USING BTREE,
  INDEX `exams_ibfk_1`(`subject_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `exams_ibfk_2`(`section_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `exams_ibfk_3`(`template_id` ASC) USING BTREE,
  INDEX `exams_ibfk_4`(`user_id` ASC) USING BTREE,
  CONSTRAINT `exams_fk_sec` FOREIGN KEY (`section_id`, `user_id`) REFERENCES `subjects_sec` (`section_id`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `exams_ibfk_1` FOREIGN KEY (`subject_id`, `user_id`) REFERENCES `subjects` (`subject_id`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `exams_ibfk_3` FOREIGN KEY (`template_id`) REFERENCES `templates` (`template_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `exams_ibfk_4` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of exams
-- ----------------------------
INSERT INTO `exams` VALUES ('1201111_1_Test', 'Test', 10, '2026-08-16 13:22:02', '1201111', '1201111_2', '30-A-E', '66011211135@msu.ac.th', 1, 2, NULL);
INSERT INTO `exams` VALUES ('1201111_1_test', 'test', 20, '2026-08-21 08:19:35', '1201111', '1201111_3', '30-A-E', 'ibossy2004@gmail.com', 0, 1, '2026-08-21');
INSERT INTO `exams` VALUES ('1201413_1_Pro2', 'Pro2', 20, '2026-08-16 16:40:48', '1201413', '1201413_1', '50-A-E', '66011211135@msu.ac.th', 0, 1, NULL);

-- ----------------------------
-- Table structure for exams_detail
-- ----------------------------
DROP TABLE IF EXISTS `exams_detail`;
CREATE TABLE `exams_detail`  (
  `exam_detail_id` int NOT NULL AUTO_INCREMENT,
  `question_no` int NOT NULL,
  `student_answer` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `status_answer` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `result_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`exam_detail_id`, `user_id`) USING BTREE,
  INDEX `exams_detail_ibfk_1`(`result_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `exams_detail_ibfk_2`(`user_id` ASC) USING BTREE,
  CONSTRAINT `exams_detail_ibfk_1` FOREIGN KEY (`result_id`, `user_id`) REFERENCES `results` (`result_id`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `exams_detail_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 983 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of exams_detail
-- ----------------------------
INSERT INTO `exams_detail` VALUES (736, 1, 'E', 'Correct', '2bfb9f9b324d4dbabfa742bb3b0a73db', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (737, 2, 'D', 'Correct', '2bfb9f9b324d4dbabfa742bb3b0a73db', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (738, 3, 'C', 'Correct', '2bfb9f9b324d4dbabfa742bb3b0a73db', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (739, 4, 'B', 'Correct', '2bfb9f9b324d4dbabfa742bb3b0a73db', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (740, 5, 'A', 'Correct', '2bfb9f9b324d4dbabfa742bb3b0a73db', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (741, 6, 'E', 'Correct', '2bfb9f9b324d4dbabfa742bb3b0a73db', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (742, 7, 'D', 'Correct', '2bfb9f9b324d4dbabfa742bb3b0a73db', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (743, 8, 'C', 'Correct', '2bfb9f9b324d4dbabfa742bb3b0a73db', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (744, 9, 'B', 'Correct', '2bfb9f9b324d4dbabfa742bb3b0a73db', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (745, 10, 'A', 'Correct', '2bfb9f9b324d4dbabfa742bb3b0a73db', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (746, 1, 'E', 'Correct', '4d380ded52cd482e9cfa84f65e59f761', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (747, 2, NULL, 'Correct', '4d380ded52cd482e9cfa84f65e59f761', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (748, 3, 'C', 'Correct', '4d380ded52cd482e9cfa84f65e59f761', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (749, 4, 'C', 'Correct', '4d380ded52cd482e9cfa84f65e59f761', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (750, 5, 'D', 'Correct', '4d380ded52cd482e9cfa84f65e59f761', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (751, 6, 'B', 'Correct', '4d380ded52cd482e9cfa84f65e59f761', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (752, 7, 'D', 'Correct', '4d380ded52cd482e9cfa84f65e59f761', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (753, 8, 'E', 'Correct', '4d380ded52cd482e9cfa84f65e59f761', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (754, 9, NULL, 'Correct', '4d380ded52cd482e9cfa84f65e59f761', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (755, 10, 'A', 'Correct', '4d380ded52cd482e9cfa84f65e59f761', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (766, 1, 'D', 'Correct', 'e7b3e47f3d074640b841d8889746aabe', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (767, 2, 'E', 'Correct', 'e7b3e47f3d074640b841d8889746aabe', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (768, 3, NULL, 'Correct', 'e7b3e47f3d074640b841d8889746aabe', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (769, 4, 'B', 'Correct', 'e7b3e47f3d074640b841d8889746aabe', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (770, 5, 'A', 'Correct', 'e7b3e47f3d074640b841d8889746aabe', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (771, 6, 'D', 'Correct', 'e7b3e47f3d074640b841d8889746aabe', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (772, 7, NULL, 'Correct', 'e7b3e47f3d074640b841d8889746aabe', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (773, 8, 'C', 'Correct', 'e7b3e47f3d074640b841d8889746aabe', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (774, 9, NULL, 'Correct', 'e7b3e47f3d074640b841d8889746aabe', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (775, 10, 'A', 'Correct', 'e7b3e47f3d074640b841d8889746aabe', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (806, 1, 'C', 'Correct', 'da6cd1ea3e3649c6a98d22ccdd416dab', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (807, 2, 'D', 'Correct', 'da6cd1ea3e3649c6a98d22ccdd416dab', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (808, 3, 'C', 'Correct', 'da6cd1ea3e3649c6a98d22ccdd416dab', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (809, 4, 'B', 'Correct', 'da6cd1ea3e3649c6a98d22ccdd416dab', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (810, 5, 'A', 'Correct', 'da6cd1ea3e3649c6a98d22ccdd416dab', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (811, 6, 'E', 'Correct', 'da6cd1ea3e3649c6a98d22ccdd416dab', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (812, 7, 'E', 'Correct', 'da6cd1ea3e3649c6a98d22ccdd416dab', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (813, 8, 'C', 'Correct', 'da6cd1ea3e3649c6a98d22ccdd416dab', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (814, 9, 'B', 'Correct', 'da6cd1ea3e3649c6a98d22ccdd416dab', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (815, 10, 'A', 'Correct', 'da6cd1ea3e3649c6a98d22ccdd416dab', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (816, 1, 'B', 'Correct', '276d678aa1014c03b7958ec80bd78570', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (817, 2, 'C', 'Correct', '276d678aa1014c03b7958ec80bd78570', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (818, 3, 'B', 'Correct', '276d678aa1014c03b7958ec80bd78570', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (819, 4, 'A', 'Correct', '276d678aa1014c03b7958ec80bd78570', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (820, 5, 'A', 'Correct', '276d678aa1014c03b7958ec80bd78570', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (821, 6, 'E', 'Correct', '276d678aa1014c03b7958ec80bd78570', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (822, 7, 'D', 'Correct', '276d678aa1014c03b7958ec80bd78570', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (823, 8, 'B', 'Correct', '276d678aa1014c03b7958ec80bd78570', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (824, 9, 'B', 'Correct', '276d678aa1014c03b7958ec80bd78570', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (825, 10, 'C', 'Correct', '276d678aa1014c03b7958ec80bd78570', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (826, 1, 'B', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (827, 2, 'C', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (828, 3, 'B', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (829, 4, 'A', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (830, 5, 'C', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (831, 6, 'C', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (832, 7, 'D', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (833, 8, 'C', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (834, 9, 'B', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (835, 10, 'A', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (836, 11, 'B', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (837, 12, 'B', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (838, 13, 'C', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (839, 14, 'D', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (840, 15, 'E', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (841, 16, 'A', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (842, 17, 'A', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (843, 18, 'B', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (844, 19, 'D', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (845, 20, 'E', 'Correct', 'fd5d9a86778041b7825783b578cb7d79', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (846, 1, 'B', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (847, 2, 'B', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (848, 3, 'B', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (849, 4, NULL, 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (850, 5, 'C', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (851, 6, 'C', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (852, 7, 'C', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (853, 8, 'A', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (854, 9, NULL, 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (855, 10, 'B', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (856, 11, 'A', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (857, 12, 'B', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (858, 13, 'B', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (859, 14, 'D', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (860, 15, 'E', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (861, 16, 'B', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (862, 17, 'B', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (863, 18, 'C', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (864, 19, 'D', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (865, 20, 'E', 'Correct', '61b07cfe887e4ebd815b4040302501c9', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (866, 1, 'B', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (867, 2, 'B', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (868, 3, 'B', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (869, 4, 'B', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (870, 5, 'C', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (871, 6, 'C', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (872, 7, 'C', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (873, 8, 'A', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (874, 9, 'A', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (875, 10, 'A', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (876, 11, 'A', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (877, 12, 'B', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (878, 13, 'C', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (879, 14, 'D', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (880, 15, 'E', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (881, 16, 'A', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (882, 17, 'B', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (883, 18, 'C', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (884, 19, 'D', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');
INSERT INTO `exams_detail` VALUES (885, 20, 'E', 'Correct', '38af93f4c0bb4b268c8a92543986bf0d', '66011211135@msu.ac.th');

-- ----------------------------
-- Table structure for results
-- ----------------------------
DROP TABLE IF EXISTS `results`;
CREATE TABLE `results`  (
  `result_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `score` float NOT NULL,
  `total` int NOT NULL,
  `percent` float NOT NULL,
  `flagged` tinyint(1) NULL DEFAULT 0,
  `imageURL` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `created_at` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `exam_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `student_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `template_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`result_id`, `user_id`) USING BTREE,
  INDEX `results_ibfk_1`(`exam_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `results_ibfk_2`(`student_code` ASC, `user_id` ASC) USING BTREE,
  INDEX `results_ibfk_3`(`template_id` ASC) USING BTREE,
  INDEX `results_ibfk_4`(`user_id` ASC) USING BTREE,
  CONSTRAINT `results_ibfk_1` FOREIGN KEY (`exam_id`, `user_id`) REFERENCES `exams` (`exam_id`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `results_ibfk_2` FOREIGN KEY (`student_code`, `user_id`) REFERENCES `students` (`student_code`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `results_ibfk_3` FOREIGN KEY (`template_id`) REFERENCES `templates` (`template_id`) ON DELETE RESTRICT ON UPDATE RESTRICT,
  CONSTRAINT `results_ibfk_4` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of results
-- ----------------------------
INSERT INTO `results` VALUES ('276d678aa1014c03b7958ec80bd78570', 8, 20, 40, 0, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786897021/mtljw5pkanwszrtrlwlb.jpg', '2026-08-16 16:17:03', '1201111_1_Test', '66011211004', '30-A-E', '66011211135@msu.ac.th');
INSERT INTO `results` VALUES ('2bfb9f9b324d4dbabfa742bb3b0a73db', 20, 20, 100, 0, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786895815/vql4vilo4qpynd6hlj0m.jpg', '2026-08-16 15:56:57', '1201111_1_Test', '66011211001', '30-A-E', '66011211135@msu.ac.th');
INSERT INTO `results` VALUES ('38af93f4c0bb4b268c8a92543986bf0d', 19, 20, 95, 0, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786945299/bqc7nxwwiimhiub7wo7z.jpg', '2026-08-17 05:41:41', '1201413_1_Pro2', '66011211003', '50-A-E', '66011211135@msu.ac.th');
INSERT INTO `results` VALUES ('4d380ded52cd482e9cfa84f65e59f761', 8, 20, 40, 1, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786895926/efnsldianoa5eusre2gb.jpg', '2026-08-16 15:58:49', '1201111_1_Test', '66011211002', '30-A-E', '66011211135@msu.ac.th');
INSERT INTO `results` VALUES ('61b07cfe887e4ebd815b4040302501c9', 14, 20, 70, 1, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786899782/gjomtygqxagz2wpgpz9q.jpg', '2026-08-16 17:03:05', '1201413_1_Pro2', '66011211002', '50-A-E', '66011211135@msu.ac.th');
INSERT INTO `results` VALUES ('da6cd1ea3e3649c6a98d22ccdd416dab', 16, 20, 80, 0, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786896417/qlnozvu3vleqzsxnkwwo.jpg', '2026-08-16 16:07:01', '1201111_1_Test', '66011211005', '30-A-E', '66011211135@msu.ac.th');
INSERT INTO `results` VALUES ('e7b3e47f3d074640b841d8889746aabe', 8, 20, 40, 1, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786896055/qff9maxgwplsr9nx9h3n.jpg', '2026-08-16 16:00:57', '1201111_1_Test', '66011211003', '30-A-E', '66011211135@msu.ac.th');
INSERT INTO `results` VALUES ('fd5d9a86778041b7825783b578cb7d79', 13, 20, 65, 0, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786899181/hmarthepv8mkgj8ipe14.jpg', '2026-08-16 16:53:03', '1201413_1_Pro2', '66011211001', '50-A-E', '66011211135@msu.ac.th');

-- ----------------------------
-- Table structure for student_enrollments
-- ----------------------------
DROP TABLE IF EXISTS `student_enrollments`;
CREATE TABLE `student_enrollments`  (
  `enrollment_id` int NOT NULL AUTO_INCREMENT,
  `student_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `subject_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `section_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`enrollment_id`, `user_id`) USING BTREE,
  INDEX `enrollments_ibfk_1`(`student_code` ASC, `user_id` ASC) USING BTREE,
  INDEX `enrollments_ibfk_2`(`subject_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `enrollments_ibfk_3`(`section_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `enrollments_ibfk_4`(`user_id` ASC) USING BTREE,
  CONSTRAINT `enrollments_ibfk_1` FOREIGN KEY (`student_code`, `user_id`) REFERENCES `students` (`student_code`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `enrollments_ibfk_2` FOREIGN KEY (`subject_id`, `user_id`) REFERENCES `subjects` (`subject_id`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `enrollments_ibfk_4` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `student_enrollments_fk_sec` FOREIGN KEY (`section_id`, `user_id`) REFERENCES `subjects_sec` (`section_id`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `student_enrollments_ibfk_2` FOREIGN KEY (`section_id`, `user_id`) REFERENCES `subjects_sec` (`section_id`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB AUTO_INCREMENT = 682 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of student_enrollments
-- ----------------------------
INSERT INTO `student_enrollments` VALUES (620, '66011211001', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (621, '66011211002', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (622, '66011211003', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (623, '66011211004', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (624, '66011211005', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (625, '66011211006', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (626, '66011211007', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (627, '66011211008', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (628, '66011211009', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (629, '66011211010', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (630, '66011211011', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (631, '66011211012', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (632, '66011211013', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (633, '66011211014', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (634, '66011211015', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (635, '66011211016', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (636, '66011211017', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (637, '66011211018', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (638, '66011211019', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (639, '66011211020', '1201413', '1201413_1', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (640, '66011211001', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (641, '66011211002', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (642, '66011211003', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (643, '66011211004', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (644, '66011211005', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (645, '66011211006', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (646, '66011211007', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (647, '66011211008', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (648, '66011211009', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (649, '66011211010', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (650, '66011211011', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (651, '66011211012', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (652, '66011211013', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (653, '66011211014', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (654, '66011211015', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (655, '66011211016', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (656, '66011211017', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (657, '66011211018', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (658, '66011211019', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (659, '66011211020', '1201111', '1201111_2', '66011211135@msu.ac.th');
INSERT INTO `student_enrollments` VALUES (681, '66011211035', '1201111', '1201111_3', 'ibossy2004@gmail.com');

-- ----------------------------
-- Table structure for students
-- ----------------------------
DROP TABLE IF EXISTS `students`;
CREATE TABLE `students`  (
  `student_code` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `student_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`student_code`, `user_id`) USING BTREE,
  INDEX `students_ibfk_1`(`user_id` ASC) USING BTREE,
  CONSTRAINT `students_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of students
-- ----------------------------
INSERT INTO `students` VALUES ('66011211001', 'นายณัฐวุฒิ พงษ์พานิช', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211002', 'นายนนทวัฒน์ มณีรัตน์', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211003', 'นายกฤษณะ บุญมี', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211004', 'นางสาวพิมพ์ชนก ลายงาม', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211005', 'นายชลทิศ วงศ์สุวรรณ', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211006', 'นายชยุต เจริญสุข', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211007', 'นางสาวรัตนาภรณ์ จิตต์มั่นคง', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211008', 'นางสาวพัชราภา แสงทอง', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211009', 'นางสาวณัฐธิดา พงษ์พานิช', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211010', 'นายชลทิศ พัฒนาดี', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211011', 'นายศุภกร รุ่งเรือง', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211012', 'นายธนพัฒน์ เลิศวิไล', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211013', 'นางสาวพิมพ์ชนก ทองนพคุณ', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211014', 'นายศุภวิชญ์ บุญมี', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211015', 'นางสาวอนัญญา พาณิชย์', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211016', 'นายพีรพล ทองมาก', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211017', 'นายภาณุพงศ์ บุญมี', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211018', 'นายชินวัฒน์ รุ่งเรือง', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211019', 'นางสาวศศิธร พาณิชย์', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211020', 'นายปุญญพัฒน์ เลิศวิไล', '66011211135@msu.ac.th');
INSERT INTO `students` VALUES ('66011211035', 'นายนลธชัย บุตรราช', 'ibossy2004@gmail.com');

-- ----------------------------
-- Table structure for subjects
-- ----------------------------
DROP TABLE IF EXISTS `subjects`;
CREATE TABLE `subjects`  (
  `subject_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `subject_name` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `semester` int NULL DEFAULT NULL,
  `year` int NULL DEFAULT NULL,
  `instructor` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`subject_id`, `user_id`) USING BTREE,
  INDEX `subjects_ibfk_1`(`user_id` ASC) USING BTREE,
  CONSTRAINT `subjects_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of subjects
-- ----------------------------
INSERT INTO `subjects` VALUES ('1201111', 'Java', 2, 2568, 'Supakrit', '66011211135@msu.ac.th');
INSERT INTO `subjects` VALUES ('1201111', 'introduction', 2, 2569, 'I am Boss', 'ibossy2004@gmail.com');
INSERT INTO `subjects` VALUES ('1201413', 'Intruduction', 1, 2569, 'I am Boss', '66011211135@msu.ac.th');

-- ----------------------------
-- Table structure for subjects_sec
-- ----------------------------
DROP TABLE IF EXISTS `subjects_sec`;
CREATE TABLE `subjects_sec`  (
  `section_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `section_name` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `created_at` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `subject_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`section_id`, `user_id`) USING BTREE,
  INDEX `subjects_sec_ibfk_1`(`subject_id` ASC, `user_id` ASC) USING BTREE,
  INDEX `subjects_sec_ibfk_2`(`user_id` ASC) USING BTREE,
  CONSTRAINT `subjects_sec_ibfk_1` FOREIGN KEY (`subject_id`, `user_id`) REFERENCES `subjects` (`subject_id`, `user_id`) ON DELETE CASCADE ON UPDATE RESTRICT,
  CONSTRAINT `subjects_sec_ibfk_2` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of subjects_sec
-- ----------------------------
INSERT INTO `subjects_sec` VALUES ('1201111_1', '1', '2026-08-16 09:39:28', '1201111', '66011211135@msu.ac.th');
INSERT INTO `subjects_sec` VALUES ('1201111_1', '1', '2026-08-21 08:18:16', '1201111', 'ibossy2004@gmail.com');
INSERT INTO `subjects_sec` VALUES ('1201111_2', '2', '2026-08-16 09:39:28', '1201111', '66011211135@msu.ac.th');
INSERT INTO `subjects_sec` VALUES ('1201111_2', '2', '2026-08-21 08:26:25', '1201111', 'ibossy2004@gmail.com');
INSERT INTO `subjects_sec` VALUES ('1201111_3', '3', '2026-08-16 09:39:28', '1201111', '66011211135@msu.ac.th');
INSERT INTO `subjects_sec` VALUES ('1201111_3', '3', '2026-08-21 08:28:29', '1201111', 'ibossy2004@gmail.com');
INSERT INTO `subjects_sec` VALUES ('1201111_4', '4', '2026-08-21 08:28:29', '1201111', 'ibossy2004@gmail.com');
INSERT INTO `subjects_sec` VALUES ('1201413_1', '1', '2026-08-17 10:12:08', '1201413', '66011211135@msu.ac.th');

-- ----------------------------
-- Table structure for system_logs
-- ----------------------------
DROP TABLE IF EXISTS `system_logs`;
CREATE TABLE `system_logs`  (
  `log_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `action` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `displayName` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `role` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `action_time` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  PRIMARY KEY (`log_id`, `user_id`) USING BTREE,
  INDEX `system_logs_ibfk_1`(`user_id` ASC) USING BTREE,
  CONSTRAINT `system_logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE RESTRICT
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of system_logs
-- ----------------------------
INSERT INTO `system_logs` VALUES ('001a95b7808d45009506f549bcb3eb24', 'User deleted students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0040422d32ea415aa2545ce7df614104', 'User deleted students/66011211009', 'Exam Grading', 'Teacher', '2026-08-17 05:55:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('005408a56cd94a46ad61a188aeb68488', 'User deleted students/66011211066', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('007cd8c194714a1fa88e64247ec5e888', 'User saved students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('00c08d98f1ee42dfbf8df082e2a32925', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:03:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('00d1b91d52e74b94b607a10aa121c39a', 'User deleted students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('00dd9b32fe7747f6a10cbcf997fb8c51', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:52:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('010d640be3654e2d8bd51912e76a0124', 'User saved students/66011211085', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('011769e6ae92441ea4cd10957d9f673b', 'แก้ไขข้อมูลผู้ใช้งาน: nonthachai.b04@gmail.com', NULL, NULL, '2026-08-17 06:10:07', '1');
INSERT INTO `system_logs` VALUES ('0134813745a24d1cbb059b98c15ee7f7', 'User deleted students/68011211064', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('013gn96auuo5l6zsqpuolboe', 'User deleted students/66011211', 'I am Boss', 'Teacher', '2026-08-18 16:29:22', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('0164aefd77dc4b8483069ccc58fa9481', 'User saved students/66011211087', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('017f96f96fd34aa1b5d642661138918b', 'User deleted subjects/1201111/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0180dbdeacd54d94a62ba8ab1a7d217c', 'User deleted students/68011211085', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0197be278a6949739d9fa678f578b39c', 'User saved students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('01a788b270024e18981a2f952e647d67', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('01b8528768fd4f14bce1f2af695c97a0', 'User deleted students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('01c437d8c31246a68dae20cb0305e0bf', 'User deleted students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('01e2cd5afcac45f79898dd5aa13ae955', 'User deleted students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0237238640504ee1bb6536c268d0d264', 'User deleted students/66011211068', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('024fbfd6a30c47da9c45c8e6e6abfdba', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:03:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0287a1087dab4597ba243d03a0473f5c', 'User deleted students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('02e3ffd48dc74c5387559fddd117e0e0', 'User deleted students/68011211080', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('02e51624c3444d84b745dc1bc3aeb347', 'User deleted students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('02f3bf043afe4882ad358ea2100f570f', 'User deleted students/67011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('02f5a8db14a444849faffd7acd41143a', 'User deleted students/66011211059', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('030aaec0b130406788822276a798b4e9', 'User deleted students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('03165fac7a8249c09221ed615b09af4e', 'User deleted students/68011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('03bc316e50cd4b04981492a93899942b', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('041d3661ecc04c2ab7bb6cec9b32a36d', 'User saved students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('043468d9cdde4462a13df5d246c16be1', 'User deleted students/68011211100', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('044eb72339404e329ac43b204132adcf', 'User deleted students/67011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0472a92dff514bf5b99c74500f8ff5cb', 'User deleted students/66011211018', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('0497c6d1ff1f4e1ba1ea443c298c7ddb', 'User saved students/66011211084', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('04a93467ec444a35846d9caa7b22a312', 'User deleted students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('04bd7a1c643147b9bab87da9ed0ee39a', 'User saved students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('04c39994e57241ec9a8a3aedab9ce691', 'User saved students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('04c7471d660c479ca32d0dee90276553', 'User saved students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('04cbad65569d4f8eae77db39472ae946', 'User deleted students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('04e55f6182d0476b831ca457112c9b1e', 'User deleted students/66011211076', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('050f82b6661a49708cb8d19dae4ecffb', 'User saved students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0557d837a31b4db1ac28057f018eebed', 'User saved students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('056257a6cdfa4217a575af674870c193', 'User deleted students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('056e06c9480047a9a3dfa3a576be4d24', 'User deleted students/68011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('057cccaa24374eb9918300d06fff2f14', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('05a0d0f39c6d47aeba5d64a1fb6f2482', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('05a76cef218d4cea87e731fb0d761746', 'User saved subjects/T111/sections/T111_1', 'Exam Grading', 'Teacher', '2026-08-17 06:20:06', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('05a7dd74512b4dda94f89bde4988b303', 'User saved students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('05e32449f1e24e809ba89a8ec4a30f2b', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0614919a559c465ba9a07dec8f276034', 'User deleted students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('066ca4baa86642d2990f3b5c05f7933c', 'User saved students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('06a7c654c34344cbb355bbda7f0c8697', 'User deleted students/66011211089', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('06bcd678aef0438996e2749258cd9a6d', 'User saved students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('06ec7d61f3364d1e97f4d11d1d5cac8f', 'User saved students/66011211096', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0756a5a254a44df8b51622458207e70e', 'User saved students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('075dcf0fc1fd44c6b7593227e2ee32eb', 'User saved students/66011211088', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('07695f21d46141889f77e0561ab4347f', 'User deleted students/66011211051', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('077743ac23fc4d5c8883d78d410eb1c1', 'User updated results/75fe2c46ab9c450d8235a7540ab5dc72', 'Exam Grading', 'Teacher', '2026-08-17 07:43:55', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('07d4915dd46a41169d606f45e0ad109b', 'User deleted students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('07ef20101ad444c3a52df8fe71a24c48', 'User deleted students/66011211018', 'Exam Grading', 'Teacher', '2026-08-17 05:55:26', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('0827113f18dc45eba209a645440759f8', 'User saved students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0832a72d85d14089b6fd20ef0a0c0e73', 'User saved subjects/1201111/sections/All Section', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('08549e401481475b832f75359b7750d4', 'User deleted students/66011211025', 'Exam Grading', 'Teacher', '2026-08-17 05:58:50', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('0868395700194f78a29e7e5e7bad977c', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:15:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0888b5722a914875a458d3cf74e3bdc1', 'User deleted students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('08b2b8508cda4ef9a64292c73b700bc3', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('08db58497d2f4c4e91dc6e4a00618927', 'User deleted students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('09263d2777244edf95a4b4fd7a4f10f5', 'User deleted students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('095844f527c142778fde8118b577317b', 'User deleted students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0967b28cdc354943aeda9eaa44a90b16', 'User deleted students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('09729467dd2d44869f8e34fbccc23f03', 'User saved students/66011211063', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('097983aa438b442db806e04698c04270', 'User deleted subjects/1201413/sections/4', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:26:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('097dad61e96e4d86aef2aecfea27f480', 'User saved students/66011211065', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0999bda190c54257987f973d1ded927e', 'User saved students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('09c440861aa44ef482d9eacf2129aa62', 'User deleted students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('09e33cc58bfe4299967174977fb949b6', 'User saved students/66011211052', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0a0f10e92ebb4eec8891890b8428a455', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0a712c86a8414c9cb7b6017fdbf73657', 'User deleted subjects/1201413/sections/4', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:11:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0a75d4bf99d440f481396a03da6abd0e', 'User saved students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0a86d28b3f754da2b138a38f1ddcb237', 'User deleted students/68011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0a8e8ee57a8b424baa20b4f371f8394c', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0a8fa9b086124724a9d8bae604e4d1e6', 'User saved subjects/1201111/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:28:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0aa9d12365a4491dbd6b063edc655a50', 'User deleted students/66011211062', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0ac1edb399594fd698e80d2b066ed0f4', 'User deleted students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0ad57ebea7314b3ba434134ba342b39e', 'User deleted students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0b3ee04920dc4278bac5d504ec7318b7', 'User deleted students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0b4715fa1ac242a8930ff367cc54c702', 'User deleted students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0b5739430cf94bb8bdfe72492be5150f', 'User saved students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0b75ef40c90f4c77b34753a600c7a837', 'User deleted students/68011211073', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0b84d47540dd4d76a1be3058b515243f', 'User deleted students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0b9eb7db9daa4e37bb880315db9cd008', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0bcb33f08b1b4c62ad793f5dcae62957', 'User deleted students/66011211047', 'Exam Grading', 'Teacher', '2026-08-17 05:59:54', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('0c4397545e114f158a19bf4252da73c4', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0c6f48a5652346b395b723627e39fd45', 'User deleted students/68011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0c798bddccf949e499f5f4cfda8d6e72', 'User deleted students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:48:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0cbb77af2b444877bd73b48131b59c0a', 'User saved students/66011211088', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0cea900a667c4960834eab779fde2785', 'User deleted students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0d06f6102d334f868849bff8082e1294', 'User saved subjects/1201413/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:28:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0d191316ebcc445c95915a92670aa02e', 'User deleted students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0d4d479021944973aa73c14899c5fad0', 'User deleted students/66011211073', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0d8ed383410b40f0ad04ad6aea560d89', 'User saved subjects/Project/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0da0a3aa462c4e098bae2eecba61c31e', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0da638b034254e7d9ab3ae96f72980c5', 'User deleted students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0dafdefe57d74907b38ef9b5805768c4', 'User saved students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0db8ea2c31ff450a964bbb7c0bbd27e3', 'User deleted students/67011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0e503bbe77e84e988ccd94fee72f095b', 'User deleted students/66011211070', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0e5bdda812ec4ff489a684d55d4809bc', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0e60048f442140bcab89a5780f3763c3', 'User saved students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0e7eaee266104e72b4ab6691ed27a19b', 'User deleted students/66011211068', 'Supakrit', 'Teacher', '2026-08-17 08:54:12', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('0e9ab870bf68467f87b808cffdc2bd72', 'User saved students/66011211053', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0e9ff3ff10004d38aa84b33fb89303d4', 'User saved students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0eaa9ce6871f4113819d78d8201769e5', 'User saved students/66011211052', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0ec9a97f67bc4bc0bba214f23288bdab', 'User saved students/66011211054', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0f5f8675a4914ab7b389ffbd8e58ee48', 'User saved students/66011211089', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0f8c112402b94fb1b0792b2ae8e47145', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0f9406d871c04cf48e9791d2e440da6c', 'User deleted students/68011211083', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('0k8jge6q13j8l476xwecaa', 'User updated exams/1201111_1_test', 'I am Boss', 'Teacher', '2026-08-21 08:29:10', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('101166374abc4c698b13e01213cf48bf', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('102393bf67574f48852fda195e06ebc6', 'User deleted students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1052f0a981ff49a0a5184e13e29fa459', 'User deleted students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('105511278c6d465db3a76893e2836dd0', 'User deleted subjects/1201111/sections/1201111_1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1065914fe4a04056a73236d8abfe1615', 'User deleted students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1093fe8bec74421f949a2fd7dc4a7f59', 'User deleted students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('10943832ae1e49778ebcfe208150d670', 'User saved students/66011211099', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('10a5b971031a4410a3c4c67f97843e57', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('10ae8f491de647e09413e62c6f653f14', 'User saved students/66011211060', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:23', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('10be0039348c492e952089b32dfeba8f', 'User saved students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('10c3cd02a3814e3c8a467c6931e1770e', 'User saved profiles/exam.grading04@gmail.com', 'Exam Grading', 'Teacher', '2026-08-17 08:00:57', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('1123833822884a1a830aae13473968a9', 'User deleted students/66011211051', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1140d5c01350402f9ae1dc697292fd71', 'User deleted students/66011211089', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('1141da61c7714680979cc6c825b48b34', 'User deleted students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('11730adc98084407b34a40dafba850d7', 'User saved students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1206b9329dd74666b30b282b0973f1d0', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1247c5cc9ecd4b83b84c0b510e619c41', 'User deleted students/68011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('125aceccc57d44ea8c1c8924f5dbaafc', 'User deleted students/66011211074', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('12996a4c4055431a86f6b94f07a91869', 'User saved students/66011211051', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('12b611110ff14166bcf1abbeed970eef', 'User deleted students/67011211080', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('12ec6a3813b34509aefc28dc64483147', 'User deleted students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1357d4a60c2747cea673cb054c5f5ad8', 'User saved students/66011211052', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('13821ed981ce4105abc9287f4f9d8a86', 'User deleted students/66011211012', 'Supakrit', 'Teacher', '2026-08-17 08:54:12', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('139fe65926254a8e9009befdc479c1e7', 'User saved students/66011211071', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('13afcaf80263416ab3a533b84ba893de', 'User deleted students/66011211054', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('13b7092d8124404180b42d97fdada04c', 'User saved students/66011211086', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('13c700bfbd9f435ca91c0d712ed6d389', 'User deleted students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1449d1c9504446bd81686398a18827b4', 'User saved students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1463ba28d53e495395be6d3062f1cfea', 'User deleted students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1495b3fdc4744367b9dd1d47bc55894e', 'User deleted students/68011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('149a8cd6f0bc48fdb650669821b94ac2', 'User saved students/66011211058', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('14da91720b254fe2941b3d4e0c842445', 'User deleted students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('14e60c55976542b886ed2f7fceddd694', 'User deleted students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('151806f8e0d447549824245e39e1c81b', 'User deleted students/67011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('15af9119c80546b9bfe158ff4bdec530', 'User deleted students/66011211095', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1618fe76f4bc42e18ded3782b98465b6', 'User saved students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:23', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('161cc0e493ca48668d98341d0655d525', 'User deleted students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('166c7667033f4db98b17061446998b10', 'User deleted subjects/1201413/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('166e6b3ba6f4470ea3b8d03eb9e1952a', 'User saved subjects/1201323/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:51:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('168d3e5634ec42a68f4e3bf276d78302', 'User deleted students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1697035c203c4781acaa7d2aa99cfea7', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('16a83ceff5024b519a4e166608812bdf', 'User deleted students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('16f075df5ffe45869e2040b6f2a07bd8', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('17303840e08f46d7ba7d305a3d556635', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('17307e0f5fd3430faf2adafdbde96e5a', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('17a0c4a2001649bd9b331cac55c76ed6', 'User deleted students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('17dbb6ed3af3401d86a7a1b54b3ddf97', 'User deleted students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('17e6d2c8dd964d9b91e6b30f3013e38f', 'User saved students/66011211082', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('17ec08c169ec4c96923c20ec1e8af6fb', 'User saved students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('17eddefa3fc44f84b16355b13771a911', 'User deleted students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('17f60582785a49eea0d96c0959e8214b', 'User deleted students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1841dbab5b6f4f78a5873dc72ca19b8f', 'User saved students/66011211067', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('18ac90b2f1a94378b40f7d8e50ee63fe', 'User deleted students/68011211076', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('18be57c21e29459687268cc29128dcc8', 'User deleted students/68011211071', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1903b5fb0ff64eee93c2e3e5a918fc0c', 'User deleted students/67011211096', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('190bfbffb6ff4aa98e030d64ee90b076', 'User deleted students/66011211072', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('191a25b34879410e8ddccbf342ffcadf', 'User deleted students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('193f48b1f6ed49e1999a8d5d354f744b', 'User deleted students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('194ddc4aadae4530b6a369e1ce6046cc', 'User deleted students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1957846e4e554138a97efdad6663cbe8', 'User saved students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1961f6c7954e46028b5f4e53c92e063e', 'User signed out', 'I am Boss', 'Teacher', '2026-08-17 07:17:24', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('19a37126bd9b476ba030d4c8542864c9', 'User deleted subjects/1201111/sections/5', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('19b985693ba34138904897586486fdd3', 'User saved students/66011211094', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('19cd819b6930467ea59f47d2e527472c', 'User deleted students/66011211061', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('19e0aa7355f6476d9f3594ef5271b163', 'User deleted students/68011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1a057e13892e477e9fb097227acb97ed', 'User saved students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1a2a05d67d704fb29f12c5eaa969c2e9', 'User deleted students/68011211093', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1a3dc8da22834fa487b498ec66b33d8c', 'User saved subjects/T111', 'Exam Grading', 'Teacher', '2026-08-17 06:19:21', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('1a653c83ec92418a953f319bb5afc0ff', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1a7337ac7a50441a8f064e2c3dc7f902', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1a74155359fb4574ba948e141e6ff933', 'User deleted students/67011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1a84a7bd6b304c98925434dd7b2719a3', 'User deleted students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1a923d1f4e8c40fd9e90ba4057c312f3', 'User deleted students/66011211092', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1acab3c581c74fe2bd4949be99e14d3a', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:52:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1acd579f1b234904a4a449f2e4bf72ea', 'User saved students/66011211064', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1af9d556830d4c3cb1b6f4759c618d1e', 'User saved subjects/1201413/sections/1201413_3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:02:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1b290ec1a7684b948dde6d4b962c7940', 'User deleted students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1b2b2fc8ae9c46cd81a17a417a42c4a8', 'User deleted students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1b46a2e206df4f87aa3b140c579d2ad5', 'User saved students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1b4a70daa56543f4853ce20f0045e9d6', 'User deleted students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1b7055b847d14fab8a9a5fed42c51672', 'User deleted students/66011211079', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1be54f15b60343d7962a05427b544031', 'User deleted students/66011211004', 'Exam Grading', 'Teacher', '2026-08-17 05:54:42', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('1c013a7d1afe4bcb974b08b71fa1dec9', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1c032bdf04be4999898ef8766acf0d88', 'User saved students/66011211081', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1c0591b143bc4fd58fb2dc4c5bf4fb45', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1c564dad25704a339c47527074338c0d', 'User deleted students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1c6142110b1c4933b80d3b56cd44bf94', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1c68f2c97a9d42ce860c625b84133ae6', 'User saved subjects/1201413/sections/8', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1c9054736fe84ac284201db315a5cb5e', 'User deleted students/66011211135', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:45:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1c9399d08f2248ddac691045402d68a8', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1c93d3195be04d2ba7e7c449eb342245', 'User deleted students/66011211082', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1cac9152920a4501abc49c0524182ff2', 'User saved students/66011211071', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1cd60432275b4a28ad27bffefd9646ec', 'User saved subjects/1201413/sections/10', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1cf005c9fe9149e28376028bfdf38838', 'User saved students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1cf8db5125484835b9c1b156785ee6e0', 'User deleted students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1d001894db4842aeaaec055f916a0565', 'User deleted students/66011211092', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1d22f80bc79e4487ac5f5c03c6c29d74', 'User deleted students/67011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1d423a79c79b4394a470d66ab3dc0091', 'User deleted students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1d4f5586b70f4a1c9822068e756c7434', 'User saved students/66011211070', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1d51c4f40d924b08930cd6a5db6d843e', 'User deleted students/66011211081', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1d90834277774a72973b68d12c1168da', 'User saved students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1e62cf61010f46a1a245905b09a464e3', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:08:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1e81a1e95e0543bbb730b391970500c5', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1e9d63df05a3447d8d161b4898658689', 'User deleted students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1eb258fc5ea04243a7ef40fcb572455c', 'User saved students/66011211077', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1f0bd9f146f14ca9b61d027fb2fff5e3', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1f1a07a151fc4286b46d2fe8921af738', 'User deleted students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1f232181bfe7436c9050ed050a2dd499', 'User deleted students/66011211135', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('1f7a033b08754b2abbacc5567f2cd16c', 'User deleted students/66011211078', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('1fe1e2ec24e04964bb23e726d10b2a27', 'User saved students/66011211012', 'Exam Grading', 'Teacher', '2026-08-17 06:22:27', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('202bdffcec624f86970c91d338e01d31', 'User deleted students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('20614ed3d129474fa5b990b9d107b690', 'User deleted students/68011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('208c094fe54448fa9d27243501738b63', 'User deleted students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('20b83e7335ec44f88607f0ee32294cca', 'User deleted students/66011211061', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('20d90f61755848bc94848ee5e737416d', 'User deleted students/66011211064', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('21395c03666c45ff992f0d5f53b625f4', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2149724e6a20445c84c8f45b70af0942', 'User saved students/66011211056', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('216825aa6eec4150931179406b81df53', 'User deleted subjects/1201213', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:51:56', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2169695b83384c1db4a2c7c13a1e3f63', 'User saved students/66011211001', 'Exam Grading', 'Teacher', '2026-08-17 06:27:16', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('21a5a638c37249d9ac7bc5a334d6726f', 'User saved students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('21a6fe438c6b475eb66f5b06f47f46f1', 'User deleted students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('21d8ee51ee3f477289032ef91af83567', 'User deleted students/67011211055', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('21e3978a7b014493b4a1ce0ff2d3afcb', 'User deleted students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('21e5503af2dc41e186708a6b92960a22', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2203dd4ae99542e0a774445613fc84c2', 'User updated exams/1201213_D3_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:18:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('22204f32a1b74d61a55ffd4a7b33df30', 'User deleted students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('222a004875fa461381da0066c42aeb42', 'User deleted students/67011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('224afb718b584ae4b084d2acfd44fa52', 'User saved subjects/1201413/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:54:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2265bb80fed84d8fbfa7ca16f6018d0a', 'User saved students/66011211067', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('22a8a8f1ff2243d69c3c3347d166050c', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('22c91a0ead974b9ca02e71ecb003b469', 'User deleted subjects/1201323', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:51:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('22eabc5a65434230b5ca9c07603e2acc', 'User deleted students/66011211071', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('22fe75ae532d441a8ac848878af5aa08', 'User saved students/66011211095', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2308f7781e4644ff85296d5b4000d4d6', 'User deleted students/66011217', 'I am Boss', 'Teacher', '2026-08-17 05:58:28', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('232cc9a2b24f469b902b373e891cff9e', 'User deleted students/66011211051', 'Exam Grading', 'Teacher', '2026-08-17 05:59:54', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('2332e032ebef42a7a38c69fa0eac2094', 'User saved subjects/1201111/sections/1201111_1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2346f459ed834981b94dde0ed3e605c2', 'User deleted students/66011211076', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('236832cdd6834ba49d3db324a49e7368', 'User deleted students/66011211010', 'Exam Grading', 'Teacher', '2026-08-17 05:55:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('2373606d4363413b984af0ef61d1f8bb', 'User saved students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('238030e6a8cb43e0ba3ff75d5522143f', 'User deleted students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('23a3131cda6e418ea75b84356d77281d', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('23e9bf8a2a904bb5be807868dda0799a', 'User saved students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:54', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('23fe99ef7be04b0b8562d6c9ba964b08', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('24bf996f7aa54fbb908024b56960f6d1', 'User deleted students/66011211066', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('24c2567c05a54307b8f9ae39f6b43a46', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('24f99ecf3e53489d9c0fa274fe969140', 'User deleted students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('252ad45a75e74d8588d4c42cac59b896', 'User deleted students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('259e873fc3bc4222be5f1edbbcc90fc9', 'User deleted students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('25ad3073e3f34bbab1661eb8e0f89c72', 'User saved students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('25b546a6ea3c47f88d6c7d06aad1f9dd', 'User deleted students/67011211075', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('25ee2d9f905c43739b8b03651d7c8e74', 'User deleted students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('26142ebd550a484fba41c120bf1b1d59', 'User deleted students/66011211028', 'Exam Grading', 'Teacher', '2026-08-17 05:58:49', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('264606425c9b4e019953ad78c69c617f', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2646b0ef78994361b36db5f5271754f8', 'User deleted students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2677c7c856824eaaae353fd106031582', 'User deleted students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('26947d066bc34aaabb01847091e2fa32', 'User deleted students/67011211084', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('26b27cda5e7648a7941c395029890e14', 'User saved students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('26d7bc88557444b5804b4f9034b5b4d5', 'User deleted students/67011211071', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('26dee423a8a040c6a77670595e02c41c', 'User deleted students/68011211062', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('26f9dcce76734d4ea715af4effb9b695', 'User saved students/66011211062', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('26fa40857dd7401c98352751a651ba31', 'User deleted students/67011211081', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('273b38a511544b8b8775e9b1c10d843d', 'User saved students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('27472aed932e429a849f8b49a105ea2d', 'User deleted students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('27576ef967894b1da790649b561d8a5b', 'User saved students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('277cfc47c9dc4c1585cc9550fd9856a3', 'User deleted students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2789507a466c455f9f0b977c7e0572a6', 'User saved students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('278f976ebb404bc6a896d850c3e48160', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('280b7681a33a499eb353eaea2f1c9f0b', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:23', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('281ceca5a6a14e3f9054e2eedd929e8f', 'User deleted students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('283aced60faa42ef86385bdec0bb0dc3', 'User deleted students/68011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('284a36f9b7cf4642bb03a4695900f2e0', 'User deleted students/66011211089', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('289543eb1e0a4493badc8afca3feaf4d', 'User deleted students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('289c236e4e56436297d788ff16cdeb22', 'User saved subjects/1201413/sections/1201413_2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:02:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('28b120476505449987bffbaf25157df1', 'User saved students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('28e10fc3dbb948e69681d4fe9bea0039', 'User deleted students/66011211065', 'Supakrit', 'Teacher', '2026-08-17 08:54:12', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('290ead3131614eb89e5a7d8b69a9c065', 'User deleted students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('291e9da9f73e436a9e9653e8621f092e', 'User deleted students/67011211098', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('292b3e515e5a4a2bab78de7317446b2a', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('295a627dbbd64af288914f2621397efd', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2974256eecee47c2baaefee39ba6408d', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2978948c7eaf4f59b02fb1db5a429898', 'User saved students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('29c9fa654b7c48f29d1b8bdb2e18f6da', 'User deleted students/66011211075', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('29d5cd92fec842eeaa3ddb9d283cb144', 'User deleted students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('29e2aab3428a4f57b4001ff7cd2c82ce', 'User deleted students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2a59683d18304a6fb854e1f7f46232a7', 'User deleted students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2a7e78bec70c457a80de6295ec73952d', 'User deleted students/67011211058', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2a87a9f277dd4a58b69b6b5051368c12', 'User deleted students/68011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2ac5159f3d344d7ba25ed9a8d65a9fe9', 'User saved students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2b1cff43d9a84a6380497462b89e99ea', 'User saved students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2b2f47b1e2704900b119c3520a0f11bd', 'User deleted students/67011211086', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2b48403ba4b64c23af58c51cb238904e', 'User deleted students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2b49d2cdec1a459a85dc95df88245b04', 'User deleted students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2b95407a71964077b68fef0b99f314dc', 'User deleted students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2bb1e0d9389c433dbda4c0be99332e35', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2c12a3874f0741438f9a81ce92992ad1', 'User deleted students/66011211054', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2c1cf2ffa6dd4b399c5646d080ad35d6', 'User saved subjects/1201111/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:57:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2c5ee79a97134967b15a4474ab403228', 'User saved students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2cb117f4f87147d492a6fce288757bd5', 'User deleted students/66011211030', 'Exam Grading', 'Teacher', '2026-08-17 05:58:50', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('2cbaad81207f404bb0d538eaaf39d394', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:23', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2cef6b056f99419baf7747e20d37cc11', 'User deleted students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2cf4fe5a065f44bb809b3f7d5938c262', 'User saved students/66011211135', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:45:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2d1ddb59a41d4314b2b54ddd9bfb3319', 'User deleted students/66011211065', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2d419586161f4b2fa7eca4f43bbcb7fb', 'User saved subjects/1201111/sections/5', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2d517538ac16490fa8dae88032269db9', 'User deleted students/68011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2d5f06fab67043fd86dceaf7e680a5b1', 'User deleted students/66011211091', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2df83be795204a4ea8efefc942ee7c45', 'User deleted students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2dfc1300fdfe4d77922fd27e8c59005b', 'User deleted students/66011211076', 'Supakrit', 'Teacher', '2026-08-17 08:54:08', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('2e283275101643dcbed40b46354b654e', 'User deleted students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2e2eac14161e479f9af19abc4bafb803', 'User deleted students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2e577268089142739356ebf14e9c365f', 'User deleted students/66011211011', 'Exam Grading', 'Teacher', '2026-08-17 05:55:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('2e6a96692eb14375a4b0f0472b00a44a', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2e7c938495244eef9dd5856ad5dfbc76', 'User deleted subjects/1201111/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2e882bb942e64704b0c0e0325f46d2fb', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2e9a0a9ca3334b739ef1a627afba5b40', 'User deleted students/66011211080', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2e9c6c1d01984a72ade550d744743e02', 'User deleted students/66011211049', 'Exam Grading', 'Teacher', '2026-08-17 05:59:54', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('2ec2f0917b9b4b7f88ddc5ac8d15ba28', 'User deleted students/66011211083', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2ee61b67e3b74eb9816f311df405ca1e', 'User saved students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:11', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2f6139c154cd4fb6b98d0e92d49adde0', 'User saved students/66011211083', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2fa4882165b5419da0348a7ec1f59609', 'User saved students/66011211091', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2fb1e139b7cb46329613ff0ad025b65b', 'User deleted students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2fc075242c2349d4ac145533a698f97b', 'User deleted students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2fc70b2791554b1a84adca15c9a8c9bd', 'User deleted students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('2r71f1qi0lqp9g59yqvg1', 'User saved students/66011211035', 'I am Boss', 'Teacher', '2026-08-21 08:18:51', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('30200cc1c6464158ab3c48915fd9684d', 'User deleted students/66011211056', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('302770e91e4e4192a50ccb3411e0fde4', 'User deleted students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('30308231aed34c088cfe9206e7d41d78', 'User saved students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('303fa42658ff42b782819747ce01a7bb', 'User deleted students/67011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('305ea3768da84de0b4958b53ba953b94', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('30779980d84146809505d525af24865f', 'User saved students/66011211071', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:23', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3077b250afcc4c849cee28666ab86cd9', 'User saved exams/1201213_D2_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:43:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('315be0de515041759e8ed8cbf1a711d8', 'User deleted students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('31875745b7544ea08a31557836747097', 'User saved students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('318d043eb576408cbe10c13b0fa13d06', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:54', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('31e59d450a564daa85bf219792c48c62', 'User deleted students/67011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('32463ffa8c0c47059a89a3e84020c6b0', 'User saved students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('32758ee628674fcf8c7d2ac218fa376b', 'User deleted students/68011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('32d2ee1d251c47f3a0958efe48bdc0d5', 'User deleted students/66011211035', 'Exam Grading', 'Teacher', '2026-08-17 05:59:23', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('32ebc531c0e6412fb1b9b0164d67eb97', 'User deleted students/66011211090', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('330adc6b654d4336bfd87b5de5df83e6', 'User deleted students/66011211098', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('331b4ef7c02b407ca7f4e99e7f4c5ae1', 'User deleted students/66011211093', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('3394dfeccaf248ad99fe13bf9768a200', 'User deleted students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('33a5f9237a3941548e0584d6784d501e', 'User deleted students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('33ea690ef04b466a9250655ca1bb48bf', 'User deleted students/66011211057', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('33eaf4d5db5f4ebeba4b1977017ecbf9', 'User deleted subjects/1201413/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:11:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('33f8da5d68cc4bdbb431ae9989842927', 'User deleted students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('33ffb56c576f41f194b8f5c0223f19cd', 'User deleted students/68011211074', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('340b26afcf154cf8a19f9149ab1a861e', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3415860fb4494725a19243cd079a5b79', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3417cb9572fa4420b22e6b1f03021223', 'User deleted students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('34249c07ee8a433eb0250913861ff87d', 'User deleted students/67011211094', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('342a057acad248669d901b38ea333427', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('346bfec13d3142f992ff6474510b9cdf', 'User deleted students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('348276bca3834ceba2dd9b02f1350b94', 'User deleted students/66011211094', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('34b5168135af4e738260c1aaaf97fd74', 'User deleted students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('34b781d6e92445a3a34fc3037c2dfa93', 'User deleted students/68011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('35020cf813a443b3a90c7a0dd89d9e69', 'User deleted students/68011211067', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3510490a168a4ed2a20fcef060e6f46b', 'User deleted students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('35297c7f67334a2a8822afa6b1f87fd5', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('354c98616d75448a91a8f13a8b9f1892', 'User deleted students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('354daef2980f445880be807cc65a7360', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:03:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3551f6b415b14cb4ad851bec22320b43', 'User deleted students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3590ed857b0c40fcafded28492ffeaf8', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('35924510092c4eeab419a8196d0d37d9', 'User deleted students/67011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('359c667682494e45996747b0db96ea54', 'User deleted subjects/1201413/sections/1201413_3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:09:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('35a6e1623c23493da8510103353a62c0', 'User saved subjects/1201413/sections/1201413_4', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:02:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('35cb2ee350904d3e9f625d7f3fd5ed2f', 'User deleted students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('35e71658fbb0423e912d87e6f9be40a4', 'User deleted students/66011211080', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('35f01837b2eb47c5808ec0616c2c1b20', 'User saved students/66011211066', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('35f595aa687d4133b21b37996e13d943', 'User deleted students/66011211058', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('360185d8467343148b24ae50f02610cc', 'User deleted students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('36bf96d50804417f8237fc94eb0a6805', 'User deleted students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('36c2af51af064b34966704f77dfd3d03', 'User saved subjects/1201413/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:11:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('371d7d3b96a84052af5d9a9fab01578e', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3774f346b9694954baca7f20fdf1cbfc', 'User deleted students/66011211060', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('377abafa1cd649eba2f014ad940c0ff3', 'User saved subjects/1201413/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:28:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3790f9e427d44e75833ca47a13af77df', 'User deleted students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('37e167a0048e4530983e0c51dc5938b7', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('37ebcc2d560d44baa4f4f30e32c6f3aa', 'User deleted students/67011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('37eeceec36bd40ac98114cbf209612d0', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('38358dd956814a70b639e871e5072832', 'User deleted students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('38480e32dc5343f1af675e6d1cb8289a', 'User saved students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('386490e98c6a43e9b9b0930124be112b', 'User deleted students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('39056ad142a74d779877e3ac403f8535', 'User deleted students/66011211089', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('39132377057f4bf3b189571e47d6c772', 'User deleted students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('391832bc54a94d87abd5502f6694d9ab', 'User deleted students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('39193a670a2747e8a28bf3c74a1a67de', 'User saved students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('39653f371f3048e29cc0b7dca0307a86', 'User saved students/66011211060', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('398302bfd3ad462ea332775b6c2c152d', 'User saved students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('39910729befe4c69a750676ff8097a32', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('39974d0a06124099b941dbb221c336a0', 'User deleted students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('39f56e0c31754b7cbcd038a0047a2076', 'User saved subjects/1201413/sections/1201413_5', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:02:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('39f81b78407a41979dbe53d4b8bec7b0', 'User deleted students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3a07c12c31994fa58376f1602a7daa6e', 'User saved students/66011211057', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3a2c70e9ab1d43829cffa8cd61c9882e', 'User deleted students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3a646a1942db4f0d9700f2d55a906459', 'User deleted students/68011211072', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3acfbdfdb47a489f836d82d183912957', 'User saved students/66011211072', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3ad8fb94436e4979b0956a07995fd752', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3ad9505d833e43dc8f0002522020ccdc', 'User deleted students/66011211063', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3adee556358d448088ad3767f0604424', 'User saved students/66011211095', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3b1552aa865f48b1a62ee71b10a06492', 'User saved students/66011211059', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3b1cf2e580dd4d33a9c5b16b7dbccf18', 'User updated exams/1201111_1_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:48:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3b542e71d96944c7a7d1682b092716c8', 'User saved students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3b64d931492b4b4b9401f986a3a51e20', 'User saved students/66011211079', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3bf1f92d40c142ca961c5bf7b67288bc', 'User deleted students/66011211077', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3bf5cbfd1b314cbdaa9f70be3c29991e', 'User deleted students/67011211093', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3c067528d2864a77a1c9557c556a4f39', 'User deleted students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3c2fd9ea326a4a13ab790ab46608c76e', 'User deleted students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3c4403db070e4b8ba3b307bf8ff63e62', 'User saved students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3c57ad2c825d42ca99a9c615b564fdab', 'User deleted students/66011211014', 'Exam Grading', 'Teacher', '2026-08-17 05:55:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('3c74ac2fd0734791b69ba0ac9419d375', 'User deleted students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3cd52ee71cd84fdfbe30fe060e391109', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:50:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3cfc28ba3f494c8bbba62498e96ce7c1', 'User updated subjects/1201111', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:15:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3cfcb75e270b4e568e5cc9bb044ad4e6', 'User saved students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:54', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3d5e9ebc2271431b9ee84f5d56075827', 'User saved students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3dd1b388c55e4f3fb4cac8c4b03386c1', 'User deleted students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3dfea8920b954621a59791ddf2b8ae73', 'User saved students/66011211092', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3e6f89d127a2453fa41d433d73ffbddd', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3ed4a6749e1643c186eb883e1a8d60ec', 'User deleted students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3ede755a97954596a7aad496f69cd12e', 'User deleted students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3effd61804604c038e3f2c25f5a0449c', 'User saved subjects/1201413/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3f1087948af24ce0b0c89a0585cfaf38', 'User deleted students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3f2403335deb4702a153daf34f264952', 'User saved students/66011211078', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3f27c1889476466db565e8f7c7568086', 'User saved students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3f394159e9c340b0be5cb148e9462b6a', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:50:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3f458008816649f3a53fd34bf25a6a06', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3f7016f120244226b8bb772b757f45d1', 'User saved students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3f7a3916ea9d4a139f3369ebc8236b47', 'User saved students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3fa3065297f143ec9ee1f58a84582e7a', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3feb081c1d9c480aab1e71f0e8824aa1', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('3wh3isg2z1fwl5volj1jk', 'User saved subjects/1101', 'I am Boss', 'Teacher', '2026-08-17 10:11:30', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('40374d7ac6b14e2aad5a050983a370b6', 'User saved exams/1201413_1_Project_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:40:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4038c0eee8874916b8aaded174cdf2d5', 'User deleted students/66011211096', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('40759e15370e475497aa53f044425e9e', 'User deleted students/66011211071', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4094d440e28c4f74b683e743cf59a994', 'User deleted students/67011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('40a0fae4811d4999886105af93d7ed20', 'User deleted students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('40b17e734bf64d89b4613168ee6bad8e', 'User deleted students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('40ffee3a9d734166bfd3c9a5efb9af98', 'User deleted students/66011211090', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4103ee03345c4b6cb0f26db3accb5625', 'User deleted subjects/1201111', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:40:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('41226d2a7aa946ed8e18668345f9ce89', 'User deleted students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4152e8636db7481ab81b15f251d23791', 'User deleted students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('41b5a0ea76cc4921b97aad61c552144d', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('41cd0dbb48454fcfb02f9ef3918b1a49', 'User deleted students/66011211005', 'Exam Grading', 'Teacher', '2026-08-17 05:55:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('421931457e764fb5955c004c4e3a8947', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('422bb60621c844e5b4b4ce55703f03fa', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('424e21b6b7e542f6a5e141b3b04d56ca', 'User deleted students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4255ab624ce94ce09e6e9720399fa061', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('428c1d9eff924e2194e32b808d8a3fdc', 'User deleted students/66011211052', 'Exam Grading', 'Teacher', '2026-08-17 05:59:54', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('42994391fd384dd9906b424e77dfe0dc', 'User deleted students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('42d1a558f23f4882856f8c49eb2e12ea', 'User deleted students/66011211068', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('42ed02eda74249d291046e4c66f1fd8c', 'User updated exams/S101_1_Test', 'Exam Grading', 'Teacher', '2026-08-17 06:37:32', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('43203b96832d4deb8e7ad86657b96552', 'User saved students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4331ce9b03704d23968a8ce81fadf5c0', 'User saved students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4333b6e9b690474ea02dd4168202d3ae', 'User deleted students/66011211099', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('433e63b8444747429075bb6ff606482b', 'User deleted students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('435115fcb14c4cb69ef4a8f402165df5', 'User updated results/75fe2c46ab9c450d8235a7540ab5dc72', 'Exam Grading', 'Teacher', '2026-08-17 07:49:32', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('439054a345964e8dacafe56292800395', 'User updated results/802bf9e82115427db1798543af046488', 'Exam Grading', 'Teacher', '2026-08-17 07:51:12', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('43de539e36174f5ebf8ffb371c757871', 'User deleted students/66011211096', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('440fab65b77b44e2b25186ce37b9ee03', 'User deleted students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('44346b7887a44bbfa021b85e8f89d161', 'User deleted students/66011211095', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('445fd9a4ed044d81bb0a2d65a821d29a', 'User deleted students/66011211098', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('446f403992cd40a59d25c645269a18df', 'User saved students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('447069dc7321450c9f981eba6878671e', 'User saved students/66011211088', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('447e790e69aa4fc682433db442dd1da3', 'User deleted students/68011211094', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('447f7079e9e2412c8fe93f39f5f81cef', 'User deleted students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('44ab6b40411b4ad6ad0ade608ebdd5b3', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:23', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('44ac564132324dec92f46633af20d450', 'User saved students/66011211020', 'Exam Grading', 'Teacher', '2026-08-17 06:22:54', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('44f526bbe94d4fe8912a1b7211ed7396', 'User deleted students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('451263e5c7754c50bdf04c938d2c94eb', 'User deleted students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('45722728a1924484a57c199f51da4c8d', 'User deleted students/67011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('457db7db576848b398c888fd8b0df156', 'User deleted students/66011211086', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('46114f73a65f40ad8eb0731d962db879', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4657c847e95c48d0bd163d8974215260', 'User deleted students/66011211013', 'Supakrit', 'Teacher', '2026-08-17 08:54:12', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('4664304fc107435689f01a92ae0201c0', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4679fe5a180848b6821412d542858d3c', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('46ce026707974b8a9af2892b4bcff30e', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('46e6181c0fc142b6950ae6f7ed9f9dba', 'User deleted students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('472fe5d2627b4bdeb6445dcb4288fbec', 'User deleted students/66011211052', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('473963b05b1b4fa7ba6a39e0f007aaf4', 'User deleted students/68011211058', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('47464c281eb0407eb2b88eaa5fee3576', 'User saved students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4749d5d88b1942abb73f7099bae357bc', 'User deleted students/66011211062', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('476e85bc3f884bce80ebb4bff745c415', 'User saved subjects/T111/sections/T111_2', 'Exam Grading', 'Teacher', '2026-08-17 06:20:06', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('47e5d49dbc834a1287fd92e9c8f7b036', 'User deleted students/66011211055', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('47f10df5746f431f954b8e89bc80bec5', 'User deleted students/66011211076', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('47fc68e8bb7045a08977a5c94a88a4db', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('48027cab2e614be8a07637cacd6b5044', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('481c019d76814029a7f0aa82167658e8', 'User saved students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4822916a3a15457db6d8e83851f779a4', 'User deleted students/66011211099', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4822ed5be8db46a0b0e2a037f56023d1', 'User saved students/66011211073', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4859a866f6b7411a9b832c11964ad19d', 'User updated subjects/1201111', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:57:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('48f9a43f22be41808c9d8f910b839d4f', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:50:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4913ff276eee4f55ad49638dc02286db', 'User saved subjects/1201111/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('496ea4f4c85a49718f5383de62119e34', 'User saved students/66011211085', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:56', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('49b6b2a7ff2a43adbfe29cf6fcc854dc', 'User deleted students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('49d2f98ac28944c289faaea099b2ebe7', 'User deleted subjects/1201111/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:26:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('49ea0820ce794950be61cd4215abb539', 'User deleted students/66011211054', 'Exam Grading', 'Teacher', '2026-08-17 05:59:54', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('4ad4f9c570c04d0aa1cfe834d48d420d', 'User deleted students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4ae29899b17b4ec197e5592f42672130', 'User deleted students/66011211053', 'Exam Grading', 'Teacher', '2026-08-17 05:59:54', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('4b10ca78187f4f6a927bd513f1af7d73', 'User deleted students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4b12ecdabe8042e0928e42fdbbd48a33', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4b25ad1f718848f88c717574a901d497', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4b25e028698348ca88f311fb729846b2', 'User deleted students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4b353b583aaa460d92c1563325d52a4f', 'User saved students/66011211083', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4b4b3f4377bc4742a80be24528c71ae3', 'User saved students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4b58b74791d54ced97bd43c3d7ec8015', 'User saved students/66011211100', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4be83a86a0624e9180dbd6d5a0450608', 'User deleted students/67011211076', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4c23753fdb56451ebd08e33f7db2cb35', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4c2f3e880b924454b8b35faed97259b5', 'User deleted subjects/1201413/sections/9', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:13:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4c32eb5cb76644b6bc2edde35af83df1', 'User deleted students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4c7be4e960a74ab892e2342fabb71cca', 'User saved students/66011211078', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4c9e676d9f344dc18cc838449db9017c', 'User saved students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4cb06c2eb7e5484ebc317d2d5078f472', 'User deleted exams/1201413_1_Project_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:59:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4cd4d78e7a4340aa818f60e3143a88eb', 'User deleted students/66011211087', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4cf507353a8c4a1e98d57d45ec995c75', 'User deleted students/67011211061', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4cfc1f70b93c4bcb8f7410c0df29a7a5', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4d0f6046aadf4d3cb882937869fbe8a0', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4d1d17b7fda04513a31e37220d2b6879', 'User deleted students/67011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4d348dc7095b4982ba3f057d6d100de6', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:50:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4d4de18550324f218e905ca8b06ce04a', 'User saved students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4d7e366938b14859b7949814c78c9865', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4d8aca65f4bf4d158eb2ade1a76cee9d', 'User deleted students/66011211081', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('4d8b2ca5a9ec4ba7b7f46a69f8570377', 'User deleted students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4daef917588c4936aebabc533b0a78b1', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:45:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4dd85187b0e44c19b75f0ee53735a76c', 'User deleted students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4df3250eeb9f4a25a96a2d04db55e42f', 'User deleted students/66011211069', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4df8f26c12e84fef9c8bdf0f4b950871', 'User deleted students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4dfd9401845145099bb26a2b629de506', 'User deleted students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4e0c47ddda004b10904a853b3aba15ab', 'User saved students/66011211094', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4e3adee427904270979a10a6ec539681', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4e55529cd2044481adbd6667ea9c260b', 'User deleted students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4e66886430dc40498e06578df0a4afd4', 'User deleted students/68011211090', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4e754ccf94ee4aebbac25a0209916d79', 'User deleted students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4e849df13ce4452786098df33304bb39', 'User deleted students/67011211053', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4e86de67897e4fc585a4581bd90ca0af', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4e8cafbc2dcd4d858a7ad9da02c01ad9', 'User deleted students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4ea385a7ce804ba0b9f23a23da4bef22', 'User saved students/66011211087', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4ea71840453644aea17f476bf0c5b8c5', 'User deleted students/68011211096', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4f702b2d8ad145faa7e59cf583e6e0df', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4fbd8e5ad68c4d59a2aef54fa2c995b8', 'User deleted students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4fcf2436f1464b44ac0b1e46e2e20e36', 'User saved students/66011211074', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4fdc20306c5a43f3bf39e681aa8d1b4b', 'User deleted students/66011211068', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4fee7f15d033448d9b7d377ab570777f', 'User deleted students/66011211061', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('4ffd0d529a9d470980faa1a8be1902ef', 'User saved students/66011211064', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('50107e9fe1b64acc8af15e402ea676bc', 'User saved students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5027cc3a2273434d82298e1b0bea87f9', 'User deleted students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('508da2dfebee4448af6600bb25faf660', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5099beddd3d64e528a6287f4f3208a69', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:23', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('50b8cfb16cd94b9199e1f9711c0c483b', 'User deleted students/66011211067', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('50e6d889ee114d01a473e1a470a04b63', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:52:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('510f545dc3ab45a993944ae319ab6962', 'User deleted students/66011211007', 'Exam Grading', 'Teacher', '2026-08-17 05:55:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('5141fcb6df8b47ac8ab6d3c6a0c43df0', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('516ed485888b4218920f18a6a660a715', 'User deleted students/66011211081', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('51756ff8d9ba4f93a567c3ea27fbf946', 'User saved students/66011211070', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('517648752a5f4fb1b62159f99b3dad3f', 'User deleted students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('51bf5d675ddf475f98a8256dcc7a9534', 'User deleted students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5205170a245e4446843b60d7798d2cba', 'User saved students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5205e96a0c084d83aea76e95d807e0fe', 'User deleted students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('520ea8e0d5bc4362885af0ab71e782fb', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:52:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5212f031928f4c24b6aa58406eaa7168', 'User deleted students/67011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('52a821ad2f3848f3899e9115ac6526db', 'User deleted students/67011211097', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5378d4046aaa48c293711253d2c7f7e1', 'User deleted students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('53b1318dd33b4374819b18006a93101c', 'User saved students/66011211080', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('53b243f7f6a14a68a788cadcf210b291', 'User deleted students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('53dbed8d056442b9bfa2541073aa8e01', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('542eb4b1f930419f814d26e4540cfc81', 'User deleted students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5455cc30bc574f0094c03244a8bd4374', 'User saved students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5475edb209e34eb7ab353a846e3b0d50', 'User deleted students/66011211017', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('5497c04ffa644fd99064f9065f176c71', 'User deleted students/66011211006', 'Exam Grading', 'Teacher', '2026-08-17 05:55:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('54b0e186add6403d8c325d28c6e7105d', 'User saved students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('55227975654048daa8ae6cee3a28c964', 'User deleted students/66011211039', 'Exam Grading', 'Teacher', '2026-08-17 05:59:23', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('555b70fc7c694af9bc09b80d9015b658', 'User saved students/66011211068', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('556874262cb44fba8738f6d16eac23d2', 'User deleted students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('557fc13a26134df19e16969e2d56e5f9', 'User saved students/66011211054', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5587b99031de461db5d3948106a87393', 'User saved students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('559e125616894d13b2abea4d0b31670f', 'User saved students/66011211056', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('55ca9cabc79a405cb98143d9e47de5dc', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:54', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('55d4c8d47de746cd99ee0a7b93ca6e30', 'User deleted students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('55d568cc36964185b02ee6d2d2d3fe52', 'User saved students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('55dac1a493c94dbf91a17e1f21c5da5c', 'User deleted students/68011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('55e76ed1284b4d54b29a80695867d37a', 'User deleted students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('55e7b25d800c4f9fb835c6dd91261f4f', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('56029054b2b944f499b4cd15bcb8eda2', 'User deleted students/66011211006', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('560f788b8d194935a1d291814f6a4551', 'User updated results/802bf9e82115427db1798543af046488', 'Exam Grading', 'Teacher', '2026-08-17 07:50:43', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('5687f31f54a848d6a76b82e3d0194624', 'User saved students/66011211077', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('569437f306994d789338337936238804', 'User deleted students/66011211027', 'Exam Grading', 'Teacher', '2026-08-17 05:58:49', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('56c9d176df0541b79a30a7ffb9b4f201', 'User saved students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('56d8b4e214044b07aebdae37ff64907f', 'User saved students/66011211051', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('56e983ee78e84f399496614702d82fbe', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('573e536ea4914de08add1c53790f84ef', 'User saved students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('574dc2ce16d340e49e38c49521d59c2a', 'User saved students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('577302d091b94da59af5950b576d7169', 'User saved students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('57d1f7ac08254261a88b0e9be937ce3c', 'User deleted students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('57de73add9ae4effbf4e1907779bf32c', 'User saved students/66011211083', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('580784e8fc16434eb870e8721f22c108', 'User saved students/66011211098', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5813004f02774a819688c8c8623a6562', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5837618890af4e8bb5de2b246d31985b', 'User deleted students/66011211090', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('5838470c5aed43e2b724b775e3e6deeb', 'User deleted students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('58471f876e8b4c98a30d14c43da7afbb', 'User saved students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('58a638061eab472caf35147cb681d59c', 'User deleted students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('58f494b0b3fb417bb0a18338eafa366a', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('592f4a368b3749818972d76231a03a2e', 'User saved subjects/1201413', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:02:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('59438d9249a74e46a53095cea178f925', 'User deleted students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5958c84945d04a20903434671199117f', 'User deleted students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5979266058e44f38931242392c0ad26c', 'User deleted exams/1201413_1_Pro2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 16:40:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('59a0ac6a8e8441c5897d85e455d434fe', 'User deleted students/66011211068', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('59a54286a71843709fa9ff7570f4b631', 'User deleted students/66011211073', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('59c37b27aaee40b68ea556942ebcd4c5', 'User signed out', 'I am Boss', 'Teacher', '2026-08-17 03:38:07', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('59c5a47d8353484cb1dbb0854a7af6d3', 'User deleted students/66011211096', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('59d4820edbb3436e8c85a1f6f31f5576', 'User saved students/66011211081', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('59d8669726204896b91231f0cf21d0eb', 'User deleted students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('59e43550292141e68af62a44da7a0cca', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('59e991c83bec4f26a39c25198c603bd4', 'User deleted subjects/1201413/sections/10', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:13:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('59ec6abe21294a9699f6e9e124b51a49', 'User saved students/66011211056', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5a056a8a869e43efb37cdccbe82fff47', 'User deleted students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:48:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5a2222a02d81462c87b41c0aee83ad0c', 'User saved subjects/1201413/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:54:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5a411082e57e4750ab9d615ec9a28d29', 'User deleted students/67011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5a5b33e1ec3d49bba57e3f4a163cdd4d', 'User deleted students/66011211033', 'Exam Grading', 'Teacher', '2026-08-17 05:58:49', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('5aad2a7da50f4dbe86329c460442ff24', 'User saved students/66011211057', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5af5a1bc3dfd4ddf9e3900b1d0aa9eef', 'User saved exams/1201413_1_Pro2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 16:40:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5b4fc57a259347f0a89a34726d97ed9b', 'ระงับบัญชีผู้ใช้งาน: 66011211035@msu.ac.th', NULL, NULL, '2026-08-17 06:05:08', '1');
INSERT INTO `system_logs` VALUES ('5b7485aa2c6645edb15c10ce97233c00', 'User deleted students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5beaae28a9fd4a10b7f9ed460456db61', 'User saved students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5bf62f8c440b4661b9b5f0fe0587b791', 'User deleted students/67011211051', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5c0bc8dc65174a3f88ce29b410de4f75', 'User saved students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5c203cb3bbb4477f95ecc53fb00124d0', 'User deleted students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5c4f7dd4f92e4c2dba5961cb7d8c81ee', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5c76d52d888e4846b1ed2545395ef106', 'User signed out', 'Exam Grading', 'Teacher', '2026-08-17 07:17:42', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('5c7b18aed5064742b01e8e084d04ca54', 'User saved students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5caafc2e809047118a2638462377f07f', 'User saved students/66011211086', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5cab8448f87247b78167ba0abe648983', 'User deleted students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5d1d70842eb24cf6bfaeb0e1bf668796', 'User deleted students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5d68a7149f134716b5d438d07ba762db', 'User deleted students/66011211074', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5d993427a91c422e88bf7e149cf97752', 'User deleted students/66011211002', 'Supakrit', 'Teacher', '2026-08-17 08:54:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('5db0a8b34fce48bcb252502f06e41dae', 'User deleted students/66011211078', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5e14ce70dd744fefaaa9b4d266b8780d', 'User deleted students/66011211062', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5e155e474230490a9f8362a53e6d9b2c', 'User deleted subjects/1201413/sections/5', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:26:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5e2d0678886c4b93bdbb078cdd235f5e', 'User saved students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5e43f0a66c424bb38dfcfb8dd20b708f', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5e5c4336504a497888045ece9b625698', 'User deleted students/66011211056', 'Supakrit', 'Teacher', '2026-08-17 08:54:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('5e7437615e304074ba55cf7451edde42', 'User saved students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5e8310e2c2a94b449ca034187f28a522', 'User deleted students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5e846a705a424c2280359f548eb8f5b5', 'User saved students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5ea7aba4c5d94c25bc01437a576b85d4', 'User deleted students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5ec6ca2797ad4115a238e6f9f1edcf4f', 'User deleted subjects/1201413/sections/1201413_5', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:09:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5ef3821d03424ab9af5dbd5faf33f9b4', 'User deleted students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5f4ac537224541c58afa8245e91cdf89', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5f8b65e2e58842498b199d169d46bef1', 'User deleted students/67011211092', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5f92b89cc9714260a559da65b38ac95d', 'User deleted students/67011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5fb4756d87c54fcd81b4d067d9d3e59d', 'User deleted students/67011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5fbe8af30c9b4c6b99a678ba16d48d25', 'User saved students/66011211053', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5fd2d3ea68454b6da23dc476f86b546d', 'User deleted students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5ff99cb8540a416381a7b046e4fef97e', 'User deleted students/66011211094', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('5hfwkhjy6x6lzdelurxoal', 'User saved subjects/1201413', 'I am Boss', 'Teacher', '2026-08-17 10:12:06', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('6004d193a00847e398c360c4f4afc70c', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6020de8a2fd443c083d2811b52a4080f', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:56', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('603f420fb4944307bdff258f607815da', 'User deleted students/68011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6064ba8bc71f4ed68c262cee0bfee913', 'User deleted students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('606be907fb0e404180e7ad0922748683', 'User deleted students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('609e37dd9a644d50a621e4fe38f1c03f', 'User deleted students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('60a8dda314914902b4a3de1c3b39a2e0', 'User deleted subjects/T111', 'Supakrit', 'Teacher', '2026-08-17 08:38:50', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('60d39a903bd6494080688711e52a986e', 'User deleted students/66011211094', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('60dce16a571b40aab57f42e67c75eeac', 'User deleted students/68011211081', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6113fdd7f8564eecb3a5c3ab9df72d77', 'User deleted students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6116ca51084e4127bd4a3071d20bc954', 'User deleted students/67011211088', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6134ff49d6714d84bfb3d72ecb37de2a', 'User deleted students/67011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('613501927f314b7bb233de1859aa4320', 'User deleted students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('61814431df6f488ea0a9bd06a148e626', 'User deleted subjects/1201413/sections/6', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:13:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('618664cffdd1496b8ed57342c66c4fa7', 'User deleted students/66011211082', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('619f8afeb2a04695babfc0c339f86446', 'User saved students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('61e7cbf8ba4a44e1b0533eb19a5c19a0', 'User deleted students/67011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('622124222ff74c1ea60a208c4bae366a', 'User deleted students/66011211077', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6223f6c6dd3b424aac0dd0a946498c19', 'User saved students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('622845184c2a4633940a05c6dc8efc56', 'User saved subjects/1201413/sections/All Section', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:24:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('623bbbd2999a4809aca2dabe0a84db5c', 'User deleted students/66011211080', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('624fa857902b4e95b6a57b4447e557c3', 'User saved students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6276302b7aff4c4885499c4d7fe6ca65', 'User deleted students/67011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('62ea581b26654740b9d1ff938483f646', 'User saved subjects/1201111/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('62f748f855794578b4da5198e0620ea2', 'User deleted students/66011211080', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('632fe330a21f4c40973d5042f749e5f0', 'User deleted students/67011211054', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('638667324d05466ea3f96165f40b42f0', 'User deleted students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('63909d8fa01347b4840df2e7ce721f53', 'User saved students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('63936103e583489e85c90d81e4c5b998', 'User deleted students/68011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('640de9dc60c548f6824e1e62c2ae7c9f', 'User deleted students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6413915dc0914db099a15cd389ecfab8', 'User saved students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6428d3d4d5fd4100a92e2d41f41917c0', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:52:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6437a7a4e6f240b4b1dd0f553052e3db', 'User deleted students/66011211073', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6442304cd1024280b6af9231a858b8f4', 'User saved subjects/1201111/sections/4', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('648f8af5c14443d888a6d838afd41d91', 'User deleted students/66011211082', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('650303b516fb48f7ad5d82eb7aa31e48', 'User saved students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('65041f80a0ec4eadabfd792d2e4f505c', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('65545efb87094517af523d4becf4a90c', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6583d9b277f04ac092a47f5451b8d307', 'User saved students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6587932ca7f6445b9b1828af3c4f50e5', 'User deleted students/66011211058', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('65bbf4117bf648bfb0fc559524c3cedb', 'User deleted students/66011211079', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('65c92383648b4ff6be41817fd5f5dcca', 'User saved subjects/1201111/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:28:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('660a26e5ec16423593c77e029a8ae6ef', 'User saved students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6617e7c83f344ae496a3b7b176a0efb8', 'User deleted students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('666faed765e44fa3a8bbe38d32ffed35', 'User deleted students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6707283bb84d4c64bfc2506ba5a39c3f', 'User deleted students/66011211008', 'Supakrit', 'Teacher', '2026-08-17 08:54:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('6727ff07dd8840afbc3130bfa27775dc', 'User saved students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6739457a71b548f79a92c707900b334f', 'User deleted students/66011211058', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('677a5204021d47c4b943a7df2091e142', 'User deleted students/66011211135', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:14:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('678ef35169034e65800b9f8196f4fc1c', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('67c0bb5e8889410189bf6a3a9af11a77', 'User deleted students/66011211003', 'Exam Grading', 'Teacher', '2026-08-17 05:54:42', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('67f2ff1dc078473d83e7d626456a030b', 'User deleted students/66011211094', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('680d064576d94d32be938eda6cfddf6b', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('681df9a2d62f4db9804fedc2d3322ed0', 'User deleted students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6883dfcbf6164b2fac7085b9bc6bb590', 'User saved students/66011211093', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('68996ahm5hrwcqwgxjgys', 'User signed in', 'I am Boss', 'Teacher', '2026-08-17 10:08:20', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('69133cc72638458e8e19ba1b7a9cb72d', 'User deleted students/66011211079', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('691b03b848114cb3ae392808ef7fee57', 'User deleted students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('69338e8482564b4fb61f55268c4ad386', 'User saved students/66011211065', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('693796f4902c4ceabb527ee311b5f09e', 'User saved exams/T111_1_TEs2', 'Supakrit', 'Teacher', '2026-08-17 08:13:55', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('69c8f757604e457880230fa174b90249', 'User saved students/66011211082', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6a096afbc3864944925a8332ca42939a', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6a21f43e8f574b27a38c11f60105d3a4', 'User deleted students/67011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6a40358916ab4e7d85b032792bd4bf01', 'User saved students/66011211075', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6a59e188fb104775a09db648e1aac142', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6a661a2f34ea4f21b861ec2ae3ef00cf', 'User saved students/66011211063', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6a9062c932cd44b48c88a6b4d9f0222d', 'User deleted students/66011211029', 'Exam Grading', 'Teacher', '2026-08-17 05:58:50', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('6ab1a229a7b4453a89ecaea47666980f', 'User deleted students/68011211061', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6ab5d689d53d4e7d80ed04fe03f24f92', 'User saved subjects/1201413/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:11:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6b0a4e023f224b5ab393e49ace30ca11', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:50:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6b0b4943def347fc819388ed05b5e2ca', 'User deleted students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6b339e7945f5445ca460c85d30b3fdce', 'User deleted students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6b5472c8f1cd42878545f2b27cc9da42', 'User deleted students/66011211088', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6b5e90686f6a42e3aa11a3b50e10f13c', 'User saved students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6b63978cb6ff4d1f80a59b1870361539', 'User deleted students/66011211088', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6b9a129221e64db2851797cd77010df8', 'User saved students/66011211094', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6ba9039659cc43baa11a287b7b0fe850', 'User deleted students/66011211086', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6c183a7197ba449ab5c0564157279864', 'User deleted students/67011211052', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6c6f47a61f654035a772e086b11f0957', 'User saved students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6ca65319019c4a8aab2b064bc5e80a3c', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6cad8a1fe96646c4990992b4fa905649', 'User deleted students/68011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6caf2e3516f243d185dda1e408cdcbc2', 'User saved students/66011211096', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6cb57db5a099415f8eafbe87b6305f52', 'User deleted students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6cedf201e2f049b3a2e5a1744abd7747', 'User deleted students/66011211073', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('6cf19aca2dec456ebce4d1f5a18d4518', 'User deleted students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6cf68798baa742d5806de7669f474c0d', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6cf7b86a9ab54f99af14244d6ce2af55', 'User saved subjects/1201111/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:28:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6d366e0b68824ecc98607c97270cf094', 'User deleted students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6d5f3ea24dc649b6abad4dd979cdd715', 'User saved students/66011211058', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6d9e1927e3c64baaaeb434d51a135862', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:23', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6dbd18cf22b6474ca9d878afa663cfc8', 'User deleted students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6e43374e6fd149dda790f8a545adf0ec', 'User saved students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6e59d3c721d3467a9bea46eb4edc06c9', 'User saved exams/S101_1_Test', 'Exam Grading', 'Teacher', '2026-08-17 06:28:38', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('6e65a486572641ef89b82e5663eacad0', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6e845da5158f483bbdb749e0dfb576f3', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6eb028eedff248aba2e6feba4ded0b87', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6eb140c1c7c64a81899a9bb8b73130cd', 'User deleted students/68011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6eb969dffca34b89babb53727394d23a', 'User deleted students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6ed00e5782644a5f83d4f12f580963c5', 'User saved students/66011211100', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6efd01980a484d558ed4baa5d15b2f36', 'User deleted students/67011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6f1a5062834642c8a79de27b83da02c8', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6f20c726c2fb40a9959d784195446ce1', 'User deleted students/67011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6f3b2e9ecd034d2eb515f32efc63259e', 'User deleted students/67011211066', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6f48e5a42c594415b9af9bef3fcc1540', 'User saved students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:56', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6f99085e4028423b8fc05e27001afefb', 'User saved students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6fe96b01188442a9945abbbabe90ab45', 'User deleted students/66011211044', 'Exam Grading', 'Teacher', '2026-08-17 05:59:23', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('6ff32b5452094dfc80d3ef711da9fead', 'User deleted students/67011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6ff9dea0763d40cbadaf8c82b3e27bf6', 'User deleted students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('6klsm0hgfngcphzkvmkcnv', 'User saved subjects/1201111/sections/1201111_4', 'I am Boss', 'Teacher', '2026-08-21 08:28:31', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('6t23sbn37dk11z0whnkq84', 'User deleted subjects/T0001', 'Supakrit', 'Teacher', '2026-08-17 10:16:07', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7002f95d92744f94bda0ee29311a9c52', 'User deleted students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7024924ec73a4bac9f7f9714dcb2c5f8', 'User saved students/66011211135', 'Exam Grading', 'Teacher', '2026-08-17 06:21:18', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7042abcde86b4552ae431098af172b4c', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7056302e78084b0ea88e55fa5f2676e9', 'User deleted students/66011211062', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('70c1c06f479346759dc658cf78bd6fb7', 'User saved students/66011211068', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('70dfbbcc5c134d72a08b2a46c036ccad', 'User deleted students/67011211090', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('70e0b945c1294949b927ed09909198ca', 'User deleted students/66011211084', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('70eef60fce1a4934b90aff1e083262cc', 'User saved students/66011211093', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7124ca5f591a432da5670aa60f9f7b3a', 'User saved subjects/1201111/sections/1201111_3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:09:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('714031c340da4b8089cc17fb228a6f8d', 'User signed in', 'Exam Grading', 'Teacher', '2026-08-17 07:18:08', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('71ad221c5bbb4eda82e2147bd6ab18a6', 'User deleted subjects/T001', 'Exam Grading', 'Teacher', '2026-08-17 05:54:04', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('71de5ed5a2a44005afcff4a53d448731', 'User saved students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('71fe21f2f1c6457db1dbc046ab480219', 'User deleted students/68011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('72441f67dd1a4a0baee48779c76f707a', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7244b1f4f11c4257bbd28aad02b2a66d', 'User saved students/66011211069', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('73061beaf5d64691912b7633c1b9ae87', 'User deleted students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('735d797cce444f818bb4d3d8ae12de48', 'User deleted students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('737d099f569046c7a9857778a8016869', 'User saved students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('738e6d3ee7b94c2aa855c280d0498f14', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('73c24c26eae54cc3a20b2e60de648845', 'User deleted subjects/1201413/sections/All Section', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:24:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7403ae7e4fbf4f21a190bd4163eef613', 'User deleted students/66011211069', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('742903f6055b49d4bb46f1574ca5f2ad', 'User saved students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7469f32666344b7a8cd18b2d491a7927', 'User deleted students/68011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('74c91f62f79243d3ac110931757ec42f', 'User deleted students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('752f86a01f5845b7a4b9c980c85a36f8', 'User deleted students/66011211088', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7543a9556ed04f2eba98038929da0e2b', 'User saved students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7564c53ee2f64974a1439d43cc1145ef', 'User deleted subjects/1201413/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('756b7d1480e142cbbf230702bf70e75b', 'User deleted students/66011211057', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('75894ef38ce445d59db1b825c9360455', 'User deleted students/68011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('758fa6800b754723b4677df5f340d740', 'User deleted students/66011211056', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7597780f539e466298f2566504b97167', 'User deleted subjects/1201111/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:26:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7599e6d6392d4471bb7740612a786f62', 'User deleted students/68011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('75ce6ed3bda140169e8684ff13f86cd1', 'User deleted students/68011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('75d02627169f4c72a0a2a5a5a15d4744', 'User deleted students/67011211073', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('75d799c4a8dc496180bf77b0b73ffd64', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7609e8fd3d05424f949543b232481a2b', 'User deleted students/66011211072', 'Supakrit', 'Teacher', '2026-08-17 08:54:12', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('764b970fc85146319d5bb05776a3edd1', 'User saved students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('766383e2d5164c2c89f2eb1abf871c7c', 'User saved students/66011211001', 'Exam Grading', 'Teacher', '2026-08-17 06:27:18', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7683ed91673b46e687eeded77d6f23e0', 'User deleted students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('768e647019f945559401caee32fa5cd8', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('769848e5b0eb4c92a78649eeecfa5e21', 'User deleted students/68011211065', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('76ab5d987a2142edb8e6ee809a77d630', 'User deleted students/66011211056', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('76e8d92dea0942698a3e2d2e08f0d2c7', 'User deleted students/66011211087', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('77081e2b046b4c2282d3878cff93b4ba', 'User deleted students/66011211078', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('771d3ba431b54580b652b01f70e55626', 'User deleted students/66011211024', 'Exam Grading', 'Teacher', '2026-08-17 05:55:26', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('772a45c4f99d4fd3804870090cb478b9', 'User deleted students/66011211052', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7754065ead3a43a597fb2c4a34fb14e2', 'User saved subjects/Project', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('777c8bc7ac2047e7af3afc52e55df36e', 'User deleted students/66011211097', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('77c07ced2a2e4bba95cad39433e14f20', 'User deleted subjects/1201111/sections/6', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('77c29b3ddbe648b8bcb8d8604f6d61f0', 'User deleted students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('77e778acfaa44881b6a2440f3ba081ef', 'User saved students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('780bdec2f4ff42cfa44df1fd5ae8f64c', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7851b5eae72c4024b10fd6cab95abdfc', 'User deleted students/68011211063', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7856be8a51fa49a1923009dcdc4b2253', 'User deleted students/66011211099', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('78c04afe7d484ab5b6484f711d3c4b7f', 'User saved students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('78ca25d40d4e4c57968d6bbe869414d7', 'User deleted students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('78f3b55b44c04cc1aa3fe1d4dbc46e2b', 'User updated exams/1201413_1_Pro2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 16:50:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('78f85a9a556a48a99ec5209213730f97', 'User deleted students/66011211097', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('791a821995e741ea938f28571f85b9cc', 'User deleted students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7926077ae4014901853872fcc6e33ebb', 'User deleted students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('798e4202d1fd42119ddd721bf94d4116', 'User deleted students/66011211038', 'Exam Grading', 'Teacher', '2026-08-17 05:59:23', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('799565101f4f4450b4a7be5250ef2810', 'User deleted students/66011211081', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('79b78b9c2e834847bc343fe7123ee77e', 'User saved subjects/1201413/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:54:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('79c9dc5bb83d435aaf2dca4ab4a52845', 'User deleted students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('79d57d136d624be2abea9a17579ca3e0', 'User deleted subjects/1201111', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:51:54', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('79d845a012d3479c84cfd78e94debe1d', 'User deleted students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('79eca211675a47a196779315eed17305', 'User saved students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('79f32e212011416d91a4f12266ba9968', 'User saved students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7a159c6604014cd58532cfd9e1e7e1a1', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7a21eb6257b8468a8c54def6899da7d6', 'User deleted students/66011211015', 'Exam Grading', 'Teacher', '2026-08-17 05:55:26', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7a2a47bb5f424306af1530f951ecf64f', 'User saved students/66011211061', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7a2cb61a1afc495aa4cf9eae5a94dde7', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7a47034067ff40059fcfef7f9df3c966', 'User deleted students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7a4b912b9dbd417b964f2a8a731033c8', 'User deleted students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7a55ae63afb94b77947c969a63aa4b2a', 'User saved students/66011211072', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7a73965d62114e88b9c27a1d778b5b24', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7a81555162ce42348e8f5ac6c6a53fe3', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7a854f2b416447a8a638e64dad21fb25', 'User deleted students/68011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7a9fea4cb49544b2b5dff9407ab412cb', 'User saved students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7ace923501674ebdbefde1ffd32bb7b1', 'User deleted students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7ad9d6322ae844bda6a1532bf770b4a1', 'User saved students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7af5907155c241b1980884bde54f29c1', 'User saved students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7b08ae1e47e240c498d28dec7894a40e', 'User saved students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7b15f6603233431ebabdbafd33a577c5', 'User deleted students/66011211034', 'Exam Grading', 'Teacher', '2026-08-17 05:58:49', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7b6c0f0dfdd0428cbbc3c8b18f2b9d0d', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7b7317d19f324283baf1d8f551e14846', 'User deleted students/66011211075', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7b94ebbb004345f19f593870b3d6a005', 'User updated exams/1201111_1_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:17:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7badb49ee8894a34a2e818d2506c34b1', 'User saved students/66011211097', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7bbf4286a35f460eb6d3e062ad303bad', 'User deleted students/68011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7bcf7a84ab72499e9cdc9122fcfcb29d', 'User deleted students/68011211095', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7bfeffb6c771493e8a6b1bca60bc532a', 'User deleted students/66011211012', 'Exam Grading', 'Teacher', '2026-08-17 05:55:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7c1076lv7jrulikyypbs49', 'User saved subjects/1201111/sections/1201111_2', 'I am Boss', 'Teacher', '2026-08-21 08:26:27', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('7c253aaa42a043359ad5ab4222192d1b', 'User deleted students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7c28556b6b85496b8e15eafcbcf37318', 'User deleted students/66011211086', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7c568ddb50a649499218ffb7e069e30c', 'User deleted students/68011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7c737cb9e501405897fb2645ddef1b8b', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7c74df1db6d44aec8b9977c258fa2d5c', 'User deleted students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7c8741ca95d7458993e39e525e9d6293', 'User deleted students/66011211093', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7c8a711df9ed4a9a814c45125f838bb1', 'User saved subjects/1201413/sections/4', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:54:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7c9189bec64a4754af94558dc6c1ec13', 'User deleted students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7c9c11b006e84d9289d9f866dd73a649', 'User deleted students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7cf1704d39654bc48eeb0b2ed11525e4', 'User deleted students/68011211075', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7d46012c2a4b421f9e47cd31cf22c7d0', 'User deleted students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7d5382fda7274f088d99bef1ead6d4fe', 'User deleted students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7d892e51e7bf46bda2bb90f98c11a347', 'ออกจากระบบ (Admin)', 'Admin', 'Teacher', '2026-08-21 08:17:47', '1');
INSERT INTO `system_logs` VALUES ('7da38c97fef74f26a4f35d8d13b7a7f1', 'User deleted students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7dc709c81888445ebf0ba388a7ec2b99', 'User saved students/66011211085', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7dd5d82c12a44349b46e241a093c7a5a', 'User deleted students/66011211005', 'Supakrit', 'Teacher', '2026-08-17 08:54:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7de594e3809a4a08bc835330729a82bc', 'User saved students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7dfefdec1308489ba119b3653d37ea70', 'User deleted students/66011211073', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7e12edf787884b839a35cf78decf66f1', 'User saved subjects/1201323/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:51:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7e3a068c716c4cedb12283fdf087890d', 'User deleted students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7e409f0d0529412c95130aea1db9a605', 'User saved students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7e4a5d549dd8465e82e192e3e1f6fbcc', 'User deleted students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7e70ffbb35bc418ba6c21a88a814d388', 'User deleted students/66011211019', 'Exam Grading', 'Teacher', '2026-08-17 05:55:26', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7ea04ad511794067ac521cfb88822bc9', 'User saved students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7eddda88ddab41e1bca14a4f7a57c1a4', 'User saved students/66011211091', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7ee07d0338234ba9b29a2f1e9f04388f', 'User deleted students/66011211064', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7f33dc8d7a154a6c805adf6951aaae75', 'User deleted students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7f7135e14c924d2085da08496694e403', 'User saved students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7f91eca3066844ee953d06d72a248332', 'User deleted students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7faf1b84526d4902837f78509fe3e881', 'User saved students/66011211016', 'Exam Grading', 'Teacher', '2026-08-17 06:22:40', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('7fb9266c24cb48f89c9b0b5f40d54c93', 'User updated exams/1201413_1_Pro2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 16:25:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('7tvj5h8pgd9yok2n1fsr4r', 'User updated exams/1201111_1_test', 'I am Boss', 'Teacher', '2026-08-21 08:27:04', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('8002378a7d6f472697145be6d5ba2a2e', 'User deleted students/66011211097', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('80346735260f48dea23b7c3ead45cad1', 'User deleted students/66011211084', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('804b06e5d0c449d58902ef86c90b2f13', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('804b608aa8b04eb2bf3549967372a2fd', 'User saved students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('804eb90086604920b74a624de2329a73', 'User saved students/66011211066', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('80634d041d944a25a8d0c64cbe3da1a1', 'User deleted students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('80ba04bfd6194365a0a88365b6cbab4e', 'User deleted students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('80c21e37766d4a47b23a41e654486092', 'User saved students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('80c95774ecef4a2eb1325c30ed70570c', 'User saved students/66011211065', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('812090a5a7f14c8bb5d2de55da3c7f6e', 'User deleted students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8144aa6c54ff4c8c99edd0b0fdbd6a86', 'User saved students/66011211005', 'Exam Grading', 'Teacher', '2026-08-17 06:22:01', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('814f780a9cd144158dd97fa4594a7ac4', 'User deleted students/66011211062', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('815ef3a6e02848268fd524f07d6a0632', 'User deleted students/66011211066', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('8197772786144b3284efcf834c0e213e', 'User signed in', 'นลธชัย บุตรราช', 'Teacher', '2026-08-16 11:20:02', '66011211035@msu.ac.th');
INSERT INTO `system_logs` VALUES ('81c2b936e1d9481cbd63da9e47ba6bcd', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('81c528918e7746ffa04aaf1890181189', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('81e2804c444d4c3c99d857804de79f7b', 'User saved students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('82010e784063474b95e65868ac26f4ff', 'User deleted students/66011211077', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('829d5852699b459f89441e409da634ae', 'User saved students/66011211063', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('830b4cdc49a643f08cbee9cdabc81533', 'User deleted students/66011211089', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('83296e8399a24e60b21651de5485040c', 'User deleted students/67011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('83594fd1ab5646b8928bac9e67693a2b', 'User deleted students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8374de934e934019a7f1896ba1d4f20a', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('83c97899a8744420a39ecd265ae7805d', 'User updated exams/1201111_1_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:22:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('83f830fb5c4d4a5297dc54093b40923e', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('84007371d5da489d87c7fffc002c6487', 'User deleted students/67011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('841a53b9d94444b8bec6d26552fe121b', 'User deleted students/66011211065', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('844e7838e7854ced86fc4f81a29a3165', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('846acc5f560c41f8905af1ec7f793635', 'User saved students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('84914c8d1b124c319655922a3eed7505', 'User deleted students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('852078abd08043799a991151ac8db112', 'User deleted students/66011211064', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('855a689831774c068ae606d5ed7b65d8', 'User deleted students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('857a89e3f12c4bb28474944650943386', 'User saved students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('85ab4ce81560463fb1937fe776c84360', 'User saved students/66011211055', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('85c37e33f8104371915b0391bbdc2669', 'User deleted students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('86474df5ad2e4e8b9ad016b88b274c98', 'User deleted students/66011211071', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('8648670585fc4df58134fe5c99bcb283', 'User deleted students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('86759bf6fc76448e899ff3d5806141aa', 'User deleted students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('868bbfaf69a4432ea274c5c15836cde7', 'User saved students/66011211087', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('869f909812774d7f86c49951db134afe', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:15:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('86a57be5e091451b9bafdc68e4d311f0', 'User deleted students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('86b0779c3df54ee9b59ba16294d2310a', 'User saved students/66011211075', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('871e4b59d4a941b5be343371d4ea227d', 'User deleted students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('877b0e49807b46cca9754c37532b7eaa', 'User deleted students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('87880ea1993b4cd0a7569955d2097edc', 'User deleted students/66011211046', 'Exam Grading', 'Teacher', '2026-08-17 05:59:55', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('87a4a5c6aac94de8acb5ad947e86f28d', 'User deleted students/66011211060', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('87b00e1c69f24934a4a41dc720f2c4ff', 'User deleted students/66011211092', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('87c06d920b8f4199918efe300bd43d94', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('87c7b17b9e22476c8b2f454fa4afa517', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('87d1b46f33c446eaafc5959690771aec', 'User deleted students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('87d46fdf403f41769239a9aa45d3d459', 'User signed in', 'I am Boss', 'Teacher', '2026-08-17 04:20:33', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('87df3b8775cc47d699e66a710accad7f', 'User deleted students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('88281a7f113b4ec5aa7853db33c651df', 'User saved students/66011211078', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('888b6c9a27b94f0186b3debd939348e1', 'User deleted students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('88e6096860c041cb8232b8c2e4f85c3e', 'User saved subjects/1201111', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:55:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('891e30f95bbd40afa92390fb3837fcd2', 'User saved subjects/1201413/sections/5', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:28:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('892bfb54e37e457b8c28af30afa12d05', 'User deleted students/68011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('89737b67d13f4b8ca112513495aa3882', 'User deleted students/66011211061', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('89986c4277eb419388ee354893730dc9', 'User deleted students/66011211058', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('89b731ccfcc34c4dada6a01ccd533c89', 'User deleted students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('89cc92237ce2434795bc864b8db60631', 'User deleted students/66011211085', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('89d37240e09c4ec28e0c3302da41373c', 'User deleted students/66011211072', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8a163745d90e4958904b09c6a1ed9da1', 'User saved students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8a6cfc13c14449ac8ade87e32052331c', 'User deleted students/66011211099', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('8aa0aa6c44b642d5896fcb6f20871e5d', 'User saved students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8afa0296e5f744aab28b54fd8f3b1bf0', 'User deleted students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8b1401df75a4456ea6bbc50bf57952b0', 'User deleted students/66011211057', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8b15fcc0d43f470d96e120e014ef3eb5', 'User deleted students/67011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8b2ded72c0d84560a2f09344bd850670', 'User saved students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8b42b9c3563a4997a4e0b94945540259', 'User deleted students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8bbd38463c3e446ba6074a9634650034', 'User deleted students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8bf451aff47e4172ba4c173b4b4251d6', 'User saved subjects/1201111/sections/1201111_2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8c4443bb0ac5401e9cda7d32bf60f888', 'User saved subjects/1201413/sections/1201413_1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:02:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8c4f6bf708ac4ead8e7142678315fc45', 'User deleted students/66011211084', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8c873125072949ab823352e98969a862', 'User deleted students/67011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8cbe6296fbec4bc195c6491136e1af09', 'User saved students/66011211097', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8d1f869c6c5142f981b73895345fbfe2', 'User deleted students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8d64d66927a74a35a370b7b8a49db220', 'User deleted students/66011211095', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8d91cb5a488747f2904f7b888922c733', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:52:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8d92ebed63db4cb2930defd057d4e01e', 'User saved students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8d9cc5cfa36648eb8d7e57ed8ef9f544', 'User deleted students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8daea41a3c8242fd836a2e2493f51b52', 'User saved subjects/1201413/sections/6', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8de5b6d35a1f42f695c096543c0e068c', 'User deleted students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8e202aad1ae949ff90e1b09ef7ff198d', 'User saved subjects/1201413/sections/7', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8e3cf6cfb4db4b978764d9e52277c7cd', 'User deleted students/66011211075', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8e44026ff380476f9cb847b01f2d622d', 'User saved students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8e7ae9c7a5fb45f88014526c1ab8a4bc', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8e8168bfc20049d5ad59b8069b2bacd6', 'User deleted students/68011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8e939f490f4649a49d8264a7572a834a', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8eaf118cc47b49d881a5545b2e879e8e', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8eb810bd0a894977ac56c9943235a120', 'User deleted subjects/T0001', 'Supakrit', 'Teacher', '2026-08-17 09:18:36', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('8ee8790f726144fd9e0f75767f4081b8', 'User deleted students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8f0e910e287e48109446136a664d4032', 'User deleted students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8f19c43476684ec8b7b511b78f5f687a', 'User deleted students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8f6c96cd47c247cf8f65b0c557a9ff37', 'User deleted students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8f7f94f10bb4462eab29856887c9695b', 'User deleted students/68011211089', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('8fe2a68515f6462693e615d571b8066f', 'User deleted students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('901209c3a557499ba685973e6a14c955', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('901410fb526e4a1b9fa3a432477fe51f', 'User deleted students/67011211069', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('901477889c4f4f688a6243950e095936', 'User deleted students/68011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9028fe0a5db249f1b99d98712a31d3f1', 'User deleted students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('902e8bdf496347ceae3e7fd9647deff8', 'User deleted students/67011211067', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('903e0d8a774f4732a189c832c7ba1a70', 'User deleted students/67011211089', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('907e74efe5de442b9eb9b84c700572ae', 'User deleted students/66011211019', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('9086f45efbd1441b88ecc7ab9274b1e2', 'User deleted students/66011211082', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('90c681f1dd17439db6725e594b1a474b', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('911d5b82fabb4885a3cd7ea9daa689d5', 'User deleted students/66011211077', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('91223fe434c948e794f2a036dc89dba0', 'User deleted students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9126fcd5327545899f63956476e85000', 'User deleted students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('915f0ccb576c4cc7918a0b7ad7685d23', 'User saved students/66011211081', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('916e8132ab564616890b06910f3e200b', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('917ecf7598954bb8961c4a0251ca8032', 'User deleted students/67011211074', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9191a289002e4ebcab7fede0a471118d', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('91946a730a38450aa131177b2ca4b097', 'User saved students/66011211076', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('91d701a6dff34447814f58457f521291', 'User saved students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('91e01f484a654172a67a7f1c05a0d704', 'User deleted students/66011211060', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('91f69a2d46994f06806b1d36a0d48b02', 'User saved students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('92175634d212495b9e657ef884fbfd43', 'User deleted students/66011211067', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9217d1b35c54420cbb5627cf58883778', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9228dfe9c1144ccc96dbcd572221d372', 'User saved students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9243e45724b24087a9fa113244c2cd59', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('92b9a9c3a9744321b80499efd35a2f5b', 'User deleted students/66011211021', 'Exam Grading', 'Teacher', '2026-08-17 05:55:26', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('9302af13df1e4ee48f79dc55f6f8ec84', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9309d40434a04ceb966689233f2a67f5', 'User saved students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('930faf197c314fecafac8f249463f89d', 'User deleted students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9311e563ab7046deb6ffce45c1043247', 'User saved students/66011211100', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9351d449d892416790b11e1163904a33', 'User deleted students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9353f4e52dd249baa2d341071f22cbfc', 'User deleted students/67011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('937ce9065c334f8caa718cebaf6f0378', 'User deleted students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('938ce39845a545c185ef3aaee08cb003', 'User deleted students/67011211082', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('93e850bfcb8848b89e6accde92717366', 'User deleted students/66011211078', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9403bff4fd874901ae33ad34aefc466e', 'User deleted students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9434b2945c164e37a3d9ad4ac856a89b', 'User deleted students/68011211088', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('946666fc1b3843408138c475cd08aa9d', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9469383544c44bd9ab9f6f0aea0bf3f8', 'User deleted students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9472cd718d2b4e848142d698b5aaa238', 'User saved students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('94a20807cf124a9aa41ee69832da1ea7', 'User deleted students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('94d16951579344919f1f997264cb7759', 'User deleted students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('95261d2c28254409a675e0f688c91823', 'User deleted students/66011211059', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('95284ae1af884bd2aa6126024e2e129e', 'User deleted students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9566c94f6ad44b0fa3e9e3bd049451d0', 'User deleted students/66011211090', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('95932cf3abfa489aa7ed4fa84e3cb470', 'User deleted students/66011211069', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('95af30e194394cfe9477e4cd8f307aab', 'User deleted students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('95b3cc1fe26742ddaa5e67fea0b0e2eb', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('960d116b1cba4de3aeea410dffae0953', 'User saved students/66011211062', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('96300774bb264f62927adb8bf14b494e', 'User deleted students/66011211020', 'Exam Grading', 'Teacher', '2026-08-17 05:55:26', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('96481247c64b4d73a6444af962d1856f', 'User deleted students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('965a6010b3e4481d92567ef75b3ba638', 'User deleted students/66011211069', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('966d9fd02fad4534a3bde23c76d8967e', 'User deleted students/66011211097', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('96c272aab41e4fec88cdd0d10668d564', 'User deleted results/245ed458d4b949018e4cbf415c6ec058', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 14:08:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('974d435a21d348ee933675c46c6fa480', 'User saved students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9765110dc28340dfb8d697095409caf1', 'User deleted students/66011211063', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('97712ad3122d454bbcf92b513067c95c', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('97fb3a191dad4de4bda55abf6b1a4ec8', 'User deleted students/66011211100', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('982fc90c0e3546d39d2b7ddf5fa8b3e7', 'User deleted subjects/1201111/sections/1201111_3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('983869bd2e464a0cafbf966bc1ce4371', 'User deleted students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9839e0d95ad4448ea10ff80e6c56ea80', 'User deleted students/66011211074', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('98520d4ca75c49848f35779d14beafeb', 'User saved students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9867c4da234847259ecdf8f35bedfd5e', 'User deleted students/66011211059', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('993e429d39e04b24bb573468ffc747d2', 'User deleted students/67011211100', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9941c2b1092144c2b4292116e457a67f', 'User deleted students/68011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('994d2d2553d34844b8a73499ceae37e0', 'User saved students/66011211018', 'Exam Grading', 'Teacher', '2026-08-17 06:22:47', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('9981c89cc9964810b39e905541d7fc21', 'User saved students/66011211001', 'Exam Grading', 'Teacher', '2026-08-17 06:21:46', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('999ea6508df144e8a0bb16ad5e8a9f2b', 'User deleted students/67011211095', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('99c511a90a8c420098de9726a60f7811', 'User saved students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('99cedfe7c3174f95b3a0ac57a996b7f9', 'User deleted students/66011211059', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('99fa1029484f4441aeb12a59bafbda63', 'User deleted students/66011211064', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9a64ab2d13e844efb05a9a21217a5aaf', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9a69f9aeca0f45fb9c80446b6f41646b', 'User saved students/66011211076', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9a702a9e4e07475ab3f95516bb97f07a', 'User saved students/66011211092', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9a7d49cf8eef40f297eb887cf0dd66fd', 'User saved students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9ae30e9d7c5b4d29a776690b6c81deb4', 'User saved students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9ae3326c3f35432d94fb8c96accf56fe', 'User deleted students/68011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9af1424c61be497380101caabaf07d34', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9b3b953fd8094fc1b168bacd9d79c563', 'User deleted students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9b53f7906b6245a5bc2b415bf2b5ccc1', 'User saved students/66011211058', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9b683bce02774b68aebd644c80df368c', 'User deleted students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9b974b2a8cd84333a6cced269e3aaefb', 'User deleted students/66011211074', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9bd7a312980c4ebbaa4b830c923d3d73', 'User saved students/66011211062', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9bf48cd6e6914629b38ca89abf517f44', 'User saved students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:56', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9bff74e8bba84cfbbca82954cb7859ef', 'User saved students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9c1d0d81d98f4e90b40437159e17609c', 'User deleted students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9c3136b1bb234775a1795058d4bcabc3', 'User deleted students/66011211042', 'Exam Grading', 'Teacher', '2026-08-17 05:59:23', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('9c441aec52b44f1abef37dd8b5f3807a', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9c5b0d360cf946de96b844752441ea21', 'User deleted students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9c68cb05dc5f4028ab1690ccdce4d509', 'User deleted students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9c71922a18f643539e2eedbbbeb73b0c', 'User saved students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9c75cd524f58404282914574da37a5cf', 'User saved students/66011211075', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9c91e757459b4f60a9d893cd187486e9', 'User deleted students/66011211053', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9ccfa63dfc36401da60f5cbea290a17e', 'User deleted students/66011211065', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9d12303fa32f4b248e027adbd1b09d48', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9d713e4e29814c889b559e6dbd440026', 'User deleted students/67011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9dba9a177fad4e4190ddcea3a519e592', 'User saved students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9e17f960f6674e77a30ea89893b9d8ab', 'User deleted students/66011211010', 'Supakrit', 'Teacher', '2026-08-17 08:54:12', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('9e6a5bfc9b3c4d01838e9571f3bcfce5', 'User deleted students/68011211082', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9e82c5bf4d0c4d25993be8f8cc2d65e2', 'User deleted students/66011211060', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9eaf4d86a5624ffd860f22e217be45dd', 'User deleted students/66011211007', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('9ec605ffa862413e92cb16cae9842ad4', 'User deleted students/66011211054', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9eeee14ef99640fb9ed738bc7e2abaf2', 'User deleted students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9ef1af691afe4eacac06a863c6083472', 'User saved subjects/S101/sections/S101_2', 'Exam Grading', 'Teacher', '2026-08-17 06:17:25', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('9ef4db6986b049edaf18aee6ca60414a', 'User saved students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9ef53572759e4192ad195713813ceb10', 'User saved students/66011211072', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9f30d358b4444778ab2f5fae66b6ea3c', 'User deleted students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9f3fd9fa1c84412aa1ec2f3df5d3099d', 'User saved subjects/1201413/sections/All Section', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9f6f4b1b26664a948a90b40fd244954b', 'User deleted students/66011211037', 'Exam Grading', 'Teacher', '2026-08-17 05:59:24', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('9fb8b54cb3024ddf8db002cee1c7aa16', 'User deleted students/67011211087', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('9ff64861a7e94c669a01ebcd02859ad9', 'User saved students/66011211097', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:53', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a05341fc76f047c8bdc8ecbfaf4eaa16', 'User deleted students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a09498652bf84e26937e871a486b34d2', 'User deleted students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a0e9ec4574db4f48b974964f18c9eebf', 'User deleted students/67011211063', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a0ece15e9a0a440b8168cf4e8aec4889', 'User deleted subjects/1201111/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:26:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a0f40d44df5e4cde84b2fc760fb2ceae', 'User deleted students/66011211086', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a123aabdbaa943e287d8c5bae1682b23', 'User saved students/66011211055', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a13d5cdcef92484f9dd4ebc2f40e0f61', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:45:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a17715f60778462db7540eddd783216f', 'User deleted students/68011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a18a5cedf0e445009e05c5a4aaf714ad', 'User deleted subjects/1201111/sections/4', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a1b7b9cddd4148d79d5d2ed5afc29106', 'User deleted students/66011211023', 'Exam Grading', 'Teacher', '2026-08-17 05:55:26', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('a1bb7411a081428db0453b352713f8aa', 'User saved subjects/1201413', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:53:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a1bf05c711314f0fb65eb8b4b678bcde', 'User deleted students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a1c8e6ce2cf845dd9226e47736ef60bb', 'User deleted students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a1dfcfd5a33d46fe80a71038a257364c', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a1e819d3f18c4fca990988b4a8e88e29', 'User saved students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a2172b60c1da47049847a7b89b2d4f2d', 'User deleted students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a2505bfbcd5a4f2c91178160d6899561', 'User deleted students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a25db5ee5d5142efbb7b6b58e3ae8386', 'User signed out', 'Exam Grading', 'Teacher', '2026-08-17 06:03:02', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('a265a25f8eb74bd9942a6a3373d0fc7f', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:11', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a27be1fb96874101a1757a7d15fcb239', 'User deleted students/67011211060', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a289081b0f8b44cb94236b66d776e0c9', 'User deleted students/67011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a29bde97553d407c9045989c9c5d32f5', 'User deleted students/68011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a2aa9dc9367a4dd4bc8184fe6c463819', 'User deleted students/68011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a2abd77b09a1454793ed51c959b3dce6', 'User deleted students/66011211003', 'Supakrit', 'Teacher', '2026-08-17 08:54:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('a2b5af7740b54d90929951dd1e5882cf', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:14:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a2f224df9cbb49fe8f66b77507e168f4', 'User deleted students/68011211056', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a2f71affafb44cb6b1954de90ec556aa', 'User deleted students/68011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a30d9d2ef74e414e9250bbb3d0a30912', 'User saved students/66011211061', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:11', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a3353dcded544fd79db6cbd150c1fa89', 'User saved students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a3440c9e3c2e4d45876d7fb2fdfe1bf9', 'User deleted students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a35sn8icaamud8ry3piw7g', 'User saved exams/1101_1_test', 'I am Boss', 'Teacher', '2026-08-18 16:28:37', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('a378846ae0af42c4965dca383e75d89e', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a39408ec094a41d1a8925e305111ba5d', 'User saved profiles/66011211035@msu.ac.th', 'นลธชัย บุตรราช', 'Teacher', '2026-08-16 13:18:02', '66011211035@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a3a4db89e61b4077aef7472f48720ad1', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a42ab595c8994c21963db3666318f376', 'User deleted students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a44915baa0434cb0b1dbafd0d40e9650', 'User saved students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:11', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a4576c0174314bf49b45a75ac90ac8c6', 'User deleted students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a49bb112a36a4f20affd7c87d3b18098', 'User deleted students/66011211051', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a4ab2adfd7bd4a8da69fe4849a11ba16', 'User deleted students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a4cf528e4c7846188bc45e403ae0b49a', 'User deleted students/66011211096', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a50243c3aeb645388f6661c9c7908d9a', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a506e6e33f4d4e8a865eb3f32a5f3ecf', 'User deleted students/67011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a5075cfd4b6840dbb1e695cbd9520f38', 'User saved students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a51y1mu9gvdzdmda1jysr', 'User saved subjects/1201111', 'I am Boss', 'Teacher', '2026-08-21 08:18:15', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('a52c5c65c0ab4eab861b4911913b58d1', 'User deleted students/67011211077', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a564686d37f54eb990a724ba12764a33', 'User saved students/66011211066', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a57b4e9c00964d52a45c944355415a6a', 'User deleted students/66011211020', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('a610bfe8cdca431bbbcee82dc7eee47d', 'User saved students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a61e477568ed428fb2999b68504e410b', 'User saved students/66011211076', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a62fabb6f5d64fc58014c035a633eff3', 'User deleted students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a694a59683544d8e9c0a7e07bee811ca', 'User deleted students/66011211095', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a6bb5a9d350e4ef48b8379a658eadf3a', 'User deleted students/66011211085', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('a6de98b2b49c44a0b98fdb93a86f3e0b', 'User deleted students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a6e9b1a23b1c46a5897ff705c7e8ad90', 'User deleted students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a720207f16bc492e9f5aa68d4fd2f79e', 'User deleted students/68011211084', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a74137d85a554a26b09fdc4058b64aa5', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a747d3d38985464d8eddf1e668bd04d3', 'User deleted students/68011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a778615d74b44425832b80fbcacfc7b2', 'User deleted students/66011211045', 'Exam Grading', 'Teacher', '2026-08-17 05:59:54', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('a781adfcb67842d6a6f3b8a03b0b79b1', 'User deleted students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a790ca8ba6314c8e877903296e5a160c', 'User saved students/66011211086', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a7f6352e7e024a3ebc8ec3f63c85b956', 'User updated exams/1201111_1_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:17:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a822d2135b9d437ab75babf6c383f91d', 'User saved students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a8b2616eb55747849d393c2cbf310cbe', 'User deleted students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a8d5577214a74fc19b0d9502655002b3', 'User deleted students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a8ffc437e41e4c6982e428d5e37f2593', 'User saved students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a91acc06e1474807aa93d1e208d2bec9', 'User deleted students/66011211091', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('a935db503f06470f9802577fec785959', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a951e19f17ff453cbd1dd2ddddff63b2', 'User deleted students/66011211087', 'Supakrit', 'Teacher', '2026-08-17 08:54:12', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('a95eb9c25eb147ae81197a69c41c9d13', 'User deleted students/66011211070', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a96312a046604acaa442af857318903b', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a980f1aa6ba640cca1392c87c5dca9ff', 'User saved students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a98248ad42144ddfb33fde9c4860d6ec', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a9b5f87d444b4a9dacb801e75fdbe345', 'User saved students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a9dfc3a490a84972b6aac2ca00a6838b', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a9e879f70e664a6297e80c45a2f2c5fa', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:56', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('a9f55e3d1a7341a793096e6ad978975e', 'User saved students/66011211099', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:56', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('aa03749b05cb4a6dad2150ee6296bce6', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:50:21', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('aa08ae78f2d14b089270ecc49a6d54e0', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('aa8681e111a846d19b7d80fc3a16c5c0', 'User deleted students/66011211091', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ab0bb1806d634b6e8a2f9d16336f95f8', 'User deleted students/67011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ab1974c23f354beca4911e5d49b3e3da', 'User deleted students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ab6b2d7550894d08a94795a556823062', 'User saved students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ab76b05041154cc4bc2fff94cbe9cd78', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ab80ebd1e9864e48ba6f7dc30da57f9e', 'User deleted students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ab864d043ac54861bf1b4dac80cf52be', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('abcf81f846c148799507ba1794643c8e', 'User saved students/66011211093', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ac163459534d4154808105950f1c868d', 'User deleted students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ac26253b9a4f43daa954ffdfa91dc906', 'User updated exams/1201213_D3_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:18:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ac62040c8fb64e27bebe2b2dcf574843', 'User deleted students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ac8ffe7cf5514c8dba462586421f5361', 'User deleted students/67011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('aca27839a77b4fefb8151670046a9fc8', 'User deleted students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('acc8ae22d7714359acb0f6a83b2538aa', 'User deleted students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('acd2675506a048b4880a08e2865351d8', 'User saved students/66011211077', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ace9c43705b040858952d465f8ac7b01', 'User deleted students/66011211036', 'Exam Grading', 'Teacher', '2026-08-17 05:59:23', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('ad5bd62b7b6a4913acb0a6ef6a0eb7ab', 'User deleted students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ad81bfcdd7ba419c9e71817f07a39d60', 'User deleted students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ad9d5cc61cb24b19b629bd8dfa1dd05e', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('add4a416cecb48df8cc7fe356dffcd34', 'User deleted students/66011211060', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ae320bca4e1f4947bc41e52eaf51e3f1', 'User deleted students/68011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ae4ff6db4ed0497fadb1ddc7519fec1b', 'User deleted students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ae53fc56f1fb4c378de2de8277e0f0e5', 'User deleted students/66011211070', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ae57abea10a540d2b8cab90ef1c5ac17', 'User deleted students/68011211068', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ae9ea3e24a65439081e11196c6d30b9c', 'User deleted students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('aeebcc8937f141bab633ab8a86ea808c', 'User saved subjects/S101', 'Exam Grading', 'Teacher', '2026-08-17 06:17:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('af0080aa81f1482e8e5a412961bfd43d', 'User saved students/66011211098', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('af36333895134d1b8049af06b8b17044', 'User deleted students/66011211092', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('af60b03fd9454a9ca50d040e94c74208', 'User signed in', 'I am Boss', 'Teacher', '2026-08-16 13:18:33', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('af694c735aa84bac84fe6114e5d9fa42', 'User deleted exams/1201213_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:35:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('afaaa321c7954cb08c6cf6cea7eab320', 'User deleted students/68011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('afcdfe97589f488b834ba2f4e1de9d8d', 'User deleted subjects/1201413/sections/1201413_4', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:09:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('afe6b63798874525a9567e91d909bd95', 'User deleted students/68011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b0386fa7b90844c9b6d0fbe81c945575', 'User deleted students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b083885f34204c7b9947137731fc6808', 'User deleted students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b0853e8955af495b9153167d135a21d2', 'User deleted students/66011211054', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b0abb7aaca014acc82601caaed54b198', 'User deleted students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b0d81f84738a4162840330b4c4cb77be', 'User saved students/66011211002', 'Exam Grading', 'Teacher', '2026-08-17 06:21:50', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('b0fosvgy04drkzmpt76px', 'User updated exams/1201111_1_test', 'I am Boss', 'Teacher', '2026-08-21 08:42:43', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('b1143a0d8bda44cbb383ec087e4e6cbf', 'User deleted students/66011211032', 'Exam Grading', 'Teacher', '2026-08-17 05:58:49', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('b1ec1c6fd973446bbe29b3883d731d7a', 'User saved students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b1ed14a837f44b838c5d99449b8895f2', 'User deleted students/66011211055', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b2274e428e9e4fbc899e2b74bbb4fb58', 'User deleted students/66011211053', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b23a114a68154ae89cfc93016584e25a', 'User deleted students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b23b26cc48e048f4817a71249ed5f9cb', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:09:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b265ab9e76f34329ba1ca353923439cf', 'User deleted students/66011211057', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b2795b58496c477d843ee7facbd38af1', 'User deleted students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b2aca4f8344b4aed879d954f11027eec', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b2bce1ac30af464e8a4e7da79c3810d8', 'User deleted students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b2cccf444ab74306a69d5f9e62583936', 'User deleted students/66011211083', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('b2d04c5c7eea47e9af16445ed5000fee', 'User deleted students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b2d39493df9b47db9051488ca0574e15', 'User deleted subjects/1201111/sections/All Section', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b2f87c25bcab4869807310d96cfd915d', 'User deleted students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b2fecaa1551640df99d29f8938d83e5a', 'User deleted students/68011211091', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b314786265f1403aa6bcd6eaaee0958c', 'User deleted students/66011211071', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b318fabec43c44118c89f276e7126c4e', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b379a878232944ef8a284e3a5bee41cc', 'User saved students/66011211055', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b38afcee13d1498c94a51f1faea85bd9', 'User deleted students/68011211054', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b3ef696581544e2f8e134295dc5a6d75', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b408a182c27c40009b2ee6119220eb0b', 'User deleted students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b4dbc4f4dfc44855946364c0a964269b', 'User deleted students/67011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b4df76ec079f495e83a8fe9ebfe709c5', 'User deleted students/66011211069', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('b4f08725b5594cc885cf61713e3a8de2', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b4fedc75fa7949cab4a9a80f05be7894', 'User deleted students/66011211064', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b502e7430fb542909218e0b3c09ac0fb', 'User deleted students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b5096d5a9840442085f8ddbbb60409ba', 'User deleted students/66011211100', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b515019793194f02b92c9c7c8b63050f', 'User saved students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b5280616e20e4e2688639d0c9a1c2321', 'User deleted students/66011211098', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b5309031a8b046758652e6f00b79b145', 'User deleted students/68011211053', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b54f1b7b9aa3404cb229c566fe0e7e31', 'User saved students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b550421b029b4d919270fc9bf090341b', 'User deleted students/66011211015', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('b576a17c60194c308dfbd47eceb2933b', 'User deleted students/66011211093', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b5825dc60301485c98f3da79ce33b00a', 'User saved subjects/1201111', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:40:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b59f53c1052540d7a124e907907eb159', 'User deleted subjects/1201111/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b5a4975877f3437aae91e4f5bf835135', 'User deleted students/68011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b5ad3805ea9f4798b442e342ac2c1bd8', 'User saved students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b5e4b8044fea46098aa39c796b101d29', 'User updated exams/1201413_1_Pro2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 16:47:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b65132e6984a47bab43afa98d2174cba', 'User deleted students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b66016326d3b4962954d7b31b3642d68', 'User deleted students/66011211063', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b677c4dc059e4cb8a540d09da2d983fb', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b68167a5c1c2427ba5857a51ffd9caca', 'User deleted students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b6970cb7af5847b19ed3bbf494e697c3', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:15:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b6cc4548604540dba567a4bd33798095', 'User deleted students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b73a4883d61e4e2b985475c64d5ff4ce', 'User saved students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b7425eed1ba74726bff63db05fd0ea11', 'User deleted students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b75fa1f21fab468cbed814e0ef1d4f7b', 'User saved students/66011211089', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b760b37bc20f4c3ea0f92331b8010181', 'User saved students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b77904cbffda466eaf3c14632d007163', 'User saved students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b8165d44844e4b6ab1b45e4b788f8d14', 'User deleted students/68011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b81c123d0ed14b4299c9143d7eaf04e8', 'User saved students/66011211059', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:23', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b85bdb221182439a99cc047a928adacc', 'User deleted students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b8665933b28d4227ac04c64efcde0a76', 'User deleted students/67011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b8921b3dc4d943b5a52905209f40b37b', 'User deleted students/66011211096', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b8db3dd03c184992932558d2fb6c40ed', 'User deleted students/68011211070', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b8e206ea71a647ec979335b3ab15a61d', 'User deleted students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b90de32b0b1345568891fa167f6ba047', 'User deleted students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b915b94d7d3646e399e447cb0e620569', 'User deleted students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b925bc21da044492a81ab773a273e2e5', 'User deleted students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b929a59f833947468761a4fb1716ac02', 'User deleted students/66011211063', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b9b62fef69e9498a818845b1da46575c', 'User saved students/66011211059', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b9ba02113d7848cbafcf86f2f16770d8', 'User deleted students/66011211070', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b9cdc01f05864b269a3abc7c8ffe54ab', 'User deleted students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b9d4e917af984b97afc3be77875dd45e', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b9ef15982930452385cab6330d9896ad', 'User deleted students/68011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('b9f5ea2cceac4d749c25af742f2fa407', 'User saved students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ba04464864c341f380101187845aafe7', 'User saved students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ba22a8b5d008485eac67835f2cfa0d50', 'User saved students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ba3cb29bea8940b9870d1f94a0c62888', 'User updated exams/1201111_1_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:22:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ba4dc526421543ee929b382276ec53a4', 'User saved students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ba7a4594145043dca055452f8a81c20c', 'User deleted students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('baa06b38cdf542ca99d6787719e45982', 'User saved students/66011211057', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bad72d45965c4a9a886ba5126aa8454d', 'User saved exams/1201111_1_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:17:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bb22c6af6f814fa89682fe74decf83cd', 'User deleted students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bb5793859a37433b9fbac83efdbc4fee', 'User deleted students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bb7315eaac104fa3b65d69c3801f2322', 'User saved students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bbb548e194a24db8b0744939225cb55f', 'User deleted students/66011211079', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bbcc604882464cdc9b4d1ba24f884a1c', 'User deleted students/66011211090', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bc33acd0204c427e8e8df511429033ae', 'User deleted students/68011211052', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bc5060fb520f48dbbec01ae789daa81b', 'User deleted students/68011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bca285c025c14b429a1043509cb97dd9', 'User saved students/66011211089', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bcabe542b147493ebc7f2b21223a90e8', 'User deleted students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bcb627cbcbbe4705a3621221043bcf91', 'User deleted students/66011211079', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bcf8e8310bda4847bdb982780cb5a037', 'User saved students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bcff97a92a074bf1af07a6bcfd0b05f8', 'User deleted students/66011211088', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bd078659d02f48709fc18d4696c104e3', 'User saved subjects/1201111/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:46:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bd0ccc6c31f24dbfb29f988904bd1fc8', 'User deleted students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bd0fc93995074e859bee32b0432c9652', 'User saved students/66011211070', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bd2755a666094c68b254fa5d49461813', 'User deleted students/67011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bd38e3dad1754cf0a599349398afeaa3', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bd49863e7cb74c24b6b3b65a5d1311d7', 'User deleted subjects/1201413/sections/1201413_2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:10:56', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bd602f411cde4f288eae1d2cb51f26ff', 'User saved students/66011211061', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bd736f7cc37b452e82b4e4acc01d67fe', 'User saved students/66011211004', 'Exam Grading', 'Teacher', '2026-08-17 06:21:57', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('bd94eefa8fce433484ff921fa6379ee5', 'User deleted students/66011211086', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('bde90b4c9c634900a77f06e321e95c73', 'User saved students/66011211074', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('be27fff45a5f476da109feb20ab9a9c9', 'User deleted students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('be348dd1aae74ff09d217377e337f0fb', 'User saved students/66011211069', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('be3f9525b2584d3aa410e6f082414cb7', 'User saved students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('be416bdd7155406ea1525cea4cc3b306', 'User deleted students/66011211066', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('be658b4e373544928dbdd5b3417c137a', 'User saved students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:54', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bea3da51ac0546d98a1f32f8d47e45e8', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:45:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bebc4a5898c341b09afd7170c9524e8b', 'User saved students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bed6556a41b94f2dbb9c8cd834aaa8f4', 'User deleted students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bef6c5a4fd4e40c0a943015fa0b4eb86', 'User deleted students/66011211087', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bf1e4ab40ffc4b2d9cf38e1e4aaea21d', 'User saved subjects/1201111/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:46:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bf2db6a60a0c4d7a8c1ddb8ab54aee6f', 'User deleted students/67011211059', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bf4cbb71a77942089b5318fff6ce05c8', 'User saved students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('bf6c397c1a4a4cd68214005e24cf552d', 'User saved students/66011211013', 'Exam Grading', 'Teacher', '2026-08-17 06:22:30', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('bff07524bbce460e8631a9e2404ddde0', 'User saved subjects/1201111/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:14:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c008a8b5d0664f91aa4f859456dde805', 'User saved students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:56', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c02d3705cdd54ae4bf17fe818873f0fb', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c058fcdacacc434ca1914113ce410c29', 'User deleted students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c08b4f64d5cf477d88dee4b58622a653', 'User deleted students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c0axr0jptbm9bng89csq7q', 'User saved students/66011211035', 'I am Boss', 'Teacher', '2026-08-21 08:26:46', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('c0bf885c8c904630bb2574b8e5e2a03f', 'User deleted students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c0cbed7a264b4ef6a0fae3e9d77b4b26', 'User saved students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c0e2305f2de0497e93d324047ac0c765', 'User deleted students/68011211078', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c0ee03d6d41442dcaef7270968008d93', 'User deleted students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c1094e6f6f5e4eada16016210e936fb2', 'User deleted students/68011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c10d0bb8c09343f7b60016277e63e9e6', 'User saved students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c120159b8bd44b06a841731a340228d2', 'User saved students/66011211135', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:05:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c166bd39b3934d76b1b28ce2199747ed', 'User deleted students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c1946ae041f04bafa5704cbc70c0e827', 'User deleted students/67011211079', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c1b3c6b88dc546198419ad862b2c3c33', 'User saved students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c1ca641a86d84bccaa9c0f1232b8b777', 'User deleted students/66011211080', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c1fc353d66d14236b656c468fc1bb7b9', 'User saved students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:26', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c202b595c86f4db39afd85e3de802376', 'User deleted students/66011211001', 'Supakrit', 'Teacher', '2026-08-17 08:54:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('c237dbbefd1841c7af4e3a0c3ce16d9f', 'User saved students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:54', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c276fee0af9f4eaaab4e0bd89afeb156', 'User saved subjects/1201111/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:57:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c293c86942464bfdbd4622024aa9d0f6', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c2a5022e7b0049dd9b3f4b47c82cbfa6', 'User saved students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c2a9a80b59a1453eaa6e15c1c44d5b57', 'User saved subjects/T0001', 'Supakrit', 'Teacher', '2026-08-17 08:54:49', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('c2aefe9d0cae4692a2b6cc45129c34c3', 'User saved students/66011211090', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c2c07319fa0a4140b566974548467f23', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c2d4513e7d1a4520a5d962b7db5148dc', 'User deleted students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c2f5a6f020e544b1bf36889483d81ec3', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c3255373b61b4446b5e99602e3b46983', 'User deleted students/66011211083', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c331671ede32438b97bca79fd6584648', 'User deleted students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c3627427900447c9a8d92af965ca7cad', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c36755bc543a403da7d4a51d4e47b42c', 'User deleted students/66011211093', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c380cfcda87f41cb9b0b836c2f341595', 'User saved students/66011211068', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c3dca154b6f74a7ca8354255c1e5c5cd', 'User deleted subjects/1201413/sections/7', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:13:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c42ecfa60acb423d83db797ff0a82592', 'User deleted exams/1201111_G1_TEst', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:16:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c432a37faa8e4fbb92e8ec44fca6a3ba', 'User deleted students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c4578f679a5d4d5fab687c8fd26de077', 'User deleted students/67011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c47a7cb8358241f18ed08a10e23a9aa5', 'User deleted students/68011211079', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c48c1d2ecbdd4cf9a45b1e8319c5b3b9', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c4919efa52ab412992210a66b1d238ef', 'User deleted students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c4ba045be88d4e3da701ef9e729f173e', 'User deleted students/66011211011', 'Supakrit', 'Teacher', '2026-08-17 08:54:12', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('c4cc2b252af44a2da2c39cafa97b5657', 'User saved students/66011211080', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c4f062fc77e94a87a508d613931c7551', 'User saved students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c4f1137924184385953cebd62a9d945a', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c4fd5d3e0250463abe7f7226c7138fa4', 'User deleted students/66011211092', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c5001ff7a5f142bdb3061871cd48173b', 'User deleted students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c51b1c395a3a49f7b2856bef0d373429', 'User saved students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c54cd4e8ce3748bb866b3a49672230e8', 'User saved students/66011211074', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c5747d9713d946c0b7017650b834a3c8', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:11', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c5fc13a00add44c8a8e427f5105735d2', 'User saved subjects/1201111/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:14:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c5wdyriq3d2vg7i9gigve', 'User deleted subjects/1201413', 'I am Boss', 'Teacher', '2026-08-17 10:09:19', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('c603cc18dd9a4f2f9bba327a3e899348', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:43', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c60a35704d3c41269ed2eea1122c921b', 'User deleted students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c61233435f1d4519b8c37df6ebf2a011', 'User deleted students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c61df2fbbd3547b4b59cf9be386f2599', 'User deleted students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c647fc21b6594ff28a6ec4cd7b490b36', 'User updated exams/1201111_1_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:36:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c64be47cfb334855be743f7eb17db9a5', 'User saved students/66011211064', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c6cff637aab244e3927561729af8ceda', 'User saved students/66011211082', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c6dc8d2b313f4a5ab335d8d006ebec50', 'User deleted students/66011211091', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c6fdeca7d3334ed5b94da738b08c214f', 'User deleted students/66011211093', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c71c443fa3e248f48ea61ce2010557d1', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c7265af3a8004360ab87e2e602d01570', 'User deleted students/66011211022', 'Exam Grading', 'Teacher', '2026-08-17 05:55:26', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('c72e232384de4b0abdb5e3cf6c4be978', 'User deleted students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c79b84a19fa74a879473aa0aeb55488a', 'User deleted students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c7aaca437dba442c9eeb0d31936ac68d', 'User deleted students/66011211085', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c7b17ff98ca9413f96b5de5056662249', 'User saved students/66011211073', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c7b1bb203758436da5995b1379dfd7bb', 'User deleted students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c7dc8b282cd54588a212f6e5050da1b5', 'User saved students/66011211010', 'Exam Grading', 'Teacher', '2026-08-17 06:22:20', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('c81f41567b3540369ab4d007ab9dcaa9', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c8325b1fb3b547019a29b0ab5e8b9325', 'User saved subjects/1201413/sections/4', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c84ef04267554b74b665e31605b7a999', 'User deleted students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c85bfcee8dc34863b85ef912c7cd699c', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c86fbe83094c436fa9a5872f1a5c998f', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c8fb879bba944f958b13aca2906d5402', 'User deleted students/66011211094', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c8fc354780204a739a7d85c5f336773b', 'User deleted students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c910aa00032047f19e010774bda27fac', 'User deleted students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c92b387572bb4d078fc17564401d2a9e', 'User deleted students/66011211052', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c935914534744df4a13c83c40314a430', 'User saved subjects/1201413/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:11:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c9364056e05144afaedaefabc26246d6', 'User deleted students/66011211067', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c955c4721bdf4deaac804d453b36dd45', 'User saved subjects/1201413/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:28:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('c9da1d66162147a5b3d4eaf51afa24da', 'User deleted students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ca2258ba16c44bb9b5d07460fd65d176', 'User deleted students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ca7136eb967c4cf2a1acafad972ae7e6', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:11', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ca8615ca738b45539227df8a7c794266', 'User deleted students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ca9d2192fc794caa90f9865537536c09', 'User deleted students/67011211099', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ca9f3449d7ba4999a0d50a16119b6aa0', 'User saved subjects/1201413/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('caaa8a5a94da4d6e985195fede281026', 'User deleted subjects/1201413/sections/8', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:13:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cb315e985c034230a8d436ab92dc327c', 'User saved students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cb392048748845128cd926f502a22db7', 'User deleted students/68011211087', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cb492ca3cd0c40e596006482d641feee', 'User deleted students/66011211002', 'Exam Grading', 'Teacher', '2026-08-17 05:54:42', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('cb576c84abd04b778c286267ced63640', 'User saved exams/1201413_1_Pro2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:47:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cb6b5fde945c475c934f020f7d5d3dac', 'User deleted students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cb7739bf468140f39cf26db37dcf63e2', 'User deleted students/66011211098', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cb8ccff03b9146de9d2d49261a8ff807', 'User deleted students/66011211077', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cba57643ad3c43ec958874ab99088eeb', 'User saved students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cbd35a7ddf1342fb8539f53998ce575c', 'User saved exams/1201213_D3_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:31:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cbdb98b135f54391867aa631d22f427f', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cc0d1e388f804460b03ddcf7b75dc6c4', 'User saved subjects/1201111/sections/1201111_3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cc44b475315a4120a1b2e909d9c29a09', 'User deleted students/66011211084', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ccefcd2918e4441aab92fe6f89cd8ed0', 'User saved students/66011211095', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ccf564e29d13419a9ff6610f5a2050dc', 'User saved students/66011211054', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ccfe25aa5d1f4d05981451959f83107d', 'User signed out', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-17 08:42:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cd07273051b741b78aa6854ac35d1413', 'User deleted students/66011211076', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cd0c6d1a1a9b4565b812e40611aed68e', 'User deleted students/68011211051', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cd6fc6d459ed4040b68b1697505da35a', 'User saved subjects/1201413/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cd8c8f82573f4e0e982f24a4ac07ec0d', 'User deleted students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cdc06dae7e264e9bb2b4d8a4be7458b7', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cdc506f5c8974b06a241ea8ebfcc1b53', 'User updated exams/1201413_1_Pro2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 16:23:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cddf6d76fafb4354bf42872aa47b6c0b', 'User deleted students/68011211099', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cdfd041bf3e74920b60782d4fc53e4e5', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ce390f8c94de490a858e243a559cc40a', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ce403c462e44497e846962c38d2e87de', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cee66e7ba8df4019a3d0aa992fbdfb10', 'User saved students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cf0b198fe17d4c66b61c1fd4ba477340', 'User saved subjects/1201413/sections/All Section', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cf100b42887f40629008e48a241748bf', 'User deleted students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cf11830ad5a74eb1b195309849113a37', 'User deleted students/68011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cf1d4d82723d43d4a3613bc940a0fbb5', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cf547c1fbcaf4087925d659325afb248', 'User deleted students/66011211072', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cf56aea5a2be4e248b9a9c5f558debe3', 'User deleted students/66011211067', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cf72e7e5846b4eb58c7496d779e9592e', 'User saved students/66011211069', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cf7d7b0bd05e4cdf9321c5d418cf71e3', 'User deleted subjects/Project', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:10:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cf811a7e3bae4cdeb8f32855a55e8309', 'User deleted students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cfe95ee55d864d84aac8409ca757b9f4', 'User saved students/66011211003', 'Exam Grading', 'Teacher', '2026-08-17 06:21:53', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('cfec415e6dff42b7ac777f814e8c291b', 'User saved students/66011211096', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:11', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('cogsh4o2yqmqtdakxnwab', 'User deleted students/66011213', 'I am Boss', 'Teacher', '2026-08-18 16:29:19', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('d05adbfe6ce849fa80dff512cd325e4b', 'User deleted subjects/1201111/sections/1201111_2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d07e9e9e47dc436399bedd0661374566', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d094aaaa5a4a42a3b13f1a39c9f07338', 'User saved students/66011211008', 'Exam Grading', 'Teacher', '2026-08-17 06:22:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('d0b9955f40e548349cb1e1a5c01193f0', 'User deleted students/66011211084', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('d0e588012b8b408c916ca9bffa994d48', 'User deleted students/66011211004', 'Supakrit', 'Teacher', '2026-08-17 08:54:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('d0eaab83de23494eb07141fadef734ec', 'User deleted students/68011211066', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d10cc2681f9445ea9b669bbc779ab595', 'User deleted students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d1306e6df9d140a4a479cb5139cbb14b', 'User saved exams/1201213_D3_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:25:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d131ddb3f87b4ac0b22a1a667d0c4fdd', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d149e715d5b646d1a02a5b86c0ad7191', 'User deleted students/66011211059', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d1628196b49c4c2ea003dcadb25a5040', 'User saved students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d1748f4a381148428f56d060a57f013f', 'User deleted students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d1f9726a8e20405fbe341bfcc93725ab', 'User deleted students/66011211074', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d21c7adf9e3f45bbb448dba13d8b0a78', 'User deleted students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d2336d80c58f49b9bcaa79d9a60d6ead', 'User deleted students/67011211057', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d2663d3a3a32431e8823d2c4db620256', 'User deleted students/67011211083', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d2681d7ee2db480e996e22d7b53829b1', 'User saved students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:56', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d26d2610bcc34cd5a186155ec6f82f2f', 'User deleted students/66011211075', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d271df3db3c4494bbf238b5d3e8e318b', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d27ff161caf54b21bf995164ad07e17e', 'User deleted students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d2824299b4e14b2d8456835c6b81d007', 'User deleted students/66011211061', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d28c245a895c409890ef242433a2172a', 'User saved students/66011211015', 'Exam Grading', 'Teacher', '2026-08-17 06:22:37', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('d30846c313164f88a549f3c006ec2e8e', 'User saved exams/1201111_1_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:22:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d33567a5041c4975904dcd1f8dda7a22', 'User saved students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d35c48e7c40842a68c44a1965ed9f233', 'User saved students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d3853f83a06d4945899d6cb9e7aa6d56', 'User deleted students/66011211055', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d39dbc8f91c84f51ab50899e692beb5a', 'User saved students/66011211012', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:50:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d3cb81bcde514f6e84dfa3674523d1d2', 'User saved subjects/1201413/sections/4', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:28:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d3d4955009ff4526bddc1187caef0ddd', 'User deleted students/66011211083', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d3e4a288a3474eddabfbeaaebdcde258', 'User deleted students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d416657583ea45a888c7b46829951e9e', 'User saved students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d427ee86841d4d128109c94852881cbc', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:31:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d4ac9a9930e6469b918b69c53d24af7a', 'User saved students/66011211099', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d4cb5a1239464668ae8690dcf5df7289', 'User deleted students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d4f096506523471f8a7eb4215cac40ea', 'User deleted students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:48:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d4fd77f07b59482bbad36826e179ce81', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d5073b00047c4ddaae992011ac7c4720', 'User saved exams/1201413_1_Pro2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 16:23:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d52a04ba2e0d47a39bd9d04e3fcf20c8', 'User deleted students/66011211099', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d54d7d97e4f44120a8c6a67ef890736f', 'User deleted students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d58fdd997b224c9fb8b4398f6d505c52', 'User deleted students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d5d3e6i1jefj4lr2dvfz48', 'User saved exams/1201111_1_test', 'I am Boss', 'Teacher', '2026-08-21 08:19:36', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('d5ec9a4bb128465db746e59a855073bd', 'User saved students/66011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d5fa2c14a47d499e95ad79305938d185', 'User deleted students/66011211075', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d60e7ad3c6f646a18dd51bca32b71680', 'User deleted students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d66c7a99701849319484f6c04c5cc050', 'User deleted students/67011211091', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d6b269196c3d4fd184ba8b255b15c53e', 'User deleted students/66011211091', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d6b83061a38b433491440bd5017519be', 'User deleted students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d6c90c69996c4e59a7f241cbcdb7fc8b', 'User signed out', 'นลธชัย บุตรราช', 'Teacher', '2026-08-16 13:18:22', '66011211035@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d6c9cd0c08e642f58ebd79e481445784', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d6d5a9f4c63c4c83be2e9efe267c5818', 'User deleted students/68011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d6f6d4810b164836b66915c458ff8933', 'User deleted students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d7582348204e496eb04fabfd65546cc1', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d76322fcf28748b38a0db052385a1dc3', 'User deleted students/66011211051', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d766aae480514c0cbb974e050973ebdf', 'User deleted students/68011211055', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d76a0d0a9d8e41a0be38b5136db8ff93', 'User deleted exams/1201413_1_Pro2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:47:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d792ae842f334595ae421a7564376100', 'User deleted students/66011211071', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d7aa4f47ae3d4e26a8b36825314c4cb4', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d7c11fa689a148b89b88ed27a8047047', 'User deleted students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d7dce8fe11c6434bbc63fe276e539793', 'User deleted students/67011211078', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d9023e10326d4f9fa590dfb7b8d9fd9d', 'User deleted students/66011211081', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d9651af659c04154a3588b9836aeb17b', 'User deleted students/66011211082', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d98b8012a2e44d608853ffcbd66d17c3', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d9a7046c03fc4b4cb3126889f797a4c3', 'User saved students/66011211079', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d9c6fd9e211848b78d03b4fe2dfa03a6', 'User deleted students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('d9ca5e9387674386a0c445bd992f5af4', 'User updated results/75fe2c46ab9c450d8235a7540ab5dc72', 'Exam Grading', 'Teacher', '2026-08-17 07:44:16', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('da1ac262b2b04ddaa8be3669dbf70750', 'User deleted students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('da29ea404467499cb1de13945a32c0dc', 'User saved students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('da39e0541fb54a2aa96bd9ac1c5793ac', 'User deleted students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('da81825ad403465ea66bd5df9771dd28', 'User deleted students/67011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('da8a0cf7b758450085d533adf5c86007', 'User saved students/66011211090', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('da8a0e333f154ec0a685ea5950389835', 'User deleted students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dabfe5d631d44322a065491d2616270e', 'User saved students/66011211007', 'Exam Grading', 'Teacher', '2026-08-17 06:22:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('db134e7341434ff4a280d16e0eea545d', 'User deleted students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('db170bf58461461db0c325734008e2cd', 'User saved students/66011211009', 'Exam Grading', 'Teacher', '2026-08-17 06:22:17', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('db4ed6d42741467590358ffb441634d2', 'User deleted students/67011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('db66c38f67f3433a90c684a48e3fa0d5', 'User deleted students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('db761ed494834613847079be7f4152fd', 'User deleted students/66011211087', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dbb90b9f1eb544ddb8fbab39ea368506', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dbba901b68f246a79ea22f75e1554db1', 'User deleted students/66011211055', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('dbbb16124b2241dca36b01b2c732e7cf', 'User saved students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dbca2bc775544d00b0033a91602f11d0', 'User deleted students/67011211070', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dbdaf16b3b7e46469b9bb6a8f2e08201', 'User deleted students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dbfa490949fb4ac59406ebe79ee96de1', 'User saved students/66011211053', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dc0727adcf434ca5a039ed7f7cf88b30', 'User deleted students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dc1409ccf3da453f8c1649e0f0a62d45', 'User saved students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dc204199ff06495bb0e327955e651f90', 'User deleted students/66011211009', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('dc2da295ce544c0799ce45a30509e058', 'User deleted students/66011211008', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dc55f5173a5b4561b26d5b01aac46537', 'User deleted students/67011211056', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dd179b9004c84fc98a54978290389caa', 'User saved students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dd41aa390e6748a9b0d7692950a58f44', 'User saved students/66011211090', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dd751fd2c4af4a1ca0bc85a5750aea38', 'User deleted students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('dda3f5ef2612442aa6c2086a5b4a6c2a', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:12', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('de2e96203c884619b46d74ea89fbe570', 'User deleted students/66011211001', 'Exam Grading', 'Teacher', '2026-08-17 05:54:28', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('de37b1314ce44284aaefb3d1efb4a0cd', 'User saved subjects/S101/sections/S101_3', 'Exam Grading', 'Teacher', '2026-08-17 06:17:25', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('de3c378ded5f4cdd8f08db40f9030336', 'User deleted students/66011211016', 'Exam Grading', 'Teacher', '2026-08-17 05:55:26', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('dea720189edd4917baa28a89f018d718', 'User saved students/66011211098', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:39:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('debc2b7e4b344268ad06db73a8ce7e6e', 'User saved students/66011211084', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('df3c65eaec7d4a419581c223d1af25c0', 'User saved students/66011211073', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('df559f1475bd4208a59d9034292b7985', 'User deleted students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('df8700f3b59046b89c0c1ae32beedbb6', 'User deleted students/67011211064', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('df976aff04344ecb8708b7c0a5d79ca0', 'User deleted students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e01e032f28b44cfa86c32201540957aa', 'User saved students/66011211092', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e03bec8b5cae411b98f9182e649e3bf7', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:50:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e04e045767ab4fef929e65a427dbe36c', 'User saved students/66011211032', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e0a170728d74471ba49217048c4ba345', 'User deleted students/66011211078', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('e1002937dd9b41fb8ceb4d0058323d08', 'User saved subjects/1201111/sections/3', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:14:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e13ea50b794341e99d153a473582b430', 'User deleted students/66011211100', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e14793a1570d4748be09c3df4e3e3060', 'User deleted students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e15de4520e0d45858cc398054d2ecff1', 'User deleted students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e16bf4be496f47c1bd47b2260c2beb80', 'User deleted students/66011211055', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e1b0b461662d4feaa840827899d63f58', 'User saved students/66011211080', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:49', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e1c564173ca548feafdcf84178e9804e', 'User saved students/66011211079', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e246fa8d697a41799ba415730df2ea66', 'User deleted students/67011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e25c42eb2ee24011a1f722b0ba9c0b5d', 'User deleted students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e2bb3f1cb820420d87825455fdb1aac0', 'User deleted students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e2d75a3d42b54f1e84c131dc0543b503', 'User deleted students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e32f3fe5387a423a9ab8337bb0b37f2f', 'User deleted students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e34031d545d34143832746117b030f89', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e3cc46b1a7764b24b777697401e4ce6a', 'User deleted students/66011211100', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e4082da15aac4c3981d36344f267c8e3', 'User saved subjects/1201413/sections/5', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e4169d4f926e4015b811b6334e6811c6', 'User deleted students/66011211088', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e434f74505614de388b9aaaac4194a35', 'User deleted students/66011211041', 'Exam Grading', 'Teacher', '2026-08-17 05:59:23', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('e43fa472a9394634a0d34d81d0f4a8da', 'User saved students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e44bad16071940faaa1315b86030a78f', 'User deleted students/66011211070', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('e455bdf4c8ac49938a5e71f658f17b85', 'User deleted students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e45c7ad012b14430bbb1d4a19848801a', 'User deleted students/66011211043', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e480ebcdf5ad49ab9d0235b2040316ad', 'User deleted students/67011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e49329cc80dd44e49ae01dbe3342b33d', 'User deleted students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e4caa9a43eef4a3899a3473784d48f80', 'User saved students/66011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:22', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e4d86138d0354d9eb37079a21b60d071', 'User deleted students/66011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e4fc66a502e6418b98a7a85820a78844', 'User deleted students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e5202825174e4ed78e6a1ac27310d5eb', 'User saved students/66011211011', 'Exam Grading', 'Teacher', '2026-08-17 06:22:24', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('e5384a3a2d864b728bd1eceb8f32d695', 'User deleted students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:48:58', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e548d5c4712d4d779107b85667b3d693', 'User saved students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e569f53eefc342abb08a4d4dd068df63', 'User deleted students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e5858af128394f219b3c27de216b4ed8', 'User deleted students/66011211098', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e5ae40019db9461eb71b2ac0509f796a', 'User deleted students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e5b855c0fa21431491ef220111b98194', 'User deleted students/66011211097', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e5ba1bebc0c74b04b78c338f14871d9c', 'User deleted students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e661713ab90e466fb936dadc2b5848ea', 'User deleted students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:18:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e66534da9eaa47969f8cf16ca3e2b66b', 'User deleted students/66011211063', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e67dd68555ba47f1b22eaa51e1a73852', 'User deleted students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e6953a202986464188539c2ab03c72bd', 'User deleted students/66011211083', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e6cf6d9b6aef4f338e53c15487350a15', 'User deleted students/66011211038', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e6d0f83d8a4d4b6b9be7d0f1a0fb2799', 'User deleted students/66011211040', 'Exam Grading', 'Teacher', '2026-08-17 05:59:23', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('e6d441d980ac4c9a8e58f26c8fc5cf39', 'User saved students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e71401af9b01487b9e48d9648213b50c', 'User deleted exams/1201111_1_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:17:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e7505aa3ad0943168b9368ea16b503b2', 'User deleted students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e77b0ee72dd24d0a8c7cc8326e769297', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:50:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e7d647f059054e5184236ea547e220d2', 'User deleted students/68011211098', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e851faacf1a5473bb7fc3830ded2b0d1', 'User deleted students/68011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e85e5d36aee14a52bb50ddaaa369bd31', 'User saved exams/1201213_D3_Test', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:16:57', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e8c49fe943d742f780d63e36949efc2f', 'User deleted students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e8d83fb9ed704fca8a78bac83d48e490', 'User saved students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e8f12f96072f4856b1ac5c34f7f7f3fa', 'User signed in', 'Exam Grading', 'Teacher', '2026-08-16 06:05:45', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('e9106ae66f3846789f4b73c035214b49', 'User deleted students/66011211053', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e93f0c028d4f4dddade92ffa1b0972d8', 'User deleted students/67011211049', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e958cfd6013a46b080eb2eceb3dc6717', 'User saved students/66011211006', 'Exam Grading', 'Teacher', '2026-08-17 06:22:05', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('e99f1f9810e84f0fb475fa4f9271afba', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:40:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('e9d29b3137154236a056e0fa2253b559', 'User saved students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ea0e842c8d6646c39d6d20a11657e402', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ea5f55174b244161a74fa11b7cef1ac8', 'User deleted students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ea838e458d5b439585d6055db6c0fa5f', 'User saved subjects/1201111/sections/2', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:46:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('eabfe1f931c54a5eade23027204475b9', 'User deleted students/67011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('eb050529632a4933aa857be8b8a99f81', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('eb3b84caae234373ae3eeb29b7c3b19b', 'User deleted students/66011211048', 'Exam Grading', 'Teacher', '2026-08-17 05:59:54', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('eb49e0572d1348788bc3eb189ab80700', 'User saved subjects/S101', 'Exam Grading', 'Teacher', '2026-08-17 06:18:08', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('eb579d20c2aa435f95a0b858e8cb116b', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:03:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('eb80d69a546a46398430dc3812394472', 'User saved students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:06:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('eb8ce7dbbe2644a88da898c4d809e2d2', 'User deleted students/67011211068', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('eba4e16ea8164a40ba7b900fe3c290be', 'User deleted students/66011211002', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ebb3a45620b94b48802b91e18fbf2f1e', 'User saved students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ebcecacd993c40638743200baa84b587', 'User deleted students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ebe094ad62ba44caa231b4a2937bd3b1', 'User saved students/66011211019', 'Exam Grading', 'Teacher', '2026-08-17 06:22:51', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('ebf1dd76aaf2474abed0b43bf68e712d', 'User deleted students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ebf50b0b2bba40e3a9143ff3c04da7ce', 'User deleted students/68011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ec0133f41ec549cdaf5c30d96fca2a58', 'User deleted students/66011211043', 'Exam Grading', 'Teacher', '2026-08-17 05:59:23', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('ec2e50c1fc2a4b8e84d21ed5abf67410', 'User deleted students/66011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ec75af9d2809466b9d2a49c0f52e1364', 'User deleted students/66011211056', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ec96d8aa83c64d1c8708b3257344a0b0', 'User saved students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ec9fcu1i5j9kuxf449w2lg', 'User saved subjects/1201413/sections/1201413_1', 'I am Boss', 'Teacher', '2026-08-17 10:10:01', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('ecce18efefbf4d15912c35bc42385bb6', 'User deleted students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ed0edf91863b406a9c1486cd99fa6984', 'User deleted students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ed32f5d25a564ded956f2f04633c8f48', 'User deleted students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ed5583715b50444983ffe739f4338421', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ed60f0eac1dc4af18d08bb5ac635b2cd', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('edad9e7333d843cfaddbfa04533c978a', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('edd49e91dbe04b3aa6e1d8371fe6aab1', 'User deleted students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ee285b6b775c4f2c9dc05c1a60ff10ca', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ee54b02e95f445daa7ec60bda517459a', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ee5eaa4454cf4d61bdeb6a4d4265c025', 'User saved students/66011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ee740fb8cef8420e87c17244ac73f4ef', 'User deleted students/68011211009', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ee7b705eebcc4b579513cd82a4034c62', 'User saved students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('eebfe72dc8e849ea915d1257d06fda3d', 'User saved students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('eef21f8764f34f6fb606a6ccb66dcd5e', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:15', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ef13aeec876445b5993ae90ce5e6db0a', 'User saved students/66011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ef46aaae9a96486f8e110bf99e98b8c0', 'User deleted students/66011211066', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:18', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ef9c6aea04cf43828051f992405c53d2', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ef9fca0b98a344c88f8ec1983b433d36', 'User deleted students/66011211024', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('elswqs3x3ytgbcn98fv1ui', 'User signed out', 'Exam Grading', 'Teacher', '2026-08-17 10:08:07', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f005bd5f965942ac8c02031c43810136', 'User saved subjects/1201111/sections/1201111_1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 08:08:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f030465854a44fc8be14de8ecb2910ab', 'User saved students/66011211029', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:13', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f0331338ed244e74ab76e15d17d8e4db', 'User deleted students/66011211050', 'Exam Grading', 'Teacher', '2026-08-17 05:59:54', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f0441da4a147432eb36474375a4622c5', 'User deleted students/66011211014', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f04dace7818b4052af70e39c3efa7a79', 'User deleted students/66011211031', 'Exam Grading', 'Teacher', '2026-08-17 05:58:49', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f0ba6d6d83274c658e4b5c5b3dff9520', 'User saved students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:24', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f0d9db34b160433196749dddb437d2ab', 'User saved students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f136cdbcf4e14cd89288bc2f03cd27f5', 'User saved students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f1616d37b4e741d4b34bfce3065b33eb', 'User deleted students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f19875a15d5745609514b51a76b3bcd4', 'User deleted students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f1b126de7df945bcad013fcfd53fcbd9', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:52:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f1cb0edc5258427e8673b0f733b989c1', 'User saved students/66011211025', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f1ccdd344f6f4340b198afd548c1c5e6', 'User saved students/66011211027', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f1e9430bbfaa41d2a5ad1e5e2266319e', 'User deleted students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f1ecedd6cf754bdfbe378e8e4d83378c', 'User deleted students/66011211057', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f215caf96b284e3dae9b4ac5d4a57ae5', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f23c5f357435488892bc35765fd73985', 'User deleted students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f23e74ff354f4eba97182ed14f5cc4ee', 'User deleted students/66011211072', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:40', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f23fa711844043549177b7412ea156db', 'User saved students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f24ca0bbe9cf4823819dc92f1417002a', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f253d54b98c141e48d0c0366e5b54405', 'User deleted students/68011211060', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f2983f1608564978aacbd885a59eeb4a', 'User deleted students/67011211039', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f2a1aae29f1746c39661f4c9794f6829', 'User saved students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:10:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f3151c9304e3478c9d89daa720171ec2', 'User deleted students/66011211026', 'Exam Grading', 'Teacher', '2026-08-17 05:58:49', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f321e0489cc24365a982ed197c0d96a6', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f3555efa709c48f4a94ac02d90d938b6', 'User deleted students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f35b3379b8064bd4b3ea3e782e36043e', 'User deleted students/66011211014', 'Supakrit', 'Teacher', '2026-08-17 08:54:10', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f365755a6af44c6c87caf5ea10484814', 'User saved students/66011211067', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:11:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f367c8c4423b4df5bdf72e64b1774744', 'User deleted students/66011211067', 'Supakrit', 'Teacher', '2026-08-17 08:54:12', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f378b8d50eba4c8fa4a9bf4b49b7d0ab', 'User updated results/802bf9e82115427db1798543af046488', 'Exam Grading', 'Teacher', '2026-08-17 07:51:27', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f40ed876c4114d4fa522cd04546fc3ff', 'User deleted students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f4a71decdf0043568e56ccb23528746a', 'User deleted students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f4b25bbff4d34d66bfd67c100fc6d9bf', 'User deleted students/68011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f4b2c8f268b343e9b5eb701c9f297b67', 'User deleted students/67011211036', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f4c80ee49f7a4cb0b20303d483ea5ffb', 'User saved students/66011211051', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:59', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f53fbfa9b28f469ab6982837b1093f28', 'User saved subjects/T0001', 'Supakrit', 'Teacher', '2026-08-17 09:19:00', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f5608ae137a54e319ca8b136fee057be', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:27', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f595cd0826664e3aae87c1adaad0c3da', 'User deleted students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f5d07577576a4781938f9d45d67e8957', 'User saved students/66011211021', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:42', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f5dffce002f4417083c2eb3a9e0c45fa', 'User deleted students/66011211053', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f6473b6808bb4c81bdceab9d77ffe516', 'User deleted subjects/S101', 'Supakrit', 'Teacher', '2026-08-17 08:38:23', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f64c47c086f844e98ad04ef8ebc17be7', 'User deleted students/66011211017', 'Exam Grading', 'Teacher', '2026-08-17 05:55:26', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f671823094a945ea8aed66d75b765a10', 'User deleted students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:50', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f70196474b1d451fadeb78f56824e30a', 'User saved students/66011211007', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:04:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f70d6b8af89a4fd585ebb71ecf5022ac', 'User deleted students/67011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f73694bbb5a84f37b7605d399e6a615b', 'User saved students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f744f9fd9bef4bc7be1ffd0a82cdd038', 'User deleted students/66011211100', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f75f04459b2343d9906e9fa6e88d4883', 'User deleted students/67011211085', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:32', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f7689e4a6e584a0385fbdf0f6b2fe8fc', 'User deleted students/66011211050', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f773951bc0b24051a63f2cc8339ca5be', 'User deleted students/66011211017', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f7a88e9dd2e545e5951449773ca984ed', 'User saved students/66011211014', 'Exam Grading', 'Teacher', '2026-08-17 06:22:34', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f7de80d8997947a19c33a5bfdeca14ce', 'User deleted students/66011211046', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f86150cad2e242779db4c1b0d463c85d', 'User deleted students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f886a4bb1be14d8c95d6d16401093f1d', 'User saved students/66011211044', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:14', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f8c4a1b364f44fd79e20f5f311d970bd', 'User saved students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:44', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f8d39f8bf21a48d2ab9fd8cc99fc352e', 'User deleted students/66011211030', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:52', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f8fc5cc83feb41a7b5d3fa9cf866b4b1', 'User saved students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:53:08', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f92a49bd7a4943b193aadc4b0533ddf5', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f92aa91c728e433d9d3de0d7a9c9a667', 'User deleted students/67011211001', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:28', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f961246c56e84f429c2184f74332e3cb', 'User deleted students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f970dfaefaa14ae39b341da79faa528f', 'User deleted students/66011211034', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:39', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f984ed97fbdf46c4824646f48d52a2a9', 'User deleted students/66011211035', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:02', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f99d684bce3f477dbad1c1d65391580d', 'User signed in', 'Exam Grading', 'Teacher', '2026-08-17 07:18:04', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f9ace90347cb4c0484f8fe24e56a526c', 'User deleted students/68011211097', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f9bdc89251134ac08b075f332e60b143', 'User saved students/66011211040', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:15:07', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f9be869d962a4150891197b02f55c93a', 'User deleted students/66011211022', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f9c606f4a0864a33b88508018e425a03', 'User deleted students/66011211008', 'Exam Grading', 'Teacher', '2026-08-17 05:55:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('f9e7a0dbfd624b2eb040425190b6ec04', 'User saved students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:41:05', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('f9ffe65b70a04d47b9170b0f6389e913', 'User deleted students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fa1b60d5437e44cd8133f69f150aee66', 'User deleted students/68011211057', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fa452e514c8940858c785f8755f1f35a', 'User saved students/66011211023', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fa6daf1e45d54a3a989da3a3c36a1530', 'User deleted students/67011211072', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fa6lvt60s6cixlw6lc5wf', 'User updated exams/1201111_1_test', 'I am Boss', 'Teacher', '2026-08-21 08:27:34', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('faf1a600281d4bc7ad02c1df0a15fdc8', 'User deleted students/68011211059', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:34', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('faf259e51da64899a8251c5cc64907c4', 'User saved students/66011211003', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:25', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fb0b88682e9d4c608f5aa294d06bacfb', 'User deleted students/66011211020', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:16', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fb220ee5d03b4c25a37bc6fb71b48fa2', 'User deleted students/66011211013', 'Exam Grading', 'Teacher', '2026-08-17 05:55:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('fb46b7227d3e428fbee96e55e9574ee9', 'User deleted students/66011211052', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fb5540819a964177b90f100dca1f9153', 'User deleted students/66011211085', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fb56bb3bba1342ab9ed15b25e638b793', 'User deleted students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fb928f6ca98b45f4802f239353df33d1', 'User deleted students/67011211047', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fbb47bf774924e7fbb4a64660a75dd8c', 'User saved subjects/S101/sections/S101_1', 'Exam Grading', 'Teacher', '2026-08-17 06:17:25', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('fbc72f39d52f451ba3c8c291c0dbdee6', 'User deleted students/67011211065', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fbe4eb852d6845f89c81f9db53a82b9b', 'User deleted students/66011211085', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fbebad428ef34bcc9908194387f88818', 'User saved students/66011211033', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:32:19', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fc039fd2be4348aca236f8680189a833', 'User deleted students/68011211092', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fc1f7340227e45879fc67322ac6c5ec1', 'User saved subjects/1201111/sections/6', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:47:09', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fc4015f8e82948e3980054a5903f701b', 'User saved students/66011211006', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 13:16:03', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fc4a1968d3fa4a71bb86c6c77899ec22', 'User saved students/66011211037', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fc63ecb7e9f04ddf99748a07bfb1af7a', 'User deleted students/66011211019', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:46', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fc80daee383344a2afd7f09b7ed7c6fb', 'User saved students/66011211084', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 12:38:55', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fc82eabfa04f43a0ae77dc9434273592', 'User deleted students/66011211048', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:47', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fc948c91a86d442693451c92e12bca97', 'User saved students/66011211041', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fcf6a02279ae4a4e9689b5af5dbad051', 'User deleted students/66011211028', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:17', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fcfb23b0b35149bebd15c83fa03999ed', 'User deleted subjects/1201413/sections/All Section', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fd110f57d92446708efa382fc3c210e2', 'User deleted students/66011211065', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:16:20', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fd20b7a272404cd3bf1e8cf322cbe1b8', 'User deleted students/66011211018', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:44:48', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fd4e0cedbbb74345a384f7f60660823b', 'User deleted students/68011211077', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fd53d767e3f04bcb8090999bc8650474', 'User deleted students/66011211013', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:39:06', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fd5e5ba80b3d4575b9907b4628e403cc', 'User deleted students/66011211010', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:58:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fd5e9fdc3e9347959632236f8571d689', 'User deleted students/68011211069', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fd6048655123467ebb5faaaf7c41c55d', 'User saved students/66011211042', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fd80bc4f94fe495ab6dc836185b3f212', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:17:35', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fd8d167a53f64b18bddbaf92a6b9741f', 'User saved students/66011211015', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:11', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fdd7a30c25fa4e999faec7d801f93550', 'User saved students/66011211016', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:02:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fde02c848b1744afaaeb62e7a4f28721', 'User saved students/66011211026', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:30', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fde2dd6e40034288861a69208826d151', 'User saved students/66011211001', 'Exam Grading', 'Teacher', '2026-08-17 06:27:21', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('fe06de58c79e4e9396b25fdf16dc4b12', 'User saved students/66011211004', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 15:49:33', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fe132b0b395342ceb0b45eb1a8405517', 'User deleted students/66011211095', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:27:41', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fe3e36ce05874340b393a046d6b49d09', 'User saved subjects/1201413/sections/9', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:13:00', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fe4b3e00ae5c40a2ac46617b58151a3f', 'User saved students/66011211031', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:25:36', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fe5ea3df39294df58ee3be2bc5c11baa', 'User saved students/66011211060', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:26:10', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fe659dcffb2942428da1c8a640701af7', 'User saved students/66011211017', 'Exam Grading', 'Teacher', '2026-08-17 06:22:44', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('fe65de793a8f496ab06891e8721e4250', 'User deleted students/66011211058', 'Supakrit', 'Teacher', '2026-08-17 08:54:13', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('fe762eb8adf4404e8b320a682bb98a8f', 'User saved students/66011211005', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:46:01', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fe96491b06f44ea195c6a99bb962cf38', 'User deleted students/66011211016', 'Supakrit', 'Teacher', '2026-08-17 08:54:11', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('fee72c70cbba4b7e9b8b07b8e8a35461', 'User deleted students/66011211045', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fef09155851046ffbd69f7ddbd432ec0', 'User deleted students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:03:37', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('fefa586e8b804503b333dd0ea4d1460a', 'User saved students/66011211091', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 09:12:04', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ff0dd5b914244bc89a1be52224d30701', 'User deleted subjects/1201413/sections/1', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 07:12:51', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ff3a50221da340d6b4dffa12c2f92bf2', 'User updated exams/S101_1_Test', 'Exam Grading', 'Teacher', '2026-08-17 06:34:09', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('ff42c26be0c348e9b73a868f201d1908', 'User deleted students/68011211086', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:38', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ffa1fa6b0044493f8f02f7063554072d', 'User saved students/66011211011', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 10:14:29', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ffb4f23b684442508cbff962209be80f', 'User deleted students/67011211062', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-16 06:52:31', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('ffc9c23661694105870cdaac9d9b59be', 'User signed in', 'Exam Grading', 'Teacher', '2026-08-17 06:15:53', 'exam.grading04@gmail.com');
INSERT INTO `system_logs` VALUES ('hpdhxvssygh1ij0z9hq3iw', 'User signed in', 'I am Boss', 'Teacher', '2026-08-21 08:17:55', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('ire7g1z4ymrxqvmdhezej', 'User saved subjects/1201413/sections/1201413_1', 'I am Boss', 'Teacher', '2026-08-17 10:12:10', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('iufrzjipgtmyqva9qda3qs', 'User deleted exams/1101_1_test', 'I am Boss', 'Teacher', '2026-08-18 16:29:06', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('jjwn14e8jtblt9aod7zo3m', 'User saved subjects/1201413', 'I am Boss', 'Teacher', '2026-08-17 10:09:56', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('jmhloadupu9bd8bzjui9t', 'User signed in', 'ศุภกฤต คำเมือง', 'Teacher', '2026-08-17 18:01:45', '66011211135@msu.ac.th');
INSERT INTO `system_logs` VALUES ('kd2vjsqgpuaooyvbls404', 'User signed in', 'I am Boss', 'Teacher', '2026-08-21 08:13:16', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('m6jmt3e1knrwysrsj1s8m', 'User saved subjects/1101/sections/1101_1', 'I am Boss', 'Teacher', '2026-08-17 10:11:35', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('o85ty6b9fic3xh9aobd59', 'User deleted students/66011215', 'I am Boss', 'Teacher', '2026-08-18 16:29:20', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('pz68lb5zcim34m13d6ywdy', 'User signed out', 'I am Boss', 'Teacher', '2026-08-21 08:13:02', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('qmpgdl6hjtggh6uaojakx', 'User signed out', 'I am Boss', 'Teacher', '2026-08-21 08:17:05', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('r1cls0h10apath1mddtu', 'User saved students/66011211035', 'I am Boss', 'Teacher', '2026-08-21 08:42:21', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('sg3hfoafzscw15qhbbas5', 'User deleted exams/1101_1_test', 'I am Boss', 'Teacher', '2026-08-18 16:28:59', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('sjyodl94hct8srp9v0dy', 'User deleted subjects/1101', 'I am Boss', 'Teacher', '2026-08-21 08:16:28', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('t97pav942lgqnwzjsyegar', 'User deleted students/66011212', 'I am Boss', 'Teacher', '2026-08-18 16:29:20', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('tv96it2eduil89w7etlqrj', 'User saved students/66011211035', 'I am Boss', 'Teacher', '2026-08-21 08:27:53', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('uuvshs99kumh871sfh24dt', 'User saved students/66011211035', 'I am Boss', 'Teacher', '2026-08-21 08:19:08', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('v7ym2u3h26r2mbgflrhz08', 'User saved subjects/1201111/sections/1201111_1', 'I am Boss', 'Teacher', '2026-08-21 08:18:18', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('w27qw5p23dpnt73771vjqa', 'User deleted students/66011216', 'I am Boss', 'Teacher', '2026-08-18 16:29:19', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('x0psryduf0l3xpntbc8osr', 'User saved subjects/1201111/sections/1201111_3', 'I am Boss', 'Teacher', '2026-08-21 08:28:31', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('xtv7jydta7ra4gqluaxr', 'User saved students/66011211035', 'I am Boss', 'Teacher', '2026-08-21 08:28:52', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('xyenlyc1srqjj211l3jk', 'User deleted students/66011214', 'I am Boss', 'Teacher', '2026-08-18 16:29:19', 'ibossy2004@gmail.com');
INSERT INTO `system_logs` VALUES ('z6sqc4d1ovnuk2ghu1u4g', 'User updated subjects/1201413', 'I am Boss', 'Teacher', '2026-08-17 10:08:43', 'ibossy2004@gmail.com');

-- ----------------------------
-- Table structure for system_settings
-- ----------------------------
DROP TABLE IF EXISTS `system_settings`;
CREATE TABLE `system_settings`  (
  `setting_key` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `setting_value` text CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL,
  `updated_at` datetime NULL DEFAULT NULL,
  PRIMARY KEY (`setting_key`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of system_settings
-- ----------------------------
INSERT INTO `system_settings` VALUES ('academic_term', '2', '2026-08-21 08:17:41');
INSERT INTO `system_settings` VALUES ('academic_year', '2569', '2026-08-21 08:17:40');

-- ----------------------------
-- Table structure for templates
-- ----------------------------
DROP TABLE IF EXISTS `templates`;
CREATE TABLE `templates`  (
  `template_id` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `template_name` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `max_questions` int NOT NULL,
  `image_path` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  PRIMARY KEY (`template_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of templates
-- ----------------------------
INSERT INTO `templates` VALUES ('100-A-E', 'กระดาษคำตอบแบบ 100 ข้อ', 100, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786883543/template_100q_ecoe0w.png');
INSERT INTO `templates` VALUES ('30-A-E', 'กระดาษคำตอบแบบ 30 ข้อ', 30, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786883542/template_30q_cd2as6.png');
INSERT INTO `templates` VALUES ('50-A-E', 'กระดาษคำตอบแบบ 50 ข้อ', 50, 'https://res.cloudinary.com/dwmzp0tgw/image/upload/v1786883543/template_50q_pj3jj1.png');

-- ----------------------------
-- Table structure for users
-- ----------------------------
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users`  (
  `user_id` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `username` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `password` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `email` varchar(100) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL,
  `displayName` varchar(200) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `photoURL` varchar(500) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT NULL,
  `role` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT 'user',
  `created_at` datetime NULL DEFAULT CURRENT_TIMESTAMP,
  `status` varchar(20) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NULL DEFAULT 'active',
  PRIMARY KEY (`user_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_general_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Records of users
-- ----------------------------
INSERT INTO `users` VALUES ('1', 'admin', '8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92', '', 'Admin', NULL, 'admin', '2026-07-18 22:49:08', 'active');
INSERT INTO `users` VALUES ('66011211035@msu.ac.th', '66011211035@msu.ac.th', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', '66011211035@msu.ac.th', 'นลธชัย บุตรราช', 'https://examgrading.onrender.com/static/uploads/66011211035@msu.ac.th_b8a55b7e.JPEG', 'user', '2026-08-07 05:39:48', 'suspended');
INSERT INTO `users` VALUES ('66011211135@msu.ac.th', '66011211135@msu.ac.th', 'bb53584247a7131532d48ca0f3b66c56998b9471548c70f39333d28f41c2b463', '66011211135@msu.ac.th', 'ศุภกฤต คำเมือง', 'https://lh3.googleusercontent.com/a/ACg8ocKD2MHZLSu_ZefvKob6eoupWScEG2yUU7dbFxJcVLAFK5OJiqk=s360-c-no', 'user', '2026-07-18 11:21:02', 'active');
INSERT INTO `users` VALUES ('exam.grading04@gmail.com', 'exam.grading04@gmail.com', '2abd52a7398973c173e9a4c7b146528f48281709a12d9ab16b896aa068dd54f6', 'exam.grading04@gmail.com', 'Supakrit', 'https://lh3.googleusercontent.com/a/ACg8ocJ5m0aGugXpHzzNnnK5wy5WKU01DHgSsrAA1mxiPtxil1cN9A=s96-c', 'user', '2026-08-05 14:30:48', 'active');
INSERT INTO `users` VALUES ('ibossy2004@gmail.com', 'ibossy2004@gmail.com', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'ibossy2004@gmail.com', 'I am Boss', 'https://lh3.googleusercontent.com/a/ACg8ocIJKaKOp5EvQee_bqotz_5i50DmaCPMHLQjy7z-o0E1ZCA-20Ya=s96-c', 'user', '2026-08-07 05:39:34', 'active');
INSERT INTO `users` VALUES ('nonthachai.b04@gmail.com', 'nonthachai.b04@gmail.com', '5a87262d38c94c657a42c1c17a12c9565ad75cf2e1469c131c371e94e24e8e42', 'nonthachai.b04@gmail.com', 'nonthachai.b04@gmail.com', '', 'user', '2026-08-13 19:47:21', 'active');

SET FOREIGN_KEY_CHECKS = 1;
