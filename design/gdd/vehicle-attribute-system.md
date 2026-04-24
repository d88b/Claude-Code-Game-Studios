# 战车属性系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 1 (战车即生命), Pillar 2 (搜打撤节奏)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #17 (from systems-index.md)

## Overview

战车属性系统是管理战车实例运行时状态的核心系统。每个战车实例拥有独立的属性状态：当前耐久值、当前魔能值、载重量、武器装备配置、改装安装状态。该系统从战车类型数据库读取类型定义，初始化实例属性，并为所有下游系统提供统一的属性查询接口。

**数据层定位**：属性系统存储每个战车实例的运行时状态（`VehicleInstance`），包括：
- 耐久状态（current_durability, durability_ratio）
- 魔能状态（current_magic_energy, magic_energy_ratio）
- 运动状态（current_speed, current_load, movement_state）
- 装备状态（equipped_weapons[], installed_modifications[]）

**玩家感知层**：玩家通过以下方式直接感知属性系统：
- HUD耐久条（绿色→黄色→红色渐变，低于30%闪烁警报）
- HUD魔能表（半圆形魔力晶石显示，低于20%发出脉冲警告）
- 出发检查界面（显示耐久/魔能是否满足出发条件）
- 撤退警告触发（当属性低于阈值时UI弹出警告）

**系统必要性**：没有属性系统，游戏将无法：
- 区分不同战车实例的状态（所有战车共享类型定义的静态值）
- 实现耐久消耗和损坏逻辑（战车损坏系统无数据源）
- 实现魔能消耗和续航计算（战车驾驶系统无法追踪魔能消耗）
- 实现撤退判定（撤退阈值系统无法比较当前值与阈值）
- 实现武器装备和改装安装（战车武器/改装系统无法追踪装备状态）

**服务于支柱**：
- **Pillar 1 (战车即生命)**：属性系统是战车的"生命体征监护仪"——耐久是战车的血量，魔能是战车的续航心跳，玩家看着数值变化感受到战车的"生命力"
- **Pillar 2 (搜打撤节奏)**：属性系统追踪魔能消耗和耐久损耗，为撤退判定提供实时数据，创造"再搜一个废墟？"的风险决策

## Player Fantasy

玩家在战车属性系统中面对的核心体验是**钢铁脉搏的监护共鸣**——每一次耐久下降、每一次魔能消耗，都是战车在向玩家传递它的状态，玩家与战车建立起情感纽带。

### 情感锚定时刻

**出发前的生命体检**：玩家在车库界面检查战车状态时，看着耐久条从70%上升到满格（维修完成），魔能表从空槽逐渐填充（魔能补充完成）。那一刻不是冰冷的数值，而是"它准备好带我出去了"的安全感。绿灯亮起时，玩家感受到的是伙伴的承诺："今天我会带你安全回家。"

**战斗中的衰弱恐惧**：当战车被变异狼撕咬，耐久条从绿色滑向黄色；当魔导炮连续发射，魔能表一格格下降。玩家心跳加速——"它撑得住吗？再打一发会不会耗尽魔能？"这种对战车"生命"的担忧，不是对失败惩罚的恐惧，而是对伙伴的关心。

**撤退时的求生抉择**：当魔能跌破20%，警告脉冲开始；当耐久跌破30%，红色条开始闪烁。玩家面对的是"再搜一个废墟？"的诱惑与"它撑不住了"的危机感之间的博弈。撤退不是逃避，是保护伙伴的决策。

**返回后的疗愈满足**：驾驶伤痕累累的战车返回地堡，看着维修槽一格一格修复耐久，看着魔能晶石一粒一粒填充魔能。那一刻是疗愈——"它回家了，我们来照顾它。"

### 幻想服务于支柱

**Pillar 1 (战车即生命)**：属性系统的数值变化是战车的"心跳"——耐久条是战车的生命线，魔能表是战车的能量脉搏。玩家不是在管理"资源"，而是在监护"伙伴的生命体征"。撤退阈值不是抽象数字，是战车在呻吟："我撑不住了，带我回家。"

**Pillar 4 (魔导科技美学)**：属性的视觉呈现体现魔导科技设定——魔能表不是"燃油表"，是"魔力晶石容量显示"；耐久条不是"HP条"，是"装甲完整性指示器"。术语和视觉语调强化世界观。

### 语调示例

```
❌ "耐久降低30点，剩余70点"
✓ "战车的装甲在颤抖——它还能承受更多，但伤痕已经累积"

❌ "魔能剩余15%，触发撤退警告"
✓ "魔力晶石的脉动变得急促——它在呼喊：'我的能量快耗尽了'"

❌ "维修完成，耐久恢复100%"
✓ "装甲重新完整，战车的呼吸平稳了——它准备好再次出发"
```

## Detailed Design

### Core Rules

#### 1. VehicleInstance Data Structure

每个战车实例定义为独立的运行时数据对象，存储当前属性状态。属性系统管理`VehicleInstance`的生命周期。

**Primary VehicleInstance Fields:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `instance_id` | int | 0-65535 | — | 战车实例唯一标识符（运行时生成） |
| `vehicle_type_id` | int | 0-65535 | — | 关联的战车类型ID（从VehicleTypes查询定义） |
| `current_durability` | int | 0-500 | max_durability | 当前耐久值（战车生命血量） |
| `current_magic_energy` | int | 0-500 | max_magic_energy | 当前魔能值（续航能量） |
| `current_speed` | float | 0.0-10.0 | base_speed | 当前移动速度（格/秒） |
| `current_load` | int | 0-500 | 0 | 当前载重量（仓库物品总重量） |
| `movement_state` | int | 0-4 | 0 | 运动状态枚举（见Movement State） |
| `vehicle_state` | int | 0-5 | 0 | 战车状态枚举（见Vehicle State Machine） |
| `position_cell` | Vector2i | — | (0, 0) | 当前网格位置坐标 |
| `equipped_weapons` | Array[int] | — | [] | 已装备武器类型ID列表（对应weapon_mount_config slots） |
| `installed_modifications` | Array[int] | — | [] | 已安装改装类型ID列表（Vertical Slice） |
| `warehouse_contents` | Dictionary | — | {} | 仓库内容 {resource_id: count} |

**Computed/Ratio Fields (不存储，实时计算):**

| Computed Field | Formula | Range | Description |
|----------------|---------|-------|-------------|
| `durability_ratio` | current_durability / max_durability | 0.0-1.0 | 耐久比例（用于阈值比较和HUD显示） |
| `magic_energy_ratio` | current_magic_energy / max_magic_energy | 0.0-1.0 | 魔能比例（用于阈值比较和HUD显示） |
| `load_ratio` | current_load / load_capacity | 0.0-1.0+ | 载重比例（用于速度修正和超载判断） |
| `is_deployable` | 见Deploy Validation Formula | bool | 是否可出发 |
| `should_retreat` | 见Retreat Trigger Formula | bool | 是否触发撤退 |

**Field Validation Rules:**

1. `current_durability`永远不超过`max_durability`（上限约束）
2. `current_durability`不允许负值，最小值为0（损坏状态）
3. `current_magic_energy`永远不超过`max_magic_energy`（上限约束）
4. `current_magic_energy`不允许负值，最小值为0（魔能耗尽）
5. `current_speed`由公式计算，不直接设置
6. `current_load`可超过`load_capacity`（允许超载，但有惩罚）
7. `equipped_weapons[]`长度不超过`weapon_mounts`（挂载点数量约束）

---

#### 2. Vehicle State Machine

战车实例具有生命周期状态，定义可执行操作和下游系统行为。

**State Enumeration:**

| Value | Name | Description | Allowed Actions |
|-------|------|-------------|-----------------|
| 0 | `GARAGE_IDLE` | 在车库停放，等待出发 | 维修、魔能补充、改装、武器装备 |
| 1 | `DEPLOYABLE` | 满足出发条件，可驾驶外出 | 维修、魔能补充、改装、武器装备、出发 |
| 2 | `DEPLOYED` | 已出发，在地表驾驶 | 驾驶、战斗、搜刮、撤退 |
| 3 | `DISABLED` | 瘫痪状态（魔能耗尽或耐久归零） | 步行逃回（战车留在原地），等待救援（Alpha功能） |
| 4 | `DESTROYED` | 永久损坏（不可修复） | 战车报废，资源回收，玩家步行 |
| 5 | `REPAIRING` | 正在维修（车库状态） | 无操作，等待维修完成 |

**State Transitions:**

| From State | To State | Trigger | Guard Condition | Action |
|------------|----------|---------|-----------------|--------|
| `GARAGE_IDLE` | `DEPLOYABLE` | 属性恢复满足出发条件 | durability_ratio ≥ 0.80 AND magic_energy_ratio ≥ 0.50 | 触发出发检查UI显示绿灯 |
| `DEPLOYABLE` | `GARAGE_IDLE` | 属性下降不满足出发条件 | durability_ratio < 0.80 OR magic_energy_ratio < 0.50 | 触发出发检查UI显示红灯 |
| `DEPLOYABLE` | `DEPLOYED` | 玩家出发指令 | durability_ratio ≥ 0.80 AND magic_energy_ratio ≥ 0.50 | 执行出发流程，进入驾驶状态 |
| `DEPLOYED` | `DEPLOYABLE` | 玩家返回车库 | 主动返回或撤退成功 | 执行返回流程，卸载仓库 |
| `DEPLOYED` | `DISABLED` | 魔能耗尽或耐久归零 | magic_energy = 0 OR durability = 0 | 战车瘫痪，触发步行逃回状态 |
| `DISABLED` | `REPAIRING` | 玩家步行返回后启动维修 | 战车被回收或救援到达（Alpha功能） | 开始维修流程 |
| `REPAIRING` | `GARAGE_IDLE` | 维修完成 | current_durability ≥ max_durability × 0.30 | 维修完成，进入停放状态 |
| `REPAIRING` | `DEPLOYABLE` | 维修完成并魔能补充 | durability_ratio ≥ 0.80 AND magic_energy_ratio ≥ 0.50 | 维修完成，可直接出发 |
| `GARAGE_IDLE` / `DEPLOYABLE` | `DESTROYED` | 战车报废指令（玩家决策或事件） | 特定报废条件触发 | 战车永久移除，仓库内容丢失 |

**State Transition Notes:**

1. `GARAGE_IDLE`和`DEPLOYABLE`是车库内状态，可双向转换（属性恢复/消耗）
2. `DEPLOYED`是地表驾驶状态，只有返回或瘫痪才能退出
3. `DISABLED`是瘫痪状态，战车留在地表某位置，玩家步行
4. `DESTROYED`是终态，战车实例从管理列表移除
5. MVP阶段不支持`DISABLED`→救援→`REPAIRING`流程（步行逃回后战车丢失）

---

#### 3. Movement State Enumeration

运动状态定义战车当前的驾驶行为。

| Value | Name | Description | Speed Modifier |
|-------|------|-------------|----------------|
| 0 | `IDLE` | 静止状态 | speed = 0 |
| 1 | `MOVING` | 正常移动 | speed = actual_speed |
| 2 | `ACCELERATING` | 加速中 | speed = actual_speed × accel_factor (渐增) |
| 3 | `DECELERATING` | 减速中 | speed = actual_speed × decel_factor (渐减) |
| 4 | `BLOCKED` | 被阻挡（碰撞） | speed = 0, 持续碰撞检测 |

---

#### 4. Attribute Modification Rules

属性值在运行时被多种事件修改，需遵循一致性规则。

**Durability Modification:**

| Event | Delta | Rule | Constraint |
|-------|-------|------|------------|
| 敌人攻击 | -damage | `current_durability -= actual_damage` | actual_damage = incoming × (1 - armor%) |
| 碰撞冲击 | -severity | `current_durability -= collision_severity` | severity由block-collision-system计算 |
| 维修 | +repair_amount | `current_durability = min(current + repair, max_durability)` | 不超过上限 |
| 完整维修 | → max | `current_durability = max_durability` | 特殊维修事件 |

**Magic Energy Modification:**

| Event | Delta | Rule | Constraint |
|-------|-------|------|------------|
| 驾驶消耗 | -drive_cost | `current_magic_energy -= drive_cost` | drive_cost由魔能消耗系统计算 |
| 武器射击 | -shot_cost | `current_magic_energy -= shot_cost` | shot_cost由战车武器系统定义 |
| 魔能补充 | +charge_amount | `current_magic_energy = min(current + charge, max_magic_energy)` | 不超过上限 |
| 魔能晶石补充 | → target | `current_magic_energy += crystal_value` | 晶石固定值由资源数据库定义 |

**Load Modification:**

| Event | Delta | Rule | Constraint |
|-------|-------|------|------------|
| 搜刮拾取 | +item_weight | `current_load += item.weight` | 无上限约束（可超载） |
| 仓库卸载 | -unload_weight | `current_load -= unload_total` | 无下限约束（最小为0） |
| 改装载重修正 | ±mod_delta | `load_capacity += mod_effect` | 改装系统影响载重上限 |

**Speed Recalculation Rule:**

每次`current_load`变化时，重新计算`current_speed`：

```
load_modifier = 1.0 - clamp(current_load / load_capacity, 0.0, 1.0) × 0.3
current_speed = base_speed × load_modifier
```

- 超载时（current_load > load_capacity）：`load_ratio = 1.0`（clamp），速度降低30%
- 空载时（current_load = 0）：`load_modifier = 1.0`，速度等于base_speed

---

#### 5. Initialization Logic

战车实例创建时，从VehicleTypeDatabase读取类型定义，初始化属性。

**Initialization Sequence:**

1. 读取类型定义：`type_def = VehicleTypes.get_vehicle_definition(vehicle_type_id)`
2. 初始化主属性：
   - `current_durability = type_def.max_durability`（满耐久）
   - `current_magic_energy = type_def.max_magic_energy`（满魔能）
   - `current_speed = type_def.base_speed`（基础速度）
   - `current_load = 0`（空载）
3. 初始化状态：`vehicle_state = GARAGE_IDLE`
4. 初始化位置：`position_cell = garage_spawn_point`（车库出生点）
5. 初始化装备槽：
   - `equipped_weapons = []`（空槽，玩家后续装备）
   - `installed_modifications = []`（空槽，Vertical Slice）
6. 初始化仓库：`warehouse_contents = {}`（空仓库）

**Initialization Edge Cases:**

| Case | Handling |
|------|----------|
| `vehicle_type_id = 0` | Reject — 创建实例失败，返回null |
| `vehicle_type_id` invalid | Reject — log warning，返回null |
| `max_durability = 0` | Reject — 类型定义无效 |
| 类型定义缺失required fields | Reject — log error，返回null |

---

### States and Transitions

见上述 Vehicle State Machine 和 Movement State Enumeration。

---

### Interactions with Other Systems

#### Upstream Systems

**VehicleTypeDatabase (唯一上游依赖):**

| Interaction | Direction | Data | Timing |
|-------------|-----------|------|--------|
| 类型定义查询 | VehicleTypeDB → VehicleAttribute | `get_vehicle_definition(vehicle_type_id)` | 实例创建时，一次性查询 |
| 属性上限查询 | VehicleTypeDB → VehicleAttribute | `get_max_durability()`, `get_armor()`, `get_max_magic_energy()`, `get_base_speed()`, `get_load_capacity()` | 实例创建时 |
| 挂载点配置查询 | VehicleTypeDB → VehicleAttribute | `get_weapon_mount_config()` | 武器装备时 |

**Interaction Contract:**
- VehicleAttribute查询一次类型定义，缓存结果到实例
- 类型定义运行时不变，无需重新查询
- 如果类型定义缺失，实例创建失败

---

#### Downstream Consumer Systems

| Consumer System | Data Consumed | Query Methods | Trigger |
|-----------------|---------------|---------------|---------|
| **战车驾驶系统** | current_speed, movement_state | `get_current_speed()`, `get_movement_state()` | 每帧驱动移动 |
| **魔能消耗计算** | current_magic_energy, magic_energy_ratio | `get_magic_energy_ratio()` | 驾驶/射击时扣魔能 |
| **战车损坏系统** | current_durability, durability_ratio, armor | `get_durability_ratio()`, `get_armor()` | 敌人攻击时扣耐久 |
| **战车武器系统** | equipped_weapons[], weapon_mounts | `get_equipped_weapons()`, `can_equip_weapon()` | 武器装备和射击 |
| **撤退判定系统** | durability_ratio, magic_energy_ratio | `get_durability_ratio()`, `get_magic_energy_ratio()`, `should_retreat()` | 每帧检查阈值 |
| **战车维修系统** | current_durability, max_durability | `get_current_durability()`, `get_max_durability()` | 维修时恢复耐久 |
| **战车仓库系统** | current_load, load_capacity, warehouse_contents | `get_current_load()`, `get_load_capacity()`, `get_warehouse_contents()` | 搜刮/卸载时 |
| **HUD系统** | durability_ratio, magic_energy_ratio, vehicle_state | `get_durability_ratio()`, `get_magic_energy_ratio()`, `get_vehicle_state()` | HUD渲染 |

**Query Interface Specification:**

```gdscript
# VehicleAttribute.gd (autoload singleton 或 per-instance controller)
class_name VehicleAttribute
extends Node

# === Instance Management ===
func create_vehicle_instance(vehicle_type_id: int) -> VehicleInstance
func get_vehicle_instance(instance_id: int) -> VehicleInstance
func destroy_vehicle_instance(instance_id: int) -> void

# === Attribute Query (per instance) ===
func get_current_durability(instance_id: int) -> int
func get_max_durability(instance_id: int) -> int
func get_durability_ratio(instance_id: int) -> float
func get_current_magic_energy(instance_id: int) -> int
func get_max_magic_energy(instance_id: int) -> int
func get_magic_energy_ratio(instance_id: int) -> float
func get_current_speed(instance_id: int) -> float
func get_current_load(instance_id: int) -> int
func get_load_capacity(instance_id: int) -> int
func get_load_ratio(instance_id: int) -> float
func get_armor(instance_id: int) -> int
func get_vehicle_state(instance_id: int) -> int
func get_movement_state(instance_id: int) -> int

# === Computed Query ===
func is_deployable(instance_id: int) -> bool
func should_retreat(instance_id: int) -> bool
func get_retreat_warning_level(instance_id: int) -> int  # 0=none, 1=magic, 2=durability, 3=both

# === Equipment Query ===
func get_equipped_weapons(instance_id: int) -> Array[int]
func can_equip_weapon(instance_id: int, weapon_type_id: int, slot_index: int) -> bool
func equip_weapon(instance_id: int, weapon_type_id: int, slot_index: int) -> bool
func unequip_weapon(instance_id: int, slot_index: int) -> bool

# === Attribute Modification ===
func apply_durability_damage(instance_id: int, damage: int) -> void
func apply_magic_energy_cost(instance_id: int, cost: int) -> void
func apply_load_change(instance_id: int, delta: int) -> void
func repair_durability(instance_id: int, amount: int) -> void
func charge_magic_energy(instance_id: int, amount: int) -> void

# === State Transition ===
func transition_to_state(instance_id: int, target_state: int) -> bool
func check_deployable_transition(instance_id: int) -> void
func check_retreat_trigger(instance_id: int) -> void
```

---

#### Detailed Interaction Contracts

##### 战车驾驶系统

**Data Flow:**
- VehicleAttribute → 驾驶系统：`current_speed`（移动计算），`movement_state`（状态同步）
- 驾驶系统 → VehicleAttribute：魔能消耗事件（每帧/每移动距离扣魔能）

**Trigger Timing:**
- 驾驶系统每帧读取`current_speed`驱动战车移动
- 移动时触发`apply_magic_energy_cost()`

**Contract:**
- 驾驶系统不直接修改`current_speed`，由`apply_load_change()`间接触发重算
- 驾驶系统通过`apply_magic_energy_cost()`消耗魔能，不直接设置`current_magic_energy`

##### 撤退判定系统

**Data Flow:**
- VehicleAttribute → 撤退判定：`durability_ratio`, `magic_energy_ratio`（阈值比较）
- 撤退判定 → VehicleAttribute：无修改（仅读取）

**Trigger Timing:**
- 撤退判定系统每帧检查`should_retreat()`
- 比较当前ratio与`VEHICLE_RETREAT_MAGIC_THRESHOLD (0.20)`、`VEHICLE_RETREAT_DURABILITY_THRESHOLD (0.30)`

**Contract:**
- 撤退判定只读取，不修改属性
- 撤退触发时由玩家决策执行返回流程，属性系统不自动执行撤退

## Formulas

### 1. Speed Load Modifier Formula

战车实际移动速度受载重量影响。

```
load_ratio = current_load / load_capacity
load_modifier = 1.0 - clamp(load_ratio, 0.0, 1.0) × 0.3
actual_speed = base_speed × load_modifier
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `base_speed` | BS | float | 1.0-10.0 | VehicleTypeDatabase.get_base_speed() |
| `current_load` | CL | int | 0-500 | VehicleAttribute.current_load |
| `load_capacity` | LC | int | 50-500 | VehicleTypeDatabase.get_load_capacity() |
| `load_ratio` | LR | float | 0.0-∞ | Computed |
| `load_modifier` | LM | float | 0.7-1.0 | Computed |
| `actual_speed` | AS | float | 0.7-10.0 | Output |

**Output Range:** 0.7 × base_speed ≤ actual_speed ≤ base_speed（满载降低30%，空载无修正）

**Boundary Tests:**

| Case | current_load | load_capacity | load_ratio | load_modifier | actual_speed |
|------|--------------|---------------|------------|---------------|--------------|
| 空载 | 0 | 100 | 0.0 | 1.0 | base_speed (无修正) |
| 半载 | 50 | 100 | 0.5 | 0.85 | base_speed × 0.85 |
| 满载 | 100 | 100 | 1.0 | 0.7 | base_speed × 0.7 (最大降速) |
| 超载 | 150 | 100 | 1.5 | 0.7 (clamp) | base_speed × 0.7 (超载仍30%降速) |

**Example:**
- Standard Basic战车 (base_speed=3.0, load_capacity=100)
- current_load=60 → load_ratio=0.6 → load_modifier=0.82 → actual_speed=2.46格/秒

---

### 2. Durability Ratio Formula

耐久比例用于出发条件判断、撤退阈值比较、HUD显示。

```
durability_ratio = current_durability / max_durability
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `current_durability` | CD | int | 0-500 | VehicleAttribute.current_durability |
| `max_durability` | MD | int | 50-500 | VehicleTypeDatabase.get_max_durability() |
| `durability_ratio` | DR | float | 0.0-1.0 | Output |

**Output Range:** 0.0 (完全损坏) ≤ durability_ratio ≤ 1.0 (完好)

**Boundary Tests:**

| Case | current_durability | max_durability | durability_ratio | Meaning |
|------|--------------------|----------------|------------------|---------|
| 完好 | 100 | 100 | 1.0 | 满耐久 |
| 损坏50% | 50 | 100 | 0.5 | 半耐久 |
| 撤退阈值 | 30 | 100 | 0.30 | 触发撤退警告 |
| 出发阈值 | 80 | 100 | 0.80 | 可出发最低值 |
| 归零 | 0 | 100 | 0.0 | 战车瘫痪 |
| 超上限 | 110 | 100 | 1.0 (clamp) | 不允许超上限 |

**Example:**
- Heavy Elite战车 (max_durability=400)
- current_durability=120 → durability_ratio=0.30 → 触发撤退警告

---

### 3. Magic Energy Ratio Formula

魔能比例用于出发条件判断、撤退阈值比较、HUD显示。

```
magic_energy_ratio = current_magic_energy / max_magic_energy
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `current_magic_energy` | CME | int | 0-500 | VehicleAttribute.current_magic_energy |
| `max_magic_energy` | MME | int | 50-500 | VehicleTypeDatabase.get_max_magic_energy() |
| `magic_energy_ratio` | MER | float | 0.0-1.0 | Output |

**Output Range:** 0.0 (魔能耗尽) ≤ magic_energy_ratio ≤ 1.0 (满魔能)

**Boundary Tests:**

| Case | current_magic_energy | max_magic_energy | magic_energy_ratio | Meaning |
|------|----------------------|------------------|--------------------|---------|
| 满魔能 | 120 | 120 | 1.0 | 满魔能容量 |
| 出发阈值 | 60 | 120 | 0.50 | 可出发最低值 |
| 撤退阈值 | 24 | 120 | 0.20 | 触发撤退警告 |
| 归零 | 0 | 120 | 0.0 | 魔能耗尽，战车瘫痪 |
| 超上限 | 150 | 120 | 1.0 (clamp) | 不允许超上限 |

---

### 4. Deploy Validation Formula

出发条件判断（布尔逻辑）。

```
is_deployable = (durability_ratio ≥ DEPLOY_DURABILITY_MIN) AND 
               (magic_energy_ratio ≥ DEPLOY_MAGIC_MIN)
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `durability_ratio` | DR | float | 0.0-1.0 | Formula 2 |
| `magic_energy_ratio` | MER | float | 0.0-1.0 | Formula 3 |
| `DEPLOY_DURABILITY_MIN` | — | float | 0.80 (fixed) | entities.yaml (VEHICLE_DEPLOY_DURABILITY_MIN) |
| `DEPLOY_MAGIC_MIN` | — | float | 0.50 (fixed) | entities.yaml (VEHICLE_DEPLOY_MAGIC_MIN) |
| `is_deployable` | — | bool | true/false | Output |

**Output:** true = 可出发，false = 不可出发

**Boundary Tests:**

| Case | durability_ratio | magic_energy_ratio | is_deployable | Reason |
|------|------------------|--------------------|---------------|--------|
| 完好满魔能 | 1.0 | 1.0 | true | 两条件满足 |
| 刚好可出发 | 0.80 | 0.50 | true | 边界值满足 |
| 耐久不足 | 0.75 | 0.60 | false | durability < 0.80 |
| 魔能不足 | 0.85 | 0.45 | false | magic_energy < 0.50 |
| 双不足 | 0.70 | 0.40 | false | 两条件都不满足 |

---

### 5. Retreat Trigger Formula

撤退警告触发判断（布尔逻辑）。

```
should_retreat = (magic_energy_ratio < RETREAT_MAGIC_THRESHOLD) OR 
                (durability_ratio < RETREAT_DURABILITY_THRESHOLD)
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `durability_ratio` | DR | float | 0.0-1.0 | Formula 2 |
| `magic_energy_ratio` | MER | float | 0.0-1.0 | Formula 3 |
| `RETREAT_MAGIC_THRESHOLD` | — | float | 0.20 (fixed) | entities.yaml (VEHICLE_RETREAT_MAGIC_THRESHOLD) |
| `RETREAT_DURABILITY_THRESHOLD` | — | float | 0.30 (fixed) | entities.yaml (VEHICLE_RETREAT_DURABILITY_THRESHOLD) |
| `should_retreat` | — | bool | true/false | Output |

**Output:** true = 触发撤退警告，false = 无警告

**Boundary Tests:**

| Case | durability_ratio | magic_energy_ratio | should_retreat | Warning Level |
|------|------------------|--------------------|----------------|---------------|
| 安全 | 0.50 | 0.40 | false | 无警告 |
| 魔能警告 | 0.50 | 0.15 | true | 魔能警告（黄色） |
| 耐久警告 | 0.25 | 0.40 | true | 耐久警告（红色） |
| 双警告 | 0.20 | 0.10 | true | 双重警告（红色闪烁） |
| 边界值 | 0.30 | 0.20 | false | 刚好等于阈值，不触发 |
| 边界下限 | 0.29 | 0.19 | true | 低于阈值，触发 |

**Note:** 阈值是"低于"触发，等于阈值不触发（边界设计：玩家看到20%魔能时，警告还没触发，再消耗一点就触发）

---

### 6. Actual Damage Formula (Armor Reduction)

护甲减伤计算，用于战车损坏系统。

```
damage_reduction = armor / 100  # armor是百分比 (0-80)
actual_damage = incoming_damage × (1 - damage_reduction)
actual_damage = max(actual_damage, 1)  # 最小伤害1，防止完全无敌
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `incoming_damage` | ID | int | 1-100 | Enemy attack damage |
| `armor` | A | int | 0-80 | VehicleTypeDatabase.get_armor() |
| `damage_reduction` | DR | float | 0.0-0.80 | Computed |
| `actual_damage` | AD | int | 1-100 | Output |

**Output Range:** 1 ≤ actual_damage ≤ incoming_damage（护甲80%时最低20%伤害）

**Boundary Tests:**

| Case | incoming_damage | armor | damage_reduction | actual_damage |
|------|-----------------|-------|------------------|---------------|
| 无护甲 | 50 | 0 | 0.0 | 50 (全伤) |
| 轻护甲 | 50 | 20 | 0.20 | 40 |
| 中护甲 | 50 | 50 | 0.50 | 25 |
| 重护甲 | 50 | 80 | 0.80 | 10 (最大减伤) |
| 满护甲小伤害 | 5 | 80 | 0.80 | 1 (min=1保底) |
| 零伤害输入 | 0 | 50 | — | 0 (无效输入，不扣耐久) |

**Example:**
- Heavy Elite战车 (armor=65)
- incoming_damage=40 → damage_reduction=0.65 → actual_damage=40×0.35=14

---

### 7. Load Ratio Formula

载重比例用于超载判断和HUD显示。

```
load_ratio = current_load / load_capacity
is_overloaded = load_ratio > 1.0
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `current_load` | CL | int | 0-500 | VehicleAttribute.current_load |
| `load_capacity` | LC | int | 50-500 | VehicleTypeDatabase.get_load_capacity() |
| `load_ratio` | LR | float | 0.0-∞ | Output |
| `is_overloaded` | — | bool | true/false | Computed |

**Output Range:** 0.0 ≤ load_ratio ≤ ∞（允许超载，无上限clamp）

**Boundary Tests:**

| Case | current_load | load_capacity | load_ratio | is_overloaded |
|------|--------------|---------------|------------|---------------|
| 空载 | 0 | 100 | 0.0 | false |
| 半载 | 50 | 100 | 0.5 | false |
| 满载 | 100 | 100 | 1.0 | false |
| 超载10% | 110 | 100 | 1.1 | true |
| 超载50% | 150 | 100 | 1.5 | true |

**Note:** 超载时速度被clamp到30%降速，但load_ratio可以超过1.0用于HUD显示（"超载110%"）

---

### 8. Retreat Warning Level Formula

撤退警告等级计算（用于HUD显示不同警告级别）。

```
magic_warning = magic_energy_ratio < RETREAT_MAGIC_THRESHOLD
durability_warning = durability_ratio < RETREAT_DURABILITY_THRESHOLD
warning_level = 0 if (!magic_warning AND !durability_warning)
               = 1 if (magic_warning AND !durability_warning)
               = 2 if (!magic_warning AND durability_warning)
               = 3 if (magic_warning AND durability_warning)
```

**Output Values:**

| warning_level | Meaning | HUD Display |
|---------------|---------|-------------|
| 0 | 无警告 | 无警告UI |
| 1 | 魔能警告 | 黄色警告：魔能不足 |
| 2 | 耐久警告 | 红色警告：耐久不足 |
| 3 | 双警告 | 红色闪烁：立即撤退 |

## Edge Cases

### 1. Durability Zero/Negative Scenarios

**Case**: 耐久值归零或负值。

| Scenario | Trigger | Expected Behavior | Player Experience |
|----------|---------|-------------------|-------------------|
| `current_durability = 0` exactly | 敌人攻击恰好扣完 | 战车进入`DISABLED`状态，触发步行逃回流程 | 战车瘫痪在地表，玩家步行 |
| `current_durability < 0` attempted | 伤害超过剩余耐久 | Clamp to 0，进入`DISABLED`状态 | 同上，不显示负值 |
| `durability_ratio = 0.0` | 归零后计算比例 | HUD耐久条显示为空（黑色），闪烁警报 | 明确告知战车已瘫痪 |
| 恢复维修到 > 0 | 维修修复 | 状态从`DISABLED`/`REPAIRING`→`GARAGE_IDLE`或`DEPLOYABLE` | 战车重新可用 |

**Implementation Rule**: `apply_durability_damage()`时，`current_durability = max(0, current - damage)`，不允许负值。

---

### 2. Magic Energy Zero/Negative Scenarios

**Case**: 魔能值归零或负值。

| Scenario | Trigger | Expected Behavior | Player Experience |
|----------|---------|-------------------|-------------------|
| `current_magic_energy = 0` exactly | 驾驶/射击恰好耗尽 | 战车进入`DISABLED`状态（魔能耗尽） | 战车停止移动，需步行逃回 |
| `current_magic_energy < 0` attempted | 消耗超过剩余魔能 | Clamp to 0，进入`DISABLED`状态 | 同上，不显示负值 |
| 魔能耗尽时正在射击 | 武器射击扣魔能 | 射击被拒绝（魔能不足），不扣魔能 | 武器无反应，HUD提示"魔能不足" |
| 魔能耗尽时正在驾驶 | 驾驶扣魔能 | 战车停止移动，进入`DISABLED` | 战车停在原地，玩家步行 |

**Implementation Rule**: `apply_magic_energy_cost()`时：
- 如果 `current_magic_energy < cost` → 拒绝操作，返回false
- 如果 `current_magic_energy = cost` → 执行扣减，检查是否触发`DISABLED`

---

### 3. Overload Scenarios

**Case**: 载重量超过载重上限。

| Scenario | current_load | load_capacity | Behavior | Speed Modifier |
|----------|--------------|---------------|----------|----------------|
| 正常载重 | 100 | 100 | 允许，满载 | 0.7×base_speed |
| 轻度超载 | 110 | 100 | 允许，超载10% | 0.7×base_speed (clamp) |
| 重度超载 | 200 | 100 | 允许，超载200% | 0.7×base_speed (clamp) |
| 极端超载 | 500 | 50 | 允许，超载1000% | 0.7×base_speed (clamp) |

**Note**: 超载时速度统一降低30%（clamp到load_ratio=1.0），但HUD显示真实超载比例（如"超载200%"）

**Implementation Rule**: `load_ratio`不clamp用于显示，但`load_modifier`计算时clamp `load_ratio`到1.0。

---

### 4. Invalid Instance Creation

**Case**: 创建战车实例时传入无效类型ID。

| Scenario | Input | Expected Behavior | Return Value |
|----------|-------|-------------------|--------------|
| `vehicle_type_id = 0` | `create_vehicle_instance(0)` | Reject — ID 0 reserved | Return null, log warning |
| `vehicle_type_id < 0` | `create_vehicle_instance(-5)` | Reject — negative ID | Return null, log warning |
| `vehicle_type_id` not found | `create_vehicle_instance(9999)` | Reject — type not registered | Return null, log warning |
| Type missing required fields | Type def incomplete | Reject — invalid definition | Return null, log error |

**Implementation Rule**: `create_vehicle_instance()`返回null表示创建失败，调用方需检查返回值。

---

### 5. State Transition Edge Cases

**Case**: 状态转换的边界条件。

| From State | To State | Guard Condition Edge | Behavior |
|------------|----------|---------------------|----------|
| `DEPLOYED` → `DISABLED` | durability hits 0 OR magic hits 0 | Either condition triggers | 立即转换，触发步行逃回流程 |
| `DEPLOYABLE` → `DEPLOYED` | Exactly at threshold | durability_ratio = 0.80, magic = 0.50 | 允许出发（边界值满足） |
| `DEPLOYED` → `DEPLOYABLE` | Return to garage | 主动返回或撤退成功 | 执行返回流程，状态转换 |
| `GARAGE_IDLE` → `DEPLOYABLE` | Attribute recovery | durability crosses from 79%→80% | 触发出发UI绿灯 |
| `DEPLOYABLE` → `GARAGE_IDLE` | Attribute drop | durability crosses from 80%→79% | 触发出发UI红灯 |

**Note**: 状态转换的阈值比较使用"≥"（出发条件）和"<"（撤退条件）。

---

### 6. Query Timing Edge Cases

**Case**: 下游系统在VehicleAttribute未初始化时查询。

| Scenario | Trigger | Expected Behavior | Resolution |
|----------|---------|-------------------|------------|
| Query in `_init()` stage | System calls `get_durability_ratio()` in `_init()` | VehicleAttribute autoload not ready | Return default (0.0) or null |
| Query before instance creation | Call `get_current_speed(999)` (invalid instance_id) | Instance not found | Return 0.0, log warning |
| Query destroyed instance | Call after `destroy_vehicle_instance()` | Instance removed from registry | Return 0.0, log warning |

**Implementation Rule**: VehicleAttribute必须在`_ready()`阶段完成初始化，下游系统应在`_ready()`后查询或等待信号。

---

### 7. Threshold Boundary Cases

**Case**: 阈值刚好等于边界值。

| Threshold | Boundary Value | Comparison Operator | Trigger Condition |
|-----------|----------------|---------------------|-------------------|
| `DEPLOY_DURABILITY_MIN` | 0.80 | ≥ (greater or equal) | 0.80 满足，可出发 |
| `DEPLOY_MAGIC_MIN` | 0.50 | ≥ | 0.50 满足，可出发 |
| `RETREAT_MAGIC_THRESHOLD` | 0.20 | < (strictly less) | 0.20 不触发，0.19 触发 |
| `RETREAT_DURABILITY_THRESHOLD` | 0.30 | < | 0.30 不触发，0.29 触发 |

**Design Intent**: 出发阈值使用"≥"（边界值满足条件），撤退阈值使用"<"（边界值不触发，只有低于才警告）。这给玩家一个心理缓冲——看到20%魔能时，警告还没触发，玩家有最后一点决策空间。

---

### 8. Multiple Vehicle Instances

**Case**: 玩家拥有多辆战车实例。

| Scenario | Behavior | Implementation |
|----------|----------|----------------|
| 切换驾驶战车 | 当前战车状态→`GARAGE_IDLE`，目标战车→`DEPLOYABLE`/`DEPLOYED` | `transition_to_state()`调用 |
| 同时查看多辆战车状态 | HUD显示车库列表，每辆战车独立状态 | `get_vehicle_instance()` per ID |
| 一辆战车DISABLED，另一辆可用 | 瘫痪战车留在地表，可用战车可出发 | Alpha功能：多战车管理 |
| MVP阶段：只有一辆战车 | instance_id = 0 或固定值 | 简化设计，单实例管理 |

**MVP Simplification**: MVP阶段只支持一辆战车，多战车管理为Alpha功能。

---

### 9. Weapon Slot Edge Cases

**Case**: 武器装备槽位的边界情况。

| Scenario | vehicle weapon_mounts | Behavior |
|----------|-----------------------|----------|
| 战车无武器槽 | `weapon_mounts = 0` (scout_basic) | `can_equip_weapon()` always false，无法装备任何武器 |
| 装备槽已满 | `equipped_weapons.length = weapon_mounts` | `can_equip_weapon()` false，需先卸下 |
| 装备到错误slot_index | `slot_index >= weapon_mounts` | Reject，log warning |
| 武器类型不允许 | weapon不在`weapon_type_allowed[]`中 | Reject，提示"武器类型不兼容" |

**Implementation Rule**: `can_equip_weapon()`检查：
- `slot_index < weapon_mounts`
- `slot_index`未占用或允许替换
- weapon_type_id在allowed列表中（如果列表非空）

---

### 10. Zero Division Protection

**Case**: 公式计算中除数为零的保护。

| Formula | Division By Zero Risk | Protection |
|---------|----------------------|------------|
| `durability_ratio = current / max` | `max_durability = 0` | Reject type definition at creation |
| `magic_energy_ratio = current / max` | `max_magic_energy = 0` | Reject type definition at creation |
| `load_ratio = current_load / load_capacity` | `load_capacity = 0` | Reject type definition at creation |
| `actual_speed = base_speed × modifier` | `base_speed = 0` | Reject type definition, min=1.0 |

**Implementation Rule**: 类型定义验证阶段拒绝`max_durability=0`, `max_magic_energy=0`, `load_capacity=0`, `base_speed=0`的无效定义。运行时公式不会遇到除零情况。

## Dependencies

### Upstream Dependencies

战车属性系统依赖上游系统提供数据定义和全局阈值。

| System | Priority | Layer | Data Provided | Dependency Type | GDD Status |
|--------|----------|-------|---------------|-----------------|------------|
| **战车类型数据库 (#6)** | MVP | Foundation | Vehicle type definitions (max_durability, armor, max_magic_energy, base_speed, load_capacity, weapon_mounts) | **Blocking** — Cannot create vehicle instance without type definition | ✓ Designed (Approved) |
| **时间系统 (#8)** | MVP | Foundation | Time scale for magic energy regeneration (optional) | **Non-blocking** — 魔能补充可使用时间系统，也可使用固定速率 | ✓ Designed (Approved) |

**Critical Upstream Data Flow:**

```
VehicleTypeDatabase.get_vehicle_definition(vehicle_type_id)
  → VehicleAttribute.create_vehicle_instance()
    → Initialize: current_durability = max_durability
    → Initialize: current_magic_energy = max_magic_energy
    → Initialize: current_speed = base_speed
```

---

### Downstream Dependencies

战车属性系统为下游系统提供运行时属性查询接口。

| System | Priority | Layer | Data Consumed | Dependency Type | GDD Status |
|--------|----------|-------|---------------|-----------------|------------|
| **战车驾驶系统 (#18)** | MVP | Core | current_speed, movement_state, vehicle_state | **Blocking** — Cannot drive vehicle without speed/state | Not Started |
| **魔能消耗计算 (#19)** | MVP | Core | current_magic_energy, magic_energy_ratio | **Blocking** — Cannot calculate consumption without current value | Not Started |
| **战车武器系统 (#20)** | MVP | Core | equipped_weapons[], weapon_mounts | **Blocking** — Cannot shoot without weapon slot state | Not Started |
| **战车损坏系统 (#21)** | MVP | Core | current_durability, durability_ratio, armor | **Blocking** — Cannot apply damage without durability state | Not Started |
| **撤退判定系统 (#32)** | MVP | Core | durability_ratio, magic_energy_ratio | **Blocking** — Cannot check retreat trigger without ratios | Not Started |
| **战车维修系统 (#22)** | Vertical Slice | Feature | current_durability, max_durability | **Blocking** — Cannot repair without durability state | Not Started |
| **战车改装系统 (#23)** | Vertical Slice | Feature | installed_modifications[], modification_slots | **Blocking** — Cannot install modification without slot state | Not Started |
| **战车仓库系统 (#29)** | Vertical Slice | Feature | current_load, load_capacity, warehouse_contents | **Blocking** — Cannot manage warehouse without load state | Not Started |
| **多战车管理 (#26)** | Alpha | Feature | instance registry, vehicle state per instance | **Blocking** — Cannot manage multiple vehicles without instance list | Not Started |
| **HUD系统 (#49)** | Full Vision | Presentation | durability_ratio, magic_energy_ratio, vehicle_state | **Non-blocking** — UI can display placeholder without real data | Not Started |

---

### Critical Dependency Path (MVP)

MVP阶段的核心依赖链：

```
VehicleTypeDatabase (#6)
  → VehicleAttribute (#17) [THIS SYSTEM]
    → VehicleDriving (#18) — speed for movement
    → MagicEnergyConsumption (#19) — magic for driving/shooting
    → VehicleDamage (#21) — durability for damage tracking
    → RetreatJudge (#32) — ratios for retreat trigger
    → VehicleWeapon (#20) — weapon slots for shooting
```

**Implementation Order Recommendation:**

1. VehicleTypeDatabase (#6) — ✓ Already designed
2. VehicleAttribute (#17) — ← Current task
3. VehicleDriving (#18) — Next MVP system
4. MagicEnergyConsumption (#19) — After driving
5. VehicleDamage (#21) — After driving/magic
6. RetreatJudge (#32) — After damage/magic
7. VehicleWeapon (#20) — Parallel with driving

---

### Bidirectional Dependency Check

验证下游系统是否在其GDD中列出VehicleAttribute作为依赖。

| Downstream System | Listed Here | Listed in Target GDD | Status |
|-------------------|-------------|----------------------|--------|
| VehicleDriving (#18) | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| MagicEnergyConsumption (#19) | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| VehicleDamage (#21) | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| RetreatJudge (#32) | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| VehicleWeapon (#20) | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| VehicleRepair (#22) | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| VehicleModification (#23) | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| VehicleWarehouse (#29) | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| MultiVehicle (#26) | ✓ Listed as Blocking | Target GDD Not Started | Pending |
| HUD (#49) | ✓ Listed as Non-blocking | Target GDD Not Started | Pending |

**Action Required**: 当设计下游系统GDD时，需在Dependencies部分列出VehicleAttribute (#17)作为上游依赖。

---

### Interface Contract Summary

VehicleAttribute必须实现的接口以满足下游依赖：

| Interface Method | Consumer Systems | Contract |
|------------------|------------------|----------|
| `create_vehicle_instance(type_id)` | All downstream | Returns VehicleInstance or null |
| `get_current_durability(instance_id)` | VehicleDamage, RetreatJudge, HUD | Returns int (0-500) |
| `get_durability_ratio(instance_id)` | RetreatJudge, HUD | Returns float (0.0-1.0) |
| `get_current_speed(instance_id)` | VehicleDriving | Returns float (0.7-10.0) |
| `get_magic_energy_ratio(instance_id)` | MagicEnergyConsumption, RetreatJudge, HUD | Returns float (0.0-1.0) |
| `apply_durability_damage(instance_id, damage)` | VehicleDamage | Modifies current_durability |
| `apply_magic_energy_cost(instance_id, cost)` | VehicleDriving, VehicleWeapon | Modifies current_magic_energy |
| `get_equipped_weapons(instance_id)` | VehicleWeapon | Returns Array[int] |
| `should_retreat(instance_id)` | RetreatJudge | Returns bool |

## Tuning Knobs

### Primary Tuning Knobs (影响核心玩法)

| Knob | Current Value | Safe Range | Gameplay Effect | Pillar Affected | Locked? |
|------|---------------|------------|-----------------|-----------------|---------|
| **载重速度修正系数** | 0.3 (30% max reduction) | 0.2-0.5 | 满载速度降低幅度。提高 → 满载更慢 → 搜打撤节奏更紧张 | Pillar 2 | Tunable |
| **超载惩罚行为** | Clamp load_ratio to 1.0 | Allow/no-clamp | 超载时是否额外惩罚。no-clamp → 超载200%=速度降低60% → 更严格超载限制 | Pillar 2 | Tunable |
| **最小伤害保底** | 1 (after armor) | 1-5 | 护甲减伤后最小伤害。提高 → 高护甲战车更脆弱 → 护甲收益降低 | Pillar 1 | Tunable |
| **速度下限clamp** | 0.7 × base_speed | 0.5-0.8 | 最低速度比例。降低 → 满载战车更慢 → 搜打撤节奏变化 | Pillar 2 | Tunable |
| **属性恢复速率** | (garage) full restore | partial/full | 维修/补充是否立即恢复满值。partial → 分阶段恢复 → 等待时间增加 | Pillar 2 | Tunable |

**Note**: 出发阈值和撤退阈值由game-concept.md锁定，VehicleAttribute系统仅读取，不提供调谐。

---

### Secondary Tuning Knobs

| Knob | Current Value | Safe Range | Gameplay Effect |
|------|---------------|------------|-----------------|
| **状态转换检查频率** | 每帧 | 每帧/每0.5秒/每秒 | 检查deployable/retreat条件的频率。降低 → 响应延迟 → 状态转换滞后 |
| **实例ID生成范围** | 0-65535 | — | 实例ID分配范围。架构决策，不建议调整 |
| **属性变化信号发射** | 每次修改 | 每次/批量 | 属性修改时是否发射信号。批量 → 性能优化，但HUD更新滞后 |
| **魔能不足拒绝行为** | Reject operation | Reject/consume remaining | 魔能不足时的行为。consume → 允许部分消耗 → 战车可能魔能耗尽 |

---

### Locked Thresholds (From game-concept.md)

以下阈值由game-concept.md定义，在entities.yaml注册，**不可在本系统调谐**：

| Threshold | Value | Source | Reason |
|-----------|-------|--------|--------|
| `VEHICLE_DEPLOY_DURABILITY_MIN` | 0.80 | game-concept.md | 出发最低耐久比例 — 游戏核心设计决策 |
| `VEHICLE_DEPLOY_MAGIC_MIN` | 0.50 | game-concept.md | 出发最低魔能比例 — 游戏核心设计决策 |
| `VEHICLE_RETREAT_MAGIC_THRESHOLD` | 0.20 | game-concept.md | 撤退魔能触发比例 — 游戏核心设计决策 |
| `VEHICLE_RETREAT_DURABILITY_THRESHOLD` | 0.30 | game-concept.md | 撤退耐久触发比例 — 游戏核心设计决策 |

**If tuning needed**: 修改game-concept.md并更新entities.yaml，所有下游系统同步更新。

---

### Knob Interactions

| Knob A | Knob B | Interaction Effect |
|--------|--------|-------------------|
| 载重速度修正系数 × 超载惩罚行为 | If 系数=0.3, clamp=no → 超载200% = 速度×0.4 (降低60%) | 两个knob共同影响超载惩罚程度 |
| 最小伤害保底 × armor上限 | If 保底=5, armor=80 → 伤害=min(50×0.2, 5)=5 | 护甲收益被保底伤害限制 |
| 状态转换检查频率 × 撤退阈值 | If 检查=每秒, threshold=0.20 → 最多1秒延迟触发警告 | 检查频率影响响应及时性 |

---

### Knobs That Should NOT Be Tuned

| Knob | Reason |
|------|--------|
| **出发/撤退阈值** | 游戏核心设计决策，修改需全局更新 |
| **VehicleInstance数据结构字段** | 架构决策，修改影响所有下游系统 |
| **状态枚举值** | 架构约定，修改需更新所有引用代码 |
| **公式运算符** | 公式定义是系统契约，修改会导致下游计算错误 |

---

### Tuning Profile Recommendations

**Profile 1: 紧张节奏**
- 载重速度修正系数 = 0.5 (满载降低50%)
- 超载惩罚行为 = no-clamp (超载200%=降低60%)
- 最小伤害保底 = 3
- 效果：搜打撤节奏更紧张，超载惩罚更严厉，战车更脆弱

**Profile 2: 宽松节奏**
- 载重速度修正系数 = 0.2 (满载降低20%)
- 超载惩罚行为 = clamp (超载统一30%降速)
- 最小伤害保底 = 1
- 效果：载重对速度影响小，战车更耐用，节奏更宽松

**MVP建议**: 使用Profile 1（紧张节奏），强化Pillar 2的搜打撤压力感。

## Visual/Audio Requirements

战车属性系统是纯数据系统，不直接产生视觉或音频输出。以下列出下游系统需要的视觉/音频数据映射和信号支持。

### Visual Data Provided by VehicleAttribute

| Data | Type | Consumer System | Visual Effect |
|------|------|-----------------|---------------|
| **durability_ratio** | float (0.0-1.0) | HUD系统 | 耐久条渲染（绿色→黄色→红色渐变） |
| **magic_energy_ratio** | float (0.0-1.0) | HUD系统 | 魔能表渲染（半圆形魔力晶石显示） |
| **vehicle_state** | int (0-5) | HUD系统 | 战车状态图标（停放/可出发/出发中/瘫痪/报废/维修中） |
| **load_ratio** | float (0.0-∞) | HUD系统 | 载重比例显示（"载重: 80/100" 或 "超载: 120%"） |
| **current_speed** | float | 驾驶系统 | 战车移动速度渲染（帧动画频率） |
| **is_deployable** | bool | 出发检查UI | 出发按钮状态（绿灯✓可出发，红灯✗不可出发） |
| **should_retreat** | bool | 撤退警告UI | 撤退警告触发（显示警告弹窗） |
| **warning_level** | int (0-3) | HUD系统 | 警告等级显示（无/黄色魔能警告/红色耐久警告/红色闪烁双警告） |

### Audio Triggers Supported by VehicleAttribute

属性系统发射信号供音频系统订阅。

| Signal | Trigger Condition | Consumer System | Audio Event |
|--------|-------------------|-----------------|-------------|
| `durability_depleted` | current_durability hits 0 | 音效系统 | 战车瘫痪警报（低沉金属撞击声） |
| `magic_energy_depleted` | current_magic_energy hits 0 | 音效系统 | 魔能耗尽警报（魔力晶石空响） |
| `retreat_warning_triggered` | should_retreat becomes true | 音效系统 | 撤退警告音效（脉冲警报） |
| `deployable_changed(true)` | is_deployable becomes true | 音效系统 | 出发绿灯音效（确认提示音） |
| `deployable_changed(false)` | is_deployable becomes false | 音效系统 | 出发红灯音效（警告提示音） |
| `vehicle_state_changed` | State transition occurs | 音效系统 | 状态切换音效（出发/返回/瘫痪） |

### Signal Emission Specification

VehicleAttribute发射以下信号供下游系统订阅：

```gdscript
# VehicleAttribute signals
signal durability_changed(instance_id: int, old_value: int, new_value: int)
signal magic_energy_changed(instance_id: int, old_value: int, new_value: int)
signal load_changed(instance_id: int, old_value: int, new_value: int)
signal speed_changed(instance_id: int, old_value: float, new_value: float)

signal vehicle_state_changed(instance_id: int, old_state: int, new_state: int)
signal movement_state_changed(instance_id: int, old_state: int, new_state: int)

signal durability_depleted(instance_id: int)  # current_durability = 0
signal magic_energy_depleted(instance_id: int)  # current_magic_energy = 0

signal retreat_warning_triggered(instance_id: int, warning_level: int)
signal deployable_changed(instance_id: int, is_deployable: bool)

signal vehicle_instance_created(instance_id: int, vehicle_type_id: int)
signal vehicle_instance_destroyed(instance_id: int)
```

### Visual Threshold Mapping

属性比例值映射到视觉显示颜色/效果：

| Ratio Range | Visual State | HUD Color | Additional Effect |
|-------------|--------------|-----------|-------------------|
| durability_ratio ≥ 0.80 | HEALTHY | 绿色 (#4CAF50) | 无 |
| durability_ratio 0.50-0.79 | DAMAGED | 黄色 (#FFC107) | 轻微伤痕纹理 |
| durability_ratio 0.30-0.49 | CRITICAL | 红色 (#F44336) | 持续闪烁，伤痕纹理 |
| durability_ratio < 0.30 | RETREAT_ZONE | 红色闪烁 | 快速闪烁，撤退警告UI |
| durability_ratio = 0.0 | DISABLED | 黑色/空条 | 战车瘫痪图标 |
| magic_energy_ratio ≥ 0.50 | GOOD | 晶石蓝色 (#2196F3) | 正常脉动 |
| magic_energy_ratio 0.20-0.49 | LOW | 晶石黄色 (#FFEB3B) | 加快脉动 |
| magic_energy_ratio < 0.20 | WARNING | 晶石红色闪烁 | 急促脉动，撤退警告UI |
| magic_energy_ratio = 0.0 | DEPLETED | 晶石灰色 | 无脉动，战车瘫痪 |

### Audio Parameter Mapping

属性值影响音频参数：

| Attribute | Audio Parameter | Mapping |
|-----------|-----------------|---------|
| **current_speed** | 引擎音效频率 | speed越高 → 音效节奏越快 |
| **load_ratio** | 引擎负重感 | load越高 → 音效低沉，沉重感 |
| **durability_ratio** | 损坏警报紧迫度 | ratio越低 → 警报频率越高 |
| **vehicle_state** | 状态音效类型 | DEPLOYED → 引擎声；DISABLED → 警报声 |

### No Direct Rendering

VehicleAttribute不包含以下内容：
- Sprite或Texture资源
- AnimationPlayer或AnimationTree
- AudioStreamPlayer
- ShaderMaterial

所有视觉/音频渲染由下游系统（HUD、驾驶系统、音效系统）负责。VehicleAttribute仅提供数据和信号。

## UI Requirements

战车属性系统为UI系统提供数据支持，但本身不渲染UI。以下列出下游UI系统需要的数据和交互。

### UI Data Provided by VehicleAttribute

| UI Element | Data Source | Display Format | Consumer System |
|------------|-------------|----------------|-----------------|
| **HUD耐久条** | `durability_ratio` | 进度条 (0-100%) + 颜色渐变 | HUD系统 (#49) |
| **HUD魔能表** | `magic_energy_ratio` | 半圆形魔力晶石显示 | HUD系统 (#49) |
| **出发检查界面** | `is_deployable`, threshold values | 出发按钮状态灯 + 条件列表 | 出发UI |
| **撤退警告弹窗** | `should_retreat`, `warning_level` | 警告级别 + 属性值 + 撤退建议 | 撤退警告UI (#50) |
| **车库战车列表** | `vehicle_state`, attribute values | 战车状态图标 + 属性数值 | 车库界面 |
| **战车Tooltip** | All attribute fields | 属性详情面板 | HUD系统 (#49) |
| **载重显示** | `current_load`, `load_capacity`, `load_ratio` | "载重: 80/100" 或 "超载: 120%" | HUD系统 (#49) |

---

### HUD Layout Specification

**耐久条 (Durability Bar)**:

```
┌────────────────────────────┐
│ ████ 耐久 ████████░░░░ │ 70%
│ [绿色条 70%宽，渐变到黄色] │
└────────────────────────────┘
```

| Element | Data | Visual |
|---------|------|--------|
| 进度条填充 | `durability_ratio × 100%` | 比例决定宽度 |
| 颜色 | ratio映射 (见Visual Threshold Mapping) | 绿/黄/红渐变 |
| 数值显示 | `current_durability / max_durability` | "70/100" |
| 闪烁效果 | `should_retreat` AND durability below threshold | 红色闪烁 |

**魔能表 (Magic Energy Meter)**:

```
     ╱╲
   ╱    ╲  ← 魔力晶石容器
  │  ▓▓  │  ← 晶石填充 (magic_energy_ratio)
   ╲    ╱
     ╲╱
    "45%"
```

| Element | Data | Visual |
|---------|------|--------|
| 晶石填充高度 | `magic_energy_ratio × 180°` | 半圆形填充 |
| 晶石颜色 | ratio映射 (见Visual Threshold Mapping) | 蓝/黄/红渐变 |
| 脉动频率 | ratio决定 (0-50%正常, 20-50%加快, <20%急促) | 晶石发光脉动 |
| 数值显示 | `magic_energy_ratio × 100%` | "45%" |

---

### 出发检查界面 Specification

**出发条件显示 (Deploy Check UI)**:

```
┌─────────────────────┐
│ ◆ 出发检查          │
│ ─────────────────── │
│ 耐久: 85% ✓ (≥80%) │
│ 魔能: 45% ✗ (≥50%) │
│ ─────────────────── │
│ [出发] 按钮红灯     │
└─────────────────────┘
```

| Element | Data Query | Logic |
|---------|------------|-------|
| 耐久条件 | `durability_ratio ≥ 0.80` | ✓/✗图标 |
| 魔能条件 | `magic_energy_ratio ≥ 0.50` | ✓/✗图标 |
| 出发按钮状态 | `is_deployable` | 绿灯=可出发，红灯=不可出发 |
| 不足原因提示 | `warning_level` | 哪个条件不满足 |

---

### 撤退警告弹窗 Specification

**撤退警告触发条件 (Retreat Warning Popup)**:

| Trigger | `should_retreat` becomes true | Player sees |
|---------|-------------------------------|-------------|
| 魔能低于20% | magic_energy_ratio < 0.20 | 黄色警告弹窗 |
| 耐久低于30% | durability_ratio < 0.30 | 红色警告弹窗 |
| 双警告 | both below thresholds | 红色闪烁弹窗 + "立即撤退建议" |

**撤退警告弹窗布局**:

```
┌──────────────────────────────┐
│ ⚠ 撤退警告                    │
│ ──────────────────────────── │
│ 魔能: 15% ← 低于20%阈值       │
│ 耐久: 40%                     │
│ ──────────────────────────── │
│ 建议: 立即撤退，再搜一个废墟  │
│ 可能导致战车瘫痪              │
│ ──────────────────────────── │
│ [撤退] [继续搜刮]             │
└──────────────────────────────┘
```

---

### 车库界面 Specification

**战车状态面板 (Garage Status Panel)**:

```
┌──────────────────────────────┐
│ 标准战车 ★★☆☆                │
│ ──────────────────────────── │
│ 状态: 可出发 ✓                │
│ 耐久: ████████░░ 80%         │
│ 魔能: ██████████ 100%        │
│ 载重: 0/120 (空载)           │
│ 仓库: 120格 (空)             │
│ 武器槽: 2/2                   │
│ ──────────────────────────── │
│ [出发] [维修] [改装]          │
└──────────────────────────────┘
```

| Element | Data | Format |
|---------|------|--------|
| 状态图标 | `vehicle_state` | 文字 + ✓图标 |
| 耐久条 | `durability_ratio` | 进度条 + 百分比 |
| 魔能条 | `magic_energy_ratio` | 进度条 + 百分比 |
| 载重显示 | `current_load / load_capacity` | 数值 + 比例 |
| 仓库格子 | `warehouse_contents` | 已用/总数 |
| 武器槽 | `equipped_weapons.length / weapon_mounts` | 已装备/总数 |

---

### UI Interaction Requirements

| Interaction | Trigger | VehicleAttribute Action | UI Feedback |
|-------------|---------|-------------------------|-------------|
| 玩家点击出发 | 出发检查界面 | `transition_to_state(DEPLOYED)` if is_deployable | 出发成功动画 OR 失败提示 |
| 玩家点击维修 | 车库界面 | `repair_durability()` | 维修进度条动画 |
| 玩家点击魔能补充 | 车库界面 | `charge_magic_energy()` | 补充动画 |
| 玩家装备武器 | 武器装备界面 | `equip_weapon()` | 武器图标显示到槽位 |
| 玩家卸载仓库 | 仓库卸载界面 | `apply_load_change(-unload)` | 仓库内容清空 |
| 撤退警告响应 | 撤退警告弹窗 | Player choice → [撤退] or [继续] | UI关闭，状态转换 |

---

### UI Localization Support

VehicleAttribute提供本地化数据键：

| Data | Localization Key | Example (中文) |
|------|------------------|----------------|
| vehicle_state | `vehicle_state_{state_value}` | "停放" / "可出发" / "出发中" / "瘫痪" |
| 警告级别 | `warning_level_{level}` | "无警告" / "魔能警告" / "耐久警告" / "双警告" |
| 撤退建议 | `retreat_advice_{level}` | "魔能不足，建议撤退" / "耐久不足，立即撤退" |

---

### No UI Rendering by VehicleAttribute

VehicleAttribute不包含以下内容：
- Control节点或UI组件
- Font或Label资源
- StyleBox或Theme资源

所有UI渲染由HUD系统 (#49) 负责。VehicleAttribute仅提供数据和信号。

## Acceptance Criteria

### Data Integrity Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-001** | VehicleInstance registry loaded | 启动游戏，检查VehicleAttribute autoload | VehicleAttribute._ready()完成，无error log |
| **AC-002** | Instance ID unique | 创建多个实例，检查instance_id | 每个instance_id唯一，无冲突 |
| **AC-003** | Instance creation with valid type | `create_vehicle_instance(100)` | 返回VehicleInstance，属性从类型定义初始化 |
| **AC-004** | Instance creation rejects invalid type | `create_vehicle_instance(0)` | 返回null，log warning |
| **AC-005** | Instance creation rejects missing type | `create_vehicle_instance(9999)` | 返回null，log warning |
| **AC-006** | Durability initialized from type def | 检查new instance current_durability | current_durability = type_def.max_durability |
| **AC-007** | Magic energy initialized from type def | 检查new instance current_magic_energy | current_magic_energy = type_def.max_magic_energy |
| **AC-008** | Speed initialized from type def | 检查new instance current_speed | current_speed = type_def.base_speed |
| **AC-009** | Load initialized to 0 | 检查new instance current_load | current_load = 0 |
| **AC-010** | Vehicle state initialized to GARAGE_IDLE | 检查new instance vehicle_state | vehicle_state = 0 (GARAGE_IDLE) |
| **AC-011** | Weapon slots initialized to empty | 检查new instance equipped_weapons | equipped_weapons = [] |

---

### Attribute Query Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-012** | Valid instance returns correct durability | `get_current_durability(instance_id)` | Returns int matching stored value |
| **AC-013** | Valid instance returns correct ratio | `get_durability_ratio(instance_id)` | Returns float = current/max |
| **AC-014** | Invalid instance returns default | `get_current_durability(999)` | Returns 0, log warning |
| **AC-015** | Ratio formula correct at boundary | durability=30, max=100 | durability_ratio = 0.30 |
| **AC-016** | Speed formula correct at empty load | current_load=0 | current_speed = base_speed |
| **AC-017** | Speed formula correct at full load | current_load=load_capacity | current_speed = base_speed × 0.7 |
| **AC-018** | Speed formula correct at overload | current_load=150, capacity=100 | current_speed = base_speed × 0.7 (clamp) |
| **AC-019** | is_deployable correct at threshold | durability_ratio=0.80, magic_ratio=0.50 | is_deployable = true |
| **AC-020** | is_deployable correct below threshold | durability_ratio=0.75 | is_deployable = false |
| **AC-021** | should_retreat correct at threshold | magic_ratio=0.20, durability_ratio=0.30 | should_retreat = false (边界不触发) |
| **AC-022** | should_retreat correct below threshold | magic_ratio=0.15 | should_retreat = true |
| **AC-023** | warning_level correct for magic only | magic_ratio=0.15, durability_ratio=0.50 | warning_level = 1 |
| **AC-024** | warning_level correct for durability only | magic_ratio=0.50, durability_ratio=0.25 | warning_level = 2 |
| **AC-025** | warning_level correct for both | magic_ratio=0.15, durability_ratio=0.25 | warning_level = 3 |

---

### Attribute Modification Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-026** | Durability damage applied correctly | `apply_durability_damage(instance_id, 30)` | current_durability decreased by 30 |
| **AC-027** | Durability damage clamped to 0 | `apply_durability_damage(instance_id, 150)` on durability=100 | current_durability = 0, no negative |
| **AC-028** | Durability damage triggers state change | Apply damage until durability=0 | vehicle_state → DISABLED |
| **AC-029** | Magic energy cost applied correctly | `apply_magic_energy_cost(instance_id, 20)` | current_magic_energy decreased by 20 |
| **AC-030** | Magic energy cost rejected if insufficient | Apply cost > current_magic_energy | Returns false, current unchanged |
| **AC-031** | Magic energy depletion triggers state | Apply cost until magic=0 | vehicle_state → DISABLED |
| **AC-032** | Load change applied correctly | `apply_load_change(instance_id, 50)` | current_load increased by 50 |
| **AC-033** | Load change triggers speed recalc | Load change applied | current_speed updated per formula |
| **AC-034** | Repair durability capped at max | `repair_durability(instance_id, 50)` on current=80, max=100 | current_durability = 100 (no overflow) |
| **AC-035** | Charge magic energy capped at max | `charge_magic_energy(instance_id, 30)` on current=80, max=100 | current_magic_energy = 100 |

---

### State Transition Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-036** | GARAGE_IDLE → DEPLOYABLE transition | Repair to durability_ratio ≥ 0.80 | vehicle_state → 1 (DEPLOYABLE) |
| **AC-037** | DEPLOYABLE → GARAGE_IDLE transition | Damage to durability_ratio < 0.80 | vehicle_state → 0 (GARAGE_IDLE) |
| **AC-038** | DEPLOYABLE → DEPLOYED transition | `transition_to_state(DEPLOYED)` when deployable | vehicle_state → 2 (DEPLOYED) |
| **AC-039** | DEPLOYED → DEPLOYABLE transition | Player returns to garage | vehicle_state → 1 (DEPLOYABLE) |
| **AC-040** | DEPLOYED → DISABLED transition (durability) | durability hits 0 | vehicle_state → 3 (DISABLED) |
| **AC-041** | DEPLOYED → DISABLED transition (magic) | magic hits 0 | vehicle_state → 3 (DISABLED) |
| **AC-042** | Invalid transition rejected | `transition_to_state(DEPLOYED)` from GARAGE_IDLE | Returns false, state unchanged |

---

### Signal Emission Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-043** | durability_changed signal emitted | Apply durability damage | Signal emitted with old/new values |
| **AC-044** | magic_energy_changed signal emitted | Apply magic cost | Signal emitted with old/new values |
| **AC-045** | load_changed signal emitted | Apply load change | Signal emitted with old/new values |
| **AC-046** | vehicle_state_changed signal emitted | Transition state | Signal emitted with old/new states |
| **AC-047** | durability_depleted signal emitted | Durability hits 0 | Signal emitted |
| **AC-048** | magic_energy_depleted signal emitted | Magic hits 0 | Signal emitted |
| **AC-049** | retreat_warning_triggered signal emitted | should_retreat becomes true | Signal emitted with warning_level |
| **AC-050** | deployable_changed signal emitted | is_deployable changes | Signal emitted with new value |

---

### Edge Case Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-051** | Zero durability ratio handled | durability=0 | durability_ratio=0.0, no division error |
| **AC-052** | Zero magic ratio handled | magic=0 | magic_ratio=0.0, no division error |
| **AC-053** | Zero load handled | load=0 | load_ratio=0.0, speed = base_speed |
| **AC-054** | Overload handled | load > capacity | load_ratio > 1.0, speed clamped |
| **AC-055** | Destroyed instance unqueryable | Destroy instance, then query | Returns 0 or null, log warning |
| **AC-056** | Type def with max_durability=0 rejected | Create instance with invalid type | Returns null, log error |
| **AC-057** | Weapon slot index out of range rejected | `equip_weapon(slot_index=5)` on mounts=2 | Returns false, log warning |

---

### Performance Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-058** | Query latency < 0.1ms | Loop `get_durability_ratio()` 1000 times | Average < 0.1ms |
| **AC-059** | Instance creation latency < 5ms | Create 100 instances | Average < 5ms |
| **AC-060** | Signal emission latency < 0.05ms | Emit signal on attribute change | Latency < 0.05ms |
| **AC-061** | Registry memory < 100KB per instance | Measure memory per VehicleInstance | < 100KB |

---

### Pass/Fail Threshold

| Category | Pass Count | Fail Action |
|----------|------------|-------------|
| **Data Integrity (AC-001 to AC-011)** | 必须100%通过 | 任一失败 → 数据定义错误，必须修复 |
| **Attribute Query (AC-012 to AC-025)** | 必须100%通过 | 任一失败 → API实现错误，必须修复 |
| **Attribute Modification (AC-026 to AC-035)** | 必须100%通过 | 任一失败 → 修改逻辑错误，必须修复 |
| **State Transition (AC-036 to AC-042)** | 必须100%通过 | 任一失败 → 状态机实现错误，必须修复 |
| **Signal Emission (AC-043 to AC-050)** | 必须100%通过 | 任一失败 → 信号架构错误，必须修复 |
| **Edge Cases (AC-051 to AC-057)** | 必须100%通过 | 任一失败 → 边界处理缺失，必须补充 |
| **Performance (AC-058 to AC-061)** | 建议通过 | 任一失败 → 性能优化，但可进入实现阶段 |

**Total Criteria**: 61
**Required for Implementation**: 100% pass on all blocking categories

## Open Questions

### High Priority (Implementation Blocking)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-001** | VehicleInstance存储架构：使用Autoload singleton全局registry，还是per-instance Node（每个战车一个节点）？ | 技术总监 | 实现开始前 | 影响查询接口设计、信号发射架构、性能优化方向 |
| **Q-002** | 魔能补充是瞬时恢复还是时间-based regeneration？魔能补充速率是否需要配置？ | 游戏设计者 | 魔能消耗系统 (#19) 设计前 | 影响魔能恢复机制和车库等待时间 |
| **Q-003** | DISABLED状态在MVP阶段如何处理：战车丢失（玩家步行逃回后战车消失）还是战车留在原地等待后续救援？ | 游戏设计者 | 实现开始前 | 影响状态机实现和Alpha功能（多战车管理）设计 |

---

### Medium Priority (Design Clarification)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-004** | 装备武器时是否需要验证武器类型兼容性（weapon_type_allowed[]）？如果列表为空，是否允许所有武器类型？ | 游戏设计者 + 武器系统设计者 | 战车武器系统 (#20) 设计前 | 影响武器装备接口和错误处理 |
| **Q-005** | 改装系统是否影响属性上限（如改装装甲提升max_durability）？还是只影响运行时属性（如护甲增强）？ | 游戏设计者 + 改装系统设计者 | 战车改装系统 (#23) 设计前 | 影响改装数据结构和属性修改逻辑 |
| **Q-006** | 车库内状态转换是否需要过渡动画/等待时间？例如维修是否需要等待进度条完成？ | UX设计者 | HUD系统 (#49) 设计前 | 影响UI交互流程和等待反馈 |

---

### Low Priority (Future Consideration)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-007** | 是否需要支持战车属性持久化（存档系统保存当前耐久/魔能值）？存档时机如何确定？ | 存档系统设计者 | 存档系统 (#54) 设计前 | 影响存档数据结构 |
| **Q-008** | 多战车管理（Alpha功能）如何区分当前驾驶战车？是否需要"切换战车"功能？ | 多战车管理系统设计者 | 多战车管理 (#26) 设计前 | 影响instance_id管理逻辑 |
| **Q-009** | DESTROYED状态是否需要特殊处理（战车报废后资源回收、残留物品处理）？ | 游戏设计者 | Alpha里程碑前 | 影响战车报废流程设计 |

---

### Resolution Tracking

| ID | Status | Resolution Date | Resolved By | Summary |
|----|--------|-----------------|-------------|---------|
| Q-001 | Open | — | — | Pending 技术总监决策 → 需要ADR |
| Q-002 | Open | — | — | Pending 魔能消耗系统 (#19) GDD |
| Q-003 | Open | — | — | Pending 游戏设计者决策 |
| Q-004 | Open | — | — | Pending 武器系统 (#20) GDD |
| Q-005 | Open | — | — | Pending 改装系统 (#23) GDD |
| Q-006 | Open | — | — | Pending UX设计者决策 |
| Q-007 | Open | — | — | Pending 存档系统 (#54) GDD |
| Q-008 | Open | — | — | Pending 多战车管理 (#26) GDD |
| Q-009 | Open | — | — | Pending Alpha阶段 |

---

### Assumptions Made

| Assumption | Rationale | Risk |
|------------|-----------|------|
| **MVP单战车管理** | 游戏概念未明确多战车，MVP阶段简化为单实例管理 | 如果Alpha需要多战车，需重构instance registry |
| **魔能补充为瞬时恢复** | MVP阶段简化车库交互，无等待时间 | 如果需要时间-based regeneration，需增加配置和UI进度条 |
| **DISABLED = 战车丢失（MVP）** | MVP阶段不支持战车救援，步行逃回后战车消失 | Alpha阶段需扩展为战车留在原地等待救援 |
| **Autoload singleton架构** | 与VehicleTypeDatabase保持一致，便于查询 | 如果per-instance Node更合适，需重构数据存储 |
| **武器类型兼容性由WeaponDatabase验证** | weapon_type_allowed[]为空表示全类型允许 | 武器系统需定义类型验证逻辑 |
| **改装不影响属性上限** | 改装只修改运行时属性（护甲增强），不修改max_durability等上限 | 如果改装影响上限，需修改VehicleInstance数据结构 |

---

### Recommended ADR Creation

以下问题需通过`/architecture-decision`创建ADR解决：

| Question | ADR Title | Priority |
|----------|-----------|----------|
| Q-001 | VehicleInstance存储架构 | High |