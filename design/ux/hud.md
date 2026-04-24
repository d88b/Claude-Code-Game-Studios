# HUD UX Specification

> **Status**: Draft
> **Last Updated**: 2026-04-24
> **Game**: 铁锈魔潮 (Rust Magic Tide)
> **Accessibility Tier**: Standard
> **GDD References**: design/gdd/vehicle-attribute-system.md, design/gdd/time-system.md, design/gdd/day-night-cycle-system.md

---

## HUD Philosophy

玩家在探索和战斗过程中需要实时了解战车状态、环境信息，以做出撤退或继续探索的决策。HUD 必须提供关键信息而不遮挡游戏视野，支持快速决策，不干扰游戏体验。

**Player Need**: "我需要知道战车还能撑多久，是否应该撤退。"

---

## Overview

HUD（抬头显示）是玩家在地堡和地表探索时的核心信息界面。它提供实时状态监控（耐久、魔能、载重）、环境信息（时间、天气、区域）、快捷操作入口（建造、武器）。

---

## Screen Structure

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              HUD LAYOUT                                      │
└─────────────────────────────────────────────────────────────────────────────┘

┌─────────┬───────────────────────────────────────────────────────┬─────────┐
│         │                                                       │         │
│  LEFT   │                    CENTER                              │  RIGHT  │
│ PANEL   │                                                       │ PANEL   │
│         │                                                       │         │
├─────────┼───────────────────────────────────────────────────────┼─────────┤
│ HEALTH  │                                                       │ TIME    │
│ BAR     │                                                       │ DISPLAY │
│         │                                                       │         │
│ MAGIC   │                                                       │ AREA    │
│ BAR     │                       [WORLD VIEW]                    │ NAME    │
│         │                                                       │         │
│ CARGO   │                                                       │ DANGER  │
│ INDIC   │                                                       │ LEVEL   │
│         │                                                       │         │
│ WEAPON  │                                                       │         │
│ STATUS  │                                                       │         │
│         │                                                       │         │
├─────────┴───────────────────────────────────────────────────────┴─────────┤
│                              BOTTOM BAR                                      │
│  [Quick Build] [Quick Weapon] [Inventory] [Map] [Retreat Warning]           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Components

### Left Panel — Vehicle Status

| Component | Description | Update Frequency | Data Source |
|-----------|-------------|------------------|-------------|
| Health Bar | Current/max durability ratio | Per damage event | VehicleAttribute.current_health |
| Magic Bar | Current/max magic pool ratio | Per consumption | VehicleAttribute.current_magic |
| Cargo Indicator | Cargo load count / max capacity | On pickup/drop | VehicleAttribute.cargo_contents |
| Weapon Status | Active weapon icon + ammo count | Per shot | WeaponController |

### Right Panel — Environment Info

| Component | Description | Update Frequency | Data Source |
|-----------|-------------|------------------|-------------|
| Time Display | Current hour (0-23) + phase icon | Per hour change | TimeSystem.get_current_hour() |
| Area Name | Current exploration area name | On area_entered | AreaManager.current_area |
| Danger Level | Current danger multiplier | On phase change | DayNightCycle.get_danger_multiplier() |

### Bottom Bar — Quick Actions

| Button | Action | Input | Accessibility |
|--------|--------|-------|---------------|
| Quick Build | Open build menu | B key / Gamepad Y | Focusable, labeled |
| Quick Weapon | Cycle weapon | Tab / Gamepad LB | Focusable |
| Inventory | Open inventory | I key / Gamepad X | Focusable |
| Map | Toggle map overlay | M key / Gamepad RB | Focusable |
| Retreat Warning | Flash when threshold reached | Auto-display | High contrast |

---

## Visual Style

Per Art Bible Section 7 (UI/HUD Visual Direction):
- **HUD Style**: Minimalist, overlaid on gameplay view
- **Color Palette**: 霓虹蓝 (primary), 秘银银 (secondary), 符文金 (accent)
- **Shape Language**: Rounded rectangles, 2px border
- **Opacity**: 70% background, 100% critical info

---

## Accessibility Features

| Feature | Implementation |
|---------|----------------|
| **Remappable** | All HUD actions remappable via Input Map |
| **Scalable UI** | HUD scale slider in settings (0.8x - 1.5x) |
| **Colorblind Mode** | Health/Magic bars use patterns + colors |
| **Gamepad Navigation** | All HUD elements focusable via D-pad |
| **High Contrast Retreat** | Retreat warning uses flashing + sound cue |

---

## Interaction Patterns

| Pattern | Implementation |
|---------|----------------|
| **HUD Toggle** | Press H to hide/show HUD (screenshots) |
| **Status Hover** | Mouse hover on bar shows numeric values |
| **Retreat Alert** | Auto-popup when threshold reached, dismissible |
| **Quick Access** | Bottom bar shortcuts via single key press |

---

## Edge Cases

| Scenario | Behavior |
|----------|----------|
| Health < 20% | Health bar flashes red, retreat warning triggers |
| Magic < 10% | Magic bar pulses, vehicle slowdown warning |
| Night phase | Time icon changes, danger level increases |
| Area transition | Area name animates slide-in |

---

## Performance Budget

| Metric | Budget |
|--------|--------|
| HUD render time | < 0.5ms per frame |
| Update latency | < 100ms from data change |
| Memory footprint | < 2MB |

---

## HUD States by Gameplay Context

| Context | HUD Visibility | Modified Elements |
|---------|----------------|-------------------|
| **Exploration (Bunker)** | Full visible | Area = "地堡", No danger level |
| **Exploration (Surface)** | Full visible | Area = current zone, Danger active |
| **Combat** | Full visible + emphasis | Health/Magic bars enlarged, Warning priority |
| **Dialogue/Cutscene** | Minimal (only time) | Bottom bar hidden, Left panel dimmed |
| **Paused** | Hidden (pause overlay) | All HUD elements hidden |
| **Retreat Warning** | Warning overlay active | Full-screen warning, HUD dimmed |
| **Inventory/Build Menu** | Partial (status bars only) | Bottom bar replaced by menu |

---

## Platform Adaptation

### PC (Keyboard/Mouse)

- **Primary Input**: WASD + Mouse
- **HUD Interactions**: H key toggle, Mouse hover for numeric values
- **Resolution Support**: 1920x1080 (design target), scales to 4K

### PC (Gamepad)

- **Primary Input**: Left Stick + Face Buttons
- **HUD Interactions**: D-pad navigation, A button confirm
- **Focus Indicator**: Enhanced glow for gamepad focus

### Console (Future)

- **TV Safe Zone**: HUD elements within 90% screen bounds
- **Minimum Click Target**: 44x44 pixels enforced
- **No Mouse-Only Interactions**: All HUD actions gamepad-accessible

---

## Tuning Knobs

| Element | Player Adjustable | Range | Default |
|---------|-------------------|-------|---------|
| HUD Scale | Yes | 0.8x - 1.3x | 1.0x |
| HUD Opacity | Yes | 50% - 100% | 70% |
| Warning Duration | Yes | 1 min - 5 min | 2 min |
| Health Warning Threshold | No (GDD-defined) | — | 20% |
| Magic Warning Threshold | No (GDD-defined) | — | 10% |

---

## Localization Considerations

| Element | Max Characters (EN) | Expansion Space |
|---------|--------------------|-----------------| 
| Area Name | 20 | +40% (28 chars) |
| Time Display | "Day XX:XX" | Fixed format |
| Warning Text | 50 | +40% (70 chars) |
| Button Labels | 15 | +40% (21 chars) |

---

## Next Steps

- Run `/ux-review hud` to validate this spec
- Implement HUD in Godot CanvasLayer
- Create HUD widget components