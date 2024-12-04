DROP DATABASE IF EXISTS `Scrapers`;
CREATE DATABASE `Scrapers`;
USE Scrapers;

DELIMITER ;

-- Scrapers Configuration
CREATE TABLE Scrapers (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    scraperId UUID NOT NULL COMMENT 'UUIDv5 format with <scraper>-<name>',
    adminRefId SMALLINT UNSIGNED NULL COMMENT 'Reference to <id> in Admin DB',
    sourceSlug VARCHAR(64) NOT NULL COMMENT 'Slug of the source',
    title VARCHAR(128) NOT NULL,
    scraperSrcTitle VARCHAR(128) NOT NULL COMMENT 'Title of the scraper name in Admin DB',
    image VARCHAR(255) NULL,
    config JSON NULL,
    schedule JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT Scrapers_UK UNIQUE KEY (scraperId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Scrapers Activity Log - optimized with UUIDv7
CREATE TABLE ScrapersActivity (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    scraperRefId UUID NOT NULL COMMENT 'UUIDv5 format with <scraper>-<name>',
    runId UUID NOT NULL,
    contentType ENUM('movies', 'series') NULL,
    endTime TIMESTAMP NULL,
    startTime TIMESTAMP NOT NULL,
    status ENUM ('pending', 'running', 'completed', 'failed', 'cancelled') DEFAULT 'pending' NOT NULL,
    totalItems INT UNSIGNED NOT NULL DEFAULT 0,
    processedItems INT UNSIGNED NOT NULL DEFAULT 0,
    errorItems INT UNSIGNED NOT NULL DEFAULT 0,
    error TEXT NULL,
    metadata JSON NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT ScrapersActivity_FK FOREIGN KEY (scraperRefId) 
        REFERENCES Scrapers(scraperId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Scrapers Log - optimized with UUIDv7
CREATE TABLE ScraperLog (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    scraperRefId UUID NOT NULL COMMENT 'Reference to Scrapers.scraperId',
    runId UUID NOT NULL COMMENT 'Reference to ScrapersActivity.runId',
    tableName VARCHAR(64) NOT NULL,
    action ENUM('create', 'insert', 'update', 'delete', 'restore', 'skip') NOT NULL,
    username VARCHAR(64) NULL COMMENT 'Username of who made the change',
    appContext ENUM('scraper', 'admin', 'api', 'system', 'manual', 'user') NOT NULL DEFAULT 'scraper',
    oldData JSON NULL,
    newData JSON NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT ScraperLog_FK FOREIGN KEY (scraperRefId) 
        REFERENCES Scrapers(scraperId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for ScraperLog table
CREATE INDEX ScraperLogEntity_IDX USING BTREE ON ScraperLog (tableName);
CREATE INDEX ScraperLogUser_IDX USING BTREE ON ScraperLog (username);
CREATE INDEX ScraperLogContext_IDX USING BTREE ON ScraperLog (appContext);
CREATE INDEX ScraperLogRun_IDX USING BTREE ON ScraperLog (runId);

DELIMITER //

-- Function to get JSON representation of a Scraper record
CREATE FUNCTION GetScraperJSON(
    p_scraperId UUID,
    p_adminRefId SMALLINT UNSIGNED,
    p_sourceSlug VARCHAR(64),
    p_title VARCHAR(128),
    p_scraperSrcTitle VARCHAR(128),
    p_image VARCHAR(255),
    p_config JSON,
    p_schedule JSON,
    p_isActive BOOLEAN
) RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    SET result = JSON_OBJECT();
    
    -- Always include non-nullable fields
    SET result = JSON_SET(result,
        '$.scraperId', p_scraperId,
        '$.sourceSlug', p_sourceSlug,
        '$.title', p_title,
        '$.scraperSrcTitle', p_scraperSrcTitle,
        '$.isActive', COALESCE(p_isActive, true)
    );
    
    -- Add optional fields only if they are not null
    IF p_adminRefId IS NOT NULL THEN
        SET result = JSON_SET(result, '$.adminRefId', p_adminRefId);
    END IF;

    IF p_image IS NOT NULL THEN
        SET result = JSON_SET(result, '$.image', p_image);
    END IF;
    
    IF p_config IS NOT NULL THEN
        SET result = JSON_SET(result, '$.config', p_config);
    END IF;
    
    IF p_schedule IS NOT NULL THEN
        SET result = JSON_SET(result, '$.schedule', p_schedule);
    END IF;
    
    RETURN result;
END //

-- Scrapers table triggers
CREATE TRIGGER Scrapers_Insert_Audit
AFTER INSERT ON Scrapers
FOR EACH ROW
BEGIN
    INSERT INTO ScraperLog (
        id,
        scraperRefId,
        runId,
        tableName,
        action,
        username,
        appContext,
        oldData,
        newData
    )
    VALUES (
        UUID_v7(),
        NEW.scraperId,
        UUID_v7(),
        'Scrapers',
        'insert',
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system'),
        NULL,
        GetScraperJSON(
            NEW.scraperId,
            NEW.adminRefId,
            NEW.sourceSlug,
            NEW.title,
            NEW.scraperSrcTitle,
            NEW.image,
            NEW.config,
            NEW.schedule,
            NEW.isActive
        )
    );
END //

CREATE TRIGGER Scrapers_Update_Audit
AFTER UPDATE ON Scrapers
FOR EACH ROW
BEGIN
    INSERT INTO ScraperLog (
        id,
        scraperRefId,
        runId,
        tableName,
        action,
        username,
        appContext,
        oldData,
        newData
    )
    VALUES (
        UUID_v7(),
        NEW.scraperId,
        UUID_v7(),
        'Scrapers',
        'update',
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system'),
        GetScraperJSON(
            OLD.scraperId,
            OLD.adminRefId,
            OLD.sourceSlug,
            OLD.title,
            OLD.scraperSrcTitle,
            OLD.image,
            OLD.config,
            OLD.schedule,
            OLD.isActive
        ),
        GetScraperJSON(
            NEW.scraperId,
            NEW.adminRefId,
            NEW.sourceSlug,
            NEW.title,
            NEW.scraperSrcTitle,
            NEW.image,
            NEW.config,
            NEW.schedule,
            NEW.isActive
        )
    );
END //

CREATE TRIGGER Scrapers_Delete_Audit
AFTER DELETE ON Scrapers
FOR EACH ROW
BEGIN
    INSERT INTO ScraperLog (
        id,
        scraperRefId,
        runId,
        tableName,
        action,
        username,
        appContext,
        oldData,
        newData
    )
    VALUES (
        UUID_v7(),
        OLD.scraperId,
        UUID_v7(),
        'Scrapers',
        'delete',
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system'),
        GetScraperJSON(
            OLD.scraperId,
            OLD.adminRefId,
            OLD.sourceSlug,
            OLD.title,
            OLD.scraperSrcTitle,
            OLD.image,
            OLD.config,
            OLD.schedule,
            OLD.isActive
        ),
        NULL
    );
END //

DELIMITER ;
