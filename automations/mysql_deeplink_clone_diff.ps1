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

# Clone each database
foreach ($Database in $DatabaseNames) {
    Write-Host "`nCloning database: $Database" -ForegroundColor Cyan
    # Create database SQL command
    $createDbSQL = @"
    CREATE DATABASE IF NOT EXISTS $Database
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;
"@

    try {
        Write-Host "Attempting to create database '$Database' on $DestinationHost..." -ForegroundColor Cyan
        echo "mysql -h $DestinationHost -u $DestinationUser -P $DestinationPort -p"$DestinationPassword" -e $createDbSQL 2>&1"
        # Execute the create database command
        $result = mysql -h $DestinationHost -u $DestinationUser -P $DestinationPort -p"$DestinationPassword" -e $createDbSQL 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Database creation successful or database already exists." -ForegroundColor Green
            
            # Verify database exists
            $checkDbSQL = "SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME 
                        FROM information_schema.SCHEMATA 
                        WHERE SCHEMA_NAME = '$Database';"
            
            $dbInfo = mysql -h $DestinationHost -u $DestinationUser -p"$DestinationPassword" -N -e $checkDbSQL
            
            if ($dbInfo) {
                Write-Host "`nDatabase Information:" -ForegroundColor Cyan
                Write-Host $dbInfo
            }
        } else {
            Write-Host "Error creating database: $result" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "Error occurred: $_" -ForegroundColor Red
        exit 1
    }

    # Clone the database
    try {
        echo "mysqldump -h $SourceHost -u $SourceUser -P $SourcePort -p`"$SourcePassword`" --single-transaction --quick --lock-tables=false $Database | mysql -h $DestinationHost -u $DestinationUser -P $DestinationPort -p`"$DestinationPassword`" $Database"

        # Dump and restore in one pipeline
        $command = "mysqldump -h $SourceHost -u $SourceUser -P $SourcePort -p`"$SourcePassword`" --single-transaction --quick --lock-tables=false $Database | mysql -h $DestinationHost -u $DestinationUser -P $DestinationPort -p`"$DestinationPassword`" $Database"
        
        Invoke-Expression $command
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Successfully cloned $Database" -ForegroundColor Green
        } else {
            Write-Host "Error cloning $Database" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Failed to clone $Database" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}