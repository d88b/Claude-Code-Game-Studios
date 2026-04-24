# Pause Menu UX Specification

> **Status**: Draft
> **Last Updated**: 2026-04-24
> **Game**: 铁锈魔潮 (Rust Magic Tide)
> **Accessibility Tier**: Standard
> **Platform Target**: PC (Keyboard/Mouse + Gamepad)

---

## Purpose & Player Need

玩家在游戏过程中需要暂时中断（休息、调整设置、保存进度）。暂停菜单需要快速响应，保留游戏状态，提供安全的退出路径。

**Player Need**: "我想暂停游戏、调整设置或保存进度，然后继续或退出。"

---

## Player Context on Arrival

玩家状态：
- **主动暂停**: 想休息或调整设置，无紧迫感
- **被动暂停**: Retreat warning triggered，处于决策压力
- **保存需求**: 想保存当前进度以防丢失

玩家到达此界面时游戏时间已停止，可自由浏览，无外部时间压力。

---

## Navigation Position

```
[Gameplay] → Pause Menu (overlay)
                ↓
          [Settings Menu] → Pause Menu
                ↓
          [Save Dialog] → Pause Menu → [Saved]
                ↓
          [Load Dialog] → Pause Menu → [Game Session]
                ↓
          [Main Menu] → [App Start Point]
```

暂停菜单是游戏流程中的覆盖层节点，不终止游戏状态（除非选择 Main Menu）。

---

## Entry & Exit Points

### Entry Sources

| Source | Trigger | Player State |
|--------|---------|--------------|
| Gameplay (active) | Escape key / Start button | Exploration or Combat |
| Retreat Warning | Warning auto-trigger | Critical threshold reached |

### Exit Destinations

| Destination | Trigger | Transition |
|-------------|---------|------------|
| Gameplay (resume) | Resume / Quick Resume | Overlay fade out (0.3s) |
| Settings Menu | Settings button | Overlay slide-in |
| Save Dialog | Save Game button | Modal dialog popup |
| Load Dialog | Load Game button | Modal dialog popup |
| Main Menu | Main Menu → Confirm | Fade transition (1s) |

---

## Overview

暂停菜单是玩家在游戏过程中暂停游戏状态的界面。它需要快速响应、不干扰游戏状态、提供常用操作入口（继续、设置、保存、退出）。

---

## Screen Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          PAUSE MENU LAYOUT                                   │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                         [GAME VIEW (DIMMED)]                                │
│                     Opacity 50%, background blur optional                   │
│                                                                             │
│     ┌───────────────────────────────────────────────────────────┐           │
│     │                       PAUSED                               │           │
│     │                      游戏暂停                              │           │
│     ├───────────────────────────────────────────────────────────┤           │
│     │                                                           │           │
│     │         ┌─────────────────────┐                            │           │
│     │         │    RESUME          │  ← Primary action           │           │
│     │         └─────────────────────┘                            │           │
│     │                                                           │           │
│     │         ┌─────────────────────┐                            │           │
│     │         │    SETTINGS        │                             │           │
│     │         └─────────────────────┘                            │           │
│     │                                                           │           │
│     │         ┌─────────────────────┐                            │           │
│     │         │    SAVE GAME       │                             │           │
│     │         └─────────────────────┘                            │           │
│     │                                                           │           │
│     │         ┌─────────────────────┐                            │           │
│     │         │    LOAD GAME       │                             │           │
│     │         └─────────────────────┘                            │           │
│     │                                                           │           │
│     │         ┌─────────────────────┐                            │           │
│     │         │    MAIN MENU       │                             │           │
│     │         └─────────────────────┘                            │           │
│     │                                                           │           │
│     └───────────────────────────────────────────────────────────┘           │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  [Current Time]   [Health Status]                    [Controls Hint]       │
│  Day 14:30        85%                                  "Esc to Resume"      │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Components

### Header

| Component | Description | Data Source |
|-----------|-------------|-------------|
| "PAUSED" Title | 游戏暂停标题 | Static |
| Current Time | 当前游戏时间 | TimeSystem.get_time_string() |
| Health Status | 车辆耐久百分比 | VehicleAttribute.get_durability_ratio() |

### Menu Buttons

| Button | Action | Priority | Consequence |
|--------|--------|----------|-------------|
| Resume | Continue gameplay | Primary | Close pause menu, resume game |
| Settings | Open settings overlay | Secondary | Open settings, pause remains |
| Save Game | Save current session | Secondary | Save dialog → confirm → save |
| Load Game | Load saved session | Secondary | Load dialog → confirm → load |
| Main Menu | Return to main menu | Tertiary | Confirm dialog → main menu |

### Footer

| Component | Description |
|-----------|-------------|
| Controls Hint | "Press Escape to Resume" or "B to Resume" |

---

## Visual Style

Per Art Bible Section 7 (UI/HUD Visual Direction):
- **Background**: Game view dimmed (50% opacity), optional blur
- **Panel Style**: Centered rounded rectangle, 4px border, 70% opacity
- **Button Style**: Rounded rectangle, 2px border, 霓虹蓝 hover glow
- **Color Palette**:
  - Panel: 秘银银背景，符文金边框
  - Normal: 秘银银背景
  - Hover: 霓虹蓝 glow
  - Active: 符文金 fill
- **Typography**: 信仰雅黑 (primary), 16-24px

---

## Accessibility Features

| Feature | Implementation |
|---------|----------------|
| **Keyboard Navigation** | Tab / Arrow keys to navigate, Enter to confirm |
| **Gamepad Navigation** | D-pad / Left Stick to navigate, A to confirm, B to resume |
| **Focus Indicator** | 2px 霓虹蓝 border on focused button |
| **Quick Resume** | Escape or B button instantly resumes (no confirm) |
| **Scalable UI** | Menu scale slider in settings |
| **Status Display** | Health/time visible for orientation |

---

## Interaction Patterns

| Pattern | Implementation |
|---------|----------------|
| **Open Pause** | Escape key or Start button (gamepad) |
| **Vertical Navigation** | Up/Down Arrow or D-pad Up/Down |
| **Selection Confirmation** | Enter or A button |
| **Quick Resume** | Escape or B button (instant, no confirmation) |
| **Exit Confirmation** | "Main Menu" requires confirmation dialog |

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| No save file | "Load Game" disabled or shows "No saves" |
| Critical health | Show health warning in footer (red indicator) |
| During event | Pause blocked during cutscene/dialogue (advisory) |
| Save in progress | Disable "Save Game" while saving |

---

## Flow

1. **Trigger**: User presses Escape or Start button during gameplay
2. **Pause State**: Game time pauses, input locked to menu
3. **Display**: Pause panel appears with "Resume" as default focus
4. **Navigation**: User navigates with input, selects button
5. **Action**:
   - Resume → Close menu, resume game
   - Settings → Open settings overlay
   - Save → Save dialog → confirm → save → return to pause
   - Load → Load dialog → confirm → load → resume gameplay
   - Main Menu → Confirm dialog → fade to main menu

---

## Confirmation Dialogs

### Save Confirmation

```
┌─────────────────────────────────┐
│         SAVE GAME               │
│                                 │
│   Save to slot [Slot Name]?     │
│                                 │
│   [Cancel]        [Confirm]     │
└─────────────────────────────────┘
```

### Load Confirmation

```
┌─────────────────────────────────┐
│         LOAD GAME               │
│                                 │
│   Load [Slot Name]?             │
│   Current progress will be lost │
│                                 │
│   [Cancel]        [Confirm]     │
└─────────────────────────────────┘
```

### Main Menu Confirmation

```
┌─────────────────────────────────┐
│     RETURN TO MAIN MENU?        │
│                                 │
│   Unsaved progress will be lost │
│                                 │
│   [Cancel]        [Confirm]     │
└─────────────────────────────────┘
```

---

## Localization Considerations

| Element | Max Characters (EN) | Max Characters (CN) | Expansion Space |
|---------|--------------------|--------------------|-----------------|
| "PAUSED" | 10 | 4 (游戏暂停) | Fixed title |
| "Resume" | 10 | 4 (继续) | +40% button width |
| "Settings" | 10 | 4 (设置) | +40% button width |
| "Save Game" | 12 | 4 (保存) | +40% button width |
| "Load Game" | 12 | 4 (读取) | +40% button width |
| "Main Menu" | 12 | 6 (主菜单) | +40% button width |
| Time Display | "Day XX:XX" | "第X天 XX:XX" | Fixed format |
| Health Status | "XX%" | "耐久 XX%" | Fixed format |
| Dialog titles | 15 | 6 | +40% |
| Dialog messages | 50 | 30 | +40% |

**Font Requirement**: 信仰雅黑 (CN) + Orbitron (EN fallback)

---

## Performance Budget

| Metric | Budget |
|--------|--------|
| Pause latency | < 100ms from input |
| Resume latency | < 100ms from input |
| Animation smoothness | 60 fps |

---

## Validation Checklist

- [ ] Pause triggers on Escape/Start
- [ ] Game time pauses correctly
- [ ] Resume button focused by default
- [ ] All buttons focusable via keyboard
- [ ] All buttons focusable via gamepad
- [ ] Quick resume works (Escape/B)
- [ ] Confirmation dialogs work for Load/Main Menu
- [ ] Save in progress blocks menu
- [ ] Status info visible in footer

---

## Next Steps

- Run `/ux-review pause-menu` to validate this spec
- Create pause menu scene in Godot
- Implement pause logic (TimeSystem.pause())