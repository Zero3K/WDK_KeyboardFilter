# WDK_KeyboardFilter
WDM 7600.16385.1版本

WinXp程序(64位下编译会不能使用,Test模式也不行)

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

Quick install: Run `install.bat` as Administrator
