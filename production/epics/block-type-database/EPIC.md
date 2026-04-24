# Epic: Block Type Database

> **Layer**: Foundation
> **GDD**: design/gdd/block-type-database.md
> **Architecture Module**: BlockTypeDB
> **Status**: Ready
> **Stories**: 5 stories created — see Stories table below

## Overview

BlockTypeDB 是方块类型定义的静态数据库，存储碰撞属性（solid/passable/one-way）、挖掘难度公式、资源掉落表。所有系统查询方块属性通过此模块，确保数据驱动设计。RefCounted Autoload 从 entities.yaml 加载所有方块定义。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | TileSet Resource Loading | Integration | Ready | ADR-002 |
| 002 | Custom Data Field Mapping | Logic | Ready | ADR-002 |
| 003 | Query API Implementation | Logic | Ready | ADR-002 |
| 004 | Performance Optimization | Logic | Ready | ADR-002 |
| 005 | Edge Case Handling | Logic | Ready | ADR-002 |

BlockTypeDB 是方块类型定义的静态数据库，存储碰撞属性（solid/passable/one-way）、挖掘难度公式、资源掉落表。所有系统查询方块属性通过此模块，确保数据驱动设计。RefCounted Autoload 从 entities.yaml 加载所有方块定义。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-002: Database Loading Strategy | RefCounted Autoload from entities.yaml | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-blocktype-001 | Block collision profiles: solid/passable/one-way with friction | ADR-002 ✅ |
| TR-blocktype-002 | Block dig difficulty formula: time = base_difficulty * tool_modifier | ADR-002 ✅ |
| TR-blocktype-003 | Block resource drops: loot_table per block type | ADR-002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/block-type-database.md` are verified
- get_collision_profile(), get_dig_difficulty() unit tests pass
- All block IDs from entities.yaml loaded and queryable

## Next Step

Run `/create-stories block-type-database` to break this epic into implementable stories.