@echo off
:: Test Certificate Creation and Driver Signing Script
:: Run this on a Windows machine with Windows SDK/WDK installed
:: This script must be run as Administrator
:: Usage: create_test_cert.bat [build_directory]
:: Example: create_test_cert.bat objfre_win7_amd64

set BUILD_DIR=%~1
if "%BUILD_DIR%"=="" set BUILD_DIR=.

echo ============================================
echo  Driver Test Certificate Creation Script
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

:: Check if makecert exists
where makecert >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: makecert.exe not found!
    echo Please install Windows SDK or Windows Driver Kit
    echo The tools should be in your PATH
    pause
    exit /b 1
)

:: Check if signtool exists
where signtool >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: signtool.exe not found!
    echo Please install Windows SDK or Windows Driver Kit
    pause
    exit /b 1
)

:: Check if inf2cat exists
where inf2cat >nul 2>&1
if %errorLevel% NEQ 0 (
    echo ERROR: inf2cat.exe not found!
    echo Please install Windows Driver Kit
    pause
    exit /b 1
)

echo All required tools found.
echo.

:: Check if required driver files exist
if not exist "%BUILD_DIR%\bdfilter.sys" (
    echo ERROR: bdfilter.sys not found in %BUILD_DIR%!
    echo Please ensure you've built the driver or specify the correct build directory.
    echo Usage: create_test_cert.bat [build_directory]
    echo Example: create_test_cert.bat objfre_win7_amd64
    pause
    exit /b 1
)

if not exist "bdfilter.inf" (
    echo ERROR: bdfilter.inf not found in current directory!
    echo Please run this script from the driver source directory.
    pause
    exit /b 1
)

echo Required driver files found.
echo.

set CERT_NAME=BdFilterTestCert
set STORE_NAME=PrivateCertStore

echo Creating test certificate...
makecert -r -pe -ss %STORE_NAME% -n "CN=%CERT_NAME%" -eku 1.3.6.1.5.5.7.3.3 %CERT_NAME%.cer
if %errorLevel% NEQ 0 (
    echo ERROR: Failed to create test certificate
    pause
    exit /b 1
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
echo Signing driver files...
signtool sign /v /s %STORE_NAME% /n "%CERT_NAME%" /t http://timestamp.digicert.com "%BUILD_DIR%\bdfilter.sys"
if %errorLevel% NEQ 0 (
    echo ERROR: Failed to sign %BUILD_DIR%\bdfilter.sys
    pause
    exit /b 1
)

signtool sign /v /s %STORE_NAME% /n "%CERT_NAME%" /t http://timestamp.digicert.com "bdfilter.cat"
if %errorLevel% NEQ 0 (
    echo ERROR: Failed to sign bdfilter.cat
    pause
    exit /b 1
)

echo.
echo Verifying signatures...
signtool verify /v /kp "%BUILD_DIR%\bdfilter.sys"
signtool verify /v /kp "bdfilter.cat"

echo.
echo ============================================
echo  Certificate and Signing Complete!
echo ============================================
echo.
echo Files created:
echo - %CERT_NAME%.cer (Test certificate for installation)
echo - bdfilter.cat (Signed catalog file)
echo - %BUILD_DIR%\bdfilter.sys (Signed driver)
echo.
echo Next steps:
echo 1. Install the test certificate on target machine:
echo    certmgr -add %CERT_NAME%.cer -s -r localMachine TrustedPublisher
echo    certmgr -add %CERT_NAME%.cer -s -r localMachine root
echo.
echo 2. OR enable test signing mode on target machine:
echo    bcdedit /set testsigning on
echo    (then reboot)
echo.
echo 3. Run install.bat %BUILD_DIR% to install the driver
echo.
pause