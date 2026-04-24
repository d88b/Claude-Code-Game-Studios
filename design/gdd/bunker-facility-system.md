# 地堡设施系统

> **Status**: In Design
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-24
> **Implements Pillar**: Pillar 3 (尸潮即高潮), 堡垒生态闭环
> **Priority**: MVP | **Layer**: Feature
> **System ID**: #46 (from systems-index.md)

## Overview

地堡设施系统是设施实体的生命周期管理器和功能实现层——它接收方块放置系统的设施放置信号，创建对应的设施实体，管理设施的运行状态（激活/损坏），实现设施的具体功能（储物箱的存储、工作台的合成），并处理设施的损坏和拆除。

**数据层职责**：
- 监听`block_placed`信号，识别category=facility的放置事件
- 为每个设施创建FacilityEntity运行时实例，绑定到对应的TileMap cell
- 管理设施状态机：IDLE → ACTIVE → DAMAGED → DESTROYED
- 维护设施内部数据：储物箱的storage_contents[]、工作台的current_recipe、魔力消耗累计
- 处理设施交互请求：玩家打开储物箱界面、玩家在工作台启动合成

**设施功能实现**：
- **储物箱 (400)**：提供100格独立存储空间，玩家可交互存取物品，损坏时100%内容掉落
- **工作台 (410)**：提供基础合成配方（铁矿→铁锭等），每次合成消耗战车魔能，需要魔力供电

**魔力供电机制**：
- MVP阶段：工作台直接从战车魔能池消耗魔能（每次合成消耗5-10魔能）
- Vertical Slice阶段：引入魔力发电机提供持续魔力供应

**系统必要性**：没有地堡设施系统，游戏将无法：
- 将设施Tile转化为可交互的功能实体（储物箱只是障碍物）
- 实现堡垒生态闭环的存储和生产环节（搜刮→存储→合成→升级）
- 支撑下游生态系统（雨水收集、种田都依赖设施基础）

**下游消费系统**：
- 战车仓库系统 (#29) — 储物箱提供物品转移目的地
- 资源合成系统 (#44) — 工作台提供合成界面入口
- 雨水收集系统 (#56) — 需要设施实体框架
- 种田系统 (#57) — 需要设施实体框架

## Player Fantasy

玩家在地堡设施系统中面对的核心体验是**"战车冒险的终点与起点"**——储物箱是每次搜刮的安全归宿，工作台是每次升级的准备起点。设施创造的不是功能，而是**归属感**：这不再只是洞穴，而是玩家亲手建设的地下家园。

**锚定时刻：**

1. **战车卸货的秩序感**：搜刮归来，战车仓库塞满杂物——魔力晶石、秘银碎片、铁矿、木材。你驾驶战车停在储物箱旁，打开仓库界面，拖拽晶石到储物箱。每一件物资都有归属位置——晶石去魔导材料区，秘银去稀有材料区，铁矿去基础材料区。储物箱不是仓库，是**物资秩序的建立者**，让混乱的搜刮变成有序的资源管理。

2. **工作台前的决策时刻**：战车装甲升级需要12铁锭，库存只有8铁矿。你站在工作台前，查看配方列表：铁矿→铁锭（消耗5铁矿，产出1铁锭，消耗8魔能）。战车魔能池还剩60%，够合成吗？还是先去搜刮更多铁矿？工作台创造的是**资源转化的决策点**——"直接合成还是先搜刮"的选择让资源管理成为主动行为而非被动积累。

3. **防线布置的分区感**：储物箱A在入口区（存放紧急维修材料），储物箱B在深层区（存放稀有资源），工作台在中央生产区。玩家在地图上标记每个区域用途——入口区是"快速补给区"，深层区是"战略储备区"，中央区是"生产区"。设施布局创造的是**地堡分区感**——玩家不是随意摆放，而是有规划地设计地堡功能分区。

**失败时的感觉**：
储物箱被尸潮击毁，存储的12秘银散落地面。你有30秒抢救时间——冲过去捡拾，还是继续防守？选择继续防守，尸潮过后秘银可能被敌人踩踏消失。选择抢救，防线可能失守。储物箱损坏不是纯损失——它创造了**紧急决策时刻**，让设施成为防守的一部分而非独立的存储容器。

**支柱贡献**：
- Pillar 3 (尸潮即高潮)：设施损坏时内容掉落，创造"抢救还是防守"的紧急决策
- 堡垒生态闭环：储物箱完成搜刮→存储环节，工作台完成存储→合成环节，支撑闭环生态

**没有设施系统，玩家失去什么**：
- 搜刮没有归宿 — 战车仓库是运输工具，不是归属地；储物箱才是资源管理终点
- 升级没有起点 — 工作台将原材料转化为升级材料，支撑科技和战车改装
- 地堡没有分区 — 没有设施布局，地堡只是洞穴而非功能性堡垒

## Detailed Design

### Core Rules

#### Rule 1: Facility Entity Creation

当方块放置系统发射`block_placed`信号时，设施系统检查category=facility，创建对应的FacilityEntity：

```gdscript
# FacilityManager singleton listens to block_placed signal
func _on_block_placed(cell: Vector2i, tile_id: int, player_id: int):
    var build_item = BuildItemDB.get_build_item_for_tile(tile_id)
    if build_item == null or build_item.category != CATEGORY_FACILITY:
        return  # Not a facility, ignore
    
    var facility_entity = _create_facility_entity(build_item.build_item_id, cell)
    _register_facility(facility_entity)
    emit_signal("facility_created", facility_entity)
```

**FacilityEntity Data Structure:**

| Field | Type | Description |
|-------|------|-------------|
| `facility_id` | int | 运行时唯一ID（递增分配） |
| `build_item_id` | int | 建造物品ID（400或410） |
| `cell` | Vector2i | 绑定的TileMap cell坐标 |
| `state` | FacilityState | 状态枚举：IDLE/ACTIVE/DAMAGED/DESTROYED |
| `health_ratio` | float | 当前耐久比例（0.0-1.0），继承Tile hardness |
| `storage_contents` | Array[StorageSlot] | 仅储物箱：存储内容（100格） |
| `current_recipe` | Recipe | 仅工作台：当前合成配方 |
| `craft_progress` | float | 仅工作台：合成进度（秒） |
| `magic_powered` | bool | 仅工作台：魔力供电状态 |

---

#### Rule 2: Facility State Machine

| State | Entry Condition | Exit Condition | Behavior |
|-------|-----------------|----------------|----------|
| **IDLE** | 设施创建完成 | 玩家交互 → ACTIVE | 等待交互，无功能执行 |
| **ACTIVE** | 玩家打开交互界面 | 界面关闭 → IDLE / 耐久<30% → DAMAGED | 执行设施功能（存储/合成） |
| **DAMAGED** | health_ratio < 0.30 | 修复 → ACTIVE / 耐久=0 → DESTROYED | 功能受限，显示损坏警告，储物箱无法存取 |
| **DESTROYED** | health_ratio = 0 | — | 设施实体销毁，触发内容掉落，移除Tile |

**State Transition Triggers:**
- IDLE → ACTIVE：玩家按下交互键（E）且距离设施≤2 cells
- ACTIVE → IDLE：玩家关闭交互界面或离开设施范围>3 cells
- ACTIVE → DAMAGED：设施受到攻击，health_ratio降至<30%
- DAMAGED → ACTIVE：玩家使用修复工具修复至health_ratio≥50%
- DAMAGED → DESTROYED：设施受到攻击，health_ratio降至0

---

#### Rule 3: Storage Box (400) Implementation

储物箱提供100格独立存储空间，每格可存储一种资源类型。

**StorageSlot Data Structure:**

| Field | Type | Range | Description |
|-------|------|-------|-------------|
| `resource_id` | int | 0-65535 | 资源ID（0=空槽位） |
| `quantity` | int | 0-999 | 当前数量 |

**Storage Capacity:**
- 总槽位数：100（与战车仓库相等）
- 单槽容量上限：999（单个资源堆叠上限）
- 总容量上限：100 × 999 = 99,900（理论最大）

**交互接口:**

```gdscript
# StorageBox interaction methods
func deposit_resource(resource_id: int, amount: int) -> int:  # 返回实际存入数量
func withdraw_resource(resource_id: int, amount: int) -> int:  # 返回实际取出数量
func get_slot(slot_index: int) -> StorageSlot
func get_all_contents() -> Array[StorageSlot]
func find_empty_slot() -> int  # 返回槽位索引，-1表示无空槽
func find_slot_by_resource(resource_id: int) -> int  # 返回槽位索引
```

**Deposit Logic:**
1. 查找已有相同resource_id的槽位 → 尝试堆叠（quantity + amount ≤ 999）
2. 若堆叠失败或无已有槽位 → 查找空槽位
3. 存入空槽位，设置resource_id和quantity
4. 返回实际存入数量（可能因容量限制而少于请求量）

**Withdraw Logic:**
1. 查找resource_id对应的槽位
2. 若槽位不存在 → 返回0
3. 若槽位quantity < amount → 返回实际可取出数量
4. 扣除quantity，若quantity归零 → 清空槽位（resource_id=0）
5. 返回实际取出数量

---

#### Rule 4: Workbench (410) Implementation - MVP Basic Crafting

工作台在MVP阶段提供基础合成配方，直接从战车魔能池消耗魔能。

**MVP Basic Recipes:**

| Recipe ID | Input | Output | Magic Cost | Craft Time |
|-----------|-------|--------|------------|------------|
| `R001` | 铁矿×5 (ID 101) | 铁锭×1 (ID 151) | 8 魔能 | 10 秒 |
| `R002` | 铜矿×5 (ID 102) | 铜锭×1 (ID 152) | 8 魔能 | 10 秒 |
| `R003` | 晶石碎片×3 (ID 201) | 晶石簇×1 (ID 202) | 15 魔能 | 15 秒 |
| `R004` | 铁锭×2 (151) + 铜锭×1 (152) | 基础零件×1 (ID 160) | 12 魔能 | 12 秒 |

**Crafting Process:**
1. 玩家打开工作台界面，选择配方
2. 系统验证：材料充足 + 战车魔能充足 + 工作台魔力供电
3. 扣除材料（原子操作）+ 扣除魔能（从战车魔能池）
4. 启动合成进度计时器（craft_time秒）
5. progress完成后，产出资源存入玩家背包或战车仓库（优先背包）

**Magic Power Source (MVP):**
- 工作台直接连接战车魔能池（距离战车≤10 cells时有效）
- 玩家在工作台界面看到"魔能连接：战车魔能池 (剩余: XX%)"
- 若战车距离>10 cells，显示"魔能连接断开，请靠近战车"，无法启动合成

**Magic Connection Validation:**
```gdscript
func _validate_magic_connection(workbench_cell: Vector2i) -> bool:
    var vehicle_pos = VehicleAttributeSystem.get_vehicle_position()
    var distance = workbench_cell.distance_to(vehicle_pos)
    return distance <= MAGIC_CONNECTION_RANGE  # 10 cells
```

---

#### Rule 5: Facility Damage and Content Drop

设施作为TileMap实体，继承BlockTypeDatabase的硬度和碰撞属性。敌人攻击设施时触发伤害处理。

**Damage Processing:**
1. 设施Tile受到攻击 → BlockTypeDB查询hardness → 计算damage_ratio
2. FacilityManager接收damage信号 → 更新facility_entity.health_ratio
3. health_ratio < 0.30 → 状态转换至DAMAGED，储物箱锁定（无法存取）
4. health_ratio = 0 → 状态转换至DESTROYED

**Content Drop on Destroy:**
```gdscript
func _on_facility_destroyed(facility_entity: FacilityEntity):
    if facility_entity.build_item_id == 400:  # 储物箱
        _spawn_content_drops(facility_entity.cell, facility_entity.storage_contents)
    # 工作台无持久存储内容，无需掉落处理
    
    _unregister_facility(facility_entity)
    emit_signal("facility_destroyed", facility_entity.cell, facility_entity.build_item_id)
```

**Drop Spawn Logic:**
- 每个非空槽位生成一个ResourceDropEntity
- Drop位置：facility_entity.cell中心 ± 随机偏移（8px范围）
- Drop内容：resource_id + quantity（完整数量，100%掉落不丢失）
- Drop有效期：30秒后消失（玩家需及时拾取）

---

#### Rule 6: Facility Removal (Player Demolition)

玩家可主动拆除设施，返还部分材料。

**Demolition Process:**
1. 玩家选择拆除工具 → 点击目标设施
2. 系统验证：设施存在 + 设施未处于ACTIVE状态（交互界面关闭）
3. 若是储物箱，检查storage_contents是否为空 → 非空警告"储物箱内有物品，拆除将全部掉落"
4. 确认拆除 → 设施实体销毁 → TileMap移除Tile → 发射facility_removed信号
5. 材料返还：返还50%建造材料（参照方块挖掘系统拆除逻辑）

**Material Refund Rate:**
- 设施拆除：50%材料返还（与墙体拆除一致）
- 内容处理：储物箱内容100%掉落（与损坏一致，玩家可拾取）

---

#### Rule 7: Facility Interaction Range

玩家与设施的交互距离限制：

| Facility | Interaction Range | Condition |
|----------|------------------|-----------|
| 储物箱 (400) | 2 cells (64px) | 玩家在战车内或下车状态均可交互 |
| 工作台 (410) | 2 cells (64px) | 玩家必须下车状态才能交互（战车无法操作精密设备） |

**Interaction Validation:**
```gdscript
func _validate_interaction(facility_cell: Vector2i, player_pos: Vector2, player_state: PlayerState) -> bool:
    var distance = facility_cell.distance_to(player_pos)
    if distance > INTERACTION_RANGE:
        return false
    if facility.build_item_id == 410 and player_state == IN_VEHICLE:
        return false  # 工作台需下车状态
    return true
```

## Formulas

### Formula 1: Storage Capacity Calculation

**总存储容量计算：**

```
total_capacity = sum(quantity_i) for all slots where resource_id != 0
remaining_slots = count(slots where resource_id == 0)
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `quantity_i` | int | 0-999 | 槽位i的当前数量 |
| `resource_id_i` | int | 0-65535 | 槽位i的资源类型（0=空） |

**Output:**
- `total_capacity`: 已存储的总资源数量（sum of all quantities）
- `remaining_slots`: 剩余可用空槽位数

**Example:** storage_contents = [{101, 50}, {110, 30}, {0, 0}, ...] → total_capacity = 80, remaining_slots = 98

---

### Formula 2: Deposit Amount Limit

**可存入数量上限计算：**

```
max_deposit = min(requested_amount, 999 - existing_quantity, empty_slots_available × 999)
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `requested_amount` | int | 1-999 | 玩家请求存入数量 |
| `existing_quantity` | int | 0-999 | 已有相同resource_id槽位的数量（0 if no slot exists） |
| `empty_slots_available` | int | 0-100 | 当前空槽位数 |

**Output:** `max_deposit` ∈ [0, requested_amount]

**Example:** requested_amount=100, existing_quantity=950, empty_slots=2 → max_deposit = min(100, 49, 1998) = 49

---

### Formula 3: Magic Connection Distance

**工作台-战车魔能连接距离：**

```
is_connected = distance(workbench_cell, vehicle_cell) <= MAGIC_CONNECTION_RANGE
distance = sqrt((cell1.x - cell2.x)^2 + (cell1.y - cell2.y)^2)
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `workbench_cell` | Vector2i | world coords | 工作台所在cell坐标 |
| `vehicle_cell` | Vector2i | world coords | 战车当前cell坐标 |
| `MAGIC_CONNECTION_RANGE` | float | 10.0 cells | 魔能连接有效距离（Tuning Knob） |

**Output:** `is_connected` ∈ {true, false}

**Example:** workbench=(15, 20), vehicle=(18, 22) → distance=√(9+4)=√13≈3.6 → is_connected=true

---

### Formula 4: Crafting Magic Cost

**合成魔能消耗：**

```
magic_consumed = recipe.magic_cost
remaining_magic_ratio = (vehicle_magic_current - magic_consumed) / vehicle_magic_max
can_craft = remaining_magic_ratio >= 0 AND materials_sufficient AND magic_connected
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `recipe.magic_cost` | int | 5-20 | 配方定义的魔能消耗（Tuning Knob per recipe） |
| `vehicle_magic_current` | float | 0.0-MAX_MAGIC | 战车当前魔能值 |
| `vehicle_magic_max` | float | vehicle_type dependent | 战车魔能上限 |

**Output:** `can_craft` ∈ {true, false}, `remaining_magic_ratio` ∈ [0.0, 1.0]

**Example:** recipe.magic_cost=15, vehicle_magic_current=30, vehicle_magic_max=100 → remaining_magic_ratio=(30-15)/100=0.15 → can_craft=true

---

### Formula 5: Facility Health Ratio

**设施耐久比例（继承Tile hardness）：**

```
health_ratio = current_hardness / base_hardness
damage_ratio = damage_amount / base_hardness
new_health_ratio = health_ratio - damage_ratio
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `base_hardness` | int | BlockTypeDB定义 | 设施Tile的基础硬度（facility_storage=50, facility_workbench=40） |
| `current_hardness` | int | 0-base_hardness | 当前剩余硬度 |
| `damage_amount` | int | 0-∞ | 单次攻击伤害值 |

**Output:** `new_health_ratio` ∈ [0.0, 1.0]

**State Transition Triggers:**
- `new_health_ratio < 0.30` → DAMAGED state
- `new_health_ratio <= 0.0` → DESTROYED state

**Example:** base_hardness=50, current_hardness=35, damage_amount=20 → damage_ratio=0.4 → new_health_ratio=0.7-0.4=0.3 → DAMAGED state triggered

---

### Formula 6: Demolition Material Refund

**拆除材料返还计算：**

```
refund_amount_i = floor(material_cost_i × DEMOLITION_REFUND_RATE)
```

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `material_cost_i` | int | BuildItemDB定义 | 建造时消耗的材料i数量 |
| `DEMOLITION_REFUND_RATE` | float | 0.50 (50%) | 拆除返还比例（Tuning Knob） |

**Output:** `refund_amount_i` ∈ [0, floor(material_cost_i × 0.5)]

**Example:** facility_storage成本=铁×4, 木×6 → refund: 铁×2, 木×3

## Edge Cases

### Edge Case 1: Storage Box Full - Deposit Overflow

**If deposit request exceeds capacity:**

| Scenario | Input | Expected Behavior |
|----------|-------|-------------------|
| 所有槽位已满（100/100） | deposit 50铁矿 | 返回0，显示"储物箱已满"，无存入 |
| 有空槽但单槽堆叠上限 | deposit 100铁矿到已有900铁矿槽位 | 存入99（堆叠至999），剩余1存入新槽位或返回 |
| 空槽位不足 | deposit 200铁矿，只有1空槽位 | 存入999到新槽位，剩余101返回玩家背包 |

**Implementation:** `deposit_resource()`返回实际存入数量，玩家背包/仓库保留未存入部分。UI显示差异提示。

---

### Edge Case 2: Crafting Cancelled Mid-Progress

**If player closes workbench UI or changes recipe during crafting:**

| Scenario | Input | Expected Behavior |
|----------|-------|-------------------|
| 合成进度50% | 玩家关闭界面 | 合成暂停，进度保存，下次打开继续 |
| 合成进度50% | 玩家切换到另一个配方 | 前一个合成取消，材料100%返还，魔能100%返还 |
| 合成进度50% | 战车离开魔能范围 | 合成暂停，显示"魔能连接断开"，等待恢复 |
| 合成进度90% | 设施被攻击进入DAMAGED | 合成取消，材料返还，魔能返还，设施锁定 |

**Refund Policy:** 合成取消时，100%返还已扣除材料和魔能。暂停不返还，恢复后继续。

---

### Edge Case 3: Vehicle Leaves Magic Connection Range

**If vehicle moves away during crafting:**

| Scenario | Input | Expected Behavior |
|----------|-------|-------------------|
| 合成进行中，战车移动超出10格 | distance > MAGIC_CONNECTION_RANGE | 合成暂停，进度保存，界面显示"魔能连接断开" |
| 战车返回范围内 | distance <= MAGIC_CONNECTION_RANGE | 合成自动恢复，继续累加progress |
| 战车魔能耗尽 | magic_ratio = 0 | 无法启动新合成，已有合成继续（魔能已扣除） |
| 战车被摧毁 | vehicle destroyed | 所有合成取消，材料返还到地面掉落 |

**Implementation:** 每帧检查`_validate_magic_connection()`，暂停时停止progress累加，恢复后继续。

---

### Edge Case 4: Facility DAMAGED State - Function Lock

**If facility enters DAMAGED state (health_ratio < 0.30):**

| Facility Type | Function Status | Player Experience |
|---------------|-----------------|-------------------|
| 储物箱 (400) | 存取功能锁定 | 显示"储物箱损坏，无法存取"，物品保留在内部 |
| 工作台 (410) | 合成功能锁定 | 显示"工作台损坏，无法合成"，暂停中合成取消并返还材料/魔能 |
| 通用 | 视觉反馈 | 设施显示裂缝纹理，闪烁红色警告光效 |

**Recovery:** 玩家使用修复工具修复至health_ratio≥50% → 恢复ACTIVE状态，功能解锁。

**DAMAGED期间内容保护:** 储物箱内容不丢失，锁定期间无法存取，损坏后正常掉落。

---

### Edge Case 5: Multiple Player Interaction (Multi-player Reserved)

**If two players try to interact with same facility simultaneously:**

MVP is single-player. This edge case is reserved for Alpha/Vertical Slice co-op implementation.

| Scenario | MVP Behavior | Post-MVP Design |
|----------|--------------|-----------------|
| 玩家A交互储物箱，玩家B点击同一储物箱 | MVP无多人，不触发 | 多人共享界面，各自操作独立槽位 |
| 玩家A在工作台合成，玩家B打开同一工作台 | MVP无多人，不触发 | 多人共享，排队合成队列 |

**MVP Implementation:** 单玩家锁定，无并发处理。

---

### Edge Case 6: New Resource ID Collision

**If crafted resource IDs (151, 152, 160) need to be registered:**

| Scenario | Expected Behavior |
|----------|-------------------|
| ResourceDatabase未定义ID 151/152/160 | 本GDD完成后必须同步更新ResourceDatabase |
| Recipe输出ID不存在于ResourceDatabase | 系统启动时验证recipe.output_id，无效recipe被禁用并log warning |
| 玩家持有合成产物但ID不存在（异常数据） | fallback显示为"未知资源"，保留quantity，不丢弃 |

**Resolution Path:** 本GDD设计完成后，更新ResourceDatabase新增：
- 铁锭 (ID 151): `is_craftable_output=1, base_value=6`
- 铜锭 (ID 152): `is_craftable_output=1, base_value=9`
- 基础零件 (ID 160): `is_craftable_output=1, base_value=15`

---

### Edge Case 7: Facility Built Outside Logical Bunker Area

**If player places facility outside conventional bunker location:**

MVP无"地堡边界"概念，设施可放置在任何Layer 2有效位置。

| Scenario | MVP Behavior |
|----------|--------------|
| 设施放置在地表（远离入口） | 允许，但可能被尸潮攻击 |
| 设施放置在深层矿洞 | 允许，需玩家自行规划可达性 |
| 设施放置在敌人必经路径 | 允许，高风险（会被攻击） |

**Post-MVP:** 可能引入"地堡区域"限制，设施必须放置在已挖掘的安全区域内。

---

### Edge Case 8: Withdraw Request for Non-existent Resource

**If player requests withdraw for resource_id not in storage:**

| Scenario | Expected Behavior |
|----------|-------------------|
| withdraw(101, 50)但storage中无铁矿 | 返回0，UI显示"储物箱中无此资源" |
| withdraw(101, 100)但storage只有30铁矿 | 返回30，UI显示"取出数量不足，实际取出30" |
| withdraw在DAMAGED状态下调用 | 返回0，显示"储物箱损坏，无法存取" |

**Implementation:** `withdraw_resource()`返回实际取出数量（0表示失败），UI显示差异提示。

---

### Edge Case 9: Drop Expiration Before Pickup

**If facility destroyed drops expire (30s) before player collects:**

| Scenario | Expected Behavior |
|----------|-------------------|
| 储物箱损坏，掉落30秒后消失 | 资源永久丢失，无挽回 |
| 玩家远离掉落位置，30秒内未返回 | 掉落消失，无法追踪 |
| 多个掉落堆叠在同一位置 | 各独立掉落实体，各自30秒有效期 |

**Design Intent:** 30秒有效期创造"抢救压力"，服务于Pillar 3（尸潮即高潮）的紧张决策体验。

---

### Edge Case 10: Facility Tile Removed by Digging

**If player digs facility tile instead of using demolition tool:**

| Scenario | Expected Behavior |
|----------|-------------------|
| 玩家使用挖掘工具拆除设施Tile | 触发方块挖掘系统逻辑 → 返还50%材料（与拆除一致） |
| 设施Tile被挖掘系统处理 | FacilityManager监听`block_removed`信号 → 销毁实体 → 触发内容掉落 |
| 挖掘中途取消（进度未完成） | 设施未移除，无影响 |

**Consistency:** 挖掘和拆除共享50%返还率，确保玩家行为有一致预期。储物箱内容100%掉落（两种方式一致）。

---

### Edge Case 11: Facility Entity Lost on Scene Reload

**If TileMap chunk unloads/reloads with facility:**

| Scenario | Expected Behavior |
|----------|-------------------|
| Chunk containing facility unloaded | FacilityEntity状态保存到chunk数据，reload时恢复 |
| Player moves away, chunk unloads with active crafting | 合成暂停，进度保存，reload恢复 |
| Save/load game with facilities | 所有FacilityEntity序列化到save file，load时重建 |

**Implementation:** FacilityManager监听TileMap chunk事件，序列化/反序列化设施状态（参照TileMap世界系统chunk持久化）。

## Dependencies

### Upstream Dependencies (Required)

| System | Layer | Data Provided | Interface | Dependency Type |
|--------|-------|---------------|-----------|-----------------|
| **TileMap世界系统** (#1) | Foundation | Layer 2 cell state, chunk persistence | `get_cell_tile_data(coords)` → TileData<br>`chunk_serialize()` / `chunk_deserialize()` | **Blocking** — Facility entities bind to TileMap cells |
| **建造物品数据库** (#5) | Foundation | Build item definitions: build_item_id, category, material_costs | `BuildItemDB.get_build_item(build_item_id)` → BuildItem struct<br>`BuildItemDB.get_build_item_for_tile(tile_id)` → int | **Blocking** — Cannot determine facility type without mapping |
| **BlockTypeDatabase** (#2) | Foundation | Tile properties: hardness, buildability | `BlockTypeDB.get_by_tile_id(tile_id)` → BlockType struct | **Blocking** — Damage calculation requires hardness |
| **方块放置系统** (#13) | Core | Placement signal for facility category | Signal: `block_placed(cell, tile_id, player_id)` | **Blocking** — Facility creation trigger |
| **建造验证系统** (#45) | Feature | Placement validation (already passed) | V1-V6 rules validated before placement | **Soft** — Validation already executed, facility system assumes valid placement |
| **战车属性系统** (#17) | Core | Magic energy pool for crafting power | `VehicleAttributeSystem.get_magic_ratio()` → float<br>`VehicleAttributeSystem.get_position()` → Vector2<br>`VehicleAttributeSystem.consume_magic(amount)` → bool | **Blocking** — Workbench magic power source |
| **资源数据库** (#3) | Foundation | Resource definitions for storage validation | `ResourceDB.get_resource(resource_id)` → Resource struct<br>`ResourceDB.is_valid_resource(resource_id)` → bool | **Blocking** — Storage slot validation |
| **资源掉落系统** (#14) | Core | Drop entity spawning for content drop | `ResourceDropSystem.spawn_drop(cell, resource_id, quantity)` | **Blocking** — Facility destruction drop spawn |

### Downstream Dependent Systems

| System | Layer | Data Consumed | Interface Provided | Dependency Type |
|--------|-------|---------------|-------------------|-----------------|
| **战车仓库系统** (#29) | Feature | Storage transfer destination | `StorageBox.deposit/withdraw` API<br>Transfer UI integration | **Blocking** — Vehicle warehouse ↔ Storage box transfer |
| **资源合成系统** (#44) | Feature | Crafting recipe execution | `Workbench.start_craft(recipe_id)`<br>`Workbench.cancel_craft()` | **Indirect** — Workbench is entry point, synthesis system defines recipes |
| **雨水收集系统** (#56) | Eco | Facility entity framework (extension) | Same FacilityEntity pattern | **Non-blocking** — Eco system extends facility framework |
| **种田系统** (#57) | Eco | Facility entity framework (extension) | Same FacilityEntity pattern | **Non-blocking** — Eco system extends facility framework |
| **HUD系统** (#49) | Presentation | Storage UI, Crafting UI | Facility interaction triggers UI panels | **Non-blocking** — UI renders facility state |

### Bidirectional Reference Contract

**方块放置系统GDD** (block-placing-system.md) must update Dependencies section:
- Add "地堡设施系统 (#46) — **Blocking**" to Downstream Dependent Systems
- Interface: Signal `block_placed(cell, tile_id, player_id)` → Facility system creates entity

**战车仓库系统GDD** (pending) must reference:
- Interface: `StorageBox.get_all_contents()` → transfer UI
- Interface: `StorageBox.deposit_resource()` / `withdraw_resource()`

### Dependency Interface Contract

**Data Contract (从上游读取):**

| Interface | Return Type | Failure Mode | Consumer Contract |
|-----------|-------------|--------------|-------------------|
| `BuildItemDB.get_build_item_for_tile(tile_id)` | int or 0 | Returns 0 for non-facility tiles | Facility system checks > 0 before creating entity |
| `BlockTypeDB.get_by_tile_id(tile_id)` | BlockType or null | Returns null for invalid ID | Damage calculation fails gracefully if null |
| `VehicleAttributeSystem.get_magic_ratio()` | float | Returns 0.0 if vehicle not deployed | Workbench shows "魔能连接断开" |
| `VehicleAttributeSystem.consume_magic(amount)` | bool | Returns false if insufficient | Crafting cancelled with refund |

**Trigger Contract (向下游发射):**

| Signal | When | Data Passed | Consumer Contract |
|--------|------|-------------|-------------------|
| `facility_created(facility_entity)` | On entity creation | FacilityEntity struct | HUD/UI registers for interaction events |
| `facility_destroyed(cell, build_item_id)` | On entity destruction | cell: Vector2i, build_item_id: int | Stats system tracks facility loss; Chunk persistence removes record |
| `facility_state_changed(facility_id, new_state)` | On state transition | facility_id: int, new_state: FacilityState | UI updates damage indicator |
| `craft_completed(recipe_id, output)` | On crafting finish | recipe_id: int, output: {resource_id, quantity} | Backpack/VehicleWarehouse receives output |

### Provisional Dependencies

**ResourceDatabase更新:** 需要在本GDD完成后新增铁锭(151)、铜锭(152)、基础零件(160)。当前ResourceDatabase未包含这些ID，属于跨系统数据同步需求。

**战车仓库系统GDD未设计:** 本GDD假设战车仓库提供`transfer_to_storage_box()`和`transfer_from_storage_box()`接口，待战车仓库系统(#29)设计时确认接口契约。

### Dependency Risk Assessment

| Dependency | Risk | Mitigation |
|------------|------|------------|
| TileMap世界系统 | LOW — GDD exists, chunk persistence defined | Standard signal listener pattern |
| 战车属性系统 | LOW — GDD exists, magic API stable | Direct method calls |
| 资源掉落系统 | LOW — GDD exists, spawn_drop interface defined | Standard entity spawning |
| 战车仓库系统 | MEDIUM — GDD not yet designed | Assume Dictionary interface, document provisional assumption |
| 资源合成系统 | LOW — Vertical Slice, not MVP blocking | MVP uses provisional recipes in FacilitySystem |

## Tuning Knobs

### Primary Tuning Knobs (影响核心玩法)

| Knob ID | Knob Name | Default Value | Safe Range | Gameplay Effect | Pillar Affected |
|---------|-----------|---------------|------------|-----------------|-----------------|
| **TK-032** | `STORAGE_SLOT_COUNT` | 100 slots | 50-200 | 单储物箱容量。提高 → 单箱足够 → 减少多箱布局；降低 → 需多箱分区 → 增加规划复杂度 | 堡垒生态闭环 |
| **TK-033** | `MAGIC_CONNECTION_RANGE` | 10.0 cells | 5.0-20.0 | 工作台魔能连接距离。提高 → 工作台随处可用 → 布局自由；降低 → 需靠近战车 → 增加布局约束 | 搜打撤节奏 |
| **TK-034** | `CRAFT_MAGIC_COST_BASE` | 8 magic | 5-15 | 基础配方魔能消耗。提高 → 合成昂贵 → 减少合成频率；降低 → 合成廉价 → 增加资源转化 | 搜打撤节奏 |
| **TK-035** | `CRAFT_TIME_BASE` | 10 seconds | 5-20 | 基础配方合成时间。提高 → 合成缓慢 → 增加等待成本；降低 → 合成快速 → 减少时间压力 | 搜打撤节奏 |
| **TK-036** | `DROP_EXPIRATION_SECONDS` | 30.0 | 15.0-60.0 | 设施损坏掉落有效期。提高 → 抢救窗口宽松 → 减少惩罚；降低 → 抢救窗口紧迫 → 增加惩罚 | Pillar 3: 尸潮即高潮 |
| **TK-037** | `DEMOLITION_REFUND_RATE` | 0.50 (50%) | 0.30-0.80 | 设施拆除材料返还。提高 → 拆除成本低 → 允许布局调整；降低 → 拆除成本高 → 增加布局承诺 | 堡垒生态闭环 |

### Secondary Tuning Knobs (配方细节)

| Knob ID | Knob Name | Default Value | Safe Range | Recipe Affected |
|---------|-----------|---------------|------------|-----------------|
| **TK-038** | `RECIPE_IRON_INPUT` | 5 铁矿 | 3-8 | R001: 铁矿→铁锭 |
| **TK-039** | `RECIPE_IRON_MAGIC_COST` | 8 魔能 | 5-12 | R001: 铁矿→铁锭 |
| **TK-040** | `RECIPE_IRON_TIME` | 10 sec | 5-15 | R001: 铁矿→铁锭 |
| **TK-041** | `RECIPE_COPPER_INPUT` | 5 铜矿 | 3-8 | R002: 铜矿→铜锭 |
| **TK-042** | `RECIPE_COPPER_MAGIC_COST` | 8 魔能 | 5-12 | R002: 铜矿→铜锭 |
| **TK-043** | `RECIPE_COPPER_TIME` | 10 sec | 5-15 | R002: 铜矿→铜锭 |
| **TK-044** | `RECIPE_CRYSTAL_INPUT` | 3 晶石碎片 | 2-5 | R003: 晶石碎片→晶石簇 |
| **TK-045** | `RECIPE_CRYSTAL_MAGIC_COST` | 15 魔能 | 10-20 | R003: 晶石碎片→晶石簇 |
| **TK-046** | `RECIPE_CRYSTAL_TIME` | 15 sec | 10-20 | R003: 晶石碎片→晶石簇 |
| **TK-047** | `RECIPE_PART_MAGIC_COST` | 12 魔能 | 8-18 | R004: 铁锭+铜锭→基础零件 |
| **TK-048** | `RECIPE_PART_TIME` | 12 sec | 8-18 | R004: 铁锭+铜锭→基础零件 |

### Facility Hardness (继承BlockTypeDatabase)

| Facility | Tile ID | Base Hardness | DAMAGED Threshold | Notes |
|----------|---------|---------------|-------------------|-------|
| 储物箱 (400) | 2000 | 50 | <15 (30%) | 中等硬度，可被尸潮攻击损坏 |
| 工作台 (410) | 2001 | 40 | <12 (30%) | 较低硬度，精密设备易损坏 |

**Hardness Tuning Note:** 设施硬度由BlockTypeDatabase定义，本系统继承。若需调整硬度，更新BlockTypeDatabase而非本系统。

### Cross-System Tuning Knobs (依赖其他系统)

| Knob | Owner System | Default | Effect on Facility |
|------|--------------|---------|---------------------|
| `CELL_SIZE` | TileMap世界系统 | 32 px | MAGIC_CONNECTION_RANGE像素计算基准 |
| `MAX_STACK` | ResourceDatabase | 999 | 单槽堆叠上限（影响单槽容量） |
| `vehicle_magic_max` | 战车属性系统 | per vehicle type | 战车魔能池上限（影响合成可用魔能） |

### Knobs That Should NOT Be Tuned

| Knob | Reason |
|------|--------|
| `STORAGE_SLOT_COUNT = 100` | 与战车仓库相等是设计决策，确保单箱足够对应一次搜刮 |
| `DEMOLITION_REFUND_RATE = 50%` | 与墙体拆除一致，确保玩家行为有一致预期 |
| `DROP_EXPIRATION_SECONDS` | 30秒是Pillar 3紧张感的关键参数，不宜过长 |
| Recipe input/output ratios | 输入输出比例是平衡决策，改动需同步更新ResourceDatabase价值 |

### Tuning Scenarios

**Scenario A: 储物箱容量太小 → 玩家被迫建造过多储物箱**
- Symptom: Player needs 5+ storage boxes, cluttered bunker layout
- Adjustment: Increase `STORAGE_SLOT_COUNT` from 100 to 150
- Expected outcome: Player needs fewer boxes, cleaner layout, more space for defenses

**Scenario B: 工作台魔能消耗太高 → 玩家不敢合成**
- Symptom: Player hoards raw materials instead of crafting
- Adjustment: Reduce `CRAFT_MAGIC_COST_BASE` from 8 to 5
- Expected outcome: More frequent crafting, higher resource conversion rate

**Scenario C: 掉落有效期太短 → 玩家来不及抢救**
- Symptom: Player loses valuable resources frequently, frustration
- Adjustment: Increase `DROP_EXPIRATION_SECONDS` from 30 to 45
- Expected outcome: More forgiving salvage window, less punishment

**Scenario D: 魔能连接距离太短 → 工作台布局受限**
- Symptom: Player must place workbench very close to vehicle parking spot
- Adjustment: Increase `MAGIC_CONNECTION_RANGE` from 10 to 15 cells
- Expected outcome: More flexible workbench placement, better bunker zoning

### Tuning Validation Advisory

> **⚠️ Playtest Required**: 当前默认值来自设计假设。建议测试：
> - 如果储物箱容量不足 → 提高`STORAGE_SLOT_COUNT`或允许多箱互联
> - 如果魔能消耗过高 → 降低`CRAFT_MAGIC_COST_BASE`或调整配方消耗
> - 如果掉落过期太快 → 提高`DROP_EXPIRATION_SECONDS`到45秒
> - 如果魔能连接不稳定 → 提高`MAGIC_CONNECTION_RANGE`或增加连接稳定提示

## Acceptance Criteria

### Entity Creation Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-01** | Facility entity created on placement | Place facility_storage (400), verify FacilityEntity registered | `FacilityManager.get_facility_at(cell)` returns valid entity with build_item_id=400 |
| **AC-02** | Facility entity binds to correct cell | Place facility at cell (15, 20), verify entity.cell matches | entity.cell = Vector2i(15, 20) |
| **AC-03** | Facility state initialized to IDLE | Create new facility entity, verify initial state | entity.state = FacilityState.IDLE |
| **AC-04** | Storage contents initialized empty | Create storage_box entity, verify contents | storage_contents.size() = 100, all slots have resource_id=0, quantity=0 |
| **AC-05** | Facility ignores non-facility placement | Place wall (category=0), verify no entity created | `FacilityManager.get_facility_at(cell)` returns null |
| **AC-06** | Multiple facilities tracked independently | Place 3 storage boxes at different cells, verify each registered | `FacilityManager.get_all_facilities()` returns 3 entities with distinct facility_id |

### Storage Box Functionality Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-07** | Deposit to empty slot succeeds | Deposit 铁矿×50 to empty storage box | Returns 50, slot[0] = {101, 50} |
| **AC-08** | Deposit to existing slot stacks | Deposit 铁矿×30 to slot with {101, 200} | Returns 30, slot becomes {101, 230} |
| **AC-09** | Deposit rejects when full | Fill all 100 slots, attempt deposit 铁矿×50 | Returns 0, displays "储物箱已满" |
| **AC-10** | Deposit caps at stack limit | Deposit 铁矿×100 to slot with {101, 900} | Returns 99, slot becomes {101, 999}, remaining 1 to new slot or returned |
| **AC-11** | Withdraw exact amount succeeds | Withdraw 铁矿×30 from slot with {101, 100} | Returns 30, slot becomes {101, 70} |
| **AC-12** | Withdraw partial when insufficient | Withdraw 铁矿×100 from slot with {101, 50} | Returns 50, slot becomes {101, 0} then cleared, displays "取出数量不足" |
| **AC-13** | Withdraw zero for non-existent resource | Withdraw 铁矿×50 from box with no 铁矿 | Returns 0, displays "储物箱中无此资源" |
| **AC-14** | Storage capacity query correct | Fill 80 slots, query remaining_slots | remaining_slots = 20 |
| **AC-15** | Storage locked in DAMAGED state | Damage storage box to health_ratio=0.25, attempt deposit | Returns 0, displays "储物箱损坏，无法存取" |

### Workbench Crafting Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-16** | Recipe list displays correctly | Open workbench UI, verify 4 MVP recipes shown | R001, R002, R003, R004 visible with correct input/output |
| **AC-17** | Crafting starts with valid conditions | Select R001, have 5铁矿, vehicle magic≥8, distance≤10 | Crafting starts, progress bar appears, materials deducted |
| **AC-18** | Crafting fails without materials | Select R001, have 2铁矿 only | Displays "材料不足: 铁矿 缺少3", no crafting start |
| **AC-19** | Crafting fails without magic | Select R001, vehicle magic=5 | Displays "魔能不足", no crafting start |
| **AC-20** | Crafting fails without magic connection | Move vehicle to 15 cells away, select recipe | Displays "魔能连接断开", no crafting start |
| **AC-21** | Crafting progress updates | Monitor crafting over 10 seconds | Progress increases from 0% to 100% in 10s |
| **AC-22** | Crafting completes with output | Complete R001 crafting | Output: 铁锭×1 (ID 151) added to player backpack |
| **AC-23** | Crafting cancelled with refund | Cancel crafting at 50% progress | Materials returned, magic returned, progress cleared |
| **AC-24** | Crafting paused on magic disconnect | Start crafting, move vehicle out of range | Progress pauses at current %, displays "魔能连接断开" |
| **AC-25** | Crafting resumes on reconnect | Pause crafting, return vehicle to range | Progress continues from paused % |

### Facility Damage Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-26** | Facility health decreases on attack | Attack storage box, verify health_ratio update | health_ratio decreases proportionally to damage |
| **AC-27** | DAMAGED state triggers at 30% | Attack until health_ratio < 0.30 | State = DAMAGED, visual cracks appear, function locked |
| **AC-28** | DESTROYED state triggers at 0% | Attack until health_ratio = 0 | State = DESTROYED, entity unregistered, content dropped |
| **AC-29** | Content drops on destruction | Destroy storage box with {101, 50}, verify drops | ResourceDropEntity spawned at cell with {101, 50} |
| **AC-30** | Drops expire after 30 seconds | Destroy storage box, wait 30s, verify drops | Drops despawn, cannot be picked up |
| **AC-31** | Workbench crafting cancelled on DAMAGED | Crafting in progress, damage to 25% | Crafting cancelled, materials/magic refunded |
| **AC-32** | Facility repaired to ACTIVE | Use repair tool on DAMAGED facility (health=0.25) until 0.50 | State = ACTIVE, function unlocked |

### Facility Removal Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-33** | Demolition returns 50% materials | Demolish facility_storage (cost: 铁×4, 木×6) | Refund: 铁×2, 木×3 spawned as drops |
| **AC-34** | Demolition drops storage contents | Demolish storage box with {101, 50} | Content drops: {101, 50} spawned (100% content, separate from refund) |
| **AC-35** | Demolition warning for non-empty storage | Attempt demolish storage with contents | Displays "储物箱内有物品，拆除将全部掉落", requires confirmation |
| **AC-36** | Digging triggers same logic | Use digging tool on facility tile | Same 50% refund, same content drops as demolition |
| **AC-37** | Facility entity unregistered on removal | Remove facility, verify unregistration | `FacilityManager.get_facility_at(cell)` returns null |

### Integration Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-38** | block_placed signal triggers entity creation | Emit signal for facility tile placement | FacilityEntity created within same frame |
| **AC-39** | Vehicle warehouse can transfer to storage box | Open vehicle warehouse UI, drag item to storage box | Item moved, both UIs update |
| **AC-40** | Storage box persists on chunk reload | Place storage, move away (chunk unload), return | Storage entity restored with same contents |
| **AC-41** | Crafting output routes correctly | Complete crafting with backpack full | Output routes to vehicle warehouse instead |
| **AC-42** | Magic connection displays in UI | Open workbench UI near vehicle | Shows "魔能连接：战车魔能池 (剩余: XX%)" |
| **AC-43** | Magic connection breaks in UI | Open workbench UI 15 cells from vehicle | Shows "魔能连接断开，请靠近战车" |

### Performance Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-44** | Entity creation ≤5ms | Measure time from signal to entity registered | Execution time ≤5ms |
| **AC-45** | Deposit/withdraw ≤2ms | Execute 100 deposit/withdraw operations, measure average | Average ≤2ms |
| **AC-46** | Crafting progress update ≤1ms per frame | Profile crafting loop over 100 frames | Per-frame update ≤1ms |
| **AC-47** | 100 facilities tracked without degradation | Create 100 storage boxes, verify query performance | `get_facility_at()` ≤1ms, `get_all_facilities()` ≤10ms |
| **AC-48** | Drop spawn ≤3ms | Destroy facility with 50 slots filled, measure drop spawn time | All drops spawned within 150ms total |

### Pass/Fail Threshold

| Category | Pass Requirement | Fail Action |
|----------|------------------|-------------|
| **Entity Creation (AC-01 to AC-06)** | 100% pass | 任一失败 → 实体创建逻辑错误，必须修复 |
| **Storage (AC-07 to AC-15)** | 100% pass | 任一失败 → 存取功能错误，必须修复 |
| **Workbench (AC-16 to AC-25)** | 100% pass | 任一失败 → 合成功能错误，必须修复 |
| **Damage (AC-26 to AC-32)** | 100% pass | 任一失败 → 损坏处理错误，必须修复 |
| **Removal (AC-33 to AC-37)** | 100% pass | 任一失败 → 拆除逻辑错误，必须修复 |
| **Integration (AC-38 to AC-43)** | 100% pass | 任一失败 → 跨系统契约违反，必须修复 |
| **Performance (AC-44 to AC-48)** | 100% pass | 任一失败 → 性能优化 |

**Total Criteria**: 48
**Required for Implementation**: 100% pass on all categories

## Open Questions

### High Priority (Implementation Blocking)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-001** | 新资源ID（铁锭151、铜锭152、基础零件160）是否需要同步更新ResourceDatabase？当前ResourceDatabase未包含这些合成产物。 | ResourceDatabase维护者 | Facility system实现前 | Recipe输出无法验证，合成无法完成 |
| **Q-002** | 战车仓库系统(#29)的transfer接口是否已定义？本GDD假设`transfer_to_storage_box()`和`transfer_from_storage_box()`接口存在。 | 战车仓库系统设计者 | 战车仓库系统实现前 | 无法实现储物箱-战车仓库物品转移 |
| **Q-003** | 设施Tile ID（储物箱2000、工作台2001）是否在BlockTypeDatabase已定义？BlockTypeDatabase需同步新增这些tile定义。 | BlockTypeDatabase维护者 | BlockTypeDatabase实现前 | Facility tile无法放置（output_tile_id验证失败） |

### Medium Priority (Design Clarification)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-004** | 工作台合成产出优先存入玩家背包还是战车仓库？当前设计优先背包，背包满则战车仓库。 | Game Designer | MVP实现前 | 物品流向需要明确，避免玩家困惑 |
| **Q-005** | 储物箱是否支持快速堆叠（Shift+点击全部同类型资源）？当前设计仅支持手动单次操作。 | UX Designer | UX设计阶段 | 影响交互效率和玩家体验 |
| **Q-006** | 设施DAMAGED状态的修复机制是否需要独立修复系统？当前设计假设有修复工具，但修复系统GDD未设计。 | 修复系统设计者 | 修复功能实现前 | DAMAGED设施无法恢复ACTIVE |

### Low Priority (Future Consideration)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-007** | 多个储物箱是否支持互联（合并容量）？当前设计各箱独立100格。 | Game Designer | Vertical Slice | 影响地堡布局和存储管理策略 |
| **Q-008** | 工作台是否支持配方收藏/快捷键？当前设计每次需打开UI选择。 | UX Designer | UX设计阶段 | 影响频繁合成操作的效率 |
| **Q-009** | 设施是否支持升级（如基础储物箱→大型储物箱）？当前设计无升级机制。 | Game Designer | Alpha阶段 | 影响后期存储扩展需求 |
| **Q-010** | Vertical Slice阶段魔力发电机如何工作？当前MVP工作台直接连战车魔能池。 | 魔力发电机系统设计者 | Vertical Slice | 需要重新设计魔能供应机制 |

### Resolution Tracking

| ID | Status | Resolution Date | Resolved By | Resolution Summary |
|----|--------|-----------------|-------------|-------------------|
| Q-001 | Open | — | — | Pending ResourceDatabase更新 |
| Q-002 | Open | — | — | Pending 战车仓库系统GDD |
| Q-003 | Open | — | — | Pending BlockTypeDatabase更新 |
| Q-004 | Resolved | 2026-04-24 | Design Decision | 优先背包，背包满则战车仓库（fallback机制） |
| Q-005 | Open | — | — | Pending UX设计阶段 |
| Q-006 | Open | — | — | Pending 修复系统GDD |
| Q-007 | Open | — | — | Alpha scope |
| Q-008 | Open | — | — | UX design scope |
| Q-009 | Open | — | — | Alpha scope |
| Q-010 | Open | — | — | Vertical Slice scope |

### Assumptions Made (Temporary Decisions)

| Assumption | Rationale | Risk |
|------------|-----------|------|
| **铁锭(151)、铜锭(152)、基础零件(160) ID已分配** | 新ID不会冲突，ResourceDatabase预留了151-200合成产物区间 | 需同步更新ResourceDatabase |
| **战车仓库transfer接口签名** | `transfer_to(target_entity, resource_id, amount)` → int | 接口可能不同，需要适配 |
| **修复工具存在但GDD未设计** | MVP简化：假设玩家有修复工具 | 修复系统需后续设计 |
| **单玩家锁定** | MVP scope，无多人 | Alpha需重新设计多人并发 |
| **工作台合成产出优先背包** |背包容量较小（20格），背包满则fallback到仓库 | UX需测试玩家是否理解 |

### Cross-System Data Sync Required

本GDD完成后需要同步更新以下系统：

| System | Update Required | Data to Add |
|--------|-----------------|-------------|
| **ResourceDatabase** (#3) | 新增合成产物资源ID | 铁锭(151)、铜锭(152)、基础零件(160) — 各需is_craftable_output=1, base_value定义 |
| **BlockTypeDatabase** (#2) | 新增设施Tile定义 | facility_storage_basic(2000): hardness=50, buildability=1<br>facility_workbench(2001): hardness=40, buildability=1 |
| **BuildItemDatabase** (#5) | 验证output_tile_id映射 | 确认400→2000, 410→2001映射已定义（当前已存在） |
| **systems-index.md** | 更新系统状态 | 地堡设施系统(#46): status="Designed" |