# Epic: Build Item Database

> **Layer**: Foundation
> **GDD**: design/gdd/build-item-database.md
> **Architecture Module**: BuildItemDB
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

BuildItemDB 是建造物品定义的静态数据库，存储配方成本公式（total_cost = base_cost * quantity）、地形支持条件、放置规则。MVP定义12个建造物品覆盖墙体/炮塔/陷阱/设施/地板五大分类。PlaceController和BuildValidator查询建造属性通过此模块。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Build Item Definition Loading | Integration | Ready | ADR-002 |

BuildItemDB 是建造物品定义的静态数据库，存储配方成本公式（total_cost = base_cost * quantity）、地形支持条件、放置规则。MVP定义12个建造物品覆盖墙体/炮塔/陷阱/设施/地板五大分类。PlaceController和BuildValidator查询建造属性通过此模块。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-002: Database Loading Strategy | RefCounted Autoload from entities.yaml | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-builditem-001 | Build item cost formula: total_cost = base_cost * quantity | ADR-002 ✅ |
| TR-builditem-002 | Build item placement rules: terrain_support_required check | ADR-002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/build-item-database.md` are verified
- get_build_cost(), check_terrain_support() unit tests pass
- 12 MVP build items defined and queryable

## Next Step

Run `/create-stories build-item-database` to break this epic into implementable stories.