CREATE DATABASE IF NOT EXISTS `Tmdb`;
USE Tmdb;

DELIMITER //

CREATE OR REPLACE PROCEDURE InitializeAuditLog()
BEGIN
    -- Fill the AuditLog table with existing table data
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, tableName, 'create', 'system', 'system', JSON_OBJECT() FROM Movies;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, tableName, 'create', 'system', 'system', JSON_OBJECT() FROM Series;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, tableName, 'create', 'system', 'system', JSON_OBJECT() FROM Seasons;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, tableName, 'create', 'system', 'system', JSON_OBJECT() FROM Episodes;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, tableName, 'create', 'system', 'system', JSON_OBJECT() FROM MoviesDeeplinks;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, tableName, 'create', 'system', 'system', JSON_OBJECT() FROM SeriesDeeplinks;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, tableName, 'create', 'system', 'system', JSON_OBJECT() FROM MoviesPrices;
    INSERT INTO AuditLog (id, contentRefId, tableName, action, username, appContext, newData)
    SELECT UUID_v7(), contentId, tableName, 'create', 'system', 'system', JSON_OBJECT() FROM SeriesPrices;
END //