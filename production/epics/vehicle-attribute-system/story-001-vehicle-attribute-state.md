# Story 001: Vehicle Attribute State

> **Epic**: VehicleAttributeSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/vehicle-attribute-system.md`
**Requirement**: `TR-vehicleattr-001`, `TR-vehicleattr-002`

**ADR Governing Implementation**: ADR-007: Vehicle State Machine, ADR-002: Database Loading
**ADR Decision Summary**: VehicleAttribute 管理 health/magic_pool/cargo 状态，emit GlobalSignals。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Current health tracking (max_health from VehicleTypeDB)
- [ ] Current magic pool tracking (magic_pool from VehicleTypeDB)
- [ ] get_durability_ratio() returns health/max_health (0.0-1.0)
- [ ] get_magic_energy_ratio() returns magic_pool/max_magic_pool
- [ ] GlobalSignals.vehicle_damaged emitted on damage
- [ ] State transitions: DISABLED (health<20%), DESTROYED (health<=0)

---

## Implementation Notes

```gdscript
class_name VehicleAttribute extends Node

var current_health: float
var max_health: float
var current_magic: float
var max_magic: float

func get_durability_ratio() -> float:
    return current_health / max_health

func take_damage(amount: float) -> void:
    current_health -= amount
    GlobalSignals.vehicle_damaged.emit(amount)
    if current_health <= 0:
        GlobalSignals.vehicle_destroyed.emit(vehicle_id)
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/vehicleattr/vehicle_attribute_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: VehicleTypeDB, GlobalSignals
- Unlocks: VehicleController, DamageReceiver, RetreatJudge