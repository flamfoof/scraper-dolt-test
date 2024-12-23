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
    details TEXT NULL COMMENT 'Additional details about the failure',
    rawData JSON NULL COMMENT 'Original raw data that failed to process',
    username VARCHAR(64) NULL COMMENT 'Username of who made the change',
    appContext ENUM('scraper', 'admin', 'api', 'system', 'manual', 'user') NOT NULL DEFAULT 'system',
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT GraveyardUnique_UK UNIQUE KEY (
        contentType,
        reason,
        contentRefId,
        sourceId,
        sourceType
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
CREATE FUNCTION GetContentJSON(
    p_contentId UUID,
    p_title VARCHAR(255),
    p_tmdbId VARCHAR(20),
    p_imdbId VARCHAR(20),
    p_rgId VARCHAR(128),
    p_description TEXT,
    p_releaseDate DATE,
    p_posterPath VARCHAR(255),
    p_backdropPath VARCHAR(255),
    p_voteAverage DECIMAL(3,1),
    p_voteCount INT UNSIGNED,
    p_isActive BOOLEAN
) RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    SET result = JSON_OBJECT();
    
    -- Always include non-nullable fields
    SET result = JSON_SET(result,
        '$.contentId', p_contentId,
        '$.title', p_title,
        '$.isActive', COALESCE(p_isActive, true)
    );
    
    -- Add optional fields only if they are not null
    IF p_tmdbId IS NOT NULL THEN
        SET result = JSON_SET(result, '$.tmdbId', p_tmdbId);
    END IF;

    IF p_imdbId IS NOT NULL THEN
        SET result = JSON_SET(result, '$.imdbId', p_imdbId);
    END IF;

    IF p_rgId IS NOT NULL THEN
        SET result = JSON_SET(result, '$.rgId', p_rgId);
    END IF;

    IF p_description IS NOT NULL THEN
        SET result = JSON_SET(result, '$.description', p_description);
    END IF;

    IF p_releaseDate IS NOT NULL THEN
        SET result = JSON_SET(result, '$.releaseDate', p_releaseDate);
    END IF;

    IF p_posterPath IS NOT NULL THEN
        SET result = JSON_SET(result, '$.posterPath', p_posterPath);
    END IF;

    IF p_backdropPath IS NOT NULL THEN
        SET result = JSON_SET(result, '$.backdropPath', p_backdropPath);
    END IF;

    IF p_voteAverage IS NOT NULL THEN
        SET result = JSON_SET(result, '$.voteAverage', p_voteAverage);
    END IF;

    IF p_voteCount IS NOT NULL THEN
        SET result = JSON_SET(result, '$.voteCount', p_voteCount);
    END IF;
    
    RETURN result;
END //

CREATE FUNCTION GetContentDataJSON(
    p_jsonData JSON,
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
    SET keys_array = JSON_KEYS(p_jsonData);
    SET i = 0;
    
    WHILE i < JSON_LENGTH(keys_array) DO
        SET current_key = JSON_UNQUOTE(JSON_EXTRACT(keys_array, CONCAT('$[', i, ']')));
        SET current_value = JSON_UNQUOTE(JSON_EXTRACT(p_jsonData, CONCAT('$.', current_key)));
        SET jsonType = JSON_TYPE(JSON_EXTRACT(p_jsonData, CONCAT('$.', current_key)));
        
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

-- Helper functions for metadata JSON
CREATE FUNCTION GetMetadataJSON(
    contentId UUID,
    title VARCHAR(255),
    tmdbId VARCHAR(20),
    releaseDate DATE,
    description TEXT,
    popularity DECIMAL(10,2),
    voteAverage DECIMAL(3,1),
    voteCount INT UNSIGNED,
    genres JSON,
    keywords JSON,
    cast JSON,
    crew JSON
) RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    SET result = JSON_OBJECT();
    
    -- Always include non-nullable fields
    SET result = JSON_SET(result,
        '$.contentId', contentId,
        '$.title', title
    );
    
    -- Add optional fields only if they are not null
    IF tmdbId IS NOT NULL THEN
        SET result = JSON_SET(result, '$.tmdbId', tmdbId);
    END IF;

    IF releaseDate IS NOT NULL THEN
        SET result = JSON_SET(result, '$.releaseDate', releaseDate);
    END IF;

    IF description IS NOT NULL THEN
        SET result = JSON_SET(result, '$.description', description);
    END IF;

    IF popularity IS NOT NULL THEN
        SET result = JSON_SET(result, '$.popularity', popularity);
    END IF;

    IF voteAverage IS NOT NULL THEN
        SET result = JSON_SET(result, '$.voteAverage', voteAverage);
    END IF;

    IF voteCount IS NOT NULL THEN
        SET result = JSON_SET(result, '$.voteCount', voteCount);
    END IF;

    IF genres IS NOT NULL THEN
        SET result = JSON_SET(result, '$.genres', genres);
    END IF;

    IF keywords IS NOT NULL THEN
        SET result = JSON_SET(result, '$.keywords', keywords);
    END IF;

    IF cast IS NOT NULL THEN
        SET result = JSON_SET(result, '$.cast', cast);
    END IF;

    IF crew IS NOT NULL THEN
        SET result = JSON_SET(result, '$.crew', crew);
    END IF;
    
    RETURN result;
END //

-- Helper function for episode metadata JSON
CREATE FUNCTION GetEpisodeMetadataJSON(
    contentId UUID,
    title VARCHAR(255),
    tmdbId VARCHAR(20),
    releaseDate DATE,
    description TEXT,
    popularity DECIMAL(10,2),
    voteAverage DECIMAL(3,1),
    voteCount INT UNSIGNED,
    episodeNumber INT UNSIGNED,
    seasonNumber INT UNSIGNED,
    cast JSON,
    crew JSON
) RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    SET result = JSON_OBJECT();
    
    -- Always include non-nullable fields
    SET result = JSON_SET(result,
        '$.contentId', contentId,
        '$.title', title,
        '$.episodeNumber', episodeNumber,
        '$.seasonNumber', seasonNumber
    );
    
    -- Add optional fields only if they are not null
    IF tmdbId IS NOT NULL THEN
        SET result = JSON_SET(result, '$.tmdbId', tmdbId);
    END IF;

    IF releaseDate IS NOT NULL THEN
        SET result = JSON_SET(result, '$.releaseDate', releaseDate);
    END IF;

    IF description IS NOT NULL THEN
        SET result = JSON_SET(result, '$.description', description);
    END IF;

    IF popularity IS NOT NULL THEN
        SET result = JSON_SET(result, '$.popularity', popularity);
    END IF;

    IF voteAverage IS NOT NULL THEN
        SET result = JSON_SET(result, '$.voteAverage', voteAverage);
    END IF;

    IF voteCount IS NOT NULL THEN
        SET result = JSON_SET(result, '$.voteCount', voteCount);
    END IF;

    IF cast IS NOT NULL THEN
        SET result = JSON_SET(result, '$.cast', cast);
    END IF;

    IF crew IS NOT NULL THEN
        SET result = JSON_SET(result, '$.crew', crew);
    END IF;
    
    RETURN result;
END //

-- Function for Deeplinks JSON (both Movies and Episodes)
CREATE FUNCTION GetDeeplinkJSON(
    p_contentId UUID,
    p_contentRefId UUID,
    p_title VARCHAR(255),
    p_sourceId SMALLINT UNSIGNED,
    p_sourceType VARCHAR(64),
    p_originSource VARCHAR(64),
    p_region VARCHAR(10),
    p_web VARCHAR(512),
    p_android VARCHAR(512),
    p_iOS VARCHAR(512),
    p_androidTv VARCHAR(512),
    p_fireTv VARCHAR(512),
    p_lg VARCHAR(512),
    p_samsung VARCHAR(512),
    p_tvOS VARCHAR(512),
    p_roku VARCHAR(512),
    p_isActive BOOLEAN,
    p_tmdbId VARCHAR(20)
)
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    SET result = JSON_OBJECT(
        'contentId', p_contentId,
        'contentRefId', p_contentRefId,
        'title', p_title,
        'sourceId', p_sourceId,
        'sourceType', p_sourceType,
        'originSource', p_originSource,
        'region', p_region,
        'web', p_web,
        'android', p_android,
        'iOS', p_iOS,
        'androidTv', p_androidTv,
        'fireTv', p_fireTv,
        'lg', p_lg,
        'samsung', p_samsung,
        'tvOS', p_tvOS,
        'roku', p_roku,
        'isActive', p_isActive,
        'tmdbId', p_tmdbId
    );
    RETURN result;
END //

-- Function for Prices JSON (both Movies and Episodes)
CREATE FUNCTION GetPriceJSON(
    p_contentId UUID,
    p_contentRefId UUID,
    p_region VARCHAR(10),
    p_buySD DECIMAL(10,2),
    p_buyHD DECIMAL(10,2),
    p_buyUHD DECIMAL(10,2),
    p_rentSD DECIMAL(10,2),
    p_rentHD DECIMAL(10,2),
    p_rentUHD DECIMAL(10,2),
    p_seriesBuySD DECIMAL(10,2),
    p_seriesBuyHD DECIMAL(10,2),
    p_seriesBuyUHD DECIMAL(10,2),
    p_seriesRentSD DECIMAL(10,2),
    p_seriesRentHD DECIMAL(10,2),
    p_seriesRentUHD DECIMAL(10,2),
    p_seasonBuySD DECIMAL(10,2),
    p_seasonBuyHD DECIMAL(10,2),
    p_seasonBuyUHD DECIMAL(10,2),
    p_seasonRentSD DECIMAL(10,2),
    p_seasonRentHD DECIMAL(10,2),
    p_seasonRentUHD DECIMAL(10,2),
    p_isActive BOOLEAN
)
RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    SET result = JSON_OBJECT(
        'contentId', p_contentId,
        'contentRefId', p_contentRefId,
        'region', p_region,
        'buySD', p_buySD,
        'buyHD', p_buyHD,
        'buyUHD', p_buyUHD,
        'rentSD', p_rentSD,
        'rentHD', p_rentHD,
        'rentUHD', p_rentUHD,
        'seriesBuySD', p_seriesBuySD,
        'seriesBuyHD', p_seriesBuyHD,
        'seriesBuyUHD', p_seriesBuyUHD,
        'seriesRentSD', p_seriesRentSD,
        'seriesRentHD', p_seriesRentHD,
        'seriesRentUHD', p_seriesRentUHD,
        'seasonBuySD', p_seasonBuySD,
        'seasonBuyHD', p_seasonBuyHD,
        'seasonBuyUHD', p_seasonBuyUHD,
        'seasonRentSD', p_seasonRentSD,
        'seasonRentHD', p_seasonRentHD,
        'seasonRentUHD', p_seasonRentUHD,
        'isActive', p_isActive
    );
    RETURN result;
END //

-- Function for Seasons JSON
CREATE FUNCTION GetSeasonJSON(
    p_contentId UUID,
    p_contentRefId UUID,
    p_title VARCHAR(255),
    p_description TEXT,
    p_seasonNumber SMALLINT UNSIGNED,
    p_episodeCount SMALLINT UNSIGNED,
    p_releaseDate DATE,
    p_posterPath VARCHAR(255),
    p_voteAverage DECIMAL(3,1),
    p_voteCount INT UNSIGNED,
    p_isActive BOOLEAN
) RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    SET result = JSON_OBJECT();
    
    -- Always include non-nullable fields
    SET result = JSON_SET(result,
        '$.contentId', p_contentId,
        '$.contentRefId', p_contentRefId,
        '$.seasonNumber', p_seasonNumber,
        '$.isActive', COALESCE(p_isActive, true)
    );
    
    -- Add optional fields only if they are not null
    IF p_title IS NOT NULL THEN
        SET result = JSON_SET(result, '$.title', p_title);
    END IF;

    IF p_description IS NOT NULL THEN
        SET result = JSON_SET(result, '$.description', p_description);
    END IF;

    IF p_episodeCount IS NOT NULL THEN
        SET result = JSON_SET(result, '$.episodeCount', p_episodeCount);
    END IF;

    IF p_releaseDate IS NOT NULL THEN
        SET result = JSON_SET(result, '$.releaseDate', p_releaseDate);
    END IF;

    IF p_posterPath IS NOT NULL THEN
        SET result = JSON_SET(result, '$.posterPath', p_posterPath);
    END IF;

    IF p_voteAverage IS NOT NULL THEN
        SET result = JSON_SET(result, '$.voteAverage', p_voteAverage);
    END IF;

    IF p_voteCount IS NOT NULL THEN
        SET result = JSON_SET(result, '$.voteCount', p_voteCount);
    END IF;
    
    RETURN result;
END //

-- Function for Episodes JSON
CREATE FUNCTION GetEpisodeJSON(
    p_contentId UUID,
    p_contentRefId UUID,
    p_tmdbId VARCHAR(20),
    p_imdbId VARCHAR(20),
    p_rgId VARCHAR(128),
    p_title VARCHAR(255),
    p_altTitle VARCHAR(255),
    p_description TEXT,
    p_episodeNumber SMALLINT,
    p_runtime SMALLINT UNSIGNED,
    p_releaseDate DATE,
    p_voteAverage DECIMAL(3,1),
    p_voteCount INT UNSIGNED,
    p_posterPath VARCHAR(255),
    p_backdropPath VARCHAR(255),
    p_isActive BOOLEAN
) RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    SET result = JSON_OBJECT();
    
    -- Always include non-nullable fields
    SET result = JSON_SET(result,
        '$.contentId', p_contentId,
        '$.contentRefId', p_contentRefId,
        '$.title', p_title,
        '$.episodeNumber', p_episodeNumber,
        '$.isActive', COALESCE(p_isActive, true)
    );
    
    -- Add optional fields only if they are not null
    IF p_tmdbId IS NOT NULL THEN
        SET result = JSON_SET(result, '$.tmdbId', p_tmdbId);
    END IF;

    IF p_imdbId IS NOT NULL THEN
        SET result = JSON_SET(result, '$.imdbId', p_imdbId);
    END IF;

    IF p_rgId IS NOT NULL THEN
        SET result = JSON_SET(result, '$.rgId', p_rgId);
    END IF;

    IF p_altTitle IS NOT NULL THEN
        SET result = JSON_SET(result, '$.altTitle', p_altTitle);
    END IF;

    IF p_description IS NOT NULL THEN
        SET result = JSON_SET(result, '$.description', p_description);
    END IF;

    IF p_runtime IS NOT NULL THEN
        SET result = JSON_SET(result, '$.runtime', p_runtime);
    END IF;

    IF p_releaseDate IS NOT NULL THEN
        SET result = JSON_SET(result, '$.releaseDate', p_releaseDate);
    END IF;

    IF p_voteAverage IS NOT NULL THEN
        SET result = JSON_SET(result, '$.voteAverage', p_voteAverage);
    END IF;

    IF p_voteCount IS NOT NULL THEN
        SET result = JSON_SET(result, '$.voteCount', p_voteCount);
    END IF;

    IF p_posterPath IS NOT NULL THEN
        SET result = JSON_SET(result, '$.posterPath', p_posterPath);
    END IF;

    IF p_backdropPath IS NOT NULL THEN
        SET result = JSON_SET(result, '$.backdropPath', p_backdropPath);
    END IF;
    
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
    old_json JSON,
    new_json JSON
) RETURNS JSON
DETERMINISTIC
BEGIN
    DECLARE result JSON;
    DECLARE keys_array JSON;
    DECLARE i INT;
    DECLARE current_key TEXT;
    DECLARE old_value, new_value TEXT;
    
    SET result = JSON_OBJECT();
    SET keys_array = JSON_KEYS(JSON_MERGE_PATCH(old_json, new_json));
    SET i = 0;
    
    WHILE i < JSON_LENGTH(keys_array) DO
        SET current_key = JSON_UNQUOTE(JSON_EXTRACT(keys_array, CONCAT('$[', i, ']')));
            SET old_value = JSON_EXTRACT(old_json, CONCAT('$.', current_key));
            SET new_value = JSON_EXTRACT(new_json, CONCAT('$.', current_key));
            
            -- Unquote the values for comparison if they're not NULL
            IF old_value IS NOT NULL THEN
                SET old_value = JSON_UNQUOTE(old_value);
            END IF;
            IF new_value IS NOT NULL THEN
                SET new_value = JSON_UNQUOTE(new_value);
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

    SET jsonData = JSON_OBJECT(
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
    );
    
    CALL LogAudit(
        'Movies', 
        NEW.contentId, 
        'insert',
        NULL,
        GetContentDataJSON(jsonData, true),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER Movies_Update_Audit
AFTER UPDATE ON Movies
FOR EACH ROW
BEGIN
    DECLARE old_display_title, new_display_title VARCHAR(255);
    DECLARE old_json, new_json, changed_json JSON;
    
    SET old_display_title = GetDisplayTitle(OLD.title, OLD.altTitle);
    SET new_display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    
    SET old_json = GetContentDataJSON(JSON_OBJECT(
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
    
    SET new_json = GetContentDataJSON(JSON_OBJECT(
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
    
    SET changed_json = GetChangedFieldsJSON(old_json, new_json);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'Movies',
            NEW.contentId,
            'update',
            old_json,
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
    SET jsonData = JSON_OBJECT(
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
    );

    CALL MoviesDeleteAudit(
       jsonData,
       @graveyard_id
    );
END //

-- Series triggers
CREATE TRIGGER Series_Insert_Audit
BEFORE INSERT ON Series
FOR EACH ROW
BEGIN
    DECLARE display_title VARCHAR(255);
    SET display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    
    CALL LogAudit(
        'Series',
        NEW.contentId,
        'insert',
        NULL,
        GetContentJSON(
            NEW.contentId, 
            display_title,
            NEW.tmdbId, 
            NEW.imdbId, 
            NEW.rgId, 
            NEW.description, 
            NEW.releaseDate, 
            NEW.posterPath, 
            NEW.backdropPath, 
            NEW.voteAverage, 
            NEW.voteCount, 
            NEW.isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER Series_Update_Audit
AFTER UPDATE ON Series
FOR EACH ROW
BEGIN
    DECLARE old_display_title, new_display_title VARCHAR(255);
    DECLARE old_json, new_json, changed_json JSON;
    
    SET old_display_title = GetDisplayTitle(OLD.title, OLD.altTitle);
    SET new_display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    
    SET old_json = GetContentDataJSON(JSON_OBJECT(
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
    
    SET new_json = GetContentDataJSON(JSON_OBJECT(
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
    
    SET changed_json = GetChangedFieldsJSON(old_json, new_json);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'Series',
            NEW.contentId,
            'update',
            old_json,
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
    DECLARE v_graveyard_id UUID;
    CALL SeriesDeleteAudit(
        OLD.contentId,
        OLD.title,
        OLD.altTitle,
        OLD.tmdbId,
        OLD.imdbId,
        OLD.rgId,
        OLD.description,
        OLD.releaseDate,
        OLD.posterPath,
        OLD.backdropPath,
        OLD.popularity,
        OLD.voteAverage,
        OLD.voteCount,
        OLD.genres,
        OLD.keywords,
        OLD.cast,
        OLD.crew,
        OLD.productionCompanies,
        OLD.networks,
        OLD.totalSeasons,
        OLD.totalEpisodes,
        OLD.isActive,
        v_graveyard_id
    );
END //

-- Seasons triggers
CREATE TRIGGER Seasons_Insert_Audit
BEFORE INSERT ON Seasons
FOR EACH ROW
BEGIN
    -- Update total seasons in Series
    UPDATE Series 
    SET totalSeasons = totalSeasons + 1
    WHERE contentId = NEW.contentRefId;

    -- Log the audit
    CALL LogAudit(
        'Seasons', 
        NEW.contentId, 
        'insert', 
        NULL,
        GetSeasonJSON(
            NEW.contentId,
            NEW.contentRefId,
            NEW.title,
            NEW.description,
            NEW.seasonNumber,
            NEW.episodeCount,
            NEW.releaseDate,
            NEW.posterPath,
            NEW.voteAverage,
            NEW.voteCount,
            NEW.isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER Seasons_Update_Audit
AFTER UPDATE ON Seasons
FOR EACH ROW
BEGIN
    DECLARE old_json, new_json, changed_json JSON;
    
    -- Set episodeCount to NULL for both old and new to ignore it in comparison
    SET old_json = GetSeasonJSON(
        OLD.contentId,
        OLD.contentRefId,
        OLD.title,
        OLD.description,
        OLD.seasonNumber,
        NULL,  -- Ignore episodeCount in audit
        OLD.releaseDate,
        OLD.posterPath,
        OLD.voteAverage,
        OLD.voteCount,
        OLD.isActive
    );
    
    SET new_json = GetSeasonJSON(
        NEW.contentId,
        NEW.contentRefId,
        NEW.title,
        NEW.description,
        NEW.seasonNumber,
        NULL,  -- Ignore episodeCount in audit
        NEW.releaseDate,
        NEW.posterPath,
        NEW.voteAverage,
        NEW.voteCount,
        NEW.isActive
    );
    
    SET changed_json = GetChangedFieldsJSON(old_json, new_json);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'Seasons', 
            NEW.contentId, 
            'update',
            old_json,
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
    DECLARE v_graveyard_id UUID;
    DECLARE v_series_id UUID;

    -- First get the series ID if it exists
    SELECT contentId INTO v_series_id
    FROM Series
    WHERE contentId = OLD.contentRefId
    LIMIT 1;

    -- Delete all related Episodes
    DELETE FROM Episodes WHERE contentRefId = OLD.contentId;

    -- Update parent Series if it exists
    IF v_series_id IS NOT NULL THEN
        UPDATE Series 
        SET totalSeasons = GREATEST(0, totalSeasons - 1)
        WHERE contentId = v_series_id;
    END IF;

    CALL SeasonsDeleteAudit(
        OLD.contentId,
        OLD.contentRefId,
        OLD.title,
        OLD.description,
        OLD.seasonNumber,
        OLD.episodeCount,
        OLD.releaseDate,
        OLD.posterPath,
        OLD.voteAverage,
        OLD.voteCount,
        OLD.isActive,
        v_graveyard_id
    );
END //

-- Episodes triggers
CREATE TRIGGER Episodes_Insert_Audit
BEFORE INSERT ON Episodes
FOR EACH ROW
BEGIN
    -- Update episode count in Seasons
    UPDATE Seasons 
    SET episodeCount = episodeCount + 1
    WHERE contentId = NEW.contentRefId;

    -- Update total episodes in Series
    UPDATE Series serie
    INNER JOIN Seasons season ON season.contentRefId = serie.contentId
    SET serie.totalEpisodes = serie.totalEpisodes + 1
    WHERE season.contentId = NEW.contentRefId;

    -- Log the audit
    CALL LogAudit(
        'Episodes',
        NEW.contentId,
        'insert',
        NULL,
        GetEpisodeJSON(
            NEW.contentId,
            NEW.contentRefId,
            NEW.tmdbId,
            NEW.imdbId,
            NEW.rgId,
            NEW.title,
            NEW.altTitle,
            NEW.description,
            NEW.episodeNumber,
            NEW.runtime,
            NEW.releaseDate,
            NEW.voteAverage,
            NEW.voteCount,
            NEW.posterPath,
            NEW.backdropPath,
            NEW.isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER Episodes_Update_Audit
AFTER UPDATE ON Episodes
FOR EACH ROW
BEGIN
    DECLARE old_json, new_json, changed_json JSON;
    
    SET old_json = GetEpisodeJSON(
        OLD.contentId,
        OLD.contentRefId,
        OLD.tmdbId,
        OLD.imdbId,
        OLD.rgId,
        OLD.title,
        OLD.altTitle,
        OLD.description,
        OLD.episodeNumber,
        OLD.runtime,
        OLD.releaseDate,
        OLD.voteAverage,
        OLD.voteCount,
        OLD.posterPath,
        OLD.backdropPath,
        OLD.isActive
    );
    
    SET new_json = GetEpisodeJSON(
        NEW.contentId,
        NEW.contentRefId,
        NEW.tmdbId,
        NEW.imdbId,
        NEW.rgId,
        NEW.title,
        NEW.altTitle,
        NEW.description,
        NEW.episodeNumber,
        NEW.runtime,
        NEW.releaseDate,
        NEW.voteAverage,
        NEW.voteCount,
        NEW.posterPath,
        NEW.backdropPath,
        NEW.isActive
    );
    
    SET changed_json = GetChangedFieldsJSON(old_json, new_json);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'Episodes', 
            NEW.contentId, 
            'update',
            old_json,
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
    DECLARE v_graveyard_id UUID;
    DECLARE v_series_id UUID;
    DECLARE v_season_id UUID;
    DECLARE v_episode_count INT;

    -- First get the season ID and its current episode count if it exists
    SELECT contentId, episodeCount INTO v_season_id, v_episode_count
    FROM Seasons
    WHERE contentId = OLD.contentRefId
    LIMIT 1;

    -- If we found a season, get its series and update counts
    IF v_season_id IS NOT NULL THEN
        -- Get the series ID if it exists
        SELECT serie.contentId INTO v_series_id
        FROM Series serie
        INNER JOIN Seasons season ON serie.contentId = season.contentRefId
        WHERE season.contentId = v_season_id
        LIMIT 1;

        -- Update season's episode count
        UPDATE Seasons 
        SET episodeCount = GREATEST(0, v_episode_count - 1)
        WHERE contentId = v_season_id;

        -- Update series total episodes if we found a series
        IF v_series_id IS NOT NULL THEN
            UPDATE Series
            SET totalEpisodes = GREATEST(0, totalEpisodes - 1)
            WHERE contentId = v_series_id;
        END IF;
    END IF;

    CALL EpisodesDeleteAudit(
        OLD.contentId,
        OLD.contentRefId,
        OLD.tmdbId,
        OLD.imdbId,
        OLD.rgId,
        OLD.title,
        OLD.altTitle,
        OLD.description,
        OLD.episodeNumber,
        OLD.runtime,
        OLD.releaseDate,
        OLD.voteAverage,
        OLD.voteCount,
        OLD.posterPath,
        OLD.backdropPath,
        OLD.isActive,
        v_graveyard_id
    );
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
    
    CALL LogAudit(
        'MoviesDeeplinks', 
        NEW.contentId, 
        'insert', 
        NULL,
        GetDeeplinkJSON(
            NEW.contentId, 
            NEW.contentRefId, 
            display_title,
            NEW.sourceId, 
            NEW.sourceType, 
            NEW.originSource, 
            NEW.region, 
            NEW.web,
            NEW.android,
            NEW.iOS,
            NEW.androidTv,
            NEW.fireTv,
            NEW.lg,
            NEW.samsung,
            NEW.tvOS,
            NEW.roku,
            NEW.isActive,
            NEW.tmdbId
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER MoviesDeeplinks_Update_Audit
AFTER UPDATE ON MoviesDeeplinks
FOR EACH ROW
BEGIN
    DECLARE old_display_title, new_display_title VARCHAR(255);
    DECLARE old_json, new_json, changed_json JSON;
    
    SET old_display_title = GetDisplayTitle(OLD.title, OLD.altTitle);
    SET new_display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    
    SET old_json = GetDeeplinkJSON(
        OLD.contentId, 
        OLD.contentRefId, 
        old_display_title,
        OLD.sourceId, 
        OLD.sourceType, 
        OLD.originSource, 
        OLD.region, 
        OLD.web,
        OLD.android,
        OLD.iOS,
        OLD.androidTv,
        OLD.fireTv,
        OLD.lg,
        OLD.samsung,
        OLD.tvOS,
        OLD.roku,
        OLD.isActive,
        OLD.tmdbId
    );
    
    SET new_json = GetDeeplinkJSON(
        NEW.contentId, 
        NEW.contentRefId, 
        new_display_title,
        NEW.sourceId, 
        NEW.sourceType, 
        NEW.originSource, 
        NEW.region, 
        NEW.web,
        NEW.android,
        NEW.iOS,
        NEW.androidTv,
        NEW.fireTv,
        NEW.lg,
        NEW.samsung,
        NEW.tvOS,
        NEW.roku,
        NEW.isActive,
        NEW.tmdbId
    );
    
    SET changed_json = GetChangedFieldsJSON(old_json, new_json);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'MoviesDeeplinks', 
            NEW.contentId, 
            'update',
            old_json,
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
    DECLARE v_graveyard_id UUID;
    CALL MoviesDeeplinksDeleteAudit(
        OLD.contentId,
        OLD.contentRefId,
        OLD.tmdbId,
        OLD.title,
        OLD.altTitle,
        OLD.releaseDate,
        OLD.altReleaseDate,
        OLD.sourceId,
        OLD.sourceType,
        OLD.originSource,
        OLD.region,
        OLD.web,
        OLD.android,
        OLD.iOS,
        OLD.androidTv,
        OLD.fireTv,
        OLD.lg,
        OLD.samsung,
        OLD.tvOS,
        OLD.roku,
        OLD.isActive,
        v_graveyard_id
    );
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
        GetDeeplinkJSON(
            NEW.contentId, 
            NEW.contentRefId, 
            display_title,
            NEW.sourceId, 
            NEW.sourceType, 
            NEW.originSource, 
            NEW.region, 
            NEW.web,
            NEW.android,
            NEW.iOS,
            NEW.androidTv,
            NEW.fireTv,
            NEW.lg,
            NEW.samsung,
            NEW.tvOS,
            NEW.roku,
            NEW.isActive,
            NEW.tmdbId
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER SeriesDeeplinks_Update_Audit
AFTER UPDATE ON SeriesDeeplinks
FOR EACH ROW
BEGIN
    DECLARE old_display_title, new_display_title VARCHAR(255);
    DECLARE old_json, new_json, changed_json JSON;
    
    SET old_display_title = GetDisplayTitle(OLD.title, OLD.altTitle);
    SET new_display_title = GetDisplayTitle(NEW.title, NEW.altTitle);
    
    SET old_json = GetDeeplinkJSON(
        OLD.contentId, 
        OLD.contentRefId, 
        old_display_title,
        OLD.sourceId, 
        OLD.sourceType, 
        OLD.originSource, 
        OLD.region, 
        OLD.web,
        OLD.android,
        OLD.iOS,
        OLD.androidTv,
        OLD.fireTv,
        OLD.lg,
        OLD.samsung,
        OLD.tvOS,
        OLD.roku,
        OLD.isActive,
        OLD.tmdbId
    );
    
    SET new_json = GetDeeplinkJSON(
        NEW.contentId, 
        NEW.contentRefId, 
        new_display_title,
        NEW.sourceId, 
        NEW.sourceType, 
        NEW.originSource, 
        NEW.region, 
        NEW.web,
        NEW.android,
        NEW.iOS,
        NEW.androidTv,
        NEW.fireTv,
        NEW.lg,
        NEW.samsung,
        NEW.tvOS,
        NEW.roku,
        NEW.isActive,
        NEW.tmdbId
    );
    
    SET changed_json = GetChangedFieldsJSON(old_json, new_json);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'SeriesDeeplinks', 
            NEW.contentId, 
            'update',
            old_json,
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
    DECLARE v_graveyard_id UUID;
    CALL SeriesDeeplinksDeleteAudit(
        OLD.contentId,
        OLD.contentRefId,
        OLD.tmdbId,
        OLD.title,
        OLD.altTitle,
        OLD.releaseDate,
        OLD.altReleaseDate,
        OLD.sourceId,
        OLD.sourceType,
        OLD.originSource,
        OLD.region,
        OLD.web,
        OLD.android,
        OLD.iOS,
        OLD.androidTv,
        OLD.fireTv,
        OLD.lg,
        OLD.samsung,
        OLD.tvOS,
        OLD.roku,
        OLD.isActive,
        v_graveyard_id
    );
END //

-- MoviesPrices triggers with correct number of arguments
CREATE TRIGGER MoviesPrices_Insert_Audit
BEFORE INSERT ON MoviesPrices
FOR EACH ROW
BEGIN
    CALL LogAudit(
        'MoviesPrices', 
        NEW.contentId, 
        'insert',
        NULL,
        GetPriceJSON(
            NEW.contentId,
            NEW.contentRefId,
            NEW.region,
            NEW.buySD,
            NEW.buyHD,
            NEW.buyUHD,
            NEW.rentSD,
            NEW.rentHD,
            NEW.rentUHD,
            NULL,  -- seriesBuySD
            NULL,  -- seriesBuyHD
            NULL,  -- seriesBuyUHD
            NULL,  -- seriesRentSD
            NULL,  -- seriesRentHD
            NULL,  -- seriesRentUHD
            NULL,  -- seasonBuySD
            NULL,  -- seasonBuyHD
            NULL,  -- seasonBuyUHD
            NULL,  -- seasonRentSD
            NULL,  -- seasonRentHD
            NULL,  -- seasonRentUHD
            NEW.isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER MoviesPrices_Update_Audit
AFTER UPDATE ON MoviesPrices
FOR EACH ROW
BEGIN
    DECLARE old_json, new_json, changed_json JSON;
    
    SET old_json = GetPriceJSON(
        OLD.contentId,
        OLD.contentRefId,
        OLD.region,
        OLD.buySD,
        OLD.buyHD,
        OLD.buyUHD,
        OLD.rentSD,
        OLD.rentHD,
        OLD.rentUHD,
        NULL,  -- seriesBuySD
        NULL,  -- seriesBuyHD
        NULL,  -- seriesBuyUHD
        NULL,  -- seriesRentSD
        NULL,  -- seriesRentHD
        NULL,  -- seriesRentUHD
        NULL,  -- seasonBuySD
        NULL,  -- seasonBuyHD
        NULL,  -- seasonBuyUHD
        NULL,  -- seasonRentSD
        NULL,  -- seasonRentHD
        NULL,  -- seasonRentUHD
        OLD.isActive
    );
    
    SET new_json = GetPriceJSON(
        NEW.contentId,
        NEW.contentRefId,
        NEW.region,
        NEW.buySD,
        NEW.buyHD,
        NEW.buyUHD,
        NEW.rentSD,
        NEW.rentHD,
        NEW.rentUHD,
        NULL,  -- seriesBuySD
        NULL,  -- seriesBuyHD
        NULL,  -- seriesBuyUHD
        NULL,  -- seriesRentSD
        NULL,  -- seriesRentHD
        NULL,  -- seriesRentUHD
        NULL,  -- seasonBuySD
        NULL,  -- seasonBuyHD
        NULL,  -- seasonBuyUHD
        NULL,  -- seasonRentSD
        NULL,  -- seasonRentHD
        NULL,  -- seasonRentUHD
        NEW.isActive
    );
    
    SET changed_json = GetChangedFieldsJSON(old_json, new_json);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'MoviesPrices', 
            NEW.contentId, 
            'update',
            old_json,
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
    DECLARE v_graveyard_id UUID;
    CALL MoviesPricesDeleteAudit(
        OLD.contentId,
        OLD.contentRefId,
        OLD.region,
        OLD.buySD,
        OLD.buyHD,
        OLD.buyUHD,
        OLD.rentSD,
        OLD.rentHD,
        OLD.rentUHD,
        OLD.isActive,
        v_graveyard_id
    );
END //

-- SeriesPrices triggers
CREATE TRIGGER SeriesPrices_Insert_Audit
BEFORE INSERT ON SeriesPrices
FOR EACH ROW
BEGIN
    CALL LogAudit(
        'SeriesPrices', 
        NEW.contentId, 
        'insert',
        NULL,
        GetPriceJSON(NEW.contentId, NEW.contentRefId, NEW.region, NEW.buySD, NEW.buyHD, NEW.buyUHD, NEW.rentSD, NEW.rentHD, NEW.rentUHD, NEW.seriesBuySD, NEW.seriesBuyHD, NEW.seriesBuyUHD, NEW.seriesRentSD, NEW.seriesRentHD, NEW.seriesRentUHD, NEW.seasonBuySD, NEW.seasonBuyHD, NEW.seasonBuyUHD, NEW.seasonRentSD, NEW.seasonRentHD, NEW.seasonRentUHD, NEW.isActive),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE TRIGGER SeriesPrices_Update_Audit
AFTER UPDATE ON SeriesPrices
FOR EACH ROW
BEGIN
    DECLARE old_json, new_json, changed_json JSON;
    
    SET old_json = GetPriceJSON(NEW.contentId, NEW.contentRefId, NEW.region, NEW.buySD, NEW.buyHD, NEW.buyUHD, NEW.rentSD, NEW.rentHD, NEW.rentUHD, NEW.seriesBuySD, NEW.seriesBuyHD, NEW.seriesBuyUHD, NEW.seriesRentSD, NEW.seriesRentHD, NEW.seriesRentUHD, NEW.seasonBuySD, NEW.seasonBuyHD, NEW.seasonBuyUHD, NEW.seasonRentSD, NEW.seasonRentHD, NEW.seasonRentUHD, NEW.isActive);
    
    SET new_json = GetPriceJSON(NEW.contentId, NEW.contentRefId, NEW.region, NEW.buySD, NEW.buyHD, NEW.buyUHD, NEW.rentSD, NEW.rentHD, NEW.rentUHD, NEW.seriesBuySD, NEW.seriesBuyHD, NEW.seriesBuyUHD, NEW.seriesRentSD, NEW.seriesRentHD, NEW.seriesRentUHD, NEW.seasonBuySD, NEW.seasonBuyHD, NEW.seasonBuyUHD, NEW.seasonRentSD, NEW.seasonRentHD, NEW.seasonRentUHD, NEW.isActive);
    
    SET changed_json = GetChangedFieldsJSON(old_json, new_json);
    
    IF JSON_LENGTH(JSON_KEYS(changed_json)) > 0 THEN
        CALL LogAudit(
            'SeriesPrices', 
            NEW.contentId, 
            'update',
            old_json,
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
    DECLARE v_graveyard_id UUID;
    CALL SeriesPricesDeleteAudit(
        OLD.contentId,
        OLD.contentRefId,
        OLD.region,
        OLD.buySD,
        OLD.buyHD,
        OLD.buyUHD,
        OLD.rentSD,
        OLD.rentHD,
        OLD.rentUHD,
        OLD.seriesBuySD,
        OLD.seriesBuyHD,
        OLD.seriesBuyUHD,
        OLD.seriesRentSD,
        OLD.seriesRentHD,
        OLD.seriesRentUHD,
        OLD.seasonBuySD,
        OLD.seasonBuyHD,
        OLD.seasonBuyUHD,
        OLD.seasonRentSD,
        OLD.seasonRentHD,
        OLD.seasonRentUHD,
        OLD.isActive,
        v_graveyard_id
    );
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
    contentType TEXT,
    sourceType TEXT,
    actionType TEXT,
    reason TEXT,
    jsonData JSON
)
BEGIN
    DECLARE graveyardId UUID;
    SET graveyardId = UUID_v7();

    INSERT INTO Graveyard (
        id, contentRefId, contentType, sourceId, sourceType, title, reason, details, rawData, username, appContext
    ) VALUES (
        graveyardId,
        JSON_EXTRACT(jsonData, '$.contentId'),
        contentType,
        JSON_EXTRACT(jsonData, '$.tmdbId'),
        sourceType,
        COALESCE(JSON_EXTRACT(jsonData, '$.altTitle'), JSON_EXTRACT(jsonData, '$.title')),
        actionType,
        reason,
        jsonData,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

-- Movies delete audit procedure
CREATE PROCEDURE MoviesDeleteAudit(
    IN jsonData JSON,
    OUT p_graveyardId UUID
)
BEGIN
    -- Delete all related
    DELETE FROM MoviesDeeplinks WHERE contentRefId = JSON_EXTRACT(jsonData, '$.contentId');

    -- Insert into Graveyard
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
        JSON_EXTRACT(jsonData, '$.contentId'),
        'delete',
        jsonData,
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE SeriesDeleteAudit(
    IN p_contentId UUID,
    IN p_title VARCHAR(255),
    IN p_altTitle VARCHAR(255),
    IN p_tmdbId VARCHAR(20),
    IN p_imdbId VARCHAR(20),
    IN p_rgId VARCHAR(128),
    IN p_description TEXT,
    IN p_releaseDate DATE,
    IN p_posterPath VARCHAR(255),
    IN p_backdropPath VARCHAR(255),
    IN p_popularity DECIMAL(10,2),
    IN p_voteAverage DECIMAL(3,1),
    IN p_voteCount INT,
    IN p_genres JSON,
    IN p_keywords JSON,
    IN p_cast JSON,
    IN p_crew JSON,
    IN p_productionCompanies JSON,
    IN p_networks JSON,
    IN p_totalSeasons INT,
    IN p_totalEpisodes INT,
    IN p_isActive BOOLEAN,
    OUT p_graveyardId UUID
)
BEGIN
    -- Delete all related
    DELETE FROM Seasons WHERE contentRefId = p_contentId;

    -- Generate UUID for Graveyard
    SET p_graveyardId = UUID_v7();
    
    -- Insert into Graveyard
    INSERT INTO Graveyard (
        id, contentRefId, contentType, sourceId, sourceType, title, reason, details, rawData, username, appContext
    ) VALUES (
        p_graveyardId,
        p_contentId,
        'Series',
        p_tmdbId,
        'tmdb',
        COALESCE(p_altTitle, p_title),
        'deleted',
        'Deleted by user',
        JSON_OBJECT(
            'contentId', p_contentId,
            'tmdbId', p_tmdbId,
            'imdbId', p_imdbId,
            'rgId', p_rgId,
            'title', p_title,
            'altTitle', p_altTitle,
            'description', p_description,
            'releaseDate', p_releaseDate,
            'posterPath', p_posterPath,
            'backdropPath', p_backdropPath,
            'popularity', p_popularity,
            'voteAverage', p_voteAverage,
            'voteCount', p_voteCount,
            'genres', p_genres,
            'keywords', p_keywords,
            'cast', p_cast,
            'crew', p_crew,
            'productionCompanies', p_productionCompanies,
            'networks', p_networks,
            'totalSeasons', p_totalSeasons,
            'totalEpisodes', p_totalEpisodes,
            'isActive', p_isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );

    -- Log audit
    CALL LogAudit(
        'Series',
        p_contentId,
        'delete',
        GetContentJSON(
            p_contentId,
            GetDisplayTitle(p_title, p_altTitle),
            p_tmdbId,
            p_imdbId,
            p_rgId,
            p_description,
            p_releaseDate,
            p_posterPath,
            p_backdropPath,
            p_voteAverage,
            p_voteCount,
            p_isActive
        ),
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE SeasonsDeleteAudit(
    IN p_contentId UUID,
    IN p_contentRefId UUID,
    IN p_title VARCHAR(255),
    IN p_description TEXT,
    IN p_seasonNumber SMALLINT,
    IN p_episodeCount SMALLINT,
    IN p_releaseDate DATE,
    IN p_posterPath VARCHAR(255),
    IN p_voteAverage DECIMAL(3,1),
    IN p_voteCount INT,
    IN p_isActive BOOLEAN,
    OUT p_graveyardId UUID
)
BEGIN
    -- Delete all related
    DELETE FROM Episodes WHERE contentRefId = p_contentId;

    -- Generate UUID for Graveyard
    SET p_graveyardId = UUID_v7();
    
    -- Insert into Graveyard
    INSERT INTO Graveyard (
        id, contentRefId, contentType, sourceId, sourceType, title, reason, details, rawData, username, appContext
    ) VALUES (
        p_graveyardId,
        p_contentId,
        'Seasons',
        p_contentRefId,
        'tmdb',
        p_title,
        'deleted',
        'Deleted by user',
        JSON_OBJECT(
            'contentId', p_contentId,
            'contentRefId', p_contentRefId,
            'title', p_title,
            'description', p_description,
            'seasonNumber', p_seasonNumber,
            'episodeCount', p_episodeCount,
            'releaseDate', p_releaseDate,
            'posterPath', p_posterPath,
            'voteAverage', p_voteAverage,
            'voteCount', p_voteCount,
            'isActive', p_isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );

    -- Log audit
    CALL LogAudit(
        'Seasons',
        p_contentId,
        'delete',
        GetContentJSON(
            p_contentId,
            p_title,
            NULL,
            NULL,
            NULL,
            p_description,
            p_releaseDate,
            p_posterPath,
            NULL,
            p_voteAverage,
            p_voteCount,
            p_isActive
        ),
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE EpisodesDeleteAudit(
    IN p_contentId UUID,
    IN p_contentRefId UUID,
    IN p_tmdbId VARCHAR(20),
    IN p_imdbId VARCHAR(20),
    IN p_rgId VARCHAR(128),
    IN p_title VARCHAR(255),
    IN p_altTitle VARCHAR(255),
    IN p_description TEXT,
    IN p_episodeNumber SMALLINT,
    IN p_runtime INT,
    IN p_releaseDate DATE,
    IN p_voteAverage DECIMAL(3,1),
    IN p_voteCount INT,
    IN p_posterPath VARCHAR(255),
    IN p_backdropPath VARCHAR(255),
    IN p_isActive BOOLEAN,
    OUT p_graveyardId UUID
)
BEGIN
    -- Delete all related
    DELETE FROM SeriesDeeplinks WHERE contentRefId = p_contentId;

    -- Generate UUID for Graveyard
    SET p_graveyardId = UUID_v7();
    
    -- Insert into Graveyard
    INSERT INTO Graveyard (
        id, contentRefId, contentType, sourceId, sourceType, title, reason, details, rawData, username, appContext
    ) VALUES (
        p_graveyardId,
        p_contentId,
        'Episodes',
        p_contentRefId,
        'tmdb',
        p_title,
        'deleted',
        'Deleted by user',
        JSON_OBJECT(
            'contentId', p_contentId,
            'contentRefId', p_contentRefId,
            'tmdbId', p_tmdbId,
            'imdbId', p_imdbId,
            'rgId', p_rgId,
            'title', p_title,
            'altTitle', p_altTitle,
            'description', p_description,
            'episodeNumber', p_episodeNumber,
            'runtime', p_runtime,
            'releaseDate', p_releaseDate,
            'voteAverage', p_voteAverage,
            'voteCount', p_voteCount,
            'posterPath', p_posterPath,
            'backdropPath', p_backdropPath,
            'isActive', p_isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );

    -- Log audit
    CALL LogAudit(
        'Episodes',
        p_contentId,
        'delete',
        GetContentJSON(
            p_contentId,
            p_title,
            p_tmdbId,
            p_imdbId,
            p_rgId,
            p_description,
            p_releaseDate,
            p_posterPath,
            p_backdropPath,
            p_voteAverage,
            p_voteCount,
            p_isActive
        ),
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE MoviesDeeplinksDeleteAudit(
    IN p_contentId UUID,
    IN p_contentRefId UUID,
    IN p_tmdbId VARCHAR(20),
    IN p_title VARCHAR(255),
    IN p_altTitle VARCHAR(255),
    IN p_releaseDate DATE,
    IN p_altReleaseDate DATE,
    IN p_sourceId SMALLINT,
    IN p_sourceType VARCHAR(64),
    IN p_originSource VARCHAR(64),
    IN p_region VARCHAR(10),
    IN p_web VARCHAR(512),
    IN p_android VARCHAR(512),
    IN p_iOS VARCHAR(512),
    IN p_androidTv VARCHAR(512),
    IN p_fireTv VARCHAR(512),
    IN p_lg VARCHAR(512),
    IN p_samsung VARCHAR(512),
    IN p_tvOS VARCHAR(512),
    IN p_roku VARCHAR(512),
    IN p_isActive BOOLEAN,
    OUT p_graveyardId UUID
)
BEGIN
    -- Delete all related
    DELETE FROM MoviesPrices WHERE contentRefId = p_contentId;

    -- Generate UUID for Graveyard
    SET p_graveyardId = UUID_v7();
    
    -- Insert into Graveyard
    INSERT INTO Graveyard (
        id, contentRefId, contentType, sourceId, sourceType, title, reason, details, rawData, username, appContext
    ) VALUES (
        p_graveyardId,
        p_contentId,
        'MoviesDeeplinks',
        p_sourceId,
        p_sourceType,
        COALESCE(p_altTitle, p_title),
        'deleted',
        'Deleted by user',
        JSON_OBJECT(
            'contentId', p_contentId,
            'contentRefId', p_contentRefId,
            'tmdbId', p_tmdbId,
            'title', p_title,
            'altTitle', p_altTitle,
            'releaseDate', p_releaseDate,
            'altReleaseDate', p_altReleaseDate,
            'sourceId', p_sourceId,
            'sourceType', p_sourceType,
            'originSource', p_originSource,
            'region', p_region,
            'web', p_web,
            'android', p_android,
            'iOS', p_iOS,
            'androidTv', p_androidTv,
            'fireTv', p_fireTv,
            'lg', p_lg,
            'samsung', p_samsung,
            'tvOS', p_tvOS,
            'roku', p_roku,
            'isActive', p_isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );

    -- Log audit
    CALL LogAudit(
        'MoviesDeeplinks',
        p_contentId,
        'delete',
        GetDeeplinkJSON(
            p_contentId,
            p_contentRefId,
            COALESCE(p_altTitle, p_title),
            p_sourceId,
            p_sourceType,
            p_originSource,
            p_region,
            p_web,
            p_android,
            p_iOS,
            p_androidTv,
            p_fireTv,
            p_lg,
            p_samsung,
            p_tvOS,
            p_roku,
            p_isActive,
            p_tmdbId
        ),
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE SeriesDeeplinksDeleteAudit(
    IN p_contentId UUID,
    IN p_contentRefId UUID,
    IN p_tmdbId VARCHAR(20),
    IN p_title VARCHAR(255),
    IN p_altTitle VARCHAR(255),
    IN p_releaseDate DATE,
    IN p_altReleaseDate DATE,
    IN p_sourceId SMALLINT,
    IN p_sourceType VARCHAR(64),
    IN p_originSource VARCHAR(64),
    IN p_region VARCHAR(10),
    IN p_web VARCHAR(512),
    IN p_android VARCHAR(512),
    IN p_iOS VARCHAR(512),
    IN p_androidTv VARCHAR(512),
    IN p_fireTv VARCHAR(512),
    IN p_lg VARCHAR(512),
    IN p_samsung VARCHAR(512),
    IN p_tvOS VARCHAR(512),
    IN p_roku VARCHAR(512),
    IN p_isActive BOOLEAN,
    OUT p_graveyardId UUID
)
BEGIN
    -- Delete all related
    DELETE FROM SeriesPrices WHERE contentRefId = p_contentId;

    -- Generate UUID for Graveyard
    SET p_graveyardId = UUID_v7();
    
    -- Insert into Graveyard
    INSERT INTO Graveyard (
        id, contentRefId, contentType, sourceId, sourceType, title, reason, details, rawData, username, appContext
    ) VALUES (
        p_graveyardId,
        p_contentId,
        'SeriesDeeplinks',
        p_sourceId,
        p_sourceType,
        COALESCE(p_altTitle, p_title),
        'deleted',
        'Deleted by user',
        JSON_OBJECT(
            'contentId', p_contentId,
            'contentRefId', p_contentRefId,
            'tmdbId', p_tmdbId,
            'title', p_title,
            'altTitle', p_altTitle,
            'releaseDate', p_releaseDate,
            'altReleaseDate', p_altReleaseDate,
            'sourceId', p_sourceId,
            'sourceType', p_sourceType,
            'originSource', p_originSource,
            'region', p_region,
            'web', p_web,
            'android', p_android,
            'iOS', p_iOS,
            'androidTv', p_androidTv,
            'fireTv', p_fireTv,
            'lg', p_lg,
            'samsung', p_samsung,
            'tvOS', p_tvOS,
            'roku', p_roku,
            'isActive', p_isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );

    -- Log audit
    CALL LogAudit(
        'SeriesDeeplinks',
        p_contentId,
        'delete',
        GetDeeplinkJSON(
            p_contentId,
            p_contentRefId,
            COALESCE(p_altTitle, p_title),
            p_sourceId,
            p_sourceType,
            p_originSource,
            p_region,
            p_web,
            p_android,
            p_iOS,
            p_androidTv,
            p_fireTv,
            p_lg,
            p_samsung,
            p_tvOS,
            p_roku,
            p_isActive,
            p_tmdbId
        ),
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE MoviesPricesDeleteAudit(
    IN p_contentId UUID,
    IN p_contentRefId UUID,
    IN p_region VARCHAR(10),
    IN p_buySD DECIMAL(10,2),
    IN p_buyHD DECIMAL(10,2),
    IN p_buyUHD DECIMAL(10,2),
    IN p_rentSD DECIMAL(10,2),
    IN p_rentHD DECIMAL(10,2),
    IN p_rentUHD DECIMAL(10,2),
    IN p_isActive BOOLEAN,
    OUT p_graveyardId UUID
)
BEGIN
    -- Generate UUID for Graveyard
    SET p_graveyardId = UUID_v7();
    
    -- Insert into Graveyard
    INSERT INTO Graveyard (
        id, contentRefId, contentType, sourceId, sourceType, title, reason, details, rawData, username, appContext
    ) VALUES (
        p_graveyardId,
        p_contentId,
        'MoviesPrices',
        p_contentRefId,
        'tmdb',
        NULL,
        'deleted',
        'Deleted by user',
        JSON_OBJECT(
            'contentId', p_contentId,
            'contentRefId', p_contentRefId,
            'region', p_region,
            'buySD', p_buySD,
            'buyHD', p_buyHD,
            'buyUHD', p_buyUHD,
            'rentSD', p_rentSD,
            'rentHD', p_rentHD,
            'rentUHD', p_rentUHD,
            'isActive', p_isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );

    -- Log audit
    CALL LogAudit(
        'MoviesPrices',
        p_contentId,
        'delete',
        GetPriceJSON(
            p_contentId,
            p_contentRefId,
            p_region,
            p_buySD,
            p_buyHD,
            p_buyUHD,
            p_rentSD,
            p_rentHD,
            p_rentUHD,
            NULL, NULL, NULL,
            NULL, NULL, NULL,
            NULL, NULL, NULL,
            NULL, NULL, NULL,
            p_isActive
        ),
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

CREATE PROCEDURE SeriesPricesDeleteAudit(
    IN p_contentId UUID,
    IN p_contentRefId UUID,
    IN p_region VARCHAR(10),
    IN p_seriesBuySD DECIMAL(10,2),
    IN p_seriesBuyHD DECIMAL(10,2),
    IN p_seriesBuyUHD DECIMAL(10,2),
    IN p_seriesRentSD DECIMAL(10,2),
    IN p_seriesRentHD DECIMAL(10,2),
    IN p_seriesRentUHD DECIMAL(10,2),
    IN p_seasonBuySD DECIMAL(10,2),
    IN p_seasonBuyHD DECIMAL(10,2),
    IN p_seasonBuyUHD DECIMAL(10,2),
    IN p_seasonRentSD DECIMAL(10,2),
    IN p_seasonRentHD DECIMAL(10,2),
    IN p_seasonRentUHD DECIMAL(10,2),
    IN p_isActive BOOLEAN,
    OUT p_graveyardId UUID
)
BEGIN
    -- Generate UUID for Graveyard
    SET p_graveyardId = UUID_v7();
    
    -- Insert into Graveyard
    INSERT INTO Graveyard (
        id, contentRefId, contentType, sourceId, sourceType, title, reason, details, rawData, username, appContext
    ) VALUES (
        p_graveyardId,
        p_contentId,
        'SeriesPrices',
        p_contentRefId,
        'tmdb',
        NULL,
        'deleted',
        'Deleted by user',
        JSON_OBJECT(
            'contentId', p_contentId,
            'contentRefId', p_contentRefId,
            'region', p_region,
            'seriesBuySD', p_seriesBuySD,
            'seriesBuyHD', p_seriesBuyHD,
            'seriesBuyUHD', p_seriesBuyUHD,
            'seriesRentSD', p_seriesRentSD,
            'seriesRentHD', p_seriesRentHD,
            'seriesRentUHD', p_seriesRentUHD,
            'seasonBuySD', p_seasonBuySD,
            'seasonBuyHD', p_seasonBuyHD,
            'seasonBuyUHD', p_seasonBuyUHD,
            'seasonRentSD', p_seasonRentSD,
            'seasonRentHD', p_seasonRentHD,
            'seasonRentUHD', p_seasonRentUHD,
            'isActive', p_isActive
        ),
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );

    -- Log audit
    CALL LogAudit(
        'SeriesPrices',
        p_contentId,
        'delete',
        GetPriceJSON(
            p_contentId,
            p_contentRefId,
            p_region,
            NULL, NULL, NULL,
            NULL, NULL, NULL,
            p_seriesBuySD,
            p_seriesBuyHD,
            p_seriesBuyUHD,
            p_seriesRentSD,
            p_seriesRentHD,
            p_seriesRentUHD,
            p_seasonBuySD,
            p_seasonBuyHD,
            p_seasonBuyUHD,
            p_seasonRentSD,
            p_seasonRentHD,
            p_seasonRentUHD,
            p_isActive
        ),
        NULL,
        COALESCE(@username, 'system'),
        COALESCE(@appContext, 'system')
    );
END //

DELIMITER ;
