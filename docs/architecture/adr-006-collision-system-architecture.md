# ADR-006: Collision System Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

碰撞系统使用 swept collision algorithm（DDA raycast traversal），最大步数 MAX_SWEPT_STEPS=64。CollisionManager 每帧检测 VehicleController velocity 与 TileMapLayer collision cells，返回 hit result 和 severity。severity 用于 DamageReceiver 计算碰撞伤害。这解决战车高速移动时的穿透问题。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Physics (Collision, CharacterBody2D) |
| **Knowledge Risk** | MEDIUM — CharacterBody2D API stable, but swept collision implementation may differ from training data examples |
| **References Consulted** | `docs/engine-reference/godot/modules/physics.md` (CharacterBody2D stable), `design/gdd/block-collision-system.md` (swept collision formula) |
| **Post-Cutoff APIs Used** | None — CharacterBody2D unchanged |
| **Verification Required** | Test swept collision with high velocity (>10 cells/frame); verify severity calculation matches GDD formula |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-001 (TileMap System), ADR-002 (BlockTypeDB), ADR-005 (Event Bus) |
| **Enables** | ADR-008 (Movement and Physics), DamageReceiver |
| **Blocks** | VehicleController, DamageReceiver until Accepted |
| **Ordering Note** | Core layer — created after Foundation, before Vehicle Movement |

## Context

### Problem Statement

战车高速移动时可能穿透薄墙（tunneling problem）：
- 战车 max_speed 可能 >10 cells/frame（估算）
- 传统 collision check（position-based）会漏掉中间的墙
- 需要 swept collision（velocity-based traversal）
- 碰撞需要计算 severity（伤害触发）

如何实现高性能、准确的 swept collision？

### Current State

GDD `design/gdd/block-collision-system.md` 定义了 swept collision algorithm 和 severity formula，但未明确引擎实现。

### Constraints

- CharacterBody2D 是 Godot physics node（move_and_slide 有内置 collision）
- TileMapLayer collision 是静态 collision shape
- MAX_SWEPT_STEPS=64（entities.yaml TK-018）
- 帧预算 16.6ms，collision check 必须 <1ms
- 2D only，无 3D physics

### Requirements

- Swept collision: 检测 velocity 范围内所有 collision points
- DDA traversal: 精确 raycast 算法
- Severity calculation: velocity.magnitude * friction / SEVERITY_BASE
- Damage threshold: severity > threshold → DamageReceiver.pending_damage
- Performance: MAX_SWEPT_STEPS=64 步内完成

## Decision

**Custom Swept Collision via DDA Raycast**：
- 不使用 CharacterBody2D.move_and_slide()（有 tunneling risk）
- 自定义 DDA (Digital Differential Analyzer) raycast traversal
- 每步检测 TileMapLayer collision cells
- 返回 hit result: {hit, hit_position, remaining_velocity, severity}

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         COLLISION SYSTEM ARCHITECTURE                         │
└─────────────────────────────────────────────────────────────────────────────┘

CollisionManager (Node — part of Vehicle scene)
│
├─── Public Methods:
│    ├─── swept_collision_check(start_pos, velocity, bounds, max_steps) → Result
│    ├─── calculate_severity(velocity, block_friction) → float
│    └─── get_cell_collision_at(grid_pos) → CollisionProfile
│
├─── swept_collision_check Implementation:
│    │
│    ├─── Input: start_pos (Vector2), velocity (Vector2), bounds (Rect2), max_steps (int)
│    │
│    ├─── Algorithm: DDA Raycast Traversal
│    │         step_size = velocity.length() / max_steps
│    │         for i in range(max_steps):
│    │             check_pos = start_pos + velocity.normalized() * (i * step_size)
│    │             grid_pos = check_pos / CELL_SIZE
│    │             block_id = TileMapWorld.get_cell_at_position(grid_pos)
│    │             profile = BlockTypeDB.get_collision_profile(block_id)
│    │             if profile.is_solid:
│    │                 # Collision found!
│    │                 hit_position = check_pos
│    │                 remaining_velocity = velocity - (check_pos - start_pos).normalized() * velocity.length()
│    │                 severity = calculate_severity(velocity, profile.friction)
│    │                 return SweptCollisionResult(hit=true, ...)
│    │
│    ├─── Output: SweptCollisionResult {
│    │         hit: bool,
│    │         hit_position: Vector2,
│    │         hit_block_id: int,
│    │         remaining_velocity: Vector2,
│    │         severity: float
│    │     }
│    │
│    └─── Performance: max_steps=64, each step O(3) operations → <1ms
│
├─── calculate_severity Implementation:
│    │
│    ├─── Formula: severity = velocity.length() * block_friction / SEVERITY_BASE
│    │         SEVERITY_BASE = 100 (from entities.yaml TK-019)
│    │
│    ├─── Returns: float >= 0
│    │         0 = no damage (soft collision)
│    │         1+ = significant collision (trigger damage)
│    │
│    └─── Example: velocity=500, friction=0.5 → severity = 500 * 0.5 / 100 = 2.5
│
└─── Constants:
     ├─── MAX_SWEPT_STEPS: int = 64  # TK-018
     ├─── SEVERITY_BASE: float = 100.0  # TK-019
     ├─── DAMAGE_THRESHOLD: float = 1.0  # severity > 1 → damage


VehicleController Integration:
─────────────────────────────────────────────────────────────────────────────
VehicleController._physics_process(delta):
    │
    ├─── target_velocity = compute_target_velocity()
    │
    ├─── collision_result = CollisionManager.swept_collision_check(
    │         position, target_velocity, get_vehicle_bounds(), MAX_SWEPT_STEPS)
    │
    ├─── if collision_result.hit:
    │         # Apply velocity correction
    │         velocity = collision_result.remaining_velocity * 0.5  # Bounce factor
    │         position = collision_result.hit_position
    │
    │         # Trigger damage if severe
    │         if collision_result.severity > DAMAGE_THRESHOLD:
    │             DamageReceiver.pending_damage = collision_result.severity
    │             GlobalSignals.vehicle_damaged.emit(collision_result.severity)
    │
    │         GlobalSignals.collision_blocked.emit(position, collision_result.hit_block_id)
    │
    └─── else:
         # No collision, apply full velocity
         velocity = target_velocity
         position += velocity * delta
─────────────────────────────────────────────────────────────────────────────
```

### Key Interfaces

```gdscript
# CollisionManager — Public API
# File: src/core/collision_manager.gd

class_name CollisionManager extends Node

# === Constants ===
const MAX_SWEPT_STEPS: int = 64        # TK-018
const SEVERITY_BASE: float = 100.0    # TK-019
const DAMAGE_THRESHOLD: float = 1.0   # Internal

# === Dependencies ===
# TileMapWorld (for get_cell_at_position)
# BlockTypeDB (for get_collision_profile)

# === Public Methods ===

func swept_collision_check(
    start_pos: Vector2,
    velocity: Vector2,
    bounds: Rect2,
    max_steps: int = MAX_SWEPT_STEPS
) -> SweptCollisionResult:
    # DDA traversal through velocity range
    # Returns collision result with hit, position, remaining velocity, severity

    if velocity == Vector2.ZERO:
        return SweptCollisionResult.no_collision()

    var step_size = velocity.length() / max_steps
    var direction = velocity.normalized()
    var vehicle_half_size = bounds.size / 2

    for i in range(max_steps):
        var check_distance = i * step_size
        var check_pos = start_pos + direction * check_distance

        # Check vehicle bounds corners and center
        var collision_points = _get_collision_points(check_pos, vehicle_half_size)
        for point in collision_points:
            var grid_pos = Vector2i(int(point.x / TileMapWorld.CELL_SIZE),
                                    int(point.y / TileMapWorld.CELL_SIZE))
            var block_id = TileMapWorld.get_cell_at_position(grid_pos)

            if block_id <= 0:
                continue  # Empty or out of bounds

            var profile = BlockTypeDB.get_collision_profile(block_id)
            if profile.is_solid:
                # Collision found
                var hit_position = check_pos
                var remaining_velocity = velocity - direction * check_distance
                var severity = calculate_severity(velocity, profile.friction)

                GlobalSignals.collision_blocked.emit(grid_pos, block_id)

                return SweptCollisionResult.new(
                    true, hit_position, block_id, remaining_velocity, severity
                )

    # No collision found in all steps
    return SweptCollisionResult.no_collision()

func calculate_severity(velocity: Vector2, block_friction: float) -> float:
    # Formula: severity = velocity.length() * friction / SEVERITY_BASE
    return velocity.length() * block_friction / SEVERITY_BASE

func get_cell_collision_at(grid_pos: Vector2i) -> CollisionProfile:
    var block_id = TileMapWorld.get_cell_at_position(grid_pos)
    if block_id <= 0:
        return CollisionProfile.passable()
    return BlockTypeDB.get_collision_profile(block_id)

# === Internal Methods ===

func _get_collision_points(center: Vector2, half_size: Vector2) -> Array[Vector2]:
    # Returns corners and center of vehicle bounds for collision check
    return [
        center,  # Center
        center + Vector2(-half_size.x, -half_size.y),  # Top-left
        center + Vector2(half_size.x, -half_size.y),   # Top-right
        center + Vector2(-half_size.x, half_size.y),   # Bottom-left
        center + Vector2(half_size.x, half_size.y),    # Bottom-right
    ]


# SweptCollisionResult — Data Structure
# File: src/core/swept_collision_result.gd

class_name SweptCollisionResult extends RefCounted

var hit: bool = false
var hit_position: Vector2 = Vector2.ZERO
var hit_block_id: int = 0
var remaining_velocity: Vector2 = Vector2.ZERO
var severity: float = 0.0

func _init(hit: bool, hit_pos: Vector2, block_id: int, remaining: Vector2, sev: float) -> void:
    self.hit = hit
    self.hit_position = hit_pos
    self.hit_block_id = block_id
    self.remaining_velocity = remaining
    self.severity = sev

static func no_collision() -> SweptCollisionResult:
    return SweptCollisionResult.new(false, Vector2.ZERO, 0, Vector2.ZERO, 0.0)


# CollisionProfile — Data Structure (from BlockTypeDB)
# File: src/foundation/collision_profile.gd

class_name CollisionProfile extends RefCounted

var is_solid: bool = false
var collision_layer: int = 0  # 1=terrain, 2=structure, 4=platform
var friction: float = 0.5

static func passable() -> CollisionProfile:
    return CollisionProfile.new(false, 0, 0.0)

static func solid(layer: int, friction: float) -> CollisionProfile:
    return CollisionProfile.new(true, layer, friction)
```

### Implementation Guidelines

1. **CollisionManager Location**: 作为 VehicleController scene 的子节点，不是 Autoload
2. **DDA Step Size**: `velocity.length() / max_steps` 确保覆盖整个 velocity 范围
3. **Collision Points**: 检查 vehicle bounds 的 5 个点（中心 + 4 角）
4. **Severity Threshold**: DAMAGE_THRESHOLD=1.0，severity > 1 触发 damage
5. **Remaining Velocity**: 碰撞后剩余 velocity，乘 0.5 bounce factor
6. **Performance**: 64 步 × 5 points × 3 ops = ~960 ops，<1ms

## Alternatives Considered

### Alternative 1: CharacterBody2D.move_and_slide()

- **Description**: 使用 Godot 内置 move_and_slide() collision
- **Pros**: 内置实现，无需自定义算法
- **Cons**: Tunneling risk at high velocity，无法精确控制 severity
- **Estimated Effort**: 更低
- **Rejection Reason**: GDD 明确要求 swept collision，move_and_slide 不保证无穿透

### Alternative 2: Physics Raycast (RayCast2D)

- **Description**: 使用 RayCast2D node 进行 collision detection
- **Pros**: Godot 内置 raycast，精确
- **Cons**: 只检测一条射线，无法覆盖 vehicle bounds
- **Estimated Effort**: 更低
- **Rejection Reason**: Vehicle bounds 是 2D area，需要多 raycast 或 swept

### Alternative 3: Collision Shape (Area2D)

- **Description**: 使用 Area2D 监测 collision shape overlap
- **Pros**: 精确 area collision
- **Cons**: 无 swept traversal，只能检测当前位置 overlap
- **Estimated Effort**: 相同
- **Rejection Reason**: 无法检测 velocity 范围内 collision（tunneling）

## Consequences

### Positive

- 无穿透：swept traversal 覆盖 velocity 范围内所有 cells
- 精确 severity：公式计算碰撞伤害阈值
- 性能可控：MAX_SWEPT_STEPS=64 限制步数
- 事件驱动：collision_blocked emit 给其他系统

### Negative

- 自定义算法复杂度：需要维护 DDA traversal 实现
- 无 Godot 内置优化：CharacterBody2D 有内置 batch optimization
- 多点检测：5 points per step 增加 ops

### Neutral

- 这是 2D 游戏高速 collision 的标准解决方案

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| DDA algorithm 实现错误 | Medium | High | Test with unit tests, verify against GDD examples |
| MAX_SWEPT_STEPS 不足 | Low | Medium | If velocity > 64 * cell_size, increase MAX_SWEPT_STEPS |
| Severity formula 不符合预期 | Low | Low | Tune DAMAGE_THRESHOLD and SEVERITY_BASE in entities.yaml |
| 性能超预算（>1ms） | Low | Medium | Profile on target hardware, reduce collision points |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (swept collision) | 0 | <1ms/frame | 16.6ms/frame |
| Memory (CollisionManager) | 0 | <1KB | 512MB ceiling |
| Events (per collision) | 0 | 1-2 signals | Low |

估算：64 steps × 5 points × (TileMapWorld.get_cell + BlockTypeDB.get_profile) = 64 × 5 × 2 = 640 calls，每 call ~0.001ms → ~0.64ms total。

## Migration Plan

新架构，无迁移。

**Rollback plan**: If custom swept collision proves problematic, can fallback to CharacterBody2D.move_and_slide() with velocity clamping to reduce tunneling risk.

## Validation Criteria

- [ ] swept_collision_check() returns correct hit result
- [ ] No tunneling at velocity > 10 cells/frame
- [ ] calculate_severity() matches formula: velocity * friction / 100
- [ ] GlobalSignals.collision_blocked emitted on collision
- [ ] DamageReceiver.pending_damage set when severity > 1.0
- [ ] MAX_SWEPT_STEPS=64 configurable via entities.yaml TK-018
- [ ] Performance < 1ms/frame on target hardware

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/block-collision-system.md` | BlockCollision | Swept collision algorithm: DDA raycast traversal | swept_collision_check() uses DDA traversal with MAX_SWEPT_STEPS |
| `design/gdd/block-collision-system.md` | BlockCollision | MAX_SWEPT_STEPS = 64 | Constant from entities.yaml TK-018 |
| `design/gdd/block-collision-system.md` | BlockCollision | Severity formula: velocity * friction / SEVERITY_BASE | calculate_severity() implements formula, TK-019 |
| `design/gdd/vehicle-damage-system.md` | VehicleDamage | Collision damage threshold | severity > DAMAGE_THRESHOLD triggers pending_damage |

## Related

- ADR-001: TileMap System Architecture — TileMapWorld.get_cell_at_position() used for collision lookup
- ADR-002: Database Loading Strategy — BlockTypeDB.get_collision_profile() provides friction
- ADR-008: Movement and Physics Integration — VehicleController uses CollisionManager
- ADR-007: Vehicle State Machine Architecture — DamageReceiver receives collision damage