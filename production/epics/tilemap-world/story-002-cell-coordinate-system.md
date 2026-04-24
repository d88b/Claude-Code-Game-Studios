# Story 002: Cell Coordinate System

> **Epic**: TileMapWorld
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/tilemap-world-system.md`
**Requirement**: `TR-tilemap-004`
*(Cell coordinate system: grid_pos = world_pos / CELL_SIZE (32 pixels))*

**ADR Governing Implementation**: ADR-001: TileMap System Architecture
**ADR Decision Summary**: CELL_SIZE = 32 pixels，实现 world_to_cell() 和 cell_to_world_center() 转换函数。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: TileMapLayer API stable. Coordinate conversion is pure math, no engine-specific API needed.

**Control Manifest Rules (this layer)**:
- Required: Cell coordinate system: grid_pos = world_pos / CELL_SIZE (32)
- Required: Constants UPPER_SNAKE_CASE (CELL_SIZE, CHUNK_SIZE)

---

## Acceptance Criteria

*From GDD `design/gdd/tilemap-world-system.md`, Grid Structure Tests:*

- [ ] `world_to_cell(Vector2 world_pos)` returns `Vector2i(floor(world_pos.x / CELL_SIZE), floor(world_pos.y / CELL_SIZE))`
- [ ] `cell_to_world_center(Vector2i grid_pos)` returns `Vector2((grid_pos.x + 0.5) * CELL_SIZE, (grid_pos.y + 0.5) * CELL_SIZE)`
- [ ] World position `(100.5, 200.7)` converts to `Vector2i(3, 6)`
- [ ] Cell `Vector2i(10, 20)` center is `Vector2(336, 656)`
- [ ] Bounds edge `(32000, 32000)` clamped to `Vector2i(1000, 1000)`
- [ ] Negative position `(-64, -32)` returns `Vector2i(-2, -1)`
- [ ] CELL_SIZE constant = 32 (from entities.yaml)

---

## Implementation Notes

*Derived from ADR-001:*

```gdscript
const CELL_SIZE: int = 32  # From entities.yaml

func world_to_cell(world_pos: Vector2) -> Vector2i:
    return Vector2i(int(world_pos.x / CELL_SIZE), int(world_pos.y / CELL_SIZE))

func cell_to_world_center(grid_pos: Vector2i) -> Vector2:
    return Vector2((grid_pos.x + 0.5) * CELL_SIZE, (grid_pos.y + 0.5) * CELL_SIZE)
```

Edge case handling:
- Bounds clamping: if grid_pos exceeds MAX_CHUNK * CHUNK_SIZE, clamp to valid range
- Negative indices: supported for infinite world expansion

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 001: TileMapLayer node creation
- Story 003: Chunk loading (uses get_chunk_id_for_pos)
- Story 005: Tile damage (uses cell position for damage application)

---

## QA Test Cases

*For Logic stories — automated test specs:*

- **AC-1**: world_to_cell basic conversion
  - Given: world_pos = Vector2(100.5, 200.7)
  - When: world_to_cell(world_pos) called
  - Then: result = Vector2i(3, 6)
  - Edge cases: Test fractional positions, negative positions

- **AC-2**: cell_to_world_center conversion
  - Given: grid_pos = Vector2i(10, 20)
  - When: cell_to_world_center(grid_pos) called
  - Then: result = Vector2(336, 656)
  - Edge cases: Test grid_pos = Vector2i(0, 0), negative grid_pos

- **AC-3**: Bounds edge handling
  - Given: world_pos = Vector2(32000, 32000)
  - When: world_to_cell(world_pos) called with bounds check
  - Then: result clamped to Vector2i(1000, 1000) (MAX_WORLD_BOUNDS)
  - Edge cases: Test exactly at boundary, beyond boundary

- **AC-4**: Negative coordinate handling
  - Given: world_pos = Vector2(-64, -32)
  - When: world_to_cell(world_pos) called
  - Then: result = Vector2i(-2, -1)
  - Edge cases: Test negative world_pos, negative grid_pos to world conversion

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tilemap/cell_coordinate_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (TileMapLayer structure must exist)
- Unlocks: Story 003 (Chunk loading uses coordinate functions), Story 005 (Tile damage uses cell position)