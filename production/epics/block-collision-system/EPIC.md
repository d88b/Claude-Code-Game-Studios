# Epic: Block Collision System

> **Layer**: Core
> **GDD**: design/gdd/block-collision-system.md
> **Architecture Module**: CollisionManager
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

方块碰撞系统是TileMap世界系统与物理世界的桥梁层。它将TileMap Layer 2（碰撞层）的collision_shape数据转换为Godot PhysicsBody2D可检测的碰撞形状，为战车、敌人、子弹等所有移动实体提供统一的碰撞检测接口。系统提供查询API（is_cell_solid, raycast_tile_collision, check_swept_collision）和碰撞事件信号（collision_added/removed, vehicle_collision）。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Collision Query API | Logic | Ready | ADR-006 |

方块碰撞系统是TileMap世界系统与物理世界的桥梁层。它将TileMap Layer 2（碰撞层）的collision_shape数据转换为Godot PhysicsBody2D可检测的碰撞形状，为战车、敌人、子弹等所有移动实体提供统一的碰撞检测接口。系统提供查询API（is_cell_solid, raycast_tile_collision, check_swept_collision）和碰撞事件信号（collision_added/removed, vehicle_collision）。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-006: Collision Architecture | CollisionManager wraps TileMap collision queries, swept collision with DDA traversal | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-collision-001 | Swept collision algorithm: DDA raycast traversal to prevent tunneling | ADR-006 ✅ |
| TR-collision-002 | MAX_SWEPT_STEPS = 64 (TK-018) — maximum traversal steps per frame | ADR-006 ✅ |
| TR-collision-003 | Severity formula: severity = velocity.magnitude * block_friction / SEVERITY_BASE (TK-019 = 100) | ADR-006 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/block-collision-system.md` are verified
- is_cell_solid(), raycast_tile_collision(), check_swept_collision() unit tests pass
- Collision signals (collision_added/removed, vehicle_collision) verified in integration test
- Swept collision tested with vehicle-sized bodies (64×64 px, 2×2 cells)

## Next Step

Run `/create-stories collision` to break this epic into implementable stories.