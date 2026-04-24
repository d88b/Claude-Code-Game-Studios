# ADR-005: Event Bus vs Direct Signal Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

所有 Core/Feature 层模块需要跨场景通信。决定使用 GlobalSignals autoload 作为全局事件总线，局部场景内使用直接 Godot Signal。这解决了模块间松耦合问题，避免单例依赖和循环引用。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Signal system) |
| **Knowledge Risk** | LOW — Signal API stable since Godot 3.x, unchanged in 4.x |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` (Signal unchanged) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — Signal API is stable |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (Foundation layer) |
| **Enables** | ADR-001, ADR-003, ADR-004, all Core/Feature ADRs |
| **Blocks** | All Core layer implementation until Accepted |
| **Ordering Note** | Must be first ADR created — all other modules depend on communication pattern |

## Context

### Problem Statement

26 MVP 系统分布在 Foundation/Core/Feature 三层。模块间需要通信：
- VehicleController 需通知 CollisionManager velocity 变化
- DamageReceiver 需通知 UI health 变化
- SpawnManager 需通知 AreaManager 敌人生成
- 时间系统需驱动日夜循环、敌人生成、撤退判定

如何实现跨模块通信而不引入紧耦合？

### Current State

无现有架构。每个系统独立 GDD 设计，通信方式未统一。

### Constraints

- Godot Signal 系统是原生通信机制，必须使用
- 跨场景通信不能用直接 Signal（Autoload vs Scene node）
- 避免 God Object（单一 GlobalSignals 处理所有事件）
- 性能：Signal dispatch 必须在 frame budget 内

### Requirements

- 松耦合：模块不直接引用其他模块类名
- 类型安全：Signal 参数类型明确
- 可追溯：事件流可从架构文档追溯
- 性能：每帧最多 50 个 signal dispatch（估算）

## Decision

**双层 Signal 架构**：
- **全局事件总线**：GlobalSignals autoload 处理跨场景/跨模块事件
- **直接 Signal**：同一场景内的模块间直接 Signal 连接

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         SIGNAL ARCHITECTURE                                  │
└─────────────────────────────────────────────────────────────────────────────┘

                    ┌─────────────────────────────┐
                    │   GlobalSignals (Autoload)  │
                    │   — Global Event Bus        │
                    └─────────────────────────────┘
                                 │
        ┌────────────────────────┼────────────────────────────┐
        │                        │                            │
        ▼                        ▼                            ▼
┌───────────────┐        ┌───────────────┐            ┌───────────────┐
│ VehicleController│        │ TimeSystem    │            │ SpawnManager  │
│ (Scene node)   │        │ (Autoload)    │            │ (Scene node)  │
│                │        │               │            │               │
│ Direct Signals:│        │ Direct Signal:│            │ Direct Signal:│
│ velocity_changed│        │ hour_changed  │            │ enemy_spawned │
│ ───────────────│        │ (internal)    │            │ (internal)    │
│                │        │               │            │               │
│ Emits Global:  │        │ Emits Global: │            │ Emits Global: │
│ vehicle_deployed│        │ time_hour_changed│          │ enemy_killed  │
│ vehicle_damaged │        │ day_phase_changed│          │               │
│ vehicle_destroyed│        │               │            │               │
└────────────────┘        └───────────────┘            └───────────────┘
        │                        │                            │
        │                        │                            │
        ▼                        ▼                            ▼
┌───────────────┐        ┌───────────────┐            ┌───────────────┐
│ CollisionManager│        │ DayNightCycle │            │ AreaManager   │
│ (Scene node)   │        │ (Scene node)  │            │ (Scene node)  │
│                │        │               │            │               │
│ Subscribes:    │        │ Subscribes:   │            │ Subscribes:   │
│ velocity_changed│        │ time_hour_changed│          │ area_entered  │
│ (Direct)       │        │ (Global)      │            │ (Global)      │
└────────────────┘        └───────────────┘            └───────────────┘

Signal Flow Rules:
────────────────────────────────────────────────────────────────────────────
1. Autoload → Autoload:     Direct Signal (both are global singletons)
2. Autoload → Scene:        GlobalSignal emit (global to local)
3. Scene → Autoload:        GlobalSignal emit (local to global)
4. Scene → Scene (same):    Direct Signal (same scene tree)
5. Scene → Scene (cross):   GlobalSignal emit (cross-scene requires bus)
────────────────────────────────────────────────────────────────────────────
```

### Key Interfaces

```gdscript
# GlobalSignals — Event Bus (Autoload)
# File: src/foundation/global_signals.gd

extends Node

class_name GlobalSignals

# === Time Events ===
signal time_hour_changed(hour: int)           # TimeSystem → DayNightCycle, SpawnManager
signal day_phase_changed(phase: DayPhase)     # TimeSystem → DayNightCycle, RetreatJudge
signal day_started()                          # TimeSystem → All systems
signal night_started()                        # TimeSystem → SpawnManager, RetreatJudge

# === Vehicle Events ===
signal vehicle_deployed(vehicle_id: int)      # VehicleController → UI, SpawnManager
signal vehicle_damaged(amount: float)         # DamageReceiver → UI, RetreatJudge
signal vehicle_destroyed(vehicle_id: int)     # DamageReceiver → UI, SpawnManager, RetreatJudge
signal vehicle_repaired(amount: float)        # DamageReceiver → UI

# === Enemy Events ===
signal enemy_spawned(enemy_id: int, area_id: int)  # SpawnManager → UI, AreaManager
signal enemy_killed(enemy_id: int)                  # EnemyAIController → DropManager, UI

# === Block Events ===
signal block_dug(grid_pos: Vector2i, block_id: int)    # DigController → TileMapWorld, DropManager
signal block_placed(grid_pos: Vector2i, block_id: int) # PlaceController → TileMapWorld, BuildValidator

# === Item Events ===
signal item_collected(resource_id: int, count: int)    # DropManager → VehicleAttribute, UI
signal item_consumed(resource_id: int, count: int)     # MagicConsumption, WeaponController → UI

# === Facility Events ===
signal facility_created(facility_id: int, grid_pos: Vector2i)  # FacilityController → TileMapWorld, UI
signal facility_destroyed(facility_id: int)                     # FacilityController → DropManager, UI
signal storage_changed(facility_id: int, resource_id: int, count: int)  # FacilityController → UI

# === Area Events ===
signal area_entered(area_id: int)            # AreaManager → SpawnManager, UI
signal area_exited(area_id: int)             # AreaManager → UI

# === Retreat Events ===
signal retreat_threshold_reached(reason: RetreatReason)  # RetreatJudge → UI
signal retreat_warning_escalated(level: int)              # RetreatJudge → UI

# === Game State Events ===
signal game_loaded()                         # SaveManager → All systems
signal game_saved()                          # SaveManager → UI
signal game_ready()                          # Main scene → All systems


# Direct Signal Examples (Scene-internal):
────────────────────────────────────────────────────────────────────────────

# VehicleController (Scene node)
signal velocity_changed(new_velocity: Vector2)   # → CollisionManager (same scene)
signal position_changed(new_pos: Vector2)        # → AreaManager (same scene)

# WeaponController (Scene node)
signal weapon_fired(projectile_id: int, pos: Vector2, dir: Vector2)  # → MagicConsumption

# EnemyAIController (Scene node)
signal state_changed(new_state: EnemyState)     # → EnemyTypeDB lookup
signal target_acquired(target: Node2D)          # → WeaponController
signal killed()                                  # → SpawnManager cleanup

# TurretController (Scene node)
signal target_acquired(target: Node2D)          # → WeaponController
signal ammo_depleted()                          # → FacilityController (storage link)
```

### Implementation Guidelines

1. **GlobalSignals 文件位置**: `src/foundation/global_signals.gd`
2. **Autoload 注册**: `project.godot` 中添加 `GlobalSignals` as `global_signals`
3. **命名约定**: Signal 名称使用 snake_case 过去式或状态变化（`vehicle_damaged`, `time_hour_changed`）
4. **类型标注**: 所有 Signal 参数必须有类型标注
5. **订阅位置**: 模块在 `_ready()` 中订阅 GlobalSignals，在 `_exit_tree()` 中断开连接
6. **发射位置**: 状态变化后立即 emit，不要延迟到帧末

```gdscript
# Example: DamageReceiver subscribing to GlobalSignals
class_name DamageReceiver extends Node

func _ready() -> void:
    GlobalSignals.vehicle_damaged.connect(_on_vehicle_damaged)

func _exit_tree() -> void:
    GlobalSignals.vehicle_damaged.disconnect(_on_vehicle_damaged)

func _on_vehicle_damaged(amount: float) -> void:
    current_health -= amount
    health_changed.emit(current_health)  # Direct signal to UI (same scene)
    if current_health <= 0:
        GlobalSignals.vehicle_destroyed.emit(vehicle_id)  # Global to UI, SpawnManager
```

## Alternatives Considered

### Alternative 1: All Direct Signals (No Event Bus)

- **Description**: 模块间全部使用直接 Signal，跨场景通过场景树查找
- **Pros**: 无额外 Autoload，更接近 Godot 原生模式
- **Cons**: 跨场景查找节点复杂（`get_tree().get_first_node_in_group()`），紧耦合，难以重构
- **Estimated Effort**: 相同
- **Rejection Reason**: 跨场景节点查找不可靠，破坏模块边界

### Alternative 2: Callback Function References

- **Description**: 模块注册回调函数到中央 Registry
- **Pros**: 更灵活（可传递 lambda）
- **Cons**: 非 Godot 原生模式，调试困难，无类型安全
- **Estimated Effort**: 更高（需自定义 Registry）
- **Rejection Reason**: Godot Signal 是标准模式，不要发明新机制

### Alternative 3: Multiple Event Buses (Domain-split)

- **Description**: 拆分 GlobalSignals 为 TimeSignals, VehicleSignals, CombatSignals 等
- **Pros**: 更好的组织，减少 God Object 风险
- **Cons**: 多个 Autoload 增加复杂度，跨域事件需选择归属
- **Estimated Effort**: 更高
- **Rejection Reason**: MVP 阶段事件数量可控（~20 signals），不需要拆分。Alpha 阶段可考虑重构。

## Consequences

### Positive

- 松耦合：模块不直接引用其他模块类名，只依赖 Signal 契约
- 可追溯：架构文档明确列出所有全局 Signal
- 易重构：Signal 契约不变，发射/订阅方可独立修改
- 调试友好：Godot Debugger 可追踪 Signal 连接

### Negative

- GlobalSignals 是 God Object 风险点：如果事件数量超过 50，应拆分
- Signal 连接生命周期管理需谨慎（`disconnect` 在 `_exit_tree`）
- 跨 Scene 通信仍需 Autoload，无法完全避免全局单例

### Neutral

- 这是 Godot 项目标准模式，无特殊创新

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| GlobalSignals 变成 God Object | Low (MVP) | Medium | Alpha 阶段评估拆分 |
| Signal 连接泄漏（未 disconnect） | Medium | Low | 代码审查检查 `_exit_tree` |
| Signal 参数类型不匹配 | Low | Low | GDScript 静态类型检查 |
| 过多 Signal dispatch 影响性能 | Low | Low | 每帧估算 <50 dispatch，在预算内 |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (Signal dispatch) | 0 | <0.1ms/frame | 16.6ms/frame |
| Memory (GlobalSignals) | 0 | <1KB | 512MB ceiling |

Signal dispatch 是 O(1) 操作，每个 Signal 连接约 100 bytes。20 个全局 Signal + 100 个订阅连接 ≈ 10KB。

## Migration Plan

新架构，无迁移。

**Rollback plan**: 如果 GlobalSignals 证明有问题，可重构为 Alternative 3（Domain-split buses）。

## Validation Criteria

- [ ] GlobalSignals autoload 已注册
- [ ] 所有全局 Signal 已定义且有类型标注
- [ ] DamageReceiver, SpawnManager, RetreatJudge 已订阅相关 Signal
- [ ] `_exit_tree` 中所有连接已断开
- [ ] 无循环 Signal 依赖（A emit → B receive → B emit → A receive）

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/vehicle-damage-system.md` | VehicleDamage | Damage events must trigger UI updates and retreat warnings | GlobalSignals.vehicle_damaged, vehicle_destroyed |
| `design/gdd/time-system.md` | TimeSystem | Time changes must drive day/night cycle and enemy spawning | GlobalSignals.time_hour_changed, day_phase_changed |
| `design/gdd/enemy-spawn-system.md` | EnemySpawn | Spawned enemies must be tracked by area manager | GlobalSignals.enemy_spawned |
| `design/gdd/retreat-judgment-system.md` | RetreatJudge | Retreat warnings must trigger UI without coupling | GlobalSignals.retreat_threshold_reached |
| `design/gdd/block-digging-system.md` | BlockDigging | Dig events must trigger drop spawning | GlobalSignals.block_dug |
| `design/gdd/block-placing-system.md` | BlockPlacing | Placement must trigger TileMapWorld update | GlobalSignals.block_placed |

> **Foundational Enablement**: This ADR enables all Core/Feature layer systems to communicate without tight coupling. No single GDD requirement mandates this pattern, but all cross-module requirements implicitly depend on it.

## Related

- ADR-001: TileMap System Architecture — subscribes to block_dug, block_placed
- ADR-003: Input System Architecture — uses Direct Signals for action_changed
- ADR-007: Vehicle State Machine Architecture — emits vehicle_deployed, vehicle_destroyed
- ADR-010: Enemy AI Architecture — emits enemy_killed, subscribes to area_entered
- ADR-016: Exploration Area Architecture — emits area_entered, area_exited