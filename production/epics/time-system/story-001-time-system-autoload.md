# Story 001: Time System Autoload

> **Epic**: TimeSystem
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/time-system.md`
**Requirement**: `TR-time-001`, `TR-time-002`

**ADR Governing Implementation**: ADR-004: Time System Architecture, ADR-005: Event Bus
**ADR Decision Summary**: TimeSystem Autoload 管理 current_time, day_count, time_scale=60。10分钟 real time = 1 day cycle。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] TIME_SCALE = 60 (1 real second = 60 game seconds)
- [ ] 10 minutes real time = 1 day cycle (24 game hours)
- [ ] get_current_hour() returns 0-23
- [ ] get_phase() returns DAWN/DAY/DUSK/NIGHT
- [ ] Phase boundaries: DAWN(5h), DAY(7h), DUSK(17h), NIGHT(19h)
- [ ] GlobalSignals.time_hour_changed emitted on hour transition
- [ ] GlobalSignals.day_phase_changed emitted on phase transition

---

## Implementation Notes

```gdscript
class_name TimeSystem extends Node

const TIME_SCALE: float = 60.0  # 1 real second = 60 game seconds
const DAY_DURATION: float = 600.0  # 10 minutes real time

var current_time: float = 0.0  # Game seconds elapsed
var day_count: int = 0
var time_scale: float = TIME_SCALE

enum DayPhase { DAWN, DAY, DUSK, NIGHT }

func get_current_hour() -> int:
    return int(current_time / 3600.0) % 24

func get_phase() -> DayPhase:
    var hour = get_current_hour()
    if hour < 5: return DayPhase.NIGHT
    if hour < 7: return DayPhase.DAWN
    if hour < 17: return DayPhase.DAY
    if hour < 19: return DayPhase.DUSK
    return DayPhase.NIGHT
```

---

## QA Test Cases

- **AC-1**: Time scale validation
  - Given: 1 real second elapsed
  - When: _process(delta) called
  - Then: current_time += delta * TIME_SCALE = 60 game seconds

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/time/time_system_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: ADR-005 (GlobalSignals)
- Unlocks: DayNightCycle, SpawnManager, RetreatJudge