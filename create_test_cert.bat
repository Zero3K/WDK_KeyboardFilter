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

:: Function to find WDK tools in standard installation paths
call :FindWDKTools

:: Check if all required tools were found
if "%MAKECERT_PATH%"=="" (
    echo ERROR: makecert.exe not found!
    echo Please install Windows SDK or Windows Driver Kit
    pause
    exit /b 1
)

if "%SIGNTOOL_PATH%"=="" (
    echo ERROR: signtool.exe not found!
    echo Please install Windows SDK or Windows Driver Kit
    pause
    exit /b 1
)

if "%INF2CAT_PATH%"=="" (
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
"%MAKECERT_PATH%" -r -pe -ss %STORE_NAME% -n "CN=%CERT_NAME%" -eku 1.3.6.1.5.5.7.3.3 %CERT_NAME%.cer
if %errorLevel% NEQ 0 (
    echo ERROR: Failed to create test certificate
    pause
    exit /b 1
)

echo.
echo Generating catalog file...

:: Clean up any existing catalog file first
if exist "bdfilter.cat" del "bdfilter.cat" >nul 2>&1

:: Method 1: Try inf2cat with Windows 10 only (most reliable)
echo Trying inf2cat with Windows 10 support...
"%INF2CAT_PATH%" /driver:. /os:10_X86,10_X64 /verbose
if %errorLevel% EQU 0 goto :CatalogSuccess

:: Method 2: Try inf2cat with Windows 7 and 10
echo inf2cat failed, trying with Windows 7 and 10...
"%INF2CAT_PATH%" /driver:. /os:7_X86,7_X64,10_X86,10_X64 /verbose
if %errorLevel% EQU 0 goto :CatalogSuccess

:: Method 3: Try inf2cat with Windows 7 only
echo inf2cat failed, trying with Windows 7 only...
"%INF2CAT_PATH%" /driver:. /os:7_X86,7_X64 /verbose
if %errorLevel% EQU 0 goto :CatalogSuccess

:: Method 4: Try to validate INF file first, then generate catalog
echo inf2cat failed, validating INF file structure...
"%INF2CAT_PATH%" /driver:. /os:7_X64 /verbose /nocat
if %errorLevel% NEQ 0 (
    echo WARNING: INF file validation failed - this may cause catalog generation issues
    echo Continuing with makecat fallback...
)

:: Method 5: Try makecat as fallback
echo Trying makecat as fallback...
where makecat >nul 2>&1
if %errorLevel% EQU 0 (
    echo Creating catalog using makecat with bdfilter.cdf...
    makecat -v bdfilter.cdf
    if %errorLevel% EQU 0 goto :CatalogSuccess
    
    echo makecat failed, trying alternative approach...
    :: Try creating a basic catalog manually
    call :CreateBasicCatalog
    if %errorLevel% EQU 0 goto :CatalogSuccess
)

:: All methods failed
echo ERROR: All catalog generation methods failed
echo.
echo Troubleshooting suggestions:
echo 1. Check that bdfilter.inf is valid and properly formatted
echo 2. Ensure you have administrative privileges
echo 3. Try running from a different directory
echo 4. Check Windows temp directory permissions
echo 5. Verify WDK installation is complete
echo.
echo You can try to install the driver without a catalog file by running:
echo   install.bat ^<build_directory^> /UNSIGNED
echo.
pause
exit /b 1

:CatalogSuccess
echo Catalog generation successful!
if not exist "bdfilter.cat" (
    echo ERROR: bdfilter.cat was not created despite successful return code
    pause
    exit /b 1
)

echo.
echo Signing driver files...
"%SIGNTOOL_PATH%" sign /v /s %STORE_NAME% /n "%CERT_NAME%" /a /t http://timestamp.digicert.com "%BUILD_DIR%\bdfilter.sys"
if %errorLevel% NEQ 0 (
    echo ERROR: Failed to sign %BUILD_DIR%\bdfilter.sys
    pause
    exit /b 1
)

"%SIGNTOOL_PATH%" sign /v /s %STORE_NAME% /n "%CERT_NAME%" /a /t http://timestamp.digicert.com "bdfilter.cat"
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
"%SIGNTOOL_PATH%" verify /v /kp "%BUILD_DIR%\bdfilter.sys"
echo.
"%SIGNTOOL_PATH%" verify /v /kp "bdfilter.cat"

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

goto :eof

:CreateBasicCatalog
:: Function to create a basic catalog file using an alternative method
echo Attempting to create basic catalog file...

:: Create a minimal CDF file if one doesn't exist or is corrupted
if not exist "bdfilter.cdf" (
    echo Creating minimal CDF file...
    echo [CatalogHeader] > bdfilter.cdf
    echo Name=bdfilter.cat >> bdfilter.cdf
    echo ResultDir= >> bdfilter.cdf
    echo PublicVersion=0x0000001 >> bdfilter.cdf
    echo EncodingType=0x00010001 >> bdfilter.cdf
    echo CATATTR1=0x10010001:OSAttr:2:6.1,2:10.0 >> bdfilter.cdf
    echo. >> bdfilter.cdf
    echo [CatalogFiles] >> bdfilter.cdf
    echo bdfilter.sys=bdfilter.sys >> bdfilter.cdf
    echo bdfilter.inf=bdfilter.inf >> bdfilter.cdf
)

:: Try makecat with the CDF
makecat -v bdfilter.cdf
if %errorLevel% EQU 0 (
    echo Basic catalog created successfully using makecat
    goto :eof
)

:: If that fails, try without verbose mode
makecat bdfilter.cdf
if %errorLevel% EQU 0 (
    echo Basic catalog created successfully using makecat ^(non-verbose^)
    goto :eof
)

echo Failed to create basic catalog
exit /b 1

:FindWDKTools
:: Function to locate WDK tools in standard installation paths
echo Locating WDK tools...

set MAKECERT_PATH=
set SIGNTOOL_PATH=
set INF2CAT_PATH=

:: First try to find tools in PATH
where makecert >nul 2>&1
if %errorLevel% EQU 0 (
    for /f "tokens=*" %%i in ('where makecert') do set MAKECERT_PATH=%%i
)

where signtool >nul 2>&1
if %errorLevel% EQU 0 (
    for /f "tokens=*" %%i in ('where signtool') do set SIGNTOOL_PATH=%%i
)

where inf2cat >nul 2>&1
if %errorLevel% EQU 0 (
    for /f "tokens=*" %%i in ('where inf2cat') do set INF2CAT_PATH=%%i
)

:: If tools not found in PATH, search in standard WDK installation paths
if "%MAKECERT_PATH%"=="" call :FindToolInWDK makecert.exe MAKECERT_PATH
if "%SIGNTOOL_PATH%"=="" call :FindToolInWDK signtool.exe SIGNTOOL_PATH
if "%INF2CAT_PATH%"=="" call :FindToolInWDK inf2cat.exe INF2CAT_PATH

echo.
echo Tool locations:
if not "%MAKECERT_PATH%"=="" echo   makecert: %MAKECERT_PATH%
if not "%SIGNTOOL_PATH%"=="" echo   signtool: %SIGNTOOL_PATH%
if not "%INF2CAT_PATH%"=="" echo   inf2cat: %INF2CAT_PATH%
echo.

goto :eof

:FindToolInWDK
:: Function to find a specific tool in WDK installation paths
:: %1 = tool filename (e.g., inf2cat.exe)
:: %2 = variable name to set (e.g., INF2CAT_PATH)

set TOOL_NAME=%~1
set VAR_NAME=%~2

:: Common WDK installation paths for different versions and architectures
set WDK_PATHS[0]="C:\Program Files (x86)\Windows Kits\10\bin\x64"
set WDK_PATHS[1]="C:\Program Files (x86)\Windows Kits\10\bin\x86"
set WDK_PATHS[2]="C:\Program Files\Windows Kits\10\bin\x64"
set WDK_PATHS[3]="C:\Program Files\Windows Kits\10\bin\x86"

:: Also check versioned paths for WDK 10
for /d %%d in ("C:\Program Files (x86)\Windows Kits\10\bin\10.*") do (
    if exist "%%d\x64\%TOOL_NAME%" (
        set %VAR_NAME%=%%d\x64\%TOOL_NAME%
        goto :eof
    )
    if exist "%%d\x86\%TOOL_NAME%" (
        set %VAR_NAME%=%%d\x86\%TOOL_NAME%
        goto :eof
    )
)

for /d %%d in ("C:\Program Files\Windows Kits\10\bin\10.*") do (
    if exist "%%d\x64\%TOOL_NAME%" (
        set %VAR_NAME%=%%d\x64\%TOOL_NAME%
        goto :eof
    )
    if exist "%%d\x86\%TOOL_NAME%" (
        set %VAR_NAME%=%%d\x86\%TOOL_NAME%
        goto :eof
    )
)

:: Check basic paths without version subdirectories
for /L %%i in (0,1,3) do (
    call set "CURRENT_PATH=%%WDK_PATHS[%%i]%%"
    call set "CURRENT_PATH=%%CURRENT_PATH:"=%%"
    if exist "%CURRENT_PATH%\%TOOL_NAME%" (
        set %VAR_NAME%=%CURRENT_PATH%\%TOOL_NAME%
        goto :eof
    )
)

:: Also check WDK 8.1 paths
set WDK81_PATHS[0]="C:\Program Files (x86)\Windows Kits\8.1\bin\x64"
set WDK81_PATHS[1]="C:\Program Files (x86)\Windows Kits\8.1\bin\x86"
set WDK81_PATHS[2]="C:\Program Files\Windows Kits\8.1\bin\x64"
set WDK81_PATHS[3]="C:\Program Files\Windows Kits\8.1\bin\x86"

for /L %%i in (0,1,3) do (
    call set "CURRENT_PATH=%%WDK81_PATHS[%%i]%%"
    call set "CURRENT_PATH=%%CURRENT_PATH:"=%%"
    if exist "%CURRENT_PATH%\%TOOL_NAME%" (
        set %VAR_NAME%=%CURRENT_PATH%\%TOOL_NAME%
        goto :eof
    )
)

goto :eof

goto :eof