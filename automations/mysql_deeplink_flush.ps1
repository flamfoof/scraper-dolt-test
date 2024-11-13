# Load environment variables from proj.env
SET-LOCATION ..

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

mysqladmin flush-hosts -h $DEST_HOST -u $DEST_USER -P $DEST_PORT -p"$DEST_PASS"
mariadb-admin flush-hosts -h $DEST_HOST -u $DEST_USER -P $DEST_PORT -p"$DEST_PASS"
# Write-Host "mysqladmin flush-hosts -h $DEST_HOST -u $DEST_USER -P $DEST_PORT -p""$DEST_PASS"""
mysqladmin flush-hosts -h $SOURCE_HOST -u $SOURCE_USER -P $SOURCE_PORT -p"$SOURCE_PASS"
mariadb-admin flush-hosts -h $SOURCE_HOST -u $SOURCE_USER -P $SOURCE_PORT -p"$SOURCE_PASS"
# Write-Host "mysqladmin flush-hosts -h $SOURCE_HOST -u $SOURCE_USER -P $SOURCE_PORT -p""$SOURCE_PASS"""

Write-Host "`nThere could be errors, but that's fine." -ForegroundColor Green