# scraper-dolt-test

This project is used to test the DoltHub scraper. It spins up a local instance of MariaDB, and then clones a database from a remote server into the local instance.

## Usage

### Set up local MariaDB instance

1. Run `npm run mysqlInit` to install and configure the MariaDB service.
2. Run `npm run mysqlStart` to start the MariaDB service.
3. Run `npm run mysqlAuto` to install the service and have it start automatically.

### Clone database

1. Run `npm run mysqlClone` to clone the database from the remote server into the local instance.

### Uninstall

1. Run `sc.exe stop MariaDB` to stop the MariaDB service.
2. Run `sc.exe delete MariaDB` to uninstall the MariaDB service.

## Configuration

The scraper is configured using environment variables. You can set the following variables:

* `MASTER_DB_HOST`: The host of the remote database server.
* `MASTER_DB_USER`: The username to use when connecting to the remote database server.
* `MASTER_DB_PASS`: The password to use when connecting to the remote database server.
* `MASTER_DB_PORT`: The port to use when connecting to the remote database server.
* `LOCAL_DB_HOST`: The host of the local database server (default is `localhost`).
* `LOCAL_DB_USER`: The username to use when connecting to the local database server (default is `root`).
* `LOCAL_DB_PASS`: The password to use when connecting to the local database server (default is `dolt`).
* `LOCAL_DB_PORT`: The port to use when connecting to the local database server (default is `3306`).
* `CLONE_DATABASES`: A comma-separated list of databases to clone from the remote server.
