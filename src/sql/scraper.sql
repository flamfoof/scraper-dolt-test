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
    config JSON NULL,
    schedule JSON NULL,
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
    appContext ENUM('scraper', 'admin', 'api', 'system', 'manual') NOT NULL DEFAULT 'scraper',
    environment VARCHAR(16) NOT NULL DEFAULT 'dev' COMMENT 'Environment where change occurred',
    oldData JSON NULL,
    newData JSON NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT ScraperLog_FK FOREIGN KEY (scraperRefId) 
        REFERENCES Scrapers(scraperId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for ScraperLog table
CREATE INDEX ScraperLogEntity_IDX USING BTREE ON ScraperLog (tableName);
CREATE INDEX ScraperLogUser_IDX USING BTREE ON ScraperLog (username);
CREATE INDEX ScraperLogContext_IDX USING BTREE ON ScraperLog (appContext, environment);
CREATE INDEX ScraperLogRun_IDX USING BTREE ON ScraperLog (runId);

DELIMITER //

-- Function to get JSON representation of a Scraper record
CREATE FUNCTION GetScraperJSON(
    p_scraperId UUID,
    p_adminRefId SMALLINT UNSIGNED,
    p_sourceSlug VARCHAR(64),
    p_title VARCHAR(128),
    p_scraperSrcTitle VARCHAR(128),
    p_config JSON,
    p_schedule JSON
) RETURNS JSON
DETERMINISTIC
BEGIN
    RETURN JSON_OBJECT(
        'scraperId', p_scraperId,
        'adminRefId', p_adminRefId,
        'sourceSlug', p_sourceSlug,
        'title', p_title,
        'scraperSrcTitle', p_scraperSrcTitle,
        'config', p_config,
        'schedule', p_schedule
    );
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
        environment,
        oldData,
        newData
    )
    VALUES (
        UUID_TO_BIN(UUID(), 1),
        NEW.scraperId,
        UUID_TO_BIN(UUID(), 1),
        'Scrapers',
        'insert',
        @username,
        COALESCE(@appContext, 'system'),
        COALESCE(@environment, 'dev'),
        NULL,
        GetScraperJSON(
            NEW.scraperId,
            NEW.adminRefId,
            NEW.sourceSlug,
            NEW.title,
            NEW.scraperSrcTitle,
            NEW.config,
            NEW.schedule
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
        environment,
        oldData,
        newData
    )
    VALUES (
        UUID_TO_BIN(UUID(), 1),
        NEW.scraperId,
        UUID_TO_BIN(UUID(), 1),
        'Scrapers',
        'update',
        @username,
        COALESCE(@appContext, 'system'),
        COALESCE(@environment, 'dev'),
        GetScraperJSON(
            OLD.scraperId,
            OLD.adminRefId,
            OLD.sourceSlug,
            OLD.title,
            OLD.scraperSrcTitle,
            OLD.config,
            OLD.schedule
        ),
        GetScraperJSON(
            NEW.scraperId,
            NEW.adminRefId,
            NEW.sourceSlug,
            NEW.title,
            NEW.scraperSrcTitle,
            NEW.config,
            NEW.schedule
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
        environment,
        oldData,
        newData
    )
    VALUES (
        UUID_TO_BIN(UUID(), 1),
        OLD.scraperId,
        UUID_TO_BIN(UUID(), 1),
        'Scrapers',
        'delete',
        @username,
        COALESCE(@appContext, 'system'),
        COALESCE(@environment, 'dev'),
        GetScraperJSON(
            OLD.scraperId,
            OLD.adminRefId,
            OLD.sourceSlug,
            OLD.title,
            OLD.scraperSrcTitle,
            OLD.config,
            OLD.schedule
        ),
        NULL
    );
END //

DELIMITER ;
