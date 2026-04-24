# 建造物品数据库

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-22
> **Last Verified**: 2026-04-22
> **Implements Pillar**: Pillar 3 (尸潮即高潮), Pillar 4 (魔导科技美学)
> **Priority**: MVP | **Layer**: Foundation
> **System ID**: #5 (from systems-index.md)

## Summary

建造物品数据库是存储所有可建造物品配方定义的中央数据层。每个建造物品包含唯一标识符（独立于tile_type_id）、分类、材料消耗配方、建造时间、输出方块映射。提供建造验证、放置条件检查、材料成本计算等接口，服务于方块放置系统、炮塔系统、地堡设施系统。MVP阶段定义12个建造物品覆盖墙体、炮塔、陷阱、设施、地板五大分类。

## Overview

建造物品数据库是存储所有可建造物品配方定义的中央数据层。每个建造物品包含唯一标识符、物品分类（墙体/炮塔/陷阱/设施）、材料成本配方、建造时间、产出方块类型映射。该数据库为方块放置系统、建造验证系统、炮塔系统、地堡设施系统提供统一的建造配方接口，确保所有下游系统引用同一份成本定义。

作为Foundation层系统，该数据库直接影响玩家对**资源预算决策**的感知：不同建造物品的材料成本创造经济权衡——"建造加固墙还是基础炮塔？"的决策贯穿整个防守规划过程。这服务于Pillar 3（尸潮即高潮）——建造成本必须让玩家感受到资源有限的紧张感；以及Pillar 4（魔导科技美学）——建造物品命名和分类必须符合魔导科技世界观（符文炮塔而非电子炮塔）。

**设计决策**：
- 使用Dictionary结构存储建造物品定义（key = build_item_id, value = Dictionary of attributes）
- 采用Autoload singleton模式（extends Node），与BlockTypeDatabase、ResourceDatabase、EnemyTypeDatabase保持一致架构
- 提供`get_build_recipe(build_item_id: int)`查询接口供下游系统调用
- **关键区分**：BlockTypeDatabase定义方块属性（硬度、碰撞），本数据库定义建造配方（材料成本、建造时间）

## Player Fantasy

玩家在防守规划过程中面对的核心体验是**稀缺性下的战略权衡**——每一次建造决策都是对有限资源的承诺，"这个值得吗？"的紧张感贯穿整个规划过程。

- **资源预算压力**：每次建造前查看材料成本时，玩家感受到的是"搜刮三小时换来的铁矿该花在哪里？"的重量感。材料不是数字，是**努力和时间的具象化**
- **成本决策紧张感**：当12铁矿、3晶石、4分钟倒计时摆在面前，玩家必须快速计算——加固墙（8铁、90秒）vs基础炮塔（6铁、2晶石、120秒）的选择不是简单的对比，是对即将到来的尸潮做出的**预判性赌注**
- **事后验证反馈**：尸潮过后，玩家回看建造成果——"那堵墙撑住了，但炮塔没来得及建完"或"陷阱消耗太多晶石，下一波没钱升级装甲"。每一次事后反思都是对下一次预算规划的教训

**锚定时刻**：防守倒计时4分钟，玩家在建造菜单中查看配方：reinforced_wall需要8铁矿（库存12）和90秒建造时间；basic_turret需要6铁矿+2晶石（库存3）和120秒。玩家盯着屏幕，大脑快速计算——"晶石不够建炮塔，但墙建完只剩4铁矿...下一波还需要升级战车装甲...我该赌在墙还是分散资源？"——这种**计算紧张感**就是建造物品数据库创造的玩家体验。

**服务于支柱**：
- Pillar 3 (尸潮即高潮)：建造成本让每次放置都有真实代价，防守不再是"能建多少建多少"，而是"有限资源如何最大化防守效果"
- Pillar 4 (魔导科技美学)：建造物品命名和分类体现魔导科技世界观——"符文炮塔"而非"机枪塔"，"魔力屏障墙"而非"激光墙"，阵营科技分支体现在配方解锁路径

## Detailed Design

### Core Rules

#### 1. Build Item Data Structure

每个建造物品定义为一个独立的数据记录，存储在BuildItemDatabase资源文件中。所有建造物品共享统一的数据结构。

**Primary Build Item Fields:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `build_item_id` | int | 0-65535 | — | 唯一标识符，系统内部引用键（与tile_type_id完全独立） |
| `name` | string | — | — | 内部标识名（如"wall_basic", "turret_rune"），用于代码引用和本地化键 |
| `display_name` | string | — | — | UI显示名称（本地化键，实际显示由LocalizationManager处理） |
| `category` | int | 0-3 | — | 建造物品分类枚举值（见Category System） |
| `output_tile_id` | int | 0-65535 | — | 建造完成后在TileMap中放置的方块类型ID，引用BlockTypeDatabase |
| `build_time_seconds` | float | 0.5-300.0 | 5.0 | 建造所需时间（秒），影响建造进度条和防守规划节奏 |
| `material_costs` | Array[MaterialCost] | — | — | 材料消耗配方数组（见Material Cost Structure） |
| `tech_unlock_required` | int | 0-65535 | 0 | 解锁所需科技ID（0=默认解锁，MVP阶段所有物品默认解锁） |
| `placement_requirements` | PlacementReq | — | {} | 放置条件约束（见Placement Requirements Structure） |

**Extended Build Item Fields:**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `icon_path` | string | — | — | Godot资源路径指向建造物品图标 |
| `description` | string | — | "" | 内部文档说明 |
| `build_preview_tile_id` | int | 0-65535 | output_tile_id | 建造预览时显示的临时方块ID（默认与output相同） |
| `max_per_bunker` | int | 0-999 | 0 | 每个地堡允许的最大数量（0=无限制） |

**Field Validation Rules:**

1. `build_item_id`必须唯一，不允许重复ID
2. `build_item_id = 0`保留为"空建造物品"错误回退
3. `name`必须为有效的snake_case标识符（仅字母、数字、下划线）
4. `category`必须在枚举范围0-3内
5. `output_tile_id`必须引用BlockTypeDatabase中存在的有效tile_type_id
6. `output_tile_id`引用的tile必须满足`buildability = 1`（可建造）
7. `build_time_seconds`必须为正数（>= 0.5秒，防止瞬时建造）
8. `material_costs`数组不能为空（至少一个材料消耗）
9. `material_costs`中每个resource_id必须引用ResourceDatabase中`is_build_material = 1`的资源

---

#### 2. Build Item ID Allocation Scheme

建造物品ID使用独立的分配方案，**与BlockTypeDatabase的tile_type_id完全分离**。这确保配方系统和方块属性系统可以独立演化，避免ID冲突和耦合。

**ID Range Allocation:**

| ID Range | Category | Description |
|----------|----------|-------------|
| 0 | — | `null_build_item` — 保留为错误回退 |
| 1-99 | — | 系统内部/测试建造物品 |
| 100-199 | `wall` | 墙体建造物品（基础墙、石墙、加固墙、符文墙、秘银墙） |
| 200-299 | `turret` | 炮塔建造物品（基础炮塔、符文炮塔、火力炮塔、魔力炮塔） |
| 300-399 | `trap` | 陷阱建造物品（尖刺陷阱、火焰陷阱、魔力陷阱） |
| 400-499 | `facility` | 设施建造物品（储物箱、工作台、魔力发电机、雨水收集器） |
| 500-599 | `floor` | 地板/平台建造物品（基础地板、木质平台、金属平台） |
| 600-699 | `gate` | 闸门建造物品（基础闸门、加固闸门、魔力屏障门） |
| 700-999 | — | MVP阶段预留扩展空间 |
| 1000-65535 | — | 未来内容（Vertical Slice及以后） |

**ID Allocation Rules:**

1. 建造物品ID独立于tile_type_id，不与其重叠或冲突
2. 每个category预留100个ID槽位，确保可扩展性
3. 新建造物品必须使用category范围内的下一个可用ID
4. ID不可重新分配 — 废弃ID标记`status: deprecated`
5. `build_item_id`与`output_tile_id`是**映射关系**，不是相等关系

**关键设计决策**：
- 墙体建造物品ID 100-199 → 映射到BlockTypeDatabase墙体tile ID 1000-1499
- 炮塔建造物品ID 200-299 → 映射到BlockTypeDatabase炮塔基座tile ID 2500-2599
- 设施建造物品ID 400-499 → 映射到BlockTypeDatabase设施tile ID 2000-2499

> **Why separate IDs?** 建造配方可能产生多个输出（如炮塔包含基座tile + 炮塔实体），一个tile可能对应多个建造配方（不同材料等级），ID分离支持这些复杂映射而不产生耦合。

---

#### 3. Build Item Category System

**Category Enumeration:**

| Value | Name | Description | MVP Item Count |
|-------|------|-------------|----------------|
| 0 | `wall` | 墙体结构（防御屏障，阻挡敌人路径） | 5 |
| 1 | `turret` | 炮塔（自动攻击敌人，需要弹药/魔力供给） | 2 |
| 2 | `trap` | 陷阱（触发式伤害，消耗性使用） | 1 |
| 3 | `facility` | 设施（功能性建筑，生产/存储/发电） | 2 |
| 4 | `floor` | 地板/平台（通行结构，无碰撞或平台碰撞） | 2 |
| 5 | `gate` | 闸门（可控通道，开关机制） | 0 (Alpha) |

**Category Behavior Rules:**

| Category | Collision Provided | Layer Allowed | Placement Requirements | Build Priority |
|----------|-------------------|---------------|----------------------|----------------|
| `wall` | Full (collision_shape=1) | Layer 2 | `requires_adjacent_floor` | 防守第一优先级 |
| `turret` | Full (collision_shape=1) | Layer 2 | `requires_adjacent_wall` OR `requires_floor` | 防守第二优先级 |
| `trap` | None (collision_shape=0) | Layer 2 | `requires_floor` | 防守辅助 |
| `facility` | Full (collision_shape=1) | Layer 2 | `requires_floor` | 功能优先级 |
| `floor` | Full or Platform | Layer 2, 3 | `requires_support_below` | 基础优先级 |

---

#### 4. Material Cost Structure

材料消耗定义为数组结构，每个元素包含资源ID和数量。

**MaterialCost Data Structure:**

```gdscript
# MaterialCost structure (stored in material_costs array)
class MaterialCost:
    var resource_id: int      # ResourceDatabase ID (must have is_build_material = 1)
    var quantity: int         # Quantity required (1-999)
```

**Material Cost Rules:**

1. `material_costs`数组长度限制为1-5（最多5种材料消耗）
2. `resource_id`必须引用ResourceDatabase中`is_build_material = 1`的资源
3. `quantity`必须在范围1-999内（单材料消耗不超过999）
4. 相同`resource_id`不允许在数组中出现多次（合并为单一条目）
5. 材料消耗总数必须大于0（建造必须有代价）

**MVP Material Cost Examples:**

| Build Item | Material Costs | Total Resource Units |
|------------|----------------|----------------------|
| wall_basic (100) | [{101, 3}, {110, 2}] | 3 iron + 2 stone |
| wall_stone (110) | [{110, 8}] | 8 stone |
| wall_reinforced (120) | [{101, 6}, {110, 4}, {103, 2}] | 6 iron + 4 stone + 2 coal |
| wall_rune (130) | [{101, 4}, {201, 3}] | 4 iron + 3 crystal_shard |
| wall_mithril (140) | [{301, 4}, {201, 2}] | 4 mithril + 2 crystal_shard |
| turret_basic (200) | [{101, 6}, {110, 4}, {201, 2}] | 6 iron + 4 stone + 2 crystal_shard |
| turret_rune (210) | [{101, 4}, {201, 5}, {202, 1}] | 4 iron + 5 crystal_shard + 1 crystal_cluster |
| trap_spikes (300) | [{101, 3}, {110, 2}] | 3 iron + 2 stone |
| facility_storage (400) | [{101, 4}, {120, 6}] | 4 iron + 6 wood |
| facility_workbench (410) | [{101, 2}, {120, 4}, {110, 2}] | 2 iron + 4 wood + 2 stone |
| floor_basic (500) | [{110, 3}] | 3 stone |
| platform_wooden (510) | [{120, 4}] | 4 wood |

**Cost Balancing Principles (Pillar 3 Support):**

| Wall Tier | Iron Cost | Crystal Cost | Mithril Cost | Total Value | Build Time |
|-----------|-----------|--------------|--------------|-------------|------------|
| Basic | 3 | 0 | 0 | ~17 | 5 sec |
| Stone | 0 | 0 | 0 | ~8 | 8 sec |
| Reinforced | 6 | 0 | 0 | ~42 | 15 sec |
| Rune | 4 | 3 | 0 | ~65 | 20 sec |
| Mithril | 0 | 2 | 4 | ~510 | 30 sec |

> **Design Test**: 墙体成本必须让玩家在"建造多堵基础墙 vs 一堵高级墙"之间产生有意义的选择。如果秘银墙成本过高（如需要10秘银），玩家会放弃升级；如果过低，升级决策失去紧张感。

---

#### 5. Recipe-to-Tile Mapping Rules

建造物品ID与输出方块ID之间存在映射关系，而非相等关系。

**Mapping Table (MVP):**

| Build Item ID | Build Item Name | Category | Output Tile ID | Tile Name | Output Tile Properties |
|---------------|-----------------|----------|----------------|-----------|------------------------|
| 100 | `wall_basic` | wall | 1000 | `wall_basic` | hardness=40, collision=1 |
| 110 | `wall_stone` | wall | 1010 | `wall_stone` | hardness=70, collision=1 |
| 120 | `wall_reinforced` | wall | 1020 | `wall_reinforced` | hardness=100, collision=1 |
| 130 | `wall_rune` | wall | 1030 | `wall_rune` | hardness=140, collision=1 |
| 140 | `wall_mithril` | wall | 1040 | `wall_mithril` | hardness=200, collision=1 |
| 200 | `turret_basic` | turret | 2500 | `turret_base` | hardness=85, collision=1 |
| 210 | `turret_rune` | turret | 2501 | `turret_base_rune` | hardness=120, collision=1 (new tile) |
| 300 | `trap_spikes` | trap | 2502 | `trap_spikes_tile` | hardness=30, collision=0 (new tile) |
| 400 | `facility_storage` | facility | 2000 | `facility_storage_basic` | hardness=50, collision=1 |
| 410 | `facility_workbench` | facility | 2001 | `facility_workbench` | hardness=40, collision=1 (new tile) |
| 500 | `floor_basic` | floor | 1500 | `floor_basic` | hardness=25, collision=1 |
| 510 | `platform_wooden` | floor | 1510 | `platform_wooden` | hardness=15, collision=2 |

**Mapping Rules:**

1. `build_item_id`和`output_tile_id`是**独立系统**的ID，不直接相等
2. 映射关系通过BuildItemDatabase的`output_tile_id`字段定义
3. 建造系统查询`output_tile_id`后，向TileMap系统请求放置该tile
4. 墙体类建造物品ID（100-199）映射到墙体tile ID（1000-1499），ID偏移+900
5. 设施类建造物品ID（400-499）映射到设施tile ID（2000-2499），ID偏移+1600
6. 炮塔/陷阱建造物品需要**额外实体**（见炮塔系统GDD），tile仅为基座

**Special Mapping Cases:**

| Case | Build Item | Output Tile | Additional Entity |
|------|------------|-------------|-------------------|
| 炮塔建造 | turret_basic (200) | turret_base (2500) | TurretEntity (runtime entity) |
| 陷阱建造 | trap_spikes (300) | trap_spikes_tile (2502) | TrapEntity (runtime entity) |
| 设施建造 | facility_storage (400) | facility_storage_basic (2000) | StorageContainer (交互实体) |

> **Architecture Note**: 炮塔和陷阱的tile是"基座/锚点"，实际功能由独立的Entity系统实现。BuildItemDatabase仅定义配方和tile放置，Entity行为由各自的系统GDD定义。

---

#### 6. Placement Requirements Structure

放置条件约束定义建造物品在世界中放置的规则。

**PlacementReq Data Structure:**

```gdscript
# PlacementReq structure (stored in placement_requirements field)
class PlacementReq:
    var requires_floor: bool          # 是否需要地板/地面支撑（default: true）
    var requires_adjacent_wall: bool  # 是否需要相邻墙体（炮塔需要）
    var requires_adjacent_floor: bool # 是否需要相邻地板（墙体连接）
    var requires_support_below: bool  # 是否需要下方支撑（平台需要）
    var requires_clear_space: bool    # 是否需要空间无障碍（default: true）
    var min_distance_from_spawn: int  # 距离生成点最小距离（0=无限制）
    var forbidden_zones: Array[int]   # 禁止放置的区域ID列表
```

**Placement Requirement Rules:**

| Category | requires_floor | requires_adjacent_wall | requires_clear_space | Notes |
|----------|---------------|----------------------|---------------------|-------|
| `wall` | false | false | true | 墙体可独立放置，但需相邻地板或墙体连接 |
| `turret` | true | true (optional) | true | 炮塔需要地板支撑 OR 墙体依附 |
| `trap` | true | false | true | 陷阱需要地板，无碰撞所以不阻挡 |
| `facility` | true | false | true | 设施需要地板支撑 |
| `floor` | false | false | true | 地板需要下方支撑或相邻地板连接 |

**Placement Validation Algorithm:**

```gdscript
func validate_placement(build_item_id: int, target_cell: Vector2i) -> Dictionary:
    var build_item = BuildItems.get_build_item(build_item_id)
    var reqs = build_item.placement_requirements
    var result = {"valid": true, "reasons": []}
    
    # Rule 1: Check clear space (target cell must be empty)
    if reqs.requires_clear_space:
        if TileMapWorld.is_cell_occupied(target_cell, LAYER_STRUCTURES):
            result.valid = false
            result.reasons.append("Cell occupied by existing structure")
    
    # Rule 2: Check floor requirement (need solid below)
    if reqs.requires_floor:
        var below_cell = target_cell + Vector2i(0, 1)
        if not TileMapWorld.is_cell_occupied(below_cell, LAYER_STRUCTURES) \
           and not TileMapWorld.is_cell_occupied(below_cell, LAYER_TERRAIN):
            result.valid = false
            result.reasons.append("No floor/ground below")
    
    # Rule 3: Check adjacent wall (for turret wall-mount)
    if reqs.requires_adjacent_wall:
        var has_adjacent_wall = check_adjacent_wall(target_cell)
        if not has_adjacent_wall and not reqs.requires_floor:
            result.valid = false
            result.reasons.append("Requires adjacent wall for mounting")
    
    # Rule 4: Check forbidden zones
    if reqs.forbidden_zones.size() > 0:
        var zone_id = WorldZones.get_zone_at(target_cell)
        if zone_id in reqs.forbidden_zones:
            result.valid = false
            result.reasons.append("Cannot build in this zone")
    
    return result
```

---

#### 7. Build Time Calculation Rules

建造时间影响防守规划节奏，是Pillar 3（尸潮即高潮）的核心参数。

**Build Time Design Rationale:**

| Build Time Range | Category Example | Gameplay Impact |
|------------------|------------------|-----------------|
| 1-5 sec | 基础墙、地板 | 快速反应建造，防守倒计时紧迫时可补建 |
| 5-15 sec | 石墙、加固墙、设施 | 中等建造，需提前规划 |
| 15-30 sec | 符文墙、炮塔 | 高级建造，需预留时间 |
| 30-60 sec | 秘银墙、高级炮塔 | 顶级建造，需专门安排时间窗口 |
| 60+ sec | 闸门、大型设施 | Alpha阶段内容 |

**Build Time Formula Reference:**

```
build_time_seconds = BASE_TIME + MATERIAL_COMPLEXITY + TIER_MODIFIER

BASE_TIME = 3.0 seconds (minimum foundation time)
MATERIAL_COMPLEXITY = material_cost_count × 0.5 seconds (每种材料增加0.5秒处理时间)
TIER_MODIFIER = tier_level × 2.0 seconds (等级越高，建造越慢)
```

**Formula Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| BASE_TIME | float | 3.0 | 基础建造时间（固定） |
| material_cost_count | int | 1-5 | 材料种类数量 |
| tier_level | int | 1-5 | 建造物品等级（basic=1, mithril=5） |

**Build Time Examples:**

| Build Item | Tier | Material Count | Formula | Result |
|------------|------|----------------|---------|--------|
| wall_basic | 1 | 2 | 3 + 2×0.5 + 1×2 | 6 sec → **design override: 5 sec** |
| wall_stone | 2 | 1 | 3 + 1×0.5 + 2×2 | 7.5 sec → **design override: 8 sec** |
| wall_reinforced | 3 | 3 | 3 + 3×0.5 + 3×2 | 10.5 sec → **design override: 15 sec** |
| wall_rune | 4 | 2 | 3 + 2×0.5 + 4×2 | 12 sec → **design override: 20 sec** |
| wall_mithril | 5 | 2 | 3 + 2×0.5 + 5×2 | 14 sec → **design override: 30 sec** |
| turret_basic | 3 | 3 | 3 + 3×0.5 + 3×2 | 10.5 sec → **design override: 15 sec** |

> **Override Rule**: 公式提供基准值，实际建造时间需根据玩法测试手动调整。公式值与设计值差异记录reasoning。

---

#### 8. Initial Build Item Catalog (MVP)

以下是MVP阶段必需的建造物品定义。共12个建造物品覆盖5个分类。

**Wall Build Items (ID 100-199):**

| ID | Name | Display | Output Tile | Costs | Build Time | Tier |
|----|------|---------|-------------|-------|------------|------|
| 100 | `wall_basic` | "基础墙体" | 1000 | iron×3, stone×2 | 5 sec | 1 |
| 110 | `wall_stone` | "石墙" | 1010 | stone×8 | 8 sec | 2 |
| 120 | `wall_reinforced` | "加固墙" | 1020 | iron×6, stone×4, coal×2 | 15 sec | 3 |
| 130 | `wall_rune` | "符文墙" | 1030 | iron×4, crystal_shard×3 | 20 sec | 4 |
| 140 | `wall_mithril` | "秘银墙" | 1040 | mithril×4, crystal_shard×2 | 30 sec | 5 |

**Turret Build Items (ID 200-299):**

| ID | Name | Display | Output Tile | Costs | Build Time | Tier |
|----|------|---------|-------------|-------|------------|------|
| 200 | `turret_basic` | "基础炮塔" | 2500 | iron×6, stone×4, crystal_shard×2 | 15 sec | 3 |
| 210 | `turret_rune` | "符文炮塔" | 2501 | iron×4, crystal_shard×5, crystal_cluster×1 | 25 sec | 4 |

**Trap Build Items (ID 300-399):**

| ID | Name | Display | Output Tile | Costs | Build Time | Tier |
|----|------|---------|-------------|-------|------------|------|
| 300 | `trap_spikes` | "尖刺陷阱" | 2502 | iron×3, stone×2 | 5 sec | 2 |

**Facility Build Items (ID 400-499):**

| ID | Name | Display | Output Tile | Costs | Build Time | Tier |
|----|------|---------|-------------|-------|------------|------|
| 400 | `facility_storage` | "储物箱" | 2000 | iron×4, wood×6 | 10 sec | 2 |
| 410 | `facility_workbench` | "工作台" | 2001 | iron×2, wood×4, stone×2 | 8 sec | 2 |

**Floor/Platform Build Items (ID 500-599):**

| ID | Name | Display | Output Tile | Costs | Build Time | Tier |
|----|------|---------|-------------|-------|------------|------|
| 500 | `floor_basic` | "基础地板" | 1500 | stone×3 | 3 sec | 1 |
| 510 | `platform_wooden` | "木质平台" | 1510 | wood×4 | 4 sec | 1 |

**MVP Total: 12 Build Items**

---

#### 9. Build Item Database Query API

建造物品数据库通过`BuildItemDatabase`单例提供查询接口，供所有下游系统使用。

**Singleton Registration:**

```gdscript
# BuildItemDatabase.gd (autoload singleton)
class_name BuildItemDatabase
extends Node

# Autoload name: "BuildItems"
# Note: Autoloads must extend Node for proper lifecycle
```

**Primary Query Methods:**

```gdscript
# === Basic Lookup ===

# Returns build item definition dictionary for given build_item_id
func get_build_item(build_item_id: int) -> Dictionary

# Returns build item name (internal identifier) for given ID
func get_build_item_name(build_item_id: int) -> String

# Returns display name (localized) for given ID
func get_display_name(build_item_id: int) -> String

# Returns output tile type ID for given build item
func get_output_tile_id(build_item_id: int) -> int

# === Property Query ===

# Returns category for build item (0-5)
func get_category(build_item_id: int) -> int

# Returns build time in seconds
func get_build_time(build_item_id: int) -> float

# Returns material costs array
func get_material_costs(build_item_id: int) -> Array[MaterialCost]

# Returns placement requirements
func get_placement_requirements(build_item_id: int) -> PlacementReq

# Returns tech unlock requirement
func get_tech_unlock(build_item_id: int) -> int

# === Category Query ===

# Returns all build items in specified category
func get_build_items_by_category(category: int) -> Array[int]

# Returns all wall build items
func get_wall_items() -> Array[int]

# Returns all turret build items
func get_turret_items() -> Array[int]

# Returns all trap build items
func get_trap_items() -> Array[int]

# Returns all facility build items
func get_facility_items() -> Array[int]

# === Material Query ===

# Returns total resource cost for specific resource_id across all items
func get_total_resource_requirement(build_item_id: int, resource_id: int) -> int

# Checks if player has sufficient materials for build item
func can_afford_build(build_item_id: int, player_inventory: Dictionary) -> bool

# === Validation ===

# Returns true if build_item_id is valid
func is_valid_build_item(build_item_id: int) -> bool

# Validates placement at target cell, returns result dictionary
func validate_placement(build_item_id: int, target_cell: Vector2i) -> Dictionary

# Returns true if tech unlock requirement satisfied
func is_unlocked(build_item_id: int, player_tech_progress: Dictionary) -> bool

# === Mapping Query ===

# Returns build_item_id that produces given tile_type_id (reverse lookup)
func get_build_item_for_tile(tile_type_id: int) -> int

# Returns all build items unlocked by given tech_id
func get_items_unlocked_by_tech(tech_id: int) -> Array[int]
```

**Query Return Format:**

```gdscript
# get_build_item returns this dictionary structure:
{
    "build_item_id": int,
    "name": String,
    "display_name": String,
    "category": int,
    "output_tile_id": int,
    "build_time_seconds": float,
    "material_costs": Array[MaterialCost],  # [{resource_id, quantity}, ...]
    "tech_unlock_required": int,
    "placement_requirements": PlacementReq,
    "icon_path": String,
    "description": String,
    "build_preview_tile_id": int,
    "max_per_bunker": int
}
```

### States and Transitions

建造物品数据库是静态数据定义系统，不管理运行时状态。每个建造物品定义在数据创建后即固定不变。运行时的建造实例状态由方块放置系统和建造验证系统管理。

#### Build Item Definition States

每个建造物品定义有以下生命周期状态：

| State | Condition | Description |
|-------|-----------|-------------|
| `ACTIVE` | 建造物品定义完成并可用 | 建造物品可出现在建造菜单，可被玩家建造 |
| `DEPRECATED` | 建造物品标记废弃 | 建造物品从建造菜单移除，已建造实例保留功能 |
| `PLANNED` | 建造物品定义在GDD但未实现 | 建造物品ID预留，资源文件未创建 |
| `LOCKED` | 建造物品需要科技解锁（MVP阶段无此状态） | 存在于数据库但建造菜单不可见 |

**State transition rules:**

1. `PLANNED → ACTIVE`: 当BuildItemDefinition资源文件创建并注册
2. `ACTIVE → DEPRECATED`: 当建造物品从内容管线移除
3. `ACTIVE → LOCKED`: 当科技系统实现后，根据tech_unlock_required状态
4. `LOCKED → ACTIVE`: 当玩家解锁对应科技
5. 无其他转换 — 建造物品定义运行时不变

#### Runtime Build Instance States (Owned by 方块放置系统)

建造物品数据库不管理运行时状态。运行时建造实例的状态（BUILDING/COMPLETED/DESTROYED）由方块放置系统管理。

### Interactions with Other Systems

#### Upstream Systems (数据引用)

建造物品数据库引用以下Foundation层系统的数据定义：

| Referenced System | Data Consumed | Reference Type | Validation |
|-------------------|---------------|----------------|------------|
| **BlockTypeDatabase** | tile_type_id (output_tile_id) | External ID reference | Must reference valid tile with buildability=1 |
| **ResourceDatabase** | resource_id (in material_costs) | External ID reference | Must reference resource with is_build_material=1 |

**Reference Validation Rules:**

1. `output_tile_id`引用的tile必须存在于BlockTypeDatabase
2. `output_tile_id`引用的tile必须满足`buildability = 1`
3. `material_costs`中所有resource_id必须存在于ResourceDatabase
4. `material_costs`中所有resource_id必须满足`is_build_material = 1`
5. 引用验证在数据库加载时执行，失败则log warning

#### Downstream Consumer Systems

| Consumer System | Priority | Layer | Data Consumed | Query Methods | Timing |
|-----------------|----------|-------|---------------|---------------|--------|
| **方块放置系统** | MVP | Core | output_tile_id, material_costs, placement_requirements | `get_build_item()`, `validate_placement()` | On placement request |
| **建造验证系统** | MVP | Feature | material_costs, placement_requirements, tech_unlock_required | `can_afford_build()`, `validate_placement()`, `is_unlocked()` | Before placement validation |
| **炮塔系统** | MVP | Core | output_tile_id, build_time_seconds | `get_output_tile_id()`, `get_build_time()` | On turret construction |
| **陷阱系统** | Vertical Slice | Feature | output_tile_id, material_costs | `get_build_item()`, `get_material_costs()` | On trap construction |
| **地堡设施系统** | MVP | Feature | output_tile_id, placement_requirements | `get_build_item()`, `get_placement_requirements()` | On facility placement |
| **建造菜单UI** | MVP | Presentation | display_name, material_costs, build_time_seconds, category | `get_build_items_by_category()`, `get_display_name()` | On menu render |
| **科技解锁系统** | Vertical Slice | Feature | tech_unlock_required, category | `get_items_unlocked_by_tech()`, `is_unlocked()` | On tech unlock check |
| **HUD系统** | Full Vision | Presentation | display_name, build_time_seconds | `get_display_name()`, `get_build_time()` | On build preview tooltip |

#### Detailed Interaction Specifications

##### 方块放置系统

**Data provided:**
- Build item definition with output tile mapping
- Material costs for resource consumption
- Placement requirements for spatial validation

**Query methods called:**
- `BuildItems.get_build_item(build_item_id)` — retrieve full definition
- `BuildItems.get_output_tile_id(build_item_id)` — get tile to place
- `BuildItems.validate_placement(build_item_id, target_cell)` — validate placement

**Interaction contract:**
- 方块放置系统调用BuildItems获取配方数据
- 放置成功后，方块放置系统向TileMap请求放置output_tile_id
- BuildItems不参与实际放置过程，仅提供配方数据

##### 建造验证系统

**Data provided:**
- Material costs for inventory check
- Placement requirements for spatial validation
- Tech unlock requirement for progression check

**Query methods called:**
- `BuildItems.can_afford_build(build_item_id, player_inventory)` — check resource sufficiency
- `BuildItems.validate_placement(build_item_id, target_cell)` — validate placement location
- `BuildItems.is_unlocked(build_item_id, player_tech_progress)` — check tech unlock

**Interaction contract:**
- 建造验证系统负责综合验证（材料、位置、科技）
- BuildItems提供单项验证方法，建造验证系统组合调用
- 验证失败返回reasons数组，供UI显示错误信息

## Formulas

建造物品数据库包含材料成本计算和建造时间推导公式。

### Build Time Calculation Formula

建造时间基准公式（设计参考，实际值需手动调整）：

```
build_time_seconds = BASE_TIME + MATERIAL_COMPLEXITY + TIER_MODIFIER

BASE_TIME = 3.0 seconds
MATERIAL_COMPLEXITY = material_cost_count × 0.5 seconds
TIER_MODIFIER = tier_level × 2.0 seconds
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `BASE_TIME` | BT | float | 3.0 | 固定基础建造时间 |
| `material_cost_count` | MCC | int | 1-5 | 材料种类数量（material_costs数组长度） |
| `tier_level` | TL | int | 1-5 | 建造物品等级 |

**Tier Level Mapping:**

| Tier Level | Category Examples | Build Item IDs |
|------------|-------------------|----------------|
| 1 | Basic walls, Basic floors | 100, 500, 510 |
| 2 | Stone walls, Traps, Facilities | 110, 300, 400, 410 |
| 3 | Reinforced walls, Basic turret | 120, 200 |
| 4 | Rune walls, Rune turret | 130, 210 |
| 5 | Mithril walls | 140 |

**Output Range:** 3.0 - 17.0 seconds (formula range)

**Formula vs Design Values:**

| Build Item | Formula Result | Design Value | Override Reason |
|------------|---------------|--------------|-----------------|
| wall_basic (TL=1, MCC=2) | 3 + 1 + 2 = 6 | 5 | Lower for quick response in urgent defense |
| wall_stone (TL=2, MCC=1) | 3 + 0.5 + 4 = 7.5 | 8 | Round to whole number, slight increase for stone weight |
| wall_reinforced (TL=3, MCC=3) | 3 + 1.5 + 6 = 10.5 | 15 | Significant increase for defense value perception |
| wall_rune (TL=4, MCC=2) | 3 + 1 + 8 = 12 | 20 | Magic construction complexity, longer ritual time |
| wall_mithril (TL=5, MCC=2) | 3 + 1 + 10 = 14 | 30 | Premium material requires careful handling |
| turret_basic (TL=3, MCC=3) | 3 + 1.5 + 6 = 10.5 | 15 | Complex mechanism assembly |
| turret_rune (TL=4, MCC=3) | 3 + 1.5 + 8 = 12.5 | 25 | Rune inscribing + turret assembly |
| trap_spikes (TL=2, MCC=2) | 3 + 1 + 4 = 8 | 5 | Quick deployment trap, lower than formula |
| facility_storage (TL=2, MCC=2) | 3 + 1 + 4 = 8 | 10 | Box assembly moderate complexity |
| facility_workbench (TL=2, MCC=3) | 3 + 1.5 + 4 = 8.5 | 8 | Standard facility timing |

**Edge Case:** When formula produces < 3.0 seconds, clamp to minimum 3.0 seconds.

---

### Total Resource Cost Formula

计算建造物品的总资源价值（用于经济平衡）：

```
total_value = sum(material_costs[i].quantity × resource_base_value[i])

total_value = Σ(q_i × v_i) for i in material_costs
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `quantity` | q_i | int | 1-999 | 材料消耗数量 |
| `resource_base_value` | v_i | int | 1-9999 | 资源基础价值（从ResourceDatabase获取） |

**Resource Base Values (from ResourceDatabase):**

| Resource ID | Resource Name | Base Value |
|-------------|---------------|------------|
| 101 | iron | 5 |
| 102 | copper | 8 |
| 103 | coal | 3 |
| 110 | stone | 1 |
| 120 | wood | 2 |
| 201 | crystal_shard | 15 |
| 202 | crystal_cluster | 50 |
| 301 | mithril | 120 |

**Total Value Examples:**

| Build Item | Costs Calculation | Total Value |
|------------|------------------|-------------|
| wall_basic | 3×5 + 2×1 | 17 |
| wall_stone | 8×1 | 8 |
| wall_reinforced | 6×5 + 4×1 + 2×3 | 42 |
| wall_rune | 4×5 + 3×15 | 65 |
| wall_mithril | 4×120 + 2×15 | 510 |
| turret_basic | 6×5 + 4×1 + 2×15 | 54 |
| turret_rune | 4×5 + 5×15 + 1×50 | 145 |
| trap_spikes | 3×5 + 2×1 | 17 |
| facility_storage | 4×5 + 6×2 | 32 |
| facility_workbench | 2×5 + 4×2 + 2×1 | 20 |

**Output Range:** 3 - 9999 value units

---

### Build Time Per Value Ratio

用于平衡分析的衍生公式：

```
time_per_value_ratio = build_time_seconds / total_value
```

**Desired Ratio Ranges:**

| Tier | Ratio Target | Reasoning |
|------|--------------|-----------|
| Basic (1-2) | 0.3-0.5 sec/value | Quick access, low investment |
| Mid (3) | 0.2-0.4 sec/value | Moderate investment efficiency |
| High (4-5) | 0.05-0.1 sec/value | High value items are faster per unit |

**Ratio Examples:**

| Build Item | Time | Value | Ratio | Assessment |
|------------|------|-------|-------|------------|
| wall_basic | 5 | 17 | 0.29 | Within basic range ✓ |
| wall_stone | 8 | 8 | 1.0 | Higher than desired, adjust? |
| wall_reinforced | 15 | 42 | 0.36 | Within mid range ✓ |
| wall_rune | 20 | 65 | 0.31 | Within high range ✓ |
| wall_mithril | 30 | 510 | 0.06 | Within premium range ✓ |

> **Balance Note**: wall_stone ratio偏高，但设计意图是"石头需搬运更长时间"，保持当前值。

---

### Material Affordability Check Formula

验证玩家是否有足够材料建造：

```
can_afford = ∀ i in material_costs: player_inventory[resource_id_i] >= quantity_i

can_afford = (inventory[r1] >= q1) AND (inventory[r2] >= q2) AND ...
```

**Variables:**

| Variable | Type | Description |
|----------|------|-------------|
| `player_inventory` | Dictionary | 玩家当前持有的资源数量映射 |
| `material_costs` | Array | 建造物品的材料消耗数组 |

**Implementation:**

```gdscript
func can_afford_build(build_item_id: int, player_inventory: Dictionary) -> bool:
    var material_costs = get_material_costs(build_item_id)
    for cost in material_costs:
        var held = player_inventory.get(cost.resource_id, 0)
        if held < cost.quantity:
            return false
    return true
```

**Return Values:**
- `true`: 所有材料充足，可以建造
- `false`: 至少一种材料不足

---

### Category to Tile Layer Mapping

建造物品分类到TileMap层级的映射规则：

```
target_layer = CATEGORY_LAYER_MAP[category]
```

**Category Layer Mapping Table:**

| Category | Target Layer | Layer Name | Collision Required |
|----------|--------------|------------|--------------------|
| wall (0) | 2 | structures | Full (collision_shape=1) |
| turret (1) | 2 | structures | Full (collision_shape=1) |
| trap (2) | 2 | structures | None (collision_shape=0) |
| facility (3) | 2 | structures | Full (collision_shape=1) |
| floor (4) | 2 or 3 | structures or platforms | Full or Platform |
| gate (5) | 2 | structures | Full (collision_shape=1) |

**Validation Rule:**
- 输出tile的collision_shape必须匹配目标layer的要求
- 输出tile的layer_allowed必须包含target_layer

---

### Query Behavior Rules

**Invalid build_item_id handling:**

```
get_build_item(build_item_id):
    if build_item_id == 0:
        return NULL_BUILD_ITEM_DEFINITION
    if build_item_id not in registered_build_items:
        return null (warning logged)
    return Dictionary with all fields
```

**Default value returns for invalid queries:**

| Method | Invalid ID Return |
|--------|-------------------|
| `get_build_item()` | null |
| `get_build_item_name()` | "" (empty string) |
| `get_display_name()` | "" |
| `get_output_tile_id()` | 0 |
| `get_category()` | 0 (wall) |
| `get_build_time()` | 0.0 |
| `get_material_costs()` | [] (empty array) |
| `get_placement_requirements()` | {} (empty dict) |
| `get_tech_unlock()` | 0 |
| `is_valid_build_item()` | false |
| `validate_placement()` | {"valid": false, "reasons": ["Invalid build_item_id"]} |
| `can_afford_build()` | false |
| `is_unlocked()` | false |

## Edge Cases

### 1. Invalid Build Item ID Query

**Case**: System queries build item with ID that does not exist in the database.

| Scenario | Input | Expected Behavior | Recovery |
|----------|-------|-------------------|----------|
| `build_item_id = 0` | `get_build_item(0)` | Return `NULL_BUILD_ITEM_DEFINITION` | No error thrown; downstream system handles null |
| `build_item_id < 0` | `get_build_item(-1)` | Return `null`, log warning: "Invalid build_item_id: -1 (negative)" | Downstream system checks for null |
| `build_item_id > 65535` | `get_build_item(70000)` | Return `null`, log warning: "Invalid build_item_id: 70000 (exceeds 16-bit range)" | Downstream system handles missing item |
| `build_item_id` not registered | `get_build_item(150)` (ID in wall range but not defined) | Return `null`, log warning: "build_item_id 150 not found in registry" | Downstream system handles missing item |

**Implementation Rule**: All query methods return `null` or appropriate default values without throwing exceptions. The database never crashes on invalid input.

---

### 2. Output Tile ID Reference to Non-Buildable Tile

**Case**: Build item references a tile type that is not buildable (buildability=0).

| Scenario | Input | Expected Behavior | Resolution |
|----------|-------|-------------------|------------|
| Tile exists but buildability=0 | Build item defines output_tile_id=100 (surface_stone, buildability=0) | Database returns valid definition; placement validation fails with "Output tile not buildable" | BlockTypeDatabase must define buildable tiles; fix tile definition |
| Tile exists but not in allowed layer | Build item wall (category=0) references tile with layer_allowed=[1] (terrain layer) | Database returns valid definition; placement validation fails with "Tile layer mismatch" | Fix tile definition to allow Layer 2 |
| Tile collision mismatch | Build item wall references tile with collision_shape=0 (no collision) | Database returns valid definition; placement validation fails with "Wall requires full collision" | Fix tile collision definition |

**Cross-System Contract**: BuildItemDatabase定义配方，BlockTypeDatabase定义tile属性。BuildItemDatabase在加载时验证output_tile_id的buildability=1，验证失败log warning但不阻止定义加载。运行时placement validation再次验证。

---

### 3. Material Cost Reference to Non-Build Material

**Case**: Build item material costs reference a resource that is not a build material.

| Scenario | Input | Expected Behavior | Resolution |
|----------|-------|-------------------|------------|
| Resource exists but is_build_material=0 | Build item defines material_costs=[{401, 2}] (food_basic, is_build_material=0) | Database returns valid definition; afford check may succeed but placement fails | ResourceDatabase must mark build materials correctly |
| Resource ID not in ResourceDatabase | Build item defines material_costs=[{999, 2}] (invalid resource_id) | Database returns valid definition; afford check fails with "Unknown resource" | Fix material_costs definition |
| Empty material_costs array | Build item defines material_costs=[] | Database loads definition; placement validation fails with "No material costs defined" | All build items must have at least one material cost |

**Material Validation Rule**: material_costs验证在数据库加载时执行，验证失败log warning但不阻止加载。运行时can_afford_build()再次验证资源存在性。

---

### 4. Build Time Below Minimum Threshold

**Case**: Build item defines build_time_seconds below minimum threshold (0.5 seconds).

| Scenario | Input | Expected Behavior | System Response |
|----------|-------|-------------------|-----------------|
| build_time = 0.0 | Build item defines build_time_seconds=0.0 | Clamp to minimum 0.5 seconds at load time | Log warning: "Build time clamped from 0.0 to 0.5" |
| build_time < 0.5 | Build item defines build_time_seconds=0.3 | Clamp to minimum 0.5 seconds | Log warning: "Build time clamped from 0.3 to 0.5" |
| build_time = 0.5 | Valid minimum value | Accepted without modification | Normal operation |

**Clamping Rule**: 建造时间必须在范围[0.5, 300.0]内。低于0.5秒的值被自动修正为0.5秒（瞬时建造破坏Pillar 3节奏）。

---

### 5. Placement Validation Failures

**Case**: Placement validation returns multiple failure reasons.

| Scenario | Input | Expected Behavior | UI Response |
|----------|-------|-------------------|-------------|
| Multiple failures | Target cell occupied + No floor below + Missing materials | validate_placement returns all three reasons in array | UI displays all reasons: "位置被占用; 缺少地板支撑; 材料不足" |
| Single failure | Target cell occupied only | validate_placement returns single reason | UI displays single reason |
| All validations pass | Valid target cell + materials available + tech unlocked | validate_placement returns {"valid": true, "reasons": []} | Placement proceeds |

**Reasons Array Structure:**

```gdscript
# validate_placement returns:
{
    "valid": bool,
    "reasons": Array[String]  # Empty if valid, contains all failure reasons if invalid
}
```

---

### 6. Tech Unlock Required but Tech System Not Implemented

**Case**: Build item defines tech_unlock_required > 0 but Tech Unlock System not yet implemented (MVP phase).

| Scenario | Input | Expected Behavior | Player Experience |
|----------|-------|-------------------|-------------------|
| tech_unlock_required > 0 during MVP | Build item defines tech_unlock_required=50 | is_unlocked() checks if tech system exists; if not, returns true (fallback) | Build item appears in menu as unlocked |
| Tech system implemented | Build item defines tech_unlock_required=50 | is_unlocked() queries TechDatabase | Build item appears only if tech unlocked |

**MVP Fallback Rule**: MVP阶段所有tech_unlock_required值默认为0（无科技锁定）。如果意外设置了tech_unlock_required值，is_unlocked()返回true（宽容模式）避免阻止MVP测试。

---

### 7. Reverse Lookup: Tile to Build Item

**Case**: Querying build item that produces a given tile type ID.

| Scenario | Input | Expected Behavior | System Response |
|----------|-------|-------------------|-----------------|
| Tile has single build item | get_build_item_for_tile(1000) (wall_basic tile) | Return build_item_id=100 | Normal operation |
| Tile has no build item | get_build_item_for_tile(100) (surface_stone, natural terrain) | Return 0 (NULL_BUILD_ITEM) | Log debug: "No build item for tile_type_id 100" |
| Multiple build items produce same tile | Tile 2500 (turret_base) produced by turret_basic AND turret_rune | Return first registered build_item_id | Log warning: "Multiple build items for tile 2500, returning first" |
| Invalid tile ID | get_build_item_for_tile(-1) | Return 0, log warning | Handle gracefully |

**Multiple Items Warning**: 如果多个建造物品产生相同tile（如炮塔基座），这是设计问题而非运行时问题。数据库返回第一个注册项，但应在设计阶段避免这种情况。

---

### 8. Build Item in PLANNED State

**Case**: Build item ID is reserved in allocation scheme but definition not yet created.

| Scenario | Input | Expected Behavior | Resolution |
|----------|-------|-------------------|------------|
| Query PLANNED item | `get_build_item(160)` (wall range slot, not implemented) | Return `null`, log warning: "build_item_id 160 is in PLANNED state" | Developer must create definition |
| Build menu queries PLANNED item | Build menu tries to list wall items | PLANNED items excluded from list | Build menu only shows ACTIVE items |

---

### 9. Deprecated Build Items in Player Saves

**Case**: Player loads save with deprecated build item instances.

| Scenario | Input | Expected Behavior | Player Experience |
|----------|-------|-------------------|-------------------|
| Deprecated item in world | Save contains build_item_id=1050 (deprecated wall type) | BuildItems returns DEPRECATED definition (still exists) | Build functions normally, no player-visible difference |
| Deprecated item in player inventory | Player has "Old Wall" item referencing deprecated ID | Inventory allows placement; item marked deprecated in UI (optional) | Player can still use deprecated items |
| Query deprecated item | `get_build_item(1050)` | Returns valid definition (deprecated items remain queryable) | Definition exists but build menu doesn't offer it |

**Deprecation Policy**: DEPRECATED items remain in database and respond to queries. They are removed from build menu and new content, but existing instances function normally.

---

### 10. Max Per Bunker Limit Exceeded

**Case**: Build item defines max_per_bunker > 0 and limit is reached.

| Scenario | Input | Expected Behavior | System Response |
|----------|-------|-------------------|-----------------|
| max_per_bunker = 2, player has 2 | Player tries to build third facility_storage | validate_placement returns false with reason "Max limit (2) reached for this item" | UI shows limit message |
| max_per_bunker = 0 | No limit enforced | Normal operation | Unlimited placement |
| Player has 1, max = 2 | Player tries to build second | validate_placement returns true | Placement proceeds |

**MVP Note**: MVP阶段所有max_per_bunker = 0（无限制）。此功能为Alpha阶段内容。

---

### 11. Build Item ID Collision (Duplicate IDs)

**Case**: Two build items attempt to use the same build_item_id.

| Scenario | Input | Expected Behavior | Resolution |
|----------|-------|-------------------|------------|
| Duplicate ID at registration | Developer adds two items with ID 100 | Second registration fails, log error: "build_item_id 100 already registered" | Developer must fix ID allocation |
| ID conflict in expansion | Mod adds item claiming ID 200 (conflicts with base turret_basic) | ID allocation scheme prevents: expansion must use reserved range | Expansion rejected if ID outside reserved range |

**ID Guard**: All build item additions must use next available ID in category range. Manual ID assignment forbidden.

---

### 12. Cross-System Reference Validation Failure

**Case**: BlockTypeDatabase or ResourceDatabase not ready when BuildItemDatabase loads.

| Scenario | Input | Expected Behavior | Recovery |
|----------|-------|-------------------|----------|
| BlockTypes not loaded | BuildItemDatabase._ready() runs before BlockTypes | BuildItems loads definitions; output_tile_id validation deferred | Reference validation runs on first query, log warnings for invalid refs |
| Resources not loaded | BuildItemDatabase._ready() runs before Resources | BuildItems loads definitions; material_costs validation deferred | can_afford_build() handles missing resource gracefully |

**Load Order Contract**: BuildItemDatabase应在BlockTypes和Resources之后加载（Autoload顺序）。如果顺序错误，延迟验证在首次查询时执行。

---

### 13. Build Time = 300+ Seconds (Extended Build)

**Case**: Build item defines very long build time (60+ seconds).

| Scenario | Input | Expected Behavior | Player Experience |
|----------|-------|-------------------|-------------------|
| build_time = 60 | Large facility or gate | Progress bar displays, player can wait or cancel | Long build visible in UI with progress |
| build_time = 300 | Maximum allowed value | Progress bar displays, maximum time cap | Very long builds require special planning |
| Player cancels mid-build | Player interrupts after 30% progress | Materials consumed, incomplete tile remains | Partial build may need cleanup system |

**MVP Note**: MVP阶段无超过30秒的建造时间。Alpha阶段引入闸门和大型设施可能有60+秒建造时间。

---

### 14. Material Costs Quantity Overflow

**Case**: Material costs quantity exceeds reasonable range.

| Scenario | Input | Expected Behavior | System Response |
|----------|-------|-------------------|-----------------|
| quantity = 1000 | material_costs=[{101, 1000}] | Quantity clamped to 999 at load time | Log warning: "Quantity clamped from 1000 to 999" |
| quantity = 0 | material_costs=[{101, 0}] | Validation fails: "Quantity must be >= 1" | Build item marked invalid, not usable |
| quantity < 0 | material_costs=[{101, -5}] | Validation fails: "Quantity must be positive" | Build item marked invalid |

**Quantity Clamp**: 材料数量必须在范围[1, 999]内。超出范围自动修正或标记无效。

---

### 15. Build Preview Tile Different from Output Tile

**Case**: Build item defines different preview tile vs final output tile.

| Scenario | Input | Expected Behavior | Player Experience |
|----------|-------|-------------------|-------------------|
| preview ≠ output | turret_basic preview=generic_turret_preview (ID 2599) | Preview tile displayed during construction, output tile placed on completion | Player sees placeholder during build |
| preview = output | wall_basic preview=wall_basic (ID 1000) | Same tile for preview and final | Normal operation |
| Invalid preview tile ID | preview_tile_id references non-existent tile | Use output_tile_id as fallback | Log warning, proceed with output tile |

**MVP Note**: MVP阶段所有build_preview_tile_id = output_tile_id（预览与输出相同）。Alpha阶段可能引入特殊预览tile。

## Dependencies

建造物品数据库是Foundation层系统，引用其他Foundation层系统的数据定义，并向下游Core/Feature层系统提供配方数据。

### Upstream Dependencies (数据引用)

建造物品数据库**引用**以下系统的数据定义，但不依赖它们的运行时状态：

| System | Priority | Layer | Data Consumed | Reference Type | Validation Timing |
|--------|----------|-------|---------------|----------------|-------------------|
| **BlockTypeDatabase** | MVP | Foundation | tile_type_id (output_tile_id) | External ID reference | Database load + placement validation |
| **ResourceDatabase** | MVP | Foundation | resource_id (material_costs) | External ID reference | Database load + afford check |

**Reference Validation Rules:**

1. `output_tile_id`必须引用BlockTypeDatabase中存在的tile_type_id
2. `output_tile_id`引用的tile必须满足`buildability = 1`
3. `material_costs`中所有resource_id必须存在于ResourceDatabase
4. `material_costs`中所有resource_id必须满足`is_build_material = 1`
5. 引用验证在数据库加载时执行初步检查，运行时再次验证

**Cross-System ID Alignment:**

| Build Item Category | Build Item ID Range | Output Tile ID Range | Offset |
|---------------------|--------------------|--------------------|--------|
| wall (0) | 100-199 | 1000-1499 | +900 |
| turret (1) | 200-299 | 2500-2599 | +2300 |
| trap (2) | 300-399 | 2500-2599 (shared with turret) | Variable |
| facility (3) | 400-499 | 2000-2499 | +1600 |
| floor (4) | 500-599 | 1500-1999 | +1000 |

> **Note**: Trap和Turret共享2500-2599 tile ID range，因为它们都是"防御结构"。BuildItemDatabase通过build_item_id区分。

---

### Downstream Dependencies

以下系统依赖建造物品数据库的配方数据：

| System | Priority | Layer | Data Consumed | Query Methods | Dependency Type |
|--------|----------|-------|---------------|---------------|-----------------|
| **方块放置系统** | MVP | Core | output_tile_id, material_costs, placement_requirements | `get_build_item()`, `get_output_tile_id()`, `validate_placement()` | **Blocking** — Placement requires build recipe |
| **建造验证系统** | MVP | Feature | material_costs, placement_requirements, tech_unlock_required | `can_afford_build()`, `validate_placement()`, `is_unlocked()` | **Blocking** — Validation requires recipe data |
| **炮塔系统** | MVP | Core | output_tile_id, build_time_seconds | `get_output_tile_id()`, `get_build_time()` | **Blocking** — Turret construction needs recipe |
| **陷阱系统** | Vertical Slice | Feature | output_tile_id, material_costs | `get_build_item()`, `get_material_costs()` | **Non-blocking** — Extension content |
| **地堡设施系统** | MVP | Feature | output_tile_id, placement_requirements | `get_build_item()`, `get_placement_requirements()` | **Blocking** — Facility placement needs recipe |
| **闸门系统** | Alpha | Feature | output_tile_id, material_costs, placement_requirements | `get_build_item()`, `validate_placement()` | **Non-blocking** — Alpha content |
| **建造菜单UI** | MVP | Presentation | display_name, material_costs, build_time_seconds, category | `get_build_items_by_category()`, `get_display_name()` | **Blocking** — UI requires item catalog |
| **科技解锁系统** | Vertical Slice | Feature | tech_unlock_required, category | `get_items_unlocked_by_tech()`, `is_unlocked()` | **Blocking** — Tech system needs unlock mapping |
| **HUD系统** | Full Vision | Presentation | display_name, build_time_seconds | `get_display_name()`, `get_build_time()` | **Non-blocking** — UI enhancement |

---

### Dependency Interface Contract

#### Data Contract

| Interface | Return Type | Failure Mode | Consumer Contract |
|-----------|-------------|--------------|-------------------|
| `get_build_item(build_item_id)` | Dictionary or null | Return null for invalid ID | Consumer must handle null |
| `get_output_tile_id(build_item_id)` | int | Return 0 for invalid ID | Consumer checks > 0 before placement |
| `get_material_costs(build_item_id)` | Array[MaterialCost] | Return [] for invalid ID | Consumer checks array.size() > 0 |
| `get_build_time(build_item_id)` | float | Return 0.0 for invalid ID | Consumer uses for progress bar |
| `validate_placement(build_item_id, target_cell)` | Dictionary | Return {"valid": false, "reasons": [...]} for invalid | Consumer displays all reasons |
| `can_afford_build(build_item_id, player_inventory)` | bool | Return false for invalid ID or insufficient materials | Consumer blocks placement on false |

#### Timing Contract

| Constraint | Requirement |
|------------|-------------|
| Query latency | Immediate return — no async |
| Initialization order | BuildItems must load after BlockTypes and Resources (Autoload order) |
| Thread safety | Read-only queries are thread-safe (database immutable after load) |
| Cache expectation | Consumers may cache build item definitions — BuildItems does not invalidate caches |

---

### Critical Dependency Path (MVP)

建造物品数据库是以下MVP系统链的关键环节：

```
BlockTypeDatabase → BuildItemDatabase → 方块放置系统 → 地堡设施系统 → 尸潮防守
ResourceDatabase → BuildItemDatabase → 建造验证系统 → 方块放置系统
BuildItemDatabase → 炮塔系统 → 敌人AI系统 → 尸潮防守
```

**MVP系统必须在BuildItemDatabase完成后才能设计**：
- 方块放置系统需要output_tile_id和material_costs
- 建造验证系统需要material_costs和placement_requirements
- 炮塔系统需要build_time_seconds和output_tile_id

---

### Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| "output_tile_id must reference BlockTypeDatabase" | `design/gdd/block-type-database.md` | `tile_type_id`, `buildability` field | Data dependency |
| "material_costs resource_id must reference ResourceDatabase" | `design/gdd/resource-database.md` | `resource_id`, `is_build_material` field | Data dependency |
| "output tile collision_shape matches layer requirements" | `design/gdd/tilemap-world-system.md` | Layer validation matrix | Rule dependency |
| "turret construction spawns TurretEntity" | `design/gdd/turret-system.md` (pending) | Turret entity creation | State trigger |

## Tuning Knobs

建造物品数据库的调优参数主要影响建造成本、建造时间和防守策略。

### Primary Tuning Knobs (影响核心玩法)

| Knob | Current Value | Safe Range | Gameplay Effect | Pillar Affected |
|------|---------------|------------|-----------------|-----------------|
| **基础建造时间 (BASE_TIME)** | 3.0 sec | 1.0-5.0 | 所有建造物品的时间基准。提高 → 建造更慢 → 防守倒计时更紧张 | Pillar 3: 尸潮即高潮 |
| **等级时间修正 (TIER_MODIFIER)** | 2.0 sec/tier | 1.0-4.0 | 高级物品建造时间增量。提高 → 高级物品更耗时 → 升级决策更慎重 | Pillar 3: 尸潮即高潮 |
| **材料复杂度修正 (MATERIAL_COMPLEXITY)** | 0.5 sec/type | 0.2-1.0 | 多材料物品额外时间。提高 → 复杂配方更耗时 → 简单配方更受欢迎 | Pillar 2: 搜打撤节奏 |
| **墙体成本层级比例** | Basic:17 → Stone:8 → Reinforced:42 → Rune:65 → Mithril:510 | 1.5-3.0倍率 | 墙体升级价值跳跃。比例太低 → 升级太便宜 → 防守无压力 | Pillar 3: 尸潮即高潮 |

---

### Secondary Tuning Knobs (影响次要体验)

| Knob | Current Value | Safe Range | Gameplay Effect |
|------|---------------|------------|-----------------|
| **单材料数量上限** | 999 | 50-999 | 单材料消耗上限。降低 → 顶级物品可能无法设计 → 资源稀缺感增强 |
| **材料种类上限** | 5 | 3-8 | 配方复杂度上限。提高 → 更复杂配方 → 建造菜单UI需扩展 |
| **建造时间最小值** | 0.5 sec | 0.3-2.0 | 最小建造时间。提高 → 快速建造消失 → 防守反应时间减少 |
| **建造时间最大值** | 300 sec | 60-600 | 最大建造时间。提高 → 允许超长建造 → 需要建造进度保存机制 |

---

### Cost Tuning Knobs (建造成本平衡)

| Knob | Build Item | Current Value | Safe Range | Effect |
|------|------------|---------------|------------|--------|
| **基础墙铁成本** | wall_basic (100) | 3 iron | 1-8 | 新手防守门槛 |
| **基础墙石成本** | wall_basic (100) | 2 stone | 1-10 | 新手资源消耗 |
| **符文墙晶石成本** | wall_rune (130) | 3 crystal_shard | 1-10 | 魔导建造门槛 |
| **秘银墙秘银成本** | wall_mithril (140) | 4 mithril | 2-8 | 顶级建造稀缺性 |
| **基础炮塔铁成本** | turret_basic (200) | 6 iron | 3-12 | 防守成本基准 |
| **基础炮塔晶石成本** | turret_basic (200) | 2 crystal_shard | 1-5 | 魔导炮塔门槛 |

---

### Build Time Tuning Knobs (建造节奏平衡)

| Knob | Build Item | Current Value | Safe Range | Effect |
|------|------------|---------------|------------|--------|
| **基础墙建造时间** | wall_basic (100) | 5 sec | 3-10 sec | 快速反应建造 |
| **加固墙建造时间** | wall_reinforced (120) | 15 sec | 10-25 sec | 中等规划建造 |
| **秘银墙建造时间** | wall_mithril (140) | 30 sec | 20-60 sec | 顶级建造时间窗口 |
| **基础炮塔建造时间** | turret_basic (200) | 15 sec | 10-30 sec | 炮塔部署节奏 |
| **符文炮塔建造时间** | turret_rune (210) | 25 sec | 20-40 sec | 高级炮塔时间 |

---

### Knobs That Should NOT Be Tuned

| Knob | Reason |
|------|--------|
| **build_item_id allocation ranges** | ID分配是架构决策，改变会破坏跨系统引用一致性 |
| **output_tile_id mapping relationships** | 配方→tile映射是核心架构，改变需同步修改BlockTypeDatabase |
| **Category enumeration (0-5)** | 分类枚举是系统约定，添加新分类需更新所有依赖系统 |
| **Placement requirements structure fields** | 放置条件字段定义是架构契约，改变需修改验证系统 |

---

### Tuning Implementation

| Parameter Type | Storage Location | Load Time | Edit Method |
|----------------|------------------|-----------|-------------|
| **Per-item build_time_seconds** | BuildItemDefinition files | Game startup | Edit .tres files in Godot editor |
| **Per-item material_costs** | BuildItemDefinition files | Game startup | Edit .tres files |
| **Formula constants (BASE_TIME, etc.)** | GDD constants section | Compile time | Edit GDD → update formula → recalculate affected items |
| **Category layer mapping** | BuildItemDatabase.gd constants | Compile time | Edit code constants |

## Visual/Audio Requirements

建造物品数据库是纯数据系统，不直接产生视觉或音频输出。视觉和音频需求由下游消费系统实现。

### Visual Data Provided by BuildItemDatabase

| Data | Type | Consumer System | Visual Effect |
|------|------|-----------------|---------------|
| **icon_path** | Resource path | 建造菜单UI | 确定建造物品图标显示 |
| **display_name** | Localized string | 建造菜单UI, HUD tooltip | 确定建造物品名称显示 |
| **build_time_seconds** | float | 建造进度UI | 确定进度条动画时长 |
| **category** | int | 建造菜单UI | 确定建造物品分组显示 |

### Icon Asset Requirements

| Category | Icon Size | Icon Count (MVP) | Asset Path |
|----------|-----------|------------------|------------|
| **Wall** | 32×32 px | 5 icons | `assets/textures/icons/build/wall/` |
| **Turret** | 32×32 px | 2 icons | `assets/textures/icons/build/turret/` |
| **Trap** | 32×32 px | 1 icon | `assets/textures/icons/build/trap/` |
| **Facility** | 32×32 px | 2 icons | `assets/textures/icons/build/facility/` |
| **Floor** | 32×32 px | 2 icons | `assets/textures/icons/build/floor/` |

**Total MVP Icons**: 12 (matching Initial Build Item Catalog)

### Audio Data Mapping

数据库不存储音频文件。音频反馈由下游系统根据build item category和tier动态选择：

| Audio Event | Consumer System | Data Used | Audio Selection |
|-------------|-----------------|-----------|-----------------|
| **建造开始音效** | 方块放置系统 | category, tier | wall → 重放置声；turret → 机械启动声 |
| **建造完成音效** | 方块放置系统 | category | wall → 落地声；turret → 炮塔激活声 |
| **建造取消音效** | 方块放置系统 | — | 通用取消声 |

## UI Requirements

建造物品数据库为建造菜单UI和HUD系统提供数据支持。

### UI Data Provided by BuildItemDatabase

| UI Element | Data Source | Display Context | Consumer System |
|------------|-------------|-----------------|-----------------|
| **建造菜单分类标题** | `get_category_name(category)` | 建造菜单分类标签 | 建造菜单UI |
| **建造物品图标** | `icon_path` | 建造菜单列表项 | 建造菜单UI |
| **建造物品名称** | `get_display_name(build_item_id)` | 建造菜单列表项 | 建造菜单UI |
| **材料需求显示** | `get_material_costs(build_item_id)` | 建造菜单列表项详情 | 建造菜单UI |
| **建造时间显示** | `get_build_time(build_item_id)` | 建造菜单列表项详情 | 建造菜单UI |
| **建造进度条** | `get_build_time(build_item_id)` | 建造进行中HUD | 方块放置系统UI |
| **建造预览Tooltip** | `get_display_name()`, `get_build_time()`, `get_material_costs()` | 预览悬停 | HUD系统 |

### Build Menu Layout

```
┌─────────────────────────────────────┐
│ 建造菜单                             │
│ ─────────────────────────────────── │
│ [墙体]                               │
│   [图标] 基础墙体  铁×3 石×2  5秒    │
│   [图标] 石墙      石×8       8秒    │
│   [图标] 加固墙    铁×6 石×4 煤×2 15秒│
│   [图标] 符文墙    铁×4 晶×3  20秒    │
│   [图标] 秘银墙    秘×4 晶×2  30秒 锁定│
│                                     │
│ [炮塔]                               │
│   [图标] 基础炮塔  铁×6 石×4 晶×2 15秒│
│   [图标] 符文炮塔  铁×4 晶×5 晶簇×1 25秒│
│                                     │
│ [设施]                               │
│   [图标] 储物箱    铁×4 木×6  10秒    │
│   [图标] 工作台    铁×2 木×4 石×2 8秒│
│ ─────────────────────────────────── │
│ 材料: 铁(12) 石(8) 木(20) 晶(3) 秘(0)│
└─────────────────────────────────────┘
```

### Build Progress HUD Layout

```
┌────────────────────┐
│ 建造: 基础墙体      │
│ ████████░░░░ 60%   │ ← Progress bar
│ 剩余: 2秒          │
└────────────────────┘
```

## Acceptance Criteria

以下测试标准验证建造物品数据库的实现是否满足设计规范。

### Data Integrity Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-001** | 所有MVP Build Items定义完整 | 验证build_item_id 100-140, 200-210, 300, 400-410, 500-510存在于registry | 所有12个MVP build items有完整BuildItemDefinition |
| **AC-002** | Build Item ID无重复 | 检查registry build_item_id唯一性 | 每个build_item_id唯一，无冲突 |
| **AC-003** | ID分配符合allocation scheme | 验证每个build item ID在正确category range | wall在100-199, turret在200-299, etc. |
| **AC-004** | output_tile_id引用有效tile | 验证output_tile_id存在于BlockTypeDatabase | 所有output_tile_id有效且buildability=1 |
| **AC-005** | material_costs引用有效resource | 验证resource_id存在于ResourceDatabase | 所有resource_id有效且is_build_material=1 |
| **AC-006** | build_time_seconds在有效范围 | 检查所有build item build_time_seconds | 所有build_time在0.5-300.0范围 |
| **AC-007** | material_costs不为空 | 检查所有build item material_costs | 所有build item至少一个material cost |

### Query API Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-008** | Valid ID查询返回正确数据 | `get_build_item(100)` | 返回Dictionary包含正确name, category, output_tile_id, material_costs |
| **AC-009** | Invalid ID查询返回null | `get_build_item(150)` (不存在) | 返回null，无exception |
| **AC-010** | ID=0返回NULL_BUILD_ITEM | `get_build_item(0)` | 返回预定义NULL_BUILD_ITEM_DEFINITION |
| **AC-011** | Category查询正确 | `get_build_items_by_category(0)` (wall) | 返回ID 100, 110, 120, 130, 140 |
| **AC-012** | Output tile ID查询正确 | `get_output_tile_id(100)` | 返回1000 |
| **AC-013** | Material costs查询正确 | `get_material_costs(120)` | 返回[{101,6}, {110,4}, {103,2}] |
| **AC-014** | Build time查询正确 | `get_build_time(140)` | 返回30.0 |
| **AC-015** | Placement validation正确 | `validate_placement(100, occupied_cell)` | 返回{"valid": false, "reasons": ["Cell occupied"]} |

### Cross-System Integration Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-016** | Output tile buildability验证 | 验证output_tile_id引用的tile buildability=1 | 所有output tile满足buildability要求 |
| **AC-017** | Material is_build_material验证 | 验证material_costs引用的resource is_build_material=1 | 所有material满足build_material要求 |
| **AC-018** | Reverse lookup正确 | `get_build_item_for_tile(1000)` | 返回build_item_id=100 |
| **AC-019** | Afford check正确 | `can_afford_build(100, {101:5, 110:3})` | 返回true (iron>=3, stone>=2) |
| **AC-020** | Afford check失败正确 | `can_afford_build(100, {101:2, 110:1})` | 返回false (iron<3) |

### MVP Build Item Catalog Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-021** | Wall build items定义完整 | 检查ID range 100-199 | 5 wall items: basic, stone, reinforced, rune, mithril |
| **AC-022** | Turret build items定义完整 | 检查ID range 200-299 | 2 turret items: basic, rune |
| **AC-023** | Trap build items定义完整 | 检查ID range 300-399 | 1 trap item: spikes |
| **AC-024** | Facility build items定义完整 | 检查ID range 400-499 | 2 facility items: storage, workbench |
| **AC-025** | Floor build items定义完整 | 检查ID range 500-599 | 2 floor items: basic, platform_wooden |

### Edge Case Handling Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-026** | Negative ID返回null | `get_build_item(-1)` | 返回null，无crash |
| **AC-027** | ID超过65535返回null | `get_build_item(70000)` | 返回null，无crash |
| **AC-028** | Build time clamp生效 | BuildItemDefinition设置build_time=0.3 | 实际返回0.5 (clamped) |
| **AC-029** | Empty material_costs处理 | (design禁止，测试无效定义) | 加载时log warning，运行时拒绝建造 |
| **AC-030** | Tech unlock fallback (MVP) | `is_unlocked(100, {})` (tech system未实现) | 返回true |

### Performance Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-031** | 查询延迟足够低 | 循环`get_build_item()` 1000次，测量平均耗时 | 平均耗时 < 0.1ms |
| **AC-032** | Registry加载时间可接受 | 测量BuildItems autoload初始化耗时 | 加载时间 < 200ms |
| **AC-033** | 内存占用合理 | 测量BuildItemDatabase singleton内存占用 | 内存占用 < 200KB |

### Documentation Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-034** | GDD所有8个section完整 | 检查build-item-database.md | Overview, Player Fantasy, Detailed Design, Formulas, Edge Cases, Dependencies, Tuning Knobs, Acceptance Criteria全部有内容 |
| **AC-035** | Systems-index更新状态 | 检查systems-index.md | 建造物品数据库status更新为"Designed" |
| **AC-036** | API doc comments complete | 检查BuildItemDatabase.gd所有public方法有doc comments | 每个public方法有@brief description和@param/@return标注 |

### Pass/Fail Threshold

| Category | Pass Count | Fail Action |
|----------|------------|-------------|
| **Data Integrity (AC-001 to AC-007)** | 必须100%通过 | 任一失败 → 建造物品定义错误，必须修复 |
| **Query API (AC-008 to AC-015)** | 必须100%通过 | 任一失败 → API实现错误，必须修复 |
| **Cross-System (AC-016 to AC-020)** | 必须100%通过 | 任一失败 → 跨系统契约违反，必须修复 |
| **MVP Catalog (AC-021 to AC-025)** | 必须100%通过 | 任一失败 → 内容不足，必须补充 |
| **Edge Cases (AC-026 to AC-030)** | 必须100%通过 | 任一失败 → 边界处理缺失，必须补充 |
| **Performance (AC-031 to AC-033)** | 必须通过 | 任一失败 → 性能优化，但可进入实现阶段 |
| **Documentation (AC-034 to AC-036)** | 必须100%通过 | 任一失败 → 文档不完整 |

**Total Criteria**: 36
**Required for Implementation**: 100% pass on all blocking categories

## Open Questions

以下问题在GDD设计阶段未能完全解决，需要在实现前或实现过程中澄清。

### High Priority (Implementation Blocking)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-001** | BuildItemDefinition资源文件格式是否确认？当前设计假设使用Godot .tres文件存储单个建造物品定义，需验证Godot 4.6 Resource系统对此的支持。 | 技术总监 | BuildItemDatabase实现前 | 影响建造物品数据存储架构和加载方式 |
| **Q-002** | BlockTypeDatabase是否需要新增tile定义？炮塔和陷阱的output_tile_id引用tile（2501 turret_base_rune, 2502 trap_spikes_tile, 2001 facility_workbench）需要BlockTypeDatabase同步定义。 | BlockTypeDatabase设计者 | BuildItemDatabase实现前 | 输出tile不存在会导致建造验证失败 |
| **Q-003** | 炮塔和陷阱的Entity系统是否已设计？建造物品仅定义配方和tile放置，炮塔/陷阱的实际功能需要独立Entity系统。炮塔系统和陷阱系统GDD何时设计？ | 游戏设计者 | 炮塔/陷阱系统实现前 | 无法确定建造完成后的行为实现 |

### Medium Priority (Design Clarification)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-004** | 是否需要支持建造物品升级？（如wall_basic → wall_stone升级）当前设计假设拆除重建，但可能有升级机制。 | 游戏设计者 | Vertical Slice前 | 影响建造流程和成本计算 |
| **Q-005** | 建造取消后材料是否返还？当前设计假设材料消耗发生在建造开始时，取消建造的材料处理需确认。 | 游戏设计者 | 方块放置系统实现前 | 影响材料经济和玩家决策 |
| **Q-006** | 建造时间是否可加速？（如多人建造、科技加速）当前设计假设固定时间，但可能有加速机制。 | 游戏设计者 | Alpha阶段 | 影响建造策略和科技系统设计 |

### Low Priority (Future Consideration)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-007** | 是否需要建造物品蓝图系统？当前设计假设所有配方默认解锁，但可能有蓝图收集机制。 | 游戏设计者 | Beta阶段 | 不影响MVP实现 |
| **Q-008** | 是否需要建造物品品质等级？（如破损墙、完美墙）当前设计假设固定品质，但可能有品质差异。 | 游戏设计者 | Beta阶段 | 不影响MVP实现 |

### Resolution Tracking

| ID | Status | Resolution Date | Resolved By | Summary |
|----|--------|-----------------|-------------|---------|
| Q-001 | Open | — | — | Pending 技术总监确认 |
| Q-002 | Open | — | — | Pending BlockTypeDatabase更新 |
| Q-003 | Open | — | — | Pending 炮塔/陷阱系统GDD |
| Q-004 | Open | — | — | Pending 游戏设计者决策 |
| Q-005 | Open | — | — | Pending 游戏设计者决策 |
| Q-006 | Open | — | — | Pending 游戏设计者决策 |
| Q-007 | Open | — | — | Pending 游戏设计者决策 |
| Q-008 | Open | — | — | Pending 游戏设计者决策 |

### Assumptions Made (Temporary Decisions)

| Assumption | Rationale | Risk |
|------------|-----------|------|
| **output_tile_id引用已存在tile** | 墙体tile（1000-1040）已在BlockTypeDatabase定义，炮塔/陷阱tile需新增 | 需同步更新BlockTypeDatabase |
| **MVP阶段所有tech_unlock_required=0** | MVP阶段无科技系统，所有配方默认解锁 | Alpha阶段需重新设计解锁机制 |
| **建造取消不返还材料** | 简化实现，避免复杂状态管理 | 可能需根据玩家反馈调整 |
| **无建造升级机制** | MVP阶段拆除重建，简化实现 | Vertical Slice可能需要升级机制 |

## Cross-References

| This Document References | Target GDD | Specific Element Referenced | Nature |
|--------------------------|-----------|----------------------------|--------|
| "output_tile_id must reference BlockTypeDatabase" | `design/gdd/block-type-database.md` | `tile_type_id`, `buildability` field | Data dependency |
| "material_costs resource_id must reference ResourceDatabase" | `design/gdd/resource-database.md` | `resource_id`, `is_build_material` field | Data dependency |
| "output tile collision_shape matches layer requirements" | `design/gdd/tilemap-world-system.md` | Layer validation matrix | Rule dependency |
| "turret construction spawns TurretEntity" | `design/gdd/turret-system.md` (pending) | Turret entity creation | State trigger |
| "trap construction spawns TrapEntity" | `design/gdd/trap-system.md` (pending) | Trap entity creation | State trigger |
| "tech unlock gates build items" | `design/gdd/tech-unlock-system.md` (pending) | Tech unlock requirement | Rule dependency |