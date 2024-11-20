-- Create and use the database
CREATE DATABASE IF NOT EXISTS `Tmdb`;
USE Tmdb;

-- Disable foreign key checks for clean setup
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `ScrapersActivity`;
DROP TABLE IF EXISTS `Scrapers`;
DROP TABLE IF EXISTS `MovieDeeplinks`;
DROP TABLE IF EXISTS `EpisodeDeeplinks`;
DROP TABLE IF EXISTS `MoviesMetadata`;
DROP TABLE IF EXISTS `SeriesMetadata`;
DROP TABLE IF EXISTS `SeasonsMetadata`;
DROP TABLE IF EXISTS `EpisodesMetadata`;
DROP TABLE IF EXISTS `Movies`;
DROP TABLE IF EXISTS `Series`;
DROP TABLE IF EXISTS `Seasons`;
DROP TABLE IF EXISTS `Episodes`;
DROP TABLE IF EXISTS `AuditLog`;
DROP TABLE IF EXISTS `ContentTypes`;
SET FOREIGN_KEY_CHECKS = 1;

-- Base content type enum
CREATE TABLE ContentTypes (
    id TINYINT UNSIGNED PRIMARY KEY,
    name VARCHAR(32) NOT NULL UNIQUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO ContentTypes (id, name) VALUES 
(1, 'movie'),
(2, 'series'),
(3, 'season'),
(4, 'episode');

-- Core Movies table
CREATE TABLE Movies (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    deeplinkRefId UUID NOT NULL,
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

-- Movies Metadata
CREATE TABLE MoviesMetadata (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    tmdbId VARCHAR(20) NULL,
    imdbId VARCHAR(20) NULL,
    rgId VARCHAR(64) NULL,
    title VARCHAR(255) NULL,
    originalTitle VARCHAR(255) NULL,
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
    lastUpdated TIMESTAMP NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT MoviesMetadataUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT MoviesMetadataMovie_FK FOREIGN KEY (contentId) 
        REFERENCES Movies(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- TV Series table
CREATE TABLE Series (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    title VARCHAR(255) NOT NULL,
    altTitle VARCHAR(255) NULL,
    releaseDate DATE NULL,
    seasonContentIds JSON NULL COMMENT 'Array of season contentIds',
    totalSeasons INT UNSIGNED DEFAULT 0 NULL,
    totalEpisodes INT UNSIGNED DEFAULT 0 NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    isDupe BOOLEAN DEFAULT false NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT SeriesUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT SeriesSeasons_CHK CHECK (JSON_VALID(seasonContentIds))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Series Metadata
CREATE TABLE SeriesMetadata (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    tmdbId VARCHAR(20) NULL,
    imdbId VARCHAR(20) NULL,
    rgId VARCHAR(64) NULL,
    title VARCHAR(255) NULL,
    originalTitle VARCHAR(255) NULL,
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
    networks JSON NULL,
    productionCompanies JSON NULL,
    lastUpdated TIMESTAMP NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT SeriesMetadataUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT SeriesMetadataSeries_FK FOREIGN KEY (contentId) 
        REFERENCES Series(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seasons table
CREATE TABLE Seasons (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    seriesContentId UUID NOT NULL,
    seasonNumber INT DEFAULT -1 NOT NULL,
    episodeContentIds JSON NULL COMMENT 'Array of episode contentIds',
    episodeCount INT UNSIGNED DEFAULT 0 NULL,
    releaseDate DATE NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT SeasonsUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT SeasonNumber_UK UNIQUE KEY (seriesContentId, seasonNumber),
    CONSTRAINT SeasonsEpisodes_CHK CHECK (JSON_VALID(episodeContentIds))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seasons Metadata
CREATE TABLE SeasonsMetadata (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    seriesContentId UUID NOT NULL,
    tmdbId VARCHAR(20) NULL,
    title VARCHAR(255) NULL,
    description TEXT NULL,
    episodeCount SMALLINT UNSIGNED NULL,
    releaseDate DATE NULL,
    posterPath VARCHAR(255) NULL,
    voteAverage DECIMAL(3,1) NULL,
    voteCount INT UNSIGNED NULL,
    lastUpdated TIMESTAMP NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT SeasonsMetadataUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT SeasonsMetadataSeason_FK FOREIGN KEY (contentId) 
        REFERENCES Seasons(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episodes table
CREATE TABLE Episodes (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    deeplinkRefId UUID NOT NULL,
    seasonContentId UUID NOT NULL,
    episodeNumber SMALLINT DEFAULT -1 NOT NULL,
    title VARCHAR(255) NOT NULL,
    releaseDate DATE NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT EpisodesUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT EpisodeNumber_UK UNIQUE KEY (seasonContentId, episodeNumber)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episodes Metadata
CREATE TABLE EpisodesMetadata (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    seasonContentId UUID NOT NULL,
    tmdbId VARCHAR(20) NULL,
    imdbId VARCHAR(20) NULL,
    rgId VARCHAR(64) NULL,
    title VARCHAR(255) NULL,
    description TEXT NULL,
    episodeNumber SMALLINT DEFAULT -1 NOT NULL,
    runtime SMALLINT UNSIGNED NULL COMMENT 'Runtime in minutes',
    releaseDate DATE NULL,
    voteAverage DECIMAL(3,1) NULL,
    voteCount INT UNSIGNED NULL,
    posterPath VARCHAR(255) NULL,
    backdropPath VARCHAR(255) NULL,
    lastUpdated TIMESTAMP NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT EpisodesMetadataUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT EpisodesMetadataEpisode_FK FOREIGN KEY (contentId) 
        REFERENCES Episodes(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Movie Deeplinks table for storing platform-specific movie links
CREATE TABLE MovieDeeplinks (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'Reference to Movies.contentId',
    sourceId SMALLINT UNSIGNED NOT NULL,
    sourceType VARCHAR(64) NOT NULL,
    originSource ENUM ('none', 'freecast', 'gracenote', 'reelgood') DEFAULT 'none' NOT NULL,
    region VARCHAR(10) NULL,
    platformLinks JSON NULL COMMENT '{
        "web": "https://example.com/watch/movie-123",
        "android":"android-app://com.example/watch/movie-123",
        "ios":"example://watch/movie-123",
        "androidTv": "android-tv://com.example/watch/movie-123",
        "fireTv": "amzn://apps/android?asin=B01234567",
        "lg": "lgwebos://watch/movie-123",
        "samsung": "samsung-tizen://watch/movie-123",
        "tvOS": "com.example.tv://watch/movie-123"
    }',
    pricing JSON NULL COMMENT '{
        "buy": {"SD": 9.99, "HD": 14.99, "UHD": 19.99},
        "rent": {"SD": 3.99, "HD": 4.99, "UHD": 5.99}
    }',
    lastUpdated TIMESTAMP NULL,
    updateHistory JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT MovieDeeplinksContent_UK UNIQUE KEY (contentId, sourceId, sourceType, region),
    CONSTRAINT MovieDeeplinksMovies_FK FOREIGN KEY (contentId) 
        REFERENCES Movies(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episode Deeplinks table for storing platform-specific episode links
CREATE TABLE EpisodeDeeplinks (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'Reference to Episodes.contentId',
    sourceId SMALLINT UNSIGNED NOT NULL,
    sourceType VARCHAR(64) NOT NULL,
    originSource ENUM ('none', 'freecast', 'gracenote', 'reelgood') DEFAULT 'none' NOT NULL,
    region VARCHAR(10) NULL,
    platformLinks JSON NULL COMMENT '{
        "web": "https://example.com/watch/episode-123",
        "android":"android-app://com.example/watch/episode-123",
        "ios":"example://watch/episode-123",
        "androidTv": "android-tv://com.example/watch/episode-123",
        "fireTv": "amzn://apps/android?asin=B01234567",
        "lg": "lgwebos://watch/episode-123",
        "samsung": "samsung-tizen://watch/episode-123",
        "tvOS": "com.example.tv://watch/episode-123"
    }',
    pricing JSON NULL COMMENT '{
        "buy": {"SD": 9.99, "HD": 14.99, "UHD": 19.99},
        "rent": {"SD": 3.99, "HD": 4.99, "UHD": 5.99}
    }',
    lastUpdated TIMESTAMP NULL,
    updateHistory JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT EpisodeDeeplinksContent_UK UNIQUE KEY (contentId, sourceId, sourceType, region),
    CONSTRAINT EpisodeDeeplinksEpisodes_FK FOREIGN KEY (contentId) 
        REFERENCES Episodes(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Scrapers Configuration
CREATE TABLE Scrapers (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    scraperId UUID NOT NULL,
    adminRefId SMALLINT UNSIGNED NULL,
    sourceSlug VARCHAR(64) NOT NULL,
    title VARCHAR(128) NOT NULL,
    scraperSrcTitle VARCHAR(128) NOT NULL,
    config JSON NULL,
    schedule JSON NULL,
    supportedTypes JSON NULL COMMENT 'Array of supported content type IDs',
    lastUpdated TIMESTAMP NULL,
    updateHistory JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT ScrapersUuid_UK UNIQUE KEY (scraperId),
    CONSTRAINT ScrapersAdmin_UK UNIQUE KEY (adminRefId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Scrapers Activity Log
CREATE TABLE ScrapersActivity (
    id BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
    scraperId UUID NOT NULL,
    runId UUID NOT NULL,
    contentType TINYINT UNSIGNED NULL,
    startTime TIMESTAMP NOT NULL,
    endTime TIMESTAMP NULL,
    itemsProcessed INT UNSIGNED DEFAULT 0,
    itemsSucceeded INT UNSIGNED DEFAULT 0,
    error TEXT NULL,
    metadata JSON NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT ScrapersActivity_FK FOREIGN KEY (scraperId) 
        REFERENCES Scrapers(scraperId) ON DELETE CASCADE,
    CONSTRAINT ScrapersActivityType_FK FOREIGN KEY (contentType)
        REFERENCES ContentTypes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Audit Log for tracking all significant changes
CREATE TABLE AuditLog (
    id BIGINT UNSIGNED AUTO_INCREMENT NOT NULL,
    entityType VARCHAR(64) NOT NULL,
    entityId UUID NOT NULL,
    action ENUM('create', 'update', 'delete', 'restore') NOT NULL,
    userId VARCHAR(64) NULL,
    changes JSON NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Drop old Deeplinks table
DROP TABLE IF EXISTS Deeplinks;

-- Indexes for better query performance
CREATE INDEX MoviesTitle_IDX USING BTREE ON Movies (title);
CREATE INDEX MoviesActive_IDX USING BTREE ON Movies (isActive);

CREATE INDEX SeriesTitle_IDX USING BTREE ON Series (title);
CREATE INDEX SeriesActive_IDX USING BTREE ON Series (isActive);

CREATE INDEX SeasonsShow_IDX USING BTREE ON Seasons (seriesContentId, seasonNumber);
CREATE INDEX SeasonsActive_IDX USING BTREE ON Seasons (isActive);

CREATE INDEX EpisodesSeason_IDX USING BTREE ON Episodes (seasonContentId, episodeNumber);
CREATE INDEX EpisodesActive_IDX USING BTREE ON Episodes (isActive);

CREATE INDEX MoviesMetadataImdb_IDX USING BTREE ON MoviesMetadata (imdbId);
CREATE INDEX MoviesMetadataRg_IDX USING BTREE ON MoviesMetadata (rgId);

CREATE INDEX SeriesMetadataImdb_IDX USING BTREE ON SeriesMetadata (imdbId);
CREATE INDEX SeriesMetadataRg_IDX USING BTREE ON SeriesMetadata (rgId);
CREATE INDEX SeriesMetadataTitle_IDX USING BTREE ON SeriesMetadata (title);

CREATE INDEX SeasonsMetadataShow_IDX USING BTREE ON SeasonsMetadata (seriesContentId);

CREATE INDEX EpisodesMetadataSeason_IDX USING BTREE ON EpisodesMetadata (seasonContentId);

CREATE INDEX MovieDeeplinksContent_IDX USING BTREE ON MovieDeeplinks (contentId);
CREATE INDEX MovieDeeplinksSource_IDX USING BTREE ON MovieDeeplinks (sourceId, sourceType, region);

CREATE INDEX EpisodeDeeplinksContent_IDX USING BTREE ON EpisodeDeeplinks (contentId);
CREATE INDEX EpisodeDeeplinksSource_IDX USING BTREE ON EpisodeDeeplinks (sourceId, sourceType, region);

CREATE INDEX ScrapersActivityRun_IDX USING BTREE ON ScrapersActivity (runId);
CREATE INDEX ScrapersActivityTime_IDX USING BTREE ON ScrapersActivity (startTime);

CREATE INDEX AuditLogEntity_IDX USING BTREE ON AuditLog (entityType, entityId);
CREATE INDEX AuditLogTime_IDX USING BTREE ON AuditLog (created_at);

DELIMITER //

-- Triggers for Movies table
CREATE TRIGGER Movies_Audit_Insert AFTER INSERT ON Movies
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
END //

CREATE TRIGGER Movies_Audit_Update AFTER UPDATE ON Movies
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
END //

-- Triggers for Series table
CREATE TRIGGER Series_Audit_Insert AFTER INSERT ON Series
FOR EACH ROW
BEGIN
    INSERT INTO AuditLog (entityType, entityId, action, changes)
    VALUES ('Series', NEW.contentId, 'create',
        JSON_OBJECT(
            'contentId', NEW.contentId,
            'title', NEW.title,
            'isActive', NEW.isActive
        )
    );
END //

CREATE TRIGGER Series_Audit_Update AFTER UPDATE ON Series
FOR EACH ROW
BEGIN
    IF OLD.title != NEW.title OR OLD.isActive != NEW.isActive OR OLD.isDupe != NEW.isDupe THEN
        INSERT INTO AuditLog (entityType, entityId, action, changes)
        VALUES ('Series', NEW.contentId, 'update',
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
END //

-- Create trigger to update Series.seasonContentIds when a new season is added
CREATE TRIGGER Seasons_Series_Insert AFTER INSERT ON Seasons
FOR EACH ROW
BEGIN
    UPDATE Series 
    SET seasonContentIds = JSON_ARRAY_APPEND(
        COALESCE(seasonContentIds, JSON_ARRAY()),
        '$',
        NEW.contentId
    ),
    totalSeasons = JSON_LENGTH(
        JSON_ARRAY_APPEND(
            COALESCE(seasonContentIds, JSON_ARRAY()),
            '$',
            NEW.contentId
        )
    )
    WHERE contentId = NEW.seriesContentId;
END //

-- Create trigger to update Series.seasonContentIds when a season is deleted
CREATE TRIGGER Seasons_Series_Delete AFTER DELETE ON Seasons
FOR EACH ROW
BEGIN
    UPDATE Series 
    SET seasonContentIds = JSON_REMOVE(
        seasonContentIds,
        JSON_UNQUOTE(JSON_SEARCH(seasonContentIds, 'one', OLD.contentId))
    ),
    totalSeasons = JSON_LENGTH(
        JSON_REMOVE(
            seasonContentIds,
            JSON_UNQUOTE(JSON_SEARCH(seasonContentIds, 'one', OLD.contentId))
        )
    )
    WHERE contentId = OLD.seriesContentId;
END //

-- Create trigger to update Seasons.episodeContentIds when a new episode is added
CREATE TRIGGER Episodes_Seasons_Insert AFTER INSERT ON Episodes
FOR EACH ROW
BEGIN
    UPDATE Seasons 
    SET episodeContentIds = JSON_ARRAY_APPEND(
        COALESCE(episodeContentIds, JSON_ARRAY()),
        '$',
        NEW.contentId
    ),
    episodeCount = JSON_LENGTH(
        JSON_ARRAY_APPEND(
            COALESCE(episodeContentIds, JSON_ARRAY()),
            '$',
            NEW.contentId
        )
    )
    WHERE contentId = NEW.seasonContentId;
END //

-- Create trigger to update Seasons.episodeContentIds when an episode is deleted
CREATE TRIGGER Episodes_Seasons_Delete AFTER DELETE ON Episodes
FOR EACH ROW
BEGIN
    UPDATE Seasons 
    SET episodeContentIds = JSON_REMOVE(
        episodeContentIds,
        JSON_UNQUOTE(JSON_SEARCH(episodeContentIds, 'one', OLD.contentId))
    ),
    episodeCount = JSON_LENGTH(
        JSON_REMOVE(
            episodeContentIds,
            JSON_UNQUOTE(JSON_SEARCH(episodeContentIds, 'one', OLD.contentId))
        )
    )
    WHERE contentId = OLD.seasonContentId;
END //

-- Sample data generation procedure
DROP PROCEDURE IF EXISTS InsertRandomData //

CREATE PROCEDURE InsertRandomData()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE movie_content_id UUID;
    DECLARE series_content_id UUID;
    DECLARE season_content_id UUID;
    DECLARE episode_content_id UUID;
    DECLARE movie_deeplink_ref_id UUID;
    DECLARE episode_deeplink_ref_id UUID;
    
    WHILE i <= 100000 DO
        -- Generate UUIDs
        SET movie_content_id = UUID();
        SET series_content_id = UUID();
        SET season_content_id = UUID();
        SET episode_content_id = UUID();
        SET movie_deeplink_ref_id = UUID();
        SET episode_deeplink_ref_id = UUID();
        
        -- Insert a movie and its related records
        INSERT INTO Movies (contentId, deeplinkRefId, title)
        VALUES (movie_content_id, movie_deeplink_ref_id, CONCAT('Movie ', i));
        
        INSERT INTO MoviesMetadata (contentId, imdbId, rgId)
        VALUES (movie_content_id, CONCAT('tt', LPAD(i, 7, '0')), CONCAT('rg', i));
        
        INSERT INTO MovieDeeplinks (contentId, sourceId, sourceType, region)
        VALUES (movie_content_id, 69, 'tmdb', 'US');
        
        -- Insert a series and its related records
        INSERT INTO Series (contentId, title)
        VALUES (series_content_id, CONCAT('TV Series ', i));
        
        INSERT INTO SeriesMetadata (contentId, imdbId, rgId)
        VALUES (series_content_id, CONCAT('tt', LPAD(i+1000, 7, '0')), CONCAT('rg', i+1000));
        
        -- Insert a season
        INSERT INTO Seasons (contentId, seriesContentId, seasonNumber)
        VALUES (season_content_id, series_content_id, 1);
        
        INSERT INTO SeasonsMetadata (contentId, seriesContentId, tmdbId)
        VALUES (season_content_id, series_content_id, i);
        
        -- Insert an episode
        INSERT INTO Episodes (contentId, deeplinkRefId, seasonContentId, episodeNumber, title)
        VALUES (episode_content_id, episode_deeplink_ref_id, season_content_id, 1, CONCAT('Episode ', i));
        
        INSERT INTO EpisodesMetadata (contentId, seasonContentId, imdbId, rgId)
        VALUES (episode_content_id, season_content_id, CONCAT('tt', LPAD(i+2000, 7, '0')), CONCAT('rg', i+2000));
        
        INSERT INTO EpisodeDeeplinks (contentId, sourceId, sourceType, region)
        VALUES (episode_content_id, 69, 'tmdb', 'US');
        
        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;

CALL InsertRandomData();
