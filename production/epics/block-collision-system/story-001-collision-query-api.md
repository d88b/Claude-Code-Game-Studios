# Story 001: Collision Query API

> **Epic**: BlockCollisionSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/block-collision-system.md`
**Requirement**: `TR-collision-001`

**ADR Governing Implementation**: ADR-006: Collision Architecture
**ADR Decision Summary**: CollisionManager 提供 is_cell_solid, raycast_tile_collision, check_swept_collision 查询接口。

**Engine**: Godot 4.6 | **Risk**: LOW

**Control Manifest Rules (this layer)**:
- Required: Swept collision via DDA traversal
- Required: MAX_SWEPT_STEPS = 64

---

## Acceptance Criteria

- [ ] is_cell_solid(grid_pos) returns bool (layer collision check)
- [ ] raycast_tile_collision(from, to) returns collision point and normal
- [ ] check_swept_collision(body_rect, velocity) uses DDA traversal
- [ ] MAX_SWEPT_STEPS = 64 maximum traversal steps
- [ ] Prevent tunneling at high velocities

---

## Implementation Notes

```gdscript
class_name CollisionManager extends Node

const MAX_SWEPT_STEPS: int = 64

func is_cell_solid(grid_pos: Vector2i) -> bool:
    var block_id = TileMapWorld.get_cell_at_position(grid_pos)
    return BlockTypeDB.get_collision_shape(block_id) == CollisionShape.FULL

func check_swept_collision(body_rect: Rect2, velocity: Vector2) -> Dictionary:
    # DDA raycast traversal
    # Returns {collision_point, normal, time_of_impact}
```

---

## QA Test Cases

- **AC-1**: Solid cell detection
  - Given: grid_pos with terrain tile (collision_shape=FULL)
  - When: is_cell_solid(grid_pos) called
  - Then: returns true

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/collision/collision_query_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: TileMapWorld (Story 001-002), BlockTypeDB (Story 003)
- Unlocks: VehicleController, EnemyAIController