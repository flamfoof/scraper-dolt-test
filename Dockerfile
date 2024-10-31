# Use the official MariaDB image as the base
FROM mariadb:latest

WORKDIR /var/lib/mysql
ARG MARIADB_ROOT_PASSWORD

# Expose the MariaDB port
EXPOSE 3306

# Initialize the database and create a test database
COPY ./mariadb.ini /etc/mysql/my.ini
COPY ./mariadb.ini /etc/mysql/my.cnf

# Command to run when the container starts
# CMD ["mariadbd", "--defaults-file=/etc/mysql/my.ini"]