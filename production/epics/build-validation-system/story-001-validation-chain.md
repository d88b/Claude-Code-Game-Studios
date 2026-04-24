# Story 001: Validation Chain V1-V6

> **Epic**: BuildValidationSystem
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/build-validation-system.md`
**Requirement**: `TR-buildvalid-001`, `TR-buildvalid-002`

**ADR Governing Implementation**: ADR-005: Event Bus
**ADR Decision Summary**: BuildValidator 执行 V1-V6 validation chain，检查 terrain_support 和 entity_collision。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [x] V1: World bounds check — cell within [-1000, 1000] range (MAX_WORLD_BOUNDS)
- [x] V2: Layer occupancy check — no existing tile at target cell on Layer 2 (structures)
- [x] V3: Placement range check — distance <= 5 cells from player (MAX_PLACE_RANGE)
- [x] V4: Tile buildability check — block is constructible (BuildItemDB.is_buildable)
- [x] V5: Category-specific rules — wall requires adjacent support, turret/trap/facility requires floor foundation
- [x] V6: Material sufficiency check — player inventory has required resources
- [x] ValidationResult class with passed, failure_code, failure_message
- [x] validate_placement() executes V1→V6 chain with early exit on failure

---

## Implementation Notes

```gdscript
class_name BuildValidator extends Node

func validate_placement(item_id: int, grid_pos: Vector2i, layer: int) -> ValidationResult:
    # V1: Terrain support
    var terrain = TileMapWorld.get_cell_at_position(grid_pos, LayerType.TERRAIN_BASE)
    if not BuildItemDB.check_terrain_support(item_id, terrain):
        return ValidationResult.fail("V1_TERRAIN_UNSUPPORTED")
    
    # V2: Entity collision
    if TileMapWorld.get_cell_at_position(grid_pos, layer) != 0:
        return ValidationResult.fail("V2_ENTITY_COLLISION")
    
    # V3-V6: Additional checks...
    return ValidationResult.success()
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/placing/placement_validation_test.gd`
**Status**: [x] Created — 60+ test cases covering V1-V6, ValidationResult, PlaceController integration, GlobalSignals
**Note**: Tests must be run in Godot Editor GUT panel (headless mode class_name loading issue)
**Implementation**: BuildValidator implements V1→V6 chain with early exit, PlaceController orchestrates flow

---

## Dependencies

- Depends on: TileMapWorld, BuildItemDB, VehicleAttribute
- Unlocks: PlaceController (uses validation)