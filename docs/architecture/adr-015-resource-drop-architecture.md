# ADR-015: Resource Drop and Pickup Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

资源掉落使用 DropManager 管理 active_drops。每个 drop 是 ResourceDropEntity (Node2D)，有 lifetime=30s (TK-0XX)，pickup_radius。掉落位置随机 offset。pickup 时 emit GlobalSignals.item_collected，添加到 VehicleAttribute.cargo_contents。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Feature (Drop, Pickup) |
| **Knowledge Risk** | LOW — No engine API dependency |
| **References Consulted** | `design/gdd/resource-drop-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test drop lifetime, pickup radius, cargo addition |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-002 (ResourceDB), ADR-001 (TileMapWorld), ADR-007 (Vehicle Attribute), ADR-005 (Event Bus) |
| **Enables** | Resource economy gameplay |
| **Blocks** | Resource collection until Accepted |
| **Ordering Note** | Feature layer — after Foundation and Core |

## Decision

**DropManager with ResourceDropEntity**：

```gdscript
class_name DropManager extends Node

var active_drops: Array[ResourceDropEntity] = []
const DROP_LIFETIME: float = 30.0  # seconds
const PICKUP_RADIUS: float = 2.0  # cells

func spawn_drop(position: Vector2, resource_id: int, count: int) -> void:
    var offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * TileMapWorld.CELL_SIZE
    var drop = ResourceDropEntity.new()
    drop.position = position + offset
    drop.resource_id = resource_id
    drop.count = count
    drop.lifetime = DROP_LIFETIME
    active_drops.append(drop)
    add_child(drop)

func pickup_drop(drop: ResourceDropEntity) -> void:
    if not VehicleAttribute.can_add_to_cargo(drop.resource_id, drop.count):
        return  # Cargo full
    VehicleAttribute.add_to_cargo(drop.resource_id, drop.count)
    GlobalSignals.item_collected.emit(drop.resource_id, drop.count)
    active_drops.erase(drop)
    drop.queue_free()

func _process(delta: float) -> void:
    # Check lifetime expiration
    for drop in active_drops:
        drop.lifetime -= delta
        if drop.lifetime <= 0:
            active_drops.erase(drop)
            drop.queue_free()

    # Check pickup proximity
    var vehicle_pos = VehicleController.position
    for drop in active_drops:
        if drop.position.distance_to(vehicle_pos) < PICKUP_RADIUS * TileMapWorld.CELL_SIZE:
            pickup_drop(drop)
```

## GDD Requirements Addressed

| GDD | Requirement | How Satisfied |
|-----|-------------|---------------|
| `resource-drop-system.md` | Drop lifetime | DROP_LIFETIME = 30s |
| `resource-drop-system.md` | Pickup radius | PICKUP_RADIUS = 2 cells |
| `resource-drop-system.md` | Random spawn offset | offset = random Vector2 |

## Related

- ADR-002: ResourceDB — drop resource definition
- ADR-007: Vehicle Attribute — cargo_contents storage