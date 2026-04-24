# 战车武器系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 1 (战车即生命), Pillar 2 (搜打撤节奏), Pillar 4 (魔导科技美学)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #20 (from systems-index.md)

## Overview

战车武器系统是管理战车武器装备、射击行为、伤害输出的核心战斗系统。它定义武器类型属性（基础伤害、射击模式、魔能消耗、射程），管理战车实例的武器装备状态（equipped_weapons[]），处理玩家输入触发的射击流程（瞄准→判定→发射→伤害），并计算最终伤害输出（damage = base_damage × modifiers - armor）。该系统从战车属性系统获取魔能状态和载重信息，调用魔能消耗计算模块扣减射击成本，向敌人AI系统传递伤害事件，为HUD系统提供武器状态和弹药数据。

**数据层定位**：武器系统管理战车战斗能力的完整生命周期：
- 武器类型定义：damage, fire_rate, fire_mode, range, magic_cost, projectile_type
- 装备状态管理：equipped_weapons[] 验证（长度 ≤ weapon_mounts）
- 射击流程控制：输入监听 → 状态检查 → 魔能扣减 → 弹道生成 → 伤害判定
- 伤害计算公式：damage = weapon_base_damage × efficiency × crit_factor - enemy_armor

**玩家感知层**：玩家通过以下方式直接感知武器系统：
- 战车炮塔旋转瞄准（视觉瞄准反馈）
- 按下`fire`键时的发射动作（炮口闪光、弹道轨迹）
- 魔能表下降一格（射击魔能消耗的视觉反馈）
- 敌人血条下降或死亡动画（伤害效果确认）
- HUD武器状态显示（当前武器、冷却状态、弹药指示）

**系统必要性**：没有武器系统，游戏将无法：
- 实现战车自卫能力（Pillar 1 战车即生命 失去攻击维度）
- 创造魔能资源竞争（射击消耗 vs 驾驶续航，Pillar 2 搜打撤节奏 失去决策压力）
- 提供战斗反馈循环（击杀敌人的成就感，核心乐趣缺失）
- 支持战车改装动力（武器升级是改装系统的核心目标）

**服务于支柱**：
- **Pillar 1 (战车即生命)**：武器是战车的"爪牙"——装备武器让战车从纯运输工具变为魔导战斗载具，玩家感受到战车的"战斗力"
- **Pillar 2 (搜打撤节奏)**：射击消耗魔能，与驾驶续航形成资源竞争，创造"射击还是撤退？"的决策压力
- **Pillar 4 (魔导科技美学)**：武器类型命名体现魔导设定——魔导炮、符文弹、晶石弹，而非"机枪"、"火箭弹"

## Player Fantasy

玩家在战车武器系统中面对的核心体验是**魔导火力的节奏掌控**——每一次按下射击键，魔导炮喷出晶石弹，玩家感受到的是力量释放的快感与资源消耗的代价博弈。武器系统将战车从"运输工具"升华为"魔导战斗载具"。

### 情感锚定时刻

**首杀的火力觉醒**：玩家第一次驾驶装备魔导炮的战车出门，按下`fire`键的那一刻——炮口蓝光闪烁，晶石弹划破空气，变异狼应声倒地。这是战车"觉醒"的时刻："原来我不只是跑路的工具，我能战斗。"玩家感受到战车从"伙伴"升级为"守护者"——它不只带我回家，它还能为我扫清障碍。

**连射中的资源博弈**：尸潮逼近，玩家按下连射键，魔导炮连续喷发。魔能表一格格下降，每发都在消耗撤退的续航。玩家心跳加速："再打5发？还是省下魔能撤退？"这种"火力诱惑 vs 续航代价"的博弈，是搜打撤节奏的核心高潮——射击不只是爽，是代价抉择。

**精准击杀的猎人满足**：远处一只精英敌人正在逼近，玩家瞄准、预判轨迹、按下单发。晶石弹精准命中头部，敌人倒地。那一刻不是随机射击的爽快，而是"猎人精准打击"的成就感——战车的火力 + 玩家的瞄准技巧 = 击杀回报。

### 幻想服务于支柱

**Pillar 1 (战车即生命)**：武器系统赋予战车"战斗生命力"——不只是耐久和魔能的数字，是炮塔旋转、炮口闪光、击杀反馈的动态生命。玩家看着战车战斗，感受到的是"伙伴在战斗，它在保护我"，而非"我操作的武器系统"。

**Pillar 2 (搜打撤节奏)**：射击消耗魔能，与驾驶续航形成资源竞争。玩家面对"射击杀敌获得战利品"vs"保留魔能安全撤退"的抉择。这种代价博弈让战斗不再是无风险的爽快，而是"每一发都要算"的紧张决策。

**Pillar 4 (魔导科技美学)**：武器命名和视觉风格体现魔导设定——魔导炮发射晶石弹而非金属弹，符文炮塔释放魔法波动，弹道轨迹带有蓝光魔能特效。术语和视觉强化世界观沉浸。

### 语调示例

```
❌ "武器伤害30点，消耗10魔能"
✓ "魔导炮喷出一枚晶石弹——魔力脉冲穿过弹道，击中目标的瞬间释放30点伤害"

❌ "连续射击5秒，消耗50魔能"
✓ "连射模式下，魔导晶石的脉动变得急促——每发都在抽走撤退的能量"

❌ "击杀敌人获得战利品"
✓ "敌人倒在晶石弹的威力下——废土的馈赠在它的残骸中等待拾取"
```

### 没有武器系统，玩家失去什么

- **战车失去战斗维度** — 只有耐久和魔能，无法自卫，变成纯运输工具
- **搜打撤失去资源竞争** — 射击不消耗魔能，战斗无代价，决策失去压力
- **魔导科技失去火力表达** — 没有魔导炮、符文弹，世界观失去战斗维度支撑

## Detailed Design

### Core Rules

#### 1. Weapon Type Data Structure

每个武器类型定义为一个独立的数据记录。武器类型数据库（WeaponTypeDatabase）作为本系统的数据层，供魔能消耗系统、HUD系统、改装系统查询。

**Primary Weapon Type Fields:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `weapon_type_id` | int | 0-65535 | — | 唯一标识符，系统内部引用键 |
| `name` | string | — | — | 内部标识名（如"magic_cannon_basic", "rune_cannon") |
| `display_name` | string | — | — | UI显示名称（本地化键） |
| `category` | int | 0-3 | 0 | 武器分类枚举（见Weapon Category System） |
| `damage` | int | 5-100 | 20 | 基础伤害值（单发伤害） |
| `fire_rate` | float | 0.5-10.0 | 2.0 | 射击速率（发/秒） |
| `fire_mode` | int | 0-2 | 0 | 射击模式枚举（见Fire Mode System） |
| `range` | float | 5.0-50.0 | 15.0 | 最大射程（格） |
| `magic_cost_per_shot` | float | 1.0-50.0 | 10.0 | 每发魔能消耗（供#19使用） |
| `projectile_type` | int | 0-3 | 0 | 弹道类型枚举（见Projectile System） |
| `projectile_speed` | float | 10.0-50.0 | 20.0 | 弹道飞行速度（格/秒） |
| `accuracy` | float | 0.5-1.0 | 0.85 | 精准度（命中率修正） |
| `crit_chance` | float | 0.0-0.30 | 0.05 | 暴击概率 |
| `crit_multiplier` | float | 1.5-3.0 | 2.0 | 暴击倍率 |
| `slot_requirement` | int | 1-4 | 1 | 占用挂载点数量（大型武器占2槽） |

**Weapon Category Enumeration:**

| Value | Name | Description | Typical Stats |
|-------|------|-------------|---------------|
| 0 | `CANNON` | 魔导炮类（直射弹道） | 高伤害，中等射程，中等魔能消耗 |
| 1 | `BEAM` | 符文光束类（瞬间命中） | 低伤害，高射速，低魔能消耗 |
| 2 | `LAUNCHER` | 晶石发射器类（抛射弹道） | 高伤害，长射程，高魔能消耗 |
| 3 | `SPECIAL` | 特殊武器（Alpha功能） | 独特机制，待定义 |

**Fire Mode Enumeration:**

| Value | Name | Description | Input Behavior |
|-------|------|-------------|----------------|
| 0 | `SINGLE` | 单发射击 | 每次按键发射1发 |
| 1 | `BURST` | 连发射击 | 按住连续发射，预设burst_count上限 |
| 2 | `AUTO` | 自动射击 | 按住无限制连射，直至魔能耗尽 |

**Projectile Type Enumeration:**

| Value | Name | Description | Visual Behavior |
|-------|------|-------------|-----------------|
| 0 | `DIRECT` | 直射弹道（直线飞行） | 瞬间出发，直线轨迹 |
| 1 | `ARCING` | 抛射弹道（抛物线） | 发射器类武器，有落点预判 |
| 2 | `BEAM` | 光束弹道（瞬间命中） | 无飞行时间，瞬发命中 |
| 3 | `HOMING` | 追踪弹道（Alpha功能） | 自动追踪目标 |

---

#### 2. Weapon Equipment Rules

武器装备由战车属性系统管理，武器系统提供装备验证逻辑。

**Equipment Rules:**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| WEQ-001 | 武器数量上限 | `equipped_weapons.length ≤ vehicle_type.weapon_mounts` — 挂载点数量约束 |
| WEQ-002 | 槽位占用验证 | `sum(slot_requirement) ≤ weapon_mounts` — 大型武器占2槽，需验证总占用 |
| WEQ-003 | 装备状态检查 | 只有`GARAGE_IDLE`或`DEPLOYABLE`状态可装备武器（车库内操作） |
| WEQ-004 | 武器类型有效 | `weapon_type_id`必须在WeaponTypeDatabase中存在 |
| WEQ-005 | 装备替换规则 | 新武器装备时，如果槽位不足，提示玩家选择替换或取消 |

**Equipment Interface:**

```gdscript
# VehicleWeaponSystem.gd
static func can_equip_weapon(
    vehicle_instance: VehicleInstance,
    weapon_type_id: int
) -> bool:
    var weapon_def := WeaponTypes.get_definition(weapon_type_id)
    if weapon_def == null:
        return false  # WEQ-004
    
    var current_slots_used := sum_slot_requirements(vehicle_instance.equipped_weapons)
    var new_slots_needed := weapon_def.slot_requirement
    var max_slots := VehicleTypes.get_weapon_mounts(vehicle_instance.vehicle_type_id)
    
    return current_slots_used + new_slots_needed <= max_slots  # WEQ-002

func equip_weapon(vehicle_instance_id: int, weapon_type_id: int) -> bool:
    if not can_equip_weapon(...):
        return false
    VehicleAttribute.add_equipped_weapon(vehicle_instance_id, weapon_type_id)
    emit_signal("weapon_equipped", vehicle_instance_id, weapon_type_id)
    return true
```

---

#### 3. Firing Process Rules

射击流程从玩家输入触发，经过状态检查、魔能扣减、弹道生成、伤害判定。

**Firing Process Sequence:**

| Step | Action | Guard Condition | Output |
|------|--------|-----------------|--------|
| 1 | 输入监听 | `Input.is_action_pressed("fire")` | 触发射击尝试 |
| 2 | 状态检查 | `vehicle_state == DEPLOYED` AND `movement_state != BLOCKED` | 允许射击 |
| 3 | 武器选择 | `current_weapon_index` within `equipped_weapons.length` | 确定武器类型 |
| 4 | 魔能检查 | `current_magic_energy >= magic_cost_per_shot` | 允许扣减 |
| 5 | 冷却检查 | `cooldown_remaining <= 0` | 允许发射 |
| 6 | 魔能扣减 | 调用 `MagicConsumption.calculate_shot_magic_cost()` | 执行消耗 |
| 7 | 弹道生成 | 创建Projectile节点，设置trajectory | 发射弹道 |
| 8 | 伤害判定 | 弹道命中敌人 → 计算damage → 发送伤害事件 | 敌人受伤 |

**Firing Rules:**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| FIRE-001 | 魔能不足禁止射击 | `current_magic_energy < magic_cost_per_shot` → 射击失败，无弹道生成 |
| FIRE-002 | 冷却期间禁止射击 | `cooldown_remaining > 0` → 射击失败，等待冷却完成 |
| FIRE-003 | 瘫痪状态禁止射击 | `vehicle_state == DISABLED` → 射击失败（战车无法操作） |
| FIRE-004 | 武器切换冷却 | 切换武器后，进入`weapon_switch_cooldown` (default 0.5秒) |
| FIRE-005 | 连射魔能预扣 | `fire_mode == BURST or AUTO` → 预扣burst全消耗（#19 WPN-COST-007） |
| FIRE-006 | 射程限制判定 | 弹道飞行距离超过`range` → 弹道消失，不造成伤害 |
| FIRE-007 | 精准度判定 | `random(0, 1) <= accuracy` → 弹道命中；否则弹道偏移 |

---

#### 4. Damage Calculation Rules

伤害计算公式决定最终输出伤害。

**Damage Formula Components:**

| Component | Source | Calculation | Range |
|-----------|--------|-------------|-------|
| `base_damage` | WeaponTypeDatabase | — | 5-100 |
| `efficiency_modifier` | Modification bonus | `1.0 + mod_bonus` | 0.8-1.5 |
| `crit_factor` | Crit roll | `crit_chance` roll → `crit_multiplier` | 1.0 or 2.0 |
| `armor_reduction` | Enemy armor | `enemy.armor` % reduction | 0-80% |
| `range_falloff` | Range penalty | distance > range_threshold → damage × falloff_factor | 0.5-1.0 |

**Damage Calculation Formula:**

```
final_damage = base_damage × efficiency_modifier × crit_factor × (1 - armor_reduction) × range_falloff
```

**Damage Rules:**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| DMG-001 | 伤害最小值 | `final_damage >= 1` — 即使护甲80%，至少造成1点伤害 |
| DMG-002 | 暴击判定 | `random(0, 1) < crit_chance` → crit_factor = crit_multiplier |
| DMG-003 | 无暴击判定 | 否则 → crit_factor = 1.0 |
| DMG-004 | 护甲减伤上限 | `armor_reduction <= 0.80` — 最多减伤80%，不可完全免疫 |
| DMG-005 | 射程衰减触发 | `distance > range × 0.8` → 应用range_falloff |
| DMG-006 | 射程衰减公式 | `falloff_factor = 1.0 - (distance - threshold) / (range - threshold) × 0.5` |

---

#### 5. Projectile System Rules

弹道生成和管理由Projectile节点处理。

**Projectile Properties:**

| Property | Type | Source | Description |
|----------|------|--------|-------------|
| `origin_position` | Vector2 | Vehicle position | 发射起点 |
| `target_direction` | Vector2 | Aim direction (from input or auto-aim) | 弹道方向 |
| `speed` | float | WeaponTypeDatabase.projectile_speed | 飞行速度（格/秒） |
| `damage_payload` | Dictionary | {base, efficiency, crit_chance, crit_mult} | 伤害参数 |
| `range_remaining` | float | WeaponTypeDatabase.range | 剩余射程 |
| `collision_layer` | int | COLLISION_PLAYER_PROJECTILE (待定义) | 碰撞层 |

**Projectile Behavior:**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| PROJ-001 | 弹道飞行 | 每帧移动 `position += direction × speed × delta` |
| PROJ-002 | 射程耗尽消失 | `range_remaining <= 0` → 弹道节点销毁 |
| PROJ-003 | 碰撞检测 | 弹道Area2D检测碰撞层COLLISION_ENEMY_BODY (value=8) |
| PROJ-004 | 碰撞处理 | 碰撞敌人 → 调用damage calculation → 发送伤害事件 → 弹道销毁 |
| PROJ-005 | 弹道穿透（Alpha） | 特定武器类型允许穿透多个敌人（待定义） |

---

#### 6. Aim System Rules

瞄准系统处理玩家输入和目标选择。

**Aim Input Sources:**

| Input Mode | Source | Aim Direction | Notes |
|------------|--------|---------------|-------|
| Keyboard | `aim_up/down/left/right` InputMap | 方向键方向 | 8方向离散瞄准 |
| Mouse | Mouse position relative to vehicle | 精确方向 | 自由瞄准（PC） |
| Gamepad | Right stick axis | 精确方向 | 自由瞄准（控制器） |

**Aim Rules:**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| AIM-001 | 瞄准方向归一化 | `aim_direction = aim_input.normalized()` — 防止零向量 |
| AIM-002 | 瞄准视觉反馈 | 炮塔节点旋转至aim_direction角度（lerp平滑） |
| AIM-003 | 自动瞄准辅助（可选） | `nearest_enemy_distance <= auto_aim_range` → 自动锁定最近敌人 |
| AIM-004 | 瞄准死区 | `aim_input.magnitude < 0.15` → 不更新瞄准方向（防止漂移） |

---

#### 7. Weapon Switching Rules

武器切换处理多武器装备场景。

**Switch Rules:**

| Rule ID | Rule Description | Implementation |
|---------|-----------------|----------------|
| SWT-001 | 武器切换触发 | `switch_weapon` InputMap action 或 数字键1-4 |
| SWT-002 | 切换索引验证 | `new_index` within `equipped_weapons.length` |
| SWT-003 | 切换冷却 | 切换后进入`switch_cooldown` (0.5秒)，期间禁止射击 |
| SWT-004 | 当前武器索引 | `current_weapon_index` 存储在VehicleInstance |

---

### States and Transitions

武器系统无独立状态机，依赖VehicleAttribute的vehicle_state。射击冷却和武器切换冷却作为临时计时器状态。

**Cooldown States:**

| State | Trigger | Duration | Constraint |
|-------|---------|----------|------------|
| `fire_cooldown` | 发射完成 | `1.0 / fire_rate` 秒 | cooldown_remaining > 0 → 禁止射击 |
| `burst_cooldown` | 连射burst结束 | burst结束后冷却 | 连射间隔 |
| `switch_cooldown` | 武器切换完成 | 0.5秒 | 切换后禁止射击 |

---

### Interactions with Other Systems

#### Upstream Systems (This System Depends On)

| System | Interface | Data Consumed | Timing |
|--------|-----------|---------------|--------|
| **战车属性系统 (#17)** | `get_equipped_weapons(instance_id)` | equipped_weapons[] | 每次射击/装备 |
| **战车属性系统 (#17)** | `get_vehicle_state(instance_id)` | vehicle_state | 射击前状态检查 |
| **战车属性系统 (#17)** | `get_current_magic_energy(instance_id)` | current_magic_energy | 魔能检查 |
| **战车属性系统 (#17)** | `get_vehicle_position(instance_id)` | position_cell | 弹道起点 |
| **战车属性系统 (#17)** | `get_load_ratio(instance_id)` | load_ratio | 魔能消耗修正 |
| **魔能消耗计算 (#19)** | `calculate_shot_magic_cost(weapon_id, load_ratio)` | shot_cost | 魔能扣减计算 |
| **魔能消耗计算 (#19)** | `calculate_continuous_fire_cost(...)` | burst_cost | 连射预扣 |
| **输入控制系统 (#9)** | `Input.is_action_pressed("fire")` | fire input | 每帧检测 |
| **输入控制系统 (#9)** | `Input.get_vector("aim_...")` | aim direction | 瞄准方向 |
| **TileMap世界系统 (#1)** | `CELL_SIZE` | 32 pixels | 弹道坐标转换 |
| **战车类型数据库 (#6)** | `get_weapon_mounts(vehicle_type_id)` | weapon_mounts | 装备上限 |

#### Downstream Systems (Systems That Depend On This)

| System | Interface | Data Provided | Timing |
|--------|-----------|---------------|--------|
| **敌人AI系统 (#36)** | `take_damage(enemy_id, damage, source)` | Damage event | 弹道命中时 |
| **战车属性系统 (#17)** | `apply_magic_energy_cost(instance_id, cost)` | Magic deduction | 魔能扣减 |
| **HUD系统 (#49)** | `get_current_weapon(instance_id)` | current_weapon_index | HUD显示 |
| **HUD系统 (#49)** | `get_weapon_status(instance_id)` | {name, cooldown, ammo_indicator} | 武器状态 |
| **音效系统 (#52)** | Signal `weapon_fired` | weapon_type_id, position | 音效触发 |
| **音效系统 (#52)** | Signal `weapon_hit` | weapon_type_id, damage | 命中音效 |

#### Signal Architecture

| Signal | Parameters | Trigger | Consumers |
|--------|------------|---------|-----------|
| `weapon_equipped` | `instance_id, weapon_type_id` | 武器装备成功 | HUD (#49), Audio (#52) |
| `weapon_fired` | `instance_id, weapon_type_id, position` | 弹道生成 | Audio (#52), VFX |
| `weapon_hit` | `instance_id, weapon_type_id, enemy_id, damage` | 弹道命中敌人 | Audio (#52), EnemyAI (#36) |
| `weapon_switched` | `instance_id, old_index, new_index` | 武器切换 | HUD (#49) |
| `magic_insufficient_for_fire` | `instance_id, required_cost` | 魔能不足射击失败 | HUD (#49) Warning |

## Formulas

### Formula 1: Damage Calculation

The damage calculation formula determines final damage output per hit.

```
final_damage = base_damage × efficiency_modifier × crit_factor × (1 - armor_reduction) × range_falloff
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `final_damage` | D | int | 1–150 | Output damage (minimum 1 per DMG-001) |
| `base_damage` | Bd | int | 5–100 | Weapon base damage from WeaponTypeDatabase |
| `efficiency_modifier` | Em | float | 0.8–1.5 | Modification bonus (default 1.0) |
| `crit_factor` | Cf | float | 1.0 or 2.0 | Critical hit multiplier (from crit roll) |
| `armor_reduction` | Ar | float | 0.0–0.80 | Enemy armor % reduction (max 80%) |
| `range_falloff` | Rf | float | 0.5–1.0 | Range penalty factor |

**Output Range:** 1 to 150 (after minimum damage rule DMG-001)
**Example:** Bd=20, Em=1.0, Cf=1.0, Ar=0.30, Rf=1.0 → D = 20 × 1.0 × 1.0 × 0.70 × 1.0 = 14 damage

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| Bd=20, Em=1.0, Cf=1.0, Ar=0.0, Rf=1.0 | D=20 | Zero armor, full range |
| Bd=20, Em=1.0, Cf=1.0, Ar=0.80, Rf=1.0 | D=4 | Max armor, minimum damage rule applies? 20×0.20=4 ≥1, ok |
| Bd=5, Em=1.0, Cf=1.0, Ar=0.80, Rf=1.0 | D=1 | Minimum damage rule DMG-001: 5×0.20=1 → clamped to 1 |
| Bd=20, Em=1.5, Cf=2.0, Ar=0.0, Rf=1.0 | D=60 | Maximum modifiers, no armor |
| Bd=20, Em=1.0, Cf=1.0, Ar=0.30, Rf=0.5 | D=7 | Range falloff at 50% |

---

### Formula 2: Crit Factor Determination

The crit factor determination uses probability roll to decide critical hit.

```
crit_factor = crit_multiplier IF random(0,1) < crit_chance ELSE 1.0
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `crit_factor` | Cf | float | 1.0 or 2.0+ | Output multiplier |
| `crit_chance` | Cc | float | 0.0–0.30 | Weapon crit probability |
| `crit_multiplier` | Cm | float | 1.5–3.0 | Weapon crit multiplier |
| `random_value` | Rv | float | 0.0–1.0 | Random number generation |

**Output Range:** Either 1.0 (normal hit) or Cm (critical hit)
**Example:** Cc=0.05, Cm=2.0, Rv=0.03 → Cf = 2.0 (crit triggered)

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| Cc=0.0, Rv=any | Cf=1.0 | Zero crit chance → always normal |
| Cc=0.30, Rv=0.25 | Cf=Cm | High crit chance, roll succeeds |
| Cc=0.05, Rv=0.10 | Cf=1.0 | Low crit chance, roll fails |

---

### Formula 3: Range Falloff Calculation

The range falloff formula reduces damage at extended range.

```
falloff_factor = 1.0 IF distance ≤ threshold ELSE 1.0 - (distance - threshold)/(range - threshold) × 0.5
threshold = range × 0.8
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `falloff_factor` | Rf | float | 0.5–1.0 | Damage reduction factor |
| `distance` | d | float | 0.0–∞ | Actual projectile travel distance (cells) |
| `range` | R | float | 5.0–50.0 | Weapon max range (cells) |
| `threshold` | T | float | R×0.8 | Falloff trigger distance |

**Output Range:** 0.5 to 1.0 (minimum 50% damage at max range)
**Example:** R=15, d=16, T=12 → Rf = 1.0 - (16-12)/(15-12) × 0.5 = 1.0 - 1.33×0.5 = 0.33 → clamped to 0.5

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| R=15, d=10, T=12 | Rf=1.0 | Within threshold, no falloff |
| R=15, d=12, T=12 | Rf=1.0 | At threshold, no falloff |
| R=15, d=15, T=12 | Rf=0.5 | At max range, minimum falloff |
| R=15, d=20, T=12 | Rf=0.5 | Beyond range, clamped to minimum |

---

### Formula 4: Fire Cooldown Duration

The fire cooldown duration determines wait time between shots.

```
cooldown_duration = 1.0 / fire_rate
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `cooldown_duration` | Cd | float | 0.1–2.0 | Seconds between shots |
| `fire_rate` | Fr | float | 0.5–10.0 | Shots per second |

**Output Range:** 0.1 seconds (high fire rate) to 2.0 seconds (low fire rate)
**Example:** Fr=2.0 → Cd = 0.5 seconds

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| Fr=0.5 | Cd=2.0 | Slow weapon, long cooldown |
| Fr=10.0 | Cd=0.1 | Fast weapon, minimal cooldown |
| Fr=1.0 | Cd=1.0 | Standard cooldown |

---

### Formula 5: Projectile Travel Time

The projectile travel time estimates flight duration to target.

```
travel_time = distance / projectile_speed
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `travel_time` | Tt | float | 0.0–∞ | Flight duration (seconds) |
| `distance` | d | float | 0.0–range | Travel distance (cells) |
| `projectile_speed` | Ps | float | 10.0–50.0 | Projectile velocity (cells/sec) |

**Output Range:** 0.0 to range/10 (max travel time at slowest speed)
**Example:** d=15, Ps=20 → Tt = 0.75 seconds

**Boundary Tests:**

| Input | Expected Output | Notes |
|-------|-----------------|-------|
| d=0, Ps=20 | Tt=0 | Zero distance, instant |
| d=15, Ps=50 | Tt=0.3 | Fast projectile |
| d=50, Ps=10 | Tt=5.0 | Slow projectile at max range |

---

### Formula 6: Magic Cost per Shot (Delegated to #19)

This formula is defined by 魔能消耗计算 (#19). This system calls the interface.

```
shot_cost = MagicConsumption.calculate_shot_magic_cost(weapon_type_id, load_ratio, efficiency_modifier)
```

**Interface Contract:**

| Parameter | Type | Source | Notes |
|-----------|------|--------|-------|
| `weapon_type_id` | int | Current weapon | Passed to WeaponTypes.get_magic_cost() |
| `load_ratio` | float | VehicleAttribute | Current vehicle load ratio |
| `efficiency_modifier` | float | Weapon mod | Modification bonus (default 1.0) |

**Output:** Magic cost per shot (float, 0.0–∞)

---

### Formula 7: Continuous Fire Cost (Delegated to #19)

This formula is defined by 魔能消耗计算 (#19). This system calls the interface.

```
burst_cost = MagicConsumption.calculate_continuous_fire_cost(weapon_type_id, fire_rate, fire_duration, load_ratio)
```

**Interface Contract:**

| Parameter | Type | Source | Notes |
|-----------|------|--------|-------|
| `weapon_type_id` | int | Current weapon | Passed to calculate_shot_magic_cost |
| `fire_rate` | float | WeaponTypeDatabase | Shots per second |
| `fire_duration` | float | Input hold duration | Seconds of continuous fire |
| `load_ratio` | float | VehicleAttribute | Current vehicle load ratio |

**Output:** Total magic cost for burst (float, 0.0–∞)

## Edge Cases

| ID | Edge Case | Expected Behavior | Rationale |
|----|-----------|-------------------|-----------|
| **EC-001** | Zero magic energy (`current_magic_energy = 0`) | Shooting fails → `magic_insufficient_for_fire` signal emitted → HUD warning | FIRE-001 enforcement; player cannot shoot without magic |
| **EC-002** | Magic energy < shot_cost but > 0 | Shooting fails → signal emitted → partial magic not consumed | Prevents partial consumption that could leave player stranded |
| **EC-003** | Fire cooldown active (`cooldown_remaining > 0`) | Shooting fails silently → wait for cooldown to expire | FIRE-002 enforcement; prevents rapid-fire exploits |
| **EC-004** | Weapon switch cooldown active | Shooting fails → wait for switch_cooldown (0.5s) | FIRE-004 enforcement; prevents instant weapon swap-shooting |
| **EC-005** | Vehicle in DISABLED state | Shooting fails completely → no magic check, no projectile | FIRE-003 enforcement; paralyzed vehicle cannot act |
| **EC-006** | No weapons equipped (`equipped_weapons.length = 0`) | Shooting fails → no current weapon to fire | Empty weapon array scenario |
| **EC-007** | Invalid current_weapon_index | Clamp to valid range `0 ≤ index < equipped_weapons.length` | Array index protection |
| **EC-008** | Weapon mount slots = 0 (`weapon_mounts = 0`) | No weapons can be equipped → always EC-006 scenario | Vehicle type has no combat capability |
| **EC-009** | Weapon_type_id not in database | Equipment fails → return false, log warning "Unknown weapon" | WEQ-004 enforcement; invalid ID protection |
| **EC-010** | Slot requirement exceeds mounts | Equipment fails → "Weapon too large for this vehicle" message | WEQ-002 enforcement; large weapon constraint |
| **EC-011** | Projectile range exhausted before hitting enemy | Projectile node destroyed → no damage dealt | PROJ-002 enforcement; range limit |
| **EC-012** | Projectile collision with terrain (not enemy) | Projectile destroyed → no damage, no signal | Terrain collision consumes projectile |
| **EC-013** | Projectile collision with friendly entity | Projectile destroyed → no damage to friendlies | Prevents self-damage (friendly fire off for MVP) |
| **EC-014** | Enemy dies before projectile arrives | Projectile continues flight → may hit other enemies or terrain | Enemy death doesn't cancel projectile |
| **EC-015** | Multiple enemies in projectile path | First collision triggers damage → projectile destroyed (no penetration for MVP) | PROJ-005 defines penetration as Alpha feature |
| **EC-016** | Zero aim input magnitude | Aim direction unchanged from previous frame | AIM-001 deadzone protection |
| **EC-017** | Aim input below deadzone (`magnitude < 0.15`) | Aim direction unchanged → prevents micro-drift | AIM-004 enforcement |
| **EC-018** | Damage calculation produces 0 before minimum rule | `final_damage = 1` (minimum damage enforced) | DMG-001 enforcement; never deal zero |
| **EC-019** | Armor reduction > 0.80 (data error) | Clamp armor_reduction to 0.80 max | DMG-004 enforcement; no invincible enemies |
| **EC-020** | Range falloff calculation produces < 0.5 | Clamp falloff_factor to 0.5 minimum | Prevents below-minimum damage at extended range |
| **EC-021** | Crit chance > 0.30 (data error) | Clamp crit_chance to 0.30 max | Prevents excessive crit frequency |
| **EC-022** | Fire rate = 0 (data error) | Default to fire_rate = 1.0, log warning | Prevents infinite cooldown (division by zero) |
| **EC-023** | Projectile speed = 0 (data error) | Default to projectile_speed = 20.0, log warning | Prevents stationary projectile |
| **EC-024** | Range = 0 (data error) | Default to range = 5.0 minimum, log warning | Prevents zero-range weapon |
| **EC-025** | Vehicle destroyed mid-firing sequence | Projectile already generated continues → damage may still apply | Projectile is independent once fired |
| **EC-026** | Burst fire interrupted by magic depletion | Pre-deducted burst cost remains consumed → partial burst fired | FIRE-005 pre-deduction model; no refund |
| **EC-027** | Negative base_damage (data corruption) | Clamp to 1 minimum, log error "Invalid damage" | Data protection; minimum damage rule |
| **EC-028** | Negative fire_rate (data corruption) | Clamp to 0.5 minimum, log error | Data protection |
| **EC-029** | Attempting to switch to same weapon index | Switch succeeds → switch_cooldown still applies | Even same-index switch triggers cooldown |

## Dependencies

### Upstream Dependencies (This System Depends On)

| System ID | System Name | Interface Used | Status | Notes |
|-----------|-------------|----------------|--------|-------|
| **#17** | 战车属性系统 | `get_equipped_weapons()`, `get_vehicle_state()`, `get_current_magic_energy()`, `get_vehicle_position()`, `get_load_ratio()` | Designed | Core state queries for firing/equipment |
| **#19** | 魔能消耗计算 | `calculate_shot_magic_cost()`, `calculate_continuous_fire_cost()` | Designed | Magic cost calculation delegate |
| **#9** | 输入控制系统 | `Input.is_action_pressed("fire")`, `Input.get_vector("aim_...")` | Designed | Fire and aim input triggers |
| **#1** | TileMap世界系统 | `CELL_SIZE` constant | Designed | Projectile coordinate conversion |
| **#6** | 战车类型数据库 | `get_weapon_mounts()` | Designed | Equipment slot limit query |
| **WeaponTypes** | 武器类型数据库 | `get_definition(weapon_type_id)` | **Provisional** | Defined in this GDD Section C.1 — needs separate GDD or inline implementation |

**Provisional dependency alert**: WeaponTypeDatabase interface is defined in this GDD (#20) but not yet registered as a separate system. MagicConsumption (#19) expects `WeaponTypes.get_magic_cost(weapon_type_id)` interface. Resolution: Either (1) create separate WeaponTypeDatabase GDD, or (2) inline weapon definitions in this GDD.

---

### Downstream Dependencies (Systems That Depend On This)

| System ID | System Name | Interface Called | Status | Notes |
|-----------|-------------|------------------|--------|-------|
| **#36** | 敌人AI系统 | `take_damage(enemy_id, damage, source)` via signal | Not Started | Enemy damage reception |
| **#49** | HUD系统 | `get_current_weapon()`, `get_weapon_status()` | Not Started | Weapon HUD display |
| **#52** | 音效系统 | Signal `weapon_fired`, `weapon_hit` | Not Started | Weapon audio triggers |
| **#21** | 战车损坏系统 | (Indirect) weapon damage to vehicle | Not Started | Potential self-damage scenarios |

**Bidirectional confirmation**:
- #17 (VehicleAttribute) GDD Section F lists weapon equipment management ✓
- #19 (MagicConsumption) GDD Section F lists #20 as downstream ✓
- #36, #49, #52 GDDs not yet written → will need to add this dependency when authored

---

### Dependency Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| WeaponTypeDatabase interface provisional | **HIGH** | Define inline in this GDD or create separate GDD before #19 implementation |
| #36 (EnemyAI) undesigned | **MEDIUM** | Damage interface assumed (`take_damage()`); validate when EnemyAI designed |
| #49 (HUD) undesigned | **LOW** | Weapon status interface can be adjusted |
| Collision layer for player projectiles undefined | **MEDIUM** | Need to register COLLISION_PLAYER_PROJECTILE in entities.yaml (new constant) |

## Tuning Knobs

### Global Tuning Knobs

| Knob ID | Knob Name | Value | Range | Affects | Owner | Notes |
|---------|-----------|-------|-------|---------|-------|-------|
| **TK-001** | `WEAPON_SWITCH_COOLDOWN` | 0.5 | 0.3–1.0 | Weapon swap delay | #20 | Higher = slower tactical switching; affects combat flow |
| **TK-002** | `MINIMUM_DAMAGE` | 1 | 1–5 | Damage floor | #20 | Higher = more forgiving for low-damage weapons against armored enemies |
| **TK-003** | `MAX_ARMOR_REDUCTION` | 0.80 | 0.50–0.90 | Enemy armor cap | #20 | Higher = enemies more tanky; 0.90 = 90% reduction possible |
| **TK-004** | `RANGE_FALLOFF_THRESHOLD_RATIO` | 0.80 | 0.60–0.95 | Falloff trigger point | #20 | Higher = longer effective range; lower = earlier falloff |
| **TK-005** | `MIN_RANGE_FALLOFF` | 0.50 | 0.30–0.70 | Minimum damage at max range | #20 | Higher = weapons more effective at range; lower = steep penalty |
| **TK-006** | `AIM_DEADZONE` | 0.15 | 0.05–0.25 | Aim input threshold | #20 | Shared with InputControl (#9); higher = forgiving drift |
| **TK-007** | `AUTO_AIM_RANGE` | 0.0 | 0.0–10.0 | Auto-aim activation distance | #20 | 0 = disabled (MVP); higher = more aim assist for casual players |

---

### Weapon-Type Tunable Fields (Per-Weapon, Not Global)

| Field | Range | Affects | Tuning Consideration |
|-------|-------|---------|----------------------|
| `damage` | 5–100 | DPS baseline | Higher = stronger weapon but higher magic cost pressure |
| `fire_rate` | 0.5–10.0 | DPS + cooldown | Higher = faster shots but faster magic drain |
| `range` | 5.0–50.0 | Effective distance | Longer = safer engagement; shorter = riskier close combat |
| `magic_cost_per_shot` | 1.0–50.0 | Resource competition | Higher = steeper 搜打撤 pressure (Pillar 2) |
| `accuracy` | 0.5–1.0 | Hit reliability | Higher = reliable; lower = skill-dependent |
| `crit_chance` | 0.0–0.30 | Burst damage potential | Higher = more variance; 0.05 = reliable baseline |
| `crit_multiplier` | 1.5–3.0 | Crit payoff | Higher = bigger crit payoff; 2.0 = standard |
| `projectile_speed` | 10.0–50.0 | Hit timing | Higher = easier to hit moving targets |

---

### Tuning Scenarios

| Scenario | Knobs to Adjust | Expected Effect |
|----------|-----------------|-----------------|
| **Combat feels too easy** | Increase `MAX_ARMOR_REDUCTION` to 0.90 | Enemies tankier; requires more shots per kill |
| **Weapons feel weak at range** | Increase `MIN_RANGE_FALLOFF` to 0.70 | Range penalty reduced; longer effective engagement |
| **Weapon switching too slow** | Reduce `WEAPON_SWITCH_COOLDOWN` to 0.3 | Faster tactical swaps; enables combo weapon use |
| **Shooting drains magic too fast** | Reduce `magic_cost_per_shot` across weapon types | Less resource competition; longer exploration possible |
| **Aim feels jittery** | Increase `AIM_DEADZONE` to 0.20 | More forgiving; less micro-drift on controllers |
| **Accuracy variance frustrating** | Increase `accuracy` across weapon types to 0.90 | More reliable hits; skill ceiling lowered |

---

### Constants from Other Systems (Referenced, Not Owned)

| Constant | Value | Source | Usage in #20 |
|----------|-------|--------|--------------|
| `CELL_SIZE` | 32 | TileMap (#1) | Projectile coordinate conversion |
| `MAX_LOAD_PENALTY_SHOOTING` | 0.15 | MagicConsumption (#19) | Referenced via #19 interface |
| `DEADZONE_AXIS_INNER` | 0.15 | InputControl (#9) | Shared aim deadzone concept |

## Visual/Audio Requirements

| Requirement ID | Type | Trigger | Effect | Notes |
|----------------|------|---------|--------|-------|
| **VA-001** | Visual | Weapon fired | Muzzle flash at cannon position (0.3s duration) | Blue glow for magitech aesthetic (Pillar 4) |
| **VA-002** | Visual | Projectile travel | Projectile trail (glowing blue line) | Indicates trajectory and range |
| **VA-003** | Visual | Projectile hit enemy | Impact burst (enemy position, 0.2s) | Damage confirmation feedback |
| **VA-004** | Visual | Critical hit | Enhanced impact (larger burst, yellow color) | Distinguishes crit from normal hit |
| **VA-005** | Visual | Weapon switch | Weapon icon swap animation (HUD) | Instant feedback for selection |
| **VA-006** | Visual | Magic insufficient for fire | Magic bar flash red + warning icon | Urgency signal (Pillar 2 tension) |
| **VA-007** | Visual | Weapon cooldown active | Cooldown meter (radial or bar) | Shows wait time visually |
| **VA-008** | Audio | Weapon fired | "Magitech cannon fire" sound | Distinct per weapon category (cannon/beam/launcher) |
| **VA-009** | Audio | Projectile hit | "Impact hit" sound | Confirms damage to enemy |
| **VA-010** | Audio | Critical hit | "Critical impact" sound (louder/different) | Reward feedback for crit |
| **VA-011** | Audio | Magic insufficient | "Magic depleted warning" sound | Urgency alert |
| **VA-012** | Audio | Weapon switch | "Weapon select click" sound | Menu-style UI feedback |

## UI Requirements

| Requirement ID | UI Element | Data Source | Update Frequency | Notes |
|----------------|------------|-------------|------------------|-------|
| **UI-001** | Current weapon name | `get_current_weapon()` | On weapon switch | Display weapon display_name |
| **UI-002** | Weapon cooldown indicator | `get_weapon_status().cooldown` | Every frame | Radial meter or bar showing wait time |
| **UI-003** | Weapon selection panel | `equipped_weapons[]` | On equipment change | Shows all equipped weapons with slots |
| **UI-004** | Magic cost per shot | WeaponTypeDatabase.magic_cost_per_shot | On weapon switch | Shows cost for current weapon |
| **UI-005** | Crosshair / aim reticle | Aim direction | Every frame | Centered on aim target position |
| **UI-006** | Weapon damage preview | WeaponTypeDatabase.damage | On weapon hover | Tooltip or HUD corner |
| **UI-007** | Weapon range indicator | WeaponTypeDatabase.range | On weapon hover | Shows effective engagement distance |
| **UI-008** | Ammo/magic indicator (optional) | Magic energy ratio | Every magic change | Visual link between shooting and magic pool |

## Acceptance Criteria

### Weapon Equipment

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-001** | GIVEN vehicle with weapon_mounts=1, WHEN attempting to equip 2nd weapon, THEN equipment fails with "slot exceeded" message | Unit test: WEQ-001/002 |
| **AC-002** | GIVEN vehicle with weapon_mounts=4, WHEN equipping large weapon (slot_requirement=2), THEN remaining slots = 2 | Unit test: slot accounting |
| **AC-003** | GIVEN vehicle in DEPLOYED state, WHEN attempting to equip weapon, THEN equipment fails (WEQ-003) | Unit test: state guard |
| **AC-004** | GIVEN invalid weapon_type_id (99999), WHEN attempting to equip, THEN equipment fails with warning log | Unit test: WEQ-004 |
| **AC-005** | GIVEN valid weapon_type_id, WHEN equip_weapon() called, THEN equipped_weapons[] appended and `weapon_equipped` signal emitted | Integration test |

### Firing Process

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-006** | GIVEN vehicle with magic_energy=0, WHEN fire input pressed, THEN shooting fails and `magic_insufficient_for_fire` signal emitted | Unit test: FIRE-001 |
| **AC-007** | GIVEN vehicle with magic_energy=5 and shot_cost=10, WHEN fire input pressed, THEN shooting fails (partial magic not consumed) | Unit test: EC-002 |
| **AC-008** | GIVEN fire_cooldown_remaining=0.3s, WHEN fire input pressed, THEN shooting fails silently | Unit test: FIRE-002 |
| **AC-009** | GIVEN vehicle in DISABLED state, WHEN fire input pressed, THEN shooting fails completely | Unit test: FIRE-003 |
| **AC-010** | GIVEN weapon_switch_cooldown active (0.5s remaining), WHEN fire input pressed, THEN shooting fails | Unit test: FIRE-004 |
| **AC-011** | GIVEN vehicle in DEPLOYED state with sufficient magic, WHEN fire input pressed, THEN projectile generated at vehicle position with correct direction | Integration test: projectile spawn |
| **AC-012** | GIVEN BURST fire_mode weapon, WHEN fire input held for 2 seconds, THEN burst_cost pre-deducted (FIRE-005) | Integration test: magic pre-deduction |
| **AC-013** | GIVEN no weapons equipped, WHEN fire input pressed, THEN shooting fails with no current weapon | Unit test: EC-006 |

### Damage Calculation

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-014** | GIVEN base_damage=20, armor_reduction=0.80, WHEN damage calculated, THEN final_damage=4 (20×0.20=4) | Unit test: Formula 1 |
| **AC-015** | GIVEN base_damage=5, armor_reduction=0.80, WHEN damage calculated, THEN final_damage=1 (minimum rule DMG-001) | Unit test: EC-018 |
| **AC-016** | GIVEN crit_chance=0.05, WHEN random roll succeeds (Rv<0.05), THEN crit_factor=crit_multiplier | Unit test: Formula 2 |
| **AC-017** | GIVEN crit_chance=0.0, WHEN any random roll, THEN crit_factor=1.0 | Unit test: zero crit |
| **AC-018** | GIVEN range=15, distance=16 (threshold=12), WHEN range falloff calculated, THEN falloff_factor=0.5 (minimum) | Unit test: Formula 3 |
| **AC-019** | GIVEN armor_reduction=0.90 (invalid), WHEN damage calculated, THEN armor clamped to 0.80 | Unit test: EC-019 |

### Projectile Behavior

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-020** | GIVEN projectile with range=15, WHEN traveled 15 cells, THEN projectile destroyed (PROJ-002) | Unit test: range exhaustion |
| **AC-021** | GIVEN projectile colliding with terrain, WHEN collision detected, THEN projectile destroyed with no damage event | Unit test: EC-012 |
| **AC-022** | GIVEN projectile colliding with enemy, WHEN collision detected, THEN damage event sent to EnemyAI and projectile destroyed | Integration test: PROJ-004 |
| **AC-023** | GIVEN projectile_speed=20 cells/sec, WHEN distance=15 cells, THEN travel_time=0.75 seconds | Unit test: Formula 5 |
| **AC-024** | GIVEN projectile colliding with friendly entity, WHEN collision detected, THEN projectile destroyed with no damage | Unit test: EC-013 |

### Aim System

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-025** | GIVEN aim_input magnitude=0.0, WHEN aim_direction updated, THEN previous aim_direction retained | Unit test: EC-016 |
| **AC-026** | GIVEN aim_input magnitude=0.10 (< 0.15 deadzone), WHEN aim_direction updated, THEN previous aim_direction retained | Unit test: AIM-004 |
| **AC-027** | GIVEN aim_input magnitude=0.50 (> deadzone), WHEN aim_direction updated, THEN direction normalized to unit vector | Unit test: AIM-001 |
| **AC-028** | GIVEN auto_aim_range=0 (disabled), WHEN nearest enemy at 5 cells, THEN aim_direction unchanged from input | Unit test: MVP no auto-aim |

### Weapon Switching

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-029** | GIVEN 3 weapons equipped, WHEN switch to index 2 requested, THEN current_weapon_index=2 and `weapon_switched` signal emitted | Unit test: SWT-001/002 |
| **AC-030** | GIVEN 2 weapons equipped, WHEN switch to index 5 requested, THEN index clamped to 1 | Unit test: EC-007 |
| **AC-031** | GIVEN weapon switch completed, WHEN attempting to fire, THEN fire blocked for 0.5 seconds (switch_cooldown) | Integration test: SWT-003 |
| **AC-032** | GIVEN switch to same weapon index, WHEN switch completes, THEN switch_cooldown still applied | Unit test: EC-029 |

### Integration

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-033** | GIVEN projectile hit enemy, WHEN damage event sent, THEN EnemyAI.take_damage() called with correct parameters | Integration test: downstream call |
| **AC-034** | GIVEN weapon fired, WHEN magic consumed, THEN VehicleAttribute.current_magic_energy decremented by shot_cost | Integration test: #17 integration |
| **AC-035** | GIVEN weapon equipped, WHEN HUD queries status, THEN get_weapon_status() returns {name, cooldown_remaining, magic_cost} | Integration test: #49 interface |
| **AC-036** | GIVEN weapon fired, WHEN Audio system receives signal, THEN `weapon_fired` signal includes weapon_type_id and position | Integration test: #52 signal |

### Formula Correctness

| AC ID | Criterion | Test Method |
|-------|-----------|-------------|
| **AC-037** | GIVEN fire_rate=2.0, WHEN cooldown calculated, THEN cooldown_duration=0.5 seconds | Unit test: Formula 4 |
| **AC-038** | GIVEN fire_rate=0.5 (slow), WHEN cooldown calculated, THEN cooldown_duration=2.0 seconds | Unit test: Formula 4 boundary |
| **AC-039** | GIVEN fire_rate=0 (invalid), WHEN cooldown calculated, THEN default to fire_rate=1.0 (EC-022) | Unit test: data error handling |

## Open Questions

| Question ID | Question | Status | Impact | Resolution Needed By |
|-------------|----------|--------|--------|----------------------|
| **Q-001** | Should WeaponTypeDatabase be a separate GDD or inline definitions? | **Open** | Defines interface structure for #19 and #20 integration | Before implementation of #19/#20 |
| **Q-002** | Should auto-aim be implemented for MVP (optional feature)? | **Resolved** | Current design: AUTO_AIM_RANGE=0 (disabled) | Alpha feature if player feedback requests aim assist |
| **Q-003** | Should projectile penetration be allowed for MVP? | **Resolved** | PROJ-005 defines as Alpha feature | MVP: single collision destroys projectile |
| **Q-004** | Should friendly fire be allowed (player hitting own structures)? | **Open** | EC-013 assumes friendly fire OFF for MVP | Before #21 (Vehicle Damage) design — may need self-damage rules |
| **Q-005** | What collision layer value for COLLISION_PLAYER_PROJECTILE? | **Open** | Needs registration in entities.yaml | Before TileMap collision system implementation |
| **Q-006** | Should weapon modification interface be in #20 or separate Modification GDD? | **Open** | efficiency_modifier currently assumed from mods | Before #23 (Vehicle Modification) design |
| **Q-007** | Should burst_count have a maximum cap per burst? | **Open** | FIRE-005 pre-deducts unlimited burst duration | Before balance tuning — prevent infinite burst draining all magic |