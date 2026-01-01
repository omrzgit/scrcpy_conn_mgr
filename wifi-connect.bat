@echo off
setlocal enabledelayedexpansion

:start
title   scrcpy Connection Manager
cls
echo ================================================================================
echo                        SCRCPY CONNECTION MANAGER
echo ================================================================================
echo.
echo This program helps you connect to your Android device using scrcpy.
echo.
echo Two connection methods available:
echo   1. WIRELESS (TCP/IP) - Connect over Wi-Fi using device IP address
echo   2. USB CABLE - Direct connection via USB cable
echo.
echo The program will:
echo   - Store your device IP for quick reconnection
echo   - Automatically troubleshoot connection issues
echo   - Fall back to alternative methods if needed
echo.
echo ================================================================================
echo.
pause
goto choice

:choice
title   initialising....
timeout 1 /nobreak >nul
cls
echo.
echo.

rem Check if IP exists and is valid at startup
if not exist "%~dp0lastip.txt" (
    echo No saved IP found. You'll need to enter a new IP address...
    timeout 2 /nobreak >nul
    goto newip
)

set /p savedip=<"%~dp0lastip.txt"
if "!savedip!"=="" (
    echo Saved IP is empty. You'll need to enter a new IP address...
    timeout 2 /nobreak >nul
    goto newip
)

echo Stored IP found: !savedip!
echo.
echo Do you want to connect using stored IP? (Yes=1 / No=0)
set /p "starwars=Your choice: "
if not defined starwars goto choice
if "%starwars%"=="1" goto ip
if "%starwars%"=="0" goto usbstart
if "%starwars%"=="2" goto usbstart
if "%starwars%"=="6" goto usbstart
if "%starwars%"=="4" goto choice
echo.
echo Invalid input. Please enter 1 for Yes or 0 for No.
timeout 2 /nobreak >nul
goto choice

:ip
title   connecting....
set /p savedip=<"%~dp0lastip.txt"

rem Check if adb is available
where adb >nul 2>&1
if errorlevel 1 (
    echo ================================================================================
    echo ERROR: ADB not found in PATH
    echo Please install Android SDK Platform Tools
    echo ================================================================================
    pause
    goto exit
)

rem Check if scrcpy is available
where scrcpy >nul 2>&1
if errorlevel 1 (
    echo ================================================================================
    echo ERROR: scrcpy not found in PATH
    echo Please install scrcpy from https://github.com/Genymobile/scrcpy
    echo ================================================================================
    pause
    goto exit
)

echo Attempting to connect to stored ip !savedip!:5555...
adb connect !savedip!:5555 >nul 2>&1
timeout 2 /nobreak >nul

echo Testing connection with scrcpy...
scrcpy -s !savedip!:5555 --video-codec=h264 --max-size=1080 2>nul
if not errorlevel 1 (
    title   Connected.
    pause
    goto exit
)

echo.
echo ================================================================================
echo                           CONNECTION FAILED
echo ================================================================================
echo.
echo Please confirm the following:
echo   - Wireless debugging is ENABLED on your device
echo   - Device IP address matches stored IP: !savedip!
echo   - Both devices are on the SAME Wi-Fi network
echo.
echo ================================================================================
echo.
echo Do you want to continue with automatic troubleshooting? (Yes=1 / No=0)
set /p "continue=Your choice: "
if "!continue!"=="0" goto choice
if "!continue!"=="2" goto choice

echo.
echo Attempting automatic fixes...
echo.
echo [Step 1/2] Restarting ADB server...
adb kill-server >nul 2>&1
timeout 1 /nobreak >nul
adb start-server >nul 2>&1
timeout 2 /nobreak >nul

echo [Step 2/2] Retrying connection to stored ip !savedip!:5555...
adb connect !savedip!:5555 >nul 2>&1
timeout 2 /nobreak >nul

echo Testing connection with scrcpy...
scrcpy -s !savedip!:5555 --video-codec=h264 --max-size=1080 2>nul
if not errorlevel 1 (
    title   Connected.
    pause
    goto exit
)

echo.
echo ================================================================================
echo Automatic troubleshooting failed. Trying TCP/IP mode setup...
echo.
echo IMPORTANT: Please connect your device via USB cable now
echo ================================================================================
timeout 3 /nobreak >nul

adb tcpip 5555
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo WARNING: Failed to enable TCP/IP mode
    echo ================================================================================
    echo.
    echo What would you like to do next?
    echo   1 - Retry with same IP
    echo   2 - Connect via USB instead
    echo   3 - Enter a new IP address
    echo   0 - Exit to main menu
    echo.
    set /p "retry=Your choice: "
    if "!retry!"=="1" goto ip
    if "!retry!"=="2" goto usb
    if "!retry!"=="3" goto newip
    goto exit
)

timeout 2 /nobreak >nul
echo Connecting to !savedip!:5555...
adb connect !savedip!:5555
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo ERROR: Still unable to connect
    echo ================================================================================
    echo.
    echo What would you like to do next?
    echo   1 - Retry with same IP
    echo   2 - Connect via USB instead
    echo   3 - Enter a new IP address
    echo   0 - Exit to main menu
    echo.
    set /p "retry=Your choice: "
    if "!retry!"=="1" goto ip
    if "!retry!"=="2" goto usb
    if "!retry!"=="3" goto newip
    goto exit
)

timeout 1 /nobreak >nul
echo Starting scrcpy...
scrcpy -s !savedip!:5555 --video-codec=h264 --max-size=1080
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo ERROR: scrcpy failed to start
    echo ================================================================================
    echo.
    echo This could be due to:
    echo   - Device not authorized (check device screen for prompt)
    echo   - Network connection issues
    echo   - Device screen is off
    echo.
    pause
)
title   Connected.
pause
goto exit

:usbstart
cls
echo.
echo.
echo Do you want to connect via USB cable? (Yes=1 / No=0)
set /p "starwars=Your choice: "
if not defined starwars goto usbstart
if "%starwars%"=="1" goto usb
if "%starwars%"=="0" goto newipstart
if "%starwars%"=="2" goto newipstart
if "%starwars%"=="6" goto newipstart
if "%starwars%"=="4" goto choice
echo.
echo Invalid input. Please enter 1 for Yes or 0 for No.
timeout 2 /nobreak >nul
goto usbstart

:usb
title   connecting via USB....

rem Check if adb is available
where adb >nul 2>&1
if errorlevel 1 (
    echo ================================================================================
    echo ERROR: ADB not found in PATH
    echo ================================================================================
    pause
    goto exit
)

rem Check if scrcpy is available
where scrcpy >nul 2>&1
if errorlevel 1 (
    echo ================================================================================
    echo ERROR: scrcpy not found in PATH
    echo ================================================================================
    pause
    goto exit
)

echo Checking for USB connected devices...
adb devices | findstr /R "device$" >nul
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo ERROR: No USB devices found
    echo ================================================================================
    echo.
    echo Please verify:
    echo   - Device is connected via USB cable
    echo   - USB debugging is ENABLED in Developer Options
    echo   - Device is AUTHORIZED (check device screen for USB debugging prompt)
    echo   - USB cable supports data transfer (not charge-only)
    echo.
    echo ================================================================================
    pause
    goto choice
)

echo Device detected! Starting scrcpy via USB...
scrcpy -d --video-codec=h264 --max-size=1080
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo ERROR: scrcpy failed to start
    echo ================================================================================
    pause
)
title   Connected.
pause
goto exit

:newipstart
cls
echo.
echo.
echo Do you want to enter a new IP address? (Yes=1 / No=0)
set /p "starwars=Your choice: "
if not defined starwars goto newipstart
if "%starwars%"=="1" goto newip
if "%starwars%"=="0" goto choice
if "%starwars%"=="2" goto choice
if "%starwars%"=="6" goto exit
if "%starwars%"=="4" goto newipstart
echo.
echo Invalid input. Please enter 1 for Yes or 0 for No.
timeout 2 /nobreak >nul
goto newipstart

:newip
title   setting up new IP connection....
cls
echo.
echo ================================================================================
echo                          NEW IP ADDRESS SETUP
echo ================================================================================
echo.
echo To find your device's IP address:
echo   1. Open Settings on your Android device
echo   2. Go to: About Phone ^> Status ^> IP Address
echo      OR: Settings ^> Wi-Fi ^> Current Network ^> IP Address
echo.
echo ================================================================================
echo.
echo Enter your device's IP address (e.g., 192.168.18.11):
set "ipaddress="
set /p "ipaddress=IP Address: "

rem Validate IP is not empty
if not defined ipaddress (
    echo.
    echo ERROR: No IP address entered. Please try again.
    timeout 2 /nobreak >nul
    goto newip
)

rem Remove any spaces
set "ipaddress=%ipaddress: =%"

rem Basic validation - check if it contains dots
echo %ipaddress% | findstr /C:"." >nul
if errorlevel 1 (
    echo.
    echo ERROR: Invalid IP format
    echo Please enter a valid IP address like 192.168.1.100
    timeout 3 /nobreak >nul
    goto newip
)

rem Save IP to file in current directory
echo %ipaddress%>"%~dp0lastip.txt"
if errorlevel 1 (
    echo WARNING: Failed to save IP address
    echo Will continue with this session only
    timeout 3 /nobreak >nul
) else (
    echo.
    echo IP address %ipaddress% saved successfully!
    timeout 1 /nobreak >nul
)

rem Check if adb is available
where adb >nul 2>&1
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo ERROR: ADB not found in PATH
    echo ================================================================================
    pause
    goto exit
)

rem Check if scrcpy is available
where scrcpy >nul 2>&1
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo ERROR: scrcpy not found in PATH
    echo ================================================================================
    pause
    goto exit
)

echo.
echo Attempting to connect to stored ip %ipaddress%:5555...
adb connect %ipaddress%:5555 >nul 2>&1
timeout 2 /nobreak >nul

echo Testing connection with scrcpy...
scrcpy -s %ipaddress%:5555 --video-codec=h264 --max-size=1080 2>nul
if not errorlevel 1 (
    title   Connected.
    pause
    goto exit
)

echo.
echo ================================================================================
echo                           CONNECTION FAILED
echo ================================================================================
echo.
echo Please confirm the following:
echo   - Wireless debugging is ENABLED on your device
echo   - Device IP address is correct: %ipaddress%
echo   - Both devices are on the SAME Wi-Fi network
echo.
echo ================================================================================
echo.
echo Do you want to continue with automatic troubleshooting? (Yes=1 / No=0)
set /p "continue=Your choice: "
if "!continue!"=="0" goto choice
if "!continue!"=="2" goto choice

echo.
echo Attempting automatic fixes...
echo.
echo [Step 1/2] Restarting ADB server...
adb kill-server >nul 2>&1
timeout 1 /nobreak >nul
adb start-server >nul 2>&1
timeout 2 /nobreak >nul

echo [Step 2/2] Retrying connection to stored ip %ipaddress%:5555...
adb connect %ipaddress%:5555 >nul 2>&1
timeout 2 /nobreak >nul

echo Testing connection with scrcpy...
scrcpy -s %ipaddress%:5555 --video-codec=h264 --max-size=1080 2>nul
if not errorlevel 1 (
    title   Connected.
    pause
    goto exit
)

echo.
echo ================================================================================
echo Automatic troubleshooting failed. Trying TCP/IP mode setup...
echo.
echo IMPORTANT: Please connect your device via USB cable now
echo ================================================================================
timeout 3 /nobreak >nul

adb tcpip 5555
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo WARNING: Failed to enable TCP/IP mode
    echo Make sure device is connected via USB first
    echo ================================================================================
    echo.
    echo What would you like to do next?
    echo   1 - Retry with same IP
    echo   2 - Connect via USB instead
    echo   3 - Enter a different IP address
    echo   0 - Exit to main menu
    echo.
    set /p "retry=Your choice: "
    if "!retry!"=="1" goto ip
    if "!retry!"=="2" goto usb
    if "!retry!"=="3" goto newip
    goto exit
)

timeout 2 /nobreak >nul
echo Connecting to %ipaddress%:5555...
adb connect %ipaddress%:5555
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo ERROR: Still unable to connect
    echo ================================================================================
    echo.
    echo Double-check:
    echo   - Device is on the same Wi-Fi network
    echo   - TCP/IP debugging is enabled
    echo   - IP address is correct: %ipaddress%
    echo.
    echo What would you like to do next?
    echo   1 - Retry with same IP
    echo   2 - Connect via USB instead
    echo   3 - Enter a different IP address
    echo   0 - Exit to main menu
    echo.
    set /p "retry=Your choice: "
    if "!retry!"=="1" goto ip
    if "!retry!"=="2" goto usb
    if "!retry!"=="3" goto newip
    goto exit
)

timeout 1 /nobreak >nul
echo Starting scrcpy...
scrcpy -s %ipaddress%:5555 --video-codec=h264 --max-size=1080
if errorlevel 1 (
    echo.
    echo ================================================================================
    echo ERROR: scrcpy failed to start
    echo ================================================================================
    pause
)
title   Connected.
pause
goto exit

:exit
title   disconnected.
cls
echo.
echo.
echo ================================================================================
echo                        SESSION ENDED
echo ================================================================================
echo.
echo Would you like to:
echo   1 - Exit program
echo   2 - Return to main menu
echo   3 - Connect with new IP
echo.
set /p "starwars=Your choice: "
if not defined starwars goto exitnow
if "%starwars%"=="0" goto choice
if "%starwars%"=="2" goto choice
if "%starwars%"=="1" goto exitnow
if "%starwars%"=="4" goto newipstart
if "%starwars%"=="6" goto newipstart
if "%starwars%"=="3" goto newipstart
echo.
echo Invalid input. Please enter a valid option.
timeout 2 /nobreak >nul
goto exit

:exitnow
title   exiting....
cls
echo.
echo ================================================================================
echo                    Thank you for using scrcpy Manager!
echo ================================================================================
echo.
timeout 1 /nobreak >nul
rem color 06
echo Goodbye!
echo.
timeout 2 /nobreak >nul
cls
exit
