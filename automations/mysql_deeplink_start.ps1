SET-LOCATION ..
mysql_install_db -c mariadb_local.ini -p admin 
mysqld --defaults-file="mariadb_local.ini" --console