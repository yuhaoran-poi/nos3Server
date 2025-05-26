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

 Date: 26/05/2025 16:20:59
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
) ENGINE = InnoDB AUTO_INCREMENT = 98 CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for c_guild
-- ----------------------------
DROP TABLE IF EXISTS `c_guild`;
CREATE TABLE `c_guild`  (
  `guildId` bigint(0) NOT NULL,
  `value` mediumblob NOT NULL,
  `json` json NULL,
  PRIMARY KEY (`guildId`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for c_guild_bag
-- ----------------------------
DROP TABLE IF EXISTS `c_guild_bag`;
CREATE TABLE `c_guild_bag`  (
  `guildId` bigint(0) NOT NULL,
  `value` mediumblob NOT NULL,
  `json` json NULL,
  PRIMARY KEY (`guildId`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for c_guild_record
-- ----------------------------
DROP TABLE IF EXISTS `c_guild_record`;
CREATE TABLE `c_guild_record`  (
  `guildId` bigint(0) NOT NULL,
  `value` mediumblob NOT NULL,
  `json` json NULL,
  PRIMARY KEY (`guildId`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for c_guild_shop
-- ----------------------------
DROP TABLE IF EXISTS `c_guild_shop`;
CREATE TABLE `c_guild_shop`  (
  `guildId` bigint(0) NOT NULL,
  `value` mediumblob NOT NULL,
  `json` json NULL,
  PRIMARY KEY (`guildId`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for coins
-- ----------------------------
DROP TABLE IF EXISTS `coins`;
CREATE TABLE `coins`  (
  `uid` bigint(0) NOT NULL,
  `value` mediumblob NULL,
  `json` json NULL,
  PRIMARY KEY (`uid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for ghosts
-- ----------------------------
DROP TABLE IF EXISTS `ghosts`;
CREATE TABLE `ghosts`  (
  `uid` bigint(0) NOT NULL,
  `value` mediumblob NULL,
  `json` json NULL,
  PRIMARY KEY (`uid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for itemimages
-- ----------------------------
DROP TABLE IF EXISTS `itemimages`;
CREATE TABLE `itemimages`  (
  `uid` bigint(0) NOT NULL,
  `value` mediumblob NULL,
  `json` json NULL,
  PRIMARY KEY (`uid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for roles
-- ----------------------------
DROP TABLE IF EXISTS `roles`;
CREATE TABLE `roles`  (
  `uid` bigint(0) NOT NULL,
  `value` mediumblob NULL,
  `json` json NULL,
  PRIMARY KEY (`uid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

-- ----------------------------
-- Table structure for user_attr
-- ----------------------------
DROP TABLE IF EXISTS `user_attr`;
CREATE TABLE `user_attr`  (
  `uid` bigint(0) NOT NULL,
  `value` mediumblob NULL,
  `json` json NULL,
  PRIMARY KEY (`uid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci ROW_FORMAT = Dynamic;

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

-- ----------------------------
-- Table structure for userdata
-- ----------------------------
DROP TABLE IF EXISTS `userdata`;
CREATE TABLE `userdata`  (
  `uid` bigint(0) NOT NULL,
  `data` text CHARACTER SET utf8mb4 COLLATE utf8mb4_bin NOT NULL,
  PRIMARY KEY (`uid`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_bin ROW_FORMAT = Dynamic;

SET FOREIGN_KEY_CHECKS = 1;
