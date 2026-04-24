# Story 001: Weapon Firing System

> **Epic**: VehicleWeaponSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/vehicle-weapon-system.md`
**Requirement**: `TR-weapon-001`, `TR-weapon-002`, `TR-weapon-003`

**ADR Governing Implementation**: ADR-005: Event Bus
**ADR Decision Summary**: WeaponController 管理 cooldown，emit GlobalSignals.turret_fired。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Weapon cooldown per shot (fire_rate from WeaponTypeDB)
- [ ] Damage formula: effective_damage = incoming - armor (min 0)
- [ ] GlobalSignals.turret_fired emitted on shot
- [ ] GlobalSignals.turret_hit emitted on target hit
- [ ] Magic consumption per shot (TK-015)

---

## Implementation Notes

```gdscript
class_name WeaponController extends Node

var cooldown_timer: float = 0.0

func try_fire() -> bool:
    if cooldown_timer > 0:
        return false
    if not MagicConsumptionCalculator.consume_magic(SHOT_COST):
        return false
    
    cooldown_timer = fire_rate
    GlobalSignals.turret_fired.emit(projectile_id, position, direction)
    return true

func _process(delta: float) -> void:
    cooldown_timer -= delta
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/weapon/weapon_firing_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: MagicConsumptionCalculator, GlobalSignals
- Unlocks: TurretSystem