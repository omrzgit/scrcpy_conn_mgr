@echo off
setlocal enabledelayedexpansion
mode con: cols=103 lines=30 >nul 2>&1

rem Default Scrcpy Flags & Preset
set "SCRCPY_FLAGS=--video-codec=h264 --max-size=1080"
set "RES_NAME=1080p Balanced"
set "WINDOW_MODE=HIDE"
set "ALWAYS_ON_TOP=0"

rem Check if nircmd is available (check script folder first, then PATH)
if exist "%~dp0nircmd.exe" (
    set "NIRCMD_EXE=%~dp0nircmd.exe"
    set "NIRCMD_AVAILABLE=1"
) else (
    where nircmd >nul 2>&1
    if not errorlevel 1 (
        set "NIRCMD_EXE=nircmd"
        set "NIRCMD_AVAILABLE=1"
    ) else (
        set "NIRCMD_EXE="
        set "NIRCMD_AVAILABLE=0"
    )
)

rem Dispatch subroutine if called externally with a label argument
if not "%~1"=="" goto %~1

:start
color 07
title   scrcpy Connection Manager
cls
echo ================================================================================
echo                        SCRCPY CONNECTION MANAGER v4.0
echo ================================================================================
echo.
echo  This program helps you connect to your Android device using scrcpy.
echo.
echo  Features:
echo    1. WIRELESS (TCP/IP) - Connect over Wi-Fi using device IP address
echo    2. ANDROID 11+ PAIRING - Automatic pairing wizard for dynamic Wi-Fi ports
echo    3. USB CABLE - Direct connection via USB cable with TCP/IP bootstrap
echo    4. DEVICE ALIASES - Assign friendly nicknames to your devices
echo    5. RESOLUTION PRESETS - Quick toggle between 1080p, 720p, 480p, and Native
echo    6. SELF-HEALING ENGINE - Automated socket clearing and multi-device routing
echo.
echo ================================================================================
echo.
pause
goto choice

:choice
title   scrcpy Connection Manager - Initialising...
timeout 1 /nobreak >nul 2>&1
cls
echo.
echo.

rem Check if IP file exists
if not exist "%~dp0lastip.txt" (
    echo  No saved IPs found. Setting up new IP address...
    timeout 2 /nobreak >nul 2>&1
    goto newip
)

rem Check for old format and convert if needed
call :checkandconvert

rem Parse and load IP data
call :parseipdata

if !ipcount!==0 (
    echo  No saved IPs found. Setting up new IP address...
    timeout 2 /nobreak >nul 2>&1
    goto newip
)

rem Show saved IPs and ask to auto-connect
echo  Found !ipcount! saved IP address(es):
echo.
for /l %%i in (1,1,!ipcount!) do (
    set "displaymark="
    if "!savedipmarker%%i!"=="LAST" set "displaymark=*"
    set "alias_display="
    if defined savedipalias%%i (
        if not "!savedipalias%%i!"=="-" if not "!savedipalias%%i!"=="" (
            set "alias_display= (!savedipalias%%i!)"
        )
    )
    if defined savediptime%%i (
        echo    IP %%i: !savedip%%i!!alias_display!  [!savediptime%%i!] !displaymark!
    ) else (
        echo    IP %%i: !savedip%%i!!alias_display!  [Never used] !displaymark!
    )
)
echo.
echo  Do you want to automatically try all saved IPs? (1=Yes / 0=No)
set /p "autoconnect=Your choice: "

if "!autoconnect!"=="1" goto tryall
if /i "!autoconnect!"=="Y" goto tryall
if /i "!autoconnect!"=="y" goto tryall
if "!autoconnect!"=="02" goto manualselect
if "!autoconnect!"=="03" goto newip
if "!autoconnect!"=="04" goto manageips
if "!autoconnect!"=="05" goto usb
if "!autoconnect!"=="00" goto manualmenu
if "!autoconnect!"=="000" goto manualmenu

rem If user chose not to auto-connect, show manual menu
:manualmenu
cls
echo.
echo  ================================================================================
echo                              MANUAL CONNECTION MENU
echo  ================================================================================
echo.
echo  Saved IP addresses:
echo.

rem Reload data to ensure it's current
call :parseipdata

for /l %%i in (1,1,!ipcount!) do (
    set "displaymark="
    if "!savedipmarker%%i!"=="LAST" set "displaymark=*"
    set "alias_display="
    if defined savedipalias%%i (
        if not "!savedipalias%%i!"=="-" if not "!savedipalias%%i!"=="" (
            set "alias_display= (!savedipalias%%i!)"
        )
    )
    if defined savediptime%%i (
        echo    %%i. !savedip%%i!!alias_display!  [!savediptime%%i!] !displaymark!
    ) else (
        echo    %%i. !savedip%%i!!alias_display!  [Never used] !displaymark!
    )
)
echo.
echo  Options:
echo    1 - Auto-try all saved IPs
echo    2 - Select specific IP to connect
echo    3 - Add new IP address / Android 11+ Pairing
echo    4 - Manage saved IPs (remove / set alias)
echo    5 - Change Resolution Preset (Current: !RES_NAME!)
echo    6 - Try USB connection
echo    7 - Window ^& Display Settings
echo    0 - Exit program

echo.
set /p "menuchoice=Your choice: "

if "!menuchoice!"=="1" goto tryall
if "!menuchoice!"=="2" goto manualselect
if "!menuchoice!"=="3" goto newip
if "!menuchoice!"=="4" goto manageips
if "!menuchoice!"=="5" goto changeres
if "!menuchoice!"=="6" goto usb
if "!menuchoice!"=="7" goto windowsettings
if "!menuchoice!"=="0" goto exitnow
echo.
echo  Invalid choice. Please try again.
timeout 2 /nobreak >nul 2>&1
goto manualmenu

:changeres
cls
echo.
echo  ================================================================================
echo                       RESOLUTION & QUALITY PRESET
echo  ================================================================================
echo.
echo  Current Preset: !RES_NAME!
echo  Active Flags  : !SCRCPY_FLAGS!
echo.
echo  Select a preset:
echo    1 - 1080p Balanced (Default - 1080p, 8Mbps h264)
echo    2 - 720p Low Latency (Fast - 720p, 4Mbps, 30fps) - Recommended for Wi-Fi
echo    3 - 480p High Speed (Smooth - 480p, 2Mbps, 30fps) - Weak Wi-Fi
echo    4 - Native / Uncapped (Maximum fidelity for USB or Wi-Fi 6)
echo    0 - Back to Menu
echo.
set /p "reschoice=Your choice: "
if "!reschoice!"=="1" (
    set "SCRCPY_FLAGS=--video-codec=h264 --max-size=1080"
    set "RES_NAME=1080p Balanced"
    echo  Preset changed to 1080p Balanced.
    timeout 1 /nobreak >nul 2>&1
    goto manualmenu
)
if "!reschoice!"=="2" (
    set "SCRCPY_FLAGS=--video-codec=h264 --max-size=720 --video-bit-rate=4M --max-fps=30"
    set "RES_NAME=720p Low Latency"
    echo  Preset changed to 720p Low Latency.
    timeout 1 /nobreak >nul 2>&1
    goto manualmenu
)
if "!reschoice!"=="3" (
    set "SCRCPY_FLAGS=--video-codec=h264 --max-size=480 --video-bit-rate=2M --max-fps=30"
    set "RES_NAME=480p High Speed"
    echo  Preset changed to 480p High Speed.
    timeout 1 /nobreak >nul 2>&1
    goto manualmenu
)
if "!reschoice!"=="4" (
    set "SCRCPY_FLAGS=--video-codec=h264"
    set "RES_NAME=Native / Uncapped"
    echo  Preset changed to Native / Uncapped.
    timeout 1 /nobreak >nul 2>&1
    goto manualmenu
)
if "!reschoice!"=="0" goto manualmenu
echo  Invalid choice.
timeout 1 /nobreak >nul 2>&1
goto changeres

:windowsettings
cls
echo.
echo  ================================================================================
echo                        WINDOW & DISPLAY SETTINGS
echo  ================================================================================
echo.
echo  1. Window Minimization Mode: [!WINDOW_MODE!]
echo     (MINIMIZE = Minimize to taskbar during mirror)
echo     (TRAY     = Completely hide CMD window to tray/background during mirror)
echo.
echo  2. Always On Top: [!ALWAYS_ON_TOP!]
echo     (1 = Scrcpy window stays on top of other windows)
echo     (0 = Standard window behavior)
echo.
echo  Options:
echo    1 - Toggle Window Minimization Mode (Taskbar / Tray)
echo    2 - Toggle Always on Top (On / Off)
echo    0 - Back to Menu
echo.
set /p "winchoice=Your choice: "
if "!winchoice!"=="1" (
    if "!WINDOW_MODE!"=="MINIMIZE" (
        set "WINDOW_MODE=TRAY"
        echo  Window mode set to TRAY [Hide window].
    ) else (
        set "WINDOW_MODE=MINIMIZE"
        echo  Window mode set to MINIMIZE [Taskbar].
    )
    timeout 1 /nobreak >nul 2>&1
    goto windowsettings
)
if "!winchoice!"=="2" (
    if "!ALWAYS_ON_TOP!"=="0" (
        set "ALWAYS_ON_TOP=1"
        echo  Always On Top ENABLED.
    ) else (
        set "ALWAYS_ON_TOP=0"
        echo  Always On Top DISABLED.
    )
    timeout 1 /nobreak >nul 2>&1
    goto windowsettings
)
if "!winchoice!"=="0" goto manualmenu
goto windowsettings

:checktools
rem Subroutine to check if ADB and scrcpy are available (check local folder first, then PATH)
where adb >nul 2>&1
if errorlevel 1 (
    if not exist "%~dp0adb.exe" (
        echo  ================================================================================
        echo  ERROR: ADB not found in PATH or script directory
        echo  Please install Android SDK Platform Tools
        echo  ================================================================================
        pause
        set "toolcheck_failed=1"
        goto :eof
    )
)

where scrcpy >nul 2>&1
if errorlevel 1 (
    if not exist "%~dp0scrcpy.exe" (
        echo  ================================================================================
        echo  ERROR: scrcpy not found in PATH or script directory
        echo  Please install scrcpy from https://github.com/Genymobile/scrcpy
        echo  ================================================================================
        pause
        set "toolcheck_failed=1"
        goto :eof
    )
)

set "toolcheck_failed=0"
goto :eof

:parseipdata
rem Parse IP data from file into arrays (using - as placeholder for empty fields)
set ipcount=0
if exist "%~dp0lastip.txt" (
    for /f "usebackq tokens=1,2,3,4* delims=|" %%a in ("%~dp0lastip.txt") do (
        set "clean_ip=%%a"
        set "clean_ip=!clean_ip: =!"
        if defined clean_ip (
            set /a ipcount+=1
            set "savedip!ipcount!=!clean_ip!"
            
            set "clean_time=%%b"
            if not defined clean_time set "clean_time=Never used"
            if "!clean_time!"=="-" set "clean_time=Never used"
            set "savediptime!ipcount!=!clean_time!"
            
            set "clean_mark=%%c"
            if not defined clean_mark set "clean_mark=-"
            set "clean_mark=!clean_mark: =!"
            set "savedipmarker!ipcount!=!clean_mark!"
            
            set "clean_alias=%%d"
            if not defined clean_alias set "clean_alias=-"
            set "savedipalias!ipcount!=!clean_alias!"
        )
    )
)
goto :eof

:checkandconvert
rem Check if file is in old format and convert to standard 4-field format: IP|TIMESTAMP|MARKER|ALIAS
set "tempfile=%~dp0temp_convert.txt"
if exist "!tempfile!" del "!tempfile!"

if exist "%~dp0lastip.txt" (
    for /f "usebackq delims=" %%l in ("%~dp0lastip.txt") do (
        set "line=%%l"
        set "line=!line: =!"
        if defined line (
            rem Check how many pipes exist
            set "p1="
            set "p2="
            set "p3="
            set "p4="
            for /f "tokens=1,2,3,4* delims=|" %%a in ("%%l") do (
                set "p1=%%a"
                set "p2=%%b"
                set "p3=%%c"
                set "p4=%%d"
            )
            set "p1=!p1: =!"
            if not defined p2 set "p2=Never used"
            if "!p2!"=="" set "p2=Never used"
            if not defined p3 set "p3=-"
            if "!p3!"=="" set "p3=-"
            if not defined p4 set "p4=-"
            if "!p4!"=="" set "p4=-"
            echo !p1!^|!p2!^|!p3!^|!p4!>>"!tempfile!"
        )
    )
    if exist "!tempfile!" (
        del "%~dp0lastip.txt"
        move "!tempfile!" "%~dp0lastip.txt" >nul 2>&1
    )
)
goto :eof

:updateipsuccess
rem Update IP with current timestamp and mark as LAST (preserving alias)
set "targetip=%~1"
if "!targetip!"==":updateipsuccess" set "targetip=%~2"
if "!targetip!"=="updateipsuccess" set "targetip=%~2"
set "tempfile=%~dp0temp_ips.txt"
if exist "!tempfile!" del "!tempfile!"

rem Get current timestamp (YYYY-MM-DD HH:MM)
set "timestamp="
for /f "usebackq tokens=*" %%a in (`powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd HH:mm'" 2^>nul`) do set "timestamp=%%a"
if not defined timestamp (
    for /f "tokens=2 delims==" %%a in ('wmic OS Get localdatetime /value 2^>nul') do (
        set "dt=%%a"
        set "timestamp=!dt:~0,4!-!dt:~4,2!-!dt:~6,2! !dt:~8,2!:!dt:~10,2!"
    )
)
if not defined timestamp set "timestamp=%date% %time:~0,5%"

rem Write updated file with new LAST marker preserving aliases
for /f "usebackq tokens=1,2,3,4* delims=|" %%a in ("%~dp0lastip.txt") do (
    set "cur_ip=%%a"
    set "cur_ip=!cur_ip: =!"
    set "cur_alias=%%d"
    if not defined cur_alias set "cur_alias=-"
    if "!cur_alias!"=="" set "cur_alias=-"
    
    if "!cur_ip!"=="!targetip!" (
        echo !cur_ip!^|!timestamp!^|LAST^|!cur_alias!>>!tempfile!
    ) else (
        echo !cur_ip!^|%%b^|-^|!cur_alias!>>!tempfile!
    )
)

del "%~dp0lastip.txt"
move "!tempfile!" "%~dp0lastip.txt" >nul 2>&1

rem Reload data
call :parseipdata
goto :eof

:minimizewindow
rem Completely hide the CMD/Terminal window from desktop and taskbar before launching scrcpy
if "!NIRCMD_AVAILABLE!"=="1" (
    rem Windows Terminal [Windows 11] - Hide completely (off screen and off taskbar)
    "!NIRCMD_EXE!" win hide class "CASCADIA_HOSTING_WINDOW_CLASS" >nul 2>&1
    "!NIRCMD_EXE!" win hide process "WindowsTerminal.exe" >nul 2>&1
    rem Legacy Command Prompt & Title targeting
    "!NIRCMD_EXE!" win hide ititle "scrcpy Connection Manager" >nul 2>&1
    "!NIRCMD_EXE!" win hide class "ConsoleWindowClass" >nul 2>&1
    "!NIRCMD_EXE!" win hide foreground >nul 2>&1
) else (
    rem Safe portable PowerShell minimization [no temp files]
    powershell -NoProfile -Command "(New-Object -ComObject WScript.Shell).SendKeys('%% n')" >nul 2>&1
)
goto :eof

:restorewindow
rem Unhide, restore, and pop the CMD/Terminal window back to the foreground so the user can see it and close it
if "!NIRCMD_AVAILABLE!"=="1" (
    rem Windows Terminal [Windows 11]
    "!NIRCMD_EXE!" win show class "CASCADIA_HOSTING_WINDOW_CLASS" >nul 2>&1
    "!NIRCMD_EXE!" win normal class "CASCADIA_HOSTING_WINDOW_CLASS" >nul 2>&1
    "!NIRCMD_EXE!" win activate class "CASCADIA_HOSTING_WINDOW_CLASS" >nul 2>&1
    "!NIRCMD_EXE!" win settopmost class "CASCADIA_HOSTING_WINDOW_CLASS" 1 >nul 2>&1
    "!NIRCMD_EXE!" win settopmost class "CASCADIA_HOSTING_WINDOW_CLASS" 0 >nul 2>&1
    "!NIRCMD_EXE!" win show process "WindowsTerminal.exe" >nul 2>&1
    "!NIRCMD_EXE!" win normal process "WindowsTerminal.exe" >nul 2>&1
    "!NIRCMD_EXE!" win activate process "WindowsTerminal.exe" >nul 2>&1
    rem Legacy Command Prompt & Title targeting
    "!NIRCMD_EXE!" win show ititle "scrcpy Connection Manager" >nul 2>&1
    "!NIRCMD_EXE!" win normal ititle "scrcpy Connection Manager" >nul 2>&1
    "!NIRCMD_EXE!" win activate ititle "scrcpy Connection Manager" >nul 2>&1
    "!NIRCMD_EXE!" win settopmost ititle "scrcpy Connection Manager" 1 >nul 2>&1
    "!NIRCMD_EXE!" win settopmost ititle "scrcpy Connection Manager" 0 >nul 2>&1
    "!NIRCMD_EXE!" win show class "ConsoleWindowClass" >nul 2>&1
    "!NIRCMD_EXE!" win normal class "ConsoleWindowClass" >nul 2>&1
    "!NIRCMD_EXE!" win activate class "ConsoleWindowClass" >nul 2>&1
    "!NIRCMD_EXE!" win focus ititle "scrcpy Connection Manager" >nul 2>&1
) else (
    powershell -NoProfile -Command "(New-Object -ComObject WScript.Shell).AppActivate('scrcpy Connection Manager')" >nul 2>&1
)
goto :eof

:launchscrcpy
rem Helper subroutine to build scrcpy arguments and launch cleanly
set "launch_target=%~1"
set "EXTRA_FLAGS="
if "!ALWAYS_ON_TOP!"=="1" set "EXTRA_FLAGS=--always-on-top"

call :minimizewindow
scrcpy -s !launch_target! !SCRCPY_FLAGS! !EXTRA_FLAGS!
call :restorewindow
goto :eof

:tryall
title   scrcpy Connection Manager - Trying saved IPs...

rem Check if tools are available first
call :checktools
if "!toolcheck_failed!"=="1" goto exit

echo.
echo  Attempting automatic connection to all saved IPs...
echo.

for /l %%i in (1,1,!ipcount!) do (
    set "alias_display="
    if defined savedipalias%%i (
        if not "!savedipalias%%i!"=="-" if not "!savedipalias%%i!"=="" (
            set "alias_display= (!savedipalias%%i!)"
        )
    )
    echo  [%%i/!ipcount!] Trying !savedip%%i!:5555!alias_display!...
    
    rem Clear any stale socket before attempting connection
    adb disconnect !savedip%%i!:5555 >nul 2>&1
    
    adb connect !savedip%%i!:5555 >nul 2>&1
    timeout 2 /nobreak >nul 2>&1
    
    rem Verify connection before launching scrcpy
    adb devices | findstr "!savedip%%i!:5555" | findstr "device$" >nul 2>&1
    if not errorlevel 1 (
        echo  Connection established! Starting scrcpy...
        
        call :launchscrcpy "!savedip%%i!:5555"
        
        title   scrcpy Connection Manager - Connected to !savedip%%i!
        set "savedip=!savedip%%i!"
        echo.
        echo  Successfully connected to !savedip%%i!!
        
        rem Update timestamp and LAST marker
        call :updateipsuccess "!savedip!"
        
        rem Move successful IP to top of list
        call :moveiptotop "!savedip!"
        
        timeout 2 /nobreak >nul 2>&1
        goto reconnect
    )
    echo     Failed.
    echo.
)

echo  ================================================================================
echo  All saved IPs failed to connect
echo  ================================================================================
echo.
echo  What would you like to do?
echo    1 - Retry all saved IPs again
echo    2 - Retry specific saved IP
echo    3 - Add new IP / Android 11+ Pairing
echo    4 - Manage saved IPs (remove / alias)
echo    5 - Try USB connection
echo    0 - Exit program
echo.
set /p "retry=Your choice: "
if "!retry!"=="1" goto tryall
if "!retry!"=="2" goto manualselect
if "!retry!"=="3" goto newip
if "!retry!"=="4" goto manageips
if "!retry!"=="5" goto usb
if "!retry!"=="0" goto exitnow
goto manualmenu

:manageips
cls
echo.
echo  ================================================================================
echo                           MANAGE SAVED IP ADDRESSES
echo  ================================================================================
echo.
echo  Currently saved IPs:
echo.

rem Reload IPs in case of changes
call :parseipdata

rem Display IPs
if !ipcount!==0 (
    echo    No IPs saved.
    echo.
    echo  Press any key to return to menu...
    pause >nul 2>&1
    goto manualmenu
)

for /l %%i in (1,1,!ipcount!) do (
    set "displaymark="
    if "!savedipmarker%%i!"=="LAST" set "displaymark=*"
    set "alias_display="
    if defined savedipalias%%i (
        if not "!savedipalias%%i!"=="-" if not "!savedipalias%%i!"=="" (
            set "alias_display= (!savedipalias%%i!)"
        )
    )
    if defined savediptime%%i (
        echo    %%i. !savedip%%i!!alias_display!  [!savediptime%%i!] !displaymark!
    ) else (
        echo    %%i. !savedip%%i!!alias_display!  [Never used] !displaymark!
    )
)

echo.
echo  Options:
echo    - Enter number (1-!ipcount!) to remove that IP
echo    - Enter R to set or change a Device Nickname / Alias
echo    - Press 0 to return to menu
echo.
set /p "managechoice=Your choice: "

if "!managechoice!"=="0" goto manualmenu
if /i "!managechoice!"=="R" goto editalias

rem Check if valid number for removal
set /a testnum=!managechoice! 2>nul
if !testnum! GEQ 1 if !testnum! LEQ !ipcount! (
    set "iptoremove=!savedip%managechoice%!"
    echo.
    echo  Are you sure you want to remove !iptoremove!? [1=Yes / 0=No]
    set /p "confirmremove=Your choice: "
    if "!confirmremove!"=="1" (
        call :removeip "!iptoremove!"
        echo.
        echo  IP !iptoremove! removed successfully!
        timeout 2 /nobreak >nul 2>&1
        
        rem Check if there are still IPs left
        call :parseipdata
        if !ipcount!==0 (
            echo  No more IPs saved. Redirecting to add new IP...
            timeout 2 /nobreak >nul 2>&1
            goto newip
        )
        goto manageips
    ) else (
        goto manageips
    )
) else (
    echo.
    echo  Invalid choice. Please try again.
    timeout 2 /nobreak >nul 2>&1
    goto manageips
)

:editalias
cls
echo.
echo  ================================================================================
echo                          SET / EDIT DEVICE ALIAS
echo  ================================================================================
echo.
for /l %%i in (1,1,!ipcount!) do (
    set "alias_display="
    if defined savedipalias%%i (
        if not "!savedipalias%%i!"=="-" if not "!savedipalias%%i!"=="" (
            set "alias_display= (!savedipalias%%i!)"
        )
    )
    echo    %%i. !savedip%%i!!alias_display!
)
echo.
echo  Select IP number to edit alias (or 0 to cancel):
set /p "aliasnum=Choice: "
if "!aliasnum!"=="0" goto manageips
set /a atest=!aliasnum! 2>nul
if !atest! GEQ 1 if !atest! LEQ !ipcount! (
    set "targetaliasip=!savedip%aliasnum%!"
    echo.
    echo  Enter new nickname/alias for !targetaliasip! [or - to clear]:
    set "newalias="
    set /p "newalias=Alias: "
    if not defined newalias set "newalias=-"
    if "!newalias!"=="" set "newalias=-"
    
    set "tempfile=%~dp0temp_ips.txt"
    if exist "!tempfile!" del "!tempfile!"
    for /f "usebackq tokens=1,2,3,4* delims=|" %%a in ("%~dp0lastip.txt") do (
        set "chkip=%%a"
        set "chkip=!chkip: =!"
        if "!chkip!"=="!targetaliasip!" (
            echo !chkip!^|%%b^|%%c^|!newalias!>>!tempfile!
        ) else (
            echo !chkip!^|%%b^|%%c^|%%d>>!tempfile!
        )
    )
    del "%~dp0lastip.txt"
    move "!tempfile!" "%~dp0lastip.txt" >nul 2>&1
    call :parseipdata
    echo  Alias updated successfully!
    timeout 1 /nobreak >nul 2>&1
    goto manageips
)
echo  Invalid selection.
timeout 1 /nobreak >nul 2>&1
goto editalias

:removeip
rem Create temp file without the IP to remove
set "target_remove=%~1"
if "!target_remove!"==":removeip" set "target_remove=%~2"
if "!target_remove!"=="removeip" set "target_remove=%~2"
set "tempfile=%~dp0temp_ips.txt"
if exist "!tempfile!" del "!tempfile!"
for /f "usebackq tokens=1,2,3,4* delims=|" %%a in ("%~dp0lastip.txt") do (
    set "chkip=%%a"
    set "chkip=!chkip: =!"
    if not "!chkip!"=="!target_remove!" (
        echo !chkip!^|%%b^|%%c^|%%d>>!tempfile!
    )
)
del "%~dp0lastip.txt"
if exist "!tempfile!" (
    move "!tempfile!" "%~dp0lastip.txt" >nul 2>&1
)
goto :eof

:moveiptotop
rem Move the selected IP to the top of the list (preserving timestamp and alias)
set "selectedip=%~1"
if "!selectedip!"==":moveiptotop" set "selectedip=%~2"
if "!selectedip!"=="moveiptotop" set "selectedip=%~2"
set "tempfile=%~dp0temp_ips.txt"

if exist "!tempfile!" del "!tempfile!"

rem First, write the selected IP at the top
for /f "usebackq tokens=1,2,3,4* delims=|" %%a in ("%~dp0lastip.txt") do (
    set "chkip=%%a"
    set "chkip=!chkip: =!"
    if "!chkip!"=="!selectedip!" (
        echo !chkip!^|%%b^|%%c^|%%d>!tempfile!
        goto :writemoverest
    )
)

:writemoverest
rem Add all other IPs (excluding the selected one)
for /f "usebackq tokens=1,2,3,4* delims=|" %%a in ("%~dp0lastip.txt") do (
    set "chkip=%%a"
    set "chkip=!chkip: =!"
    if not "!chkip!"=="!selectedip!" (
        echo !chkip!^|%%b^|%%c^|%%d>>!tempfile!
    )
)

del "%~dp0lastip.txt"
move "!tempfile!" "%~dp0lastip.txt" >nul 2>&1

rem Reload the IPs into memory
call :parseipdata
goto :eof

:manualselect
cls
echo.
echo  Select an IP address to connect:
echo.
for /l %%i in (1,1,!ipcount!) do (
    set "displaymark="
    if "!savedipmarker%%i!"=="LAST" set "displaymark=*"
    set "alias_display="
    if defined savedipalias%%i (
        if not "!savedipalias%%i!"=="-" if not "!savedipalias%%i!"=="" (
            set "alias_display= (!savedipalias%%i!)"
        )
    )
    if defined savediptime%%i (
        echo    %%i. !savedip%%i!!alias_display!  [!savediptime%%i!] !displaymark!
    ) else (
        echo    %%i. !savedip%%i!!alias_display!  [Never used] !displaymark!
    )
)
echo.
echo    0 - Return to menu
echo.
set /p "ipchoice=Your choice: "

if "!ipchoice!"=="0" goto manualmenu
set /a testnum=!ipchoice! 2>nul
if !testnum! GEQ 1 if !testnum! LEQ !ipcount! (
    set "savedip=!savedip%ipchoice%!"
    
    rem Move selected IP to top of list
    call :moveiptotop "!savedip!"
    
    goto connectip
)

echo.
echo  Invalid choice. Please try again.
timeout 2 /nobreak >nul 2>&1
goto manualselect

:connectip
title   scrcpy Connection Manager - Connecting to !savedip!...

rem Check tools before connecting
call :checktools
if "!toolcheck_failed!"=="1" goto exit

echo.
echo  Attempting to connect to !savedip!:5555...

rem Clear stale socket
adb disconnect !savedip!:5555 >nul 2>&1

adb connect !savedip!:5555 >nul 2>&1
timeout 3 /nobreak >nul 2>&1

rem Verify connection
adb devices | findstr "!savedip!:5555" | findstr "device$" >nul 2>&1
if not errorlevel 1 (
    echo  Connection established! Starting scrcpy...
    
    call :launchscrcpy "!savedip!:5555"
    
    title   scrcpy Connection Manager - Connected to !savedip!
    echo.
    echo  Connection successful!
    
    rem Update timestamp and LAST marker
    call :updateipsuccess "!savedip!"
    
    timeout 2 /nobreak >nul 2>&1
    goto reconnect
)

:troubleshoot
echo.
echo  ================================================================================
echo                            CONNECTION FAILED
echo  ================================================================================
echo.
echo  Target IP: !savedip!
echo.
echo  Please confirm:
echo    - Wireless debugging is ENABLED on your device
echo    - Device IP address is correct: !savedip!
echo    - Both PC and Android device are on the SAME Wi-Fi network
echo.
echo  ================================================================================
echo.
echo  Do you want to continue with automatic troubleshooting? (1=Yes / 0=No)
set /p "continue=Your choice: "
if "!continue!"=="0" goto aftertroubleshoot
if "!continue!"=="2" goto aftertroubleshoot
if /i "!continue!"=="N" goto aftertroubleshoot
if /i "!continue!"=="n" goto aftertroubleshoot

echo.
echo  Attempting self-healing fixes...
echo.
echo  [Step 1/3] Clearing stale sockets and restarting ADB server...
adb disconnect !savedip!:5555 >nul 2>&1
adb kill-server >nul 2>&1
taskkill /f /im adb.exe >nul 2>&1
timeout 1 /nobreak >nul 2>&1
adb start-server >nul 2>&1
timeout 2 /nobreak >nul 2>&1

echo  [Step 2/3] Retrying connection to !savedip!:5555...
adb connect !savedip!:5555 >nul 2>&1
timeout 3 /nobreak >nul 2>&1

rem Verify connection
adb devices | findstr "!savedip!:5555" | findstr "device$" >nul 2>&1
if not errorlevel 1 (
    echo  Connection established! Starting scrcpy...
    
    call :launchscrcpy "!savedip!:5555"
    
    title   scrcpy Connection Manager - Connected to !savedip!
    echo.
    echo  Connection successful!
    
    rem Update timestamp and LAST marker
    call :updateipsuccess "!savedip!"
    
    timeout 2 /nobreak >nul 2>&1
    goto reconnect
)

:pair_ladder
echo.
echo  ================================================================================
echo             [Step 3/3] ANDROID 11+ WIRELESS PAIRING CHECK (REQUIRED)
echo  ================================================================================
echo   Android 11+ uses a random pairing port and a 6-digit Wi-Fi pairing code.
echo.
echo   Is your phone running Android 11 or higher?
echo     [Y] Yes          - Enter pairing port and 6-digit pairing code
echo     [N] No           - Skip pairing, proceed to USB cable setup
echo     [I] I Don't Know - Try Android 11+ pairing wizard
echo.
set "a11_answer="
set /p "a11_answer=Your choice (Y/N/I): "
if /i "!a11_answer!"=="y" goto pair_wizard
if /i "!a11_answer!"=="yes" goto pair_wizard
if /i "!a11_answer!"=="i" goto pair_wizard
if /i "!a11_answer!"=="idk" goto pair_wizard
if /i "!a11_answer!"=="n" goto troubleshoot_usb_fallback
if /i "!a11_answer!"=="no" goto troubleshoot_usb_fallback
echo.
echo  Invalid choice. Please enter Y, N, or I.
timeout 2 /nobreak >nul 2>&1
goto pair_ladder

:pair_wizard
cls
echo.
echo  ================================================================================
echo                        ANDROID 11+ WIRELESS SETUP
echo  ================================================================================
echo.
echo  Target IP: !savedip!
echo.
echo  Open on your phone:
echo    Settings -^> Developer Options -^> Wireless Debugging [Turn ON]
echo.
echo  Check the list under "Paired devices" at the bottom of the phone screen:
echo  Is your PC listed under "Paired devices"?
echo.
echo    1 - YES, my PC is already listed as paired
echo        ^> Just connect using the port shown under "IP address ^& Port"
echo.
echo    2 - NO, need to pair first [or re-pairing]
echo        ^> Tap "Pair device with pairing code" to get pairing port ^& 6-digit code
echo.
echo    0 - Return to Menu
echo.
set "already_paired_choice="
set /p "already_paired_choice=Your choice [1/2/0]: "
if "!already_paired_choice!"=="1" goto conn_port_input
if "!already_paired_choice!"=="2" goto pair_inputs_start
if "!already_paired_choice!"=="0" goto manualmenu
goto pair_wizard

:pair_inputs_start
echo.
echo  NOTE: If your PC is already listed under Paired devices on your phone,
echo        tap the gear icon next to it and tap "Forget" first.
echo.
echo  Now tap "Pair device with pairing code" on your phone:
echo  Keep the popup dialog open on your phone! It shows:
echo    - IP Address ^& Pairing Port [e.g. !savedip!:38472]
echo    - 6-digit Wi-Fi Pairing Code [e.g. 123456]
echo.

:pair_inputs
set "pairport="
set /p "pairport=Enter the PAIRING PORT from phone popup (or 0 to cancel): "
if not defined pairport (
    echo.
    echo  ERROR: Pairing port cannot be empty.
    echo.
    goto pair_inputs
)
set "pairport=!pairport: =!"
if "!pairport!"=="0" goto manualmenu

rem Check port is numeric
set "validport=1"
for /f "delims=0123456789" %%k in ("!pairport!") do set "validport=0"
if "!validport!"=="0" (
    echo.
    echo  ERROR: Port must contain numbers only. You entered "!pairport!".
    echo.
    goto pair_inputs
)

set /a portcheck=!pairport! 2>nul
if !portcheck! LEQ 0 (
    echo.
    echo  ERROR: Port must be greater than 0.
    echo.
    goto pair_inputs
)
if !portcheck! GTR 65535 (
    echo.
    echo  ERROR: Invalid port "!pairport!". Port numbers cannot exceed 65535.
    echo         [Did you enter the 6-digit pairing code here by accident?]
    echo.
    goto pair_inputs
)

:code_input
set "paircode="
set /p "paircode=Enter the 6-digit PAIRING CODE from phone popup (or 0 to re-enter port): "
if not defined paircode (
    echo.
    echo  ERROR: Pairing code cannot be empty.
    echo.
    goto code_input
)
set "paircode=!paircode: =!"
if "!paircode!"=="0" goto pair_inputs

rem Check code is numeric
set "validcode=1"
for /f "delims=0123456789" %%k in ("!paircode!") do set "validcode=0"
if "!validcode!"=="0" (
    echo.
    echo  ERROR: Pairing code must contain numbers only. You entered "!paircode!".
    echo.
    goto code_input
)

echo.
echo  --------------------------------------------------------------------------------
echo  CONFIRM PAIRING DETAILS:
echo    Device IP    : !savedip!
echo    Pairing Port : !pairport!
echo    Pairing Code : !paircode!
echo  --------------------------------------------------------------------------------
echo.
set "pair_confirm="
set /p "pair_confirm=Is this correct? (1=Yes, pair now / 0=No, re-enter details): "
if "!pair_confirm!"=="0" (
    echo.
    echo  Re-entering pairing details...
    timeout 1 /nobreak >nul 2>&1
    goto pair_inputs
)
if /i "!pair_confirm!"=="n" (
    echo.
    echo  Re-entering pairing details...
    timeout 1 /nobreak >nul 2>&1
    goto pair_inputs
)
if /i "!pair_confirm!"=="no" (
    echo.
    echo  Re-entering pairing details...
    timeout 1 /nobreak >nul 2>&1
    goto pair_inputs
)

echo.
echo  [*] Executing: adb pair !savedip!:!pairport! !paircode!
adb pair !savedip!:!pairport! !paircode!
if errorlevel 1 (
    echo.
    echo  ================================================================================
    echo  WARNING: adb pair reported an error.
    echo  ================================================================================
    echo  Common causes:
    echo    - The pairing popup dialog on your phone timed out or was closed
    echo    - The pairing port or code was mistyped
    echo.
    echo  What would you like to do?
    echo    1 - Re-enter pairing port and code [Default]
    echo    2 - Continue to connection port anyway
    echo    0 - Return to menu
    echo.
    set "pair_err_choice="
    set /p "pair_err_choice=Your choice [1/2/0, Enter=1]: "
    if "!pair_err_choice!"=="2" goto conn_port_input
    if "!pair_err_choice!"=="0" goto manualmenu
    goto pair_inputs
)

timeout 2 /nobreak >nul 2>&1

:conn_port_input
echo.
echo  --------------------------------------------------------------------------------
echo  CONNECTING TO DEVICE
echo  --------------------------------------------------------------------------------
echo  Look at the main "Wireless Debugging" screen on your phone.
echo  Check the connection port shown under "IP address ^& Port":
echo    [e.g. !savedip!:38637 or !savedip!:41641]
echo.
set "conn_port=5555"
set /p "conn_port=Enter connection port [Press Enter for default 5555]: "
if not defined conn_port set "conn_port=5555"
set "conn_port=!conn_port: =!"

set "validcport=1"
for /f "delims=0123456789" %%k in ("!conn_port!") do set "validcport=0"
if "!validcport!"=="0" (
    echo.
    echo  ERROR: Port must be numeric.
    goto conn_port_input
)
set /a cportcheck=!conn_port! 2>nul
if !cportcheck! LEQ 0 (
    echo.
    echo  ERROR: Invalid port "!conn_port!". Port must be between 1 and 65535.
    timeout 1 /nobreak >nul 2>&1
    goto conn_port_input
)
if !cportcheck! GTR 65535 (
    echo.
    echo  ERROR: Invalid port "!conn_port!". Port must be between 1 and 65535.
    timeout 2 /nobreak >nul 2>&1
    goto conn_port_input
)

echo.
echo  Connecting to !savedip!:!conn_port!...
adb connect !savedip!:!conn_port!
timeout 3 /nobreak >nul 2>&1

adb devices | findstr "!savedip!:!conn_port!" | findstr "device$" >nul 2>&1
if not errorlevel 1 (
    echo.
    echo  Connection established! Starting scrcpy...
    
    call :launchscrcpy "!savedip!:!conn_port!"
    
    title   scrcpy Connection Manager - Connected to !savedip!
    call :updateipsuccess "!savedip!"
    call :moveiptotop "!savedip!"
    timeout 2 /nobreak >nul 2>&1
    goto reconnect
) else (
    echo.
    echo  ================================================================================
    echo  Connection to !savedip!:!conn_port! could not be established.
    echo  ================================================================================
    echo.
    echo  What would you like to do?
    echo    1 - Try a different connection port
    echo    2 - Re-pair device [new pairing code from phone]
    echo    3 - Setup via USB cable
    echo    0 - Return to menu
    echo.
    set "post_conn_choice="
    set /p "post_conn_choice=Your choice [1/2/3/0]: "
    if "!post_conn_choice!"=="1" goto conn_port_input
    if "!post_conn_choice!"=="2" goto pair_inputs
    if "!post_conn_choice!"=="3" goto troubleshoot_usb_fallback
    goto manualmenu
)

:troubleshoot_usb_fallback
echo.
echo  ================================================================================
echo  Trying USB TCP/IP mode bootstrap...
echo.
echo  IMPORTANT: Please connect your device via USB cable now
echo  ================================================================================
timeout 3 /nobreak >nul 2>&1

rem Disambiguate USB device
set "USB_SERIAL="
for /f "tokens=1,2" %%u in ('adb devices ^| findstr /v "List" ^| findstr "device$"') do (
    echo %%u | findstr ":" >nul 2>&1
    if errorlevel 1 (
        set "USB_SERIAL=%%u"
    )
)

if defined USB_SERIAL (
    echo  Enabling TCP/IP on USB device [!USB_SERIAL!]...
    adb -s !USB_SERIAL! tcpip 5555
) else (
    adb tcpip 5555
)

if errorlevel 1 (
    echo.
    echo  ================================================================================
    echo  WARNING: Failed to enable TCP/IP mode via USB
    echo  ================================================================================
    goto aftertroubleshoot
)

timeout 2 /nobreak >nul 2>&1
echo  Connecting to !savedip!:5555...
adb connect !savedip!:5555
if errorlevel 1 (
    echo.
    echo  ================================================================================
    echo  ERROR: Still unable to connect
    echo  ================================================================================
    goto aftertroubleshoot
)

timeout 2 /nobreak >nul 2>&1

rem Verify final connection
adb devices | findstr "!savedip!:5555" | findstr "device$" >nul 2>&1
if not errorlevel 1 (
    echo  Connection established! Starting scrcpy...
    
    call :launchscrcpy "!savedip!:5555"
    
    title   scrcpy Connection Manager - Connected to !savedip!
    echo.
    echo  Connection successful!
    
    rem Update timestamp and LAST marker
    call :updateipsuccess "!savedip!"
    
    timeout 2 /nobreak >nul 2>&1
    goto reconnect
) else (
    echo.
    echo  ================================================================================
    echo  ERROR: scrcpy failed to start
    echo  ================================================================================
    echo.
    echo  This could be due to:
    echo    - Device not authorized [check device screen for prompt]
    echo    - Network connection issues
    echo    - Device screen is off
    echo.
    pause
)

:aftertroubleshoot
echo.
echo  What would you like to do next?
echo    1 - Retry with same IP
echo    2 - Try all saved IPs again
echo    3 - Enter a new IP address / Android 11+ Pairing
echo    4 - Connect via USB instead
echo    0 - Return to main menu
echo.
set /p "retry=Your choice: "
if "!retry!"=="1" goto connectip
if "!retry!"=="2" goto tryall
if "!retry!"=="3" goto newip
if "!retry!"=="4" goto usb
if "!retry!"=="0" goto manualmenu
goto aftertroubleshoot

:usb
title   scrcpy Connection Manager - Connecting via USB...
cls
echo.
echo.

rem Check tools before USB connection
call :checktools
if "!toolcheck_failed!"=="1" goto exit

echo  Checking for USB connected devices...
set "USB_DEVICE="
for /f "tokens=1,2" %%u in ('adb devices ^| findstr /v "List" ^| findstr "device$"') do (
    echo %%u | findstr ":" >nul 2>&1
    if errorlevel 1 (
        set "USB_DEVICE=%%u"
    )
)

if not defined USB_DEVICE (
    echo.
    echo  ================================================================================
    echo  ERROR: No USB devices found
    echo  ================================================================================
    echo.
    echo  Please verify:
    echo    - Device is connected via USB cable
    echo    - USB debugging is ENABLED in Developer Options
    echo    - Device is AUTHORIZED [check device screen for USB debugging prompt]
    echo    - USB cable supports data transfer [not charge-only]
    echo.
    echo  ================================================================================
    echo.
    echo  What would you like to do?
    echo    1 - Retry USB connection
    echo    2 - Try wireless connection
    echo    0 - Return to menu
    echo.
    set /p "usbretry=Your choice: "
    if "!usbretry!"=="1" goto usb
    if "!usbretry!"=="2" goto manualmenu
    if "!usbretry!"=="0" goto manualmenu
    goto manualmenu
)

echo  Device detected [!USB_DEVICE!]! Starting scrcpy via USB...

call :launchscrcpy "!USB_DEVICE!"

set "savedip=USB"
title   scrcpy Connection Manager - Connected via USB
echo.
echo  Connection successful!
timeout 2 /nobreak >nul 2>&1
goto reconnect

:newip
title   scrcpy Connection Manager - New IP Setup
cls
echo.
echo  ================================================================================
echo                           NEW IP ADDRESS SETUP
echo  ================================================================================
echo.
echo  To find your device's IP address:
echo    1. Open Settings on your Android device
echo    2. Go to: About Phone ^> Status ^> IP Address
echo       OR: Settings ^> Wi-Fi ^> Current Network ^> IP Address
echo.
echo  ================================================================================
echo.
echo  Enter your device's IP address (e.g., 192.168.18.11):
set "ipaddress="
set /p "ipaddress=IP Address: "

rem Validate IP is not empty
if not defined ipaddress (
    echo.
    echo  ERROR: No IP address entered. Please try again.
    timeout 2 /nobreak >nul 2>&1
    goto newip
)

rem Remove any spaces
set "ipaddress=%ipaddress: =%"

rem Basic validation - check if it contains dots
echo %ipaddress% | findstr /C:"." >nul 2>&1
if errorlevel 1 (
    echo.
    echo  ERROR: Invalid IP format
    echo  Please enter a valid IP address like 192.168.1.100
    timeout 3 /nobreak >nul 2>&1
    goto newip
)

echo.
echo  Optional: Enter a nickname/alias for this device (e.g. Omer Phone, Tablet):
set "ipalias="
set /p "ipalias=Device Alias (Press Enter to skip): "
if not defined ipalias set "ipalias=-"
if "!ipalias!"=="" set "ipalias=-"

rem Check if IP already exists
set "ipalreadyexists=0"
if exist "%~dp0lastip.txt" (
    for /f "usebackq tokens=1 delims=|" %%a in ("%~dp0lastip.txt") do (
        if "%%a"=="%ipaddress%" set "ipalreadyexists=1"
    )
)

if "!ipalreadyexists!"=="1" goto ip_already_exists

rem Add new IP to top of list (limit to 7 IPs)
set "tempfile=%~dp0temp_ips.txt"
if exist "!tempfile!" del "!tempfile!"

rem Write new IP first with "Never used" timestamp and alias
echo %ipaddress%^|Never used^|-^|%ipalias%>>!tempfile!

rem Add existing IPs (up to 6 more, total 7)
set addcount=0
if exist "%~dp0lastip.txt" (
    for /f "usebackq tokens=1,2,3,4* delims=|" %%a in ("%~dp0lastip.txt") do (
        if !addcount! LSS 6 (
            echo %%a^|%%b^|%%c^|%%d>>!tempfile!
            set /a addcount+=1
        )
    )
)

rem Replace original file
if exist "%~dp0lastip.txt" del "%~dp0lastip.txt"
move "!tempfile!" "%~dp0lastip.txt" >nul 2>&1

echo.
if !addcount! GEQ 6 (
    echo  Note: IP limit reached [7 max]. Oldest IP was removed.
)
echo  IP address %ipaddress% saved successfully at top of list!
timeout 1 /nobreak >nul 2>&1

set "savedip=%ipaddress%"

rem Reload IPs
call :parseipdata

rem Check tools before connecting
call :checktools
if "!toolcheck_failed!"=="1" goto exit
goto newip_connect_choice

:ip_already_exists
echo.
echo  ================================================================================
echo  This IP address [!ipaddress!] is already saved in your list!
echo  ================================================================================
echo.
echo  How would you like to connect?
echo    1 - Android 11+ Wireless Pairing Wizard [Pairing Port ^& Code]
echo    2 - Standard TCP/IP Port 5555 [Connect directly]
echo    3 - Enter a different IP
echo    0 - Return to menu
echo.
set "existchoice="
set /p "existchoice=Your choice [1/2/3/0]: "
if "!existchoice!"=="1" (
    set "savedip=%ipaddress%"
    call :moveiptotop "!savedip!"
    goto pair_wizard
)
if "!existchoice!"=="2" (
    set "savedip=%ipaddress%"
    call :moveiptotop "!savedip!"
    goto connectip
)
if "!existchoice!"=="3" goto newip
if "!existchoice!"=="0" goto manualmenu
goto manualmenu

:newip_connect_choice
echo.
echo  ================================================================================
echo                SELECT CONNECTION METHOD FOR %ipaddress%
echo  ================================================================================
echo.
echo    1 - Android 11+ Wireless Pairing Wizard (Pairing Port ^& Code)
echo        ^> Select this for Android 11, 12, 13, 14, 15+ Wireless Debugging
echo.
echo    2 - Standard TCP/IP Port 5555
echo        ^> Select this for Android 10 or below, or already paired devices
echo.
echo    3 - Setup via USB Cable
echo        ^> Connect USB cable to enable wireless TCP/IP mode automatically
echo.
echo    0 - Return to Menu (Saved without connecting)
echo.
set "new_method="
set /p "new_method=Your choice [1/2/3/0]: "
if "!new_method!"=="1" goto pair_wizard
if "!new_method!"=="2" goto newip_try_std
if "!new_method!"=="3" goto usb
if "!new_method!"=="0" goto manualmenu
echo  Invalid choice. Please select 1, 2, 3, or 0.
timeout 1 /nobreak >nul 2>&1
goto newip_connect_choice

:newip_try_std
echo.
echo  Attempting to connect to %ipaddress%:5555...

rem Clear stale socket
adb disconnect %ipaddress%:5555 >nul 2>&1

adb connect %ipaddress%:5555 >nul 2>&1
timeout 3 /nobreak >nul 2>&1

rem Verify connection
adb devices | findstr "%ipaddress%:5555" | findstr "device$" >nul 2>&1
if not errorlevel 1 (
    echo  Connection established! Starting scrcpy...
    
    call :launchscrcpy "%ipaddress%:5555"
    
    title   scrcpy Connection Manager - Connected to %ipaddress%
    echo.
    echo  Connection successful!
    
    rem Update timestamp and LAST marker
    call :updateipsuccess "%ipaddress%"
    
    timeout 2 /nobreak >nul 2>&1
    goto reconnect
)

goto troubleshoot

:reconnect
echo.
echo  ================================================================================
echo                         SESSION ENDED
echo  ================================================================================
echo.
if "!savedip!"=="USB" (
    echo  Would you like to:
    echo    1 - Reconnect via USB
    echo    2 - Try wireless connection
    echo    3 - Add new IP address / Android 11+ Pairing
    echo    5 - Change Resolution Preset [Current: !RES_NAME!]
    echo    0 - Exit program
) else (
    echo  Would you like to:
    echo    1 - Reconnect with same IP [!savedip!]
    echo    2 - Try all saved IPs again
    echo    3 - Try different saved IP
    echo    4 - Add new IP address / Android 11+ Pairing
    echo    5 - Change Resolution Preset [Current: !RES_NAME!]
    echo    0 - Exit program
)
echo.
set /p "choice=Your choice: "
if "!choice!"=="1" (
    if "!savedip!"=="USB" (
        goto usb
    ) else (
        goto connectip
    )
)
if "!choice!"=="2" (
    if "!savedip!"=="USB" (
        goto manualmenu
    ) else (
        goto tryall
    )
)
if "!choice!"=="3" (
    if "!savedip!"=="USB" (
        goto newip
    ) else (
        goto manualselect
    )
)
if "!choice!"=="4" goto newip
if "!choice!"=="5" goto changeres
if "!choice!"=="0" goto exitnow
goto reconnect

:exit
title   scrcpy Connection Manager - Disconnected
cls
echo.
echo.
echo  ================================================================================
echo                         SESSION ENDED
echo  ================================================================================
echo.
echo  Would you like to:
echo    1 - Exit program
echo    2 - Return to main menu
echo    3 - Connect with new IP
echo.
set /p "choice=Your choice: "
if not defined choice goto exitnow
if "!choice!"=="1" goto exitnow
if "!choice!"=="2" goto manualmenu
if "!choice!"=="3" goto newip
echo.
echo  Invalid input. Please enter a valid option.
timeout 2 /nobreak >nul 2>&1
goto exit

:exitnow
title   scrcpy Connection Manager - Exiting...
cls
echo.
echo  ================================================================================
echo                     Thank you for using scrcpy Manager!
echo  ================================================================================
echo.
timeout 1 /nobreak >nul 2>&1
if exist "%~dp0daw11.txt" (
    type "%~dp0daw11.txt"
) else if exist "%~dp0daw10.txt" (
    type "%~dp0daw10.txt"
)
echo.
timeout 2 /nobreak >nul 2>&1
cls
exit
