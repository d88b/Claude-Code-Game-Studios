# Story 001: Vehicle Definition Loading

> **Epic**: VehicleTypeDB
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/vehicle-type-database.md`
**Requirement**: `TR-vehicletype-001`, `TR-vehicletype-002`

**ADR Governing Implementation**: ADR-002: Database Loading Strategy, ADR-007: Vehicle State Machine
**ADR Decision Summary**: VehicleTypeDB 存储 base stats 和 state machine 定义（5-state）。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Vehicle definitions loaded from entities.yaml
- [ ] get_vehicle_stats(vehicle_id) returns VehicleStats (max_health/armor/magic_pool/max_speed/acceleration_rate)
- [ ] State machine: GARAGE_IDLE → DEPLOYABLE → DEPLOYED → DISABLED → DESTROYED
- [ ] DISABLED threshold: health < 20%
- [ ] DESTROYED threshold: health <= 0

---

## Implementation Notes

```gdscript
class_name VehicleTypeDB extends RefCounted

class VehicleStats:
    var vehicle_id: int
    var max_health: float
    var armor: float
    var magic_pool: float
    var max_speed: float
    var acceleration_rate: float

enum VehicleState { GARAGE_IDLE, DEPLOYABLE, DEPLOYED, DISABLED, DESTROYED }

func get_vehicle_stats(vehicle_id: int) -> VehicleStats:
    return _vehicles.get(vehicle_id, null)
```

---

## QA Test Cases

- **AC-1**: Vehicle stats query
  - Given: vehicle_id = 1 (default vehicle)
  - When: get_vehicle_stats(1) called
  - Then: returns VehicleStats with all 5 attributes
- **AC-2**: State machine validation
  - Given: state transitions defined
  - When: transition logic tested
  - Then: GARAGE_IDLE → DEPLOYABLE → DEPLOYED → DISABLED → DESTROYED valid

---

## Test Evidence

**Type**: Integration
**Required**: `tests/unit/vehicletype/vehicle_loading_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation layer)
- Unlocks: VehicleAttributeSystem, VehicleController