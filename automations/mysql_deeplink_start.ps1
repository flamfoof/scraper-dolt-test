SET-LOCATION ..
$directory = "mysql/data"

if (Get-ChildItem -Path $directory) {
    Write-Host "The directory '$directory' contains files."
} else {
    Write-Host "The directory '$directory' is empty."
    mysql_install_db -c mariadb_local.ini -p admin 
}

mysqld --defaults-file="mariadb_local.ini" --console