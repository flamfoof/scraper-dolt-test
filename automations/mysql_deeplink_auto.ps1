
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # Relaunch as administrator
    Start-Process powershell.exe -Verb RunAs "-NoProfile -ExecutionPolicy Bypass  -Command cd '$PWD' ;`"$PSCommandPath`""
    Exit
}

# Change to parent directory
Set-Location ..

# Stop MariaDB service if it exists
$service = Get-Service -Name "mariadb" -ErrorAction SilentlyContinue
if ($service) {
    Stop-Service -Name "mariadb" -Force
    # Delete the existing service
    sc.exe stop mariadb
    Start-Sleep -Seconds 1.0

    sc.exe delete mariadb
    Start-Sleep -Seconds 1.0
}

# Install MariaDB service
mysql_install_db --service MariaDB -c mariadb_local.ini -p admin
Start-Sleep -Seconds 1.0

sc.exe start MariaDB
Start-Sleep -Seconds 2.0

Exit