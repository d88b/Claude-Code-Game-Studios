# ADR-013: Build System Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

建造系统整合 DigController 和 PlaceController。挖掘使用 dig_progress 累积 damage，accumulated_damage >= block.difficulty → block destroyed。放置使用 BuildValidator.validate_placement() 检查 terrain support 和 entity collision。成本从 VehicleAttribute.cargo_contents 消耗。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Build (Dig, Place) |
| **Knowledge Risk** | LOW — No engine API dependency |
| **References Consulted** | `design/gdd/block-digging-system.md`, `design/gdd/block-placing-system.md`, `design/gdd/build-validation-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test dig progress, placement validation, cost deduction |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (TileMap), ADR-002 (BlockTypeDB, BuildItemDB), ADR-003 (Input), ADR-007 (Vehicle Attribute), ADR-005 (Event Bus) |
| **Enables** | Build gameplay |
| **Blocks** | Dig/Place gameplay until Accepted |
| **Ordering Note** | Feature layer — after Foundation and Core |

## Decision

**DigController + PlaceController + BuildValidator**：

```gdscript
# DigController
func _physics_process(delta: float) -> void:
    if InputManager.is_action_pressed(&"dig"):
        var target_pos = InputManager.get_mouse_grid_position()
        var block_id = TileMapWorld.get_cell_at_position(target_pos)
        if block_id <= 0:
            return  # No block
        var difficulty = BlockTypeDB.get_dig_difficulty(block_id)
        if difficulty < 0:
            return  # Undiggable
        dig_progress[target_pos] += delta * dig_power / difficulty
        if dig_progress[target_pos] >= difficulty:
            TileMapWorld.set_cell_at_position(target_pos, 0)  # Remove block
            DropManager.spawn_drops(target_pos, BlockTypeDB.get_resource_drops(block_id))
            GlobalSignals.block_dug.emit(target_pos, block_id)
            dig_progress.erase(target_pos)

# PlaceController
func confirm_placement(grid_pos: Vector2i, item_id: int) -> bool:
    var result = BuildValidator.validate_placement(grid_pos, item_id, self)
    if not result.valid:
        return false
    var cost = BuildItemDB.get_build_cost(item_id)
    if not _can_afford_cost(cost):
        return false
    _deduct_cost(cost)
    var block_id = BuildItemDB.get_block_id(item_id)
    TileMapWorld.set_cell_at_position(grid_pos, block_id, BuildItemDB.get_layer(item_id))
    GlobalSignals.block_placed.emit(grid_pos, block_id)
    return true

# BuildValidator
func validate_placement(grid_pos: Vector2i, item_id: int, placer: Node2D) -> ValidationResult:
    var terrain_type = TileMapWorld.get_cell_at_position(grid_pos, LayerType.TERRAIN_BASE)
    if not BuildItemDB.check_terrain_support(item_id, terrain_type):
        return ValidationResult.invalid("Terrain does not support this item")
    var entities = get_entities_at_position(grid_pos)
    if entities.size() > 0:
        return ValidationResult.invalid("Position occupied by entity")
    return ValidationResult.valid()
```

## GDD Requirements Addressed

| GDD | Requirement | How Satisfied |
|-----|-------------|---------------|
| `block-digging-system.md` | Dig progress: accumulated_damage >= difficulty | dig_progress dict + comparison |
| `block-placing-system.md` | Placement validation | BuildValidator.validate_placement() |
| `build-validation-system.md` | Terrain support check | BuildItemDB.check_terrain_support() |

## Related

- ADR-001: TileMap — TileMapWorld.set_cell_at_position()
- ADR-002: BlockTypeDB, BuildItemDB — difficulty, cost, terrain support
- ADR-015: Drop — DropManager.spawn_drops() on block destroyed