# 敌人类型数据库

> **Status**: Designed
> **Author**: [user + agents]
> **Last Updated**: 2026-04-22
> **Implements Pillar**: Pillar 3 (尸潮即高潮), Pillar 4 (魔导科技美学)

## Overview

敌人类型数据库是存储所有敌人类型定义的中央数据层。每个敌人类型包含唯一标识符、基础属性（血量、伤害、护甲、速度）、阵营归属、行为提示字段。该数据库为敌人AI系统、敌人生成系统、尸潮规模预估提供统一的数据接口，确保所有下游系统引用同一份敌人定义。

作为Foundation层系统，该数据库直接影响玩家对威胁多样性的感知：不同阵营敌人呈现不同的视觉风格（墓园/地狱/塔楼/元素），不同难度敌人创造 escalating challenge。这服务于Pillar 3（尸潮即高潮）——敌人设计必须产生真实压力；以及Pillar 4（魔导科技美学）——四大阵营必须有清晰的视觉标识。

**设计决策**：
- 使用Dictionary结构存储敌人定义（key = enemy_id, value = Dictionary of attributes）
- 采用Autoload singleton模式（extends Node），与BlockTypeDatabase、ResourceDatabase保持一致架构
- 提供`get_enemy_definition(enemy_id: int)`查询接口供下游系统调用

## Player Fantasy

玩家在尸潮中面对多种敌人类型，核心体验是**瞬间的威胁识别与战术响应**——看到敌人视觉特征，立即判断其威胁类型并执行正确对策。这种"猎人自信"的快感来自于：

- **阵营识别直觉**：骨骼质感 = 墓园阵营（耐久高，慢速推进）；火焰色调 = 地狱阵营（速度快，脆弱易杀）；金属光泽 = 塔楼阵营（护甲厚，需侧翼攻击）；晶石光芒 = 元素阵营（远程攻击，需躲避射击）
- **难度递进的紧张感**：每次尸潮解锁新敌人类型，玩家面对未知威胁时的"我能应付吗？"紧张，转化为击败后的"我学会了"成就感
- **视觉语言的可靠性**：敌人外观必须准确传达其威胁属性——大体型 = 高血量；发光武器 = 高伤害；符文护甲 = 需特殊对策

**锚定时刻**：尸潮中首次出现塔楼阵营重装骷髅，玩家在0.5秒内识别其金属护甲视觉特征，大脑快速调用"塔楼 = 侧翼攻击"的战术记忆，调整战车位置绕开正面碰撞。

**服务于支柱**：
- Pillar 3 (尸潮即高潮)：敌人多样性将尸潮从"数量压力"转化为"战术挑战"，让防守成为可精通的测试而非无脑消耗
- Pillar 4 (魔导科技美学)：四大阵营的视觉语言一致性让玩家通过外观即可判断威胁类型，强化世界观沉浸

## Detailed Design

### Core Rules

1. **数据存储架构**：敌人类型数据库采用Dictionary结构存储所有敌人定义，key为`enemy_id`（int），value为包含完整属性的Dictionary。该数据库作为Autoload singleton（extends Node）运行，与BlockTypeDatabase、ResourceDatabase保持一致架构。

2. **查询接口**：数据库提供以下查询方法供下游系统调用：
   - `get_enemy_definition(enemy_id: int) -> Dictionary` — 返回完整敌人属性
   - `get_enemies_by_faction(faction: int) -> Array[Dictionary]` — 返回指定阵营所有敌人
   - `get_enemies_by_unlock_day(day: int) -> Array[Dictionary]` — 返回指定天数解锁的敌人
   - `get_threat_score(enemy_id: int) -> int` — 返回威胁评分（用于尸潮规模预估）

3. **阵营分配规则**：四大阵营各有独立ID范围（墓园1000-1999，地狱2000-2999，塔楼3000-3999，元素4000-4999），确保ID查询可快速定位阵营归属。

4. **层级分配规则**：每个阵营内按层级细分ID范围（Basic=0-99偏移，Enhanced=100-199，Elite=200-299，Boss=300-399），公式：`enemy_id = FACTION_BASE + TIER_OFFSET + VARIANT_INDEX`。

5. **解锁时机规则**：每个敌人类型有`unlock_day`字段定义首次出现天数，尸潮生成系统必须检查该字段，未解锁敌人不得生成。

6. **行为提示规则**：`behavior_hint`字段定义8种AI行为模式（SWARM_CHARGE、WALL_BREAKER、TRACKER_HUNT、PATROL_GUARD、SNIPER_RANGE、AMBUSHER_HIDE、SUMMONER_CALL、SUPPORT_BUFF），敌人AI系统读取该字段决定行为逻辑。

### Data Structure Schema

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `enemy_id` | int | 0-65535 | — | 唯一标识符 |
| `name` | string | — | — | 内部标识名（如"graveyard_zombie_basic"） |
| `display_name` | string | — | — | UI显示名（如"腐烂丧尸"） |
| `faction` | int | 0-3 | — | 阵营枚举（GRAVEYARD/HELL/TOWER/ELEMENT） |
| `tier` | int | 1-5 | 1 | 层级（1=Basic, 2=Enhanced, 3=Elite, 4=Miniboss, 5=Boss） |
| `health` | int | 10-1000 | 50 | 基础血量 |
| `damage` | int | 1-100 | 5 | 每次攻击伤害 |
| `armor` | int | 0-80 | 0 | 减伤百分比（上限80%） |
| `speed` | float | 0.5-5.0 | 1.0 | 移动速度（格/秒） |
| `attack_range` | float | 0.5-10.0 | 1.5 | 攻击范围（格） |
| `attack_cooldown` | float | 0.5-5.0 | 1.0 | 攻击间隔（秒） |
| `behavior_hint` | int | 0-7 | 0 | AI行为模式枚举 |
| `size_category` | int | 0-2 | 0 | 视觉体型（0=Normal, 1=Large, 2=Huge） |
| `unlock_day` | int | 1-30 | 1 | 解锁天数 |
| `spawn_weight` | float | 0.1-10.0 | 1.0 | 尸潮生成权重 |
| `threat_score` | int | 1-100 | 10 | 威胁评分（用于尸潮规模预估） |
| `special_ability` | int | 0-15 | 0 | 特殊能力枚举 |
| `wall_damage_multiplier` | float | 0.5-3.0 | 1.0 | 对墙体伤害倍率 |
| `drop_resource_id` | int | 0-65535 | 0 | 死亡掉落资源ID（引用ResourceDatabase） |
| `drop_chance` | float | 0.0-1.0 | 0.0 | 掉落概率 |

### Enumeration Definitions

#### Faction Enum

| Value | Name | Visual Theme | Primary Color | Secondary Color |
|-------|------|--------------|---------------|-----------------|
| 0 | `GRAVEYARD` | 骨骼与死亡（虫族有机质感） | 灰白 #808080 | 腐烂绿 #4A7C4A |
| 1 | `HELL` | 火焰与恶魔（克苏鲁宇宙恐怖） | 暗红 #8B0000 | 火焰橙 #FF4500 |
| 2 | `TOWER` | 机械与金属（锈蚀残留机械） | 金属银 #C0C0C0 | 电路蓝 #0080FF |
| 3 | `ELEMENT` | 晶石与光芒（天气绑定元素） | 晶石紫 #800080 | 光芒金 #FFD700 |

#### Tier Enum

| Value | Name | HP Range | Spawn Weight | Role in Tide |
|-------|------|----------|--------------|--------------|
| 1 | `BASIC` | 10-50 | High (1.0-3.0) | 尸潮主力，数量压制 |
| 2 | `ENHANCED` | 50-100 | Medium (0.5-1.0) | 压力递增 |
| 3 | `ELITE` | 100-200 | Low (0.2-0.5) | 优先处理威胁 |
| 4 | `MINIBOSS` | 200-400 | Very Low (0.05-0.1) | 波次高潮 |
| 5 | `BOSS` | 400-1000 | Unique | 里程碑尸潮终局 |

#### Behavior Hint Enum

| Value | Name | Description | AI Implementation Hint |
|-------|------|-------------|------------------------|
| 0 | `SWARM_CHARGE` | 集群冲锋 | 向最近玩家/防御设施移动，接触时攻击 |
| 1 | `WALL_BREAKER` | 拆墙攻城 | 优先攻击墙体/结构，忽略玩家 |
| 2 | `TRACKER_HUNT` | 追踪猎杀 | 追踪战车，优先移动目标 |
| 3 | `PATROL_GUARD` | 规律巡逻 | 按模式移动，玩家进入范围时交战 |
| 4 | `SNIPER_RANGE` | 远程狙击 | 保持攻击距离，远程射击 |
| 5 | `AMBUSHER_HIDE` | 伏击埋伏 | 隐藏等待，玩家接近时攻击 |
| 6 | `SUMMONER_CALL` | 召唤增援 | 定期召唤额外敌人 |
| 7 | `SUPPORT_BUFF` | 辅助增强 | 增强附近敌人，保持后线位置 |

### Initial Enemy Catalog (MVP: 11 Types)

#### Day 1-5: 墓园阵营

| ID | Name | Display | Tier | HP | DMG | Armor | Speed | Behavior | Unlock | SpawnWt |
|----|------|---------|------|----|-----|-------|-------|----------|--------|---------|
| 1000 | `graveyard_zombie_basic` | "腐烂丧尸" | 1 | 30 | 5 | 0 | 0.8 | SWARM_CHARGE | Day 1 | 3.0 |
| 1001 | `graveyard_zombie_runner` | "冲刺丧尸" | 1 | 20 | 8 | 0 | 1.5 | SWARM_CHARGE | Day 1 | 1.5 |
| 1100 | `graveyard_skeleton_basic` | "骨骼骷髅" | 2 | 60 | 10 | 5 | 0.6 | WALL_BREAKER | Day 3 | 1.0 |
| 1101 | `graveyard_skeleton_archer` | "骷髅弓手" | 2 | 40 | 15 | 0 | 0.5 | SNIPER_RANGE | Day 4 | 0.8 |
| 1200 | `graveyard_bone_knight` | "骨甲骑士" | 3 | 150 | 25 | 20 | 0.7 | WALL_BREAKER | Day 10 | 0.3 |

#### Day 6-10: 地狱阵营

| ID | Name | Display | Tier | HP | DMG | Armor | Speed | Behavior | Unlock | SpawnWt |
|----|------|---------|------|----|-----|-------|-------|----------|--------|---------|
| 2000 | `hell_imp_basic` | "地狱小鬼" | 1 | 15 | 12 | 0 | 2.5 | TRACKER_HUNT | Day 6 | 2.0 |
| 2001 | `hell_fire_sprite` | "火焰精灵" | 1 | 10 | 8 | 0 | 3.0 | SWARM_CHARGE | Day 6 | 2.5 |
| 2100 | `hell_demon_runner` | "恶魔猎手" | 2 | 35 | 20 | 0 | 2.0 | TRACKER_HUNT | Day 7 | 1.0 |
| 2101 | `hell_explosion_imp` | "爆裂小鬼" | 2 | 25 | 15 | 0 | 1.8 | SWARM_CHARGE | Day 8 | 0.6 |

#### Day 11-12: 塔楼阵营预览

| ID | Name | Display | Tier | HP | DMG | Armor | Speed | Behavior | Unlock | SpawnWt |
|----|------|---------|------|----|-----|-------|-------|----------|--------|---------|
| 3000 | `tower_scrap_drone` | "废料无人机" | 1 | 40 | 10 | 15 | 1.2 | SNIPER_RANGE | Day 11 | 1.0 |

### States and Transitions

敌人类型数据库本身无状态转换。各敌人类型的`state`概念由敌人AI系统管理，而非本数据库定义。本数据库仅提供静态属性定义。

### Interactions with Other Systems

| System | Direction | Interface | Data Flow |
|--------|-----------|-----------|-----------|
| **敌人AI系统** | Outbound | `get_enemy_definition(enemy_id)` → `behavior_hint`, `speed`, `attack_range` | AI系统读取behavior_hint决定行为逻辑，读取速度/攻击范围参数 |
| **敌人生成系统** | Outbound | `get_enemies_by_unlock_day(day)` → `spawn_weight`, `faction` | 生成系统查询当天解锁敌人，按spawn_weight生成 |
| **尸潮规模预估** | Outbound | `get_threat_score(enemy_id)` → `threat_score` | 预估系统累加所有生成敌人的threat_score计算总威胁 |
| **炮塔系统** | Outbound | `get_enemy_definition(enemy_id)` → `armor`, `speed` | 炮塔系统读取护甲决定伤害计算，读取速度决定瞄准 |
| **ResourceDatabase** | Inbound | `drop_resource_id` → 引用ResourceDatabase定义 | 敌人掉落资源ID需在ResourceDatabase中有对应定义 |

## Formulas

### Damage Calculation Formula

`actual_damage = weapon_damage × (1 - enemy_armor%)`

**Variables:**
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `weapon_damage` | int | 5-100 | 武器基础伤害 |
| `enemy_armor` | int | 0-80 | 敌人护甲百分比 |

**Output Range**: 5-100 伤害（护甲0%时全伤，护甲80%时减伤至20%）
**Example**: weapon_damage=50, enemy_armor=30 → actual_damage = 50 × 0.7 = 35

### Shots-to-Kill Formula

`shots_to_kill = ceil(enemy_health / actual_damage)`

**Variables:**
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `enemy_health` | int | 10-1000 | 敌人血量 |
| `actual_damage` | int | 5-100 | 计算后伤害 |

**Output Range**: 1-200 shots（Boss级高血量需更多射击）
**Example**: enemy_health=150, actual_damage=35 → shots_to_kill = ceil(150/35) = 5

### Threat Score Formula

`threat_score = floor(health × 0.1 + damage × 1.0 + armor × 0.5 + speed × 10.0)`

**Variables:**
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `health` | int | 10-1000 | 敌人血量 |
| `damage` | int | 1-100 | 敌人伤害 |
| `armor` | int | 0-80 | 敌人护甲 |
| `speed` | float | 0.5-5.0 | 敌人速度 |

**Output Range**: 1-100 威胁评分（用于尸潮规模预估）
**Example**: health=150, damage=25, armor=20, speed=0.7 → threat_score = 15 + 25 + 10 + 7 = 57

### Faction Stat Modifier Rules

阵营决定基础属性倾向，用于敌人类型设计参考而非实时计算：

| Faction | HP Modifier | Damage Modifier | Armor Modifier | Speed Modifier | Behavior Bias |
|---------|-------------|-----------------|----------------|----------------|---------------|
| `GRAVEYARD` | ×1.5 | ×1.0 | ×1.3 | ×0.7 | 耐久高，慢速推进 |
| `HELL` | ×0.7 | ×1.5 | ×0.5 | ×1.4 | 速度快，脆弱易杀 |
| `TOWER` | ×1.2 | ×1.0 | ×2.0 | ×0.9 | 护甲厚，侧翼攻击 |
| `ELEMENT` | ×0.9 | ×1.3 | ×0.8 | ×1.0 | 远程攻击，躲避射击 |

### Tier Stat Multiplier Rules

层级决定属性倍率，用于敌人类型设计参考：

| Tier | HP Mult | Damage Mult | Armor Mult | Speed Mult | Threat Mult |
|------|---------|-------------|------------|------------|-------------|
| `BASIC` | ×1.0 | ×1.0 | ×1.0 | ×1.0 | ×1.0 |
| `ENHANCED` | ×1.5 | ×1.2 | ×1.5 | ×1.1 | ×1.5 |
| `ELITE` | ×2.5 | ×1.5 | ×2.0 | ×1.2 | ×2.5 |
| `MINIBOSS` | ×4.0 | ×2.0 | ×3.0 | ×1.0 | ×4.0 |
| `BOSS` | ×6.0 | ×2.5 | ×4.0 | ×0.9 | ×6.0 |

## Edge Cases

### Stat Boundary Cases

- **If health < 10**: Reject enemy definition with error "health below minimum (10)". An enemy with near-zero health cannot function in gameplay—would die instantly, breaking threat perception.
- **If health > 1000**: Clamp to 1000 and log warning. Threat score formula calibrated for max 1000; values beyond produce threat scores outside valid range.
- **If armor > 80**: Clamp to 80 and log warning. Armor above 80% makes enemy nearly invulnerable, violating "every threat has counter" principle.
- **If armor < 0**: Set armor = 0 and log warning. Negative armor mathematically amplifies damage, contradicting armor semantics.
- **If speed < 0.5**: Clamp to 0.5 and log warning. Extremely slow enemies reduce threat perception and may cause pathfinding issues.
- **If speed > 5.0**: Clamp to 5.0 and log warning. Speed above 5 exceeds player reaction capability, creating unfair encounters.
- **If damage = 0**: Reject enemy definition with error "damage must be at least 1". An enemy that cannot damage is not a threat, breaking Pillar 3.
- **If damage > 100**: Clamp to 100 and log warning. Damage above 100 would require >100 health for Boss tier, exceeding health ceiling.

### Invalid ID Query Cases

- **If enemy_id not in database**: Return `null` for `get_enemy_definition()`. For property queries, return defaults: faction=0, tier=1, health=50, damage=5, armor=0, speed=1.0, threat_score=10. Downstream systems must not crash on missing data.
- **If enemy_id = 0**: Return predefined `NULL_ENEMY_DEFINITION` with name="null_enemy", display_name="无效敌人", all stats at defaults. ID 0 reserved as explicit null indicator.
- **If enemy_id < 0**: Return null and log warning "Invalid enemy_id (negative)". Negative IDs indicate corrupted data.
- **If enemy_id > 65535**: Return null and log warning. IDs beyond 16-bit range cannot be stored in declared schema type.

### Faction/Tier Mismatch Cases

- **If enemy_id suggests GRAVEYARD (1000-1999) but faction field differs**: Log warning "ID-range/faction mismatch". Return definition as-is. Mismatch indicates design error; runtime does not auto-correct.
- **If enemy_id suggests tier BASIC (offset 0-99) but tier field differs**: Log warning. Return definition as-is. Mismatch breaks visual-to-stat mapping expectations.

### Unlock Day Cases

- **If unlock_day = 0**: Reject enemy definition with error "unlock_day must be >= 1". Day 0 does not exist in game calendar.
- **If unlock_day > 30**: Accept definition and log warning "unlock_day exceeds max content day, enemy will not spawn in MVP". Supports future expansion.
- **If get_enemies_by_unlock_day(day) receives day < 1**: Return empty array `[]`. Invalid day query.
- **If spawn system requests enemies for day where none are unlocked**: Return empty array. Content gap indication.

### Spawn Weight Cases

- **If spawn_weight = 0**: Accept and log debug "enemy will never spawn naturally". Valid for event-only/special encounter enemies.
- **If spawn_weight < 0**: Clamp to 0.0 and log warning. Negative weight produces invalid probability.
- **If spawn_weight > 10.0**: Clamp to 10.0 and log warning. Excessive weight dominates spawn selection, breaking threat diversity.

### Drop Resource Cases

- **If drop_resource_id references non-existent ResourceDatabase entry**: Log warning, enemy drops nothing. Missing reference does not crash spawning.
- **If drop_resource_id = 0**: Enemy drops no resource (valid configuration). ID 0 is NULL_RESOURCE indicator.
- **If drop_chance > 1.0**: Clamp to 1.0 (100%) and log warning. Probability cannot exceed 100%.
- **If drop_chance < 0.0**: Clamp to 0.0 and log warning. Negative probability invalid.

### Threat Score Cases

- **If threat_score formula produces > 100**: Clamp to 100 and log debug. Threat range 1-100 calibrated for tide estimation.
- **If threat_score formula produces < 1**: Set to 1 (minimum) and log debug. All enemies must contribute minimum threat.
- **If get_threat_score(invalid_enemy_id)**: Return default threat_score = 10 and log warning. Invalid query returns safe placeholder.
- **If stored threat_score differs from formula result**: Use stored value (designer override is authoritative).

## Dependencies

敌人类型数据库是Foundation层系统，无上游依赖。所有依赖关系为下游输出。

### Upstream Dependencies (None)

本系统无上游依赖。敌人属性定义为基础数据层，不依赖其他系统。

### Downstream Dependencies (Systems that depend on this)

| System | Dependency Type | Interface Used | Status |
|--------|-----------------|----------------|--------|
| **敌人AI系统** | Hard | `get_enemy_definition()` → `behavior_hint`, `speed`, `attack_range`, `attack_cooldown` | Not Started |
| **敌人生成系统** | Hard | `get_enemies_by_unlock_day()`, `get_enemies_by_faction()`, `spawn_weight` | Not Started |
| **尸潮规模预估** | Hard | `get_threat_score()` → threat_score summation | Not Started |
| **炮塔系统** | Soft | `get_enemy_definition()` → `armor`, `speed` for targeting/damage calc | Not Started |
| **陷阱系统** | Soft | `get_enemy_definition()` → `speed` for trigger timing | Not Started |
| **ResourceDatabase** | Cross-Reference | `drop_resource_id` → ResourceDatabase definition lookup | Designed |

**Dependency Nature**:
- **Hard dependency**: Downstream system cannot function without this database (Enemy AI needs behavior_hint, Spawning needs unlock_day/threat filters)
- **Soft dependency**: Downstream system functions but is enhanced by this database (Turret targeting improves with enemy speed data)
- **Cross-reference**: ID reference that must exist in another database (drop_resource_id must match ResourceDatabase entry)

### Bidirectional Check

| Dependency | Listed Here | Listed in Target | Status |
|------------|-------------|------------------|--------|
| Enemy AI → EnemyTypeDatabase | ✓ Listed as Hard | — Target GDD not written | Pending |
| Enemy Spawning → EnemyTypeDatabase | ✓ Listed as Hard | — Target GDD not written | Pending |
| Tide Estimation → EnemyTypeDatabase | ✓ Listed as Hard | — Target GDD not written | Pending |
| Turret → EnemyTypeDatabase | ✓ Listed as Soft | — Target GDD not written | Pending |
| EnemyTypeDatabase → ResourceDatabase | ✓ Listed as Cross-Ref | ResourceDatabase does NOT list this (inbound ref only) | Correct |

**Note**: ResourceDatabase is inbound reference only—it does not depend on EnemyTypeDatabase, it merely defines resource IDs that EnemyTypeDatabase may reference. Bidirectional listing is not required for inbound-only references.

## Tuning Knobs

### Global Tuning Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `global_hp_multiplier` | 1.0 | 0.5-2.0 | Overall difficulty slider | ×0.5 = easier tides, ×2.0 = brutal survival |
| `global_damage_multiplier` | 1.0 | 0.5-2.0 | Player survival tuning | ×0.5 = forgiving combat, ×2.0 = lethal encounters |
| `global_armor_multiplier` | 1.0 | 0.5-2.0 | Armor effectiveness | ×0.5 = armor-piercing mode, ×2.0 = tank meta |

### Faction Tuning Knobs

| Knob | Default | Purpose | Effect on Gameplay |
|------|---------|---------|-------------------|
| `graveyard_hp_mult` | 1.5 | 墓园耐久倾向 | Higher = tankier Graveyard, longer tides |
| `graveyard_speed_mult` | 0.7 | 墓园慢速倾向 | Lower = slower push, more time to react |
| `hell_hp_mult` | 0.7 | 地狱脆弱倾向 | Lower = easier kills, but fast approach |
| `hell_speed_mult` | 1.4 | 地狱快速倾向 | Higher = rush threat, less reaction time |
| `tower_armor_mult` | 2.0 | 塔楼护甲倾向 | Higher = armor-piercing weapons required |
| `element_range_mult` | 2.5 | 元素远程倾向 | Higher = sniping enemies, priority targets |

### Tier Tuning Knobs

| Knob | Default | Purpose | Effect on Tide Composition |
|------|---------|---------|---------------------------|
| `basic_hp_mult` | 1.0 | Basic enemy baseline | Foundation for tier scaling |
| `basic_spawn_weight_base` | 70.0 | Basic spawn ratio | Higher = mass swarm tides |
| `elite_hp_mult` | 2.5 | Elite health jump | Higher = priority targets tankier |
| `elite_damage_mult` | 1.5 | Elite damage increase | Higher = elites more lethal |
| `boss_hp_mult` | 6.0 | Boss health pool | Higher = longer boss fights |
| `boss_armor_mult` | 4.0 | Boss armor scaling | Higher = boss armor-piercing requirement |

### Spawn Composition Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `basic_spawn_ratio` | 70% | 50-85% | Tide mass composition | 85% = swarm meta, 50% = elite-heavy |
| `elite_spawn_ratio` | 20% | 10-30% | Elite presence | 30% = high-threat tides |
| `boss_spawn_ratio` | 10% | 5-15% | Boss/miniboss presence | 15% = boss every wave |

### Threat Score Knobs

| Knob | Default | Purpose | Formula Impact |
|------|---------|---------|----------------|
| `threat_health_weight` | 0.1 | HP contribution to threat | Higher = tanky enemies score higher |
| `threat_damage_weight` | 1.0 | Damage contribution | Higher = lethal enemies score higher |
| `threat_armor_weight` | 0.5 | Armor contribution | Higher = armored enemies score higher |
| `threat_speed_weight` | 10.0 | Speed contribution | Higher = fast enemies score higher |

### Knob Interactions

- **`graveyard_hp_mult` × `global_hp_multiplier`** — Combined effect on Graveyard enemy health
- **`elite_damage_mult` × `global_damage_multiplier`** — Combined elite damage scaling
- **`basic_spawn_ratio + elite_spawn_ratio + boss_spawn_ratio`** — Must sum to 100% for spawn system balance
- **`threat_*_weight` knobs** — Changing relative weights changes tide estimation priorities (fast vs tanky)

## Visual/Audio Requirements

### Faction Visual Archetypes

每个阵营的敌人必须拥有独特的视觉原型，确保玩家能在0.5秒内从视觉特征识别威胁类型并调用战术记忆。

| 阵营 | 视觉原型 (1-2句) | 核心识别特征 | 战术含义传达 |
|------|------------------|--------------|--------------|
| **墓园 (虫族风格)** | 虫族有机质感+克苏鲁腐化变异的亡灵生物——蠕动的肢体、粘液覆盖、蜂巢结构组合。 | **剪影**: 蠕动的人形轮廓 + 粘液滴落<br>**材质**: 有机生物质感 + 骨骼残留<br>**配件**: 触须伸出伤口 + 蜂巢纹路 | 腐烂绿 = 高耐久慢速推进，需持续火力覆盖 |
| **地狱 (克苏鲁风格)** | 克苏鲁宇宙恐怖的恶魔生物——触手+眼球组合、扭曲维度轮廓、不可名状的深渊形态。 | **剪影**: 触手眼球组合 + 扭曲轮廓<br>**材质**: 虚空有机质感 + 火焰附着<br>**配件**: 多眼球组合 + 触手森林 | 深渊紫黑 = 高伤害快速突袭，评估撤退时机 |
| **塔楼 (锈蚀机械)** | 锈蚀残留的废土机械——方形锈蚀轮廓、破损金属边角、损坏AI的规律行为。 | **剪影**: 锈蚀方块机械 + 破损边角<br>**材质**: 锈铁质感 + 破损金属<br>**配件**: 残留电路 + 破损武器 | 锈铁色 = 高护甲需侧翼攻击，次要威胁 |
| **元素 (天气绑定)** | 晶石光芒的元素生物——晶石形状、光芒放射、天气元素动态附着。 | **剪影**: 晶石几何形状 + 光芒放射<br>**材质**: 晶石发光质感<br>**配件**: 天气元素附着（火/冰/风） | 晶石紫 = 远程攻击需躲避射击，天气相关 |

### Tier Visual Progression (Basic → Elite → Boss)

每个阵营的敌人类型必须通过视觉层级表达难度递进——玩家必须能从外观一眼判断"这是普通敌人还是精英威胁"。

#### 墓园势力层级

| 层级 | 视觉规模 | 视觉复杂度 | 独特标识 | 识别规则 |
|------|----------|------------|----------|----------|
| **Basic (骷髅兵/丧尸)** | 小型 (16-32px) | 简化轮廓：人形骨骼/腐烂肉体 + 轻度虫族变异（粘液） | 无独特发光，灰白+腐烂绿基础色 | 小型蠕动 = 低威胁，基础火力可处理 |
| **Elite (尸巫/变异丧尸)** | 中型 (32-48px) | 增强轮廓：法袍下触须伸出/肢体重度变异 + 独特配件（眼球组合） | 轮廓增强发光（腐烂绿边缘光） + 独特形状（法袍/触须） | 中型触须眼球 = 高威胁，需优先处理 |
| **Boss (蜂巢母体/鬼龙)** | 大型-极大 (48-96px+) | 极复杂轮廓：触手森林+眼球组合（母体）/腐化龙形+触须覆盖（鬼龙） | 全身发光脉动 + 独特BOSS光环（深渊紫黑外圈） + 多阶段视觉变化 | 大型触手眼球 = BOSS级，全队集中火力 |

#### 地狱势力层级

| 层级 | 视觉规模 | 视觉复杂度 | 独特标识 | 识别规则 |
|------|----------|------------|----------|----------|
| **Basic (小鬼)** | 小型 (16-32px) | 简化轮廓：触手+小眼球组合 | 无独特发光，火焰橙+深渊紫黑基础色 | 小型触手 = 快速脆弱，快速清除 |
| **Elite (恶魔)** | 中型 (32-48px) | 增强轮廓：多触手+中等眼球组合 + 扭曲肢体增强 | 触手末端火焰橙发光 + 眼球注视光束 | 中型眼球注视 = 追踪攻击，需躲避 |
| **Boss (深渊领主/大恶魔)** | 大型-极大 (48-96px+) | 极复杂轮廓：触手森林+大眼球组合 + 维度扭曲轮廓 | 全身深渊紫黑脉动 + 维度扭曲光环（空间颤动） + 眼球凝视光束强化 | 大型触手森林 = BOSS级，准备撤退决策 |

#### 塔楼势力层级

| 层级 | 视觉规模 | 视觉复杂度 | 独特标识 | 识别规则 |
|------|----------|------------|----------|----------|
| **Basic (巡逻机器人)** | 小型 (16-32px) | 简化轮廓：锈蚀方块 + 破损边角 | 无独特发光，锈铁色+破损蓝基础色 | 小型锈方块 = 次要威胁，可忽略 |
| **Elite (魔像)** | 中型 (32-48px) | 增强轮廓：锈蚀大型方块 + 装甲板凸起 + 残留武器 | 破损蓝边缘发光（弱） + 装甲板轮廓高亮 | 中型装甲方块 = 高护甲，需侧翼绕开 |
| **Boss (泰坦/主脑)** | 大型-极大 (48-96px+) | 极复杂轮廓：锈蚀巨大方块+残留武器（泰坦）/锈蚀核心+残留电路（主脑） | 残留霓虹蓝脉冲（弱） + BOSS光环（锈铁灰外圈） + 电路残留闪光 | 大型锈方块 = BOSS级（次要），火力覆盖 |

#### 元素势力层级

| 层级 | 视觉规模 | 视觉复杂度 | 独特标识 | 识别规则 |
|------|----------|------------|----------|----------|
| **Basic (小型元素)** | 小型 (16-32px) | 简化轮廓：晶石几何形状 + 单一天气元素附着 | 晶石基础发光（霓虹蓝/晶石紫） | 小型晶石 = 低威胁远程，躲避射击 |
| **Elite (中型元素)** | 中型 (32-48px) | 增强轮廓：多晶石组合 + 多天气元素附着 + 光芒放射增强 | 晶石光芒放射增强 + 天气元素特效附着（火/冰/风） | 中型晶石光芒 = 高威胁远程，优先躲避 |
| **Boss (古龙)** | 大型-极大 (48-96px+) | 极复杂轮廓：龙形+晶石覆盖 + 全身光芒放射 + 天气绑定动态变化 | 全身晶石脉动 + 天气绑定光环 + 元素风暴特效 | 大型龙形晶石 = BOSS级，天气影响战斗 |

### Visual-to-Stat Mapping Rules

敌人外观必须准确传达其数值属性——玩家不应需要查看数值界面来判断威胁程度。

#### 规则定义

| 视觉特征 | 数值含义 | 传达规则 | 设计测试 |
|----------|----------|----------|----------|
| **体型规模** | HP血量 | 大体型 = 高血量（直观物理直觉）<br>规则: Basic 16-32px → Elite 32-48px → Boss 48-96px+ | 如果大型敌人HP很低，它违反此规则 |
| **发光武器/攻击部位** | 攻击伤害 | 发光强度 = 伤害等级<br>无发光 = 低伤害（基础）<br>边缘发光 = 中伤害（Elite）<br>全身脉动 = 高伤害（Boss） | 如果发光敌人伤害很低，它违反此规则 |
| **装甲板/护甲轮廓** | 护甲值 | 装甲板凸起 = 有护甲<br>装甲板厚度 = 护甲等级<br>锈蚀装甲 = 破损护甲（塔楼特色） | 如果无装甲视觉的敌人有高护甲，它违反此规则 |
| **速度指示器** | 移动速度 | 轮廓动态感 = 速度暗示<br>僵硬方正轮廓 = 慢速（塔楼）<br>扭曲蠕动轮廓 = 中速（墓园）<br>流畅触手轮廓 = 快速（地狱） | 如果僵硬轮廓敌人移动很快，它违反此规则 |
| **攻击方式指示器** | 攻击类型 | 武器轮廓 = 近战（肢体/触手）<br>光芒放射 = 远程（晶石/眼球）<br>自爆特征 = 自爆（小鬼火焰包裹） | 如果远程视觉的敌人是近战，它违反此规则 |

#### 阵营-属性视觉关联

| 阵营 | HP视觉传达 | 伤害视觉传达 | 护甲视觉传达 | 速度视觉传达 |
|------|------------|--------------|--------------|--------------|
| **墓园** | 蠕动肉体质感厚度 = HP<br>蜂巢结构覆盖 = 高HP | 触须末端腐烂绿发光 = 伤害<br>眼球组合凝视光束 = 高伤害 | 无明显装甲（虫族无装甲概念）<br>粘液层 = 轻度防护 | 踉跄蠕动轮廓 = 中慢速<br>蜂巢集群 = 冲锋加速 |
| **地狱** | 触手数量/厚度 = HP<br>维度扭曲程度 = 高HP（Boss） | 眼球组合注视光束 = 伤害<br>火焰橙发光强度 = 高伤害 | 无装甲（虚空生物）<br>维度扭曲 = 减伤效果 | 扭曲流畅轮廓 = 快速<br>触手伸展 = 追踪加速 |
| **塔楼** | 锈蚀方块厚度 = HP<br>装甲板层数 = 高HP | 残留武器轮廓 = 伤害<br>电路残留闪光 = 高伤害 | 装甲板凸起 = 护甲核心<br>装甲厚度 = 护甲等级 | 梯形方块轮廓 = 慢速<br>规律移动 = 恒定速度 |
| **元素** | 晶石大小 = HP<br>晶石组合数量 = 高HP | 晶石光芒放射强度 = 伤害<br>天气元素特效 = 高伤害 | 无装甲（晶石生物）<br>晶石硬度 = 自然护甲 | 晶石悬浮轮廓 = 中速<br>天气绑定速度 = 动态变化 |

#### 色盲友好规则

不单独依赖颜色传达数值信息，必须有形状/纹理备份：

| 数值属性 | 颜色指示 | 形状备份指示 | 组合识别 |
|----------|----------|--------------|----------|
| **高HP** | 轮廓发光颜色更深 | 体型规模增大 + 装甲板增厚 | 大体型+厚装甲 = 高HP（不依赖颜色） |
| **高伤害** | 武器发光强度更高 | 攻击部位更大 + 独特攻击特征 | 大攻击部位+独特发光 = 高伤害 |
| **高护甲** | 装甲板颜色更亮 | 装甲板凸起轮廓更明显 | 明显装甲凸起 = 有护甲（不依赖颜色） |
| **高速度** | 轮廓颜色更活跃 | 轮廓流畅度更高 + 动态肢体 | 流畅轮廓+动态肢体 = 快速 |

### VFX Requirements List

#### 死亡效果 (Death VFX)

每个阵营必须有独特的死亡效果，强化阵营视觉识别并提供击杀反馈。

| 阵营 | 死亡效果 | VFX元素 | 持续时间 | 音效配合 |
|------|----------|----------|----------|----------|
| **墓园** | 有机崩溃 → 粘液扩散 | 肢体蠕动崩溃动画 + 腐烂绿粘液粒子扩散 + 蜂巢碎片飞散 | 0.8s | 虫族崩溃声 + 粘液溅射声 |
| **地狱** | 维度消散 → 深渊吸入 | 触手眼球消散动画 + 深渊紫黑粒子吸入效果 + 空间扭曲残留 | 1.0s（更长恐怖感） | 深渊吸入声 + 低频震颤 |
| **塔楼** | 机械解体 → 锈蚀崩溃 | 锈蚀方块解体动画 + 锈铁粒子飞散 + 电路残留火花 | 0.5s（简短次要威胁） | 机械崩溃声 + 电路短路声 |
| **元素** | 晶石粉碎 → 光芒消散 | 晶石粉碎动画 + 光芒粒子消散 + 天气元素残留特效 | 0.6s | 晶石粉碎声 + 元素消散声 |

#### 层级死亡效果差异

| 层级 | 死亡效果规模 | 粒子数量 | 屏幕影响 |
|------|--------------|----------|----------|
| **Basic** | 小规模崩溃 | 8-16粒子 | 无屏幕影响 |
| **Elite** | 中规模崩溃 + 轻微屏幕震动 | 16-32粒子 + 轻微ScreenShake | 短暂ScreenShake (0.1s) |
| **Boss** | 大规模崩溃 + 强屏幕震动 + 全屏闪光 | 32-64粒子 + 强ScreenShake + 全屏闪光 | ScreenShake (0.3s) + 全屏闪光 |

#### 攻击效果 (Attack VFX)

每个阵营必须有独特的攻击效果，传达攻击类型和伤害等级。

| 阵营 | 近战攻击 | 远程攻击 | 特殊攻击 |
|------|----------|----------|----------|
| **墓园** | 肢体挥击 → 腐烂绿粘液飞溅<br>触须伸出 → 粘液缠绕效果 | 无远程（近战为主）<br>尸巫魔法 → 腐烂绿魔法光束 | 蜂巢召唤 → 小型虫族生成特效<br>粘液陷阱 → 地面粘液区域 |
| **地狱** | 触手挥击 → 深渊紫黑鞭痕<br>眼球凝视 → 精神攻击光束 | 眼球射出 → 深渊紫黑能量弹<br>触手射出 → 虚空能量束 | 自爆（小鬼） → 火焰橙爆炸球<br>维度撕裂 → 空间裂缝特效 |
| **塔楼** | 机械撞击 → 锈铁碰撞火花<br>残留武器攻击 → 锈蚀弹道 | 残留炮击 → 锈铁色弹道<br>电路射线 → 破损蓝能量线 | 警报呼叫 → 召唤其他机械<br>过载攻击 → 电路火花爆炸 |
| **元素** | 晶石撞击 → 光芒碰撞闪光<br>天气元素攻击 → 火焰/冰霜/风暴附着 | 晶石射出 → 霓虹蓝/晶石紫能量弹<br>元素射出 → 天气元素弹道 | 天气绑定攻击 → 天气增强攻击效果<br>元素风暴 → 区域元素特效 |

#### 层级攻击效果差异

| 层级 | 攻击效果规模 | 发光强度 | 屏幕影响 |
|------|--------------|----------|----------|
| **Basic** | 小规模攻击效果 | 边缘发光（弱） | 无屏幕影响 |
| **Elite** | 中规模攻击效果 + 轻微屏幕震动 | 边缘发光增强 + 攻击部位高亮 | 攻击时ScreenShake (0.05s) |
| **Boss** | 大规模攻击效果 + 强屏幕震动 | 全身脉动 + 攻击部位强发光 | 攻击时ScreenShake (0.15s) + 闪光 |

#### Elite Glow (精英发光标识)

所有Elite级敌人必须有独特的发光标识，确保玩家能快速识别精英威胁。

| 阵营 | Elite Glow效果 | Glow位置 | Glow颜色 | 动态特征 |
|------|-----------------|----------|----------|----------|
| **墓园** | 轮廓边缘腐烂绿发光 + 触须末端高亮 | 全身轮廓边缘 + 触须末端 | 腐烂绿 #556B2F | 蠕动脉动 (频率0.5s) |
| **地狱** | 触手末端火焰橙发光 + 眼球注视光束 | 触手末端 + 眼球组合 | 火焰橙 #FF6B35 | 眼球追踪玩家 (动态光束) |
| **塔楼** | 装甲板边缘破损蓝发光 + 电路残留闪光 | 装甲板边缘 + 残留电路 | 破损蓝 #4A6B8A | 电路脉冲 (频率1s，低调) |
| **元素** | 晶石光芒放射增强 + 天气元素附着 | 晶石全身 + 天气元素附着位置 | 晶石紫 + 天气色 | 天气绑定动态变化 |

#### Boss Aura (Boss光环标识)

所有Boss级敌人必须有独特的光环标识，确保玩家能立即识别BOSS级威胁并调整战术。

| 阵营 | Boss Aura效果 | Aura位置 | Aura颜色 | 动态特征 |
|------|-----------------|----------|----------|----------|
| **墓园** | 深渊紫黑外圈光环 + 触手森林脉动 | 全身外圈 + 触手森林区域 | 深渊紫黑 #1A0A2E | 触手脉动 + 光环扩散 (频率1s) |
| **地狱** | 维度扭曲光环 + 眼球森林注视光束 | 全身外圈 + 眼球组合区域 | 深渊紫黑 #1A0A2E + 火焰橙残留 | 空间颤动 + 眼球追踪 (恐怖感) |
| **塔楼** | 锈铁灰外圈光环 + 电路残留脉冲 | 全身外圈 + 核心电路区域 | 锈铁灰 #5C5C5C | 电路脉冲 (低调，次要威胁) |
| **元素** | 天气绑定光环 + 元素风暴特效 | 全身外圈 + 天气元素区域 | 晶石紫 + 天气色 | 天气绑定动态变化 + 元素风暴 |

### Animation/Movement Style Differences

每个阵营必须有独特的动画和移动风格，通过动态特征强化阵营识别。

#### 基础移动风格

| 阵营 | 移动风格 | 动画特征 | 速度感传达 | 阵营叙事 |
|------|----------|----------|------------|----------|
| **墓园** | 踉跄蠕动 | 肢体蠕动动画 + 踉跄步态 + 伤口触须蠕动 | 中慢速推进感 | "被腐化的亡灵，蠕动前进" |
| **地狱** | 扭曲追踪 | 触手伸展动画 + 扭曲移动 + 眼球追踪 | 快速追踪感 | "深渊的生物，追踪猎物" |
| **塔楼** | 规律机械 | 机械步态动画 + 规律移动 + 锈蚀卡顿 | 慢速恒定感 | "损坏的AI，规律残留" |
| **元素** | 悬浮晶石 | 晶石悬浮动画 + 天气绑定移动 + 光芒脉动 | 中速动态感 | "晶石生物，天气绑定" |

#### 攻击动画风格

| 阵营 | 攻击准备动画 | 攻击执行动画 | 攻击后动画 | 传达信息 |
|------|--------------|--------------|------------|----------|
| **墓园** | 肢体蠕动聚能 → 触须伸出准备 | 肢体挥击 → 触须缠绕 | 肢体恢复蠕动 | "有机攻击，粘液残留" |
| **地狱** | 眼球注视锁定 → 触手伸展准备 | 触手鞭击 → 眼球射出 | 触手恢复伸展 | "虚空攻击，追踪精准" |
| **塔楼** | 机械锁定目标 → 电路闪光准备 | 机械撞击 → 炮击射出 | 机械恢复规律 | "残留攻击，机械精准" |
| **元素** | 晶石光芒聚能 → 天气元素附着 | 晶石射出 → 元素射出 | 晶石恢复悬浮 | "晶石攻击，天气绑定" |

#### 层级动画复杂度

| 层级 | 动画帧数 | 动画复杂度 | 独特动画 |
|------|----------|------------|----------|
| **Basic** | 4-8帧 | 简化动画：基础移动+基础攻击 | 无独特动画 |
| **Elite** | 8-16帧 | 增强动画：准备动作+攻击后恢复+独特特征 | 独特准备动画（触须伸出/眼球注视） |
| **Boss** | 16-32帧 | 极复杂动画：多阶段攻击+多肢体协调+BOSS专属 | BOSS专属动画（触手森林/维度扭曲/元素风暴） |

#### 状态动画

| 状态 | 墓园动画 | 地狱动画 | 塔楼动画 | 元素动画 |
|------|----------|----------|----------|----------|
| **Idle** | 轻微蠕动 + 粘液滴落 | 触手轻微伸展 + 眼球转动 | 机械轻微震动 + 电路闪光 | 晶石轻微脉动 + 光芒闪烁 |
| **移动** | 踉跄蠕动步态 | 扭曲追踪步态 | 规律机械步态 | 悬浮晶石移动 |
| **攻击准备** | 肢体聚能 + 触须伸出 | 眼球锁定 + 触手伸展 | 机械锁定 + 电路闪光 | 晶石聚能 + 元素附着 |
| **攻击执行** | 肢体挥击 + 粘液飞溅 | 触手鞭击 + 眼球射出 | 机械撞击 + 炮击射出 | 晶石射出 + 元素射出 |
| **受伤** | 肢体扭曲 + 粘液喷出 | 触手颤抖 + 眼球收缩 | 机械震动 + 电路火花 | 晶石震动 + 光芒减弱 |
| **死亡** | 有机崩溃 + 粘液扩散 | 维度消散 + 深渊吸入 | 机械解体 + 锈蚀崩溃 | 晶石粉碎 + 光芒消散 |

### Audio Requirements Summary

| 阵营 | Idle音效 | 移动音效 | 攻击音效 | 死亡音效 | 环境音效 |
|------|----------|----------|----------|----------|----------|
| **墓园** | 虫族蠕动声 | 踉跄拖行声 + 粘液滴落 | 肢体挥击声 + 粘液飞溅声 | 虫族崩溃声 + 粘液溅射声 | 蜂巢嗡嗡声 |
| **地狱** | 深渊低语声 | 扭曲移动声 + 触手伸展声 | 触手鞭击声 + 眼球射出声 | 深渊吸入声 + 低频震颤 | 深渊低频背景声 |
| **塔楼** | 机械震动声 | 锈蚀移动声 + 机械卡顿声 | 机械撞击声 + 电路短路声 | 机械崩溃声 + 电路短路声 | 机械残留背景声 |
| **元素** | 晶石脉动声 | 悬浮移动声 + 光芒闪烁声 | 晶石射出声 + 元素特效声 | 晶石粉碎声 + 元素消散声 | 天气元素背景声 |

#### 层级音效强度

| 层级 | 音效强度 | 独特音效 |
|------|----------|----------|
| **Basic** | 低强度音效 | 无独特音效 |
| **Elite** | 中强度音效 + 独特准备音效 | 独特准备音效（触须伸出声/眼球锁定声） |
| **Boss** | 高强度音效 + 独特BOSS音效 | BOSS专属音效（深渊呼唤声/维度撕裂声/元素风暴声） |

## UI Requirements

敌人类型数据库是纯数据层系统，无直接UI交互。所有敌人信息通过下游系统间接呈现：

- **敌人AI系统** → 敌人实体在游戏世界中的视觉表现（sprite, VFX）
- **HUD系统** → 尸潮预警UI可能显示敌人图标（由敌人生成系统提供）
- **战车武器系统** → 瞄准UI可能显示敌人类型标签（由炮塔系统提供）

**无本系统专属UI需求**。若需敌人类型查阅界面（调试/设计工具），属于开发工具范畴，不在MVP范围。

## Acceptance Criteria

### Core Rules Coverage

**AC-01**: GIVEN the game initializes, WHEN EnemyTypeDatabase autoload loads, THEN database singleton exists, internal Dictionary initialized with 11 MVP enemy definitions, and `get_enemy_definition()` method is callable.

**AC-02**: GIVEN enemy_id=1000 (Graveyard range), WHEN `get_enemy_definition(1000)` is called, THEN returned Dictionary has faction=0 (GRAVEYARD enum).

**AC-03**: GIVEN enemy_id=1100, WHEN ID is parsed, THEN tier=ENHANCED (offset 100-199), and tier field value matches ID-derived tier.

**AC-04**: GIVEN valid enemy_id=1000, WHEN `get_enemy_definition(1000)` is called, THEN returned Dictionary contains all 19 fields with correct types (int for health, float for speed, string for display_name).

**AC-05**: GIVEN faction=1 (HELL), WHEN `get_enemies_by_faction(1)` is called, THEN returned Array contains only enemies with faction=1, array length matches Hell MVP count (4), all enemy_id in range 2000-2999.

**AC-06**: GIVEN day=6, WHEN `get_enemies_by_unlock_day(6)` is called, THEN returned Array contains enemies with unlock_day <= 6, Day 7+ enemies excluded.

### Formula Coverage

**AC-07**: GIVEN weapon_damage=50, enemy_armor=30, WHEN damage calculation performed, THEN actual_damage = 50 × (1 - 0.30) = 35.

**AC-08**: GIVEN enemy_health=150, actual_damage=35, WHEN shots-to-kill calculated, THEN shots_to_kill = ceil(150/35) = 5.

**AC-09**: GIVEN enemy with health=150, damage=25, armor=20, speed=0.7, WHEN `get_threat_score()` called, THEN threat_score = 15 + 25 + 10 + 7 = 57.

### Cross-System Integration

**AC-10**: GIVEN enemy with drop_resource_id=0, WHEN database validates, THEN no warning logged (valid null). GIVEN enemy with drop_resource_id=9999 (non-existent), WHEN database validates, THEN warning logged, database does NOT crash.

**AC-11**: GIVEN enemy with drop_chance=1.5 (exceeds range), WHEN database loads, THEN drop_chance clamped to 1.0, warning logged.

### Edge Case Coverage

**AC-12**: GIVEN enemy_id=-1, WHEN `get_enemy_definition(-1)` called, THEN returns null, warning logged. GIVEN enemy_id=99999, WHEN called, THEN returns null, warning logged "enemy_id exceeds schema range".

**AC-13**: GIVEN enemy definition with health=1500, WHEN database loads, THEN health clamped to 1000, warning logged. GIVEN armor=90, WHEN loaded, THEN armor clamped to 80, warning logged.

**AC-14**: GIVEN enemy_id=1500 (Graveyard) but faction=1 (HELL), WHEN database loads, THEN warning logged "ID-range/faction mismatch", definition returned as-is.

## Open Questions

| ID | Question | Owner | Target Resolution | Status |
|----|----------|-------|-------------------|--------|
| Q-001 | 元素阵营天气绑定机制具体如何影响敌人属性？是否需要动态属性计算？ | EnemyAI系统GDD | Day 16+ content design phase | Open |
| Q-002 | Boss级敌人是否需要多阶段属性变化？当前设计假设单一静态属性。 | EnemyAI系统GDD | Before Boss implementation (Day 12) | Open |
| Q-003 | `behavior_hint`与实际AI行为实现的对齐验证 — 数据库定义8种模式，AI系统是否能全部实现？ | EnemyAI系统GDD | Before EnemyAI implementation | Open |
| Q-004 | 11种MVP敌人是否足够覆盖前12天体验？是否需要增加更多变体？ | Content design review | Before MVP milestone (Day 12) | Open |