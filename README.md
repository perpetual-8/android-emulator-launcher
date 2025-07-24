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

easiest way is to setup andriod studio.

manuall:
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
```

## 🧰 Use Cases

This tool is especially useful for:

### 👨‍💻 Android Developers
- Quickly launch emulators with predefined resource settings.
- Skip launching Android Studio just to run an emulator.

### 🧪 QA Engineers & Testers
- Use headless mode for silent background testing.
- Perform repeated cold boots to ensure app consistency across clean environments.
- View emulator status instantly and kill all sessions in one click.

### 🔄 CI/CD & Automation Pipelines
- Launch emulators directly from scripts or CI jobs via CLI mode.
- Run emulator checks and configure GPS coordinates as part of test setup.

### 🧑‍💼 DevOps / IT Teams
- Provide non-developers with a simplified interface to start Android emulators.
- Bundle into workstation setup scripts for new team members or test labs.
