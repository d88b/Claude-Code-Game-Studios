# Epic: Resource Drop System

> **Layer**: Core
> **GDD**: design/gdd/resource-drop-system.md
> **Architecture Module**: DropController
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

资源掉落系统是方块破坏事件到资源实体生成的桥梁层。它监听方块挖掘系统发出的破坏事件，根据方块的resource_type_id和resource_multiplier属性，通过掉落公式计算产出数量，在世界中生成对应的资源实体。所有Pillar 2（搜打撤节奏）的探索收益决策都依赖此系统的产出稳定性。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Resource Drop Entity | Logic | Ready | ADR-002 |

资源掉落系统是方块破坏事件到资源实体生成的桥梁层。它监听方块挖掘系统发出的破坏事件，根据方块的resource_type_id和resource_multiplier属性，通过掉落公式计算产出数量，在世界中生成对应的资源实体。所有Pillar 2（搜打撤节奏）的探索收益决策都依赖此系统的产出稳定性。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-002: Database Loading Strategy | RefCounted Autoload from entities.yaml | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-drop-001 | Resource drop entity: lifetime (30s default), pickup_radius for collection | ADR-002 ✅ |
| TR-drop-002 | Drop spawn position: random offset from destroyed block position | ADR-002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/resource-drop-system.md` are verified
- Drop probability (rarity gate) unit tests pass
- Drop quantity formula verified
- Resource entity spawn and pickup verified

## Next Step

Run `/create-stories drop` to break this epic into implementable stories.