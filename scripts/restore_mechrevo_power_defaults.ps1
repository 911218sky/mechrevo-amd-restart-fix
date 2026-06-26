[CmdletBinding()]
param(
    [string]$TargetPlanName = "Mechrevo AMD Stability",
    [string]$StateFilePath = ""
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
        [string]$StatePath
    )

    $arguments = @(
        "-ExecutionPolicy", "Bypass",
        "-File", ('"{0}"' -f $ScriptPath),
        "-TargetPlanName", ('"{0}"' -f $PlanName),
        "-StateFilePath", ('"{0}"' -f $StatePath)
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

if ([string]::IsNullOrWhiteSpace($StateFilePath)) {
    $StateFilePath = Join-Path $PSScriptRoot "last-apply.json"
}

if (-not (Test-IsAdministrator)) {
    Write-Host "Requesting administrator elevation..."
    Start-SelfElevated -ScriptPath $PSCommandPath -PlanName $TargetPlanName -StatePath $StateFilePath
    exit 0
}

$schemes = Get-PowerSchemeMap

if (Test-Path -LiteralPath $StateFilePath) {
    $state = Get-Content -Raw -LiteralPath $StateFilePath | ConvertFrom-Json
    $originalGuid = [string]$state.original_guid

    if ($originalGuid -and ($schemes.Values -contains $originalGuid.ToLowerInvariant())) {
        powercfg /S $originalGuid | Out-Null
        if ($null -ne $state.original_auto_reboot) {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name AutoReboot -Value ([int]$state.original_auto_reboot)
        }
        Write-Host "Restored original power plan: $($state.original_name)"
        Write-Host "State file: $StateFilePath"
        exit 0
    }
}

powercfg /S SCHEME_BALANCED | Out-Null
if (Test-Path -LiteralPath $StateFilePath) {
    $state = Get-Content -Raw -LiteralPath $StateFilePath | ConvertFrom-Json
    if ($null -ne $state.original_auto_reboot) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name AutoReboot -Value ([int]$state.original_auto_reboot)
    }
}
Write-Host "Original plan not found. Switched to Balanced plan instead."
Write-Host "State file checked: $StateFilePath"
Write-Host "This does not revert BIOS changes or AMD driver changes."
