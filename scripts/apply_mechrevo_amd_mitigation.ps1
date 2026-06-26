[CmdletBinding()]
param(
    [string]$TargetPlanName = "Mechrevo AMD Stability",
    [string]$StateFilePath = "",
    [string]$LogPath = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Start-SelfElevated {
    param(
        [string]$ScriptPath,
        [string]$PlanName,
        [string]$StatePath,
        [string]$TranscriptPath
    )

    $arguments = @(
        "-ExecutionPolicy", "Bypass",
        "-File", ('"{0}"' -f $ScriptPath),
        "-TargetPlanName", ('"{0}"' -f $PlanName),
        "-StateFilePath", ('"{0}"' -f $StatePath),
        "-LogPath", ('"{0}"' -f $TranscriptPath)
    ) -join " "

    Start-Process -FilePath "powershell.exe" -ArgumentList $arguments -Verb RunAs -Wait
}

function Get-PowerSchemeMap {
    $schemes = @{}
    foreach ($line in (powercfg /L)) {
        if ($line -match '([A-Fa-f0-9-]{36}).*\((.+?)\)') {
            $guid = $matches[1].ToLowerInvariant()
            $name = $matches[2]
            $schemes[$name] = $guid
        }
    }
    return $schemes
}

function Get-ActiveScheme {
    foreach ($line in (powercfg /GetActiveScheme)) {
        if ($line -match '([A-Fa-f0-9-]{36}).*\((.+?)\)') {
            return [pscustomobject]@{
                Guid = $matches[1].ToLowerInvariant()
                Name = $matches[2]
            }
        }
    }
    throw "Unable to determine the active power scheme."
}

function Duplicate-Scheme {
    param(
        [string]$SourceScheme,
        [string]$NewName
    )

    $newGuid = ([guid]::NewGuid().Guid).ToLowerInvariant()
    powercfg /duplicatescheme $SourceScheme $newGuid | Out-Null

    powercfg /changename $newGuid $NewName | Out-Null
    return $newGuid
}

function Save-StateFile {
    param(
        [string]$Path,
        [pscustomobject]$ActiveScheme
    )

    $directory = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($directory)) {
        New-Item -ItemType Directory -Force -Path $directory | Out-Null
    }

    $payload = [pscustomobject]@{
        saved_at = (Get-Date).ToString("o")
        original_guid = $ActiveScheme.Guid
        original_name = $ActiveScheme.Name
        target_plan_name = $TargetPlanName
        original_auto_reboot = (Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name AutoReboot).AutoReboot
    }

    $payload | ConvertTo-Json | Set-Content -Encoding UTF8 -Path $Path
}

if ([string]::IsNullOrWhiteSpace($StateFilePath)) {
    $StateFilePath = Join-Path $PSScriptRoot "last-apply.json"
}

if ([string]::IsNullOrWhiteSpace($LogPath)) {
    $LogPath = Join-Path $PSScriptRoot "apply-transcript.log"
}

if (-not (Test-IsAdministrator)) {
    Write-Host "Requesting administrator elevation..."
    Start-SelfElevated -ScriptPath $PSCommandPath -PlanName $TargetPlanName -StatePath $StateFilePath -TranscriptPath $LogPath
    exit 0
}

try {
    Start-Transcript -Path $LogPath -Append | Out-Null

    $active = Get-ActiveScheme
    $schemes = Get-PowerSchemeMap

    if (-not $schemes.ContainsKey($TargetPlanName)) {
        Write-Host "Creating target plan from High performance..."
        $targetGuid = Duplicate-Scheme -SourceScheme "SCHEME_MIN" -NewName $TargetPlanName
    } else {
        $targetGuid = $schemes[$TargetPlanName]
    }

    if ($active.Guid -ne $targetGuid) {
        Save-StateFile -Path $StateFilePath -ActiveScheme $active
    } elseif (-not (Test-Path -LiteralPath $StateFilePath)) {
        Save-StateFile -Path $StateFilePath -ActiveScheme $active
    } else {
        Write-Host "Current active plan already matches target; keeping existing state file."
    }

    Write-Host "Applying CPU and PCIe stability settings to: $TargetPlanName"
    powercfg /setacvalueindex $targetGuid SUB_PROCESSOR PROCTHROTTLEMIN 5 | Out-Null
    powercfg /setdcvalueindex $targetGuid SUB_PROCESSOR PROCTHROTTLEMIN 5 | Out-Null
    powercfg /setacvalueindex $targetGuid SUB_PROCESSOR PROCTHROTTLEMAX 99 | Out-Null
    powercfg /setdcvalueindex $targetGuid SUB_PROCESSOR PROCTHROTTLEMAX 99 | Out-Null
    powercfg /setacvalueindex $targetGuid SUB_PCIEXPRESS ASPM 0 | Out-Null
    powercfg /setdcvalueindex $targetGuid SUB_PCIEXPRESS ASPM 0 | Out-Null
    powercfg /S $targetGuid | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name AutoReboot -Value 0

    Write-Host ""
    Write-Host "Applied plan:  $TargetPlanName"
    Write-Host "Saved prior active plan to: $StateFilePath"
    Write-Host "CPU min state: 5% (AC/DC)"
    Write-Host "CPU max state: 99% (AC/DC)"
    Write-Host "PCIe ASPM:     Off (AC/DC)"
    Write-Host "Auto restart:  Off on system failure"
    Write-Host ""
    Write-Host "Next manual steps if instability remains:"
    Write-Host "1. Check BIOS Operating Mode / thermal mode manually."
    Write-Host "2. Use DDU in Safe Mode."
    Write-Host "3. Install the latest matching AMD graphics driver."
} catch {
    Write-Error $_
    throw
} finally {
    try {
        Stop-Transcript | Out-Null
    } catch {
    }
}
