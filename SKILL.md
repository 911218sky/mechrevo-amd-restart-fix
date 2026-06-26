---
name: mechrevo-amd-restart-fix
description: "Diagnose and mitigate random restarts, freezes, black screens, auto reboot issues, or light-load crashes on AMD-based Mechrevo / 机械革命 / 機械革命 laptops, especially Mechrevo 15X Blizzard / 15X 暴风雪 / 15X 暴風雪. Use when the user reports AMD graphics related restart problems, suspects BIOS or driver compatibility, wants a structured troubleshooting path, or wants an AI agent to apply the validated Windows power-plan mitigation automatically with elevated PowerShell."
---

# 机械革命 AMD 重启修复

## Overview

Use this skill to handle Mechrevo laptops that randomly restart or freeze under light load, media playback, or other non-stress scenarios after AMD graphics activity. Treat outdated AMD graphics drivers and unstable power-state transitions as higher-probability causes than broad claims about AMD hardware defects.

## Workflow

1. Confirm the symptom pattern before prescribing a fix.
2. Apply the least risky validated mitigation first with administrator PowerShell.
3. Escalate to DDU plus latest AMD driver reinstall if the machine is still unstable.
4. Keep BIOS advice explicit and manual; do not pretend Windows can automate vendor BIOS options unless a documented vendor CLI exists.

## Symptom Filter

Use this skill when most of the following are true:

- The laptop is a 机械革命 / Mechrevo model using AMD graphics or AMD APU graphics.
- The machine restarts, freezes, or black-screens without a clear thermal overload pattern.
- Crashes can appear during light usage, idle/light-load transitions, browser/media playback, or mixed desktop activity.
- The installed AMD driver is old, OEM-locked, or not updating normally.

If the machine also shows thermal shutdowns under heavy stress, WHEA hardware errors, battery swelling, or repeat crashes across Linux/WinPE, do not overfit this skill. Switch to broader hardware diagnosis.

## Decision Rules

- Do not present "AMD CPU design flaw" as the default conclusion.
- Do not claim BIOS is definitely the root cause if several changes were applied together.
- Prefer language like "most likely", "higher-probability", or "validated mitigation" unless the cause was isolated by A/B testing.
- Treat the OEM AMD graphics driver as a primary suspect when it is much older than current AMD releases or cannot update cleanly.

## Preferred Remediation Order

### 1. Apply the validated Windows power mitigation

Run the bundled script in elevated PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply_mechrevo_amd_mitigation.ps1
```

What it does:

- Relaunches itself as administrator if needed.
- Creates a dedicated high-performance-based power plan.
- Sets minimum processor state to `5` for AC and DC.
- Sets maximum processor state to `99` for AC and DC.
- Disables PCI Express link state power management for AC and DC.
- Disables `System failure -> Automatically restart` by setting `CrashControl\AutoReboot` to `0`.
- Activates the new plan.
- Saves the previously active plan GUID to a local state file so it can be restored later.

Use this first because it is reversible and directly targets unstable power-state transitions.

This also keeps Windows from immediately rebooting after a system failure, which makes it easier to capture minidumps and confirm whether the machine is blue-screening instead of silently restarting.

### 2. Check BIOS settings manually

For the validated case captured in `references/mechrevo-15x-case.md`, the user set:

- `Operating Mode` -> `Turbo Mode`

Important:

- Do not claim the BIOS change alone fixed the issue unless it was tested in isolation.
- Do not say AI can automate this from Windows unless the user has a vendor BIOS utility or WMI interface that is documented for this exact model.

### 3. Reinstall the AMD graphics driver cleanly

If the machine is still unstable:

1. Use DDU in Safe Mode to remove the current AMD graphics driver.
2. Install the newest AMD driver package that matches the laptop's AMD graphics hardware.
3. Prefer the official AMD package when the OEM package is old and failed to update, but keep model-specific caveats in mind.

When reporting likely cause, use this framing:

- A June 2024-era OEM AMD driver that could not update normally is a strong compatibility suspect.
- A clean install of the latest AMD driver, combined with the power-plan mitigation, is the strongest validated fix in the recorded case.

### 4. Validate over time

Do not call the issue solved after a single boot. Validate with:

- 3 to 7 days of normal use
- browser plus media playback
- light-load and idle transitions
- wake/sleep cycles if the user normally uses them

## Read-Only Verification Checklist

Use these checks when the user wants confirmation without modifying the system:

```powershell
powercfg /GETACTIVESCHEME
```

Confirm the active plan name is `Mechrevo AMD Stability`.

```powershell
$active = (powercfg /GETACTIVESCHEME | Select-String -Pattern '([A-Fa-f0-9-]{36})').Matches[0].Groups[1].Value.ToLower()
powercfg /Q $active SUB_PROCESSOR PROCTHROTTLEMIN
powercfg /Q $active SUB_PROCESSOR PROCTHROTTLEMAX
powercfg /Q $active SUB_PCIEXPRESS ASPM
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name AutoReboot
```

Confirm:

- minimum processor state is `5%` on AC and DC
- maximum processor state is `99%` on AC and DC
- PCIe ASPM is `Off` on AC and DC
- `AutoReboot` is `0`

## Automation Guidance

Use the bundled scripts instead of ad hoc commands:

- `scripts/apply_mechrevo_amd_mitigation.ps1`
- `scripts/restore_mechrevo_power_defaults.ps1`

If the user asks the AI to "auto set it with administrator PowerShell", use the apply script first. Explain that BIOS changes and DDU-based driver removal remain manual unless the user explicitly wants more aggressive automation and understands the risk.

## References

- Read `references/mechrevo-15x-case.md` for the original case, reasoning, and phrasing constraints.
