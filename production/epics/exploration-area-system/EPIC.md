# Epic: Exploration Area System

> **Layer**: Core
> **GDD**: design/gdd/exploration-area-system.md
> **Architecture Module**: AreaManager
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

探索区域系统定义TileMap网格上的命名空间区域，将单元格组合成有意义的探索区域。每个区域携带危险等级、搜刮密度、阵营归属和环境主题的元数据。区域是玩家对地表世界的心理地图："废弃城市"意味着铁矿搜刮和丧尸巡逻；"恶魔荒原"意味着稀有晶石和恶魔伏击。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Area Bounds Manager | Logic | Ready | ADR-005 |

探索区域系统定义TileMap网格上的命名空间区域，将单元格组合成有意义的探索区域。每个区域携带危险等级、搜刮密度、阵营归属和环境主题的元数据。区域是玩家对地表世界的心理地图："废弃城市"意味着铁矿搜刮和丧尸巡逻；"恶魔荒原"意味着稀有晶石和恶魔伏击。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-005: Event Bus Architecture | GlobalSignals.area_entered, area_exited | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-area-001 | Area bounds definition: Rect2(center, size) defining explorable region | ADR-005 ✅ |
| TR-area-002 | Area entry detection: vehicle.position crosses area boundary triggers GlobalSignals.area_entered | ADR-005 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/exploration-area-system.md` are verified
- Area bounds containment check unit tests pass
- Area entry detection verified
- Danger level integration with RetreatJudge verified

## Next Step

Run `/create-stories area` to break this epic into implementable stories.