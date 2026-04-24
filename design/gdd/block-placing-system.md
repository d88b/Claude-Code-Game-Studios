# 方块放置系统

> **Status**: Approved
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 2 (搜打撤节奏), Pillar 3 (尸潮即高潮)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #13 (from systems-index.md)

## Overview

方块放置系统是玩家建造行为的核心执行层——玩家选择建造物品、确认目标位置、系统验证放置条件、扣除材料、在TileMapLayer Layer 2写入方块实例、同步更新碰撞形状。它将**建造物品数据库**的配方数据转化为世界中实际存在的方块实体，将**TileMap世界系统**的cell操作转化为物理上可碰撞的建筑物，将**建造验证系统**的规则检查转化为建造许可/拒绝的决策输出。

**基础设施角色**：系统管理放置流程的状态机（Select→Validate→Commit→Place），执行材料消耗扣除，协调TileMapLayer API调用，确保放置操作遵循物理帧边界（通过`queue_tile_modification`队列）。每个放置操作创建一个TileMapLayer cell实例，该实例继承BlockTypeDatabase定义的属性，并附加运行时状态。

**玩家影响层**：建造是玩家塑造世界空间的唯一方式。玩家直接感知：
- **决策压力**：选择建造哪个物品（墙vs炮塔vs陷阱）涉及材料预算和防守策略——服务于Pillar 2（搜打撤节奏）和Pillar 3（尸潮即高潮）
- **即时反馈**：放置成功产生音效、粒子爆发、建筑出现；放置失败产生拒绝反馈和原因提示
- **空间所有权感**：每次放置都在世界网格上留下玩家标记——"这是我建的"

**核心价值**：没有方块放置系统，世界只能被挖掘（破坏），无法被建设（创造）；有了它，玩家才能建造防御墙、布置炮塔、扩展地堡、规划防守布局。放置创造**结构**——地堡从洞穴变为玩家设计的防守阵地。

## Player Fantasy

### 核心幻想：防线编织者 — 在崩溃边缘编织生存

玩家是废土防线编织者，用手中最珍贵的资源——时间和材料——在尸潮来临前的紧迫窗口中**编织生存边界**。建造不是从容的规划，而是**高压下的创世行为**：材料库存转化为决策筹码，倒计时转化为紧迫感，每一块放置的墙都在回答"这道防线撑得住吗？"

**锚定时刻：黄昏前的最后一块墙**

防守倒计时还有23秒。远处尸群的低吼已经传来。你站在地堡外围缺口前，库存里只剩3个劣质钢材和1个符文核心。菜单里两个选项：**魔力墙**（需要3铁+1晶，硬度150）还是**符文炮塔**（需要2铁+1晶，伤害输出型）？你只有一次选择机会。手指悬在按钮上方。你选择了墙。第一只尸尸撞击它时，距离倒计时结束还有3秒。墙震了一下——但撑住了。你长出一口气。

**玩家应该感受到**：
- **紧迫中的掌控感**：每次成功放置都是在倒计时终结前夺取主动权
- **被验证的庆幸感**：当墙撑住尸潮冲击时，"我做了正确的选择"
- **失误的代价感**：当墙崩溃时，"我低估了"——归因指向自己的决策，而非系统惩罚

**失败时的感觉**：
墙的裂缝在蔓延。你有两个选择：花更多材料加固，还是放弃这道防线撤退到第二层。不管怎么选，**损失都是真实的**。材料没了，防线弱了。玩家不会说"建造系统有问题"——他们会说"我赌错了"。这种归因是设计成功的标志。

**服务于支柱**：
- Pillar 2（搜打撤节奏）：建造时间倒计时创造"最后冲刺"的紧张决策窗口
- Pillar 3（尸潮即高潮）：每块放置的墙都是尸潮冲击的直接承受者——玩家的创造物成为战场主角
- Pillar 4（魔导科技美学）：建造物品的命名（符文炮塔、魔力屏障墙、秘银加固墙）和视觉反馈（符文发光、魔力脉冲）强化魔导科技世界观

## Detailed Design

### Core Rules

**Rule 1: Input Detection and Build Mode**

玩家必须处于建造模式才能执行放置操作：

1. 玩家从hotbar选择建造物品 → 进入Build Mode
2. Build Mode激活时，显示ghost preview（半透明方块预览）跟随鼠标位置
3. 按下Left Mouse Button → 触发放置流程
4. 松开Build Mode → 取消当前选择，返回IDLE状态

**Rule 2: Target Selection**

鼠标位置转换为cell坐标：

1. 获取全局鼠标位置：`get_global_mouse_position()`
2. 转换为cell坐标：`structures_layer.local_to_map(global_mouse_pos)`
3. 存储`target_cell = Vector2i(x, y)`
4. Ghost preview实时更新至target_cell位置

**Rule 3: Pre-Placement Validation Chain**

所有验证必须通过（按优先级顺序，early exit）：

| Check | Condition | Failure Message |
|-------|-----------|-----------------|
| V1 | Cell在MAX_WORLD_BOUNDS内 | "超出世界边界" |
| V2 | Layer 2 cell为空 | "位置已被占用" |
| V3 | distance(player_pos, cell) ≤ MAX_PLACE_RANGE×CELL_SIZE | "超出放置范围" |
| V4 | output_tile_id.buildability=1 | "此方块不可建造" |
| V5 | Category-specific rules pass | "位置条件不满足" |
| V6 | Player inventory ≥ material_costs[] | "材料不足: [缺失列表]" |

**Rule 4: Material Consumption and Construction Start**

验证通过后执行材料扣除和建造进度启动：

1. 遍历`material_costs[]`，每个`(resource_id, amount)`从inventory扣除（原子操作）
2. 扣除操作不可分割——任一材料不足则整个操作失败
3. 启动建造进度计时器：从`BuildItemDB.get_build_time(build_item_id)`获取建造时长
4. 建造进度条开始显示，状态进入BUILDING
5. 建造时间范围：基础物品 3-5 秒，高级物品 15-30 秒（参照 BuildItemDB 定义）
6. 若建造被中断或取消，执行 Rule 7 的材料返还逻辑

**Rule 5: Tile Creation (Physics-Safe, After Construction)**

建造进度完成后，使用 TileMapLayer API 创建方块（deferred to physics frame）：

1. 当 `construction_progress >= build_time_seconds` 时，触发放置完成
2. 调用 `BlockCollision.queue_tile_modification(target_cell, LAYER_STRUCTURES, SET, {source_id, atlas_coords, alternative_tile})`（扩展接口，见方块碰撞系统 GDD）
3. 修改排队至下一物理帧边界执行（与 BlockDiggingSystem 模式一致）
4. Godot TileMapLayer 自动同步 collision shape（无需手动创建）
5. 发射信号 `block_placed(cell, tile_id, player_id)` 通知下游系统（通过 call_deferred 在物理帧边界后发射）

**Rule 6: Category-Specific Placement Requirements**

| Category | Requirement | Validation |
|----------|-------------|------------|
| `floor(4)` | 无要求 | 可放置于任意空Layer 2 cell |
| `wall(0)` | 相邻支持 | 四方向邻居中至少有一个floor或wall |
| `turret(1)` | Floor基础 | 同cell的Layer 1必须有floor tile |
| `trap(2)` | Floor基础 | 同cell的Layer 1必须有floor tile |
| `facility(3)` | Floor基础 | 同cell的Layer 1必须有floor tile |

**Rule 7: Cancellation and Refund**

建造进度进行中玩家可取消建造：

1. **取消时机**：建造进度进行中（BUILDING state）玩家按 Escape 或切换选择
2. **Material refund**：100%返还所有已扣除材料（MVP政策，见 Tuning Knobs 讨论）
3. **清理**：移除 ghost preview，清除进度条，发射 `build_cancelled(cell, build_item_id)` 信号
4. **Progress loss**：建造进度不保存，下次建造从 0% 开始

### States and Transitions

| State | Entry | Exit | Actions |
|-------|-------|------|---------|
| **IDLE** | 无建造物品选择 | 玩家选择物品 | 清除ghost preview |
| **SELECTING** | 物品在手中 | 玩家点击放置 → VALIDATE | Ghost preview跟随cursor |
| **VALIDATE** | 点击检测 | 所有check通过 → COMMIT / 失败 → FAILED | 执行V1-V6检查 |
| **VALIDATE** | 点击检测 | 所有check通过 → COMMIT / 失败 → FAILED | 执行V1-V6检查 |
| **FAILED** | 验证失败 | 反馈显示，返回SELECTING | 播放失败音效，显示原因 |
| **COMMIT** | 验证通过 | 材料扣除 → BUILDING | 原子扣除materials，启动建造计时 |
| **BUILDING** | 建造进度进行中 | progress >= build_time → PLACE / 取消 → CANCELLED | 显示进度条，每帧累加progress |
| **CANCELLED** | 玩家取消建造 | 材料返还 → IDLE | 100% refund，清除进度，发射build_cancelled |
| **PLACE** | 建造完成 | Tile创建排队 | 调用queue_tile_modification(operation=SET) |
| **COMPLETE** | Tile放置完成 | 信号发射 → SELECTING | 通过call_deferred发射block_placed |

### Interactions with Other Systems

| System | Data Flow | Interface |
|--------|-----------|-----------|
| **TileMap世界系统** | 读取：Layer 1/2 cell状态 | `get_cell_tile_data(coords)` → TileData or null |
| **建造物品数据库** | 读取：build_item定义、material_costs、output_tile_id | `BuildItemDB.get_build_item(build_item_id)` → BuildItem struct |
| **BlockTypeDatabase** | 读取：buildability、collision_shape | `BlockTypeDB.get_by_tile_id(tile_id)` → BlockType struct |
| **战车仓库系统/玩家背包** | 读取：材料库存<br>写入：材料扣除/返还 | `inventory.get_quantity(resource_id)` → int<br>`inventory.remove(resource_id, amount)`<br>`inventory.add(resource_id, amount)` (refund) |
| **方块碰撞系统** | 写入：queue_tile_modification(SET operation) | `BlockCollision.queue_tile_modification(cell, layer, SET, {source_id, atlas_coords, alternative_tile})` — 扩展接口 |
| **炮塔系统** | 触发：turret category放置完成 | `block_placed`信号→炮塔系统初始化炮塔实体 |
| **音效系统** | 触发：放置成功/失败音效 | `AudioSystem.play_place_success()`<br>`AudioSystem.play_place_failed()` |

## Formulas

### Range Validation Formula

```
distance_squared = (player_x - cell_center_x)² + (player_y - cell_center_y)²
is_in_range = distance_squared <= (MAX_PLACE_RANGE * CELL_SIZE)²
```

**Variables:**

| Variable | Type | Unit | Source | Range |
|----------|------|------|--------|-------|
| `player_x, player_y` | float | pixels | Player transform | World bounds |
| `cell_center_x, cell_center_y` | float | pixels | Cell center position | World bounds |
| `MAX_PLACE_RANGE` | float | cells | Config constant | 5.0 (fixed) |
| `CELL_SIZE` | int | pixels | TileMap世界系统 | 32 (from registry) |

**Output:** `is_in_range` ∈ {true, false}

**Example:**
```
player_pos = (480, 320), target_cell = (15, 10), CELL_SIZE = 32
cell_center = (15×32+16, 10×32+16) = (496, 336)
distance_squared = (480-496)² + (320-336)² = 256+256 = 512
max_range_squared = (5×32)² = 160² = 25600
is_in_range = 512 <= 25600 → true (distance ≈ 22.6 px, well within 160 px)
```

**Optimization Note:** Use squared distance comparison to avoid sqrt() per-frame. Only compute actual distance for UI display if needed.

---

### Cell Coordinate Conversion Formula

```
cell_coords = Vector2i(floor(world_pos.x / CELL_SIZE), floor(world_pos.y / CELL_SIZE))
cell_center = Vector2((cell_coords.x + 0.5) * CELL_SIZE, (cell_coords.y + 0.5) * CELL_SIZE)
```

**Variables:**

| Variable | Type | Unit | Source | Range |
|----------|------|------|--------|-------|
| `world_pos` | Vector2 | pixels | Mouse/player position | World bounds |
| `CELL_SIZE` | int | pixels | TileMap世界系统 | 32 (from registry) |

**Output:** `cell_coords` ∈ Vector2i (integer grid coordinates)

**Godot Implementation:**
```gdscript
# Use TileMapLayer built-in methods, not manual calculation
var cell_coords: Vector2i = structures_layer.local_to_map(global_mouse_pos)
var cell_center: Vector2 = structures_layer.map_to_local(cell_coords) + Vector2(CELL_SIZE/2, CELL_SIZE/2)
```

---

### Material Sufficiency Formula

```
can_afford = ∀i: inventory[resource_id[i]] >= amount[i]
```

Where `material_costs[]` = array of `{resource_id: int, amount: int}` pairs.

**Variables:**

| Variable | Type | Unit | Source | Range |
|----------|------|------|--------|-------|
| `inventory[resource_id]` | int | count | 战车仓库系统 | 0-MAX_STACK |
| `material_costs[]` | Array | pairs | 建造物品数据库 | Per-item definition |

**Example:**
```
wall_basic material_costs = [{resource_id: 110 (stone), amount: 5}, {resource_id: 120 (wood), amount: 3}]
inventory = {stone: 12, wood: 2, iron: 5}
can_afford = (12>=5) AND (2>=3) → false (wood insufficient)
```

---

### Boundary Case Summary

| Boundary | Formula Impact | Handling |
|----------|---------------|----------|
| world_pos outside MAX_WORLD_BOUNDS | cell_coords outside ±1000 | V1 check: reject immediately |
| cell_coords negative | Valid if within bounds | Godot TileMap supports negative coords |
| CELL_SIZE mismatch | Distance calc wrong | Use registry value (32), never hardcode |
| material_costs empty array | Free placement | Skip material validation (V6) |
| inventory = 0 for required material | can_afford = false | V6 check: reject with "材料不足" |

## Edge Cases

### 1. Validation Chain Edge Cases

**If two validation checks fail simultaneously**: Return first failure in priority order (V1→V2→V3→V4→V5→V6). Early exit prevents wasted computation and gives deterministic error messages.

**If player at exactly MAX_PLACE_RANGE distance**: `distance <= MAX_PLACE_RANGE` is **inclusive**. 5 cells exactly (160px) is valid placement. Player expectation: "5 range means 5 cells".

**If material deducted then validation fails during physics frame**: Materials are deducted at validation start, but full V1-V6 chain is **re-executed on physics frame** before tile creation. If any check fails, refund materials and emit `placement_cancelled` signal. Do NOT silently drop placement.

---

### 2. Category-Specific Requirement Edge Cases

**If floor destroyed under turret (support removal)**:
- **MVP behavior**: Turret remains but enters DISABLED state (non-functional). Emits `structure_unsupported` warning signal.
- **Post-MVP**: Turret collapses after 5-second grace period if floor not restored.
- Rationale: Immediate deletion feels unfair; grace period allows re-flooring.

**If wall's adjacent support is destroyed**: Wall remains. Placement requires adjacency, but **existence does not require ongoing support**. Cascading wall collapse is complex and punishing—simpler rule: once placed, wall is self-supporting.

**If trap placed on cell with enemy present**: Placement allowed. Trap is non-blocking occupancy—enemy takes immediate damage on trap activation. Traps check occupancy for *blocks* (walls, facilities), not for *enemies*.

---

### 3. Material Handling Edge Cases

**If inventory changes after material deduction**: Deduction is atomic and final at validation start. External inventory changes don't affect in-progress placement. Refund returns **original deducted amount**, not percentage of current inventory.

**If inventory full when refund needed**:
1. Try adding to existing stack
2. Try expanding stack (if stack limit allows)
3. Drop materials on ground at player position

Never lose player materials—ground drop is safety valve.

**If material cost changes during placement (hotfix)**: Cost is captured at validation start. Cost change mid-frame doesn't affect in-progress placements. New costs apply to next placement attempt.

---

### 4. Ghost Preview Edge Cases

**If preview shows valid but click triggers invalid (race condition)**: Click validation is **authoritative**, not preview state. Preview is helpful UI, not guarantee. If preview was green but click validation fails, show error feedback (sound, flash, message). Do not place.

**If hotbar switch doesn't update ghost**: Hotbar selection change triggers immediate ghost rebuild. Old ghost entity destroyed, new ghost entity created for newly selected block type. This is a UI bug if stale.

---

### 5. Physics Frame Boundary Edge Cases

**If player moves out of range during queue**: V3 (range check) uses player position at **physics frame execution time**, not click time. Queue stores target position; re-validates with current player position. Prevents "sniping" placements beyond range via movement exploits.

**If player dies during placement queue**: Cancel placement, refund materials, discard queued modification. Dead players cannot place blocks. Check player entity validity before executing queued modification.

**If two players target same cell simultaneously (multi-player edge case)**: First queued modification wins. Second fails V2 (occupancy) on re-validation, refunds materials, emits `placement_failed — cell occupied`. MVP is single-player; this is Alpha scope for co-op.

---

### 6. Multi-Cell Footprint Edge Cases (Post-MVP)

**If partial overlap with existing structure**: All footprint cells must pass all V checks. Single failure aborts entire placement. Ghost preview highlights invalid cells specifically.

**If footprint spans chunk boundary**: Placement validation is coordinate-agnostic. Chunk boundaries are rendering/loading concerns, not placement concerns. If chunks are loaded for player to see, they're valid for placement.

## Dependencies

### Upstream Dependencies

| System | Layer | Data Provided | Interface | Dependency Type |
|--------|-------|---------------|-----------|-----------------|
| **TileMap世界系统** | Foundation | Layer 1/2 cell state, coordinate conversion | `get_cell_tile_data(coords)` → TileData<br>`world_to_cell(pos)` → Vector2i<br>`cell_to_world_center(cell)` → Vector2 | **Blocking** — Cannot place without world state |
| **方块碰撞系统** | Core | Physics-safe modification queue (extended interface) | `queue_tile_modification(coords, operation, tile_data)` — supports SET/DELETE | **Blocking** — Cannot safely create tiles without queue |
| **建造物品数据库** | Foundation | Build item definitions: output_tile_id, material_costs[], category, build_time_seconds | `BuildItemDB.get_build_item(build_item_id)` → BuildItem struct | **Blocking** — Cannot determine placement rules without item data |
| **BlockTypeDatabase** | Foundation | Tile properties: buildability, collision_shape, hardness | `BlockTypeDB.get_by_tile_id(tile_id)` → BlockType struct | **Blocking** — Cannot validate buildability without tile data |
| **战车仓库系统/玩家背包** | Feature | Material inventory: current quantities, deduct/add operations | `inventory.get_quantity(resource_id)` → int<br>`inventory.remove(resource_id, amount)` → bool<br>`inventory.add(resource_id, amount)` | **Blocking** — Cannot consume materials without inventory |
| **输入控制系统** | Foundation | Build mode toggle, hotbar selection, mouse click detection | `InputControl.is_build_mode_active()` → bool<br>`InputControl.get_selected_build_item()` → int | **Blocking** — Cannot respond to input without input system |
| **建造验证系统** | Feature | Placement condition validation (provisional rules) | See Core Rules V1-V6 — **Provisional** (system not yet designed) | **Soft** — MVP uses provisional rules; future: dedicated validation system |

### Downstream Dependent Systems

| System | Layer | Data Consumed | Interface Provided | Dependency Type |
|--------|-------|---------------|-------------------|-----------------|
| **炮塔系统** | Core | Turret tile placement event for entity initialization | Signal: `block_placed(cell, tile_id, player_id)` → turret system initializes turret entity if category=turret | **Blocking** — Turret system expects placement signal |
| **陷阱系统** | Core | Trap tile placement event | Signal: `block_placed(cell, tile_id, player_id)` → trap system initializes trap entity | **Indirect** — Trap system needs placement trigger |
| **地堡设施系统** | Feature | Facility tile placement event | Signal: `block_placed(cell, tile_id, player_id)` → facility system initializes facility entity | **Indirect** — Facility system needs placement trigger |
| **音效系统** | Presentation | Placement success/failure sound triggers | `AudioSystem.play_place_success()`<br>`AudioSystem.play_place_failed()` | **Non-blocking** — Audio not required for gameplay |
| **HUD系统** | Presentation | Material cost display, build menu, ghost preview | Build menu provides build_item selection; ghost preview renders placement preview | **Non-blocking** — UI not required for core placement |

### Dependency Interface Contract

**Data Contract (从上游读取):**

| Interface | Return Type | Failure Mode | Consumer Contract |
|-----------|-------------|--------------|-------------------|
| `structures_layer.get_cell_tile_data(coords)` | TileData or null | Returns null for empty cell | Placement system checks `== null` for occupancy validation |
| `floors_layer.get_cell_tile_data(coords)` | TileData or null | Returns null for empty cell | Placement system checks `!= null` for floor requirement validation |
| `BuildItemDB.get_build_item(id)` | BuildItem struct | Returns null for invalid ID | Placement rejects if null; UI should prevent invalid selection |
| `BlockTypeDB.get_by_tile_id(id)` | BlockType struct | Returns null for invalid ID | Placement rejects if null or buildability=0 |
| `inventory.get_quantity(resource_id)` | int | Returns 0 for missing resource | Placement checks `>= amount` for material sufficiency |

**Trigger Contract (向下游发射):**

| Signal | When | Data Passed | Consumer Contract |
|--------|------|-------------|-------------------|
| `block_placed(cell, tile_id, player_id)` | On successful tile creation (after physics frame) | cell: Vector2i, tile_id: int, player_id: int | Turret/Trap/Facility systems initialize entities; Stats system tracks placement count |
| `placement_failed(cell, reason)` | On validation failure | cell: Vector2i, reason: String (error code) | UI displays error message; Stats system tracks failure count |
| `placement_cancelled(cell, reason)` | On physics-frame re-validation failure | cell: Vector2i, reason: String | UI displays cancellation feedback; Refund already processed |

### Provisional Dependency Notes

**建造验证系统 not yet designed**: This GDD incorporates provisional validation rules (V1-V6) as Core Rules. When 建造验证系统 is designed:
1. Migrate V1-V6 rules to that system's GDD
2. Update this GDD's Dependency section to reference 建造验证系统 as **Blocking** upstream
3. Update Interface table to call `ValidationSystem.validate_placement(build_item_id, cell)` instead of local validation logic

## Tuning Knobs

### Primary Tuning Knobs (影响放置决策)

| Knob | Current Value | Safe Range | Gameplay Effect | Pillar Affected |
|------|---------------|------------|-----------------|-----------------|
| **MAX_PLACE_RANGE** | 5.0 cells (160 px) | 3.0-10.0 cells | 放置距离限制。提高 → 玩家可更远程建造 → 防守规划灵活性增加。降低 → 需近距离建造 → 暴露风险增加 | Pillar 2: 搜打撤节奏 |
| **Material refund rate** | 100% | 50%-100% | 取消放置时的材料返还比例。100% → 鼓励尝试/撤销决策；<100% → 惩罚取消，增加承诺感 | Pillar 3: 尸潮即高潮 |

### Secondary Tuning Knobs (影响UI/反馈)

| Knob | Current Value | Safe Range | Gameplay Effect |
|------|---------------|------------|-----------------|
| **Ghost preview opacity** | 0.5 (50%) | 0.3-0.7 | 预览方块透明度。影响"即将建造"的视觉提示强度 |
| **Validation feedback duration** | 2.0 sec | 1.0-3.0 sec | 失败提示显示时间。太短 → 玩家错过原因；太长 → 干扰后续操作 |
| **Invalid cell highlight color** | Red (#FF0000) | Any high-contrast color | 无效位置的视觉标记颜色 |

### Cross-System Tuning Knobs (依赖其他系统)

| Knob | Owner System | Current Value | Effect on Placement |
|------|--------------|---------------|---------------------|
| **CELL_SIZE** | TileMap世界系统 | 32 px (registry) | 固定值。改变影响MAX_PLACE_RANGE像素计算和坐标转换 |
| **buildability flags** | BlockTypeDatabase | Per-tile definition | 定义哪些tile可建造。改变影响可用建造选项 |
| **material_costs[]** | 建造物品数据库 | Per-item definition | 每个建造物品的材料成本。改变影响经济决策 |
| **build_time_seconds** | 建造物品数据库 | Per-item definition (MVP: ignored) | 建造时间。MVP instant placement忽略此值；Post-MVP启用时影响防守倒计时紧张感 |

### Knobs That Should NOT Be Tuned

| Knob | Reason |
|------|--------|
| **Layer assignment (Layer 2 only)** | 架构约束。改变破坏世界层级逻辑。 |
| **Validation chain order (V1→V2→V3→V4→V5→V6)** | 逻辑约束。改变顺序可能产生不一致错误消息或性能问题。 |
| **Category-specific placement rules** | 设计决策。改变需要重新验证整个建造生态的合理性。 |

### Tuning Scenarios

**Scenario A: 放置太远 → 防守压力不足**
- Symptom: Player can build entire perimeter without approaching danger zones
- Adjustment: Reduce MAX_PLACE_RANGE from 5.0 to 3.0 cells
- Expected outcome: Player must get closer to place → exposure risk increases

**Scenario B: 放置太近 → 紧急建造困难**
- Symptom: Player dies while trying to place defensive wall near breach
- Adjustment: Increase MAX_PLACE_RANGE to 7.0 cells
- Expected outcome: Emergency fortification possible from safer distance

**Scenario C: 100% refund鼓励滥用**
- Symptom: Players spam-click to test placement, cancel frequently, no cost
- Adjustment: Reduce refund rate to 50%
- Expected outcome: Every placement attempt has cost → more deliberate decision-making

**Scenario D: 材料成本过低 → 防守无压力**
- Symptom: Players can build unlimited walls, no economic decision
- Adjustment: Not this system — adjust material_costs[] in BuildItemDB
- Expected outcome: See 建造物品数据库 tuning scenarios

## Visual/Audio Requirements

### Visual Requirements

| Requirement | Description | Implementation Owner |
|-------------|-------------|---------------------|
| **Ghost Preview** | Semi-transparent (55% opacity) block preview following cursor. Valid placement: green tint (#4AE090) with soft pulse. Invalid: red tint (#E05A5A) with static X icon overlay (WCAG-safe, no strobing). Grid-snapped to 32px cells. | UI System / Placement System |
| **Placement Success Animation** | Block spawns at 0.85 scale → ease-out to 1.0 over 150ms → impact frame (scale 1.08, 1 frame) → settle to 1.0. Dust particles (8-12, tan #B8A080) emit radially. Rune glow awakens over 600ms. | VFX System |
| **Placement Failure Animation** | Ghost flash red (#FF4444), shake ±3px horizontal for 100ms, fade out. Error particles (6-8, red #FF4444) emit radially. | VFX System |
| **Rune Glow (Magitech Accent)** | All placed structures show horizontal rune line at bottom edge, color varies by category: walls=#60D0FF (blue), turrets=#FF8040 (orange), traps=#A060FF (purple), facilities=#60FF90 (green). Pulse cycle 2s, alpha 50-75%. Idle spark particles every 10s when powered. | TileMap/VFX System |
| **Cursor Indicator** | Ghost preview anchors to cursor center-bottom, offset -8px from cell center. | UI System |

### Audio Requirements

| Event | Audio Type | Trigger Condition | Sound Bank |
|-------|------------|-------------------|------------|
| **Placement Success** | Impact "thunk" + crystalline shimmer | On tile creation confirmed | `sfx_build_place_success.wav` (0.3-0.5s, vol 0.7) |
| **Placement Failure** | Low "bup" error tone + buzz | On validation failure | `sfx_build_place_fail.wav` (0.15-0.25s, vol 0.5) |
| **Block Selection** | Quick metallic click | On hotbar selection | `sfx_build_select.wav` (0.1s, vol 0.4, pitch ±5%) |
| **Insufficient Materials** | Hollow "clink" | On material check fail | `sfx_build_no_resources.wav` (0.2s, vol 0.45) |

### Visual-Audio Integration Matrix

| State | Visual | Audio | Duration |
|-------|--------|-------|----------|
| Ghost Valid | Green tint, soft pulse | None | Continuous |
| Ghost Invalid | Red tint, static X icon overlay | None | Continuous |
| Place Success | Scale pop, dust particles, rune awaken | Impact + shimmer | 350ms total |
| Place Fail | Red flash, shake, error particles | Error tone | 250ms total |
| Rune Idle | Soft glow pulse (category color) | None | 2s cycle |

### Asset Requirements

| Asset | Count | Size | Source |
|-------|-------|------|--------|
| Ghost preview shader | 1 | Tint shader | VFX asset production |
| Dust particles spritesheet | 1 | 2x2 px squares | VFX asset production |
| Rune overlay patterns | 4 variants (wall/turret/trap/facility) | 4-8px tall overlay | TileSet extension |
| Audio samples | 4 (place_success, place_fail, select, no_resources) | WAV files | Audio asset production |

📌 **Asset Spec** — Visual/Audio requirements are defined. After the art bible is approved, run `/asset-spec system:block-placing-system` to produce per-asset visual descriptions, dimensions, and generation prompts from this section.

## UI Requirements

### HUD Elements

| Element | Position | Display Logic | Update Frequency |
|---------|----------|---------------|------------------|
| **Hotbar** | Bottom-center, 48px from edge | Visible when build mode active; 10 slots (64×64px), numbered 1-0 | On selection change |
| **Ghost Preview** | Following cursor/mouse position | Semi-transparent preview block; green for valid, red for invalid | Every frame |
| **Material Cost Tooltip** | Below ghost preview (8px gap) | Shows material icons + quantities; green ✓ for sufficient, red ✗ for insufficient | On item selection, after 300ms delay |
| **Error Message** | Top-center of screen | Slide-in message box with error title + description; auto-dismiss after 2.5s | On validation failure |
| **Distance Indicator** | Floating above ghost preview | Shows current distance in meters; green text within range, red text when exceeding MAX_PLACE_RANGE | Every frame |

### Hotbar Specification

```
Layout:
┌───┬───┬───┬───┬───┬───┬───┬───┬───┬───┐
│ 1 │ 2 │ 3 │ 4 │ 5 │ 6 │ 7 │ 8 │ 9 │ 0 │
└───┴───┴───┴───┴───┴───┴───┴───┴───┴───┘

Dimensions:
- Slot size: 64×64 px
- Gap: 4 px
- Background: RGBA(20, 20, 20, 180)
- Selected slot border: 3px solid #FFD200, subtle pulse (0.8s cycle)

Content per slot:
- Icon: 48×48 px, centered
- Quantity badge: Bottom-right, 20×20 px
- Disabled state: 40% opacity, grayscale filter
```

### Ghost Preview States

| State | Visual Treatment | Audio |
|-------|------------------|-------|
| **Valid** | Green tint (#4AE090), 55% opacity, soft pulse (1s cycle) | None |
| **Invalid** | Red tint (#E05A5A), 45° diagonal stripes, static X icon overlay (no shake) | None |
| **Out of Range** | Red tint + dashed border + distance text "7.5m (MAX: 5.0m)" | None |

### Error Message Format

| Error Type | Title | Description | Color |
|------------|-------|-------------|-------|
| `INSUFFICIENT_MATERIALS` | 材料不足 | "需要: {数量} {材料} (持有: {当前})" | Orange (#FF9500) |
| `POSITION_OCCUPIED` | 位置已占用 | "此位置已有方块" | Red (#FF3B30) |
| `OUT_OF_RANGE` | 超出范围 | "靠近后可建造 (距离: {d}m / 最大: {max}m)" | Red (#FF3B30) |
| `INVALID_POSITION` | 位置无效 | "此位置不可建造" | Red (#FF3B30) |

**Message Box Animation**: Slide in 200ms, hold 2.5s, fade out 500ms. Max 3 visible stacked vertically.

### Keyboard Accessibility

| Key | Action |
|-----|--------|
| `1-9, 0` | Select hotbar slot directly |
| `Tab` | Open/close full build menu |
| `W/A/S/D` | Move ghost preview cursor (keyboard-only mode) |
| `Shift+W/A/S/D` | Move cursor faster (5 cells per press) |
| `Space` | Place block at cursor position |
| `Escape` | Exit build mode |
| `Q/E` | Cycle through hotbar items |

**Keyboard Cursor Indicator**: Diamond-shaped cursor (32×32px) at target cell center, with subtle bob animation (2px, 1.5s cycle). Shake on movement attempt beyond bounds.

📌 **UX Flag — 方块放置系统**: This system has UI requirements. In Phase 4 (Pre-Production), run `/ux-design` to create a UX spec for the Build Menu and Ghost Preview HUD **before** writing epics. Stories that reference UI should cite `design/ux/build-mode.md`, not this GDD directly.

## Acceptance Criteria

### Core Mechanics Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-CR1** | Input detection registers single placement event per click | Press placement key while targeting valid cell, verify exactly one placement attempt registered | Input registered within 1 frame of event, no duplicate triggers |
| **AC-CR2** | Target selection converts mouse position to cell coords | Move cursor to screen position, verify target cell highlight updates | Cell highlighted within 16ms, matches expected grid coords |
| **AC-CR3** | Validation chain executes before tile modification | Trigger placement, verify validation returns result before any world change | Boolean result returned, no tile created on failure |
| **AC-CR4** | Material consumption is atomic | Place block costing N materials, verify exact N deducted and block appears | Inventory reflects N deduction, block exists at target cell |
| **AC-CR5** | Tile creation produces queryable entity | Place block at coords, verify TileMap query returns correct tile | `get_cell_tile_data(coords)` returns TileData with correct tile_id |
| **AC-CR6** | Category-specific rules execute independently | Attempt placement for each category, verify category check passes/fails per rules | Wall fails without support, turret fails without floor, floor always passes |
| **AC-CR7** | Cancellation returns 100% materials | Place block consuming N materials, cancel it, verify N materials restored | Inventory equals pre-placement state exactly |

---

### Validation Chain Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-V1** | Range validation uses inclusive bound | Test at distances 4.9, 5.0, 5.1 cells from player | 5.0 cells passes, 5.1 cells fails |
| **AC-V2** | Occupancy check detects existing blocks | Attempt placement on empty cell and on occupied cell | Empty passes, occupied fails with "位置已占用" message |
| **AC-V3** | Bounds check rejects out-of-world coords | Attempt placement at (MAX_WORLD_BOUNDS+1, 0) | Fails with "超出世界边界" message |
| **AC-V4** | Material check verifies all requirements | Test with exact materials, one short, excess | Exact passes, short fails with missing material listed, excess passes |
| **AC-V5** | Buildability check queries BlockTypeDB | Attempt placement with buildability=0 tile_id | Fails with "此方块不可建造" message |
| **AC-V6** | Category prerequisite validation | Test wall without adjacent support, turret without floor | Wall fails without adjacent floor/wall, turret fails without floor |

---

### Category Requirements Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-CAT-FLOOR** | Floor requires no prerequisites | Place floor on isolated empty cell | Placement succeeds |
| **AC-CAT-WALL** | Wall requires adjacent support | Place wall with no neighbors, with floor neighbor, with wall neighbor | No neighbors=fail, any neighbor=pass |
| **AC-CAT-TURRET** | Turret requires floor underneath | Place turret on empty cell, on floor tile | Empty=fail, floor=pass |
| **AC-CAT-TRAP** | Trap requires floor underneath | Place trap on empty cell, on floor tile | Empty=fail, floor=pass |
| **AC-CAT-FACILITY** | Facility requires floor underneath | Place facility on empty cell, on floor tile | Empty=fail, floor=pass |

---

### Edge Case Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-EC1** | Validation chain short-circuits on first failure | Trigger V1 failure, verify V2-V6 not executed | Returns "超出范围" error within 1ms, no subsequent checks |
| **AC-EC2** | Material deduction atomic on failure | Force tile creation to fail after material deduction | Materials not deducted (transaction rolled back) |
| **AC-EC3** | Ghost preview at exact range boundary | Hover at 5.0 cells, then at 5.01 cells | 5.0 shows green (valid), 5.01 shows red (invalid) |
| **AC-EC4** | Ghost preview shows material insufficiency | Select wall with insufficient materials, hover valid cell | Ghost shows red/invalid state, cost display shows shortage |
| **AC-EC5** | Physics frame safety on rapid placement | Queue 10 placements in single frame | All tiles created at frame N+1, no physics anomalies for 60 frames |
| **AC-EC6** | Cancellation restores exact materials | Place wall (cost: 3 Stone, 2 Wood), cancel | Inventory restored to exact pre-placement values |
| **AC-EC7** | Multi-cell integrity (Post-MVP) | Attempt 2x2 placement where 1 cell invalid | Entire placement rejected, zero tiles modified |

---

### Performance Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-P1** | Input to preview response ≤16ms | Measure frame from input to ghost update | Execution time ≤16ms (maintains 60fps) |
| **AC-P2** | Validation chain ≤2ms (pass), ≤0.5ms (fail) | Profile V1-V6 execution time | Pass case ≤2ms, early-fail ≤0.5ms |
| **AC-P3** | Tile creation ≤5ms | Measure from validation pass to entity registered | Execution time ≤5ms |
| **AC-P4** | Inventory UI update ≤100ms | Place/cancel, verify UI reflects change | UI refresh within 100ms |
| **AC-P5** | Ghost preview maintains 60fps during cursor movement | Move cursor rapidly, profile update rate | Every frame updated within 16ms |
| **AC-P6** | 10 queued placements complete in ≤16ms spread | Queue 10 placements single frame, measure total processing | All tiles created by N+1, total time ≤16ms |
| **AC-P7** | No memory leak after 1000 place/cancel cycles | Perform 1000 cycles, measure heap delta | Memory increase ≤1MB |

---

### Pass/Fail Threshold

| Category | Pass Requirement | Fail Action |
|----------|------------------|-------------|
| **Core Mechanics (AC-CR1 to AC-CR7)** | 100% pass | 任一失败 → 核心逻辑错误，必须修复 |
| **Validation Chain (AC-V1 to AC-V6)** | 100% pass | 任一失败 → 验证逻辑缺失，必须修复 |
| **Category Requirements (AC-CAT-*)** | 100% pass | 任一失败 → 类别规则错误，必须修复 |
| **Edge Cases (AC-EC1 to AC-EC7)** | 100% pass (EC7 Post-MVP) | 任一失败 → 边界处理缺失 |
| **Performance (AC-P1 to AC-P7)** | 100% pass | 任一失败 → 性能优化 |

**MVP Total Criteria**: 31 (AC-EC7 excluded as Post-MVP)
**Alpha Scope**: AC-EC7 (multi-cell footprint integrity)
**Required for Implementation**: 100% pass on all MVP categories

## Open Questions

### High Priority (Implementation Blocking)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-001** | 战车仓库系统接口是否已定义？Placement system calls `inventory.remove(resource_id, amount)` but interface not yet specified. | 战车仓库系统 GDD设计者 | 战车仓库系统实现前 | Cannot deduct materials; fallback to placeholder inventory |
| **Q-002** | 建造验证系统是否已设计？This GDD uses provisional V1-V6 rules. If dedicated validation system exists, should migrate rules there. | 建造验证系统 GDD设计者 | 建造验证系统实现前 | Duplicate validation logic; unclear ownership |
| **Q-003** | 炮塔系统初始化接口是否已定义？`block_placed` signal triggers turret entity creation, but interface not specified. | 炮塔系统 GDD设计者 | 炮塔系统实现前 | Turrets placed but not functional |

### Medium Priority (Design Clarification)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-004** | 放置是否需要魔能消耗？战车驾驶消耗魔能，建造是否也消耗？If yes, need new validation check and cost display. | Game Designer | Beta阶段 | May need to add魔能_cost mechanic |
| **Q-005** | 建造时间机制是否满足节奏需求？当前设计启用 build_time (3-30秒)，需验证是否创造足够紧张感。 | Game Designer | MVP实现前 | May need to tune build_time ranges based on playtest |
| **Q-006** | 墙体是否支持旋转？MVP设计中rotation被排除。If rotation exists, need footprint validation for each orientation. | Game Designer | MVP实现前 | Formula and validation complexity increases |

### Low Priority (Future Consideration)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-007** | 多格建筑（>1 cell）如何处理？当前GDD仅覆盖单格。Facilities may be 2x2 or larger. | Level Designer | Alpha阶段 | Need footprint validation, cost scaling |
| **Q-008** | 撤销系统如何工作？当前100% refund。Alternative: limited undo window, or no undo at all. | Game Designer | Alpha阶段 | Refund policy may change |
| **Q-009** | 地形类型影响建造？当前V5假设所有terrain可建造。If terrain has types (pit/void/buildable), need terrain compatibility table. | World Designer | Vertical Slice | Need terrain_type validation |

### Assumptions Made (Temporary Decisions)

| Assumption | Rationale | Risk |
|------------|-----------|------|
| **Inventory API: remove(resource_id, amount) returns bool** | Standard inventory pattern. Assumed atomic deduct. | If API differs, placement system adapter needed |
| **No魔能消耗 for building** | 建造是物理行为，不消耗魔能。移动消耗魔能是驱动系统。 | If魔能消耗 added, new validation + UI |
| **Build_time enabled (3-30 seconds)** | 实现 Player Fantasy 的紧张感，参照 BuildItemDB 定义的时间值。 | Build time ranges may need tuning based on playtest feedback |
| **Single-player placement** | MVP scope. Multi-player race handled by queue pattern. | If co-op, need player_id tracking and sync |
| **Ghost preview uses same sprite as output tile** | 最简单实现，无需额外asset。 | If different preview needed, new asset type |

### Resolution Tracking

| ID | Status | Resolution Date | Resolved By | Resolution Summary |
|----|--------|-----------------|-------------|-------------------|
| Q-001 | Open | — | — | Pending 战车仓库系统GDD |
| Q-002 | Open | — | — | Pending 建造验证系统GDD (or accept provisional) |
| Q-003 | Open | — | — | Pending 炮塔系统GDD |
| Q-004 | Open | — | — | Pending Game Designer决策 |
| Q-005 | Resolved | 2026-04-23 | Design Review | Build_time enabled (3-30s) to match Player Fantasy tension |
| Q-006 | Open | — | — | MVP scope excludes rotation |
| Q-007 | Open | — | — | Post-MVP scope |
| Q-008 | Open | — | — | Alpha scope |
| Q-009 | Open | — | — | Vertical Slice scope |