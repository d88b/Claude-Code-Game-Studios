# 魔能消耗计算

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 2 (搜打撤节奏)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #19 (from systems-index.md)

## Overview

魔能消耗计算系统是战车所有魔能消耗行为的统一计算层。它为战车驾驶系统(#18)、战车武器系统(#20)及其他魔能消耗系统提供标准化的消耗公式和修正系数计算。该系统从战车属性系统(#17)获取当前魔能状态和载重信息，根据消耗类型(驾驶/武器射击/其他)和上下文参数(载重修正、武器类型、连射模式等)计算魔能消耗量，并调用VehicleAttribute.apply_magic_energy_cost()执行扣减。

**数据层定位**：魔能消耗系统管理消耗计算逻辑：
- 公式定义：为每种消耗类型定义标准公式(驾驶消耗、武器射击消耗)
- 修正系数：载重修正系数(load_cost_modifier)、武器类型修正系数
- 累积追踪：累积消耗值，批量扣减优化
- 消耗速率：每秒消耗量计算，用于HUD显示和撤退预测

**玩家感知层**：玩家通过以下方式直接感知消耗系统：
- HUD魔能消耗速率显示("消耗: 2.5魔能/秒")
- 撤退预测计算("当前魔能可支撑X格路程")
- 武器射击时的魔能闪烁反馈
- 驾驶与射击的魔能竞争感("射击会消耗驾驶魔能")

**系统必要性**：没有消耗计算系统，游戏将无法：
- 统一管理多种魔能消耗来源(驾驶、武器、其他)
- 提供一致的消耗公式供下游系统调用
- 计算撤退预测(魔能剩余可支撑路程)
- 平衡驾驶消耗与武器消耗的资源竞争

**服务于支柱**：
- **Pillar 2 (搜打撤节奏)**：魔能消耗是搜打撤节奏的核心压力源——驾驶消耗魔能，射击消耗魔能，两者竞争有限的续航资源，创造"再搜一个废墟？"的决策压力

**架构决策待定**：本系统依赖VehicleAttribute架构决策(Q-001)，确定魔能消耗计算模块是否与VehicleAttribute合并为统一Autoload，或作为独立计算模块供多系统调用。当前设计假设为独立计算模块(MagicConsumptionCalculator)，通过静态方法或Autoload提供公式计算接口。

## Player Fantasy

玩家在魔能消耗系统中面对的核心体验是**资源的呼吸节奏**——每一次驾驶、每一次射击，魔能像战车的呼吸一样被消耗，玩家感受到的是有限续航的紧迫感和资源分配的决策压力。

### 情感锚定时刻

**出发前的续航计算**：玩家在车库界面检查魔能表时，看着满格的晶石容量。出发前的那一刻是"今天我能走多远？"的规划感——魔能容量决定探索半径，玩家感受到的不是冰冷的数字，而是"我的行动半径"的自由边界。100魔能 → 可探索60格 → 可到达远处的废墟。这种可预测性给予玩家安全感。

**驾驶中的消耗感知**：战车每移动一格，魔能表一格格下降。玩家感受到魔能的"呼吸"——加速时消耗加快，转向时消耗平稳。这不是抽象的资源条，而是战车的"体力消耗"。玩家会自然形成节约驾驶的习惯：不乱跑、直线前进、避免无效绕路。这种驾驶行为的内化是搜打撤节奏的根基。

**射击时的资源竞争**：玩家按下射击键，魔能表突然下降一格。那一刻是"射击还是撤退？"的博弈感——射击消耗魔能，减少续航，但消灭敌人获得战利品。驾驶和射击争夺同一份魔能资源，玩家感受到的是"每一发都要算"的紧张决策。

**撤退前的续航焦虑**：魔能30%，距离车库30格，敌人逼近。玩家面对的是"魔能够不够回去？"的计算焦虑。消耗速率×剩余路程 = 需要魔能。如果不够，必须做出选择：放弃部分战利品减重加速，或冒险战斗获取额外魔能晶石(如果有)。这种撤退前的决策压力是Pillar 2的核心高潮。

### 幻想服务于支柱

**Pillar 2 (搜打撤节奏)**：魔能消耗是搜打撤的"心跳"。驾驶消耗创造移动成本，射击消耗创造战斗成本，两者竞争创造资源决策。撤退不是"我想走"，而是"魔能耗尽不得不走"。消耗系统的存在让"再搜一个废墟？"成为真实的诱惑vs风险博弈。

**Pillar 4 (魔导科技美学)**：魔能消耗的术语体现魔导设定——消耗的不是"燃油"，是"魔力"；消耗速率不是"油耗"，是"魔能脉动频率"。玩家感受到的是魔导战车的独特能量系统。

### 语调示例

```
❌ "移动消耗0.5魔能，射击消耗10魔能"
✓ "战车的魔导晶石随每一次移动而脉动消耗——驾驶消耗魔力，射击抽空能量"

❌ "魔能剩余20%，触发撤退警告"
✓ "魔能晶石的脉动变得急促——战车的续航只剩最后的冲刺距离"

❌ "驾驶和射击共享魔能资源池"
✓ "驾驶和射击争夺同一份魔力储备——每一发魔导炮弹都在减少你的撤退路程"
```

### 没有消耗系统，玩家失去什么

- **搜打撤节奏失去压力源**——没有消耗，探索变成无风险的观光
- **Pillar 2的核心体验崩溃**——"再搜一个废墟？"失去真实的决策困境
- **驾驶和射击失去资源竞争**——射击不消耗魔能，战斗变成无代价的刷怪
- **撤退失去紧迫感**——没有魔能限制，撤退变成随意选择而非压力决策

## Detailed Design

### Core Rules

#### 1. Driving Consumption Calculation

驾驶魔能消耗基于移动距离计算，调用系统提供此公式供VehicleDriving(#18)使用。

**1.1 Driving Magic Cost Formula**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| DRV-COST-001 | 驾驶魔能消耗公式 | `magic_cost = distance_traveled × MAGIC_COST_PER_CELL × load_cost_modifier` |
| DRV-COST-002 | 载重修正系数计算 | `load_cost_modifier = 1.0 + clamp(load_ratio - 1.0, 0.0, OVERLOAD_COST_PENALTY)` |
| DRV-COST-003 | 空载修正系数 | load_ratio ≤ 1.0 → load_cost_modifier = 1.0 |
| DRV-COST-004 | 超载修正系数 | load_ratio > 1.0 → load_cost_modifier = 1.0 + (load_ratio - 1.0) × 0.5 (max 1.5) |

**Interface Method**:

```gdscript
# MagicConsumptionCalculator.gd
static func calculate_driving_magic_cost(
    distance_traveled: float,
    load_ratio: float,
    magic_cost_per_cell: float = MAGIC_COST_PER_CELL
) -> float:
    var load_cost_modifier := 1.0 + clamp(load_ratio - 1.0, 0.0, 0.5)
    return distance_traveled × magic_cost_per_cell × load_cost_modifier
```

---

#### 2. Weapon Shooting Consumption Calculation

武器射击魔能消耗基于武器类型和射击模式计算。

**2.1 Single Shot Magic Cost**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| WPN-COST-001 | 单发射击魔能消耗 | `shot_cost = weapon_base_magic_cost × weapon_efficiency × load_penalty` |
| WPN-COST-002 | 武器基础魔能消耗 | `weapon_base_magic_cost` from WeaponTypeDatabase |
| WPN-COST-003 | 武器效率修正 | `weapon_efficiency` from weapon modification bonus (default 1.0) |
| WPN-COST-004 | 载重惩罚修正 | `load_penalty = 1.0 + clamp(load_ratio × 0.1, 0.0, 0.15)` — 载重增加射击消耗10-15% |

**2.2 Continuous Fire Magic Cost**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| WPN-COST-005 | 连射魔能消耗公式 | `continuous_cost = shot_cost × fire_rate × fire_duration` |
| WPN-COST-006 | 连射模式判定 | `fire_mode` from WeaponTypeDatabase (single/burst/auto) |
| WPN-COST-007 | 连射魔能预扣 | 连射开始时预扣burst全消耗，而非逐发扣除 |

**Interface Methods**:

```gdscript
static func calculate_shot_magic_cost(
    weapon_type_id: int,
    load_ratio: float,
    weapon_efficiency: float = 1.0
) -> float:
    var base_cost := WeaponTypes.get_magic_cost(weapon_type_id)
    var load_penalty := 1.0 + clamp(load_ratio × 0.1, 0.0, 0.15)
    return base_cost × weapon_efficiency × load_penalty

static func calculate_continuous_fire_cost(
    weapon_type_id: int,
    fire_rate: float,
    fire_duration: float,
    load_ratio: float
) -> float:
    var shot_cost := calculate_shot_magic_cost(weapon_type_id, load_ratio)
    return shot_cost × fire_rate × fire_duration
```

---

#### 3. Accumulation and Batching Strategy

魔能消耗累积后批量扣减，优化性能并允许HUD显示实时消耗速率。

**3.1 Accumulation Rule**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| ACCUM-001 | 累积消耗值存储 | `accumulated_magic_cost` per instance, reset after deduction |
| ACCUM-002 | 累积触发阈值 | 累积值达到 `ACCUMULATION_THRESHOLD` (default 5.0 magic) 或经过 `ACCUMULATION_INTERVAL` frames (default 5 frames) |
| ACCUM-003 | 批量扣减调用 | 累积值扣减时调用 `VehicleAttribute.apply_magic_energy_cost(instance_id, accumulated_cost)` |
| ACCUM-004 | 扣减成功处理 | 成功后 `accumulated_magic_cost = 0`，发射 `magic_consumed` 信号 |
| ACCUM-005 | 扣减失败处理 | 失败时 `accumulated_magic_cost` 保持，触发魔能耗尽处理 |

**3.2 Accumulation Interface**

```gdscript
# Per-instance accumulation tracking
var accumulated_magic_cost: float = 0.0
var accumulation_frame_count: int = 0

func accumulate_magic_cost(instance_id: int, cost: float) -> void:
    accumulated_magic_cost += cost
    accumulation_frame_count += 1
    
    if accumulated_magic_cost >= ACCUMULATION_THRESHOLD OR accumulation_frame_count >= ACCUMULATION_INTERVAL:
        _flush_accumulation(instance_id)

func _flush_accumulation(instance_id: int) -> void:
    if accumulated_magic_cost > 0:
        var success := VehicleAttribute.apply_magic_energy_cost(instance_id, accumulated_magic_cost)
        if success:
            emit_signal("magic_consumed", instance_id, accumulated_magic_cost, VehicleAttribute.get_current_magic_energy(instance_id))
            accumulated_magic_cost = 0.0
            accumulation_frame_count = 0
        else:
            # Magic depleted — trigger DISABLED state
            emit_signal("magic_depleted_during_accumulation", instance_id, accumulated_magic_cost)
```

---

#### 4. Consumption Rate Tracking

消耗速率用于HUD显示和撤退预测计算。

**4.1 Consumption Rate Formula**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| RATE-001 | 消耗速率计算 | `consumption_rate = accumulated_magic_cost / elapsed_time` (magic per second) |
| RATE-002 | 速率追踪窗口 | 使用滑动窗口(3秒)计算平均消耗速率，而非瞬时值 |
| RATE-003 | HUD消耗速率显示 | `consumption_rate` 用于HUD显示"消耗: X魔能/秒" |

**4.2 Remaining Range Prediction**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| RANGE-001 | 剩余路程预测 | `remaining_range = current_magic_energy / (consumption_rate / speed)` (cells) |
| RANGE-002 | 撤退预测显示 | 剩余路程用于HUD显示"可支撑X格路程" |
| RANGE-003 | 撤退距离计算 | `retreat_distance = current_position.distance_to(garage_position)` (cells) |
| RANGE-004 | 撤退可行性判断 | `can_retreat = remaining_range >= retreat_distance` |

**Interface Methods**:

```gdscript
static func calculate_consumption_rate(
    accumulated_cost: float,
    elapsed_time: float
) -> float:
    if elapsed_time > 0:
        return accumulated_cost / elapsed_time
    return 0.0

static func calculate_remaining_range(
    current_magic_energy: int,
    consumption_rate: float,
    current_speed: float
) -> float:
    if consumption_rate > 0 and current_speed > 0:
        return current_magic_energy / (consumption_rate / current_speed)
    return current_magic_energy / MAGIC_COST_PER_CELL  # 简化计算(无消耗速率时)

static func can_retreat_to_garage(
    current_magic_energy: int,
    current_position: Vector2i,
    garage_position: Vector2i,
    consumption_rate: float,
    current_speed: float
) -> bool:
    var retreat_distance := current_position.distance_to(garage_position) / CELL_SIZE
    var remaining_range := calculate_remaining_range(current_magic_energy, consumption_rate, current_speed)
    return remaining_range >= retreat_distance
```

---

#### 5. Consumption Type Registry

消耗类型注册表追踪所有魔能消耗来源。

**5.1 Consumption Type Enumeration**

| Type ID | Type Name | Description | Primary Consumer |
|---------|-----------|-------------|------------------|
| 0 | `DRIVING` | 驾驶移动消耗 | VehicleDriving (#18) |
| 1 | `WEAPON_SHOT` | 武器单发射击消耗 | VehicleWeapon (#20) |
| 2 | `WEAPON_CONTINUOUS` | 武器连射消耗 | VehicleWeapon (#20) |
| 3 | `SPECIAL_ABILITY` | 特殊技能消耗 | Alpha功能 |
| 4 | `PASSIVE_DRAIN` | 被动消耗(如护盾维持) | Alpha功能 |

**5.2 Consumption Record Structure**

```gdscript
# Per-consumption event record
class ConsumptionRecord:
    var instance_id: int
    var consumption_type: int  # ConsumptionType enum
    var cost_amount: float
    var timestamp: float  # game time
    var context: Dictionary  # {weapon_type_id: int, distance: float, etc.}
```

---

### States and Transitions

魔能消耗计算系统是**无状态计算模块**。它提供静态计算方法和累积追踪，不维护状态机。

**无状态设计理由**:
- 纯计算逻辑，不需要状态转换
- 累积值是临时变量，每次扣减后清空
- 调用系统(VehicleDriving, VehicleWeapon)负责触发计算

**累积追踪变量(临时)**:

| Variable | Type | Lifecycle |
|----------|------|-----------|
| `accumulated_magic_cost` | float | 累积→扣减→清空 |
| `accumulation_frame_count` | int | 累积→扣减→清空 |
| `consumption_rate_history[]` | Array[float] | 滑动窗口(3秒) |

---

### Interactions with Other Systems

#### Upstream Systems

| System | Interface | Data Consumed | Timing |
|--------|-----------|---------------|--------|
| **战车属性系统 (#17)** | `VehicleAttribute.get_current_magic_energy(instance_id)` | current_magic_energy | Every deduction |
| **战车属性系统 (#17)** | `VehicleAttribute.get_load_ratio(instance_id)` | load_ratio | Every calculation |
| **战车属性系统 (#17)** | `VehicleAttribute.apply_magic_energy_cost(instance_id, cost)` | Magic deduction | Accumulation flush |
| **战车类型数据库 (#6)** | `VehicleTypes.get_base_speed()` | base_speed | Remaining range calculation |
| **武器类型数据库** | `WeaponTypes.get_magic_cost(weapon_type_id)` | weapon_base_magic_cost | Shooting calculation |
| **TileMap世界系统 (#1)** | `CELL_SIZE = 32` | Grid cell size | Distance/range calculation |

#### Downstream Consumer Systems

| System | Interface | Data Provided | Timing |
|--------|-----------|---------------|--------|
| **战车驾驶系统 (#18)** | `calculate_driving_magic_cost(distance, load_ratio)` | Driving magic cost | Every movement |
| **战车武器系统 (#20)** | `calculate_shot_magic_cost(weapon_type_id, load_ratio)` | Shot magic cost | Every shot |
| **战车武器系统 (#20)** | `calculate_continuous_fire_cost(...)` | Continuous fire cost | Burst/auto fire |
| **HUD系统 (#49)** | `get_consumption_rate(instance_id)` | Consumption rate per second | HUD update |
| **HUD系统 (#49)** | `calculate_remaining_range(...)` | Remaining range (cells) | HUD prediction display |
| **撤退判定系统 (#32)** | `can_retreat_to_garage(...)` | Retreat feasibility check | Every retreat check |

#### Signal Architecture

| Signal | Parameters | Trigger | Consumers |
|--------|------------|---------|-----------|
| `magic_consumed` | `instance_id: int, amount: float, remaining: int` | Accumulation flush success | HUD (#49), AudioSystem (#52) |
| `magic_depleted_during_accumulation` | `instance_id: int, pending_cost: float` | Deduction failure | VehicleAttribute (DISABLED trigger) |
| `consumption_rate_changed` | `instance_id: int, rate: float` | Rate threshold change | HUD (#49) |

## Formulas

### Formula 1: Driving Magic Cost

```
magic_cost = distance_traveled × MAGIC_COST_PER_CELL × load_cost_modifier
```

**Variables:**

| Symbol | Type | Range | Description | Source |
|--------|------|-------|-------------|--------|
| `magic_cost` | float | 0.0–∞ | Total magic energy consumed | Output |
| `distance_traveled` | float | 0.0–∞ | Distance in cells | VehicleDriving (#18) |
| `MAGIC_COST_PER_CELL` | float | 0.5 | Base cost per cell | Tuning Knob |
| `load_cost_modifier` | float | 1.0–1.5 | Load multiplier factor | Formula 1a |

**Sub-Formula 1a: Load Cost Modifier**

```
load_cost_modifier = 1.0 + clamp(load_ratio - 1.0, 0.0, OVERLOAD_COST_PENALTY)
```

| Symbol | Type | Range | Description | Source |
|--------|------|-------|-------------|--------|
| `load_ratio` | float | 0.0–1.5 | current_load / max_load | VehicleAttribute (#17) |
| `OVERLOAD_COST_PENALTY` | float | 0.5 | Maximum penalty cap | Tuning Knob |

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| distance=0, load_ratio=1.0 | magic_cost=0 | Zero travel = zero cost |
| distance=10, load_ratio=0.5 | magic_cost=5.0 | Underload: modifier=1.0 |
| distance=10, load_ratio=1.0 | magic_cost=5.0 | Full load: modifier=1.0 |
| distance=10, load_ratio=1.5 | magic_cost=7.5 | Overload: modifier=1.5 |
| distance=10, load_ratio=2.0 | magic_cost=7.5 | Extreme overload clamped |

---

### Formula 2: Weapon Shot Magic Cost

```
shot_cost = weapon_base_magic_cost × weapon_efficiency × load_penalty
```

**Variables:**

| Symbol | Type | Range | Description | Source |
|--------|------|-------|-------------|--------|
| `shot_cost` | float | 0.0–∞ | Magic cost per shot | Output |
| `weapon_base_magic_cost` | float | 5.0–20.0 | Weapon type base cost | WeaponTypeDatabase |
| `weapon_efficiency` | float | 0.8–1.2 | Modification bonus | VehicleWeapon (#20) |
| `load_penalty` | float | 1.0–1.15 | Load shooting penalty | Formula 2a |

**Sub-Formula 2a: Load Penalty (Shooting)**

```
load_penalty = 1.0 + clamp(load_ratio × 0.1, 0.0, 0.15)
```

| Symbol | Type | Range | Description | Source |
|--------|------|-------|-------------|--------|
| `load_ratio` | float | 0.0–1.5 | current_load / max_load | VehicleAttribute (#17) |

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| base=10, efficiency=1.0, load_ratio=0.0 | shot_cost=10.0 | Empty load: penalty=1.0 |
| base=10, efficiency=1.0, load_ratio=1.0 | shot_cost=11.0 | Full load: penalty=1.1 |
| base=10, efficiency=1.0, load_ratio=1.5 | shot_cost=11.5 | Overload: penalty=1.15 (clamped) |
| base=10, efficiency=0.8, load_ratio=1.0 | shot_cost=8.8 | Efficient weapon reduces cost |
| base=10, efficiency=1.2, load_ratio=1.0 | shot_cost=13.2 | Inefficient weapon increases cost |

---

### Formula 3: Continuous Fire Cost

```
continuous_cost = shot_cost × fire_rate × fire_duration
```

**Variables:**

| Symbol | Type | Range | Description | Source |
|--------|------|-------|-------------|--------|
| `continuous_cost` | float | 0.0–∞ | Total magic for burst | Output |
| `shot_cost` | float | 0.0–∞ | Per-shot cost | Formula 2 |
| `fire_rate` | float | 1.0–10.0 | Shots per second | WeaponTypeDatabase |
| `fire_duration` | float | 0.1–5.0 | Duration in seconds | VehicleWeapon (#20) |

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| shot_cost=10, fire_rate=5, duration=0.5 | continuous_cost=25.0 | Short burst |
| shot_cost=10, fire_rate=5, duration=2.0 | continuous_cost=100.0 | Full auto burst |
| shot_cost=5, fire_rate=10, duration=1.0 | continuous_cost=50.0 | High fire rate |
| duration=0 | continuous_cost=0 | Zero duration = zero cost |

---

### Formula 4: Consumption Rate

```
consumption_rate = accumulated_magic_cost / elapsed_time
```

**Variables:**

| Symbol | Type | Range | Description | Source |
|--------|------|-------|-------------|--------|
| `consumption_rate` | float | 0.0–∞ | Magic per second | Output |
| `accumulated_magic_cost` | float | 0.0–∞ | Accumulated cost | Internal tracking |
| `elapsed_time` | float | 0.0–3.0 | Time window (seconds) | Sliding window (3s) |

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| accumulated=15, elapsed=3.0 | rate=5.0 | Normal 3-second window |
| accumulated=0, elapsed=3.0 | rate=0.0 | No consumption |
| accumulated=15, elapsed=0.5 | rate=30.0 | Short window spikes |
| elapsed=0 | rate=0.0 | Division by zero guard |

**Implementation Note:** Uses sliding window (3 seconds) to average consumption rate, not instantaneous value. This smooths HUD display and prevents jitter.

---

### Formula 5: Remaining Range

```
remaining_range = current_magic_energy / (consumption_rate / speed)
```

Alternative (simplified, when consumption_rate unavailable):

```
remaining_range = current_magic_energy / MAGIC_COST_PER_CELL
```

**Variables:**

| Symbol | Type | Range | Description | Source |
|--------|------|-------|-------------|--------|
| `remaining_range` | float | 0.0–∞ | Travelable distance (cells) | Output |
| `current_magic_energy` | int | 0–100 | Current magic remaining | VehicleAttribute (#17) |
| `consumption_rate` | float | 0.0–∞ | Magic per second | Formula 4 |
| `speed` | float | 2.0–8.0 | Current speed (cells/sec) | VehicleDriving (#18) |
| `MAGIC_COST_PER_CELL` | float | 0.5 | Base cost per cell | Tuning Knob |

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| magic=100, rate=5.0, speed=5.0 | range=100.0 | Full magic, normal speed |
| magic=50, rate=5.0, speed=5.0 | range=50.0 | Half magic |
| magic=10, rate=5.0, speed=5.0 | range=10.0 | Low magic warning |
| magic=0, rate=5.0, speed=5.0 | range=0.0 | Depleted = cannot move |
| rate=0, speed=5.0 | range=200.0 (simplified) | No consumption = full range via simplified formula |

---

### Formula 6: Retreat Feasibility

```
can_retreat = remaining_range >= retreat_distance
```

**Variables:**

| Symbol | Type | Range | Description | Source |
|--------|------|-------|-------------|--------|
| `can_retreat` | bool | true/false | Feasibility result | Output |
| `remaining_range` | float | 0.0–∞ | Travelable distance | Formula 5 |
| `retreat_distance` | float | 0.0–∞ | Distance to garage (cells) | TileMap (#1) |

**Sub-Formula 6a: Retreat Distance**

```
retreat_distance = current_position.distance_to(garage_position) / CELL_SIZE
```

| Symbol | Type | Range | Description | Source |
|--------|------|-------|-------------|--------|
| `current_position` | Vector2i | World bounds | Player position | VehicleDriving (#18) |
| `garage_position` | Vector2i | Fixed | Garage location | TileMap (#1) |
| `CELL_SIZE` | int | 32 | Pixels per cell | TileMap (#1) |

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| remaining_range=100, retreat_distance=30 | can_retreat=true | Safe retreat |
| remaining_range=30, retreat_distance=30 | can_retreat=true | Exact threshold |
| remaining_range=29, retreat_distance=30 | can_retreat=false | Cannot reach garage |
| remaining_range=0, retreat_distance=30 | can_retreat=false | Stranded |

## Edge Cases

| ID | Edge Case | Expected Behavior | Rationale |
|----|-----------|-------------------|-----------|
| **EC-001** | Magic depleted during accumulation flush | `apply_magic_energy_cost()` returns false → `magic_depleted_during_accumulation` signal emitted → accumulated cost preserved for retry | Player shouldn't lose track of pending cost; signal triggers DISABLED state in VehicleAttribute |
| **EC-002** | Zero distance traveled | Driving cost formula returns 0.0 | No movement = no consumption (formula naturally handles this) |
| **EC-003** | Zero fire duration | Continuous fire cost returns 0.0 | No firing = no consumption (formula naturally handles this) |
| **EC-004** | Zero elapsed_time in consumption rate | `consumption_rate = 0.0` (division guard) | Prevent division by zero; indicates no time passed |
| **EC-005** | Zero speed in remaining range calculation | Use simplified formula: `remaining_range = current_magic_energy / MAGIC_COST_PER_CELL` | Cannot compute rate-based range when stationary; fallback to theoretical max |
| **EC-006** | Zero consumption rate | Use simplified formula (same as EC-005) | If no consumption, rate-based calculation invalid; use theoretical max |
| **EC-007** | Load ratio = 0.0 (empty load) | `load_cost_modifier = 1.0`, `load_penalty = 1.0` | Empty load = no penalty; clamp formula ensures this |
| **EC-008** | Load ratio > 1.5 (extreme overload) | `load_cost_modifier = 1.5`, `load_penalty = 1.15` (both clamped) | Prevent runaway penalties; cap at max values |
| **EC-009** | Load ratio < 0.0 (invalid data) | Clamp to 0.0 before calculation | Invalid input protection; treat as empty load |
| **EC-010** | Weapon efficiency = 0.0 | `shot_cost = 0.0` | Zero efficiency = free shots (likely data error; log warning) |
| **EC-011** | Weapon efficiency > 2.0 | Clamp to 2.0 max | Prevent extreme cost multipliers |
| **EC-012** | Negative weapon base cost | Clamp to 0.0 minimum; log error | Invalid data protection |
| **EC-013** | Accumulation exactly at threshold (5.0 magic) | Flush immediately on next accumulate call | Threshold crossing triggers flush |
| **EC-014** | Continuous fire interrupted (player cancels mid-burst) | Pre-deducted full burst cost remains consumed | Pre-deduction model; cannot refund partial burst |
| **EC-015** | Retreat distance exactly equals remaining range | `can_retreat = true` | Exact threshold is feasible (player can arrive with 0 magic) |
| **EC-016** | Current magic energy = 0 | `remaining_range = 0.0`, `can_retreat = false` (unless retreat_distance = 0) | Stranded scenario; cannot move |
| **EC-017** | Player at garage (retreat_distance = 0) | `can_retreat = true` regardless of magic | Already at safety |
| **EC-018** | Negative current_magic_energy (data corruption) | Clamp to 0 before calculation | Invalid state protection; treat as depleted |
| **EC-019** | Weapon type ID invalid (not in database) | Return `shot_cost = 0.0`, log warning "Unknown weapon type ID" | Graceful failure; prevents crash on missing data |
| **EC-020** | Fire rate = 0 in continuous fire | `continuous_cost = 0.0` | Zero fire rate = no shots (data error likely) |
| **EC-021** | Negative distance_traveled input | Clamp distance to 0.0 minimum; log warning "Negative distance" | Invalid input protection; treat as zero travel |
| **EC-022** | Remaining range formula produces negative output | Clamp `remaining_range` to 0.0 minimum | Output protection; prevents negative range display on HUD |

## Dependencies

### Upstream Dependencies (This System Depends On)

| System ID | System Name | Interface Used | Status | Notes |
|-----------|-------------|----------------|--------|-------|
| **#17** | 战车属性系统 | `get_current_magic_energy()`, `get_load_ratio()`, `apply_magic_energy_cost()` | Designed | Core data source for magic state and load |
| **#6** | 战车类型数据库 | `get_base_speed()` | Designed | Used in remaining range calculation fallback |
| **#1** | TileMap世界系统 | `CELL_SIZE = 32` | Designed | Distance/range conversion constant |
| **WeaponDB** | 武器类型数据库 | `get_magic_cost(weapon_type_id)` | Not Started | Weapon base cost lookup (assumed interface) |

**Undesigned dependencies**: 武器类型数据库 has no GDD yet. This GDD assumes the interface `WeaponTypes.get_magic_cost(weapon_type_id: int) -> float`. Flag as provisional until designed.

---

### Downstream Dependencies (Systems That Depend On This)

| System ID | System Name | Interface Called | Status | Notes |
|-----------|-------------|------------------|--------|-------|
| **#18** | 战车驾驶系统 | `calculate_driving_magic_cost()` | Designed | Driving cost per movement |
| **#20** | 战车武器系统 | `calculate_shot_magic_cost()`, `calculate_continuous_fire_cost()` | Not Started | Weapon cost per shot/burst |
| **#49** | HUD系统 | `get_consumption_rate()`, `calculate_remaining_range()` | Not Started | HUD display data |
| **#32** | 撤退判定系统 | `can_retreat_to_garage()` | Not Started | Retreat feasibility check |

**Bidirectional confirmation**: 
- #18 (VehicleDriving) GDD Section G (Dependencies) must list #19 as downstream consumer → **CONFIRMED** (will verify after this GDD is written)
- #20, #49, #32 GDDs not yet written → will need to add this dependency when authored

---

### Dependency Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| Weapon type database interface undefined | **MEDIUM** | Define provisional interface in this GDD; validate when WeaponDB is designed |
| #20 (VehicleWeapon) undesigned | **LOW** | Interface assumptions documented; easy to adjust |
| #32 (撤退判定) depends on this + #18 + #17 | **MEDIUM** | Coordinate design order: #17 → #19 → #20 → #18 → #32 |

## Tuning Knobs

### Tuning Knobs

| Knob ID | Knob Name | Value | Range | Affects | Owner | Notes |
|---------|-----------|-------|-------|---------|-------|-------|
| **TK-001** | `MAGIC_COST_PER_CELL` | 0.5 | 0.3–1.0 | Driving cost per cell | **Shared** (from #18) | Already registered in entities.yaml — consumption system uses this shared constant |
| **TK-002** | `OVERLOAD_COST_PENALTY` | 0.5 | 0.3–0.8 | Max load modifier cap | #19 | Higher value = harsher overload penalty on driving |
| **TK-003** | `ACCUMULATION_THRESHOLD` | 5.0 | 1.0–20.0 | Flush trigger (magic) | #19 | Higher = fewer flushes, smoother HUD but risk of depletion |
| **TK-004** | `ACCUMULATION_INTERVAL` | 5 | 1–30 | Flush trigger (frames) | #19 | Higher = fewer flushes, more per-frame accumulation |
| **TK-005** | `CONSUMPTION_RATE_WINDOW` | 3.0 | 1.0–10.0 | Sliding window (seconds) | #19 | Longer = smoother rate display, less responsive |
| **TK-006** | `MAX_LOAD_PENALTY_SHOOTING` | 0.15 | 0.05–0.25 | Max shooting load penalty | #19 | Higher = overloaded vehicles have higher shooting cost |

---

### Tuning Scenarios

| Scenario | Knobs to Adjust | Expected Effect |
|----------|-----------------|-----------------|
| **Driving feels too cheap** | Increase `MAGIC_COST_PER_CELL` to 0.8 | Exploration radius shrinks; retreat pressure increases |
| **Overload penalty too harsh** | Reduce `OVERLOAD_COST_PENALTY` to 0.3 | Overloaded vehicles burn less magic; load management less critical |
| **HUD rate display jittery** | Increase `CONSUMPTION_RATE_WINDOW` to 5.0 | Smoother display; less responsive to sudden spikes |
| **Accumulation flushes too often** | Increase `ACCUMULATION_THRESHOLD` to 10.0 | Fewer signal emissions; risk of depletion before flush |
| **Shooting cost negligible** | Increase `MAX_LOAD_PENALTY_SHOOTING` to 0.25 | Overloaded vehicles pay 25% extra per shot; resource competition intensifies |

---

### Tuning Validation Advisory

> **⚠️ Playtest Required**: Current default values (MAGIC_COST_PER_CELL=0.5, max_magic=100) allow ~200 cells theoretical range. This may be too generous for Pillar 2 (搜打撤节奏) tension. Validate in MVP playtest:
> - If exploration feels too safe → increase MAGIC_COST_PER_CELL to 0.8 or reduce max_magic
> - If shooting/driving competition feels weak → increase MAX_LOAD_PENALTY_SHOOTING to 0.25-0.30
> - If retreat anxiety is low → use conservative rate (peak rate, not smoothed average) for remaining_range calculation

---

### Constants from Other Systems (Referenced, Not Owned)

| Constant | Value | Source | Usage in #19 |
|----------|-------|--------|--------------|
| `CELL_SIZE` | 32 | TileMap (#1) | Distance/range conversion |
| `MAX_LOAD_RATIO` | 1.5 | VehicleAttribute (#17) | Overload threshold assumption |

## Visual/Audio Requirements

| Requirement ID | Type | Trigger | Effect | Notes |
|----------------|------|---------|--------|-------|
| **VA-001** | Visual | Magic consumption flush | Brief HUD magic bar pulse (0.2s) | Indicates deduction occurred |
| **VA-002** | Visual | Magic depleted during accumulation | Magic bar turns red, warning flash | DISABLED state transition |
| **VA-003** | Visual | High consumption rate (>5 magic/sec) | Rate text turns orange | Visual urgency cue |
| **VA-004** | Visual | Low remaining range (<30 cells) | Range indicator turns red | Retreat warning |
| **VA-005** | Audio | Magic consumption flush | Soft "energy drain" sound | Subtle feedback per flush |
| **VA-006** | Audio | Magic depleted | "energy exhausted" alert sound | Critical warning |
| **VA-007** | Audio | Retreat feasible → not feasible | Warning tone shift | Status change alert |

## UI Requirements

| Requirement ID | UI Element | Data Source | Update Frequency | Notes |
|----------------|------------|-------------|------------------|-------|
| **UI-001** | Magic bar (HUD) | VehicleAttribute.current_magic_energy | Every flush | Primary magic display |
| **UI-002** | Consumption rate text | consumption_rate (Formula 4) | Every 1 second | Format: "X.X 魔能/秒" |
| **UI-003** | Remaining range indicator | remaining_range (Formula 5) | Every 1 second | Format: "可支撑 X 格" |
| **UI-004** | Retreat feasibility icon | can_retreat (Formula 6) | On change | Green = feasible, Red = stranded |
| **UI-005** | Load penalty indicator | load_cost_modifier, load_penalty | On load change | Show penalty percentage |

## Acceptance Criteria

### Driving Consumption

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-001** | `calculate_driving_magic_cost(10, 1.0)` returns exactly 5.0 magic | Unit test: formula with known inputs |
| **AC-002** | `calculate_driving_magic_cost(10, 0.5)` returns exactly 5.0 magic (no underload bonus) | Unit test: load_ratio < 1.0 |
| **AC-003** | `calculate_driving_magic_cost(10, 1.5)` returns exactly 7.5 magic (overload penalty) | Unit test: load_ratio at max penalty |
| **AC-004** | `calculate_driving_magic_cost(0, 1.0)` returns exactly 0.0 magic | Unit test: zero distance |
| **AC-005** | Load modifier clamps at 1.5 maximum regardless of input load_ratio | Unit test: `load_ratio = 2.0` → modifier = 1.5 |

### Weapon Consumption

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-006** | `calculate_shot_magic_cost(weapon_id, 1.0, 1.0)` returns `WeaponTypes.get_magic_cost(weapon_id)` × 1.1 | Unit test: base cost × load penalty |
| **AC-007** | `calculate_shot_magic_cost(weapon_id, 0.0, 1.0)` returns exactly base cost (no penalty) | Unit test: empty load |
| **AC-008** | `calculate_shot_magic_cost(weapon_id, 1.5, 1.0)` returns base cost × 1.15 (max penalty) | Unit test: overload |
| **AC-009** | Weapon efficiency modifier multiplies cost correctly: 0.8 efficiency = 80% cost | Unit test: efficiency factor |
| **AC-010** | Unknown weapon_type_id returns 0.0 cost and logs warning | Unit test: invalid ID handling |

### Continuous Fire

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-011** | `calculate_continuous_fire_cost(weapon_id, 5.0, 2.0, 1.0)` returns `shot_cost × 5 × 2` | Unit test: burst formula |
| **AC-012** | Zero fire_duration returns exactly 0.0 cost | Unit test: zero duration |
| **AC-013** | Zero fire_rate returns exactly 0.0 cost | Unit test: zero rate |

### Accumulation and Flush

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-014** | Accumulated cost below threshold does NOT trigger flush | Unit test: accumulate 3.0 magic → no flush |
| **AC-015** | Accumulated cost at threshold triggers flush on next call | Unit test: accumulate to 5.0 → flush called |
| **AC-016** | Frame count reaching interval triggers flush regardless of amount | Unit test: 5 frames with 1.0 magic → flush |
| **AC-017** | Successful flush emits `magic_consumed` signal with `amount` parameter matching `accumulated_magic_cost` before flush | Integration test: signal parameter verification |
| **AC-018** | Failed flush (current_magic_energy < accumulated_cost) emits `magic_depleted_during_accumulation` signal with `pending_cost` parameter matching accumulated value | Integration test: depletion scenario setup |

### Consumption Rate

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-019** | `calculate_consumption_rate(15.0, 3.0)` returns exactly 5.0 magic/sec | Unit test: rate formula |
| **AC-020** | Zero elapsed_time returns 0.0 rate (division guard) | Unit test: zero time |
| **AC-021** | Sliding window averages rate: feed costs [5.0, 10.0, 5.0] over 3 seconds → rate=5.0 (average), not 10.0 (peak) or instantaneous | Integration test: multi-sample rate input |

### Remaining Range

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-022** | `calculate_remaining_range(100, 5.0, 5.0)` returns exactly 100.0 cells | Unit test: range formula |
| **AC-023** | Zero speed uses simplified formula: `magic / MAGIC_COST_PER_CELL` | Unit test: stationary fallback |
| **AC-024** | Zero consumption_rate uses simplified formula | Unit test: no consumption fallback |
| **AC-025** | Zero magic returns 0.0 range | Unit test: depleted state |

### Retreat Feasibility

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-026** | `can_retreat_to_garage` returns true when remaining_range >= retreat_distance | Unit test: feasible scenario |
| **AC-027** | `can_retreat_to_garage` returns false when remaining_range < retreat_distance | Unit test: stranded scenario |
| **AC-028** | Exact threshold (remaining_range == retreat_distance) returns true | Unit test: edge case |
| **AC-029** | Player at garage (retreat_distance = 0) returns true | Unit test: already safe |

### Signal Architecture

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-030** | `magic_consumed` signal includes instance_id, amount, remaining_magic | Integration test: signal parameters |
| **AC-031** | `consumption_rate_changed` signal fires when rate crosses threshold | Integration test: rate change detection |

### Integration

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-032** | VehicleDriving calls `calculate_driving_magic_cost(distance=1.0, load_ratio)` when vehicle position changes by ≥1 cell | Integration test: caller trigger condition |
| **AC-033** | VehicleAttribute.apply_magic_energy_cost receives flush deductions | Integration test: downstream call |
| **AC-034** | Load ratio from VehicleAttribute.get_load_ratio(instance_id) matches value passed to calculate_driving_magic_cost within same frame | Integration test: data flow synchronization |

## Open Questions

| Question ID | Question | Status | Impact | Resolution Needed By |
|-------------|----------|--------|--------|----------------------|
| **Q-001** | Should MagicConsumptionCalculator be an Autoload singleton or static class methods? | **Open** | Architecture decision affects caller interface design | Before implementation (#18, #20) |
| **Q-002** | Should weapon type database be a separate GDD or merged into existing database? | **Open** | Defines `WeaponTypes.get_magic_cost()` interface existence | Before #20 design |
| **Q-003** | Should accumulation flush happen on frame count OR threshold OR both? | **Resolved** | Current design: both triggers work | — |
| **Q-004** | What is the threshold for `consumption_rate_changed` signal? | **Open** | Defines when HUD updates rate display visually | Before HUD (#49) design |
| **Q-005** | Should continuous fire pre-deduct full burst cost or deduct per-shot? | **Resolved** | Current design: pre-deduct full burst (WPN-COST-007) | — |
| **Q-006** | Where does the magic depletion fallback behavior belong (this system or VehicleAttribute)? | **Open** | Boundary between systems unclear | Before #17/#19 integration |