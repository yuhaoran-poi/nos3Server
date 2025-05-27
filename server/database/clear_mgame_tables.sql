DELIMITER //
DROP PROCEDURE IF EXISTS clear_mgame_tables;
CREATE PROCEDURE clear_mgame_tables()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE table_name_var VARCHAR(64);
    
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
        BEGIN
            GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
            SELECT CONCAT('Error executing truncate commands: ', @errno, ' (', @sqlstate, '): ', @text) AS error_message;
        END;
    
    -- 创建临时表存储所有表名
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_mgame_tables (table_name VARCHAR(64));
    
    -- 插入所有表名到临时表
    INSERT INTO temp_mgame_tables
    SELECT table_name FROM information_schema.tables 
    WHERE table_schema = 'mgame' AND table_type = 'BASE TABLE';
    
    -- 检查是否有表需要清空
    IF (SELECT COUNT(*) FROM temp_mgame_tables) > 0 THEN
        -- 循环执行TRUNCATE语句
        BEGIN
            DECLARE table_cursor CURSOR FOR SELECT table_name FROM temp_mgame_tables;
            DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
            
            OPEN table_cursor;
            
            read_loop: LOOP
                FETCH table_cursor INTO table_name_var;
                IF done THEN
                    LEAVE read_loop;
                END IF;
                
                SET @sql = CONCAT('TRUNCATE TABLE `', table_name_var, '`');
                PREPARE stmt FROM @sql;
                EXECUTE stmt;
                DEALLOCATE PREPARE stmt;
            END LOOP;
            
            CLOSE table_cursor;
        END;
        
        SELECT CONCAT('Truncated all tables in mgame database') AS status_message;
    ELSE
        SELECT 'No tables found in mgame database' AS status_message;
    END IF;
    
    -- 删除临时表
    DROP TEMPORARY TABLE IF EXISTS temp_mgame_tables;
END //
DELIMITER ;