#!/bin/bash

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   sudo -E "$0"
   exit 0
fi

# Change to parent directory
cd ..

# Stop MariaDB service if it exists
sudo systemctl stop mariadb
sudo systemctl disable mariadb

# Remove the old MySQL data directory
rm -rf mysql

# Create the new MySQL data directory
mkdir -p mysql/data mysql/logs

# Create the my.cnf configuration file
cat > my.cnf << EOF
[mysqld]
log-bin = mysql-bin
server-id = 2
port = 3307
datadir = "./mysql/data"
socket = "./mysql/mysql.sock"
log-error = "./mysql/logs/error.log"
slow_query_log_file = "./mysql/logs/slow_query.log"
slow_query_log = 1
innodb_buffer_pool_size = 256M
innodb_log_file_size = 50M
max_connections = 100
innodb_flush_log_at_trx_commit = 2

[client]
plugin-dir = "$HOME/scoop/apps/mariadb/current/lib/plugin"
EOF

# Initialize the MySQL data directory and install the service
mysql_install_db --user=mysql --datadir="./mysql" --basedir="/usr/local/mysql" --console
sudo systemctl enable mariadb

# Start the MariaDB service
sudo systemctl start mariadb