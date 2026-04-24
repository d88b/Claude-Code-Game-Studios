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

- [x] Area bounds: Rect2(center, size) defining explorable region (bunker, city, demon, element)
- [x] Area entry: vehicle.position crosses boundary → GlobalSignals.area_entered emitted
- [x] Area exit: vehicle.position leaves boundary → GlobalSignals.area_exited emitted
- [x] Danger level per area (1-5 scale) for RetreatJudge
- [x] Loot tier per area (1-4 scale) for loot pools
- [x] Enemy density formula: danger_level × ENEMY_BASE_DENSITY
- [x] Rare drop chance formula: BASE_RARE_DROP + loot_tier × RARE_DROP_INCREMENT
- [x] Area discovery: first entry sets discovered=true and emits area_discovered

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
**Status**: [x] Created — 65+ test cases covering constants, area definitions, formulas, position detection, transitions, discovery, signals
**Note**: Tests must be run in Godot Editor GUT panel (headless mode class_name loading issue)
**Implementation**: AreaManager with 4 MVP areas (bunker/city/demon/element), position tracking, formula implementations (F1/F2/F3)

---

## Dependencies

- Depends on: VehicleController, GlobalSignals
- Unlocks: SpawnManager, RetreatJudge