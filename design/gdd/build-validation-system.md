# 建造验证系统

> **Status**: In Design
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 2 (搜打撤节奏), Pillar 3 (尸潮即高潮)
> **Priority**: MVP | **Layer**: Feature
> **System ID**: #45 (from systems-index.md)

## Overview

建造验证系统是建造流程的规则检查层——在玩家选择建造物品并点击目标位置后，系统执行一系列验证检查，确认建造请求是否合法可执行。验证通过后，建造请求传递给方块放置系统执行；验证失败则返回错误代码和反馈信息，阻止建造执行。

**系统职责**：
- 位置合法性验证：目标cell在TileMap世界边界内、目标Layer未被占用、目标位置满足collision兼容性
- 材料充足性验证：玩家资源库存满足建造物品的material_costs配方
- 放置条件验证：建造物品的placement_requirements满足（如炮塔需要相邻墙体、地板需要下层支撑）
- 输出方块合法性验证：建造物品的output_tile_id对应的tile满足buildability=1且layer_allowed包含目标Layer

**验证流程**：
玩家选择建造物品 → 系统预检查材料充足性 → 玩家点击目标位置 → 系统执行位置验证 → 系统执行放置条件验证 → 验证结果返回

**玩家间接体验**：
玩家不直接与"验证系统"交互，但每次建造操作都会触发验证检查。验证成功时，建造进度条开始；验证失败时，屏幕显示错误提示（"超出世界边界"、"材料不足"、"位置已被占用"）。验证系统定义了玩家建造行为的边界——玩家能在哪里建造、需要多少资源、哪些条件必须满足。

**支柱贡献**：
- Pillar 2 (搜打撤节奏)：验证失败时的明确反馈让玩家快速调整建造计划，避免浪费时间在无效建造尝试上
- Pillar 3 (尸潮即高潮)：位置合法性验证确保玩家建造的防御结构不会产生无效碰撞或穿透，保证防守有意义

**ADR Note**：建造验证系统将在实现阶段创建ADR，定义验证规则执行顺序、验证失败处理策略、以及与方块放置系统的接口契约。

## Player Fantasy

玩家在建造规划过程中面对的核心体验是**边界清晰下的快速决策**——验证系统不是阻止建造的障碍，而是帮助玩家快速知道"什么是可行的"的反馈机制。每次验证失败都是一次清晰的信息传递："这个位置不能建，因为X原因"——玩家能立即调整，而不是浪费时间尝试无效建造。

**情绪锚定**：
- **验证失败时的明确性**：玩家点击目标位置后，如果验证失败，屏幕显示具体原因："超出世界边界"、"位置已被占用"、"材料不足（缺少3铁矿）"、"炮塔需要相邻墙体"。玩家不会困惑"为什么不能建"，而是立即知道下一步该怎么做——换位置、收集更多材料、先建墙体。验证失败不是挫败，是**信息**
- **验证成功时的流畅感**：验证通过后，建造进度条立即开始，玩家进入下一个决策——"建造时间90秒，我要等待还是做其他事？"验证成功是**确认**，让玩家能继续规划流程
- **防守倒计时下的紧张验证**：尸潮倒计时4分钟，玩家快速点击建造位置，验证在毫秒级完成——成功则立即开始建造，失败则换下一个位置。验证速度决定了玩家能在倒计时内完成多少建造规划。验证是**时间压力的放大器**

**学习曲线**：
新玩家第一次尝试建造炮塔在空地上 → 验证失败："炮塔需要相邻墙体或地板支撑" → 玩家学会炮塔放置规则 → 下次建造炮塔前先建造地板或墙体 → 验证成功。验证失败反馈是**建造规则的隐性教程**，玩家通过失败学会系统的要求。

**支柱贡献**：
- Pillar 2 (搜打撤节奏)：验证反馈让玩家快速调整建造计划，不会在无效建造上浪费时间，保证搜打撤节奏流畅
- Pillar 3 (尸潮即高潮)：防守前的建造规划时间有限，验证系统的快速反馈让玩家能最大化有限时间内的建造效率——"4分钟内我能完成哪些建造？"的决策依赖验证速度

**失败时感觉**：
如果验证系统没有明确反馈（只显示"不能建造"而无具体原因），玩家会困惑并浪费时间尝试多个位置，最终挫败感上升。验证系统的价值在于**信息明确性**，而非验证本身。

## Detailed Design

### Core Rules

**Rule 1: Validation Priority Order (Early Exit)**

验证规则按优先级顺序执行，任一规则失败立即返回错误，不继续后续验证：

| Priority | Check ID | Check Name | Reason for Priority |
|----------|----------|------------|---------------------|
| 1 | V1 | World Bounds | 越界位置无意义，最先检查 |
| 2 | V2 | Layer Occupancy | 已占用位置无意义，快速失败 |
| 3 | V3 | Placement Range | 超出范围位置无意义，快速失败 |
| 4 | V4 | Tile Buildability | buildability=0的tile不可建造 |
| 5 | V5 | Category-Specific | 依赖上游数据，计算成本高 |
| 6 | V6 | Material Sufficiency | 最后检查，避免计算材料差异 |

---

**Rule 2: World Bounds Validation (V1)**

```gdscript
func validate_world_bounds(cell: Vector2i) -> ValidationResult:
    if cell.x < -MAX_WORLD_BOUNDS or cell.x > MAX_WORLD_BOUNDS:
        return {valid: false, error_code: "OUT_OF_BOUNDS", message: "超出世界边界"}
    if cell.y < -MAX_WORLD_BOUNDS or cell.y > MAX_WORLD_BOUNDS:
        return {valid: false, error_code: "OUT_OF_BOUNDS", message: "超出世界边界"}
    return {valid: true}
```

**Constants**: MAX_WORLD_BOUNDS = 1000 cells (from entities.yaml)

---

**Rule 3: Layer Occupancy Validation (V2)**

```gdscript
func validate_layer_occupancy(cell: Vector2i, layer: int) -> ValidationResult:
    var tile_data = _tilemap.get_cell_tile_data(layer, cell)
    if tile_data != null:
        return {valid: false, error_code: "CELL_OCCUPIED", message: "位置已被占用"}
    return {valid: true}
```

**Default layer**: Layer 2 (structures layer) for MVP build items. Category-specific layers defined in BuildItemDatabase placement_requirements.

---

**Rule 4: Placement Range Validation (V3)**

```gdscript
func validate_placement_range(cell: Vector2i, player_pos: Vector2, max_range: float) -> ValidationResult:
    var cell_center = Vector2((cell.x + 0.5) * CELL_SIZE, (cell.y + 0.5) * CELL_SIZE)
    var distance = player_pos.distance_to(cell_center)
    var max_distance = max_range * CELL_SIZE
    if distance > max_distance:
        return {valid: false, error_code: "OUT_OF_RANGE", message: "超出放置范围"}
    return {valid: true}
```

**Constants**: CELL_SIZE = 32 px (from entities.yaml), MAX_PLACE_RANGE = 5.0 cells (from block-placing-system)

---

**Rule 5: Tile Buildability Validation (V4)**

```gdscript
func validate_tile_buildability(output_tile_id: int) -> ValidationResult:
    var tile_type = BlockTypeDB.get_by_tile_id(output_tile_id)
    if tile_type == null:
        return {valid: false, error_code: "INVALID_TILE_ID", message: "无效方块类型"}
    if tile_type.buildability != 1:
        return {valid: false, error_code: "NOT_BUILDABLE", message: "此方块不可建造"}
    return {valid: true}
```

**Interface**: BlockTypeDB.get_by_tile_id(tile_id) → BlockType struct with buildability field

---

**Rule 6: Category-Specific Placement Validation (V5)**

验证建造物品的placement_requirements是否满足：

| Category | Requirement | Validation Logic |
|----------|-------------|------------------|
| `wall` | `requires_adjacent_floor` OR none | 检查相邻cells是否有Layer 2/3 tile |
| `turret` | `requires_adjacent_wall` OR `requires_floor` | 检查相邻cells是否有Layer 2 wall或脚下有floor |
| `trap` | `requires_floor` | 检查脚下cell是否有Layer 2 floor |
| `facility` | `requires_floor` | 检查脚下cell是否有Layer 2 floor |
| `floor` | `requires_support_below` | 检查下方cell是否有solid terrain (Layer 1) 或 structure (Layer 2) |

```gdscript
func validate_category_requirements(cell: Vector2i, build_item: BuildItem) -> ValidationResult:
    var req = build_item.placement_requirements
    var category = build_item.category
    
    match category:
        0: # wall
            if req.requires_adjacent_floor:
                if not _has_adjacent_floor(cell):
                    return {valid: false, error_code: "NO_ADJACENT_FLOOR", message: "墙体需要相邻地板"}
        1: # turret
            if req.requires_adjacent_wall and not _has_adjacent_wall(cell):
                return {valid: false, error_code: "NO_ADJACENT_WALL", message: "炮塔需要相邻墙体"}
            if req.requires_floor and not _has_floor_below(cell):
                return {valid: false, error_code: "NO_FLOOR_BELOW", message: "炮塔需要地板支撑"}
        2: # trap
            if req.requires_floor and not _has_floor_below(cell):
                return {valid: false, error_code: "NO_FLOOR_BELOW", message: "陷阱需要地板支撑"}
        3: # facility
            if req.requires_floor and not _has_floor_below(cell):
                return {valid: false, error_code: "NO_FLOOR_BELOW", message: "设施需要地板支撑"}
        4: # floor
            if req.requires_support_below and not _has_support_below(cell):
                return {valid: false, error_code: "NO_SUPPORT_BELOW", message: "地板需要下层支撑"}
    
    return {valid: true}

func _has_adjacent_floor(cell: Vector2i) -> bool:
    for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
        var adj_cell = cell + offset
        var tile_layer2 = _tilemap.get_cell_tile_data(2, adj_cell)
        var tile_layer3 = _tilemap.get_cell_tile_data(3, adj_cell)
        if tile_layer2 != null or tile_layer3 != null:
            return true
    return false

func _has_adjacent_wall(cell: Vector2i) -> bool:
    for offset in [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]:
        var adj_cell = cell + offset
        var tile = _tilemap.get_cell_tile_data(2, adj_cell)
        if tile != null:
            var adj_tile_type = BlockTypeDB.get_by_tile_data(tile)
            if adj_tile_type.category == "wall":
                return true
    return false

func _has_floor_below(cell: Vector2i) -> bool:
    var below_cell = cell + Vector2i(0, 1)
    return _tilemap.get_cell_tile_data(2, below_cell) != null

func _has_support_below(cell: Vector2i) -> bool:
    var below_cell = cell + Vector2i(0, 1)
    var layer1_tile = _tilemap.get_cell_tile_data(1, below_cell)
    var layer2_tile = _tilemap.get_cell_tile_data(2, below_cell)
    return layer1_tile != null or layer2_tile != null
```

---

**Rule 7: Material Sufficiency Validation (V6)**

```gdscript
func validate_material_sufficiency(material_costs: Array[MaterialCost], inventory: Dictionary) -> ValidationResult:
    var missing: Array[Dictionary] = []
    
    for cost in material_costs:
        var resource_id = cost.resource_id
        var required = cost.amount
        var available = inventory.get(resource_id, 0)
        if available < required:
            missing.append({
                resource_id: resource_id,
                required: required,
                available: available,
                deficit: required - available
            })
    
    if missing.size() > 0:
        var message = _format_missing_message(missing)
        return {valid: false, error_code: "INSUFFICIENT_MATERIALS", message: message, missing: missing}
    
    return {valid: true}

func _format_missing_message(missing: Array[Dictionary]) -> String:
    var parts: Array[String] = []
    for item in missing:
        var resource_name = ResourceDB.get_display_name(item.resource_id)
        parts.append("%s: 缺少%d" % [resource_name, item.deficit])
    return "材料不足: " + parts.join(", ")
```

---

**Rule 8: Full Validation Chain Interface**

```gdscript
# Main validation entry point called by BlockPlacingSystem
func validate_placement(build_item_id: int, target_cell: Vector2i, player_pos: Vector2) -> ValidationResult:
    var build_item = BuildItemDB.get_build_item(build_item_id)
    if build_item == null:
        return {valid: false, error_code: "INVALID_BUILD_ITEM", message: "无效建造物品"}
    
    # V1: World bounds
    var result = validate_world_bounds(target_cell)
    if not result.valid: return result
    
    # V2: Layer occupancy
    var target_layer = build_item.placement_requirements.target_layer
    result = validate_layer_occupancy(target_cell, target_layer)
    if not result.valid: return result
    
    # V3: Placement range
    result = validate_placement_range(target_cell, player_pos, MAX_PLACE_RANGE)
    if not result.valid: return result
    
    # V4: Tile buildability
    result = validate_tile_buildability(build_item.output_tile_id)
    if not result.valid: return result
    
    # V5: Category-specific requirements
    result = validate_category_requirements(target_cell, build_item)
    if not result.valid: return result
    
    # V6: Material sufficiency
    result = validate_material_sufficiency(build_item.material_costs, PlayerInventory.get_all())
    if not result.valid: return result
    
    return {valid: true, build_item: build_item, cell: target_cell}
```

---

### States and Transitions

建造验证系统无显式状态机——验证是同步调用，即时返回结果。调用方（方块放置系统）持有状态：

| Caller State | Validation Trigger | Result Handling |
|--------------|-------------------|-----------------|
| SELECTING | 玩家点击目标位置 | 成功 → COMMIT，失败 → FAILED |
| FAILED | 验证返回error | 显示错误消息，返回SELECTING |

---

### Interactions with Other Systems

| System | Data Flow In | Data Flow Out | Interface Owner |
|--------|--------------|---------------|-----------------|
| **方块放置系统** (#13) | `validate_placement(build_item_id, cell, player_pos)` | ValidationResult struct | ValidationSystem exposes API |
| **TileMap世界系统** (#1) | `get_cell_tile_data(layer, cell)` | TileData or null | TileMap provides query |
| **BlockTypeDatabase** (#2) | `get_by_tile_id(tile_id)` | BlockType struct | BlockTypeDB provides lookup |
| **建造物品数据库** (#5) | `get_build_item(build_item_id)` | BuildItem struct | BuildItemDB provides lookup |
| **ResourceDatabase** | `get_display_name(resource_id)` | Localized name string | ResourceDB provides display |
| **PlayerInventory** | `get_all()` → Dictionary of resource_id: amount | Inventory dict | Inventory exposes query |

**ValidationResult Structure**:
```gdscript
class ValidationResult:
    var valid: bool
    var error_code: String  # "" if valid, one of error codes if invalid
    var message: String     # "" if valid, localized message if invalid
    var missing: Array[Dictionary]  # Only for V6 failure, list of deficit items
    var build_item: BuildItem  # Only if valid, the validated item
    var cell: Vector2i        # Only if valid, the validated cell
```

## Formulas

### Formula 1: Distance Calculation (V3 Range Check)

**Purpose**: Calculate distance from player to target cell center for range validation.

```
distance = sqrt((player_pos.x - cell_center.x)^2 + (player_pos.y - cell_center.y)^2)
is_in_range = distance <= MAX_PLACE_RANGE * CELL_SIZE
```

**Variables**:
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `player_pos` | Vector2 | pixels | Player center position (world coords) |
| `cell_center` | Vector2 | pixels | Cell center position (coords × CELL_SIZE + CELL_SIZE/2) |
| `MAX_PLACE_RANGE` | float | cells | 5.0 (from block-placing-system) |
| `CELL_SIZE` | int | pixels | 32 (from TileMap system) |

**Output Range**: 0.0 to MAX_PLACE_RANGE × CELL_SIZE (160 pixels for default)
**Example**: Player at (100, 100), target cell (2, 2) → cell_center = (80, 80) → distance = sqrt(400) = 20 px → is_in_range = true (20 <= 160)

---

### Formula 2: Material Deficit Calculation (V6)

**Purpose**: Calculate missing material quantities for error message.

```
deficit = required - available
total_deficit = sum of all deficit values
```

**Variables**:
| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `required` | int | 1-999 | Material amount from material_costs[] |
| `available` | int | 0-999 | Current inventory quantity |
| `deficit` | int | 0-999 | Missing amount (0 if sufficient) |

**Output**: Array of deficit dictionaries `{resource_id, required, available, deficit}`
**Example**: Required iron=8, available iron=5 → deficit=3 → message: "铁矿: 缺少3"

## Edge Cases

### Edge Case 1: Two Validation Checks Fail Simultaneously

**If V1-V6 checks fail at the same time**: Return first failure in priority order (V1→V2→V3→V4→V5→V6). Early exit prevents wasted computation and gives deterministic error messages. Player sees only the first reason, not a combined message.

---

### Edge Case 2: Player at Exactly MAX_PLACE_RANGE Distance

**If distance equals MAX_PLACE_RANGE exactly**: `distance <= MAX_PLACE_RANGE` is **inclusive**. 5.0 cells (160px) is valid placement. Player expectation: "5 range means 5 cells". Round-up logic not applied.

---

### Edge Case 3: Adjacent Tile Destroyed During Validation

**If supporting floor/wall destroyed between preview validation and click validation**: Click validation is **authoritative**. Preview shows valid state (floor exists), but click validation re-checks and finds floor missing → fails V5 with "炮塔需要地板支撑". Player sees error feedback.

---

### Edge Case 4: Material Costs Array Empty

**If material_costs[] is empty**: V6 check passes immediately (no materials required). Free placement scenario — useful for debug/test items. BuildItemDB validation should flag empty array as unusual, but validation system allows it.

---

### Edge Case 5: Invalid Build Item ID

**If build_item_id doesn't exist in BuildItemDB**: Immediate failure at Rule 8 entry, return `{valid: false, error_code: "INVALID_BUILD_ITEM"}`. No downstream queries attempted. Prevents null reference errors.

---

### Edge Case 6: Negative Cell Coordinates

**If cell.x or cell.y is negative**: Valid if within MAX_WORLD_BOUNDS. Godot TileMap supports negative coordinates. V1 check only rejects values outside [-1000, 1000] range.

---

### Edge Case 7: Category-Specific Rule Missing from PlacementReq

**If placement_requirements lacks expected field**: Use default behavior per category:
- wall: default `requires_adjacent_floor: false` (no requirement)
- turret: default `requires_floor: true` (most turrets need floor)
- trap: default `requires_floor: true`
- facility: default `requires_floor: true`
- floor: default `requires_support_below: true`

---

### Edge Case 8: Player Inventory Returns Null/Empty

**If PlayerInventory.get_all() returns empty Dictionary**: V6 check assumes 0 for all materials. All material_costs with amount > 0 will fail. Return error listing all required materials as missing.

## Dependencies

### Upstream Dependencies

| System | Layer | Data Provided | Interface | Dependency Type |
|--------|-------|---------------|-----------|-----------------|
| **TileMap世界系统** (#1) | Foundation | Layer 1/2/3 cell state, coordinate conversion | `get_cell_tile_data(layer, coords)` → TileData or null<br>`world_to_cell(pos)` → Vector2i<br>`cell_to_world_center(cell)` → Vector2 | **Blocking** — Cannot validate occupancy without world state |
| **BlockTypeDatabase** (#2) | Foundation | Tile properties: buildability, layer_allowed, category | `get_by_tile_id(tile_id)` → BlockType struct<br>`get_by_tile_data(tile_data)` → BlockType struct | **Blocking** — Cannot validate V4/V5 without tile data |
| **建造物品数据库** (#5) | Foundation | Build item definitions: output_tile_id, material_costs[], category, placement_requirements | `get_build_item(build_item_id)` → BuildItem struct | **Blocking** — Cannot validate V5/V6 without item data |
| **ResourceDatabase** (#3) | Foundation | Resource display names for error messages | `get_display_name(resource_id)` → String | **Soft** — Error message quality depends on this |
| **PlayerInventory** | Feature | Material inventory state | `get_all()` → Dictionary of resource_id: amount | **Blocking** — Cannot validate V6 without inventory |

### Downstream Dependent Systems

| System | Layer | Data Consumed | Interface Provided | Dependency Type |
|--------|-------|---------------|-------------------|-----------------|
| **方块放置系统** (#13) | Core | ValidationResult for placement decision | `ValidationSystem.validate_placement(build_item_id, cell, player_pos)` → ValidationResult | **Blocking** — BlockPlacingSystem requires validation API |
| **地堡设施系统** (#46) | Feature | Placement validation before facility creation | Same validate_placement interface | **Blocking** — Facility system needs validation |
| **闸门系统** (#47) | Defense | Placement validation before gate creation | Same validate_placement interface | **Blocking** — Gate system needs validation |

### Bidirectional Reference Contract

方块放置系统GDD (block-placing-system.md) must update Dependencies section:
- Change "建造验证系统 — Provisional" to "建造验证系统 (#45) — **Blocking**"
- Change interface from "See Core Rules V1-V6" to "`ValidationSystem.validate_placement()` → ValidationResult"

---

### Dependency Risk Assessment

| Dependency | Risk | Mitigation |
|------------|------|------------|
| TileMap世界系统 | LOW — GDD exists, interface stable | Standard TileMap query API |
| BlockTypeDatabase | LOW — GDD exists, buildability field defined | Direct field access |
| 建造物品数据库 | LOW — GDD exists, placement_requirements defined | Field access with defaults for missing fields |
| PlayerInventory | MEDIUM — GDD not written (战车仓库系统/玩家背包系统 pending) | Assume Dictionary interface, document provisional assumption |
| 方块放置系统 | LOW — GDD exists, provisional reference already noted | Update reference after this GDD complete |

## Tuning Knobs

| Knob | Default | Safe Range | Gameplay Effect | Tuning Notes |
|------|---------|------------|-----------------|--------------|
| `MAX_PLACE_RANGE` | 5.0 cells | 3.0-10.0 | 放置距离限制。Owned by block-placing-system — referenced here. | 参见 block-placing-system.md Tuning Knobs |
| `Validation execution order` | V1→V2→V3→V4→V5→V6 | Fixed | 决定错误消息优先级。不应改变。 | 逻辑约束 — 改变顺序可能产生不一致错误消息 |
| `Category requirement defaults` | See Edge Case 7 | Per-category | 无placement_requirements字段时的fallback行为 | 设计决策 — 改变需要更新BuildItemDB默认值 |

**External Knobs Referenced**:
- CELL_SIZE = 32 px (TileMap系统)
- MAX_WORLD_BOUNDS = 1000 cells (TileMap系统)
- material_costs[] per build item (BuildItemDB)
- placement_requirements per build item (BuildItemDB)

---

## Visual/Audio Requirements

建造验证系统无直接视觉输出——验证成功/失败的反馈由方块放置系统和HUD系统呈现。

**Indirect Visual Feedback** (owned by downstream systems):
- 验证成功 → 建造进度条开始显示 (方块放置系统)
- 验证失败 → 错误消息弹窗显示 (HUD系统)
- Ghost preview颜色 → 红色表示验证失败区域 (方块放置系统)

**Indirect Audio Feedback** (owned by 音效系统):
- 验证成功 → 无特定音效（建造开始音效由方块放置系统触发）
- 验证失败 → 拒绝音效（短促的"buzzer"音效，表示操作无效）

**验证系统不包含资产** — 所有反馈由下游系统实现。

---

## UI Requirements

建造验证系统无直接UI元素——验证反馈由HUD系统呈现。

**Error Message Format** (供HUD系统参考):
| Error Code | Display Template | HUD Responsibility |
|------------|-----------------|-------------------|
| OUT_OF_BOUNDS | "超出世界边界" | Top-center toast message |
| CELL_OCCUPIED | "位置已被占用" | Top-center toast message |
| OUT_OF_RANGE | "超出放置范围" | Top-center toast message |
| NOT_BUILDABLE | "此方块不可建造" | Top-center toast message |
| NO_ADJACENT_FLOOR | "墙体需要相邻地板" | Top-center toast message |
| NO_ADJACENT_WALL | "炮塔需要相邻墙体" | Top-center toast message |
| NO_FLOOR_BELOW | "[category]需要地板支撑" | Top-center toast message |
| NO_SUPPORT_BELOW | "地板需要下层支撑" | Top-center toast message |
| INSUFFICIENT_MATERIALS | "材料不足: [缺失列表]" | Material breakdown panel |

**HUD系统职责**: 接收ValidationResult.error_code，渲染对应消息模板，自动消失时间2.5秒。

---

## Acceptance Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC1** | V1 rejects out-of-bounds cells | Attempt placement at (1001, 0) and (-1001, 0) | Both fail with "超出世界边界" |
| **AC2** | V2 rejects occupied cells | Place tile at cell, attempt second placement | Second fails with "位置已被占用" |
| **AC3** | V3 validates range inclusively | Test at 4.9, 5.0, 5.1 cells from player | 5.0 passes, 5.1 fails |
| **AC4** | V4 rejects buildability=0 tiles | Use build_item with output_tile_id buildability=0 | Fails with "此方块不可建造" |
| **AC5** | V5 category rules execute per category | Test wall/turret/trap/facility/floor with missing support | Each fails with category-specific message |
| **AC6** | V6 reports exact deficit | Attempt placement with 5 iron when 8 required | Message shows "铁矿: 缺少3" |
| **AC7** | Validation chain early-exits | Mock V1 failure, verify V2-V6 not called | Only V1 executed, immediate return |
| **AC8** | Full chain passes valid request | Valid cell, materials, requirements | Returns {valid: true, build_item, cell} |
| **AC9** | Invalid build_item_id fails immediately | Call with build_item_id=99999 | Returns INVALID_BUILD_ITEM error |
| **AC10** | Empty material_costs passes V6 | Build item with empty material_costs array | V6 check skipped, chain continues |

---

## Open Questions

### Q1: PlayerInventory Interface Contract

**Question**: PlayerInventory (战车仓库系统/玩家背包系统) GDD not yet written. What is the exact interface for `get_all()`?

**Current Assumption**: Returns `Dictionary` with keys = resource_id (int), values = amount (int).

**Resolution Path**: When 战车仓库系统 (#29) or 玩家背包系统 (#28) is designed, verify `get_all()` signature and update this GDD's interface reference.

**Owner**: 战车仓库系统 / 玩家背包系统 GDD author

---

### Q2: Multi-Cell Footprint Validation

**Question**: MVP build items are single-cell. Post-MVP items (large facilities, multi-cell traps) require footprint validation. How should validation system extend to support multi-cell?

**Options**:
- Option A: Single validate_placement call with footprint array
- Option B: Call validate_placement for each footprint cell, aggregate results

**Resolution Path**: Decide during Vertical Slice when multi-cell items are designed.

**Owner**: Game Designer + Technical Director

---

### Q3: Validation Re-execution Timing

**Question**: Block-placing-system stores queued modifications. Should validation re-execute at physics frame execution time, or trust initial validation result?

**Current Spec**: V3 (range) uses player position at execution time, not click time (per block-placing-system Edge Case 5).

**Resolution Path**: Verify in implementation — confirm no race conditions between validation and execution.

**Owner**: Implementation team

---

### Q4: Category-Specific Rule Defaults in BuildItemDB

**Question**: placement_requirements defaults (Edge Case 7) should be defined in BuildItemDB, not ValidationSystem. Should BuildItemDB guarantee all fields present, or allow ValidationSystem to fallback?

**Resolution Path**: Update BuildItemDB GDD to add default values for placement_requirements fields, remove fallback logic from ValidationSystem.

**Owner**: BuildItemDB GDD author