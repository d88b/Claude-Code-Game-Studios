# 战车损坏系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 1 (战车即生命), Pillar 3 (尸潮即高潮)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #21 (from systems-index.md)

## Overview

战车损坏系统是管理战车耐久值消耗和损坏状态转换的核心系统。该系统接收来自敌人攻击、碰撞冲击的伤害事件，计算实际伤害（应用护甲减伤），扣除耐久值，并根据耐久阈值触发状态转换（DISABLED瘫痪）。系统连接敌人AI攻击输出与战车属性系统耐久输入，是战斗伤害传递的核心桥梁。

**数据层定位**：损坏系统处理伤害事件流：
- 接收伤害输入（来源：敌人攻击、碰撞冲击、特殊攻击）
- 应用护甲减伤公式计算实际伤害
- 调用`VehicleAttribute.apply_durability_damage()`扣除耐久
- 监听耐久阈值触发状态转换信号

**系统必要性**：没有损坏系统，游戏将无法：
- 将敌人攻击转化为战车耐久消耗（敌人攻击无效果）
- 实现护甲减伤机制（护甲属性无意义）
- 触发战车瘫痪（耐久归零无后果）
- 为撤退判定系统提供耐久下降驱动（撤退触发无数据源）

**服务于支柱**：
- **Pillar 1 (战车即生命)**：损坏系统是战车"生命损耗"的核心机制——每一次敌人攻击都是战车"受伤"，护甲减伤是战车"抵御伤害"，耐久归零是战车"死亡"
- **Pillar 3 (尸潮即高潮)**：损坏系统将尸潮敌人的攻击转化为真实耐久压力，创造"战车撑得住吗？"的紧张体验

## Player Fantasy

战车损坏系统是纯基础设施层系统，玩家不直接与该系统交互，而是感知其产生的效果：

- **间接体验——耐久下降的恐惧**：玩家看到HUD耐久条下降，听到攻击音效，感受到的是战车正在"受伤"。损坏系统是幕后计算者，将敌人攻击转化为耐久损耗数据
- **间接体验——护甲减伤的感知**：玩家驾驶重装甲战车时，观察到同样敌人攻击造成的耐久下降更少，感受到的是"厚装甲有效"。损坏系统的护甲公式是这种感知的数据基础
- **间接体验——瘫痪危机**：玩家面对耐久归零、战车瘫痪的瞬间，感受到的是"战车撑不住了"。损坏系统的阈值检测是触发瘫痪状态的数据驱动者

该系统服务于上游系统（战车属性系统）的状态管理，为下游系统（撤退判定、战车维修）提供事件触发。玩家感知的是战车属性系统的HUD输出，损坏系统是其背后的"伤害计算引擎"。

## Detailed Design

### Core Rules

#### 1. Damage Event Processing Pipeline

损坏系统处理伤害事件的完整流水线：

1. **事件接收**：系统监听伤害事件信号（敌人攻击、碰撞冲击、特殊攻击）
2. **伤害来源识别**：解析事件来源类型，应用不同处理逻辑
3. **护甲减伤计算**：调用公式计算实际伤害（见Formulas节）
4. **耐久扣除**：调用`VehicleAttribute.apply_durability_damage(instance_id, actual_damage)`
5. **阈值检测**：检查耐久比例是否触发状态转换（归零 → DISABLED）
6. **信号发射**：发射损坏事件信号供下游系统订阅

---

#### 2. Damage Source Types

伤害来源分类及其处理方式：

| Source Type | ID | Trigger | Damage Input | Special Processing |
|-------------|----|---------|--------------|--------------------|
| **敌人近战攻击** | 1 | `enemy_body_entered` signal | `enemy.damage` (from EnemyTypeDB) | 应用护甲减伤，攻击冷却检查 |
| **敌人远程攻击** | 2 | `projectile_hit` signal | `enemy.damage` + projectile modifier | 应用护甲减伤，无冷却检查 |
| **碰撞冲击** | 3 | `collision_impact` signal | severity from block-collision-system | 部分护甲减伤（50% effectiveness） |
| **特殊攻击** | 4 | `special_attack` signal | custom damage value | 可能绕过护甲（如腐蚀攻击） |
| **环境伤害** | 5 | `environment_hazard` signal | hazard damage value | 无护甲减伤（直接扣除） |

---

#### 3. Enemy Attack Detection

敌人攻击战车的检测机制：

**接触检测（近战攻击）：**
- 战车碰撞层：`COLLISION_PLAYER_BODY` (Bit 6, value 64)
- 敌人碰撞掩码：检测 Bit 6
- 当敌人Area2D接触战车碰撞体 → 触发`body_entered`信号
- 信号携带：`enemy_id`, `contact_position`, `contact_time`

**远程攻击检测：**
- 战车碰撞层：`COLLISION_PLAYER_BODY` (Bit 6)
- 敌人投射物碰撞层：`COLLISION_ENEMY_PROJECTILE`（待定义）
- 投射物Area2D接触战车 → 触发`projectile_hit`信号
- 信号携带：`projectile_type_id`, `source_enemy_id`, `hit_position`

---

#### 4. Attack Cooldown Tracking

敌人攻击有冷却间隔，防止同一敌人无限连续攻击：

- 每个敌人实例维护`last_attack_time`记录
- 攻击冷却 = `attack_cooldown`（从EnemyTypeDB读取）
- 攻击触发时检查：`current_time - last_attack_time >= attack_cooldown`
- 冷却未满足 → 拒绝攻击，不扣耐久
- 冷却满足 → 执行攻击，更新`last_attack_time`

**Cooldown Exception:**
- 远程投射物攻击无冷却检查（投射物本身就是冷却机制）
- 多敌人同时攻击：各自独立冷却，不共享

---

#### 5. Multi-Contact Handling (Stacking Rule)

当多个敌人同时接触战车时，伤害处理规则：

| Scenario | Behavior | Rationale |
|----------|----------|-----------|
| **2个敌人同时接触** | 各敌人独立计算伤害，分别扣除 | 尸潮包围的真实压力 |
| **N个敌人包围（N>2）** | 各敌人独立攻击，按攻击触发顺序依次扣除 | 不人为限制包围惩罚 |
| **同一敌人多次接触** | 每次接触触发攻击检测，受冷却限制 | 防止单敌人无限攻击 |
| **攻击间隔<帧时间** | 多次攻击在同一帧触发 → 累加后一次性扣除 | 性能优化，减少信号次数 |

**Implementation Note:** 每帧累加所有有效攻击伤害，帧末一次性调用`apply_durability_damage(total_damage)`。

---

#### 6. Durability Threshold Detection

耐久阈值检测触发状态转换：

| Threshold | Trigger Condition | State Transition | Signal Emitted |
|-----------|-------------------|------------------|----------------|
| **归零阈值** | `current_durability = 0` | `DEPLOYED` → `DISABLED` | `durability_depleted` |
| **撤退阈值** | `durability_ratio < 0.30` | 无状态转换（警告触发） | `retreat_warning_triggered` (level=2 or 3) |
| **出发阈值** | `durability_ratio < 0.80` (车库内) | `DEPLOYABLE` → `GARAGE_IDLE` | `deployable_changed(false)` |

**Threshold Check Timing:**
- 每次耐久扣除后立即检查阈值
- 检查顺序：归零 → 撤退 → 出发（按紧急程度）
- 阈值检测由VehicleAttribute系统负责，损坏系统仅触发耐久扣除

---

### States and Transitions

损坏系统本身无状态机，它驱动VehicleAttribute系统的状态转换：

| Trigger Event | VehicleAttribute State Change | Damage System Action |
|---------------|------------------------------|----------------------|
| `current_durability = 0` | `DEPLOYED` → `DISABLED` | 发射`durability_depleted`信号，停止接受新伤害事件 |
| `durability_ratio crosses 0.30` | 无变化（警告触发） | 无直接动作，由VehicleAttribute发射撤退警告信号 |
| `durability_ratio crosses 0.80` (车库) | `DEPLOYABLE` → `GARAGE_IDLE` | 无直接动作，由VehicleAttribute处理 |

**Damage System State:** 始终处于"活跃监听"状态，接收并处理伤害事件。无内部状态切换。

---

### Interactions with Other Systems

#### Upstream Systems (Data Providers)

| System | Interface | Data Flow | Trigger Timing |
|--------|-----------|-----------|----------------|
| **敌人AI系统 (#36)** | `enemy_attack_signal` | `enemy_id`, `damage`, `attack_type` | 敌人攻击触发时 |
| **敌人类型数据库 (#4)** | `get_enemy_definition(enemy_id)` | `damage`, `attack_cooldown`, `behavior_hint` | 攻击事件处理时查询 |
| **方块碰撞系统 (#11)** | `collision_impact_signal` | `severity`, `impact_type` | 碰撞发生时 |
| **战车类型数据库 (#6)** | `get_armor(vehicle_type_id)` | `armor` (0-80) | 护甲减伤计算时 |

#### Downstream Systems (Data Consumers)

| System | Interface | Data Flow | Trigger Timing |
|--------|-----------|-----------|----------------|
| **战车属性系统 (#17)** | `apply_durability_damage(instance_id, damage)` | `actual_damage` | 每次伤害事件处理后 |
| **撤退判定系统 (#32)** | `durability_depleted` signal | `instance_id` | 耐久归零时（订阅信号） |
| **战车维修系统 (#22)** | 无直接接口 | 通过VehicleAttribute查询`current_durability` | 维修时读取状态 |
| **HUD系统 (#49)** | 无直接接口 | 通过VehicleAttribute获取`durability_ratio` | HUD渲染时 |
| **音效系统 (#52)** | `damage_taken_signal` (新定义) | `damage_amount`, `damage_type` | 每次伤害扣除后 |

#### Signal Contract

损坏系统发射以下信号：

```gdscript
# VehicleDamage signals (emitted by damage system)
signal damage_received(instance_id: int, source_type: int, raw_damage: int, actual_damage: int)
signal durability_threshold_crossed(instance_id: int, threshold_type: int)  # 1=retreat, 2=depleted
signal armor_effective(instance_id: int, damage_blocked: int)  # 护甲减伤效果反馈
```

## Formulas

### 1. Armor Damage Reduction Formula

护甲减伤计算，将原始伤害转化为实际伤害。

```
damage_reduction = armor / 100
damage_reduction = min(damage_reduction, MAX_ARMOR_REDUCTION)
actual_damage = raw_damage × (1 - damage_reduction)
actual_damage = max(actual_damage, MINIMUM_DAMAGE)
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `raw_damage` | RD | int | 1-100 | EnemyTypeDB.damage or collision severity |
| `armor` | A | int | 0-80 | VehicleTypeDB.get_armor() |
| `MAX_ARMOR_REDUCTION` | MAR | float | 0.80 | entities.yaml (locked) |
| `MINIMUM_DAMAGE` | MD | int | 1 | entities.yaml (tunable 1-5) |
| `damage_reduction` | DR | float | 0.0-0.80 | Computed |
| `actual_damage` | AD | int | 1-100 | Output |

**Output Range:** 1 ≤ actual_damage ≤ raw_damage（护甲80%时最低20%伤害，保底1点）

**Boundary Tests:**

| Case | raw_damage | armor | damage_reduction | actual_damage |
|------|------------|-------|------------------|---------------|
| 无护甲 | 50 | 0 | 0.0 | 50 (全伤) |
| 轻护甲 | 50 | 20 | 0.20 | 40 |
| 中护甲 | 50 | 50 | 0.50 | 25 |
| 重护甲 | 50 | 80 | 0.80 (clamp) | 10 (最大减伤) |
| 超限护甲 | 50 | 95 | 0.80 (clamp to MAR) | 10 |
| 小伤害保底 | 5 | 80 | 0.80 | 1 (min=1保底) |

**Example:**
- 战车 (armor=65), 敌人 (damage=40)
- damage_reduction = 0.65 → actual_damage = 40 × 0.35 = 14

---

### 2. Collision Impact Damage Formula

碰撞冲击伤害计算，部分应用护甲减伤。

```
collision_damage = collision_severity × (1 - armor × COLLISION_ARMOR_EFFECTIVENESS)
collision_damage = max(collision_damage, MINIMUM_DAMAGE)
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `collision_severity` | CS | int | 1-20 | block-collision-system computed |
| `armor` | A | int | 0-80 | VehicleTypeDB.get_armor() |
| `COLLISION_ARMOR_EFFECTIVENESS` | CAE | float | 0.50 | Tunable 0.3-0.7 |
| `MINIMUM_DAMAGE` | MD | int | 1 | entities.yaml |
| `collision_damage` | CD | int | 1-20 | Output |

**Output Range:** 1 ≤ collision_damage ≤ collision_severity

**Boundary Tests:**

| Case | collision_severity | armor | effective_reduction | collision_damage |
|------|--------------------|-------|---------------------|------------------|
| 无护甲碰撞 | 10 | 0 | 0.0 | 10 (全伤) |
| 重护甲碰撞 | 10 | 80 | 0.40 (80×0.5) | 6 |
| 最大碰撞 | 20 | 80 | 0.40 | 12 |
| 小碰撞保底 | 3 | 80 | 0.40 | 2 → clamp to 1 |

**Example:**
- 战车 (armor=65), 碰撞 (severity=8)
- effective_reduction = 65 × 0.50 = 0.325 → collision_damage = 8 × 0.675 = 5

---

### 3. Multi-Contact Frame Accumulation Formula

同一帧内多次攻击伤害累加。

```
frame_accumulated_damage = Σ(actual_damage_i) for all valid attacks in frame
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `actual_damage_i` | AD_i | int | 1-100 | Per-attack computed damage |
| `valid_attacks_count` | N | int | 0-50 | Frame内的有效攻击数 |
| `frame_accumulated_damage` | FAD | int | 0-5000 | Output (sum) |

**Output Range:** 0 (无攻击) ≤ FAD ≤ N × 100 (N个最大伤害攻击)

**Boundary Tests:**

| Case | Attacks in Frame | Individual Damages | FAD |
|------|------------------|--------------------|-----|
| 无攻击 | 0 | — | 0 |
| 单攻击 | 1 | 14 | 14 |
| 3敌人包围 | 3 | 14, 25, 10 | 49 |
| 尸潮包围 | 10 | 平均15 | 150 |
| 极端包围 | 50 | 平均5 | 250 |

**Example:**
- 帧内5个僵尸攻击，各伤害10, 8, 12, 7, 9
- FAD = 10 + 8 + 12 + 7 + 9 = 46

---

### 4. Attack Cooldown Check Formula

攻击冷却有效性判断。

```
is_attack_valid = (current_game_time - last_attack_time) >= attack_cooldown
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `current_game_time` | CGT | float | 0-∞ | TimeSystem.get_game_time() |
| `last_attack_time` | LAT | float | 0-∞ | Enemy instance stored |
| `attack_cooldown` | AC | float | 0.5-5.0 | EnemyTypeDB.attack_cooldown |
| `is_attack_valid` | — | bool | true/false | Output |

**Output:** true = 攻击有效，执行扣除；false = 攻击无效，跳过

**Boundary Tests:**

| Case | current_time | last_attack | cooldown | is_valid |
|------|--------------|-------------|----------|----------|
| 初始攻击 | 1.0 | 0.0 (never) | 1.0 | true |
| 刚过冷却 | 2.0 | 1.0 | 1.0 | true (≥满足) |
| 冷却中 | 1.5 | 1.0 | 1.0 | false (0.5 < 1.0) |
| 快速敌人 | 1.3 | 1.0 | 0.5 | false (0.3 < 0.5) |
| Wait → true | 1.5 | 1.0 | 0.5 | true (0.5 ≥ 0.5) |

**Example:**
- 僵尸 (cooldown=1.0秒), last_attack=5.0秒, current=5.8秒
- 5.8 - 5.0 = 0.8 < 1.0 → is_valid = false (冷却未满)

---

### 5. Damage Blocked Feedback Formula

护甲减伤效果的反馈值计算（用于视觉/音频反馈）。

```
damage_blocked = raw_damage - actual_damage
armor_effectiveness_ratio = damage_blocked / raw_damage
```

**Variables:**

| Variable | Symbol | Type | Range | Source |
|----------|--------|------|-------|--------|
| `raw_damage` | RD | int | 1-100 | EnemyTypeDB.damage |
| `actual_damage` | AD | int | 1-100 | Formula 1 output |
| `damage_blocked` | DB | int | 0-99 | Computed |
| `armor_effectiveness_ratio` | AER | float | 0.0-0.80 | Output |

**Output Range:** 0 ≤ damage_blocked ≤ raw_damage × MAX_ARMOR_REDUCTION

**Example:**
- raw_damage=50, actual_damage=14
- damage_blocked = 50 - 14 = 36
- armor_effectiveness_ratio = 36/50 = 0.72 (护甲阻挡了72%伤害)

## Edge Cases

### 1. Zero/Negative Durability Handling

**If current_durability reaches 0 exactly**: Clamp to 0, trigger `DEPLOYED` → `DISABLED` state transition, emit `durability_depleted` signal. 战车瘫痪，停止接受新伤害事件。

**If damage exceeds remaining durability**: Clamp `current_durability` to 0 (no negative), execute disabled state transition as above. VehicleAttribute handles the clamp internally.

**If durability is already 0 and new damage arrives**: Reject damage event (战车已瘫痪，不接受伤害). Log warning: "Damage rejected on disabled vehicle."

---

### 2. Zero/Negative Damage Input Handling

**If raw_damage = 0**: Skip processing, no durability deduction. Log debug: "Zero damage event received, skipped."

**If raw_damage < 0**: Reject as invalid input. Log warning: "Negative damage rejected." Return without processing.

**If collision_severity = 0**: Skip collision damage processing. Collision system should not emit zero-severity signals.

---

### 3. Armor Out of Range Handling

**If armor > 80 (exceeds MAX_ARMOR_REDUCTION)**: Clamp armor reduction to MAX_ARMOR_REDUCTION (0.80). Actual damage = raw_damage × 0.20 minimum. VehicleTypeDB validation should reject armor > 80 at definition stage.

**If armor < 0**: Treat as armor = 0 (no reduction). Log warning: "Negative armor treated as 0." This should not happen if VehicleTypeDB validates properly.

---

### 4. Multi-Attack Simultaneous Threshold Crossing

**If multiple attacks in one frame cause durability to cross multiple thresholds**: Process thresholds in priority order: 归零 → 撤退 → 出发. Only the highest-priority threshold triggers signal emission. If durability crosses from 35% to 0% in one frame, only `durability_depleted` is emitted, not retreat warning.

---

### 5. Attack During State Transition

**If damage arrives while vehicle state is transitioning**: Process damage after state transition completes. If transitioning to `DISABLED`, subsequent damage is rejected. If transitioning to `GARAGE_IDLE`, damage still processed (战车仍在运行).

---

### 6. Enemy Instance Destroyed Mid-Attack

**If enemy that triggered attack is destroyed before cooldown expires**: Cooldown tracking uses enemy instance ID. Destroyed enemy's cooldown record is cleaned up on next frame. Attack was already processed; no retroactive reversal.

---

### 7. Projectile Hits Disabled Vehicle

**If projectile hits vehicle already in DISABLED state**: Reject projectile damage. Projectile continues (does not despawn on hit) or despawns on terrain. Disabled vehicle is not valid damage target.

---

### 8. Collision Damage During Magic Energy Depletion

**If vehicle is simultaneously taking collision damage and magic depletion**: Process independently. Collision damage deducts durability, magic depletion deducts magic energy. Either reaching zero triggers `DISABLED` state. Order does not matter—both systems call VehicleAttribute independently.

---

### 9. Frame Accumulation Overflow

**If frame_accumulated_damage exceeds 5000 (extreme edge)**: Apply damage in batches of 500 per call to `apply_durability_damage()` to prevent single-call overflow. VehicleAttribute should handle large damage values correctly, but batching is safer for visual feedback timing.

---

### 10. Unknown Damage Source Type

**If damage event has unrecognized source_type**: Log warning: "Unknown damage source type [X], defaulting to type 1 (enemy melee)." Process with full armor reduction (default conservative approach).

---

### 11. Time System Unavailable for Cooldown Check

**If TimeSystem.get_game_time() returns invalid value**: Default to allowing attack (fail-open behavior). Log warning: "Time check failed, attack allowed by default." Gameplay impact is minor (potential extra attacks), preferable to blocking all attacks.

---

### 12. Boss/Miniboss Special Damage

**If enemy tier is 4 (Miniboss) or 5 (Boss)**: Apply special damage multiplier defined in EnemyTypeDB. Boss attacks may have `wall_damage_multiplier` or special ability that bypasses armor. Check `special_ability` field for armor pierce flag. If flagged: actual_damage = raw_damage (no armor reduction).

## Dependencies

### Upstream Dependencies (Blocking)

| System | Priority | Layer | Data Provided | Dependency Type | GDD Status |
|--------|----------|-------|---------------|-----------------|------------|
| **战车属性系统 (#17)** | MVP | Core | `apply_durability_damage()`, `get_armor()`, durability threshold signals | **Blocking** — Cannot deduct durability without VehicleAttribute interface | ✓ Designed |
| **战车类型数据库 (#6)** | MVP | Foundation | `get_armor(vehicle_type_id)` — armor value for damage reduction | **Blocking** — Cannot compute armor reduction without armor data | ✓ Designed |
| **敌人类型数据库 (#4)** | MVP | Foundation | `get_enemy_definition(enemy_id)` — damage, attack_cooldown values | **Blocking** — Cannot process enemy attacks without enemy damage data | ✓ Designed |
| **时间系统 (#8)** | MVP | Foundation | `get_game_time()` — for attack cooldown tracking | **Soft-blocking** — Can use frame counting as fallback if time unavailable | ✓ Designed |
| **方块碰撞系统 (#11)** | MVP | Core | `collision_impact_signal` — collision severity for impact damage | **Soft-blocking** — Collision damage is secondary, not core loop | ✓ Approved |

---

### Downstream Dependencies (Consumers)

| System | Priority | Layer | Data Consumed | Dependency Type | GDD Status |
|--------|----------|-------|---------------|-----------------|------------|
| **撤退判定系统 (#32)** | MVP | Core | `durability_depleted` signal, durability_ratio changes | **Blocking** — Retreat trigger depends on durability threshold crossing | Not Started |
| **战车维修系统 (#22)** | Vertical Slice | Feature | `current_durability` (via VehicleAttribute) | **Blocking** — Repair needs to know current durability state | Not Started |
| **战车瘫痪处理 (#24)** | Vertical Slice | Feature | `durability_depleted` signal, DISABLED state trigger | **Blocking** — Paralyzed handling starts when durability reaches 0 | Not Started |
| **音效系统 (#52)** | Full Vision | Presentation | `damage_received` signal, `armor_effective` signal | **Non-blocking** — Audio enhances but not required for damage logic | Not Started |
| **HUD系统 (#49)** | Full Vision | Presentation | durability_ratio (via VehicleAttribute) | **Non-blocking** — UI displays durability but not required for damage processing | Not Started |

---

### Bidirectional Dependency Check

| System | Listed in This GDD | Listed in Target GDD | Status |
|--------|--------------------|---------------------|--------|
| VehicleAttribute (#17) | ✓ Upstream Blocking | ✓ Listed in #17 "Depended on by VehicleDamage" | ✓ Consistent |
| RetreatJudge (#32) | ✓ Downstream Blocking | Target Not Started | Pending verification |
| VehicleRepair (#22) | ✓ Downstream Blocking | Target Not Started | Pending verification |
| VehicleParalyzed (#24) | ✓ Downstream Blocking | Target Not Started | Pending verification |

---

### Critical Dependency Path (MVP)

```
VehicleTypeDB (#6) → VehicleAttribute (#17)
EnemyTypeDB (#4) → VehicleDamage (#21) [THIS SYSTEM]
TimeSystem (#8) → VehicleDamage (#21)
CollisionSystem (#11) → VehicleDamage (#21) (soft)
VehicleDamage (#21) → RetreatJudge (#32)
```

---

### Interface Contract Summary

损坏系统必须实现的接口以满足下游依赖：

| Interface | Consumer | Contract |
|-----------|----------|----------|
| `process_damage_event(source_type, raw_damage, enemy_id)` | EnemyAI, CollisionSystem | Called on damage event, deducts durability |
| `get_last_attack_time(enemy_id)` | Internal (cooldown tracking) | Returns timestamp for cooldown check |
| `damage_received` signal | AudioSystem, HUD | Emitted after each damage processing |
| `armor_effective` signal | AudioSystem | Emitted when armor blocks significant damage |
| `durability_threshold_crossed` signal | RetreatJudge | Emitted when durability crosses critical thresholds |

## Tuning Knobs

### Primary Tuning Knobs (Affect Core Gameplay)

| Knob | Current Value | Safe Range | Gameplay Effect | Pillar Affected |
|------|---------------|------------|-----------------|-----------------|
| **COLLISION_ARMOR_EFFECTIVENESS** | 0.50 | 0.3-0.7 | Collision damage armor effectiveness. Higher → armor blocks more collision damage → collision less punishing | Pillar 1 |
| **MINIMUM_DAMAGE** | 1 | 1-5 | Damage floor after armor. Higher → even heavy armor takes chip damage → armor less impactful | Pillar 1, 3 |
| **FRAME_ACCUMULATION_BATCH_SIZE** | 500 | 100-1000 | Max damage per single durability call. Higher → faster processing but may miss visual feedback timing | Performance |
| **ARMOR_PIERCE_BOSS_FLAG** | true (for tier 5) | true/false | Boss attacks bypass armor. true → boss damage always full → boss encounters scarier | Pillar 3 |

---

### Secondary Tuning Knobs

| Knob | Current Value | Safe Range | Gameplay Effect |
|------|---------------|------------|-----------------|
| **COOLDOWN_TRACKING_ENABLED** | true | true/false | Enemy attack cooldown enforcement. false → enemies attack every contact → extreme pressure (testing/debug) |
| **UNKNOWN_SOURCE_DEFAULT** | 1 (enemy melee) | 1-5 | Default damage source type for unrecognized events. Higher → more armor reduction by default |
| **TIME_FAIL_OPEN** | true | true/false | Allow attack when time system fails. false → block attacks on time error → safer but may freeze combat |
| **DAMAGE_BATCH_VISUAL_DELAY** | 0.05 | 0.0-0.2 | Seconds between batch damage calls for visual feedback spread. Higher → damage appears gradual |

---

### Locked Constants (Not Tunable Here)

以下常量由其他系统或registry锁定，不可在本系统调谐：

| Constant | Value | Source | Reason |
|----------|-------|--------|--------|
| `MAX_ARMOR_REDUCTION` | 0.80 | entities.yaml | Global armor cap, affects all damage calculations |
| `VEHICLE_RETREAT_DURABILITY_THRESHOLD` | 0.30 | entities.yaml | Locked from game-concept.md |
| `VEHICLE_DEPLOY_DURABILITY_MIN` | 0.80 | entities.yaml | Locked from game-concept.md |
| `MINIMUM_DAMAGE` | 1 | entities.yaml (also tunable here) | Shared with VehicleWeapon, needs global sync |

---

### Knob Interactions

| Knob A | Knob B | Interaction Effect |
|--------|--------|-------------------|
| COLLISION_ARMOR_EFFECTIVENESS × armor value | Higher effectiveness × higher armor = more collision damage blocked | Two knobs multiply to determine collision damage reduction |
| MINIMUM_DAMAGE × MAX_ARMOR_REDUCTION | If min=5, armor=80% → max reduction still 20% of raw, but floor is 5 | High minimum damage undermines armor effectiveness at low raw_damage |
| FRAME_ACCUMULATION_BATCH_SIZE × damage rate | High batch size × high enemy count → fewer calls but larger damage chunks | Performance/visual feedback trade-off |

---

### Tuning Profile Recommendations

**Profile 1: 紧张节奏 (Recommended for MVP)**
- COLLISION_ARMOR_EFFECTIVENESS = 0.3 (collision damage mostly unmitigated)
- MINIMUM_DAMAGE = 3 (chip damage against heavy armor)
- ARMOR_PIERCE_BOSS_FLAG = true (boss bypass armor)
- Effect: High damage pressure, armor less protective, 搜打撤节奏更紧张

**Profile 2: 宽松节奏**
- COLLISION_ARMOR_EFFECTIVENESS = 0.7 (collision damage heavily mitigated)
- MINIMUM_DAMAGE = 1 (armor very effective)
- ARMOR_PIERCE_BOSS_FLAG = false (boss respects armor)
- Effect: Damage more forgiving, heavy armor builds viable, 节奏宽松

## Visual/Audio Requirements

[To be designed]

## UI Requirements

[To be designed]

## Acceptance Criteria

### Damage Processing Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-001** | GIVEN vehicle deployed (state=DEPLOYED), WHEN enemy attack signal received, THEN damage is processed and durability deducted | Simulate enemy attack event | `current_durability` decreased by `actual_damage` |
| **AC-002** | GIVEN raw_damage=50, armor=20, WHEN armor reduction formula applied, THEN actual_damage=40 | Formula unit test | Formula 1 output matches expected |
| **AC-003** | GIVEN raw_damage=50, armor=80, WHEN armor reduction formula applied, THEN actual_damage=10 (max reduction) | Formula unit test | damage_reduction clamped to 0.80 |
| **AC-004** | GIVEN raw_damage=5, armor=80, WHEN armor reduction formula applied, THEN actual_damage=1 (minimum floor) | Formula unit test | MINIMUM_DAMAGE floor applied |
| **AC-005** | GIVEN raw_damage=0, WHEN damage event processed, THEN no durability deduction, event skipped | Edge case test | `current_durability` unchanged |
| **AC-006** | GIVEN raw_damage=-5 (invalid), WHEN damage event received, THEN event rejected, log warning | Edge case test | No durability change, warning logged |

---

### Armor Reduction Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-007** | GIVEN armor=95 (exceeds cap), WHEN formula applied, THEN reduction clamped to MAX_ARMOR_REDUCTION=0.80 | Edge case test | damage_reduction = 0.80 (not 0.95) |
| **AC-008** | GIVEN armor=-10 (invalid), WHEN formula applied, THEN armor treated as 0, no reduction | Edge case test | damage_reduction = 0.0, warning logged |
| **AC-009** | GIVEN armor=0, WHEN damage processed, THEN actual_damage=raw_damage (full damage) | Formula test | No reduction applied |

---

### Collision Damage Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-010** | GIVEN collision_severity=10, armor=80, WHEN collision formula applied, THEN collision_damage=6 (40% reduction) | Formula unit test | Formula 2 output matches |
| **AC-011** | GIVEN collision_severity=3, armor=80, WHEN collision formula applied, THEN collision_damage=1 (minimum floor) | Formula test | MINIMUM_DAMAGE floor applied |
| **AC-012** | GIVEN collision_severity=0, WHEN collision event received, THEN event skipped, no deduction | Edge case test | No durability change |

---

### Attack Cooldown Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-013** | GIVEN enemy cooldown=1.0s, last_attack=1.0s, current_time=2.0s, WHEN cooldown check, THEN attack is valid (2.0-1.0 >= 1.0) | Cooldown test | is_attack_valid = true |
| **AC-014** | GIVEN enemy cooldown=1.0s, last_attack=1.0s, current_time=1.5s, WHEN cooldown check, THEN attack invalid (0.5 < 1.0) | Cooldown test | is_attack_valid = false |
| **AC-015** | GIVEN enemy never attacked (last_attack=0), WHEN first attack check, THEN attack valid | Initial attack test | is_attack_valid = true |
| **AC-016** | GIVEN time system returns invalid value, WHEN cooldown check, THEN fail-open: attack allowed (TIME_FAIL_OPEN=true) | Edge case test | is_attack_valid = true, warning logged |

---

### Multi-Contact Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-017** | GIVEN 3 enemies attack in one frame, damages=14, 25, 10, WHEN frame accumulation, THEN FAD=49 | Multi-attack test | Sum matches expected total |
| **AC-018** | GIVEN 10 enemies attack in one frame, WHEN frame accumulation, THEN single `apply_durability_damage` call with sum | Performance test | One call with FAD value |
| **AC-019** | GIVEN FAD=600 (exceeds batch size 500), WHEN damage applied, THEN damage applied in 2 batches (500 + 100) | Overflow test | Two calls to `apply_durability_damage` |

---

### Threshold Detection Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-020** | GIVEN durability=100, max=100, damage applied=100, WHEN durability reaches 0, THEN state transition to DISABLED | Threshold test | vehicle_state = DISABLED (3) |
| **AC-021** | GIVEN durability_ratio crosses from 35% to 0% in one frame, WHEN threshold check, THEN only `durability_depleted` emitted (not retreat warning) | Priority test | One signal emitted, highest priority |
| **AC-022** | GIVEN durability already 0, WHEN new damage arrives, THEN damage rejected, log warning | Disabled vehicle test | No durability change, warning logged |

---

### State Transition Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-023** | GIVEN vehicle transitioning to DISABLED, WHEN damage arrives during transition, THEN damage rejected (post-transition state) | Transition timing test | Damage blocked after transition |
| **AC-024** | GIVEN vehicle transitioning to GARAGE_IDLE, WHEN damage arrives during transition, THEN damage processed (still running) | Transition timing test | Durability deducted |

---

### Signal Emission Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-025** | GIVEN damage event processed, WHEN actual_damage computed, THEN `damage_received` signal emitted with (instance_id, source_type, raw, actual) | Signal test | Signal parameters match |
| **AC-026** | GIVEN armor blocks 36 damage (raw=50, actual=14), WHEN damage processed, THEN `armor_effective` signal emitted with damage_blocked=36 | Feedback test | Signal emitted with correct blocked value |
| **AC-027** | GIVEN durability reaches 0, WHEN threshold crossed, THEN `durability_threshold_crossed` signal emitted with threshold_type=2 (depleted) | Threshold signal test | Signal type matches |

---

### Boss/Special Damage Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-028** | GIVEN enemy tier=5 (Boss), ARMOR_PIERCE_BOSS_FLAG=true, WHEN damage processed, THEN actual_damage=raw_damage (no armor reduction) | Boss test | Armor bypassed |
| **AC-029** | GIVEN enemy tier=5, ARMOR_PIERCE_BOSS_FLAG=false, WHEN damage processed, THEN armor reduction applied normally | Alt config test | Formula applied |
| **AC-030** | GIVEN enemy special_ability has armor pierce flag, WHEN damage processed, THEN armor bypassed regardless of tier | Special ability test | Armor ignored |

---

### Performance Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-031** | GIVEN 50 simultaneous enemy contacts, WHEN frame processing, THEN frame time < 2ms | Performance test | Frame time measured |
| **AC-032** | GIVEN damage event stream, WHEN processing 100 events/second, THEN no frame drops below 60fps | Stress test | FPS maintained |
| **AC-033** | GIVEN cooldown tracking for 100 enemies, WHEN cleanup runs, THEN destroyed enemy records removed within 1 frame | Cleanup test | No orphan cooldown records |

---

### Pass/Fail Threshold

| Category | Pass Count | Fail Action |
|----------|------------|-------------|
| **Damage Processing (AC-001 to AC-006)** | 100% required | Core functionality broken |
| **Armor Reduction (AC-007 to AC-009)** | 100% required | Formula implementation error |
| **Collision Damage (AC-010 to AC-012)** | 100% required | Collision integration error |
| **Cooldown (AC-013 to AC-016)** | 100% required | Attack timing broken |
| **Multi-Contact (AC-017 to AC-019)** | 100% required | 尸潮 handling broken |
| **Threshold (AC-020 to AC-022)** | 100% required | State machine broken |
| **Signals (AC-025 to AC-027)** | 100% required | Event system broken |
| **Boss/Special (AC-028 to AC-030)** | 100% required | Boss encounters broken |
| **Performance (AC-031 to AC-033)** | Recommended | Optimization needed if fail |

**Total Criteria**: 33

## Visual/Audio Requirements

战车损坏系统是纯逻辑系统，不直接产生视觉/音频输出。但系统发射信号供视觉/音频系统订阅：

### Visual Feedback Signals

| Signal | Trigger Condition | Visual Effect | Consumer System |
|--------|-------------------|---------------|-----------------|
| `damage_received` | Damage processed | 车身震动动画，耐久条下降动画 | Animation/VFX系统 |
| `armor_effective` | Armor blocks ≥30 damage | 护甲闪光效果（金属光泽） | VFX系统 |
| `durability_threshold_crossed` (type=2) | Durability = 0 | 战车瘫痪特效（冒烟/倾斜），HUD耐久条变黑 | VFX/HUD系统 |

### Audio Feedback Signals

| Signal | Trigger Condition | Audio Event | Consumer System |
|--------|-------------------|-------------|-----------------|
| `damage_received` | Every damage | 金属撞击音效（强度随damage变化） | 音效系统 |
| `armor_effective` | Significant armor block | 护甲格挡音效（金属"叮"声） | 音效系统 |
| `durability_depleted` | Durability hits 0 | 战车瘫痪警报（长低频金属撞击） | 音效系统 |

### No Direct Asset Requirements

损坏系统不包含：
- Sprite或Texture资源
- AnimationPlayer
- AudioStreamPlayer
- ShaderMaterial

所有视觉/音频由下游系统（VFX、音效系统）负责。

## UI Requirements

战车损坏系统不直接渲染UI，但为HUD系统提供数据触发UI更新：

### HUD Damage Feedback

| UI Element | Trigger | Display Effect |
|------------|---------|----------------|
| **耐久条** | `damage_received` signal | 耐久条立即下降（动画平滑），颜色根据ratio变化 |
| **伤害数字** | `damage_received` signal | 伤害数字浮动显示（"-14"红色数字，1秒后消失） |
| **护甲格挡提示** | `armor_effective` signal | 护甲格挡数字浮动显示（"格挡36"蓝色数字） |
| **瘫痪警告** | `durability_depleted` signal | 全屏警告弹窗"战车瘫痪！步行逃回" |

### Damage Feedback Timing

- 耐久条下降：立即响应（无延迟）
- 伤害数字：0.3秒内显示，1秒后淡出
- 护甲格挡：同时显示，蓝色与红色伤害数字并列

### No UI Rendering by Damage System

损坏系统不包含：
- Control节点
- Label或Font资源
- StyleBox或Theme

所有UI由HUD系统 (#49) 负责。

## Open Questions

### High Priority (Implementation Blocking)

| ID | Question | Owner | Resolution Needed Before | Impact |
|----|----------|-------|-------------------------|--------|
| **Q-001** | 投射物碰撞层定义：`COLLISION_ENEMY_PROJECTILE`是否需要在block-collision-system中定义，还是在本系统新增？ | Technical Director | 实现开始前 | 影响碰撞检测架构 |
| **Q-002** | 冷却追踪存储：敌人攻击冷却记录存储在EnemyAI系统还是Damage系统？谁负责清理destroyed enemy记录？ | AI Programmer + Systems Designer | 实现开始前 | 影响数据所有权 |

### Medium Priority (Design Clarification)

| ID | Question | Owner | Resolution Needed Before | Impact |
|----|----------|-------|-------------------------|--------|
| **Q-003** | Boss护甲穿透规则：`ARMOR_PIERCE_BOSS_FLAG`是否对所有Boss生效，还是只有特定Boss类型？ | Game Designer | EnemyAI实现前 | 影响Boss威胁设计 |
| **Q-004** | 碰撞伤害与方块碰撞系统接口：collision_severity的计算公式是否在block-collision-system定义完整？ | Systems Designer | Collision实现前 | 影响碰撞伤害值 |

### Low Priority (Future Consideration)

| ID | Question | Owner | Resolution Needed Before | Impact |
|----|----------|-------|-------------------------|--------|
| **Q-005** | 多战车场景：如果Alpha阶段支持多战车，Damage系统如何区分不同战车的伤害事件？ | MultiVehicle Designer | Alpha阶段 | 影响instance_id路由 |
| **Q-006** | 环境伤害类型：是否需要扩展damage source type支持天气伤害（雷电）、地堡陷阱伤害等？ | Game Designer | Vertical Slice | 影响伤害来源枚举 |

### Assumptions Made

| Assumption | Rationale | Risk |
|------------|-----------|------|
| 冷却追踪由Damage系统管理 | 避免EnemyAI系统过重，Damage系统作为伤害中心管理冷却 | 如果EnemyAI重构，冷却追踪可能需迁移 |
| 投射物碰撞层由block-collision-system定义 | 保持碰撞层集中管理 | 如果未定义，需在本系统或Projectile系统新增 |
| Boss护甲穿透全局生效 | 简化设计，所有Boss具有威胁感 | 特殊Boss可能需要不同规则 |