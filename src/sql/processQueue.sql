DROP DATABASE IF EXISTS `TaskQueue`;
CREATE DATABASE `TaskQueue`;
USE TaskQueue;

DELIMITER ;

-- Process Queue Configuration
CREATE TABLE ProcessQueue (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    taskType VARCHAR(100) NOT NULL COMMENT 'Name of stored procedure to execute',
    parameters JSON NULL COMMENT 'Parameters to pass to the procedure',
    priority TINYINT UNSIGNED DEFAULT 1 NOT NULL,
    status ENUM('pending', 'processing', 'completed', 'failed', 'cancelled') DEFAULT 'pending' NOT NULL,
    retryCount TINYINT UNSIGNED DEFAULT 0 NOT NULL,
    maxRetries TINYINT UNSIGNED DEFAULT 3 NOT NULL,
    lastError TEXT NULL,
    metadata JSON NULL COMMENT 'Additional task metadata',
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    startedAt TIMESTAMP NULL,
    completedAt TIMESTAMP NULL,
    CONSTRAINT PRIMARY KEY (id),
    INDEX ProcessQueueStatus_IDX (id, status, priority),
    INDEX ProcessQueueType_IDX (taskType)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Failed Tasks Log
CREATE TABLE FailedTasks (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    taskId UUID NOT NULL COMMENT 'Reference to ProcessQueue.id',
    taskType VARCHAR(100) NOT NULL,
    parameters JSON NULL,
    error TEXT NOT NULL,
    metadata JSON NULL,
    failedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    INDEX FailedTasksType_IDX (taskType),
    INDEX FailedTasksTime_IDX (failedAt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER //

-- Function to get JSON representation of a Task
CREATE FUNCTION GetTaskJSON(
    p_id UUID,
    p_taskType VARCHAR(100),
    p_parameters JSON,
    p_priority TINYINT UNSIGNED,
    p_status VARCHAR(20),
    p_metadata JSON
) RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    SET result = JSON_OBJECT();
    
    -- Always include non-nullable fields
    SET result = JSON_SET(result,
        '$.id', p_id,
        '$.taskType', p_taskType,
        '$.status', COALESCE(p_status, 'pending'),
        '$.priority', COALESCE(p_priority, 1)
    );
    
    -- Add optional fields only if they are not null
    IF p_parameters IS NOT NULL THEN
        SET result = JSON_SET(result, '$.parameters', p_parameters);
    END IF;

    IF p_metadata IS NOT NULL THEN
        SET result = JSON_SET(result, '$.metadata', p_metadata);
    END IF;
    
    RETURN result;
END //

-- Helper procedure to add a task to the queue
CREATE PROCEDURE QueueTask(
    IN p_taskType VARCHAR(100),
    IN p_parameters JSON,
    IN p_priority TINYINT UNSIGNED,
    IN p_metadata JSON
)
BEGIN
    INSERT INTO ProcessQueue (
        id,
        taskType,
        parameters,
        priority,
        metadata
    )
    VALUES (
        UUID_v7(),
        p_taskType,
        p_parameters,
        COALESCE(p_priority, 1),
        p_metadata
    );
END //

-- Procedure to process queue items
CREATE PROCEDURE ProcessQueueItems(IN batchSize INT UNSIGNED)
BEGIN
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE task_id BINARY(16);
    DECLARE task_type VARCHAR(100);
    DECLARE task_params JSON;
    
    DECLARE cur CURSOR FOR
        SELECT id, taskType, parameters
        FROM ProcessQueue
        WHERE status = 'pending'
        AND retryCount < maxRetries
        ORDER BY priority DESC, id ASC
        LIMIT batchSize;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
    BEGIN
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        
        -- Log the failed task
        INSERT INTO FailedTasks (
            id,
            taskId,
            taskType,
            parameters,
            error,
            metadata
        )
        SELECT 
            UUID_v7(),
            id,
            taskType,
            parameters,
            CONCAT('Error: ', @errno, ' State: ', @sqlstate, ' Message: ', @text),
            metadata
        FROM ProcessQueue
        WHERE id = task_id;
        
        -- Update task status
        UPDATE ProcessQueue 
        SET status = 'failed',
            lastError = CONCAT('Error: ', @errno, ' State: ', @sqlstate, ' Message: ', @text),
            retryCount = retryCount + 1,
            completedAt = CURRENT_TIMESTAMP
        WHERE id = task_id;
    END;
    
    START TRANSACTION;
    
    OPEN cur;
    
    read_loop: LOOP
        FETCH cur INTO task_id, task_type, task_params;
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Mark as processing
        UPDATE ProcessQueue 
        SET status = 'processing',
            startedAt = CURRENT_TIMESTAMP 
        WHERE id = task_id;
        
        -- Execute the stored procedure dynamically
        SET @sql = CONCAT('CALL ', task_type, '(', 
            IFNULL(
                (SELECT 
                    GROUP_CONCAT(
                        CASE 
                            WHEN JSON_TYPE(value) IN ('INTEGER', 'BOOLEAN') THEN value
                            ELSE CONCAT('"', value, '"')
                        END
                        ORDER BY path
                    )
                FROM JSON_TABLE(
                    task_params,
                    '$[*]' COLUMNS(
                        path FOR ORDINALITY,
                        value JSON PATH '$'
                    )
                ) AS params),
                ''
            ),
        ')');
        
        PREPARE stmt FROM @sql;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
        
        -- Mark as completed
        UPDATE ProcessQueue 
        SET status = 'completed',
            completedAt = CURRENT_TIMESTAMP
        WHERE id = task_id;
        
    END LOOP;
    
    CLOSE cur;
    
    COMMIT;
END //

-- Create event to process queue periodically
CREATE EVENT IF NOT EXISTS ProcessQueueEvent
ON SCHEDULE EVERY 30 SECOND
DO
    CALL ProcessQueueItems(50) //

DELIMITER ;
