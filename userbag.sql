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

 Date: 29/04/2025 15:18:06
*/

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ----------------------------
-- Table structure for userbag
-- ----------------------------
DROP TABLE IF EXISTS `userbag`;
CREATE TABLE `userbag`  (
  `uid` bigint(0) NOT NULL,
  `cangku` mediumblob NULL,
  `cangku_json` json NULL,
  `consume` mediumblob NULL,
  `consume_json` json NULL,
  `booty` mediumblob NULL,
  `booty_json` json NULL,
  PRIMARY KEY (`uid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;
