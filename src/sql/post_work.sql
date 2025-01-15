CREATE DATABASE IF NOT EXISTS `Tmdb`;
USE Tmdb;

DELIMITER //

CREATE OR REPLACE PROCEDURE InitializeAuditLog()
BEGIN
    -- Fill the AuditLog table with existing table data
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT 
        UUID_v7(), 
        contentId, 
        'Movies', 
        'create', 
        'system', 
        'system', 
        GetContentDataJSON(JSON_OBJECT(
            'contentId', contentId,
            'tmdbId', tmdbId,
            'imdbId', imdbId,
            'rgId', rgId,
            'titleId', titleId,
            'title', title,
            'altTitle', altTitle,
            'description', description,
            'runtime', runtime,
            'releaseDate', releaseDate,
            'posterPath', posterPath,
            'backdropPath', backdropPath,
            'popularity', popularity,
            'voteAverage', voteAverage,
            'voteCount', voteCount,
            'genres', genres,
            'keywords', keywords,
            'cast', cast,
            'crew', crew,
            'productionCompanies', productionCompanies,
            'region', region
        ), FALSE) 
    FROM Movies;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, "Series", 'create', 'system', 'system', 
        GetContentDataJSON(JSON_OBJECT(
            'contentId', contentId,
            'title', title,
            'tmdbId', tmdbId,
            'imdbId', imdbId,
            'rgId', rgId,
            'description', description,
            'releaseDate', releaseDate,
            'posterPath', posterPath,
            'backdropPath', backdropPath,
            'voteAverage', voteAverage,
            'voteCount', voteCount,
            'totalSeasons', totalSeasons,
            'totalEpisodes', totalEpisodes
        ), FALSE) 
        FROM Series;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, "Seasons", 'create', 'system', 'system', 
        GetContentDataJSON(JSON_OBJECT(
            'contentId', contentId,
            'contentRefId', contentRefId,
            'title', title,
            'seasonNumber', seasonNumber,
            'description', description,
            'releaseDate', releaseDate,
            'posterPath', posterPath,
            'episodeCount', episodeCount
        ), FALSE) 
        FROM Seasons;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, "Episodes", 'create', 'system', 'system', 
        GetContentDataJSON(JSON_OBJECT(
            'contentId', contentId,
            'contentRefId', contentRefId,
            'title', title,
            'altTitle', altTitle,
            'episodeNumber', episodeNumber,
            'description', description,
            'releaseDate', releaseDate,
            'runtime', runtime,
            'voteAverage', voteAverage,
            'voteCount', voteCount
        ), FALSE) 
        FROM Episodes;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, "MoviesDeeplinks", 'create', 'system', 'system', 
        GetContentDataJSON(JSON_OBJECT(
            'contentId', contentId,
            'contentRefId', contentRefId,
            'tmdbId', tmdbId,
            'title', title,
            'altTitle', altTitle,
            'releaseDate', releaseDate,
            'altReleaseDate', altReleaseDate,
            'sourceId', sourceId,
            'sourceType', sourceType,
            'originSource', originSource,
            'region', region,
            'web', web,
            'android', android,
            'iOS', iOS,
            'androidTv', androidTv,
            'fireTv', fireTv,
            'lg', lg,
            'samsung', samsung,
            'tvOS', tvOS,
            'roku', roku
        ), FALSE) 
        FROM MoviesDeeplinks;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, "SeriesDeeplinks", 'create', 'system', 'system', 
        GetContentDataJSON(JSON_OBJECT(
            'contentId', contentId,
            'contentRefId', contentRefId,
            'title', title,
            'sourceId', sourceId,
            'sourceType', sourceType,
            'originSource', originSource,
            'region', region,
            'web', web,
            'android', android,
            'iOS', iOS,
            'androidTv', androidTv,
            'fireTv', fireTv,
            'lg', lg,
            'samsung', samsung,
            'tvOS', tvOS,
            'roku', roku,
            'isActive', isActive,
            'tmdbId', tmdbId
        ), FALSE) 
        FROM SeriesDeeplinks;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, "MoviesPrices", 'create', 'system', 'system', 
        GetContentDataJSON(JSON_OBJECT(
            'contentId', contentId,
            'contentRefId', contentRefId,
            'region', region,
            'buySD', buySD,
            'buyHD', buyHD,
            'buyUHD', buyUHD,
            'rentSD', rentSD,
            'rentHD', rentHD,
            'rentUHD', rentUHD
        ), FALSE) 
        FROM MoviesPrices;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, "SeriesPrices", 'create', 'system', 'system', 
        GetContentDataJSON(JSON_OBJECT(
            'contentId', contentId,
            'contentRefId', contentRefId,
            'region', region,
            'buySD', buySD,
            'buyHD', buyHD,
            'buyUHD', buyUHD,
            'rentSD', rentSD,
            'rentHD', rentHD,
            'rentUHD', rentUHD,
            'seriesBuySD', seriesBuySD,
            'seriesBuyHD', seriesBuyHD,
            'seriesBuyUHD', seriesBuyUHD,
            'seriesRentSD', seriesRentSD,
            'seriesRentHD', seriesRentHD,
            'seriesRentUHD', seriesRentUHD,
            'seasonBuySD', seasonBuySD,
            'seasonBuyHD', seasonBuyHD,
            'seasonBuyUHD', seasonBuyUHD,
            'seasonRentSD', seasonRentSD,
            'seasonRentHD', seasonRentHD,
            'seasonRentUHD', seasonRentUHD
        ), FALSE) 
        FROM SeriesPrices;
END //
