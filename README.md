# Android Emulator Launcher - Professional Edition

> A powerful, user-friendly PowerShell script to manage and launch Android emulators with ease.

---

## 📦 Features

- ✅ Interactive menu-driven interface
- 🚀 Multiple launch modes:
  - Quick Start (optimized)
  - Headless (no UI)
  - Cold Boot (with data wipe)
  - Standard
  - Performance Mode (high resource config)
- 📊 System and SDK diagnostics
- 🔄 Emulator status viewer and process manager

---

## 🛠 Requirements

- **Windows PowerShell 5.1+** (or PowerShell Core)
- **Android SDK** installed with:
  - `emulator.exe`
  - `adb.exe`
- At least **one valid AVD** (Android Virtual Device)

---

## 🔧 Configuration

Edit the top of the script to adjust paths and AVD name:

```powershell
$script:Config = @{
    EmulatorPath = "C:\Path\To\Sdk\emulator\emulator.exe"
    AdbPath = "C:\Path\To\Sdk\platform-tools\adb.exe"
    AvdName = "Your_AVD_Name"
    DefaultMemory = 2048
    DefaultCores = 4
    BootTimeout = 120
}
