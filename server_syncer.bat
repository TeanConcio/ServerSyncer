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
echo Starting server syncer script...
echo.
call :check_files || pause && exit /b 1
call :read_username || pause && exit /b 1
call :pull_changes || pause && exit /b 1
call :get_variables || pause && exit /b 1
call :check_status || pause && exit /b 1
call :set_status_online || pause && exit /b 1
call :start_server || pause && exit /b 1
call :set_status_offline || pause && exit /b 1
echo Server syncer script completed successfully.
echo.

endlocal
pause
exit /b



:: Function Definitions



:: Phase Functions

:check_files
:: Check if required files exist
echo Checking if required files exist...
if not exist %username_file% (
    echo Error: %username_file% not found. Please make one that contains the username of the user.
    exit /b 1
)
if not exist %status_file% (
    echo Error: %status_file% not found.
    exit /b 1
)
echo All files exist.
echo.
goto :eof


:read_username
:: Read the username from the file
echo Reading username from %username_file%...
for /f "usebackq tokens=*" %%A in ("%username_file%") do (
    set /a CURRLINE+=1
    if !CURRLINE! EQU 1 (
        set "USERNAME=%%A"
        :: Remove starting and trailing spaces
        call :trim USERNAME
        goto :DONE
    )
)
:DONE
if "%USERNAME%"=="" (
    echo Error: %username_file% is empty. It must contain the username of the user.
    exit /b 1
)
echo Username is %USERNAME%.
echo.
goto :eof


:pull_changes
:: Pull the latest changes
for /f "tokens=2 delims==" %%A in ('findstr "WORKING_BRANCH=" %status_file%') do set WORKING_BRANCH=%%A
echo Updating server to latest changes from %WORKING_BRANCH% branch...
git pull origin %WORKING_BRANCH% || (
    echo Error: Failed to pull latest changes from branch %WORKING_BRANCH%.
    exit /b 1
)
echo Server updated successfully.
echo.
goto :eof


:get_variables
:: Get variables from status file
echo Getting variables from %status_file%...
for /f "tokens=2 delims==" %%A in ('findstr "STATUS=" %status_file%') do set STATUS=%%A
for /f "tokens=2 delims==" %%B in ('findstr "CURRENT_HOST=" %status_file%') do set CURRENT_HOST=%%B
for /f "tokens=2 delims==" %%C in ('findstr "SERVER_FOLDER=" %status_file%') do set SERVER_FOLDER=%%C
for /f "tokens=2 delims==" %%D in ('findstr "SERVER_RUN_FILE=" %status_file%') do set SERVER_RUN_FILE=%%D
for /f "tokens=2 delims==" %%E in ('findstr "WORKING_BRANCH=" %status_file%') do set WORKING_BRANCH=%%E
echo Variables set successfully.
echo.
goto :eof


:check_status
:: Check if the server is already running
echo Checking server status...
if "%STATUS%" == "online" (
    echo Server is already being run by %CURRENT_HOST%. Please stop the server before running it again.
    exit /b 1
)
echo Server is offline.
echo.
goto :eof


:set_status_online
:: Set the status to online and commit the changes
echo Setting server status to online...
:: Get current timestamp for start event
call :get_timestamp
set start_timestamp=%timestamp%
:: Set the flag to online
call :update_status_file "online"
call :commit_files "Server started by %USERNAME% on %start_timestamp%" || exit /b 1
echo Server status set to online with host %USERNAME%.
echo.
goto :eof


:start_server
:: Start the server
echo Starting the server...
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
echo Server terminated successfully.
echo.
goto :eof


:set_status_offline
:: Set the status to offline and commit the changes
echo Updating remote server and setting status to offline...
:: Get current timestamp for stop event
call :get_timestamp
set stop_timestamp=%timestamp%
:: After server stops, set the flag to offline and commit the changes
call :update_status_file "offline"
git add %SERVER_FOLDER% || (
    echo Error: Failed to add files to commit.
    exit /b 1
)
call :commit_files "Server stopped by %USERNAME% on %stop_timestamp%" || exit /b 1
echo Remote server updated and status set to offline.
echo.
goto :eof



:: Helper Functions


:get_timestamp
:: Helper function to get current timestamp
for /f "tokens=1-5 delims=/: " %%d in ("%date% %time%") do (
    set timestamp=%%d-%%e-%%f %%g:%%h
)
goto :eof


:trim
:: Function to trim spaces
set "var=!%1!"
for /f "tokens=* delims= " %%a in ("!var!") do set "var=%%a"
for /l %%a in (1,1,31) do if "!var:~-1!"==" " set "var=!var:~0,-1!"
endlocal & set "%1=%var%"
goto :eof


:update_status_file
:: Helper function to create a status file with the the variables
set status=%~1
(echo STATUS=%status%) > %status_file%
if "%status%" == "online" (
    (echo CURRENT_HOST=%USERNAME%) >> %status_file%
) else (
    (echo CURRENT_HOST=) >> %status_file%
)
(echo.) >> %status_file%
(echo SERVER_FOLDER=%SERVER_FOLDER%) >> %status_file%
(echo SERVER_RUN_FILE=%SERVER_RUN_FILE%) >> %status_file%
(echo WORKING_BRANCH=%WORKING_BRANCH%) >> %status_file%
goto :eof


:commit_files
:: Helper function to commit files with a commit message as a parameter
set commit_message=%~1
git add %status_file% || (
    echo Error: Failed to add %status_file% to commit.
    exit /b 1
)
git commit -m "%commit_message%" || (
    echo Error: Failed to commit changes.
    exit /b 1
)
git push origin %WORKING_BRANCH% || (
    echo Error: Failed to push changes to branch %WORKING_BRANCH%.
    exit /b 1
)
goto :eof