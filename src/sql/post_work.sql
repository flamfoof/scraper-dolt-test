CREATE DATABASE IF NOT EXISTS `Tmdb`;
USE Tmdb;

DELIMITER //

-- CREATE OR REPLACE PROCEDURE InitializeAuditLog()
-- BEGIN
--     -- Fill the AuditLog table with existing table data
--     INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
--     SELECT 
--         UUID_v7(), 
--         contentId, 
--         'Movies', 
--         'create', 
--         'system', 
--         'system', 
--         GetContentDataJSON(JSON_OBJECT(
--             'contentId', contentId,
--             'tmdbId', tmdbId,
--             'imdbId', imdbId,
--             'rgId', rgId,
--             'titleId', titleId,
--             'title', title,
--             'altTitle', altTitle,
--             'description', description,
--             'runtime', runtime,
--             'releaseDate', releaseDate,
--             'posterPath', posterPath,
--             'backdropPath', backdropPath,
--             'popularity', popularity,
--             'voteAverage', voteAverage,
--             'voteCount', voteCount,
--             'genres', genres,
--             'keywords', keywords,
--             'cast', cast,
--             'crew', crew,
--             'productionCompanies', productionCompanies,
--             'region', region
--         ), TRUE) 
--     FROM Movies;
--     INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
--     SELECT UUID_v7(), contentId, "Series", 'create', 'system', 'system', JSON_OBJECT() FROM Series;
--     INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
--     SELECT UUID_v7(), contentId, "Seasons", 'create', 'system', 'system', JSON_OBJECT() FROM Seasons;
--     INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
--     SELECT UUID_v7(), contentId, "Episodes", 'create', 'system', 'system', JSON_OBJECT() FROM Episodes;
--     INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
--     SELECT UUID_v7(), contentId, "MoviesDeeplinks", 'create', 'system', 'system', JSON_OBJECT() FROM MoviesDeeplinks;
--     INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
--     SELECT UUID_v7(), contentId, "SeriesDeeplinks", 'create', 'system', 'system', JSON_OBJECT() FROM SeriesDeeplinks;
--     INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
--     SELECT UUID_v7(), contentId, "MoviesPrices", 'create', 'system', 'system', JSON_OBJECT() FROM MoviesPrices;
--     INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
--     SELECT UUID_v7(), contentId, "SeriesPrices", 'create', 'system', 'system', JSON_OBJECT() FROM SeriesPrices;
-- END //