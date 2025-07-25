# Driver Signing Guide for Windows 7 x64 and Later

## Overview

Starting with Windows Vista x64 and continuing through Windows 7 x64 and later versions, Microsoft enforces **Kernel-Mode Code Signing (KMCS)**. This means all kernel-mode drivers, including our `bdfilter.sys` keyboard filter driver, must be digitally signed to load properly.

## The Problem

When trying to install an unsigned driver on Windows 7 x64, you'll encounter errors like:
- "Code integrity determined that the image hash of a file is not valid"
- "The file could be corrupt due to unauthorized modification or the invalid hash could indicate a potential disk device error"
- Driver installation failures in Device Manager

## Solutions

### Option 1: Enable Test Signing Mode (Recommended for Testing)

This is the easiest solution for testing purposes:

1. **Open Command Prompt as Administrator**
2. **Enable test signing:**
   ```cmd
   bcdedit /set testsigning on
   ```
3. **Restart your computer**
4. **Install the driver** using `install.bat`

**Note:** Test signing mode will show a watermark on your desktop indicating "Test Mode". This is normal and indicates the system will accept test-signed drivers.

**To disable test signing later:**
```cmd
bcdedit /set testsigning off
```
(requires restart)

### Option 2: Create and Use a Test Certificate

For a more proper signing approach, create a test certificate:

1. **Run the certificate creation script:**
   ```cmd
   create_test_cert.bat
   ```
   **For compiled drivers in build subdirectories:**
   ```cmd
   create_test_cert.bat objfre_win7_amd64
   ```
   This script will:
   - Create a test certificate
   - Generate a catalog file (`bdfilter.cat`)
   - Sign both the driver and catalog

2. **Install the test certificate on target machines:**
   ```cmd
   certmgr -add BdFilterTestCert.cer -s -r localMachine TrustedPublisher
   certmgr -add BdFilterTestCert.cer -s -r localMachine root
   ```

3. **Install the driver** using `install.bat` (or `install.bat [build_directory]`)

### Option 3: Sign with an Existing Certificate

If you have an existing code signing certificate:

1. **Run the signing script:**
   ```cmd
   sign_driver.bat
   ```
   **For compiled drivers in build subdirectories:**
   ```cmd
   sign_driver.bat objfre_win7_amd64
   ```
   This will prompt you for your certificate details and sign the driver.

2. **Install the certificate** (if using a test certificate)
3. **Install the driver** using `install.bat` (or `install.bat [build_directory]`)

## Working with WDK Build Output Directories

When you build the driver using the Windows Driver Kit (WDK), the compiled output goes to subdirectories based on your build configuration:

### Common WDK Build Directory Patterns

**Windows 7 DDK/WDK Build Environment:**
- `objfre_win7_x86` - Windows 7 x86 free/retail build
- `objfre_win7_amd64` - Windows 7 x64 free/retail build  
- `objchk_win7_x86` - Windows 7 x86 checked/debug build
- `objchk_win7_amd64` - Windows 7 x64 checked/debug build

**Modern WDK/Visual Studio Build Environment:**
- `x64\Debug\` - x64 debug build
- `x64\Release\` - x64 release build
- `x86\Debug\` - x86 debug build
- `x86\Release\` - x86 release build

### Using Scripts with Build Directories

All signing and installation scripts accept an optional build directory parameter:

```cmd
# Sign driver in specific build directory
create_test_cert.bat objfre_win7_amd64
sign_driver.bat objfre_win7_amd64

# Install driver from specific build directory  
install.bat objfre_win7_amd64
```

```powershell
# PowerShell installation with build directory
PowerShell -ExecutionPolicy Bypass -File install.ps1 objfre_win7_amd64
```

### Script Behavior

- **Without build directory parameter:** Scripts look for files in the current directory (`.`)
- **With build directory parameter:** Scripts look for files in the specified subdirectory
- **File verification:** Scripts verify that `bdfilter.sys` and `bdfilter.inf` exist in the target directory before proceeding

## Files Created During Signing

- **`bdfilter.cat`** - Catalog file containing cryptographic hashes of the driver files
- **`BdFilterTestCert.cer`** - Test certificate (when using create_test_cert.bat)
- **Signed `bdfilter.sys`** - Driver file with embedded digital signature

## Understanding the INF File

The `bdfilter.inf` file references a catalog file:
```ini
CatalogFile=bdfilter.cat
```

This catalog file must be present and properly signed for the driver to install without test signing mode.

## Troubleshooting

### "The required line was not found in the INF" Error
- This usually means the catalog file is missing or improperly generated
- Run `create_test_cert.bat [build_dir]` or `sign_driver.bat [build_dir]` to generate the catalog

### "Driver signature verification failed" Warning
- The driver signature might be corrupt or use an untrusted certificate
- Verify the certificate is installed in the correct stores
- Enable test signing mode as a fallback

### "bdfilter.sys not found" Error
- Ensure you've specified the correct build directory path
- Check that the driver was successfully compiled to the expected output directory
- Verify the build directory contains both `bdfilter.sys` and `bdfilter.inf`

### "Access Denied" During Certificate Installation
- Ensure you're running as Administrator
- Some antivirus software may block certificate installation

### Code Integrity Errors in Event Log
Check Windows Event Viewer under:
- **Windows Logs > System** (look for Event ID 5038)
- **Applications and Services Logs > Microsoft > Windows > CodeIntegrity > Operational**

Common error codes:
- **0xC0000428** - The file's signature cannot be verified (unsigned)
- **0xC000035** - Certificate not trusted
- **0xC0000603** - Invalid catalog

## Security Considerations

### For Development/Testing
- Test signing mode reduces system security by allowing test-signed drivers
- Only enable on development or test systems
- Disable test signing on production systems

### For Production
- Use a proper code signing certificate from a trusted CA
- Consider getting an EV (Extended Validation) certificate for kernel drivers
- Implement proper certificate management and revocation procedures

## Windows Version-Specific Notes

### Windows 7 x64
- Enforces KMCS for all kernel drivers
- Allows test signing mode
- Supports SHA-1 and SHA-256 signatures

### Windows 8/8.1 x64
- Same requirements as Windows 7
- Enhanced signature validation

### Windows 10 x64
- Stricter requirements for new kernel drivers
- Requires attestation signing from Microsoft for new drivers
- Legacy drivers can still use standard code signing

## Automated Build Integration

For automated builds, you can integrate signing into your build process:

1. **Add to your build script:**
   ```batch
   rem Generate catalog
   inf2cat /driver:. /os:7_X64,8_X64,10_X64
   
   rem Sign files
   signtool sign /f YourCert.pfx /p YourPassword /t http://timestamp.digicert.com bdfilter.sys
   signtool sign /f YourCert.pfx /p YourPassword /t http://timestamp.digicert.com bdfilter.cat
   ```

2. **Verify signatures:**
   ```batch
   signtool verify /v /kp bdfilter.sys
   signtool verify /v /kp bdfilter.cat
   ```

## Command Reference

### Enable/Disable Test Signing
```cmd
bcdedit /set testsigning on     # Enable
bcdedit /set testsigning off    # Disable
bcdedit /enum                   # Check current status
```

### Certificate Management
```cmd
certmgr -add cert.cer -s -r localMachine TrustedPublisher  # Install to Trusted Publishers
certmgr -add cert.cer -s -r localMachine root              # Install to Trusted Root CAs
certmgr -del -c -n "CertName" -s -r localMachine TrustedPublisher  # Remove certificate
```

### Driver Installation
```cmd
pnputil /add-driver bdfilter.inf /install    # Install driver package
pnputil /delete-driver bdfilter.inf          # Remove driver package
pnputil /enum-drivers                        # List installed drivers
```

### Signature Verification
```cmd
signtool verify /v /kp bdfilter.sys    # Verify driver signature
signtool verify /v /kp bdfilter.cat    # Verify catalog signature
```

## Additional Resources

- [Microsoft Driver Signing Documentation](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/driver-signing)
- [Windows Hardware Dev Center](https://developer.microsoft.com/en-us/windows/hardware)
- [Code Signing Best Practices](https://docs.microsoft.com/en-us/windows-hardware/drivers/install/code-signing-best-practices)

## FAQ

**Q: Why does my driver work on Windows 7 x86 but not x64?**
A: Only x64 versions of Windows enforce kernel-mode code signing. x86 versions are more permissive.

**Q: Can I permanently disable driver signature enforcement?**
A: While technically possible, it's not recommended as it significantly reduces system security.

**Q: My antivirus flags the test certificate as suspicious. Is this normal?**
A: Yes, test certificates and self-signed drivers often trigger antivirus warnings. This is expected behavior.

**Q: How long does a code signing certificate last?**
A: Test certificates typically last 1 year. Commercial certificates usually last 1-3 years depending on the CA.