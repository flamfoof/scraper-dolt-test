# Deeplink MySQL DB

A powerful and efficient MariaDB cloning and management tool optimized for handling movie metadata across multiple streaming platforms.

## Features

- **Database Management**
  - Initialize and manage MariaDB instances
  - Run as Windows service or standalone
  - Efficient database cloning
  - Schema comparison and validation
  - Sample data generation

- **Movie Metadata Tracking**
  - Comprehensive movie information storage
  - Extended metadata with TMDB integration
  - Platform availability tracking
  - Pricing and region management
  - Duplicate detection

- **Scraper Integration**
  - Configurable scraper management
  - Activity logging and monitoring
  - Performance metrics tracking
  - Error handling and reporting
  - Scheduled execution support

- **Performance & Security**
  - Connection pooling
  - Batched data transfer
  - Efficient indexing
  - Secure credential management
  - Comprehensive audit logging

## Prerequisites

- [Bun](https://bun.sh/) (>= 1.0.0)
- [Node.js](https://nodejs.org/) (>= 18.0.0)
- [MariaDB](https://mariadb.org/) (>= 10.5)
- Windows OS (for service functionality)

## Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   bun install
   ```
3. Copy `sample.env` to `proj.env` and configure:
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

## Audit Logging System

The database uses session variables to track the context of changes for audit purposes. These variables must be set before performing operations that will be audited.

### Required Session Variables

- `@username`: The username of the person/system making the change (VARCHAR(64))
- `@appContext`: The context in which the change is being made
  - Values: 'scraper', 'admin', 'api', 'system', 'manual'
- `@environment`: The environment where the change is occurring
  - Values: 'production', 'staging', 'development'

### Example Usage

```sql
-- For admin user making changes in production
SET @username = 'john.doe';
SET @appContext = 'admin';
SET @environment = 'production';

-- For scraper running in staging
SET @username = 'tmdb-scraper';
SET @appContext = 'scraper';
SET @environment = 'staging';

-- For system operations
SET @username = 'system';
SET @appContext = 'system';
SET @environment = 'production';
```

### Default Values

If these variables are not set, the audit system will use these defaults:
- username: 'system'
- appContext: 'system'
- environment: 'production'

## Usage

### Database Setup

Initialize the database schema and optionally generate sample data:

```bash
# Basic setup (uses local database by default)
bun run setup

# Setup with sample data
bun run setup --sample-data 1000

# Setup using master database
bun run setup --connection master
# or use the shorthand command
bun run setup:master

# Setup using local database (explicit)
bun run setup --connection local
# or use the shorthand command
bun run setup:local

# Reset database
bun run setup --reset

# Combine options
bun run setup --connection master --sample-data 1000 --reset
```

The setup command supports the following options:
- `--connection [type]`: Choose database connection (local/master)
- `--sample-data [count]`: Generate sample data with specified count
- `--reset`: Reset the database (WARNING: deletes all data)
- `--debug`: Enable debug logging

### Server Management

The application provides different ways to connect to the database:

```bash
# Initialize MariaDB
bun run init

# Create SSH tunnel to remote database
bun run start

# Run as Windows service (requires admin)
bun run service

```

The `start` command will:
1. Create an SSH tunnel to the remote database server using your SSH key
2. Forward the specified port (default: 3306) to allow local database access
3. Open the SSH connection in a new window for easy monitoring

Required environment variables for SSH tunnel:
```env
SSH_HOST=your_remote_host    # Remote server hostname/IP
SSH_USER=your_ssh_user      # SSH username
SSH_FILE=your_key_file      # SSH key filename (default: google_compute_engine)
MASTER_DB_PORT=3306         # Port to forward (default: 3306)
```

Your SSH key should be located in the standard `.ssh` directory:
- Windows: `C:\Users\<username>\.ssh\`
- Linux/Mac: `~/.ssh/`

### Data Management

Clone and compare databases:

```bash
# Clone specific database
bun run clone -d database_name

# Clone with custom batch size
bun run clone -d database_name -b 5000

# Compare schemas
bun run diff -d database_name

# Preview changes (dry run)
bun run clone --dry-run
```

## Database Structure

- **Movies**: Core movie information
  - Basic details (title, release date)
  - Activity status tracking
  - Duplicate detection

- **MoviesMetadata**: Extended information
  - TMDB/IMDB identifiers
  - Detailed movie attributes
  - Media assets (posters, backdrops)
  - Production information

- **Deeplinks**: Platform availability
  - Streaming platform links
  - Regional availability
  - Pricing information
  - Source tracking

- **Scrapers**: Configuration
  - Source definitions
  - Scheduling settings
  - Performance parameters

- **ScrapersActivity**: Operation logs
  - Run statistics
  - Error tracking
  - Performance metrics

- **AuditLog**: Change tracking
  - Entity modifications
  - User actions
  - Temporal tracking

## Logging

Logs are stored in:
- `mysql/logs/error.log`: MariaDB errors
- `mysql/logs/mysql.log`: General queries
- `mysql/logs/audit.log`: Change tracking

## Known Limitations

- Windows-specific service management
- MariaDB/MySQL compatibility only
- Environment-specific configuration required
- Large databases may require significant transfer time

## Development

### Project Structure
```
src/
├── commands/          # CLI commands
│   ├── init.js       # Database initialization
│   ├── service.js    # Service management
│   ├── start.js      # Direct server startup
│   ├── setup.js      # Schema setup
│   ├── clone.js      # Database cloning
│   └── clone-diff.js # Schema comparison
├── lib/              # Core functionality
│   └── db-manager.js # Database operations
├── sql/              # SQL definitions
│   └── schema.sql    # Database schema
└── index.js          # Entry point
```

### Adding New Features

1. Create command in `src/commands/`
2. Add to `src/index.js`
3. Update package.json scripts
4. Document in README.md

## Troubleshooting

Common issues and solutions:

1. **Service won't start**
   - Run as administrator
   - Check port availability
   - Verify credentials

2. **Clone fails**
   - Check network connectivity
   - Verify source credentials
   - Check available space

3. **Schema mismatch**
   - Run diff command
   - Check version compatibility
   - Verify source schema
