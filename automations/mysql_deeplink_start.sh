cd ..

directory="mysql/data"

if [ -d "$directory" ] && [ -n "$(ls -A "$directory")" ]; then
    echo "The directory '$directory' contains files."
else
    echo "The directory '$directory' is empty."
    mysql_install_db -c mariadb_local.ini -p admin
fi

mysqld --defaults-file="mariadb_local.ini" --console