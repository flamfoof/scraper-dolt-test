@echo off

setlocal enabledelayedexpansion

for /f "tokens=1-4 delims=/ " %%a in ('echo %date%') do (
  set "month=%%b"
  set "day=%%c"
  set "year=%%d"
)

set "formatted_date=!year!_!month!_!day!"

echo !formatted_date!

aws s3 cp s3://tmdb-dump/movies_tmdb_!formatted_date!.json ./sample
aws s3 cp s3://tmdb-dump/series_tmdb_!formatted_date!.json ./sample

endlocal