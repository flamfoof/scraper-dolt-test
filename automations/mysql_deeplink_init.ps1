if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relaunch as administrator
    Start-Process powershell.exe -Verb RunAs "-NoProfile -ExecutionPolicy Bypass  -Command cd '$PWD' ;`"$PSCommandPath`""
    Exit
}

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

sc.exe stop mariadb
sc.exe delete mariadb


# Start the service
$SSH_File = $envConfig['SSH_FILE']
$SSH_Path = "$env:USERPROFILE\.ssh\$SSH_File"
$process = Start-Process "ssh-add" "$SSH_Path" -NoNewWindow -PassThru -Wait 

Start-Sleep -Seconds 1.5

rm -r ./mysql

$currDir=(Get-Location).Path -replace "\\", "/"
$userDir = $env:USERPROFILE -replace "\\", "/"

mkdir ./mysql -Force
mkdir ./mysql/logs -Force
mkdir ./mysql/data -Force

$data = @{
    "mysqld" = @{
        "log-bin                        "   = "mysql-bin"
        "server-id                      "   = 2
        "port                           "   = 3307
        "datadir                        "   = "$currDir/mysql/data"
        "socket                         "   = "$currDir/mysql/mysql.sock"
        "log-error                      "   = "$currDir/mysql/logs/error.log"
        "slow_query_log_file            "   = "$currDir/mysql/logs/slow_query.log"
        "slow_query_log                 "   = 1
        "innodb_buffer_pool_size        "   = "256M"
        "innodb_log_file_size           "   = "50M"
        "max_connections                "   = 100
        "innodb_flush_log_at_trx_commit "   = 2
        "lower_case_table_names         "   = 2
    }
    "client" = @{
        "plugin-dir                     "   = "$userDir/scoop/apps/mariadb/current/lib/plugin"
    }
}

$config = @()
$config += "# These are the configurations for local->remote connection"
foreach ($section in $Data.Keys) {
    $config += "[$($section)]"
    foreach ($key in $Data[$section].Keys) {
        $config += "$key=$($Data[$section][$key])"
    }
    $config += ""
}
$config += "skip-name-resolve"

echo "Creating the local config file: mariadb_local.ini"

Start-Sleep -Seconds 1.0

$config | Out-File "mariadb_local.ini" -Encoding ASCII

#start the mariadb service
# mysql_install_db -c mariadb_local.ini -p admin 
# mysqld --defaults-file="mariadb_local.ini" --console

Start-Sleep -Seconds 1.0

exit