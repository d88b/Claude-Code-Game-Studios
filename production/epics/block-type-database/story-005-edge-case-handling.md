# Story 005: Edge Case Handling

> **Epic**: BlockTypeDB
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/block-type-database.md`
**Requirement**: Edge case handling
*(Negative ID, ID > 65535, deprecated tiles, PLANNED tiles, empty variants)*

**ADR Governing Implementation**: ADR-002: Database Loading Strategy
**ADR Decision Summary**: Invalid IDs return null gracefully, no exceptions. Edge cases logged as warnings.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript validation logic.

**Control Manifest Rules (this layer)**:
- Required: O(1) lookup via Dictionary
- Forbidden: Never hardcode game values

---

## Acceptance Criteria

*From GDD `design/gdd/block-type-database.md`, Edge Case Handling Criteria:*

- [ ] Negative ID (-1) returns null, no crash
- [ ] ID > 65535 (70000) returns null, no crash
- [ ] PLANNED tile (status=PLANNED) returns null with warning log
- [ ] Deprecated tile returns valid BlockDefinition (runtime behavior unchanged)
- [ ] Empty variants array returns variant 0 (default), no error
- [ ] All variants weight=0 returns variant 0 with warning log
- [ ] Invalid query does not throw exception, returns null/false

---

## Implementation Notes

*Derived from ADR-002:*

```gdscript
func get_tile_data(tile_id: int) -> BlockDefinition:
    # Validation bounds
    if tile_id < 0:
        return null
    if tile_id > 65535:
        return null
    
    if not _tile_data_cache.has(tile_id):
        return null
    
    var data = _tile_data_cache[tile_id]
    
    # PLANNED tiles not available at runtime
    if data.status == "PLANNED":
        push_warning("Query for PLANNED tile_id=%d" % tile_id)
        return null
    
    return data

func get_random_variant(tile_id: int) -> int:
    var data = get_tile_data(tile_id)
    if data == null or data.variants.is_empty():
        return 0  # Default variant
    
    # Handle all weight=0 case
    var total_weight = 0
    for v in data.variants:
        total_weight += v.weight
    if total_weight == 0:
        push_warning("All variants have weight=0 for tile_id=%d" % tile_id)
        return 0
    
    # Weighted random selection
    # ... selection logic
```

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 003: Valid query API
- entities.yaml: PLANNED/deprecated status in source data

---

## QA Test Cases

*For Logic stories — automated test specs:*

- **AC-1**: Negative ID handling
  - Given: tile_id = -1
  - When: get_tile_data(-1) called
  - Then: returns null, no crash, no exception
  - Edge cases: Test -100, -65535

- **AC-2**: ID overflow handling
  - Given: tile_id = 70000 (>65535)
  - When: get_tile_data(70000) called
  - Then: returns null, no crash
  - Edge cases: Test ID = 65536 (boundary)

- **AC-3**: PLANNED tile handling
  - Given: tile_id = 400 (PLANNED status in registry)
  - When: get_tile_data(400) called
  - Then: returns null, warning logged
  - Edge cases: Test PLANNED tile in valid ID range

- **AC-4**: Deprecated tile behavior
  - Given: tile_id = 1000 (marked deprecated in metadata)
  - When: get_tile_data(1000) called
  - Then: returns valid BlockDefinition (runtime unchanged)
  - Edge cases: Verify buildability query still works

- **AC-5**: Empty variants handling
  - Given: tile with variants = []
  - When: get_random_variant(tile_id) called
  - Then: returns 0 (default variant), no error
  - Edge cases: Test tile with single variant

- **AC-6**: All weight=0 handling
  - Given: tile with variants but all weight=0
  - When: get_random_variant(tile_id) called
  - Then: returns 0 (fallback), warning logged
  - Edge cases: Test mixed weights (some 0, some positive)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/blocktype/edge_case_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 003
- Unlocks: None (standalone validation)