echo off
REM Get the current directory
setlocal enabledelayedexpansion
set "current_dir=%~dp0"

REM Set the task name and description
set task_name=Scraper - 
set task_description=A daily task scheduled to run at 6AM
set username=flam
set userpass=Tomandjerry123@
echo on
REM Create the task
@REM C:\Users\!username!\Documents\work\scrapper\ztestScheduler.bat
echo !current_dir!
@REM schtasks /create /tn "!task_name!Test" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_gracenote_metadata_latest_windows.bat'"
REM Set security options
schtasks /create /tn "!task_name!abc" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_abc_windows.bat'"
schtasks /create /tn "!task_name!acorn" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_acorn_windows.bat'"
schtasks /create /tn "!task_name!ae" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_ae_windows.bat'"
schtasks /create /tn "!task_name!amazon" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_amazon_windows.bat'"
schtasks /create /tn "!task_name!amc" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_amc_windows.bat'"
schtasks /create /tn "!task_name!apple" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_apple_windows.bat'"
schtasks /create /tn "!task_name!betplus" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_betplus_windows.bat'"
schtasks /create /tn "!task_name!britbox" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_britbox_windows.bat'"
schtasks /create /tn "!task_name!discovery" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_discovery_windows.bat'"
schtasks /create /tn "!task_name!disney" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_disney_windows.bat'"
schtasks /create /tn "!task_name!fubo" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_fubo_windows.bat'"
schtasks /create /tn "!task_name!google-play" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_google-play_windows.bat'"
schtasks /create /tn "!task_name!hgtv" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_hgtv_windows.bat'"
schtasks /create /tn "!task_name!hoopla" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_hoopla_windows.bat'"
schtasks /create /tn "!task_name!hulu" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_hulu_windows.bat'"
schtasks /create /tn "!task_name!max" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_max_windows.bat'"
schtasks /create /tn "!task_name!paramount" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_paramount_windows.bat'"
schtasks /create /tn "!task_name!peacock" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_peacock_windows.bat'"
schtasks /create /tn "!task_name!philo" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_philo_windows.bat'"
schtasks /create /tn "!task_name!roku" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_roku_windows.bat'"
schtasks /create /tn "!task_name!sling" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_sling_windows.bat'"
schtasks /create /tn "!task_name!starz" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_starz_windows.bat'"
schtasks /create /tn "!task_name!sundance" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_sundance_windows.bat'"
schtasks /create /tn "!task_name!tlc" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_tlc_windows.bat'"
schtasks /create /tn "!task_name!travel_channel" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_travel_channel_windows.bat'"
schtasks /create /tn "!task_name!tubi" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_tubi_windows.bat'"
schtasks /create /tn "!task_name!vudu" /sc DAILY /mo 1 /st 06:00:00 /sd 03/01/2024 /RU !username! /RP !userpass! /RL HIGHEST /f /tr "cmd '/c cd !current_dir! && !current_dir!automation_vudu_windows.bat'"