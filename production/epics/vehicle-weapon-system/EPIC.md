# Epic: Vehicle Weapon System

> **Layer**: Core
> **GDD**: design/gdd/vehicle-weapon-system.md
> **Architecture Module**: WeaponController
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

战车武器系统是管理战车武器装备、射击行为、伤害输出的核心战斗系统。它定义武器类型属性（基础伤害、射击模式、魔能消耗、射程），管理战车实例的武器装备状态，处理玩家输入触发的射击流程（瞄准→判定→发射→伤害），并计算最终伤害输出。系统从战车属性系统获取魔能状态和载重信息，调用魔能消耗计算模块扣减射击成本，向敌人AI系统传递伤害事件。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Weapon Firing System | Logic | Ready | ADR-005 |

战车武器系统是管理战车武器装备、射击行为、伤害输出的核心战斗系统。它定义武器类型属性（基础伤害、射击模式、魔能消耗、射程），管理战车实例的武器装备状态，处理玩家输入触发的射击流程（瞄准→判定→发射→伤害），并计算最终伤害输出。系统从战车属性系统获取魔能状态和载重信息，调用魔能消耗计算模块扣减射击成本，向敌人AI系统传递伤害事件。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-005: Event Bus Architecture | GlobalSignals.weapon_fired, weapon_hit events | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-weapon-001 | Weapon cooldown timer per shot (prevent rapid fire) | ADR-005 ✅ |
| TR-weapon-002 | Projectile spawn at weapon muzzle position with direction vector | ADR-005 ✅ |
| TR-weapon-003 | Ammo consumption per shot from VehicleAttribute.cargo_contents | ADR-005 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/vehicle-weapon-system.md` are verified
- Damage calculation formula unit tests pass
- Projectile spawn and flight verified
- Weapon cooldown mechanism verified
- Magic consumption integration verified

## Next Step

Run `/create-stories weapon` to break this epic into implementable stories.