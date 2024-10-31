#!/bin/bash

# Check if script is run as root
if [ "$EUID" -ne 0 ]; then 
    echo "This script must be run as root"
    # Attempt to re-run with sudo
    exec sudo "$0" "$@"
    exit
fi

# Change directory up one level
cd ..

# Stop and remove MariaDB service if it exists
if systemctl list-units --full -all | grep -q "mariadb.service"; then
    systemctl stop mariadb.service
    systemctl disable mariadb.service
fi

# Remove MariaDB if it was installed as a system service
if command -v mysqld >/dev/null 2>&1; then
    if [ -f "/etc/init.d/mariadb" ]; then
        /etc/init.d/mariadb stop
        update-rc.d -f mariadb remove
    fi
fi

# Install MariaDB database files
mysql_install_db --datadir=/var/lib/mysql --defaults-file="mariadb_local.ini" --user=mysql

# Start MariaDB with specified configuration
mysqld --defaults-file="mariadb_local.ini" --console