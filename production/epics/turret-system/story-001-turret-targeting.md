# Story 001: Turret Targeting

> **Epic**: TurretSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/turret-system.md`
**Requirement**: `TR-turret-001`, `TR-turret-002`, `TR-turret-003`

**ADR Governing Implementation**: ADR-005: Event Bus
**ADR Decision Summary**: TurretController 状态机 (IDLE/TARGETING/FIRING/COOLDOWN/DISABLED)，nearest enemy targeting。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [x] State machine: IDLE → TARGETING → FIRING → COOLDOWN → DISABLED with transition logic
- [x] Targeting: nearest enemy within targeting_range (attack_range × 2.0)
- [x] Resource consumption: MAGIC_RESERVE or AMMO_STACK per shot
- [x] GlobalSignals.turret_fired, turret_hit emitted on fire
- [x] Efficiency drops on damage (0.8 at 50% health, 0.5 at 30% health)
- [x] MINIMUM_DAMAGE floor (1) applied in damage calculation
- [x] Target lock debounce (TARGET_LOCK_FRAMES = 3)

---

## Implementation Notes

```gdscript
class_name TurretController extends Node

enum State { IDLE, TARGETING, FIRING, COOLDOWN, DISABLED }

var detection_radius: float = 256.0  # 8 cells
var linked_storage: FacilityController

func find_target() -> Node2D:
    var enemies = SpawnManager.active_enemy_list
    var nearest = null
    var nearest_dist = INF
    
    for enemy in enemies:
        var dist = position.distance_to(enemy.position)
        if dist < detection_radius and dist < nearest_dist:
            nearest = enemy
            nearest_dist = dist
    
    return nearest
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/turret/turret_targeting_test.gd`
**Status**: [x] Created — 75+ test cases covering state machine, targeting, resources, damage calculation, health/efficiency, repair, signals
**Note**: Tests must be run in Godot Editor GUT panel (headless mode class_name loading issue)
**Implementation**: TurretController with state machine, SpawnManager integration for target query, damage formula with armor effectiveness

---

## Dependencies

- Depends on: SpawnManager, FacilityController, WeaponController
- Unlocks: None