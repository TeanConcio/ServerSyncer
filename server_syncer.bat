@echo off
setlocal enabledelayedexpansion



:: Define files
set username_file=username.txt
set status_file=server_status.txt

:: Define variables
set USERNAME=
set STATUS=
set CURRENT_HOST=
set SERVER_FOLDER=server_files
set SERVER_RUN_FILE=run.bat
set WORKING_BRANCH=main

:: Define function return variables
set timestamp=
set status=
set commit_message=
set start_timestamp=
set stop_timestamp=



:: Main Script
call :check_files || pause && exit /b 1
call :read_username || pause && exit /b 1
call :pull_changes || pause && exit /b 1
call :get_variables || pause && exit /b 1
call :check_status || pause && exit /b 1
call :set_status_online || pause && exit /b 1
call :start_server || pause && exit /b 1
call :set_status_offline || pause && exit /b 1

endlocal
exit /b



:: Function Definitions



:: Phase Functions

:check_files
:: Check if required files exist
if not exist %username_file% (
    echo Error: %username_file% not found.
    exit /b 1
)
if not exist %status_file% (
    echo Error: %status_file% not found.
    exit /b 1
)
goto :eof


:read_username
:: Read the username from the file
if exist %username_file% (
    set /p USERNAME=<%username_file%
    if "%USERNAME%"=="" (
        echo Error: %username_file% is empty.
        exit /b 1
    )
) else (
    echo Error: %username_file% not found.
    exit /b 1
)
goto :eof


:pull_changes
:: Pull the latest changes from GitHub
for /f "tokens=2 delims==" %%A in ('findstr "WORKING_BRANCH=" %status_file%') do set WORKING_BRANCH=%%A
git pull origin %WORKING_BRANCH% || (
    echo Error: Failed to pull latest changes from branch %WORKING_BRANCH%.
    exit /b 1
)
goto :eof


:get_variables
:: Get variables from status file
for /f "tokens=2 delims==" %%A in ('findstr "STATUS=" %status_file%') do set STATUS=%%A
for /f "tokens=2 delims==" %%B in ('findstr "CURRENT_HOST=" %status_file%') do set CURRENT_HOST=%%B
for /f "tokens=2 delims==" %%C in ('findstr "SERVER_FOLDER=" %status_file%') do set SERVER_FOLDER=%%C
for /f "tokens=2 delims==" %%D in ('findstr "SERVER_RUN_FILE=" %status_file%') do set SERVER_RUN_FILE=%%D
for /f "tokens=2 delims==" %%E in ('findstr "WORKING_BRANCH=" %status_file%') do set WORKING_BRANCH=%%E
goto :eof


:check_status
:: Check if the server is already running
if "%STATUS%" == "online" (
    echo Server is already running by %CURRENT_HOST%
    exit /b 1
)
goto :eof


:set_status_online
:: Get current timestamp for start event
call :get_timestamp
set start_timestamp=%timestamp%
:: Set the flag to online
call :update_status_file "online"
call :commit_files "Server started by %USERNAME% on %start_timestamp%" || exit /b 1
goto :eof


:start_server
:: Navigate to the server folder and start the server
cd %SERVER_FOLDER% || (
    echo Error: Failed to navigate to %SERVER_FOLDER% directory.
    exit /b 1
)
call %SERVER_RUN_FILE% || (
    echo Error: Failed to start the server.
    exit /b 1
)
cd .. || (
    echo Error: Failed to navigate back to original directory.
    exit /b 1
)
goto :eof


:set_status_offline
:: Get current timestamp for stop event
call :get_timestamp
set stop_timestamp=%timestamp%
:: After server stops, set the flag to offline
call :update_status_file "offline"
call :commit_files "Server stopped by %USERNAME% on %stop_timestamp%" || exit /b 1
goto :eof



:: Helper Functions


:get_timestamp
:: Helper function to get current timestamp
for /f "tokens=1-5 delims=/: " %%d in ("%date% %time%") do (
    set timestamp=%%d-%%e-%%f %%g:%%h
)
goto :eof


:update_status_file
:: Helper function to create a status file with the the variables
set status=%~1
(echo STATUS=%status%) > %status_file%
(echo CURRENT_HOST=) >> %status_file%
(echo.) >> %status_file%
(echo SERVER_FOLDER=%SERVER_FOLDER%) >> %status_file%
(echo SERVER_RUN_FILE=%SERVER_RUN_FILE%) >> %status_file%
(echo WORKING_BRANCH=%WORKING_BRANCH%) >> %status_file%
goto :eof


:commit_files
:: Helper function to commit files with a commit message as a parameter
set "commit_message=%~1"
git add %status_file%
git commit -m "%commit_message%"
git push origin %WORKING_BRANCH% || (
    echo Error: Failed to push changes to branch %WORKING_BRANCH%.
    exit /b 1
)
goto :eof