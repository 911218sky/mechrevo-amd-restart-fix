# Mechrevo AMD Restart Fix

Languages: [简体中文](./README.md) | [繁體中文](./README.zh-TW.md) | English

A repair-focused project for `Mechrevo` AMD laptops that show problems like:

- random automatic restarts
- black-screen reboots
- freezes or sudden restarts during light load
- unstable state transitions with old AMD graphics drivers

The core idea is simple:

- create a stability-focused power plan
- set minimum processor state to `5%`
- set maximum processor state to `99%`
- disable `PCIe Link State Power Management`
- disable `Automatically restart` under `System failure`

## Fastest Way To Use It

Send this repository URL to Codex or another AI agent and ask it to use the project to repair the machine:

```text
https://github.com/911218sky/mechrevo-amd-restart-fix
```

Example prompt:

```text
Please use this project to help me fix random AMD-related restarts on my Mechrevo laptop:
https://github.com/911218sky/mechrevo-amd-restart-fix
Check my current power plan, automatic restart setting, and driver state first, then apply the mitigation from the repository.
```

This only works as intended if:

- the repository is downloaded onto the affected Windows laptop
- the agent can access that local repository
- the final script is executed there in elevated PowerShell

## AI Agent Workflow

If you want Codex or another agent to handle it, the expected flow is:

0. clone or download this repository into a local workspace the agent can access
1. open this repository
2. read `SKILL.md`
3. inspect the current power plan, `AutoReboot`, and AMD driver state
4. run `scripts/apply_mechrevo_amd_mitigation.ps1` with administrator rights
5. verify that the settings were applied
6. optionally run `scripts/restore_mechrevo_power_defaults.ps1` if you want to undo the change

Expected end state:

- active plan is `Mechrevo AMD Stability`
- minimum processor state is `5%`
- maximum processor state is `99%`
- PCIe link state power management is `Off`
- `AutoReboot = 0`

Before changing anything, at minimum confirm:

- which power plan is currently active
- whether `AutoReboot` is already `0`
- whether the AMD graphics driver looks stale, OEM-locked, or unable to update normally

## Manual Use

Expected environment:

- Windows 11
- PowerShell
- administrator rights
- the repository is already cloned or downloaded locally
- run the commands from the repository root

Apply the fix:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply_mechrevo_amd_mitigation.ps1
```

Restore the previous state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore_mechrevo_power_defaults.ps1
```

## How To Verify Success

Run:

```powershell
powercfg /GETACTIVESCHEME
$active = (powercfg /GETACTIVESCHEME | Select-String -Pattern '([A-Fa-f0-9-]{36})').Matches[0].Groups[1].Value.ToLower()
powercfg /Q $active SUB_PROCESSOR PROCTHROTTLEMIN
powercfg /Q $active SUB_PROCESSOR PROCTHROTTLEMAX
powercfg /Q $active SUB_PCIEXPRESS ASPM
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name AutoReboot
```

## What It Changes

The apply script will:

- create or re-create `Mechrevo AMD Stability`
- set minimum processor state to `5%`
- set maximum processor state to `99%`
- set PCIe link state power management to `Off`
- set `System failure -> Automatically restart` to `Off`

## What It Does Not Do

- it does not change BIOS settings automatically
- it does not run DDU automatically
- it does not prove whether the machine has a hardware fault

If the issue still remains, the next step is usually:

1. check BIOS-related settings
2. clean the AMD driver with DDU
3. install a newer AMD driver

## Verified

This project was not left untested.

It has already been tested with:

- `apply -> verify -> repeated apply -> restore -> reapply`
- real checks on the current Windows machine
- a read-only verification pass by an independent subagent

## Files

- `SKILL.md`: main Codex instructions
- `scripts/apply_mechrevo_amd_mitigation.ps1`: apply script
- `scripts/restore_mechrevo_power_defaults.ps1`: restore script
- `references/mechrevo-15x-case.md`: case notes

## Search Keywords

- `Mechrevo AMD random restart`
- `Mechrevo 15X Blizzard random restart`
- `AMD laptop random reboot fix`
- `机械革命 AMD 自动重启`
