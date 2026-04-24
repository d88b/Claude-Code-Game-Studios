# ADR-012: Spawn System Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

敌人生成使用 SpawnManager，管理 spawn_queue 和 active_enemies。wave timing 由 TimeSystem 和 AreaManager 驱动。spawn_interval 配置每个 area。生成位置验证：within bounds, not overlapping。GlobalSignals.enemy_spawned, enemy_killed broadcast。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Spawn management) |
| **Knowledge Risk** | LOW — No engine API dependency |
| **References Consulted** | `design/gdd/enemy-spawn-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test wave timing, spawn position validation |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-002 (EnemyTypeDB), ADR-010 (EnemyAI), ADR-004 (TimeSystem), ADR-016 (AreaManager), ADR-005 (Event Bus) |
| **Enables** | Combat gameplay |
| **Blocks** | Enemy encounters until Accepted |
| **Ordering Note** | Core layer — after Enemy AI and Time System |

## Decision

**SpawnManager with Wave Timing**：

```gdscript
class_name SpawnManager extends Node

var spawn_queue: Array[SpawnWave] = []
var active_enemies: Array[EnemyAIController] = []
var wave_timer: float = 0.0

func spawn_wave(area_id: int, wave_def: SpawnWaveDef) -> void:
    for enemy_def in wave_def.enemies:
        var spawn_pos = _validate_spawn_position(enemy_def.position, area_id)
        var enemy = EnemyTypeDB.create_enemy(enemy_def.enemy_type_id, spawn_pos)
        active_enemies.append(enemy)
        GlobalSignals.enemy_spawned.emit(enemy.enemy_id, area_id)

func _on_time_hour_changed(hour: int) -> void:
    # Night triggers spawn waves
    if hour >= 19:  # NIGHT_START
        spawn_wave(current_area, night_wave_def)
```

## GDD Requirements Addressed

| GDD | Requirement | How Satisfied |
|-----|-------------|---------------|
| `enemy-spawn-system.md` | Wave timing | TimeSystem.hour triggers spawn |
| `enemy-spawn-system.md` | Spawn position validation | _validate_spawn_position() checks bounds |

## Related

- ADR-010: Enemy AI — SpawnManager creates EnemyAIController
- ADR-016: Area — AreaManager defines spawn bounds