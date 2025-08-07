# ==== Android Emulator Launcher - Professional Edition ====
# Author: System Administrator
# Version: 2.0
# Description: Professional Android emulator launcher with menu system

# ==== Configuration ====
$script:Config = @{
    EmulatorPath = "C:\Users\info\AppData\Local\Android\Sdk\emulator\emulator.exe"
    AdbPath = "C:\Users\info\AppData\Local\Android\Sdk\platform-tools\adb.exe"
    AvdName = "Small_Phone"
    DefaultMemory = 2048
    DefaultCores = 4
    BootTimeout = 120
}

# ==== Global Variables ====
$script:ErrorActionPreference = "SilentlyContinue"

# ==== Validation Functions ====
function Test-Prerequisites {
    <#
    .SYNOPSIS
    Validates all required components before launching emulator
    #>
    
    Write-Host "`n[INFO] Checking prerequisites..." -ForegroundColor Cyan
    
    # Check emulator executable
    if (-not (Test-Path $script:Config.EmulatorPath)) {
        Write-Host "[ERROR] Emulator not found at: $($script:Config.EmulatorPath)" -ForegroundColor Red
        Write-Host "[HELP] Please verify Android SDK installation" -ForegroundColor Yellow
        return $false
    }
    
    # Check ADB executable
    if (-not (Test-Path $script:Config.AdbPath)) {
        Write-Host "[ERROR] ADB not found at: $($script:Config.AdbPath)" -ForegroundColor Red
        Write-Host "[HELP] Please verify Android SDK platform-tools installation" -ForegroundColor Yellow
        return $false
    }
    
    # Verify AVD exists
    Write-Host "[INFO] Validating AVD configuration..."
    try {
        $availableAvds = & $script:Config.EmulatorPath -list-avds 2>$null
        if ($availableAvds -notcontains $script:Config.AvdName) {
            Write-Host "[ERROR] AVD '$($script:Config.AvdName)' not found" -ForegroundColor Red
            Write-Host "[INFO] Available AVDs:" -ForegroundColor Yellow
            $availableAvds | ForEach-Object { Write-Host "  * $_" -ForegroundColor Gray }
            return $false
        }
    }
    catch {
        Write-Host "[ERROR] Failed to query AVDs: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
    
    Write-Host "[SUCCESS] All prerequisites validated" -ForegroundColor Green
    return $true
}

# ==== Display Functions ====
function Show-Header {
    <#
    .SYNOPSIS
    Displays application header with system information
    #>
    
    Clear-Host
    $headerText = @"
================================================================================
                      ANDROID EMULATOR LAUNCHER v2.0
================================================================================
Current AVD: $($script:Config.AvdName)
System Time: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
================================================================================
"@
    Write-Host $headerText -ForegroundColor Cyan
}

function Show-MainMenu {
    <#
    .SYNOPSIS
    Displays the main menu options
    #>
    
    $menuText = @"

LAUNCH OPTIONS:
[1] Quick Start       - Fast boot with optimized settings (Recommended)
[2] Headless Mode     - Background operation without UI
[3] Cold Boot         - Fresh start with data wipe
[4] Standard Boot     - Normal boot with snapshot support
[5] Performance Mode  - Maximum performance configuration

MANAGEMENT OPTIONS:
[6] Show Status       - Display running emulators
[7] Kill All          - Terminate all emulator instances
[8] System Info       - Show system and SDK information
[9] Exit              - Close application
[10] Debug Mode      - Minimal settings for troubleshooting
================================================================================
"@
    Write-Host $menuText -ForegroundColor White
}

function Show-SystemInfo {
    <#
    .SYNOPSIS
    Displays system and SDK information
    #>
    
    Write-Host "`n[INFO] System Information" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    
    # System specs
    $totalRam = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    $cpuCores = (Get-CimInstance Win32_Processor).NumberOfCores
    
    Write-Host "OS Version: $([System.Environment]::OSVersion.VersionString)"
    Write-Host "Total RAM: $totalRam GB"
    Write-Host "CPU Cores: $cpuCores"
    Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
    
    # SDK information
    Write-Host "`n[INFO] Android SDK Configuration" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    Write-Host "Emulator Path: $($script:Config.EmulatorPath)"
    Write-Host "ADB Path: $($script:Config.AdbPath)"
    Write-Host "Target AVD: $($script:Config.AvdName)"
    
    # Check versions
    try {
        $adbVersion = & $script:Config.AdbPath version 2>$null | Select-Object -First 1
        Write-Host "ADB Version: $adbVersion"
    }
    catch {
        Write-Host "ADB Version: Unable to determine"
    }
    
    Read-Host "`nPress Enter to continue"
}

# ==== Device Management Functions ====
function Wait-ForEmulatorBoot {
    <#
    .SYNOPSIS
    Waits for emulator to complete boot process with progress indication
    #>
    param(
        [bool]$IsHeadless = $false
    )
    
    $startTime = Get-Date
    $timeout = $script:Config.BootTimeout
    
    if ($IsHeadless) {
        Write-Host "[INFO] Starting headless emulator..." -ForegroundColor Yellow
    } else {
        Write-Host "[INFO] Waiting for emulator boot..." -ForegroundColor Yellow
    }
    
    do {
        Start-Sleep -Seconds 3
        $elapsed = [int]((Get-Date) - $startTime).TotalSeconds
        
        try {
            $bootStatus = & $script:Config.AdbPath shell getprop sys.boot_completed 2>$null
            if ($bootStatus.Trim() -eq "1") {
                Write-Host "[SUCCESS] Emulator booted successfully ($elapsed seconds)" -ForegroundColor Green
                
                # Verify connectivity
                Write-Host "[INFO] Verifying emulator connectivity..." -ForegroundColor Cyan
                
                # Check package manager
                $packageCount = & $script:Config.AdbPath shell pm list packages 2>$null | Measure-Object | Select-Object -ExpandProperty Count
                
                # Test network connectivity
                $networkStatus = & $script:Config.AdbPath shell ping -c 1 8.8.8.8 2>$null
                $hasInternet = $LASTEXITCODE -eq 0
                
                if ($packageCount -gt 0) {
                    Write-Host "[SUCCESS] System services operational ($packageCount packages detected)" -ForegroundColor Green
                    if ($hasInternet) {
                        Write-Host "[SUCCESS] Internet connectivity verified" -ForegroundColor Green
                        return $true
                    } else {
                        Write-Host "[WARNING] Internet connectivity issues detected" -ForegroundColor Yellow
                        Write-Host "[HELP] Try the following:" -ForegroundColor Cyan
                        Write-Host "  * Verify host machine has internet access" -ForegroundColor Gray
                        Write-Host "  * Check Windows Firewall settings" -ForegroundColor Gray
                        Write-Host "  * Ensure no VPN is interfering with emulator" -ForegroundColor Gray
                        Write-Host "  * Try restarting the emulator with '-dns-server 8.8.8.8'" -ForegroundColor Gray
                    }
                } else {
                    Write-Host "[WARNING] System services not fully initialized" -ForegroundColor Yellow
                }
                return $true
            }
        }
        catch {
            # Continue waiting
        }
        
        if ($elapsed -ge $timeout) {
            Write-Host "[ERROR] Boot timeout exceeded ($timeout seconds)" -ForegroundColor Red
            Write-Host "[HELP] Try cold boot or check AVD configuration" -ForegroundColor Yellow
            return $false
        }
        
        # Progress indicator
        $progress = [math]::Min(100, ($elapsed / $timeout) * 100)
        Write-Host "[PROGRESS] Booting... $elapsed/$timeout seconds ($([math]::Round($progress, 1))%)" -ForegroundColor Gray
        
    } while ($true)
}

function Get-RunningEmulators {
    <#
    .SYNOPSIS
    Returns list of currently running emulator instances
    #>
    
    try {
        $devices = & $script:Config.AdbPath devices 2>$null
        $emulators = $devices | Where-Object { $_ -match "emulator-\d+" }
        return $emulators
    }
    catch {
        Write-Host "[ERROR] Failed to query running emulators: $($_.Exception.Message)" -ForegroundColor Red
        return @()
    }
}

function Show-EmulatorStatus {
    <#
    .SYNOPSIS
    Displays status of running emulators
    #>
    
    Write-Host "`n[INFO] Emulator Status Check" -ForegroundColor Cyan
    Write-Host "----------------------------------------"
    
    $runningEmulators = Get-RunningEmulators
    
    if ($runningEmulators.Count -gt 0) {
        Write-Host "[ACTIVE] Running emulators detected:" -ForegroundColor Green
        $runningEmulators | ForEach-Object {
            $deviceInfo = $_.Split("`t")
            if ($deviceInfo.Length -ge 2) {
                Write-Host "  * $($deviceInfo[0]) - Status: $($deviceInfo[1])" -ForegroundColor Gray
            }
        }
        
        # Get additional info for first emulator
        try {
            $firstEmulator = ($runningEmulators[0] -split "`t")[0]
            & $script:Config.AdbPath -s $firstEmulator shell getprop ro.build.version.release 2>$null | ForEach-Object {
                if ($_.Trim()) {
                    Write-Host "  * Android Version: $_" -ForegroundColor Gray
                }
            }
        }
        catch {
            # Ignore errors for additional info
        }
    } else {
        Write-Host "[IDLE] No emulators currently running" -ForegroundColor Yellow
    }
    
    Read-Host "`nPress Enter to continue"
}

function Stop-AllEmulators {
    <#
    .SYNOPSIS
    Terminates all running emulator instances
    #>
    
    Write-Host "`n[INFO] Terminating all emulator instances..." -ForegroundColor Yellow
    
    # Kill ADB server
    & $script:Config.AdbPath kill-server 2>$null
    Start-Sleep -Seconds 2
    
    # Force kill emulator processes
    try {
        $emulatorProcesses = Get-Process | Where-Object { $_.Name -like "*emulator*" -or $_.Name -like "*qemu*" }
        if ($emulatorProcesses) {
            $emulatorProcesses | Stop-Process -Force
            Write-Host "[SUCCESS] Terminated $($emulatorProcesses.Count) emulator process(es)" -ForegroundColor Green
        } else {
            Write-Host "[INFO] No emulator processes found" -ForegroundColor Gray
        }
    }
    catch {
        Write-Host "[ERROR] Failed to terminate some processes: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    # Restart ADB server
    Start-Sleep -Seconds 2
    & $script:Config.AdbPath start-server 2>$null
    Write-Host "[INFO] ADB server restarted" -ForegroundColor Green
    
    Start-Sleep -Seconds 2
}

# ==== Emulator Launch Functions ====
function Start-EmulatorInstance {
    <#
    .SYNOPSIS
    Launches emulator with specified configuration
    #>
    param(
        [Parameter(Mandatory)]
        [string]$LaunchMode
    )
    
    # Initialize ADB
    Write-Host "[INFO] Initializing ADB server..." -ForegroundColor Cyan
    & $script:Config.AdbPath start-server 2>$null
    Start-Sleep -Seconds 2
    
    $emulatorArgs = @()
    $isHeadless = $false
    $modeDescription = ""
    
    switch ($LaunchMode) {
        "quick" {
            $modeDescription = "Quick Start Mode"
            $emulatorArgs = @(
                "-avd", $script:Config.AvdName,
                "-no-snapshot-load",
                "-no-snapshot-save",
                "-gpu", "host",
                "-memory", $script:Config.DefaultMemory,
                "-cores", $script:Config.DefaultCores,
                "-dns-server", "8.8.8.8",
                "-netdelay", "none",
                "-netspeed", "full"
            )
        }
        
        "headless" {
            $modeDescription = "Headless Mode"
            $isHeadless = $true
            $emulatorArgs = @(
                "-avd", $script:Config.AvdName,
                "-no-window",
                "-no-snapshot-load",
                "-no-snapshot-save",
                "-gpu", "swiftshader_indirect",
                "-memory", $script:Config.DefaultMemory
            )
        }
        
        "cold" {
            $modeDescription = "Cold Boot Mode"
            Write-Host "[WARNING] Cold boot will reset all emulator data!" -ForegroundColor Yellow
            $confirmation = Read-Host "Continue with data wipe? (y/N)"
            if ($confirmation -notmatch "^[Yy]$") {
                Write-Host "[CANCELLED] Cold boot cancelled by user" -ForegroundColor Yellow
                return $false
            }
            $emulatorArgs = @(
                "-avd", $script:Config.AvdName,
                "-wipe-data",
                "-no-snapshot-load"
            )
        }
        
        "standard" {
            $modeDescription = "Standard Boot Mode"
            $emulatorArgs = @("-avd", $script:Config.AvdName)
        }
        
        "performance" {
            $modeDescription = "Performance Mode"
            $emulatorArgs = @(
                "-avd", $script:Config.AvdName,
                "-no-snapshot-load",
                "-no-snapshot-save",
                "-gpu", "host",
                "-memory", 4096,
                "-cores", 6,
                "-cache-size", 1024,
                "-partition-size", 2048,
                "-dns-server", "8.8.8.8",
                "-netdelay", "none",
                "-netspeed", "full"
            )
        }

        "debug" {
    $modeDescription = "Debug Mode (Minimal Settings)"
    Write-Host "[INFO] Using minimal settings for troubleshooting..." -ForegroundColor Yellow
    $emulatorArgs = @(
        "-avd", $script:Config.AvdName,
        "-gpu", "off",
        "-no-snapshot-load",
        "-no-snapshot-save",
        "-memory", 1024,
        "-cores", 2,
        "-no-audio",
        "-no-boot-anim"
    )
}
        
        default {
            Write-Host "[ERROR] Invalid launch mode: $LaunchMode" -ForegroundColor Red
            return $false
        }
    }
    
    Write-Host "[INFO] Launching emulator in $modeDescription..." -ForegroundColor Green
    Write-Host "[DEBUG] Command: $($script:Config.EmulatorPath) $($emulatorArgs -join ' ')" -ForegroundColor Gray
    
    try {
        # Launch emulator process
        $process = Start-Process -FilePath $script:Config.EmulatorPath -ArgumentList $emulatorArgs -PassThru
        
        if ($process) {
            Write-Host "[SUCCESS] Emulator process started (PID: $($process.Id))" -ForegroundColor Green
            
            # Wait for boot completion
            $bootSuccess = Wait-ForEmulatorBoot -IsHeadless $isHeadless
            
            if ($bootSuccess) {
                Write-Host "[READY] Emulator is ready for use!" -ForegroundColor Green
                return $true
            } else {
                Write-Host "[ERROR] Emulator failed to boot properly" -ForegroundColor Red
                return $false
            }
        } else {
            Write-Host "[ERROR] Failed to start emulator process" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "[ERROR] Exception during emulator launch: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Invoke-MenuAction {
    <#
    .SYNOPSIS
    Processes user menu selection
    #>
    param(
        [Parameter(Mandatory)]
        [string]$Choice
    )
    
    switch ($Choice) {
        "1" { 
            $result = Start-EmulatorInstance -LaunchMode "quick"
            if (-not $result) { Read-Host "Press Enter to continue" }
        }
        "2" { 
            $result = Start-EmulatorInstance -LaunchMode "headless"
            if (-not $result) { Read-Host "Press Enter to continue" }
        }
        "3" { 
            $result = Start-EmulatorInstance -LaunchMode "cold"
            if (-not $result) { Read-Host "Press Enter to continue" }
        }
        "4" { 
            $result = Start-EmulatorInstance -LaunchMode "standard"
            if (-not $result) { Read-Host "Press Enter to continue" }
        }
        "5" { 
            $result = Start-EmulatorInstance -LaunchMode "performance"
            if (-not $result) { Read-Host "Press Enter to continue" }
        }
        "6" { 
            Show-EmulatorStatus 
        }
        "7" { 
            Stop-AllEmulators
            Read-Host "Press Enter to continue"
        }
        "8" { 
            Show-SystemInfo 
        }
        "9" {
            Write-Host "`n[INFO] Application closing..." -ForegroundColor Cyan
            Write-Host "Thank you for using Android Emulator Launcher!" -ForegroundColor Green
            exit 0
        }
        "10" { 
    $result = Start-EmulatorInstance -LaunchMode "debug"
    if (-not $result) { Read-Host "Press Enter to continue" }
}

        default {
            Write-Host "[ERROR] Invalid selection. Please choose 1-9." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}

# ==== Main Application Entry Point ====
function Start-EmulatorLauncher {
    <#
    .SYNOPSIS
    Main application entry point
    #>
    
    # Handle command line arguments for direct launch
    if ($args.Count -gt 0) {
        $validModes = @("quick", "headless", "cold", "standard", "performance")
        $requestedMode = $args[0].ToLower()
        
        if ($requestedMode -in $validModes) {
            Write-Host "[INFO] Direct launch mode: $requestedMode" -ForegroundColor Cyan
            if (Test-Prerequisites) {
                $result = Start-EmulatorInstance -LaunchMode $requestedMode
                exit $(if ($result) { 0 } else { 1 })
            } else {
                exit 1
            }
        } else {
            Write-Host "[ERROR] Invalid launch mode. Valid options: $($validModes -join ', ')" -ForegroundColor Red
            exit 1
        }
    }
    
    # Validate prerequisites
    if (-not (Test-Prerequisites)) {
        Write-Host "`n[FATAL] Prerequisites check failed. Cannot continue." -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    
    # Main interactive loop
    do {
        Show-Header
        Show-MainMenu
        
        $userChoice = Read-Host "Select option [1-10]"
        Invoke-MenuAction -Choice $userChoice.Trim()
        
    } while ($true)
}

# ==== Script Execution ====
try {
    Start-EmulatorLauncher @args
}
catch {
    Write-Host "`n[FATAL] Unhandled exception: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[DEBUG] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor Gray
    Read-Host "Press Enter to exit"
    exit 1
}

