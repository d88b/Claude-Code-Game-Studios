# Epic: Enemy Spawn System

> **Layer**: Core
> **GDD**: design/gdd/enemy-spawn-system.md
> **Architecture Module**: SpawnManager
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

敌人生成系统是管理敌人实例动态创建的核心系统。根据尸潮配置（enemy_id列表、数量、位置范围）调用EnemyTypeDatabase读取敌人定义，在TileMapWorld指定位置创建敌人CharacterBody2D实例，初始化EnemyAI组件，并向下游系统暴露敌人列表供目标查询。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Spawn Wave Timing | Logic | Ready | ADR-002, ADR-005 |

敌人生成系统是管理敌人实例动态创建的核心系统。根据尸潮配置（enemy_id列表、数量、位置范围）调用EnemyTypeDatabase读取敌人定义，在TileMapWorld指定位置创建敌人CharacterBody2D实例，初始化EnemyAI组件，并向下游系统暴露敌人列表供目标查询。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-002: Database Loading Strategy | RefCounted Autoload from entities.yaml | LOW |
| ADR-005: Event Bus Architecture | GlobalSignals.enemy_spawned, enemy_despawned | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-spawn-001 | Spawn wave timing: spawn_interval per area (night triggers spawn waves) | ADR-005 ✅ |
| TR-spawn-002 | Spawn position validation: within area bounds, not overlapping existing entities | ADR-002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/enemy-spawn-system.md` are verified
- Spawn wave timing unit tests pass
- Position validation verified
- Enemy instantiation verified
- active_enemy_list management verified

## Next Step

Run `/create-stories spawn` to break this epic into implementable stories.