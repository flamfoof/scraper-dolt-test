# Deeplink MySQL DB

A powerful and efficient MariaDB cloning and management tool optimized for handling database operations.

## Features

- **Efficient Database Cloning**: Clone databases with optimized connection pooling and batched operations
- **Schema Comparison**: Compare database schemas between source and destination
- **Local Database Management**: Initialize and manage local MariaDB instances
- **Windows Service Integration**: Run MariaDB as a Windows service with auto-start capability
- **Progress Tracking**: Visual feedback for long-running operations
- **Dry Run Mode**: Preview changes before execution

## Prerequisites

- [Bun](https://bun.sh/) (>= 1.0.0)
- MariaDB (>= 10.5)
- Node.js (>= 18.0.0)
- Windows OS (for service functionality)

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bun install
   ```
3. Copy `sample.env` to `proj.env` and configure your environment variables

## Configuration

Required environment variables in `proj.env`:

```env
MASTER_DB_HOST=your_source_host
MASTER_DB_USER=your_source_user
MASTER_DB_PASS=your_source_password
MASTER_DB_PORT=3306

LOCAL_DB_HOST=localhost
LOCAL_DB_USER=your_local_user
LOCAL_DB_PASS=your_local_password
LOCAL_DB_PORT=3307

CLONE_DATABASES=db1,db2,db3
SSH_FILE=your_ssh_key_file
```

## Usage

### Initialize Local Database

Set up a new local MariaDB instance:

```bash
bun run init
```

### Run as Windows Service

Install and start MariaDB as a Windows service (requires Administrator privileges):

```bash
# Install and start as service
bun run service

# Uninstall service
bun run service:uninstall

# Service can also be managed using Windows commands:
net start MariaDB
net stop MariaDB
sc.exe query MariaDB
```

### Start Database Server (Non-service mode)

Start the local MariaDB server directly:

```bash
bun run start
```

### Clone Databases

Clone databases from source to destination:

```bash
# Clone specific database
bun run clone -d database_name

# Clone with custom batch size
bun run clone -d database_name -b 5000

# Dry run to preview changes
bun run clone --dry-run
```

### Compare Schemas

Compare database schemas between source and destination:

```bash
bun run diff -d database_name
```

## Commands

- `init`: Initialize a new MariaDB instance
- `service`: Install and run MariaDB as a Windows service
- `start`: Start the MariaDB server (non-service mode)
- `clone`: Clone databases from source to destination
- `diff`: Compare database schemas
- `setup`: Create necessary databases and users

## Architecture

The project uses a modular architecture with the following components:

- `src/lib/db-manager.js`: Core database operations
- `src/commands/`: CLI commands
  - `init.js`: Database initialization
  - `service.js`: Windows service management
  - `start.js`: Direct server startup
  - `clone.js`: Database cloning
  - `clone-diff.js`: Schema comparison
- `src/index.js`: Main entry point


## Logging

Logs are stored in:
- `mysql/logs/error.log`: MariaDB error logs
- `mysql/logs/mysql.log`: General query logs
