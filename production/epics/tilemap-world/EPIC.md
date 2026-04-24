# Epic: TileMap World System

> **Layer**: Foundation
> **GDD**: design/gdd/tilemap-world-system.md
> **Architecture Module**: TileMapWorld
> **Status**: Ready
> **Stories**: 6 stories created — see Stories table below

## Overview

TileMapWorld 是世界地图的核心管理器，负责5层TileMapLayer结构（background/terrain_base/structures/platforms/overlay）、chunk-based动态加载（32x32 cells per chunk）、方块坐标系统（grid_pos = world_pos / CELL_SIZE）、程序生成地形。所有空间操作依赖此模块提供方块位置查询和修改接口。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | TileMapLayer Node Structure | Integration | Ready | ADR-001 |
| 002 | Cell Coordinate System | Logic | Ready | ADR-001 |
| 003 | Chunk Loading System | Logic | Ready | ADR-001 |
| 004 | Procedural Terrain Generation | Logic | Ready | ADR-001 |
| 005 | Tile Damage State Machine | Logic | Ready | ADR-001, ADR-005 |
| 006 | Chunk Persistence | Integration | Ready | ADR-001 |

TileMapWorld 是世界地图的核心管理器，负责5层TileMapLayer结构（background/terrain_base/structures/platforms/overlay）、chunk-based动态加载（32x32 cells per chunk）、方块坐标系统（grid_pos = world_pos / CELL_SIZE）、程序生成地形。所有空间操作依赖此模块提供方块位置查询和修改接口。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-001: TileMap System Architecture | 5 TileMapLayer nodes, chunk loading, procedural generation | LOW (TileMapLayer stable 4.3+) |
| ADR-005: Event Bus Architecture | GlobalSignals for cell_changed, chunk_loaded | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-tilemap-001 | 5-layer structure: background/terrain_base/structures/platforms/overlay | ADR-001 ✅ |
| TR-tilemap-002 | Chunk-based loading: 32x32 cells per chunk | ADR-001 ✅ |
| TR-tilemap-003 | Procedural terrain generation with seed | ADR-001 ✅ |
| TR-tilemap-004 | Cell coordinate system: grid_pos = world_pos / CELL_SIZE (32) | ADR-001 ✅ |
| TR-tilemap-005 | Use TileMapLayer API (not deprecated TileMap) | ADR-001 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/tilemap-world-system.md` are verified
- All Logic stories have passing unit tests in `tests/unit/tilemap/`
- Chunk loading/unloading verified on target hardware (<50ms per chunk)
- Procedural generation produces consistent terrain with seed

## Next Step

Run `/create-stories tilemap-world` to break this epic into implementable stories.