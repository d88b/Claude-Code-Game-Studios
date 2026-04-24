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

- [ ] V1: Terrain support check — block_type requires specific terrain layer type
- [ ] V2: Entity collision check — no overlap with existing entities at placement position
- [ ] V3: Resource cost check — player has sufficient resources
- [ ] V4: Layer allowed check — block can be placed on target layer
- [ ] V5: Buildability check — block is constructible (not natural terrain)
- [ ] V6: Adjacent support check — block has foundation (solid adjacent tile or below)
- [ ] GlobalSignals.validation_failed emitted on rejection

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
**Required**: `tests/unit/buildvalid/validation_chain_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: TileMapWorld, BuildItemDB, VehicleAttribute
- Unlocks: PlaceController (uses validation)