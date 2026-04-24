# 炮塔系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 3 — 尸潮即高潮 (建造投入转化为实战火力)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #38 (from systems-index.md)

## Overview

炮塔系统是管理所有已建造炮塔实例的运行时实体系统。每个炮塔实例作为独立运行实体（TurretEntity），从建造物品数据库读取炮塔类型属性（攻击范围、射速、伤害、弹药类型），维护自身状态机（待机/瞄准/射击/冷却），执行目标搜索逻辑（敌人在射程内、视线遮挡检测），触发射击事件生成弹道实体。

**数据层职责**：
- 管理TurretEntity实例生命周期（建造完成时创建、被摧毁时销毁）
- 维护炮塔状态机：IDLE → TARGETING → FIRING → COOLDOWN循环
- 执行目标搜索算法：遍历敌人列表，筛选射程内目标，视线遮挡检测
- 触发射击事件：发送`turret_fired(turret_id, target_id, damage)`信号
- 消耗弹药/魔力资源：根据炮塔类型扣减资源（弹药堆叠或魔力晶石）

**玩家影响层（间接）**：
- 尸潮期间炮塔自动射击，玩家感受到建造投入转化为实战火力
- 炮塔位置决定防守效果，玩家学会优化炮塔布局策略
- 炮塔损坏时防线缺口，玩家感受到防守压力真实后果

**系统必要性**：没有炮塔系统，建造物品数据库的炮塔配方无法生效——玩家建造了炮塔方块却无火力输出。炮塔系统将建造决策转化为防守压力，是Pillar 3（尸潮即高潮）的核心火力输出层。

**下游消费系统**：
- 敌人AI系统 — 接收炮塔伤害事件
- 敌人生成系统 — 接收`enemy_killed`信号
- 战斗反馈系统 — 接收射击/击中/击杀事件用于视觉反馈
- HUD系统 — 查询炮塔状态显示

## Player Fantasy

**情感目标：建造投入的火力回报**

玩家在炮塔系统中面对的核心体验是**建造决策的实战验证**——每一座炮塔都是用搜刮资源换来的火力承诺，尸潮来袭时，玩家看着炮塔自动射击，感受到的是"我的投入正在生效"的掌控感与满足感。

**锚定时刻**：

1. **首次火力生效**：玩家建造完第一座基础炮塔（6铁+4石+2晶石，15秒建造），尸潮倒计时结束的那一刻——炮塔炮口旋转，锁定目标，砰！第一发晶石弹击中僵尸。这是"建造投入转化为火力"的觉醒时刻：玩家感受到的不是"炮塔在自动射击"，而是"我用搜刮换来的晶石正在保护我的堡垒"。

2. **防线火力协同**：玩家建造了三座炮塔布局成三角形防线，尸潮来袭时三座炮塔同时开火，火力网覆盖多个敌人。玩家看着协同火力压制尸潮，感受到的是"布局策略生效"的成就感——不只是每座炮塔单独工作，而是整体防线设计创造火力压制。

3. **炮塔损坏的代价感**：尸潮高峰期，一座炮塔被敌人攻击损坏停火。防线缺口，敌人涌入，玩家看着损坏的炮塔残骸，感受到的是"防守代价真实存在"——建造不是无风险投入，炮塔会损坏，防线会缺口，后果真实且可见。

**支柱服务**：

- **Pillar 3 (尸潮即高潮)**：炮塔火力是尸潮"压力真实感"的核心来源——没有炮塔，尸潮只是敌人数量堆叠；有了炮塔，玩家有反击手段，尸潮变成"火力对抗"的战术博弈。炮塔损坏创造防守后果真实感。

**语调示例**：

```
❌ "炮塔每秒射击2发，造成30伤害"
✓ "符文炮塔旋转炮口——晶石脉动闪烁，每发都是用废土搜刮换来的火力承诺"

❌ "炮塔被摧毁，防线缺口"
✓ "炮塔残骸冒着魔能余温——防线缺口处，尸潮正在涌入，建造的代价此刻可见"
```

**没有炮塔系统，玩家失去什么**：
- 建造投入失去火力验证 — 资源消耗无实战回报感
- 尸潮防守失去反击手段 — 纯被动承受压力，无主动性
- 防线布局失去策略意义 — 无火力输出，位置决策无意义

## Detailed Design

### Core Rules

**Rule 1: Turret Entity Data Structure**

每个炮塔实例作为独立的运行时实体（TurretEntity），存储在场景中作为Node2D子节点。炮塔实体数据从建造物品数据库和炮塔类型扩展数据读取。

**TurretEntity Primary Fields:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `turret_id` | int | 200-299 | — | 建造物品ID（引用BuildItemDB） |
| `instance_id` | int | 0-∞ | — | 运行时唯一实例标识符 |
| `position` | Vector2 | world bounds | — | 炮塔世界位置（继承自建造方块位置） |
| `state` | TurretState | 0-4 | IDLE | 状态机当前状态 |
| `current_target` | int | -1/enemy_id | -1 | 当前锁定目标ID（-1=无目标） |
| `cooldown_timer` | float | 0-fire_rate | 0 | 射击冷却计时器 |
| `health` | int | 0-max_health | max | 炮塔耐久值 |
| `ammo_stack` | int | 0-max_ammo | 0 | 弹药堆叠数量（弹药型炮塔） |
| `magic_reserve` | float | 0-max_magic | max | 魔力储备（魔力型炮塔） |

**TurretType Extended Fields (from TurretTypeDatabase):**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `damage` | int | 5-100 | 20 | 单发伤害值 |
| `fire_rate` | float | 0.5-10.0 | 2.0 | 射击速率（发/秒） |
| `attack_range` | float | 5.0-30.0 | 15.0 | 攻击范围（格） |
| `targeting_range` | float | attack_range×2 | — | 目标搜索范围（比攻击范围大，用于预瞄准） |
| `projectile_type` | int | 0-2 | 0 | 弹道类型（DIRECT/ARCING/BEAM） |
| `projectile_speed` | float | 10.0-50.0 | 20.0 | 弹道速度（格/秒） |
| `ammo_type` | int | 0-2 | 0 | 资源类型（AMMO_STACK/MAGIC_RESERVE/FREE） |
| `ammo_cost_per_shot` | int | 1-5 | 1 | 每发消耗（弹药型） |
| `magic_cost_per_shot` | float | 1.0-20.0 | 5.0 | 每发魔能消耗（魔力型） |
| `rotation_speed` | float | 30-180 | 90 | 炮塔旋转速度（度/秒） |
| `targeting_priority` | int | 0-2 | 0 | 目标优先级策略（NEAREST/HIGHEST_THREAT/LOWEST_HEALTH） |

---

**Rule 2: Target Acquisition Algorithm**

每帧执行目标搜索逻辑，筛选射程内敌人作为有效目标。

**目标搜索流程：**

```
1. 获取所有活跃敌人列表（从EnemySpawnSystem）
2. 篇选：敌人位置在targeting_range内
3. 排序：按targeting_priority策略排序
4. 视线检测：RayCast2D检查炮塔→敌人路径是否被方块遮挡
5. 锁定：选择第一个视线无遮挡的目标作为current_target
```

**目标优先级策略：**

| Priority | Strategy | Sorting Formula |
|----------|----------|------------------|
| 0 (NEAREST) | 最近距离优先 | `sort_key = distance(turret_pos, enemy_pos)` |
| 1 (HIGHEST_THREAT) | 最高威胁优先 | `sort_key = -enemy.threat_score`（WALL_BREAKER威胁更高） |
| 2 (LOWEST_HEALTH) | 最低血量优先（击杀收割） | `sort_key = enemy.health` |

**视线遮挡检测：**

- 使用RayCast2D从炮塔位置指向敌人位置
- 禁止碰撞层：COLLISION_TERRAIN (1), COLLISION_STRUCTURE (2)
- 允许穿透层：COLLISION_ENEMY_BODY (8)（敌人不遮挡视线）
- 如果RayCast碰撞点 ≠ 敌人位置 → 视线被遮挡，跳过该目标

---

**Rule 3: State Machine and Firing Logic**

炮塔状态机控制射击节奏。

**状态枚举：**

| State | Name | Entry Condition | Behavior |
|-------|------|-----------------|----------|
| IDLE (0) | 待机 | 无有效目标 | 炮塔静止，等待目标进入targeting_range |
| TARGETING (1) | 瞄准 | 目标进入targeting_range | 炮塔旋转朝向目标，等待进入attack_range |
| FIRING (2) | 射击 | 目标在attack_range内且cooldown_timer≤0 | 发射弹道，扣减资源，重置cooldown_timer |
| COOLDOWN (3) | 冷却 | 射击后cooldown_timer>0 | 等待冷却计时器归零，保持瞄准 |
| DISABLED (4) | 损坏 | health≤0 | 停止运作，等待修复或销毁 |

**状态转换表：**

| Current State | Trigger | Next State |
|---------------|---------|------------|
| IDLE | 目标进入targeting_range | TARGETING |
| TARGETING | 目标进入attack_range且cooldown_timer≤0 | FIRING |
| TARGETING | 目标丢失（超出targeting_range或死亡） | IDLE |
| FIRING | 射击完成 | COOLDOWN |
| COOLDOWN | cooldown_timer归零且有目标 | FIRING |
| COOLDOWN | cooldown_timer归零且无目标 | IDLE |
| ANY | health≤0 | DISABLED |
| DISABLED | 修复完成（health>0） | IDLE |

**射击执行流程：**

```
1. 检查资源：ammo_stack ≥ ammo_cost 或 magic_reserve ≥ magic_cost
2. 生成弹道实体：ProjectileEntity（继承projectile_type属性）
3. 扣减资源：ammo_stack -= ammo_cost 或 magic_reserve -= magic_cost
4. 发射信号：turret_fired(turret_id, target_id, damage)
5. 重置冷却：cooldown_timer = 1.0 / fire_rate
6. 状态转换：FIRING → COOLDOWN
```

---

**Rule 4: Damage Calculation**

炮塔伤害计算继承战车武器系统公式，适配炮塔类型。

**伤害公式：**

```
final_damage = max(MINIMUM_DAMAGE, turret_damage × efficiency × crit_factor - enemy_armor × armor_effectiveness)
```

**变量定义：**

| Variable | Source | Range | Description |
|----------|--------|-------|-------------|
| `turret_damage` | TurretTypeDB | 5-100 | 炮塔基础伤害 |
| `efficiency` | Runtime | 0.8-1.0 | 炮塔效率系数（损坏状态降低） |
| `crit_factor` | RNG | 1.0 or 2.0 | 暴击倍率（crit_chance概率触发） |
| `enemy_armor` | EnemyTypeDB | 0-50 | 敌人护甲值 |
| `armor_effectiveness` | Tuning | 0.5-0.8 | 护甲减伤系数 |
| `MINIMUM_DAMAGE` | Constant | 1 | 最小伤害保底 |

**暴击规则：**

- 暴击概率：turret_crit_chance（炮塔类型定义，默认0.05）
- RNG检查：`random_float() < crit_chance` → crit_factor = 2.0
- 暴击时伤害计算：`damage × 2.0`（护甲减伤仍生效）

---

**Rule 5: Resource Consumption**

炮塔射击消耗资源，根据ammo_type决定消耗类型。

**资源类型：**

| ammo_type | Resource | Consumption | Replenishment |
|-----------|----------|-------------|---------------|
| 0 (AMMO_STACK) | 弹药堆叠 | ammo_cost_per_shot (int) | 玩家手动补给（下车状态交互） |
| 1 (MAGIC_RESERVE) | 魔力储备 | magic_cost_per_shot (float) | 魔力发电机自动供给 |
| 2 (FREE) | 无消耗 | 0 | 无限射击 |

**弹药补给规则（AMMO_STACK）：**

- 玩家下车状态下靠近炮塔交互
- 补给弹药类型由TurretTypeDB定义（ammo_resource_id）
- 补给数量：玩家背包ammo_resource → 炮塔ammo_stack（转移）
- 最大堆叠：max_ammo（炮塔类型定义）

**魔力供给规则（MAGIC_RESERVE）：**

- 魔力发电机设施每秒产生魔力
- 炮塔魔力储备自动从发电机获取（若有魔力发电机在供给范围内）
- 供给范围：GENERATOR_SUPPLY_RANGE（待定义，Alpha功能）
- MVP阶段：炮塔魔力储备初始满值，射击消耗，无自动补给

---

**Rule 6: Turret Damage and Destruction**

炮塔可被敌人攻击损坏或摧毁。

**伤害接收：**

- 炮塔监听`enemy_attack_signal`
- 当敌人攻击目标为炮塔时，炮塔扣减health
- 伤害公式继承战车损坏系统（enemy_damage × collision_modifier）

**损坏状态：**

| health_ratio | State | Behavior |
|--------------|-------|----------|
| > 0.5 | 正常运作 | efficiency = 1.0 |
| 0.3-0.5 | 损坏运作 | efficiency = 0.8，视觉裂纹 |
| 0.0-0.3 | 严重损坏 | efficiency = 0.5，射击间隔延长 |
| ≤ 0.0 | 损毁停机 | DISABLED状态，等待修复 |

**修复规则：**

- 玩家下车状态下交互修复
- 修复材料：repair_material_costs（待定义）
- 修复时间：repair_time_seconds（待定义）

---

### States and Transitions

| Current State | Transition Trigger | Next State | Notes |
|---------------|--------------------|------------|-------|
| IDLE | 目标进入targeting_range且有视线 | TARGETING | 开始旋转瞄准 |
| TARGETING | 炮塔角度对准目标且cooldown≤0 | FIRING | 射击准备 |
| TARGETING | 目标超出targeting_range或死亡 | IDLE | 丢失目标 |
| TARGETING | 视线被新方块遮挡 | IDLE | 重新搜索 |
| FIRING | 射击完成 | COOLDOWN | 进入冷却 |
| COOLDOWN | cooldown归零且有目标 | FIRING | 连续射击 |
| COOLDOWN | cooldown归零且无目标 | IDLE | 等待新目标 |
| ANY | health≤0 | DISABLED | 损毁停机 |
| DISABLED | 修复完成 | IDLE | 恢复运作 |

---

### Interactions with Other Systems

| System | Direction | Data Interface | Nature |
|--------|-----------|----------------|--------|
| **建造物品数据库 (#5)** | IN | `get_turret_type(build_item_id)` → returns damage, fire_rate, range, ammo_type | Query API |
| **TileMap世界系统 (#1)** | IN | 炮塔位置查询、视线遮挡检测（RayCast2D） | Position/Physics |
| **敌人AI系统 (#36)** | OUT | `turret_fired(turret_id, target_id, damage)` signal → enemy damage system | Signal emitter |
| **敌人生成系统 (#37)** | IN | `get_active_enemies()` → returns enemy list for targeting | Query API |
| **方块放置系统 (#13)** | IN | `block_placed` signal → 创建TurretEntity | Signal listener |
| **战斗反馈系统 (#41)** | OUT | `turret_fired`, `turret_hit`, `turret_kill` signals → visual feedback | Signal emitter |
| **HUD系统 (#49)** | OUT | `get_turret_status(instance_id)` → returns state, ammo, health | Query API |

## Formulas

### Formula 1: Target Distance Calculation

`target_distance = turret_position.distance_to(enemy_position) / CELL_SIZE`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `turret_position` | — | Vector2 | world bounds | 炮塔世界位置（像素） |
| `enemy_position` | — | Vector2 | world bounds | 敌人世界位置（像素） |
| `CELL_SIZE` | — | int | 32 | 单元格像素尺寸（来自entities.yaml） |

**Output Range:** 0 to MAX_WORLD_BOUNDS (cells)

**Example:** turret_pos=(1600, 800), enemy_pos=(2000, 900), CELL_SIZE=32 → distance = sqrt(400² + 100²) / 32 = sqrt(170000) / 32 ≈ 13.2 cells

---

### Formula 2: Damage Calculation

`final_damage = max(MINIMUM_DAMAGE, turret_damage × efficiency × crit_factor - enemy_armor × armor_effectiveness)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `turret_damage` | TD | int | 5-100 | 炮塔基础伤害（来自TurretTypeDB） |
| `efficiency` | EFF | float | 0.5-1.0 | 炮塔效率系数（损坏降低） |
| `crit_factor` | CRIT | float | 1.0 or 2.0 | 暴击倍率（RNG触发） |
| `enemy_armor` | ARM | int | 0-50 | 敌人护甲值（来自EnemyTypeDB） |
| `armor_effectiveness` | AE | float | 0.5-0.8 | 护甲减伤系数（tuning knob） |
| `MINIMUM_DAMAGE` | MIN | int | 1 | 最小伤害保底（来自registry） |

**Output Range:** 1 to 200 (100 × 1.0 × 2.0 - 0)

**Example:** turret_damage=30, efficiency=1.0, crit_factor=1.0, enemy_armor=10, armor_effectiveness=0.6 → damage = max(1, 30 × 1.0 × 1.0 - 10 × 0.6) = max(1, 24) = 24

**Boundary Tests:**

| Case | TD | EFF | CRIT | ARM | AE | final_damage |
|------|----|----|------|-----|----|--------------|
| 无护甲敌人 | 30 | 1.0 | 1.0 | 0 | 0.6 | 30 |
| 暴击命中 | 30 | 1.0 | 2.0 | 10 | 0.6 | 48 |
| 损坏炮塔 | 30 | 0.5 | 1.0 | 0 | 0.6 | 15 |
| 高护甲敌人 | 30 | 1.0 | 1.0 | 50 | 0.8 | max(1, -10) = 1 |

---

### Formula 3: Cooldown Timer Reset

`cooldown_timer = 1.0 / fire_rate`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `fire_rate` | FR | float | 0.5-10.0 | 射击速率（发/秒，来自TurretTypeDB） |

**Output Range:** 0.1 seconds (fire_rate=10.0) to 2.0 seconds (fire_rate=0.5)

**Example:** fire_rate=2.0 → cooldown_timer = 1.0 / 2.0 = 0.5 seconds

---

### Formula 4: Targeting Range

`targeting_range = attack_range × TARGETING_RANGE_MULT`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `attack_range` | AR | float | 5.0-30.0 | 攻击范围（格，来自TurretTypeDB） |
| `TARGETING_RANGE_MULT` | TRM | float | 1.5-3.0 | 目标搜索范围倍率（tuning knob，默认2.0） |

**Output Range:** 7.5 cells to 60 cells

**Example:** attack_range=15.0, TRM=2.0 → targeting_range = 30.0 cells

---

### Formula 5: Rotation Time to Target

`rotation_time = angle_difference / rotation_speed`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `angle_difference` | Δθ | float | 0-180 | 炮塔当前角度与目标角度差（度） |
| `rotation_speed` | RS | float | 30-180 | 炮塔旋转速度（度/秒，来自TurretTypeDB） |

**Output Range:** 0 seconds (aligned) to 6 seconds (180° at 30°/sec)

**Example:** angle_difference=90°, rotation_speed=90 → rotation_time = 90 / 90 = 1.0 second

## Edge Cases

1. **If multiple turrets target the same enemy simultaneously**: All turrets fire independently, damage stacked. No target "ownership" — each turret processes its own firing cycle. Rationale: Avoids coordination overhead, simpler implementation.

2. **If turret has no ammo/magic and enemy in attack_range**: Enter IDLE state despite enemy presence. Log debug `"Turret [id] has no resources, cannot fire"`. Visual indicator shows empty state (ammo/magic bar at 0). Rationale: Player must replenish resources to restore火力.

3. **If target dies while projectile is in flight**: Projectile continues trajectory to target's last position. On arrival, no damage applied. Projectile despawns. Rationale: Projectile physics独立，避免中飞行取消的视觉突兀。

4. **If turret placement has no line of sight to enemy path**: Turret remains in IDLE state permanently. Target acquisition algorithm视线检测确保无目标被锁定。Warn player at placement time with visual preview showing sight lines. Rationale: Prevents useless turret placements, player learns positioning strategy.

5. **If multiple enemies enter targeting_range simultaneously**: Targeting_priority strategy applies sorting. First valid target after视线检测 is locked. Turret does not rapid-switch targets mid-cycle (prevents target flip-flop). Rationale: Stable targeting creates predictable火力 pattern.

6. **If turret is damaged while in COOLDOWN state**: Damage applied immediately, efficiency updated. State remains COOLDOWN — no state interruption. If damage reduces health to ≤0, transition to DISABLED after cooldown completes. Rationale: Damage interrupts firing flow but cooldown must complete before checking health.

7. **If turret rotation_speed cannot catch fast-moving enemy**: Turret continues rotating toward target's current position each frame. If target exits attack_range before alignment completes, transition to IDLE or TARGETING (follow targeting_range rules). Rationale: Fast enemies may evade turret fire, creates tactical advantage for enemy speed types.

8. **If enemy armor exceeds potential damage (damage - armor × effectiveness ≤ 0)**: MINIMUM_DAMAGE floor applies. Turret always deals at least 1 damage per shot. Rationale: Prevents炮塔完全无效 scenario, maintains player investment回报感。

9. **If spatial partition query returns empty enemy list**: Treat as no targets, enter IDLE state. Log warning `"EnemySpawnSystem returned empty list — no active enemies"`. Rationale: Handles edge case of no enemies spawned (pre-尸潮 or post-wave).

10. **If RayCast2D视线检测 fails (engine error)**: Treat as视线遮挡 (skip target). Log error `"RayCast2D视线检测 failed for turret [id]"`. Fallback: use distance-only targeting (no视线遮挡 check) for current frame. Rationale: Engine failure should not break targeting entirely.

11. **If turret entity created at same cell as existing turret**: Block placement system prevents this (BuildValidationSystem checks). If creation somehow bypasses validation, reject and log error `"Duplicate turret at cell [coords]"`. Rationale: Collision layer prevents stacking, validation ensures uniqueness.

12. **If projectile_type BEAM hits multiple enemies in path**: BEAM projectiles pierce enemies in line until max_range or COLLISION_TERRAIN/STRUCTURE hit. Damage applied to each enemy hit. Rationale: BEAM type creates area denial火力 pattern.

## Dependencies

### Upstream Dependencies (Required)

| System | ID | Status | Data Flow | Interface |
|--------|----|---------|-----------|-----------|
| **建造物品数据库** | #5 | Designed | `get_turret_type(build_item_id)` → returns damage, fire_rate, attack_range, projectile_type, ammo_type | Query API |
| **TileMap世界系统** | #1 | Designed | 炮塔位置查询、RayCast2D视线检测、CELL_SIZE constant | Position/Physics |
| **敌人AI系统** | #36 | Designed | `turret_fired` signal → enemy damage system receives damage event | Signal emitter |
| **敌人生成系统** | #37 | Designed | `get_active_enemies()` → returns enemy list for targeting | Query API |

### Downstream Dependents (Consumers)

| System | ID | Status | Data Flow | Interface |
|--------|----|---------|-----------|-----------|
| **方块放置系统** | #13 | Approved | `block_placed` signal → creates TurretEntity when turret build item placed | Signal listener |
| **战斗反馈系统** | #41 | Not Started | `turret_fired`, `turret_hit`, `turret_kill` signals → visual/audio feedback | Signal emitter |
| **HUD系统** | #49 | Not Started | `get_turret_status(instance_id)` → returns state, ammo, health for UI display | Query API |
| **防守失败梯度** | #40 | Not Started | Turret damage/destruction affects failure progression | Indirect consumer |
| **音效系统** | #52 | Not Started | `turret_fired` signal → triggers shooting sound effect | Signal listener |

### Dependency Nature

| Dependency | Nature | Without it... |
|------------|--------|---------------|
| 建造物品数据库 | **Hard** | Cannot determine turret type attributes (damage, fire_rate, range) |
| TileMap世界系统 | **Hard** | Cannot determine turret position, cannot perform视线遮挡检测 |
| 敌人AI系统 | **Hard** | No damage delivery — turret火力无法造成敌人伤害 |
| 敌人生成系统 | **Hard** | No enemy list — target acquisition has no targets to query |

### Provisional Dependencies

None. All upstream dependencies have designed GDDs.

## Tuning Knobs

| Knob ID | Knob Name | Value | Range | Affects | Notes |
|---------|-----------|-------|-------|---------|-------|
| **TK-008** | `TARGETING_RANGE_MULT` | 2.0 | 1.5-3.0 | Turret targeting range | ×3.0 = wide search, ×1.5 = tight search. Affects pre-aim timing. |
| **TK-009** | `TURRET_ARMOR_EFFECTIVENESS` | 0.6 | 0.5-0.8 | Damage vs armored enemies | ×0.8 = armor strong, ×0.5 = armor weak. Affects炮塔对护甲敌人效果. |
| **TK-010** | `TURRET_CRIT_CHANCE_BASE` | 0.05 | 0.0-0.15 | Crit probability for all turrets | ×0.15 = frequent crits, ×0.0 = no crits. Affects火力 spike frequency. |
| **TK-011** | `TURRET_EFFICIENCY_DAMAGE_THRESHOLD` | 0.5 | 0.3-0.7 | Health ratio where efficiency drops to 0.8 | Lower = earlier efficiency penalty, higher = later penalty. |
| **TK-012** | `TURRET_EFFICIENCY_HEAVY_DAMAGE_THRESHOLD` | 0.3 | 0.1-0.5 | Health ratio where efficiency drops to 0.5 | Lower =炮塔 stays effective longer under damage. |
| **TK-013** | `MAX_TURRETS_PER_FRAME` | 50 | 20-100 | Turret processing batch limit | Cap prevents frame spikes when many turrets active. Affects尸潮大规模防守 performance. |
| **TK-014** | `TARGET_LOCK_FRAMES` | 3 | 1-10 | Frames before turret can switch target | Prevents target flip-flop. Higher = stable targeting, lower = reactive targeting. |

### Knob Interactions

- **`TARGETING_RANGE_MULT` × `attack_range`** — 最终搜索范围 = 攻击范围 × 倍率。高倍率让炮塔提前预瞄准，减少射击延迟。
- **`TURRET_ARMOR_EFFECTIVENESS` × `enemy_armor`** — 最终减伤 = 护甲 × 效果系数。高效果系数让护甲更有效，炮塔对护甲敌人火力降低。
- **`TURRET_EFFICIENCY_*_THRESHOLD`** — 损坏状态阈值定义效率下降曲线。两级阈值创造渐进损坏效果而非突然失效。

### Tuning Validation Advisory

> **⚠️ Playtest Required**: 当前默认值可能需要根据尸潮体验调整：
> - 如果炮塔火力过强，尸潮无压力 → 降低`TARGETING_RANGE_MULT`到1.5或提高`TURRET_ARMOR_EFFECTIVENESS`
> - 如果炮塔过早损坏失去火力 → 降低`TURRET_EFFICIENCY_DAMAGE_THRESHOLD`到0.3（延迟效率下降）
> - 如果多炮塔造成帧率掉落 → 降低`MAX_TURRETS_PER_FRAME`到30

## Visual/Audio Requirements

炮塔系统属于Defense类别，Visual/Audio为必需部分——防守设施的视觉反馈是Pillar 3（尸潮即高潮）的关键体验层。

### Visual Requirements

**Turret Base and Barrel:**

每个炮塔实例由两部分组成：
- **炮塔底座**：固定朝向的方块纹理（继承建造物品数据库的block_texture）
- **炮塔炮管**：可旋转的Sprite2D子节点，朝向当前目标

**视觉状态反馈：**

| health_ratio | 纹理状态 | 纹理文件 | 描述 |
|--------------|---------|---------|------|
| > 0.5 | 正常 | `turret_[type]_normal.png` | 完整外观，炮管金属光泽 |
| 0.3-0.5 | 损坏 | `turret_[type]_damaged.png` | 表面裂纹，轻微锈蚀痕迹 |
| 0.0-0.3 | 严重损坏 | `turret_[type]_heavy_damage.png` | 明显破损，炮管变形 |
| ≤ 0.0 | 损毁 | `turret_[type]_destroyed.png` | 残骸状态，炮管断裂 |

**Aiming Visual Feedback:**

- 炮管旋转动画：使用`rotation_speed`参数控制动画速度（度/秒）
- 目标锁定指示器：当`current_target`有效时，炮管顶端显示瞄准激光线（LINE_RENDERER）
- 激光线颜色：魔力型炮塔=蓝紫色调，弹药型炮塔=橙红色调

**Firing Visual Effects:**

| projectile_type | 发射效果 | 弹道效果 | 击中效果 |
|-----------------|---------|---------|---------|
| DIRECT (0) | 炮口闪光sprite | 直线弹道轨迹sprite | 撞击粒子爆炸 |
| ARCING (1) | 炮口烟雾particle | 弧形弹道trail effect | 地面撞击裂纹 |
| BEAM (2) | 持续光束beam shader | 光束穿透线beam | 敌人灼烧flash |

**Ammo/Magic Indicator HUD Overlay:**

- 炮塔上方显示小型资源条（弹药堆叠数量或魔力储备比例）
- 弹药型：数字显示剩余堆叠数（如"45/60"）
- 魔力型：进度条显示魔力储备比例（0-100%）
- 空状态警告：资源条闪烁红色，提示玩家补给

### Audio Requirements

**Audio Events:**

| Event | Audio File | Volume | Loop | Trigger Condition |
|-------|-----------|--------|------|-------------------|
| 炮塔旋转 | `sfx_turret_rotate.wav` | 0.3 | false | 炮管角度变化>5° |
| 炮塔射击 | `sfx_turret_fire_[type].wav` | 0.5 | false | FIRING state entry |
| 弹道击中 | `sfx_projectile_hit.wav` | 0.4 | false | Projectile collision |
| 炮塔损坏 | `sfx_turret_damage.wav` | 0.6 | false | health下降事件 |
| 炮塔损毁 | `sfx_turret_destroy.wav` | 0.8 | false | health≤0 |
| 弹药空警告 | `sfx_turret_empty_warning.wav` | 0.4 | true (until ammo replenished) | ammo_stack=0 或 magic_reserve=0 |

**Audio Parameters:**

- 炮塔射击音效参数化：根据fire_rate调整pitch（高射速=higher pitch）
- 弹道击中音效分层：DIRECT=金属撞击音，ARCING=地面爆破音，BEAM=灼烧嗡鸣音

**Audio Spatial Positioning:**

- 所有炮塔音效使用2D spatial audio，位置跟随炮塔世界坐标
- 玩家视角范围内（camera viewport）的炮塔音效全音量
- 视角外炮塔音效衰减（distance attenuation）

## UI Requirements

炮塔系统为数据层，UI需求由HUD系统和建造系统消费。

### Turret Status HUD (HUD系统 #49)

**Turret Info Panel:**

当玩家靠近炮塔或选中炮塔时，显示炮塔状态面板：
- **状态指示器**：图标显示当前状态（IDLE/TARGETING/FIRING/COOLDOWN/DISABLED）
- **资源条**：弹药堆叠数或魔力储备比例
- **耐久条**：health/max_health比例
- **效率指示**：当前efficiency值（损坏状态降低时显示警告）

**Turret List Overview (防守期间):**

- 尸潮防守期间，HUD显示所有活跃炮塔状态列表
- 列表按炮塔位置排序（从左到右防线位置）
- 每个炮塔条目显示：状态图标、耐久条、资源状态
- 损毁炮塔条目高亮警告（红色闪烁）

### Build Preview UI (建造系统 #13)

**Turret Placement Preview:**

放置炮塔建造物品时，建造预览UI显示：
- **射程预览圈**：圆形指示器显示attack_range范围
- **视线预览线**：从放置位置向可能的敌人路径方向发射虚拟视线检测线
- **覆盖区域评估**：显示"有效覆盖：良好/一般/差"评级

**Build Cost Display:**

建造物品数据库已定义炮塔配方cost，UI显示：
- 配方资源列表（铁/石/晶石数量）
- 建造时间（秒）
- 建造工具需求（建造锤等级）

### Interaction UI (下车状态系统 #30)

**Ammo Replenishment Interaction:**

玩家下车靠近弹药型炮塔时：
- **交互提示**："按[E]补给弹药"
- **补给预览**：显示玩家背包弹药资源 → 炮塔ammo_stack转移预览
- **补给确认**：补给完成后UI显示"补给完成：+X弹药"

**Repair Interaction:**

玩家下车靠近损坏炮塔时：
- **修复提示**："按[E]修复炮塔"
- **修复预览**：显示修复材料需求和修复时间
- **修复进度条**：修复过程中显示进度

## Open Questions

1. **TurretTypeDatabase具体数据结构如何定义？**

   当前GDD引用TurretTypeDatabase扩展字段（damage, fire_rate, attack_range等），但未定义该数据库的存储方式。建议：在建造物品数据库(#5)中扩展build_item表，增加`turret_type_data`子表存储炮塔特定属性。或者新建独立TurretTypeDatabase GDD(#38.1)。

   → **待定**：Alpha阶段前需要定义TurretTypeDatabase结构。

2. **魔力发电机供给范围如何计算？**

   当前GDD定义MAGIC_RESERVE类型炮塔依赖魔力发电机供给，但未定义供给范围计算方式（GENERATOR_SUPPLY_RANGE常量待定义）。MVP阶段简化为：魔力型炮塔初始满值，射击消耗，无自动补给。Alpha阶段引入魔力发电机供给系统。

   → **MVP简化**：魔力型炮塔无自动补给，玩家需下车手动充能。

3. **炮塔修复机制具体参数如何定义？**

   当前GDD定义修复规则为"玩家下车状态下交互修复"，但repair_material_costs和repair_time_seconds参数未定义。建议：在建造物品数据库(#5)中增加`turret_repair_data`子表定义修复参数。或者设计独立的RepairSystem GDD(#39)处理所有修复逻辑（战车修复、炮塔修复、设施修复）。

   → **待定**：Alpha阶段前需要定义修复系统参数。

4. **多炮塔协同射击如何优化性能？**

   当前GDD定义MAX_TURRETS_PER_FRAME=50限制每帧处理炮塔数量。当活跃炮塔超过50座时，需要分布处理策略：每帧处理50座，剩余炮塔下一帧处理，可能导致火力输出不均匀。建议：引入炮塔优先级队列（距离敌人最近的炮塔优先处理），或分帧批处理策略。

   → **MVP简化**：50座炮塔上限足够覆盖大部分防守场景。大规模尸潮Alpha阶段需优化策略。

## Acceptance Criteria

### Core Rule Coverage

**AC-01**: GIVEN turret_basic (build_item_id=200) built at cell (50, 30), WHEN build completes, THEN TurretEntity created with damage=20, fire_rate=2.0, attack_range=15.0, ammo_type=MAGIC_RESERVE.

**AC-02**: GIVEN enemy at distance=12 cells from turret with attack_range=15.0, WHEN target acquisition runs, THEN target_distance ≤ attack_range → target locked.

**AC-03**: GIVEN turret in TARGETING state with cooldown_timer=0, WHEN target in attack_range, THEN transition to FIRING, projectile spawned, `turret_fired` signal emitted.

**AC-04**: GIVEN turret with fire_rate=2.0 fires, WHEN firing completes, THEN cooldown_timer = 1.0 / 2.0 = 0.5 seconds, state=COOLDOWN.

**AC-05**: GIVEN turret with ammo_type=AMMO_STACK and ammo_stack=0, WHEN enemy in attack_range, THEN state=IDLE, no firing, debug log `"no resources"`.

**AC-06**: GIVEN turret health reduced to 20 (max=100), WHEN damage_threshold=0.5, THEN efficiency=0.8, damage output reduced by 20%.

### Formula Coverage

**AC-07**: GIVEN turret_pos=(1600, 800), enemy_pos=(2000, 900), CELL_SIZE=32, WHEN distance calculated, THEN target_distance ≈ 13.2 cells.

**AC-08**: GIVEN turret_damage=30, efficiency=1.0, crit_factor=1.0, enemy_armor=10, armor_effectiveness=0.6, WHEN damage calculated, THEN final_damage = max(1, 30 - 6) = 24.

**AC-09**: GIVEN fire_rate=2.0, WHEN cooldown reset, THEN cooldown_timer = 0.5 seconds.

**AC-10**: GIVEN attack_range=15.0, TARGETING_RANGE_MULT=2.0, WHEN targeting_range calculated, THEN targeting_range = 30.0 cells.

**AC-11**: GIVEN angle_difference=90°, rotation_speed=90°/sec, WHEN rotation time calculated, THEN rotation_time = 1.0 second.

### Edge Case Coverage

**AC-12**: GIVEN two turrets targeting same enemy, WHEN both fire simultaneously, THEN damage stacked, both `turret_fired` signals emitted.

**AC-13**: GIVEN target dies mid-flight, WHEN projectile arrives at last target position, THEN no damage applied, projectile despawns.

**AC-14**: GIVEN enemy armor=50, turret_damage=30, armor_effectiveness=0.8, WHEN damage calculated, THEN MINIMUM_DAMAGE floor=1 applied.

**AC-15**: GIVEN BEAM projectile with multiple enemies in path, WHEN fired, THEN damage applied to all enemies in line until max_range.

### System Integration Coverage

**AC-16**: GIVEN block_placed signal for turret_basic (200), WHEN received, THEN TurretEntity created at placed cell position.

**AC-17**: GIVEN `turret_fired` signal emitted, WHEN enemy damage system receives signal, THEN enemy health reduced by damage value.

**AC-18**: GIVEN spatial partition returns empty enemy list, WHEN turret processes frame, THEN state=IDLE, warning logged.

**AC-19**: GIVEN multiple turrets active (count=50), WHEN frame processed, THEN MAX_TURRETS_PER_FRAME limit applied, processing distributed across frames if count exceeds limit.

## Open Questions

1. **TurretTypeDatabase具体数据结构如何定义？**

   当前GDD引用TurretTypeDatabase扩展字段（damage, fire_rate, attack_range等），但未定义该数据库的存储方式。建议：在建造物品数据库(#5)中扩展build_item表，增加`turret_type_data`子表存储炮塔特定属性。或者新建独立TurretTypeDatabase GDD(#38.1)。

   → **待定**：Alpha阶段前需要定义TurretTypeDatabase结构。

2. **魔力发电机供给范围如何计算？**

   当前GDD定义MAGIC_RESERVE类型炮塔依赖魔力发电机供给，但未定义供给范围计算方式（GENERATOR_SUPPLY_RANGE常量待定义）。MVP阶段简化为：魔力型炮塔初始满值，射击消耗，无自动补给。Alpha阶段引入魔力发电机供给系统。

   → **MVP简化**：魔力型炮塔无自动补给，玩家需下车手动充能。

3. **炮塔修复机制具体参数如何定义？**

   当前GDD定义修复规则为"玩家下车状态下交互修复"，但repair_material_costs和repair_time_seconds参数未定义。建议：在建造物品数据库(#5)中增加`turret_repair_data`子表定义修复参数。或者设计独立的RepairSystem GDD(#39)处理所有修复逻辑（战车修复、炮塔修复、设施修复）。

   → **待定**：Alpha阶段前需要定义修复系统参数。

4. **多炮塔协同射击如何优化性能？**

   当前GDD定义MAX_TURRETS_PER_FRAME=50限制每帧处理炮塔数量。当活跃炮塔超过50座时，需要分布处理策略：每帧处理50座，剩余炮塔下一帧处理，可能导致火力输出不均匀。建议：引入炮塔优先级队列（距离敌人最近的炮塔优先处理），或分帧批处理策略。

   → **MVP简化**：50座炮塔上限足够覆盖大部分防守场景。大规模尸潮Alpha阶段需优化策略。