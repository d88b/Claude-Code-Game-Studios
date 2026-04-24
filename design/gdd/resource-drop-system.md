# 资源掉落系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 2 — 搜打撤节奏 (资源产出影响探索时间投资决策)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #14 (from systems-index.md)

## Overview

资源掉落系统是方块破坏事件到资源实体生成的桥梁层。它监听方块挖掘系统发出的破坏事件，根据方块的`resource_type_id`和`resource_multiplier`属性，通过掉落公式计算产出数量，在世界中生成对应的资源实体。

**数据层职责**：
- 接收方块破坏事件（包含`tile_type_id`, `cell_coords`）
- 从方块类型数据库查询`resource_type_id`和`resource_multiplier`
- 从资源数据库查询`max_stack_size`和`rarity`（影响掉落概率）
- 应用掉落公式计算最终产出数量
- 触发资源实体生成信号，传递资源ID、数量、位置

**玩家影响层（间接）**：
- 挖掘矿脉获得的资源数量由掉落公式决定
- 稀有资源的低掉落率创造稀缺感和价值认知
- 掉落倍率差异（如古代秘银×3.0 vs 铁矿×1.0）传达材料价值层级

**核心价值**：资源掉落系统将静态方块属性转化为动态收集奖励。没有它，方块只是被破坏；有了它，方块破坏成为资源获取的行为。所有Pillar 2（搜打撤节奏）的探索收益决策都依赖此系统的产出稳定性。

**下游消费系统**：
- 玩家背包系统 — 接收资源实体，处理堆叠和容量
- 战车仓库系统 — 接收大量资源，处理存储上限
- 科技解锁系统 — 查询掉落统计判断稀有资源获取率

## Player Fantasy

资源掉落系统没有直接的玩家幻想——它是数据计算层，玩家不会"感知"到掉落逻辑的执行。玩家体验的是掉落结果在实际游戏中的表现：挖掘矿脉后获得的资源数量、稀有材料出现的惊喜感、收集材料填充仓库的满足感。

**玩家间接体验（由掉落公式和概率驱动）**：

- **稀有度惊喜**: 挖掘秘银矿脉时，古代秘银（rarity=4）的低掉落率（10%×multiplier）让每次产出都成为意外惊喜。数据库的rarity值定义了这种惊喜频率。
- **产出量预期**: 挖掘煤矿层（multiplier=1.5）知道会获得较多煤矿，而铁矿脉（multiplier=1.0）产出稳定。玩家学会预测不同矿脉的产出效率，优化挖掘决策。
- **时间收益评估**: Pillar 2（搜打撤节奏）决策受掉落产出影响——"这个矿脉值得花多少时间挖掘？产出够不够抵消魔能消耗？"掉落公式定义了这种收益/时间权衡。

**支柱间接贡献**：

- **Pillar 2: 搜打撤节奏** — 掉落产出量影响探索收益评估。高产出矿脉吸引玩家停留，低产出矿脉促使玩家快速移动。掉落公式创造了"判断挖掘价值"的决策点。

## Detailed Design

### Core Rules

**Rule 1: Drop Trigger — Block Destruction Event**

资源掉落系统监听方块挖掘系统发出的 `block_destroyed` 信号。信号包含以下数据：
- `tile_type_id` (int): 破坏的方块类型ID
- `cell_coords` (Vector2i): 方块所在的单元格坐标
- `destroyer_id` (int): 破坏者ID（战车工具或玩家下车挖掘）

信号触发后，掉落系统执行完整的掉落计算流程。

---

**Rule 2: Single-Resource Drop Model (MVP)**

MVP阶段采用单资源掉落模型：每个方块类型最多掉落一种资源类型。方块类型数据库的`resource_type_id`字段指定唯一的产出资源。

- `resource_type_id = 0`: 无资源产出（如普通石头、泥土）
- `resource_type_id > 0`: 产出指定资源类型

**扩展预留**（Vertical Slice）：未来可扩展为多资源掉落表（multi-drop table），支持同一方块产出多种资源（如矿石+宝石）。数据结构预留`drop_table`数组字段，MVP阶段数组长度=1。

---

**Rule 3: Drop Quantity Calculation**

```
drop_count = floor(base_drop × resource_multiplier × luck_modifier)
```

**变量定义**：
- `base_drop`: 基础掉落量，固定值=1（每块产出1个基准单位）
- `resource_multiplier`: 方块类型数据库定义的产出倍率（0.5-10.0）
- `luck_modifier`: 运气修正，默认=1.0（未来扩展，MVP固定为1.0）

**产出范围**：
- 最低产出：`floor(1 × 0.5 × 1.0) = 0` → 最小产出=1（保底机制）
- 最高产出：`floor(1 × 10.0 × 1.0) = 10` → 受max_stack_size约束

---

**Rule 4: Drop Probability — Rarity Gate**

资源稀有度影响"是否产出"，而非"产出多少"。

```
drop_success = (random_float() < drop_probability)
drop_probability = BASE_DROP_RATE × rarity_modifier
```

**稀有度修正**（继承自资源数据库）：

| Rarity | rarity_modifier | BASE_DROP_RATE=1.0时实际概率 |
|--------|-----------------|------------------------------|
| 1 (common) | 1.0 | 100% |
| 2 (uncommon) | 0.6 | 60% |
| 3 (rare) | 0.3 | 30% |
| 4 (epic) | 0.1 | 10% |
| 5 (legendary) | 0.03 | 3% |

**计算流程**：
1. 查询resource_type_id对应的资源稀有度
2. 计算drop_probability = 1.0 × rarity_modifier
3. 执行RNG检查：`random_float(0.0, 1.0) < drop_probability`
4. 检查通过 → 执行Rule 3计算drop_count
5. 检查失败 → drop_count = 0，不生成资源实体

---

**Rule 5: Resource Entity Generation**

掉落成功后，生成资源实体并放置在世界中。

**实体数据结构**：

```gdscript
class ResourceEntity:
    var resource_id: int        # Resource type ID
    var quantity: int           # Drop count (1-10)
    var position: Vector2       # World position (cell_coords × CELL_SIZE + offset)
    var state: String           # "dropped" → "pickupable"
```

**放置规则**：
- 位置：`world_pos = Vector2(cell_coords.x × CELL_SIZE + CELL_SIZE/2, cell_coords.y × CELL_SIZE + CELL_SIZE/2)`
- 偏移：随机±8像素避免多掉落堆叠在同一位置
- 状态：初始为"dropped"，等待玩家拾取交互

**信号输出**：

```gdscript
signal resource_spawned(resource_id: int, quantity: int, position: Vector2)
```

---

**Rule 6: Drop Rate Modifier System (Tuning Hook)**

系统提供全局掉落倍率调整接口，供设计师批量调优。

```gdscript
# Global tuning knobs
var GLOBAL_DROP_RATE_MULT: float = 1.0    # All drop rates × this value
var GLOBAL_QUANTITY_MULT: float = 1.0    # All quantities × this value
```

**公式更新**：

```
drop_probability = BASE_DROP_RATE × rarity_modifier × GLOBAL_DROP_RATE_MULT
drop_count = floor(base_drop × resource_multiplier × GLOBAL_QUANTITY_MULT)
```

---

### States and Transitions

资源掉落系统是事件驱动系统，无持久运行时状态。每次block_destroyed信号触发独立的计算流程。

**Signal-Driven Execution Flow**:

| Step | Trigger | Action | Output |
|------|---------|--------|--------|
| 1 | `block_destroyed` signal received | Extract tile_type_id, cell_coords | — |
| 2 | BlockTypeDB query | Get resource_type_id, resource_multiplier | — |
| 3 | ResourceDB query | Get rarity, max_stack_size, display_name | — |
| 4 | Rarity gate check | RNG test drop_probability | pass/fail |
| 5 | Quantity calculation | Apply drop formula | drop_count (1-10) |
| 6 | Entity spawn | Create ResourceEntity, emit signal | `resource_spawned` |

---

### Interactions with Other Systems

| System | Direction | Data Interface | Nature |
|--------|-----------|----------------|--------|
| **方块挖掘系统 (#12)** | IN | `block_destroyed(tile_type_id, cell_coords)` | Signal listener |
| **方块类型数据库 (#2)** | IN | `get_resource_data(tile_type_id)` → returns resource_type_id, multiplier | Query API |
| **资源数据库 (#3)** | IN | `get_resource_info(resource_id)` → returns rarity, max_stack_size, display_name | Query API |
| **TileMap世界系统 (#1)** | IN | `CELL_SIZE` constant (32 px) | Constant reference |
| **玩家背包系统 (#28)** | OUT | `resource_spawned(resource_id, quantity, position)` | Signal emitter |
| **战车仓库系统 (#29)** | OUT | `resource_spawned` (same signal, different receiver) | Signal emitter |
| **搜刮交互系统 (#31)** | OUT | `resource_spawned` → pickupable entities | Signal emitter |

## Formulas

### Formula 1: Drop Probability (Rarity Gate)

`drop_probability = BASE_DROP_RATE × rarity_modifier × GLOBAL_DROP_RATE_MULT`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `BASE_DROP_RATE` | — | float | 1.0 | 基础掉落率，固定为100% |
| `rarity_modifier` | — | float | 0.03-1.0 | 稀有度修正，继承自资源数据库 |
| `GLOBAL_DROP_RATE_MULT` | GDR | float | 0.5-2.0 | 全局掉落率倍率调优参数 |

**Output Range:** 0.03 (legendary × 1.0 × 1.0) to 1.0 (common × 1.0 × 1.0) per block

**Example:** 古代秘银 (rarity=4 → modifier=0.1), GLOBAL_DROP_RATE_MULT=1.0 → drop_probability = 0.1 (10%)

---

### Formula 2: Drop Quantity

`drop_count = max(1, floor(base_drop × resource_multiplier × GLOBAL_QUANTITY_MULT))`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `base_drop` | — | int | 1 | 基础掉落单位，固定值 |
| `resource_multiplier` | RM | float | 0.5-10.0 | 方块产出倍率，来自BlockTypeDB |
| `GLOBAL_QUANTITY_MULT` | GQM | float | 0.5-2.0 | 全局数量倍率调优参数 |

**Output Range:** 1 (保底) to 20 (10 × 2.0) per successful drop

**Example:** 古代秘银 multiplier=3.0, GQM=1.0 → drop_count = floor(1 × 3.0 × 1.0) = 3

**Boundary Tests:**

| Case | base_drop | multiplier | GQM | drop_count |
|------|-----------|------------|-----|------------|
| 最小产出（保底） | 1 | 0.5 | 1.0 | max(1, 0) = 1 |
| 铁矿标准 | 1 | 1.0 | 1.0 | 1 |
| 煤矿高产出 | 1 | 1.5 | 1.0 | 1 |
| 古代秘银稀有 | 1 | 3.0 | 1.0 | 3 |
| 满倍率产出 | 1 | 10.0 | 2.0 | 20 |

---

### Formula 3: World Position Calculation

`world_pos = Vector2(cell_x × CELL_SIZE + offset_x, cell_y × CELL_SIZE + offset_y)`

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `cell_x` | int | -1000 to +1000 | 方块单元格X坐标 |
| `cell_y` | int | -1000 to +1000 | 方块单元格Y坐标 |
| `CELL_SIZE` | int | 32 | 单元格像素尺寸（来自entities.yaml） |
| `offset_x` | float | -8 to +8 | 随机偏移避免堆叠 |
| `offset_y` | float | -8 to +8 | 随机偏移避免堆叠 |

**Output Range:** World position in pixels

**Example:** cell_coords=(50, 30), offset=(4, -3) → world_pos = (1604, 957)

## Edge Cases

1. **If `resource_type_id = 0` (no resource defined)**: Skip all drop calculations, emit no signal. Rationale: Block type explicitly has no resource output (e.g., plain stone, dirt).

2. **If `resource_multiplier = 0.0`**: Treat as invalid configuration, force `drop_count = 0`. Log warning `"BlockType [tile_type_id] has resource_type_id > 0 but multiplier = 0.0"`.

3. **If drop_probability check fails**: Do not generate resource entity. Emit `resource_spawn_failed(cell_coords)` signal for debugging (optional).

4. **If drop_count exceeds `max_stack_size`**: Split into multiple resource entities. Example: drop_count=15, max_stack_size=10 → spawn 2 entities (quantity=10, quantity=5).

5. **If multiple blocks destroyed simultaneously (batch damage)**: Process sequentially, respect frame budget. If queue exceeds `MAX_DROPS_PER_FRAME` (tuning knob), defer remaining to next frame.

6. **If BlockTypeDB query returns null**: Treat as `resource_type_id = 0`, skip drop. Log error `"BlockType [tile_type_id] not found in database"`.

7. **If ResourceDB query returns null**: Skip drop, log error `"Resource [resource_id] not found in database"`.

8. **If RNG produces exact threshold value (e.g., 0.1 for epic)**: Use `<` comparison, not `<=`. Exact threshold value = fail. Ensures 10% means "strictly less than 0.1".

9. **If offset calculation produces identical positions**: Add sequential offset. First drop at center, subsequent at center+(4,0), center+(0,4), center+(-4,0), etc.

10. **If GLOBAL_DROP_RATE_MULT = 0.0**: All drops disabled. Use for special events (e.g., no-drop tutorial area).

11. **If GLOBAL_QUANTITY_MULT set below 1.0**: Drops become scarcer. Minimum of 1 enforced by `max(1, ...)` formula.

12. **If cell_coords outside world bounds**: Validate before processing. If invalid, skip drop and log warning.

## Dependencies

### Upstream Dependencies (Required)

| System | ID | Status | Data Flow | Interface |
|--------|----|---------|-----------|-----------|
| **方块类型数据库** | #2 | Designed | `get_resource_data(tile_type_id)` → returns resource_type_id, resource_multiplier | Query API |
| **资源数据库** | #3 | Designed | `get_resource_info(resource_id)` → returns rarity, max_stack_size, display_name, drop_weight | Query API |
| **方块挖掘系统** | #12 | Approved | Emits `block_destroyed(tile_type_id, cell_coords, destroyer_id)` | Signal source |
| **TileMap世界系统** | #1 | Designed | `CELL_SIZE` constant = 32 | Constant reference |

### Downstream Dependents (Consumers)

| System | ID | Status | Data Flow | Interface |
|--------|----|---------|-----------|-----------|
| **玩家背包系统** | #28 | Not Started | Receives `resource_spawned(resource_id, quantity, position)` | Signal consumer |
| **战车仓库系统** | #29 | Not Started | Receives `resource_spawned` (same signal) | Signal consumer |
| **搜刮交互系统** | #31 | Not Started | Receives `resource_spawned`, handles pickup interaction | Signal consumer |

### Dependency Nature

| Dependency | Nature | Without it... |
|------------|--------|---------------|
| 方块类型数据库 | **Hard** | Cannot determine what resource to drop |
| 资源数据库 | **Hard** | Cannot determine drop probability or stack limits |
| 方块挖掘系统 | **Hard** | No trigger for drop events |
| TileMap世界系统 | **Hard** | Cannot calculate world positions |

### Provisional Dependencies (None)

All upstream dependencies are designed and approved. No provisional assumptions required.

## Tuning Knobs

| Knob ID | Knob Name | Value | Range | Affects | Notes |
|---------|-----------|-------|-------|---------|-------|
| **TK-001** | `GLOBAL_DROP_RATE_MULT` | 1.0 | 0.5-2.0 | All drop probabilities | ×2.0 = 所有稀有资源掉落率翻倍；×0.5 = 稀有资源更稀缺 |
| **TK-002** | `GLOBAL_QUANTITY_MULT` | 1.0 | 0.5-2.0 | All drop quantities | ×2.0 = 所有产出量翻倍；×0.5 = 资源产出减半 |
| **TK-003** | `MAX_DROPS_PER_FRAME` | 20 | 10-100 | Batch processing limit | 防止大量方块同时破坏时的帧率掉落 |
| **TK-004** | `DROP_OFFSET_RANGE` | 8 | 4-16 | Resource entity spawn offset | 像素范围，避免多掉落堆叠 |
| **TK-005** | `BASE_DROP_RATE` | 1.0 | 1.0 (fixed) | Base probability before rarity | MVP固定为100%，未来可扩展为区域/难度修正 |

### Knob Interactions

- **`GLOBAL_DROP_RATE_MULT` × `rarity_modifier`** — 最终掉落概率 = 基础率 × 稀有度 × 全局倍率（高全局倍率让稀有资源更容易获取）
- **`GLOBAL_QUANTITY_MULT` × `resource_multiplier`** — 最终产出量 = 基础 × 方块倍率 × 全局倍率（高全局倍率让每个方块产出更多）
- **`MAX_DROPS_PER_FRAME`** — 批量掉落时的帧预算控制（超出部分延迟到下一帧）

### Tuning Validation Advisory

> **⚠️ Playtest Required**: 当前默认值（GLOBAL_DROP_RATE_MULT=1.0, GLOBAL_QUANTITY_MULT=1.0）可能需要根据实际探索体验调整：
> - 如果稀有资源（古代秘银）获取太困难 → 提高GLOBAL_DROP_RATE_MULT到1.5-2.0
> - 如果基础资源（铁矿）产出太少影响建造 → 提高GLOBAL_QUANTITY_MULT到1.2-1.5
> - 如果探索收益感太低 → 检查rarity_modifier配置是否过于严苛

## Visual/Audio Requirements

资源掉落系统是纯数据层，无直接视觉/音频需求。视觉反馈由下游消费系统（玩家背包拾取UI、战车仓库存储动画）呈现。

**间接视觉需求（由资源实体驱动）**：
- 资源实体图标：继承ResourceDB的`icon_path`字段
- 拾取反馈：搜刮交互系统处理视觉动画（发光、飞向玩家）

**无系统专属音效需求。**

## UI Requirements

资源掉落系统无直接UI需求。掉落结果由下游系统呈现：
- 拾取提示：搜刮交互系统显示"获得 [资源名] ×N"
- 仓库容量：战车仓库系统显示存储状态

**无系统专属UI需求。**

## Acceptance Criteria

### Core Rule Coverage

**AC-01**: GIVEN block_destroyed signal with tile_type_id=500 (iron_ore), WHEN drop calculation executes, THEN drop_probability=1.0 (rarity=1), drop_count=floor(1×1.0×1.0)=1.

**AC-02**: GIVEN block_destroyed signal with tile_type_id=710 (ancient_mithril), WHEN drop calculation executes, THEN drop_probability=0.1 (rarity=4), drop_count=floor(1×3.0×1.0)=3 on success.

**AC-03**: GIVEN block_destroyed signal with tile_type_id=100 (surface_stone, resource_type_id=0), WHEN drop calculation executes, THEN no resource_spawned signal emitted.

**AC-04**: GIVEN resource_type_id=301 (mithril) with rarity_modifier=0.1, WHEN RNG roll=0.05 (< 0.1), THEN drop succeeds, entity spawned.

**AC-05**: GIVEN resource_type_id=302 (ancient_mithril) with rarity_modifier=0.03, WHEN RNG roll=0.05 (> 0.03), THEN drop fails, no entity spawned.

### Formula Coverage

**AC-06**: GIVEN drop_count calculation with multiplier=3.0, GQM=1.0, THEN result=floor(1×3.0×1.0)=3.

**AC-07**: GIVEN drop_count calculation with multiplier=0.5, GQM=1.0, THEN result=max(1, floor(0.5))=1 (保底机制生效).

**AC-08**: GIVEN world_pos calculation with cell_coords=(50, 30), CELL_SIZE=32, offset=(4, -3), THEN result=(1604, 957).

### Edge Case Coverage

**AC-09**: GIVEN resource_type_id > 0 AND resource_multiplier=0.0, WHEN drop calculation executes, THEN drop_count=0, warning logged.

**AC-10**: GIVEN BlockTypeDB query returns null for tile_type_id, WHEN drop calculation executes, THEN treated as resource_type_id=0, no signal emitted, error logged.

**AC-11**: GIVEN drop_count=15 and max_stack_size=10, WHEN entity generation executes, THEN 2 entities spawned (quantity=10, quantity=5).

**AC-12**: GIVEN multiple block_destroyed events exceeding MAX_DROPS_PER_FRAME, WHEN processing executes, THEN first 20 processed, remaining deferred to next frame.

### System Integration Coverage

**AC-13**: GIVEN block_destroyed signal received, WHEN all dependencies available, THEN resource_spawned signal emitted within same frame.

**AC-14**: GIVEN Global tuning knobs modified (GDR=2.0, GQM=1.5), WHEN drop calculation executes, THEN probabilities and quantities reflect modified values.

**AC-15**: GIVEN CELL_SIZE constant from entities.yaml=32, WHEN world_pos calculation executes, THEN position matches expected cell center.

## Open Questions

| ID | Question | Owner | Target Resolution | Notes |
|----|----------|-------|-------------------|-------|
| **Q-001** | 是否需要支持多资源掉落表（同一方块产出多种资源）？MVP采用单资源模型，Vertical Slice是否需要扩展？ | Game Designer | Vertical Slice前 | 影响数据结构扩展（drop_table数组） |
| **Q-002** | 运气修正（luck_modifier）是否在MVP启用？当前固定为1.0，未来可能与战车改装或科技解锁关联。 | Game Designer | Alpha里程碑 | 影响公式复杂度和战车改装系统接口 |
| **Q-003** | drop_probability失败时是否需要播放"失败"视觉反馈？当前静默处理，玩家可能困惑为何挖到矿脉却无产出。 | UX Designer | UX spec阶段 | 影响搜刮交互系统设计 |
| **Q-004** | 全球掉落倍率是否需要区域差异（深层区域掉落率更高）？当前为全局单一值。 | Level Designer | 区域系统设计时 | 影响探索风险/收益平衡 |