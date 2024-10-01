@echo off
netsh interface show interface
for /F "skip=3 tokens=1,2,3* delims= " %%G in ('netsh interface show interface') DO (
    IF "%%H"=="Connected" echo Restarting "%%J" device & netsh interface set interface "%%J" disabled & netsh interface set interface "%%J" enabled
)