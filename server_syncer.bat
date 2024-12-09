@echo off
setlocal enabledelayedexpansion

:: Define the file and variables
set username_file=username.txt
set status_file=server_status.txt

set USERNAME=
set STATUS=
set CURRENT_HOST=
set SERVER_FOLDER=server_files
set SERVER_RUN_FILE=run.bat

:: Check if files exist
if not exist %username_file% (
    echo Error: %username_file% not found.
    exit /b 1
)
if not exist %status_file% (
    echo Error: %status_file% not found.
    exit /b 1
)

:: Read the username from the file
set /p USERNAME=<%username_file%

:: Pull the latest changes
git pull origin main || (
    echo Error: Failed to pull latest changes from GitHub.
    exit /b 1
)

:: Get variables from status file
for /f "tokens=2 delims==" %%A in ('findstr "STATUS=" %status_file%') do set STATUS=%%A
for /f "tokens=2 delims==" %%B in ('findstr "CURRENT_HOST=" %status_file%') do set CURRENT_HOST=%%B
for /f "tokens=2 delims==" %%C in ('findstr "SERVER_FOLDER=" %status_file%') do set SERVER_FOLDER=%%C
for /f "tokens=2 delims==" %%D in ('findstr "SERVER_RUN_FILE=" %status_file%') do set SERVER_RUN_FILE=%%D

:: Check server status
if "%STATUS%" == "online" (
    echo Server is already running by %CURRENT_HOST%
    exit /b 1
)

:: Set the flag to online
(echo STATUS=online) > %status_file%
(echo CURRENT_HOST=%USERNAME%) >> %status_file%
(echo SERVER_FOLDER=%SERVER_FOLDER%) >> %status_file%
(echo SERVER_RUN_FILE=%SERVER_RUN_FILE%) >> %status_file%
git add %status_file%
git commit -m "Server started by %USERNAME%"
git push origin main || (
    echo Error: Failed to push status changes to GitHub.
    exit /b 1
)

:: Navigate to the server folder
cd %SERVER_FOLDER% || (
    echo Error: Failed to navigate to %SERVER_FOLDER% directory.
    exit /b 1
)

:: Start the server
call %SERVER_RUN_FILE%

:: Navigate back to the original directory
cd .. || (
    echo Error: Failed to navigate back to original directory.
    exit /b 1
)

:: After server stops, set the flag to offline
(echo STATUS=offline) > %status_file%
(echo CURRENT_HOST=) >> %status_file%
(echo SERVER_FOLDER=%SERVER_FOLDER%) >> %status_file%
(echo SERVER_RUN_FILE=%SERVER_RUN_FILE%) >> %status_file%
git add %status_file%
git commit -m "Server stopped by %USERNAME%"
git push origin main || (
    echo Error: Failed to push status changes to GitHub.
    exit /b 1
)

endlocal
