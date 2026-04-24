# ADR-016: Exploration Area Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

探索区域使用 AreaManager 管理 area_definitions。每个 area 有 bounds (Rect2)，spawn_points，difficulty_level。vehicle 进入 area 时 emit GlobalSignals.area_entered，触发 SpawnManager.spawn_wave。RetreatJudge 监控 area 内的撤退条件（health < 20%, magic < 10%, night fall）。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Feature (Area, Retreat) |
| **Knowledge Risk** | LOW — No engine API dependency |
| **References Consulted** | `design/gdd/exploration-area-system.md`, `design/gdd/retreat-judgment-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test area entry detection, retreat warning triggers |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (TileMap), ADR-004 (TimeSystem), ADR-007 (Vehicle Attribute), ADR-009 (Magic), ADR-005 (Event Bus) |
| **Enables** | Exploration gameplay |
| **Blocks** | Area-based gameplay until Accepted |
| **Ordering Note** | Feature layer — after Foundation and Core |

## Decision

**AreaManager + RetreatJudge**：

```gdscript
class_name AreaManager extends Node

var area_definitions: Dictionary = {}  # {area_id: AreaDefinition}
var current_area: int = 0
var visited_areas: Array[int] = []

func check_area_entry(vehicle_pos: Vector2) -> void:
    for area_id in area_definitions:
        var area = area_definitions[area_id]
        if area.bounds.has_point(vehicle_pos):
            if current_area != area_id:
                current_area = area_id
                if not visited_areas.has(area_id):
                    visited_areas.append(area_id)
                GlobalSignals.area_entered.emit(area_id)
                SpawnManager.spawn_wave(area_id, area.initial_wave)

class_name RetreatJudge extends Node

const HEALTH_THRESHOLD: float = 0.2   # 20%
const MAGIC_THRESHOLD: float = 0.1   # 10%

func _process(delta: float) -> void:
    var health_ratio = VehicleAttribute.current_health / VehicleAttribute.max_health
    var magic_ratio = MagicConsumption.current_pool / MagicConsumption.max_pool
    var phase = TimeSystem.get_phase()

    if health_ratio < HEALTH_THRESHOLD:
        GlobalSignals.retreat_threshold_reached.emit(RetreatReason.LOW_HEALTH)
    elif magic_ratio < MAGIC_THRESHOLD:
        GlobalSignals.retreat_threshold_reached.emit(RetreatReason.LOW_MAGIC)
    elif phase == DayPhase.NIGHT:
        GlobalSignals.retreat_threshold_reached.emit(RetreatReason.NIGHT_FALL)
```

## GDD Requirements Addressed

| GDD | Requirement | How Satisfied |
|-----|-------------|---------------|
| `exploration-area-system.md` | Area bounds definition | AreaDefinition.bounds = Rect2 |
| `exploration-area-system.md` | Area entry detection | check_area_entry() per frame |
| `retreat-judgment-system.md` | Health < 20% threshold | HEALTH_THRESHOLD = 0.2 |
| `retreat-judgment-system.md` | Magic < 10% threshold | MAGIC_THRESHOLD = 0.1 |
| `retreat-judgment-system.md` | Night fall warning | DayPhase.NIGHT triggers |

## Related

- ADR-004: TimeSystem — DayPhase.NIGHT detection
- ADR-012: Spawn — SpawnManager.spawn_wave on area entry
- ADR-007: Vehicle Attribute — health_ratio calculation
- ADR-009: Magic — magic_ratio calculation