# Epic: Block Placing System

> **Layer**: Core
> **GDD**: design/gdd/block-placing-system.md
> **Architecture Module**: PlaceController
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

方块放置系统是玩家建造行为的核心执行层。玩家选择建造物品、确认目标位置、系统验证放置条件、扣除材料、在TileMapLayer Layer 2写入方块实例、同步更新碰撞形状。它将建造物品数据库的配方数据转化为世界中实际存在的方块实体，将建造验证系统的规则检查转化为建造许可/拒绝的决策输出。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Placement Validation | Logic | Ready | ADR-009 |

方块放置系统是玩家建造行为的核心执行层。玩家选择建造物品、确认目标位置、系统验证放置条件、扣除材料、在TileMapLayer Layer 2写入方块实例、同步更新碰撞形状。它将建造物品数据库的配方数据转化为世界中实际存在的方块实体，将建造验证系统的规则检查转化为建造许可/拒绝的决策输出。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-009: Placing Architecture | Placement validation chain V1-V6, material consumption atomic operation | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-placing-001 | Block placement validation: BuildValidator.check_terrain_support required before placement | ADR-009 ✅ |
| TR-placing-002 | Block placement cost: consume from player cargo (VehicleAttribute.cargo_contents) | ADR-009 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/block-placing-system.md` are verified
- Validation chain (V1-V6) unit tests pass
- Material consumption atomic operation verified
- Category-specific placement rules verified (floor/wall/turret/trap/facility)

## Next Step

Run `/create-stories placing` to break this epic into implementable stories.