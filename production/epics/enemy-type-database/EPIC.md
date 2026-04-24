# Epic: Enemy Type Database

> **Layer**: Foundation
> **GDD**: design/gdd/enemy-type-database.md
> **Architecture Module**: EnemyTypeDB
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

EnemyTypeDB 是敌人类型定义的静态数据库，存储属性（health/damage/armor/speed）、行为提示（8种behavior_hint: aggressive/defensive/swarm/wall_breaker/tracker/ambusher/retreat_early/boss）。EnemyAIController查询敌人属性通过此模块。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Enemy Definition Loading | Integration | Ready | ADR-002 |

EnemyTypeDB 是敌人类型定义的静态数据库，存储属性（health/damage/armor/speed）、行为提示（8种behavior_hint: aggressive/defensive/swarm/wall_breaker/tracker/ambusher/retreat_early/boss）。EnemyAIController查询敌人属性通过此模块。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-002: Database Loading Strategy | RefCounted Autoload from entities.yaml | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-enemytype-001 | Enemy stats definition: health, damage, armor, speed, behavior_hint | ADR-002 ✅ |
| TR-enemytype-002 | 8 behavior_hint types | ADR-002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/enemy-type-database.md` are verified
- get_enemy_stats(), get_behavior_hint() unit tests pass
- All 8 behavior_hint types defined

## Next Step

Run `/create-stories enemy-type-database` to break this epic into implementable stories.