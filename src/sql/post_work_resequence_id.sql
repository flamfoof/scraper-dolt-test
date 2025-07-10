CREATE DATABASE IF NOT EXISTS `Tmdb`;
USE Tmdb;

DELIMITER //





CREATE OR REPLACE PROCEDURE ResequenceIDs(IN p_tableName VARCHAR(64) COLLATE utf8mb4_unicode_ci)
BEGIN
    DECLARE batch_size INT DEFAULT 1000;
    DECLARE batch_start INT DEFAULT 0;
    DECLARE batch_end INT DEFAULT 0;
    -- DECLARE CONTINUE HANDLER FOR SQLSTATE '45000'

    SET @errMessage := CONCAT('Table does not exist for: ', p_tableName);
    If NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = p_tableName) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = @errMessage;
    END IF;

    -- Find min and max id values
-- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'wtf';
    
    SET @getMinMax := CONCAT(
        'SELECT ', 
        'MIN(id), MAX(id) ',
        'INTO  @min_id, @max_id FROM ', p_tableName, ';'
    );
    PREPARE stmt FROM @getMinMax;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
    SET @max_id = 69;
    SET @new_id = 0;
    

    SET batch_start := @min_id;

    WHILE batch_start <= @max_id DO
        SET batch_end = batch_start + batch_size - 1;

        SET @batchSql := CONCAT('UPDATE ', p_tableName, ' ',
            'SET adminRefId = (@new_id := @new_id + 1) ',
            'WHERE id BETWEEN ', batch_start, ' AND ', batch_end, ';'
        );
        UPDATE DebuggingStation 
        SET debugMessage = @batchSql
        WHERE resource = "Resequencer";

        PREPARE stmt FROM @batchSql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;

        SET batch_start = batch_end + 1;
    END WHILE;

    -- SET @sqlUpdateTable := CONCAT('UPDATE ', 
    --     p_tableName, ' currTable ', 
    --     'SET currTable.adminRefId = NULL ',
    --     'BETWEEN 100 ', ';'
    -- );
    -- PREPARE stmt FROM @sqlUpdateTable;
    -- EXECUTE stmt;
    -- DEALLOCATE PREPARE stmt;
-- SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Updated Current Table';

--     -- Step 5: Reset AUTO_INCREMENT to next value
--     SELECT MAX(id) INTO @max_id FROM p_tableName;
--     SET @next_id := IFNULL(@max_id, 0) + 1;
--     SET @sql := CONCAT('ALTER TABLE ', p_tableName, ' AUTO_INCREMENT = ', @next_id);
--     PREPARE stmt FROM @sql;
--     EXECUTE stmt;
--     DEALLOCATE PREPARE stmt;

--     -- Step 6: Clean up
--     DROP TEMPORARY TABLE IF EXISTS id_map;

    -- BEGIN
END //

CALL ResequenceIDs("Movies"); //
