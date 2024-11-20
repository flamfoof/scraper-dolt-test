CREATE DATABASE IF NOT EXISTS `Tmdb`;
use Tmdb;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS `ScrapersActivity`;
DROP TABLE IF EXISTS `Scrapers`;
DROP TABLE IF EXISTS `deeplinks`;
DROP TABLE IF EXISTS `MoviesMetadata`;
DROP TABLE IF EXISTS `Movies`;
SET FOREIGN_KEY_CHECKS = 1;


CREATE TABLE Movies (
	id INT UNSIGNED AUTO_INCREMENT NOT NULL,
	contentId UUID NOT NULL,
	title TINYTEXT NOT NULL,
	altTitle TINYTEXT NULL,
	releaseDate DATE NULL,
	isActive BOOL DEFAULT true NOT NULL,
	isDupe BOOL DEFAULT false NOT NULL,
	CONSTRAINT MoviesUuid_UK UNIQUE KEY (contentId),
	CONSTRAINT PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE INDEX MoviesUuid_IDX USING BTREE ON Movies (contentId);
CREATE INDEX MoviesTitle_IDX USING BTREE ON Movies (title);

CREATE TABLE `MoviesMetadata` (
	contentId UUID NULL,
	deeplinkRefId UUID NULL,
	slug TINYTEXT NULL,
	TmdbId VARCHAR(12) NULL,
	imdbId VARCHAR(12) NULL,
	rgId TINYTEXT NULL,
	title TINYTEXT NULL,
	`desc` TEXT NULL,
	lastUpdated DATETIME NULL,
	`updateHistory` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
	CONSTRAINT MoviesMetadataTmdb_UK UNIQUE KEY (TmdbId),
	CONSTRAINT MoviesMetadataDlid_UK UNIQUE KEY (deeplinkRefId),
	CONSTRAINT PRIMARY KEY (contentId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
ALTER TABLE MoviesMetadata ADD CONSTRAINT MoviesMetadataCid_CFK FOREIGN KEY MoviesMetadataCid_FK (contentId) REFERENCES Movies(contentId) ON DELETE CASCADE ON UPDATE CASCADE;



CREATE TABLE `Deeplinks` (
	contentId UUID NOT NULL,
	deeplinkRefId UUID NOT NULL,
	sourceId SMALLINT DEFAULT 0 NOT NULL,
	sourceType TINYTEXT DEFAULT ''NOT NULL,
	originSource ENUM ('none', 'freecast', 'gracenote', 'reelgood') DEFAULT 'none' NOT NULL,
	region TINYTEXT NULL,
	web TEXT DEFAULT NULL,
	android TEXT DEFAULT NULL,
	ios TEXT DEFAULT NULL,
	androidTv TEXT DEFAULT NULL,
	fireTv TEXT DEFAULT NULL,
	lg TEXT DEFAULT NULL,
	samsung TEXT DEFAULT NULL,
	tvOS TEXT DEFAULT NULL,
	lastUpdated DATETIME NULL,
	updateHistory longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
	isActive BOOL DEFAULT true NOT NULL,
	CONSTRAINT DeeplinksDlid_UK UNIQUE KEY (deeplinkRefId),
	CONSTRAINT PRIMARY KEY (contentId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
ALTER TABLE Deeplinks ADD CONSTRAINT DeeplinksMoviesMetadata_FK FOREIGN KEY (deeplinkRefId) REFERENCES Tmdb.MoviesMetadata(deeplinkRefId) ON DELETE CASCADE ON UPDATE CASCADE;


CREATE TABLE `Scrapers` (
	scraperId UUID NOT NULL,
	adminRefId SMALLINT NULL,
	sourceSlug TINYTEXT NOT NULL,
	title TINYTEXT NOT NULL,
	scraperSrcTitle TINYTEXT NOT NULL,
	lastUpdated DATETIME NULL,
	updateHistory longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
	CONSTRAINT PRIMARY KEY (scraperId, adminRefId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE `ScrapersActivity` (
	scraperId UUID NOT NULL,
	title TINYTEXT NOT NULL,
	lastRun DATETIME NULL,
	lastRunStatus TINYTEXT NULL,
	currentRun DATETIME NULL,
	currentRunStatus TINYTEXT NULL,
	`message` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
	updateHistory longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL,
	isActive BOOL DEFAULT true NOT NULL,
	CONSTRAINT PRIMARY KEY (scraperId)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
ALTER TABLE Deeplinks ADD CONSTRAINT ScrapersActivity_FK FOREIGN KEY (deeplinkRefId) REFERENCES Tmdb.MoviesMetadata(deeplinkRefId) ON DELETE CASCADE ON UPDATE SET DEFAULT;


-- Triggers for testing
DELIMITER //
//
CREATE TRIGGER NewMovies
AFTER INSERT ON Movies
FOR EACH row
BEGIN
	set 
		@contentId = new.contentId,
		@title = new.title;
		
	INSERT INTO MoviesMetadata (contentid, deeplinkRefId, title, lastUpdated) VALUES (@contentId, UUID(), @title, NOW());
END//

CREATE TRIGGER NewMovieMetadata
AFTER INSERT ON MoviesMetadata
FOR EACH row
BEGIN
	set  
		@contentId = new.contentId,
		@Dlid = new.deeplinkRefId;
	
	INSERT INTO Deeplinks (contentid, deeplinkRefId, lastUpdated)
	VALUES (@contentId, @Dlid, NOW());
END//

-- Create large random sample of movies data
DROP PROCEDURE IF EXISTS InsertRandomData; //
CREATE PROCEDURE InsertRandomData()
BEGIN
	DECLARE i INT DEFAULT 1;
	WHILE i <= 100000 DO
		INSERT INTO Movies (contentId, title)
		VALUES (UUID(), RAND() * 100000);
		SET i = i + 1;
	END WHILE;
END //
-- CALL InsertRandomData(); //
-- SELECT * FROM Movies ORDER BY id DESC LIMIT 50; 

