# Windows Setup Script

PowerShell script to quickly prepare a fresh Windows installation.

It removes common Windows bloatware, applies privacy tweaks, and installs essential applications using Winget.

---

## Features

### Remove Windows Bloatware

Removes most preinstalled Windows apps while keeping essential ones like:

* Microsoft Store
* Calculator
* Photos
* Camera
* Edge
* Snipping Tool
* Paint
* Desktop App Installer

---

### Privacy Tweaks

The script modifies several Windows settings to reduce tracking:

* Disable telemetry
* Disable advertising ID
* Disable location services
* Disable background apps
* Disable Cortana
* Disable Windows tips
* Disable online speech recognition
* Disable feedback notifications

These settings are applied using registry changes.

---

### Automatic Application Installation

Applications are installed or upgraded using Winget.

Installed software includes:

* Spotify
* LibreWolf
* NordVPN
* VLC
* Bitwarden
* Docker Desktop
* Filen Sync
* MEGAsync
* Git
* IrfanView
* Notepad++
* VS Code
* WinRAR
* WD Security
* Python 3.13
* Terraform

---

## Requirements

* Windows 10 or Windows 11
* Administrator privileges
* Winget installed
* Internet connection

---

## Usage

1. Clone the repository:

```bash
git clone https://github.com/YOUR_USERNAME/windows-setup-script.git
```

2. Open **PowerShell as Administrator**

3. Run the script:

```powershell
.\InstallScript.ps1
```

---

## Important Notes

* Run the script as **Administrator**
* Some drivers must still be installed manually:

  * GPU drivers
  * Motherboard drivers
  * Audio drivers

---

## Warning

This script modifies system settings and removes built-in Windows apps.

Use at your own risk.

It is recommended to run this on **fresh Windows installations only**.

---

## License

MIT License

Copyright (c) 2025 Phil Kelly

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software...
