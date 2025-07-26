@echo off
:: Test Certificate Creation and Driver Signing Script
:: Run this on a Windows machine with Windows SDK/WDK installed
:: This script must be run as Administrator
:: Usage: create_test_cert.bat [build_directory]
:: Example: create_test_cert.bat objfre_win7_amd64
::
:: Note: This script tries multiple approaches for catalog generation:
:: 1. inf2cat with comprehensive OS support (Vista through Windows 10)
:: 2. inf2cat with Windows 7 only (for compatibility)
:: 3. makecat using bdfilter.cdf as fallback

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
echo Trying inf2cat with comprehensive OS support...
inf2cat /driver:. /os:Vista_X86,Vista_X64,7_X86,7_X64,8_X86,8_X64,6_3_X86,6_3_X64,10_X86,10_X64
if %errorLevel% NEQ 0 (
    echo inf2cat failed, trying with Windows 7 only...
    inf2cat /driver:. /os:7_X86,7_X64
    if %errorLevel% NEQ 0 (
        echo inf2cat failed, trying makecat as fallback...
        where makecat >nul 2>&1
        if %errorLevel% EQU 0 (
            makecat bdfilter.cdf
            if %errorLevel% NEQ 0 (
                echo ERROR: All catalog generation methods failed
                echo Make sure bdfilter.inf is present and valid in current directory
                pause
                exit /b 1
            )
        ) else (
            echo ERROR: Failed to generate catalog file
            echo Make sure bdfilter.inf is present and valid in current directory
            echo Consider installing a compatible version of Windows SDK/WDK
            pause
            exit /b 1
        )
    )
)

echo.
echo Signing driver files...
signtool sign /v /s %STORE_NAME% /n "%CERT_NAME%" /a /t http://timestamp.digicert.com "%BUILD_DIR%\bdfilter.sys"
if %errorLevel% NEQ 0 (
    echo ERROR: Failed to sign %BUILD_DIR%\bdfilter.sys
    pause
    exit /b 1
)

signtool sign /v /s %STORE_NAME% /n "%CERT_NAME%" /a /t http://timestamp.digicert.com "bdfilter.cat"
if %errorLevel% NEQ 0 (
    echo ERROR: Failed to sign bdfilter.cat
    pause
    exit /b 1
)

echo.
echo Verifying signatures...
echo NOTE: Verification may show trust errors for test certificates - this is expected.
echo The files are properly signed but the test certificate is not yet trusted.
echo.
signtool verify /v /kp "%BUILD_DIR%\bdfilter.sys"
echo.
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
echo NOTE: If verification showed trust errors above, this is expected
echo for test certificates that haven't been installed yet.
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