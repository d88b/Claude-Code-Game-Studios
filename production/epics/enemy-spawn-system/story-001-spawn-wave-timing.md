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

- [ ] Spawn wave timing: spawn_interval per area (night triggers waves)
- [ ] Spawn position validation: within area bounds, not overlapping existing entities
- [ ] GlobalSignals.enemy_spawned emitted on spawn
- [ ] active_enemy_list management
- [ ] EnemyTypeDB lookup for stats

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
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: TimeSystem, AreaManager, EnemyTypeDB, GlobalSignals
- Unlocks: EnemyAIController