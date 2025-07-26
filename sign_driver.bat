@echo off
:: Driver Signing Script for existing certificates
:: Run this on a Windows machine with Windows SDK/WDK installed
:: This script must be run as Administrator
:: Usage: sign_driver.bat [build_directory]
:: Example: sign_driver.bat objfre_win7_amd64

set BUILD_DIR=%~1
if "%BUILD_DIR%"=="" set BUILD_DIR=.

echo ============================================
echo      Driver Signing Script
echo ============================================
echo Build directory: %BUILD_DIR%
echo.

:: Check for administrator privileges
net session >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: This script must be run as Administrator!
    echo Right-click and select "Run as administrator"
    pause
    exit /b 1
)

:: Check if required files exist
if not exist "%BUILD_DIR%\bdfilter.sys" (
    echo ERROR: bdfilter.sys not found in %BUILD_DIR%!
    echo Please ensure you've built the driver or specify the correct build directory.
    echo Usage: sign_driver.bat [build_directory]
    echo Example: sign_driver.bat objfre_win7_amd64
    pause
    exit /b 1
)

if not exist "bdfilter.inf" (
    echo ERROR: bdfilter.inf not found in current directory!
    echo Please run this script from the driver source directory.
    pause
    exit /b 1
)

:: Check if signing tools exist
where signtool >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: signtool.exe not found!
    echo Please install Windows SDK or Windows Driver Kit
    pause
    exit /b 1
)

where inf2cat >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: inf2cat.exe not found!
    echo Please install Windows Driver Kit
    pause
    exit /b 1
)

echo Required files and tools found.
echo.

:: Prompt for certificate file
set /p CERT_FILE="Enter path to certificate file (.cer or .pfx): "
if not exist "%CERT_FILE%" (
    echo ERROR: Certificate file not found: %CERT_FILE%
    pause
    exit /b 1
)

:: Get file extension
for %%i in ("%CERT_FILE%") do set CERT_EXT=%%~xi

:: Set signing parameters based on certificate type
if /i "%CERT_EXT%"==".pfx" (
    set /p PFX_PASSWORD="Enter PFX password (or press Enter if none): "
    set SIGN_PARAMS=/f "%CERT_FILE%" /p "%PFX_PASSWORD%"
) else (
    set /p CERT_STORE="Enter certificate store name (default: My): "
    if "%CERT_STORE%"=="" set CERT_STORE=My
    set /p CERT_NAME="Enter certificate subject name: "
    if "%CERT_NAME%"=="" (
        echo ERROR: Certificate subject name is required for .cer files
        pause
        exit /b 1
    )
    set SIGN_PARAMS=/s "%CERT_STORE%" /n "%CERT_NAME%"
)

echo.
echo Generating catalog file...
inf2cat /driver:. /os:7_X86,7_X64
if %errorLevel% NEQ 0 (
    echo ERROR: Failed to generate catalog file
    echo Make sure bdfilter.inf is present and valid in current directory
    pause
    exit /b 1
)

echo.
echo Signing driver file...
signtool sign /v %SIGN_PARAMS% /t http://timestamp.digicert.com "%BUILD_DIR%\bdfilter.sys"
if %errorLevel% NEQ 0 (
    echo ERROR: Failed to sign %BUILD_DIR%\bdfilter.sys
    pause
    exit /b 1
)

echo.
echo Signing catalog file...
signtool sign /v %SIGN_PARAMS% /t http://timestamp.digicert.com "bdfilter.cat"
if %errorLevel% NEQ 0 (
    echo ERROR: Failed to sign bdfilter.cat
    pause
    exit /b 1
)

echo.
echo Verifying signatures...
signtool verify /v /kp "%BUILD_DIR%\bdfilter.sys"
if %errorLevel% NEQ 0 (
    echo WARNING: Driver signature verification failed
)

signtool verify /v /kp "bdfilter.cat"
if %errorLevel% NEQ 0 (
    echo WARNING: Catalog signature verification failed
)

echo.
echo ============================================
echo        Driver Signing Complete!
echo ============================================
echo.
echo Signed files:
echo - %BUILD_DIR%\bdfilter.sys (Signed driver)
echo - bdfilter.cat (Signed catalog file)
echo.
echo If using a test certificate, ensure on target machine:
echo 1. Install the certificate to TrustedPublisher and Root stores, OR
echo 2. Enable test signing mode: bcdedit /set testsigning on
echo.
echo Then run install.bat %BUILD_DIR% to install the driver.
echo.
pause