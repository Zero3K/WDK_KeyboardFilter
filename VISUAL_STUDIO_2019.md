# Visual Studio 2019 Build Instructions

This project now includes Visual Studio 2019 solution and project files for building the keyboard filter driver using the modern Windows Driver Kit (WDK).

## Prerequisites

1. **Visual Studio 2019** (Community, Professional, or Enterprise)
2. **Windows Driver Kit (WDK) 10** 
   - Download from Microsoft: https://docs.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk
   - The WDK must be installed after Visual Studio 2019
   - Includes all necessary headers, libraries, and build tools

## Installation Steps

1. **Install Visual Studio 2019** with C++ development tools
2. **Install Windows Driver Kit (WDK) 10**
   - The WDK installer will automatically integrate with Visual Studio 2019
   - Adds the `WindowsKernelModeDriver10.0` platform toolset

## Opening the Project

1. Double-click `bdfilter.sln` to open in Visual Studio 2019
2. Or open Visual Studio 2019 and select **File → Open → Project/Solution** and choose `bdfilter.sln`

## Build Configurations

The solution includes the following configurations:
- **Debug|Win32** - 32-bit debug build
- **Release|Win32** - 32-bit release build  
- **Debug|x64** - 64-bit debug build
- **Release|x64** - 64-bit release build

All configurations target **Windows 7** and later for maximum compatibility.

## Building the Driver

1. Select your desired configuration from the dropdown (Debug/Release, Win32/x64)
2. Build the solution using:
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

## Windows Version Compatibility

This driver is built with modern WDK 10 but maintains compatibility with:
- **Windows 7** (both 32-bit and 64-bit)
- **Windows 8/8.1**
- **Windows 10**
- **Windows 11**

The driver uses WDM (Windows Driver Model) APIs that are available across all these Windows versions.

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

**Build Methods:**
```bash
# Traditional DDK build (still works)
build -cZ

# New Visual Studio build with modern WDK
msbuild bdfilter.sln /p:Configuration=Release /p:Platform=x64

# Visual Studio IDE build
# Open bdfilter.sln in Visual Studio 2019 and build normally
```

## Troubleshooting

- **WDK not found**: 
  - Ensure WDK 10 is installed after Visual Studio 2019
  - Restart Visual Studio after WDK installation
  - Verify in **Help → About** that WDK components are listed

- **Platform Toolset not found**: 
  - The project uses `WindowsKernelModeDriver10.0` toolset from WDK
  - Ensure WDK 10 is properly installed and integrated with Visual Studio

- **Build errors**: 
  - Make sure you have WDK 10 installed and integrated with Visual Studio 2019
  - Check that all required C++ development tools are installed in Visual Studio

- **Driver signing issues**: 
  - Refer to `DRIVER_SIGNING.md` for detailed signing instructions
  - Test certificate signing is required for development/testing

## Modern WDK Benefits

Using the modern WDK provides several advantages over the legacy DDK approach:

- **Integrated Development**: Full IntelliSense support and debugging capabilities
- **Modern Toolchain**: Up-to-date compiler optimizations and security features  
- **Simplified Setup**: No need to set environment variables or manually configure paths
- **Cross-Platform**: Single project file works across different Windows versions
- **Active Support**: Microsoft actively maintains and updates the WDK

## Legacy DDK Note

This project has been modernized to use WDK 10 instead of the legacy DDK. The source code now uses `wdm.h` (modern WDK header) instead of `NTDDK.h` (legacy DDK header), while maintaining full backwards compatibility with Windows 7.