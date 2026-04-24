# ADR-014: Facility System Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

设施系统使用 FacilityController 管理 storage box 和 workbench。storage_capacity=100 (TK-032)。workbench 有 4 MVP recipes。魔能连接距离 ≤10 cells (TK-047)。拆除返还 DEMOLITION_REFUND_RATE=0.5 (TK-048)。设施损坏时 contents 全部掉落，30秒有效期。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Feature (Facility, Storage, Crafting) |
| **Knowledge Risk** | LOW — No engine API dependency |
| **References Consulted** | `design/gdd/bunker-facility-system.md`, `design/registry/entities.yaml` (TK-032 to TK-048) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test storage capacity, crafting recipes, magic link distance |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (TileMap), ADR-002 (BuildItemDB, ResourceDB), ADR-009 (Magic), ADR-013 (Build), ADR-005 (Event Bus) |
| **Enables** | Bunker gameplay |
| **Blocks** | Facility gameplay until Accepted |
| **Ordering Note** | Feature layer — after Build System |

## Decision

**FacilityController with Storage and Workbench**：

```gdscript
class_name FacilityController extends Node2D

var facility_id: int
var facility_type: int  # BlockTypeDB ID (2000+ for facilities)
var state: FacilityState = FacilityState.NORMAL
var contents: Dictionary = {}  # {resource_id: count}
var magic_link_distance: float = 10.0  # TK-047

# Storage Box
const STORAGE_CAPACITY: int = 100  # TK-032

func deposit_item(resource_id: int, count: int) -> bool:
    if contents.size() >= STORAGE_CAPACITY:
        return false  # Full
    contents[resource_id] = contents.get(resource_id, 0) + count
    GlobalSignals.storage_changed.emit(facility_id, resource_id, contents[resource_id])
    return true

func withdraw_item(resource_id: int, count: int) -> bool:
    if contents.get(resource_id, 0) < count:
        return false  # Not enough
    contents[resource_id] -= count
    if contents[resource_id] <= 0:
        contents.erase(resource_id)
    GlobalSignals.storage_changed.emit(facility_id, resource_id, contents.get(resource_id, 0))
    return true

# Workbench Crafting
func craft_item(recipe_id: int) -> CraftResult:
    var recipe = get_recipe(recipe_id)
    if not _has_inputs(recipe.inputs):
        return CraftResult.failed("Missing inputs")
    if not _is_magic_connected():
        return CraftResult.failed("No magic power")
    _consume_inputs(recipe.inputs)
    craft_timer = recipe.craft_time
    # After timer completes:
    var output = recipe.output
    contents[output.resource_id] = contents.get(output.resource_id, 0) + output.count
    GlobalSignals.storage_changed.emit(facility_id, output.resource_id, contents[output.resource_id])
    return CraftResult.success(output)

func _is_magic_connected() -> bool:
    var vehicle_pos = VehicleController.position
    var facility_grid = position / TileMapWorld.CELL_SIZE
    var vehicle_grid = vehicle_pos / TileMapWorld.CELL_SIZE
    return facility_grid.distance_to(vehicle_grid) <= magic_link_distance

# Demolition
func demolish() -> void:
    var refund_rate = 0.5  # TK-048 DEMOLITION_REFUND_RATE
    var build_cost = BuildItemDB.get_build_cost(facility_type)
    for resource_id in build_cost:
        var refund = int(build_cost[resource_id] * refund_rate)
        DropManager.spawn_drop(position, resource_id, refund)
    # Drop all contents
    for resource_id in contents:
        DropManager.spawn_drop(position, resource_id, contents[resource_id])
    TileMapWorld.set_cell_at_position(grid_position, 0, LayerType.STRUCTURES)
    GlobalSignals.facility_demolished.emit(facility_id)
```

## GDD Requirements Addressed

| GDD | Requirement | How Satisfied |
|-----|-------------|---------------|
| `bunker-facility-system.md` | STORAGE_CAPACITY = 100 | TK-032 constant |
| `bunker-facility-system.md` | Magic link distance ≤10 cells | TK-047, _is_magic_connected() |
| `bunker-facility-system.md` | DEMOLITION_REFUND_RATE = 0.5 | TK-048, demolish() returns 50% |
| `bunker-facility-system.md` | Workbench 4 MVP recipes | craft_item() with recipe lookup |

## Related

- ADR-009: Magic — magic_link_distance check
- ADR-013: Build — FacilityController uses BuildItemDB
- ADR-015: Drop — DropManager.spawn_drop() on demolition