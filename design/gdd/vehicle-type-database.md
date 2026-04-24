# 战车类型数据库

> **Status**: Designed (Core Rules Complete)
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-22
> **Implements Pillar**: Pillar 1 (战车即生命)
> **Priority**: MVP | **Layer**: Foundation
> **System ID**: #6 (from systems-index.md)

## Overview

战车类型数据库是存储所有战车类型定义的单一数据源。每个战车类型定义了基础属性（耐久、护甲、魔能容量、速度、载重量）、武器挂载点、改装槽位配置、视觉配置标识。该数据库为战车属性系统、战车驾驶系统、战车武器系统、战车改装系统提供统一的战车定义接口，确保所有下游系统引用同一份战车属性基准。

作为Foundation层系统，该数据库直接影响玩家对**战车重量感和风险感**的感知：不同战车类型的耐久上限定义了"这辆战车能承受多少打击"的生存边界，魔能容量定义了"能探索多远"的续航限制，速度和护甲定义了驾驶手感和防御能力。这服务于Pillar 1（战车即生命）——战车数据定义了玩家在末世废土中的生存能力边界。

**设计决策**：
- 使用Dictionary结构存储战车类型定义（key = vehicle_type_id, value = Dictionary of attributes）
- 采用Autoload singleton模式（extends Node），与BlockTypeDatabase、ResourceDatabase保持一致架构
- 提供`get_vehicle_definition(vehicle_type_id: int)`查询接口供下游系统调用
- **架构决策待定**: Godot实现架构将在`/architecture-decision`中确定，当前设计假设Autoload singleton模式

**ADR引用**: 无现有ADR — `/architecture-decision`需在实现前确定战车数据存储架构

## Player Fantasy

玩家在战车相关系统中面对的核心体验是**钢铁脉搏的生存共鸣**——数据库中的每一个属性数值，都是这头魔导战车的生命体征，玩家与战车建立起情感纽带。

- **出发前的生命检查**: 玩家在车库中检查战车状态时，看到的不是冷冰冰的数字，而是"它今天能不能带我回家"的答案。耐久80%以上的绿灯是战车在说"我准备好了"，魔能半满是魔导晶石中储存的心跳
- **撤退时的衰弱恐惧**: 当魔能跌破20%的警报响起，玩家感受到的是"伙伴在衰弱"而非"资源耗尽"。耐久30%的红线是战车在呻吟——"我撑不住了"。撤退决策不是数学计算，是对伙伴生命的保护抉择
- **改装完成的守护承诺**: 每增加一个武器挂载点、每提升一级护甲，玩家感受到的是"我要让你活得更久"。改装不只是换装备，是为伙伴添置铠甲，是废土世界中最珍贵的承诺

**锚定时刻**: 第一次驾驶基础战车出门，玩家看着耐久100%、魔能100%的满状态，感受到的是"它还很健康，能带我去探索"的安全感。但当第一场战斗过后，耐久跌到40%，魔能只剩15%，玩家看着面板上闪烁的红色警告，心跳加速——"再不走它就撑不住了"。这种**战车生命与玩家生存绑定**的紧张感，就是本数据库创造的玩家体验。

**服务于支柱**：
- **Pillar 1 (战车即生命)**: 数据库属性是战车的生命体征，出发条件和撤退阈值是战车在"说话"——告诉玩家它今天的状态、它的极限、它何时需要回家。战车不是工具，是废土世界中的伙伴
- **Pillar 4 (魔导科技美学)**: 属性命名和描述语调体现魔导科技世界观——"魔能容量"而非"燃料箱"，"护甲等级"而非"装甲值"，"符文炮塔基座"而非"武器挂载点"

**语调示例**:
```
❌ "载重量上限500kg，速度减少15%"
✓ "增加负重，战车的步伐变得沉重——但能带回更多废土的馈赠"

❌ "护甲值40，减少受到的物理伤害"  
✓ "护甲等级：废土标准型。足以挡住变异狼的爪牙，但面对巨兽的冲撞？祈祷吧。"
```

## Detailed Design

### Core Rules

#### 1. Vehicle Type Data Structure

每个战车类型定义为一个独立的数据记录，存储在VehicleDatabase资源文件中。所有战车类型共享统一的数据结构，确保下游系统可以一致地查询属性。

**Primary Vehicle Type Fields (存储在VehicleDefinition资源):**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `vehicle_type_id` | int | 0-65535 | — | 唯一标识符，系统内部引用键 |
| `name` | string | — | — | 内部标识名（如"scout_basic", "heavy_mithril"），用于代码引用和本地化键 |
| `display_name` | string | — | — | UI显示名称（本地化键，实际显示由LocalizationManager处理） |
| `tier` | int | 1-5 | 1 | 战车层级（1=Basic, 2=Standard, 3=Advanced, 4=Elite, 5=Legendary） |
| `category` | int | 0-3 | 0 | 战车分类枚举值（见Category System） |
| `max_durability` | int | 50-500 | 100 | 耐久上限（战车生命血量，决定生存边界） |
| `armor` | int | 0-80 | 0 | 护甲减伤百分比（上限80%，不可完全无敌） |
| `max_magic_energy` | int | 50-500 | 100 | 魔能容量上限（续航能力，决定探索距离） |
| `base_speed` | float | 1.0-10.0 | 3.0 | 基础移动速度（格/秒） |
| `load_capacity` | int | 50-500 | 100 | 载重量上限（kg，影响仓库容量和速度修正） |
| `warehouse_slots` | int | 20-200 | 100 | 战车仓库格子数量（来自游戏概念：100格） |
| `weapon_mounts` | int | 0-4 | 1 | 武器挂载点数量（决定可装备武器数量） |

**Extended Vehicle Type Fields (不映射到核心属性，存储在metadata):**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `modification_slots` | int | 0-6 | 0 | 改装槽位数量（Vertical Slice系统） |
| `unlock_day` | int | 1-30 | 1 | 解锁天数（游戏进程里程碑） |
| `unlock_cost` | Dictionary | — | {} | 解锁消耗资源 `{resource_id: count}` |
| `visual_config_id` | string | — | "" | 视觉配置标识（指向assets/vehicles/配置文件） |
| `description` | string | — | "" | 内部文档说明（语调体现Pillar 1情感） |
| `flavor_text` | string | — | "" | UI风味文本（本地化键） |

**出发/撤退阈值字段（硬编码在游戏概念中，数据库仅存储参考值）:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `deploy_durability_min` | float | 0.5-1.0 | 0.80 | 出发最低耐久比例（游戏概念：80%） |
| `deploy_magic_energy_min` | float | 0.3-0.7 | 0.50 | 出发最低魔能比例（游戏概念：50%） |
| `retreat_magic_energy_threshold` | float | 0.1-0.3 | 0.20 | 撤退魔能触发比例（游戏概念：20%） |
| `retreat_durability_threshold` | float | 0.2-0.4 | 0.30 | 撤退耐久触发比例（游戏概念：30%） |

**Field Validation Rules:**

1. `vehicle_type_id`必须唯一，不允许重复ID
2. `vehicle_type_id = 0`保留为"空战车"错误回退
3. `name`必须为有效的snake_case标识符（仅字母、数字、下划线）
4. `tier`必须在范围1-5内
5. `category`必须在枚举范围0-3内
6. `max_durability`必须为正整数（>=50），上限500
7. `armor`必须在范围0-80内（80%减伤上限，不可完全无敌）
8. `max_magic_energy`必须为正整数（>=50），上限500
9. `base_speed`必须在范围1.0-10.0内
10. `load_capacity`必须为正整数（>=50），上限500
11. `warehouse_slots`必须为正整数（>=20），上限200
12. `weapon_mounts`必须在范围0-4内（MVP最多4个挂载点）
13. `modification_slots`必须在范围0-6内（Vertical Slice最多6个槽位）
14. **Contradiction validation**: 如果 `weapon_mounts > 0` 但未定义任何weapon mount slots配置，这是无效配置。武器挂载点必须有具体的slot定义。

---

#### 2. Vehicle Type ID Allocation Scheme

战车类型ID按类别和层级分配，确保ID范围可预测、可扩展、易于查询。

**ID Range Allocation:**

| ID Range | Category | Tier Range | Description |
|----------|----------|------------|-------------|
| 0 | — | — | `null_vehicle` — 保留为错误回退 |
| 1-99 | `scout` | 1-2 | 轻型侦察战车（高速度、低耐久、探索专用） |
| 100-199 | `standard` | 1-3 | 标准战车（平衡属性、多用途） |
| 200-299 | `heavy` | 2-4 | 重型战车（高耐久、高护甲、低速度、防守专用） |
| 300-399 | `special` | 3-5 | 特殊战车（独特功能、魔导科技、稀有解锁） |
| 400-65535 | `reserved` | — | 未来内容预留（扩展、mod、特殊活动） |

**ID Allocation Rules:**

1. IDs按类别分配在连续块中
2. 每个类别有100个ID槽位；未使用槽位保留未来添加
3. 新战车类型必须使用类别范围内的下一个可用ID
4. ID必须永不重新分配 — 废弃ID标记`status: deprecated`
5. `vehicle_type_id = 0`保留为"null vehicle"（错误回退）

**Tier ID Offset within Category:**

| Tier | Name | ID Offset | Example (Standard Category) |
|------|------|-----------|------------------------------|
| 1 | `BASIC` | 0-9 | ID 100-109 = Basic Standard Vehicles |
| 2 | `STANDARD` | 10-19 | ID 110-119 = Standard Tier Vehicles |
| 3 | `ADVANCED` | 20-49 | ID 120-149 = Advanced Vehicles |
| 4 | `ELITE` | 50-79 | ID 150-179 = Elite Vehicles |
| 5 | `LEGENDARY` | 80-99 | ID 180-199 = Legendary Vehicles |

**ID Derivation Formula:**

```
vehicle_type_id = CATEGORY_BASE + TIER_OFFSET + VARIANT_INDEX

Example:
- Scout Basic (category=0, tier=1, variant=0): ID = 0 + 0 + 0 = 1
- Standard Advanced (category=1, tier=3, variant=0): ID = 100 + 20 + 0 = 120
- Heavy Elite (category=2, tier=4, variant=0): ID = 200 + 50 + 0 = 250
- Special Legendary (category=3, tier=5, variant=0): ID = 300 + 80 + 0 = 380
```

---

#### 3. Vehicle Tier/Category System

战车按**分类**定义功能定位，按**层级**定义能力等级。

**Category Enumeration:**

| Value | Name | Role | Durability Range | Speed Range | Armor Range | Magic Energy Range |
|-------|------|------|------------------|-------------|-------------|-------------------|
| 0 | `SCOUT` | 轻型侦察 | 50-150 (低耐久) | 4.0-10.0 (高速度) | 0-20 (低护甲) | 50-150 (中等续航) |
| 1 | `STANDARD` | 标准多用途 | 100-250 (中等耐久) | 2.5-5.0 (标准速度) | 10-40 (中等护甲) | 100-250 (标准续航) |
| 2 | `HEAVY` | 重型防守 | 200-500 (高耐久) | 1.0-3.0 (低速度) | 30-80 (高护甲) | 150-300 (较长续航) |
| 3 | `SPECIAL` | 特殊功能 | 100-350 (波动) | 2.0-6.0 (波动) | 0-60 (波动) | 100-500 (波动) |

**Category Role Description:**

| Category | Exploration Role | Defense Role | Modification Bias |
|----------|------------------|--------------|-------------------|
| `SCOUT` | 快速搜刮、侦察废墟、低风险区域探索 | 不适合防守（低护甲、低耐久） | 速度改装、续航改装 |
| `STANDARD` | 日常探索、中型资源运输、一般风险区域 | 可参与防守（中等护甲、可装备炮塔） | 平衡改装、多功能改装 |
| `HEAVY` | 高风险区域探索、大型资源运输 | 防守主力（高护甲、可承受尸潮冲击） | 耐久改装、护甲改装、武器改装 |
| `SPECIAL` | 特殊任务（天气绑定、魔导科技、稀有解锁） | 特殊防守功能（天气炮塔、魔导武器） | 独特改装路径 |

**Tier Enumeration:**

| Value | Name | Unlock Day | Stat Modifier | Weapon Mounts | Modification Slots | Flavor |
|-------|------|------------|---------------|----------------|-------------------|--------|
| 1 | `BASIC` | Day 1 | ×1.0 (基准) | 0-1 | 0 | "废土入门款——能跑就行" |
| 2 | `STANDARD` | Day 5 | ×1.2 | 1-2 | 1-2 | "可靠的伙伴——够用就好" |
| 3 | `ADVANCED` | Day 10 | ×1.5 | 2-3 | 2-3 | "魔导升级款——废土精英标配" |
| 4 | `ELITE` | Day 20 | ×2.0 | 3-4 | 3-4 | "重型钢铁巨兽——尸潮中屹立不倒" |
| 5 | `LEGENDARY` | Day 30 | ×2.5 | 4 | 4-6 | "末世传说——魔导科技的终极形态" |

**Tier Stat Modifier Application:**

Tier modifier应用于战车类型的基础属性，用于设计参考而非实时计算：

| Tier | Durability Mult | Armor Mult | Speed Mult | Magic Energy Mult | Load Capacity Mult |
|------|-----------------|------------|------------|-------------------|--------------------|
| 1 (`BASIC`) | ×1.0 | ×1.0 | ×1.0 | ×1.0 | ×1.0 |
| 2 (`STANDARD`) | ×1.2 | ×1.2 | ×1.0 | ×1.2 | ×1.1 |
| 3 (`ADVANCED`) | ×1.5 | ×1.5 | ×0.9 | ×1.5 | ×1.2 |
| 4 (`ELITE`) | ×2.0 | ×2.0 | ×0.8 | ×2.0 | ×1.5 |
| 5 (`LEGENDARY`) | ×2.5 | ×2.5 | ×0.7 | ×2.5 | ×2.0 |

> **Note**: Tier modifier是设计参考值，实际属性值由设计师手动定义。Tier multiplier帮助保持层级递进的数值一致性。

---

#### 4. Weapon Mount Configuration

武器挂载点定义战车可装备的武器类型和数量。

**Weapon Mount Slot Definition:**

每个挂载点定义为一个独立的数据结构：

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `slot_index` | int | 0-3 | — | 挂载点索引（从0开始） |
| `slot_type` | int | 0-3 | — | 挂载点类型枚举（见WeaponSlotType） |
| `weapon_type_allowed` | Array[int] | — | [] | 允许装备的武器类型ID列表（空=全类型允许） |
| `is_locked` | int | 0-1 | 0 | 是否锁定（需要改装解锁） |
| `unlock_cost` | Dictionary | — | {} | 解锁消耗（如果是locked状态） |
| `visual_position` | Vector2 | — | (0, 0) | 挂载点视觉位置偏移（相对于战车中心） |

**Weapon Slot Type Enumeration:**

| Value | Name | Weapon Types | Description | Visual Position Bias |
|-------|------|--------------|-------------|----------------------|
| 0 | `PRIMARY` | 主炮、重型武器 | 主武器挂载点，战车核心火力 | 战车前端中心 |
| 1 | `SECONDARY` | 副炮、轻型武器 | 副武器挂载点，辅助火力 | 战车前端侧边 |
| 2 | `TURRET_TOP` | 旋转炮塔 | 顶部炮塔挂载点，360度旋转 | 战车顶部中心 |
| 3 | `TURRET_SIDE` | 固定炮塔 | 侧边炮塔挂载点，固定方向 | 战车侧边 |

**Weapon Mount Configuration Rules:**

1. `weapon_mounts`字段值必须等于挂载点配置数量
2. 挂载点索引必须连续（0, 1, 2, 3...）
3. PRIMARY挂载点必须是第一个slot（slot_index=0）
4. 如果`is_locked=1`，必须有`unlock_cost`定义
5. `weapon_type_allowed`数组为空表示该slot允许所有武器类型
6. `visual_position`用于武器渲染偏移计算

**Weapon Mount Example Configuration:**

```gdscript
# Standard Advanced战车 (ID 120) - 2个武器挂载点
weapon_mounts: 2
weapon_mount_config:
  - slot_index: 0
    slot_type: 0  # PRIMARY
    weapon_type_allowed: []  # 全类型允许
    is_locked: 0
    visual_position: Vector2(15, 0)  # 前端中心偏移15px
    
  - slot_index: 1
    slot_type: 1  # SECONDARY
    weapon_type_allowed: [101, 102]  # 仅允许轻型武器类型ID 101-102
    is_locked: 0
    visual_position: Vector2(10, -5)  # 前端侧边偏移
```

---

#### 5. Modification Slot Configuration (Vertical Slice)

改装槽位定义战车可进行的改装类型和数量。改装系统在Vertical Slice阶段实现。

**Modification Slot Definition:**

每个改装槽位定义为一个独立的数据结构：

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `slot_index` | int | 0-5 | — | 改装槽索引（从0开始） |
| `slot_category` | int | 0-5 | — | 改装槽类别枚举（见ModificationSlotCategory） |
| `modification_type_allowed` | Array[int] | — | [] | 允许的改装类型ID列表（空=全类别允许） |
| `is_locked` | int | 0-1 | 0 | 是否锁定（需要解锁） |
| `unlock_cost` | Dictionary | — | {} | 解锁消耗 |

**Modification Slot Category Enumeration:**

| Value | Name | Modification Types | Description |
|-------|------|-------------------|-------------|
| 0 | `ENGINE` | 速度、加速度、魔能效率 | 引擎改装槽 |
| 1 | `ARMOR` | 护甲、减伤、碰撞抵抗 | 护甲改装槽 |
| 2 | `WEAPON` | 武器伤害、射速、射程 | 武器增强改装槽 |
| 3 | `STORAGE` | 载重量、仓库格子 | 储存改装槽 |
| 4 | `UTILITY` | 探索辅助、传感器、照明 | 功能改装槽 |
| 5 | `SPECIAL` | 独特改装、魔导科技 | 特殊改装槽 |

**Modification Slot Configuration Rules:**

1. `modification_slots`字段值必须等于槽位配置数量
2. 槽位索引必须连续（0, 1, 2...）
3. 每个战车类型最多6个改装槽位
4. 同类slot_category最多出现2次（不能全部是ARMOR改装）
5. 改装槽位数量随Tier递增：Basic=0, Standard=1-2, Advanced=2-3, Elite=3-4, Legendary=4-6
6. MVP阶段：所有战车`modification_slots = 0`（改装系统为Vertical Slice）

**Modification Slot Example Configuration (Vertical Slice):**

```gdscript
# Heavy Elite战车 (ID 250) - 4个改装槽位
modification_slots: 4
modification_config:
  - slot_index: 0
    slot_category: 1  # ARMOR
    modification_type_allowed: []  # 全ARMOR改装允许
    is_locked: 0
    
  - slot_index: 1
    slot_category: 2  # WEAPON
    modification_type_allowed: [201, 202]  # 仅允许重型武器改装
    is_locked: 0
    
  - slot_index: 2
    slot_category: 3  # STORAGE
    modification_type_allowed: []
    is_locked: 1  # 需要解锁
    unlock_cost: {RESOURCE_MITHRIL_ID: 5}
    
  - slot_index: 3
    slot_category: 5  # SPECIAL
    modification_type_allowed: [301]  # 仅允许魔导改装
    is_locked: 1
    unlock_cost: {RESOURCE_ANCIENT_MITHRIL_ID: 1, RESOURCE_CRYSTAL_CLUSTER_ID: 3}
```

---

#### 6. Initial Vehicle Catalog (MVP)

以下是MVP阶段必需的战车类型定义。每个战车类型包含完整属性定义。

**Scout Category (ID 1-99):**

| ID | Name | Display | Tier | Durability | Armor | Magic Energy | Speed | Load | Warehouse | Weapon Mounts | Unlock Day |
|----|------|---------|------|------------|-------|--------------|-------|------|-----------|---------------|------------|
| 1 | `scout_basic` | "废土侦察车" | 1 | 60 | 5 | 80 | 5.0 | 50 | 50 | 0 | Day 1 |
| 10 | `scout_standard` | "轻型侦察车" | 2 | 100 | 10 | 120 | 6.0 | 80 | 80 | 1 | Day 5 |

**Standard Category (ID 100-199):**

| ID | Name | Display | Tier | Durability | Armor | Magic Energy | Speed | Load | Warehouse | Weapon Mounts | Unlock Day |
|----|------|---------|------|------------|-------|--------------|-------|------|-----------|---------------|------------|
| 100 | `standard_basic` | "基础战车" | 1 | 100 | 15 | 100 | 3.0 | 100 | 100 | 1 | Day 1 |
| 110 | `standard_standard` | "标准战车" | 2 | 120 | 20 | 120 | 3.5 | 120 | 120 | 2 | Day 5 |
| 120 | `standard_advanced` | "先进战车" | 3 | 150 | 25 | 150 | 3.0 | 150 | 150 | 2 | Day 10 |

**Heavy Category (ID 200-299):**

| ID | Name | Display | Tier | Durability | Armor | Magic Energy | Speed | Load | Warehouse | Weapon Mounts | Unlock Day |
|----|------|---------|------|------------|-------|--------------|-------|------|-----------|---------------|------------|
| 210 | `heavy_standard` | "重型运输车" | 2 | 250 | 35 | 200 | 2.0 | 200 | 150 | 1 | Day 8 |
| 220 | `heavy_advanced` | "重型装甲车" | 3 | 300 | 50 | 250 | 1.5 | 250 | 180 | 3 | Day 15 |
| 250 | `heavy_elite` | "钢铁巨兽" | 4 | 400 | 65 | 300 | 1.2 | 350 | 200 | 4 | Day 20 |

**Special Category (ID 300-399) - MVP Placeholder:**

| ID | Name | Display | Tier | Durability | Armor | Magic Energy | Speed | Load | Warehouse | Weapon Mounts | Unlock Day |
|----|------|---------|------|------------|-------|--------------|-------|------|-----------|---------------|------------|
| 300 | `special_placeholder` | "[预留]" | 3 | 200 | 30 | 200 | 3.0 | 150 | 150 | 2 | Day 25 |

**MVP Vehicle Catalog Summary:**

- **Total MVP Vehicles**: 8 types (2 Scout + 3 Standard + 3 Heavy + 1 Special placeholder)
- **Player Starting Vehicle**: `standard_basic` (ID 100) — Day 1默认解锁
- **First Upgrade Path**: `standard_basic` → `standard_standard` → `standard_advanced`
- **Defense Specialist Path**: `heavy_standard` → `heavy_advanced` → `heavy_elite`
- **Scout Path**: `scout_basic` → `scout_standard` — 快速探索专用

---

#### 7. Vehicle Database Query API

战车类型数据库通过`VehicleTypeDatabase`单例提供查询接口，供所有下游系统使用。

**Singleton Registration:**

```gdscript
# VehicleTypeDatabase.gd (autoload singleton)
class_name VehicleTypeDatabase
extends Node

# Autoload name: "VehicleTypes"
# Note: Autoloads must extend Node for proper lifecycle (_ready, _process, scene tree access)
```

**Primary Query Methods:**

```gdscript
# === Basic Lookup ===

# Returns Dictionary containing all vehicle type fields for given ID
func get_vehicle_definition(vehicle_type_id: int) -> Dictionary

# Returns vehicle type name (internal identifier) for given ID
func get_vehicle_name(vehicle_type_id: int) -> String

# Returns display name (localized) for given ID
func get_display_name(vehicle_type_id: int) -> String

# === Property Query ===

# Returns tier value (1-5)
func get_tier(vehicle_type_id: int) -> int

# Returns category value (0-3)
func get_category(vehicle_type_id: int) -> int

# Returns max_durability (50-500)
func get_max_durability(vehicle_type_id: int) -> int

# Returns armor percentage (0-80)
func get_armor(vehicle_type_id: int) -> int

# Returns max_magic_energy (50-500)
func get_max_magic_energy(vehicle_type_id: int) -> int

# Returns base_speed (1.0-10.0)
func get_base_speed(vehicle_type_id: int) -> float

# Returns load_capacity (50-500)
func get_load_capacity(vehicle_type_id: int) -> int

# Returns warehouse_slots (20-200)
func get_warehouse_slots(vehicle_type_id: int) -> int

# Returns weapon_mounts count (0-4)
func get_weapon_mount_count(vehicle_type_id: int) -> int

# Returns weapon mount configuration array
func get_weapon_mount_config(vehicle_type_id: int) -> Array[Dictionary]

# === Category/Tier Query ===

# Returns all vehicle types in specified category
func get_vehicles_by_category(category: int) -> Array[int]

# Returns all vehicle types at specified tier
func get_vehicles_by_tier(tier: int) -> Array[int]

# Returns all vehicle types unlocked by specified day
func get_vehicles_by_unlock_day(day: int) -> Array[int]

# === Validation ===

# Returns true if vehicle_type_id is valid (exists in database)
func is_valid_vehicle_type(vehicle_type_id: int) -> bool

# Returns true if vehicle can be deployed (meets deploy thresholds)
func can_deploy(vehicle_type_id: int, current_durability_ratio: float, current_magic_energy_ratio: float) -> bool

# Returns true if retreat should be triggered
func should_retreat(vehicle_type_id: int, current_durability_ratio: float, current_magic_energy_ratio: float) -> bool

# === Threshold Query ===

# Returns deploy_durability_min threshold (0.80 default)
func get_deploy_durability_min(vehicle_type_id: int) -> float

# Returns deploy_magic_energy_min threshold (0.50 default)
func get_deploy_magic_energy_min(vehicle_type_id: int) -> float

# Returns retreat_magic_energy_threshold (0.20 default)
func get_retreat_magic_energy_threshold(vehicle_type_id: int) -> float

# Returns retreat_durability_threshold (0.30 default)
func get_retreat_durability_threshold(vehicle_type_id: int) -> float
```

**Query Return Format:**

```gdscript
# get_vehicle_definition returns this dictionary structure:
{
    "vehicle_type_id": int,
    "name": String,
    "display_name": String,
    "tier": int,
    "category": int,
    "max_durability": int,
    "armor": int,
    "max_magic_energy": int,
    "base_speed": float,
    "load_capacity": int,
    "warehouse_slots": int,
    "weapon_mounts": int,
    "weapon_mount_config": Array[Dictionary],
    "modification_slots": int,
    "modification_config": Array[Dictionary],
    "unlock_day": int,
    "unlock_cost": Dictionary,
    "visual_config_id": String,
    "description": String,
    "flavor_text": String,
    "deploy_durability_min": float,
    "deploy_magic_energy_min": float,
    "retreat_magic_energy_threshold": float,
    "retreat_durability_threshold": float
}
```

**Query Behavior Rules:**

1. 所有查询方法立即返回 — 无异步加载，数据库预加载
2. Invalid vehicle_type_id返回null或默认值（int返回0，float返回0.0，string返回""）
3. 查询方法是线程安全的读取操作 — 无需mutex
4. 数据库在游戏启动时加载一次，运行期间不可变
5. 本地化查询（`get_display_name`）委托给LocalizationManager

### States and Transitions

战车类型数据库是静态数据定义系统，不管理运行时状态。每个战车类型定义在数据创建后即固定不变。运行时的战车实例状态由战车属性系统管理。

#### Vehicle Type Definition States

每个战车类型定义有以下生命周期状态：

| State | Condition | Description |
|-------|-----------|-------------|
| `ACTIVE` | 战车类型定义完成并可用 | 战车类型可被查询和部署 |
| `DEPRECATED` | 战车类型标记废弃 | 战车类型不再在新内容使用，现有实例正常功能 |
| `PLANNED` | GDD定义但未实现 | 战车类型ID预留，返回null |

**State transition rules:**

1. `PLANNED → ACTIVE`: 当VehicleDefinition资源文件创建并注册
2. `ACTIVE → DEPRECATED`: 当战车类型从内容管线移除
3. 无其他转换 — 战车类型定义运行时不变

#### Runtime Vehicle Instance States (Owned by 战车属性系统)

战车类型数据库不管理运行时状态。运行时战车实例的状态由战车属性系统管理，包括：
- 耐久值（current_durability）
- 魔能值（current_magic_energy）
- 武器装备状态
- 改装安装状态
- 运动状态（移动/静止/碰撞）

---

### Interactions with Other Systems

#### Upstream Systems (无)

战车类型数据库是Foundation层系统，无上游依赖。数据定义独立于其他系统。

#### Downstream Consumer Systems

| Consumer System | Priority | Layer | Data Consumed | Query Methods | Dependency Type |
|-----------------|----------|-------|---------------|---------------|-----------------|
| **战车属性系统** | MVP | Core | max_durability, armor, max_magic_energy, base_speed | `get_vehicle_definition()`, `get_max_durability()`, `get_armor()` | **Blocking** — 战车实例属性依赖类型定义 |
| **战车驾驶系统** | MVP | Core | base_speed, load_capacity | `get_base_speed()`, `get_load_capacity()` | **Blocking** — 驾驶速度/负重计算依赖类型定义 |
| **战车武器系统** | MVP | Core | weapon_mounts, weapon_mount_config | `get_weapon_mount_count()`, `get_weapon_mount_config()` | **Blocking** — 武器挂载点配置依赖类型定义 |
| **战车损坏系统** | MVP | Core | max_durability, armor | `get_max_durability()`, `get_armor()` | **Blocking** — 损坏计算依赖耐久上限和护甲 |
| **战车维修系统** | Vertical Slice | Feature | max_durability | `get_max_durability()` | **Blocking** — 维修目标上限依赖耐久上限 |
| **战车改装系统** | Vertical Slice | Feature | modification_slots, modification_config | `get_modification_slots()` | **Blocking** — 改装槽位配置依赖类型定义 |
| **战车仓库系统** | Vertical Slice | Feature | warehouse_slots, load_capacity | `get_warehouse_slots()` | **Blocking** — 仓库格子数量依赖类型定义 |
| **撤退判定系统** | MVP | Core | retreat thresholds | `should_retreat()`, `get_retreat_thresholds()` | **Blocking** — 撤退触发判断依赖阈值定义 |
| **多战车管理** | Alpha | Feature | vehicle type list | `get_vehicles_by_category()`, `get_vehicles_by_unlock_day()` | **Blocking** — 多战车选择依赖类型列表 |
| **HUD系统** | Full Vision | Presentation | display_name, tier, category | `get_display_name()`, `get_tier()` | **Non-blocking** — UI显示查询 |

#### Detailed Interaction Specifications

##### 战车属性系统

**Data provided:**
- 完整战车类型定义（创建战车实例时读取）
- 耐久上限、护甲、魔能容量、速度

**Query methods called:**
- `VehicleTypes.get_vehicle_definition(vehicle_type_id)` — 创建战车实例时读取全部属性
- `VehicleTypes.get_max_durability(vehicle_type_id)` — 初始化耐久值
- `VehicleTypes.get_max_magic_energy(vehicle_type_id)` — 初始化魔能值

**Interaction contract:**
- 战车属性系统查询一次类型定义，缓存结果用于实例
- VehicleTypes返回不可变数据 — 战车属性系统存储副本，不追踪类型变化

##### 战车驾驶系统

**Data provided:**
- 基础速度用于移动计算
- 载重量用于速度修正公式

**Query methods called:**
- `VehicleTypes.get_base_speed(vehicle_type_id)` — 基础移动速度
- `VehicleTypes.get_load_capacity(vehicle_type_id)` — 载重量上限

**Interaction contract:**
- 驾驶系统使用base_speed作为初始速度，根据实际载重应用修正公式
- load_capacity用于超载判断

##### 撤退判定系统

**Data provided:**
- 撤退触发阈值（魔能20%、耐久30%）

**Query methods called:**
- `VehicleTypes.should_retreat(vehicle_type_id, durability_ratio, magic_energy_ratio)` — 判断是否触发撤退
- `VehicleTypes.get_retreat_magic_energy_threshold(vehicle_type_id)` — 魔能阈值
- `VehicleTypes.get_retreat_durability_threshold(vehicle_type_id)` — 耐久阈值

**Interaction contract:**
- 撤退判定系统每帧检查战车状态
- 当魔能ratio低于阈值或耐久ratio低于阈值时触发撤退警告

## Formulas

战车类型数据库主要提供静态数据定义。以下为下游系统使用的计算规则。

### Speed Load Modifier Formula

战车实际速度受载重量影响（由战车驾驶系统计算）：

```
actual_speed = base_speed × load_modifier
load_modifier = 1.0 - (current_load / load_capacity × 0.3)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `base_speed` | BS | float | 1.0-10.0 | VehicleTypes.get_base_speed() |
| `current_load` | CL | int | 0-500 | 当前载重量（仓库物品总重量） |
| `load_capacity` | LC | int | 50-500 | VehicleTypes.get_load_capacity() |

**Output Range:** 0.7-10.0（满载时速度最多降低30%）

**Example:**
- Heavy Elite (base_speed=1.2, load_capacity=350)
- current_load=200 → load_modifier = 1.0 - (200/350 × 0.3) = 1.0 - 0.17 = 0.83
- actual_speed = 1.2 × 0.83 = 0.996 ≈ 1.0格/秒

---

### Damage Reduction Formula

护甲减伤计算（由战车损坏系统使用）：

```
actual_damage = incoming_damage × (1 - armor%)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `incoming_damage` | ID | int | 1-100 | 敌人/环境伤害值 |
| `armor` | A | int | 0-80 | VehicleTypes.get_armor() |

**Output Range:** 1-100（护甲0%时全伤，护甲80%时减伤至20%）

**Example:**
- incoming_damage=50, armor=30 → actual_damage = 50 × 0.7 = 35
- incoming_damage=50, armor=80 → actual_damage = 50 × 0.2 = 10

---

### Retreat Trigger Formula

撤退触发判断（布尔逻辑，非数值计算）：

```
should_retreat = (magic_energy_ratio < retreat_magic_threshold) OR 
                 (durability_ratio < retreat_durability_threshold)
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `magic_energy_ratio` | float | 0.0-1.0 | 当前魔能/最大魔能 |
| `durability_ratio` | float | 0.0-1.0 | 当前耐久/最大耐久 |
| `retreat_magic_threshold` | float | 0.1-0.3 | 默认0.20 |
| `retreat_durability_threshold` | float | 0.2-0.4 | 默认0.30 |

**Output:** boolean (true = trigger retreat warning)

**Example:**
- magic_energy_ratio=0.15, durability_ratio=0.50 → should_retreat = true (魔能低于20%)
- magic_energy_ratio=0.25, durability_ratio=0.25 → should_retreat = true (耐久低于30%)
- magic_energy_ratio=0.30, durability_ratio=0.40 → should_retreat = false

---

### Deploy Validation Formula

出发条件判断（布尔逻辑）：

```
can_deploy = (durability_ratio >= deploy_durability_min) AND 
             (magic_energy_ratio >= deploy_magic_energy_min)
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `durability_ratio` | float | 0.0-1.0 | 当前耐久/最大耐久 |
| `magic_energy_ratio` | float | 0.0-1.0 | 当前魔能/最大魔能 |
| `deploy_durability_min` | float | 0.5-1.0 | 默认0.80 |
| `deploy_magic_energy_min` | float | 0.3-0.7 | 默认0.50 |

**Output:** boolean (true = can deploy)

**Example:**
- durability_ratio=0.85, magic_energy_ratio=0.60 → can_deploy = true
- durability_ratio=0.75, magic_energy_ratio=0.60 → can_deploy = false (耐久低于80%)

---

### Tier Stat Reference Formula

层级属性倍率（设计参考，非运行时计算）：

```
reference_durability = CATEGORY_BASE_DURABILITY × TIER_MODIFIER
reference_armor = CATEGORY_BASE_ARMOR × TIER_MODIFIER
```

**Category Base Values:**

| Category | Base Durability | Base Armor | Base Speed | Base Magic Energy |
|----------|-----------------|------------|------------|-------------------|
| `SCOUT` | 80 | 10 | 5.0 | 100 |
| `STANDARD` | 120 | 20 | 3.0 | 120 |
| `HEAVY` | 250 | 50 | 1.5 | 200 |
| `SPECIAL` | 150 | 30 | 3.0 | 150 |

> **Note**: 此公式仅供设计师参考，确保战车数值一致。实际数值由设计师手动定义，不自动计算。

## Edge Cases

### 1. Invalid Vehicle Type ID Query

**Case**: 系统查询不存在于数据库中的战车类型ID。

| Scenario | Input | Expected Behavior | Recovery |
|----------|-------|-------------------|----------|
| `vehicle_type_id = 0` | `get_vehicle_definition(0)` | Return `NULL_VEHICLE_DEFINITION` (ID 0 reserved as error fallback) | No error thrown; downstream system handles null |
| `vehicle_type_id < 0` | `get_vehicle_definition(-1)` | Return `null`, log warning: "Invalid vehicle_type_id: -1 (negative)" | Downstream system checks for null |
| `vehicle_type_id > 65535` | `get_vehicle_definition(70000)` | Return `null`, log warning: "Invalid vehicle_type_id: exceeds 16-bit range" | Downstream system handles missing vehicle |
| `vehicle_type_id` not registered | `get_vehicle_definition(50)` (ID range 50-99 empty) | Return `null`, log warning: "vehicle_type_id not found in registry" | Downstream system handles missing vehicle |

**Implementation Rule**: All query methods return `null` or appropriate default (int=0, float=0.0, string="") for invalid IDs without throwing exceptions. Database never crashes on invalid input.

---

### 2. Missing Vehicle Definition (PLANNED State)

**Case**: Vehicle type ID is reserved in allocation scheme but VehicleDefinition not yet created (PLANNED state).

| Scenario | Trigger | Expected Behavior | Resolution |
|----------|---------|-------------------|------------|
| Query PLANNED vehicle | `get_vehicle_definition(350)` (special slot, not implemented) | Return `null`, log warning: "vehicle_type_id is in PLANNED state" | Developer must create definition |
| Garage menu references PLANNED vehicle | Garage UI shows vehicle ID 350 | Garage system filters out PLANNED vehicles | Content must only reference ACTIVE vehicles |

---

### 3. Deprecated Vehicle Types in Existing Saves

**Case**: Player loads save file containing deprecated vehicle instances.

| Scenario | Input | Expected Behavior | Player Experience |
|----------|-------|-------------------|-------------------|
| Deprecated vehicle in garage | Save contains vehicle_type_id=15 (deprecated scout) | VehicleTypes returns DEPRECATED definition | Vehicle renders normally, functions normally |
| Deprecated vehicle deployed | Player deploys deprecated vehicle | Vehicle operates using stored attributes | No difference from active vehicle |

**Deprecation Rule**: DEPRECATED vehicle types remain queryable. They are removed from garage menu and new unlocks, but existing instances remain fully functional.

---

### 4. Category/Tier ID Mismatch

**Case**: Vehicle type ID suggests different category or tier than stored fields.

| Scenario | Input | Expected Behavior | System Response |
|----------|-------|-------------------|-----------------|
| ID suggests Scout (1-99) but category=1 | `get_vehicle_definition(10)` returns category=1 (Standard) | Log warning "ID-range/category mismatch", return definition as-is | Design error, runtime does not auto-correct |
| ID suggests Elite (offset 50-79) but tier=2 | `get_vehicle_definition(260)` returns tier=2 | Log warning, return definition as-is | Mismatch breaks visual-to-stat mapping |

---

### 5. Weapon Mount Configuration Invalid

**Case**: Weapon mount configuration violates rules.

| Scenario | Trigger | Expected Behavior | Resolution |
|----------|---------|-------------------|------------|
| `weapon_mounts=2` but only 1 slot config defined | Definition inconsistency | Log error "weapon_mounts count mismatch", return definition with warning | Designer must fix configuration |
| PRIMARY slot not at index 0 | slot_index=0 is SECONDARY type | Log warning "PRIMARY slot must be index 0", accept definition | Non-blocking but violates visual convention |
| Locked slot without unlock_cost | `is_locked=1` but `unlock_cost={}` | Log error "locked slot missing unlock_cost", treat as unlocked | Designer must add unlock_cost |

---

### 6. Modification Slot Configuration Invalid (Vertical Slice)

**Case**: Modification slot configuration violates rules.

| Scenario | Trigger | Expected Behavior | Resolution |
|----------|---------|-------------------|------------|
| Same slot_category 3+ times | All slots are ARMOR (category 1) | Log warning "slot_category repetition exceeds limit (2)", accept definition | Designer should diversify slots |
| `modification_slots` count mismatch | `modification_slots=4` but 3 configs defined | Log error, use actual config count | Designer must fix |
| Legendary vehicle has 7 slots | `modification_slots=7` exceeds max | Clamp to 6, log warning | Maximum 6 slots enforced |

---

### 7. Stat Boundary Cases

| Scenario | Condition | Expected Behavior |
|----------|-----------|-------------------|
| `max_durability < 50` | Below minimum | Reject definition with error "durability below minimum (50)" |
| `max_durability > 500` | Above maximum | Clamp to 500, log warning |
| `armor > 80` | Exceeds cap | Clamp to 80, log warning (80% cap prevents invulnerability) |
| `armor = 100` | Invalid value | Set to 80 (cap), log warning |
| `base_speed < 1.0` | Below minimum | Clamp to 1.0, log warning |
| `base_speed > 10.0` | Above maximum | Clamp to 10.0, log warning |
| `warehouse_slots = 0` | Invalid (minimum 20) | Set to 20, log warning |

---

### 8. Unlock Day Validation

| Scenario | Condition | Expected Behavior |
|----------|-----------|-------------------|
| `unlock_day = 0` | Day 0 invalid | Reject definition with error "unlock_day must be >= 1" |
| `unlock_day > 30` | Exceeds MVP content range | Accept, log warning "unlock_day exceeds MVP max (30)" |
| `get_vehicles_by_unlock_day(0)` | Invalid query day | Return empty array `[]` |

---

### 9. Retreat Threshold Edge Cases

| Scenario | Condition | Expected Behavior |
|----------|-----------|-------------------|
| Both thresholds triggered | Magic AND durability below thresholds | Return true (any trigger causes retreat) |
| Threshold exactly at boundary | magic_energy_ratio = 0.20 exactly | Return true (threshold inclusive, at boundary triggers) |
| Threshold inverted | durability threshold > deploy durability min | Log warning "retreat_threshold > deploy_min, may cause immediate retreat", accept definition |

---

### 10. Cross-System Query Timing

| Scenario | Trigger | Expected Behavior | Resolution |
|----------|---------|-------------------|------------|
| Query before VehicleTypes ready | System queries during `_init()` | VehicleTypes autoload not ready → returns `null` | Downstream systems must query in `_ready()` or after signal |
| Early query before autoloads load | `_init()` stage query | Return default values (0, 0.0, "") | Query after `vehicle_types_loaded` signal |

**Initialization Order**: VehicleTypes must load before 战车属性系统、战车驾驶系统.

## Dependencies

### Upstream Dependencies (无)

战车类型数据库是Foundation层系统，无上游依赖。数据定义独立于其他系统。

### Downstream Dependencies

| System | Priority | Layer | Data Consumed | Dependency Type |
|--------|----------|-------|---------------|-----------------|
| **战车属性系统** | MVP | Core | Full definition | **Blocking** — Cannot create vehicle instance without type definition |
| **战车驾驶系统** | MVP | Core | base_speed, load_capacity | **Blocking** — Movement calculation requires speed |
| **战车武器系统** | MVP | Core | weapon_mount_config | **Blocking** — Weapon slots must be defined |
| **战车损坏系统** | MVP | Core | max_durability, armor | **Blocking** — Damage reduction requires armor |
| **战车维修系统** | Vertical Slice | Feature | max_durability | **Blocking** — Repair target requires durability cap |
| **战车改装系统** | Vertical Slice | Feature | modification_slots | **Blocking** — Modification requires slot config |
| **战车仓库系统** | Vertical Slice | Feature | warehouse_slots | **Blocking** — Warehouse UI requires slot count |
| **撤退判定系统** | MVP | Core | retreat thresholds | **Blocking** — Retreat logic requires thresholds |
| **多战车管理** | Alpha | Feature | vehicle type list | **Blocking** — Vehicle selection requires catalog |
| **HUD系统** | Full Vision | Presentation | display_name | **Non-blocking** — UI queries for display |

### Critical Dependency Path (MVP)

```
VehicleTypeDatabase → 战车属性系统 → 战车驾驶系统 → 撤退判定系统
VehicleTypeDatabase → 战车武器系统 → 尸潮防守
VehicleTypeDatabase → 战车损坏系统 → 撤退判定系统
```

### Bidirectional Check

| Dependency | Listed Here | Listed in Target | Status |
|------------|-------------|------------------|--------|
| VehicleAttribute → VehicleTypeDatabase | Listed as Blocking | Target GDD not written | Pending |
| VehicleDriving → VehicleTypeDatabase | Listed as Blocking | Target GDD not written | Pending |
| VehicleWeapon → VehicleTypeDatabase | Listed as Blocking | Target GDD not written | Pending |

## Tuning Knobs

### Primary Tuning Knobs (影响核心玩法)

| Knob | Current Value | Safe Range | Gameplay Effect | Pillar Affected |
|------|---------------|------------|-----------------|-----------------|
| **基础耐久上限范围** | Scout:60-100, Standard:100-150, Heavy:250-400 | ±30% | 耐久定义生存边界。提高耐久 → 探索时间更长 → 搜打撤压力降低 | Pillar 1: 战车即生命 |
| **护甲上限** | 80% max | 50-90% | 护甲定义减伤能力。提高上限 → 防守更强 → 尸潮突破更难 | Pillar 1 & 3 |
| **基础速度范围** | Scout:5.0-6.0, Heavy:1.2-2.0 | ±20% | 速度定义探索效率。提高速度 → 探索更快 → 搜打撤时间窗口扩大 | Pillar 2: 搜打撤节奏 |
| **魔能容量范围** | Scout:80-120, Heavy:200-300 | ±25% | 魔能定义续航距离。提高容量 → 探索距离更长 → 撤退触发延迟 | Pillar 2 |
| **撤退魔能阈值** | 20% default | 15-30% | 撤退触发时机。降低阈值 → 撤退更晚 → 风险更大但收益更高 | Pillar 2 |
| **撤退耐久阈值** | 30% default | 20-40% | 撤退触发时机。降低阈值 → 撤退更晚 → 战车更可能瘫痪 | Pillar 1 |

### Secondary Tuning Knobs

| Knob | Current Value | Safe Range | Gameplay Effect |
|------|---------------|------------|-----------------|
| **出发耐久最低要求** | 80% default | 70-95% | 出发门槛。提高要求 → 玩家必须更充分维修才能出发 |
| **出发魔能最低要求** | 50% default | 40-70% | 出发门槛。提高要求 → 玩家必须更充分补充魔能 |
| **载重量速度修正系数** | 0.3 (max 30% reduction) | 0.2-0.5 | 超载惩罚。提高系数 → 满载速度更慢 → 搜打撤节奏变化 |
| **仓库格子基准** | 100 slots default | 80-150 | 储存容量。增加格子 → 资源运输更多 → 搜刮收益提升 |

### Tier Tuning Knobs

| Knob | Default | Purpose | Effect on Design |
|------|---------|---------|------------------|
| `tier_durability_mult` | 1.0→1.2→1.5→2.0→2.5 | 层级耐久递进 | Tier 5 durability = Tier 1 × 2.5 |
| `tier_armor_mult` | 1.0→1.2→1.5→2.0→2.5 | 层级护甲递进 | Tier 5 armor = Tier 1 × 2.5 |
| `tier_speed_mult` | 1.0→1.0→0.9→0.8→0.7 | 层级速度递减 | Heavy vehicles slower at high tier |
| `tier_weapon_mounts_base` | 0→1→2→3→4 | 层级武器挂载点递增 | Legendary tier = 4 mounts |

### Knob Interactions

- **`retreat_magic_threshold` × `max_magic_energy`**: 魔能绝对值触发点 = max_magic_energy × threshold
- **`load_modifier_coefficient` × `base_speed`**: 满载实际速度 = base_speed × (1 - 0.3)
- **`armor` × `incoming_damage`**: 实际伤害 = incoming × (1 - armor%)

### Knobs That Should NOT Be Tuned

| Knob | Reason |
|------|--------|
| **vehicle_type_id allocation ranges** | ID分配是架构决策，改变会破坏跨系统引用一致性 |
| **Category enumeration (0-3)** | 分类枚举是系统约定，添加新分类需更新所有依赖系统 |
| **Tier enumeration (1-5)** | 层级枚举是系统约定，改变需更新所有依赖系统 |
| **Maximum weapon mounts (4)** | MVP架构限制，增加需重新设计武器UI |

## Visual/Audio Requirements

战车类型数据库是纯数据系统，不直接产生视觉或音频输出。以下列出下游系统需要的视觉/音频数据映射。

### Visual Data Provided by VehicleTypeDatabase

| Data | Type | Consumer System | Visual Effect |
|------|------|-----------------|---------------|
| **visual_config_id** | Resource path | 战车渲染系统 | 确定战车外观（sprite、动画、粒子效果） |
| **category** | int (0-3) | 战车渲染系统 | 确定战车视觉风格（Scout轻快、Heavy厚重） |
| **tier** | int (1-5) | 战车渲染系统 | 确定战车装饰等级（Basic朴素、Legendary华丽） |
| **display_name** | Localized string | HUD tooltip | 战车名称显示 |

### Vehicle Visual Archetypes by Category

| Category | Visual Archetype | Core Visual Features |
|----------|------------------|----------------------|
| **SCOUT** | 轻型侦察风格 | 小型轮廓、流线车身、低装甲覆盖、高机动感 |
| **STANDARD** | 标准多用途风格 | 中等轮廓、平衡装甲、实用外观 |
| **HEAVY** | 重型钢铁巨兽风格 | 大型轮廓、厚装甲板、重型武器挂载点、低稳姿态 |
| **SPECIAL** | 魔导科技风格 | 晶石装饰、符文发光、独特轮廓 |

### Tier Visual Progression

| Tier | Visual Decoration | Visual Effects |
|------|-------------------|----------------|
| **BASIC (1)** | 无装饰、锈蚀残留、朴素外观 | 无特效 |
| **STANDARD (2)** | 轻度装甲覆盖、基础涂装 | 边缘微弱发光 |
| **ADVANCED (3)** | 中度装甲覆盖、符文纹路、魔导装饰 | 轮廓发光脉动 |
| **ELITE (4)** | 重度装甲覆盖、符文高亮、晶石点缀 | 全身发光脉动、引擎粒子 |
| **LEGENDARY (5)** | 完全装甲覆盖、符文全覆盖、晶石镶嵌 | 全身强发光、魔导粒子特效、独特光环 |

### Audio Data Provided by VehicleTypeDatabase

数据库不存储音频文件。音频由下游系统根据category/tier动态选择：

| Audio Event | Consumer System | Data Used | Audio Selection Logic |
|-------------|-----------------|-----------|----------------------|
| **引擎启动音效** | 战车驾驶系统 | category, tier | Heavy → 低沉引擎声；Scout → 轻快引擎声；Legendary → 魔导启动声 |
| **移动音效** | 战车驾驶系统 | base_speed, category | Heavy → 重型履带声；Scout → 轻型轮胎声 |
| **碰撞音效** | 战车驾驶系统 | armor | 高护甲 → 金属碰撞声；低护甲 → 轻碰撞声 |
| **损坏警报音效** | 战车损坏系统 | retreat thresholds | 达到阈值 → 警报声（魔能警报 vs 耐久警报不同音效） |
| **撤退触发音效** | 撤退判定系统 | threshold type | 魔能撤退 vs 耐久撤退不同警报音 |

## UI Requirements

战车类型数据库为UI系统提供数据支持，但本身不渲染UI。

### UI Data Provided by VehicleTypeDatabase

| UI Element | Data Source | Display Context | Consumer System |
|------------|-------------|-----------------|-----------------|
| **车库战车列表** | `get_vehicles_by_unlock_day(day)` | 车库菜单显示可用战车 | 多战车管理系统 |
| **战车Tooltip** | `get_vehicle_definition()` | 悬停战车时显示属性 | HUD系统 |
| **战车状态面板** | `get_max_durability()`, `get_max_magic_energy()` | 显示耐久/魔能上限 | HUD系统 |
| **出发条件提示** | `get_deploy_durability_min()`, `get_deploy_magic_energy_min()` | 显示出发最低要求 | HUD系统 |
| **撤退警告阈值** | `get_retreat_thresholds()` | 显示撤退触发条件 | 撤退警告UI |

### Garage Vehicle List Display

| Element | Format | Data Query |
|---------|--------|------------|
| **战车图标** | visual_config_id sprite | Texture lookup |
| **战车名称** | display_name (localized) | `get_display_name()` |
| **层级标识** | ★×tier (1-5星) | `get_tier()` |
| **分类标签** | "侦察"/"标准"/"重型" | `get_category()` → text mapping |
| **武器挂载点** | "武器槽: 2/4" | `get_weapon_mount_count()` |
| **解锁状态** | ✓ or 锁定图标 | `unlock_day <= current_day` |

### Vehicle Tooltip Layout

```
┌─────────────────────┐
│ 标准战车        ★★☆☆│
│ ─────────────────── │
│ 分类: 标准多用途     │
│ 层级: Standard      │
│ 耐久上限: 120       │
│ 护甲: 20%           │
│ 魔能容量: 120       │
│ 速度: 3.5 格/秒     │
│ 仓库: 120格         │
│ 武器挂载: 2         │
│ 解锁天数: Day 5     │
└─────────────────────┘
```

### Deploy Status Display

| Element | Format | Logic |
|---------|--------|-------|
| **出发状态** | 绿灯 ✓ / 红灯 ✗ | `can_deploy()` result |
| **耐久要求** | "耐久 ≥ 80%" | `get_deploy_durability_min()` |
| **魔能要求** | "魔能 ≥ 50%" | `get_deploy_magic_energy_min()` |
| **当前状态** | "耐久 85% ✓ / 魔能 45% ✗" | Compare current ratios to thresholds |

### Retreat Warning Display

| Warning Level | Trigger | Display |
|---------------|---------|---------|
| **魔能低** | magic_ratio < 0.20 | 黄色警告：魔能不足20% |
| **耐久低** | durability_ratio < 0.30 | 红色警告：耐久不足30% |
| **双重警告** | Both triggered | 红色闪烁：立即撤退建议 |

## Acceptance Criteria

### Data Integrity Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-001** | Vehicle definition registry loaded | 启动游戏，检查VehicleTypes autoload | VehicleTypes._ready()完成，无error log |
| **AC-002** | Vehicle type ID unique | 检查registry vehicle_type_id唯一性 | 每个vehicle_type_id唯一，无冲突 |
| **AC-003** | ID allocation follows scheme | 验证每个vehicle ID在正确category range | Scout在1-99, Standard在100-199, Heavy在200-299 |
| **AC-004** | Tier value valid | 检查所有vehicle tier值 | 所有tier在1-5范围 |
| **AC-005** | Category value valid | 检查所有vehicle category值 | 所有category在0-3范围 |
| **AC-006** | Durability in valid range | 检查所有max_durability | 所有durability在50-500范围 |
| **AC-007** | Armor in valid range | 检查所有armor值 | 所有armor在0-80范围 |
| **AC-008** | Magic energy in valid range | 检查所有max_magic_energy | 所有magic_energy在50-500范围 |
| **AC-009** | Speed in valid range | 检查所有base_speed | 所有speed在1.0-10.0范围 |
| **AC-010** | Weapon mounts valid | 检查weapon_mounts值 | 所有weapon_mounts在0-4范围 |
| **AC-011** | Warehouse slots valid | 检查warehouse_slots值 | 所有warehouse_slots在20-200范围 |

### Query API Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-012** | Valid ID returns correct data | `get_vehicle_definition(100)` | Returns Dictionary with correct name="standard_basic", tier=1, durability=100 |
| **AC-013** | Invalid ID returns null | `get_vehicle_definition(500)` (不存在) | Returns `null`, 无exception |
| **AC-014** | ID=0 returns NULL_VEHICLE | `get_vehicle_definition(0)` | Returns predefined NULL_VEHICLE_DEFINITION |
| **AC-015** | Category query correct | `get_vehicles_by_category(2)` (Heavy) | Returns ID 210, 220, 250 |
| **AC-016** | Tier query correct | `get_vehicles_by_tier(3)` (Advanced) | Returns ID 120, 220 |
| **AC-017** | Unlock day query correct | `get_vehicles_by_unlock_day(10)` | Returns vehicles with unlock_day <= 10 |
| **AC-018** | Threshold query correct | `get_retreat_magic_energy_threshold(100)` | Returns 0.20 |
| **AC-019** | Deploy validation correct | `can_deploy(100, 0.85, 0.60)` | Returns true (both thresholds met) |
| **AC-020** | Retreat trigger correct | `should_retreat(100, 0.50, 0.15)` | Returns true (magic below 20%) |

### MVP Catalog Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-021** | Scout vehicles defined | 检查ID range 1-99 | 至少2个Scout定义（scout_basic=1, scout_standard=10） |
| **AC-022** | Standard vehicles defined | 检查ID range 100-199 | 至少3个Standard定义（standard_basic=100, standard_standard=110, standard_advanced=120） |
| **AC-023** | Heavy vehicles defined | 检查ID range 200-299 | 至少3个Heavy定义（heavy_standard=210, heavy_advanced=220, heavy_elite=250） |
| **AC-024** | Starting vehicle exists | 检查ID 100存在且unlock_day=1 | standard_basic unlocked on Day 1 |

### Edge Case Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-025** | Negative ID returns null | `get_vehicle_definition(-1)` | Returns `null`, 无crash |
| **AC-026** | ID exceeds range returns null | `get_vehicle_definition(70000)` | Returns `null`, 无crash |
| **AC-027** | PLANNED vehicle returns null | `get_vehicle_definition(350)` (PLANNED) | Returns `null`, log warning |
| **AC-028** | Invalid stat clamped | Create definition with armor=90 | Clamped to 80, warning logged |
| **AC-029** | Deploy threshold edge | `can_deploy(100, 0.80, 0.50)` | Returns true (exactly at boundary) |
| **AC-030** | Retreat threshold edge | `should_retreat(100, 0.70, 0.20)` | Returns true (magic exactly at threshold) |

### Performance Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-031** | Query latency < 0.1ms | 循环`get_vehicle_definition(100)` 1000次，测量平均耗时 | 平均耗时 < 0.1ms |
| **AC-032** | Registry load time < 300ms | 测量VehicleTypes autoload初始化耗时 | 加载时间 < 300ms |
| **AC-033** | Memory footprint < 500KB | 测量VehicleTypes singleton内存占用 | 内存占用 < 500KB |

### Pass/Fail Threshold

| Category | Pass Count | Fail Action |
|----------|------------|-------------|
| **Data Integrity (AC-001 to AC-011)** | 必须100%通过 | 任一失败 → 数据定义错误，必须修复 |
| **Query API (AC-012 to AC-020)** | 必须100%通过 | 任一失败 → API实现错误，必须修复 |
| **MVP Catalog (AC-021 to AC-024)** | 必须100%通过 | 任一失败 → 内容不足，必须补充 |
| **Edge Cases (AC-025 to AC-030)** | 必须100%通过 | 任一失败 → 边界处理缺失，必须补充 |
| **Performance (AC-031 to AC-033)** | 必须通过 | 任一失败 → 性能优化，但可进入实现阶段 |

**Total Criteria**: 33
**Required for Implementation**: 100% pass on all blocking categories

## Open Questions

### High Priority (Implementation Blocking)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-001** | 武器类型数据库是否已设计？武器挂载点引用weapon_type_id，但武器类型定义需确认。 | 武器类型数据库GDD | 战车武器系统实现前 | 无法验证weapon_mount_config的有效性 |
| **Q-002** | 改装类型数据库是否已设计？改装槽位引用modification_type_id，但改装类型定义需确认。 | 改装系统GDD | 战车改装系统实现前 | 无法验证modification_config的有效性 |
| **Q-003** | 战车视觉配置架构是否确认？visual_config_id引用视觉资源，但视觉配置文件格式需确认。 | 艺术总监 | 战车渲染系统实现前 | 无法加载战车视觉资源 |

### Medium Priority (Design Clarification)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-004** | 撤退阈值是否需要per-vehicle自定义？当前设计假设全局阈值，但不同战车可能有不同阈值需求。 | 游戏设计者 | 撤退判定系统设计前 | 影响撤退判定逻辑复杂度 |
| **Q-005** | 是否需要战车类型描述文本用于UI？当前description仅用于内部文档，但可能需要UI显示。 | UX设计者 | Beta阶段 | 不影响MVP实现 |
| **Q-006** | 是否需要支持动态添加战车类型（mod/expansion）？当前设计假设静态registry。 | 技术总监 | Alpha里程碑前 | 影响ID allocation scheme扩展策略 |

### Low Priority (Future Consideration)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-007** | 是否需要战车类型稀有度系统？当前无稀有度字段，但可能有稀有战车解锁机制。 | 游戏设计者 | Beta阶段 | 不影响MVP实现 |
| **Q-008** | 是否需要战车类型阵营归属？当前无阵营字段，但可能有阵营科技绑定战车。 | 游戏设计者 | 阵营科技系统设计前 | 影响科技解锁关联 |

### Resolution Tracking

| ID | Status | Resolution Date | Resolved By | Summary |
|----|--------|-----------------|-------------|---------|
| Q-001 | Open | — | — | Pending 武器类型数据库GDD |
| Q-002 | Open | — | — | Pending 改装系统GDD |
| Q-003 | Open | — | — | Pending 艺术总监确认 |
| Q-004 | Open | — | — | Pending 游戏设计者决策 |
| Q-005 | Open | — | — | Pending UX设计者决策 |
| Q-006 | Open | — | — | Pending 技术总监决策 |
| Q-007 | Open | — | — | Pending 游戏设计者决策 |
| Q-008 | Open | — | — | Pending 阵营科技系统GDD |

### Assumptions Made

| Assumption | Rationale | Risk |
|------------|-----------|------|
| **撤退阈值全局统一** | 游戏概念文档定义魔能20%、耐久30%为统一阈值 | 如果不同战车需要不同阈值，需扩展设计 |
| **weapon_type_id未定义** | 武器系统为独立系统，将有自己的数据库 | 需在武器数据库完成后验证挂载点引用有效性 |
| **modification_slots=0 for MVP** | 改装系统为Vertical Slice，MVP阶段暂不实现 | Alpha阶段需补充改装槽位配置 |
| **visual_config_id为文件路径引用** | 遵循Godot资源路径约定 | 如果视觉配置格式不同，需调整引用方式 |