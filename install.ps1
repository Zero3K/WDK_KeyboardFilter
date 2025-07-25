# PowerShell Driver Installation Script with Signing Support
# Run as Administrator: PowerShell -ExecutionPolicy Bypass -File install.ps1

param(
    [switch]$EnableTestSigning,
    [switch]$Force
)

# Check if running as Administrator
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: This script must be run as Administrator!" -ForegroundColor Red
    Write-Host "Right-click PowerShell and select 'Run as administrator'" -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Keyboard Filter Driver Installation Script (PowerShell)" -ForegroundColor Green
Write-Host "========================================================" -ForegroundColor Green
Write-Host

# Check for required files
if (-not (Test-Path "bdfilter.inf")) {
    Write-Host "ERROR: bdfilter.inf not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

if (-not (Test-Path "bdfilter.sys")) {
    Write-Host "ERROR: bdfilter.sys not found!" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Required files found." -ForegroundColor Green
Write-Host

# Check driver signature
Write-Host "Checking driver signature..." -ForegroundColor Yellow

$driverSigned = $false
$catalogSigned = $false

try {
    $result = & signtool verify /v /kp bdfilter.sys 2>&1
    if ($LASTEXITCODE -eq 0) {
        $driverSigned = $true
        Write-Host "Driver signature: OK" -ForegroundColor Green
    } else {
        Write-Host "Driver signature: NOT SIGNED" -ForegroundColor Red
    }
} catch {
    Write-Host "Driver signature: CANNOT VERIFY" -ForegroundColor Red
}

if (Test-Path "bdfilter.cat") {
    try {
        $result = & signtool verify /v /kp bdfilter.cat 2>&1
        if ($LASTEXITCODE -eq 0) {
            $catalogSigned = $true
            Write-Host "Catalog signature: OK" -ForegroundColor Green
        } else {
            Write-Host "Catalog signature: NOT SIGNED" -ForegroundColor Red
        }
    } catch {
        Write-Host "Catalog signature: CANNOT VERIFY" -ForegroundColor Red
    }
} else {
    Write-Host "Catalog file: MISSING" -ForegroundColor Red
}

# Handle signing issues
if (-not $driverSigned -and -not $Force) {
    Write-Host
    Write-Host "DRIVER SIGNING ISSUE DETECTED" -ForegroundColor Yellow
    Write-Host "==============================" -ForegroundColor Yellow
    Write-Host "The driver is not digitally signed. On Windows 7 x64 and later," -ForegroundColor White
    Write-Host "kernel-mode drivers must be signed. You have the following options:" -ForegroundColor White
    Write-Host
    Write-Host "1. Enable test signing mode (recommended for testing):" -ForegroundColor Cyan
    Write-Host "   bcdedit /set testsigning on" -ForegroundColor Gray
    Write-Host "   (requires reboot)" -ForegroundColor Gray
    Write-Host
    Write-Host "2. Sign the driver with a test certificate:" -ForegroundColor Cyan
    Write-Host "   Run create_test_cert.bat or sign_driver.bat" -ForegroundColor Gray
    Write-Host
    Write-Host "3. Install a test certificate if you have one" -ForegroundColor Cyan
    Write-Host
    
    if ($EnableTestSigning) {
        Write-Host "EnableTestSigning parameter specified. Enabling test signing mode..." -ForegroundColor Yellow
        $enableResult = & bcdedit /set testsigning on 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Test signing enabled successfully!" -ForegroundColor Green
            Write-Host "IMPORTANT: You must restart your computer before installing the driver." -ForegroundColor Red
            Write-Host "After restart, run this script again." -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit 0
        } else {
            Write-Host "ERROR: Failed to enable test signing mode" -ForegroundColor Red
            Write-Host "You may need to disable Secure Boot in BIOS/UEFI settings" -ForegroundColor Yellow
            Read-Host "Press Enter to exit"
            exit 1
        }
    } else {
        $choice = Read-Host "Do you want to enable test signing mode now? (Y/N)"
        if ($choice -eq "Y" -or $choice -eq "y") {
            Write-Host "Enabling test signing mode..." -ForegroundColor Yellow
            $enableResult = & bcdedit /set testsigning on 2>&1
            if ($LASTEXITCODE -eq 0) {
                Write-Host "Test signing enabled successfully!" -ForegroundColor Green
                Write-Host "IMPORTANT: You must restart your computer before installing the driver." -ForegroundColor Red
                Write-Host "After restart, run this script again." -ForegroundColor Yellow
                Read-Host "Press Enter to exit"
                exit 0
            } else {
                Write-Host "ERROR: Failed to enable test signing mode" -ForegroundColor Red
                Write-Host "You may need to disable Secure Boot in BIOS/UEFI settings" -ForegroundColor Yellow
                Read-Host "Press Enter to exit"
                exit 1
            }
        } else {
            Write-Host "Continuing with installation attempt..." -ForegroundColor Yellow
        }
    }
}

Write-Host
Write-Host "Installing keyboard filter driver..." -ForegroundColor Yellow

try {
    $installResult = & pnputil /add-driver bdfilter.inf /install 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Driver package installed successfully!" -ForegroundColor Green
    } else {
        Write-Host
        Write-Host "Installation failed. Error code: $LASTEXITCODE" -ForegroundColor Red
        Write-Host
        Write-Host "This is likely due to driver signing issues. Common solutions:" -ForegroundColor Yellow
        Write-Host
        Write-Host "1. Enable test signing mode:" -ForegroundColor Cyan
        Write-Host "   bcdedit /set testsigning on" -ForegroundColor Gray
        Write-Host "   (then reboot and try again)" -ForegroundColor Gray
        Write-Host
        Write-Host "2. Sign the driver properly:" -ForegroundColor Cyan
        Write-Host "   Use create_test_cert.bat or sign_driver.bat" -ForegroundColor Gray
        Write-Host
        Write-Host "3. Install test certificate to trusted stores" -ForegroundColor Cyan
        Write-Host
        Write-Host "4. Check Windows Event Log for detailed error information" -ForegroundColor Cyan
        Write-Host
        Read-Host "Press Enter to exit"
        exit 1
    }
} catch {
    Write-Host "ERROR: Failed to run pnputil. Error: $($_.Exception.Message)" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host
Write-Host "Starting the keyboard filter service..." -ForegroundColor Yellow

try {
    $serviceResult = & sc start bdfilter 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Service started successfully!" -ForegroundColor Green
    } else {
        Write-Host "Warning: Service failed to start automatically." -ForegroundColor Yellow
        Write-Host "You may need to start it manually or reboot the system." -ForegroundColor Yellow
    }
} catch {
    Write-Host "Warning: Could not start service. You may need to start it manually." -ForegroundColor Yellow
}

Write-Host
Write-Host "Installation complete!" -ForegroundColor Green
Write-Host
Write-Host "To verify installation:" -ForegroundColor Cyan
Write-Host "- Check Device Manager under System devices" -ForegroundColor Gray
Write-Host "- Use 'sc query bdfilter' to check service status" -ForegroundColor Gray
Write-Host
Write-Host "To uninstall, run uninstall.bat" -ForegroundColor Cyan
Write-Host
Read-Host "Press Enter to exit"