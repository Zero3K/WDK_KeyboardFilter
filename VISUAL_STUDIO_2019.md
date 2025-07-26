# Visual Studio 2019 Build Instructions

This project now includes Visual Studio 2019 solution and project files for building the keyboard filter driver.

## Prerequisites

1. **Visual Studio 2019** (Community, Professional, or Enterprise)
2. **Windows Driver Kit (WDK)** compatible with Visual Studio 2019
   - Download from Microsoft: https://docs.microsoft.com/en-us/windows-hardware/drivers/download-the-wdk

## Opening the Project

1. Double-click `bdfilter.sln` to open in Visual Studio 2019
2. Or open Visual Studio 2019 and select **File → Open → Project/Solution** and choose `bdfilter.sln`

## Build Configurations

The solution includes the following configurations:
- **Debug|Win32** - 32-bit debug build
- **Release|Win32** - 32-bit release build  
- **Debug|x64** - 64-bit debug build
- **Release|x64** - 64-bit release build

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

- **Error: Platform Toolset not found**: Ensure the Windows Driver Kit (WDK) is properly installed
- **Build errors**: Make sure you have the correct WDK version compatible with Visual Studio 2019
- **Driver signing issues**: Refer to `DRIVER_SIGNING.md` for detailed signing instructions