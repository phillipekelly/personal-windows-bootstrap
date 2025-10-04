#Notes:
#1. run this as admin
#2. be sure to manually install GPU and mobo drivers (audio, mouse etc...)

# ========== PART 1: REMOVE BLOATWARE ==========

Write-Host "=== Removing Windows bloatware (except essential apps) ===" -ForegroundColor Cyan

$keepApps = @(
    "Microsoft.WindowsStore",
    "Microsoft.WindowsCalculator",
    "Microsoft.Windows.Photos",
    "Microsoft.WindowsCamera",
    "Microsoft.MicrosoftEdge",
    "Microsoft.DesktopAppInstaller",
    "Microsoft.BingWeather",
    "Microsoft.MSPaint",
    "Microsoft.SnippingTool" 
)

# Remove bloatware for current user
Get-AppxPackage | Where-Object {
    $packageName = $_.Name
    $keepApps -notcontains $packageName
} | ForEach-Object {
    Write-Host "Removing $($_.Name)"
    Remove-AppxPackage -Package $_.PackageFullName -ErrorAction SilentlyContinue
}

# Remove provisioned apps for new users (requires admin)
Write-Host "`nRemoving provisioned apps for new users..."
Get-AppxProvisionedPackage -Online | Where-Object {
    $packageName = $_.DisplayName
    $keepApps -notcontains $packageName
} | ForEach-Object {
    Write-Host "Removing provisioned package $($_.DisplayName)"
    Remove-AppxProvisionedPackage -Online -PackageName $_.PackageName -ErrorAction SilentlyContinue
}

Write-Host "`nBloatware removal complete.`n" -ForegroundColor Green

# --- Function: Apply Privacy Tweaks ---
function Set-PrivacySettings {
    Write-Host "Applying Windows Privacy Tweaks..." -ForegroundColor Cyan

    Try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -Type DWord
        Write-Host "Telemetry disabled." -ForegroundColor Green
    } Catch { Write-Warning "Failed to disable telemetry: $_" }

    Try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\CapabilityAccessManager\ConsentStore\location" -Name "Value" -Value "Deny" -Type String
        Write-Host "Location services disabled." -ForegroundColor Green
    } Catch { Write-Warning "Failed to disable location services: $_" }

    Try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo" -Name "Enabled" -Value 0 -Type DWord
        Write-Host "Advertising ID disabled." -ForegroundColor Green
    } Catch { Write-Warning "Failed to disable Advertising ID: $_" }

    Try {
        $apps = Get-StartApps
        foreach ($app in $apps) {
            $regPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications\$($app.PackageFamilyName)"
            if (Test-Path $regPath) {
                Set-ItemProperty -Path $regPath -Name "Enabled" -Value 0 -ErrorAction SilentlyContinue
            }
        }
        Write-Host "Background apps disabled." -ForegroundColor Green
    } Catch { Write-Warning "Failed to disable background apps: $_" }

    Try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0 -Type DWord
        Write-Host "Cortana disabled (partial)." -ForegroundColor Green
    } Catch { Write-Warning "Failed to disable Cortana: $_" }

    Try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\SettingSync" -Name "Enabled" -Value 0 -Type DWord
        Write-Host "Settings sync disabled." -ForegroundColor Green
    } Catch { Write-Warning "Failed to disable syncing: $_" }

    Try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\PenWorkspace" -Name "AllowInkWorkspace" -Value 0 -Type DWord
        Write-Host "Handwriting and Ink Workspace disabled." -ForegroundColor Green
    } Catch { Write-Warning "Failed to disable handwriting workspace: $_" }

    Try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Speech_OneCore\Settings\OnlineSpeechPrivacy" -Name "HasAccepted" -Value 0 -Type DWord
        Write-Host "Online speech recognition disabled." -ForegroundColor Green
    } Catch { Write-Warning "Failed to disable speech recognition: $_" }

    Try {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -ErrorAction SilentlyContinue | Out-Null
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "DoNotShowFeedbackNotifications" -Value 1 -Type DWord
        Write-Host "Feedback notifications disabled." -ForegroundColor Green
    } Catch { Write-Warning "Failed to disable feedback notifications: $_" }

    Try {
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SystemPaneSuggestionsEnabled" -Value 0 -Type DWord
        Write-Host "Windows Tips disabled." -ForegroundColor Green
    } Catch { Write-Warning "Failed to disable Windows Tips: $_" }

    Write-Host "Privacy tweaks applied." -ForegroundColor Yellow
}

# ========== PART 2: INSTALL / UPGRADE APPS VIA WINGET ==========

Write-Host "=== Installing / Upgrading Applications ===" -ForegroundColor Cyan

$apps = @(
    @{ Name = "Spotify";          Id = "Spotify.Spotify" },
    @{ Name = "LibreWolf";        Id = "LibreWolf.LibreWolf" },
    @{ Name = "NordVPN";          Id = "NordSecurity.NordVPN" },
    @{ Name = "VLC Media Player"; Id = "VideoLAN.VLC" },
    @{ Name = "Bitwarden";        Id = "Bitwarden.Bitwarden" },
    @{ Name = "Docker Desktop";   Id = "Docker.DockerDesktop" },
    @{ Name = "Filen Sync";       Id = "FilenCloud.FilenSync" },
    @{ Name = "MEGAsync";         Id = "Mega.MEGASync" },
    @{ Name = "Git";              Id = "Git.Git" },
    @{ Name = "IrfanView";        Id = "IrfanSkiljan.IrfanView" },
    @{ Name = "Notepad++";        Id = "Notepad++.Notepad++" },
    @{ Name = "VS Code";          Id = "Microsoft.VisualStudioCode" },
    @{ Name = "WinRAR";           Id = "RARLab.WinRAR" },
    @{ Name = "WD Security";      Id = "WesternDigital.Security" },
    @{ Name = "Python 3.13";      Id = "Python.Python.3.13" },
    @{ Name = "Terraform";        Id = "HashiCorp.Terraform" }


)

$failedInstalls = @()

foreach ($app in $apps) {
    Write-Host "`n🔄 Processing $($app.Name)..." -ForegroundColor Cyan

    # Attempt to upgrade first
    $upgradeOutput = winget upgrade --id=$($app.Id) -e --accept-source-agreements --accept-package-agreements 2>&1

    if ($upgradeOutput -match "No applicable update found" -or $upgradeOutput -match "No installed package found") {
        Write-Host "⚠️ $($app.Name) not upgraded. Attempting install..." -ForegroundColor Yellow

        try {
            winget install --id=$($app.Id) -e --accept-source-agreements --accept-package-agreements -h
            Write-Host "✅ Installed $($app.Name)." -ForegroundColor Green
        } catch {
            Write-Warning "❌ Installation failed for $($app.Name)"
            $failedInstalls += $app.Name
        }
    } else {
        Write-Host "✅ $($app.Name) upgraded (or already latest version)." -ForegroundColor Green
    }
}

# ========== PART 3: VERIFY INSTALLATION ==========

Write-Host "`n🔍 Verifying installed apps..." -ForegroundColor Cyan

foreach ($app in $apps) {
    # Escape regex special chars for Select-String
    $escapedId = [regex]::Escape($app.Id)

    $found = winget list --id $app.Id -e | Select-String -SimpleMatch $app.Id

    if (-not $found) {
        Write-Host "❌ $($app.Name) is NOT installed!" -ForegroundColor Red
        if ($app.Name -notin $failedInstalls) {
            $failedInstalls += $app.Name
        }
    } else {
        Write-Host "✅ $($app.Name) is installed." -ForegroundColor Green
    }
}

# ========== FINAL SUMMARY ==========

Write-Host "`n=== 🧾 Installation Summary ===" -ForegroundColor Yellow

if ($failedInstalls.Count -eq 0) {
    Write-Host "🎉 All applications were successfully installed or upgraded!" -ForegroundColor Green
} else {
    Write-Host "⚠️ The following applications were NOT installed or upgraded correctly:" -ForegroundColor Red
    $failedInstalls | ForEach-Object { Write-Host " - $_" -ForegroundColor Red }
}

# ========== PAUSE AT END  ==========
Read-Host -Prompt "Press Enter to exit..."
