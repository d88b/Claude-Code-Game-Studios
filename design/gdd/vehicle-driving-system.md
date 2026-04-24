# 战车驾驶系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 1 (战车即生命)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #18 (from systems-index.md)

## Overview

战车驾驶系统是战车移动的执行层。它从输入控制系统接收语义化的驾驶指令（`drive_forward`, `drive_backward`, `drive_left`, `drive_right`），从战车属性系统查询当前速度和运动状态，通过方块碰撞系统检测移动边界，最终驱动战车CharacterBody2D在TileMap网格上移动。

**数据层定位**：驾驶系统管理战车的移动执行：
- 输入→速度映射：将输入强度转换为加速度，驱动current_speed变化
- 碰撞响应：检测TileMap碰撞，触发BLOCKED状态和vehicle_collision信号
- 魔能消耗：每移动距离单位消耗魔能，调用apply_magic_energy_cost()
- 状态同步：更新movement_state（IDLE/MOVING/ACCELERATING/DECELERATING/BLOCKED）

**玩家感知层**：玩家通过以下方式直接感知驾驶系统：
- 方向键/摇杆→战车移动的直接响应感（"我的手与战车连接"）
- 按住加速的重量感加速曲线（非瞬停瞬动，而是有惯性的驾驶体验）
- 撞墙的硬停止反馈（碰撞振动、音效、速度归零）
- 满载时的沉重感（速度降低30%，玩家感知战车负重）

**系统必要性**：没有驾驶系统，游戏将无法：
- 实现战车探索（战车无法在地表移动）
- 实现搜打撤节奏（无法驾驶到废墟、无法撤退）
- 实现Pillar 1的核心体验（战车无法响应玩家输入，"战车即生命"失败）
- 实现战车碰撞交互（无法检测墙体、无法触发碰撞反馈）

**服务于支柱**：
- **Pillar 1 (战车即生命)**：驾驶手感定义了玩家与战车的连接感——响应速度、重量感、碰撞反馈共同塑造"这台机器听我的"的核心体验
- **Pillar 2 (搜打撤节奏)**：驾驶系统驱动搜打撤的节奏——速度决定探索效率，魔能消耗创造撤退压力，满载降速创造载重决策

**架构决策待定**：本系统涉及VehicleController架构决策（是否与VehicleAttribute合并为单一Autoload，或使用per-instance Node），需通过`/architecture-decision`创建ADR确定。当前设计假设VehicleController为独立控制器，通过instance_id查询VehicleAttribute。

## Player Fantasy

玩家在战车驾驶系统中面对的核心体验是**钢铁意志的传导共鸣**——每一次按键、每一次摇杆推动，玩家的意图通过驾驶系统转化为战车的动作，玩家感受到的不是"操作一台机器"，而是"这台机器响应我的意志"。

### 情感锚定时刻

**出发时的心跳加速**：玩家在车库界面确认出发，方向键按下，战车引擎轰鸣启动，轮轴转动，战车缓缓驶出地堡入口。那一刻是Pillar 1的核心承诺兑现："它准备好了带我出去。"玩家感受到战车的"生命"——不是冰冷机械的启动，而是伙伴的"我们出发吧"。

**探索中的重量掌控**：玩家按住加速键，战车不是瞬间达到全速，而是逐渐加速——有重量的感觉。这不是赛车游戏的轻飘跑酷，而是重型魔导战车的惯性体验。玩家感受到战车的"质量"——按多久、达到什么速度、需要多少时间刹车，都是可控的。满载时战车速度降低30%，玩家感知到"它背负着沉重的战利品"。

**碰撞时的硬停止反馈**：驾驶中撞上墙体，战车硬停止。游戏pad振动、屏幕微震、碰撞音效同时触发。玩家感受到的不是"穿墙滑出"的bug感，而是"撞击是真的"的物理可信度。碰撞强度由速度、角度、耐久状态综合计算——高速正面撞击反馈强烈，低速侧擦反馈轻微。这种反馈层次塑造Pillar 1的驾驶信任感。

**撤退时的生死时速**：魔能15%，耐久40%，黄昏逼近，尸群在身后。玩家全力加速返回车库。每一格速度都珍贵——"还能再快吗？"的极限驾驶感。紧急转弯避开障碍，碰撞墙体的瞬间减速造成心跳骤停——"还能回去吗？"这种撤退时的紧张驾驶，是Pillar 2搜打撤节奏的压力峰值。

### 幻想服务于支柱

**Pillar 1 (战车即生命)**：驾驶系统的手感定义了玩家与战车的连接。响应速度（按键→动作的延迟）、重量感（加速曲线的非线性）、碰撞反馈（振动、音效、视觉）共同塑造"这台机器听我的"的核心体验。玩家不是在操作一个工具，而是在驾驶一个伙伴——战车的响应就像伙伴对玩家指令的服从。

**Pillar 4 (魔导科技美学)**：驾驶的视觉/音频呈现体现魔导科技设定——引擎声是"魔导晶石脉动"而非"柴油马达轰鸣"，加速感是"魔力流动驱动"而非"燃油燃烧推进"。术语和视觉语调强化世界观。

### 语调示例

```
❌ "按下方向键，战车以3.0格/秒速度向东移动"
✓ "你的手指推动摇杆，战车缓缓转向——它感受到你的意图，引擎调整魔力流向"

❌ "碰撞墙体，速度归零，触发振动反馈"
✓ "战车撞上墙壁，金属骨架震颤——它在告诉你：'前方有障碍，我们需要改变方向'"

❌ "满载状态，速度降低30%"
✓ "战车背负沉重的战利品，步伐变得缓慢——但它仍在前进，带你回家"
```

### 没有驾驶系统，玩家失去什么

- **战车不再感觉像意志的延伸**——按键无响应或响应不一致，玩家感受到"操作对抗"而非"驾驶掌控"
- **Pillar 1的核心体验崩溃**——战车无法响应玩家输入，"战车即生命"变成"战车即故障"
- **搜打撤节奏被打断**——无法驾驶到废墟（无法搜刮），无法撤退（无法返回），核心循环断裂
- **物理可信度崩溃**——穿墙、漂移、碰撞无反馈，玩家不信任这个世界是物理连贯的

## Detailed Design

### Core Rules

#### 1. Movement Input Processing

驾驶系统每帧从InputManager获取驾驶输入向量，转换为加速度驱动战车速度变化。

**1.1 Input Query Rule**

| Input Query | Method | Timing | Processing |
|-------------|--------|--------|------------|
| 方向输入 | `InputManager.get_vector("drive_left", "drive_right", "drive_forward", "drive_backward")` | 每帧 `_physics_process()` | 返回 Vector2 normalized (-1.0 to 1.0) |
| 键盘强度 | 已应用digital ramp curve (300ms) | InputManager内部处理 | `get_action_strength()` 返回 ramped value |
| 游戏pad强度 | Deadzone-adjusted raw axis | InputManager内部处理 | 直接返回 analog value |

**1.2 Input → Acceleration Mapping**

```gdscript
# VehicleController.gd
func _physics_process(delta: float):
    var input_vector := InputManager.get_vector(
        &"drive_left", &"drive_right", 
        &"drive_backward", &"drive_forward"
    )
    
    # Input magnitude determines acceleration
    var input_magnitude := input_vector.length()
    
    if input_magnitude > 0.01:
        # Apply acceleration toward target speed
        var target_speed := _calculate_target_speed(input_magnitude)
        _apply_acceleration(target_speed, delta)
        _update_movement_state(MovementState.ACCELERATING if _is_accelerating else MovementState.MOVING)
    else:
        # No input → natural deceleration
        _apply_deceleration(delta)
        _update_movement_state(MovementState.DECELERATING if current_speed > 0.1 else MovementState.IDLE)
```

---

#### 2. Speed Calculation Rules

**2.1 Target Speed Calculation**

```
target_speed = base_speed × load_modifier × input_magnitude × max_speed_ratio
```

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `base_speed` | float | 1.0-10.0 cells/sec | VehicleTypes.get_base_speed() |
| `load_modifier` | float | 0.7-1.0 | VehicleAttribute (Formula from #17) |
| `input_magnitude` | float | 0.0-1.0 | InputManager.get_vector().length() |
| `max_speed_ratio` | float | 0.0-1.0 | Tuning knob (default 1.0) |

**Example**: Standard Basic战车 (base_speed=3.0), empty load (modifier=1.0), full input (magnitude=1.0)
- target_speed = 3.0 × 1.0 × 1.0 × 1.0 = 3.0 cells/sec

**Example**: Heavy Elite战车 (base_speed=1.2), half load (modifier=0.85), partial input (magnitude=0.6)
- target_speed = 1.2 × 0.85 × 0.6 × 1.0 = 0.61 cells/sec

**2.2 Current Speed Update Rule**

当前速度通过加速度逐步逼近目标速度：

```gdscript
func _apply_acceleration(target: float, delta: float):
    var speed_diff := target - current_speed
    var accel_rate := ACCELERATION_RATE if speed_diff > 0 else DECELERATION_RATE
    
    # Clamp acceleration to prevent overshooting
    var max_change := abs(speed_diff)
    var actual_change := sign(speed_diff) × min(accel_rate × delta, max_change)
    
    current_speed = clamp(current_speed + actual_change, 0.0, target)
    VehicleAttribute.set_current_speed(instance_id, current_speed)
```

---

#### 3. Collision Detection Rules

**3.1 Pre-Movement Collision Check**

每次移动前，驾驶系统调用方块碰撞系统的swept collision检测：

```gdscript
# Before applying velocity
var motion := velocity × delta  # velocity in pixels/sec, delta in seconds
var collision_result := CollisionManager.check_swept_collision(vehicle_bounds, motion)

if collision_result.collision:
    # Collision detected — reduce motion to avoid penetration
    motion = collision_result.valid_motion  # Partial motion allowed
    current_speed = 0.0  # Hard stop on collision
    _update_movement_state(MovementState.BLOCKED)
    _emit_collision_signal(collision_result)
else:
    # No collision — apply full motion
    vehicle.position += motion
```

**3.2 Collision Response Rule**

| Collision Type | Speed Behavior | State Transition | Feedback |
|----------------|----------------|------------------|----------|
| 正面撞击 (angle > 0.7) | current_speed → 0.0 (hard stop) | MOVING/ACCELERATING → BLOCKED | Strong vibration + crash sound + screen shake |
| 侧擦 (angle 0.3-0.7) | current_speed × 0.7 (partial reduction) | MOVING → MOVING (speed reduced) | Medium vibration + scrape sound |
| 轻擦 (angle < 0.3) | current_speed × 0.95 (minor reduction) | MOVING → MOVING (speed maintained) | Light scrape sound |

---

#### 4. Magic Energy Consumption Rules

**4.1 Consumption Trigger Rule**

魔能消耗基于实际移动距离而非时间：

```
magic_cost = distance_traveled × MAGIC_COST_PER_CELL × load_cost_modifier
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `distance_traveled` | float | 0.0-∞ cells | Actual movement distance this frame |
| `MAGIC_COST_PER_CELL` | float | Tuning knob | Base magic cost per cell traveled |
| `load_cost_modifier` | float | 1.0-1.5 | Higher load = higher consumption |

**4.2 Consumption Application Rule**

```gdscript
func _consume_magic_for_movement(distance: float):
    if vehicle_state != VehicleState.DEPLOYED:
        return  # Only consume magic when deployed
    
    var load_ratio := VehicleAttribute.get_load_ratio(instance_id)
    var load_cost_modifier := 1.0 + clamp(load_ratio - 1.0, 0.0, 0.5)  # Overload = extra cost
    
    var magic_cost := distance × MAGIC_COST_PER_CELL × load_cost_modifier
    
    # Attempt to consume magic
    var success := VehicleAttribute.apply_magic_energy_cost(instance_id, magic_cost)
    
    if not success:
        # Magic depleted — trigger DISABLED state
        VehicleAttribute.transition_to_state(instance_id, VehicleState.DISABLED)
        current_speed = 0.0
        _emit_magic_depleted_signal()
```

**4.3 Consumption Frequency**

- 魾能消耗**每帧累积**（与移动同步）
- 实际扣减每**N帧**执行一次（性能优化，避免频繁写入）
- 累积值在DISABLED状态检查时一次性扣减

---

#### 5. Steering/Turning Rules

**5.1 Direction Update Rule**

战车方向基于输入向量逐步转向：

```gdscript
# Steering applies to velocity direction, not position
var current_direction := velocity.normalized()
var target_direction := input_vector.normalized()

# Steering rate depends on speed (slower = faster turn)
var turn_rate := BASE_TURN_RATE × (1.0 - speed_ratio × 0.5)  # Higher speed = slower turn

var angle_diff := current_direction.angle_to(target_direction)
var max_turn := turn_rate × delta

# Clamp turn to prevent overshooting
var actual_turn := clamp(angle_diff, -max_turn, max_turn)
var new_direction := current_direction.rotated(actual_turn)

velocity = new_direction × current_speed × CELL_SIZE  # Convert cells/sec to pixels/sec
```

**5.2 Turning Speed Penalty**

转向时速度略有降低（momentum conservation）：

```gdscript
# Speed reduction during turn
var turn_penalty := abs(angle_diff) × TURN_SPEED_PENALTY_FACTOR
current_speed = current_speed × (1.0 - turn_penalty × delta)
```

---

### States and Transitions

#### Movement State Enumeration (继承自战车属性系统)

| Value | Name | Condition | Behavior |
|-------|------|-----------|----------|
| 0 | `IDLE` | current_speed < 0.1, no input | No movement, zero velocity |
| 1 | `MOVING` | current_speed ≥ 0.1, stable speed | Constant velocity movement |
| 2 | `ACCELERATING` | current_speed increasing toward target | Speed change > threshold |
| 3 | `DECELERATING` | current_speed decreasing, no input | Natural friction/drag |
| 4 | `BLOCKED` | Collision detected, speed = 0 | Hard stop, collision feedback |

#### State Transition Table

| From | To | Trigger | Guard | Action |
|------|-----|---------|-------|--------|
| `IDLE` | `ACCELERATING` | Input detected (magnitude > 0.01) | vehicle_state = DEPLOYED | Start acceleration toward target speed |
| `ACCELERATING` | `MOVING` | Speed stabilized (|Δspeed| < threshold) | current_speed ≈ target_speed | Emit movement_stable signal |
| `MOVING` | `DECELERATING` | No input (magnitude < 0.01) | current_speed > 0.1 | Apply natural deceleration |
| `DECELERATING` | `IDLE` | Speed near zero | current_speed < 0.1 | Stop movement, clear velocity |
| `MOVING`/`ACCELERATING` | `BLOCKED` | Collision detected | collision_result.collision = true | Hard stop, emit vehicle_collision signal |
| `BLOCKED` | `IDLE` | Collision cleared, no input | No collision, input = 0 | Wait for new input |
| `BLOCKED` | `ACCELERATING` | Collision cleared, input active | No collision, input > 0.01 | Resume acceleration |
| Any | `IDLE` | Magic depleted | current_magic_energy = 0 | Trigger DISABLED (via VehicleAttribute) |

---

### Interactions with Other Systems

#### Upstream Systems

| System | Interface | Data Consumed | Timing |
|--------|-----------|---------------|--------|
| **输入控制系统 (#9)** | `InputManager.get_vector()` | Input direction (Vector2) | Every `_physics_process()` frame |
| **输入控制系统 (#9)** | `InputManager.get_action_strength()` | Input magnitude (0.0-1.0) | Every frame |
| **战车属性系统 (#17)** | `VehicleAttribute.get_current_speed()` | Current speed (cells/sec) | Every frame |
| **战车属性系统 (#17)** | `VehicleAttribute.get_vehicle_state()` | Vehicle state (DEPLOYED/GARAGE_IDLE/etc.) | Frame start check |
| **战车类型数据库 (#6)** | `VehicleTypes.get_base_speed()` | Base speed | Initialization only |
| **方块碰撞系统 (#11)** | `CollisionManager.check_swept_collision()` | Collision detection | Before each movement |

#### Downstream Consumers

| System | Interface | Data Provided | Timing |
|--------|-----------|---------------|--------|
| **战车属性系统 (#17)** | `VehicleAttribute.set_current_speed()` | Updated current_speed | Every frame |
| **战车属性系统 (#17)** | `VehicleAttribute.apply_magic_energy_cost()` | Magic consumption | After distance traveled |
| **方块碰撞系统 (#11)** | `vehicle_collision` signal | Collision event | On collision detection |
| **音效系统 (#52)** | `movement_state_changed` signal | State transition | On state change |
| **音效系统 (#52)** | `magic_consumed` signal | Consumption event | On magic deduction |

#### Signal Architecture

| Signal | Parameters | Trigger | Consumers |
|--------|------------|---------|-----------|
| `movement_state_changed` | `instance_id: int, old_state: int, new_state: int` | State transition | VehicleAttribute, AudioSystem, HUD |
| `vehicle_collision` | `instance_id: int, collision_cell: Vector2i, severity: float` | Collision detected | AudioSystem, GamepadVibration, ScreenShake |
| `magic_consumed` | `instance_id: int, amount: float, remaining: float` | Magic deduction | VehicleAttribute, HUD |
| `speed_changed` | `instance_id: int, old_speed: float, new_speed: float` | Speed threshold crossed | VehicleAttribute, HUD |

## Formulas

### 1. Target Speed Formula

战车目标速度由基础速度、载重修正、输入强度综合计算。

```
target_speed = base_speed × load_modifier × input_magnitude × max_speed_ratio
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `base_speed` | BS | float | 1.0-10.0 cells/sec | VehicleTypes.get_base_speed(vehicle_type_id) |
| `load_modifier` | LM | float | 0.7-1.0 | VehicleAttribute.speed_load_modifier (from #17) |
| `input_magnitude` | IM | float | 0.0-1.0 | InputManager.get_vector().length() |
| `max_speed_ratio` | MSR | float | 0.0-1.0 | Tuning knob, default 1.0 |
| `target_speed` | TS | float | 0.0-10.0 cells/sec | Output |

**Output Range:** 0.0 (no input) to base_speed × load_modifier (full input, empty load)

**Boundary Tests:**

| Case | base_speed | load_modifier | input_magnitude | target_speed |
|------|------------|---------------|-----------------|--------------|
| No input | 3.0 | 1.0 | 0.0 | 0.0 |
| Full input, empty load | 3.0 | 1.0 | 1.0 | 3.0 |
| Full input, half load | 3.0 | 0.85 | 1.0 | 2.55 |
| Full input, full load | 3.0 | 0.7 | 1.0 | 2.1 |
| Partial input (0.6) | 3.0 | 1.0 | 0.6 | 1.8 |
| Heavy Elite, partial input | 1.2 | 0.85 | 0.6 | 0.61 |

**Example:**
- Standard Basic战车 (base_speed=3.0)
- Empty load → load_modifier=1.0
- Keyboard input at 150ms hold → ramp_value=0.56
- target_speed = 3.0 × 1.0 × 0.56 × 1.0 = 1.68 cells/sec

---

### 2. Acceleration Rate Formula

加速度决定战车达到目标速度所需时间。

```
acceleration_rate = ACCELERATION_BASE × load_accel_penalty
load_accel_penalty = 1.0 + clamp(load_ratio - 0.5, 0.0, 0.5) × 0.3
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `ACCELERATION_BASE` | — | const | 1.0-5.0 cells/sec² | Tuning knob, default 2.0 |
| `load_ratio` | LR | float | 0.0-∞ | current_load / load_capacity |
| `load_accel_penalty` | LAP | float | 1.0-1.15 | Heavy load = slower acceleration |
| `acceleration_rate` | AR | float | 1.0-5.0 cells/sec² | Output |

**Output Range:** ACCELERATION_BASE (empty) to ACCELERATION_BASE × 1.15 (overloaded)

**Boundary Tests:**

| Case | load_ratio | load_accel_penalty | acceleration_rate (BASE=2.0) |
|------|------------|--------------------|-------------------------------|
| Empty load | 0.0 | 1.0 | 2.0 cells/sec² |
| Half load | 0.5 | 1.0 | 2.0 |
| Full load | 1.0 | 1.15 | 2.3 (slightly slower due to inertia) |
| Overload 150% | 1.5 | 1.15 (clamp) | 2.3 |

**Example:**
- ACCELERATION_BASE = 2.0 cells/sec²
- load_ratio = 0.8 (80% load)
- load_accel_penalty = 1.0 + (0.8 - 0.5) × 0.3 = 1.09
- acceleration_rate = 2.0 × 1.09 = 2.18 cells/sec²
- Time to reach 3.0 cells/sec from 0: ~1.4 seconds

---

### 3. Deceleration Rate Formula

无输入时的自然减速（摩擦/阻力）。

```
deceleration_rate = current_speed × DRAG_COEFFICIENT × delta
new_speed = current_speed - deceleration_rate
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `current_speed` | CS | float | 0.0-10.0 cells/sec | VehicleAttribute.get_current_speed() |
| `DRAG_COEFFICIENT` | — | const | 0.5-2.0 | Tuning knob, default 1.0 |
| `delta` | Δt | float | 0.016 sec | Physics frame time (60fps) |
| `new_speed` | NS | float | 0.0-CS | Output |

**Output Range:** Speed decreases by current_speed × DRAG_COEFFICIENT × delta per frame

**Boundary Tests:**

| Case | current_speed | DRAG_COEFFICIENT | delta | decel per frame | Speed after 1s |
|------|----------------|------------------|-------|-----------------|-----------------|
| Full speed, high drag | 3.0 | 2.0 | 0.016 | 0.096 | ~0 (stop quickly) |
| Full speed, low drag | 3.0 | 0.5 | 0.016 | 0.024 | ~1.5 (gradual) |
| Full speed, standard drag | 3.0 | 1.0 | 0.016 | 0.048 | ~0.9 in 1s |

**Example:**
- current_speed = 3.0 cells/sec
- DRAG_COEFFICIENT = 1.0
- delta = 0.016 (60fps)
- decel_per_frame = 3.0 × 1.0 × 0.016 = 0.048 cells/sec
- After 60 frames (1 second): speed ≈ 3.0 × (1.0 - 1.0) = 0.0 (exponential decay)

---

### 4. Magic Energy Consumption Formula

移动距离对应的魔能消耗。

```
magic_cost = distance_traveled × MAGIC_COST_PER_CELL × load_cost_modifier
load_cost_modifier = 1.0 + clamp(load_ratio - 1.0, 0.0, 0.5)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `distance_traveled` | DT | float | 0.0-∞ cells | Actual movement this frame |
| `MAGIC_COST_PER_CELL` | — | const | 0.1-1.0 | Tuning knob, default 0.5 |
| `load_ratio` | LR | float | 0.0-∞ | current_load / load_capacity |
| `load_cost_modifier` | LCM | float | 1.0-1.5 | Overload penalty |
| `magic_cost` | MC | float | 0.0-∞ | Output (magic units) |

**Output Range:** MAGIC_COST_PER_CELL (empty load) to MAGIC_COST_PER_CELL × 1.5 (overloaded)

**Boundary Tests:**

| Case | distance | MAGIC_COST_PER_CELL | load_ratio | magic_cost |
|------|----------|---------------------|------------|------------|
| 1 cell, empty load | 1.0 | 0.5 | 0.0 | 0.5 |
| 1 cell, full load | 1.0 | 0.5 | 1.0 | 0.5 |
| 1 cell, overload 150% | 1.0 | 0.5 | 1.5 | 0.75 |
| 10 cells, empty load | 10.0 | 0.5 | 0.0 | 5.0 |
| Full exploration (100 cells) | 100.0 | 0.5 | 0.8 | 50.0 |

**Example:**
- Standard Basic战车 (max_magic_energy=100)
- Exploration distance: 60 cells (from garage to distant ruin)
- MAGIC_COST_PER_CELL = 0.5
- load_ratio = 0.5 (half load)
- load_cost_modifier = 1.0
- magic_cost = 60 × 0.5 × 1.0 = 30 magic units
- Remaining: 100 - 30 = 70 magic (70% of capacity)

---

### 5. Turning Rate Formula

转向速度与当前速度反比（高速时转向慢）。

```
turn_rate = BASE_TURN_RATE × (1.0 - speed_ratio × TURN_SPEED_FACTOR)
speed_ratio = current_speed / max_possible_speed
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `BASE_TURN_RATE` | — | const | 90-180 deg/sec | Tuning knob, default 120 |
| `current_speed` | CS | float | 0.0-10.0 cells/sec | VehicleAttribute.get_current_speed() |
| `max_possible_speed` | MPS | float | base_speed × load_modifier | Maximum speed at current load |
| `speed_ratio` | SR | float | 0.0-1.0 | Speed relative to max |
| `TURN_SPEED_FACTOR` | — | const | 0.3-0.7 | Tuning knob, default 0.5 |
| `turn_rate` | TR | float | 60-180 deg/sec | Output |

**Output Range:** BASE_TURN_RATE (idle/low speed) to BASE_TURN_RATE × 0.5 (full speed)

**Boundary Tests:**

| Case | current_speed | max_possible_speed | speed_ratio | turn_rate (BASE=120) |
|------|----------------|--------------------|-------------|----------------------|
| Idle | 0.0 | 3.0 | 0.0 | 120 deg/sec (fast turn) |
| Half speed | 1.5 | 3.0 | 0.5 | 120 × 0.75 = 90 deg/sec |
| Full speed | 3.0 | 3.0 | 1.0 | 120 × 0.5 = 60 deg/sec (slow turn) |

**Example:**
- BASE_TURN_RATE = 120 deg/sec
- current_speed = 2.0 cells/sec
- max_possible_speed = 3.0 cells/sec
- speed_ratio = 0.67
- turn_rate = 120 × (1.0 - 0.67 × 0.5) = 120 × 0.67 = 80 deg/sec

---

### 6. Collision Speed Reduction Formula

碰撞后的速度减少比例（基于碰撞角度）。

```
speed_reduction = 1.0 - impact_angle × COLLISION_PENALTY_FACTOR
impact_angle = abs(dot(velocity.normalized(), collision_normal))
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `velocity` | V | Vector2 | — | Vehicle velocity direction |
| `collision_normal` | N | Vector2 | — | Collision surface normal |
| `impact_angle` | IA | float | 0.0-1.0 | Collision alignment (0=parallel, 1=perpendicular) |
| `COLLISION_PENALTY_FACTOR` | — | const | 0.5-1.0 | Tuning knob, default 0.7 |
| `speed_reduction` | SR | float | 0.3-1.0 | Output multiplier |

**Output Range:** 
- impact_angle = 1.0 (正面撞击) → speed_reduction = 0.3 (hard stop, 70% loss)
- impact_angle = 0.0 (侧面滑擦) → speed_reduction = 1.0 (no reduction)

**Boundary Tests:**

| Case | impact_angle | COLLISION_PENALTY_FACTOR | speed_reduction |
|------|--------------|-------------------------|-----------------|
| 正面撞击 | 1.0 | 0.7 | 0.3 (70% speed lost) |
| 侧擦 (45°) | 0.7 | 0.7 | 0.51 (49% lost) |
| 轻擦 (15°) | 0.3 | 0.7 | 0.79 (21% lost) |
| 平行滑擦 | 0.0 | 0.7 | 1.0 (no speed lost) |

**Example:**
- Velocity direction: (1.0, 0.0) (moving right)
- Collision normal: (-1.0, 0.0) (wall facing left)
- impact_angle = |dot((1,0), (-1,0))| = 1.0 (正面撞击)
- speed_reduction = 1.0 - 1.0 × 0.7 = 0.3
- new_speed = current_speed × 0.3 (70% reduction)

## Edge Cases

### 1. Zero Input While Moving

**If** input magnitude drops to 0.0 while vehicle is moving at full speed:
- Vehicle enters DECELERATING state immediately
- Speed decays via DRAG_COEFFICIENT formula (not instant stop)
- No magic consumed during deceleration (only consumed for actual movement)
- **Rationale**: Momentum conservation — vehicle doesn't teleport to zero speed

---

### 2. Collision During Acceleration

**If** collision detected while vehicle is accelerating toward target speed:
- Speed immediately reduced per Collision Speed Reduction Formula
- State transitions: ACCELERATING → BLOCKED (if speed near zero) or ACCELERATING → MOVING (if partial reduction)
- Input continues → acceleration resumes from reduced speed
- **Rationale**: Collision interrupts acceleration curve, vehicle must rebuild speed from lower baseline

---

### 3. Magic Depleted During Movement

**If** magic_energy reaches 0 during movement:
- VehicleAttribute.apply_magic_energy_cost() returns false
- VehicleAttribute.transition_to_state(instance_id, DISABLED) triggered
- current_speed immediately set to 0.0 (hard stop)
- Vehicle position frozen at collision point
- movement_state → IDLE
- `magic_energy_depleted` signal emitted
- Player must walk back (战车瘫痪 in place)
- **Rationale**: Pillar 1 consequence — 魔能耗尽 = 战车瘫痪，player experiences real risk

---

### 4. Overload Speed Clamp

**If** load_ratio > 1.0 (overloaded):
- load_modifier clamped to 0.7 (maximum 30% speed reduction)
- Player sees actual load_ratio in HUD (e.g., "超载150%")
- Speed formula uses clamped modifier for movement
- load_cost_modifier = 1.0 + (load_ratio - 1.0) × penalty factor (consumption still scales)
- **Rationale**: Overload has consumption penalty but speed penalty capped — prevents "战车无法移动" frustration

---

### 5. Multiple Collision in Single Frame

**If** swept collision detects multiple solid cells in motion path:
- Collision resolved at first encountered cell
- Motion truncated to collision point
- Remaining motion discarded (no tunneling through second wall)
- collision_result includes all detected cells for visual/audio context
- **Rationale**: Single collision point per frame — prevents physics tunneling exploits

---

### 6. Input Method Switch Mid-Drive

**If** player switches from keyboard to gamepad while moving:
- InputManager.last_active_device updates immediately
- InputManager.get_vector() returns new device's input
- Speed continuity maintained — no reset to 0
- Acceleration curve continues from current_speed
- **Rationale**: Seamless device transition — player doesn't lose momentum when switching control methods

---

### 7. Vehicle State Change (DEPLOYED → GARAGE)

**If** vehicle_state transitions from DEPLOYED to GARAGE_IDLE (return to garage):
- current_speed immediately set to 0.0
- velocity vector cleared
- Magic consumption stops
- movement_state → IDLE
- Vehicle position reset to garage_spawn_point
- **Rationale**: Garage state = no driving, clean state reset for next deployment

---

### 8. Collision While Magic Below Threshold

**If** collision occurs while magic_energy_ratio < VEHICLE_RETREAT_MAGIC_THRESHOLD (0.20):
- Collision feedback amplified (integrity_factor higher in severity formula)
- Gamepad vibration intensity increased by 20%
- Screen shake amplitude increased by 30%
- Sound pitch lowered (more dramatic crash sound)
- **Rationale**: Retreat pressure — low magic + collision = high-risk moment, feedback heightens tension

---

### 9. Speed Oscillation Prevention

**If** input magnitude fluctuates rapidly (e.g., 0.3 → 0.8 → 0.3 within 0.5 seconds):
- Acceleration/deceleration uses smoothed input average (rolling 3-frame window)
- Prevents "jittery" speed changes from micro-input variations
- State transitions thresholded: speed_change > 0.2 cells/sec² to trigger state change
- **Rationale**: Driving feel stability — micro-input noise filtered for smooth acceleration curve

---

### 10. Simultaneous Forward and Backward Input

**If** input_vector has conflicting directions (e.g., drive_forward + drive_backward both pressed):
- InputManager.get_vector() returns net magnitude (forward - backward)
- If magnitude < 0.01: treated as no input → DECELERATING
- If magnitude > 0.01: treated as valid input in dominant direction
- **Rationale**: Conflicting input resolved by InputManager — driving system receives net vector only

## Dependencies

### Upstream Dependencies (Systems this depends on)

| System | Priority | Layer | Interface Used | Dependency Type | GDD Status |
|--------|----------|-------|----------------|-----------------|------------|
| **战车属性系统 (#17)** | MVP | Core | `get_current_speed()`, `get_vehicle_state()`, `apply_magic_energy_cost()`, `set_current_speed()`, movement_state signals | **Blocking** — Cannot drive without speed/state data | ✓ Designed (Approved) |
| **输入控制系统 (#9)** | MVP | Foundation | `get_vector("drive_*")`, `get_action_strength()`, `action_triggered` signal | **Blocking** — Cannot drive without input abstraction | ✓ Designed (Approved) |
| **TileMap世界系统 (#1)** | MVP | Foundation | `world_to_cell()`, `cell_to_world_center()`, CELL_SIZE=32 | **Blocking** — Cannot navigate without coordinate system | ✓ Designed (Approved) |
| **方块碰撞系统 (#11)** | MVP | Core | `check_swept_collision()`, `vehicle_collision` signal, collision_layer/mask configuration | **Blocking** — Cannot detect walls without collision | ✓ Designed (Revised) |
| **战车类型数据库 (#6)** | MVP | Foundation | `get_base_speed()`, `get_load_capacity()` | **Blocking** — Cannot determine max speed without type definition | ✓ Designed (Approved) |

**Critical Upstream Data Flow:**

```
VehicleTypes (#6) → base_speed (initialization)
InputManager (#9) → input_vector (every frame)
VehicleAttribute (#17) → current_speed, vehicle_state, magic_energy (every frame)
CollisionManager (#11) → collision_result (before movement)
TileMapWorld (#1) → world_to_cell, CELL_SIZE (coordinate conversion)
```

---

### Downstream Dependencies (Systems that depend on this)

| System | Priority | Layer | Data Consumed | Dependency Type | GDD Status |
|--------|----------|-------|---------------|-----------------|------------|
| **魔能消耗计算 (#19)** | MVP | Core | distance_traveled, consumption rate, magic remaining | **Blocking** — Cannot calculate consumption without movement | Not Started |
| **战车损坏系统 (#21)** | MVP | Core | collision severity, impact speed, collision normal | **Blocking** — Cannot apply collision damage without collision data | Not Started |
| **战车武器系统 (#20)** | MVP | Core | vehicle position, vehicle direction (velocity) | **Blocking** — Cannot fire weapons without position/orientation | Not Started |
| **撤退判定系统 (#32)** | MVP | Core | current_speed, movement_state, distance_from_garage | **Blocking** — Cannot judge retreat timing without position | Not Started |
| **战车维修系统 (#22)** | Vertical Slice | Feature | vehicle_state (GARAGE_IDLE trigger) | **Blocking** — Cannot initiate repair without state change | Not Started |
| **战车仓库系统 (#29)** | Vertical Slice | Feature | current_load change events | **Blocking** — Cannot update warehouse without load tracking | Not Started |
| **HUD系统 (#49)** | Full Vision | Presentation | current_speed, movement_state, magic consumption rate | **Non-blocking** — UI can display placeholder | Not Started |
| **音效系统 (#52)** | Full Vision | Presentation | movement_state_changed, vehicle_collision, magic_consumed signals | **Non-blocking** — Audio can be silent | Not Started |

**Critical Downstream Data Flow:**

```
VehicleDriving (#18) → distance_traveled → MagicConsumption (#19)
VehicleDriving (#18) → collision_result → VehicleDamage (#21)
VehicleDriving (#18) → position, velocity → VehicleWeapon (#20)
VehicleDriving (#18) → signals → AudioSystem (#52), HUD (#49)
```

---

### Bidirectional Dependency Check

| Dependency | Listed Here | Listed in Target GDD | Status |
|------------|--------------|----------------------|--------|
| VehicleAttribute → VehicleDriving | ✓ Listed as Blocking | ✓ Listed in #17 as Blocking | ✓ Verified |
| InputManager → VehicleDriving | ✓ Listed as Blocking | ✓ Listed in #9 as Blocking | ✓ Verified |
| CollisionManager → VehicleDriving | ✓ Listed as Blocking | ✓ Listed in #11 as Blocking | ✓ Verified |
| TileMapWorld → VehicleDriving | ✓ Listed as Blocking | ✓ Listed in #1 as Blocking | ✓ Verified |
| VehicleTypes → VehicleDriving | ✓ Listed as Blocking | ✓ Listed in #6 as Blocking | ✓ Verified |
| MagicConsumption → VehicleDriving | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| VehicleDamage → VehicleDriving | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| VehicleWeapon → VehicleDriving | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| RetreatJudge → VehicleDriving | ✓ Listed as Blocking | Target GDD Not Started | Pending |

---

### Interface Contract Summary

**VehicleDriving MUST provide to downstream systems:**

| Interface Method | Consumer Systems | Contract |
|------------------|------------------|----------|
| `get_distance_traveled(instance_id)` | MagicConsumption (#19) | Returns float (cells traveled this frame) |
| `get_current_position(instance_id)` | VehicleWeapon (#20), RetreatJudge (#32) | Returns Vector2 (world position in pixels) |
| `get_velocity_direction(instance_id)` | VehicleWeapon (#20) | Returns Vector2 (normalized direction) |
| `get_collision_result(instance_id)` | VehicleDamage (#21) | Returns Dictionary (cell, severity, normal) |
| `movement_state_changed` signal | AudioSystem (#52), HUD (#49) | Emits on state transition |
| `vehicle_collision` signal | AudioSystem (#52), VehicleDamage (#21) | Emits on collision detected |
| `magic_consumed` signal | HUD (#49) | Emits on magic deduction |

## Tuning Knobs

### Primary Tuning Knobs

These values directly control driving feel and balance. Each knob has a safe tuning range, a default value, and a gameplay impact description.

| Knob | Default | Safe Range | Unit | Gameplay Impact |
|------|---------|------------|------|-----------------|
| **ACCELERATION_BASE** | 2.0 | 1.0-5.0 | cells/sec² | Controls weight感 — lower = heavy acceleration, higher = snappy response. Affects Pillar 1 (战车即生命). |
| **DRAG_COEFFICIENT** | 1.0 | 0.5-2.0 | ratio | Controls natural deceleration rate — lower = momentum-heavy (vehicle keeps moving), higher = responsive stop. Affects撤退紧张感. |
| **MAGIC_COST_PER_CELL** | 0.5 | 0.1-1.0 | magic/cell | Controls exploration economy — lower = longer exploration range, higher = tighter 搜打撤压力. Affects Pillar 2. |
| **BASE_TURN_RATE** | 120 | 90-180 | deg/sec | Controls steering responsiveness — lower = deliberate turns (heavy vehicle), higher = agile turns. Affects驾驶掌控感. |
| **TURN_SPEED_FACTOR** | 0.5 | 0.3-0.7 | ratio | Controls speed-dependent turn penalty — lower = turns remain fast at speed, higher = high-speed turns slow. Affects collision avoidance. |
| **COLLISION_PENALTY_FACTOR** | 0.7 | 0.5-1.0 | ratio | Controls collision severity — lower = minor speed loss (forgiving), higher = hard stop on impact. Affects物理可信度. |
| **max_speed_ratio** | 1.0 | 0.5-1.5 | ratio | Global speed multiplier — lower = slower exploration, higher = faster traversal. Tuning emergency override only. |

---

### Secondary Tuning Knobs

These values affect state transitions and edge case behavior. Less frequently tuned but critical for feel polish.

| Knob | Default | Safe Range | Unit | Gameplay Impact |
|------|---------|------------|------|-----------------|
| **IDLE_SPEED_THRESHOLD** | 0.1 | 0.05-0.3 | cells/sec | Speed below which vehicle is considered IDLE. Lower = longer deceleration before stop state. |
| **ACCELERATION_STABLE_THRESHOLD** | 0.2 | 0.1-0.5 | cells/sec² | Speed change rate below which ACCELERATING → MOVING. Lower = smoother state transition. |
| **INPUT_SMOOTHING_WINDOW** | 3 | 1-5 | frames | Rolling average for input smoothing (Edge Case #9). Higher = more stable but less responsive. |
| **MAGIC_ACCUMULATION_INTERVAL** | 5 | 1-10 | frames | Frames between magic deduction write. Higher = fewer writes but larger per-frame cost visibility. |
| **OVERLOAD_SPEED_CLAMP** | 0.7 | 0.5-0.85 | ratio | Minimum load_modifier (Edge Case #4). Lower = overload severely slows vehicle, higher = overload less punishing. |

---

### Locked Values (Cannot Tune)

These values are owned by other systems. Do NOT modify in driving system tuning — they are referenced as constants.

| Constant | Value | Owner System | Reason for Lock |
|----------|-------|--------------|-----------------|
| **CELL_SIZE** | 32 px | TileMap世界系统 (#1) | All coordinate conversion depends on this. Changing requires asset re-scale. |
| **DIGITAL_RAMP_TIME** | 300 ms | 输入控制系统 (#9) | Keyboard steering ramp. Changing affects all input-dependent systems. |
| **DIGITAL_CANCEL_TIME** | 80 ms | 输入控制系统 (#9) | Return-to-neutral timing. Affects all steering feel systems. |
| **MAX_SWEPT_STEPS** | 64 | 方块碰撞系统 (#11) | Collision traversal cap. Performance constraint, not gameplay tuning. |
| **VEHICLE_DEPLOY_DURABILITY_MIN** | 0.80 | Game Concept | Minimum durability to deploy. Pillar constraint, locked from concept. |
| **VEHICLE_DEPLOY_MAGIC_MIN** | 0.50 | Game Concept | Minimum magic to deploy. Pillar constraint, locked from concept. |
| **VEHICLE_RETREAT_MAGIC_THRESHOLD** | 0.20 | Game Concept | Retreat warning trigger. Pillar 2 rhythm constraint. |
| **VEHICLE_RETREAT_DURABILITY_THRESHOLD** | 0.30 | Game Concept | Retreat warning trigger. Pillar 2 rhythm constraint. |

---

### Knob Interaction Matrix

Some knobs interact non-linearly. When tuning one, consider its effect on others:

| Interaction | Effect | Tuning Guidance |
|-------------|--------|-----------------|
| ACCELERATION_BASE + DRAG_COEFFICIENT | High accel + high drag = snappy response (fast accel, fast stop). Low accel + low drag = momentum-heavy (slow accel, long drift). | Match to vehicle type fantasy — Heavy战车 = low accel + low drag, Scout战车 = high accel + high drag. |
| MAGIC_COST_PER_CELL + BASE_TURN_RATE | High magic cost + slow turn rate = careful navigation (every wasted movement costs magic). Low magic cost + fast turn = agile exploration. | Tighten for 撤退压力 (high cost), loosen for early-game exploration (low cost). |
| COLLISION_PENALTY_FACTOR + DRAG_COEFFICIENT | Both affect stop feel. Collision penalty is instant, drag is gradual. High collision penalty + low drag = collision feels dramatic but normal stop is gentle. | Calibrate collision to feel "冲击感", drag to feel "惯性自然停止". |
| TURN_SPEED_FACTOR + ACCELERATION_BASE | High turn factor + high accel = vehicle can accelerate while turning (agile feel). Low turn factor + low accel = turning kills speed (heavy feel). | Heavy战车 = low turn factor, Scout战车 = high turn factor. |

---

### Tuning Profiles (Recommended Presets)

Two tuning profiles are recommended for MVP testing:

#### Profile A: 紧张节奏 (Tense Rhythm)

**Purpose**: Emphasize Pillar 2 (搜打撤节奏) — create pressure during exploration.

| Knob | Value | Effect |
|------|-------|--------|
| ACCELERATION_BASE | 1.5 | Slow acceleration = deliberate movement |
| DRAG_COEFFICIENT | 1.5 | Fast deceleration = responsive stop |
| MAGIC_COST_PER_CELL | 0.8 | High consumption = shorter exploration range |
| BASE_TURN_RATE | 100 | Slow turn = careful navigation |
| TURN_SPEED_FACTOR | 0.6 | High-speed turns difficult |
| COLLISION_PENALTY_FACTOR | 0.8 | Hard collision penalty = collision hurts |

**Player experience**: Every movement feels weighted. Collision wastes precious magic. Retreat feels tense — every wasted turn costs resources. Recommended for late-game / high-stakes exploration.

---

#### Profile B: 宽松节奏 (Relaxed Rhythm)

**Purpose**: Emphasize Pillar 1 (战车即生命) — create responsive, satisfying driving feel.

| Knob | Value | Effect |
|------|-------|--------|
| ACCELERATION_BASE | 3.0 | Fast acceleration = responsive |
| DRAG_COEFFICIENT | 0.8 | Gradual deceleration = momentum feel |
| MAGIC_COST_PER_CELL | 0.3 | Low consumption = long exploration range |
| BASE_TURN_RATE | 150 | Fast turn = agile navigation |
| TURN_SPEED_FACTOR | 0.4 | Turns remain responsive at speed |
| COLLISION_PENALTY_FACTOR | 0.5 | Forgiving collision = minor speed loss |

**Player experience**: Vehicle feels responsive and agile. Exploration feels free. Collision is forgiving. Recommended for early-game / onboarding / tutorial.

---

### Tuning Workflow

1. **Start with Profile B (宽松节奏)** for MVP prototype — players need to feel driving is fun before they feel pressure.
2. **Gradually tighten knobs toward Profile A** as player skill increases.
3. **Per-vehicle tuning**: VehicleTypes database may override global knobs per vehicle type (Heavy战车 uses Profile A values, Scout战车 uses Profile B values).
4. **Playtest validation**: Each knob change must be validated via playtest — "feels right" is subjective, need actual player feedback.

---

### Knob Registration

The following knobs will be registered to `design/registry/entities.yaml` as tunable constants:

| Name | Category | Notes |
|------|----------|-------|
| ACCELERATION_BASE | Tuning | Primary driving feel knob |
| DRAG_COEFFICIENT | Tuning | Primary deceleration feel knob |
| MAGIC_COST_PER_CELL | Tuning | Primary economy balance knob |
| BASE_TURN_RATE | Tuning | Primary steering feel knob |
| TURN_SPEED_FACTOR | Tuning | Speed-dependent turn knob |
| COLLISION_PENALTY_FACTOR | Tuning | Collision severity knob |

## Visual/Audio Requirements

### Visual Feedback Requirements

| Event | Visual Effect | Trigger | Intensity Scaling |
|-------|---------------|---------|-------------------|
| **Acceleration start** | Vehicle sprite slight forward tilt (acceleration lean) | ACCELERATING state | Lean angle ∝ acceleration_rate |
| **Stable movement** | Vehicle sprite neutral (no tilt) | MOVING state | None |
| **Deceleration** | Vehicle sprite slight backward tilt (braking lean) | DECELERATING state | Lean angle ∝ deceleration_rate |
| **Collision (正面)** | Screen shake (horizontal jitter), dust particle burst at collision point | BLOCKED state, impact_angle > 0.7 | Shake amplitude ∝ collision severity, particle count ∝ speed at impact |
| **Collision (侧擦)** | Vehicle sprite brief sideways skew, scrape particle trail | MOVING with speed reduction | Skew angle ∝ impact_angle, particle density ∝ speed |
| **Magic depletion** | Vehicle sprite grayscale tint fade (魔能枯竭 visual), surrounding glow dims | DISABLED state | Tint intensity ∝ remaining_magic (gradual before depletion) |
| **Low magic warning** | Vehicle edges glow red pulsing (retreat warning visual) | magic_ratio < 0.20 | Pulse rate ∝ urgency (faster at lower magic) |

### Audio Feedback Requirements

| Event | Sound Design | Trigger | Volume/Pitch Scaling |
|-------|--------------|---------|----------------------|
| **Engine idle** | Low hum (魔导晶石脉动 baseline) | IDLE state | Volume ∝ base_speed (heavier vehicle = louder hum) |
| **Engine accelerating** | Rising pitch hum (魔能流动加速) | ACCELERATING state | Pitch sweep from idle_pitch to max_pitch over acceleration duration |
| **Engine stable** | Constant mid-pitch hum (稳定运转) | MOVING state | Volume ∝ current_speed, pitch constant |
| **Engine decelerating** | Falling pitch hum (魔能流动减速) | DECELERATING state | Pitch sweep down to idle_pitch |
| **Collision crash** | Metal impact + 魔导 discharge crackle | BLOCKED state | Volume ∝ impact_speed, crackle intensity ∝ collision severity |
| **Collision scrape** | Metal grind + dust rustle | Side collision | Volume ∝ impact_angle, duration ∝ scrape distance |
| **Magic depleted** | Emergency shutdown siren + silence fallback | DISABLED state | Siren loops until player action, then engine goes silent |
| **Low magic warning** | Pulsing warning tone (retreat alert) | magic_ratio < 0.20 | Pulse frequency ∝ urgency, tone pitch lowers as magic depletes |

### Visual/Audio Integration Notes

- All sounds are 魔导科技风格 — no diesel/gasoline engine sounds. Engine hum = 魔导晶石脉动 (crystal resonance), not mechanical combustion.
- Collision sounds include 魔导 discharge — impact causes brief magic energy discharge crackle, reinforcing Pillar 4 aesthetic.
- Low magic warning audio/visual must be **noticeable but not annoying** — see Edge Case #8 for intensity scaling.
- All feedback timed to frame precision — audio triggers on collision detection frame, visual effects apply immediately in same frame.

## UI Requirements

### HUD Display Elements

| Element | Display Content | Update Frequency | Visibility Condition |
|---------|-----------------|------------------|----------------------|
| **Speed indicator** | Current speed (cells/sec or percentage) | Every frame | Always visible when vehicle deployed |
| **Movement state icon** | Icon indicating IDLE/MOVING/ACCELERATING/DECELERATING/BLOCKED | On state change | Always visible when vehicle deployed |
| **Magic consumption rate** | Current magic cost per second (derived from speed × cost_per_cell) | Every frame | Visible when magic < 80% |
| **Distance traveled** | Cumulative cells traveled this deployment | Every MAGIC_ACCUMULATION_INTERVAL frames | Visible in exploration mode |
| **Load indicator** | Current load ratio (percentage or bar) | On load change | Always visible when vehicle deployed |
| **Direction indicator** | Compass showing vehicle facing direction | Every frame | Optional (toggle in settings) |

### Warning UI Elements

| Element | Trigger | Display Style | Dismissal |
|---------|---------|---------------|-----------|
| **Low magic warning** | magic_ratio < 0.20 | Red pulsing banner at top of HUD, "魔能不足" text | Auto-dismiss when magic > 0.25 or player acknowledges |
| **Collision alert** | BLOCKED state | Brief flash icon at collision location | Auto-dismiss after 0.5 seconds |
| **Magic depleted alert** | DISABLED state | Full-screen overlay "魔能耗尽 — 战车瘫痪", walk back prompt | Player must initiate walk back action |
| **Overload warning** | load_ratio > 1.0 | Yellow banner "超载", speed penalty shown | Auto-dismiss when load < 1.0 |

### UI Integration Notes

- All HUD elements defer to HUD系统 (#49) for final design — this section specifies data requirements only.
- Speed indicator format: percentage (0-100%) recommended for player comprehension, cells/sec for debugging.
- Movement state icons: simple shape-coded (◇ IDLE, ◆ MOVING, ▲ ACCELERATING, ▼ DECELERATING, ✖ BLOCKED).
- Warning UI must not block gameplay — overlay style is non-blocking, player can still see game world.

## Acceptance Criteria

Testable success conditions organized by category. Each criterion must be independently verifiable by QA.

### Category 1: Input Processing (8 criteria)

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC-DRV-001 | `InputManager.get_vector()` returns correct normalized Vector2 for all direction combinations (forward/backward/left/right) | Unit test: mock input, verify vector output |
| AC-DRV-002 | Keyboard input applies digital ramp curve (300ms to reach 1.0 magnitude) | Integration test: hold key for 150ms, verify magnitude ≈ 0.5 |
| AC-DRV-003 | Gamepad input returns raw analog value (no ramp applied) | Integration test: move stick to 50%, verify magnitude = 0.5 |
| AC-DRV-004 | Input magnitude 0.0 triggers DECELERATING state within 1 frame | Unit test: set input to 0, verify state transition |
| AC-DRV-005 | Input magnitude > 0.01 triggers ACCELERATING state when vehicle in IDLE | Unit test: set input to 0.5, verify IDLE→ACCELERATING |
| AC-DRV-006 | Simultaneous forward+backward input resolved to net vector (forward - backward) | Unit test: press both, verify net magnitude |
| AC-DRV-007 | Input device switch (keyboard→gamepad) maintains speed continuity | Integration test: move at 2.0 cells/sec, switch device, verify speed unchanged |
| AC-DRV-008 | Input smoothing window (3 frames) prevents speed oscillation from micro-input changes | Integration test: toggle input 0.3→0.8→0.3 in 0.5s, verify smoothed speed |

---

### Category 2: Speed Calculation (12 criteria)

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC-DRV-009 | Target speed formula: `base_speed × load_modifier × input_magnitude × max_speed_ratio` produces correct values | Unit test: plug test values, verify output matches formula |
| AC-DRV-010 | Empty load (load_ratio=0.0): target_speed = base_speed × 1.0 × input_magnitude | Unit test: verify load_modifier=1.0 for empty |
| AC-DRV-011 | Full load (load_ratio=1.0): target_speed = base_speed × 0.85 × input_magnitude | Unit test: verify load_modifier=0.85 for full |
| AC-DRV-012 | Overload (load_ratio>1.0): target_speed clamped to base_speed × 0.7 × input_magnitude | Unit test: load_ratio=1.5, verify modifier=0.7 (clamp) |
| AC-DRV-013 | Acceleration rate: `ACCELERATION_BASE × load_accel_penalty` produces correct values | Unit test: verify formula with test load_ratios |
| AC-DRV-014 | Speed increases toward target at acceleration_rate per frame | Integration test: accelerate from 0, measure time to reach target |
| AC-DRV-015 | Speed does not overshoot target (clamp to max_change) | Unit test: verify current_speed never exceeds target |
| AC-DRV-016 | Deceleration rate: `current_speed × DRAG_COEFFICIENT × delta` produces correct values | Unit test: verify formula with test speeds |
| AC-DRV-017 | Speed decays exponentially (not linear) when no input | Integration test: measure speed decay curve over 3 seconds |
| AC-DRV-018 | Speed reaches IDLE_THRESHOLD (0.1) within reasonable time (≤ 3 sec at max speed, DRAG=1.0) | Integration test: max speed→no input, measure stop time |
| AC-DRV-019 | `VehicleAttribute.set_current_speed()` called every frame with updated value | Integration test: verify VehicleAttribute current_speed matches driving system |
| AC-DRV-020 | Current speed is never negative (clamp to 0.0) | Unit test: apply deceleration at 0.0 speed, verify remains 0.0 |

---

### Category 3: Collision Detection (10 criteria)

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC-DRV-021 | `CollisionManager.check_swept_collision()` called before every movement | Unit test: verify collision check in movement path |
| AC-DRV-022 | Collision detected → motion truncated to valid_motion (no penetration) | Integration test: drive into wall, verify position at collision point |
| AC-DRV-023 | 正面撞击 (impact_angle>0.7): current_speed → 0.0 (hard stop) | Integration test: collide head-on, verify speed=0 |
| AC-DRV-024 | 侧擦 (impact_angle 0.3-0.7): current_speed × 0.7 | Integration test: side collision, verify 30% reduction |
| AC-DRV-025 | 轻擦 (impact_angle<0.3): current_speed × 0.95 | Integration test: light scrape, verify 5% reduction |
| AC-DRV-026 | Collision triggers BLOCKED state (if speed near zero) or MOVING (if partial reduction) | Integration test: verify state transition per impact angle |
| AC-DRV-027 | `vehicle_collision` signal emitted with collision_cell, severity parameters | Integration test: collide, verify signal emission |
| AC-DRV-028 | Multiple collision cells in path resolved at first encountered cell | Integration test: drive through multi-cell wall, verify single collision point |
| AC-DRV-029 | No collision (collision_result.collision=false): full motion applied | Integration test: drive in open area, verify full movement |
| AC-DRV-030 | Collision response does not tunnel through wall (position remains outside solid cell) | Integration test: high-speed collision, verify no penetration |

---

### Category 4: Magic Consumption (8 criteria)

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC-DRV-031 | Magic cost formula: `distance × MAGIC_COST_PER_CELL × load_cost_modifier` produces correct values | Unit test: verify formula with test distances |
| AC-DRV-032 | Empty load (load_ratio≤1.0): load_cost_modifier = 1.0 | Unit test: verify modifier for empty |
| AC-DRV-033 | Overload (load_ratio>1.0): load_cost_modifier = 1.0 + (load_ratio-1.0) × penalty (max 1.5) | Unit test: verify modifier for overload |
| AC-DRV-034 | Magic consumed only when vehicle_state = DEPLOYED | Integration test: GARAGE_IDLE state, verify no consumption |
| AC-DRV-035 | Magic accumulated per frame, deducted every MAGIC_ACCUMULATION_INTERVAL frames | Integration test: measure deduction frequency |
| AC-DRV-036 | `VehicleAttribute.apply_magic_energy_cost()` returns success when magic available | Unit test: mock sufficient magic, verify return true |
| AC-DRV-037 | Magic depleted: `apply_magic_energy_cost()` returns false, DISABLED state triggered | Integration test: exhaust magic, verify DISABLED state |
| AC-DRV-038 | Magic depleted: current_speed → 0.0, position frozen, `magic_energy_depleted` signal emitted | Integration test: exhaust magic while moving, verify stop and signal |

---

### Category 5: Steering/Turning (6 criteria)

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC-DRV-039 | Turn rate formula: `BASE_TURN_RATE × (1.0 - speed_ratio × TURN_SPEED_FACTOR)` produces correct values | Unit test: verify formula with test speeds |
| AC-DRV-040 | Idle speed (speed_ratio=0.0): turn_rate = BASE_TURN_RATE (max turn) | Unit test: verify turn rate at 0.0 speed |
| AC-DRV-041 | Full speed (speed_ratio=1.0): turn_rate = BASE_TURN_RATE × 0.5 (min turn) | Unit test: verify turn rate at max speed |
| AC-DRV-042 | Direction change does not overshoot target direction (clamp to max_turn) | Integration test: rapid input change, verify gradual turn |
| AC-DRV-043 | Velocity direction updated via rotation (not instant snap) | Integration test: turn input, verify velocity direction change |
| AC-DRV-044 | Turning applies speed penalty: `current_speed × (1.0 - turn_penalty × delta)` | Integration test: turn while moving, verify speed reduction |

---

### Category 6: State Management (10 criteria)

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC-DRV-045 | All 5 movement states (IDLE/MOVING/ACCELERATING/DECELERATING/BLOCKED) reachable via valid transitions | Integration test: trace all state transitions |
| AC-DRV-046 | IDLE state: current_speed < IDLE_THRESHOLD, no input | Unit test: verify IDLE condition |
| AC-DRV-047 | MOVING state: current_speed ≥ IDLE_THRESHOLD, stable speed (|Δspeed| < ACCEL_STABLE_THRESHOLD) | Unit test: verify MOVING condition |
| AC-DRV-048 | ACCELERATING state: speed increasing (Δspeed > ACCEL_STABLE_THRESHOLD) | Unit test: verify ACCELERATING condition |
| AC-DRV-049 | DECELERATING state: speed decreasing (Δspeed < -ACCEL_STABLE_THRESHOLD), no input | Unit test: verify DECELERATING condition |
| AC-DRV-050 | BLOCKED state: collision detected, speed near zero | Unit test: verify BLOCKED condition |
| AC-DRV-051 | State transition: IDLE → ACCELERATING (input > 0.01) | Integration test: apply input from IDLE, verify transition |
| AC-DRV-052 | State transition: MOVING → DECELERATING (input = 0) | Integration test: remove input while MOVING, verify transition |
| AC-DRV-053 | State transition: Any → IDLE (magic depleted) | Integration test: exhaust magic, verify IDLE state |
| AC-DRV-054 | `movement_state_changed` signal emitted on every state transition | Integration test: trigger transition, verify signal emission |

---

### Category 7: Integration & Signals (8 criteria)

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC-DRV-055 | `VehicleAttribute.get_current_speed()` returns correct value at frame start | Integration test: verify VehicleAttribute speed matches driving system |
| AC-DRV-056 | `VehicleAttribute.get_vehicle_state()` blocks driving when state ≠ DEPLOYED | Integration test: GARAGE_IDLE state, verify no movement |
| AC-DRV-057 | `CollisionManager.check_swept_collision()` receives correct vehicle_bounds and motion | Integration test: verify collision query parameters |
| AC-DRV-058 | `VehicleAttribute.set_current_speed()` updates VehicleAttribute every frame | Integration test: verify VehicleAttribute reflects driving system speed |
| AC-DRV-059 | `speed_changed` signal emitted when speed crosses threshold | Integration test: speed change > threshold, verify signal |
| AC-DRV-060 | `magic_consumed` signal emitted with amount and remaining parameters | Integration test: consume magic, verify signal emission |
| AC-DRV-061 | `vehicle_collision` signal received by AudioSystem, VehicleDamage consumers | Integration test: collide, verify downstream signal handling |
| AC-DRV-062 | `movement_state_changed` signal received by AudioSystem, HUD consumers | Integration test: state change, verify downstream signal handling |

---

### Category 8: Edge Cases (12 criteria)

| ID | Criterion | Test Method |
|----|-----------|-------------|
| AC-DRV-063 | Zero input while moving: DECELERATING state entered, speed decays via drag formula | Integration test: full speed→no input, verify deceleration curve |
| AC-DRV-064 | Collision during acceleration: speed reduced per formula, acceleration resumes from reduced speed | Integration test: accelerate→collide→resume, verify speed continuity |
| AC-DRV-065 | Magic depleted during movement: DISABLED state triggered, speed → 0.0, position frozen | Integration test: exhaust magic while moving, verify stop |
| AC-DRV-066 | Overload speed clamp: load_modifier ≥ 0.7 (never slower than 30% reduction) | Unit test: verify modifier clamp for extreme overload |
| AC-DRV-067 | Multiple collision in single frame: resolved at first cell, remaining motion discarded | Integration test: drive through multi-cell wall, verify single collision |
| AC-DRV-068 | Input switch mid-drive: speed continuity maintained, acceleration curve continues | Integration test: switch device while moving, verify speed unchanged |
| AC-DRV-069 | Vehicle state change (DEPLOYED→GARAGE): speed → 0.0, velocity cleared, magic stops | Integration test: return to garage, verify clean reset |
| AC-DRV-070 | Collision while magic below threshold (0.20): feedback amplified (vibration +20%, shake +30%) | Integration test: low magic collision, verify feedback intensity |
| AC-DRV-071 | Speed oscillation prevention: input smoothing (3-frame window) applied | Integration test: rapid input toggle, verify smoothed response |
| AC-DRV-072 | Conflicting input (forward+backward): net magnitude calculated, treated as valid if > 0.01 | Integration test: press both directions, verify net result |
| AC-DRV-073 | Vehicle position frozen when DISABLED (no drift after magic depleted) | Integration test: exhaust magic, verify position stability |
| AC-DRV-074 | BLOCKED state cleared when collision removed + input active → ACCELERATING | Integration test: collide→move away→resume input, verify transition |

---

### Summary

| Category | Criteria Count |
|----------|----------------|
| Input Processing | 8 |
| Speed Calculation | 12 |
| Collision Detection | 10 |
| Magic Consumption | 8 |
| Steering/Turning | 6 |
| State Management | 10 |
| Integration & Signals | 8 |
| Edge Cases | 12 |
| **Total** | **74** |

## Open Questions

### Q-001: VehicleController Architecture Decision (ADR Required)

**Question**: Should VehicleController be a per-instance Node attached to each vehicle entity, or a centralized Autoload singleton managing all vehicle instances?

**Options**:
- **Option A: Per-instance Node**: Each VehicleInstance has a VehicleController node component. Pros: Clean separation, per-instance state encapsulation, Godot idiomatic. Cons: More memory per vehicle, signal routing between instances more complex.
- **Option B: Autoload singleton**: Single VehicleController manages all vehicle instances via instance_id lookup. Pros: Centralized logic, easier global queries (e.g., "find all vehicles in region"), lower memory overhead for parked vehicles. Cons: Singleton pattern can create hidden dependencies, instance_id management complexity.

**Impact**: Affects implementation architecture, signal routing, and how downstream systems query vehicle data. Must resolve via `/architecture-decision` before implementation.

**Recommendation**: Per-instance Node for MVP — cleaner separation, easier to test per-instance behavior. Autoload singleton may be needed if multi-vehicle management (#26) requires global queries.

---

### Q-002: Collision Feedback Timing

**Question**: Should collision feedback (vibration, sound, screen shake) be triggered by VehicleDriving system directly, or emitted via signal to AudioSystem/VibrationManager?

**Options**:
- **Option A: Direct trigger**: VehicleDriving calls AudioSystem.play_collision_sound() and GamepadVibration.trigger() directly. Pros: Tight timing (same frame as collision), simpler implementation. Cons: Cross-system dependency, violates separation of concerns.
- **Option B: Signal emission**: VehicleDriving emits `vehicle_collision` signal with severity parameter, AudioSystem/VibrationManager subscribe and handle feedback. Pros: Clean separation, AudioSystem can adjust feedback independently. Cons: Signal dispatch adds 1-frame delay (unless using call_deferred workaround).

**Impact**: Affects feedback feel precision — same-frame vs. 1-frame delay matters for collision "冲击感".

**Recommendation**: Signal emission for MVP — 1-frame delay acceptable for audio/vibration. Direct trigger if playtest feedback shows timing issue.

---

### Q-003: Input Smoothing Implementation

**Question**: Should input smoothing (Edge Case #9) use rolling average or exponential smoothing?

**Options**:
- **Option A: Rolling average (3-frame window)**: Average of last 3 input magnitudes. Pros: Simple, predictable behavior. Cons: Introduces 2-frame lag (average of frames N, N-1, N-2).
- **Option B: Exponential smoothing**: `smoothed_value = α × raw_input + (1-α) × prev_smoothed`, α = 0.6. Pros: Single-frame response, tunable via α. Cons: Infinite memory (slow decay from old spikes).

**Impact**: Affects driving responsiveness — rolling average = 2-frame lag, exponential = immediate but may over-smooth.

**Recommendation**: Exponential smoothing for MVP — single-frame response is critical for driving feel. α = 0.6 as starting point.

---

### Q-004: Magic Cost Accumulation Write Frequency

**Question**: Should magic cost deduction write to VehicleAttribute every frame or accumulate and write every N frames?

**Options**:
- **Option A: Every frame write**: Immediate deduction on each movement. Pros: Exact magic tracking, no accumulation drift. Cons: Frequent writes may cause performance overhead for save sync.
- **Option B: Accumulated write (N=5 frames)**: Magic cost accumulated per frame, written every 5 frames. Pros: Fewer writes, better performance. Cons: Accumulated value may drift from displayed HUD value, magic depletion detection slightly delayed.

**Impact**: Affects save sync frequency and HUD magic display accuracy.

**Recommendation**: Accumulated write (N=5) for MVP — performance optimization acceptable, drift minimal (≤ 5 frames = 0.08 sec).

---

All questions flagged for architecture/design decision before implementation. Resolve via `/architecture-decision` or design discussion.