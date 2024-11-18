-- Create and use the database
CREATE DATABASE IF NOT EXISTS `Tmdb`;
USE Tmdb;

-- Disable foreign key checks for clean setup
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `ScrapersActivity`;
DROP TABLE IF EXISTS `Scrapers`;
DROP TABLE IF EXISTS `Deeplinks`;
DROP TABLE IF EXISTS `MoviesMetadata`;
DROP TABLE IF EXISTS `Movies`;
DROP TABLE IF EXISTS `AuditLog`;
SET FOREIGN_KEY_CHECKS = 1;

-- Core Movies table
CREATE TABLE Movies (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId BINARY(16) NOT NULL,
    title VARCHAR(255) NOT NULL,
    altTitle VARCHAR(255) NULL,
    releaseDate DATE NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    isDupe BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT MoviesUuid_UK UNIQUE KEY (contentId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX MoviesTitle_IDX USING BTREE ON Movies (title);
CREATE INDEX MoviesActive_IDX USING BTREE ON Movies (isActive);

-- Movies Metadata
CREATE TABLE MoviesMetadata (
    contentId BINARY(16) NOT NULL,
    deeplinkRefId BINARY(16) NOT NULL,
    slug VARCHAR(255) NULL,
    tmdbId VARCHAR(20) NULL,
    imdbId VARCHAR(20) NULL,
    rgId VARCHAR(50) NULL,
    title VARCHAR(255) NULL,
    originalTitle VARCHAR(255) NULL,
    description TEXT NULL,
    posterPath VARCHAR(255) NULL,
    backdropPath VARCHAR(255) NULL,
    runtime INT UNSIGNED NULL,
    popularity DECIMAL(10,2) NULL,
    voteAverage DECIMAL(3,1) NULL,
    voteCount INT UNSIGNED NULL,
    genres JSON NULL,
    productionCompanies JSON NULL,
    lastUpdated TIMESTAMP NULL,
    updateHistory JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (contentId),
    CONSTRAINT MoviesMetadataTmdb_UK UNIQUE KEY (tmdbId),
    CONSTRAINT MoviesMetadataDlid_UK UNIQUE KEY (deeplinkRefId),
    CONSTRAINT MoviesMetadataCid_FK FOREIGN KEY (contentId) 
        REFERENCES Movies(contentId) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX MoviesMetadataImdb_IDX USING BTREE ON MoviesMetadata (imdbId);
CREATE INDEX MoviesMetadataRg_IDX USING BTREE ON MoviesMetadata (rgId);

-- Deeplinks
CREATE TABLE Deeplinks (
    contentId BINARY(16) NOT NULL,
    deeplinkRefId BINARY(16) NOT NULL,
    sourceId SMALLINT DEFAULT 0 NOT NULL,
    sourceType VARCHAR(50) NOT NULL,
    originSource ENUM ('none', 'freecast', 'gracenote', 'reelgood') DEFAULT 'none' NOT NULL,
    region VARCHAR(10) NULL,
    platformLinks JSON NULL,
    pricing JSON NULL,
    availability JSON NULL,
    lastUpdated TIMESTAMP NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (contentId),
    CONSTRAINT DeeplinksDlid_UK UNIQUE KEY (deeplinkRefId),
    CONSTRAINT DeeplinksMetadata_FK FOREIGN KEY (deeplinkRefId) 
        REFERENCES MoviesMetadata(deeplinkRefId) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX DeeplinksActive_IDX USING BTREE ON Deeplinks (isActive);
CREATE INDEX DeeplinksSource_IDX USING BTREE ON Deeplinks (sourceId, sourceType);

-- Scrapers Configuration
CREATE TABLE Scrapers (
    scraperId BINARY(16) NOT NULL,
    adminRefId SMALLINT NULL,
    sourceSlug VARCHAR(50) NOT NULL,
    title VARCHAR(100) NOT NULL,
    scraperSrcTitle VARCHAR(100) NOT NULL,
    config JSON NULL,
    schedule JSON NULL,
    lastUpdated TIMESTAMP NULL,
    updateHistory JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (scraperId),
    CONSTRAINT ScrapersAdmin_UK UNIQUE KEY (adminRefId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Scrapers Activity Log
CREATE TABLE ScrapersActivity (
    id BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
    scraperId BINARY(16) NOT NULL,
    runId BINARY(16) NOT NULL,
    startTime TIMESTAMP NOT NULL,
    endTime TIMESTAMP NULL,
    status ENUM('pending', 'running', 'completed', 'failed', 'cancelled') NOT NULL,
    itemsProcessed INT UNSIGNED DEFAULT 0,
    itemsSucceeded INT UNSIGNED DEFAULT 0,
    itemsFailed INT UNSIGNED DEFAULT 0,
    error TEXT NULL,
    metadata JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT ScrapersActivity_FK FOREIGN KEY (scraperId) 
        REFERENCES Scrapers(scraperId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX ScrapersActivityRun_IDX USING BTREE ON ScrapersActivity (runId);
CREATE INDEX ScrapersActivityTime_IDX USING BTREE ON ScrapersActivity (startTime);

-- Audit Log for tracking all significant changes
CREATE TABLE AuditLog (
    id BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
    entityType VARCHAR(50) NOT NULL,
    entityId BINARY(16) NOT NULL,
    action ENUM('create', 'update', 'delete', 'restore') NOT NULL,
    userId VARCHAR(50) NULL,
    changes JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX AuditLogEntity_IDX USING BTREE ON AuditLog (entityType, entityId);
CREATE INDEX AuditLogTime_IDX USING BTREE ON AuditLog (created_at);

-- Triggers for automatic audit logging
DELIMITER //

CREATE TRIGGER Movies_Audit_Insert
AFTER INSERT ON Movies
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (entityType, entityId, action, changes)
    VALUES ('Movies', NEW.contentId, 'create', 
        JSON_OBJECT(
            'contentId', NEW.contentId,
            'title', NEW.title,
            'isActive', NEW.isActive
        )
    );
END//

CREATE TRIGGER Movies_Audit_Update
AFTER UPDATE ON Movies
FOR EACH ROW
BEGIN
    IF OLD.title != NEW.title OR OLD.isActive != NEW.isActive OR OLD.isDupe != NEW.isDupe THEN
        INSERT INTO AuditLog (entityType, entityId, action, changes)
        VALUES ('Movies', NEW.contentId, 'update',
            JSON_OBJECT(
                'before', JSON_OBJECT(
                    'title', OLD.title,
                    'isActive', OLD.isActive,
                    'isDupe', OLD.isDupe
                ),
                'after', JSON_OBJECT(
                    'title', NEW.title,
                    'isActive', NEW.isActive,
                    'isDupe', NEW.isDupe
                )
            )
        );
    END IF;
END//

CREATE TRIGGER Deeplinks_Audit
AFTER UPDATE ON Deeplinks
FOR EACH ROW
BEGIN
    IF OLD.isActive != NEW.isActive OR OLD.platformLinks != NEW.platformLinks THEN
        INSERT INTO AuditLog (entityType, entityId, action, changes)
        VALUES ('Deeplinks', NEW.contentId, 'update',
            JSON_OBJECT(
                'before', JSON_OBJECT(
                    'isActive', OLD.isActive,
                    'platformLinks', OLD.platformLinks
                ),
                'after', JSON_OBJECT(
                    'isActive', NEW.isActive,
                    'platformLinks', NEW.platformLinks
                )
            )
        );
    END IF;
END//

-- Procedure for generating test data
CREATE PROCEDURE InsertRandomData(IN count INT)
BEGIN
    DECLARE i INT DEFAULT 1;
    WHILE i <= count DO
        SET @uuid = UUID_TO_BIN(UUID());
        SET @dlid = UUID_TO_BIN(UUID());
        
        -- Insert movie
        INSERT INTO Movies (contentId, title)
        VALUES (@uuid, CONCAT('Movie ', i));
        
        -- Insert metadata
        INSERT INTO MoviesMetadata (contentId, deeplinkRefId, title, tmdbId)
        VALUES (@uuid, @dlid, CONCAT('Movie ', i), CONCAT('tt', LPAD(i, 7, '0')));
        
        -- Insert deeplink
        INSERT INTO Deeplinks (contentId, deeplinkRefId, sourceType)
        VALUES (@uuid, @dlid, 'test');
        
        SET i = i + 1;
    END WHILE;
END//

DELIMITER ;

-- Create test scraper
INSERT INTO Scrapers (scraperId, sourceSlug, title, scraperSrcTitle, config)
VALUES (
    UUID_TO_BIN(UUID()),
    'test-scraper',
    'Test Scraper',
    'Test Source',
    JSON_OBJECT(
        'enabled', true,
        'interval', 3600,
        'timeout', 300
    )
);
