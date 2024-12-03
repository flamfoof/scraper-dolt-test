DELIMITER //

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
        INSERT INTO Movies (contentId, title, tmdbId, isActive)
        VALUES (movie_content_id, CONCAT('Movie ', i), i+1000, true);
        
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

CALL InsertRandomData(); //

DELIMITER ;