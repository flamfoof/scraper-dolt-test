# Use the official MariaDB image as the base
FROM mariadb:latest

WORKDIR /var/lib/mysql

# # Update the package lists
# RUN apt-get update -y

# # # Install MariaDB server
# RUN apt-get install -y mariadb-server

# Set the MariaDB root password
# ENV MYSQL_ROOT_PASSWORD=Fr33c@st

# Expose the MariaDB port
EXPOSE 3306

# Initialize the database and create a test database
# COPY init-mariadb.sql /app/init-mariadb.sql
COPY ./mariadb.ini /etc/mysql/my.cnf
# CMD [ "/bin/bash", "mkdir", "data", "&&", "mariadbd"]

# Command to run when the container starts
CMD ["mariadbd"]