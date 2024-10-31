#!/bin/bash
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root"
    # Attempt to re-run with sudo
    exec sudo "$0" "$@"
    exit
fi

# Stop the existing MariaDB service (if running)
sudo systemctl stop mariadb

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

# Initialize the MySQL data directory
mysql_install_db -c mariadb_local.ini -p admin 

# Start the MariaDB server
mysqld --defaults-file="mariadb_local.ini" --console