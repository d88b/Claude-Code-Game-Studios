# Story 001: Spawn Wave Timing

> **Epic**: EnemySpawnSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/enemy-spawn-system.md`
**Requirement**: `TR-spawn-001`, `TR-spawn-002`

**ADR Governing Implementation**: ADR-002, ADR-005: Event Bus
**ADR Decision Summary**: SpawnManager 监听 time_hour_changed，night triggers spawn waves。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [x] Spawn wave timing: night triggers spawn waves via GlobalSignals.day_phase_changed
- [x] Spawn position validation: within spawn_zone, not overlapping existing entities
- [x] GlobalSignals.enemy_spawned emitted on spawn
- [x] active_enemy_list management (add on spawn, remove on kill)
- [x] EnemyTypeDB lookup for enemy selection
- [x] MAX_ACTIVE_ENEMIES limit (100)
- [x] Wave structure: WAVE_COUNT_PER_TIDE (5), WAVE_INTERVAL (30s)
- [x] danger_multiplier applied to wave batch count

---

## Implementation Notes

```gdscript
class_name SpawnManager extends Node

var active_enemy_list: Array[Node2D] = []

func _ready() -> void:
    GlobalSignals.night_started.connect(_on_night_started)

func _on_night_started() -> void:
    # Night triggers spawn waves
    spawn_wave()

func spawn_wave() -> void:
    var area = AreaManager.current_area
    var spawn_count = area.danger_level * BASE_SPAWN_COUNT
    
    for i in spawn_count:
        var pos = get_valid_spawn_position(area.bounds)
        spawn_enemy(pos)
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/spawn/spawn_wave_test.gd`
**Status**: [x] Created — 60+ test cases covering constants, state machine, signals, wave management, spawn logic, enemy creation, death handling
**Note**: Tests must be run in Godot Editor GUT panel (headless mode class_name loading issue)
**Implementation**: SpawnManager monitors GlobalSignals.day_phase_changed, spawns on NIGHT phase, maintains active_enemy_list, uses EnemyAIController scene

---

## Dependencies

- Depends on: TimeSystem, AreaManager, EnemyTypeDB, GlobalSignals
- Unlocks: EnemyAIController