# 搜刮容器数据库

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-22
> **Implements Pillar**: Pillar 2 (搜打撤节奏)
> **Priority**: MVP | **Layer**: Foundation
> **System ID**: #7 (from systems-index.md)

## Overview

搜刮容器数据库是存储所有可搜刮容器类型定义的单一数据源。每个容器类型定义了容器分类（宝箱、废墟、敌人掉落）、稀有度、掉落表配置、搜刮时间、重生规则。该数据库为搜刮交互系统、地图废墟生成系统、敌人生成系统提供统一的容器掉落接口，确保所有搜刮行为引用同一份掉落定义。

作为Foundation层系统，该数据库直接影响玩家对**搜刮风险决策**的感知：不同容器的掉落表稀有度创造"再搜一个废墟？"的心理博弈，搜刮时间影响撤退节奏判断，重生规则影响探索路径规划。这服务于Pillar 2（搜打撤节奏）——每次搜刮都是诱惑vs风险的决策，容器数据定义了这种博弈的数学边界。

**设计决策**：
- 使用Dictionary结构存储容器类型定义（key = container_type_id, value = Dictionary of attributes）
- 采用Autoload singleton模式（extends Node），与BlockTypeDatabase、ResourceDatabase、EnemyTypeDatabase、VehicleTypeDatabase保持一致架构
- 提供`get_container_definition(container_type_id: int)`查询接口供下游系统调用
- 掉落表结构遵循EnemyTypeDatabase的`drop_resource_id + drop_chance`模式，支持多物品掉落（drop_table array）

## Player Fantasy

玩家在搜刮相关系统中面对的核心体验是**废墟拾荒者的两难时刻**——每个容器都是一场贪婪与理性的博弈，"再开一个箱子？"的决策贯穿每次探索。

- **打开前的期待**: 玩家蹲伏在废墟阴影中，手电筒光束扫过一个微微发光的魔导宝箱，背包还剩3格，但箱子里可能有稀有组件——手指悬在"打开"键上，心跳加速。数据库的稀有度等级和掉落表定义了这种期待感："这个容器是什么级别？里面可能有什么？"
- **搜刮时的紧迫**: 打开容器需要时间（搜刮时间字段），撤退倒计时在逼近，远处传来丧尸低吼——玩家必须快速决定"值不值得花这3秒？"数据库的scavenge_time_seconds定义了这种时间成本
- **取舍后的释然或懊悔**: 背包满后盯着两件物品，必须选择留下什么。数据库的掉落表创造了"一地垃圾"vs"稀有材料"的不确定性，每一次选择都在训练"该不该搜"的直觉

**锚定时刻**: 第一次打开废墟中的军用绿箱，里面不是垃圾，而是一枚锈迹斑斑但核心仍闪烁微光的魔导核心。鼠标悬停显示未知物品图标，伴随神秘音效——"这个能用来做什么？"的好奇心驱动下一次探索。但当撤退倒计时只剩30秒，背包已满，玩家必须放弃那箱子里50%概率的铁矿——懊悔感留在心头，下次会更谨慎。

**服务于支柱**：
- **Pillar 2 (搜打撤节奏)**: 每个容器的搜刮时间、掉落概率、稀有度都是"诱惑vs风险"博弈的数学参数。数据库定义了这种决策边界
- **Pillar 4 (魔导科技美学)**: 容器分类不只是"宝箱/废墟"，而是"魔导储能器/军用补给舱/被腐蚀的研究样本箱"。掉落物品命名延续魔导科技语调

**容器分层设计**:
| 容器层级 | 视觉标识 | 搜刮时间 | 撤退警报触发 | 玩家直觉 |
|----------|----------|----------|--------------|----------|
| 破旧木箱 | 腐烂木头、藤蔓覆盖 | 1-2秒 | 无 | "垃圾，但可能有用" |
| 军用绿箱 | 金属锈迹、军用标识 | 3-5秒 | 无 | "可能有武器组件" |
| 魔导晶体舱 | 发光符文、能量嗡鸣 | 5-8秒 | 低概率 | "危险但高价值" |
| 异变体巢穴 | 生物发光、腐蚀痕迹 | 8-15秒 | 高概率 | "高风险高回报" |

## Detailed Design

### Core Rules

#### 1. Container Type Data Structure

每个容器类型定义为一个独立的数据记录，存储在ContainerDatabase资源文件中。所有容器类型共享统一的数据结构。

**Primary Container Fields:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `container_type_id` | int | 0-65535 | — | 唯一标识符，系统内部引用键 |
| `name` | string | — | — | 内部标识名（如"wooden_chest", "ruined_safe"），用于代码引用和本地化键 |
| `display_name` | string | — | — | UI显示名称（本地化键，实际显示由LocalizationManager处理） |
| `category` | int | 0-2 | — | 容器分类枚举值（见Category System） |
| `rarity` | int | 1-5 | 1 | 容器稀有度等级，影响掉落质量概率分布 |
| `scavenge_time_seconds` | float | 1.0-15.0 | 3.0 | 搜刮所需时间（秒），影响撤退决策压力 |
| `drop_table` | Array[Dictionary] | — | [] | 掉落表（多物品掉落配置，见Drop Table Structure） |
| `respawn_rules` | Dictionary | — | — | 重生规则配置（见Respawn Rules） |
| `spawn_weight` | float | 0.1-10.0 | 1.0 | 世界生成权重（影响容器出现频率） |
| `min_drop_count` | int | 0-5 | 1 | 最小掉落物品数量 |
| `max_drop_count` | int | 1-10 | 3 | 最大掉落物品数量 |
| `alert_chance_on_open` | float | 0.0-1.0 | 0.0 | 打开时触发撤退警报的概率 |
| `is_lockable` | int | 0-1 | 0 | 是否可被锁定（需要钥匙/解密） |

**Extended Container Fields:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `icon_path` | string | — | — | Godot资源路径指向容器图标 |
| `description` | string | — | "" | 内部文档说明 |
| `visual_theme` | int | 0-3 | 0 | 视觉主题枚举（魔导/军用/废墟/异变） |
| `audio_open` | string | — | — | 打开音效资源路径 |
| `audio_empty` | string | — | — | 空容器音效资源路径 |

**Field Validation Rules:**

1. `container_type_id`必须唯一，不允许重复ID
2. `container_type_id = 0`保留为"空容器"错误回退
3. `name`必须为有效的snake_case标识符（仅字母、数字、下划线）
4. `category`必须在枚举范围0-2内
5. `rarity`必须在范围1-5内
6. `scavenge_time_seconds`必须为正浮点数（>=1.0）
7. `drop_table`必须为有效数组，每项包含resource_id和drop_chance
8. `min_drop_count <= max_drop_count`（违反则自动调整max=min）

---

#### 2. Container Type ID Allocation Scheme

容器ID按类别分配，确保ID范围可预测、可扩展。

**ID Range Allocation:**

| ID Range | Category | Description |
|----------|----------|-------------|
| 0 | — | `null_container` — 保留为错误回退 |
| 1-99 | — | 系统内部容器（占位符、测试） |
| 100-499 | `chest` | 宝箱类容器（可移动、可锁定） |
| 500-999 | `ruin` | 废墟类容器（固定位置、环境嵌入） |
| 1000-1499 | `enemy_drop` | 敌人掉落容器（动态生成、自动消失） |
| 1500-1999 | `special` | 特殊/事件容器（任务相关、一次性） |
| 2000-65535 | — | 未来内容预留 |

**ID Sub-Range by Rarity (within each category):**

| Rarity | Sub-Range Offset | Example (Chest 100-499) |
|--------|------------------|-------------------------|
| 1 (common) | +0-99 | 100-199 = Common Chests |
| 2 (uncommon) | +100-199 | 200-299 = Uncommon Chests |
| 3 (rare) | +200-299 | 300-399 = Rare Chests |
| 4 (epic) | +300-399 | 400-499 = Epic Chests |
| 5 (legendary) | +400-499 | — (exceeds range, use special) |

> **Constraint**: Legendary containers typically use `special` category (1500-1999) due to their unique nature.

---

#### 3. Container Category System

**Category Enumeration:**

| Value | Name | Description | Behavior Rules |
|-------|------|-------------|----------------|
| 0 | `chest` | 宝箱类容器 | 可移动、可被玩家放置、可锁定、搜刮后保留 |
| 1 | `ruin` | 庢墟类容器 | 固定位置、环境嵌入、搜刮后变为空状态、可重生 |
| 2 | `enemy_drop` | 敌人掉落 | 动态生成、自动消失（60秒timeout）、不可锁定 |

**Category-Specific Behavior Rules:**

| Behavior | Chest (0) | Ruin (1) | Enemy Drop (2) |
|----------|-----------|----------|----------------|
| **可移动** | 是（可被玩家搬运） | 否（固定位置） | 否（生成位置固定） |
| **可锁定** | 是（需钥匙解锁） | 否 | 否 |
| **搜刮后状态** | 消失或变空壳 | 变空状态（视觉保留） | 消失（timeout或拾取后） |
| **重生规则** | 不重生（除非重新放置） | 按respawn_rules重生 | 不重生 |
| **背包交互** | 可放入背包（占1格） | 不可放入背包 | 不可放入背包 |
| **撤退警报** | 可能触发 | 可能触发 | 不触发 |
| **世界生成** | 随机分布（spawn_weight） | 废墟区域固定分布 | 击杀敌人时生成 |

---

#### 4. Drop Table Structure

掉落表采用数组结构，支持多物品掉落。每项定义遵循EnemyTypeDatabase的`drop_resource_id + drop_chance`模式扩展。

**Drop Table Entry Structure:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `resource_id` | int | 0-65535 | — | 掉落资源ID（引用ResourceDatabase） |
| `drop_chance` | float | 0.0-1.0 | — | 单次掉落概率（独立概率，非权重） |
| `min_quantity` | int | 1-100 | 1 | 最小掉落数量 |
| `max_quantity` | int | 1-100 | 1 | 最大掉落数量 |
| `rarity_modifier` | float | 0.0-2.0 | 1.0 | 稀有度修正（乘以ResourceDatabase的rarity_drop_modifier） |

**Drop Table JSON Example:**

```json
"drop_table": [
    {
        "resource_id": 101,
        "drop_chance": 0.8,
        "min_quantity": 1,
        "max_quantity": 5,
        "rarity_modifier": 1.0
    },
    {
        "resource_id": 201,
        "drop_chance": 0.3,
        "min_quantity": 1,
        "max_quantity": 2,
        "rarity_modifier": 1.5
    },
    {
        "resource_id": 301,
        "drop_chance": 0.05,
        "min_quantity": 1,
        "max_quantity": 1,
        "rarity_modifier": 2.0
    }
]
```

**Drop Generation Algorithm:**

```
function generate_drops(container_type_id):
    definition = get_container_definition(container_type_id)
    drops = []
    
    for entry in definition.drop_table:
        # Calculate effective drop chance
        resource_rarity = ResourceDatabase.get_rarity(entry.resource_id)
        base_drop_modifier = RARITY_DROP_MODIFIER[resource_rarity]
        effective_chance = entry.drop_chance * base_drop_modifier * entry.rarity_modifier
        
        # Roll for each entry (independent probability)
        if random(0.0, 1.0) <= effective_chance:
            quantity = random(entry.min_quantity, entry.max_quantity)
            drops.append({"resource_id": entry.resource_id, "quantity": quantity})
    
    # Enforce min/max drop count constraints
    if len(drops) < definition.min_drop_count:
        # Pad with lowest rarity resources from drop_table
        while len(drops) < definition.min_drop_count:
            fallback = get_lowest_rarity_entry(definition.drop_table)
            drops.append(fallback)
    
    if len(drops) > definition.max_drop_count:
        # Trim highest rarity drops first (preserve common drops)
        drops = trim_high_rarity_first(drops, definition.max_drop_count)
    
    return drops
```

**Drop Chance vs Resource Rarity Interaction:**

| Container Rarity | Resource Rarity Modifier Applied |
|------------------|----------------------------------|
| 1 (common) | ×0.5 on rare+ resources |
| 2 (uncommon) | ×1.0 standard |
| 3 (rare) | ×1.5 on uncommon+ resources |
| 4 (epic) | ×2.0 on rare+ resources |
| 5 (legendary) | ×3.0 on epic+ resources |

---

#### 5. Rarity Tier System

容器稀有度影响掉落质量概率分布和视觉表现。

**Rarity Levels:**

| Level | Name | Drop Quality Bias | Visual Glow | Scavenge Time Modifier |
|-------|------|-------------------|-------------|------------------------|
| 1 | `common` | 基础材料为主 | 无发光 | ×1.0 |
| 2 | `uncommon` | 基础+少量魔导材料 | 边缘微光 | ×1.2 |
| 3 | `rare` | 魔导材料为主 | 中等发光 | ×1.5 |
| 4 | `epic` | 魔导+稀有材料 | 强发光+脉动 | ×2.0 |
| 5 | `legendary` | 稀有材料+特殊物品 | 全身发光+特效 | ×3.0 |

**Rarity Drop Modifier Table:**

| Container Rarity | Common (rarity=1) | Uncommon (rarity=2) | Rare (rarity=3) | Epic (rarity=4) | Legendary (rarity=5) |
|------------------|-------------------|---------------------|-----------------|-----------------|----------------------|
| 1 (common) | 100% | 60% | 15% | 3% | 0.5% |
| 2 (uncommon) | 100% | 80% | 30% | 8% | 2% |
| 3 (rare) | 100% | 100% | 50% | 15% | 5% |
| 4 (epic) | 100% | 100% | 80% | 30% | 10% |
| 5 (legendary) | 100% | 100% | 100% | 50% | 20% |

> **Interpretation**: A common container (rarity=1) has 15% chance to drop rare resources (rarity=3), but an epic container (rarity=4) has 80% chance for the same rare resource.

**Container Rarity Visual Style:**

| Rarity | Border Color | Glow Effect | Audio Cue |
|--------|--------------|-------------|-----------|
| 1 | 白色/灰色 #CCCCCC | 无 | 普通开箱声 |
| 2 | 绿色 #00FF00 | 边缘微光 | 轻微金属声 |
| 3 | 蓝色 #0088FF | 中等发光 | 魔导嗡鸣声 |
| 4 | 紫色 #AA00FF | 强发光+脉动 | 能量蓄积声 |
| 5 | 金色 #FFD700 | 全身发光+特效 | 稀有解锁音效 |

---

#### 6. Scavenge Time Rules

搜刮时间直接服务于Pillar 2（搜打撤节奏）——每次搜刮都是时间vs收益的决策。

**Base Scavenge Time by Category:**

| Category | Base Time | Reasoning |
|----------|-----------|-----------|
| `chest` | 2-5秒 | 可移动容器，搜刮较快 |
| `ruin` | 3-10秒 | 固定容器，需要搜索动作 |
| `enemy_drop` | 1-2秒 | 敌人掉落，快速拾取 |

**Rarity Time Modifier:**

| Container Rarity | Time Modifier | Reasoning |
|------------------|---------------|-----------|
| 1 (common) | ×1.0 | 基准时间 |
| 2 (uncommon) | ×1.2 | 需要检查机制 |
| 3 (rare) | ×1.5 | 魔导锁解除 |
| 4 (epic) | ×2.0 | 高级魔导封印 |
| 5 (legendary) | ×3.0 | 古代封印破解 |

**Scavenge Time Formula:**

```
effective_scavenge_time = scavenge_time_seconds × RARITY_TIME_MODIFIER
```

**Example:**
- 破旧木箱 (chest, rarity=1, base=2秒): `effective = 2 × 1.0 = 2秒`
- 魔导晶体舱 (ruin, rarity=3, base=5秒): `effective = 5 × 1.5 = 7.5秒`
- 异变体巢穴 (ruin, rarity=4, base=8秒): `effective = 8 × 2.0 = 16秒`

**Scavenge Time Gameplay Rules:**

1. **搜刮开始**: 玩家按下交互键，开始搜刮计时
2. **搜刮动画**: 播放开箱/搜索动画，UI显示进度条
3. **中断规则**: 
   - 玩家主动取消 → 搜刮失败，容器状态不变
   - 受到伤害 → 搜刮中断，容器状态不变
   - 移动离开 → 搜刮中断
4. **撤退警报**: 如果`alert_chance_on_open > 0`，搜刮开始时触发概率检查
5. **完成**: 计时结束，生成掉落物品，容器状态变更

**Time Pressure Design Table:**

| 搜刮时间 | 撤退倒计时剩余 | 决策心理 |
|----------|-----------------|----------|
| 1-3秒 | >60秒 | "快速捡起，风险低" |
| 3-5秒 | 30-60秒 | "犹豫但仍可接受" |
| 5-10秒 | <30秒 | "高风险决策，可能放弃" |
| >10秒 | <15秒 | "极端风险，仅限高价值容器" |

---

#### 7. Respawn Rules

重生规则仅适用于`ruin`类容器，定义何时、如何在世界中重新填充。

**Respawn Rule Structure:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `respawn_enabled` | int | 0-1 | 0 | 是否启用重生 |
| `respawn_time_seconds` | float | 60-3600 | 300 | 重生时间（秒），默认5分钟 |
| `respawn_requires_zone_leave` | int | 0-1 | 1 | 是否需要玩家离开区域才重生 |
| `respawn_drop_table_same` | int | 0-1 | 1 | 重生后掉落表是否相同（0=重新生成） |
| `respawn_max_count` | int | 0-10 | 0 | 区域内最大重生次数（0=无限） |

**Respawn Rule JSON Example:**

```json
"respawn_rules": {
    "respawn_enabled": 1,
    "respawn_time_seconds": 300,
    "respawn_requires_zone_leave": 1,
    "respawn_drop_table_same": 1,
    "respawn_max_count": 0
}
```

**Respawn Behavior by Category:**

| Category | Respawn Behavior | Reasoning |
|----------|------------------|-----------|
| `chest` | 不重生 | 玩家可携带，重生会破坏资源平衡 |
| `ruin` | 按规则重生 | 鼓励重复探索废墟区域 |
| `enemy_drop` | 不重生 | 敌人击杀后才会生成新掉落 |

**Respawn Algorithm:**

```
function check_respawn(container_instance):
    if container_instance.category != RUIN:
        return false
    
    rules = container_instance.respawn_rules
    if rules.respawn_enabled == 0:
        return false
    
    if rules.respawn_max_count > 0:
        if container_instance.respawns_so_far >= rules.respawn_max_count:
            return false
    
    if rules.respawn_requires_zone_leave == 1:
        if player_in_zone(container_instance.zone_id):
            return false
    
    time_since_scavenged = current_time - container_instance.scavenged_time
    if time_since_scavenged >= rules.respawn_time_seconds:
        return true
    
    return false
```

---

#### 8. Initial Container Catalog (MVP)

MVP阶段定义最小可玩容器类型集，覆盖所有类别和稀有度层级。

**Chest Containers (ID 100-499):**

| ID | Name | Display | Rarity | Category | Scavenge Time | Alert Chance | Drop Count Range |
|----|------|---------|--------|----------|---------------|---------------|------------------|
| 101 | `wooden_chest_basic` | "破旧木箱" | 1 | chest | 2.0秒 | 0% | 1-3 |
| 102 | `wooden_chest_reinforced` | "加固木箱" | 2 | chest | 3.0秒 | 0% | 2-4 |
| 201 | `military_green_box` | "军用绿箱" | 2 | chest | 3.0秒 | 5% | 2-5 |
| 202 | `military_supply_case` | "补给舱" | 3 | chest | 5.0秒 | 10% | 3-6 |
| 301 | `magitech_storage_unit` | "魔导储能器" | 3 | chest | 5.0秒 | 15% | 3-5 |
| 302 | `magitech_crystal_pod` | "魔导晶体舱" | 4 | chest | 8.0秒 | 25% | 3-6 |

**Ruin Containers (ID 500-999):**

| ID | Name | Display | Rarity | Category | Scavenge Time | Alert Chance | Respawn | Drop Count Range |
|----|------|---------|--------|----------|---------------|---------------|---------|------------------|
| 501 | `ruined_cabinet` | "废弃柜子" | 1 | ruin | 3.0秒 | 0% | 5分钟 | 1-3 |
| 502 | `ruined_desk` | "废弃办公桌" | 1 | ruin | 2.5秒 | 0% | 5分钟 | 1-2 |
| 503 | `collapsed_shelf` | "坍塌货架" | 2 | ruin | 4.0秒 | 0% | 8分钟 | 2-4 |
| 601 | `ruined_safe` | "废墟保险箱" | 2 | ruin | 5.0秒 | 10% | 10分钟 | 2-5 |
| 602 | `corrupted_research_cabinet` | "被腐蚀研究柜" | 3 | ruin | 6.0秒 | 20% | 15分钟 | 3-5 |
| 701 | `mutant_nest_container` | "异变体巢穴" | 4 | ruin | 10.0秒 | 40% | 不重生 | 3-7 |

**Enemy Drop Containers (ID 1000-1499):**

| ID | Name | Display | Rarity | Category | Scavenge Time | Timeout | Drop Count Range |
|----|------|---------|--------|----------|---------------|---------|------------------|
| 1001 | `zombie_drop_pile` | "丧尸掉落堆" | 1 | enemy_drop | 1.0秒 | 60秒 | 0-2 |
| 1002 | `skeleton_drop_pile` | "骷髅掉落堆" | 2 | enemy_drop | 1.0秒 | 60秒 | 1-3 |
| 1101 | `elite_drop_cache` | "精英掉落缓存" | 3 | enemy_drop | 1.5秒 | 90秒 | 2-4 |
| 1201 | `boss_drop_trove` | "Boss掉落宝库" | 4 | enemy_drop | 2.0秒 | 120秒 | 4-8 |

**Special Containers (ID 1500-1999):**

| ID | Name | Display | Rarity | Category | Scavenge Time | Special Condition |
|----|------|---------|--------|----------|---------------|-------------------|
| 1501 | `quest_key_cache` | "任务钥匙缓存" | 3 | special | 3.0秒 | 仅任务触发时出现 |
| 1502 | `event_supply_drop` | "事件补给空投" | 4 | special | 5.0秒 | 仅事件触发时出现 |

**MVP Total: 16 Container Types**
- Chest: 6 types
- Ruin: 6 types
- Enemy Drop: 4 types
- Special: 2 types

---

#### 9. Container Database Query API

**Singleton Registration:**

```gdscript
# ContainerDatabase.gd (autoload singleton)
class_name ContainerDatabase
extends Node

# Autoload name: "Containers"
```

**Primary Query Methods:**

```gdscript
# === Basic Lookup ===
func get_container_definition(container_type_id: int) -> Dictionary
func get_container_name(container_type_id: int) -> String
func get_display_name(container_type_id: int) -> String

# === Property Query ===
func get_category(container_type_id: int) -> int
func get_rarity(container_type_id: int) -> int
func get_scavenge_time(container_type_id: int) -> float
func get_drop_table(container_type_id: int) -> Array[Dictionary]
func get_respawn_rules(container_type_id: int) -> Dictionary

# === Category Query ===
func get_containers_by_category(category: int) -> Array[int]
func get_chests() -> Array[int]
func get_ruins() -> Array[int]
func get_enemy_drops() -> Array[int]

# === Rarity Query ===
func get_containers_by_rarity(rarity: int) -> Array[int]

# === Drop Generation ===
func generate_drops(container_type_id: int) -> Array[Dictionary]
func generate_enemy_drop(enemy_id: int) -> Array[Dictionary]

# === Validation ===
func is_valid_container(container_type_id: int) -> bool
```

**Query Return Format:**

```gdscript
# get_container_definition returns:
{
    "container_type_id": int,
    "name": String,
    "display_name": String,
    "category": int,
    "rarity": int,
    "scavenge_time_seconds": float,
    "drop_table": Array[Dictionary],
    "respawn_rules": Dictionary,
    "spawn_weight": float,
    "min_drop_count": int,
    "max_drop_count": int,
    "alert_chance_on_open": float,
    "is_lockable": bool,
    "icon_path": String,
    "description": String,
    "visual_theme": int,
    "audio_open": String,
    "audio_empty": String
}
```

### States and Transitions

容器实例在游戏世界中的生命周期状态管理。

**Container Instance State Machine:**

| State | Name | Description | Valid Transitions |
|-------|------|-------------|-------------------|
| `SPAWNED` | 生成态 | 容器刚生成，等待玩家发现 | → INTERACTABLE, → DESPAWNED (enemy_drop timeout) |
| `INTERACTABLE` | 可交互态 | 玩家可开始搜刮 | → SCAVENGING, → LOCKED (if is_lockable), → DESTROYED |
| `LOCKED` | 锁定态 | 需要钥匙才能打开 | → INTERACTABLE (unlock), → DESTROYED |
| `SCAVENGING` | 搜刮中态 | 玩家正在搜刮（计时进行） | → COMPLETED, → INTERRUPTED |
| `COMPLETED` | 完成态 | 搜刮完成，掉落已生成 | → EMPTY (chest/ruin), → DESPAWNED (enemy_drop) |
| `EMPTY` | 空态 | 已搜刮，等待重生 | → INTERACTABLE (respawn trigger), → DESPAWNED |
| `INTERRUPTED` | 中断态 | 搜刮被打断 | → INTERACTABLE (re-initiate), → DESTROYED |
| `DESPAWNED` | 消失态 | 从世界中移除（终态） | 无 |
| `DESTROYED` | 摧毁态 | 被物理摧毁（终态） | 无 |

**State Transition Diagram:**

```
[SPAWNED] ──(player approaches)──> [INTERACTABLE]
       │                              │
       │                              ├──(is_lockable & no key)──> [LOCKED]
       │                              │                              │
       │                              │                              └──(unlock)──> [INTERACTABLE]
       │                              │
       │                              ├──(player starts scavenge)──> [SCAVENGING]
       │                              │                              │
       │                              │                              ├──(timer complete)──> [COMPLETED]
       │                              │                              │
       │                              │                              ├──(cancel/damage/move)──> [INTERRUPTED]
       │                              │                              │                              │
       │                              │                              │                              └──(re-initiate)──> [INTERACTABLE]
       │                              │
       │                              └──(explosion/damage)──> [DESTROYED]
       │
       └──(timeout: enemy_drop)──> [DESPAWNED]

[COMPLETED] ──(chest/ruin)──> [EMPTY]
       │
       └──(enemy_drop)──> [DESPAWNED]

[EMPTY] ──(respawn trigger)──> [INTERACTABLE]
       │
       └──(no respawn)──> [EMPTY] (permanent)
```

**State-Specific Behavior:**

| State | UI Display | Visual Effect | Audio | Player Action |
|-------|------------|---------------|-------|---------------|
| `SPAWNED` | 无提示 | 容器外观显示 | 无 | 无交互 |
| `INTERACTABLE` | 交互提示图标 | 边缘高亮（rarity决定颜色） | 接近时轻微嗡鸣 | 按交互键搜刮 |
| `LOCKED` | 锁定图标 + "需要钥匙" | 锁具视觉效果 | 锁定音效 | 无法打开，显示所需钥匙 |
| `SCAVENGING` | 进度条（搜刮时间） | 开箱动画 | 搜刮循环音效 | 可取消 |
| `COMPLETED` | 掉落物品列表 | 开箱完成效果 | 开箱成功音效 | 拾取物品 |
| `EMPTY` | "空"提示 | 空容器外观 | 空容器音效 | 无交互 |
| `INTERRUPTED` | 中断警告 | 动画停止 | 中断音效 | 可重新开始 |
| `DESPAWNED` | 无 | 容器消失 | 消失音效 | 无 |
| `DESTROYED` | 无 | 碎片效果 | 摧毁音效 | 无 |

---

### Interactions with Other Systems

容器数据库与多个下游系统的数据流和接口契约。

**搜刮交互系统 (#31) — 硬依赖**

| 接口调用 | 触发时机 | 数据流向 | 返回数据 |
|----------|----------|----------|----------|
| `get_container_definition(id)` | 玩家接近容器时 | ContainerDB → ScavengeInteraction | 完整容器定义Dictionary |
| `get_scavenge_time(id)` | 搜刮开始时 | ContainerDB → ScavengeInteraction | 搜刮时间（含稀有度修正） |
| `generate_drops(id)` | 搜刮完成时 | ContainerDB → ScavengeInteraction | Array[{resource_id, quantity}] |

**搜刮交互系统状态同步:**
- 搜刮开始 → ContainerDB提供时间参数，ScavengeInteraction管理进度条
- 搜刮完成 → ContainerDB生成掉落，ScavengeInteraction显示UI
- 搜刮中断 → ContainerDB不生成掉落，容器状态回退

---

**地图/废墟生成系统 (#48) — 硬依赖**

| 接口调用 | 触发时机 | 数据流向 | 返回数据 |
|----------|----------|----------|----------|
| `get_ruins()` | 废墟区域生成时 | ContainerDB → WorldGenerator | Array[int] ruin容器ID列表 |
| `get_chests()` | 世界随机分布时 | ContainerDB → WorldGenerator | Array[int] chest容器ID列表 |
| `get_spawn_weight(id)` | 分布概率计算时 | ContainerDB → WorldGenerator | float spawn权重 |

**世界生成数据流:**
```
WorldGenerator.request_zone_containers(zone_type)
    → ContainerDB.get_ruins() + get_chests()
    → 按spawn_weight加权分布
    → 生成ContainerInstance节点
    → 设置初始状态 = SPAWNED
```

---

**敌人生成系统 (#13) — 硬依赖**

| 接口调用 | 触发时机 | 数据流向 | 返回数据 |
|----------|----------|----------|----------|
| `get_enemy_drops()` | 敌人死亡时 | ContainerDB → EnemySpawner | Array[int] 对应敌人掉落容器ID |
| `generate_drops(enemy_drop_id)` | 掉落生成时 | ContainerDB → EnemySpawner | Array[{resource_id, quantity}] |

**敌人掉落生成流程:**
```
Enemy.on_death()
    → EnemyTypeDB.get_drop_container_id(enemy_type_id)
    → ContainerDB.generate_drops(container_id)
    → 生成EnemyDrop节点
    → 设置timeout = 60秒
    → 状态 = SPAWNED → INTERACTABLE
```

---

**ResourceDatabase — 软依赖**

| 数据引用 | 用途 | 交互方式 |
|----------|------|----------|
| `get_rarity(resource_id)` | 掉落概率修正计算 | ContainerDB查询ResourceDB |
| `get_name(resource_id)` | 掉落物品UI显示 | 间接通过ScavengeInteraction |

**掉落生成时的ResourceDB查询:**
- 每个drop_table entry查询resource_id的稀有度
- 用于计算effective_drop_chance公式中的resource_rarity_modifier
- 缺失resource_id跳过该entry，不阻止其他掉落生成

---

**时间系统 (#8) — 状态依赖**

| 时间事件 | 容器行为 | 触发条件 |
|----------|----------|----------|
| 敌人掉落timeout计时 | 60秒后自动despawn | enemy_drop状态=INTERACTABLE |
| 废墟重生计时 | respawn_time_seconds后重生 | ruin状态=EMPTY，respawn_enabled=1 |
| 撤退倒计时逼近 | 搜刮时间压力增加 | 撤退倒计时 < 搜刮时间 |

---

**撤退判定系统 (#32) — 触发依赖**

| 触发事件 | 容器角色 | 数据来源 |
|----------|----------|----------|
| 警报触发检查 | alert_chance_on_open概率检查 | ContainerDB.alert_chance |
| 警报触发后果 | 撤退倒计时加速，敌人生成 | 搜刮交互系统执行 |

---

**HUD系统 (#49) — 显示依赖**

| HUD元素 | 数据来源 | 显示时机 |
|----------|----------|----------|
| 搜刮进度条 | scavenge_time_seconds | 状态=SCAVENGING |
| 容器稀有度指示 | rarity + border_color | 状态=INTERACTABLE |
| 掉落物品列表 | generate_drops结果 | 状态=COMPLETED |
| 警报警告图标 | alert_chance触发 | 搜刮开始时概率触发 |

## Formulas

### Effective Drop Chance Formula

掉落概率受多层修正因子影响，最终决定资源是否从掉落表中生成。

```
effective_chance = drop_chance × resource_rarity_modifier × container_rarity_modifier × entry.rarity_modifier
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `drop_chance` | DC | float | 0.0-1.0 | Drop table entry base probability |
| `resource_rarity_modifier` | RRM | float | 0.03-1.0 | Rarity modifier from ResourceDatabase (RDM table) |
| `container_rarity_modifier` | CRM | float | 0.005-1.0 | Container rarity modifier from RARITY_DROP_MODIFIER table |
| `entry.rarity_modifier` | ERM | float | 0.0-2.0 | Drop table entry specific modifier |

**Resource Rarity Modifier Table (from ResourceDatabase):**

| Resource Rarity | RRM Value |
|-----------------|-----------|
| 1 (common) | 1.0 |
| 2 (uncommon) | 0.6 |
| 3 (rare) | 0.3 |
| 4 (epic) | 0.1 |
| 5 (legendary) | 0.03 |

**Container Rarity Drop Modifier Table:**

| Container Rarity | Resource Rarity=1 | Rarity=2 | Rarity=3 | Rarity=4 | Rarity=5 |
|------------------|-------------------|----------|----------|----------|----------|
| 1 (common) | 100% (1.0) | 60% (0.6) | 15% (0.15) | 3% (0.03) | 0.5% (0.005) |
| 2 (uncommon) | 100% (1.0) | 80% (0.8) | 30% (0.3) | 8% (0.08) | 2% (0.02) |
| 3 (rare) | 100% (1.0) | 100% (1.0) | 50% (0.5) | 15% (0.15) | 5% (0.05) |
| 4 (epic) | 100% (1.0) | 100% (1.0) | 80% (0.8) | 30% (0.3) | 10% (0.1) |
| 5 (legendary) | 100% (1.0) | 100% (1.0) | 100% (1.0) | 50% (0.5) | 20% (0.2) |

**Output Range:** 0.0-1.0 (clamped — values exceeding 1.0 are clamped to 100%)

**Example Calculation:**
- Container: `magitech_crystal_pod` (rarity=4, epic)
- Drop entry: resource_id=301 (秘银, rarity=4), drop_chance=0.05, entry.rarity_modifier=2.0
- Calculation: `effective_chance = 0.05 × 0.1 × 0.3 × 2.0 = 0.003 (0.3%)`
- Interpretation: Epic container with epic resource has 0.3% chance to drop 秘银 under these modifiers

**Edge Cases:**
- If effective_chance > 1.0 → Clamp to 1.0 (100% guaranteed drop)
- If effective_chance < 0.0 → Set to 0.0 (impossible drop), log warning
- If drop_chance = 0 → Skip entry entirely (no roll needed)
- If resource_rarity_modifier = 0 → Resource will never drop (invalid ResourceDatabase state)

---

### Drop Quantity Generation Formula

掉落数量从min_quantity和max_quantity范围随机生成。

```
quantity = random(min_quantity, max_quantity)
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `min_quantity` | int | 1-100 | Minimum drop quantity from drop table entry |
| `max_quantity` | int | 1-100 | Maximum drop quantity from drop table entry |
| `quantity` | int | 1-100 | Generated quantity (output) |

**Output Range:** min_quantity to max_quantity (inclusive)

**Distribution:** Uniform random distribution (each value equally likely)

**Example:**
- Drop entry: min_quantity=2, max_quantity=5
- Possible outputs: 2, 3, 4, or 5 (each 25% probability)
- Average expected quantity: (2+5)/2 = 3.5

**Edge Cases:**
- If min_quantity > max_quantity → Swap values, log warning "min/max quantity inverted"
- If min_quantity = max_quantity → Fixed quantity (no randomness)
- If min_quantity < 1 → Set to 1, log warning "quantity below minimum"
- If max_quantity > 100 → Clamp to 100, log warning "quantity exceeds maximum"

---

### Scavenge Time Calculation Formula

搜刮时间受容器稀有度修正影响，高稀有度容器需要更长解锁时间。

```
actual_scavenge_time = base_scavenge_time × RARITY_TIME_MODIFIER[container_rarity]
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `base_scavenge_time` | BST | float | 1.0-15.0 | Container's scavenge_time_seconds field |
| `container_rarity` | CR | int | 1-5 | Container rarity tier |
| `RARITY_TIME_MODIFIER` | RTM | float | 1.0-3.0 | Rarity-dependent time multiplier |

**Rarity Time Modifier Table:**

| Container Rarity | RTM Value | Reasoning |
|------------------|-----------|-----------|
| 1 (common) | 1.0 | Baseline time |
| 2 (uncommon) | 1.2 | Mechanism check required |
| 3 (rare) | 1.5 | Magitech lock removal |
| 4 (epic) | 2.0 | Advanced magitech seal |
| 5 (legendary) | 3.0 | Ancient seal破解 |

**Output Range:** 1.0-45.0 seconds (base max 15s × legend modifier 3.0)

**Example Calculations:**

| Container | Base Time | Rarity | Modifier | Actual Time | Decision Pressure |
|-----------|-----------|--------|----------|-------------|-------------------|
| 破旧木箱 | 2.0s | 1 | ×1.0 | 2.0s | "Quick pickup, low risk" |
| 军用绿箱 | 3.0s | 2 | ×1.2 | 3.6s | "Hesitate but acceptable" |
| 魔导晶体舱 | 5.0s | 3 | ×1.5 | 7.5s | "High-risk decision, may skip" |
| 异变体巢穴 | 10.0s | 4 | ×2.0 | 20.0s | "Extreme risk, high-value only" |

**Edge Cases:**
- If actual_scavenge_time < 1.0 → Clamp to 1.0s (minimum interaction time)
- If actual_scavenge_time > 30.0 → Log debug "scavenge time exceeds 30s, player may skip"
- If base_scavenge_time = 0 → Reject container definition (invalid, minimum 1.0)
- If container_rarity outside 1-5 → Use default modifier 1.0, log warning

---

### Container Rarity Drop Modifier Formula

容器稀有度影响其掉落表中各稀有度资源的生成概率。该修正表决定"高稀有度容器更可能产出稀有资源"的直觉逻辑。

```
container_rarity_modifier = RARITY_DROP_MODIFIER[container_rarity][resource_rarity]
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `container_rarity` | CR | int | 1-5 | Container's rarity tier |
| `resource_rarity` | RR | int | 1-5 | Resource's rarity from ResourceDatabase |
| `RARITY_DROP_MODIFIER` | RDM | float | 0.005-1.0 | Lookup table value |

**RARITY_DROP_MODIFIER Matrix:**

```
RDM[CR][RR] = {
    // CR=1 (common container)
    [1] = { 1: 1.0,  2: 0.6,  3: 0.15, 4: 0.03,  5: 0.005 },
    // CR=2 (uncommon container)
    [2] = { 1: 1.0,  2: 0.8,  3: 0.3,  4: 0.08,  5: 0.02  },
    // CR=3 (rare container)
    [3] = { 1: 1.0,  2: 1.0,  3: 0.5,  4: 0.15,  5: 0.05  },
    // CR=4 (epic container)
    [4] = { 1: 1.0,  2: 1.0,  3: 0.8,  4: 0.3,   5: 0.1   },
    // CR=5 (legendary container)
    [5] = { 1: 1.0,  2: 1.0,  3: 1.0,  4: 0.5,   5: 0.2   }
}
```

**Output Range:** 0.005 (legendary from common) to 1.0 (common from any container)

**Interpretation Rules:**
- Common resources (RR=1) always have 100% modifier — they drop freely from all containers
- Uncommon resources (RR=2) start at 60% from common containers, reach 100% from rare+ containers
- Rare resources (RR=3) require rare+ containers for meaningful drop chance
- Epic resources (RR=4) require epic+ containers for >30% chance
- Legendary resources (RR=5) have maximum 20% chance even from legendary containers

**Example:**
- Query: RDM[CR=4][RR=3] (Epic container, Rare resource)
- Result: 0.8 (80% modifier)
- Interpretation: Epic containers have 80% probability modifier for rare-tier resources

**Edge Cases:**
- If CR < 1 or CR > 5 → Return 0.0, log warning "invalid container rarity"
- If RR < 1 or RR > 5 → Return 0.0, log warning "invalid resource rarity"
- If resource_rarity > container_rarity + 2 → Log debug "unlikely drop (rarity gap > 2)"

---

### Respawn Time Formula

废墟类容器重生时间计算，决定玩家重复探索废墟区域的时机。

```
respawn_time = respawn_time_seconds × zone_modifier × difficulty_modifier
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `respawn_time_seconds` | RTS | float | 60-3600 | Base respawn time from respawn_rules |
| `zone_modifier` | ZM | float | 0.5-2.0 | Zone-specific respawn multiplier (world config) |
| `difficulty_modifier` | DM | float | 0.8-1.5 | Difficulty-based respawn multiplier (balance) |

**Default Zone Modifier Values:**

| Zone Type | ZM Value | Reasoning |
|-----------|----------|-----------|
| Safe Zone (base perimeter) | 0.5 | Fast respawn, encourage local exploration |
| Standard Zone | 1.0 | Baseline respawn |
| Dangerous Zone | 1.5 | Slower respawn, risk premium |
| High-Value Zone | 2.0 | Slowest respawn, rare resource protection |

**Default Difficulty Modifier Values:**

| Difficulty Setting | DM Value | Reasoning |
|--------------------|----------|-----------|
| Easy | 0.8 | Faster respawn, more opportunities |
| Normal | 1.0 | Baseline |
| Hard | 1.2 | Slower respawn, scarcity pressure |
| Survival | 1.5 | Slowest respawn, extreme scarcity |

**Output Range:** 48-10800 seconds (0.8 min to 3 hours max)

**Example:**
- Container: 废墟保险箱 (respawn_time_seconds=600)
- Zone: Dangerous (ZM=1.5)
- Difficulty: Hard (DM=1.2)
- Calculation: `respawn_time = 600 × 1.5 × 1.2 = 1080 seconds (18 minutes)`

**Respawn Conditions (must all be true):**

```
can_respawn = respawn_enabled AND 
              (time_since_scavenged >= respawn_time) AND
              (NOT respawn_requires_zone_leave OR NOT player_in_zone) AND
              (respawn_max_count = 0 OR respawns_so_far < respawn_max_count)
```

**Edge Cases:**
- If respawn_enabled = 0 → No respawn (chest/enemy_drop categories)
- If respawn_time < 60 → Clamp to 60s (minimum respawn time)
- If respawn_time > 3600 → Clamp to 3600s (1 hour maximum)
- If respawns_so_far >= respawn_max_count AND respawn_max_count > 0 → Permanent depletion
- If player stays in zone AND respawn_requires_zone_leave = 1 → Respawn blocked

---

### Alert Chance Formula

打开容器时触发撤退警报的概率计算，服务于Pillar 2（搜打撤节奏）。

```
actual_alert_chance = alert_chance_on_open × stealth_modifier × container_noise_modifier
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `alert_chance_on_open` | ACO | float | 0.0-1.0 | Base alert chance from container definition |
| `stealth_modifier` | SM | float | 0.0-1.5 | Player stealth state modifier (from stealth system) |
| `container_noise_modifier` | CNM | float | 0.0-2.0 | Container type noise modifier (category-based) |

**Stealth Modifier Values:**

| Player State | SM Value | Reasoning |
|--------------|----------|-----------|
| Undetected (stealth active) | 0.0 | Stealth prevents alert |
| Low Visibility | 0.5 | Reduced alert chance |
| Normal Visibility | 1.0 | Baseline |
| High Visibility (near enemies) | 1.5 | Increased alert risk |

**Container Noise Modifier by Category:**

| Category | CNM Value | Reasoning |
|----------|-----------|-----------|
| chest (宝箱) | 1.0 | Standard noise |
| ruin (废墟) | 1.5 | Debris noise, more attention |
| enemy_drop (敌人掉落) | 0.0 | No alert (already in combat context) |

**Rarity Noise Modifier (additional factor):**

| Rarity | Additional Noise | Reasoning |
|--------|------------------|-----------|
| 1-2 (common/uncommon) | ×1.0 | Standard |
| 3-4 (rare/epic) | ×1.2 | Magitech seal release noise |
| 5 (legendary) | ×1.5 | Ancient seal breach noise |

**Full Formula (with rarity):**

```
actual_alert_chance = ACO × SM × CNM × RARITY_NOISE_MODIFIER[container_rarity]
```

**Output Range:** 0.0-2.25 (but clamped to 0.0-1.0 for probability)

**Example:**
- Container: 魔导晶体舱 (ACO=0.25, rarity=4)
- Player: Normal visibility (SM=1.0)
- Category: chest (CNM=1.0)
- Rarity noise: ×1.2
- Calculation: `actual_alert_chance = 0.25 × 1.0 × 1.0 × 1.2 = 0.3 (30%)`
- Interpretation: 30% chance to trigger retreat alert when opening

**Alert Trigger Behavior:**
1. Roll random(0.0, 1.0) against actual_alert_chance
2. If roll <= actual_alert_chance → Trigger retreat alert
3. Retreat alert: 
   - Start retreat countdown acceleration
   - Spawn nearby enemies (alert wave)
   - Play alert audio cue
   - UI shows warning indicator

**Edge Cases:**
- If ACO = 0 → No alert possible (破旧木箱, 废弃柜子)
- If SM = 0 (stealth active) → Alert prevented regardless of ACO
- If actual_alert_chance > 1.0 → Clamp to 1.0 (guaranteed alert)
- If container category = enemy_drop → Alert always 0 (combat context)
- If player in vehicle → Apply additional vehicle_noise_modifier (×1.3)

---

### Min/Max Drop Count Enforcement Formula

掉落数量约束公式，确保生成结果符合容器定义的min_drop_count和max_drop_count范围。

```
final_drop_count = clamp(generated_drop_count, min_drop_count, max_drop_count)
```

**Drop Count Adjustment Rules:**

1. **If generated drops < min_drop_count:**
   ```
   pad_with_lowest_rarity(generated_drops, min_drop_count)
   ```
   - Select lowest rarity entry from drop_table
   - Generate additional drops until count reaches min_drop_count
   - Priority: Fill with common resources (rarity=1) first

2. **If generated drops > max_drop_count:**
   ```
   trim_highest_rarity_first(generated_drops, max_drop_count)
   ```
   - Sort drops by resource rarity (descending)
   - Remove highest rarity drops first
   - Preserve common drops over rare drops
   - Stop when count equals max_drop_count

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `generated_drop_count` | int | 0-10 | Count of successful drop rolls |
| `min_drop_count` | int | 0-5 | Container's minimum required drops |
| `max_drop_count` | int | 1-10 | Container's maximum allowed drops |
| `final_drop_count` | int | min_drop_count to max_drop_count | Adjusted output |

**Example:**
- Container: 军用绿箱 (min=2, max=5)
- Generated drops: 1 (only one entry passed roll)
- Adjustment: Pad with lowest rarity entry → 2 drops
- Final: 2 drops (meets minimum)

**Edge Cases:**
- If min_drop_count = 0 → No minimum enforcement (can produce empty)
- If min_drop_count > max_drop_count → Invalid definition, log error
- If drop_table is empty AND min_drop_count > 0 → Log error, return empty drops
- If all drop_table entries have drop_chance=0 → Only padding mechanism applies

---

### Drop Generation Algorithm (Complete Flow)

综合掉落生成流程，整合上述所有公式。

```gdscript
func generate_drops(container_type_id: int) -> Array[Dictionary]:
    var definition = get_container_definition(container_type_id)
    var drops = []
    
    # Phase 1: Roll each drop table entry
    for entry in definition.drop_table:
        # Get resource rarity from ResourceDatabase
        var resource_rarity = Resources.get_rarity(entry.resource_id)
        var resource_rarity_mod = RARITY_DROP_MODIFIER_RESOURCE[resource_rarity]
        
        # Get container rarity modifier
        var container_rarity = definition.rarity
        var container_mod = RARITY_DROP_MODIFIER[container_rarity][resource_rarity]
        
        # Calculate effective drop chance
        var effective_chance = entry.drop_chance * resource_rarity_mod * container_mod * entry.rarity_modifier
        effective_chance = clamp(effective_chance, 0.0, 1.0)
        
        # Roll for drop
        if randf() <= effective_chance:
            # Generate quantity
            var quantity = randi_range(entry.min_quantity, entry.max_quantity)
            drops.append({"resource_id": entry.resource_id, "quantity": quantity})
    
    # Phase 2: Enforce min/max drop count
    if drops.size() < definition.min_drop_count:
        drops = pad_drops_to_minimum(drops, definition.drop_table, definition.min_drop_count)
    
    if drops.size() > definition.max_drop_count:
        drops = trim_drops_to_maximum(drops, definition.max_drop_count)
    
    return drops

func pad_drops_to_minimum(drops: Array, drop_table: Array, min_count: int) -> Array:
    while drops.size() < min_count:
        var fallback_entry = get_lowest_rarity_entry(drop_table)
        var quantity = randi_range(fallback_entry.min_quantity, fallback_entry.max_quantity)
        drops.append({"resource_id": fallback_entry.resource_id, "quantity": quantity})
    return drops

func trim_drops_to_maximum(drops: Array, max_count: int) -> Array:
    # Sort by rarity descending, remove highest rarity first
    drops.sort_custom(func(a, b): return Resources.get_rarity(a.resource_id) > Resources.get_rarity(b.resource_id))
    while drops.size() > max_count:
        drops.remove_at(0)  # Remove highest rarity
    return drops

func get_lowest_rarity_entry(drop_table: Array) -> Dictionary:
    var lowest_rarity = 999
    var lowest_entry = {}
    for entry in drop_table:
        var rarity = Resources.get_rarity(entry.resource_id)
        if rarity < lowest_rarity:
            lowest_rarity = rarity
            lowest_entry = entry
    return lowest_entry
```

**Performance Notes:**
- Drop generation runs once per container interaction
- Expected execution time: < 5ms for standard drop_table (10 entries)
- ResourceDatabase queries are cached (singleton pattern)
- Random number generation uses Godot's randf()/randi_range()

---

### Formula Summary Table

| Formula | Purpose | Primary Variables | Output |
|---------|---------|-------------------|--------|
| Effective Drop Chance | Determine if resource drops | DC, RRM, CRM, ERM | 0.0-1.0 probability |
| Drop Quantity | Determine amount of resource | min_q, max_q | 1-100 quantity |
| Scavenge Time | Player interaction duration | BST, RTM | 1.0-45.0 seconds |
| Container Rarity Modifier | Cross-rarity probability matrix | CR, RR | 0.005-1.0 modifier |
| Respawn Time | Container refill timing | RTS, ZM, DM | 48-10800 seconds |
| Alert Chance | Retreat trigger probability | ACO, SM, CNM | 0.0-1.0 probability |
| Drop Count Enforcement | Bound generated drops | generated, min, max | bounded count |

## Edge Cases

### 1. Invalid container_type_id Queries

**If container_type_id = 0**: Return `null_container` definition (empty Dictionary with `container_type_id: 0`, `name: "null_container"`). No drop generation, no scavenge interaction. ID 0 is reserved as error fallback per ID Allocation Scheme.

**If container_type_id < 0**: Return `null_container` definition. Log warning `"Invalid container_type_id: [id] (negative value)"`. Negative IDs violate the 0-65535 range constraint.

**If container_type_id > 65535**: Return `null_container` definition. Log warning `"Invalid container_type_id: [id] (out of range)"`. Exceeds 16-bit integer maximum.

**If container_type_id is in valid range but not registered**: Return `null_container` definition. Log warning `"Container type [id] not found in database"`. Example: querying ID 2500 (in future content range 2000-65535) when no definition exists yet.

**If `is_valid_container(container_type_id)` returns false**: All downstream calls (generate_drops, get_drop_table, get_scavenge_time) return empty/default values and log warnings. Prevents silent failures propagating to gameplay logic.

---

### 2. Empty Drop Table

**If `drop_table = []` (empty array)**: `generate_drops()` returns `[]` (no items). Container opens, UI shows "Empty" message, plays `audio_empty` sound if defined. Player wastes scavenge time but receives nothing.

**If all drop_table entries fail their probability rolls**: `generate_drops()` returns `[]`. However, if `min_drop_count > 0`, the algorithm pads with fallback entries per Drop Generation Algorithm (lines 208-212 in Core Rules). Minimum drops are guaranteed even if all rolls fail.

**If `drop_table = []` AND `min_drop_count > 0`: Log error `"Empty drop_table but min_drop_count=[value] — constraint violation"`. Return `[]` (cannot pad from empty table). This is a data definition error that should be caught during database validation, not runtime.

**If container has non-empty drop_table but all entries have `drop_chance = 0.0`: Log warning `"All drop entries have 0% chance — container will always be empty"`. Return `[]` after rolls (no padding possible since no entry qualifies as "lowest rarity fallback").

---

### 3. Drop Count Constraints Violation

**If generated drops exceed `max_drop_count`: Trim drops by removing highest-rarity entries first (preserve common drops). Use `trim_high_rarity_first()` function from Drop Generation Algorithm. This maintains player expectation that common containers yield common items.

**If generated drops are below `min_drop_count`: Pad with lowest-rarity entries from drop_table. Select entry with lowest `resource_id` rarity (query ResourceDatabase.get_rarity()). If multiple entries share lowest rarity, select first in drop_table order. Rationale: ensures minimum reward guarantee for player's time investment.

**If `min_drop_count > max_drop_count` in definition**: Auto-correct at load time: set `max_drop_count = min_drop_count`. Log warning `"Fixed invalid drop count range: min=[min] > max=[max], set max=min"`. Per Field Validation Rule 8.

**If `min_drop_count = 0` AND all rolls fail**: Return `[]`. No padding required. Container may legitimately be empty (design intent for certain containers like "already scavenged" ruins).

**If `min_drop_count = 0` AND `max_drop_count = 0`: Return `[]` always. This defines a "visual-only" container that cannot drop items (used for environmental storytelling). Log info `"Container [id] has zero drop capacity — decorative only"`.

---

### 4. Resource_id References Non-existent Resource

**If drop_table entry contains `resource_id` not found in ResourceDatabase**: Skip that entry entirely during `generate_drops()`. Log error `"Drop entry references missing resource_id: [id] in container [container_id] — entry skipped"`. Do not crash, do not return null.

**If ALL entries in drop_table reference non-existent resources**: Return `[]`. Log critical error `"Container [id] has entirely invalid drop_table — all resource_ids missing"`. This indicates data corruption; trigger system health alert.

**If `get_container_definition()` references `icon_path` pointing to non-existent resource file**: Use fallback icon `res://assets/icons/containers/fallback_container.png`. Log warning `"Container [id] icon not found: [path] — using fallback"`.

**If `audio_open` or `audio_empty` path invalid**: Use silence (no audio played). Log warning `"Container [id] audio file not found: [path] — playing no sound"`.

---

### 5. Drop Chance Boundary Values

**If `drop_chance = 0.0`: Entry never drops. Algorithm skips this entry entirely (no roll performed). Valid for "placeholder" entries in drop_table that may be activated by future events/modifiers.

**If `drop_chance = 1.0`: Entry always drops (100% probability). Roll always succeeds regardless of container rarity or resource rarity modifiers. This is the only case where modifiers do NOT affect outcome.

**If `drop_chance = 0.0` but `rarity_modifier > 0`: Still never drops. 0.0 × any modifier = 0.0. Modifier cannot resurrect a zero-chance entry.

**If `drop_chance = 1.0` and `min_quantity = max_quantity`: Exact quantity guaranteed. No randomization needed.

**If `drop_chance = 1.0` for ALL entries AND sum of min_quantity exceeds player inventory capacity: Drops spill to ground as "loot pile" objects (handled by InventorySystem, not this database). This is a gameplay scenario, not a database error.

---

### 6. Scavenge Interrupted

**If player manually cancels (presses cancel key during scavenge)**: Scavenge stops immediately. Container state unchanged (not opened, not emptied). No drops generated. Progress bar resets. Player can re-initiate scavenge. Per Gameplay Rule 3 in Scavenge Time Rules.

**If player takes damage during scavenge**: Scavenge interrupts immediately. Container state unchanged. Player enters combat state. No drops generated. Rationale: damage is a "force-cancel" signal that the zone is no longer safe.

**If player moves more than `SCAVENGE_CANCEL_DISTANCE` (default 2.0 meters) from container**: Scavenge interrupts. Container state unchanged. Movement indicates player chose to abandon the action.

**If container is destroyed (e.g., by explosion) during scavenge**: Scavenge interrupts. Container removed from world. No drops generated (container destroyed, not opened). Player receives no reward and no penalty beyond time lost.

**If retreat countdown reaches 0 during scavenge**: Scavenge continues until completion OR player-initiated interrupt. Retreat timer does NOT auto-cancel scavenge — player must choose to abandon or risk staying. This is intentional Pillar 2 tension design.

**If scavenge completes but player is incapacitated (e.g., grabbed by enemy) before loot spawns**: Loot spawns at container location as ground items. Player can retrieve after recovery. Loot does NOT disappear — it persists for `GROUND_LOOT_TIMEOUT` (default 120 seconds).

---

### 7. Container Respawn Edge Cases

**If `respawn_max_count > 0` AND `respawns_so_far >= respawn_max_count`: No respawn. Container permanently remains in "scavenged/empty" state. Log info `"Container [instance_id] reached max respawn count [max] — permanent empty state"`. Per Respawn Algorithm.

**If `respawn_requires_zone_leave = 1` AND player remains in zone**: Timer pauses at `respawn_time_seconds` threshold. Respawn only triggers when player exits zone AND timer elapsed. Rationale: prevents "farm loop" where player loots, waits, loots again in same location.

**If `respawn_requires_zone_leave = 0` AND player in zone AND timer elapsed**: Respawn triggers immediately. Player sees container refill in-place. Only valid for specific container designs (e.g., "auto-replenishing supply cache").

**If container is `chest` (category=0) but has `respawn_rules` defined**: Ignore respawn rules entirely. Chests never respawn regardless of configuration. Log warning `"Chest [id] has respawn_rules but category=chest — rules ignored"`. Per Respawn Behavior by Category.

**If `respawn_drop_table_same = 0` AND respawn triggers**: Generate NEW drops from drop_table (full probability reroll). Container may have different contents each respawn cycle.

**If `respawn_drop_table_same = 1` AND respawn triggers**: Restore EXACT same drops from previous scavenge (stored in `container_instance.previous_drops`). Container contents repeat predictably.

**If respawn timer reaches threshold but zone is "locked" (e.g., active combat event)**: Pause respawn until zone unlocks. Respawn does NOT trigger during active gameplay events that would disrupt flow.

---

### 8. Enemy Drop Timeout

**If enemy_drop container exists for 60 seconds without player interaction**: Auto-despawn. Container removed from world. Any unclaimed loot is lost. Log info `"Enemy drop [id] despawned after 60s timeout"`. Per Enemy Drop Catalog timeout column.

**If player begins scavenge on enemy_drop at 55 seconds**: Scavenge completes (takes 1-2 seconds) before timeout. Player receives loot. Timeout resets to 60 seconds AFTER scavenge completes (for boss/elite drops with extended timeout).

**If enemy_drop timeout is extended (e.g., boss_drop with 120s) AND player starts scavenge at 115s**: Scavenge completes, loot received. Timeout extension is intentional for high-value drops.

**If player loots partial items from enemy_drop (e.g., takes 2 of 5 items) AND timeout triggers**: Remaining items despawn. Partially-looted containers still respect timeout. Player must choose: take everything quickly or risk losing leftovers.

**If enemy_drop is in player inventory (picked up as item) AND timeout would trigger**: Timeout does NOT apply to inventory items. Once picked up, the container-as-item persists indefinitely. Timeout only applies to world-placed containers.

---

### 9. Locked Container Without Key

**If `is_lockable = 1` AND player has no matching key item**: Scavenge interaction fails immediately. UI shows "Locked — Requires [key_name]" message. No scavenge timer starts. No drops generated. Player cannot open without key.

**If `is_lockable = 1` AND player has matching key**: Normal scavenge proceeds. Key is NOT consumed (key is reusable per design intent for exploration, not single-use consumable).

**If `is_lockable = 1` for `enemy_drop` (category=2)**: Data validation error. Log critical `"Enemy drop [id] marked as lockable — invalid, enemy drops cannot lock"`. Auto-correct: set `is_lockable = 0` at load. Per Category-Specific Behavior Rules.

**If locked container is destroyed (e.g., explosive damage)**: Container destroyed, no drops. Locked containers cannot be "forced open" by destruction. Rationale: prevents bypassing key requirement via explosives.

**If player attempts to pick up locked container (chest category)**: Pickup succeeds. Locked chest can be carried. Key requirement applies when attempting to open the carried chest in inventory, not during pickup.

---

### 10. Container in PLANNED/DEPRECATED State

**If container_type_id is in reserved range but marked `state: "PLANNED"` in definition**: Return definition normally. `generate_drops()` returns empty array `[]`. UI shows "Coming Soon" placeholder icon. Used for teaser content in patches before full release.

**If container_type_id is in reserved range but marked `state: "DEPRECATED"`**: Return `null_container` definition. Log info `"Container [id] is deprecated — replaced by [replacement_id] if available"`. Deprecated containers are removed from active gameplay but ID remains reserved.

**If container_type_id references deprecated container AND replacement_id is specified**: Query redirects to replacement container. `get_container_definition(deprecated_id)` returns replacement's definition with `"replaced_from": deprecated_id` metadata. Seamless migration for content updates.

**If deprecated container exists in world save data**: Load as replacement container (if replacement_id defined) OR as `null_container` (if no replacement). Old saves do NOT crash; data migrates gracefully.

**If `state: "TESTING"` (ID in 1-99 range)**: Return definition normally. `generate_drops()` works normally. Testing containers are excluded from spawn_weight calculations for world generation. Only appear in dev/debug modes.

**If undefined container_type_id (not PLANNED, not DEPRECATED, simply missing)**: Return `null_container`. This is the default behavior per Edge Case 1 — no special state handling needed for truly missing IDs.

## Dependencies

### Upstream Dependencies (无)

该系统为Foundation层系统，不依赖任何上游系统。所有数据自包含定义。

### Downstream Dependencies

| 下游系统 | 系统ID | 依赖类型 | 接口契约 | 数据流向 |
|----------|--------|----------|----------|----------|
| **搜刮交互系统** | #31 | 硬依赖 | `get_container_definition(id)`, `generate_drops(id)` | 查询容器定义 → 返回属性 + 生成掉落物品 |
| **地图/废墟生成** | #48 | 硬依赖 | `get_ruins()`, `get_chests()`, `spawn_weight` | 查询容器类型列表 → 按权重分布生成世界容器 |
| **敌人生成系统** | #13 | 硬依赖 | `get_enemy_drops()`, `generate_enemy_drop(enemy_id)` | 查询敌人掉落容器 → 生成击杀后掉落 |

### Dependency Layer

```
Foundation Layer (本系统)
├── ContainerDatabase (自包含)
│   ├── 容器类型定义 (无外部引用)
│   ├── 掉落表结构 (引用ResourceDatabase.resource_id)
│   └── 稀有度系统 (自包含定义)
│
└── Downstream: Core/Feature Layer
    ├── 搜刮交互系统 (#31, Core) → 查询+生成掉落
    ├── 地图/废墟生成 (#48, Feature) → 世界分布生成
    └── 敌人生成系统 (#13, Core) → 敌人击杀掉落
```

### Interface Contracts

| 接口方法 | 返回类型 | 被调用系统 | 契约说明 |
|----------|----------|------------|----------|
| `get_container_definition(id)` | Dictionary | 搜刮交互、地图生成、敌人生成 | 返回完整容器定义，无效ID返回null_container |
| `generate_drops(id)` | Array[Dictionary] | 搜刮交互、敌人生成 | 执行掉落算法，返回[{resource_id, quantity}]数组 |
| `get_containers_by_category(cat)` | Array[int] | 地图生成 | 按类别过滤容器ID列表 |
| `get_scavenge_time(id)` | float | 搜刮交互 | 返回搜刮时间（含稀有度修正） |
| `get_rarity(id)` | int | 搜刮交互、地图生成 | 返回容器稀有度等级 |

### Cross-System Data Flow

```
ResourceDatabase (提供资源稀有度)
        ↓
ContainerDatabase (整合资源引用)
        ↓
    ┌───┴───┬───────────────┐
    ↓       ↓               ↓
搜刮交互  地图生成        敌人生成
(掉落生成) (容器分布)     (击杀掉落)
```

### Dependency Notes

1. **软依赖ResourceDatabase**: 掉落表中`resource_id`引用ResourceDatabase定义，但ContainerDatabase可独立加载（缺失资源ID在生成时跳过）
2. **无循环依赖**: Foundation层单向流向Core/Feature层
3. **数据完整性约束**: ContainerDatabase定义验证时需校验所有`resource_id`存在于ResourceDatabase

## Tuning Knobs

以下参数为游戏平衡调整的关键控制点，可在运行时或配置文件中修改以影响玩家体验。

### Time-Based Tuning Knobs

| Knob名称 | 当前值 | 安全范围 | Gameplay效果 | 调整建议 |
|----------|--------|----------|--------------|----------|
| **BASE_SCAVENGE_TIME_CHEST** | 2-5秒 | 1-8秒 | 宝箱类容器搜刮时间。增加→强化时间压力，降低→快速拾取感 | MVP期间保持当前值，若玩家反馈"搜刮太慢"可下调至2-3秒 |
| **BASE_SCAVENGE_TIME_RUIN** | 3-10秒 | 2-15秒 | 废墟类容器搜刮时间。增加→强化废墟探索紧张感 | 与撤退倒计时配合调整，确保玩家需权衡"继续搜刮vs立即撤退" |
| **BASE_SCAVENGE_TIME_ENEMY_DROP** | 1-2秒 | 0.5-3秒 | 敌人掉落拾取时间。增加→强化战斗节奏压力 | 战斗中拾取应快速，不建议超过2秒 |
| **RARITY_TIME_MODIFIER** | {1:1.0, 2:1.2, 3:1.5, 4:2.0, 5:3.0} | 1.0-5.0 | 稀有度时间修正。传奇×3.0→搜刮需30秒，极端压力 | 若legendary搜刮时间过长玩家放弃，可下调至×2.5 |
| **ENEMY_DROP_TIMEOUT** | 60秒 | 30-180秒 | 敌人掉落消失时间。增加→宽松拾取窗口，降低→紧迫感 | Boss掉落使用120秒，精英使用90秒，普通60秒 |

### Drop Rate Tuning Knobs

| Knob名称 | 当前值 | 安全范围 | Gameplay效果 | 调整建议 |
|----------|--------|----------|--------------|----------|
| **RARITY_DROP_MODIFIER** (5×5矩阵) | 见Formulas章节表格 | 0.005-1.0 | 容器稀有度×资源稀有度的掉落概率修正 | 核心平衡参数，谨慎调整。提高legendary容器产出率会降低稀缺感 |
| **MIN_DROP_COUNT_DEFAULT** | 1 | 0-5 | 最小掉落物品数。增加→保证奖励，降低→可能空箱 | 设为0允许"失望感"，设为≥1保证"总有收获" |
| **MAX_DROP_COUNT_DEFAULT** | 3 | 1-10 | 最大掉落物品数。增加→背包压力，降低→简化决策 | 与背包容量配合调整，建议max_drop_count ≤ 背包容量×0.5 |
| **DROP_CHANCE_PADDING_ENABLED** | true | true/false | 是否启用最小掉落填充 | 设为false允许"全roll失败=空箱"的极端情况（增加风险感） |

### Alert/Risk Tuning Knobs

| Knob名称 | 当前值 | 安全范围 | Gameplay效果 | 调整建议 |
|----------|--------|----------|--------------|----------|
| **ALERT_CHANCE_BASE_CHEST** | 0%-25% | 0%-50% | 宝箱打开触发警报概率 | 增加强化风险感，但过度会抑制探索欲望 |
| **ALERT_CHANCE_BASE_RUIN** | 0%-40% | 0%-60% | 废墟打开触发警报概率 | 异变体巢穴40%为高风险标杆 |
| **ALERT_CHANCE_BASE_ENEMY_DROP** | 0% | 0% | 敌人掉落不触发警报（战斗语境） | 保持为0，战斗中无需额外警报压力 |
| **CONTAINER_NOISE_MODIFIER_CHEST** | 1.0 | 0.5-2.0 | 宝箱噪音修正 | 增加→警报概率上升 |
| **CONTAINER_NOISE_MODIFIER_RUIN** | 1.5 | 0.5-2.5 | 废墟噪音修正（更高） | 废墟搜刮比宝箱更"吵"，符合废墟环境设定 |
| **RARITY_NOISE_MODIFIER** | {1-2:1.0, 3-4:1.2, 5:1.5} | 1.0-2.0 | 稀有度噪音修正（魔导封印释放） | 高稀有度容器更"吵"，符合魔导科技设定 |

### Respawn Tuning Knobs

| Knob名称 | 当前值 | 安全范围 | Gameplay效果 | 调整建议 |
|----------|--------|----------|--------------|----------|
| **RESPAWN_TIME_DEFAULT_RUIN** | 300秒(5分钟) | 60-3600秒 | 废墟容器重生时间 | 短→鼓励重复探索，长→资源稀缺感 |
| **RESPAWN_ZONE_MODIFIER_SAFE** | 0.5 | 0.3-1.0 | 安全区域重生加速 | 安全区重生快，鼓励周边探索 |
| **RESPAWN_ZONE_MODIFIER_DANGEROUS** | 1.5 | 1.0-2.5 | 危险区域重生减慢 | 高风险区域资源更稀缺 |
| **RESPAWN_MAX_COUNT_DEFAULT** | 0(无限) | 0-10 | 区域最大重生次数 | 设限→永久耗尽机制，增加长期压力 |

### Tuning Knob Summary Matrix

| 调整维度 | 主要Knob | Gameplay支柱 | 调整频率 |
|----------|----------|--------------|----------|
| **时间压力** | BASE_SCAVENGE_TIME + RARITY_TIME_MODIFIER | Pillar 2 (搜打撤节奏) | 高（核心体验） |
| **奖励满足感** | RARITY_DROP_MODIFIER + MIN/MAX_DROP_COUNT | Pillar 2 (风险vs收益) | 中（平衡调整） |
| **风险紧张感** | ALERT_CHANCE系列 + NOISE_MODIFIER | Pillar 2 (搜刮决策) | 中（难度调整） |
| **探索节奏** | RESPAWN_TIME + ZONE_MODIFIER | Pillar 2 + Pillar 1 | 低（长期节奏） |

### Tuning Implementation Notes

1. **运行时配置**: 所有Knob存储在`config/container_tuning.cfg`资源文件，支持热重载（开发模式）
2. **调试工具**: 通过`Containers.set_tuning_knob(name, value)`临时调整（仅Debug模式）
3. **版本控制**: 调整Knob需记录变更日志，追踪玩家反馈数据
4. **安全边界**: 超出安全范围的值触发警告日志，但仍允许执行（极端测试用）

## Visual/Audio Requirements

本系统定义容器视觉外观和音效需求，服务于Pillar 4（魔导科技美学）和Pillar 2（搜打撤节奏）。所有视觉/audio设计需符合Art Bible原则。

### Container Visual Themes (魔导/军用/废墟/异变)

| Visual Theme | 主题ID | 视觉风格 | 主色调 | 形状语言 | Art Bible参考 |
|--------------|--------|----------|--------|----------|---------------|
| **魔导科技** | 0 | 赛博朋克魔导风格：霓虹符文电路、魔力晶石嵌入、金属符文刻蚀 | 霓虹蓝 #00D4FF + 秘银银 #B8C4CE | 直线+锐角（电路网格）+ 发光边缘（符文电路） | Art Bible Section 3: 玩家科技风格 |
| **军用废土** | 1 | 废土军用风格：锈蚀金属、军用标识、补给舱质感 | 锈色 #8B4513 + 破损蓝 #4A6B8A | 方块+直线（军用标准）+ 凸起附件（补给舱轮廓） | Art Bible Section 6: 废墟建筑风格 |
| **废墟衰败** | 2 | 末世衰败风格：腐烂木质、坍塌结构、生活痕迹残留 | 锈色 #8B4513 + 天空灰 #4A5568 | 不规则曲线（衰败）+ 破碎直线（废墟） | Art Bible Section 6: 环境衰败质感 |
| **异变腐化** | 3 | 虫族/克苏鲁腐化风格：生物发光、触须附着、深渊渗透 | 腐烂绿 #556B2F + 深渊紫黑 #1A0A2E | 有机曲线（蠕动）+ 扭曲形状（克苏鲁渗透） | Art Bible Section 5: 虫族/克苏鲁风格 |

### Rarity Glow Effects

| Rarity | 发光等级 | 发光颜色 | 发光范围 | 发光动画 | Art Bible参考 |
|--------|----------|----------|----------|----------|---------------|
| **1 (Common)** | 无发光 | — | — | — | 纯视觉纹理，无特殊效果 |
| **2 (Uncommon)** | 边缘微光 | 霓虹蓝 #00D4FF | 2-4像素边缘 | 恒定低亮度 | Art Bible: 霓虹蓝边缘发光基础 |
| **3 (Rare)** | 中等发光 | 霓虹蓝 #00D4FF | 4-8像素范围 | 恒定中亮度 | Art Bible: 魔导晶石发光质感 |
| **4 (Epic)** | 强发光+脉动 | 霓虹蓝 + 火焰橙边缘 | 8-12像素 | 脉动动画(0.8s周期) | Art Bible: 警告色火焰橙 + 稳定冷光霓虹蓝 |
| **5 (Legendary)** | 全身发光+特效 | 金色 #FFD700 + 霓虹蓝 | 12-16像素全容器 | 脉动+光芒放射(粒子) | Art Bible: 资源/奖励语义色 + 霓虹蓝 |

**Glow Shader Specification:**

```gdshader
// container_glow.gdshader - 稀有度发光效果
shader_type canvas_item;

uniform int rarity : hint_range(1, 5) = 1;
uniform vec4 glow_color : source_color = vec4(0.0, 0.83, 1.0, 1.0); // 霓虹蓝
uniform float glow_intensity : hint_range(0.0, 1.0) = 0.0;
uniform float pulse_speed : hint_range(0.5, 2.0) = 1.0;

void fragment() {
    COLOR = texture(TEXTURE, UV);
    
    if (rarity >= 2) {
        float base_glow = glow_intensity * (rarity - 1) * 0.25;
        
        // Epic/Legendary脉动
        if (rarity >= 4) {
            base_glow *= 0.7 + 0.3 * sin(TIME * pulse_speed * TWO_PI);
        }
        
        // Legendary光芒放射（边缘效果）
        if (rarity == 5) {
            float edge_dist = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
            base_glow *= smoothstep(0.0, 0.15, edge_dist);
        }
        
        COLOR.rgb += glow_color.rgb * base_glow;
    }
}
```

### Open Animation Specifications

| Animation类型 | 持续时间 | 动画曲线 | 视觉元素 | Art Bible参考 |
|---------------|----------|----------|----------|---------------|
| **宝箱打开** | 0.5秒 | ease_out_quad | 顶盖翻转180° + 内容显示（粒子烟雾） | 废土金属质感翻转 |
| **废墟搜索** | 0.8秒 | linear + 轻微抖动 | 手部搜索动画（循环）+ 碎屑飘落 | 废墟衰败碎屑 |
| **敌人掉落拾取** | 0.3秒 | ease_in_quad | 资源飞向玩家 + 消失闪光 | 快速拾取反馈 |
| **魔导封印解除** | 1.0秒 | ease_out_back + 符文脉动 | 符文发光→消退→开箱 | 赛博魔导符文动画 |
| **异变体巢穴突破** | 1.5秒 | ease_in_out + 腐化动画 | 触须收缩→内容暴露 | 虫族有机质感动画 |

**Animation State Machine:**

```
States: CLOSED → OPENING → OPEN → SCAVENGED
- CLOSED: 显示关闭状态sprite
- OPENING: 播放开箱动画（基于visual_theme）
- OPEN: 显示打开状态sprite + 发光粒子（rarity发光）
- SCAVENGED: 显示空状态sprite（废墟类）或消失（宝箱类）
```

### Audio Cues

| Audio事件 | 音效类型 | 音效特征 | 音效路径示例 | Art Bible参考 |
|-----------|----------|----------|--------------|---------------|
| **普通开箱** | 机械金属声 | 短促金属碰撞 + 轻微回响 | `audio/container/chest_open_wood.wav` | 废土金属质感 |
| **魔导开箱** | 魔导能量声 | 霓虹嗡鸣 + 符文释放声 | `audio/container/magitech_unlock.ogg` | 赛博魔导霓虹嗡鸣 |
| **异变开箱** | 有机撕裂声 | 触须收缩 + 粘液声 | `audio/container/mutant_nest_open.wav` | 虫族有机质感 |
| **空容器** | 空荡回声 | 短促空洞声 + 轻微失望感 | `audio/container/empty_hollow.wav` | 废墟空荡感 |
| **稀有掉落** | 稀有音效 | 金色铃音 + 霓虹余韵 | `audio/container/rare_drop_chime.ogg` | Art Bible: 资源/奖励音效风格 |
| **传奇掉落** | 传奇音效 | 金色交响 + 光芒释放 | `audio/container/legendary_drop_fanfare.ogg` | Art Bible: 极端奖励音效 |
| **警报触发** | 警报声 | 火焰橙警报音 + 符文闪烁声 | `audio/alert/container_alert_trigger.wav` | Art Bible: 警告状态火焰橙 |

**Audio Implementation:**

```gdscript
# ContainerAudioPlayer.gd
func play_open_sound(container_type_id: int, rarity: int, is_empty: bool):
    var definition = Containers.get_container_definition(container_type_id)
    
    # 基础开箱音效（按visual_theme）
    var base_sound = _get_theme_open_sound(definition.visual_theme)
    Audio.play_at_position(base_sound, container_position)
    
    # 空容器特殊音效
    if is_empty:
        Audio.play_at_position("audio/container/empty_hollow.wav", container_position)
        return
    
    # 稀有掉落音效叠加
    if rarity >= 3:
        Audio.play_delayed("audio/container/rare_drop_chime.ogg", 0.3)
    if rarity >= 5:
        Audio.play_delayed("audio/container/legendary_drop_fanfare.ogg", 0.3)
```

### Alert Trigger Visual/Audio

| Alert阶段 | 视觉效果 | 音效 | HUD反馈 | Art Bible参考 |
|-----------|----------|------|----------|---------------|
| **警报触发瞬间** | 容器周围火焰橙光环脉冲 | 警报触发音 | 无HUD显示（世界内效果） | Art Bible: 火焰橙警告色 |
| **警报持续** | 容器上方警告图标闪烁 | 警报持续低鸣 | 撤退倒计时加速提示 | Art Bible: 符文闪烁警告 |
| **敌人生成** | 附近敌人出现闪光 | 敌人spawn声 | 小地图敌人标记 | Art Bible: 阵营识别色 |

**Alert Visual Specification:**

```gdshader
// alert_glow.gdshader - 警报触发效果
shader_type canvas_item;

uniform float alert_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 alert_color : source_color = vec4(1.0, 0.42, 0.21, 1.0); // 火焰橙 #FF6B35

void fragment() {
    COLOR = texture(TEXTURE, UV);
    
    if (alert_intensity > 0.0) {
        float pulse = 0.5 + 0.5 * sin(TIME * 4.0 * TWO_PI); // 快速脉动
        COLOR.rgb += alert_color.rgb * alert_intensity * pulse * 0.5;
    }
}
```

### Cross-Reference: Art Bible Alignment

| 容器视觉需求 | Art Bible原则 | 合规检查 |
|--------------|---------------|----------|
| **魔导科技主题** | 赞博朋克魔导美学 (Section 1) | ✓ 霓虹蓝发光边缘，符文电路纹理 |
| **军用废土主题** | 废土衰败质感 (Section 6) | ✓ 锈色主色调，军用方块形状 |
| **废墟衰败主题** | 环境几何 (Section 3) | ✓ 不规则曲线，衰败纹理 |
| **异变腐化主题** | 虫族有机恐怖 + 克苏鲁深渊渗透 (Section 1/5) | ✓ 腐烂绿+深渊紫黑，触须蠕动 |
| **稀有度发光** | 霓虹蓝+火焰橙+金色语义色 (Section 4) | ✓ 稀有=霓虹蓝，警告=火焰橙，传奇=金色 |
| **警报效果** | 警告状态视觉 (Section 4/7) | ✓ 火焰橙闪烁，符文边框，抢夺焦点 |
| **音效风格** | 数字绘画风格→音频风格映射 | ✓ 金属机械声→废土质感，霓虹嗡鸣→魔导科技 |

### Asset Naming Convention

| Asset类型 | 命名格式 | 示例 |
|-----------|----------|------|
| **容器Sprite** | `container_[theme]_[rarity].png` | `container_magitech_rare.png` |
| **发光Shader** | `container_glow.gdshader` | — |
| **开箱音效** | `container_open_[theme].wav` | `container_open_ruin.wav` |
| **掉落音效** | `container_drop_[rarity].ogg` | `container_drop_legendary.ogg` |
| **警报音效** | `container_alert.wav` | — |

### Visual/Audio Implementation Priority

| 优先级 | Asset | MVP必需 | 原因 |
|--------|-------|---------|------|
| **P0** | Common容器sprite (4主题) | ✓ | 基础容器可视化 |
| **P0** | 普通开箱音效 (4主题) | ✓ | 基础交互反馈 |
| **P1** | Rare发光shader | ✓ | 稀有度识别核心 |
| **P1** | 稀有掉落音效 | ✓ | 奖励满足感 |
| **P2** | 警报触发效果 | Vertical Slice | 风险反馈（可延后） |
| **P2** | Epic/Legendary特效 | Vertical Slice | 极端奖励反馈（可延后） |

## UI Requirements

### UI Elements Inventory

| UI Element ID | Element Type | Content Source | Display Context | Trigger Condition |
|---------------|--------------|----------------|-----------------|-------------------|
| `UI-CONT-001` | Container Tooltip | `ContainerDatabase.get_container_definition()` | Hover/focus on world container | Player proximity < 3m OR cursor over container |
| `UI-CONT-002` | Scavenge Progress Bar | `scavenge_time_seconds × rarity_modifier` | Screen center/bottom | Scavenge interaction initiated |
| `UI-CONT-003` | Drop Result Popup | `generate_drops()` output | Screen center overlay | Scavenge completes successfully |
| `UI-CONT-004` | Empty Container Feedback | N/A (no drops generated) | Container location tooltip | `generate_drops()` returns empty array |
| `UI-CONT-005` | Locked Container Message | `is_lockable` + key_name from InventorySystem | Container tooltip | Player attempts locked container without key |
| `UI-CONT-006` | Alert Warning Indicator | `alert_chance_on_open` roll result | HUD overlay (top) | Alert triggered during scavenge |
| `UI-CONT-007` | Retreat Countdown UI | RetreatSystem integration | HUD overlay (top-right) | Alert triggers countdown acceleration |
| `UI-CONT-008` | Rarity Visual Border | `rarity` field | Container sprite outline | Container in world or inventory |
| `UI-CONT-009` | Drop Item Cards | `resource_id`, `quantity`, ResourceDatabase | Drop Result Popup | Each generated drop item |
| `UI-CONT-010` | Respawn Timer (Debug) | `respawn_rules.respawn_time_seconds` | Container tooltip (dev mode) | Dev mode enabled, scavenged ruin |

---

### UI-CONT-001: Container Tooltip

**Display Position**: Above container sprite, anchored to container world position

**Content Layout**:
```
┌─────────────────────────────┐
│ [Container Display Name]     │ ← display_name (localized)
│ ─────────────────────────── │
│ Rarity: ★★☆☆☆ [Uncommon]    │ ← rarity (1-5 stars + color)
│ Category: [Chest/Ruin/Drop]  │ ← category enum name
│ Scavenge Time: ~3.6s         │ ← effective_scavenge_time
│ Alert Risk: LOW (5%)         │ ← alert_chance_on_open
│ ─────────────────────────── │
│ [Possible Contents...]       │ ← drop_table summary (optional)
│ • Iron Ore (80%)             │
│ • Magitech Core (30%)        │
└─────────────────────────────┘
```

**Content Source Mapping**:
| Tooltip Field | Data Source | Transformation |
|---------------|-------------|----------------|
| Display Name | `get_display_name(container_type_id)` | Localization lookup |
| Rarity Stars | `get_rarity(container_type_id)` | Map 1-5 to ★ symbols |
| Rarity Color | `rarity` | Use RARITY_COLOR table (Core Rules line 261-267) |
| Category Label | `get_category(container_type_id)` | Enum to localized string |
| Scavenge Time | `scavenge_time_seconds × RTM[container_rarity]` | Formula calculation |
| Alert Risk | `alert_chance_on_open × CNM × SM` | Contextual modifier |
| Drop Preview | `drop_table` entries | Probability percentage display |

**Interaction**:
- Appears on mouse hover (PC) or focus (gamepad)
- Auto-hides after 3 seconds of no interaction
- Click/press to initiate scavenge (if within range)

---

### UI-CONT-002: Scavenge Progress Bar

**Display Position**: Bottom-center of screen, above HUD

**Visual Design**:
```
┌─────────────────────────────────────────────┐
│   Scavenging [魔导晶体舱]...                  │
│   ████████████████░░░░░░░░░░░░░░░░░░░░░░░  │  ← Progress bar
│   7.5s / 7.5s                               │  ← Time remaining
│   [Press ESC to cancel]                     │
└─────────────────────────────────────────────┘
```

**Progress Calculation**:
```
progress_ratio = elapsed_time / effective_scavenge_time
remaining_time = effective_scavenge_time - elapsed_time
```

**Visual Feedback**:
| Progress Stage | Bar Fill Color | Animation |
|----------------|----------------|-----------|
| 0-25% | Gray #888888 | Static fill |
| 25-50% | White #FFFFFF | Slight glow |
| 50-75% | Container rarity color | Pulsing glow |
| 75-99% | Rarity color + glow intensify | Accelerated pulse |
| 100% | Green #00FF00 | Completion flash |

**Cancel Prompt**: Always visible during scavenge. Shows keybinding for cancel action.

**Interrupt States**:
- Damage received → Bar flashes red, shows "Interrupted!" message
- Movement away → Bar fades, shows "Cancelled - Moved away"
- Manual cancel → Bar slides down, shows "Cancelled"

---

### UI-CONT-003: Drop Result Popup

**Display Position**: Screen center, modal overlay with backdrop dimming

**Layout Structure**:
```
┌─────────────────────────────────────────────────────┐
│   ╔═════════════════════════════════════════════╗   │
│   ║       [魔导晶体舱] Contents                  ║   │
│   ╠═════════════════════════════════════════════╣   │
│   ║                                              ║   │
│   ║   ┌─────────┐  ┌─────────┐  ┌─────────┐     ║   │
│   ║   │ [Icon]  │  │ [Icon]  │  │ [Icon]  │     ║   │
│   ║   │ Iron Ore│  │Magitech │  │Crystal  │     ║   │
│   ║   │   ×5    │  │ Core×1  │  │ Shard×2 │     ║   │
│   ║   │ [★★☆]  │  │ [★★★]  │  │ [★★★★] │     ║   │
│   ║   └─────────┘  └─────────┘  └─────────┘     ║   │
│   ║                                              ║   │
│   ║   [Take All]  [Leave Items]  [Close]        ║   │
│   ╚═════════════════════════════════════════════╝   │
└─────────────────────────────────────────────────────┘
```

**Content Source**:
| Card Field | Data Source | Notes |
|------------|-------------|-------|
| Icon | `Resources.get_icon(resource_id)` | ResourceDatabase lookup |
| Name | `Resources.get_display_name(resource_id)` | Localized |
| Quantity | `drop.quantity` | From generate_drops() |
| Rarity Stars | `Resources.get_rarity(resource_id)` | Per-item rarity display |

**Interaction Buttons**:
| Button | Action | Outcome |
|--------|--------|---------|
| Take All | Add all drops to inventory | If full → overflow to ground loot |
| Leave Items | Close popup, drops remain as ground loot | Timeout applies (enemy_drop) |
| Close | Same as Leave Items | Standard dismiss |

**Animation**:
- Popup slides up from bottom (0.3s ease-out)
- Drop cards appear sequentially (0.1s stagger per card)
- Rarity glow effect on high-value items (rarity >= 3)
- Sound: `audio_open` from container definition + per-item pickup sounds

---

### UI-CONT-004: Empty Container Feedback

**Display Position**: Container tooltip area (replaces normal tooltip)

**Visual Design**:
```
┌─────────────────────────────┐
│ [Empty Container]           │ ← Grayed display_name
│ ─────────────────────────── │
│ ♢ This container is empty   │ ← Empty message
│                             │
│ [Rarity border fades]       │ ← Visual state change
└─────────────────────────────┘
```

**Audio**: `audio_empty` sound if defined in container definition

**State Persistence**:
- Empty state persists until respawn (ruin category)
- Empty chest disappears from world (chest category)
- Enemy drop despawns on timeout (enemy_drop category)

---

### UI-CONT-005: Locked Container Message

**Display Position**: Container tooltip area, red highlight

**Visual Design**:
```
┌─────────────────────────────────────────┐
│ [魔导储能器] - LOCKED                     │ ← "LOCKED" in red
│ ─────────────────────────────────────── │
│ 🔒 Requires: [Military Key Card]        │ ← Key item name
│                                         │
│ You do not have the required key.       │ ← Inventory check result
│                                         │
│ [Find Key] [Force Open (Impossible)]    │ ← Action hints
└─────────────────────────────────────────┘
```

**Content Source**:
| Message Field | Data Source | Notes |
|---------------|-------------|-------|
| Container Name | `get_display_name(container_type_id)` | Normal tooltip |
| Lock Status | `is_lockable` | Boolean check |
| Key Name | `key_item_id` → InventorySystem | Key definition lookup |
| Has Key | `InventorySystem.has_item(key_item_id)` | Player inventory check |

**Interaction**:
- Scavenge action blocked
- No progress bar starts
- Player must obtain key first
- Locked chest can be picked up (key check applies to opening, not pickup)

---

### UI-CONT-006: Alert Warning Indicator

**Display Position**: HUD top overlay, red pulsing banner

**Visual Design**:
```
┌─────────────────────────────────────────────────────────┐
│ ⚠ ALERT TRIGGERED! Enemies approaching!                 │
│ ████████████████████████████████████████████████████    │ ← Threat bar
│ Retreat countdown accelerated: 30s → 15s remaining       │
└─────────────────────────────────────────────────────────┘
```

**Content Source**:
| Warning Field | Data Source | Notes |
|---------------|-------------|-------|
| Alert Status | `alert_chance_on_open` roll success | Random roll result |
| Threat Level | Spawned enemy count | CombatSystem integration |
| Countdown | RetreatSystem.get_remaining_time() | Cross-system query |

**Visual Effects**:
- Red pulsing background (#FF0000 at 50% opacity, pulse 0.5s interval)
- Screen edge vignette (red glow from corners)
- Audio: Alert siren sound + enemy spawn audio cues

**Behavior**:
- Appears immediately on alert trigger
- Persists until countdown ends OR player reaches safe zone
- Can stack if multiple alerts triggered (threat bar increases)

---

### UI-CONT-007: Retreat Countdown UI (Alert Trigger)

**Display Position**: HUD top-right corner, below alert warning if active

**Visual Design**:
```
┌───────────────────────┐
│ RETREAT TIMER         │
│ ┌─────────────────┐   │
│ │    15s ← 30s    │   │ ← Accelerated countdown
│ └─────────────────┘   │
│ ██████░░░░░░░░░░░░    │ ← Progress bar
└───────────────────────┘
```

**Behavior on Alert**:
- Countdown timer accelerated (x2 speed or halved remaining)
- Visual urgency: timer turns red, bar fills faster
- Audio: ticking sound increases tempo

---

### UI-CONT-008: Rarity Visual Border

**Display Position**: Container sprite outline in world

**Rarity Color Table** (from Core Rules section):
| Rarity | Border Color | Glow Effect | Opacity |
|--------|--------------|-------------|---------|
| 1 | #CCCCCC (gray) | None | 100% |
| 2 | #00FF00 (green) | Edge glow (2px) | 100% |
| 3 | #0088FF (blue) | Medium glow (4px) | 100% |
| 4 | #AA00FF (purple) | Strong glow + pulse (6px) | 100% |
| 5 | #FFD700 (gold) | Full glow + particles (8px) | 100% |

**Animation**:
- Rarity 3+: Glow pulsates at 1s interval
- Rarity 4+: Particles emanate from container (VFX integration)
- Rarity 5: Special "legendary" shader effect (distortion + sparkles)

---

### UI-CONT-009: Drop Item Cards

**Card Design per Item**:
```
┌─────────────────────┐
│   [Resource Icon]   │ ← 64x64 px sprite
│                     │
│   [Resource Name]   │ ← Localized, truncated if long
│                     │
│   Quantity: ×[n]    │ ← Quantity from drop
│                     │
│   [★★★☆☆]          │ ← Resource rarity stars
│                     │
│   [Hover: Details]  │ ← Hover shows full tooltip
└─────────────────────┘
```

**Hover Detail Expansion**:
| Hover Content | Data Source |
|---------------|-------------|
| Full Description | `Resources.get_description(resource_id)` |
| Stack Limit | `Resources.get_stack_limit(resource_id)` |
| Sell Value | `Resources.get_sell_value(resource_id)` |

---

### UI-CONT-010: Respawn Timer (Debug Mode)

**Display Position**: Container tooltip (additional debug section)

**Visual Design**:
```
┌─────────────────────────────────┐
│ [DEV MODE]                      │
│ Respawn Timer: 285s remaining   │ ← respawn_time - elapsed
│ Respawns So Far: 3 / 5          │ ← respawns_so_far / max_count
│ Zone Leave Required: Yes        │ ← respawn_requires_zone_leave
└─────────────────────────────────┘
```

**Availability**: Only visible when `DEBUG_MODE = true` or dev build

---

### UI Accessibility Requirements

| Requirement | Implementation |
|-------------|----------------|
| Gamepad Navigation | All popups focusable with D-pad, buttons selectable with A button |
| Keyboard Navigation | Tab cycles through drop cards, Enter confirms selection |
| Color Blind Support | Rarity stars + text labels accompany color coding |
| Screen Reader | Tooltip content readable by accessibility API (Godot 4.5+ AccessKit) |
| High Contrast Mode | Border colors use high-contrast variants when enabled |

---

### UI Event Flow Diagram

```
[Player approaches container]
       │
       ▼
[UI-CONT-001: Tooltip appears]
       │
       ▼
[Player presses Interact key]
       │
       ├─► [is_lockable = 1 AND no key]
       │        │
       │        ▼
       │   [UI-CONT-005: Locked message]
       │
       ├─► [Normal scavenge start]
       │        │
       │        ▼
       │   [UI-CONT-002: Progress bar]
       │        │
       │        ├─► [alert_chance roll success]
       │        │        │
       │        │        ▼
       │        │   [UI-CONT-006: Alert warning]
       │        │        │
       │        │        ▼
       │        │   [UI-CONT-007: Countdown accelerated]
       │        │
       │        ├─► [interrupt (damage/move/cancel)]
       │        │        │
       │        │        ▼
       │        │   [Progress bar shows "Cancelled"]
       │        │
       │        ▼
       │   [Scavenge completes]
       │        │
       │        ├─► [drops = empty array]
       │        │        │
       │        │        ▼
       │        │   [UI-CONT-004: Empty feedback]
       │        │
       │        ▼
       │   [UI-CONT-003: Drop popup]
       │        │
       │        ▼
       │   [Player selects items]
       │
       ▼
[Container state updated]
```

## Acceptance Criteria

### Pass/Fail Threshold

| Category | Pass Threshold | Total Tests | Blocking Level |
|----------|----------------|-------------|----------------|
| Database Initialization | 100% (5/5) | 5 | BLOCKING — Database must load correctly before any gameplay |
| Query API Validation | 100% (10/10) | 10 | BLOCKING — API contract must be reliable for downstream systems |
| Drop Generation Correctness | 100% (5/5) | 5 | BLOCKING — Core gameplay mechanic must be mathematically correct |
| Cross-System Integration | 80% (4/5) | 5 | ADVISORY — Integration tests may have acceptable edge cases |
| Edge Case Handling | 90% (4.5/5) | 5 | ADVISORY — Edge cases important but non-blocking for MVP |
| Performance | 100% (3/3) | 3 | BLOCKING — Performance budget must be met |

**Overall Pass Threshold**: 95% (32/34 tests minimum) — All BLOCKING categories must pass 100%

---

### Database Initialization (AC-001 to AC-005)

#### AC-001: Singleton Autoload Registration

**Given**: The game engine loads the project with ContainerDatabase configured as Autoload
**When**: The game session starts
**Then**: `Containers` singleton is accessible globally via `Containers.get_container_definition()`
**And**: No null reference errors occur on first query

| Test ID | Test Method | Expected Result |
|---------|-------------|-----------------|
| AC-001-UNIT | `assert(Containers != null)` | Singleton instance exists |
| AC-001-INT | `Containers.get_container_definition(101)` returns valid Dictionary | First query succeeds |

---

#### AC-002: Container Type Definitions Loaded

**Given**: ContainerDatabase loads from `data/containers.json` (or equivalent resource file)
**When**: All container type definitions are parsed
**Then**: All 16 MVP container types (IDs 101-102, 201-202, 301-302, 501-503, 601-602, 701, 1001-1002, 1101, 1201, 1501-1502) are registered
**And**: Each definition contains all required fields per Core Rules section

| Test ID | Test Method | Expected Result |
|---------|-------------|-----------------|
| AC-002-UNIT | `Containers.get_registered_count() == 16` | All MVP containers loaded |
| AC-002-UNIT | `Containers.is_valid_container(101)` returns true | Sample ID validates |
| AC-002-UNIT | `definition.has("container_type_id")` for each container | Required fields present |

---

#### AC-003: ID Uniqueness Validation

**Given**: ContainerDatabase loads container type definitions
**When**: ID uniqueness check runs during initialization
**Then**: No duplicate `container_type_id` values exist
**And**: Log warning if duplicate detected, reject duplicate entry

| Test ID | Test Method | Expected Result |
|---------|-------------|-----------------|
| AC-003-UNIT | No duplicate IDs in `_validate_definitions()` | Validation passes |
| AC-003-NEG | Attempt to load definition with duplicate ID → Warning logged, entry rejected | Duplicate handled |

---

#### AC-004: Field Validation on Load

**Given**: ContainerDatabase parses each container definition
**When**: Field validation rules from Core Rules section apply
**Then**: Invalid fields are auto-corrected with warning logs
**And**: Definition with critical errors (missing required fields) is rejected

| Test ID | Test Method | Expected Result |
|---------|-------------|-----------------|
| AC-004-UNIT | `min_drop_count > max_drop_count` auto-corrected | max = min |
| AC-004-UNIT | `scavenge_time_seconds < 1.0` → clamped to 1.0 | Minimum enforced |
| AC-004-NEG | Definition with missing `container_type_id` → Rejected, error logged | Critical error handled |

---

#### AC-005: Null Container Fallback

**Given**: An invalid container_type_id is queried (0, negative, >65535, or unregistered)
**When**: `get_container_definition(invalid_id)` is called
**Then**: Returns `null_container` definition (ID=0, name="null_container")
**And**: Warning log written with invalid ID value

| Test ID | Test Method | Expected Result |
|---------|-------------|-----------------|
| AC-005-UNIT | `Containers.get_container_definition(9999)` returns null_container | Fallback works |
| AC-005-UNIT | `Containers.get_container_definition(-1)` returns null_container | Negative ID handled |
| AC-005-UNIT | `Containers.get_container_definition(70000)` returns null_container | Out-of-range handled |

---

### Query API Validation (AC-006 to AC-010)

#### AC-006: Basic Lookup Methods

**Given**: ContainerDatabase is loaded with valid definitions
**When**: Basic lookup methods are called with valid container_type_id
**Then**: Correct values are returned for each method

| Test ID | Method | Input | Expected Output |
|---------|--------|-------|-----------------|
| AC-006-UNIT | `get_container_definition(101)` | ID 101 | Full Dictionary with all fields |
| AC-006-UNIT | `get_container_name(101)` | ID 101 | "wooden_chest_basic" |
| AC-006-UNIT | `get_display_name(101)` | ID 101 | Localized "破旧木箱" |
| AC-006-UNIT | `get_category(101)` | ID 101 | 0 (chest) |
| AC-006-UNIT | `get_rarity(101)` | ID 101 | 1 (common) |

---

#### AC-007: Property Query Methods

**Given**: ContainerDatabase is loaded
**When**: Property-specific methods are called
**Then**: Correct property values returned

| Test ID | Method | Input | Expected Output |
|---------|--------|-------|-----------------|
| AC-007-UNIT | `get_scavenge_time(301)` | ID 301 (rarity=3) | 5.0 × 1.5 = 7.5 seconds |
| AC-007-UNIT | `get_drop_table(201)` | ID 201 | Array of drop entries |
| AC-007-UNIT | `get_respawn_rules(501)` | ID 501 | Dictionary with respawn config |
| AC-007-UNIT | `get_alert_chance(701)` | ID 701 | 0.4 (40%) |

---

#### AC-008: Category Filter Methods

**Given**: ContainerDatabase has containers across all categories
**When**: Category filter methods are called
**Then**: Correct ID arrays returned for each category

| Test ID | Method | Expected Output |
|---------|--------|-----------------|
| AC-008-UNIT | `get_chests()` | Array of IDs in 100-499 range |
| AC-008-UNIT | `get_ruins()` | Array of IDs in 500-999 range |
| AC-008-UNIT | `get_enemy_drops()` | Array of IDs in 1000-1499 range |
| AC-008-UNIT | `get_containers_by_category(0)` | Same as get_chests() |

---

#### AC-009: Rarity Filter Methods

**Given**: ContainerDatabase has containers at all rarity levels
**When**: Rarity filter method is called
**Then**: Correct ID arrays returned for specified rarity

| Test ID | Method | Expected Output |
|---------|--------|-----------------|
| AC-009-UNIT | `get_containers_by_rarity(1)` | IDs with rarity=1 (101, 501, 502, 1001) |
| AC-009-UNIT | `get_containers_by_rarity(4)` | IDs with rarity=4 (302, 701, 1201) |
| AC-009-UNIT | `get_containers_by_rarity(6)` | Empty array (invalid rarity) |

---

#### AC-010: Validation Method

**Given**: ContainerDatabase is loaded
**When**: `is_valid_container(container_type_id)` is called
**Then**: Returns true for registered IDs, false for invalid IDs

| Test ID | Method | Expected Output |
|---------|--------|-----------------|
| AC-010-UNIT | `is_valid_container(101)` | true |
| AC-010-UNIT | `is_valid_container(0)` | false (null_container ID) |
| AC-010-UNIT | `is_valid_container(9999)` | false (unregistered) |
| AC-010-UNIT | `is_valid_container(-1)` | false (invalid range) |

---

### Drop Generation Correctness (AC-011 to AC-015)

#### AC-011: Drop Table Probability Correctness

**Given**: A container with defined drop_table and known probabilities
**When**: `generate_drops(container_type_id)` is called N times (N=10000 statistical sample)
**Then**: Drop frequency for each entry matches expected probability within ±5% tolerance

| Test ID | Container | Entry | Expected Chance | Observed Range |
|---------|-----------|-------|-----------------|----------------|
| AC-011-STAT | ID 101 | resource_id X (80% chance) | 80% | 75%-85% |
| AC-011-STAT | ID 101 | resource_id Y (30% chance) | 30% | 25%-35% |
| AC-011-STAT | ID 101 | resource_id Z (5% chance) | 5% | 3%-7% |

---

#### AC-012: Rarity Modifier Application

**Given**: A container with rarity=4 (epic) and drop entry for rare resource (rarity=3)
**When**: Drop generation runs
**Then**: Effective drop chance = base_chance × 0.8 (from RARITY_DROP_MODIFIER matrix)

| Test ID | Scenario | Calculation | Expected |
|---------|----------|-------------|----------|
| AC-012-UNIT | Epic container (rarity=4) + Rare resource (rarity=3) | 0.05 × 0.8 | 0.04 (4%) |
| AC-012-UNIT | Common container (rarity=1) + Legendary resource (rarity=5) | 0.05 × 0.005 | 0.00025 (0.025%) |

---

#### AC-013: Quantity Range Correctness

**Given**: Drop entry with min_quantity=2, max_quantity=5
**When**: Quantity is generated over N=1000 samples
**Then**: Quantity values 2, 3, 4, 5 each appear approximately 25% of time
**And**: No values outside range [2, 5]

| Test ID | Scenario | Expected | Observed Tolerance |
|---------|----------|----------|--------------------|
| AC-013-STAT | min=2, max=5 | Uniform distribution | ±5% for each value |
| AC-013-UNIT | min=1, max=1 | Always 1 | 100% value=1 |

---

#### AC-014: Min/Max Drop Count Enforcement

**Given**: Container with min_drop_count=2, max_drop_count=5
**When**: `generate_drops()` returns result
**Then**: Result array length is always between 2 and 5
**And**: Below minimum → padding applied, above maximum → trimming applied

| Test ID | Scenario | Input Drops | Expected Output |
|---------|----------|-------------|-----------------|
| AC-014-UNIT | All rolls fail, min=2 | 0 drops → padding | 2 drops (lowest rarity entries) |
| AC-014-UNIT | 8 entries pass, max=5 | 8 drops → trimming | 5 drops (high rarity removed) |

---

#### AC-015: Empty Drop Table Handling

**Given**: Container with empty drop_table
**When**: `generate_drops()` is called
**Then**: Returns empty array []
**And**: If min_drop_count > 0, logs error (constraint violation)

| Test ID | Scenario | Expected |
|---------|----------|----------|
| AC-015-UNIT | drop_table=[], min=0 | Returns [] |
| AC-015-UNIT | drop_table=[], min=1 | Returns [], logs error |

---

### Cross-System Integration (AC-016 to AC-020)

#### AC-016: ResourceDatabase Integration

**Given**: Drop entry references valid resource_id from ResourceDatabase
**When**: Drop generation queries ResourceDatabase for rarity
**Then**: Correct resource rarity is returned
**And**: Missing resource_id → entry skipped, error logged

| Test ID | Scenario | Expected |
|---------|----------|----------|
| AC-016-INT | Valid resource_id=101 in drop_table | Rarity lookup succeeds |
| AC-016-INT | Invalid resource_id=99999 in drop_table | Entry skipped, error logged |

---

#### AC-017: InventorySystem Integration (UI Layer)

**Given**: Player opens container and generate_drops() returns items
**When**: UI-CONT-003 (Drop Result Popup) displays drops
**Then**: Each drop card shows correct icon from ResourceDatabase
**And**: "Take All" button adds items to InventorySystem

| Test ID | Scenario | Expected |
|---------|----------|----------|
| AC-017-INT | Drop popup displays 3 items | Cards rendered correctly |
| AC-017-INT | "Take All" clicked | InventorySystem receives items |

---

#### AC-018: RetreatSystem Integration (Alert Trigger)

**Given**: Container with alert_chance_on_open > 0
**When**: Alert roll succeeds during scavenge
**Then**: Retreat countdown acceleration triggered
**And**: UI-CONT-006 (Alert Warning) appears

| Test ID | Scenario | Expected |
|---------|----------|----------|
| AC-018-INT | alert_chance roll = 0.3, randf() = 0.2 | Alert triggered |
| AC-018-INT | Alert triggered | Retreat countdown halved |

---

#### AC-019: World Generation Integration

**Given**: Map/Ruin Generation system queries ContainerDatabase
**When**: `get_ruins()` is called for ruin placement
**Then**: Valid ruin container IDs returned
**And**: `spawn_weight` used for distribution probability

| Test ID | Scenario | Expected |
|---------|----------|----------|
| AC-019-INT | get_ruins() called | Returns [501, 502, 503, 601, 602, 701] |
| AC-019-INT | spawn_weight applied | Higher weight containers appear more frequently |

---

#### AC-020: Enemy Generation Integration

**Given**: Enemy killed and drop container generated
**When**: `generate_enemy_drop(enemy_id)` is called
**Then**: Correct enemy_drop container type used
**And**: Drops spawn at enemy death location

| Test ID | Scenario | Expected |
|---------|----------|----------|
| AC-020-INT | Zombie killed | zombie_drop_pile (ID 1001) generated |
| AC-020-INT | Boss killed | boss_drop_trove (ID 1201) generated |

---

### Edge Case Handling (AC-021 to AC-025)

#### AC-021: Scavenge Interrupt Handling

**Given**: Player is scavenging a container (progress bar active)
**When**: Interrupt condition occurs (damage, movement, cancel)
**Then**: Scavenge stops immediately, container state unchanged
**And**: Progress bar shows appropriate "Cancelled" message

| Test ID | Interrupt Type | Expected |
|---------|----------------|----------|
| AC-021-INT | Player takes damage | Scavenge cancels, no drops |
| AC-021-INT | Player moves >2m away | Scavenge cancels |
| AC-021-INT | Player presses cancel key | Scavenge cancels |

---

#### AC-022: Locked Container Interaction

**Given**: Container with is_lockable=1
**When**: Player without key attempts scavenge
**Then**: Scavenge blocked, UI-CONT-005 shows lock message
**And**: No progress bar starts

| Test ID | Scenario | Expected |
|---------|----------|----------|
| AC-022-INT | Player has no key, attempts locked chest | Blocked, lock message shown |
| AC-022-INT | Player has key, attempts locked chest | Normal scavenge proceeds |

---

#### AC-023: Respawn Timer Behavior

**Given**: Ruin container with respawn_rules defined
**When**: Container scavenged and respawn conditions met
**Then**: Container respawns with new/same drops based on respawn_drop_table_same

| Test ID | Scenario | Expected |
|---------|----------|----------|
| AC-023-INT | respawn_requires_zone_leave=1, player in zone | Timer paused |
| AC-023-INT | Player leaves zone, timer elapsed | Container respawns |
| AC-023-INT | respawn_max_count reached | Permanent empty state |

---

#### AC-024: Enemy Drop Timeout

**Given**: enemy_drop container spawned (timeout=60s)
**When**: 60 seconds pass without player interaction
**Then**: Container despawns, unclaimed loot lost
**And**: Timeout resets if player partially loots

| Test ID | Scenario | Expected |
|---------|----------|----------|
| AC-024-INT | 60s timeout reached | Container despawns |
| AC-024-INT | Player loots at 55s | Timeout resets to 60s after completion |

---

#### AC-025: Deprecated Container Handling

**Given**: World save data references deprecated container_type_id
**When**: Save is loaded
**Then**: Deprecated ID replaced with replacement_id (if defined)
**And**: If no replacement, null_container used

| Test ID | Scenario | Expected |
|---------|----------|----------|
| AC-025-INT | Deprecated ID with replacement | Replacement definition loaded |
| AC-025-INT | Deprecated ID without replacement | null_container loaded |

---

### Performance (AC-026 to AC-028)

#### AC-026: Query Response Time

**Given**: ContainerDatabase singleton is loaded
**When**: `get_container_definition(id)` is called
**Then**: Response time < 1ms (cached Dictionary lookup)
**And**: No GC allocation on repeated queries

| Test ID | Method | Performance Budget |
|---------|--------|--------------------|
| AC-026-PERF | get_container_definition() | < 1ms |
| AC-026-PERF | get_drop_table() | < 1ms |

---

#### AC-027: Drop Generation Performance

**Given**: Container with 10-entry drop_table
**When**: `generate_drops()` is called
**Then**: Execution time < 5ms (per Core Rules performance notes)
**And**: No significant memory allocation

| Test ID | Scenario | Performance Budget |
|---------|----------|--------------------|
| AC-027-PERF | 10-entry drop_table | < 5ms |
| AC-027-PERF | 20-entry drop_table | < 10ms |

---

#### AC-028: Initialization Load Time

**Given**: ContainerDatabase loads all MVP definitions (16 containers)
**When**: Game session starts
**Then**: Database initialization completes in < 50ms
**And**: No frame spike during autoload registration

| Test ID | Scenario | Performance Budget |
|---------|----------|--------------------|
| AC-028-PERF | Load 16 containers | < 50ms |
| AC-028-PERF | Load 100 containers (future) | < 200ms |

---

### Acceptance Criteria Summary Table

| AC Category | AC IDs | Test Count | Pass Threshold | Blocking Level |
|-------------|--------|------------|----------------|----------------|
| Database Initialization | AC-001 to AC-005 | 5 | 100% | BLOCKING |
| Query API Validation | AC-006 to AC-010 | 10 | 100% | BLOCKING |
| Drop Generation Correctness | AC-011 to AC-015 | 5 | 100% | BLOCKING |
| Cross-System Integration | AC-016 to AC-020 | 5 | 80% | ADVISORY |
| Edge Case Handling | AC-021 to AC-025 | 5 | 90% | ADVISORY |
| Performance | AC-026 to AC-028 | 3 | 100% | BLOCKING |
| **TOTAL** | — | **34** | **95%** | — |

**Pass/Fail Determination**:
- PASS: All BLOCKING categories at 100% + Overall ≥ 95%
- FAIL: Any BLOCKING category below 100% OR Overall < 95%

## Open Questions

### High Priority Questions

#### Q-001: Weapon Drop Support

| Field | Value |
|-------|-------|
| **Question ID** | Q-001 |
| **Priority** | HIGH |
| **Owner** | Combat System Designer + Loot System Designer |
| **Status** | OPEN |
| **Question** | Does the drop_table need to support `weapon_type_id` references in addition to `resource_id`? Currently drop_table only references ResourceDatabase, but containers may drop weapons. |
| **Context** | The Core Rules section (line 147-187) defines drop_table with `resource_id` field only. Military containers (ID 201-202) are designed to "possibly contain weapon components", but no weapon drop mechanism is specified. |
| **Options** | 1) Add `drop_type` field (resource/weapon/item) to drop_table entries<br>2) Treat weapons as special resources in ResourceDatabase<br>3) Create separate `weapon_drop_table` array field<br>4) Weapons only available via special containers (not in standard drop tables) |
| **Resolution Needed Before** | Combat System GDD completion + Loot System implementation (Core layer) |
| **Impact if Unresolved** | BLOCKING — Cannot implement military container loot if weapon drop mechanism undefined. Players expect weapon drops from military containers (design intent from Player Fantasy section). |

---

#### Q-002: Container Rarity Visual Implementation

| Field | Value |
|-------|-------|
| **Question ID** | Q-002 |
| **Priority** | HIGH |
| **Owner** | Art Director + UI Designer + VFX Artist |
| **Status** | OPEN |
| **Question** | Should container rarity glow effect use shader (runtime) or pre-baked sprites (static)? The Visual/Audio Requirements section specifies shader-based glow, but this may impact mobile/console performance. |
| **Context** | Rarity visual border (UI-CONT-008) and Visual/Audio Requirements (line 1245-1286) define shader-based glow effects. However, Art Bible compliance and target platform (PC only per Technical Preferences) suggest shader approach is viable. |
| **Options** | 1) Use shader-based glow (per Visual/Audio Requirements spec)<br>2) Pre-bake rarity variants as separate sprites (5 variants per container type)<br>3) Hybrid: shader for rarity 3-5, static sprites for 1-2<br>4) Post-MVP decision — start with static sprites, migrate to shaders |
| **Resolution Needed Before** | Art asset production kickoff + VFX pipeline setup (Presentation layer) |
| **Impact if Unresolved** | ADVISORY — Can proceed with placeholder visuals, but may cause rework if decision changes post-production. Shader complexity affects Art Bible compliance and technical budget. |

---

#### Q-003: Respawn Zone Boundaries Definition

| Field | Value |
|-------|-------|
| **Question ID** | Q-003 |
| **Priority** | HIGH |
| **Owner** | Level Designer + World System Designer |
| **Status** | OPEN |
| **Question** | How are "respawn zones" defined for `respawn_requires_zone_leave` check? The respawn algorithm (line 361-384) references `player_in_zone(container_instance.zone_id)` but zone definition is unclear. |
| **Context** | Respawn Rules section (line 326-385) specifies `respawn_requires_zone_leave = 1` for many ruin containers, but zone_id assignment and zone boundary definition is not specified in this GDD or any existing document. |
| **Options** | 1) Zone = defined by Level System (per-container zone_id assigned during world gen)<br>2) Zone = radius around container (e.g., 50m radius)<br>3) Zone = named area from LevelData (e.g., "Industrial District")<br>4) Zone = screen/chunk bounds (tile-based zones) |
| **Resolution Needed Before** | Level Design GDD completion + World System implementation (Core layer) |
| **Impact if Unresolved** | BLOCKING — Respawn system cannot function without zone definition. Ruin containers (501-701) depend on respawn behavior for repeatable exploration loop (Pillar 2). |

---

### Medium Priority Questions

#### Q-004: Multi-Player Container Sync

| Field | Value |
|-------|-------|
| **Question ID** | Q-004 |
| **Priority** | MEDIUM |
| **Owner** | Networking System Designer |
| **Status** | OPEN |
| **Question** | How should container state sync across multiple players (if multiplayer added)? Container state (scavenged/empty/open) needs sync to prevent loot duplication or conflict. |
| **Context** | The system is designed for single-player MVP, but future multiplayer support is mentioned in project scope. Current design has no multiplayer sync mechanism. |
| **Options** | 1) Single-player only (no sync needed for MVP)<br>2) Server-authoritative container state (player actions synced to server)<br>3) Instance-based loot (each player sees their own drops from same container)<br>4) First-player-claims loot (race condition for containers) |
| **Resolution Needed Before** | Networking System architecture decision (if multiplayer scoped for MVP) |
| **Impact if Unresolved** | ADVISORY — MVP is single-player, so not blocking. However, if multiplayer added post-MVP, container sync may require significant rework of state management. |

---

#### Q-005: Locked Container Key System Details

| Field | Value |
|-------|-------|
| **Question ID** | Q-005 |
| **Priority** | MEDIUM |
| **Owner** | Item System Designer + Quest System Designer |
| **Status** | OPEN |
| **Question** | What is the key item system for locked containers? The Edge Case section (line 1087-1098) mentions `key_item_id` and `key_name` but key item definition and acquisition method is undefined. |
| **Context** | Containers with `is_lockable = 1` require a key. The locked container UI (UI-CONT-005) shows key name and inventory check, but: (1) How are keys defined? (2) Where do keys spawn? (3) Are keys single-use or reusable? |
| **Options** | 1) Keys defined in ItemDatabase (key_type_id, single-use consumable)<br>2) Keys defined in ItemDatabase (key_type_id, reusable permanent item)<br>3) Keys are quest rewards only (QuestSystem integration)<br>4) Keys are world loot items (spawn in specific containers) |
| **Resolution Needed Before** | Item System GDD completion + Quest System implementation (if quest-based) |
| **Impact if Unresolved** | ADVISORY — Locked containers are MVP content (魔导储能器 ID 301), but key system can be deferred. If deferred, locked containers may be disabled for MVP release. |

---

### Low Priority Questions

#### Q-006: Drop Table Extension for Future Content

| Field | Value |
|-------|-------|
| **Question ID** | Q-006 |
| **Priority** | LOW |
| **Owner** | Live Ops Designer |
| **Status** | OPEN |
| **Question** | Should drop_table support future content hooks (event modifiers, seasonal drops, conditional entries)? |
| **Context** | Live ops may need to add temporary drop entries (seasonal items, event rewards) to existing containers without redefining entire container definitions. |
| **Options** | 1) Static drop_table only (no extension mechanism)<br>2) Support `drop_table_modifiers` field for event overrides<br>3) Dynamic drop injection via LiveOpsSystem API<br>4) Post-MVP decision — add extension system when live ops scoped |
| **Resolution Needed Before** | Live Ops System design (post-MVP) |
| **Impact if Unresolved** | LOW — MVP does not include live ops. Can defer to post-launch planning. |

---

#### Q-007: Container Sound Spatialization

| Field | Value |
|-------|-------|
| **Question ID** | Q-007 |
| **Priority** | LOW |
| **Owner** | Audio Designer |
| **Status** | OPEN |
| **Question** | Should container audio cues be spatialized (position-based) or global (screen-level)? |
| **Context** | Visual/Audio Requirements section (line 1308-1341) defines audio cues but does not specify spatialization. Audio implementation sample uses `Audio.play_at_position()` suggesting spatialization. |
| **Options** | 1) Spatialized audio (position-based, volume/distance attenuation)<br>2) Global audio (same volume regardless of player position)<br>3) Hybrid: alert sounds global, container sounds spatialized |
| **Resolution Needed Before** | Audio system implementation (Presentation layer) |
| **Impact if Unresolved** | LOW — Audio can proceed with default approach (spatialized per implementation sample). Minor impact on player experience if decision changes. |

---

#### Q-008: Debug Respawn Timer Visibility

| Field | Value |
|-------|-------|
| **Question ID** | Q-008 |
| **Priority** | LOW |
| **Owner** | QA Lead + Dev Tools Designer |
| **Status** | OPEN |
| **Question** | Should respawn timer (UI-CONT-010) be visible in debug mode or require explicit debug command? |
| **Context** | UI-CONT-010 defines respawn timer display for dev mode, but visibility trigger (auto-on vs command-activated) is undefined. |
| **Options** | 1) Auto-visible when DEBUG_MODE=true<br>2) Requires console command `show_respawn_timers`<br>3) Visible in dedicated debug UI panel |
| **Resolution Needed Before** | Debug tools implementation (Tools layer) |
| **Impact if Unresolved** | LOW — Debug UI is internal tool, not affecting player experience. |

---

### Open Questions Summary Matrix

| Question ID | Priority | Owner(s) | Blocking Status | Resolution Deadline |
|-------------|----------|----------|-----------------|---------------------|
| Q-001 | HIGH | Combat + Loot Designers | BLOCKING | Combat System GDD completion |
| Q-002 | HIGH | Art + UI + VFX | ADVISORY | Art production kickoff |
| Q-003 | HIGH | Level + World Designers | BLOCKING | Level Design GDD completion |
| Q-004 | MEDIUM | Networking Designer | ADVISORY | Networking architecture decision |
| Q-005 | MEDIUM | Item + Quest Designers | ADVISORY | Item System GDD completion |
| Q-006 | LOW | Live Ops Designer | LOW | Post-MVP live ops planning |
| Q-007 | LOW | Audio Designer | LOW | Audio system implementation |
| Q-008 | LOW | QA + Dev Tools | LOW | Debug tools implementation |

---

### Question Resolution Process

1. **Owner Assignment**: Each question has assigned owner(s) responsible for driving resolution
2. **Deadline Tracking**: Resolution deadline must be met to avoid blocking downstream work
3. **Decision Documentation**: Resolution must be documented in relevant GDD with cross-reference to Q-ID
4. **Status Update**: Update question status from OPEN → RESOLVED when decision made
5. **Propagation**: If resolution affects other systems, use `/propagate-design-change` to notify dependent GDDs

---

### Blocking Questions Priority Queue

```
Priority 1 (BLOCK MVP Implementation):
├── Q-001: Weapon Drop Support → Combat System GDD
└── Q-003: Respawn Zone Boundaries → Level Design GDD

Priority 2 (BLOCK Production Asset Work):
└── Q-002: Container Rarity Visual → Art Bible + VFX Pipeline

Priority 3 (DEFER to Post-MVP):
├── Q-004: Multi-Player Sync
├── Q-005: Key System Details
├── Q-006: Live Ops Extension
├── Q-007: Audio Spatialization
└── Q-008: Debug UI Visibility
```