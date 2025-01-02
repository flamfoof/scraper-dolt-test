use Tmdb;

DELIMITER //



CREATE OR REPLACE PROCEDURE InsertRandomData()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE movie_content_id UUID;
    DECLARE series_content_id UUID;
    DECLARE season_content_id UUID;
    DECLARE episode_content_id UUID;
    DECLARE movie_deeplink_id UUID;
    DECLARE episode_deeplink_id UUID;
    DECLARE movie_release_date DATE;
    DECLARE series_release_date DATE;
    DECLARE episode_release_date DATE;
    
    WHILE i <= 10 DO
        -- Generate UUIDs
        SET movie_content_id = UUID();
        SET series_content_id = UUID();
        SET season_content_id = UUID();
        SET episode_content_id = UUID();
        SET movie_deeplink_id = UUID();
        SET episode_deeplink_id = UUID();
        
        SET movie_release_date = DATE_ADD('1990-01-01', 
            INTERVAL FLOOR(RAND() * DATEDIFF('2024-12-31', '1990-01-01')) DAY);
        SET series_release_date = DATE_ADD('1990-01-01', 
            INTERVAL FLOOR(RAND() * DATEDIFF('2024-12-31', '1990-01-01')) DAY);
        SET episode_release_date = DATE_ADD(series_release_date, 
            INTERVAL FLOOR(RAND() * 365) DAY);

        -- Insert a movie and its related records
        INSERT INTO Movies (contentId, title, tmdbId, releaseDate, isActive)
        VALUES (movie_content_id, CONCAT('Movie ', i), i+1000, movie_release_date, true);
        
        -- Create multiple deeplinks for the same movie with different sources
        INSERT INTO MoviesDeeplinks (
            contentId, 
            contentRefId, 
            releaseDate,
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
                movie_release_date,
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
                movie_release_date,
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
        INSERT INTO Series (contentId, title, tmdbId, releaseDate)
        VALUES (series_content_id, CONCAT('TV Series ', i), i+1000, series_release_date);
        
        -- Insert a season
        INSERT INTO Seasons (contentId, contentRefId, seasonNumber)
        VALUES (season_content_id, series_content_id, 1);
        
        -- Insert an episode
        INSERT INTO Episodes (contentId, contentRefId, episodeNumber, title, tmdbId, releaseDate)
        VALUES (episode_content_id, season_content_id, 1, CONCAT('Episode ', i), i+1000, episode_release_date);
        
        -- Create multiple deeplinks for the same episode with different sources
        INSERT INTO SeriesDeeplinks (
            contentId, 
            contentRefId, 
            releaseDate,
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
                episode_release_date,
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
                episode_release_date,
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
        INSERT INTO SeriesPrices (
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

DELIMITER ;

CALL InsertRandomData();

DELIMITER //

CREATE OR REPLACE PROCEDURE TestTableUpdatesWithCount(IN update_count INT)
BEGIN
    -- Create temporary tables with IDs to update
    CREATE TEMPORARY TABLE tmp_movies_original AS 
    SELECT contentId, title, runtime, releaseDate, isActive 
    FROM (
        SELECT contentId, title, runtime, releaseDate, isActive,
               @row_num := @row_num + 1 AS row_num
        FROM Movies, (SELECT @row_num := 0) AS r
    ) ranked
    
    WHERE row_num <= update_count;
    
    CREATE TEMPORARY TABLE tmp_series_original AS 
    SELECT contentId, title, totalSeasons, releaseDate, isActive 
    FROM (
        SELECT contentId, title, totalSeasons, releaseDate, isActive,
               @row_num2 := @row_num2 + 1 AS row_num
        FROM Series, (SELECT @row_num2 := 0) AS r
    ) ranked
    WHERE row_num <= update_count;
    
    CREATE TEMPORARY TABLE tmp_episodes_original AS 
    SELECT contentId, title, episodeNumber, runtime, releaseDate 
    FROM (
        SELECT contentId, title, episodeNumber, runtime, releaseDate,
               @row_num3 := @row_num3 + 1 AS row_num
        FROM Episodes, (SELECT @row_num3 := 0) AS r
    ) ranked
    WHERE row_num <= update_count;

    CREATE TEMPORARY TABLE tmp_movies_deeplinks_ids AS 
    SELECT contentId 
    FROM (
        SELECT contentId,
               @row_num5 := @row_num5 + 1 AS row_num
        FROM MoviesDeeplinks, (SELECT @row_num5 := 0) AS r
    ) ranked
    WHERE row_num <= update_count;

    CREATE TEMPORARY TABLE tmp_series_deeplinks_ids AS 
    SELECT contentId 
    FROM (
        SELECT contentId,
               @row_num6 := @row_num6 + 1 AS row_num
        FROM SeriesDeeplinks, (SELECT @row_num6 := 0) AS r
    ) ranked
    WHERE row_num <= update_count;

    CREATE TEMPORARY TABLE tmp_movies_prices_ids AS 
    SELECT contentId 
    FROM (
        SELECT contentId,
               @row_num7 := @row_num7 + 1 AS row_num
        FROM MoviesPrices, (SELECT @row_num7 := 0) AS r
    ) ranked
    WHERE row_num <= update_count;

    CREATE TEMPORARY TABLE tmp_series_prices_ids AS 
    SELECT contentId 
    FROM (
        SELECT contentId,
               @row_num8 := @row_num8 + 1 AS row_num
        FROM SeriesPrices, (SELECT @row_num8 := 0) AS r
    ) ranked
    WHERE row_num <= update_count;

    -- Test Movies updates
    UPDATE Movies 
    SET 
        title = CONCAT(title, ' - Extended Cut'),
        runtime = runtime + 10,
        releaseDate = DATE_ADD(releaseDate, INTERVAL 1 DAY),
        isActive = NOT isActive
    WHERE contentId IN (SELECT contentId FROM tmp_movies_original);

    -- Test Series updates
    UPDATE Series 
    SET 
        title = CONCAT(title, ' - Remastered'),
        totalSeasons = totalSeasons + 1,
        releaseDate = DATE_ADD(releaseDate, INTERVAL 1 YEAR),
        isActive = NOT isActive
    WHERE contentId IN (SELECT contentId FROM tmp_series_original);

    -- Test Episodes updates
    UPDATE Episodes 
    SET 
        title = CONCAT(title, " - Director's Cut"),
        episodeNumber = episodeNumber + 100,
        runtime = COALESCE(runtime, 0) + 5,
        releaseDate = DATE_ADD(releaseDate, INTERVAL 7 DAY)
    WHERE contentId IN (SELECT contentId FROM tmp_episodes_original);

    -- Test MoviesDeeplinks updates
    UPDATE MoviesDeeplinks 
    SET 
        title = CONCAT(COALESCE(title, 'Movie'), ' - New Version'),
        web = CONCAT(COALESCE(web, 'https://'), '/updated'),
        android = CONCAT(COALESCE(android, 'android://'), '/updated'),
        isActive = NOT isActive
    WHERE contentId IN (SELECT contentId FROM tmp_movies_deeplinks_ids);

    -- Test SeriesDeeplinks updates
    UPDATE SeriesDeeplinks 
    SET 
        title = CONCAT(COALESCE(title, 'Series'), ' - New Version'),
        web = CONCAT(COALESCE(web, 'https://'), '/updated'),
        android = CONCAT(COALESCE(android, 'android://'), '/updated'),
        isActive = NOT isActive
    WHERE contentId IN (SELECT contentId FROM tmp_series_deeplinks_ids);

    -- Test MoviesPrices updates
    UPDATE MoviesPrices 
    SET 
        buySD = buySD * 1.1,
        buyHD = buyHD * 1.1,
        buyUHD = buyUHD * 1.1,
        rentSD = rentSD * 1.1,
        rentHD = rentHD * 1.1,
        rentUHD = rentUHD * 1.1,
        isActive = NOT isActive
    WHERE contentId IN (SELECT contentId FROM tmp_movies_prices_ids);

    -- Test SeriesPrices updates
    UPDATE SeriesPrices 
    SET 
        buySD = buySD * 1.1,
        buyHD = buyHD * 1.1,
        buyUHD = buyUHD * 1.1,
        rentSD = rentSD * 1.1,
        rentHD = rentHD * 1.1,
        rentUHD = rentUHD * 1.1,
        seasonBuySD = seasonBuySD * 1.1,
        seasonBuyHD = seasonBuyHD * 1.1,
        seasonBuyUHD = seasonBuyUHD * 1.1,
        seasonRentSD = seasonRentSD * 1.1,
        seasonRentHD = seasonRentHD * 1.1,
        seasonRentUHD = seasonRentUHD * 1.1,
        isActive = NOT isActive
    WHERE contentId IN (SELECT contentId FROM tmp_series_prices_ids);

    -- Verify updates with original values
    SELECT 'Movies Updates' as Test, 
           m.contentId, 
           o.title as old_title, 
           m.title as new_title,
           o.runtime as old_runtime,
           m.runtime as new_runtime,
           o.isActive as old_active,
           m.isActive as new_active
    FROM Movies m
    JOIN tmp_movies_original o ON m.contentId = o.contentId;

    SELECT 'Series Updates' as Test,
           s.contentId,
           o.title as old_title,
           s.title as new_title,
           o.totalSeasons as old_seasons,
           s.totalSeasons as new_seasons,
           o.isActive as old_active,
           s.isActive as new_active
    FROM Series s
    JOIN tmp_series_original o ON s.contentId = o.contentId;

    SELECT 'Episodes Updates' as Test,
           e.contentId,
           o.title as old_title,
           e.title as new_title,
           o.episodeNumber as old_episode,
           e.episodeNumber as new_episode,
           o.runtime as old_runtime,
           e.runtime as new_runtime
    FROM Episodes e
    JOIN tmp_episodes_original o ON e.contentId = o.contentId;

    -- Clean up temporary tables
    DROP TEMPORARY TABLE IF EXISTS tmp_movies_original;
    DROP TEMPORARY TABLE IF EXISTS tmp_series_original;
    DROP TEMPORARY TABLE IF EXISTS tmp_episodes_original;
    DROP TEMPORARY TABLE IF EXISTS tmp_scrapers_ids;
    DROP TEMPORARY TABLE IF EXISTS tmp_movies_deeplinks_ids;
    DROP TEMPORARY TABLE IF EXISTS tmp_series_deeplinks_ids;
    DROP TEMPORARY TABLE IF EXISTS tmp_movies_prices_ids;
    DROP TEMPORARY TABLE IF EXISTS tmp_series_prices_ids;
END //

DELIMITER ;

-- Example usage:
CALL TestTableUpdatesWithCount(5);

-- Test partial content deletion
DELIMITER //

CREATE OR REPLACE PROCEDURE TestPartialDeletion()
BEGIN
    -- Declare variables for test data
    DECLARE content_id1 UUID;
    DECLARE content_id2 UUID;
    DECLARE season_id1 UUID;
    DECLARE season_id2 UUID;
    DECLARE episode_id1 UUID;
    DECLARE episode_id2 UUID;
    DECLARE deeplink_id1 UUID;
    DECLARE deeplink_id2 UUID;
    
    -- Start transaction
    START TRANSACTION;
    
    -- Create test data: 2 series, each with 1 season and 1 episode
    SET content_id1 = UUID_v7();
    SET content_id2 = UUID_v7();
    
    -- Insert two test series
    INSERT INTO Movies (contentId, title, isActive)
    VALUES 
        (content_id1, 'Test Movie 1', true),
        (content_id2, 'Test Movie 2', true);
    INSERT INTO Series (contentId, title, isActive)
    VALUES 
        (content_id1, 'Test Series 1', true),
        (content_id2, 'Test Series 2', true);

    
    -- Insert seasons
    SET season_id1 = UUID_v7();
    SET season_id2 = UUID_v7();
    
    INSERT INTO Seasons (contentId, contentRefId, title, seasonNumber)
    VALUES 
        (season_id1, content_id1, 'Season 1 of Series 1', 1),
        (season_id2, content_id2, 'Season 1 of Series 2', 1);
    
    -- Insert episodes
    SET episode_id1 = UUID_v7();
    SET episode_id2 = UUID_v7();
    
    INSERT INTO Episodes (contentId, contentRefId, title, episodeNumber)
    VALUES 
        (episode_id1, season_id1, 'Episode 1 of Season 1 Series 1', 1),
        (episode_id2, season_id2, 'Episode 1 of Season 1 Series 2', 1);
    
    -- Insert deeplinks
    SET deeplink_id1 = UUID_v7();
    SET deeplink_id2 = UUID_v7();

    INSERT INTO MoviesDeeplinks (contentId, contentRefId, sourceId, sourceType, title)
    VALUES 
        (deeplink_id1, content_id1, 1, 'netflix', 'Netflix Link 1'),
        (deeplink_id2, content_id2, 1, 'netflix', 'Netflix Link 2');
    
    INSERT INTO SeriesDeeplinks (contentId, contentRefId, sourceId, sourceType, title)
    VALUES 
        (deeplink_id1, episode_id1, 1, 'netflix', 'Netflix Link 1'),
        (deeplink_id2, episode_id2, 1, 'netflix', 'Netflix Link 2');
    
    -- Verify initial state
    -- SELECT COUNT(*) = 2 INTO @test_result FROM Series;
    -- CALL AssertTrue(@test_result, 'Should have 2 series');
    
    -- SELECT COUNT(*) = 2 INTO @test_result FROM Seasons;
    -- CALL AssertTrue(@test_result, 'Should have 2 seasons');
    
    -- SELECT COUNT(*) = 2 INTO @test_result FROM Episodes;
    -- CALL AssertTrue(@test_result, 'Should have 2 episodes');
    
    -- SELECT COUNT(*) = 2 INTO @test_result FROM SeriesDeeplinks;
    -- CALL AssertTrue(@test_result, 'Should have 2 deeplinks');
    -- COMMIT;
    
    -- Delete one series (should cascade to its season, episode, and deeplink)
    DELETE FROM Series WHERE contentId = content_id1;
    DELETE FROM Movies WHERE contentId = content_id1;
    -- DELETE FROM MoviesDeeplinks WHERE contentRefId = content_id1;
    -- COMMIT;
    
    -- Verify series 1 and its children are deleted
    -- SELECT COUNT(*) = 0 INTO @test_result FROM Series WHERE contentId = series_id1;
    -- CALL AssertTrue(@test_result, 'Series 1 should be deleted');
    
    -- SELECT COUNT(*) = 0 INTO @test_result FROM Seasons WHERE contentRefId = series_id1;
    -- CALL AssertTrue(@test_result, 'Season from Series 1 should be deleted');
    
    -- SELECT COUNT(*) = 0 INTO @test_result FROM Episodes WHERE contentRefId = season_id1;
    -- CALL AssertTrue(@test_result, 'Episode from Series 1 should be deleted');
    
    -- SELECT COUNT(*) = 0 INTO @test_result FROM SeriesDeeplinks WHERE contentRefId = episode_id1;
    -- CALL AssertTrue(@test_result, 'Deeplink from Series 1 should be deleted');
    
    -- -- Verify series 2 and its children still exist
    -- SELECT COUNT(*) = 1 INTO @test_result FROM Series WHERE contentId = series_id2;
    -- CALL AssertTrue(@test_result, 'Series 2 should still exist');
    
    -- SELECT COUNT(*) = 1 INTO @test_result FROM Seasons WHERE contentRefId = series_id2;
    -- CALL AssertTrue(@test_result, 'Season from Series 2 should still exist');
    
    -- SELECT COUNT(*) = 1 INTO @test_result FROM Episodes WHERE contentRefId = season_id2;
    -- CALL AssertTrue(@test_result, 'Episode from Series 2 should still exist');
    
    -- SELECT COUNT(*) = 1 INTO @test_result FROM SeriesDeeplinks WHERE contentRefId = episode_id2;
    -- CALL AssertTrue(@test_result, 'Deeplink from Series 2 should still exist');
    
    -- -- Verify Graveyard entries
    -- SELECT COUNT(*) = 1 INTO @test_result FROM Graveyard WHERE contentId = series_id1 AND contentType = 'Series';
    -- CALL AssertTrue(@test_result, 'Should have Graveyard entry for deleted series');
    
    -- SELECT COUNT(*) = 1 INTO @test_result FROM Graveyard WHERE contentId = season_id1 AND contentType = 'Seasons';
    -- CALL AssertTrue(@test_result, 'Should have Graveyard entry for deleted season');
    
    -- SELECT COUNT(*) = 1 INTO @test_result FROM Graveyard WHERE contentId = episode_id1 AND contentType = 'Episodes';
    -- CALL AssertTrue(@test_result, 'Should have Graveyard entry for deleted episode');
    
    -- SELECT COUNT(*) = 1 INTO @test_result FROM Graveyard WHERE contentId = deeplink_id1 AND contentType = 'SeriesDeeplinks';
    -- CALL AssertTrue(@test_result, 'Should have Graveyard entry for deleted deeplink');
    
    -- Cleanup
    -- ROLLBACK;
END //

DELIMITER ;

-- Run the test
CALL TestPartialDeletion();

use TaskQueue;
-- Process Queue Test Procedures
DELIMITER //
-- Test procedure that will be called by the queue
CREATE OR REPLACE PROCEDURE TestUpdateCounter(IN counter_value INT)
BEGIN
    SELECT counter_value as updated_value;
END //

-- Test procedure that will fail
CREATE OR REPLACE PROCEDURE TestFailingProcedure(IN should_fail BOOLEAN)
BEGIN
    IF should_fail THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Intentional test failure';
    END IF;
    SELECT 'Success' as result;
END //

-- Main test procedure for ProcessQueue
CREATE OR REPLACE PROCEDURE TestProcessQueue()
BEGIN
    -- Declare test variables
    DECLARE test_task_id UUID;
    DECLARE test_result BOOLEAN;
    DECLARE currentDatabase VARCHAR(64);
    
    SELECT DATABASE() INTO @dbRef;
    SET currentDatabase = @dbRef;
--     -- Clean up any existing test data
--     -- DELETE FROM TaskQueue.FailedTasks;
-- --     DELETE FROM TaskQueue.ProcessQueue;
    
    -- Test 1: Queue a simple task
    CALL TaskQueue.QueueTask(
        currentDatabase,
        'TestUpdateCounter',
        JSON_ARRAY(42),
        1,
        JSON_OBJECT('test_name', 'simple_counter_test')
    );
    
    SELECT COUNT(*) = 1 INTO test_result 
    FROM TaskQueue.ProcessQueue 
    WHERE taskType = 'TestUpdateCounter'
    AND status = 'pending';
    
    SELECT IF(test_result, 'PASS', 'FAIL') as result, 
        'Queue Simple Task' as test_name;
    
    -- Test 2: Queue a task with different priority
    CALL TaskQueue.QueueTask(
        currentDatabase,
        'TestUpdateCounter',
        JSON_ARRAY(100),
        2,
        JSON_OBJECT('test_name', 'high_priority_test')
    );

    SELECT priority = 2 INTO test_result 
    FROM TaskQueue.ProcessQueue 
    WHERE taskType = 'TestUpdateCounter' 
    ORDER BY id DESC 
    LIMIT 1;
    
    SELECT IF(test_result, 'PASS', 'FAIL') as result, 
           'Queue Priority Test' as test_name;
    
    -- Test 3: Test task failure handling
    CALL TaskQueue.QueueTask(
        currentDatabase,
        'TestFailingProcedure',
        JSON_ARRAY(true),
        1,
        JSON_OBJECT('test_name', 'failure_test')
    );
    
    -- Process the queue
    -- CALL TaskQueue.ProcessQueueItems(10);
    
    
    -- Check if task was moved to FailedQueue
    SELECT COUNT(*) >= 1 INTO test_result 
    FROM TaskQueue.FailedQueue 
    WHERE taskType = 'TestFailingProcedure'
    AND lastError IS NOT NULL;
    
    SELECT IF(test_result, 'PASS', 'FAIL') as result, 
           'Task Failure Handling Test' as test_name;
    
    -- Test 4: Test successful task completion
    SELECT COUNT(*) >= 1 INTO test_result 
    FROM TaskQueue.CompletedQueue 
    WHERE taskType = 'TestUpdateCounter';
    
    SELECT IF(test_result, 'PASS', 'FAIL') as result, 
           'Task Completion Test' as test_name;
           
    -- Test 5: Verify tasks are removed from ProcessQueue after processing
    SELECT COUNT(*) = 0 INTO test_result 
    FROM TaskQueue.ProcessQueue 
    WHERE taskType IN ('TestUpdateCounter', 'TestFailingProcedure');
    
    SELECT IF(test_result, 'PASS', 'FAIL') as result, 
           'Process Queue Cleanup Test' as test_name;
           
    -- Test 6: Verify task reference IDs are maintained
    SELECT COUNT(*) >= 1 INTO test_result 
    FROM TaskQueue.CompletedQueue c
    JOIN TaskQueue.FailedQueue f ON f.taskType = 'TestFailingProcedure'
    WHERE c.taskType = 'TestUpdateCounter'
    AND c.taskRefId IS NOT NULL
    AND f.taskRefId IS NOT NULL;
    
    SELECT IF(test_result, 'PASS', 'FAIL') as result, 
           'Task Reference ID Test' as test_name;
END //

DELIMITER ;

-- Run the ProcessQueue tests
-- CALL TestProcessQueue();

-- Switch to Scrapers database for test data generation
USE Scrapers;

DELIMITER //

-- Sample scraper data generation procedure

CREATE OR REPLACE PROCEDURE InsertScraperTestData()
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE scraper_id UUID;
    DECLARE run_id UUID;
    
    WHILE i < 5 DO
        -- Generate UUIDs
        SET scraper_id = UUID();
        
        -- Insert scraper configuration
        INSERT INTO Scrapers (
            scraperId,
            adminRefId,
            sourceSlug,
            title,
            scraperSrcTitle,
            config,
            schedule
        )
        VALUES (
            scraper_id,
            i,
            CONCAT('source-', i),
            CONCAT('Scraper ', i),
            CONCAT('Admin Scraper ', i),
            JSON_OBJECT(
                'baseUrl', CONCAT('https://api.source-', i, '.com'),
                'apiKey', CONCAT('key-', i),
                'rateLimit', 100,
                'timeout', 30000
            ),
            JSON_OBJECT(
                'frequency', 'daily',
                'startTime', '00:00',
                'endTime', '06:00',
                'daysOfWeek', JSON_ARRAY('MON', 'WED', 'FRI')
            )
        );
        
        -- Insert multiple activity records for each scraper
        SET i = i + 1;
        
        -- Completed run
        SET run_id = UUID();
        INSERT INTO ScrapersActivity (
            id,
            scraperRefId,
            runId,
            contentType,
            startTime,
            endTime,
            status,
            totalItems,
            processedItems,
            errorItems,
            metadata
        )
        VALUES (
            UUID_v7(),
            scraper_id,
            run_id,
            'movies',
            DATE_SUB(NOW(), INTERVAL i DAY),
            DATE_SUB(NOW(), INTERVAL i-1 DAY),
            'completed',
            1000,
            1000,
            0,
            JSON_OBJECT(
                'duration', '5h 30m',
                'avgProcessingTime', '19.8s',
                'peakMemoryUsage', '256MB'
            )
        );
        
        -- Failed run
        SET run_id = UUID();
        INSERT INTO ScrapersActivity (
            id,
            scraperRefId,
            runId,
            contentType,
            startTime,
            endTime,
            status,
            totalItems,
            processedItems,
            errorItems,
            error,
            metadata
        )
        VALUES (
            UUID_v7(),
            scraper_id,
            run_id,
            'series',
            DATE_SUB(NOW(), INTERVAL i+1 DAY),
            DATE_SUB(NOW(), INTERVAL i DAY),
            'failed',
            500,
            250,
            250,
            'API rate limit exceeded',
            JSON_OBJECT(
                'duration', '2h 15m',
                'avgProcessingTime', '32.4s',
                'peakMemoryUsage', '512MB',
                'lastProcessedItem', 'series-250'
            )
        );
        
        -- Currently running
        SET run_id = UUID();
        INSERT INTO ScrapersActivity (
            id,
            scraperRefId,
            runId,
            contentType,
            startTime,
            status,
            totalItems,
            processedItems,
            errorItems,
            metadata
        )
        VALUES (
            UUID_v7(),
            scraper_id,
            run_id,
            'movies',
            NOW(),
            'running',
            2000,
            500,
            10,
            JSON_OBJECT(
                'currentItem', 'movie-501',
                'avgProcessingTime', '25.6s',
                'peakMemoryUsage', '384MB'
            )
        );
    END WHILE;
END //

DELIMITER ;


-- Call the procedure to generate test data
CALL InsertScraperTestData();

-- Sample data generation procedure
DROP PROCEDURE IF EXISTS InsertRandomData;
DROP PROCEDURE IF EXISTS InsertScraperTestData;
DROP PROCEDURE IF EXISTS TestPartialDeletion;
-- DROP PROCEDURE IF EXISTS TestTableUpdatesWithCount;
-- DROP PROCEDURE IF EXISTS TestProcessQueue;
-- DROP PROCEDURE IF EXISTS TestUpdateCounter;
-- DROP PROCEDURE IF EXISTS TestFailingProcedure;
