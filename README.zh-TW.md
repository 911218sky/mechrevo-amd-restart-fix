# Mechrevo AMD Restart Fix

語言：[简体中文](./README.md) | 繁體中文 | [English](./README.en.md)

一個給 `機械革命 / Mechrevo` AMD 筆電使用的修復專案，專門處理這類問題：

- 隨機自動重啟
- 黑屏後重啟
- 輕負載時卡死或突然重啟
- AMD 驅動太舊，系統狀態切換不穩定

這個專案的核心做法很直接：

- 建立一個穩定性電源計畫
- 最低處理器狀態設為 `5%`
- 最高處理器狀態設為 `99%`
- 關閉 `PCIe 鏈路狀態電源管理`
- 關閉 `系統失敗時自動重新啟動`

## 一句話怎麼用

把這個專案網址丟給 Codex 或其他 AI agent，然後直接叫它幫你修復：

```text
https://github.com/911218sky/mechrevo-amd-restart-fix
```

你可以直接複製這段話：

```text
請使用這個專案幫我修復機械革命 AMD 自動重啟問題：
https://github.com/911218sky/mechrevo-amd-restart-fix
先檢查我目前的電源計畫、自動重新啟動和驅動狀態，再按專案裡的腳本幫我處理。
```

這個流程的前提是：

- 倉庫已經下載到出問題的那台 Windows 筆電上
- agent 能存取這個本地倉庫
- 最終腳本會在那台機器上用管理員 PowerShell 執行

## AI 使用流程

如果你是讓 Codex 或其他 agent 幫你操作，正常流程應該是：

0. 先把這個倉庫 clone / 下載到 agent 能存取的本地工作區
1. 打開這個倉庫
2. 讀取 `SKILL.md`
3. 檢查你目前的電源計畫、`AutoReboot` 和 AMD 驅動狀態
4. 用管理員權限執行 `scripts/apply_mechrevo_amd_mitigation.ps1`
5. 再次檢查設定是否已經成功套用
6. 如果你想撤銷，再執行 `scripts/restore_mechrevo_power_defaults.ps1`

你預期看到的結果是：

- 活動計畫變成 `Mechrevo AMD Stability`
- 最低處理器狀態是 `5%`
- 最高處理器狀態是 `99%`
- PCIe 鏈路狀態電源管理是 `關閉`
- `AutoReboot = 0`

開始修改前，至少要先確認：

- 目前活動電源計畫是什麼
- `AutoReboot` 目前是不是 `0`
- AMD 顯卡驅動是否明顯過舊、無法正常更新，或者仍是舊 OEM 版本

## 自己手動用

適用環境：

- Windows 11
- PowerShell
- 管理員權限
- 倉庫已經 clone / 下載到本地
- 在倉庫根目錄執行命令

套用修復：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\apply_mechrevo_amd_mitigation.ps1
```

還原之前的狀態：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\restore_mechrevo_power_defaults.ps1
```

## 怎麼確認已經成功

執行下面這些命令檢查：

```powershell
powercfg /GETACTIVESCHEME
$active = (powercfg /GETACTIVESCHEME | Select-String -Pattern '([A-Fa-f0-9-]{36})').Matches[0].Groups[1].Value.ToLower()
powercfg /Q $active SUB_PROCESSOR PROCTHROTTLEMIN
powercfg /Q $active SUB_PROCESSOR PROCTHROTTLEMAX
powercfg /Q $active SUB_PCIEXPRESS ASPM
Get-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Name AutoReboot
```

## 它會改什麼

套用腳本會：

- 建立或重新建立 `Mechrevo AMD Stability` 電源計畫
- 把最低處理器狀態改成 `5%`
- 把最高處理器狀態改成 `99%`
- 把 PCIe 鏈路狀態電源管理改成 `關閉`
- 把 `System failure -> Automatically restart` 設成 `關閉`

## 它不會做什麼

- 不會自動改 BIOS
- 不會自動用 DDU 卸載驅動
- 不會替你判斷是不是硬體已經損壞

如果用了這個專案後還是會重啟，下一步通常是：

1. 檢查 BIOS 相關設定
2. 用 DDU 清理 AMD 驅動
3. 安裝新的 AMD 驅動

## 已經測試過

這個專案不是只寫腳本，沒有驗證。

已經實際測試過：

- `apply -> verify -> repeated apply -> restore -> reapply`
- 目前這台機器驗證通過
- 獨立 subagent 已做過唯讀檢查，確認別的 AI 也能讀懂並驗證目前狀態

## 檔案一覽

- `SKILL.md`：給 Codex 的主說明
- `scripts/apply_mechrevo_amd_mitigation.ps1`：自動修復腳本
- `scripts/restore_mechrevo_power_defaults.ps1`：還原腳本
- `references/mechrevo-15x-case.md`：案例紀錄

## 搜尋關鍵字

- `機械革命 自動重啟`
- `機械革命 AMD 自動重啟`
- `機械革命 15X 暴風雪 自動重啟`
- `AMD 筆電 隨機重啟 修復`
