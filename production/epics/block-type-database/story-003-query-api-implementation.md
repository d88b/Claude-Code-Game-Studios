# Story 003: Query API Implementation

> **Epic**: BlockTypeDB
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/block-type-database.md`
**Requirement**: `TR-blocktype-001`, `TR-blocktype-002`, `TR-blocktype-003`
*(Query API for collision profile, dig difficulty, resource drops)*

**ADR Governing Implementation**: ADR-002: Database Loading Strategy
**ADR Decision Summary**: Public query API: get_tile_data(), get_hardness(), get_collision_shape(), O(1) Dictionary lookup.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript, no engine-specific API for query logic.

**Control Manifest Rules (this layer)**:
- Required: O(1) lookup via Dictionary
- Performance: Single query latency <0.1ms

---

## Acceptance Criteria

*From GDD `design/gdd/block-type-database.md`, Query API Criteria:*

- [ ] `get_tile_data(tile_id: int)` returns BlockDefinition for valid ID, null for invalid
- [ ] `get_hardness(tile_id: int)` returns hardness value (int), 255 override for indestructible
- [ ] `get_collision_shape(tile_id: int)` returns collision shape (0=NONE, 1=FULL, 2=PLATFORM)
- [ ] `get_resource_type_id(tile_id: int)` returns resource type ID for drop
- [ ] `get_resource_multiplier(tile_id: int)` returns drop multiplier (float)
- [ ] `is_buildable(tile_id: int)` returns true if buildability=1
- [ ] `can_place_on_layer(tile_id: int, layer: int)` returns true if layer in layer_allowed
- [ ] `get_tiles_by_category(category: String)` returns list of tile IDs in category range
- [ ] `get_buildable_tiles()` returns list of all buildability=1 tiles
- [ ] Invalid ID (450) returns null, no exception
- [ ] Hardness override for destructibility=0 tiles (returns 255)

---

## Implementation Notes

*Derived from ADR-002:*

```gdscript
class_name BlockTypeDB extends RefCounted

func get_tile_data(tile_id: int) -> BlockDefinition:
    if not _tile_data_cache.has(tile_id):
        return null
    return _tile_data_cache[tile_id]

func get_hardness(tile_id: int) -> int:
    var data = get_tile_data(tile_id)
    if data == null:
        return 255  # Indestructible by default
    if data.destructibility == 0:
        return 255  # Override for indestructible tiles
    return data.hardness

func get_collision_shape(tile_id: int) -> int:
    var data = get_tile_data(tile_id)
    if data == null:
        return 0  # No collision for invalid
    return data.collision_shape

func is_buildable(tile_id: int) -> bool:
    var data = get_tile_data(tile_id)
    return data != null and data.buildability == 1

func can_place_on_layer(tile_id: int, layer: int) -> bool:
    var data = get_tile_data(tile_id)
    return data != null and layer in data.layer_allowed
```

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 001: TileSet loading
- Story 002: Custom data mapping
- Story 004: Integration with TileMapWorld, CollisionManager

---

## QA Test Cases

*For Logic stories — automated test specs:*

- **AC-1**: Valid ID query
  - Given: tile_id = 100 (valid terrain tile)
  - When: get_tile_data(100) called
  - Then: returns BlockDefinition with correct hardness=60, destructibility=1
  - Edge cases: Test multiple valid IDs across ranges (terrain, ore, building)

- **AC-2**: Invalid ID query
  - Given: tile_id = 450 (invalid, not in allocation)
  - When: get_tile_data(450) called
  - Then: returns null, no exception thrown
  - Edge cases: Test negative ID, ID > 65535

- **AC-3**: Hardness override for indestructible
  - Given: tile_id = 1 (bedrock, destructibility=0)
  - When: get_hardness(1) called
  - Then: returns 255 (override), not stored hardness value
  - Edge cases: Test destructibility=1 tile (returns stored hardness)

- **AC-4**: Collision shape query
  - Given: tile_id = 1510 (platform, collision_shape=2)
  - When: get_collision_shape(1510) called
  - Then: returns 2 (PLATFORM)
  - Edge cases: Test solid tile (1), passable tile (0)

- **AC-5**: Buildability query
  - Given: tile_id = 100 (terrain, buildability=0)
  - When: is_buildable(100) called
  - Then: returns false
  - Edge cases: Test tile_id = 1000 (building, buildability=1) → true

- **AC-6**: Layer validation
  - Given: tile_id = 100 (terrain), layer = 2 (structure layer)
  - When: can_place_on_layer(100, 2) called
  - Then: returns false (terrain cannot be on layer 2)
  - Edge cases: Test layer = 1 (terrain layer) → true

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/blocktype/query_api_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 002
- Unlocks: Story 004 (Integration), TileMapWorld (uses query API)