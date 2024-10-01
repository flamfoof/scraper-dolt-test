@echo off
:: Read environment variables from config.txt
setlocal enabledelayedexpansion
for /f "tokens=1-3" %%a in (.env) do (
  set "line=%%a"
  
  if not "!line:~0,1!" == "#" (
    set %%a=%%c
  )
)

@echo on

node main.js -i "none" -m movies -pf tubi -o "./cache/tubi/movies/"
node main.js -i "none" -m series -pf tubi -o "./cache/tubi/series/"

node main.js -i "./cache/detail/out/movies_out.json" -trim '{\"media\":\"movies\"}' -o "./cache/trim/movies/"
node main.js -i "./cache/detail/out/series_out.json" -trim '{\"media\":\"series\"}' -o "./cache/trim/series/"

node main.js -i "none" -pf tubi -m merge -p '{\"inputScrape\":\"./cache/tubi/movies/out.json\",\"inputTmdbSeries\":\"./cache/trim/series/out.json\",\"inputTmdbMovies\":\"./cache/trim/movies/out.json\"}' -o "./cache/tubi/movies/merge"
node main.js -i "none" -pf tubi -m merge -p '{\"inputScrape\":\"./cache/tubi/series/out.json\",\"inputTmdbSeries\":\"./cache/trim/series/out.json\",\"inputTmdbMovies\":\"./cache/trim/movies/out.json\"}' -o "./cache/tubi/series/merge"

node main.js -i "./cache\tubi\movies\merge\out.json" -m movies --ingestion -pf tubi -o "./cache/tubi/movies/ingestion"
node main.js -i "./cache\tubi\series\merge\out.json" -m series --ingestion -pf tubi -o "./cache/tubi/series/ingestion" 

node main.js -i "./cache/tubi/movies/ingestion/movies_out.csv" -m movies -gz '{\"actions\":\"compress\", \"name\":\"tubi_movies_out\"}' -o "./cache/tubi/movies/gz/"
node main.js -i "./cache/tubi/series/ingestion/series_out.csv" -m series -gz '{\"actions\":\"compress\", \"name\":\"tubi_series_out\"}' -o "./cache/tubi/series/gz/"

node main.js -i "./cache/tubi/movies/gz/tubi_movies_out.gz" -awsBucket '{\"media\":\"movies\", \"s3Bucket\":\"%SCRIPT_ENVIRONMENT%-freecast-sources-ingestor\", \"s3Folder\":\"freecast_movie_sources\"}'
node main.js -i "./cache/tubi/series/gz/tubi_series_out.gz" -awsBucket '{\"media\":\"series\", \"s3Bucket\":\"%SCRIPT_ENVIRONMENT%-freecast-sources-ingestor\", \"s3Folder\":\"freecast_episode_sources\"}'

node main.js -o "./cache/tubi/" -c

@echo off
setlocal disabledelayedexpansion