# ===============================
# Printer Mapping + Idle Timeout + Log Cleanup
# ===============================

Start-Sleep -Seconds 15  # Wait for redirection to complete

# --- CONFIGURATION ---
$logFolder = "C:\log"
$logRetentionDays = 7
$idleTimeoutMinutes = 240
$currentUser = $env:USERNAME
$logPath = "$logFolder\PrinterMap_$currentUser.log"

$currentUser = ">" + $currentUser

# --- CREATE LOG FOLDER ---
New-Item -ItemType Directory -Path $logFolder -Force | Out-Null

# --- CLEAN UP OLD LOGS ---
Get-ChildItem -Path $logFolder -Filter "*.log" | Where-Object {
    $_.LastWriteTime -lt (Get-Date).AddDays(-$logRetentionDays)
} | Remove-Item -Force

# --- DETECT IDLE TIME ---
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class IdleTime {
    [DllImport("user32.dll")]
    public static extern bool GetLastInputInfo(ref LASTINPUTINFO plii);
    [StructLayout(LayoutKind.Sequential)]
    public struct LASTINPUTINFO {
        public uint cbSize;
        public uint dwTime;
    }
    public static uint GetIdleTime() {
        LASTINPUTINFO lii = new LASTINPUTINFO();
        lii.cbSize = (uint)Marshal.SizeOf(lii);
        GetLastInputInfo(ref lii);
        return ((uint)Environment.TickCount - lii.dwTime) / 60000;
    }
}
"@

$idleMinutes = [IdleTime]::GetIdleTime()
Add-Content $logPath "`n[$(Get-Date)] Idle time detected: $idleMinutes minutes"

# --- OPTIONAL: LOG OFF IF IDLE ---
if ($idleMinutes -ge $idleTimeoutMinutes) {
    Add-Content $logPath "User idle for $idleMinutes minutes. Logging off..."
    shutdown.exe /l
    exit
}

# --- GET SESSION ID ---
# Run query user and capture output
$queryOutput = query user


# Initialize session ID
$sessionID = $null

# Loop through each line and match username, session ID, and state
foreach ($line in $queryOutput) {
    if ($line -match "^\s*$currentUser\s+\S+\s+(\d+)\s+Activo") {
        $sessionID = $matches[1]
        break
    }
}

# Log result
if ($sessionID) {
    Add-Content $logPath "`n[$(Get-Date)] Detected ACTIVE session ID: $sessionID"
} else {
    Add-Content $logPath "`n[$(Get-Date)] No ACTIVE session found for user $currentUser"
}


# --- GET REDIRECTED PRINTERS ---
$printers = Get-WmiObject -Class Win32_Printer -Namespace "root\cimv2" | Where-Object {
    $_.PortName -like "TS*" -and $_.Name -like "*redireccionado*"
}

Add-Content $logPath "`nRedirected printers found:"
foreach ($printer in $printers) {
    Add-Content $logPath "Name: $($printer.Name), Port: $($printer.PortName)"
}

# --- MATCH PRINTER BY SESSION ID ---
if ($sessionID) {
    $matchedPrinter = $printers | Where-Object { $_.PortName -eq $printer.PortName }
    if ($matchedPrinter) {
        Add-Content $logPath "Matched printer by TS port: $($matchedPrinter.Name)"
    } else {
        Add-Content $logPath "No printer matched $printer.PortName. Falling back."
    }
} else {
    $matchedPrinter = $null
}

# --- FALLBACK TO FIRST REDIRECTED PRINTER ---
if (-not $matchedPrinter -and $printers.Count -gt 0) {
    $matchedPrinter = $printers[0]
    Add-Content $logPath "Using fallback printer: $($matchedPrinter.Name)"
}

# --- SET DEFAULT PRINTER ---
if ($matchedPrinter) {
    (New-Object -ComObject WScript.Network).SetDefaultPrinter($matchedPrinter.Name)
    Add-Content $logPath "Default printer set to: $($matchedPrinter.Name)"
} else {
    Add-Content $logPath "No redirected printer available to set as default."
}