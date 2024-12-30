-- Create and use the database
CREATE DATABASE IF NOT EXISTS `Tmdb`;
USE Tmdb;

-- Disable foreign key checks for clean setup
SET FOREIGN_KEY_CHECKS = 0;

DELIMITER //

CALL DropAllFunctions(); //
CALL DropAllTriggers(); //
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
    titleId UUID NULL COMMENT 'UUIDv5 from title',
    title VARCHAR(255) NOT NULL,
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
    titleId UUID NULL COMMENT 'UUIDv5 from title',
    title VARCHAR(255) NOT NULL,
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
    contentRefId UUID NULL COMMENT 'Reference to Series.contentId',
    titleId UUID NULL COMMENT 'UUIDv5 from title',
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
        REFERENCES Series(contentId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episodes table
CREATE TABLE Episodes (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    contentRefId UUID NULL COMMENT 'Reference to Seasons.contentId',
    tmdbId VARCHAR(20) NULL,
    imdbId VARCHAR(20) NULL,
    rgId VARCHAR(128) NULL,
    titleId UUID NULL COMMENT 'UUIDv5 from title',
    title VARCHAR(255) NOT NULL,
    altTitle VARCHAR(255) NULL,
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
    CONSTRAINT EpisodesNumber_UK UNIQUE KEY (contentRefId, episodeNumber),
    CONSTRAINT EpisodesSeason_FK FOREIGN KEY (contentRefId)
        REFERENCES Seasons(contentId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Movie Deeplinks table for storing platform-specific movie links
CREATE TABLE MoviesDeeplinks (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'UUIDv5 format with <content>-<tmdbId>',
    contentRefId UUID NULL COMMENT 'Reference to Movies.contentId',
    tmdbId VARCHAR(20) NULL,
    sourceId SMALLINT UNSIGNED NOT NULL,
    sourceType VARCHAR(64) NOT NULL,
    title VARCHAR(255) NULL COMMENT 'This is the title scraped from the scraper',
    altTitle VARCHAR(255) NULL COMMENT 'If set, this will override the scrapers title, use it to match the TMDB title',
    releaseDate DATE NULL,
    altReleaseDate DATE NULL COMMENT 'If set, this will override the scrapers release date, use it to match the TMDB title',
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
        REFERENCES Movies(contentId) 
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episode Deeplinks table for storing platform-specific episode links
CREATE TABLE SeriesDeeplinks (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'UUIDv5 format with <content>-<tmdbId>',
    contentRefId UUID NULL COMMENT 'Reference to Episodes.contentId',
    tmdbId VARCHAR(20) NULL,
    sourceId SMALLINT UNSIGNED NOT NULL,
    sourceType VARCHAR(64) NOT NULL,
    title VARCHAR(255) NULL COMMENT 'This is the title scraped from the scraper',
    altTitle VARCHAR(255) NULL COMMENT 'If set, this will override the scrapers title, use it to match the TMDB title',
    releaseDate DATE NULL,
    altReleaseDate DATE NULL COMMENT 'If set, this will override the scrapers release date, use it to match the TMDB title',
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
    CONSTRAINT SeriesDeeplinksContent_UK UNIQUE KEY (contentId),
    CONSTRAINT SeriesDeeplinksContentSource_UK UNIQUE KEY (contentRefId, sourceId, originSource),
    CONSTRAINT SeriesDeeplinksContentRef_FK FOREIGN KEY (contentRefId)
        REFERENCES Episodes(contentId) 
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
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT MoviesPricesContent_UK UNIQUE KEY (contentRefId, region),
    CONSTRAINT MoviesPricesDeeplinks_FK
        FOREIGN KEY (contentRefId)
        REFERENCES MoviesDeeplinks (contentId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episodes Prices table for storing TV content pricing information
CREATE TABLE SeriesPrices (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'UUIDV5 format with <content>-<deeplinkSource>-<tmdbId>',
    contentRefId UUID NULL COMMENT 'Reference to SeriesDeeplinks.contentId',
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
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT SeriesPricesContent_UK UNIQUE KEY (contentRefId, region),
    CONSTRAINT SeriesPricesDeeplinks_FK
        FOREIGN KEY (contentRefId)
        REFERENCES SeriesDeeplinks (contentId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audit Log for tracking all significant changes
CREATE TABLE AuditLog (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    contentRefId UUID NULL COMMENT 'Reference to the content being audited',
    tableName VARCHAR(64) NOT NULL,
    action ENUM('create', 'insert', 'update', 'delete', 'restore') NOT NULL,
    username VARCHAR(64) NULL COMMENT 'Username of who made the change',
    appContext ENUM('scraper', 'admin', 'api', 'system', 'manual', 'user') NOT NULL DEFAULT 'system',
    oldData JSON NULL,
    newData JSON NULL,
    CONSTRAINT PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE Users (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    username VARCHAR(64) NOT NULL,
    firstName VARCHAR(64) NOT NULL,
    lastName VARCHAR(64) NOT NULL,
    email VARCHAR(128) NOT NULL,
    password VARCHAR(128) NOT NULL,
    role VARCHAR(64) NOT NULL,
    PRIMARY KEY (id)
);

-- Indexes for AuditLog table
CREATE INDEX AuditLogEntity_IDX USING BTREE ON AuditLog (tableName);
CREATE INDEX AuditLogUser_IDX USING BTREE ON AuditLog (username);
CREATE INDEX AuditLogContext_IDX USING BTREE ON AuditLog (appContext);
CREATE INDEX AuditLogcontentRefId_IDX USING BTREE ON AuditLog (contentRefId, tableName);

-- Drop old Deeplinks table
DROP TABLE IF EXISTS Deeplinks;

-- Graveyard table for tracking failed content and links
CREATE TABLE Graveyard (
    id UUID NOT NULL COMMENT 'UUIDv7 format includes timestamp',
    contentRefId UUID NULL COMMENT 'Reference to the original content ID if available',
    reason ENUM('duplicate', 'invalid_data', 'missing_required', 'api_error', 'parsing_error', 'deleted', 'other') NOT NULL,
    contentType ENUM('Movies', 'Series', 'Seasons', 'Episodes', 'MoviesDeeplinks', 'SeriesDeeplinks', 'MoviesPrices', 'SeriesPrices') NOT NULL,
    sourceId VARCHAR(128) NULL COMMENT 'External ID from the source (e.g., TMDB ID, IMDB ID)',
    sourceType VARCHAR(64) NULL COMMENT 'Source of the content (e.g., tmdb, imdb, reelgood)',
    title VARCHAR(255) NULL COMMENT 'Original title of the content',
    altTitle VARCHAR(255) NULL COMMENT 'Alternate title of the content',
    details TEXT NULL COMMENT 'Additional details about the failure',
    rawData JSON NULL COMMENT 'Original raw data that failed to process',
    username VARCHAR(64) NULL COMMENT 'Username of who made the change' DEFAULT 'system',
    appContext ENUM('scraper', 'admin', 'api', 'system', 'manual', 'user') NOT NULL DEFAULT 'system',
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT GraveyardUnique_UK UNIQUE KEY (
        contentType,
        contentRefId
    )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Indexes for Graveyard table
CREATE INDEX GraveyardType_IDX USING BTREE ON Graveyard (contentType, sourceType);
CREATE INDEX GraveyardSource_IDX USING BTREE ON Graveyard (sourceId, sourceType);
CREATE INDEX GraveyardReason_IDX USING BTREE ON Graveyard (reason);

-- Indexes for better query performance
CREATE FULLTEXT INDEX MoviesTitle_IDX ON Movies (title);
CREATE INDEX MoviesContentId_IDX USING BTREE ON Movies (contentId);
CREATE INDEX MoviesTitleId_IDX USING BTREE ON Movies (titleId);
CREATE INDEX MoviesActive_IDX USING BTREE ON Movies (isActive);

CREATE FULLTEXT INDEX SeriesTitle_IDX ON Series (title);
CREATE INDEX SeriesContentId_IDX USING BTREE ON Series (contentId);
CREATE INDEX SeriesTitleId_IDX USING BTREE ON Series (titleId);
CREATE INDEX SeriesActive_IDX USING BTREE ON Series (isActive);

CREATE FULLTEXT INDEX SeasonsTitle_IDX ON Seasons (title);
CREATE INDEX SeasonsContentId_IDX USING BTREE ON Seasons (contentId);
CREATE INDEX SeasonsTitleId_IDX USING BTREE ON Seasons (titleId);
CREATE INDEX SeasonsShow_IDX USING BTREE ON Seasons (contentRefId, seasonNumber);
CREATE INDEX SeasonsActive_IDX USING BTREE ON Seasons (isActive);

CREATE FULLTEXT INDEX EpisodesTitle_IDX ON Episodes (title);
CREATE INDEX EpisodesContentId_IDX USING BTREE ON Episodes (contentId);
CREATE INDEX EpisodesTitleId_IDX USING BTREE ON Episodes (titleId);
CREATE INDEX EpisodesSeason_IDX USING BTREE ON Episodes (contentRefId);
CREATE INDEX EpisodesActive_IDX USING BTREE ON Episodes (isActive);

CREATE INDEX MoviesDeeplinksContent_IDX USING BTREE ON MoviesDeeplinks (contentId);
CREATE UNIQUE INDEX MoviesDeeplinksRefSource_UK ON MoviesDeeplinks (contentRefId, sourceId, originSource);
CREATE INDEX MoviesDeeplinksSource_IDX USING BTREE ON MoviesDeeplinks (sourceId, sourceType, region);

CREATE INDEX SeriesDeeplinksContent_IDX USING BTREE ON SeriesDeeplinks (contentId);
CREATE UNIQUE INDEX SeriesDeeplinksRefSource_UK ON SeriesDeeplinks (contentRefId, sourceId, originSource);
CREATE INDEX SeriesDeeplinksSource_IDX USING BTREE ON SeriesDeeplinks (sourceId, sourceType, region);


CREATE INDEX MoviesPrices_IDX_content_id ON MoviesPrices (contentId);
CREATE INDEX MoviesPrices_IDX_content_ref_id ON MoviesPrices (contentRefId);
CREATE INDEX MoviesPrices_IDX_region ON MoviesPrices (region);

CREATE INDEX SeriesPrices_IDX_content_id ON SeriesPrices (contentId);
CREATE INDEX SeriesPrices_IDX_content_ref_id ON SeriesPrices (contentRefId);
CREATE INDEX SeriesPrices_IDX_region ON SeriesPrices (region);


DELIMITER //

-- Base function for content JSON with common fields
CREATE FUNCTION GetContentDataJSON(
    jsonData JSON,
    showAllFields BOOLEAN
) RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    DECLARE keys_array JSON;
    DECLARE i INT;
    DECLARE current_key TEXT DEFAULT NULL;
    DECLARE current_value JSON;
    DECLARE jsonType TEXT;
    
    SET result = JSON_OBJECT();
    SET keys_array = JSON_KEYS(jsonData);
    SET i = 0;
    
    WHILE i < JSON_LENGTH(keys_array) DO
        SET current_key = JSON_VALUE(keys_array, CONCAT('$[', i, ']'));
        SET current_value = JSON_VALUE(jsonData, CONCAT('$.', current_key));
        SET jsonType = JSON_TYPE(JSON_EXTRACT(jsonData, CONCAT('$.', current_key)));
        
        CASE jsonType
            WHEN 'NULL' THEN
                IF showAllFields THEN
                    SET result = JSON_SET(result, CONCAT('$.', current_key), NULL);
                END IF;
            WHEN 'STRING' THEN
                SET result = JSON_SET(result, CONCAT('$.', current_key), current_value);
            WHEN 'INTEGER' THEN
                SET result = JSON_SET(result, CONCAT('$.', current_key), CAST(current_value AS DECIMAL(10,2)));
            WHEN 'BOOLEAN' THEN
                SET result = JSON_SET(result, CONCAT('$.', current_key), current_value);
            WHEN 'DECIMAL' THEN
                SET result = JSON_SET(result, CONCAT('$.', current_key), CAST(current_value AS DECIMAL(10,2)));
            WHEN 'OBJECT' THEN
                SET result = JSON_SET(result, CONCAT('$.', current_key), current_value);
            WHEN 'ARRAY' THEN
                SET result = JSON_SET(result, CONCAT('$.', current_key), current_value);
            ELSE
                SET result = JSON_SET(result, CONCAT('$.', current_key), current_value);
        END CASE;
        SET i = i + 1;
    END WHILE;
    
    RETURN result;
END //

-- Function to get display title considering altTitle
CREATE FUNCTION GetDisplayTitle(originalTitle VARCHAR(255), altTitle VARCHAR(255))
RETURNS VARCHAR(255)
DETERMINISTIC
BEGIN
    RETURN COALESCE(altTitle, originalTitle);
END //

-- Function to get only changed fields between two JSON objects
CREATE FUNCTION GetChangedFieldsJSON(
    oldJsonData JSON,
    newJsonData JSON
) RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    DECLARE keys_array JSON;
    DECLARE i INT;
    DECLARE current_key TEXT;
    DECLARE old_value, new_value TEXT;
    
    SET result = JSON_OBJECT();
    SET keys_array = JSON_KEYS(JSON_MERGE_PATCH(oldJsonData, newJsonData));
    SET i = 0;
    
    WHILE i < JSON_LENGTH(keys_array) DO
        SET current_key = JSON_VALUE(keys_array, CONCAT('$[', i, ']'));
        SET old_value = JSON_VALUE(oldJsonData, CONCAT('$.', current_key));
        SET new_value = JSON_VALUE(newJsonData, CONCAT('$.', current_key));
        
        -- Unquote the values for comparison if they're not NULL
        IF old_value IS NOT NULL THEN
            SET old_value = old_value;
        END IF;
        IF new_value IS NOT NULL THEN
            SET new_value = new_value;
        END IF;
        
        IF (old_value IS NULL AND new_value IS NOT NULL) OR 
            (old_value IS NOT NULL AND new_value IS NULL) OR 
            (old_value <> new_value) THEN
        -- Use JSON_MERGE_PATCH to combine the existing result with a new JSON_OBJECT
        SET result = JSON_MERGE_PATCH(
            result,
            JSON_OBJECT(current_key, new_value)
        );
        END IF;
        SET i = i + 1;
    END WHILE;
    
    RETURN result;
END //


-- Movies triggers
CREATE TRIGGER Movies_Insert_Audit
BEFORE INSERT ON Movies
FOR EACH ROW
BEGIN
    DECLARE display_title VARCHAR(255);
    DECLARE jsonData JSON;

    SET display_title = GetDisplayTitle(NEW.title, NEW.altTitle);

    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'title', display_title,
        'tmdbId', NEW.tmdbId,
        'imdbId', NEW.imdbId,
        'rgId', NEW.rgId,
        'description', NEW.description,
        'releaseDate', NEW.releaseDate,
        'posterPath', NEW.posterPath,
        'backdropPath', NEW.backdropPath,
        'voteAverage', NEW.voteAverage,
        'voteCount', NEW.voteCount,
        'isActive', NEW.isActive
    ), true);
    
    CALL LogAudit(
        'Movies', 
        NEW.contentId, 
        'insert',
        NULL,
        jsonData,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER Movies_Update_Audit
AFTER UPDATE ON Movies
FOR EACH ROW
BEGIN
    DECLARE old_display_title, new_display_title VARCHAR(255);
    DECLARE oldJsonData, newJsonData, changed_json JSON;
    
    SET old_display_title = GetDisplayTitle(OLD.title, OLD.altTitle);
    SET new_display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    
    SET oldJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'title', old_display_title,
        'tmdbId', OLD.tmdbId,
        'imdbId', OLD.imdbId,
        'rgId', OLD.rgId,
        'description', OLD.description,
        'releaseDate', OLD.releaseDate,
        'posterPath', OLD.posterPath,
        'backdropPath', OLD.backdropPath,
        'voteAverage', OLD.voteAverage,
        'voteCount', OLD.voteCount,
        'isActive', OLD.isActive
    ), false);
    
    SET newJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId, 
        'title', new_display_title,
        'tmdbId', NEW.tmdbId, 
        'imdbId', NEW.imdbId, 
        'rgId', NEW.rgId, 
        'description', NEW.description, 
        'releaseDate', NEW.releaseDate, 
        'posterPath', NEW.posterPath, 
        'backdropPath', NEW.backdropPath, 
        'voteAverage', NEW.voteAverage, 
        'voteCount', NEW.voteCount, 
        'isActive', NEW.isActive
    ), false);
    
    SET changed_json = GetChangedFieldsJSON(oldJsonData, newJsonData);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'Movies',
            NEW.contentId,
            'update',
            oldJsonData,
            changed_json,
            COALESCE(@username, 'system'),
            COALESCE(@appContext, 'system')
        );
    END IF;
END //

CREATE TRIGGER Movies_Delete_Audit
BEFORE DELETE ON Movies
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;
    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'tmdbId', OLD.tmdbId,
        'imdbId', OLD.imdbId,
        'rgId', OLD.rgId,
        'title', OLD.title,
        'altTitle', OLD.altTitle,
        'description', OLD.description,
        'runtime', OLD.runtime,
        'releaseDate', OLD.releaseDate,
        'posterPath', OLD.posterPath,
        'backdropPath', OLD.backdropPath,
        'popularity', OLD.popularity,
        'voteAverage', OLD.voteAverage,
        'voteCount', OLD.voteCount,
        'genres', OLD.genres,
        'keywords', OLD.keywords,
        'cast', OLD.cast,
        'crew', OLD.crew,
        'productionCompanies', OLD.productionCompanies,
        'isActive', OLD.isActive,
        'isDupe', OLD.isDupe
    ), true);
    
    CALL MoviesDeleteAudit(jsonData);
END //

-- Series triggers
CREATE TRIGGER Series_Insert_Audit
AFTER INSERT ON Series
FOR EACH ROW
BEGIN
    DECLARE display_title VARCHAR(255);
    DECLARE jsonData JSON;
    
    SET display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'title', display_title,
        'tmdbId', NEW.tmdbId,
        'imdbId', NEW.imdbId,
        'rgId', NEW.rgId,
        'description', NEW.description,
        'releaseDate', NEW.releaseDate,
        'posterPath', NEW.posterPath,
        'backdropPath', NEW.backdropPath,
        'voteAverage', NEW.voteAverage,
        'voteCount', NEW.voteCount,
        'totalSeasons', NEW.totalSeasons,
        'totalEpisodes', NEW.totalEpisodes,
        'isActive', NEW.isActive
    ), true);
    
    CALL LogAudit(
        'Series',
        NEW.contentId,
        'insert',
        NULL,
        jsonData,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER Series_Update_Audit
AFTER UPDATE ON Series
FOR EACH ROW
BEGIN
    DECLARE old_display_title, new_display_title VARCHAR(255);
    DECLARE oldJsonData, newJsonData, changed_json JSON;
    
    SET old_display_title = GetDisplayTitle(OLD.title, OLD.altTitle);
    SET new_display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    
    SET oldJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'title', old_display_title,
        'tmdbId', OLD.tmdbId,
        'imdbId', OLD.imdbId,
        'rgId', OLD.rgId,
        'description', OLD.description,
        'releaseDate', OLD.releaseDate,
        'posterPath', OLD.posterPath,
        'backdropPath', OLD.backdropPath,
        'voteAverage', OLD.voteAverage,
        'voteCount', OLD.voteCount,
        'totalSeasons', OLD.totalSeasons,
        'totalEpisodes', OLD.totalEpisodes,
        'isActive', OLD.isActive
    ), false);
    
    SET newJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId, 
        'title', new_display_title,
        'tmdbId', NEW.tmdbId, 
        'imdbId', NEW.imdbId, 
        'rgId', NEW.rgId, 
        'description', NEW.description, 
        'releaseDate', NEW.releaseDate, 
        'posterPath', NEW.posterPath, 
        'backdropPath', NEW.backdropPath, 
        'voteAverage', NEW.voteAverage, 
        'voteCount', NEW.voteCount, 
        'totalSeasons', NEW.totalSeasons,
        'totalEpisodes', NEW.totalEpisodes,
        'isActive', NEW.isActive
    ), false);
    
    SET changed_json = GetChangedFieldsJSON(oldJsonData, newJsonData);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'Series',
            NEW.contentId,
            'update',
            oldJsonData,
            changed_json,
            COALESCE(@username, 'system'),
            COALESCE(@appContext, 'system')
        );
    END IF;
END //

CREATE TRIGGER Series_Delete_Audit
BEFORE DELETE ON Series
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;
    
    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'tmdbId', OLD.tmdbId,
        'imdbId', OLD.imdbId,
        'rgId', OLD.rgId,
        'title', OLD.title,
        'altTitle', OLD.altTitle,
        'description', OLD.description,
        'releaseDate', OLD.releaseDate,
        'posterPath', OLD.posterPath,
        'backdropPath', OLD.backdropPath,
        'popularity', OLD.popularity,
        'voteAverage', OLD.voteAverage,
        'voteCount', OLD.voteCount,
        'genres', OLD.genres,
        'keywords', OLD.keywords,
        'cast', OLD.cast,
        'crew', OLD.crew,
        'productionCompanies', OLD.productionCompanies,
        'networks', OLD.networks,
        'totalSeasons', OLD.totalSeasons,
        'totalEpisodes', OLD.totalEpisodes,
        'isActive', OLD.isActive
    ), true);
    
    CALL SeriesDeleteAudit(jsonData);
END //



-- Seasons triggers
CREATE TRIGGER Seasons_Insert_Audit
AFTER INSERT ON Seasons
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;
    
    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'contentRefId', NEW.contentRefId,
        'title', NEW.title,
        'seasonNumber', NEW.seasonNumber,
        'description', NEW.description,
        'releaseDate', NEW.releaseDate,
        'posterPath', NEW.posterPath,
        'episodeCount', NEW.episodeCount,
        'isActive', NEW.isActive
    ), true);
    
    CALL LogAudit(
        'Seasons', 
        NEW.contentId, 
        'insert', 
        NULL,
        jsonData,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER Seasons_Update_Audit
AFTER UPDATE ON Seasons
FOR EACH ROW
BEGIN
    DECLARE oldJsonData, newJsonData, changed_json JSON;
    
    SET oldJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'title', OLD.title,
        'seasonNumber', OLD.seasonNumber,
        'description', OLD.description,
        'releaseDate', OLD.releaseDate,
        'posterPath', OLD.posterPath,
        'episodeCount', OLD.episodeCount,
        'isActive', OLD.isActive
    ), false);
    
    SET newJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'contentRefId', NEW.contentRefId,
        'title', NEW.title,
        'seasonNumber', NEW.seasonNumber,
        'description', NEW.description,
        'releaseDate', NEW.releaseDate,
        'posterPath', NEW.posterPath,
        'episodeCount', NEW.episodeCount,
        'isActive', NEW.isActive
    ), false);
    
    SET changed_json = GetChangedFieldsJSON(oldJsonData, newJsonData);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'Seasons', 
            NEW.contentId, 
            'update',
            oldJsonData,
            changed_json,
            COALESCE(@username, 'system'),
            COALESCE(@appContext, 'system')
        );
    END IF;
END //

CREATE TRIGGER Seasons_Delete_Audit
BEFORE DELETE ON Seasons
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;

    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', @contentId,
        'contentRefId', OLD.contentRefId,
        'title', OLD.title,
        'seasonNumber', OLD.seasonNumber,
        'description', OLD.description,
        'releaseDate', OLD.releaseDate,
        'posterPath', OLD.posterPath,
        'episodeCount', OLD.episodeCount,
        'isActive', OLD.isActive
    ), true);
    
    CALL SeasonsDeleteAudit(jsonData);
END //

-- Episodes triggers
CREATE TRIGGER Episodes_Insert_Audit
AFTER INSERT ON Episodes
FOR EACH ROW
BEGIN
    DECLARE display_title VARCHAR(255);
    DECLARE jsonData JSON;
    DECLARE v_series_id UUID;
    
    -- Get the series ID from the season
    SELECT s.contentRefId INTO v_series_id
    FROM Seasons s
    WHERE s.contentId = NEW.contentRefId;
    
    -- Update episode count in Seasons table
    UPDATE Seasons 
    SET episodeCount = episodeCount + 1
    WHERE contentId = NEW.contentRefId;
    
    -- Update episode count in Series table
    UPDATE Series
    SET totalEpisodes = totalEpisodes + 1
    WHERE contentId = v_series_id;
    
    SET display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'contentRefId', NEW.contentRefId,
        'title', display_title,
        'episodeNumber', NEW.episodeNumber,
        'description', NEW.description,
        'releaseDate', NEW.releaseDate,
        'runtime', NEW.runtime,
        'voteAverage', NEW.voteAverage,
        'voteCount', NEW.voteCount,
        'isActive', NEW.isActive
    ), false);
    
    CALL LogAudit(
        'Episodes',
        NEW.contentId,
        'insert',
        NULL,
        jsonData,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER Episodes_Update_Audit
AFTER UPDATE ON Episodes
FOR EACH ROW
BEGIN
    DECLARE old_display_title, new_display_title VARCHAR(255);
    DECLARE oldJsonData, newJsonData, changed_json JSON;
    
    SET old_display_title = GetDisplayTitle(OLD.title, OLD.altTitle);
    SET new_display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    
    SET oldJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'title', old_display_title,
        'episodeNumber', OLD.episodeNumber,
        'description', OLD.description,
        'releaseDate', OLD.releaseDate,
        'runtime', OLD.runtime,
        'voteAverage', OLD.voteAverage,
        'voteCount', OLD.voteCount,
        'isActive', OLD.isActive
    ), false);
    
    SET newJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'contentRefId', NEW.contentRefId,
        'title', new_display_title,
        'episodeNumber', NEW.episodeNumber,
        'description', NEW.description,
        'releaseDate', NEW.releaseDate,
        'runtime', NEW.runtime,
        'voteAverage', NEW.voteAverage,
        'voteCount', NEW.voteCount,
        'isActive', NEW.isActive
    ), false);
    
    SET changed_json = GetChangedFieldsJSON(oldJsonData, newJsonData);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'Episodes', 
            NEW.contentId, 
            'update',
            oldJsonData,
            changed_json,
            COALESCE(@username, 'system'),
            COALESCE(@appContext, 'system')
        );
    END IF;
END //

CREATE TRIGGER Episodes_Delete_Audit
BEFORE DELETE ON Episodes
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;
    
    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'title', OLD.title,
        'altTitle', OLD.altTitle,
        'episodeNumber', OLD.episodeNumber,
        'description', OLD.description,
        'releaseDate', OLD.releaseDate,
        'runtime', OLD.runtime,
        'voteAverage', OLD.voteAverage,
        'voteCount', OLD.voteCount,
        'isActive', OLD.isActive
    ), true);
    
    CALL EpisodesDeleteAudit(jsonData);
END //

-- Create trigger to update Series.seasonContentIds when a new season is added
CREATE TRIGGER Seasons_Series_Insert AFTER INSERT ON Seasons
FOR EACH ROW
BEGIN
    UPDATE Series 
    SET totalSeasons = totalSeasons + 1
    WHERE contentId = NEW.contentRefId;
END //

-- MoviesDeeplinks triggers
CREATE TRIGGER MoviesDeeplinks_Insert_Audit
BEFORE INSERT ON MoviesDeeplinks
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;
    DECLARE inherited_title VARCHAR(255);
    DECLARE inherited_tmdbId VARCHAR(20);
    DECLARE inherited_releaseDate DATE;
    DECLARE display_title VARCHAR(255);
    
    -- If contentRefId exists, get data from Movies table
    IF NEW.contentRefId IS NOT NULL THEN
        SELECT 
            title, 
            tmdbId,
            releaseDate
        INTO 
            inherited_title,
            inherited_tmdbId,
            inherited_releaseDate
        FROM Movies 
        WHERE contentId = NEW.contentRefId;
        
        -- Set the values before insert
        IF NEW.title IS NULL OR TRIM(NEW.title) = '' THEN
            SET NEW.title = inherited_title;
        END IF;

        IF NEW.tmdbId IS NULL OR TRIM(NEW.tmdbId) = '' THEN
            SET NEW.tmdbId = inherited_tmdbId;
        END IF;

        IF NEW.releaseDate IS NULL THEN
            SET NEW.releaseDate = inherited_releaseDate;
        END IF;
        
        SET display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    ELSE
        SET display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    END IF;
    
    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'contentRefId', NEW.contentRefId,
        'tmdbId', NEW.tmdbId,
        'title', NEW.title,
        'altTitle', NEW.altTitle,
        'releaseDate', NEW.releaseDate,
        'altReleaseDate', NEW.altReleaseDate,
        'sourceId', NEW.sourceId,
        'sourceType', NEW.sourceType,
        'originSource', NEW.originSource,
        'region', NEW.region,
        'web', NEW.web,
        'android', NEW.android,
        'iOS', NEW.iOS,
        'androidTv', NEW.androidTv,
        'fireTv', NEW.fireTv,
        'lg', NEW.lg,
        'samsung', NEW.samsung,
        'tvOS', NEW.tvOS,
        'roku', NEW.roku
    ), true);

    CALL LogAudit(
        'MoviesDeeplinks', 
        NEW.contentId, 
        'insert', 
        NULL,
        jsonData,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER MoviesDeeplinks_Update_Audit
AFTER UPDATE ON MoviesDeeplinks
FOR EACH ROW
BEGIN
    DECLARE old_display_title, new_display_title VARCHAR(255);
    DECLARE oldJsonData, newJsonData, changed_json JSON;
    DECLARE jsonData JSON;
    
    SET old_display_title = GetDisplayTitle(OLD.title, OLD.altTitle);
    SET new_display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    
    SET oldJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'title', old_display_title,
        'sourceId', OLD.sourceId,
        'sourceType', OLD.sourceType,
        'originSource', OLD.originSource,
        'region', OLD.region,
        'web', OLD.web,
        'android', OLD.android,
        'iOS', OLD.iOS,
        'androidTv', OLD.androidTv,
        'fireTv', OLD.fireTv,
        'lg', OLD.lg,
        'samsung', OLD.samsung,
        'tvOS', OLD.tvOS,
        'roku', OLD.roku,
        'isActive', OLD.isActive,
        'tmdbId', OLD.tmdbId
    ), false);
    
    SET newJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'contentRefId', NEW.contentRefId,
        'title', new_display_title,
        'sourceId', NEW.sourceId,
        'sourceType', NEW.sourceType,
        'originSource', NEW.originSource,
        'region', NEW.region,
        'web', NEW.web,
        'android', NEW.android,
        'iOS', NEW.iOS,
        'androidTv', NEW.androidTv,
        'fireTv', NEW.fireTv,
        'lg', NEW.lg,
        'samsung', NEW.samsung,
        'tvOS', NEW.tvOS,
        'roku', NEW.roku,
        'isActive', NEW.isActive,
        'tmdbId', NEW.tmdbId
    ), false);
    
    SET changed_json = GetChangedFieldsJSON(oldJsonData, newJsonData);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'MoviesDeeplinks', 
            NEW.contentId, 
            'update',
            oldJsonData,
            changed_json,
            COALESCE(@username, 'system'),
            COALESCE(@appContext, 'system')
        );
    END IF;
END //

CREATE TRIGGER MoviesDeeplinks_Delete_Audit
BEFORE DELETE ON MoviesDeeplinks
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;

    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'tmdbId', OLD.tmdbId,
        'title', OLD.title,
        'altTitle', OLD.altTitle,
        'releaseDate', OLD.releaseDate,
        'altReleaseDate', OLD.altReleaseDate,
        'sourceId', OLD.sourceId,
        'sourceType', OLD.sourceType,
        'originSource', OLD.originSource,
        'region', OLD.region,
        'web', OLD.web,
        'android', OLD.android,
        'iOS', OLD.iOS,
        'androidTv', OLD.androidTv,
        'fireTv', OLD.fireTv,
        'lg', OLD.lg,
        'samsung', OLD.samsung,
        'tvOS', OLD.tvOS,
        'roku', OLD.roku,
        'isActive', OLD.isActive
    ), true);

    CALL MoviesDeeplinksDeleteAudit(jsonData);
END //

-- SeriesDeeplinks triggers
CREATE TRIGGER SeriesDeeplinks_Insert_Audit
BEFORE INSERT ON SeriesDeeplinks
FOR EACH ROW
BEGIN
    DECLARE inherited_title VARCHAR(255);
    DECLARE inherited_tmdbId VARCHAR(20);
    DECLARE inherited_releaseDate DATE;
    DECLARE display_title VARCHAR(255);
    DECLARE jsonData JSON;

    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
            'contentRefId', NEW.contentRefId,
            'title', NEW.title,
            'sourceId', NEW.sourceId,
            'sourceType', NEW.sourceType,
            'originSource', NEW.originSource,
            'region', NEW.region,
            'web', NEW.web,
            'android', NEW.android,
            'iOS', NEW.iOS,
            'androidTv', NEW.androidTv,
            'fireTv', NEW.fireTv,
            'lg', NEW.lg,
            'samsung', NEW.samsung,
            'tvOS', NEW.tvOS,
            'roku', NEW.roku,
            'isActive', NEW.isActive,
            'tmdbId', NEW.tmdbId
    ), true);
    
    -- If contentRefId exists, get data from Episodes table
    IF NEW.contentRefId IS NOT NULL THEN
        SELECT 
            title,
            releaseDate,
            tmdbId
        INTO 
            inherited_title,
            inherited_releaseDate,
            inherited_tmdbId
        FROM Episodes 
        WHERE contentId = NEW.contentRefId;
        

        -- Set the values before insert
        IF NEW.title IS NULL OR TRIM(NEW.title) = '' THEN
            SET NEW.title = inherited_title;
        END IF;
        
        IF NEW.tmdbId IS NULL OR TRIM(NEW.tmdbId) = '' THEN
            SET NEW.tmdbId = inherited_tmdbId;
        END IF;
        
        IF NEW.releaseDate IS NULL THEN
            SET NEW.releaseDate = inherited_releaseDate;
        END IF;
        
        SET display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    ELSE
        SET display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    END IF;
    
    CALL LogAudit(
        'SeriesDeeplinks', 
        NEW.contentId, 
        'insert', 
        NULL,
        jsonData,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER SeriesDeeplinks_Update_Audit
AFTER UPDATE ON SeriesDeeplinks
FOR EACH ROW
BEGIN
    DECLARE old_display_title, new_display_title VARCHAR(255);
    DECLARE oldJsonData, newJsonData, changed_json JSON;
    
    SET old_display_title = GetDisplayTitle(OLD.title, OLD.altTitle);
    SET new_display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    
    SET oldJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'title', old_display_title,
        'sourceId', OLD.sourceId,
        'sourceType', OLD.sourceType,
        'originSource', OLD.originSource,
        'region', OLD.region,
        'web', OLD.web,
        'android', OLD.android,
        'iOS', OLD.iOS,
        'androidTv', OLD.androidTv,
        'fireTv', OLD.fireTv,
        'lg', OLD.lg,
        'samsung', OLD.samsung,
        'tvOS', OLD.tvOS,
        'roku', OLD.roku,
        'isActive', OLD.isActive,
        'tmdbId', OLD.tmdbId
    ), false);
    
    SET newJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId, 
        'contentRefId', NEW.contentRefId, 
        'title', new_display_title,
        'sourceId', NEW.sourceId, 
        'sourceType', NEW.sourceType, 
        'originSource', NEW.originSource, 
        'region', NEW.region, 
        'web', NEW.web,
        'android', NEW.android,
        'iOS', NEW.iOS,
        'androidTv', NEW.androidTv,
        'fireTv', NEW.fireTv,
        'lg', NEW.lg,
        'samsung', NEW.samsung,
        'tvOS', NEW.tvOS,
        'roku', NEW.roku,
        'isActive', NEW.isActive,
        'tmdbId', NEW.tmdbId
    ), false);
    
    SET changed_json = GetChangedFieldsJSON(oldJsonData, newJsonData);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'SeriesDeeplinks', 
            NEW.contentId, 
            'update',
            oldJsonData,
            changed_json,
            COALESCE(@username, 'system'),
            COALESCE(@appContext, 'system')
        );
    END IF;
END //

CREATE TRIGGER SeriesDeeplinks_Delete_Audit
BEFORE DELETE ON SeriesDeeplinks
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;
    
    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'tmdbId', OLD.tmdbId,
        'title', OLD.title,
        'altTitle', OLD.altTitle,
        'releaseDate', OLD.releaseDate,
        'altReleaseDate', OLD.altReleaseDate,
        'sourceId', OLD.sourceId,
        'sourceType', OLD.sourceType,
        'originSource', OLD.originSource,
        'region', OLD.region,
        'web', OLD.web,
        'android', OLD.android,
        'iOS', OLD.iOS,
        'androidTv', OLD.androidTv,
        'fireTv', OLD.fireTv,
        'lg', OLD.lg,
        'samsung', OLD.samsung,
        'tvOS', OLD.tvOS,
        'roku', OLD.roku,
        'isActive', OLD.isActive
    ), true);

    CALL SeriesDeeplinksDeleteAudit(jsonData);
END //

-- MoviesPrices triggers with correct number of arguments
CREATE TRIGGER MoviesPrices_Insert_Audit
BEFORE INSERT ON MoviesPrices
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;

    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'contentRefId', NEW.contentRefId,
        'region', NEW.region,
        'buySD', NEW.buySD,
        'buyHD', NEW.buyHD,
        'buyUHD', NEW.buyUHD,
        'rentSD', NEW.rentSD,
        'rentHD', NEW.rentHD,
        'rentUHD', NEW.rentUHD,
        'isActive', NEW.isActive
    ), true);

    CALL LogAudit(
        'MoviesPrices', 
        NEW.contentId, 
        'insert',
        NULL,
        jsonData,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER MoviesPrices_Update_Audit
AFTER UPDATE ON MoviesPrices
FOR EACH ROW
BEGIN
    DECLARE oldJsonData, newJsonData, changed_json JSON;
    
    SET oldJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'region', OLD.region,
        'buySD', OLD.buySD,
        'buyHD', OLD.buyHD,
        'buyUHD', OLD.buyUHD,
        'rentSD', OLD.rentSD,
        'rentHD', OLD.rentHD,
        'rentUHD', OLD.rentUHD,
        'isActive', OLD.isActive
    ), false);
    
    SET newJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'contentRefId', NEW.contentRefId,
        'region', NEW.region,
        'buySD', NEW.buySD,
        'buyHD', NEW.buyHD,
        'buyUHD', NEW.buyUHD,
        'rentSD', NEW.rentSD,
        'rentHD', NEW.rentHD,
        'rentUHD', NEW.rentUHD,
        'isActive', NEW.isActive
    ), false);
    
    SET changed_json = GetChangedFieldsJSON(oldJsonData, newJsonData);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'MoviesPrices', 
            NEW.contentId, 
            'update',
            oldJsonData,
            changed_json,
            COALESCE(@username, 'system'),
            COALESCE(@appContext, 'system')
        );
    END IF;
END //

CREATE TRIGGER MoviesPrices_Delete_Audit
BEFORE DELETE ON MoviesPrices
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;

    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'region', OLD.region,
        'buySD', OLD.buySD,
        'buyHD', OLD.buyHD,
        'buyUHD', OLD.buyUHD,
        'rentSD', OLD.rentSD,
        'rentHD', OLD.rentHD,
        'rentUHD', OLD.rentUHD,
        'isActive', OLD.isActive
    ), true);

    CALL MoviesPricesDeleteAudit(jsonData);
END //

-- SeriesPrices triggers
CREATE TRIGGER SeriesPrices_Insert_Audit
BEFORE INSERT ON SeriesPrices
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;

    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'contentRefId', NEW.contentRefId,
        'region', NEW.region,
        'buySD', NEW.buySD,
        'buyHD', NEW.buyHD,
        'buyUHD', NEW.buyUHD,
        'rentSD', NEW.rentSD,
        'rentHD', NEW.rentHD,
        'rentUHD', NEW.rentUHD,
        'seriesBuySD', NEW.seriesBuySD,
        'seriesBuyHD', NEW.seriesBuyHD,
        'seriesBuyUHD', NEW.seriesBuyUHD,
        'seriesRentSD', NEW.seriesRentSD,
        'seriesRentHD', NEW.seriesRentHD,
        'seriesRentUHD', NEW.seriesRentUHD,
        'seasonBuySD', NEW.seasonBuySD,
        'seasonBuyHD', NEW.seasonBuyHD,
        'seasonBuyUHD', NEW.seasonBuyUHD,
        'seasonRentSD', NEW.seasonRentSD,
        'seasonRentHD', NEW.seasonRentHD,
        'seasonRentUHD', NEW.seasonRentUHD,
        'isActive', NEW.isActive
    ), true);

    CALL LogAudit(
        'SeriesPrices', 
        NEW.contentId, 
        'insert',
        NULL,
        jsonData,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER SeriesPrices_Update_Audit
AFTER UPDATE ON SeriesPrices
FOR EACH ROW
BEGIN
    DECLARE oldJsonData, newJsonData, changed_json JSON;
    SET oldJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'region', OLD.region,
        'buySD', OLD.buySD,
        'buyHD', OLD.buyHD,
        'buyUHD', OLD.buyUHD,
        'rentSD', OLD.rentSD,
        'rentHD', OLD.rentHD,
        'rentUHD', OLD.rentUHD,
        'seriesBuySD', OLD.seriesBuySD,
        'seriesBuyHD', OLD.seriesBuyHD,
        'seriesBuyUHD', OLD.seriesBuyUHD,
        'seriesRentSD', OLD.seriesRentSD,
        'seriesRentHD', OLD.seriesRentHD,
        'seriesRentUHD', OLD.seriesRentUHD,
        'seasonBuySD', OLD.seasonBuySD,
        'seasonBuyHD', OLD.seasonBuyHD,
        'seasonBuyUHD', OLD.seasonBuyUHD,
        'seasonRentSD', OLD.seasonRentSD,
        'seasonRentHD', OLD.seasonRentHD,
        'seasonRentUHD', OLD.seasonRentUHD,
        'isActive', OLD.isActive
    ), true);

    SET newJsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', NEW.contentId,
        'contentRefId', NEW.contentRefId,
        'region', NEW.region,
        'buySD', NEW.buySD,
        'buyHD', NEW.buyHD,
        'buyUHD', NEW.buyUHD,
        'rentSD', NEW.rentSD,
        'rentHD', NEW.rentHD,
        'rentUHD', NEW.rentUHD,
        'seriesBuySD', NEW.seriesBuySD,
        'seriesBuyHD', NEW.seriesBuyHD,
        'seriesBuyUHD', NEW.seriesBuyUHD,
        'seriesRentSD', NEW.seriesRentSD,
        'seriesRentHD', NEW.seriesRentHD,
        'seriesRentUHD', NEW.seriesRentUHD,
        'seasonBuySD', NEW.seasonBuySD,
        'seasonBuyHD', NEW.seasonBuyHD,
        'seasonBuyUHD', NEW.seasonBuyUHD,
        'seasonRentSD', NEW.seasonRentSD,
        'seasonRentHD', NEW.seasonRentHD,
        'seasonRentUHD', NEW.seasonRentUHD,
        'isActive', NEW.isActive
    ), true);        

    SET changed_json = GetChangedFieldsJSON(oldJsonData, newJsonData);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'SeriesPrices', 
            NEW.contentId, 
            'update',
            oldJsonData,
            changed_json,
            COALESCE(@username, 'system'),
            COALESCE(@appContext, 'system')
        );
    END IF;
END //

CREATE TRIGGER SeriesPrices_Delete_Audit
BEFORE DELETE ON SeriesPrices
FOR EACH ROW
BEGIN
    DECLARE jsonData JSON;
    SET jsonData = GetContentDataJSON(JSON_OBJECT(
        'contentId', OLD.contentId,
        'contentRefId', OLD.contentRefId,
        'region', OLD.region,
        'buySD', OLD.buySD,
        'buyHD', OLD.buyHD,
        'buyUHD', OLD.buyUHD,
        'rentSD', OLD.rentSD,
        'rentHD', OLD.rentHD,
        'rentUHD', OLD.rentUHD,
        'seriesBuySD', OLD.seriesBuySD,
        'seriesBuyHD', OLD.seriesBuyHD,
        'seriesBuyUHD', OLD.seriesBuyUHD,
        'seriesRentSD', OLD.seriesRentSD,
        'seriesRentHD', OLD.seriesRentHD,
        'seriesRentUHD', OLD.seriesRentUHD,
        'seasonBuySD', OLD.seasonBuySD,
        'seasonBuyHD', OLD.seasonBuyHD,
        'seasonBuyUHD', OLD.seasonBuyUHD,
        'seasonRentSD', OLD.seasonRentSD,
        'seasonRentHD', OLD.seasonRentHD,
        'seasonRentUHD', OLD.seasonRentUHD,
        'isActive', OLD.isActive
    ), true);

    CALL SeriesPricesDeleteAudit(jsonData);
END //


CALL DropAllProcedures(); //
DROP PROCEDURE IF EXISTS DropAllProcedures; //


-- Audit helper procedures and functions
-- Central audit logging procedure
CREATE PROCEDURE LogAudit(
    IN tableName VARCHAR(64),
    IN contentRefId UUID,
    IN actionType ENUM('insert', 'update', 'delete', 'restore'),
    IN oldData JSON,
    IN newData JSON,
    IN username VARCHAR(64),
    IN context ENUM('scraper', 'admin', 'api', 'system', 'manual', 'user')
)
BEGIN
    INSERT INTO AuditLog (
        id,
        contentRefId,
        tableName,
        action,
        username,
        appContext,
        oldData,
        newData
    ) VALUES (
        UUID_v7(),
        contentRefId,
        tableName,
        actionType,
        IFNULL(username, 'system'),
        IFNULL(context, 'system'),
        oldData,
        newData
    );
END //

CREATE PROCEDURE CreateGraveyardItem(
    dataContentType ENUM('Movies', 'Series', 'Seasons', 'Episodes', 'MoviesDeeplinks', 'SeriesDeeplinks', 'MoviesPrices', 'SeriesPrices'),
    dataSourceType TEXT,
    dataReason ENUM('duplicate', 'invalid_data', 'missing_required', 'api_error', 'parsing_error', 'deleted', 'other'),
    dataDetails TEXT,
    jsonData JSON
)
BEGIN
    DECLARE thisDataContent ENUM('Movies', 'Series', 'Seasons', 'Episodes');
    DECLARE contentIdType UUID;

    CASE dataContentType
        WHEN dataContentType = 'Movies' THEN 
            SET contentIdType = JSON_VALUE(jsonData, '$.contentId');
        WHEN dataContentType = 'Series' THEN 
            SET contentIdType = JSON_VALUE(jsonData, '$.contentId');
        ELSE 
            SET contentIdType = JSON_VALUE(jsonData, '$.contentRefId');
    END CASE;
    
    INSERT INTO Graveyard (
        id,
        contentRefId,
        reason,
        contentType,
        sourceId,
        sourceType,
        title,
        altTitle,
        details,
        rawData,
        username,
        appContext
    ) VALUES (
        UUID_v7(),
        contentIdType,
        dataReason,
        dataContentType,
        JSON_VALUE(jsonData, '$.tmdbId'),
        dataSourceType,
        JSON_VALUE(jsonData, '$.title'),
        JSON_VALUE(jsonData, '$.altTitle'),
        dataDetails,
        jsonData,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

-- Movies delete audit procedure
CREATE PROCEDURE MoviesDeleteAudit(
    IN jsonData JSON
)
BEGIN
    -- Delete all related
    DELETE FROM MoviesDeeplinks WHERE contentRefId = JSON_VALUE(jsonData, '$.contentId');

    CALL CreateGraveyardItem(
        'Movies',
        'tmdb',
        'deleted',
        'Deleted by user',
        jsonData
    );

    -- Log audit
    CALL LogAudit(
        'Movies',
        JSON_VALUE(jsonData, '$.contentId'),
        'delete',
        jsonData,
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE SeriesDeleteAudit(
    IN jsonData JSON
)
BEGIN
    -- Delete all related
    DELETE FROM Seasons WHERE contentRefId = JSON_VALUE(jsonData, '$.contentId');

    CALL CreateGraveyardItem(
        'Series',
        'tmdb',
        'deleted',
        'Deleted by user',
        jsonData
    );

    -- Log audit
    CALL LogAudit(
        'Series',
        JSON_VALUE(jsonData, '$.contentId'),
        'delete',
        jsonData,
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE SeasonsDeleteAudit(
    IN jsonData JSON
)
BEGIN
    DECLARE vContentRefId UUID;
    SET vContentRefId = JSON_VALUE(jsonData, '$.contentRefId');
    
    DELETE FROM Episodes WHERE contentRefId = vContentRefId;
    -- First get the series ID if it exists
    -- SELECT contentId INTO v_series_id
    -- FROM Series
    -- WHERE contentId = JSON_EXTRACT(jsonData, '$.contentRefId')
    -- LIMIT 1;
    
    -- Delete all related Episodes

    -- Update parent Series if it exists
    -- IF v_series_id IS NOT NULL THEN
    --     UPDATE Series 
    --     SET totalSeasons = GREATEST(0, totalSeasons - 1)
    --     WHERE contentId = v_series_id;
    -- END IF;
    
    CALL CreateGraveyardItem(
        'Seasons',
        'tmdb',
        'deleted',
        'Deleted by user',
        jsonData
    );
    
    -- Log audit
    CALL LogAudit(
        'Seasons',
        JSON_VALUE(jsonData, '$.contentId'),
        'delete',
        jsonData,
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE EpisodesDeleteAudit(
    IN jsonData JSON
)
BEGIN
    DECLARE v_series_id UUID;
    DECLARE v_season_id UUID;
    DECLARE v_episode_count INT;
    DECLARE vContentRefId UUID;
    SET vContentRefId = JSON_VALUE(jsonData, '$.contentRefId');
    
    DELETE FROM SeriesDeeplinks WHERE contentRefId = vContentRefId;
    
    -- First get the series ID if it exists
    SELECT contentId INTO v_series_id
    FROM Series
    WHERE contentId = vContentRefId
    LIMIT 1;
    
    -- First get the season ID if it exists
    SELECT contentId INTO v_season_id
    FROM Seasons
    WHERE contentId = vContentRefId
    LIMIT 1;
    
    -- Update parent Series if it exists
    IF v_series_id IS NOT NULL THEN
        UPDATE Series 
        SET totalEpisodes = GREATEST(0, totalEpisodes - 1)
        WHERE contentId = v_series_id;
    END IF;
    
    -- Update parent Season if it exists
    IF v_season_id IS NOT NULL THEN
        SELECT totalEpisodes INTO v_episode_count
        FROM Seasons
        WHERE contentId = v_season_id
        LIMIT 1;
        
        UPDATE Seasons 
        SET totalEpisodes = GREATEST(0, totalEpisodes - 1)
        WHERE contentId = v_season_id;
    END IF;
    
    CALL CreateGraveyardItem(
        'Episodes',
        'tmdb',
        'deleted',
        'Deleted by user',
        jsonData
    );
    
    -- Log audit
    CALL LogAudit(
        'Episodes',
        JSON_VALUE(jsonData, '$.contentId'),
        'delete',
        jsonData,
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE MoviesDeeplinksDeleteAudit(
    IN jsonData JSON
)
BEGIN
    -- Delete all related
    DELETE FROM MoviesPrices WHERE contentRefId = JSON_VALUE(jsonData, '$.contentId');

    CALL CreateGraveyardItem(
        'MoviesDeeplinks',
        'tmdb',
        'deleted',
        'Deleted by user',
        jsonData
    );

    -- Log audit
    CALL LogAudit(
        'MoviesDeeplinks',
        JSON_VALUE(jsonData, '$.contentId'),
        'delete',
        jsonData,
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE SeriesDeeplinksDeleteAudit(
    IN jsonData JSON
)
BEGIN
    -- Delete all related
    DELETE FROM SeriesPrices WHERE contentRefId = JSON_VALUE(jsonData, '$.contentId');

    CALL CreateGraveyardItem(
        'SeriesDeeplinks',
        'tmdb',
        'deleted',
        'Deleted by user',
        jsonData
    );

    -- Log audit
    CALL LogAudit(
        'SeriesDeeplinks',
        JSON_VALUE(jsonData, '$.contentId'),
        'delete',
        jsonData,
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE MoviesPricesDeleteAudit(
    IN jsonData JSON
)
BEGIN
    CALL CreateGraveyardItem(
        'MoviesPrices',
        'tmdb',
        'deleted',
        'Deleted by user',
        jsonData
    );

    -- Log audit
    CALL LogAudit(
        'MoviesPrices',
        JSON_VALUE(jsonData, '$.contentId'),
        'delete',
        jsonData,
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE SeriesPricesDeleteAudit(
    IN jsonData JSON
)
BEGIN
    CALL CreateGraveyardItem(
        'SeriesPrices',
        'tmdb',
        'deleted',
        'Deleted by user',
        jsonData
    );

    -- Log audit
    CALL LogAudit(
        'SeriesPrices',
        JSON_VALUE(jsonData, '$.contentId'),
        'delete',
        jsonData,
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

DELIMITER ;
