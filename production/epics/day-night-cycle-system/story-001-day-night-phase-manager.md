# Story 001: Day Night Phase Manager

> **Epic**: DayNightCycleSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/day-night-cycle-system.md`
**Requirement**: `TR-daynight-001`, `TR-daynight-002`

**ADR Governing Implementation**: ADR-004: Time System Architecture, ADR-005: Event Bus
**ADR Decision Summary**: 监听 time_phase_changed，触发视觉效果和危险倍率变化。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Phase definitions: DAWN, DAY, DUSK, NIGHT
- [ ] Danger multiplier: DAWN=0.8, DAY=1.0, DUSK=1.2, NIGHT=1.5
- [ ] Ambient lighting changes per phase (CanvasModulate.color)
- [ ] Overlay layer visibility for night effects
- [ ] GlobalSignals.day_phase_changed subscription

---

## Implementation Notes

```gdscript
class_name DayNightCycle extends Node

enum Phase { DAWN, DAY, DUSK, NIGHT }

const DANGER_MULTIPLIERS = {
    Phase.DAWN: 0.8,
    Phase.DAY: 1.0,
    Phase.DUSK: 1.2,
    Phase.NIGHT: 1.5
}

func get_danger_multiplier() -> float:
    return DANGER_MULTIPLIERS[TimeSystem.get_phase()]

func _ready() -> void:
    GlobalSignals.day_phase_changed.connect(_on_phase_changed)
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/daynight/day_night_cycle_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: TimeSystem, GlobalSignals
- Unlocks: SpawnManager, RetreatJudge