# Main Menu UX Specification

> **Status**: Draft
> **Last Updated**: 2026-04-24
> **Game**: 铁锈魔潮 (Rust Magic Tide)
> **Accessibility Tier**: Standard
> **Platform Target**: PC (Keyboard/Mouse + Gamepad)

---

## Purpose & Player Need

玩家刚启动游戏，想要开始新的探险或继续之前的进度。主菜单需要快速响应，传达游戏风格，提供无障碍的启动入口。

**Player Need**: "我想快速开始或继续我的游戏进度。"

---

## Player Context on Arrival

玩家状态：
- **首次启动**: 无存档，期待了解游戏氛围，选择"New Game"
- **有存档**: 有上次进度，期待快速继续，选择"Continue"
- **从暂停返回**: 有活跃游戏状态，期待重新开始或切换存档

玩家到达此界面时无压力，可自由浏览，无时间限制。

---

## Navigation Position

```
[App Launch] → Main Menu → [Game Session]
                    ↓
              [Settings Menu] → Main Menu
                    ↓
              [Exit Confirm] → [Desktop]
```

主菜单是游戏的入口节点，是所有玩家流程的起点。

---

## Entry & Exit Points

### Entry Sources

| Source | Trigger | Player State |
|--------|---------|--------------|
| App Launch | Game executable start | Fresh session |
| Pause Menu → Main Menu | Confirm exit | Active gameplay (terminated) |
| Settings Menu → Back | Back button | Settings complete |

### Exit Destinations

| Destination | Trigger | Transition |
|-------------|---------|------------|
| Game Session | New Game / Continue | Fade transition (1s) |
| Settings Menu | Settings button | Overlay slide-in |
| Desktop | Exit → Confirm | Fade out (0.5s) |

---

## Overview

主菜单是玩家首次进入游戏的界面。它需要传达游戏的魔导科技美学风格，提供清晰的游戏启动入口，支持键盘和游戏pad导航。

---

## Screen Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                          MAIN MENU LAYOUT                                    │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────────────┐
│                                                                             │
│                           [GAME LOGO / TITLE]                               │
│                         铁锈魔潮                                            │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│                          [BACKGROUND ART]                                   │
│                     地堡入口 / 战车剪影 / 符文背景                           │
│                                                                             │
│                                                                             │
│                                                                             │
│         ┌─────────────────────┐                                             │
│         │    NEW GAME         │  ← Primary action                           │
│         └─────────────────────┘                                             │
│                                                                             │
│         ┌─────────────────────┐                                             │
│         │    CONTINUE         │  ← Show if save exists                      │
│         └─────────────────────┘                                             │
│                                                                             │
│         ┌─────────────────────┐                                             │
│         │    SETTINGS         │                                             │
│         └─────────────────────┘                                             │
│                                                                             │
│         ┌─────────────────────┐                                             │
│         │    EXIT             │                                             │
│         └─────────────────────┘                                             │
│                                                                             │
├─────────────────────────────────────────────────────────────────────────────┤
│  [Version Info]                                        [Controls Hint]      │
│  v0.1.0-alpha                                          "Press Enter"       │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Components

### Title Area

| Component | Description | Visual Style |
|-----------|-------------|--------------|
| Game Logo | 铁锈魔潮 title with rune glow | 霓虹蓝发光效果，符文金边框 |
| Subtitle | Rust Magic Tide (英文副标题) | 秘银银，较小字体 |

### Menu Buttons

| Button | Action | Priority | Visibility |
|--------|--------|----------|------------|
| New Game | Start fresh game session | Primary | Always visible |
| Continue | Load most recent save | Secondary | Only if save exists |
| Settings | Open settings menu | Tertiary | Always visible |
| Exit | Quit to desktop | Tertiary | Always visible |

### Footer

| Component | Description |
|-----------|-------------|
| Version Info | Current build version (e.g., v0.1.0-alpha) |
| Controls Hint | "Press Enter to select" or "A button to select" |

---

## Visual Style

Per Art Bible Section 7 (UI/HUD Visual Direction):
- **Background**: 地堡入口剪影 + 符文魔法粒子效果
- **Button Style**: Rounded rectangle, 2px border, 霓虹蓝 hover glow
- **Color Palette**:
  - Normal: 秘银银背景，符文金边框
  - Hover: 霓虹蓝 glow
  - Active: 符文金 fill
- **Typography**: 信仰雅黑 (primary), 16-24px

---

## Accessibility Features

| Feature | Implementation |
|---------|----------------|
| **Keyboard Navigation** | Tab / Arrow keys to navigate, Enter to confirm |
| **Gamepad Navigation** | D-pad / Left Stick to navigate, A button to confirm |
| **Focus Indicator** | 2px 霓虹蓝 border on focused button |
| **Colorblind Mode** | Focus indicator uses glow + border pattern |
| **Scalable UI** | Menu scale slider in settings (0.8x - 1.5x) |

---

## Interaction Patterns

| Pattern | Implementation |
|---------|----------------|
| **Vertical Navigation** | Up/Down Arrow or D-pad Up/Down |
| **Selection Confirmation** | Enter or A button |
| **Back/Cancel** | Escape or B button (none on main menu) |
| **Hover Effect** | Mouse hover shows glow effect |
| **Click Effect** | Left click confirms selection |

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| No save file | "Continue" button hidden or grayed out |
| First launch | Show "New Game" as default focus |
| Gamepad connected | Show gamepad button hints (A, B) |
| Keyboard only | Show keyboard hints (Enter, Escape) |

---

## Flow

1. **Entry**: Screen loads with title animation (rune glow fade-in)
2. **Focus**: Default focus on "New Game" (or "Continue" if save exists)
3. **Selection**: User navigates with input, selects button
4. **Transition**: 
   - New Game → Fade to gameplay intro
   - Continue → Fade to saved session
   - Settings → Open settings overlay
   - Exit → Confirm dialog → Quit

---

## States & Variants

### Normal State

- All buttons visible and interactive
- Background art animated (rune particles)
- Default focus on "New Game" or "Continue"

### Loading State

- Triggered on: New Game / Continue selection
- Visual: Buttons dimmed, loading spinner overlay
- Duration: < 1 second (design target)
- Cancel: Not allowed once transition starts

### Error State

| Error | Visual | Recovery |
|-------|--------|----------|
| Save file corrupted | "Continue" grayed out + tooltip | Auto-create new save slot |
| Settings load failed | Default settings fallback | Silent recovery |
| Asset load failed | Retry button overlay | Player retry option |

### Empty State (No Save)

- "Continue" button: Hidden or grayed out with "No save found" tooltip
- Focus default: "New Game"
- Subtle hint: "Start your adventure" text below "New Game"

---

## Localization Considerations

| Element | Max Characters (EN) | Max Characters (CN) | Expansion Space |
|---------|--------------------|--------------------|-----------------|
| Game Title | 18 (Rust Magic Tide) | 4 (铁锈魔潮) | Title art — fixed |
| "New Game" | 10 | 4 (新游戏) | +40% button width |
| "Continue" | 10 | 4 (继续) | +40% button width |
| "Settings" | 10 | 4 (设置) | +40% button width |
| "Exit" | 5 | 2 (退出) | +40% button width |
| Version Info | 12 (v0.1.0-alpha) | 12 | Fixed format |
| Controls Hint | 20 | 15 | +40% |

**Font Requirement**: 信仰雅黑 (CN) + Orbitron (EN fallback)

---

## Performance Budget

| Metric | Budget |
|--------|--------|
| Load time | < 1 second |
| Animation smoothness | 60 fps |
| Memory footprint | < 5MB (background art) |

---

## Validation Checklist

- [ ] Title visible and readable
- [ ] All buttons focusable via keyboard
- [ ] All buttons focusable via gamepad
- [ ] Focus indicator visible (2px border + glow)
- [ ] Continue button hidden when no save
- [ ] Exit confirmation dialog works
- [ ] Background art loads within budget

---

## Next Steps

- Run `/ux-review main-menu` to validate this spec
- Create main menu scene in Godot
- Implement menu button navigation