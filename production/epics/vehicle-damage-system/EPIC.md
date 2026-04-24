# Epic: Vehicle Damage System

> **Layer**: Core
> **GDD**: design/gdd/vehicle-damage-system.md
> **Architecture Module**: DamageReceiver
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

战车损坏系统是管理战车耐久值消耗和损坏状态转换的核心系统。该系统接收来自敌人攻击、碰撞冲击的伤害事件，计算实际伤害（应用护甲减伤），扣除耐久值，并根据耐久阈值触发状态转换（DISABLED瘫痪）。系统连接敌人AI攻击输出与战车属性系统耐久输入，是战斗伤害传递的核心桥梁。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Damage Receiver System | Logic | Ready | ADR-007, ADR-005 |

战车损坏系统是管理战车耐久值消耗和损坏状态转换的核心系统。该系统接收来自敌人攻击、碰撞冲击的伤害事件，计算实际伤害（应用护甲减伤），扣除耐久值，并根据耐久阈值触发状态转换（DISABLED瘫痪）。系统连接敌人AI攻击输出与战车属性系统耐久输入，是战斗伤害传递的核心桥梁。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-007: Vehicle State Machine Architecture | DISABLED state trigger on health=0 | LOW |
| ADR-005: Event Bus Architecture | GlobalSignals.vehicle_damaged, durability_depleted | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-damage-001 | Damage calculation: effective_damage = incoming_damage - armor (min 0) | ADR-007 ✅ |
| TR-damage-002 | Damage state transitions: NORMAL → DAMAGED → DISABLED → DESTROYED based on health threshold | ADR-007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/vehicle-damage-system.md` are verified
- Armor reduction formula unit tests pass
- State transitions verified
- Damage received signal emission verified

## Next Step

Run `/create-stories damage` to break this epic into implementable stories.