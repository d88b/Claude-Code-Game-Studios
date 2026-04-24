# Story 001: Damage Receiver System

> **Epic**: VehicleDamageSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/vehicle-damage-system.md`
**Requirement**: `TR-damage-001`, `TR-damage-002`

**ADR Governing Implementation**: ADR-007: Vehicle State Machine, ADR-005: Event Bus
**ADR Decision Summary**: DamageReceiver 接收 damage，计算 effective_damage，emit GlobalSignals.vehicle_damaged。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [x] Damage formula: effective_damage = raw_damage * (1 - armor_factor) with armor_factor clamped to 0.80 — test_calculate_actual_damage_*
- [x] GlobalSignals.vehicle_damaged emitted on damage — test_receive_damage_emits_global_vehicle_damaged
- [x] State transition: DISABLED when health < 20% — test_damage_triggers_disabled_state
- [x] State transition: DESTROYED when health <= 0 — test_damage_triggers_destroyed_state
- [x] GlobalSignals.vehicle_destroyed emitted on death — test_damage_triggers_global_vehicle_destroyed

---

## Implementation Notes

```gdscript
class_name DamageReceiver extends Node

func take_damage(incoming: float) -> void:
    var armor = VehicleTypeDB.get_vehicle_stats(vehicle_id).armor
    var effective = max(0, incoming - armor)
    
    VehicleAttribute.current_health -= effective
    GlobalSignals.vehicle_damaged.emit(effective)
    
    if VehicleAttribute.get_durability_ratio() < 0.2:
        VehicleState.transition_to(VehicleState.DISABLED)
    
    if VehicleAttribute.current_health <= 0:
        VehicleState.transition_to(VehicleState.DESTROYED)
        GlobalSignals.vehicle_destroyed.emit(vehicle_id)
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/damage/damage_receiver_test.gd`
**Status**: [x] Created — 45 test cases covering damage formula, armor reduction, state transitions, signals, edge cases
**Note**: Tests must be run in Godot Editor GUT panel (headless mode class_name loading issue)
**Implementation**: Used GDD percentage formula (armor/100 reduction) instead of story's simplified linear formula

---

## Dependencies

- Depends on: VehicleAttribute, VehicleTypeDB, GlobalSignals
- Unlocks: RetreatJudge