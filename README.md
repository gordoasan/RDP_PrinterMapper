RDP Auto Printer Mapper
========================

Author: Carlos Fraguio
Date: 2025-07-07
Environment: Windows Server 2016–2022 (Spanish Locale), Domain Joined
Legacy Stack: VB6 applications with Crystal Reports 8.5 runtime (32-bit)

Problem:
--------
Crystal 8.5 and legacy VB6 apps fail to bind reliably to RDP redirected printers due to timing and port ambiguity (e.g., TS004 != session ID 4).

Solution:
---------
This script:
- Detects idle users and logs them off after 240 min
- Logs user session info for debugging
- Scans for redirected printers by name (Spanish: *redireccionado*)
- Sets default printer with fallback
- Automatically cleans old logs (older than 7 days)
- Runs in 32-bit PowerShell (SysWOW64) for Crystal/VB6 compatibility

Tested On:
----------
- Windows Server 2016 (Spanish)
- Windows Server 2022
- Crystal Reports 8.5 Runtime
- VB6 apps compiled x86
- Domain GPO logon script, per-user

Usage:
------
1. Place PowerShell script in \\yourdomain\netlogon
2. Place .bat launcher in C:\log of each RDP host
3. Link launcher via User Logon GPO
4. Observe logs in C:\log\PrinterMap_[username].log

Future Enhancements:
--------------------
- Match printers via WMI printer owner or session tokens
- Aggregate logs to central share
- AD-based printer routing

License:
--------
For internal use within [Your Company Name]. No external distribution without permission.

# RDP Printer Auto-Mapping Deployment

This package provides a robust printer redirection system for RDP environments running 32-bit legacy applications (VB6 + Crystal Reports 8.5).

## 📂 Files
- `SetRedirectedPrinter.ps1` → Centralized in `\\yourdomain\netlogon`
- `LaunchPrinterScript.bat` → Placed locally on each RDP host in `C:\log`
- `README.md` → Deployment reference

## ✅ Features
- Detects TS printers (e.g., TS001, TS004) dynamically
- Works in Spanish Windows Server environments
- Auto-cleanup of log files older than 7 days
- Logs off idle users after 240 min
- Designed for compatibility with Crystal 8.5 runtime (32-bit)

## 📦 Installation Steps
1. Copy `SetRedirectedPrinter.ps1` to `\\yourdomain\netlogon`
2. Copy `LaunchPrinterScript.bat` to `C:\log` on each target RDP server
3. In GPMC:  
   `User Configuration → Windows Settings → Scripts (Logon)`  
   Add `C:\log\LaunchPrinterScript.bat` as the logon script
4. Confirm permissions & execution policy

## 🔒 Notes
- Log files saved to `C:\log\PrinterMap_USERNAME.log`
- Ensure PowerShell execution policy permits script (use `Bypass` via `.bat`)
- Compatible with Windows Server 2016, 2019, 2022
