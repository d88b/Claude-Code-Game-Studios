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

- [x] Weapon cooldown per shot (fire_rate from WeaponTypeDB) — test_cooldown_duration_formula, test_try_fire_success
- [x] Damage formula: base_damage × efficiency × crit × (1-armor) × range_falloff (min 1) — test_calculate_damage_*
- [x] GlobalSignals.turret_fired emitted on shot — test_try_fire_emits_turret_fired
- [x] GlobalSignals.turret_hit emitted on target hit — test_on_hit_target_emits_turret_hit
- [x] Magic consumption per shot (10.0 for basic weapon) — test_try_fire_consumes_magic

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
**Required**: `tests/unit/weapon/weapon_controller_test.gd`
**Status**: [x] Created — 55 test cases covering cooldown, damage formula, crit, range falloff, GlobalSignals, magic consumption
**Note**: Tests must be run in Godot Editor GUT panel (headless mode class_name loading issue)
**Implementation**: Used GDD percentage formula (armor/100 reduction) with range_falloff, crit_factor, efficiency_modifier

---

## Dependencies

- Depends on: MagicConsumptionCalculator, GlobalSignals
- Unlocks: TurretSystem