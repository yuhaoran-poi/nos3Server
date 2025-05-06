/*
 Navicat Premium Data Transfer

 Source Server         : localhost8.0
 Source Server Type    : MySQL
 Source Server Version : 80041
 Source Host           : localhost:3306
 Source Schema         : mgame

 Target Server Type    : MySQL
 Target Server Version : 80041
 File Encoding         : 65001

 Date: 02/04/2025 21:29:41
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for account
-- ----------------------------
DROP TABLE IF EXISTS `account`;
CREATE TABLE `account`  (
  `user_id` bigint unsigned NOT NULL,
  `authkey` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `username` varchar(64) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `password_hash` char(32) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
  `create_time` timestamp(0) NULL DEFAULT CURRENT_TIMESTAMP,
  `last_login` timestamp(0) NULL DEFAULT NULL,
  PRIMARY KEY (`user_id`) USING BTREE,
  UNIQUE INDEX `username`(`username`) USING BTREE
) ENGINE = InnoDB AUTO_INCREMENT = 36 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;
