LOAD mysql;
ATTACH 'host=localhost user=root password=Fr33c@st port=3306 database=tmdb' AS mysql_db (TYPE mysql_scanner, READ_ONLY);
USE mysql_db;

sling run --src-conn "jdbc:mariadb://localhost:3306/tmdb" --src-stream my_schema.my_table --tgt-object file://path/to/my_data.parquet --tgt-conn target_db --tgt-stream my_schema.my_table

export MARIADB='mariadb://myuser:mypass@host.ip:3306/mydatabase?tls=skip-verify'
sling conns set MARIADB type=mariadb host=localhost user=root password=Fr33c@st database=tmdb port=3306

@REM OR use url
@REM sling conns set MARIADB url="mariadb://dev:Fr33c@st@192.168.1.134:3306/tmdb?tls=skip-verify"


@REM sling run --src-conn "mariadb://root:Fr33c@st@localhost:3306/tmdb?tls=skip-verify" --src-stream tmdb.test3 --tgt-object ./par.parquet
@REM sling run --src-conn MARIADB --src-stream 'tmdb.test4' --tgt-object 'file://my_file.parquet'

sling conns set MARIADB type=mariadb host=localhost user=sling database=tmdb password=test port=3306

@REM sling run --src-stream MARIADB --tgt-conn mariadb --tgt-object file://par.parquet --mode full-refresh

@REM works
sling run --src-conn MARIADB --src-stream tmdb.test4 --tgt-conn LOCAL --tgt-object ./tmdb_parquets --tgt-options "{\"file_max_rows\": 10, \"format\": \"parquet\"}"