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

- [ ] State machine: IDLE → TARGETING → FIRING → COOLDOWN → DISABLED
- [ ] Targeting: nearest enemy within detection_radius
- [ ] Ammo consumption from linked storage (FacilityController.contents)
- [ ] GlobalSignals.turret_fired, turret_hit, turret_kill emitted

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
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: SpawnManager, FacilityController, WeaponController
- Unlocks: None