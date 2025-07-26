# Visual Studio 2019 Build Instructions

This project now includes Visual Studio 2019 solution and project files for building the keyboard filter driver.

## Prerequisites

1. **Visual Studio 2019** (Community, Professional, or Enterprise)
2. **Windows Driver Development Kit (DDK)** - Legacy DDK (not WDK)
   - The project requires the legacy Windows DDK (Driver Development Kit) 
   - Common installation paths: `C:\WINDDK\7600.16385.1\` or similar
   - **Important**: You must set the `DDKROOT` environment variable to point to your DDK installation directory

## Environment Setup

### Setting the DDKROOT Environment Variable

Before building, you must set the `DDKROOT` environment variable to point to your DDK installation:

**Method 1: System Environment Variables**
1. Right-click **This PC** → **Properties** → **Advanced system settings** → **Environment Variables**
2. Under **System variables**, click **New**
3. Variable name: `DDKROOT`
4. Variable value: Path to your DDK installation (e.g., `C:\WINDDK\7600.16385.1`)
5. Click **OK** and restart Visual Studio

**Method 2: Visual Studio Project Settings**
1. Open the project in Visual Studio
2. Right-click the project → **Properties**
3. Go to **Configuration Properties** → **Build Events** → **Pre-Build Event**
4. Add: `set DDKROOT=C:\WINDDK\7600.16385.1` (adjust path as needed)

## Opening the Project

1. Ensure `DDKROOT` environment variable is set
2. Double-click `bdfilter.sln` to open in Visual Studio 2019
3. Or open Visual Studio 2019 and select **File → Open → Project/Solution** and choose `bdfilter.sln`

## Build Configurations

The solution includes the following configurations:
- **Debug|Win32** - 32-bit debug build
- **Release|Win32** - 32-bit release build  
- **Debug|x64** - 64-bit debug build
- **Release|x64** - 64-bit release build

## Building the Driver

1. Verify that `DDKROOT` is set correctly (see Environment Setup above)
2. Select your desired configuration from the dropdown (Debug/Release, Win32/x64)
3. Build the solution using:
   - **Build → Build Solution** (Ctrl+Shift+B)
   - Or right-click the project and select **Build**

The compiled driver (`bdfilter.sys`) will be output to:
- `Debug/` or `Release/` folder for Win32 builds
- `x64/Debug/` or `x64/Release/` folder for x64 builds

## Project Structure in Visual Studio

- **Source Files/**
  - `bdfilter.c` - Main driver source code
- **Driver Files/**
  - `bdfilter.inf` - Driver installation file
- **Build Files/**
  - `sources` - Original DDK build configuration
  - `makefile` - Original DDK makefile

## Driver Signing and Installation

After building, the driver must be signed before installation on Windows 7 x64 and later:

1. Use the included batch files for signing:
   - `create_test_cert.bat [build_output_dir]` - Creates test certificate and signs driver
   - `sign_driver.bat [build_output_dir]` - Signs driver with existing certificate

2. Install the driver:
   - `install.bat [build_output_dir]` - Installs the signed driver

**Note:** For the Visual Studio builds, specify the build output directory (e.g., `Release`, `x64\Release`) as the parameter to the batch files.

## Compatibility with Existing Build System

The original DDK build system (using `sources` and `makefile`) remains fully functional. This Visual Studio solution is an additional build method and does not replace the existing system.

## Troubleshooting

- **Error: Cannot open include file: 'NTDDK.h'**: 
  - Verify that `DDKROOT` environment variable is set correctly
  - Check that your DDK installation contains the `inc\ddk` directory
  - Restart Visual Studio after setting environment variables
- **Platform Toolset not found**: The project uses standard Visual Studio 2019 compiler (v142), not WDK toolset
- **Build errors**: Make sure you have the legacy DDK installed and `DDKROOT` properly configured
- **Driver signing issues**: Refer to `DRIVER_SIGNING.md` for detailed signing instructions

## DDK vs WDK Note

This project uses the legacy Windows DDK (Driver Development Kit) rather than the modern WDK (Windows Driver Kit). The DDK was the predecessor to WDK and uses different header files and build systems. The Visual Studio project has been configured to work with the legacy DDK structure.