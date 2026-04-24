# Story 003: Chunk Loading System

> **Epic**: TileMapWorld
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/tilemap-world-system.md`
**Requirement**: `TR-tilemap-002`
*(Chunk-based loading: 32x32 cells per chunk)*

**ADR Governing Implementation**: ADR-001: TileMap System Architecture
**ADR Decision Summary**: CHUNK_SIZE = 32 cells，LOAD_RADIUS = 3 chunks around vehicle。ChunkManager 管理加载/卸载。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Chunk logic is pure GDScript, no engine-specific API. Performance target <50ms per chunk.

**Control Manifest Rules (this layer)**:
- Required: Chunk-based loading: 32x32 cells per chunk
- Required: LOAD_RADIUS = 3 chunks around vehicle
- Performance: TileMap chunk load <50ms per chunk

---

## Acceptance Criteria

*From GDD `design/gdd/tilemap-world-system.md`, Chunk Loading Tests:*

- [ ] `get_chunk_id_for_pos(Vector2i grid_pos)` returns `Vector2i(grid_pos.x / CHUNK_SIZE, grid_pos.y / CHUNK_SIZE)`
- [ ] `load_chunks_around(Vector2 world_pos)` loads chunks in LOAD_RADIUS (3) around center
- [ ] Player at chunk (5,5) loads chunks (2-8, 2-8) (3-radius = 7x7 chunks)
- [ ] Modified chunk serialization on unload (preserves player-built tiles)
- [ ] Unmodified chunk data discarded on unload (regenerated on next load)
- [ ] Unload timer: 30 seconds after entity exits 3-chunk radius
- [ ] Timer reset when entity re-enters radius during countdown
- [ ] CHUNK_SIZE constant = 32 cells
- [ ] LOAD_RADIUS constant = 3 chunks
- [ ] Chunk load performance <50ms per 32x32 chunk

---

## Implementation Notes

*Derived from ADR-001:*

```gdscript
const CHUNK_SIZE: int = 32  # From entities.yaml
const LOAD_RADIUS: int = 3  # Chunks around vehicle
const UNLOAD_DELAY: float = 30.0  # Seconds before unload

var loaded_chunks: Dictionary = {}  # {Vector2i: ChunkData}
var modified_cells: Dictionary = {}  # {Vector2i: block_id} — for persistence

class ChunkData:
    var chunk_id: Vector2i
    var is_loaded: bool
    var cells_terrain_base: Array[int]  # 32x32 = 1024 cells
    var cells_structures: Array[int]
    var has_modifications: bool

func get_chunk_id_for_pos(grid_pos: Vector2i) -> Vector2i:
    return Vector2i(grid_pos.x / CHUNK_SIZE, grid_pos.y / CHUNK_SIZE)

func load_chunks_around(center_world_pos: Vector2) -> void:
    var center_chunk = _world_pos_to_chunk_id(center_world_pos)
    for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
        for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
            var chunk_id = center_chunk + Vector2i(dx, dy)
            if not loaded_chunks.has(chunk_id):
                _load_chunk(chunk_id)
```

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 002: Coordinate conversion (world_to_cell, cell_to_world_center)
- Story 004: Procedural terrain generation (_generate_terrain content)
- Story 006: Chunk persistence (SaveManager integration)

---

## QA Test Cases

*For Logic stories — automated test specs:*

- **AC-1**: get_chunk_id_for_pos conversion
  - Given: grid_pos = Vector2i(100, 200)
  - When: get_chunk_id_for_pos(grid_pos) called
  - Then: result = Vector2i(3, 6) (100/32=3, 200/32=6)
  - Edge cases: Test at chunk boundaries (31, 32), negative grid_pos

- **AC-2**: load_chunks_around radius
  - Given: player at chunk (5, 5)
  - When: load_chunks_around(player_pos) called
  - Then: chunks (2-8, 2-8) loaded (7x7 = 49 chunks total)
  - Edge cases: Test at world origin (0,0), edge of world bounds

- **AC-3**: Modified chunk preservation
  - Given: chunk with has_modifications = true
  - When: chunk unload triggered
  - Then: chunk data serialized to modified_cells dict (not discarded)
  - Edge cases: Test with empty modification, multiple modifications

- **AC-4**: Unmodified chunk discard
  - Given: chunk with has_modifications = false
  - When: chunk unload triggered
  - Then: chunk data discarded, will regenerate on next load
  - Edge cases: Verify regeneration produces same terrain (seed consistency)

- **AC-5**: Unload timer behavior
  - Given: no entity within 3-chunk radius for 30 seconds
  - When: unload timer triggers
  - Then: chunks transition to UNLOADING then UNLOADED
  - Edge cases: Timer reset when entity re-enters, timer pause/resume

- **AC-6**: Performance target
  - Given: 32x32 chunk with procedural generation
  - When: chunk load executes
  - Then: load time <50ms on target hardware
  - Edge cases: Profile with worst-case terrain (all layers populated)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tilemap/chunk_loading_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (TileMapLayer structure), Story 002 (Coordinate conversion)
- Unlocks: Story 004 (Procedural generation called during load), Story 006 (Chunk persistence)