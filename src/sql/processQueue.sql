DROP DATABASE IF EXISTS TaskQueue;
CREATE DATABASE TaskQueue;
USE TaskQueue;

DELIMITER ;

-- Process Queue Configuration
CREATE OR REPLACE  TABLE ProcessQueue (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    database VARCHAR(64) NOT NULL,
    taskType VARCHAR(64) NOT NULL COMMENT 'Name of stored procedure to execute',
    status ENUM('pending', 'processing', 'completed', 'failed', 'cancelled') DEFAULT 'pending' NOT NULL,
    parameters JSON NULL COMMENT 'Parameters to pass to the procedure',
    priority TINYINT UNSIGNED DEFAULT 1 NOT NULL,
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
CREATE OR REPLACE  TABLE FailedTasks (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    taskRefId UUID NOT NULL COMMENT 'Reference to ProcessQueue.id',
    database VARCHAR(64) NOT NULL,
    taskType VARCHAR(64) NOT NULL,
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
CREATE OR REPLACE  FUNCTION GetTaskJSON(
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
CREATE OR REPLACE  PROCEDURE QueueTask(
    IN p_database VARCHAR(100),
    IN p_taskType VARCHAR(100),
    IN p_parameters JSON,
    IN p_priority TINYINT UNSIGNED,
    IN p_metadata JSON
)
BEGIN
    INSERT INTO TaskQueue.ProcessQueue (
        id,
        database,
        taskType,
        parameters,
        priority,
        metadata
    )
    VALUES (
        UUID_v7(),
        p_database,
        p_taskType,
        p_parameters,
        COALESCE(p_priority, 1),
        p_metadata
    );
END //

-- Procedure to process queue items
CREATE OR REPLACE  PROCEDURE ProcessQueueItems(IN batchSize INT UNSIGNED)
BEGIN
    DECLARE done BOOLEAN DEFAULT FALSE;
    DECLARE task_id BINARY(16);
    DECLARE task_type VARCHAR(100);
    DECLARE task_params JSON;
    DECLARE task_database VARCHAR(64);
    DECLARE task_metadata JSON;
    DECLARE error_occurred BOOLEAN DEFAULT FALSE;
    
    DECLARE cur CURSOR FOR
        SELECT id, database, taskType, parameters, metadata
        FROM TaskQueue.ProcessQueue
        WHERE status = 'pending'
        AND retryCount < maxRetries
        ORDER BY priority DESC, id ASC
        LIMIT batchSize;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
    BEGIN
        SET error_occurred = TRUE;
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
        
        -- Log the failed task
        INSERT INTO TaskQueue.FailedTasks (
            id,
            taskRefId,
            database,
            taskType,
            parameters,
            error,
            metadata
        )
        VALUES (
            UUID_v7(),
            task_id,
            task_database,
            task_type,
            task_params,
            CONCAT('Error: ', @errno, ' State: ', @sqlstate, ' Message: ', @text),
            task_metadata
        );
        
        -- Update task status
        UPDATE TaskQueue.ProcessQueue 
        SET status = 'failed',
            lastError = CONCAT('Error: ', @errno, ' State: ', @sqlstate, ' Message: ', @text),
            retryCount = retryCount + 1,
            completedAt = CURRENT_TIMESTAMP
        WHERE id = task_id;
        
        -- Commit the failure record and status update
        COMMIT;
        -- Start a new transaction for the next item
        START TRANSACTION;
    END;
    
    START TRANSACTION;
    OPEN cur;
    
    read_loop: LOOP
        -- Reset error flag at start of each iteration
        SET error_occurred = FALSE;
        
        FETCH cur INTO task_id, task_database, task_type, task_params, task_metadata;
        
        -- Exit if we're done or had a fetch error
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Mark as processing
        UPDATE TaskQueue.ProcessQueue 
        SET status = 'processing',
            startedAt = CURRENT_TIMESTAMP 
        WHERE id = task_id;
        
        -- Commit the status update
        COMMIT;
        
        -- Execute the stored procedure dynamically
        SET @sql = CONCAT('CALL ', task_database, '.', task_type, '(', 
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
        
        START TRANSACTION;
        
        -- Prepare and execute with error handling
        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            BEGIN
                SET error_occurred = TRUE;
                GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
                
                -- Log the failed task
                INSERT INTO TaskQueue.FailedTasks (
                    id,
                    taskRefId,
                    database,
                    taskType,
                    parameters,
                    error,
                    metadata
                )
                VALUES (
                    UUID_v7(),
                    task_id,
                    task_database,
                    task_type,
                    task_params,
                    CONCAT('Error: ', @errno, ' State: ', @sqlstate, ' Message: ', @text),
                    task_metadata
                );
                
                -- Commit the failure record
                COMMIT;
            END;
            
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            -- If no error occurred, mark as completed
            IF NOT error_occurred THEN
                UPDATE TaskQueue.ProcessQueue 
                SET status = 'completed',
                    completedAt = CURRENT_TIMESTAMP
                WHERE id = task_id;
                COMMIT;
            ELSE 
                -- Update task status
                UPDATE TaskQueue.ProcessQueue 
                SET status = 'failed',
                    lastError = CONCAT('Error: ', @errno, ' State: ', @sqlstate, ' Message: ', @text),
                    retryCount = retryCount + 1,
                    completedAt = CURRENT_TIMESTAMP
                WHERE id = task_id;
            END IF;
        END;
        
        START TRANSACTION;
    END LOOP;
    
    CLOSE cur;
    COMMIT;
    
    -- Clean up
    SET @sql = NULL;
END //

-- CREATE OR REPLACE  event to process queue periodically
CREATE EVENT IF NOT EXISTS ProcessQueueEvent
ON SCHEDULE EVERY 5 SECOND
DO
    CALL ProcessQueueItems(50) //

DELIMITER ;
-- Queue(
--     'update_user',
--     '{"name": "John Doe", "email": "john@example.com"}',
--     'users',
--     NOW(),
--     1
-- );

-- Process events manually (if needed)
-- CALL ProcessEvents();
