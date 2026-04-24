# Story 001: Enemy Definition Loading

> **Epic**: EnemyTypeDB
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/enemy-type-database.md`
**Requirement**: `TR-enemytype-001`, `TR-enemytype-002`

**ADR Governing Implementation**: ADR-002: Database Loading Strategy
**ADR Decision Summary**: EnemyTypeDB 是 RefCounted Autoload，从 entities.yaml 加载敌人定义，包含 8 种 behavior_hint。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Enemy definitions loaded from entities.yaml
- [ ] get_enemy_stats(enemy_id) returns EnemyStats (health/damage/armor/speed)
- [ ] get_behavior_hint(enemy_id) returns behavior_hint string
- [ ] 8 behavior_hint types defined: aggressive/defensive/swarm/wall_breaker/tracker/ambusher/retreat_early/boss
- [ ] Invalid enemy_id returns null

---

## Implementation Notes

```gdscript
class_name EnemyTypeDB extends RefCounted

class EnemyStats:
    var enemy_id: int
    var health: float
    var damage: float
    var armor: float
    var speed: float
    var behavior_hint: String  # 8种类型

func get_enemy_stats(enemy_id: int) -> EnemyStats:
    return _enemies.get(enemy_id, null)

func get_behavior_hint(enemy_id: int) -> String:
    var stats = get_enemy_stats(enemy_id)
    return stats.behavior_hint if stats else ""
```

---

## QA Test Cases

- **AC-1**: Enemy stats query
  - Given: enemy_id = 1 (valid enemy)
  - When: get_enemy_stats(1) called
  - Then: returns EnemyStats with health, damage, armor, speed
- **AC-2**: Behavior hint validation
  - Given: all enemies loaded
  - When: behavior_hint checked
  - Then: valid hint in 8 types list

---

## Test Evidence

**Type**: Integration
**Required**: `tests/unit/enemytype/enemy_loading_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation layer)
- Unlocks: EnemyAIController, SpawnManager