# ADR-011: Combat System Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

战斗系统整合 WeaponController（战车武器）和 TurretController（炮塔）。武器有 cooldown_timer，消耗 ammo 和 magic。炮塔自动 targeting 最近敌人。DamageReceiver 计算 damage = incoming - armor (min 0)。damage 触发 health change 和 state transition。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Combat (Damage, Projectile) |
| **Knowledge Risk** | LOW — No engine API dependency |
| **References Consulted** | `design/gdd/vehicle-weapon-system.md`, `design/gdd/turret-system.md`, `design/gdd/vehicle-damage-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test weapon cooldown, turret targeting, damage calculation |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-009 (Magic), ADR-002 (ResourceDB, EnemyTypeDB), ADR-010 (Enemy AI), ADR-007 (Vehicle Attribute), ADR-005 (Event Bus) |
| **Enables** | Combat gameplay loop |
| **Blocks** | All combat until Accepted |
| **Ordering Note** | Core layer — after Magic and Enemy AI |

## Decision

**WeaponController + TurretController + DamageReceiver**：

```gdscript
# WeaponController
func fire_weapon(direction: Vector2) -> bool:
    if cooldown_timer > 0:
        return false
    if not MagicConsumption.can_afford(weapon_magic_cost):
        return false
    MagicConsumption.consume(weapon_magic_cost)
    cooldown_timer = weapon_cooldown
    spawn_projectile(position, direction)
    GlobalSignals.weapon_fired.emit(projectile_id, position, direction)
    return true

# TurretController
func acquire_target() -> Node2D:
    var enemies = SpawnManager.active_enemies
    var nearest = null
    var nearest_dist = detection_radius
    for enemy in enemies:
        var dist = position.distance_to(enemy.position)
        if dist < nearest_dist:
            nearest = enemy
            nearest_dist = dist
    return nearest

# DamageReceiver
func take_damage(amount: float) -> void:
    var effective_damage = amount - armor  # armor from VehicleTypeDB
    if effective_damage < 0:
        effective_damage = 0
    current_health -= effective_damage
    GlobalSignals.vehicle_damaged.emit(effective_damage)
    if current_health <= 0:
        state = VehicleState.DESTROYED
        GlobalSignals.vehicle_destroyed.emit(vehicle_id)
```

## GDD Requirements Addressed

| GDD | Requirement | How Satisfied |
|-----|-------------|---------------|
| `vehicle-weapon-system.md` | Weapon cooldown | cooldown_timer per shot |
| `turret-system.md` | Turret targeting | acquire_target() finds nearest enemy |
| `vehicle-damage-system.md` | Damage = incoming - armor | effective_damage calculation |

## Related

- ADR-009: Magic — Weapon consumes magic
- ADR-010: Enemy AI — Turret targets EnemyAIController
- ADR-007: Vehicle Attribute — DamageReceiver modifies health