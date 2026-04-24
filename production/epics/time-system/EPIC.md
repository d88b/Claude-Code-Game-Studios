# Epic: Time System

> **Layer**: Foundation
> **GDD**: design/gdd/time-system.md
> **Architecture Module**: TimeSystem
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

TimeSystem 是全局时钟管理器，管理游戏时间（current_time）、天数计数（day_count）、时间尺度（time_scale=60x）。1 real second = 60 game seconds，10分钟real = 1 day cycle。小时变化emit GlobalSignals.time_hour_changed，日夜相位变化emit GlobalSignals.day_phase_changed。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Time System Autoload | Logic | Ready | ADR-004, ADR-005 |

TimeSystem 是全局时钟管理器，管理游戏时间（current_time）、天数计数（day_count）、时间尺度（time_scale=60x）。1 real second = 60 game seconds，10分钟real = 1 day cycle。小时变化emit GlobalSignals.time_hour_changed，日夜相位变化emit GlobalSignals.day_phase_changed。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-004: Time System Architecture | TimeSystem Autoload, TIME_SCALE=60, phase boundaries | LOW |
| ADR-005: Event Bus Architecture | GlobalSignals.time_hour_changed, day_phase_changed | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-time-001 | Game time scale: 1 real second = 60 game seconds | ADR-004 ✅ |
| TR-time-002 | Day/night cycle duration: 10 minutes real time per cycle | ADR-004 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/time-system.md` are verified
- get_current_hour(), get_phase() unit tests pass
- Hour/phase change events verified in integration test
- 10-minute cycle timing verified in playtest

## Next Step

Run `/create-stories time-system` to break this epic into implementable stories.