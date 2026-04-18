@echo off
call :resolve_paths
if errorlevel 1 exit /b 1

if /I "%~1"=="--help" goto :help
if /I "%~1"=="-h" goto :help
if /I "%~1"=="--install" goto :install
if /I "%~1"=="--uninstall" goto :uninstall
if /I "%~1"=="--init" goto :init
if /I "%~1"=="--history" goto :history_path
if /I "%~1"=="--list" goto :recent
if /I "%~1"=="-l" goto :recent
if /I "%~1"=="--clean" goto :clean
if /I "%~1"=="-c" goto :clean
if /I "%~1"=="--record" (
    shift
    goto :record_only
)
if /I "%~1"=="--cd" goto :proxy_cd
if /I "%~1"=="--pushd" goto :proxy_pushd
if /I "%~1"=="--popd" goto :proxy_popd

if "%~1"=="" goto :recent

if exist "%~1\" (
    cd /d "%~1"
    if errorlevel 1 exit /b 1
    call :record_dir "%CD%" >nul 2>nul
    exit /b 0
)

set "J_QUERY=%~1"
set "J_TARGET="
call :find_target

if not defined J_TARGET (
    echo No match for "%J_QUERY%".
    goto :recent_fail
)

cd /d "%J_TARGET%"
if errorlevel 1 exit /b 1
call :record_dir "%CD%" >nul 2>nul
exit /b 0

:help
echo Usage:
echo   j ^<keyword^>
echo   j --init
echo   j --install
echo   j --uninstall
echo   j --history
echo   j --list
echo   j --clean
echo.
echo Behavior:
echo   - Fuzzy match only the last directory name in history.
echo   - Newest visited directory wins.
echo   - Existing directory path works directly.
echo.
echo Tracking:
echo   - Running j records the current directory.
echo   - Run "j --init" once per cmd.exe session to track cd/chdir/pushd/popd too.
echo   - Run "j --install" once to auto-load cd/chdir/pushd/popd tracking in every new cmd.exe session.
echo.
echo History file:
echo   %J_HISTORY%
exit /b 0

:install
set "J_AUTORUN=call \"%~f0\" --init --quiet"
reg add "HKCU\Software\Microsoft\Command Processor" /v AutoRun /t REG_SZ /d "%J_AUTORUN%" /f >nul
if errorlevel 1 (
    echo Failed to install cmd AutoRun.
    exit /b 1
)
call :init_quiet
echo Installed cmd AutoRun for current user.
echo New cmd.exe sessions will auto-enable cd/chdir/pushd/popd tracking.
exit /b 0

:uninstall
reg delete "HKCU\Software\Microsoft\Command Processor" /v AutoRun /f >nul 2>nul
if errorlevel 1 (
    echo AutoRun was not set.
    exit /b 0
)
echo Removed cmd AutoRun for current user.
exit /b 0

:history_path
echo %J_HISTORY%
exit /b 0

:clean
echo Cleaned history:
for /f "usebackq tokens=1,* delims=|" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0j-helper.ps1" -Action clean -HistoryPath "%J_HISTORY%"`) do (
    if /I "%%A"=="RECENT" echo %%B
)
exit /b 0

:init
if /I "%~2"=="--quiet" goto :init_quiet
if /I "%~2"=="/quiet" goto :init_quiet
call :init_quiet
echo j tracking loaded for this cmd.exe session.
echo   cd     - tracked
echo   chdir  - tracked
echo   pushd  - tracked
echo   popd   - tracked
echo History file: %J_HISTORY%
exit /b 0

:init_quiet
doskey cd=call "%~f0" --cd $*
doskey chdir=call "%~f0" --cd $*
doskey pushd=call "%~f0" --pushd $*
doskey popd=call "%~f0" --popd
call :record_dir "%CD%" >nul 2>nul
exit /b 0

:record_only
if "%~1"=="" (
    call :record_dir "%CD%" >nul 2>nul
    exit /b 0
)
call :record_dir "%~1" >nul 2>nul
exit /b 0

:proxy_cd
if "%~2"=="" (
    cd
    exit /b 0
)
if /I "%~2"=="/?" (
    cd /?
    exit /b 0
)
if /I "%~2"=="/d" (
    if "%~3"=="" exit /b 1
    cd /d "%~3"
) else (
    cd "%~2"
)
if errorlevel 1 exit /b 1
call :record_dir "%CD%" >nul 2>nul
exit /b 0

:proxy_pushd
if "%~2"=="" exit /b 1
pushd "%~2"
if errorlevel 1 exit /b 1
call :record_dir "%CD%" >nul 2>nul
exit /b 0

:proxy_popd
popd
if errorlevel 1 exit /b 1
call :record_dir "%CD%" >nul 2>nul
exit /b 0

:recent
echo Recent directories:
for /f "usebackq tokens=1,* delims=|" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0j-helper.ps1" -Action recent -HistoryPath "%J_HISTORY%"`) do (
    if /I "%%A"=="RECENT" echo %%B
)
exit /b 0

:recent_fail
call :recent
exit /b 1

:find_target
for /f "usebackq tokens=1,* delims=|" %%A in (`powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0j-helper.ps1" -Action find -HistoryPath "%J_HISTORY%" -Query "%J_QUERY%"`) do (
    if /I "%%A"=="TARGET" if not defined J_TARGET set "J_TARGET=%%B"
)
exit /b 0

:record_dir
if "%~1"=="" exit /b 0
if not exist "%~f1\" exit /b 0
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0j-helper.ps1" -Action record -HistoryPath "%J_HISTORY%" -Dir "%~f1" >nul
exit /b 0

:resolve_paths
if defined J_HISTORY_FILE (
    set "J_HISTORY=%J_HISTORY_FILE%"
) else if defined J_HOME (
    set "J_HISTORY=%J_HOME%\history.txt"
) else (
    set "J_HISTORY=%~dp0j.history"
)

for %%P in ("%J_HISTORY%") do (
    set "J_HISTORY=%%~fP"
    set "J_HISTORY_DIR=%%~dpP"
)

if not exist "%J_HISTORY_DIR%" mkdir "%J_HISTORY_DIR%" >nul 2>nul
if not exist "%J_HISTORY%" type nul > "%J_HISTORY%" 2>nul
if not exist "%J_HISTORY%" exit /b 1
exit /b 0
