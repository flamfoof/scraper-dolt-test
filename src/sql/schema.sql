-- Create and use the database
CREATE DATABASE IF NOT EXISTS `Tmdb`;
USE Tmdb;

-- Disable foreign key checks for clean setup
SET FOREIGN_KEY_CHECKS = 0;

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


CALL DropAllTables(); //

DELIMITER ;

SET FOREIGN_KEY_CHECKS = 1;

-- Core Movies table
CREATE TABLE Movies (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'UUIDv5 format with <content>-<tmdbId>',
    tmdbId VARCHAR(20) NULL,
    imdbId VARCHAR(20) NULL,
    rgId VARCHAR(128) NULL,
    title VARCHAR(255) NOT NULL,
    originalTitle VARCHAR(255) NULL,
    altTitle VARCHAR(255) NULL,
    description TEXT NULL,
    runtime INT UNSIGNED NULL COMMENT 'Runtime in minutes',
    releaseDate DATE NULL,
    posterPath VARCHAR(255) NULL,
    backdropPath VARCHAR(255) NULL,
    popularity DECIMAL(10,2) NULL,
    voteAverage DECIMAL(3,1) NULL,
    voteCount INT UNSIGNED NULL,
    genres JSON NULL,
    keywords JSON NULL,
    cast JSON NULL,
    crew JSON NULL,
    productionCompanies JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    isDupe BOOLEAN DEFAULT false NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT MoviesUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT MoviesTmdb_UK UNIQUE KEY (tmdbId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- TV Series table
CREATE TABLE Series (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'UUIDv5 format with <content>-<tmdbId>',
    tmdbId VARCHAR(20) NULL,
    imdbId VARCHAR(20) NULL,
    rgId VARCHAR(128) NULL,
    title VARCHAR(255) NOT NULL,
    originalTitle VARCHAR(255) NULL,
    altTitle VARCHAR(255) NULL,
    description TEXT NULL,
    releaseDate DATE NULL,
    posterPath VARCHAR(255) NULL,
    backdropPath VARCHAR(255) NULL,
    popularity DECIMAL(10,2) NULL,
    voteAverage DECIMAL(3,1) NULL,
    voteCount INT UNSIGNED NULL,
    genres JSON NULL,
    keywords JSON NULL,
    cast JSON NULL,
    crew JSON NULL,
    productionCompanies JSON NULL,
    networks JSON NULL,
    totalSeasons INT UNSIGNED DEFAULT 0 NULL,
    totalEpisodes INT UNSIGNED DEFAULT 0 NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    isDupe BOOLEAN DEFAULT false NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT SeriesUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT SeriesTmdb_UK UNIQUE KEY (tmdbId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seasons table
CREATE TABLE Seasons (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    contentRefId UUID NOT NULL COMMENT 'Reference to Series.contentId',
    title VARCHAR(255) NULL,
    description TEXT NULL,
    seasonNumber SMALLINT UNSIGNED DEFAULT 0 NOT NULL,
    episodeCount SMALLINT UNSIGNED DEFAULT 0 NULL,
    releaseDate DATE NULL,
    posterPath VARCHAR(255) NULL,
    voteAverage DECIMAL(3,1) NULL,
    voteCount INT UNSIGNED NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT SeasonsUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT SeasonsNumber_UK UNIQUE KEY (contentRefId, seasonNumber),
    CONSTRAINT SeasonsSeries_FK FOREIGN KEY (contentRefId) 
        REFERENCES Series(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episodes table
CREATE TABLE Episodes (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    contentRefId UUID NOT NULL COMMENT 'Reference to Seasons.contentId',
    tmdbId VARCHAR(20) NULL,
    imdbId VARCHAR(20) NULL,
    rgId VARCHAR(128) NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NULL,
    episodeNumber SMALLINT DEFAULT -1 NOT NULL,
    runtime SMALLINT UNSIGNED NULL COMMENT 'Runtime in minutes',
    releaseDate DATE NULL,
    voteAverage DECIMAL(3,1) NULL,
    voteCount INT UNSIGNED NULL,
    posterPath VARCHAR(255) NULL,
    backdropPath VARCHAR(255) NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT EpisodesUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT EpisodesTmdb_UK UNIQUE KEY (tmdbId),
    CONSTRAINT EpisodesSeason_FK FOREIGN KEY (contentRefId)
        REFERENCES Seasons(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Movie Deeplinks table for storing platform-specific movie links
CREATE TABLE MoviesDeeplinks (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'UUIDv5 format with <content>-<tmdbId>',
    contentRefId UUID NULL COMMENT 'Reference to Movies.contentId',
    imdbId VARCHAR(20) NULL,
    tmdbId VARCHAR(20) NULL,
    rgId VARCHAR(128) NULL,
    title VARCHAR(255) NULL COMMENT 'This is the title scraped from the scraper',
    altTitle VARCHAR(255) NULL COMMENT 'If set, this will override the scrapers title, use it to match the TMDB title',
    releaseDate DATE NULL,
    altReleaseDate DATE NULL COMMENT 'If set, this will override the scrapers release date, use it to match the TMDB title',
    sourceId SMALLINT UNSIGNED NOT NULL,
    sourceType VARCHAR(64) NOT NULL,
    originSource ENUM ('none', 'freecast', 'gracenote', 'reelgood', 'tmdb') DEFAULT 'none' NOT NULL,
    region VARCHAR(10) NULL,
    -- Platform specific links
    web VARCHAR(512) NULL COMMENT 'Web browser URL',
    android VARCHAR(512) NULL COMMENT 'Android mobile app deep link',
    iOS VARCHAR(512) NULL COMMENT 'iOS mobile app deep link',
    androidTv VARCHAR(512) NULL COMMENT 'Android TV app deep link',
    fireTv VARCHAR(512) NULL COMMENT 'Amazon Fire TV app deep link',
    lg VARCHAR(512) NULL COMMENT 'LG WebOS TV app deep link',
    samsung VARCHAR(512) NULL COMMENT 'Samsung Tizen TV app deep link',
    tvOS VARCHAR(512) NULL COMMENT 'Apple TV app deep link',
    roku VARCHAR(512) NULL COMMENT 'Roku app deep link',
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT MoviesDeeplinksContent_UK UNIQUE KEY (contentId),
    CONSTRAINT MoviesDeeplinksContentSource_UK UNIQUE KEY (contentRefId, sourceId, originSource),
    CONSTRAINT MoviesDeeplinksContentRef_FK FOREIGN KEY (contentRefId)
        REFERENCES Movies(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episode Deeplinks table for storing platform-specific episode links
CREATE TABLE EpisodesDeeplinks (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'UUIDv5 format with <content>-<tmdbId>',
    contentRefId UUID NULL COMMENT 'Reference to Episodes.contentId',
    imdbId VARCHAR(20) NULL,
    tmdbId VARCHAR(20) NULL,
    rgId VARCHAR(128) NULL,
    title VARCHAR(255) NULL COMMENT 'This is the title scraped from the scraper',
    altTitle VARCHAR(255) NULL COMMENT 'If set, this will override the scrapers title, use it to match the TMDB title',
    releaseDate DATE NULL,
    altReleaseDate DATE NULL COMMENT 'If set, this will override the scrapers release date, use it to match the TMDB title',
    sourceId SMALLINT UNSIGNED NOT NULL,
    sourceType VARCHAR(64) NOT NULL,
    originSource ENUM ('none', 'freecast', 'gracenote', 'reelgood', 'tmdb') DEFAULT 'none' NOT NULL,
    region VARCHAR(10) NULL,
    -- Platform specific links
    web VARCHAR(512) NULL COMMENT 'Web browser URL',
    android VARCHAR(512) NULL COMMENT 'Android mobile app deep link',
    iOS VARCHAR(512) NULL COMMENT 'iOS mobile app deep link',
    androidTv VARCHAR(512) NULL COMMENT 'Android TV app deep link',
    fireTv VARCHAR(512) NULL COMMENT 'Amazon Fire TV app deep link',
    lg VARCHAR(512) NULL COMMENT 'LG WebOS TV app deep link',
    samsung VARCHAR(512) NULL COMMENT 'Samsung Tizen TV app deep link',
    tvOS VARCHAR(512) NULL COMMENT 'Apple TV app deep link',
    roku VARCHAR(512) NULL COMMENT 'Roku app deep link',
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT EpisodesDeeplinksContent_UK UNIQUE KEY (contentId),
    CONSTRAINT EpisodesDeeplinksContentSource_UK UNIQUE KEY (contentRefId, sourceId, originSource),
    CONSTRAINT EpisodesDeeplinksContentRef_FK FOREIGN KEY (contentRefId)
        REFERENCES Episodes(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Movies Prices table for storing movie pricing information
CREATE TABLE MoviesPrices (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'UUIDV5 format with <content>-<deeplinkSource>-<tmdbId>',
    contentRefId UUID NULL COMMENT 'Reference to MoviesDeeplinks.contentId',
    region VARCHAR(10) NULL,
    -- Buy prices of movies
    buySD DECIMAL(10,2) NULL COMMENT 'SD quality purchase price of movies',
    buyHD DECIMAL(10,2) NULL COMMENT 'HD quality purchase price of movies',
    buyUHD DECIMAL(10,2) NULL COMMENT 'UHD/4K quality purchase price of movies',
    -- Rental prices of movies
    rentSD DECIMAL(10,2) NULL COMMENT 'SD quality rental price of movies',
    rentHD DECIMAL(10,2) NULL COMMENT 'HD quality rental price of movies',
    rentUHD DECIMAL(10,2) NULL COMMENT 'UHD/4K quality rental price of movies',
    -- Metadata
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_content_id (contentId),
    INDEX idx_content_ref_id (contentRefId),
    INDEX idx_region (region),
    CONSTRAINT MoviesPricesContent_UK UNIQUE KEY (contentRefId, region),
    CONSTRAINT MoviesPricesDeeplinks_FK
        FOREIGN KEY (contentRefId)
        REFERENCES MoviesDeeplinks (contentId)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episodes Prices table for storing TV content pricing information
CREATE TABLE EpisodesPrices (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'UUIDV5 format with <content>-<deeplinkSource>-<tmdbId>',
    contentRefId UUID NULL COMMENT 'Reference to EpisodesDeeplinks.contentId',
    region VARCHAR(10) NULL,
    -- Buy prices of episodes
    buySD DECIMAL(10,2) NULL COMMENT 'SD quality purchase price of episodes',
    buyHD DECIMAL(10,2) NULL COMMENT 'HD quality purchase price of episodes',
    buyUHD DECIMAL(10,2) NULL COMMENT 'UHD/4K quality purchase price of episodes',
    -- Rental prices of episodes
    rentSD DECIMAL(10,2) NULL COMMENT 'SD quality rental price of episodes',
    rentHD DECIMAL(10,2) NULL COMMENT 'HD quality rental price of episodes',
    rentUHD DECIMAL(10,2) NULL COMMENT 'UHD/4K quality rental price of episodes',
    -- Series buy prices
    seriesBuySD DECIMAL(10,2) NULL COMMENT 'SD quality series purchase price',
    seriesBuyHD DECIMAL(10,2) NULL COMMENT 'HD quality series purchase price',
    seriesBuyUHD DECIMAL(10,2) NULL COMMENT 'UHD/4K quality series purchase price',
    -- Series rental prices
    seriesRentSD DECIMAL(10,2) NULL COMMENT 'SD quality series rental price',
    seriesRentHD DECIMAL(10,2) NULL COMMENT 'HD quality series rental price',
    seriesRentUHD DECIMAL(10,2) NULL COMMENT 'UHD/4K quality series rental price',
    -- Season buy prices
    seasonBuySD DECIMAL(10,2) NULL COMMENT 'SD quality season purchase price',
    seasonBuyHD DECIMAL(10,2) NULL COMMENT 'HD quality season purchase price',
    seasonBuyUHD DECIMAL(10,2) NULL COMMENT 'UHD/4K quality season purchase price',
    -- Season rental prices
    seasonRentSD DECIMAL(10,2) NULL COMMENT 'SD quality season rental price',
    seasonRentHD DECIMAL(10,2) NULL COMMENT 'HD quality season rental price',
    seasonRentUHD DECIMAL(10,2) NULL COMMENT 'UHD/4K quality season rental price',
    -- Metadata
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    PRIMARY KEY (id),
    INDEX idx_content_id (contentId),
    INDEX idx_content_ref_id (contentRefId),
    INDEX idx_region (region),
    CONSTRAINT EpisodesPricesContent_UK UNIQUE KEY (contentRefId, region),
    CONSTRAINT EpisodesPricesDeeplinks_FK
        FOREIGN KEY (contentRefId)
        REFERENCES EpisodesDeeplinks (contentId)
        ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audit Log for tracking all significant changes
CREATE TABLE AuditLog (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    tableName VARCHAR(64) NOT NULL,
    action ENUM('create', 'insert', 'update', 'delete', 'restore') NOT NULL,
    username VARCHAR(64) NULL COMMENT 'Username of who made the change',
    appContext ENUM('scraper', 'admin', 'api', 'system', 'manual') NOT NULL DEFAULT 'system',
    environment VARCHAR(16) NOT NULL DEFAULT 'production' COMMENT 'Environment where change occurred',
    oldData JSON NULL,
    newData JSON NULL,
    CONSTRAINT PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for AuditLog table
CREATE INDEX AuditLogEntity_IDX USING BTREE ON AuditLog (tableName);
CREATE INDEX AuditLogUser_IDX USING BTREE ON AuditLog (username);
CREATE INDEX AuditLogContext_IDX USING BTREE ON AuditLog (appContext, environment);

-- Drop old Deeplinks table
DROP TABLE IF EXISTS Deeplinks;

-- Indexes for better query performance
CREATE INDEX MoviesTitle_IDX USING BTREE ON Movies (title);
CREATE INDEX MoviesActive_IDX USING BTREE ON Movies (isActive);

CREATE INDEX SeriesTitle_IDX USING BTREE ON Series (title);
CREATE INDEX SeriesActive_IDX USING BTREE ON Series (isActive);

CREATE INDEX SeasonsShow_IDX USING BTREE ON Seasons (contentRefId, seasonNumber);
CREATE INDEX SeasonsActive_IDX USING BTREE ON Seasons (isActive);

CREATE INDEX EpisodesSeason_IDX USING BTREE ON Episodes (contentRefId);
CREATE INDEX EpisodesActive_IDX USING BTREE ON Episodes (isActive);

CREATE INDEX MoviesDeeplinksContent_IDX USING BTREE ON MoviesDeeplinks (contentId);
CREATE UNIQUE INDEX MoviesDeeplinksRefSource_UK ON MoviesDeeplinks (contentRefId, sourceId, originSource);
CREATE INDEX MoviesDeeplinksSource_IDX USING BTREE ON MoviesDeeplinks (sourceId, sourceType, region);

CREATE INDEX EpisodesDeeplinksContent_IDX USING BTREE ON EpisodesDeeplinks (contentId);
CREATE UNIQUE INDEX EpisodesDeeplinksRefSource_UK ON EpisodesDeeplinks (contentRefId, sourceId, originSource);
CREATE INDEX EpisodesDeeplinksSource_IDX USING BTREE ON EpisodesDeeplinks (sourceId, sourceType, region);

DELIMITER //

-- drop all triggers
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

CALL DropAllFunctions(); //


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

CALL DropAllTriggers(); //


-- Movies triggers
CREATE TRIGGER Movies_Insert_Audit
AFTER INSERT ON Movies
FOR EACH row
BEGIN
    CALL LogAudit('Movies', NEW.contentId, 'insert',
        NULL,
        GetContentJSON(NEW.contentId, NEW.title, NEW.tmdbId, NEW.isActive),
        @username,
        @appContext,
        @environment
    );
END //

CREATE TRIGGER Movies_Update_Audit
AFTER UPDATE ON Movies
FOR EACH row
BEGIN
    CALL LogAudit('Movies', NEW.contentId, 'update',
        GetContentJSON(OLD.contentId, OLD.title, OLD.tmdbId, OLD.isActive),
        GetContentJSON(NEW.contentId, NEW.title, NEW.tmdbId, NEW.isActive),
        @username,
        @appContext,
        @environment
    );
END //

CREATE TRIGGER Movies_Delete_Audit
AFTER DELETE ON Movies
FOR EACH row
BEGIN
    CALL LogAudit('Movies', OLD.contentId, 'delete',
        GetContentJSON(OLD.contentId, OLD.title, OLD.tmdbId, OLD.isActive),
        NULL,
        @username,
        @appContext,
        @environment
    );
END //

-- Series triggers
CREATE TRIGGER Series_Insert_Audit
AFTER INSERT ON Series
FOR EACH row
BEGIN
    CALL LogAudit('Series', NEW.contentId, 'insert',
        NULL,
        GetContentJSON(NEW.contentId, NEW.title, NEW.tmdbId, NEW.isActive),
        @username,
        @appContext,
        @environment
    );
END //

CREATE TRIGGER Series_Update_Audit
AFTER UPDATE ON Series
FOR EACH row
BEGIN
    CALL LogAudit('Series', NEW.contentId, 'update',
        GetContentJSON(OLD.contentId, OLD.title, OLD.tmdbId, OLD.isActive),
        GetContentJSON(NEW.contentId, NEW.title, NEW.tmdbId, NEW.isActive),
        @username,
        @appContext,
        @environment
    );
END //

CREATE TRIGGER Series_Delete_Audit
AFTER DELETE ON Series
FOR EACH row
BEGIN
    CALL LogAudit('Series', OLD.contentId, 'delete',
        GetContentJSON(OLD.contentId, OLD.title, OLD.tmdbId, OLD.isActive),
        NULL,
        @username,
        @appContext,
        @environment
    );
END //

-- Seasons triggers
CREATE TRIGGER Seasons_Insert_Audit
AFTER INSERT ON Seasons
FOR EACH row
BEGIN
    CALL LogAudit('Seasons', NEW.contentId, 'insert',
        NULL,
        GetSeasonJSON(NEW.contentId, NEW.contentRefId, NEW.seasonNumber, NEW.title, NEW.isActive),
        @username,
        @appContext,
        @environment
    );
END //

CREATE TRIGGER Seasons_Update_Audit
AFTER UPDATE ON Seasons
FOR EACH row
BEGIN
    CALL LogAudit('Seasons', NEW.contentId, 'update',
        GetSeasonJSON(OLD.contentId, OLD.contentRefId, OLD.seasonNumber, OLD.title, OLD.isActive),
        GetSeasonJSON(NEW.contentId, NEW.contentRefId, NEW.seasonNumber, NEW.title, NEW.isActive),
        @username,
        @appContext,
        @environment
    );
END //

CREATE TRIGGER Seasons_Delete_Audit
AFTER DELETE ON Seasons
FOR EACH row
BEGIN
    CALL LogAudit('Seasons', OLD.contentId, 'delete',
        GetSeasonJSON(OLD.contentId, OLD.contentRefId, OLD.seasonNumber, OLD.title, OLD.isActive),
        NULL,
        @username,
        @appContext,
        @environment
    );
END //

-- Episodes triggers
CREATE TRIGGER Episodes_Insert_Audit
AFTER INSERT ON Episodes
FOR EACH row
BEGIN
    CALL LogAudit('Episodes', NEW.contentId, 'insert',
        NULL,
        GetEpisodeJSON(NEW.contentId, NEW.contentRefId, NEW.episodeNumber, NEW.title, NEW.tmdbId, NEW.isActive),
        @username,
        @appContext,
        @environment
    );
END //

CREATE TRIGGER Episodes_Update_Audit
AFTER UPDATE ON Episodes
FOR EACH row
BEGIN
    CALL LogAudit('Episodes', NEW.contentId, 'update',
        GetEpisodeJSON(OLD.contentId, OLD.contentRefId, OLD.episodeNumber, OLD.title, OLD.tmdbId, OLD.isActive),
        GetEpisodeJSON(NEW.contentId, NEW.contentRefId, NEW.episodeNumber, NEW.title, NEW.tmdbId, NEW.isActive),
        @username,
        @appContext,
        @environment
    );
END //

CREATE TRIGGER Episodes_Delete_Audit
AFTER DELETE ON Episodes
FOR EACH row
BEGIN
    CALL LogAudit('Episodes', OLD.contentId, 'delete',
        GetEpisodeJSON(OLD.contentId, OLD.contentRefId, OLD.episodeNumber, OLD.title, OLD.tmdbId, OLD.isActive),
        NULL,
        @username,
        @appContext,
        @environment
    );
END //

-- Create trigger to update Series.seasonContentIds when a new season is added
CREATE TRIGGER Seasons_Series_Insert AFTER INSERT ON Seasons
FOR EACH row
BEGIN
    UPDATE Series 
    SET totalSeasons = totalSeasons + 1
    WHERE contentId = NEW.contentRefId;
END //

-- Create trigger to update Series.seasonContentIds when a season is deleted
CREATE TRIGGER Seasons_Series_Delete AFTER DELETE ON Seasons
FOR EACH row
BEGIN
    UPDATE Series 
    SET totalSeasons = totalSeasons - 1
    WHERE contentId = OLD.contentRefId;
END //

-- Create trigger to update Seasons.episodeContentIds when a new episode is added
CREATE TRIGGER Episodes_Seasons_Insert AFTER INSERT ON Episodes
FOR EACH row
BEGIN
    UPDATE Seasons 
    SET episodeCount = episodeCount + 1
    WHERE contentId = NEW.contentRefId;
END //

-- Create trigger to update Seasons.episodeContentIds when an episode is deleted
CREATE TRIGGER Episodes_Seasons_Delete AFTER DELETE ON Episodes
FOR EACH row
BEGIN
    UPDATE Seasons 
    SET episodeCount = episodeCount - 1
    WHERE contentId = OLD.contentRefId;
END //


-- Audit helper procedures and functions
-- Central audit logging procedure
CREATE PROCEDURE LogAudit(
    IN tableName VARCHAR(64),
    IN recordId UUID,
    IN actionType ENUM('insert', 'update', 'delete', 'restore'),
    IN oldData JSON,
    IN newData JSON,
    IN username VARCHAR(64),
    IN context ENUM('scraper', 'admin', 'api', 'system', 'manual'),
    IN env VARCHAR(16)
)
BEGIN
    INSERT INTO AuditLog (
        id,
        tableName,
        action,
        username,
        appContext,
        environment,
        oldData,
        newData
    ) VALUES (
        UUID_v7(),
        tableName,
        actionType,
        IFNULL(username, 'system'),
        IFNULL(context, 'system'),
        IFNULL(env, 'production'),
        oldData,
        newData
    );
END //

-- Helper function for content JSON
CREATE FUNCTION GetContentJSON(
    contentId UUID,
    title VARCHAR(255),
    tmdbId INT,
    isActive BOOLEAN
) RETURNS JSON
DETERMINISTIC
BEGIN
    RETURN JSON_OBJECT(
        'contentId', contentId,
        'title', title,
        'tmdbId', tmdbId,
        'isActive', isActive
    );
END //

-- Helper function for metadata JSON
CREATE FUNCTION GetMetadataJSON(
    contentId UUID,
    title VARCHAR(255),
    isActive BOOLEAN
) RETURNS JSON
DETERMINISTIC
BEGIN
    RETURN JSON_OBJECT(
        'contentId', contentId,
        'title', title,
        'isActive', isActive
    );
END //

-- Helper function for episode JSON
CREATE FUNCTION GetEpisodeJSON(
    contentId UUID,
    contentRefId UUID,
    episodeNumber INT,
    title VARCHAR(255),
    tmdbId INT,
    isActive BOOLEAN
) RETURNS JSON
DETERMINISTIC
BEGIN
    RETURN JSON_OBJECT(
        'contentId', contentId,
        'contentRefId', contentRefId,
        'episodeNumber', episodeNumber,
        'title', title,
        'tmdbId', tmdbId,
        'isActive', isActive
    );
END //

-- Helper function for season JSON
CREATE FUNCTION GetSeasonJSON(
    contentId UUID,
    contentRefId UUID,
    seasonNumber INT,
    title VARCHAR(255),
    isActive BOOLEAN
) RETURNS JSON
DETERMINISTIC
BEGIN
    RETURN JSON_OBJECT(
        'contentId', contentId,
        'contentRefId', contentRefId,
        'seasonNumber', seasonNumber,
        'title', title,
        'isActive', isActive
    );
END //

-- Remove the drop all procedures just to be safe
DROP PROCEDURE IF EXISTS DropAllProcedures //
DROP PROCEDURE IF EXISTS DropAllFunctions //
DROP PROCEDURE IF EXISTS DropAllTriggers //
DROP PROCEDURE IF EXISTS DropAllTables //
DELIMITER ;
