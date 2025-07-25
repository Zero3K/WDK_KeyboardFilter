@echo off
:: Keyboard Filter Driver Uninstallation Script
:: Run as Administrator

echo Keyboard Filter Driver Uninstallation Script
echo =============================================
echo.

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

echo Stopping keyboard filter service...
sc stop bdfilter

if %errorLevel% NEQ 0 (
    echo Warning: Service may not be running or already stopped.
) else (
    echo Service stopped successfully.
)

echo.
echo Removing keyboard filter service...
sc delete bdfilter

if %errorLevel% NEQ 0 (
    echo Warning: Service deletion failed or service doesn't exist.
) else (
    echo Service removed successfully.
)

echo.
echo Uninstalling driver package...
pnputil /delete-driver bdfilter.inf /uninstall /force

if %errorLevel% NEQ 0 (
    echo Warning: Driver package removal failed.
    echo The driver may have been removed already or is in use.
) else (
    echo Driver package removed successfully.
)

echo.
echo Cleaning up registry entries...
reg delete "HKLM\System\CurrentControlSet\Control\Class\{4D36E96B-E325-11CE-BFC1-08002BE10318}" /v UpperFilters /f >nul 2>&1

echo.
echo Uninstallation process completed!
echo.
echo Note: A system restart may be required to completely remove the driver.
echo If the keyboard filter is still active, please restart your computer.
echo.
pause