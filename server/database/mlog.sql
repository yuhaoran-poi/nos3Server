-- 创建mlog数据库
CREATE DATABASE IF NOT EXISTS mlog;

-- 使用mlog数据库
USE mlog;

 

-- 创建道具变更表
CREATE TABLE IF NOT EXISTS t_item_change (
    uid BIGINT NOT NULL,
    item_id INT NOT NULL,
    change_num INT NOT NULL,
    before_num INT NOT NULL,
    after_num INT NOT NULL,
    reason INT NOT NULL,
    reason_detail VARCHAR(255) NOT NULL,
    create_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;