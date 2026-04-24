# ADR-008: Movement and Physics Integration

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

战车移动使用 VehicleController (CharacterBody2D)，每帧从 InputManager 读取 joystick_direction，计算 target_velocity = acceleration_rate * input * delta，clamp 到 max_speed。CollisionManager 检测碰撞后修正 velocity。魔能消耗每 cell 消耗 MAGIC_COST_PER_CELL。这整合输入、物理、碰撞、魔能四大系统。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Physics (CharacterBody2D, Movement) |
| **Knowledge Risk** | LOW — CharacterBody2D stable since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/modules/physics.md` (CharacterBody2D unchanged) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test movement feel: acceleration, deceleration, collision response |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-003 (Input), ADR-006 (Collision), ADR-009 (Magic), ADR-007 (Vehicle Attribute) |
| **Enables** | Game loop (vehicle movement core) |
| **Blocks** | All vehicle-based gameplay until Accepted |
| **Ordering Note** | Core layer — integrates Input, Collision, Magic, Attribute |

## Context

### Problem Statement

战车驾驶是核心玩法：
- WASD/joystick 控制方向
- acceleration/deceleration 需要重量感
- 碰撞需要修正 velocity
- 移动消耗魔能（MAGIC_COST_PER_CELL）
- 速度 clamp 到 max_speed

如何整合四大系统实现流畅移动？

### Current State

GDD `design/gdd/vehicle-driving-system.md` 定义了加速度公式和魔能消耗，但未明确与 Collision 和 Input 的集成。

### Constraints

- CharacterBody2D 是物理 node
- 每帧更新：delta time based
- InputManager 提供 joystick_direction
- CollisionManager 提供 swept_collision_check
- MagicConsumption 提供 consume()
- 帧预算 <2ms for movement logic

### Requirements

- Acceleration: velocity += acceleration_rate * input * delta
- Speed clamp: |velocity| <= max_speed
- Collision correction: CollisionManager modifies velocity
- Magic cost: cells moved * MAGIC_COST_PER_CELL
- Deceleration: 无输入时 velocity 逐渐衰减

## Decision

**Integrated Movement Loop in VehicleController**：
- VehicleController._physics_process() 是主循环
- Input → target_velocity → Collision check → Magic consume → Apply velocity

### Architecture

```
VehicleController._physics_process(delta):
│
├─── 1. Read Input:
│    input_direction = InputManager.get_joystick_direction()
│    # Vector2(-1.0 to 1.0)
│
├─── 2. Compute Target Velocity:
│    target_velocity = velocity + acceleration_rate * input_direction * delta
│    # acceleration_rate from VehicleTypeDB.get_vehicle_stats(vehicle_id).acceleration_rate
│    # Formula from GDD vehicle-driving-system.md
│
├─── 3. Clamp Speed:
│    if target_velocity.length() > max_speed:
│        target_velocity = target_velocity.normalized() * max_speed
│    # max_speed from VehicleTypeDB.get_vehicle_stats(vehicle_id).max_speed
│
├─── 4. Collision Check:
│    collision_result = CollisionManager.swept_collision_check(
│        position, target_velocity, get_vehicle_bounds(), MAX_SWEPT_STEPS)
│    # Uses ADR-006 Collision System
│
├─── 5. Apply Collision Correction:
│    if collision_result.hit:
│        velocity = collision_result.remaining_velocity * 0.5  # Bounce
│        position = collision_result.hit_position
│        if collision_result.severity > DAMAGE_THRESHOLD:
│            DamageReceiver.pending_damage = collision_result.severity
│    else:
│        velocity = target_velocity
│
├─── 6. Calculate Magic Cost:
│    cells_moved = velocity.length() * delta / CELL_SIZE
│    magic_cost = cells_moved * MAGIC_COST_PER_CELL  # 0.5 from TK-013
│    if MagicConsumption.can_afford(magic_cost):
│        MagicConsumption.consume(magic_cost)
│    else:
│        # Magic depleted — slowdown
│        velocity *= 0.5  # Half speed when magic depleted
│        GlobalSignals.magic_depleted.emit()
│
├─── 7. Apply Movement:
│    position += velocity * delta
│    # Or use CharacterBody2D.set_velocity() + move_and_slide() if preferred
│
└─── 8. Emit Events:
│    GlobalSignals.velocity_changed.emit(velocity)
│    GlobalSignals.position_changed.emit(position)
│    if velocity != previous_velocity:
│        orientation = velocity.angle()  # Facing direction
│        GlobalSignals.orientation_changed.emit(orientation)
```

### Key Interfaces

```gdscript
# VehicleController._physics_process Implementation
func _physics_process(delta: float) -> void:
    # 1. Read Input
    var input_dir = InputManager.get_joystick_direction()

    # 2. Compute Target Velocity
    var accel_rate = VehicleTypeDB.get_vehicle_stats(current_vehicle_id).acceleration_rate
    var target_vel = velocity + accel_rate * input_dir * delta

    # 3. Clamp Speed
    var max_spd = VehicleTypeDB.get_vehicle_stats(current_vehicle_id).max_speed
    if target_vel.length() > max_spd:
        target_vel = target_vel.normalized() * max_spd

    # 4. Collision Check
    var collision = CollisionManager.swept_collision_check(
        position, target_vel, get_vehicle_bounds())

    # 5. Apply Collision
    if collision.hit:
        velocity = collision.remaining_velocity * 0.5
        if collision.severity > CollisionManager.DAMAGE_THRESHOLD:
            DamageReceiver.take_collision_damage(collision.severity)
    else:
        velocity = target_vel

    # 6. Magic Cost
    var cells = velocity.length() * delta / TileMapWorld.CELL_SIZE
    var cost = cells * GameConfig.MAGIC_COST_PER_CELL  # TK-013 = 0.5
    if MagicConsumption.can_afford(cost):
        MagicConsumption.consume(cost)
    else:
        velocity *= 0.5  # Slowdown

    # 7. Apply Movement
    position += velocity * delta

    # 8. Emit Events
    if velocity != _prev_velocity:
        GlobalSignals.velocity_changed.emit(velocity)
        orientation = velocity.angle()
        GlobalSignals.orientation_changed.emit(orientation)
    _prev_velocity = velocity
```

## Alternatives Considered

### Alternative 1: CharacterBody2D.move_and_slide()

- **Description**: 使用 Godot 内置 move_and_slide()
- **Pros**: 内置 physics integration
- **Cons**: 无法自定义 collision severity，无法精确 magic cost per cell
- **Rejection Reason**: 需要 swept collision 和 severity calculation，ADR-006 决定自定义

### Alternative 2: Fixed Velocity (No Acceleration)

- **Description**: input 直接设置 velocity，无 acceleration curve
- **Pros**: 更简单
- **Cons**: 无重量感，不符合 "战车即生命" pillar
- **Rejection Reason**: GDD 明确要求 acceleration，营造重量感

## Consequences

### Positive

- 整合四大系统（Input, Collision, Magic, Attribute）
- 重量感：acceleration curve 创造战车驾驶感
- 魔能约束：移动消耗魔能，创造资源压力
- 碰撞反馈：severity 触发 damage

### Negative

- 每帧 8 步逻辑，复杂度较高
- 多系统依赖：InputManager, CollisionManager, MagicConsumption, VehicleTypeDB

## Validation Criteria

- [ ] WASD/joystick controls vehicle direction
- [ ] Acceleration curve creates weight feel (test playtest feedback)
- [ ] Speed clamped to max_speed
- [ ] Collision stops vehicle, triggers damage if severe
- [ ] Magic consumed per cell moved (TK-013 = 0.5)
- [ ] Magic depletion slows vehicle to 50% speed

## GDD Requirements Addressed

| GDD | Requirement | How Satisfied |
|-----|-------------|---------------|
| `vehicle-driving-system.md` | Acceleration formula | velocity += acceleration_rate * input * delta |
| `vehicle-driving-system.md` | Speed clamp | target_vel.length() <= max_speed |
| `magic-energy-consumption.md` | MAGIC_COST_PER_CELL = 0.5 | cells * TK-013 |

## Related

- ADR-003: Input System — InputManager.get_joystick_direction()
- ADR-006: Collision System — CollisionManager.swept_collision_check()
- ADR-009: Magic Pool — MagicConsumption.consume()
- ADR-007: Vehicle Attribute — VehicleTypeDB.get_vehicle_stats()