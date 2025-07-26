# WDK_KeyboardFilter
WDM 7600.16385.1版本

## Build Options

**Visual Studio 2019 Support:** This project now includes Visual Studio 2019 solution and project files. See `VISUAL_STUDIO_2019.md` for complete build instructions.

**Traditional DDK Build:** The original Windows DDK build system using `sources` and `makefile` is still supported.

## Compatibility

**Recent Fix (2024):** Resolved Windows 7 x64 driver startup issue caused by incorrect object reference management in DriverEntry function.

**Platform Support:**
- Windows XP and later (32-bit)  
- Windows 7 x64 and later (with proper driver signing)

部分代码参考自<寒江独钓>一书

## Installation

**⚠️ IMPORTANT for Windows 7 x64 and later:** This driver requires proper digital signing or test signing mode enabled. See `DRIVER_SIGNING.md` for complete instructions.

**Quick fix for testing:**
```cmd
bcdedit /set testsigning on
```
(Run as Administrator, then reboot)

This repository now includes an INF file for easy driver installation:

- `bdfilter.inf` - Windows driver installation file
- `install.bat` - Automated installation script (run as Administrator)
- `uninstall.bat` - Automated uninstallation script (run as Administrator)
- `INSTALLATION.md` - Detailed installation instructions
- `DRIVER_SIGNING.md` - Driver signing guide for Windows 7 x64 and later
- `create_test_cert.bat` - Creates test certificate and signs driver
- `sign_driver.bat` - Signs driver with existing certificate

**Installation for compiled drivers:**
- If using root directory: `install.bat`
- If using build output: `install.bat objfre_win7_amd64` (replace with your build directory)

**Signing for compiled drivers:**
- If using root directory: `create_test_cert.bat` or `sign_driver.bat`
- If using build output: `create_test_cert.bat objfre_win7_amd64` or `sign_driver.bat objfre_win7_amd64`

Quick install: Run `install.bat` as Administrator (or `install.bat [build_dir]` for compiled drivers)
