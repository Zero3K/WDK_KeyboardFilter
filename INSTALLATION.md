# Keyboard Filter Driver Installation Guide

## Overview
This package contains a Windows keyboard filter driver (`bdfilter.sys`) and its installation file (`bdfilter.inf`) that allows monitoring and filtering keyboard input at the driver level.

## Files Included
- `bdfilter.sys` - The compiled keyboard filter driver
- `bdfilter.inf` - Windows driver installation file
- `bdfilter.c` - Driver source code
- `sources` - Build configuration file
- `makefile` - Build system file

## Installation Instructions

### Prerequisites
- Windows operating system (Windows XP or later)
- Administrator privileges
- **For Windows 7 x64 and later**: Driver must be digitally signed OR test signing enabled
  - See `DRIVER_SIGNING.md` for detailed signing instructions
  - Quick fix: Run `bcdedit /set testsigning on` as Administrator, then reboot

### Installing the Driver

**IMPORTANT for Windows 7 x64 and later:** Before installing, you must address driver signing requirements. See `DRIVER_SIGNING.md` for complete instructions, or run:
```cmd
bcdedit /set testsigning on
```
Then restart your computer.

#### Method 1: Automated Installation (Recommended)
1. Run `install.bat` as Administrator
2. The script will automatically detect signing issues and guide you through the solution

#### Method 2: Using Device Manager
1. Open Device Manager as Administrator
2. Right-click on any device and select "Add legacy hardware"
3. Choose "Install the hardware that I manually select from a list"
4. Select "Have Disk..." and browse to the `bdfilter.inf` file
5. Follow the installation wizard

#### Method 3: Using Command Line
1. Open Command Prompt as Administrator
2. Navigate to the directory containing `bdfilter.inf`
3. Run: `pnputil /add-driver bdfilter.inf /install`

**Note**: The INF file has been updated to be compatible with modern pnputil installation. It now includes proper manufacturer and device sections required by Windows driver installation.

#### Method 4: Using Right-click Install
1. Right-click on `bdfilter.inf`
2. Select "Install" from the context menu
3. Confirm the installation when prompted

### Enabling Test Signing (for unsigned drivers)
If the driver is not digitally signed, you need to enable test signing:

1. Open Command Prompt as Administrator
2. Run: `bcdedit /set testsigning on`
3. Restart the computer
4. Install the driver using one of the methods above

### Starting the Driver Service
After installation, start the driver service:
```cmd
sc start bdfilter
```

### Stopping the Driver Service
To stop the driver service:
```cmd
sc stop bdfilter
```

## Uninstallation

### Method 1: Using Device Manager
1. Open Device Manager as Administrator
2. Find the "Keyboard Filter Driver" under System devices
3. Right-click and select "Uninstall device"
4. Choose to delete the driver software

### Method 2: Using Command Line
1. Stop the service: `sc stop bdfilter`
2. Delete the service: `sc delete bdfilter`
3. Remove the driver: `pnputil /delete-driver bdfilter.inf`

### Method 3: Using INF Uninstall
1. Right-click on `bdfilter.inf`
2. Select "Uninstall" if available

## Driver Configuration

The driver is configured as a keyboard class upper filter driver. It automatically:
- Loads at system startup
- Attaches to all keyboard devices
- Monitors keyboard input
- Logs keystrokes (visible in debug output)

## Registry Entries

The driver adds itself to the keyboard class upper filters:
```
HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Class\{4D36E96B-E325-11CE-BFC1-08002BE10318}\UpperFilters
```

## Troubleshooting

### Driver Signing Issues (Windows 7 x64 and later)

**"Code integrity determined that the image hash of a file is not valid"**

This error occurs when Windows detects an unsigned or improperly signed driver. Solutions:

1. **Enable test signing mode (Quick fix):**
   ```cmd
   bcdedit /set testsigning on
   ```
   Then restart your computer.

2. **Sign the driver properly:**
   - Run `create_test_cert.bat` to create and apply a test certificate
   - Or run `sign_driver.bat` if you have an existing certificate
   - See `DRIVER_SIGNING.md` for detailed instructions

3. **Install a test certificate:**
   ```cmd
   certmgr -add YourTestCert.cer -s -r localMachine TrustedPublisher
   certmgr -add YourTestCert.cer -s -r localMachine root
   ```

### Driver won't install
- Ensure you have Administrator privileges
- Check if test signing is enabled for unsigned drivers
- Verify the INF file syntax

### "The required line was not found in the INF" error
This error typically occurs when using pnputil with INF files that don't have proper manufacturer and device sections. The INF file has been updated to include these required sections for modern Windows driver installation.

### Driver won't start
- Check Windows Event Log for error messages
- Verify the driver file exists in `C:\Windows\System32\drivers\`
- Ensure dependencies are available

### System becomes unstable
- Boot into Safe Mode
- Uninstall the driver using Device Manager
- Disable test signing if it was enabled only for this driver

## Security Notice

This driver operates at kernel level and has access to all keyboard input. Use only for legitimate purposes such as:
- Security monitoring
- Accessibility applications
- Input method debugging
- System administration

## Building from Source

To rebuild the driver from source:
1. Install Windows Driver Kit (WDK)
2. Open a WDK command prompt
3. Navigate to the source directory
4. Run: `build` or use the provided makefile

## Support

For issues with the driver installation or operation, check:
- Windows Event Viewer (System and Application logs)
- Driver Verifier output
- Debug output (if debug build)

## Legal Notice

This software is provided as-is for educational and legitimate administrative purposes. Users are responsible for compliance with local laws and regulations regarding keystroke monitoring and system modification.