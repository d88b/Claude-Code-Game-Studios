# 铁锈魔潮 (Rust Magic Tide) — Master Architecture

## Document Status

| Field | Value |
|-------|-------|
| **Version** | 1.0 |
| **Last Updated** | 2026-04-24 |
| **Engine** | Godot 4.6 |
| **GDDs Covered** | 26 MVP systems (see systems-index.md) |
| **ADRs Referenced** | ADR-001 to ADR-016 (16 ADRs created) |
| **Technical Director Sign-Off** | 2026-04-24 — APPROVED |
| **Lead Programmer Feasibility** | Skipped — Lean mode |

---

## Engine Knowledge Gap Summary

**Engine**: Godot 4.6 (January 2026)
**LLM Training Cutoff**: May 2025
**Post-Cutoff Versions**: 4.4 (MEDIUM), 4.5 (HIGH), 4.6 (HIGH)

### HIGH RISK Domains

| Domain | Post-Cutoff Change | Implication |
|--------|--------------------|-------------|
| **Dual-focus Input** | Godot 4.6 separates KB/gamepad focus from mouse/touch focus | InputManager must handle BOTH focus states simultaneously |
| **Glow Rendering** | Glow now applies BEFORE tonemapping (4.6) | Existing glow presets may produce different visual output |
| **D3D12 Default** | D3D12 is now default renderer on Windows (4.6) | Test on Windows hardware; Vulkan fallback may differ |
| **2D Navigation Server** | Dedicated NavigationServer2D introduced (4.5) | NavigationAgent2D API differs from training data |

### MEDIUM RISK Domains

| Domain | Post-Cutoff Change | Implication |
|--------|--------------------|-------------|
| **FileAccess Return Type** | FileAccess.open() returns FileAccess (not File) (4.4) | Save/load code must use FileAccess API correctly |
| **GDScript Variadic Args** | @variadic attribute added (4.5) | Optional: can use for flexible function signatures |
| **@abstract Attribute** | Abstract class enforcement (4.5) | Use for base classes that must not be instantiated directly |

### LOW RISK Domains

| Domain | Status |
|--------|--------|
| **TileMapLayer** | API stable (introduced 4.3, confirmed working in 4.6) |
| **CharacterBody2D** | API unchanged (stable since 4.0) |
| **Signal System** | No significant changes |
| **Resource Loading** | No significant changes |

### Systems Touching HIGH/MEDIUM Risk Domains

| System | Domain | Risk Level | Action Required |
|--------|--------|------------|-----------------|
| InputManager | Dual-focus Input | HIGH | Verify against `docs/engine-reference/godot/modules/input.md` |
| EnemyAIController | NavigationAgent2D | HIGH | Verify against `docs/engine-reference/godot/modules/navigation.md` |
| TileMapWorld | TileMapLayer | LOW | Use TileMapLayer API (not deprecated TileMap) |
| SaveManager | FileAccess | MEDIUM | Verify FileAccess.open() usage |

---

## System Layer Map

5 层架构模型，26 MVP 系统分层：

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  PRESENTATION LAYER                                                         │
│  (UI, HUD, menus, VFX, audio)                                               │
│  ─────────────────────────────────────────────────────────────────────────  │
│  MVP systems: None (Full Vision tier)                                       │
│  Future: HUD系统, 撤退警告UI, 天气状态UI, 音效系统                            │
├─────────────────────────────────────────────────────────────────────────────┤
│  FEATURE LAYER                                                              │
│  (gameplay features, AI, quests)                                            │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Systems:                                                                   │
│  ├── BuildValidator — placement validation rules                            │
│  └── FacilityController — storage/workbench entities                        │
│  Future: 玩家背包, 战车仓库, 下车状态, 搜刮交互, 天气系统, 种田系统           │
├─────────────────────────────────────────────────────────────────────────────┤
│  CORE LAYER                                                                 │
│  (physics, input, combat, movement)                                         │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Systems:                                                                   │
│  ├── CollisionManager — swept collision, severity calculation               │
│  ├── DigController — block destruction, progress tracking                   │
│  ├── PlaceController — block placement, cost deduction                      │
│  ├── DropManager — resource entity spawning, pickup                         │
│  ├── DayNightCycle — ambient lighting, overlay visibility                   │
│  ├── VehicleAttribute — health/magic tracking, damage events                │
│  ├── VehicleController — movement, velocity, orientation                    │
│  ├── MagicConsumption — pool management, depletion handling                 │
│  ├── WeaponController — firing, cooldown, projectile spawn                  │
│  ├── DamageReceiver — damage calculation, state transitions                 │
│  ├── AreaManager — area bounds, entry detection                             │
│  ├── EnemyAIController — state machine, navigation, boids                   │
│  ├── SpawnManager — wave timing, enemy instantiation                        │
│  ├── TurretController — targeting, firing, ammo link                        │
│  └── RetreatJudge — threshold detection, warning triggers                   │
├─────────────────────────────────────────────────────────────────────────────┤
│  FOUNDATION LAYER                                                           │
│  (engine integration, save/load, scene management, event bus)               │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Systems:                                                                   │
│  ├── TileMapWorld — chunk loading, cell storage, 5 layers                   │
│  ├── BlockTypeDB — collision profiles, dig difficulty, drops                │
│  ├── ResourceDB — stack sizes, categories, definitions                      │
│  ├── EnemyTypeDB — stats, behavior hints, animations                        │
│  ├── BuildItemDB — costs, terrain support, placement rules                  │
│  ├── VehicleTypeDB — base stats, state definitions                          │
│  ├── ScavengeContainerDB — loot tables, probabilities                       │
│  ├── TimeSystem — clock, time scale, day counting                           │
│  └── InputManager — action mapping, mouse position, gamepad state           │
├─────────────────────────────────────────────────────────────────────────────┤
│  PLATFORM LAYER                                                             │
│  (OS, hardware, engine API surface)                                         │
│  ─────────────────────────────────────────────────────────────────────────  │
│  Godot 4.6 API:                                                             │
│  ├── TileMapLayer (replaces deprecated TileMap)                             │
│  ├── CharacterBody2D (vehicle/enemy physics)                                │
│  ├── NavigationAgent2D (enemy pathfinding)                                  │
│  ├── Signal (inter-module communication)                                    │
│  ├── FileAccess (save/load serialization)                                   │
│  └── CanvasModulate (day/night ambient lighting)                            │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Module Ownership

### Foundation Layer Modules

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| **TileMapWorld** | loaded_chunks, modified_cells, 5 TileMapLayer nodes | get_cell_at_position, set_cell_at_position, get_chunk_for_position, load_chunks_around, get_spawn_point | — | TileMapLayer ⚠️ LOW RISK (stable 4.3+) |
| **BlockTypeDB** | collision_profiles, dig_difficulty_map, display_names, category_map | get_collision_profile, get_dig_difficulty, get_display_name, is_valid_block, get_blocks_by_category | — | RefCounted (no Node) |
| **ResourceDB** | resource_definitions, stack_size_map, category_map | get_resource, get_max_stack_size, get_category, can_store_in_vehicle | — | RefCounted (no Node) |
| **EnemyTypeDB** | enemy_definitions, stats_map, behavior_hint_map | get_enemy_stats, get_behavior_hint, get_display_name, is_valid_enemy | — | RefCounted (no Node) |
| **BuildItemDB** | build_item_definitions, cost_map, terrain_support_map | get_build_cost, check_terrain_support, get_placement_rules | BlockTypeDB.is_valid_block | RefCounted (no Node) |
| **VehicleTypeDB** | vehicle_definitions, stats_map, state_machine_definitions | get_vehicle_stats, get_state_definition, get_default_vehicle | — | RefCounted (no Node) |
| **ScavengeContainerDB** | container_definitions, loot_tables, probability_weights | get_loot_table, get_container_type, roll_loot | ResourceDB.get_resource | RefCounted (no Node) |
| **TimeSystem** | current_time, day_count, time_scale | get_current_time, get_day_count, set_time_scale | — | Node (autoload) |
| **InputManager** | action_map, mouse_position, mouse_action, is_gamepad_active, current_focus | is_action_pressed, is_action_just_pressed, get_current_focus | — | Input singleton ⚠️ HIGH RISK (dual-focus 4.6) |

### Core Layer Modules

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| **CollisionManager** | collision_results cache | swept_collision_check, calculate_severity | TileMapWorld.get_cell_at_position, BlockTypeDB.get_collision_profile | — |
| **DigController** | dig_progress_map, current_target | start_dig, cancel_dig, get_progress | TileMapWorld.set_cell_at_position, BlockTypeDB.get_dig_difficulty, InputManager.is_action_pressed | — |
| **PlaceController** | placement_preview, cost_queue | preview_placement, confirm_placement, cancel_placement | TileMapWorld.set_cell_at_position, BuildValidator.validate_placement, BuildItemDB.get_build_cost | — |
| **DropManager** | active_drops list, drop_entities | spawn_drop, pickup_drop, expire_drops | ResourceDB.get_resource, TileMapWorld.get_cell_at_position | — |
| **DayNightCycle** | ambient_color, overlay_opacity | get_ambient_light, get_phase | TimeSystem.get_current_time | CanvasModulate ⚠️ LOW RISK |
| **VehicleAttribute** | current_health, current_magic_pool, cargo_contents | get_health, get_magic_pool, get_cargo | VehicleTypeDB.get_vehicle_stats | — |
| **VehicleController** | velocity, position, orientation, current_vehicle_id | teleport_to, apply_velocity_correction, get_vehicle_bounds | InputManager.action_map, VehicleAttribute, MagicConsumption, CollisionManager | CharacterBody2D ⚠️ LOW RISK (stable) |
| **MagicConsumption** | current_pool, max_pool, depletion_state | can_afford, consume, replenish, get_movement_cost | VehicleAttribute.max_magic_pool | — |
| **WeaponController** | current_weapon_id, ammo_counts, cooldown_timer | fire_weapon, switch_weapon, reload_weapon | InputManager.is_action_pressed, VehicleController.position, MagicConsumption.consume | — |
| **DamageReceiver** | pending_damage, damage_state | take_damage, get_state, repair | VehicleAttribute.current_health, VehicleTypeDB.get_vehicle_stats | — |
| **AreaManager** | area_definitions, current_area, visited_areas | get_current_area, check_area_entry, get_area_bounds | TileMapWorld, VehicleController.position | — |
| **EnemyAIController** | state, behavior_hint, target_position, velocity | set_target, get_next_path_position, apply_separation, take_damage | VehicleController.position, AreaManager.get_area_bounds, EnemyTypeDB.get_behavior_hint | NavigationAgent2D ⚠️ HIGH RISK (4.5+ 2D nav server), CharacterBody2D |
| **SpawnManager** | spawn_queue, active_enemies, wave_timer | spawn_wave, get_active_enemies, despawn_enemy | EnemyTypeDB, TileMapWorld.get_spawn_point, EnemyAIController, AreaManager | — |
| **TurretController** | state, target, ammo_link, cooldown | acquire_target, fire_at_target, consume_ammo | EnemyAIController.positions, WeaponController, ResourceDB | — |
| **RetreatJudge** | retreat_threshold, warning_level | check_threshold, get_warning_level | TimeSystem, DayNightCycle, VehicleAttribute, MagicConsumption, DamageReceiver | — |

### Feature Layer Modules

| Module | Owns | Exposes | Consumes | Engine APIs |
|--------|------|---------|----------|-------------|
| **BuildValidator** | validation_rules, terrain_matrix | validate_placement, check_terrain_support, get_entities_at_position | TileMapWorld.get_cell_at_position, BlockTypeDB, BuildItemDB | — |
| **FacilityController** | facilities list, contents_map, state_map | create_facility, interact, deposit_item, withdraw_item, craft_item | TileMapWorld.set_cell_at_position, BuildValidator, MagicConsumption.current_pool | — |

---

### Module Dependency Diagram

```
                    ┌──────────────────────────────────────────────┐
                    │              PLATFORM LAYER                   │
                    │  (Godot 4.6 Engine APIs)                      │
                    └──────────────────────────────────────────────┘
                                   │
                                   ▼
    ┌──────────────────────────────────────────────────────────────────────────────┐
    │                          FOUNDATION LAYER                                     │
    │                                                                               │
    │   InputManager ─────────────┐                                                │
    │   (⚠️ HIGH RISK)            │                                                │
    │                             │                                                │
    │   TimeSystem ───────────────┼────────────────────┐                           │
    │                             │                    │                           │
    │   TileMapWorld ─────────────┼────────────────────┼─────┐                     │
    │   (⚠️ LOW RISK TileMapLayer)│                    │     │                     │
    │                             │                    │     │                     │
    │   ┌─────────────────────────┼────────────────────┼─────┼─────┐               │
    │   │ Database Cluster        │                    │     │     │               │
    │   │                         │                    │     │     │               │
    │   │ BlockTypeDB ────────────┼────┐               │     │     │               │
    │   │ ResourceDB ─────────────┼──┐ │               │     │     │               │
    │   │ EnemyTypeDB ────────────┼──┼─┼─────┐         │     │     │               │
    │   │ BuildItemDB ────────────┼──┼─┼─────┼─────┐   │     │     │               │
    │   │ VehicleTypeDB ──────────┼──┼─┼─────┼─────┼───┼─────┼─────┼─────┐         │
    │   │ ScavengeContainerDB ────┼──┼─┼─────┼─────┼───┼─────┼─────┼─────┼─────┐   │
    │   └─────────────────────────┼──┼─┼─────┼─────┼───┼─────┼─────┼─────┼─────┼───│
    │                             │  │ │     │     │   │     │     │     │     │   │
    └─────────────────────────────┼──┼─┼─────┼─────┼───┼─────┼─────┼─────┼─────┼───│
                                  │  │ │     │     │   │     │     │     │     │   │
                                  ▼  ▼ ▼     ▼     ▼   ▼     ▼     ▼     ▼     ▼   │
    ┌──────────────────────────────────────────────────────────────────────────────│
    │                            CORE LAYER                                         │
    │                                                                               │
    │   CollisionManager ────────────┬───────────────────────────────────┬─────────│
    │   (reads TileMap, BlockTypeDB) │                                   │         │
    │                                │                                   │         │
    │   VehicleController ───────────┼───────────────────────────────────┼─────────│
    │   (reads InputManager,         │                                   │         │
    │    CollisionManager corrects)  │                                   │         │
    │                                │                                   │         │
    │   VehicleAttribute ────────────┼───┬───────────────────────────────┼─────────│
    │   (reads VehicleTypeDB)        │   │                               │         │
    │                                │   │                               │         │
    │   MagicConsumption ────────────┼───┼───┬───────────────────────────┼─────────│
    │   (reads VehicleAttribute)     │   │   │                           │         │
    │                                │   │   │                           │         │
    │   DamageReceiver ──────────────┼───┼───┼───┬───────────────────────┼─────────│
    │   (reads VehicleAttribute,     │   │   │   │                       │         │
    │    CollisionManager severity)  │   │   │   │                       │         │
    │                                │   │   │   │                       │         │
    │   WeaponController ────────────┼───┼───┼───┼───┬───────────────────┼─────────│
    │   (reads InputManager,         │   │   │   │   │                   │         │
    │    VehicleController.pos,      │   │   │   │   │                   │         │
    │    MagicConsumption.consume)   │   │   │   │   │                   │         │
    │                                │   │   │   │   │                   │         │
    │   DayNightCycle ───────────────┼───┼───┼───┼───┼───────────────────┼─────────│
    │   (reads TimeSystem)           │   │   │   │   │                   │         │
    │                                │   │   │   │   │                   │         │
    │   AreaManager ─────────────────┼───┼───┼───┼───┼───────────────────┼─────────│
    │   (reads TileMapWorld,         │   │   │   │   │                   │         │
    │    VehicleController.pos)      │   │   │   │   │                   │         │
    │                                │   │   │   │   │                   │         │
    │   EnemyAIController ───────────┼───┼───┼───┼───┼───┬───────────────┼─────────│
    │   (⚠️ HIGH RISK Navigation)    │   │   │   │   │   │               │         │
    │   (reads VehicleController.pos │   │   │   │   │   │               │         │
    │    AreaManager, EnemyTypeDB)   │   │   │   │   │   │               │         │
    │                                │   │   │   │   │   │               │         │
    │   SpawnManager ────────────────┼───┼───┼───┼───┼───┼───┬───────────┼─────────│
    │   (reads EnemyTypeDB,          │   │   │   │   │   │   │           │         │
    │    TileMapWorld, EnemyAI,      │   │   │   │   │   │   │           │         │
    │    AreaManager)                │   │   │   │   │   │   │           │         │
    │                                │   │   │   │   │   │   │           │         │
    │   TurretController ────────────┼───┼───┼───┼───┼───┼───┼───┬───────┼─────────│
    │   (reads EnemyAI positions,    │   │   │   │   │   │   │   │       │         │
    │    WeaponController, ResourceDB│   │   │   │   │   │   │   │       │         │
    │                                │   │   │   │   │   │   │   │       │         │
    │   RetreatJudge ────────────────┼───┼───┼───┼───┼───┼───┼───┼───────┼─────────│
    │   (reads TimeSystem,           │   │   │   │   │   │   │   │       │         │
    │    DayNightCycle,              │   │   │   │   │   │   │   │       │         │
    │    VehicleAttribute,           │   │   │   │   │   │   │   │       │         │
    │    MagicConsumption,           │   │   │   │   │   │   │   │       │         │
    │    DamageReceiver)             │   │   │   │   │   │   │   │       │         │
    │                                │   │   │   │   │   │   │   │       │         │
    │   DigController ───────────────┼───┼───┼───┼───┼───┼───┼───┼───────┼─────────│
    │   (reads TileMapWorld,         │   │   │   │   │   │   │   │       │         │
    │    BlockTypeDB, InputManager)  │   │   │   │   │   │   │   │       │         │
    │                                │   │   │   │   │   │   │   │       │         │
    │   PlaceController ─────────────┼───┼───┼───┼───┼───┼───┼───┼───────┼─────────│
    │   (reads TileMapWorld,         │   │   │   │   │   │   │   │       │         │
    │    BuildValidator, BuildItemDB │   │   │   │   │   │   │   │       │         │
    │                                │   │   │   │   │   │   │   │       │         │
    │   DropManager ─────────────────┼───┼───┼───┼───┼───┼───┼───┼───────┼─────────│
    │   (reads ResourceDB,           │   │   │   │   │   │   │   │       │         │
    │    TileMapWorld)               │   │   │   │   │   │   │   │       │         │
    │                                │   │   │   │   │   │   │   │       │         │
    └────────────────────────────────┼───┼───┼───┼───┼───┼───┼───┼───────┼─────────│
                                     │   │   │   │   │   │   │   │       │         │
                                     ▼   ▼   ▼   ▼   ▼   ▼   ▼   ▼       ▼         │
    ┌──────────────────────────────────────────────────────────────────────────────│
    │                           FEATURE LAYER                                       │
    │                                                                               │
    │   BuildValidator ────────────────────────────────┬───────────────────────────│
    │   (reads TileMapWorld, BlockTypeDB, BuildItemDB) │                           │
    │                                                  │                           │
    │   FacilityController ────────────────────────────┼───────────────────────────│
    │   (reads TileMapWorld, BuildValidator,           │                           │
    │    BuildItemDB, MagicConsumption)                │                           │
    │                                                  │                           │
    └──────────────────────────────────────────────────┼───────────────────────────│
                                                       │                           │
                                                       ▼                           │
    ┌──────────────────────────────────────────────────────────────────────────────│
    │                         PRESENTATION LAYER                                    │
    │   (No MVP systems — Full Vision tier)                                         │
    │   Future: HUD, RetreatWarningUI, WeatherUI, AudioSystem                      │
    └──────────────────────────────────────────────────────────────────────────────┘
```

---

## Data Flow

### 1. Frame Update Path

每帧数据流（60 FPS 目标）：

```
InputManager._input(event)
    │
    ├─── Keyboard/Gamepad → action_map
    ├─── Mouse → mouse_position, mouse_action
    │
    ▼
VehicleController._physics_process(delta)
    │
    ├─── Reads: action_map, VehicleAttribute.speed, MagicConsumption.pool
    ├─── Computes: target_velocity, magic_cost
    ├─── Writes: VehicleAttribute.speed, MagicConsumption.pool
    │
    ▼
CollisionManager._physics_process(delta)
    │
    ├─── Reads: VehicleController.velocity, TileMapWorld.cells, BlockTypeDB.profiles
    ├─── Computes: swept_collision_result
    ├─── Writes: VehicleController.velocity (corrected), DamageReceiver.pending_damage
    │
    ▼
EnemyAIController._physics_process(delta)
    │
    ├─── Reads: VehicleController.position, AreaManager.bounds, SpawnManager.enemies
    ├─── Calls: NavigationAgent2D.get_next_path_position() ⚠️ HIGH RISK
    ├─── Writes: self.velocity, self.state
    │
    ▼
WeaponController._physics_process(delta)
    │
    ├─── Reads: InputManager.fire_pressed, VehicleController.position
    ├─── Writes: projectile entities, MagicConsumption.pool
    │
    ▼
DayNightCycle._process(delta)
    │
    ├─── Reads: TimeSystem.current_time
    ├─── Writes: CanvasModulate.color, TileMapWorld.overlay_visibility
    │
    ▼
Rendering (automatic via Godot scene tree)
```

**关键同步点**：
- VehicleAttribute/MagicConsumption: 共享状态，VehicleController 写入，其他读取
- CollisionManager: 可修正 VehicleController.velocity
- InputManager: ⚠️ HIGH RISK dual-focus 模式

---

### 2. Event/Signal Path

全局信号总线（GlobalSignals autoload）：

```gdscript
# GlobalSignals — Event Bus
extends Node

# Time events
signal time_hour_changed(hour: int)
signal day_phase_changed(phase: DayPhase)

# Vehicle events
signal vehicle_deployed(vehicle_id: int)
signal vehicle_damaged(amount: float)
signal vehicle_destroyed(vehicle_id: int)

# Enemy events
signal enemy_spawned(enemy_id: int)
signal enemy_killed(enemy_id: int)

# Block events
signal block_dug(position: Vector2i)
signal block_placed(position: Vector2i)

# Item events
signal item_collected(item_id: int, count: int)

# Facility events
signal facility_created(facility_id: int)
signal facility_destroyed(facility_id: int)

# Area events
signal area_entered(area_id: int)

# Retreat events
signal retreat_threshold_reached()
```

**直接信号（模块内）**：
- VehicleController.velocity_changed → CollisionManager
- DamageReceiver.health_changed → UI HUD
- WeaponController.weapon_fired → MagicConsumption
- EnemyAIController.state_changed → EnemyTypeDB
- TurretController.target_acquired → WeaponController
- FacilityController.storage_changed → UI

---

### 3. Save/Load Path

持久化数据流：

```gdscript
# SaveManager — Persistence

class_name SaveManager extends Node

func save_game(slot: int) -> void:
    var data = {
        "version": "1.0",
        "timestamp": Time.get_unix_time_from_system(),
        "world_state": {
            "chunks": TileMapWorld.get_loaded_chunks(),
            "modified_cells": TileMapWorld.get_modified_cells(),
            "facilities": FacilityController.get_all_facilities(),
        },
        "vehicle_state": {
            "current_vehicle": VehicleTypeDB.get_active_id(),
            "position": VehicleController.position,
            "health": DamageReceiver.current_health,
            "magic_pool": MagicConsumption.current_pool,
            "cargo": VehicleAttribute.cargo_contents,
            "ammo": WeaponController.ammo_counts,
        },
        "time_state": {
            "current_time": TimeSystem.current_time,
            "day_count": TimeSystem.day_count,
        },
        "progress_state": {
            "areas_visited": AreaManager.visited_areas,
            "enemies_killed": SpawnManager.total_kills,
        },
    }

    # ⚠️ MEDIUM RISK: FileAccess return type (Godot 4.4)
    var file = FileAccess.open("user://save_slot_%d.json" % slot, FileAccess.WRITE)
    file.store_string(JSON.stringify(data))
    file.close()

func load_game(slot: int) -> void:
    # ⚠️ MEDIUM RISK: FileAccess return type (Godot 4.4)
    var file = FileAccess.open("user://save_slot_%d.json" % slot, FileAccess.READ)
    var data = JSON.parse_string(file.get_as_text())
    file.close()

    # Restore state
    TileMapWorld.load_chunks(data.world_state.chunks)
    TileMapWorld.apply_modified_cells(data.world_state.modified_cells)
    VehicleController.teleport_to(data.vehicle_state.position)
    DamageReceiver.set_health(data.vehicle_state.health)
    MagicConsumption.set_pool(data.vehicle_state.magic_pool)
    TimeSystem.set_time(data.time_state.current_time)
    # ... more restoration

    GlobalSignals.game_loaded.emit()
```

**持久化边界**：
- TileMapWorld: 只保存 modified_cells（非原始地形）
- 数据库: 不保存（BlockTypeDB 等是静态配置）
- EnemyAIController.state: 不保存（加载时重算）

---

### 4. Initialisation Order

系统启动顺序：

```
Phase 0 — Autoloads (before scene load):
├─── 1. GlobalSignals (signal bus)
├─── 2. GameConfig (entities.yaml settings)
├─── 3. BlockTypeDB (static)
├─── 4. ResourceDB (static)
├─── 5. EnemyTypeDB (static)
├─── 6. BuildItemDB (static)
├─── 7. VehicleTypeDB (static)
├─── 8. ScavengeContainerDB (static)
├─── 9. TimeSystem (clock)
├─── 10. InputManager ⚠️ HIGH RISK (dual-focus)

Phase 1 — Main Scene Load:
├─── 11. TileMapWorld._ready()
│       └─── Load initial chunks, generate terrain
│       └─── Emit: world_ready

Phase 2 — Vehicle Initialization:
├─── 12. VehicleController._ready()
│       └─── Load default vehicle, init attributes
│       └─── Emit: vehicle_ready

Phase 3 — Systems Initialization:
├─── 13. CollisionManager._ready() — subscribe vehicle_ready
├─── 14. DayNightCycle._ready() — subscribe time_hour_changed
├─── 15. AreaManager._ready() — subscribe vehicle_position
├─── 16. SpawnManager._ready() — subscribe area_entered
├─── 17. BuildValidator._ready() — subscribe block_placed
├─── 18. FacilityController._ready() — subscribe facility_created

Phase 4 — UI Initialization:
├─── 19. HUD._ready() — subscribe display signals
├─── 20. MenuSystem._ready() — subscribe input events

Phase 5 — Game Ready:
└─── GlobalSignals.game_ready.emit()
```

**初始化依赖规则**：
- 数据库 Autoloads 最先（Phase 0）
- TileMapWorld 在 VehicleController 前（需要 spawn_point）
- CollisionManager 等 VehicleController（订阅 velocity）
- SpawnManager 等 AreaManager（订阅 area_entered）

---

## API Boundaries

### Foundation Layer APIs

#### TileMapWorld

```gdscript
class_name TileMapWorld extends Node2D

# Properties (Read-Only for callers)
var cell_size: int          # CELL_SIZE = 32
var chunk_size: int         # CHUNK_SIZE = 32
var loaded_chunks: Dictionary  # {chunk_id: ChunkData} — read only

# Methods
func get_cell_at_position(grid_pos: Vector2i) -> int
    # Returns: block_type_id (0=empty, -1=out of bounds)

func set_cell_at_position(grid_pos: Vector2i, block_type_id: int) -> bool
    # Returns: true if successful

func get_chunk_for_position(world_pos: Vector2) -> ChunkData

func load_chunks_around(center_chunk: Vector2i, radius: int) -> void

func get_spawn_point() -> Vector2i

# Signals
signal cell_changed(grid_pos: Vector2i, old_block: int, new_block: int)
signal chunk_loaded(chunk_id: Vector2i)
signal chunk_unloaded(chunk_id: Vector2i)
```

#### BlockTypeDB

```gdscript
class_name BlockTypeDB extends RefCounted

func get_collision_profile(block_type_id: int) -> CollisionProfile
func get_dig_difficulty(block_type_id: int) -> float
func get_display_name(block_type_id: int) -> String
func is_valid_block(block_type_id: int) -> bool
func get_blocks_by_category(category: String) -> Array[int]
```

#### ResourceDB

```gdscript
class_name ResourceDB extends RefCounted

func get_resource(resource_id: int) -> ResourceDefinition
func get_max_stack_size(resource_id: int) -> int
func get_category(resource_id: int) -> String
func can_store_in_vehicle(resource_id: int) -> bool
```

#### InputManager

```gdscript
# ⚠️ HIGH RISK — Dual-focus (Godot 4.6)
class_name InputManager extends Node

var action_map: Dictionary      # {"move_up": bool, ...}
var mouse_position: Vector2i
var mouse_action: MouseAction   # NONE, LEFT_CLICK, RIGHT_CLICK, DRAG
var is_gamepad_active: bool
var current_focus: InputFocus   # KEYBOARD_GAMEPAD, MOUSE_TOUCH, BOTH

func is_action_pressed(action: StringName) -> bool
func is_action_just_pressed(action: StringName) -> bool
func get_current_focus() -> InputFocus

signal action_changed(action: StringName, pressed: bool)
signal mouse_clicked(position: Vector2i, button: int)
signal focus_changed(focus_type: InputFocus)
```

---

### Core Layer APIs

#### VehicleController

```gdscript
class_name VehicleController extends CharacterBody2D

var velocity: Vector2
var position: Vector2
var orientation: float
var current_vehicle_id: int

func teleport_to(grid_pos: Vector2i) -> void
func apply_velocity_correction(new_velocity: Vector2) -> void
func get_vehicle_bounds() -> Rect2

signal velocity_changed(new_velocity: Vector2)
signal position_changed(new_pos: Vector2)
signal orientation_changed(new_angle: float)
```

#### CollisionManager

```gdscript
class_name CollisionManager extends Node

func swept_collision_check(
    start_pos: Vector2,
    velocity: Vector2,
    bounds: Rect2,
    max_steps: int = 64
) -> SweptCollisionResult
    # Returns: {hit, hit_position, remaining_velocity, severity}

func calculate_severity(velocity: Vector2, block_friction: float) -> float

signal collision_detected(position: Vector2, severity: float)
signal collision_blocked(position: Vector2, block_id: int)
```

#### WeaponController

```gdscript
class_name WeaponController extends Node

var current_weapon_id: int
var ammo_counts: Dictionary
var cooldown_timer: float

func fire_weapon(direction: Vector2) -> bool
func switch_weapon(slot_index: int) -> void
func reload_weapon() -> void

signal weapon_fired(projectile_id: int, position: Vector2, direction: Vector2)
signal weapon_switched(new_weapon_id: int)
signal ammo_changed(ammo_type_id: int, new_count: int)
signal cooldown_started(seconds: float)
```

#### EnemyAIController

```gdscript
# ⚠️ HIGH RISK — NavigationAgent2D (Godot 4.5+)
class_name EnemyAIController extends CharacterBody2D

var state: EnemyState           # IDLE, PATROL, CHASE, ATTACK, FLEE, DEAD
var behavior_hint: BehaviorHint # 8 types from EnemyTypeDB
var target_position: Vector2
var velocity: Vector2

func set_target(world_pos: Vector2) -> void
func get_next_path_position() -> Vector2  # ⚠️ NavigationAgent2D
func apply_separation(neighbors: Array) -> Vector2
func take_damage(amount: float) -> void

signal state_changed(new_state: EnemyState)
signal target_acquired(target: Node2D)
signal target_lost()
signal damaged(amount: float)
signal killed()
```

#### MagicConsumption

```gdscript
class_name MagicConsumption extends Node

var current_magic_pool: float
var max_magic_pool: float

func can_afford(cost: float) -> bool
func consume(cost: float) -> bool
func replenish(amount: float) -> void
func get_movement_cost(cells: int) -> float

signal magic_changed(new_pool: float)
signal magic_depleted()
signal magic_replenished(amount: float)
```

---

### Feature Layer APIs

#### FacilityController

```gdscript
class_name FacilityController extends Node2D

var facility_id: int
var facility_type: int
var state: FacilityState        # NORMAL, DAMAGED, DISABLED
var contents: Dictionary        # {resource_id: count}

func create_facility(grid_pos: Vector2i, facility_type: int) -> bool
func interact(action: InteractionAction) -> InteractionResult
func deposit_item(resource_id: int, count: int) -> bool
func withdraw_item(resource_id: int, count: int) -> bool
func craft_item(recipe_id: int) -> CraftResult

signal facility_created(facility_id: int, position: Vector2i)
signal facility_state_changed(facility_id: int, new_state: FacilityState)
signal storage_changed(facility_id: int, resource_id: int, new_count: int)
signal facility_demolished(facility_id: int)
```

#### BuildValidator

```gdscript
class_name BuildValidator extends Node

func validate_placement(
    grid_pos: Vector2i,
    block_type_id: int,
    placer_entity: Node2D
) -> ValidationResult
    # Returns: {valid, reason, collision_entities}

func check_terrain_support(grid_pos: Vector2i, block_type_id: int) -> bool
func get_entities_at_position(grid_pos: Vector2i) -> Array[Node2D]

signal validation_passed(grid_pos: Vector2i, block_type_id: int)
signal validation_failed(grid_pos: Vector2i, block_type_id: int, reason: String)
```

---

## ADR Audit

### Existing ADRs

| ADR | Status | Engine Compat | GDD Linkage |
|-----|--------|---------------|-------------|
| **None** | ❌ No ADRs exist | ❌ | ❌ |

### Technical Requirements Coverage

| Metric | Count |
|--------|-------|
| Total Requirements | 72 |
| Covered by ADRs | 0 |
| GAPs | 72 |

---

## Required ADRs

### Must Create Before Coding (Foundation & Core)

| # | ADR Title | Priority | Engine Risk |
|---|-----------|----------|-------------|
| ADR-001 | TileMap System Architecture | BLOCKING | ⚠️ HIGH |
| ADR-002 | Database Loading Strategy | BLOCKING | LOW |
| ADR-003 | Input System Architecture | BLOCKING | ⚠️ HIGH |
| ADR-004 | Time System Architecture | BLOCKING | LOW |
| ADR-005 | Event Bus vs Direct Signal Architecture | BLOCKING | LOW |
| ADR-006 | Collision System Architecture | BLOCKING | MEDIUM |
| ADR-007 | Vehicle State Machine Architecture | BLOCKING | LOW |
| ADR-008 | Movement and Physics Integration | BLOCKING | LOW |
| ADR-009 | Magic Pool Management Architecture | BLOCKING | LOW |
| ADR-010 | Enemy AI Architecture | BLOCKING | ⚠️ HIGH |
| ADR-011 | Combat System Architecture | BLOCKING | LOW |
| ADR-012 | Spawn System Architecture | BLOCKING | LOW |

### Should Create Before Feature Layer

| # | ADR Title | Priority | Engine Risk |
|---|-----------|----------|-------------|
| ADR-013 | Build System Architecture | HIGH | LOW |
| ADR-014 | Facility System Architecture | HIGH | LOW |
| ADR-015 | Resource Drop and Pickup Architecture | HIGH | LOW |
| ADR-016 | Exploration Area Architecture | HIGH | LOW |

### Can Defer to Implementation

| # | ADR Title | Priority | Engine Risk |
|---|-----------|----------|-------------|
| ADR-017 | Save/Load Serialization Format | MEDIUM | MEDIUM |
| ADR-018 | Game State Singleton Pattern | MEDIUM | LOW |
| ADR-019 | Day/Night Visual Rendering | MEDIUM | LOW |
| ADR-020 | UI HUD Data Binding Pattern | MEDIUM | LOW |

---

## Architecture Principles

从游戏支柱和技术偏好推导的核心架构原则：

### 1. 战车即生命 (Vehicle as Core Entity)

**原则**: 所有探索系统必须以战车为中心，战车是玩家的唯一化身。

**架构影响**:
- VehicleController 是 Core 层的核心模块
- 所有 Core 系统直接或间接与 VehicleController 交互
- 战车状态变化驱动全局事件（vehicle_damaged, vehicle_destroyed）
- 无下车状态 MVP — 战车始终是玩家控制对象

**验证规则**: 任何 Core 层系统如果需要玩家输入，必须通过 VehicleController 或 InputManager 获取。

---

### 2. 搜打撤节奏 (Scavenge-Retreat Pacing)

**原则**: 时间和撤退系统必须创造紧张决策，不是惩罚而是机会成本。

**架构影响**:
- TimeSystem 是 Foundation 层全局时钟
- RetreatJudge 是 Core 层节奏控制器
- 日夜循环驱动敌人行为变化（DayNightCycle → EnemyAI）
- 撤退阈值是魔能/血量/时间的综合判定

**验证规则**: 任何影响时间的系统必须通过 TimeSystem，禁止直接使用 OS 时间 API。

---

### 3. 尸潮即高潮 (Horde as Climax)

**原则**: 所有防守系统必须有真实压力和后果。

**架构影响**:
- TurretController 和 FacilityController 是防守基础设施
- EnemySpawnManager 控制尸潮规模和节奏
- 防守失败有明确后果梯度（DamageReceiver → VehicleDestroyed）

**验证规则**: 防守系统必须在 Feature 层有明确的失败处理逻辑。

---

### 4. 魔导科技美学 (Magic-Tech Aesthetic)

**原则**: 所有科技系统必须融合赛博朋克魔导风格。

**架构影响**:
- MagicConsumption 是战车动力核心
- 魔能驱动移动、武器、设施
- 资源系统以晶石/秘银为核心（ResourceDB）

**验证规则**: 任何动力/能量系统必须通过 MagicConsumption，禁止使用"燃油"或"电池"等现代能源概念。

---

### 5. 数据驱动设计 (Data-Driven Design)

**原则**: 所有游戏数值必须外部配置，禁止硬编码。

**架构影响**:
- 所有数据库模块（BlockTypeDB, ResourceDB 等）使用 RefCounted，不依赖 Node
- entities.yaml 是唯一常量来源（TK-001 到 TK-048）
- 调整数值只需修改 yaml，无需改代码

**验证规则**: 任何包含游戏数值的代码必须引用 entities.yaml 中的 TK-ID，禁止使用魔法数字。

---

## Open Questions

以下决策在架构文档中标记为"待定"，必须在相关系统编码前解决：

### Foundation Layer Questions

| Question | Affects | Deadline | Risk |
|----------|---------|----------|------|
| TileMapLayer chunk loading strategy: async vs sync? | TileMapWorld | Before Sprint 1 | ⚠️ HIGH |
| Database autoload order: alphabetical vs dependency-based? | All databases | Before Sprint 1 | LOW |
| InputManager dual-focus handling: event queue vs state snapshot? | InputManager | Before Sprint 1 | ⚠️ HIGH |

### Core Layer Questions

| Question | Affects | Deadline | Risk |
|----------|---------|----------|------|
| CollisionManager severity threshold: when to trigger damage? | DamageReceiver | Before Vehicle coding | MEDIUM |
| EnemyAIController navigation: NavigationServer2D vs A* custom? | EnemyAIController | Before Enemy coding | ⚠️ HIGH |
| SpawnManager wave timing: fixed interval vs dynamic? | SpawnManager | Before Enemy coding | LOW |

### Feature Layer Questions

| Question | Affects | Deadline | Risk |
|----------|---------|----------|------|
| FacilityController magic connection: direct link vs proximity check? | FacilityController | Before Facility coding | LOW |
| BuildValidator terrain matrix: pre-computed vs runtime check? | BuildValidator | Before Build coding | LOW |

### Persistence Layer Questions

| Question | Affects | Deadline | Risk |
|----------|---------|----------|------|
| SaveManager serialization: JSON vs binary? | SaveManager | Before Save feature | MEDIUM |
| Save slot count: 1 vs 3 vs unlimited? | SaveManager | Before Save feature | LOW |

---

## Appendix: Constants Reference

所有常量定义在 `design/registry/entities.yaml`，共 147 个：

### World Constants

| ID | Name | Value | Description |
|----|------|-------|-------------|
| — | CELL_SIZE | 32 | 单个方块像素尺寸 |
| — | CHUNK_SIZE | 32 | 单个 chunk 方块数量 (32x32) |

### Physics Constants

| ID | Name | Value | Description |
|----|------|-------|-------------|
| TK-018 | MAX_SWEPT_STEPS | 64 | swept collision 最大步数 |
| TK-019 | SEVERITY_BASE | 100 | 碰撞严重度基准值 |

### Vehicle Constants

| ID | Name | Value | Description |
|----|------|-------|-------------|
| TK-013 | MAGIC_COST_PER_CELL | 0.5 | 每格移动魔能消耗 |
| TK-014 | MAGIC_DEPLETION_THRESHOLD | 0.1 | 魔能耗尽阈值 (10%) |

### Enemy AI Constants

| ID | Name | Value | Description |
|----|------|-------|-------------|
| TK-064 | SEPARATION_FORCE | 0.3 | Boids 分离力强度 |

### Facility Constants

| ID | Name | Value | Description |
|----|------|-------|-------------|
| TK-032 | STORAGE_CAPACITY | 100 | 储物箱格子数量 |
| TK-048 | DEMOLITION_REFUND_RATE | 0.5 | 拆除返还率 (50%) |

---

## Document History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2026-04-24 | create-architecture skill | Initial architecture document |

---

## Next Steps

1. **Run these ADRs next** (按顺序):
   - `/architecture-decision Event Bus vs Direct Signal Architecture` (ADR-005)
   - `/architecture-decision TileMap System Architecture` (ADR-001) ⚠️ HIGH RISK
   - `/architecture-decision Database Loading Strategy` (ADR-002)

2. **Gate check**: Run `/gate-check pre-production` when all required ADRs (ADR-001 to ADR-012) are written.

3. **Update TR Registry**: Populate `docs/architecture/tr-registry.yaml` with the 72 technical requirements extracted in Phase 5.

4. **Update session state**: Write summary to `production/session-state/active.md`.