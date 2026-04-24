# Story 001: Area Bounds Manager

> **Epic**: ExplorationAreaSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/exploration-area-system.md`
**Requirement**: `TR-area-001`, `TR-area-002`

**ADR Governing Implementation**: ADR-005: Event Bus Architecture
**ADR Decision Summary**: AreaManager 定义 Rect2 区域边界，emit area_entered/area_exited。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Area bounds: Rect2(center, size) defining explorable region
- [ ] Area entry: vehicle.position crosses boundary → GlobalSignals.area_entered
- [ ] Area exit: vehicle.position leaves boundary → GlobalSignals.area_exited
- [ ] Danger level per area (multiplier for RetreatJudge)
- [ ] Area definitions from entities.yaml

---

## Implementation Notes

```gdscript
class_name AreaManager extends Node

class AreaDefinition:
    var area_id: int
    var bounds: Rect2
    var danger_level: float
    var display_name: String

var current_area: AreaDefinition = null

func _process(delta: float) -> void:
    var vehicle_pos = VehicleController.position
    for area in area_definitions:
        if area.bounds.has_point(vehicle_pos):
            if current_area != area:
                current_area = area
                GlobalSignals.area_entered.emit(area.area_id)
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/area/area_bounds_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: VehicleController, GlobalSignals
- Unlocks: SpawnManager, RetreatJudge