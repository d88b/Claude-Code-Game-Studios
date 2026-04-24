# Story 001: TileSet Resource Loading

> **Epic**: BlockTypeDB
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/block-type-database.md`
**Requirement**: `TR-blocktype-001` (partial)
*(Block collision profiles from TileSet resource)*

**ADR Governing Implementation**: ADR-002: Database Loading Strategy
**ADR Decision Summary**: BlockTypeDB 是 RefCounted Autoload，从 entities.yaml 加载 TileSet 资源，O(1) Dictionary lookup。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: TileSet and TileData APIs stable since Godot 3.x. TileSet resource loaded via ResourceLoader.

**Control Manifest Rules (this layer)**:
- Required: All static data from entities.yaml
- Required: Database pattern: RefCounted Autoload
- Required: O(1) lookup via Dictionary
- Forbidden: Never hardcode game values
- Performance: Database load <100ms startup

---

## Acceptance Criteria

*From GDD `design/gdd/block-type-database.md`, Data Integrity Criteria:*

- [ ] TileSet resource loads successfully on BlockTypes._ready() (no error logs)
- [ ] tile_count >= 25 (MVP catalog minimum)
- [ ] Tile type IDs are unique (no duplicate atlas indices)
- [ ] ID allocation matches scheme: terrain tiles 0-399, ores 500-999, buildings 1000-2999
- [ ] ID=0 returns NULL_TILE_DEFINITION (hardness=255, destructibility=0)
- [ ] TileSet resource load time <500ms on startup

---

## Implementation Notes

*Derived from ADR-002:*

```gdscript
class_name BlockTypeDB extends RefCounted

var _tile_set: TileSet
var _tile_data_cache: Dictionary = {}  # {tile_id: TileData}

func _init() -> void:
    _tile_set = ResourceLoader.load("res://data/block_types.tres")
    _build_cache()

func _build_cache() -> void:
    for source_id in _tile_set.get_source_count():
        var source = _tile_set.get_source(source_id)
        # Build dictionary cache for O(1) lookup
        # Map tile_type_id to TileData custom_data
```

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 002: Custom data field mapping (hardness, destructibility, etc.)
- Story 003: Query API (get_tile_data, get_hardness, etc.)
- entities.yaml: Source data file (external to this story)

---

## QA Test Cases

*For Integration stories — automated test specs:*

- **AC-1**: TileSet resource loading
  - Given: BlockTypeDB Autoload initialized
  - When: _ready() completes
  - Then: _tile_set != null, no error logs
  - Edge cases: Test missing TileSet file (error handling)

- **AC-2**: Tile count validation
  - Given: TileSet loaded
  - When: _tile_set.get_source_count() called
  - Then: count >= 25
  - Edge cases: Test empty TileSet (count = 0)

- **AC-3**: Unique tile IDs
  - Given: TileSet loaded
  - When: all atlas indices enumerated
  - Then: no duplicate indices found
  - Edge cases: Test TileSet with intentional duplicate (detect and error)

- **AC-4**: ID allocation scheme
  - Given: TileSet loaded with terrain/ore/building tiles
  - When: tile IDs checked
  - Then: terrain in 0-399, ores in 500-999, buildings in 1000-2999
  - Edge cases: Test ID outside allocation (should be invalid)

- **AC-5**: NULL_TILE definition
  - Given: query for tile_id = 0
  - When: get_tile_data(0) called
  - Then: returns NULL_TILE_DEFINITION (hardness=255, destructibility=0)
  - Edge cases: Test ID=0 collision behavior

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/unit/blocktype/tileset_loading_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation layer, first story)
- Unlocks: Story 002, Story 003, Story 004, Story 005, Story 006