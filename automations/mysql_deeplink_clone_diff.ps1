# Load environment variables from proj.env
$envFile = ".\proj.env"
$envConfig = @{}

if (Test-Path $envFile) {
    Get-Content $envFile | ForEach-Object {
        if ($_ -match '^\s*([^=]+)=(.*)$') {
            $key = $matches[1].Trim()
            $value = $matches[2].Trim() -replace '^["'']|["'']$'
            $envConfig[$key] = $value
        }
    }
} else {
    Write-Host "Environment file not found: $envFile" -ForegroundColor Red
    exit 1
}

# Set connection parameters from env file
$SOURCE_HOST = $envConfig['MASTER_DB_HOST']
$SOURCE_USER = $envConfig['MASTER_DB_USER']
$SOURCE_PASS = $envConfig['MASTER_DB_PASS']
$SOURCE_PORT = $envConfig['MASTER_DB_PORT']
$DEST_HOST = if ($envConfig['LOCAL_DB_HOST']) { $envConfig['LOCAL_DB_HOST'] } else { 'localhost' }
$DEST_USER = $envConfig['LOCAL_DB_USER']
$DEST_PASS = $envConfig['LOCAL_DB_PASS']
$DEST_PORT = $envConfig['LOCAL_DB_PORT']
$DATABASES = $envConfig['CLONE_DATABASES'] -split ','

# Rest of your functions here...
function Get-TableChecksum {
    param (
        [string]$HostLocation,
        [string]$User,
        [string]$Pass,
        [string]$Port,
        [string]$Database,
        [string]$Table
    )
    
    $query = @"
        CHECKSUM TABLE $Database.$Table EXTENDED;
"@
    
    $result = mysql -h $HostLocation -u $User -P $Port -p"$Pass" -N -e $query
    return $result
}

function Get-TableStructure {
    param (
        [string]$HostLocation,
        [string]$User,
        [string]$Pass,
        [string]$Port,
        [string]$Database,
        [string]$Table
    )
    
    $query = "SHOW CREATE TABLE $Database.$Table;"
    $result = mysql -h $HostLocation -u $User -P $Port -p"$Pass" -N -e $query
    return $result
}

function Compare-AndSync {
    param (
        [string]$Database,
        [string]$Table
    )

    Write-Host "Comparing table $Database.$Table..." -ForegroundColor Cyan

    # Compare table structures
    $sourceStructure = Get-TableStructure -Host $SOURCE_HOST -User $SOURCE_USER -Port $SOURCE_PORT -Pass $SOURCE_PASS -Database $Database -Table $Table
    $destStructure = Get-TableStructure -Host $DEST_HOST -User $DEST_USER -Port $DEST_PORT -Pass $DEST_PASS -Database $Database -Table $Table

    if ($sourceStructure -ne $destStructure) {
        Write-Host "Table structure differs for $Table. Recreating table..." -ForegroundColor Yellow
        
        # Drop and recreate table
        $dropQuery = "DROP TABLE IF EXISTS $Database.$Table;"
        mysql -h $DEST_HOST -u $DEST_USER -P $DEST_PORT -p"$DEST_PASS" $Database -e $dropQuery
        
        # Create table with source structure
        mysql -h $DEST_HOST -u $DEST_USER -P $DEST_PORT -p"$DEST_PASS" $Database -e $sourceStructure
    }

    # Compare table checksums
    $sourceChecksum = Get-TableChecksum -Host $SOURCE_HOST -User $SOURCE_USER -Port $SOURCE_PORT -Pass $SOURCE_PASS -Database $Database -Table $Table
    $destChecksum = Get-TableChecksum -Host $DEST_HOST -User $DEST_USER -Port $DEST_PORT -Pass $DEST_PASS -Database $Database -Table $Table

    if ($sourceChecksum -ne $destChecksum) {
        Write-Host "Data differs for table $Table. Syncing..." -ForegroundColor Yellow

        # Get primary key or unique key
        $keyQuery = @"
            SELECT k.COLUMN_NAME
            FROM information_schema.table_constraints t
            JOIN information_schema.key_column_usage k
            USING(constraint_name,table_schema,table_name)
            WHERE t.constraint_type='PRIMARY KEY'
            AND t.table_schema='$Database'
            AND t.table_name='$Table';
"@
        
        $keyColumn = mysql -h $SOURCE_HOST -u $SOURCE_USER -P $SOURCE_PORT -p"$SOURCE_PASS" -N -e $keyQuery

        if ($keyColumn) {
            # Sync using primary key
            $syncQuery = @"
                CREATE TEMPORARY TABLE tmp_sync_$Table LIKE $Table;
                INSERT INTO tmp_sync_$Table SELECT * FROM $Table;
                
                REPLACE INTO $Table
                SELECT source.*
                FROM ($Table@master_server source
                LEFT JOIN tmp_sync_$Table dest ON source.$keyColumn = dest.$keyColumn)
                WHERE dest.$keyColumn IS NULL;
                
                DROP TEMPORARY TABLE tmp_sync_$Table;
"@
            mysql -h $DEST_HOST -u $DEST_USER -P $DEST_PORT -p"$DEST_PASS" $Database -e $syncQuery
        } else {
            # If no primary key, do a full table sync
            Write-Host "No primary key found. Performing full table sync..." -ForegroundColor Yellow
            $dumpCmd = "mysqldump -h $SOURCE_HOST -u $SOURCE_USER -P $SOURCE_PORT -p`"$SOURCE_PASS`" --single-transaction --quick --no-create-info $Database $Table"
            $importCmd = "mysql -h $DEST_HOST -u $DEST_USER -P $DEST_PORT -p`"$DEST_PASS`" $Database"
            Invoke-Expression "$dumpCmd | $importCmd"
        }
    } else {
        Write-Host "Table $Table is in sync." -ForegroundColor Green
    }
}

# Main sync process
foreach ($Database in $DATABASES) {
    Write-Host "`nProcessing database: $Database" -ForegroundColor Cyan

    # Create database if it doesn't exist
    $createDbQuery = "CREATE DATABASE IF NOT EXISTS $Database;"
    mysql -h $DEST_HOST -u $DEST_USER -P $DEST_PORT -p"$DEST_PASS" -e $createDbQuery

    # Get list of tables
    $tablesQuery = "SHOW TABLES FROM $Database;"
    $tables = mysql -h $SOURCE_HOST -u $SOURCE_USER -P $SOURCE_PORT -p"$SOURCE_PASS" -N -e $tablesQuery

    foreach ($table in $tables) {
        Compare-AndSync -Database $Database -Table $table
    }
}

Write-Host "`nDifferential cloning completed!" -ForegroundColor Green
