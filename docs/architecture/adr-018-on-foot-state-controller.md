# ADR-018: On-Foot State Controller Architecture

## Status

Proposed

## Date

2026-04-25

## Decision Makers

architecture-decision skill

## Summary

下车状态系统采用 3 状态机（IN_VEHICLE ↔ ON_FOOT ↔ DEAD）管理玩家脱离战车后的行为。状态转换由输入动作（disembark/embark）和战车状态信号（DISABLED/DESTROYED）驱动。系统验证上车条件（距离、战车状态），发射 GlobalSignals 供下游消费。步行速度为战车速度的 30%。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (State Machine) |
| **Knowledge Risk** | LOW — State machine pattern standard per ADR-007 precedent, no engine API dependency |
| **References Consulted** | ADR-007 (State Machine pattern), ADR-003 (Input System), ADR-005 (GlobalSignals) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test state transitions: disembark input → ON_FOOT, embark input → IN_VEHICLE |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-003 (Input System — Accepted), ADR-005 (GlobalSignals — Accepted), ADR-007 (State Machine pattern — Accepted), Vehicle Attribute System (#17 — Designed) |
| **Enables** | Retreat Consequence (#33), Scavenge Interaction (#31), Retreat Judgment (#32) |
| **Blocks** | On-foot gameplay, walk-back flow, player death handling |
| **Ordering Note** | Feature layer — after Input and Vehicle State Machine, before Scavenge |

## Context

### Problem Statement

玩家可以脱离战车进行近距离活动（搜刮、维修、紧急撤离）。核心问题：
1. 如何定义玩家的三种状态（在车内、徒步、死亡）？
2. 如何处理主动下车、被迫下车、紧急撤离三种触发方式？
3. 如何验证上车条件（距离、战车状态）？
4. 如何发射信号供下游系统（搜刮、撤退判定、后果）消费？

### Requirements

From `on-foot-state-system.md`:

- 3-state machine: IN_VEHICLE, ON_FOOT, DEAD
- Transition triggers: disembark input, vehicle DISABLED/DESTROYED, embark input, player death
- Embark conditions: distance ≤ 2 tiles, vehicle state ≠ DESTROYED, no obstacles
- Walk speed: vehicle_base_speed × ON_FOOT_SPEED_RATIO (0.30)
- Signal interfaces: player_dismounted, player_remounted, player_died
- Data tracking: disembark_time, last_vehicle_position

## Decision

**3-State Machine with Input Integration + Embark Condition Validation**：

### State Machine Architecture

```
State Machine:
IN_VEHICLE ──[disembark input]──> ON_FOOT
IN_VEHICLE ──[vehicle DISABLED]──> ON_FOOT (forced dismount)
IN_VEHICLE ──[vehicle DESTROYED]──> ON_FOOT (emergency evacuation)
ON_FOOT ──[embark input + conditions met]──> IN_VEHICLE
ON_FOOT ──[player HP <= 0]──> DEAD
DEAD ──[respawn/recovery complete]──> IN_VEHICLE (new state)

State Definitions:
IN_VEHICLE:  玩家在战车内，战车驾驶模式，背包锁定
ON_FOOT:     玩家徒步，可搜刮/维修，背包可访问，步行速度 = 30% 战车速度
DEAD:        玩家死亡，背包丢失，触发撤退后果

Embark Conditions (must ALL be true):
1. distance_to_vehicle <= EMBARK_DISTANCE (2 tiles)
2. vehicle_state != DESTROYED
3. no obstacles blocking path
4. player input "embark" action
```

### Key Interfaces

```gdscript
# === GlobalSignals 新增事件 ===
# File: src/foundation/global_signals.gd (extends ADR-005)

# === Player State Events ===
signal player_dismounted(reason: DismountReason, vehicle_position: Vector2i)  # From OnFootController
signal player_remounted()  # From OnFootController
signal player_died(last_position: Vector2i, backpack_contents: Dictionary)  # From OnFootController
signal player_state_changed(new_state: PlayerState)  # From OnFootController

# === Enums ===
enum PlayerState {
    IN_VEHICLE,  # 在战车内
    ON_FOOT,     # 下车状态
    DEAD         # 死亡
}

enum DismountReason {
    VOLUNTARY,       # 主动下车
    FORCED_DISABLED, # 被迫下车
    EMERGENCY_DESTROYED  # 紧急撤离
}

# === OnFootController ===
class_name OnFootController extends Node

var current_state: PlayerState = PlayerState.IN_VEHICLE
var disembark_time: float = 0.0  # 游戏时间戳（用于撤退超时计算）
var last_vehicle_position: Vector2i = Vector2i.ZERO
var last_vehicle_state: VehicleState = VehicleState.DEPLOYED
var player_entity: CharacterBody2D  # 徒步时的玩家实体

# Tuning Knobs (from GDD #30)
const EMBARK_DISTANCE: float = 2.0  # tiles
const ON_FOOT_SPEED_RATIO: float = 0.30  # 步行速度比例
const DISMOUNT_OFFSET: float = 1.0  # tiles (下车侧方向偏移)

func _ready() -> void:
    # Subscribe to input actions
    InputManager.subscribe_action(&"disembark", _on_disembark_action)
    InputManager.subscribe_action(&"embark", _on_embark_action)
    
    # Subscribe to vehicle state changes
    GlobalSignals.vehicle_state_changed.connect(_on_vehicle_state_changed)
    
    # Subscribe to walk_back_triggered from RetreatConsequence
    GlobalSignals.walk_back_triggered.connect(_on_walk_back_triggered)

func transition_to(new_state: PlayerState, reason: DismountReason = DismountReason.VOLUNTARY) -> void:
    if not _is_valid_transition(current_state, new_state):
        return
    
    var previous_state = current_state
    current_state = new_state
    
    match new_state:
        PlayerState.ON_FOOT:
            _handle_dismount(reason)
            GlobalSignals.player_dismounted.emit(reason, last_vehicle_position)
        
        PlayerState.IN_VEHICLE:
            _handle_remount()
            GlobalSignals.player_remounted.emit()
        
        PlayerState.DEAD:
            _handle_death()
            GlobalSignals.player_died.emit(player_entity.position, _get_backpack_contents())
    
    GlobalSignals.player_state_changed.emit(new_state)

func _is_valid_transition(from: PlayerState, to: PlayerState) -> bool:
    var valid_transitions = {
        PlayerState.IN_VEHICLE: [PlayerState.ON_FOOT],
        PlayerState.ON_FOOT: [PlayerState.IN_VEHICLE, PlayerState.DEAD],
        PlayerState.DEAD: [PlayerState.IN_VEHICLE]  # Respawn
    }
    return to in valid_transitions.get(from, [])

func _handle_dismount(reason: DismountReason) -> void:
    # Record dismount data
    disembark_time = TimeSystem.get_game_time()
    last_vehicle_position = VehicleAttribute.get_vehicle_position()
    last_vehicle_state = VehicleAttribute.get_vehicle_state()
    
    # Create player entity at dismount position
    var dismount_pos = _calculate_dismount_position()
    player_entity = _spawn_player_entity(dismount_pos)
    
    # Unlock backpack (from Player Backpack System #28)
    GlobalSignals.backpack_unlocked.emit()
    
    # Pause vehicle (engine off, weapons disabled)
    GlobalSignals.vehicle_paused.emit()

func _handle_remount() -> void:
    # Destroy player entity
    if player_entity:
        player_entity.queue_free()
        player_entity = null
    
    # Clear dismount data
    disembark_time = 0.0
    last_vehicle_position = Vector2i.ZERO
    
    # Lock backpack
    GlobalSignals.backpack_locked.emit()
    
    # Resume vehicle
    GlobalSignals.vehicle_resumed.emit()

func _handle_death() -> void:
    # Backpack contents lost (from Player Backpack System #28)
    GlobalSignals.backpack_lost.emit()
    
    # Trigger retreat consequence
    # RetreatConsequence will handle failure_count += 1

func _check_embark_conditions() -> bool:
    if current_state != PlayerState.ON_FOOT:
        return false
    
    # Condition 1: Distance check
    var distance = _get_distance_to_vehicle()
    if distance > EMBARK_DISTANCE:
        return false
    
    # Condition 2: Vehicle state check
    if VehicleAttribute.get_vehicle_state() == VehicleState.DESTROYED:
        return false
    
    # Condition 3: Obstacle check (raycast to vehicle)
    if _has_obstacle_blocking():
        return false
    
    return true

func _get_walk_speed() -> float:
    # Formula 2 from GDD #30
    var vehicle_base_speed = VehicleAttribute.get_base_speed()
    return vehicle_base_speed * ON_FOOT_SPEED_RATIO

func _on_disembark_action(pressed: bool) -> void:
    if pressed and current_state == PlayerState.IN_VEHICLE:
        if VehicleAttribute.get_vehicle_state() == VehicleState.DEPLOYED:
            transition_to(PlayerState.ON_FOOT, DismountReason.VOLUNTARY)

func _on_embark_action(pressed: bool) -> void:
    if pressed and current_state == PlayerState.ON_FOOT:
        if _check_embark_conditions():
            transition_to(PlayerState.IN_VEHICLE)

func _on_vehicle_state_changed(instance_id: int, new_state: VehicleState) -> void:
    if current_state != PlayerState.IN_VEHICLE:
        return
    
    match new_state:
        VehicleState.DISABLED:
            transition_to(PlayerState.ON_FOOT, DismountReason.FORCED_DISABLED)
        VehicleState.DESTROYED:
            transition_to(PlayerState.ON_FOOT, DismountReason.EMERGENCY_DESTROYED)

func _on_walk_back_triggered(vehicle_position: Vector2i, vehicle_state: VehicleState) -> void:
    # From RetreatConsequence (ADR-017)
    if current_state == PlayerState.IN_VEHICLE:
        match vehicle_state:
            VehicleState.DISABLED:
                transition_to(PlayerState.ON_FOOT, DismountReason.FORCED_DISABLED)
            VehicleState.DESTROYED:
                transition_to(PlayerState.ON_FOOT, DismountReason.EMERGENCY_DESTROYED)
```

## Alternatives Considered

### Alternative 1: Direct Player Node Control

- **Description**: Player entity始终存在，只是显隐切换
- **Pros**: 无需 spawn/destroy player entity
- **Cons**: 状态管理复杂（隐藏时仍需暂停），资源浪费
- **Rejection Reason**: IN_VEHICLE 时玩家实体不应存在（绑定到战车），ON_FOOT 时才创建

### Alternative 2: Separate Dismount and Remount Controllers

- **Description**: 拆分下车和上车为两个独立控制器
- **Pros**: 模块更小，职责分离
- **Cons**: 状态共享复杂，两个控制器需要同步
- **Rejection Reason**: 下车和上车是同一状态机的转换，拆分增加耦合

## Consequences

### Positive
- 3-state machine 清晰表达玩家状态
- Embark conditions 验证确保上车逻辑正确
- Signal interfaces 供下游系统消费（搜刮、撤退）
- ON_FOOT_SPEED_RATIO = 0.30 强化脆弱感

### Negative
- Player entity spawn/destroy 有轻微开销
- Input integration 需要与 InputManager 协调

### Risks
- Embark conditions 验证可能有边缘情况（障碍检测）
- Player entity spawn 位置可能卡墙（需测试 dismount_offset）

## GDD Requirements Addressed

| GDD | Requirement | How This ADR Satisfies It |
|-----|-------------|--------------------------|
| `on-foot-state-system.md` Rule 1 | PlayerState enum | 3-state enum defined |
| `on-foot-state-system.md` Rule 2 | Dismount triggers | disembark input, DISABLED, DESTROYED handlers |
| `on-foot-state-system.md` Rule 3 | Dismount data sync | disembark_time, last_vehicle_position recorded |
| `on-foot-state-system.md` Rule 4 | ON_FOOT capabilities | Walk speed, backpack unlock |
| `on-foot-state-system.md` Rule 5 | Activity range | No hard limit, risk mechanism |
| `on-foot-state-system.md` Rule 6 | Embark conditions | Distance, state, obstacle checks |
| `on-foot-state-system.md` Rule 7 | Remount data sync | Backpack lock, vehicle resume |
| `on-foot-state-system.md` Rule 8 | Death handling | DEAD state, backpack lost signal |
| `on-foot-state-system.md` States | State transitions table | `_is_valid_transition()` implementation |
| `on-foot-state-system.md` Formulas 1-5 | Embark distance, walk speed, dismount time, distance calc, offset | All formulas implemented |

## Performance Implications

| Metric | Impact |
|--------|--------|
| CPU (embark check) | <0.02ms/frame (distance + state + obstacle) |
| CPU (spawn player) | ~1ms (once per dismount) |
| Memory (player entity) | ~500 bytes |

State transition is O(1), embark check is O(1) + one raycast.

## Migration Plan

New system — no migration.

## Validation Criteria

- [ ] OnFootController implemented with 3-state machine
- [ ] GlobalSignals extended with player state events
- [ ] InputManager integration for disembark/embark actions
- [ ] Embark conditions: distance ≤ 2 tiles verified
- [ ] Embark conditions: vehicle DESTROYED blocks verified
- [ ] Walk speed = 30% vehicle speed verified
- [ ] player_dismounted signal emitted on dismount
- [ ] player_remounted signal emitted on remount
- [ ] player_died signal emitted on death
- [ ] walk_back_triggered from RetreatConsequence triggers dismount

## Related

- ADR-003: Input System — disembark/embark action integration
- ADR-005: GlobalSignals — player state events
- ADR-007: Vehicle State Machine pattern precedent
- ADR-017: Retreat Consequence — walk_back_triggered signal
- on-foot-state-system.md: Full GDD specification