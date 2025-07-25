@echo off
:: Keyboard Filter Driver Installation Script
:: Run as Administrator

echo Keyboard Filter Driver Installation Script
echo ==========================================
echo.

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Checking for required files...
if not exist "bdfilter.inf" (
    echo ERROR: bdfilter.inf not found!
    pause
    exit /b 1
)

if not exist "bdfilter.sys" (
    echo ERROR: bdfilter.sys not found!
    pause
    exit /b 1
)

echo Files found successfully.
echo.

echo Installing keyboard filter driver...
pnputil /add-driver bdfilter.inf /install

if %errorLevel% NEQ 0 (
    echo.
    echo Installation failed. This might be because:
    echo - The driver is not digitally signed
    echo - Test signing is not enabled
    echo.
    echo To enable test signing, run:
    echo   bcdedit /set testsigning on
    echo Then restart your computer and run this script again.
    echo.
    pause
    exit /b 1
)

echo.
echo Driver package installed successfully!
echo.

echo.
echo Driver installed successfully!
echo.

echo Starting the keyboard filter service...
sc start bdfilter

if %errorLevel% NEQ 0 (
    echo Warning: Service failed to start automatically.
    echo You may need to start it manually or reboot the system.
) else (
    echo Service started successfully!
)

echo.
echo Installation complete!
echo.
echo To verify installation:
echo - Check Device Manager under System devices
echo - Use 'sc query bdfilter' to check service status
echo.
echo To uninstall, run uninstall.bat
echo.
pause