# Read and parse the environment file
SET-LOCATION ..
$envFile = "./proj.env"
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

# Determine which MySQL/MariaDB executables to use
if($envConfig['DB_EXEC'] -eq 'mariadb') {
    $mysqlDumpExec = "mariadb-dump"
} else {
    $mysqlDumpExec = "mysqldump"
}

# Set variables from environment file
$SourceHost = $envConfig['MASTER_DB_HOST']
$SourceUser = $envConfig['MASTER_DB_USER']
$SourcePassword = $envConfig['MASTER_DB_PASS']
$SourcePort = $envConfig['MASTER_DB_PORT']
$DestinationHost = If ($envConfig.ContainsKey('LOCAL_DB_HOST')) {$envConfig['LOCAL_DB_HOST']} Else {'localhost'}
$DestinationUser = $envConfig['LOCAL_DB_USER']
$DestinationPassword = $envConfig['LOCAL_DB_PASS']
$DestinationPort = $envConfig['LOCAL_DB_PORT']
$DatabaseNames = $envConfig['CLONE_DATABASES'] -split ','

# Display configuration (without passwords)
Write-Host "Configuration loaded:" -ForegroundColor Cyan
Write-Host "Source Host: $SourceHost"
Write-Host "Source User: $SourceUser"
Write-Host "Destination Host: $DestinationHost"
Write-Host "Destination User: $DestinationUser"
Write-Host "Databases to clone: $($DatabaseNames -join ', ')"

foreach ($database in $DatabaseNames) {
    Write-Host "Processing database: $database" -ForegroundColor Green
    
    # Create dump file name with timestamp
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $dumpFile = "mysqldump_${database}_${timestamp}.sql"
    
    if ($SourceHost -eq "localhost" -or $SourceHost -eq "127.0.0.1") {
        # Dumping from local database
        Write-Host "Dumping from local database..." -ForegroundColor Yellow
        $dumpCommand = "$mysqlDumpExec -h $SourceHost -u $SourceUser -P $SourcePort -p""$SourcePassword"" --single-transaction $database > $dumpFile"
    } else {
        # Dumping from remote database
        Write-Host "Dumping from remote database..." -ForegroundColor Yellow
        $dumpCommand = "$mysqlDumpExec -h $SourceHost -u $SourceUser -P $SourcePort -p""$SourcePassword"" --single-transaction $database > $dumpFile"
    }
    
    # Execute the dump command
    Write-Host "Creating database dump..." -ForegroundColor Yellow
    Invoke-Expression $dumpCommand
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Dump created successfully: $dumpFile" -ForegroundColor Green
        
        # Clear the destination database first
        Write-Host "Clearing destination database..." -ForegroundColor Yellow
        $dropCommand = "mysql -h $DestinationHost -u $DestinationUser -P $DestinationPort -p""$DestinationPassword"" -e ""DROP DATABASE IF EXISTS $database; CREATE DATABASE $database;"""
        Invoke-Expression $dropCommand
        
        if ($LASTEXITCODE -eq 0) {
            # Import the dump to destination
            Write-Host "Importing dump to destination database..." -ForegroundColor Yellow
            $importCommand = "mysql -h $DestinationHost -u $DestinationUser -P $DestinationPort -p""$DestinationPassword"" $database < $dumpFile"
            Invoke-Expression $importCommand
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Database $database cloned successfully" -ForegroundColor Green
                # Clean up dump file
                Remove-Item $dumpFile
            } else {
                Write-Host "Error importing database $database" -ForegroundColor Red
            }
        } else {
            Write-Host "Error clearing destination database $database" -ForegroundColor Red
        }
    } else {
        Write-Host "Error creating dump for database $database" -ForegroundColor Red
    }
}