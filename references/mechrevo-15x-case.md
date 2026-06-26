# 机械革命 15X 暴风雪案例

## Device And Problem

- Device: 机械革命 15X 暴风雪
- Platform: AMD graphics related environment
- Symptom: random restart / freeze behavior, not limited to heavy load

The user initially found several possible explanations through AI search:

1. AMD integrated graphics is sensitive to power-delivery stability, while thin chassis design may simplify power circuitry.
2. BIOS optimization may be insufficient, especially during light-load voltage transitions.
3. Audio and display coordination may amplify power fluctuation during media playback.

## Reasoning Constraints

Do not overstate those three hypotheses as facts.

- Hypothesis 1 was weakened because not every machine using the same AMD graphics stack has the problem.
- Hypothesis 3 was weakened because the machine did not only restart while playing music.
- BIOS optimization remained plausible, but it was not isolated cleanly.

The most defensible final framing is:

- BIOS and power-state behavior may be part of the trigger path.
- The outdated AMD graphics driver is the strongest practical suspect.
- Because three changes were applied together, causality is not proven with certainty.

## Changes Applied

### BIOS

- `Operating Mode` -> `Turbo Mode`

### Windows power plan

- Created or switched to a high-performance style plan
- `Maximum processor state` -> `99%`
- `Minimum processor state` -> `5%`
- `PCI Express` -> `Link State Power Management` -> `Off`
- `System failure` -> `Automatically restart` -> `Off`

These settings reduce aggressive power-state transitions and were safe enough to automate with administrator PowerShell.

### Graphics driver

- Used DDU to remove the current AMD graphics driver completely
- Found that the previous AMD driver was stuck and not auto-updating
- The old driver version was from June 2024
- Installed the newest matching AMD driver from the official AMD website

## Observed Result

- After the changes above, the machine ran normally for 6 days
- The issue was considered resolved in practical use

## Recommended Wording

When an agent summarizes this case, prefer:

- "The most likely primary fix was replacing the stale OEM AMD graphics driver."
- "The power-plan changes probably reduced the trigger conditions around light-load transitions."
- "BIOS may still be involved, but the result does not prove BIOS was the sole root cause."

Avoid:

- "This proves AMD hardware has a design defect."
- "This proves BIOS alone caused the issue."
- "Playing music is the only trigger."
