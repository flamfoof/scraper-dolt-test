
# Read and parse the environment file
SET-LOCATION ..
$envFile = "./proj.env"
$envConfig = @{}
Import-Module Posh-SSH

Write-Output (Get-Module -Name Posh-SSH)
if (Get-Module -Name Posh-SSH) {
    Write-Host "Posh-SSH is installed."
} else {
    if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        # Relaunch as administrator
        Start-Process powershell.exe -Verb RunAs "-NoProfile -ExecutionPolicy Bypass  -Command cd '$PWD' ;`"$PSCommandPath`""
        Exit
    }
    Write-Host "Posh-SSH is not installed."
    Install-Module Posh-SSH
    Import-Module Posh-SSH -Global
}

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

if($envConfig['DB_EXEC'] -eq 'mariadb') {
    $mariaExec = $envConfig['DB_EXEC']
    $mariaDumpExec = $envConfig['DB_EXEC'] + "-dump"
} else {
    $mariaExec = $envConfig['DB_EXEC']
    $mariaDumpExec = $envConfig['DB_EXEC'] + "dump"
}

if(Get-Command "mariadb" -ErrorAction SilentlyContinue) {
    $mariaLocalExec = "mariadb"
    $mariaLocalDumpExec = "mariadb" + "-dump"
} else {
    $mariaLocalExec = "mysql"
    $mariaLocalDumpExec = "mysql" + "dump"
}

# Set variables from environment file
$SSH_Host = $envConfig['SSH_HOST']
$SSH_User = $envConfig['SSH_USER']
$SourceHost = $envConfig['MASTER_DB_HOST']
$SourceUser = $envConfig['MASTER_DB_USER']
$SourcePassword = $envConfig['MASTER_DB_PASS']
$SourcePort = $envConfig['MASTER_DB_PORT']
$DestinationHost = If ($envConfig.ContainsKey('LOCAL_DB_HOST')) {$envConfig['LOCAL_DB_HOST']} Else {'localhost'}
$DestinationUser = $envConfig['LOCAL_DB_USER']
$DestinationPassword = $envConfig['LOCAL_DB_PASS']
$DestinationPort = $envConfig['LOCAL_DB_PORT']
$DatabaseNames = $envConfig['CLONE_DATABASES'] -split ','
$MasterReplUser =$envConfig['MASTER_DB_REPL']
$MasterReplPass =$envConfig['MASTER_DB_REPL_PASS']
# Display configuration (without passwords)
Write-Host "Configuration loaded:" -ForegroundColor Cyan
Write-Host "Source Host: $SourceHost"
Write-Host "Source User: $SourceUser"
Write-Host "Destination Host: $DestinationHost"
Write-Host "Destination User: $DestinationUser"
Write-Host "Databases to clone: $($DatabaseNames -join ', ')"

$mariaLocalConnection = "$mariaLocalExec -h $DestinationHost -u $DestinationUser -P $DestinationPort -p""$DestinationPassword"" -N -e "
# Connect to SSH server tunnel
$SSH_File = $envConfig['SSH_FILE']
$SSH_Path = "$env:USERPROFILE\.ssh\$SSH_File".Replace("\", "/")
$SSH_Execution = "'${SSH_Path}' ${SSH_User}@${SSH_Host}"
Write-Host "Attempting to connect to ssh: ${SSH_Execution}" -ForegroundColor Cyan

# Function to create a detached SSH session and send commands
# Import Posh-SSH if not already imported

function SendSSHCommand() {
    param(
    [Parameter(Mandatory=$true)]
    [Renci.SshNet.ShellStream]$session,
    
    [Parameter(Mandatory=$true)]
    [string]$command
    )
    # Write-Host $currSession.GetType().FullName -ForegroundColor Green

    $result = Invoke-SSHStreamShellCommand -ShellStream $session -Command $command -Verbose
    Write-Host $result -ForegroundColor DarkBlue
}

# try {
#     # Establish SSH session
#     $session = New-SSHSession -ComputerName $SSH_Host $SSH_User -Port 22 -KeyFile $SSH_Path -AcceptKey
#     $sessionShell = New-SSHShellStream 0 -Debug
# }
# catch {
#     Write-Error "An error occurred: $_"
# }

Start-Sleep -Seconds 1.0
$initMaster = """CHANGE MASTER TO
    MASTER_HOST     ='$SourceHost',
    MASTER_USER     ='$MasterReplUser',
    MASTER_PASSWORD ='$MasterReplPass',
    MASTER_LOG_FILE ='mysql-bin.000001',
    MASTER_LOG_POS  =1;,
    MASTER_SSL      =1;"""

$startSlave = """STOP SLAVE;
    START SLAVE;"""


#Only run this locally, do not run using SendSSHComamnd
$startMasterConfig = $mariaLocalConnection + $initMaster
Write-Host $startMasterConfig -ForegroundColor Green
Invoke-Expression $startMasterConfig

$startMasterConnection = $mariaLocalConnection + $startSlave
Write-Host $startMasterConnection -ForegroundColor Green
Invoke-Expression $startMasterConnection
exit


# Clone each database
foreach ($Database in $DatabaseNames) {
    Write-Host "Cloning database: $Database" -ForegroundColor Cyan
    # Create database SQL command
    $createDbSQL = 
        "CREATE DATABASE IF NOT EXISTS tmdb
        CHARACTER SET utf8mb4
        COLLATE utf8mb4_unicode_ci;"

    try {
        Write-Host "Attempting to create database '$Database' on $DestinationHost..." -ForegroundColor Cyan
        $sqlTableGen = "$mariaLocalExec -h $DestinationHost -u $DestinationUser -P $DestinationPort -p""$DestinationPassword"" -e ""$createDbSQL""" 
        Write-Host $sqlTableGen -ForegroundColor Yellow
        # Execute the create database command
        # $result = $mariaExec -h $DestinationHost -u $DestinationUser -P $DestinationPort -p"$DestinationPassword" -e $createDbSQL
        $result = SendSSHCommand -Session $sessionShell -Command $sqlTableGen


        exit
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Database creation successful or database already exists." -ForegroundColor Green
            
            # Verify database exists
            $checkDbSQL = "SELECT SCHEMA_NAME, DEFAULT_CHARACTER_SET_NAME, DEFAULT_COLLATION_NAME 
                        FROM information_schema.SCHEMATA 
                        WHERE SCHEMA_NAME = '$Database';"
            
            $dbInfo = "$mariaLocalExec -h $DestinationHost -u $DestinationUser -p""$DestinationPassword"" -N -e $checkDbSQL"
            Write-Host $dbInfo -ForegroundColor Yellow
            Invoke-Expression $dbInfo

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
    exit
    # Clone the database
    try {
        echo "$mariaDumpExec -h $SourceHost -u $SourceUser -P $SourcePort -p`"$SourcePassword`" --single-transaction --quick --lock-tables=false $Database | $mariaLocalExec -h $DestinationHost -u $DestinationUser -P $DestinationPort -p`"$DestinationPassword`" $Database"

        # Dump and restore in one pipeline
        $command = "$mariaDumpExec -h $SourceHost -u $SourceUser -P $SourcePort -p`"$SourcePassword`" --single-transaction --quick --lock-tables=false $Database | $mariaLocalExec -h $DestinationHost -u $DestinationUser -P $DestinationPort -p`"$DestinationPassword`" $Database"
        
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

if ($session) {
    Remove-SSHSession -SessionId $session.SessionId | Out-Null
    Write-Host "SSH session closed."
}

Start-Sleep -Seconds 1.0