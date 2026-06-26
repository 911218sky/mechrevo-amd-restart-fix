# Mechrevo AMD Restart Fix

`mechrevo-amd-restart-fix` is a local Codex skill for diagnosing and mitigating random restarts on AMD-based Mechrevo laptops, especially models like the Mechrevo 15X Blizzard.

Search aliases:

- Simplified Chinese: `机械革命 AMD 自动重启` / `机械革命 黑屏重启` / `机械革命 蓝屏重启` / `AMD 显卡 自动重启`
- Traditional Chinese: `機械革命 AMD 自動重啟` / `機械革命 黑屏重啟` / `機械革命 藍屏重啟` / `AMD 顯卡 自動重啟`
- English: `Mechrevo AMD random restart` / `Mechrevo AMD black screen reboot` / `AMD laptop random reboot fix`

## Multilingual Summary

### 繁體中文

這是一個針對機械革命 AMD 筆電隨機重啟、黑屏、自動重新開機問題的 Codex Skill。它會建立穩定性電源計畫，將最低處理器狀態設為 `5%`、最高處理器狀態設為 `99%`、關閉 PCIe 鏈路狀態電源管理，並關閉「系統失敗時自動重新啟動」。

### 简体中文

这是一个针对机械革命 AMD 笔记本随机重启、黑屏、自动重启问题的 Codex Skill。它会创建稳定性电源计划，将最低处理器状态设为 `5%`、最高处理器状态设为 `99%`、关闭 PCIe 链路状态电源管理，并关闭“系统失败时自动重新启动”。

### English

This is a Codex skill for Mechrevo AMD laptops that show random restarts, black screens, or silent reboot behavior. It applies a stability-oriented Windows power plan, caps the maximum processor state at `99%`, sets the minimum processor state to `5%`, disables PCIe ASPM, and disables `System failure -> Automatically restart`.

It focuses on a practical, validated path instead of broad hardware-defect claims:

- create and activate a stability-focused Windows power plan
- set minimum processor state to `5%`
- set maximum processor state to `99%`
- disable PCIe Link State Power Management
- disable `System failure -> Automatically restart`
- preserve the original Windows state so it can be restored later
- document the reasoning behind the driver / BIOS / power-state diagnosis

## What This Skill Is For

Use this skill when a Mechrevo laptop with AMD graphics or an AMD APU shows:

- random restart behavior
- black screens or freezes
- crashes during light load, idle transitions, browser use, or media playback
- a stale or OEM-locked AMD graphics driver that is not updating cleanly

This skill is not a substitute for full hardware diagnosis if the machine also shows thermal shutdowns, repeat WHEA hardware errors, battery damage, or crashes outside normal Windows use.

## Search Keywords

Relevant search phrases for GitHub and web search:

- `机械革命 自动重启`
- `機械革命 自動重啟`
- `机械革命 AMD 显卡 自动重启`
- `機械革命 AMD 顯卡 自動重啟`
- `机械革命 15X 暴风雪 自动重启`
- `機械革命 15X 暴風雪 自動重啟`
- `Mechrevo 15X Blizzard random restart`
- `AMD integrated graphics reboot issue`
- `AMD laptop power plan restart fix`

## Files

- `SKILL.md`: main skill instructions for Codex
- `agents/openai.yaml`: UI metadata
- `scripts/apply_mechrevo_amd_mitigation.ps1`: admin PowerShell apply script
- `scripts/restore_mechrevo_power_defaults.ps1`: restore script
- `references/mechrevo-15x-case.md`: case notes and reasoning constraints

## How To Use

Run the apply script from PowerShell:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply_mechrevo_amd_mitigation.ps1
```

Run the restore script if you want to switch back to the previously recorded Windows state:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore_mechrevo_power_defaults.ps1
```

The script self-elevates with UAC and stores the previous plan GUID plus the original `CrashControl\AutoReboot` value in `scripts/last-apply.json`.

## Tested On This Machine

The current implementation was tested directly on this Windows machine with real `powercfg` and registry changes.

Verified behavior:

- `apply` creates or re-creates a `Mechrevo AMD Stability` plan
- active plan settings become:
  - minimum processor state: `5%` on AC/DC
  - maximum processor state: `99%` on AC/DC
  - PCIe ASPM: `Off` on AC/DC
- `CrashControl\AutoReboot` becomes `0`
- repeated `apply` while already active does not create duplicate plans
- repeated `apply` does not overwrite the saved original-state file
- `restore` switches the machine back to the saved original power plan
- after `restore`, `apply` can re-create the stability plan and apply the settings again

## Notes

- The Windows power-plan change is a mitigation, not proof of root cause.
- In the recorded case, the most likely primary fix was still replacing the stale AMD graphics driver after a DDU cleanup.
- BIOS changes such as `Operating Mode -> Turbo Mode` are documented, but not automated by this skill.

## Invocation Example

```text
Use $mechrevo-amd-restart-fix to diagnose and mitigate random AMD-related restarts on a Mechrevo laptop, and apply the admin PowerShell power-plan fix when appropriate.
```
