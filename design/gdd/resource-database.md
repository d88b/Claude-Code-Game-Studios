# 资源数据库

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-22
> **Implements Pillar**: Pillar 4 — 魔导科技美学 (资源类型传达魔导科技设定)
> **Priority**: MVP | **Layer**: Foundation
> **System ID**: #3 (from systems-index.md)

## Overview

资源数据库是游戏中所有资源类型定义的单一数据源。每个资源类型定义了该资源的基本属性、分类、稀有度、堆叠限制、以及用途标识，供所有资源相关系统（背包、仓库、掉落、合成、建造）查询使用。

资源数据库不产生任何游戏逻辑行为——它纯粹是静态数据定义。玩家不与"资源数据库"交互，而是通过背包、仓库、建造菜单等界面与具体的资源实例交互。背包中的每个资源实例引用一个资源类型ID，从数据库中读取该资源类型的属性。

**数据模型契约:**

每个资源类型必须定义以下核心属性：
- `resource_id` (int): 唯一标识符，0-65535
- `name` (string): 内部标识名（如"iron", "crystal_shard"）
- `display_name` (string): UI显示名称（本地化）
- `category` (enum): 资源分类（基础材料、魔导材料、稀有材料、消耗品、特殊）
- `rarity` (int): 稀有度等级（1-5），影响掉落率和UI高亮
- `max_stack_size` (int): 最大堆叠数量（背包/仓库单格上限）
- `base_value` (int): 基础交易价值（用于合成和建造消耗计算）
- `is_consumable` (bool): 是否为消耗品（可被直接使用）
- `is_build_material` (bool): 是否为建造材料（可用于建造系统）
- `is_craft_material` (bool): 是否为合成材料（可用于合成系统）

**数据库职责:**
- 定义所有资源类型及其属性
- 提供资源类型查询API（按ID、按名称、按分类、按用途）
- 存储资源的稀有度和堆叠规则
- 提供资源分类和用途过滤器

**下游消费系统:**
- 玩家背包系统 — 查询max_stack_size决定堆叠上限
- 战车仓库系统 — 查询max_stack_size和base_value计算存储价值
- 资源掉落系统 — 查询resource_id验证掉落类型
- 资源合成系统 — 查询is_craft_material和base_value计算合成成本
- 科技解锁系统 — 查询稀有度决定解锁门槛
- 建造物品数据库 — 查询is_build_material确定建造消耗
- 炮塔/陷阱系统 — 查询base_value计算维护成本

**已锁定的资源ID（来自方块类型数据库）:**
- ID 101-103: 基础金属矿（铁矿、铜矿、煤矿）
- ID 201-203: 魔导材料（魔力晶石碎片、魔力晶石簇、金矿）
- ID 301-302: 稀有材料（秘银矿脉、古代秘银）

## Player Fantasy

资源数据库没有直接的玩家幻想——它是静态数据基础设施，玩家不会"感知"到数据库的存在。玩家体验的是数据库定义的资源类型在实际游戏中的表现：收集不同稀有度资源时的成就感、管理背包堆叠的策略决策、建造和合成时对材料价值的评估。

### 玩家间接体验（由数据库定义的资源属性驱动）

- **稀有度辨识**: 玩家通过资源稀有度（1-5星）识别材料价值——"这是普通铁矿（rarity=1）"、"这是珍贵秘银（rarity=4）"。数据库的rarity值定义了这种价值感知层级。
- **堆叠管理策略**: 玩家背包管理受max_stack_size约束——"铁矿可堆叠100个" vs "秘银只能堆叠10个"。数据库的堆叠上限定义了背包空间管理的策略深度。
- **建造材料选择**: 玩家建造时选择不同材料组合——"用基础石块（铁×5）" vs "用秘银墙体（秘银×3）"。数据库的is_build_material和base_value定义了建造选项及其成本。

### 支柱间接贡献

- **Pillar 4: 魔导科技美学** — 资源分类（基础材料、魔导材料、稀有材料）和资源名称（魔力晶石、秘银、符文金属）传达魔导科技设定。玩家通过资源名称学习世界观词汇。

## Detailed Design

### Core Rules

#### 1. Resource Data Structure

每个资源类型定义为一个独立的数据记录，存储在ResourceDatabase资源文件中。所有资源类型共享统一的数据结构。

**Primary Resource Fields:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `resource_id` | int | 0-65535 | — | 唯一标识符，系统内部引用键 |
| `name` | string | — | — | 内部标识名（如"iron", "crystal_shard"），用于代码引用和本地化键 |
| `display_name` | string | — | — | UI显示名称（本地化键，实际显示由LocalizationManager处理） |
| `category` | int | 0-4 | — | 资源分类枚举值（见Category System） |
| `rarity` | int | 1-5 | 1 | 稀有度等级，影响掉落率、UI高亮、堆叠上限 |
| `max_stack_size` | int | 1-999 | — | 最大堆叠数量（背包/仓库单格上限） |
| `base_value` | int | 0-9999 | 1 | 基础交易价值（用于合成消耗计算、仓库价值评估） |
| `is_consumable` | int | 0-1 | 0 | 是否为消耗品（可被直接使用） |
| `is_build_material` | int | 0-1 | 0 | 是否为建造材料（可用于建造系统） |
| `is_craft_material` | int | 0-1 | 0 | 是否为合成材料（可用于合成系统） |

**Extended Resource Fields:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `icon_path` | string | — | — | Godot资源路径指向资源图标 |
| `description` | string | — | "" | 内部文档说明 |
| `drop_weight` | float | 0.0-10.0 | 1.0 | 掉落权重修饰符 |
| `tech_unlock_required` | int | 0-65535 | 0 | 解锁所需科技ID（0=默认解锁） |

**Field Validation Rules:**

1. `resource_id`必须唯一，不允许重复ID
2. `resource_id = 0`保留为"空资源"错误回退
3. `name`必须为有效的snake_case标识符（仅字母、数字、下划线）
4. `category`必须在枚举范围0-4内
5. `rarity`必须在范围1-5内
6. `max_stack_size`必须为正整数（>=1）
7. `base_value`必须为正整数或0

---

#### 2. Resource ID Allocation Scheme

资源ID按类别分配，确保ID范围可预测、可扩展。

**ID Range Allocation:**

| ID Range | Category | Description |
|----------|----------|-------------|
| 0 | — | `null_resource` — 保留为错误回退 |
| 1-99 | — | 系统内部资源（占位符、测试） |
| 100-199 | `basic_material` | 基础材料（铁矿、铜矿、煤矿） |
| 200-299 | `magitech_material` | 魔导材料（魔力晶石、金矿） |
| 300-399 | `rare_material` | 稀有材料（秘银、古代秘银） |
| 400-499 | `consumable` | 消耗品（食物、药剂） |
| 500-599 | `special` | 特殊/收藏类资源 |
| 600-65535 | — | 未来内容预留 |

**Locked IDs (来自block-type-database.md):**

| Locked ID | Name | Category |
|-----------|------|----------|
| 101 | 铁矿 | basic_material |
| 102 | 铜矿 | basic_material |
| 103 | 煤矿 | basic_material |
| 201 | 魔力晶石碎片 | magitech_material |
| 202 | 魔力晶石簇 | magitech_material |
| 203 | 金矿脉 | magitech_material |
| 301 | 秘银矿脉 | rare_material |
| 302 | 古代秘银 | rare_material |

---

#### 3. Resource Category System

**Category Enumeration:**

| Value | Name | Description | Default Rarity |
|-------|------|-------------|----------------|
| 0 | `basic_material` | 基础建造/合成材料 | 1-2 |
| 1 | `magitech_material` | 魔导科技材料 | 2-3 |
| 2 | `rare_material` | 稀有建造/合成材料 | 3-5 |
| 3 | `consumable` | 可消耗物品 | 1-3 |
| 4 | `special` | 特殊/收藏/任务物品 | 1-5 |

---

#### 4. Rarity System

稀有度等级影响掉落率、UI表现、堆叠上限。

**Rarity Levels:**

| Level | Name | Drop Rate Modifier | Stack Modifier | UI Color |
|-------|------|-------------------|----------------|----------|
| 1 | `common` | 100% | ×1.0 | 白色/灰色 |
| 2 | `uncommon` | 60% | ×0.8 | 绿色 |
| 3 | `rare` | 30% | ×0.5 | 蓝色 |
| 4 | `epic` | 10% | ×0.3 | 紫色 |
| 5 | `legendary` | 3% | ×0.1 | 金色/橙色 |

---

#### 5. Stack Size Rules

```
max_stack_size = CATEGORY_BASE_STACK × RARITY_MODIFIER
```

**Category Base Stack Values:**

| Category | Base Stack | Reasoning |
|----------|------------|-----------|
| `basic_material` | 100 | 基础资源量大，减少背包负担 |
| `magitech_material` | 50 | 核心资源适度 |
| `rare_material` | 20 | 稀有资源量小，增加价值感 |
| `consumable` | 30 | 消耗品适度 |
| `special` | 10 | 特殊物品限量 |

**Stack Size Calculation Examples:**

| Resource | Category | Rarity | Stack Calculation | Result |
|----------|----------|--------|-------------------|--------|
| 铁矿 | basic_material | 1 | 100 × 1.0 | 100 |
| 魔力晶石簇 | magitech_material | 3 | 50 × 0.5 | 25 |
| 秘银 | rare_material | 4 | 20 × 0.3 | 6 → **override to 10** |

---

#### 6. Value Calculation

**Base Value by Rarity (基准参考值):**

| Rarity | Base Value Range | Example |
|--------|-----------------|---------|
| 1 | 1-10 | 煤矿=3, 铁矿=5 |
| 2 | 10-30 | 魔力晶石碎片=15, 金矿=25 |
| 3 | 30-100 | 魔力晶石簇=50 |
| 4 | 100-300 | 秘银=120 |
| 5 | 300-999 | 古代秘银=300 |

---

#### 7. Usage Flags

| Flag | Systems Involved |
|------|-----------------|
| `is_build_material` | 建造物品数据库、方块放置系统 |
| `is_craft_material` | 资源合成系统、科技解锁系统 |
| `is_consumable` | 消耗品系统、背包系统 |

---

#### 8. Initial Resource Catalog (MVP)

**Basic Materials (ID 100-199):**

| ID | Name | Display | Rarity | Stack | Value | Build | Craft |
|----|------|---------|--------|-------|-------|-------|-------|
| 101 | `iron` | "铁矿" | 1 | 100 | 5 | 1 | 1 |
| 102 | `copper` | "铜矿" | 1 | 100 | 8 | 1 | 1 |
| 103 | `coal` | "煤矿" | 1 | 100 | 3 | 1 | 1 |
| 110 | `stone` | "石料" | 1 | 100 | 1 | 1 | 0 |
| 120 | `wood` | "木材" | 1 | 100 | 2 | 1 | 1 |

**Magitech Materials (ID 200-299):**

| ID | Name | Display | Rarity | Stack | Value | Build | Craft |
|----|------|---------|--------|-------|-------|-------|-------|
| 201 | `crystal_shard` | "魔力晶石碎片" | 2 | 40 | 15 | 1 | 1 |
| 202 | `crystal_cluster` | "魔力晶石簇" | 3 | 25 | 50 | 1 | 1 |
| 203 | `gold` | "金矿" | 2 | 40 | 25 | 0 | 1 |

**Rare Materials (ID 300-399):**

| ID | Name | Display | Rarity | Stack | Value | Build | Craft |
|----|------|---------|--------|-------|-------|-------|-------|
| 301 | `mithril` | "秘银" | 4 | 10 | 120 | 1 | 1 |
| 302 | `ancient_mithril` | "古代秘银" | 5 | 5 | 300 | 1 | 1 |

**Consumables (ID 400-499):**

| ID | Name | Display | Rarity | Stack | Value | Build | Craft | Consumable |
|----|------|---------|--------|-------|-------|-------|-------|------------|
| 401 | `food_basic` | "基础食物" | 1 | 30 | 5 | 0 | 0 | 1 |
| 402 | `fuel_basic` | "基础燃料" | 1 | 30 | 4 | 0 | 1 | 1 |

**MVP Total: 12 Resources** (8 locked from BlockTypeDatabase + 4 additional)

---

#### 9. Resource Database Query API

**Singleton Registration:**

```gdscript
# ResourceDatabase.gd (autoload singleton)
class_name ResourceDatabase
extends Node

# Autoload name: "Resources"
```

**Primary Query Methods:**

```gdscript
# === Basic Lookup ===
func get_resource_definition(resource_id: int) -> Dictionary
func get_resource_name(resource_id: int) -> String
func get_display_name(resource_id: int) -> String

# === Property Query ===
func get_category(resource_id: int) -> int
func get_rarity(resource_id: int) -> int
func get_max_stack_size(resource_id: int) -> int
func get_base_value(resource_id: int) -> int

# === Usage Query ===
func is_buildable(resource_id: int) -> bool
func is_craftable(resource_id: int) -> bool
func is_consumable(resource_id: int) -> bool

# === Category Query ===
func get_resources_by_category(category: String) -> Array[int]
func get_build_materials() -> Array[int]
func get_craft_materials() -> Array[int]

# === Validation ===
func is_valid_resource(resource_id: int) -> bool

# === Optimized Queries ===
func get_stack_info(resource_id: int) -> Dictionary
func get_value_info(resource_id: int) -> Dictionary
func get_tooltip_info(resource_id: int) -> Dictionary
```

**Query Return Format:**

```gdscript
# get_resource_definition returns:
{
    "resource_id": int,
    "name": String,
    "display_name": String,
    "category": int,
    "rarity": int,
    "max_stack_size": int,
    "base_value": int,
    "is_consumable": bool,
    "is_build_material": bool,
    "is_craft_material": bool,
    "icon_path": String,
    "description": String,
    "drop_weight": float,
    "tech_unlock_required": int
}
```

### States and Transitions

资源数据库是静态数据系统，不管理运行时状态。每个资源类型定义有生命周期状态：

| State | Condition | Description |
|-------|-----------|-------------|
| `ACTIVE` | 资源定义完成并可用 | 查询正常返回数据 |
| `DEPRECATED` | 标记废弃 | 仍可查询，不在新内容使用 |
| `PLANNED` | GDD定义但未实现 | ID预留，返回null |

**State transition rules:**

1. `PLANNED → ACTIVE`: 当ResourceDefinition资源文件创建
2. `ACTIVE → DEPRECATED`: 当资源从内容管线移除
3. 无其他转换 — 资源定义运行时不变

### Interactions with Other Systems

| Consumer System | Data Consumed | Query Methods | Timing |
|-----------------|---------------|---------------|--------|
| **玩家背包系统** | max_stack_size, display_name | `get_stack_info()` | On pickup/slot update |
| **战车仓库系统** | max_stack_size, base_value | `get_value_info()` | On transfer/value calc |
| **资源掉落系统** | resource_id validation | `is_valid_resource()` | On tile destruction |
| **资源合成系统** | is_craft_material, base_value | `get_craft_materials()`, `get_base_value()` | On recipe lookup |
| **建造物品数据库** | is_build_material, base_value | `get_build_materials()` | On build recipe |
| **科技解锁系统** | rarity | `get_rarity()`, `get_resources_by_rarity()` | On unlock check |
| **炮塔/陷阱系统** | base_value | `get_base_value()` | On maintenance cost |
| **HUD系统** | display_name, rarity | `get_tooltip_info()` | On hover |

## Formulas

资源数据库主要是静态数据定义，少数计算规则如下：

### Stack Size Calculation Formula

`max_stack_size` 字段可通过公式推导：

```
max_stack_size = floor(CATEGORY_BASE_STACK × RARITY_STACK_MODIFIER)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `CATEGORY_BASE_STACK` | CBS | int | 10-100 | Category-dependent base stack value |
| `RARITY_STACK_MODIFIER` | RSM | float | 0.1-1.0 | Rarity-dependent modifier |

**Category Base Stack Values:**

| Category | CBS Value |
|----------|-----------|
| basic_material | 100 |
| magitech_material | 50 |
| rare_material | 20 |
| consumable | 30 |
| special | 10 |

**Rarity Stack Modifier Values:**

| Rarity | RSM Value |
|--------|-----------|
| 1 (common) | 1.0 |
| 2 (uncommon) | 0.8 |
| 3 (rare) | 0.5 |
| 4 (epic) | 0.3 |
| 5 (legendary) | 0.1 |

**Output Range:** 1-100 under normal category/rarity combinations

**Example:**
- 铁矿 (category=basic, rarity=1): `max_stack_size = floor(100 × 1.0) = 100`
- 魔力晶石簇 (category=magitech, rarity=3): `max_stack_size = floor(50 × 0.5) = 25`
- 秘银 (category=rare, rarity=4): `max_stack_size = floor(20 × 0.3) = 6` → **manual override to 10**

> **Override Rule**: When formula result is below category minimum (e.g., rare_material should never stack below 10), apply manual override with documented rationale.

---

### Drop Rate Modifier Formula

掉落概率计算（用于资源掉落系统）：

```
actual_drop_rate = base_drop_rate × drop_weight × rarity_drop_modifier
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `base_drop_rate` | BDR | float | 0.0-1.0 | Base drop rate from BlockType/Container |
| `drop_weight` | DW | float | 0.0-10.0 | Resource-specific drop weight modifier |
| `rarity_drop_modifier` | RDM | float | 0.03-1.0 | Rarity-dependent drop modifier |

**Rarity Drop Modifier Values:**

| Rarity | RDM Value |
|--------|-----------|
| 1 (common) | 1.0 |
| 2 (uncommon) | 0.6 |
| 3 (rare) | 0.3 |
| 4 (epic) | 0.1 |
| 5 (legendary) | 0.03 |

**Output Range:** 0.0-1.0 (clamped)

**Example:**
- 铁矿从iron_ore方块掉落 (BDR=1.0, DW=1.0, RDM=1.0): `actual_drop_rate = 1.0 × 1.0 × 1.0 = 100%`
- 秘银从mithril_ore方块掉落 (BDR=1.0, DW=1.0, RDM=0.1): `actual_drop_rate = 1.0 × 1.0 × 0.1 = 10%`

---

### Value Calculation Reference

`base_value` 无固定公式，遵循稀有度基准参考值：

**Rarity Value Ranges:**

| Rarity | Base Value Range |
|--------|-----------------|
| 1 | 1-10 |
| 2 | 10-30 |
| 3 | 30-100 |
| 4 | 100-300 |
| 5 | 300-999 |

**Value Assignment Rule**: 
- 低稀有度资源价值较低（鼓励收集，Pillar 2驱动）
- 高稀有度资源价值较高（稀缺性驱动，增加撤退决策压力）
- 消耗品价值低于同级材料（功能性而非收藏性）

---

### Query Behavior Rules

**Invalid resource_id handling:**

```
get_resource_definition(resource_id):
    if resource_id == 0:
        return NULL_RESOURCE_DEFINITION
    if resource_id not in registered_resources:
        return null (warning logged)
    return Dictionary with all fields
```

**Default value returns for invalid queries:**

| Method | Invalid ID Return |
|--------|-------------------|
| `get_resource_definition()` | null |
| `get_resource_name()` | "" (empty string) |
| `get_display_name()` | "" |
| `get_category()` | 0 (basic_material) |
| `get_rarity()` | 1 (common) |
| `get_max_stack_size()` | 1 (minimum) |
| `get_base_value()` | 0 |
| `is_buildable()` | false |
| `is_craftable()` | false |
| `is_consumable()` | false |

## Edge Cases

### 1. Invalid Resource ID Query

**If resource_id is invalid (not in database):**
- Return `null` for `get_resource_definition()`
- Return empty string `""` for name queries
- Return default values (category=0, rarity=1, stack_size=1, value=0) for property queries
- Log warning: "Invalid resource_id: [id] (not found in registry)"
- No exception thrown — downstream systems must handle null gracefully

### 2. Resource ID = 0 (Null Resource)

**If resource_id = 0:**
- Return `NULL_RESOURCE_DEFINITION` (predefined error fallback)
- `name` = "null_resource", `display_name` = "无效资源"
- Used when drop system cannot resolve resource_type_id
- Not a valid resource for inventory or building

### 3. Negative or Out-of-Range Resource ID

**If resource_id < 0:**
- Return null, log warning: "Invalid resource_id: [id] (negative)"
- Treat as invalid query

**If resource_id > 65535:**
- Return null, log warning: "Invalid resource_id: [id] (exceeds 16-bit range)"
- Treat as invalid query

### 4. PLANNED State Resource Query

**If resource exists in registry but marked `status: PLANNED`:**
- Return null, log warning: "resource_id [id] is in PLANNED state (not yet implemented)"
- ID is reserved but ResourceDefinition not created
- Downstream systems treat as invalid (no resource available)

### 5. Deprecated Resource in Existing Saves

**If save file contains deprecated resource_id:**
- Database returns valid definition (deprecated resources remain queryable)
- Resource functions normally in inventory and building
- Build menu and new content do not offer deprecated resources
- UI may show optional deprecated warning (UX decision)

### 6. Stack Size Below Formula Minimum

**If formula calculation produces stack_size < 1:**
- Apply minimum floor: `max_stack_size = max(floor(formula_result), 1)`
- Log debug: "Stack size formula result [value] floored to minimum 1"

**If formula calculation produces stack_size < category_minimum:**
- Apply manual override with documented rationale
- Example: rare_material minimum = 10, even if formula = 6

### 7. Base Value = 0 for Non-Special Resource

**If base_value = 0 AND category != special:**
- Log warning at resource registration: "Resource [id] has base_value=0 but category != special (no economic value)"
- Valid configuration but unusual — may indicate placeholder
- Does not block resource from functioning

### 8. All Usage Flags = 0

**If is_build_material=0, is_craft_material=0, is_consumable=0:**
- Log warning at registration: "Resource [id] has no usage flags — cannot be used in any system"
- Special/收藏类资源例外
- 其他类型应至少有一个用途标识

### 9. Drop Weight = 0 with Active Status

**If drop_weight = 0 AND status = ACTIVE:**
- Resource will never drop from any container/block
- Valid configuration (资源仅通过其他途径获取，如任务奖励)
- Log debug: "Resource [id] has drop_weight=0 — no natural drops"

### 10. Tech Unlock Required References Non-Existent Tech

**If tech_unlock_required > 0 AND tech_id not in TechDatabase:**
- Return definition normally (no validation at registration time)
- Tech Unlock System handles missing tech at runtime
- Log warning when tech check fails: "Tech unlock ID [tech_id] not found"

### 11. Cross-System ID Conflict (BlockTypeDatabase Reference)

**If BlockTypeDatabase references resource_type_id that doesn't exist:**
- Resource Drop System logs error: "Resource ID [id] not found in ResourceDatabase"
- No drop spawned (empty result)
- BlockTypeDatabase is source of truth for IDs — ResourceDatabase must define all referenced IDs

### 12. Localization Key Missing

**If LocalizationManager returns null for display_name key:**
- Return internal `name` field as fallback display
- Log warning: "Localization key '[name]' not found, using internal name"
- UI shows internal name (e.g., "iron" instead of "铁矿")

## Dependencies

### Upstream Dependencies (无)

资源数据库是Foundation层系统，无上游依赖。数据定义独立于其他系统。

---

### Downstream Dependencies

以下系统依赖资源数据库的数据定义：

| System | Priority | Layer | Data Consumed | Query Methods | Dependency Type |
|--------|----------|-------|---------------|---------------|-----------------|
| **玩家背包系统** | Vertical Slice | Feature | max_stack_size, display_name | `get_stack_info()` | **Blocking** — Backpack cannot function without stack limits |
| **战车仓库系统** | Vertical Slice | Feature | max_stack_size, base_value | `get_value_info()` | **Blocking** — Warehouse value calc requires base_value |
| **资源掉落系统** | MVP | Core | resource_id validation | `is_valid_resource()` | **Blocking** — Drop system validates IDs before spawning |
| **资源合成系统** | Vertical Slice | Feature | is_craft_material, base_value | `get_craft_materials()` | **Blocking** — Crafting recipes require material definitions |
| **科技解锁系统** | Vertical Slice | Feature | rarity | `get_rarity()` | **Blocking** — Tech unlock thresholds use rarity |
| **建造物品数据库** | MVP | Feature | is_build_material, base_value | `get_build_materials()` | **Blocking** — Build recipes require material definitions |
| **炮塔系统** | MVP | Core | base_value | `get_base_value()` | **Blocking** — Turret costs require value calculation |
| **陷阱系统** | Vertical Slice | Feature | base_value | `get_base_value()` | **Non-blocking** — Extension content |
| **HUD系统** | Full Vision | Presentation | display_name, rarity | `get_tooltip_info()` | **Non-blocking** — UI queries for display |
| **存档系统** | Full Vision | Polish | resource_id serialization | Indirect | **Non-blocking** — Save stores IDs, not definitions |

---

### Dependency Interface Contract

#### Data Contract

| Interface | Return Type | Failure Mode | Consumer Contract |
|-----------|-------------|--------------|-------------------|
| `get_resource_definition(resource_id)` | Dictionary or null | Return null for invalid ID | Consumer must handle null |
| `get_max_stack_size(resource_id)` | int | Return 1 for invalid ID | Consumer uses for stack limit |
| `get_base_value(resource_id)` | int | Return 0 for invalid ID | Consumer uses for cost calc |
| `is_valid_resource(resource_id)` | bool | Return false for invalid | Consumer validates before use |

#### Timing Contract

| Constraint | Requirement |
|------------|-------------|
| Query latency | Immediate return — no async |
| Initialization order | Resources must load before Backpack/Warehouse/Drop systems |
| Thread safety | Read-only queries are thread-safe (database immutable after load) |

---

### Critical Dependency Path (MVP)

```
ResourceDatabase → 资源掉落系统 → 玩家背包系统 → 搜刮交互系统
ResourceDatabase → 建造物品数据库 → 方块放置系统 → 地堡设施系统
ResourceDatabase → 炮塔系统 → 尸潮防守
```

---

### Cross-System ID Alignment

**BlockTypeDatabase → ResourceDatabase alignment required:**

| BlockType ID | Block Name | resource_type_id | Resource Name |
|--------------|------------|------------------|---------------|
| 500 | iron_ore | 101 | 铁矿 |
| 510 | copper_ore | 102 | 铜矿 |
| 520 | coal_deposit | 103 | 煤矿 |
| 600 | crystal_shard | 201 | 魔力晶石碎片 |
| 610 | crystal_cluster | 202 | 魔力晶石簇 |
| 800 | gold_ore | 203 | 金矿 |
| 700 | mithril_ore | 301 | 秘银 |
| 710 | ancient_mithril | 302 | 古代秘银 |

> **Constraint**: All resource_type_ids referenced in block-type-database.md MUST be defined in ResourceDatabase. Run `/consistency-check` after both GDDs complete.

## Tuning Knobs

### Primary Tuning Knobs (影响核心玩法)

| Knob | Current Value | Safe Range | Gameplay Effect | Pillar Affected |
|------|---------------|------------|-----------------|-----------------|
| **基础堆叠上限 (Category base stacks)** | basic=100, magitech=50, rare=20 | 10-200 | 背包容量上限。提高堆叠 → 减少背包管理负担 → 搜打撤压力降低 | Pillar 2: 搜打撤节奏 |
| **稀有度堆叠修正 (Rarity stack modifiers)** | 1.0→0.8→0.5→0.3→0.1 | 0.05-1.0 | 稀有资源堆叠更少 → 背包空间竞争加剧 → 撤退决策压力增加 | Pillar 2: 搜打撤节奏 |
| **基础价值范围 (Base value ranges)** | rarity1:1-10, rarity5:300-999 | ×2 multiplier per rarity tier | 合成成本/建造成本基准。提高价值 → 高级建造更昂贵 → 策略选择增加 | All pillars (economy) |
| **掉落率修正 (Rarity drop modifiers)** | 100%→60%→30%→10%→3% | 50%-1% for epic/legendary | 稀有资源掉落概率。降低修正 → 稀有资源更稀缺 → 探索回报波动增大 | Pillar 2: 搜打撤节奏 |

---

### Secondary Tuning Knobs (影响次要体验)

| Knob | Current Value | Safe Range | Gameplay Effect |
|------|---------------|------------|-----------------|
| **单资源掉落权重 (Per-resource drop_weight)** | Default 1.0 for all | 0.0-10.0 | 特定资源掉落概率微调。coal=2.0 → 煤矿更容易获取 |
| **堆叠最小值override (Stack minimum overrides)** | rare_material minimum=10 | 1-50 | 防止公式计算产生过低堆叠。override需记录理由 |
| **科技解锁ID关联 (tech_unlock_required)** | 0 for MVP (默认解锁) | 0-65535 | 资源解锁门槛。设置tech_id → 资源需科技解锁才可使用 |

---

### Economy Tuning Knobs (资源产出平衡)

| Knob | Resource | Current Value | Safe Range | Effect |
|------|----------|---------------|------------|--------|
| **铁矿价值** | iron (101) | 5 | 1-20 | 基础建造成本基准 |
| **秘银价值** | mithril (301) | 120 | 50-300 | 高级建造成本基准 |
| **古代秘银价值** | ancient_mithril (302) | 300 | 100-999 | 最高级建造成本基准 |
| **魔力晶石碎片价值** | crystal_shard (201) | 15 | 5-50 | 魔导合成成本基准 |
| **魔力晶石簇价值** | crystal_cluster (202) | 50 | 20-150 | 高级魔导合成成本 |

---

### Tuning Implementation

| Parameter Type | Storage Location | Edit Method |
|----------------|------------------|-------------|
| **Category base stacks** | Formulas section constants | Edit GDD → update formula → recalculate affected resources |
| **Rarity modifiers** | Formulas section constants | Edit GDD → update formula → recalculate affected resources |
| **Per-resource base_value** | ResourceDefinition files | Edit .tres files in Godot editor |
| **Per-resource drop_weight** | ResourceDefinition files | Edit .tres files in Godot editor |
| **Per-resource max_stack_size** | ResourceDefinition files | Edit .tres files (formula-derived or override) |

---

### Knobs That Should NOT Be Tuned

| Knob | Reason |
|------|--------|
| **resource_id allocation ranges** | ID分配是架构决策，改变会破坏跨系统引用一致性 |
| **Locked resource IDs (101-302)** | 已被BlockTypeDatabase引用，更改需同步修改两个系统 |
| **Category enumeration (0-4)** | 分类枚举是系统约定，添加新分类需更新所有依赖系统 |

## Visual/Audio Requirements

资源数据库是纯数据系统，不直接产生视觉或音频输出。视觉和音频需求由下游消费系统（HUD tooltip、背包UI、掉落实体渲染）实现。以下列出数据库需要提供的视觉/音频数据映射。

### Visual Data Provided by ResourceDatabase

| Data | Type | Consumer System | Visual Effect |
|------|------|-----------------|---------------|
| **icon_path** | Resource path | 背包UI、HUD tooltip、掉落实体 | 确定资源图标显示。每个resource指向对应图标纹理。 |
| **rarity** | int (1-5) | 背包UI、HUD tooltip | 确定稀有度边框颜色和高亮效果（白→绿→蓝→紫→金） |
| **display_name** | Localized string | HUD tooltip | 确定资源名称显示 |

### Icon Asset Requirements

| Resource Category | Icon Size | Icon Count (MVP) | Asset Path |
|------------------|-----------|------------------|------------|
| **Basic Materials** | 32×32 px | 5 icons | `assets/textures/icons/resources/basic/` |
| **Magitech Materials** | 32×32 px | 3 icons | `assets/textures/icons/resources/magitech/` |
| **Rare Materials** | 32×32 px | 2 icons | `assets/textures/icons/resources/rare/` |
| **Consumables** | 32×32 px | 2 icons | `assets/textures/icons/resources/consumable/` |

**Total MVP Icons**: 12 (matching Initial Resource Catalog)

### Rarity Visual Style

| Rarity | Border Color | Glow Effect | Background Tint |
|--------|--------------|-------------|-----------------|
| 1 (common) | 白色/灰色 #CCCCCC | 无 | 无 |
| 2 (uncommon) | 绿色 #00FF00 | 轻微脉冲 | 无 |
| 3 (rare) | 蓝色 #0088FF | 中等发光 | 无 |
| 4 (epic) | 紫色 #AA00FF | 强发光+动态 | 淡紫底 |
| 5 (legendary) | 金色 #FFD700 | 最高发光+特效 | 金色边框 |

### Audio Data Provided by ResourceDatabase

数据库不存储音频文件。音频反馈由下游系统根据resource category动态选择：

| Audio Event | Consumer System | Data Used | Audio Selection |
|-------------|-----------------|-----------|-----------------|
| **拾取音效** | 背包系统 | category, rarity | basic材料 → 轻拾取声；rare材料 → 重拾取声+高亮音效 |
| **掉落生成音效** | 资源掉落系统 | category | 普通掉落 → 轻落地声；稀有掉落 → 特殊落地声 |
| **使用消耗品音效** | 消耗品系统 | category | 食物 → 进食声；药剂 → 魔法效果声 |

## UI Requirements

### UI Data Provided by ResourceDatabase

| UI Element | Data Source | Display Context |
|------------|-------------|-----------------|
| **Tooltip标题** | `get_display_name(resource_id)` | 悬停/瞄准资源时显示 |
| **Tooltip稀有度** | `get_rarity(resource_id)` | 星级显示（1-5星） |
| **Tooltip分类** | `get_category_name(resource_id)` | 分类标签显示 |
| **Tooltip描述** | `description` (localized key) | 详细说明文本 |
| **背包图标** | `icon_path` | 背包格位显示 |

### Tooltip Layout

```
┌─────────────────────┐
│ 铁矿            ★☆☆☆│
│ ─────────────────── │
│ 分类: 基础材料       │
│ 稀有度: 普通        │
│ 堆叠上限: 100       │
│ 价值: 5             │
└─────────────────────┘
```

### Backpack Slot Layout

```
┌──────┐
│ [图标] │ ← icon_path
│  35   │ ← current count
└──────┘
     ↑
   边框颜色由rarity决定
```

## Acceptance Criteria

### Data Integrity Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-001** | 所有Locked IDs定义完整 | 验证resource_id 101-103, 201-203, 301-302存在于registry | 所有8个locked IDs有完整ResourceDefinition |
| **AC-002** | Resource ID无重复 | 检查registry resource_id唯一性 | 每个resource_id唯一，无冲突 |
| **AC-003** | ID分配符合allocation scheme | 验证每个resource ID在正确category range | basic在100-199, magitech在200-299, rare在300-399 |
| **AC-004** | Category值有效 | 检查所有resource category值 | 所有category在0-4范围 |
| **AC-005** | Rarity值有效 | 检查所有resource rarity值 | 所有rarity在1-5范围 |
| **AC-006** | Stack size值有效 | 检查所有resource max_stack_size | 所有stack_size在1-999范围 |
| **AC-007** | Base value值有效 | 检查所有resource base_value | 所有base_value在0-9999范围 |

### Query API Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-008** | Valid ID查询返回正确数据 | `get_resource_definition(101)` | 返回Dictionary包含正确name="iron", rarity=1, max_stack_size=100 |
| **AC-009** | Invalid ID查询返回null | `get_resource_definition(999)` (不存在) | 返回null，无exception |
| **AC-010** | ID=0返回NULL_RESOURCE | `get_resource_definition(0)` | 返回预定义NULL_RESOURCE_DEFINITION |
| **AC-011** | Category查询正确 | `get_resources_by_category("basic_material")` | 返回ID 101, 102, 103, 110, 120 |
| **AC-012** | Build materials查询正确 | `get_build_materials()` | 返回所有is_build_material=1的resource列表 |
| **AC-013** | Stack info query正确 | `get_stack_info(101)` | 返回{"max_stack_size":100, "display_name":"铁矿", "category":0} |
| **AC-014** | Tooltip info query正确 | `get_tooltip_info(301)` | 返回display_name, rarity=4, category_name="rare_material" |

### Cross-System Integration Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-015** | BlockType引用的resource_id全部存在 | 验证block-type-database.md引用的101-302全部定义 | 所有8个resource_type_ids在ResourceDatabase中有匹配定义 |
| **AC-016** | 资源掉落系统可验证resource_id | 调用`is_valid_resource(101)` | 返回true |
| **AC-017** | 建造系统可获取build_materials | 调用`get_build_materials()` | 返回包含iron, stone, wood, mithril的列表 |

### MVP Resource Catalog Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-018** | Basic materials定义完整 | 检查ID range 100-199 | 至少5个basic_material定义（iron, copper, coal, stone, wood） |
| **AC-019** | Magitech materials定义完整 | 检查ID range 200-299 | 至少3个magitech_material定义（crystal_shard, crystal_cluster, gold） |
| **AC-020** | Rare materials定义完整 | 检查ID range 300-399 | 至少2个rare_material定义（mithril, ancient_mithril） |
| **AC-021** | Consumables定义完整 | 检查ID range 400-499 | 至少2个consumable定义（food_basic, fuel_basic） |

### Edge Case Handling Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-022** | Negative ID返回null | `get_resource_definition(-1)` | 返回null，无crash |
| **AC-023** | ID超过65535返回null | `get_resource_definition(70000)` | 返回null，无crash |
| **AC-024** | Default values for invalid queries | `get_rarity(999)` | 返回1（default rarity），不抛异常 |
| **AC-025** | PLANNED resource返回null | `get_resource_definition(600)` (PLANNED state) | 返回null，log warning |

### Performance Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-026** | 查询延迟足够低 | 循环`get_resource_definition()` 1000次，测量平均耗时 | 平均耗时 < 0.1ms |
| **AC-027** | Registry加载时间可接受 | 测量Resources autoload初始化耗时 | 加载时间 < 300ms |
| **AC-028** | 内存占用合理 | 测量ResourceDatabase singleton内存占用 | 内存占用 < 500KB |

### Documentation Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-029** | GDD所有8个section完整 | 检查resource-database.md | Overview, Player Fantasy, Detailed Design, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria全部有内容 |
| **AC-030** | Systems-index更新状态 | 检查systems-index.md | 资源数据库status="Designed" |

### Pass/Fail Threshold

| Category | Pass Count | Fail Action |
|----------|------------|-------------|
| **Data Integrity (AC-001 to AC-007)** | 必须100%通过 | 任一失败 → 资源定义错误，必须修复 |
| **Query API (AC-008 to AC-014)** | 必须100%通过 | 任一失败 → API实现错误，必须修复 |
| **Cross-System (AC-015 to AC-017)** | 必须100%通过 | 任一失败 → 跨系统契约违反，必须修复 |
| **MVP Catalog (AC-018 to AC-021)** | 必须100%通过 | 任一失败 → 内容不足，必须补充 |
| **Edge Cases (AC-022 to AC-025)** | 必须100%通过 | 任一失败 → 边界处理缺失，必须补充 |
| **Performance (AC-026 to AC-028)** | 必须通过 | 任一失败 → 性能优化，但可进入实现阶段 |
| **Documentation (AC-029 to AC-030)** | 必须100%通过 | 任一失败 → 文档不完整 |

**Total Criteria**: 30
**Required for Implementation**: 100% pass on all blocking categories

## Open Questions

以下问题在GDD设计阶段未能完全解决，需要在实现前或实现过程中澄清。

### High Priority (Implementation Blocking)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-001** | ResourceDefinition资源文件格式是否确认？当前设计假设使用Godot .tres文件存储单个资源定义，但需验证Godot 4.6 Resource系统对此的支持。 | 技术总监 | ResourceDatabase实现前 | 影响资源数据存储架构和加载方式 |
| **Q-002** | LocalizationManager是否已存在？display_name依赖LocalizationManager进行本地化查找。如果系统未实现，需确定回退方案。 | UX设计者 | HUD系统实现前 | 影响UI显示和资源名称本地化 |
| **Q-003** | 资源掉落系统是否已确认掉落生成逻辑？ResourceDatabase定义drop_weight和rarity_drop_modifier，但掉落系统的实际调用时机需确认。 | 资源掉落系统GDD设计者 | 资源掉落系统实现前 | 无法验证掉落率修正是否产生正确的稀有度分布 |

### Medium Priority (Design Clarification)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-004** | 是否需要支持动态添加资源（mod/expansion支持）？当前设计假设静态资源定义，但未来可能需要动态注册。 | 技术总监+制作人 | Alpha里程碑前 | 影响ID allocation scheme扩展策略 |
| **Q-005** | 是否需要资源合成失败机制？当前设计假设合成成功，但可能有合成失败概率（消耗材料但失败）。 | 游戏设计者 | 资源合成系统设计前 | 影响合成成本计算和风险机制 |
| **Q-006** | 资源图标是否需要稀有度变体？当前假设单一图标，但可能需要破损/修复状态变体。 | 艺术总监 | 资产管线实现前 | 影响图标资产数量 |

### Low Priority (Future Consideration)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-007** | 是否需要资源交易系统（NPC/商人）？base_value当前仅用于合成和建造，但可能有交易系统。 | 游戏设计者 | Beta阶段 | 不影响MVP实现 |
| **Q-008** | 是否需要资源描述文本用于UI？当前description仅用于内部文档，但可能需要UI显示。 | UX设计者 | Beta阶段（UI完善） | 不影响MVP实现 |

### Resolution Tracking

| ID | Status | Resolution Date | Resolved By | Summary |
|----|--------|-----------------|-------------|---------|
| Q-001 | Open | — | — | Pending 技术总监确认 |
| Q-002 | Open | — | — | Pending LocalizationManager实现 |
| Q-003 | Open | — | — | Pending 资源掉落系统GDD |
| Q-004 | Open | — | — | Pending 技术总监决策 |
| Q-005 | Open | — | — | Pending 游戏设计者决策 |
| Q-006 | Open | — | — | Pending 艺术总监决策 |
| Q-007 | Open | — | — | Pending 游戏设计者决策 |
| Q-008 | Open | — | — | Pending UX设计者决策 |