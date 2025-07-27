@echo off
:: Keyboard Filter Driver Installation Script
:: Run as Administrator
:: Usage: install.bat [build_directory] [/UNSIGNED]
:: Example: install.bat objfre_win7_amd64
:: Example: install.bat . /UNSIGNED

set BUILD_DIR=%~1
set UNSIGNED_MODE=0

:: Parse command line arguments
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="/UNSIGNED" set UNSIGNED_MODE=1
if /i "%~1"=="/unsigned" set UNSIGNED_MODE=1
if /i "%~1"=="-unsigned" set UNSIGNED_MODE=1
shift
goto :parse_args

:args_done
if "%BUILD_DIR%"=="" set BUILD_DIR=.

echo Keyboard Filter Driver Installation Script
echo ==========================================
echo Build directory: %BUILD_DIR%
if %UNSIGNED_MODE%==1 echo Mode: UNSIGNED (skipping signature verification)
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
    echo ERROR: bdfilter.inf not found in current directory!
    echo Please run this script from the driver source directory.
    pause
    exit /b 1
)

if not exist "%BUILD_DIR%\bdfilter.sys" (
    echo ERROR: bdfilter.sys not found in %BUILD_DIR%!
    echo Please ensure you've built the driver or specify the correct build directory.
    echo Usage: install.bat [build_directory] 
    echo Example: install.bat objfre_win7_amd64
    pause
    exit /b 1
)

echo Files found successfully.
echo.

if %UNSIGNED_MODE%==1 (
    echo UNSIGNED MODE: Skipping signature verification
    echo WARNING: Installing unsigned driver - test signing must be enabled
    goto :install_driver
)

echo Checking driver signature status...
signtool verify /v /kp "%BUILD_DIR%\bdfilter.sys" >nul 2>&1
set DRIVER_SIGNED=%errorLevel%

signtool verify /v /kp "bdfilter.cat" >nul 2>&1
set CATALOG_SIGNED=%errorLevel%

if %DRIVER_SIGNED% NEQ 0 (
    echo WARNING: Driver %BUILD_DIR%\bdfilter.sys is not properly signed
)

if %CATALOG_SIGNED% NEQ 0 (
    echo WARNING: Catalog bdfilter.cat is not properly signed or missing
)

if %DRIVER_SIGNED% NEQ 0 (
    echo.
    echo DRIVER SIGNING ISSUE DETECTED
    echo ==============================
    echo The driver is not digitally signed. On Windows 7 x64 and later,
    echo kernel-mode drivers must be signed. You have the following options:
    echo.
    echo 1. Enable test signing mode ^(recommended for testing^):
    echo    bcdedit /set testsigning on
    echo    ^(requires reboot^)
    echo.
    echo 2. Sign the driver with a test certificate:
    echo    Run create_test_cert.bat %BUILD_DIR% or sign_driver.bat %BUILD_DIR%
    echo.
    echo 3. Install a test certificate if you have one:
    echo    certmgr -add YourTestCert.cer -s -r localMachine TrustedPublisher
    echo    certmgr -add YourTestCert.cer -s -r localMachine root
    echo.
    
    choice /c YN /m "Do you want to enable test signing mode now?"
    if errorlevel 2 goto :skip_testsigning
    
    echo Enabling test signing mode...
    bcdedit /set testsigning on
    if %errorLevel% NEQ 0 (
        echo ERROR: Failed to enable test signing mode
        echo You may need to disable Secure Boot in BIOS/UEFI settings
        pause
        exit /b 1
    )
    
    echo Test signing enabled successfully!
    echo IMPORTANT: You must restart your computer before installing the driver.
    echo After restart, run this script again.
    echo.
    pause
    exit /b 0
    
    :skip_testsigning
    echo Continuing with installation attempt...
)

:install_driver
echo.
echo Installing keyboard filter driver...
pnputil /add-driver "bdfilter.inf" /install

if %errorLevel% NEQ 0 (
    echo.
    echo Installation failed. Error code: %errorLevel%
    echo.
    echo This is likely due to driver signing issues. Common solutions:
    echo.
    echo 1. Enable test signing mode:
    echo    bcdedit /set testsigning on
    echo    ^(then reboot and try again^)
    echo.
    echo 2. Sign the driver properly:
    echo    Use create_test_cert.bat %BUILD_DIR% or sign_driver.bat %BUILD_DIR%
    echo.
    echo 3. Install test certificate to trusted stores:
    echo    certmgr -add TestCert.cer -s -r localMachine TrustedPublisher
    echo    certmgr -add TestCert.cer -s -r localMachine root
    echo.
    echo 4. Check Windows Event Log for detailed error information
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