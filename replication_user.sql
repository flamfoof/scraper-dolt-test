-- Connect to MariaDB on master server as root or admin user
-- Replace 'your_password' with a strong password
-- Replace 'allowed_host' with '%' for any host, or specific IP/hostname

-- Create replication user and replace password with something real.
-- Password will be kept in env
CREATE USER 'replication_user'@'%' IDENTIFIED BY 'asdf';

-- Grant replication permissions
GRANT REPLICATION SLAVE ON *.* TO 'replication_user'@'allowed_host';

-- Grant additional permissions needed for mysqldump
GRANT SELECT, SHOW VIEW, PROCESS, TRIGGER ON *.* TO 'replication_user'@'%';

-- If you need to clone specific databases only, use:
-- GRANT SELECT, SHOW VIEW, PROCESS, TRIGGER ON specific_database.* TO 'replication_user'@'allowed_host';

-- Apply privileges
FLUSH PRIVILEGES;

-- Verify user creation and privileges
SHOW GRANTS FOR 'replication_user'@'%';