Drop database if exists Tmdb;
CREATE DATABASE IF NOT EXISTS `Tmdb`;
USE Tmdb;
DELIMITER //
DROP PROCEDURE IF EXISTS DropAllProcedures //
CREATE PROCEDURE DropAllProcedures()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE procName VARCHAR(255);
    DECLARE cur CURSOR FOR 
        SELECT SPECIFIC_NAME 
        FROM information_schema.ROUTINES 
        WHERE ROUTINE_SCHEMA = DATABASE() 
        AND ROUTINE_TYPE = 'PROCEDURE'
        AND SPECIFIC_NAME != 'DropAllProcedures';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    read_loop: LOOP
        FETCH NEXT FROM cur INTO procName;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @drop_proc_sql = CONCAT('DROP PROCEDURE IF EXISTS ', procName);
        PREPARE stmt FROM @drop_proc_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;

    CLOSE cur;
END //

CALL DropAllProcedures(); //

CREATE PROCEDURE DropAllTables()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE tableName VARCHAR(255);
    DECLARE cur CURSOR FOR 
        SELECT TABLE_NAME 
        FROM information_schema.TABLES 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_TYPE = 'BASE TABLE';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    SET FOREIGN_KEY_CHECKS = 0;

    OPEN cur;
    read_loop: LOOP
        FETCH NEXT FROM cur INTO tableName;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @drop_table_sql = CONCAT('DROP TABLE IF EXISTS ', tableName);
        PREPARE stmt FROM @drop_table_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;

    CLOSE cur;
END //

CREATE PROCEDURE DropAllFunctions()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE funcName VARCHAR(255);
    DECLARE cur CURSOR FOR 
        SELECT SPECIFIC_NAME 
        FROM information_schema.ROUTINES 
        WHERE ROUTINE_SCHEMA = DATABASE() 
        AND ROUTINE_TYPE = 'FUNCTION'
        AND SPECIFIC_NAME != 'DropAllFunctions';
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    
    OPEN cur;
    read_loop: LOOP
        FETCH NEXT FROM cur INTO funcName;
        
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @drop_func_sql = CONCAT('DROP FUNCTION IF EXISTS ', funcName);
        PREPARE stmt FROM @drop_func_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;

    CLOSE cur;
END //


-- delete all triggers
CREATE PROCEDURE DropAllTriggers()
BEGIN
    DECLARE done INT DEFAULT FALSE;
    DECLARE triggerName VARCHAR(255);
    DECLARE cur CURSOR FOR 
        SELECT TRIGGER_NAME 
        FROM information_schema.TRIGGERS 
        WHERE TRIGGER_SCHEMA = DATABASE();
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

    OPEN cur;
    read_loop: LOOP
        FETCH NEXT FROM cur INTO triggerName;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        SET @drop_trigger_sql = CONCAT('DROP TRIGGER IF EXISTS ', triggerName);
        PREPARE stmt FROM @drop_trigger_sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END LOOP;

    CLOSE cur;
END //

DELIMITER ;
