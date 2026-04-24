# Epic: Day-Night Cycle System

> **Layer**: Core
> **GDD**: design/gdd/day-night-cycle-system.md
> **Architecture Module**: DayNightCycle
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

日夜循环系统是时间系统的时间阶段信号到视觉和游戏效果层的桥梁。它监听时间系统发出的time_phase_changed(phase)信号，根据当前阶段（黎明/白天/黄昏/夜晚）触发对应的视觉效果和游戏难度调整。阶段切换触发危险等级倍率变化（DAWN=0.8, DAY=1.0, DUSK=1.2, NIGHT=1.5）。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Day Night Phase Manager | Logic | Ready | ADR-004, ADR-005 |

日夜循环系统是时间系统的时间阶段信号到视觉和游戏效果层的桥梁。它监听时间系统发出的time_phase_changed(phase)信号，根据当前阶段（黎明/白天/黄昏/夜晚）触发对应的视觉效果和游戏难度调整。阶段切换触发危险等级倍率变化（DAWN=0.8, DAY=1.0, DUSK=1.2, NIGHT=1.5）。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-004: Time System Architecture | TimeSystem Autoload, TIME_SCALE=60, phase boundaries | LOW |
| ADR-005: Event Bus Architecture | GlobalSignals.time_hour_changed, day_phase_changed | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-daynight-001 | Ambient lighting changes per time phase (DAWN/DAY/DUSK/NIGHT) | ADR-004 ✅ |
| TR-daynight-002 | Overlay layer visibility for night effects (darkness overlay) | ADR-004 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/day-night-cycle-system.md` are verified
- get_current_phase(), get_danger_multiplier() unit tests pass
- Visual transition (brightness interpolation) verified
- Signal emission (phase_effects_applied) verified

## Next Step

Run `/create-stories daynight` to break this epic into implementable stories.