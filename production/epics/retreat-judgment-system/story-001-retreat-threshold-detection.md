# Story 001: Retreat Threshold Detection

> **Epic**: RetreatJudgmentSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/retreat-judgment-system.md`
**Requirement**: `TR-retreat-001`, `TR-retreat-002`

**ADR Governing Implementation**: ADR-004: Time System, ADR-005: Event Bus, ADR-007: Vehicle State Machine
**ADR Decision Summary**: RetreatJudge 监听 health/magic/time，emit GlobalSignals.retreat_threshold_reached。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Retreat threshold: health < 20% OR magic < 10% OR night_fall (TimeSystem.get_phase() == NIGHT)
- [ ] GlobalSignals.retreat_threshold_reached.emit(reason)
- [ ] GlobalSignals.retreat_warning_cleared.emit when conditions normalize
- [ ] Integration with DayNightCycle danger multiplier

---

## Implementation Notes

```gdscript
class_name RetreatJudge extends Node

func _process(delta: float) -> void:
    var health_ratio = VehicleAttribute.get_durability_ratio()
    var magic_ratio = VehicleAttribute.get_magic_ratio()
    var phase = TimeSystem.get_phase()
    
    if health_ratio < 0.2:
        GlobalSignals.retreat_threshold_reached.emit("health_critical")
    elif magic_ratio < 0.1:
        GlobalSignals.retreat_threshold_reached.emit("magic_depleted")
    elif phase == DayPhase.NIGHT:
        GlobalSignals.retreat_threshold_reached.emit("night_fall")
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/retreat/retreat_threshold_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: VehicleAttribute, TimeSystem, GlobalSignals
- Unlocks: UI Retreat Warning System