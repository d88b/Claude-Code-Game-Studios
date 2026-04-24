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

- [ ] Damage formula: effective_damage = incoming_damage - armor (min 0)
- [ ] GlobalSignals.vehicle_damaged emitted on damage
- [ ] State transition: DISABLED when health < 20%
- [ ] State transition: DESTROYED when health <= 0
- [ ] GlobalSignals.vehicle_destroyed emitted on death

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
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: VehicleAttribute, VehicleTypeDB, GlobalSignals
- Unlocks: RetreatJudge