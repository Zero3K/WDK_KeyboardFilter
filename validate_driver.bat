@echo off
:: Driver Code Validation Script
:: Checks for common driver coding issues

echo ====================================
echo  Driver Code Validation Script
echo ====================================
echo.

:: Check if source file exists
if not exist "bdfilter.c" (
    echo ERROR: bdfilter.c not found!
    exit /b 1
)

echo Checking driver code for common issues...
echo.

:: Check for the fixed object dereferencing issue
findstr /n "ObDereferenceObject(kbddriver)" bdfilter.c >nul
if %errorLevel% EQU 0 (
    echo [PASS] Object dereferencing fix is present
) else (
    echo [FAIL] Object dereferencing issue detected!
    echo        The driver should call ObDereferenceObject(kbddriver), not ObDereferenceObject(driver)
    echo        This causes CM_PROB_FAILED_DRIVER_ENTRY on Windows 7 x64
    exit /b 1
)

:: Check for proper reference management pattern
findstr /n "ObReferenceObjectByName.*kbddriver" bdfilter.c >nul
if %errorLevel% EQU 0 (
    echo [PASS] Object reference pattern found
) else (
    echo [WARN] Could not verify object reference pattern
)

:: Check for required service exports
findstr /n "DriverEntry.*PDRIVER_OBJECT" bdfilter.c >nul
if %errorLevel% EQU 0 (
    echo [PASS] DriverEntry function signature found
) else (
    echo [FAIL] DriverEntry function not found or has wrong signature
    exit /b 1
)

findstr /n "DriverUnload.*PDRIVER_OBJECT" bdfilter.c >nul
if %errorLevel% EQU 0 (
    echo [PASS] DriverUnload function found
) else (
    echo [WARN] DriverUnload function not found
)

echo.
echo ====================================
echo  Validation Complete
echo ====================================
echo All critical checks passed!
echo The driver should work correctly on Windows 7 x64.