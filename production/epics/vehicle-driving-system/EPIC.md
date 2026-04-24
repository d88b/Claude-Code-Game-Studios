# Epic: Vehicle Driving System

> **Layer**: Core
> **GDD**: design/gdd/vehicle-driving-system.md
> **Architecture Module**: VehicleController
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

战车驾驶系统是战车移动的执行层。它从输入控制系统接收语义化的驾驶指令（drive_forward/backward/left/right），从战车属性系统查询当前速度和运动状态，通过方块碰撞系统检测移动边界，最终驱动战车CharacterBody2D在TileMap网格上移动。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Vehicle Movement Loop | Logic | Ready | ADR-003 (⚠️ HIGH) |

战车驾驶系统是战车移动的执行层。它从输入控制系统接收语义化的驾驶指令（drive_forward/backward/left/right），从战车属性系统查询当前速度和运动状态，通过方块碰撞系统检测移动边界，最终驱动战车CharacterBody2D在TileMap网格上移动。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-003: Input System Architecture | InputManager Autoload, dual-focus handling, action snapshot | ⚠️ HIGH (dual-focus 4.6) |
| ADR-005: Event Bus Architecture | GlobalSignals.action_changed, focus_changed | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-driving-001 | Acceleration formula: velocity = velocity + acceleration_rate * input_direction * delta | ADR-003 ✅ |
| TR-driving-002 | Speed clamp: |velocity| <= max_speed from VehicleTypeDB | ADR-003 ✅ |
| TR-driving-003 | Magic consumption per movement: cells * MAGIC_COST_PER_CELL (TK-013 = 0.5) | ADR-003 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/vehicle-driving-system.md` are verified
- Acceleration/deceleration formulas unit tests pass
- Collision response (BLOCKED state) verified
- ⚠️ HIGH RISK: Dual-focus tested on target engine (KB only, gamepad only, mouse only, both simultaneously)

## Next Step

Run `/create-stories driving` to break this epic into implementable stories.