# Epic: Turret System

> **Layer**: Core
> **GDD**: design/gdd/turret-system.md
> **Architecture Module**: TurretController
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

炮塔系统是管理所有已建造炮塔实例的运行时实体系统。每个炮塔实例作为独立运行实体（TurretEntity），从建造物品数据库读取炮塔类型属性（攻击范围、射速、伤害、弹药类型），维护自身状态机（待机/瞄准/射击/冷却），执行目标搜索逻辑，触发射击事件生成弹道实体。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Turret Targeting | Logic | Ready | ADR-005 |

炮塔系统是管理所有已建造炮塔实例的运行时实体系统。每个炮塔实例作为独立运行实体（TurretEntity），从建造物品数据库读取炮塔类型属性（攻击范围、射速、伤害、弹药类型），维护自身状态机（待机/瞄准/射击/冷却），执行目标搜索逻辑，触发射击事件生成弹道实体。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-005: Event Bus Architecture | GlobalSignals.turret_fired, turret_hit, turret_kill | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-turret-001 | Turret state machine: IDLE → TARGETING → FIRING → COOLDOWN → DISABLED | ADR-005 ✅ |
| TR-turret-002 | Targeting: nearest enemy within detection_radius (EnemyAIController positions) | ADR-005 ✅ |
| TR-turret-003 | Ammo consumption from linked storage (FacilityController.contents) | ADR-005 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/turret-system.md` are verified
- State machine transitions unit tests pass
- Target acquisition algorithm verified
- Damage calculation verified
- Ammo consumption integration verified

## Next Step

Run `/create-stories turret` to break this epic into implementable stories.