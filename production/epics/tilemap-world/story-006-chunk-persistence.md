# Story 006: Chunk Persistence

> **Epic**: TileMapWorld
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/tilemap-world-system.md`
**Requirement**: Implicit (modified_cells tracking, chunk serialization)
*(Derived from Chunk Loading Tests: modified chunk serialization)*

**ADR Governing Implementation**: ADR-001: TileMap System Architecture
**ADR Decision Summary**: modified_cells Dictionary 记录所有修改的 cells 用于 save/load，Chunk 数据序列化到 disk。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: FileAccess API (Godot 4.4+ returns FileAccess, not File). Use JSON or binary serialization.

**Control Manifest Rules (this layer)**:
- Required: Modified cells tracking for persistence
- Required: modified_cells Dictionary persists changes for save/load
- Performance: Chunk serialization ≤32KB per 1024-cell chunk

---

## Acceptance Criteria

*From GDD `design/gdd/tilemap-world-system.md`, Chunk Loading Tests + Performance Tests:*

- [ ] `modified_cells: Dictionary` tracks all cell modifications {Vector2i: block_id}
- [ ] `set_cell_at_position()` updates modified_cells on successful placement
- [ ] Modified chunk data serialized to disk on unload (preserves player-built tiles)
- [ ] Unmodified chunk data discarded on unload (regenerated on next load)
- [ ] Chunk serialization file size ≤32KB per 1024-cell chunk
- [ ] SaveManager can restore modified_cells on game load
- [ ] GlobalSignals.game_saved/game_loaded integration

---

## Implementation Notes

*Derived from ADR-001:*

```gdscript
var modified_cells: Dictionary = {}  # {Vector2i: block_id} — for save/load

func set_cell_at_position(grid_pos: Vector2i, block_type_id: int, layer: LayerType) -> bool:
    # ... set_cell on TileMapLayer
    modified_cells[grid_pos] = block_type_id
    GlobalSignals.block_placed.emit(grid_pos, block_type_id)
    return true

func _serialize_chunk(chunk_id: Vector2i) -> Dictionary:
    var chunk_mods = {}
    for grid_pos in modified_cells:
        var cell_chunk = get_chunk_id_for_pos(grid_pos)
        if cell_chunk == chunk_id:
            chunk_mods[grid_pos] = modified_cells[grid_pos]
    return chunk_mods

func _save_chunk_to_disk(chunk_id: Vector2i, data: Dictionary) -> void:
    # Use FileAccess (Godot 4.4+ API)
    var file = FileAccess.open("user://chunks/chunk_%d_%d.json" % [chunk_id.x, chunk_id.y], FileAccess.WRITE)
    file.store_string(JSON.stringify(data))
```

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 003: Chunk loading/unloading logic
- Story 005: Tile damage (updates modified_cells on destruction)
- SaveManager: Full save/load system (separate epic)

---

## QA Test Cases

*For Integration stories — automated test specs:*

- **AC-1**: modified_cells tracking
  - Given: set_cell_at_position called with grid_pos = Vector2i(10, 20), block_id = 5
  - When: operation succeeds
  - Then: modified_cells[Vector2i(10, 20)] = 5
  - Edge cases: Test overwrite existing modification, empty block_id

- **AC-2**: Chunk serialization
  - Given: chunk with has_modifications = true, 10 modified cells
  - When: _serialize_chunk(chunk_id) called
  - Then: returns Dictionary with 10 entries
  - Edge cases: Test empty modifications, 1024 modifications (max per chunk)

- **AC-3**: File size budget
  - Given: chunk with 1024 modified cells
  - When: serialized to JSON file
  - Then: file size ≤32KB
  - Edge cases: Test binary serialization (smaller size), worst-case modification count

- **AC-4**: SaveManager integration
  - Given: modified_cells populated with player modifications
  - When: game saved and reloaded
  - Then: modified_cells restored correctly
  - Edge cases: Test empty modifications, modifications across multiple chunks

- **AC-5**: GlobalSignals integration
  - Given: SaveManager calls chunk persistence
  - When: save/load completes
  - Then: GlobalSignals.game_saved/game_loaded emitted
  - Edge cases: Verify signal timing (emit after persistence complete)

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/tilemap/chunk_persistence_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 003 (Chunk loading/unloading), Story 005 (Tile damage updates modified_cells)
- Unlocks: SaveManager (can serialize/deserialize world state)