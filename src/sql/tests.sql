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
        INSERT INTO MoviesDeeplinks (
            contentId, 
            contentRefId, 
            sourceId, 
            sourceType, 
            originSource, 
            region,
            web,
            android,
            iOS,
            androidTv,
            fireTv,
            lg,
            samsung,
            tvOS,
            roku
        )
        VALUES 
            (
                movie_deeplink_id, 
                movie_content_id, 
                69, 
                'didney-world', 
                'tmdb', 
                'US',
                'https://example.com/watch/movie-123',
                'android-app://com.example/watch/movie-123',
                'example://watch/movie-123',
                'android-tv://com.example/watch/movie-123',
                'amzn://apps/android?asin=B01234567',
                'lgwebos://watch/movie-123',
                'samsung-tizen://watch/movie-123',
                'com.example.tv://watch/movie-123',
                'https://example.com/watch/movie-123'
            ),
            (
                UUID(), 
                movie_content_id, 
                69, 
                'fidney-world', 
                'freecast', 
                'US',
                'https://fidney.com/watch/movie-123',
                'android-app://com.fidney/watch/movie-123',
                'fidney://watch/movie-123',
                'android-tv://com.fidney/watch/movie-123',
                'amzn://apps/android?asin=B01234567',
                'lgwebos://watch/movie-123',
                'samsung-tizen://watch/movie-123',
                'com.fidney.tv://watch/movie-123',
                'https://fidney.com/watch/movie-123'
            );
        
        -- Insert prices for movies
        INSERT INTO MoviesPrices (
            contentId,
            contentRefId,
            region,
            -- Buy prices
            buySD,
            buyHD,
            buyUHD,
            -- Rental prices
            rentSD,
            rentHD,
            rentUHD
        )
        VALUES 
            (
                UUID(),
                movie_deeplink_id,
                'US',
                9.99,  -- buySD
                14.99, -- buyHD
                19.99, -- buyUHD
                3.99,  -- rentSD
                4.99,  -- rentHD
                5.99   -- rentUHD
            );
        
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
        INSERT INTO EpisodesDeeplinks (
            contentId, 
            contentRefId, 
            sourceId, 
            sourceType, 
            originSource, 
            region,
            web,
            android,
            iOS,
            androidTv,
            fireTv,
            lg,
            samsung,
            tvOS,
            roku
        )
        VALUES 
            (
                episode_deeplink_id, 
                episode_content_id, 
                69, 
                'didney-world', 
                'tmdb', 
                'US',
                'https://example.com/watch/episode-123',
                'android-app://com.example/watch/episode-123',
                'example://watch/episode-123',
                'android-tv://com.example/watch/episode-123',
                'amzn://apps/android?asin=B01234567',
                'lgwebos://watch/episode-123',
                'samsung-tizen://watch/episode-123',
                'com.example.tv://watch/episode-123',
                'https://example.com/watch/episode-123'
            ),
            (
                UUID(), 
                episode_content_id, 
                69, 
                'fidney-world', 
                'freecast', 
                'US',
                'https://fidney.com/watch/episode-123',
                'android-app://com.fidney/watch/episode-123',
                'fidney://watch/episode-123',
                'android-tv://com.fidney/watch/episode-123',
                'amzn://apps/android?asin=B01234567',
                'lgwebos://watch/episode-123',
                'samsung-tizen://watch/episode-123',
                'com.fidney.tv://watch/episode-123',
                'https://fidney.com/watch/episode-123'
            );
        
        -- Insert prices for episodes and series
        INSERT INTO EpisodesPrices (
            contentId,
            contentRefId,
            region,
            -- Buy prices
            buySD,
            buyHD,
            buyUHD,
            -- Rental prices
            rentSD,
            rentHD,
            rentUHD,
            -- Series buy prices
            seriesBuySD,
            seriesBuyHD,
            seriesBuyUHD,
            -- Series rental prices
            seriesRentSD,
            seriesRentHD,
            seriesRentUHD,
            -- Season buy prices
            seasonBuySD,
            seasonBuyHD,
            seasonBuyUHD,
            -- Season rental prices
            seasonRentSD,
            seasonRentHD,
            seasonRentUHD
        )
        VALUES 
            (
                UUID(),
                episode_deeplink_id,
                'US',
                1.99,   -- buySD (episode)
                2.99,   -- buyHD (episode)
                3.99,   -- buyUHD (episode)
                0.99,   -- rentSD (episode)
                1.99,   -- rentHD (episode)
                2.99,   -- rentUHD (episode)
                29.99,  -- seriesBuySD
                39.99,  -- seriesBuyHD
                49.99,  -- seriesBuyUHD
                19.99,  -- seriesRentSD
                24.99,  -- seriesRentHD
                29.99,  -- seriesRentUHD
                14.99,  -- seasonBuySD
                19.99,  -- seasonBuyHD
                24.99,  -- seasonBuyUHD
                9.99,   -- seasonRentSD
                14.99,  -- seasonRentHD
                19.99   -- seasonRentUHD
            );
        
        SET i = i + 1;
    END WHILE;
END //

CALL InsertRandomData(); //

DELIMITER ;