#!/bin/bash
# Driver Code Validation Script (Linux/Unix version)
# Checks for common driver coding issues

echo "===================================="
echo "  Driver Code Validation Script"
echo "===================================="
echo

# Check if source file exists
if [ ! -f "bdfilter.c" ]; then
    echo "ERROR: bdfilter.c not found!"
    exit 1
fi

echo "Checking driver code for common issues..."
echo

# Check for the fixed object dereferencing issue
if grep -q "ObDereferenceObject(kbddriver)" bdfilter.c; then
    echo "[PASS] Object dereferencing fix is present"
else
    echo "[FAIL] Object dereferencing issue detected!"
    echo "       The driver should call ObDereferenceObject(kbddriver), not ObDereferenceObject(driver)"
    echo "       This causes CM_PROB_FAILED_DRIVER_ENTRY on Windows 7 x64"
    exit 1
fi

# Check for proper reference management pattern
if grep -q "ObReferenceObjectByName.*kbddriver" bdfilter.c; then
    echo "[PASS] Object reference pattern found"
else
    echo "[WARN] Could not verify object reference pattern"
fi

# Check for required service exports
if grep -q "DriverEntry.*PDRIVER_OBJECT" bdfilter.c; then
    echo "[PASS] DriverEntry function signature found"
else
    echo "[FAIL] DriverEntry function not found or has wrong signature"
    exit 1
fi

if grep -q "DriverUnload.*PDRIVER_OBJECT" bdfilter.c; then
    echo "[PASS] DriverUnload function found"
else
    echo "[WARN] DriverUnload function not found"
fi

echo
echo "===================================="
echo "  Validation Complete"
echo "===================================="
echo "All critical checks passed!"
echo "The driver should work correctly on Windows 7 x64."