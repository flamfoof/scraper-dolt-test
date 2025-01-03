DROP DATABASE IF EXISTS TaskQueue;
CREATE DATABASE TaskQueue;
USE TaskQueue;

DELIMITER ;

-- Process Queue Configuration
CREATE OR REPLACE TABLE ProcessQueue (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    database VARCHAR(64) NOT NULL,
    taskType VARCHAR(64) NOT NULL COMMENT 'Name of stored procedure to execute',
    status ENUM('pending', 'processing') DEFAULT 'pending' NOT NULL,
    parameters JSON NULL COMMENT 'Parameters to pass to the procedure',
    priority TINYINT UNSIGNED DEFAULT 1 NOT NULL,
    metadata JSON NULL COMMENT 'Additional task metadata',
    CONSTRAINT PRIMARY KEY (id),
    INDEX ProcessQueueStatus_IDX (id, status, priority),
    INDEX ProcessQueueType_IDX (taskType)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Completed Tasks Queue
CREATE OR REPLACE TABLE CompletedQueue (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    taskRefId UUID NOT NULL COMMENT 'Reference to original ProcessQueue.id',
    database VARCHAR(64) NOT NULL,
    taskType VARCHAR(64) NOT NULL,
    parameters JSON NULL,
    metadata JSON NULL,
    completedAt TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    INDEX CompletedQueueRef_IDX (taskRefId),
    INDEX CompletedQueueType_IDX (taskType),
    INDEX CompletedQueueTime_IDX (completedAt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Failed Tasks Queue
CREATE OR REPLACE TABLE FailedQueue (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    taskRefId UUID NOT NULL COMMENT 'Reference to original ProcessQueue.id',
    database VARCHAR(64) NOT NULL,
    taskType VARCHAR(64) NOT NULL,
    parameters JSON NULL,
    metadata JSON NULL,
    lastError TEXT NOT NULL,
    failedAt TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    INDEX FailedQueueRef_IDX (taskRefId),
    INDEX FailedQueueType_IDX (taskType),
    INDEX FailedQueueTime_IDX (failedAt)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER //

-- Function to get JSON representation of a Task
CREATE OR REPLACE FUNCTION GetTaskJSON(
    p_id UUID,
    p_taskType VARCHAR(100),
    p_parameters JSON,
    p_priority TINYINT UNSIGNED,
    p_status VARCHAR(20),
    p_metadata JSON
)
RETURNS JSON
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
CREATE OR REPLACE PROCEDURE QueueTask(
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
CREATE OR REPLACE PROCEDURE ProcessQueueItems(IN batchSize INT UNSIGNED)
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
        ORDER BY priority DESC, id ASC
        LIMIT batchSize;
    
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
    BEGIN
        SET error_occurred = TRUE;
        GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
    END;
    
    OPEN cur;
    
    read_loop: LOOP
        -- Reset error flag at start of each iteration
        SET error_occurred = FALSE;
        
        FETCH cur INTO task_id, task_database, task_type, task_params, task_metadata;
        
        -- Exit if we're done or had a fetch error
        IF done THEN
            LEAVE read_loop;
        END IF;
        
        -- Execute the stored procedure dynamically
        SET @sql = CONCAT(
            'CALL ', 
            task_database, 
            '.', 
            task_type, 
            '(', 
            QUOTE(task_params),  
            ')'
        );
        
        -- Prepare and execute with error handling
        BEGIN
            DECLARE CONTINUE HANDLER FOR SQLEXCEPTION
            BEGIN
                SET error_occurred = TRUE;
                GET DIAGNOSTICS CONDITION 1 @sqlstate = RETURNED_SQLSTATE, @errno = MYSQL_ERRNO, @text = MESSAGE_TEXT;
            END;
            
            START TRANSACTION;
            PREPARE stmt FROM @sql;
            EXECUTE stmt;
            DEALLOCATE PREPARE stmt;
            
            IF NOT error_occurred THEN
                -- Move to CompletedQueue
                INSERT INTO TaskQueue.CompletedQueue (
                    id,
                    taskRefId,
                    database,
                    taskType,
                    parameters,
                    metadata,
                    completedAt
                )
                SELECT 
                    UUID_v7(),
                    id,
                    database,
                    taskType,
                    parameters,
                    metadata,
                    CURRENT_TIMESTAMP
                FROM TaskQueue.ProcessQueue
                WHERE id = task_id;
                
                -- Remove from ProcessQueue
                DELETE FROM TaskQueue.ProcessQueue WHERE id = task_id;
            ELSE 
                -- Move to FailedQueue
                INSERT INTO TaskQueue.FailedQueue (
                    id,
                    taskRefId,
                    database,
                    taskType,
                    parameters,
                    metadata,
                    lastError,
                    failedAt
                )
                SELECT 
                    UUID_v7(),
                    id,
                    database,
                    taskType,
                    parameters,
                    metadata,
                    CONCAT('Error: ', @errno, ' State: ', @sqlstate, ' Message: ', @text),
                    CURRENT_TIMESTAMP
                FROM TaskQueue.ProcessQueue
                WHERE id = task_id;
                
                -- Remove from ProcessQueue
                DELETE FROM TaskQueue.ProcessQueue WHERE id = task_id;
            END IF;
            COMMIT;
        END;
    END LOOP;
    CLOSE cur;
    SET @sql = NULL;
END //

-- CREATE OR REPLACE event to process queue periodically
CREATE OR REPLACE EVENT ProcessQueueEvent
ON SCHEDULE EVERY 5 SECOND
DO
    CALL ProcessQueueItems(500) //

DELIMITER ;
