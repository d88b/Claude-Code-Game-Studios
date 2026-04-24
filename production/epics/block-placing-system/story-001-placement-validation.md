# Story 001: Placement Validation

> **Epic**: BlockPlacingSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/block-placing-system.md`
**Requirement**: `TR-placing-001`, `TR-placing-002`

**ADR Governing Implementation**: ADR-009: Placing Architecture
**ADR Decision Summary**: Placement validation chain V1-V6，material consumption atomic operation。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] BuildValidator.check_terrain_support(item_id, terrain_type) required
- [ ] V1-V6 validation chain: terrain_support, entity_collision, resource_cost, layer_allowed, buildability, adjacent_support
- [ ] Material consumption atomic: deduct from VehicleAttribute.cargo_contents
- [ ] GlobalSignals.block_placed emitted on success
- [ ] Category-specific rules: floor/wall/turret/trap/facility

---

## Implementation Notes

```gdscript
class_name PlaceController extends Node

func try_place(item_id: int, grid_pos: Vector2i) -> bool:
    # V1: Terrain support check
    if not BuildValidator.check_terrain_support(item_id, get_terrain_at(grid_pos)):
        return false
    
    # V2: Entity collision check
    if not BuildValidator.check_entity_collision(grid_pos):
        return false
    
    # V3: Resource cost check
    var cost = BuildItemDB.get_build_cost(item_id)
    if not VehicleAttribute.can_afford(cost):
        return false
    
    # V4-V6: Additional validations...
    
    # Atomic operation: deduct and place
    VehicleAttribute.consume_resources(cost)
    TileMapWorld.set_cell_at_position(grid_pos, item_id, LayerType.STRUCTURES)
    GlobalSignals.block_placed.emit(grid_pos, item_id)
    return true
```

---

## QA Test Cases

- **AC-1**: Terrain support validation
  - Given: item requires terrain_support = ["solid"]
  - When: placing on passable terrain
  - Then: validation fails, placement blocked

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/placing/placement_validation_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: BuildValidator, BuildItemDB, VehicleAttribute, TileMapWorld
- Unlocks: BunkerFacilitySystem