#!/bin/bash

# Navigate to the parent directory
cd ..

# Get the current directory and user directory
currDir=$(pwd)
userDir="$HOME"

# Create necessary directories
mkdir -p mysql/data mysql/logs

# Create the my.cnf configuration file
cat > my.cnf << EOF
[mysqld]
# Uncomment and set the following if needed
# log-bin = mysql-bin
# server-id = 2
port = 3307
datadir = "$currDir/mysql/data"
log-error = "$currDir/mysql/logs/error.log"
slow_query_log_file = "$currDir/mysql/logs/slow_query.log"
# slow_query_log = 1
innodb_buffer_pool_size = 256M
innodb_log_file_size = 50M
max_connections = 100
innodb_flush_log_at_trx_commit = 2

[client]
plugin-dir = "$userDir/scoop/apps/mariadb/current/lib/plugin"
EOF

echo "Creating the local config file: my.cnf"

# Start the MariaDB server
mysqld.exe --defaults-file=my.cnf --console