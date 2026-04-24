# Epic: Input Control System

> **Layer**: Foundation
> **GDD**: design/gdd/input-control-system.md
> **Architecture Module**: InputManager
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

InputManager 是输入系统封装器，处理Godot 4.6 dual-focus系统（KB/gamepad vs mouse/touch分离）。提供action_map状态快照、mouse_position（grid coordinates）、joystick_direction。所有系统查询输入通过此模块，确保正确处理dual-focus。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Input Manager Autoload | Integration | Ready | ADR-003 (⚠️ HIGH) |

InputManager 是输入系统封装器，处理Godot 4.6 dual-focus系统（KB/gamepad vs mouse/touch分离）。提供action_map状态快照、mouse_position（grid coordinates）、joystick_direction。所有系统查询输入通过此模块，确保正确处理dual-focus。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-003: Input System Architecture | InputManager Autoload, dual-focus handling, action snapshot | ⚠️ HIGH (dual-focus 4.6) |
| ADR-005: Event Bus Architecture | GlobalSignals.action_changed, focus_changed, mouse_clicked | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-input-001 | Dual-focus input system: KB/gamepad vs mouse/touch separate (Godot 4.6) | ADR-003 ✅ |
| TR-input-002 | Input action mapping: move_up/down/left/right, fire, dig, place | ADR-003 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/input-control-system.md` are verified
- is_action_pressed(), get_current_focus() unit tests pass
- ⚠️ HIGH RISK: Dual-focus tested on target engine (KB only, gamepad only, mouse only, both simultaneously)
- All 9 actions defined in Input Map configuration

## Next Step

Run `/create-stories input-control-system` to break this epic into implementable stories.