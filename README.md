# Mechrevo AMD Restart Fix

语言：简体中文 | [繁體中文](./README.zh-TW.md) | [English](./README.en.md)

一个给 `机械革命 / Mechrevo` AMD 笔记本用的修复项目，专门处理这类问题：

- 随机自动重启
- 黑屏后重启
- 轻负载时卡死或突然重启
- AMD 驱动太旧，系统状态切换不稳定

这个项目的核心做法很直接：

- 创建一个稳定性电源计划
- 最低处理器状态设为 `5%`
- 最高处理器状态设为 `99%`
- 关闭 `PCIe 链路状态电源管理`
- 关闭 `系统失败时自动重新启动`

## 一句话怎么用

把这个项目网址发给 Codex 或其他 AI agent，然后直接叫它帮你修复：

```text
https://github.com/911218sky/mechrevo-amd-restart-fix
```

你可以直接复制这段话：

```text
请使用这个项目帮我修复机械革命 AMD 自动重启问题：
https://github.com/911218sky/mechrevo-amd-restart-fix
先检查我当前的电源计划、自动重新启动和驱动状态，再按项目里的脚本帮我处理。
```

这个流程的前提是：

- 仓库已经下载到出问题的那台 Windows 笔记本上
- agent 能访问这个本地仓库
- 最终脚本会在那台机器上用管理员 PowerShell 执行

## AI 使用流程

如果你是让 Codex 或其他 agent 帮你操作，正常流程应该是：

0. 先把这个仓库 clone / 下载到 agent 能访问的本地工作区
1. 打开这个仓库
2. 读取 `SKILL.md`
3. 检查你当前的电源计划、`AutoReboot` 和 AMD 驱动状态
4. 用管理员权限运行 `scripts/apply_mechrevo_amd_mitigation.ps1`
5. 再次检查设置是否已经成功应用
6. 如果你想撤销，再运行 `scripts/restore_mechrevo_power_defaults.ps1`

你预期看到的结果是：

- 活动计划变成 `Mechrevo AMD Stability`
- 最低处理器状态是 `5%`
- 最高处理器状态是 `99%`
- PCIe 链路状态电源管理是 `关闭`
- `AutoReboot = 0`

开始修改前，至少要先确认：

- 当前活动电源计划是什么
- `AutoReboot` 当前是不是 `0`
- AMD 显卡驱动是否明显过旧、无法正常更新，或者仍是旧 OEM 版本

## 自己手动用

适用环境：

- Windows 11
- PowerShell
- 管理员权限
- 仓库已经 clone / 下载到本地
- 在仓库根目录运行命令

应用修复：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply_mechrevo_amd_mitigation.ps1
```

还原之前的状态：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore_mechrevo_power_defaults.ps1
```

## 怎么确认已经成功

运行下面这些命令检查：

```powershell
powercfg /GETACTIVESCHEME
$active = (powercfg /GETACTIVESCHEME | Select-String -Pattern '([A-Fa-f0-9-]{36})').Matches[0].Groups[1].Value.ToLower()
powercfg /Q $active SUB_PROCESSOR PROCTHROTTLEMIN
powercfg /Q $active SUB_PROCESSOR PROCTHROTTLEMAX
powercfg /Q $active SUB_PCIEXPRESS ASPM
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name AutoReboot
```

## 它会改什么

应用脚本会：

- 创建或重新创建 `Mechrevo AMD Stability` 电源计划
- 把最低处理器状态改成 `5%`
- 把最高处理器状态改成 `99%`
- 把 PCIe 链路状态电源管理改成 `关闭`
- 把 `System failure -> Automatically restart` 设为 `关闭`

## 它不会做什么

- 不会自动改 BIOS
- 不会自动用 DDU 卸驱动
- 不会替你判断是不是硬件已经损坏

如果用了这个项目后还是会重启，下一步通常是：

1. 检查 BIOS 相关设置
2. 用 DDU 清理 AMD 驱动
3. 安装新的 AMD 驱动

## 已经测试过

这个项目不是只写脚本，没有验证。

已经实际测试过：

- `apply -> verify -> repeated apply -> restore -> reapply`
- 当前机器验证通过
- 独立 subagent 已做过只读检查，确认别的 AI 也能读懂并验证当前状态

## 文件一览

- `SKILL.md`：给 Codex 的主说明
- `scripts/apply_mechrevo_amd_mitigation.ps1`：自动修复脚本
- `scripts/restore_mechrevo_power_defaults.ps1`：还原脚本
- `references/mechrevo-15x-case.md`：案例记录

## 搜索关键词

- `机械革命 自动重启`
- `机械革命 AMD 自动重启`
- `机械革命 15X 暴风雪 自动重启`
- `AMD 笔记本 随机重启 修复`
