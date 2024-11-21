-- Create and use the database
CREATE DATABASE IF NOT EXISTS `Tmdb`;
USE Tmdb;

-- Disable foreign key checks for clean setup
SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `ScrapersActivity`;
DROP TABLE IF EXISTS `Scrapers`;
DROP TABLE IF EXISTS `MoviesDeeplinks`;
DROP TABLE IF EXISTS `EpisodesDeeplinks`;
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

-- Core Movies table
CREATE TABLE Movies (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    tmdbId VARCHAR(20) NULL,
    title VARCHAR(255) NOT NULL,
    altTitle VARCHAR(255) NULL,
    releaseDate DATE NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    isDupe BOOLEAN DEFAULT false NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT MoviesUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT MoviesTmdb_UK UNIQUE KEY (tmdbId)
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
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT MoviesMetadataUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT MoviesMetadataTmdb_UK UNIQUE KEY (tmdbId),
    CONSTRAINT MoviesMetadataMovie_FK FOREIGN KEY (contentId) 
        REFERENCES Movies(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- TV Series table
CREATE TABLE Series (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    tmdbId VARCHAR(20) NULL,
    title VARCHAR(255) NOT NULL,
    altTitle VARCHAR(255) NULL,
    releaseDate DATE NULL,
    totalSeasons INT UNSIGNED DEFAULT 0 NULL,
    totalEpisodes INT UNSIGNED DEFAULT 0 NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    isDupe BOOLEAN DEFAULT false NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT SeriesUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT SeriesTmdb_UK UNIQUE KEY (tmdbId)
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
    productionCompanies JSON NULL,
    networks JSON NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT SeriesMetadataUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT SeriesMetadataTmdb_UK UNIQUE KEY (tmdbId),
    CONSTRAINT SeriesMetadataSeries_FK FOREIGN KEY (contentId) 
        REFERENCES Series(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seasons table
CREATE TABLE Seasons (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    contentRefId UUID NOT NULL,
    title VARCHAR(255) NULL,
    seasonNumber SMALLINT UNSIGNED DEFAULT 0 NOT NULL,
    episodeCount SMALLINT UNSIGNED DEFAULT 0 NULL,
    releaseDate DATE NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT SeasonsUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT SeasonsNumber_UK UNIQUE KEY (contentRefId, seasonNumber),
    CONSTRAINT SeasonsSeries_FK FOREIGN KEY (contentRefId) 
        REFERENCES Series(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seasons Metadata
CREATE TABLE SeasonsMetadata (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    title VARCHAR(255) NULL,
    description TEXT NULL,
    episodeCount SMALLINT UNSIGNED NULL,
    releaseDate DATE NULL,
    posterPath VARCHAR(255) NULL,
    voteAverage DECIMAL(3,1) NULL,
    voteCount INT UNSIGNED NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT SeasonsMetadataUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT SeasonsMetadataSeason_FK FOREIGN KEY (contentId) 
        REFERENCES Seasons(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episodes table
CREATE TABLE Episodes (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
    contentRefId UUID NOT NULL,
    tmdbId VARCHAR(20) NULL,
    episodeNumber SMALLINT DEFAULT -1 NOT NULL,
    title VARCHAR(255) NOT NULL,
    releaseDate DATE NULL,
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT EpisodesUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT EpisodesTmdb_UK UNIQUE KEY (tmdbId),
    CONSTRAINT EpisodesSeason_FK FOREIGN KEY (contentRefId)
        REFERENCES Seasons(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Episodes Metadata
CREATE TABLE EpisodesMetadata (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL,
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
    updateHistory JSON NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT EpisodesMetadataUuid_UK UNIQUE KEY (contentId),
    CONSTRAINT EpisodesMetadataTmdb_UK UNIQUE KEY (tmdbId),
    CONSTRAINT EpisodesMetadataEpisode_FK FOREIGN KEY (contentId)
        REFERENCES Episodes(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Movie Deeplinks table for storing platform-specific movie links
CREATE TABLE MoviesDeeplinks (
    id INT UNSIGNED AUTO_INCREMENT NOT NULL,
    contentId UUID NOT NULL COMMENT 'Reference to Movies.contentId',
    contentRefId UUID NULL COMMENT 'Reference to Movies.deeplinkRefId',
    sourceId SMALLINT UNSIGNED NOT NULL,
    sourceType VARCHAR(64) NOT NULL,
    originSource ENUM ('none', 'freecast', 'gracenote', 'reelgood', 'tmdb') DEFAULT 'none' NOT NULL,
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
    updateHistory JSON NULL,
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
    contentId UUID NOT NULL COMMENT 'Reference to Episodes.contentId',
    contentRefId UUID NULL COMMENT 'Reference to Episodes.deeplinkRefId',
    sourceId SMALLINT UNSIGNED NOT NULL,
    sourceType VARCHAR(64) NOT NULL,
    originSource ENUM ('none', 'freecast', 'gracenote', 'reelgood', 'tmdb') DEFAULT 'none' NOT NULL,
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
    updateHistory JSON NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
    isActive BOOLEAN DEFAULT true NOT NULL,
    CONSTRAINT PRIMARY KEY (id),
    CONSTRAINT EpisodesDeeplinksContent_UK UNIQUE KEY (contentId),
    CONSTRAINT EpisodesDeeplinksContentSource_UK UNIQUE KEY (contentRefId, sourceId, originSource),
    CONSTRAINT EpisodesDeeplinksContentRef_FK FOREIGN KEY (contentRefId)
        REFERENCES Episodes(contentId) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Base content type enum
CREATE TABLE ContentTypes (
    id TINYINT UNSIGNED PRIMARY KEY,
    name VARCHAR(16) NOT NULL UNIQUE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO ContentTypes (id, name) VALUES 
(1, 'movie'),
(2, 'series'),
(3, 'season'),
(4, 'episode');

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
    updateHistory JSON NULL,
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
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
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    updatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP NOT NULL,
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
    createdAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP NOT NULL,
    CONSTRAINT PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

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

CREATE INDEX MoviesMetadataContent_IDX USING BTREE ON MoviesMetadata (contentId);
CREATE INDEX SeriesMetadataContent_IDX USING BTREE ON SeriesMetadata (contentId);
CREATE INDEX SeasonsMetadataContent_IDX USING BTREE ON SeasonsMetadata (contentId);
CREATE INDEX EpisodesMetadataContent_IDX USING BTREE ON EpisodesMetadata (contentId);

CREATE INDEX SeriesMetadataTitle_IDX USING BTREE ON SeriesMetadata (title);

CREATE INDEX MoviesDeeplinksContent_IDX USING BTREE ON MoviesDeeplinks (contentId);
CREATE UNIQUE INDEX MoviesDeeplinksRefSource_UK ON MoviesDeeplinks (contentRefId, sourceId, originSource);
CREATE INDEX MoviesDeeplinksSource_IDX USING BTREE ON MoviesDeeplinks (sourceId, sourceType, region);

CREATE INDEX EpisodesDeeplinksContent_IDX USING BTREE ON EpisodesDeeplinks (contentId);
CREATE UNIQUE INDEX EpisodesDeeplinksRefSource_UK ON EpisodesDeeplinks (contentRefId, sourceId, originSource);
CREATE INDEX EpisodesDeeplinksSource_IDX USING BTREE ON EpisodesDeeplinks (sourceId, sourceType, region);

CREATE INDEX ScrapersActivityRun_IDX USING BTREE ON ScrapersActivity (runId);
CREATE INDEX ScrapersActivityTime_IDX USING BTREE ON ScrapersActivity (startTime);

CREATE INDEX AuditLogEntity_IDX USING BTREE ON AuditLog (entityType, entityId);
CREATE INDEX AuditLogTime_IDX USING BTREE ON AuditLog (createdAt);

DELIMITER //

CREATE TRIGGER NewMovies
AFTER INSERT ON Movies
FOR EACH row
BEGIN
	set 
		@contentId = new.contentId,
        @tmdbId = new.tmdbId,
		@title = new.title,
        @releaseDate = new.releaseDate;
		
	INSERT INTO MoviesMetadata (contentId, tmdbId, title, releaseDate, createdAt) VALUES (@contentId, @tmdbId, @title, @releaseDate, NOW());
END //

CREATE TRIGGER NewSeries
AFTER INSERT ON Series
FOR EACH row
BEGIN
	set 
		@contentId = new.contentId,
        @tmdbId = new.tmdbId,
		@title = new.title,
        @releaseDate = new.releaseDate;
		
	INSERT INTO SeriesMetadata (contentId, tmdbId, title, releaseDate, createdAt) VALUES (@contentId, @tmdbId, @title, @releaseDate, NOW());
END //

CREATE TRIGGER NewSeasons
AFTER INSERT ON Seasons
FOR EACH row
BEGIN
	set 
		@contentId = new.contentId,
		@title = new.title,
        @releaseDate = new.releaseDate;
		
	INSERT INTO SeasonsMetadata (contentId, title, releaseDate, createdAt) VALUES (@contentId, @title, @releaseDate, NOW());
END //

CREATE TRIGGER NewEpisodes
AFTER INSERT ON Episodes
FOR EACH row
BEGIN
	set 
		@contentId = new.contentId,
        @tmdbId = new.tmdbId,
		@title = new.title,
        @releaseDate = new.releaseDate;
		
	INSERT INTO EpisodesMetadata (contentId, tmdbId, title, releaseDate, createdAt) VALUES (@contentId, @tmdbId, @title, @releaseDate, NOW());
END //


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
    SET totalSeasons = totalSeasons + 1
    WHERE contentId = NEW.contentRefId;
END //

-- Create trigger to update Series.seasonContentIds when a season is deleted
CREATE TRIGGER Seasons_Series_Delete AFTER DELETE ON Seasons
FOR EACH ROW
BEGIN
    UPDATE Series 
    SET totalSeasons = totalSeasons - 1
    WHERE contentId = OLD.contentRefId;
END //

-- Create trigger to update Seasons.episodeContentIds when a new episode is added
CREATE TRIGGER Episodes_Seasons_Insert AFTER INSERT ON Episodes
FOR EACH ROW
BEGIN
    UPDATE Seasons 
    SET episodeCount = episodeCount + 1
    WHERE contentId = NEW.contentRefId;
END //

-- Create trigger to update Seasons.episodeContentIds when an episode is deleted
CREATE TRIGGER Episodes_Seasons_Delete AFTER DELETE ON Episodes
FOR EACH ROW
BEGIN
    UPDATE Seasons 
    SET episodeCount = episodeCount - 1
    WHERE contentId = OLD.contentRefId;
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
    DECLARE movie_deeplink_id UUID;
    DECLARE episode_deeplink_id UUID;
    
    WHILE i <= 1000 DO
        -- Generate UUIDs
        SET movie_content_id = UUID();
        SET series_content_id = UUID();
        SET season_content_id = UUID();
        SET episode_content_id = UUID();
        SET movie_deeplink_id = UUID();
        SET episode_deeplink_id = UUID();
        
        -- Insert a movie and its related records
        INSERT INTO Movies (contentId, title, tmdbId)
        VALUES (movie_content_id, CONCAT('Movie ', i), i+1000);
        
        -- Create multiple deeplinks for the same movie with different sources
        INSERT INTO MoviesDeeplinks (contentId, contentRefId, sourceId, sourceType, originSource, region, platformLinks)
        VALUES 
            (movie_deeplink_id, movie_content_id, 69, 'didney-world', 'tmdb', 'US', '{"web": "https://example.com/movie-123"}'),
            (UUID(), movie_content_id, 69, 'fidney-world', 'freecast', 'US', '{"web": "https://example.com/movie-123"}');
        
        -- Insert a series and its related records
        INSERT INTO Series (contentId, title, tmdbId)
        VALUES (series_content_id, CONCAT('TV Series ', i), i+1000);
        
        -- Insert a season
        INSERT INTO Seasons (contentId, contentRefId, seasonNumber)
        VALUES (season_content_id, series_content_id, 1);
        
        -- Insert an episode
        INSERT INTO Episodes (contentId, contentRefId, episodeNumber, title, tmdbId)
        VALUES (episode_content_id, season_content_id, 1, CONCAT('Episode ', i), i+1000);
        
        -- Create multiple deeplinks for the same episode with different sources
        INSERT INTO EpisodesDeeplinks (contentId, contentRefId, sourceId, sourceType, originSource, region, platformLinks)
        VALUES 
            (episode_deeplink_id, episode_content_id, 69, 'didney-world', 'tmdb', 'US', '{"web": "https://example.com/episode-123"}'),
            (UUID(), episode_content_id, 69, 'fidney-world', 'freecast', 'US', '{"web": "https://example.com/episode-123"}');
        
        SET i = i + 1;
    END WHILE;
END //

DELIMITER ;

CALL InsertRandomData();
