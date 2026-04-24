# 方块挖掘系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 2 (搜打撤节奏), Pillar 3 (尸潮即高潮)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #12 (from systems-index.md)

## Overview

方块挖掘系统是玩家与世界交互的核心动作层——玩家按下"挖掘"键，系统从TileMapLayer读取方块硬度，计算每帧的伤害积累，在进度条达到阈值时删除方块并移除碰撞。它将**方块类型数据库**的硬度数据转化为玩家感知的"挖掘手感"，将**TileMap世界系统**的cell操作转化为世界中的物理改变，将**输入控制系统**的`dig`动作转化为有反馈的交互循环。

**基础设施角色**：系统管理每个cell的`damage_accumulated`运行时状态（继承自TileMap世界系统），响应输入持续挖掘，在damage达到hardness时触发方块删除。删除操作排队到物理帧边界（通过方块碰撞系统的`queue_tile_modification`），确保物理引擎不会在碰撞形状更新期间产生不一致。

**玩家影响层**：挖掘是玩家扩展地堡、获取资源、创造防御开口的唯一方式。玩家直接感知：
- **材料抵抗感**：沙土(hardness=5)三秒挖穿，岩石(hardness=60)需要持续努力，秘银矿脉(hardness=180)考验耐心——硬度值转化为玩家手感的"阻力等级"
- **时间决策压力**：挖掘进度条显示剩余时间，玩家在高硬度方块前必须评估"花这么多时间值得吗？撤退时限够吗？"——服务于Pillar 2（搜打撤节奏）
- **反馈即时性**：每次挖掘帧产生进度条变化、粒子飞溅、音效脉冲——玩家知道"我的动作正在生效"

**核心价值**：没有方块挖掘系统，世界是不可改变的静态地图；有了它，玩家才能向下扩张、挖掘防御通道、获取资源、在尸潮前紧急加固。挖掘创造**可能性**——地堡从固定布局变为玩家设计的空间。

## Player Fantasy

### 核心幻想：废土工程师的精心开采

玩家是废土探矿者，每一次挥击都在**有意识地开采大地**。挖掘不是简单的资源采集，而是**工程行为**：硬度值转化为时间成本，进度条转化为反馈循环，每一块方块的破坏都是玩家与世界互动的痕迹。

**锚定时刻：面对岩壁的节奏感**

玩家的光标悬停在岩壁上。硬度读数：60。进度条开始爬行——绿→黄→红。每一帧的粒子飞溅、音效脉冲，都在说"你正在改变世界"。这是废土工程师的日常——耐心、节奏、观察。看着沙土三秒消失，岩石需要持续专注，秘银矿脉考验毅力。

**玩家应该感受到**：
- **工程成就感**：看着进度条稳步前进，每一下都有反馈
- **节奏掌控**：不同硬度创造不同挖掘节奏——快速扫清沙土，稳步攻坚岩石
- **世界改变感**：每个空掉的cell都是玩家留下的痕迹——"这是我挖开的通道"

**情感变奏：建成后的成就感**

挖掘完成后，玩家站在新扩张的地下房间里。他们记得：那块花了一整个夜晚才挖穿的砂岩墙，那根秘银支撑梁前的耐心等待。堡垒不只是避难所——它是玩家用时间和工具换取的空间。

**支撑的情感支柱**：
- Pillar 2（搜打撤节奏）：硬度创造"时间成本"差异——不同方块需要不同投资
- Pillar 3（尸潮即高潮）：辛苦建成的防御墙被攻击时，玩家有保护本能——"这是我花时间建成的"

**语言风格**：使用"开采"、"精心挖掘"、"节奏感"、"时间成本"等工程词汇。大地是**可被改变的**，玩家是工程师。反馈强调：粒子飞溅、进度条脉动、音效节奏——每一帧都在说"你的动作正在生效"。

## Detailed Design

### Core Rules

**Rule 1: Damage Accumulation Model**

每帧挖掘产生固定伤害，累加至cell的`damage_accumulated`状态：

1. 当玩家持续按住`dig`输入时，系统每物理帧计算伤害增量：
   - `damage_this_frame = BASE_DIG_RATE * tool_modifier * delta_time`
   - Where `delta_time` is the physics frame duration (≈1/60 sec at 60 fps)
2. 累加伤害：`damage_accumulated += damage_this_frame`
3. Clamp防止超额积累：`damage_accumulated = min(damage_accumulated, hardness)`
4. 当`damage_accumulated >= hardness`时，触发方块删除流程
5. 每个cell维护独立的`damage_accumulated`状态（存储在TileMap世界系统的runtime数据中）
6. 松开`dig`或切换目标时，当前cell的伤害状态保留——下次继续从该值累加

**Rule 2: Target Selection and Validation**

系统每帧验证挖掘目标的有效性：

1. 从玩家战车位置发射指向光标方向的射线，最大距离`MAX_DIG_RANGE=3.0 cells`
2. 射线碰撞检测返回第一个碰撞的TileMapLayer cell坐标
3. 验证条件：
   - `cell_exists(layer_1, coords)` → cell存在于Layer 1（地面层）
   - `is_diggable(block_id)` → 方块类型数据库标记该block_id为`diggable=true`
   - `is_in_range(player_pos, cell_coords)` → 距离不超过MAX_DIG_RANGE
4. 若任一条件失败，进入Invalid状态，不产生伤害

**Rule 3: Dig Loop Process**

有效挖掘目标确认后，执行以下循环（每物理帧）：

1. **输入检测**：检查`dig`动作是否持续激活（输入控制系统）
2. **目标验证**：执行Rule 2的验证逻辑
3. **读取硬度**：从方块类型数据库查询`hardness(block_id)`
4. **计算伤害**：应用Rule 1的伤害公式，乘以tool_modifier
5. **累加状态**：更新该cell的`damage_accumulated`值
6. **进度反馈**：计算进度百分比，更新UI进度条状态
7. **删除判定**：若`damage_accumulated >= hardness`，触发Rule 4

**Rule 4: Block Destruction Process**

当伤害累加达到阈值，执行方块删除序列：

1. **Phase 1: 删除判定**
   - 最终验证：确认`damage_accumulated >= hardness`
   - 清除该cell的`damage_accumulated`状态

2. **Phase 2: 物理帧边界排队**
   - 调用方块碰撞系统的`queue_tile_modification(coords, operation=DELETE)`
   - 操作排队至下一物理帧边界执行（避免碰撞形状更新期间的物理引擎不一致）

3. **Phase 3: 方块删除执行**
   - TileMap世界系统执行`set_cell(coords, -1, -1, -1)`（-1表示空cell，Godot 4.6 TileMapLayer API）
   - 方块碰撞系统同步更新碰撞形状：移除该cell的collision polygon
   - 触发资源掉落系统（若方块有`drop_on_destroy`定义）

**Rule 5: Player Constraints**

挖掘权限限制：

1. **层级限制**：玩家仅可挖掘Layer 1（地面层）的方块——不可破坏Layer 0（背景层）或Layer 2（前景装饰层）
2. **范围限制**：MAX_DIG_RANGE=3.0 cells——超出范围的方块不可选中
3. **输入中断**：战车移动、下车状态切换、战车损坏瘫痪时，自动中断挖掘循环
4. **工具依赖**：无工具时tool_modifier=0.5（徒手效率极低），需装备工具才能高效挖掘

**Rule 6: Tool Modifier System**

工具层级决定挖掘效率倍率：

| Tool Tier | Modifier | Description |
|-----------|----------|-------------|
| Tier 0 (徒手) | 0.5 | 无装备，基础效率的一半 |
| Tier 1 (基础工具) | 1.0 | 采集镐/铲，标准效率 |
| Tier 2 (强化工具) | 2.0 | 秘银合金工具，双倍效率 |
| Tier 3 (魔导工具) | 4.0 | 魔力驱动工具，四倍效率 |

tool_modifier来自战车属性系统或下车状态的玩家背包系统，在Rule 3计算时作为乘数应用。

### States and Transitions

**Progress Bar State Machine**

挖掘进度条的显示状态由以下状态机控制：

| State | Condition | UI Behavior | Transitions |
|-------|-----------|-------------|-------------|
| **Hidden** | 无有效目标 | 不显示进度条 | → Active: 目标验证通过 |
| **Active** | 持续挖掘中 | 显示进度条，每帧更新百分比 | → Paused: 输入中断 / → Blocked: 目标失效 / → Invalid: 验证失败 / → Hidden: 方块删除完成 |
| **Paused** | `dig`输入松开但目标仍有效 | 进度条冻结在当前值，显示"暂停"提示 | → Active: `dig`再次按下 / → Hidden: 切换目标 |
| **Blocked** | 目标有效但无法继续挖掘（如战车移动中） | 进度条冻结，显示"阻塞"图标 | → Active: 阻塞条件解除 / → Hidden: 目标失效 |
| **Invalid** | 目标验证失败 | 进度条隐藏，显示"无效目标"闪烁提示（0.5秒） | → Hidden: 提示消失 |

状态机每帧在Rule 3循环中评估当前状态，并触发相应的UI更新。

### Interactions with Other Systems

| System | Data Flow | Interface |
|--------|-----------|-----------|
| **TileMap世界系统** | 读取：cell坐标、block_id<br>写入：`set_cell(coords, -1, -1, -1)`删除方块（Godot 4.6 TileMapLayer API）<br>状态：`damage_accumulated`存储在runtime data | `get_cell_source_id(coords)` → source_id (0=empty)<br>`set_cell(coords, source_id, atlas_coords, alternative_tile)`<br>`set_cell_runtime_data(coords, key, value)` |
| **方块类型数据库** | 读取：`hardness`、`diggable`、`drop_on_destroy` | `BlockTypeDB.get_hardness(block_id)`<br>`BlockTypeDB.is_diggable(block_id)` |
| **输入控制系统** | 读取：`dig`动作状态（持续按住/松开） | `InputControl.is_action_active("dig")` |
| **方块碰撞系统** | 写入：排队删除操作 | `BlockCollision.queue_tile_modification(coords, DELETE)` |
| **资源掉落系统** | 触发：方块删除时查询掉落表 | `ResourceDrop.spawn_drops(block_id, coords)`（若`drop_on_destroy`定义存在） |
| **战车属性系统** | 读取：当前装备工具的tier | `VehicleAttributes.get_tool_tier()` |
| **下车状态系统** | 读取：下车时玩家背包的工具tier | `PlayerInventory.get_tool_tier()` |
| **日夜循环系统** | 触发：进度条UI可能显示剩余时间vs撤退时限警告 | 间接依赖——UI层读取日夜状态 |
| **音效系统** | 触发：挖掘音效脉冲、完成音效 | `AudioSystem.play_dig_pulse()`、`AudioSystem.play_block_destroyed()` |

## Formulas

### Damage Per Frame Formula

```
damage_per_frame = BASE_DIG_RATE * tool_modifier * delta_time
```

Where `delta_time = 1/60` seconds (assuming 60 fps physics frame rate).

Accumulation continues until `damage_accumulated >= hardness`.

**Variables:**

| Variable | Type | Unit | Source | Range |
|----------|------|------|--------|-------|
| `BASE_DIG_RATE` | float | damage/sec | Constant | 30.0 (fixed) |
| `tool_modifier` | float | multiplier | Vehicle/Inventory | 0.5, 1.0, 2.0, 4.0 |
| `delta_time` | float | seconds | Physics frame | 1/60 ≈ 0.0167 (fixed at 60 fps) |
| `hardness` | int | damage threshold | BlockTypeDB | 5-255 |

**Boundary Analysis:**
- Minimum (fastest): BASE_DIG_RATE=30, tool_modifier=4.0 → damage=120/sec → 0.5/frame → hardness=5 needs ~5 frames (~0.08 sec)
- Maximum (slowest): BASE_DIG_RATE=30, tool_modifier=0.5 → damage=15/sec → 0.25/frame → hardness=220 needs ~880 frames (~14.7 sec)
- Degenerate case: hardness=0 → instant destruction bypass (BlockTypeDB rule, no accumulation needed).

**Godot Implementation Note:**
```gdscript
# Frame-based accumulation (run in _physics_process)
# delta is provided by Godot's _physics_process(delta) callback
var damage_this_frame: float = BASE_DIG_RATE * tool_modifier * delta
# Accumulate and clamp to prevent over-accumulation
damage_accumulated = min(damage_accumulated + damage_this_frame, hardness)
# Check destruction threshold
if damage_accumulated >= hardness:
    trigger_block_destruction()
```

---

### Time to Destruction Formula

```
time_to_destroy = hardness / (BASE_DIG_RATE * tool_modifier)
```

**Derived from:** `damage_accumulated` reaching `hardness` after N frames, where N = hardness / damage_per_frame, and time = N / frame_rate (60 fps physics).

**Variables:**

| Variable | Type | Unit | Range |
|----------|------|------|-------|
| `hardness` | int | damage units | 5-255 |
| `BASE_DIG_RATE` | float | damage/sec | 30.0 |
| `tool_modifier` | float | multiplier | 0.5-4.0 |

**Example Calculations:**

| Block Type | Hardness | Tool Tier | Time to Destroy |
|------------|----------|-----------|-----------------|
| surface_sand (ID 120) | 5 | Tier 0 (徒手) | 5/(30×0.5) = 0.33 sec |
| surface_dirt (ID 110) | 15 | Tier 1 (基础) | 15/(30×1) = 0.5 sec |
| surface_stone (ID 100) | 60 | Tier 1 | 60/(30×1) = 2.0 sec |
| cave_stone (ID 200) | 100 | Tier 2 | 100/(30×2) = 1.67 sec |
| deep_stone (ID 300) | 150 | Tier 2 | 150/(30×2) = 2.5 sec |
| mithril_ore (ID 700) | 180 | Tier 3 | 180/(30×4) = 1.5 sec |
| ancient_mithril (ID 710) | 220 | Tier 2 | 220/(30×2) = 3.67 sec |
| ancient_mithril (ID 710) | 220 | Tier 3 | 220/(30×4) = 1.83 sec |

---

### Progress Percentage Formula

```
progress_percent = (damage_accumulated / hardness) * 100
```

**Variables:**

| Variable | Type | Unit | Range |
|----------|------|------|-------|
| `damage_accumulated` | float | damage units | 0.0 to hardness |
| `hardness` | int | damage units | 5-255 |

**UI State Mapping:**
- 0-50% → Green progress bar (INTACT visual state)
- 50-80% → Yellow progress bar (DAMAGED visual state)
- 80-100% → Red progress bar (CRITICAL visual state)

**State transition thresholds (from TileMap世界系统):**
- THRESHOLD_DAMAGED = 0.5
- THRESHOLD_CRITICAL = 0.8

---

### Damage State Threshold Formula

```
visual_state =
  if damage_ratio < 0.5 → INTACT
  if damage_ratio >= 0.5 and < 0.8 → DAMAGED
  if damage_ratio >= 0.8 → CRITICAL
```

Where `damage_ratio = damage_accumulated / hardness`.

**Used by:** TileMap system for selecting damage variant textures, particle system for intensity scaling.

---

### Range Validation Formula

```
distance = sqrt((player_pos.x - cell_pos.x)^2 + (player_pos.y - cell_pos.y)^2)
is_in_range = distance <= MAX_DIG_RANGE * CELL_SIZE
```

**Variables:**

| Variable | Type | Unit | Value |
|----------|------|------|-------|
| `player_pos` | Vector2 | pixels | Player center position (world coords) |
| `cell_pos` | Vector2 | pixels | Cell center position (coords × CELL_SIZE + CELL_SIZE/2) |
| `MAX_DIG_RANGE` | float | cells | 3.0 |
| `CELL_SIZE` | int | pixels | 32 (from TileMap system) |

**Godot Implementation:**
```gdscript
var cell_center: Vector2 = Vector2(cell_coords) * CELL_SIZE + Vector2(CELL_SIZE / 2.0, CELL_SIZE / 2.0)
var distance: float = player_pos.distance_to(cell_center)
var is_in_range: bool = distance <= MAX_DIG_RANGE * CELL_SIZE
```

---

### Retained Damage Calculation

When player switches targets and returns to a partially-dug block:

```
retained_damage = damage_accumulated (no decay)
```

**Persistence Rule:** Damage state persists per-cell until:
- Block is destroyed → damage resets to 0, cell deleted
- Player exits area (chunk unloaded) → damage saved to chunk runtime data
- Session ends → damage saved to world state (if persistence implemented)

**No damage decay mechanic in MVP.** Player's investment in partially-dug blocks is preserved.

---

### Boundary Case Summary

| Boundary | Formula Impact | Handling |
|----------|---------------|----------|
| hardness=0 | Zero threshold | Bypass dig loop → instant destruction (BlockTypeDB rule) |
| hardness=255 (indestructible) | Infinite accumulation needed | BlockTypeDB returns hardness=255 for destructibility=0 → dig validation rejects immediately, no damage calc |
| tool_modifier=0 | Zero damage | Not valid tier range — minimum is 0.5 (Tier 0). MAX_TOOL_TIER clamp prevents invalid values. |
| tool_modifier > MAX_TOOL_TIER | Invalid tier | Clamp: `tool_modifier = min(tool_modifier, TIER_3_MODIFIER)` — prevents undefined tiers |
| distance > MAX_DIG_RANGE | Target invalid | Validation rejects before damage calculation begins |
| damage_accumulated > hardness | Over-accumulation | Clamp: `damage_accumulated = min(damage_accumulated, hardness)` prevents overflow |

## Edge Cases

### 1. Player Moves During Digging

**Case**: Player initiates dig on a target, then moves the vehicle while holding `dig` input.

| Scenario | Input | Expected Behavior | Recovery |
|----------|-------|-------------------|----------|
| Vehicle starts moving | `move` input detected during active dig | Dig loop interrupted → Progress bar state → Blocked → Damage accumulation stops | When movement stops, player can re-target and resume (retained damage preserved) |
| Vehicle rotates slightly | Rotation changes aim direction | Target may shift to different cell if raycast now hits different cell | New target starts fresh; old target retains accumulated damage |
| Movement key accidental tap | Brief movement input | Dig interrupted for that frame; if movement ends within same frame, dig resumes | Grace period: 1-frame movement doesn't interrupt if velocity remains zero |

**Implementation Rule**: Detect `linear_velocity > 0.1 cells/sec` as movement trigger. Zero velocity within tolerance = stationary.

---

### 2. Target Becomes Invalid Mid-Dig

**Case**: Player is actively digging when the target cell becomes invalid (e.g., another player destroys it, system removes it).

| Scenario | Trigger | Expected Behavior | System Response |
|----------|---------|-------------------|-----------------|
| Target cell deleted by external event | TileMapLayer reports cell now empty at coords | Dig loop Rule 2 validation fails → Target invalid → Progress bar → Invalid → 0.5 sec flash | Damage accumulated for that cell discarded (cannot apply to non-existent cell) |
| Target cell hardness changed | BlockTypeDB updated (dev/testing scenario) | Continue with new hardness value; accumulated damage may now exceed new hardness → immediate destruction | Runtime handles: `if damage_accumulated >= current_hardness` triggers destruction |
| Target cell becomes indestructible | destructibility changed to 0 (unlikely in normal play) | Validation Rule 2 fails on next frame → Invalid state | No further damage; player warned "不可破坏" |

---

### 3. Switching Targets During Active Dig

**Case**: Player holds `dig` input but moves cursor to aim at different cell.

| Scenario | Input | Expected Behavior | State Transition |
|----------|-------|-------------------|------------------|
| Cursor moves to adjacent cell | Raycast now returns different coords | Old target: damage_accumulated retained in runtime data. New target: fresh damage accumulation begins. | Progress bar: Hidden → Active (new target) |
| Cursor moves to empty space | Raycast returns no collision | Target invalid → Progress bar → Invalid → 0.5 sec flash. Damage on previous target retained. | No damage accumulation while no target |
| Cursor moves beyond MAX_DIG_RANGE | Distance validation fails | Target invalid → same as empty space case | Player must move closer to resume |

**Damage Retention Rule**: Each cell maintains independent `damage_accumulated` state. Switching targets does not reset previous cell's damage.

---

### 4. Digging on Layer 0, 2, 3, or 4

**Case**: Player attempts to dig a cell on a non-diggable layer.

| Scenario | Input | Expected Behavior | Recovery |
|----------|-------|-------------------|----------|
| Target is Layer 0 (background) | Raycast hits Layer 0 cell | Rule 2 validation: Layer 0 not allowed for dig → Invalid (Rule 5 constraint) | Progress bar shows "无效目标"; no damage applied |
| Target is Layer 2 (structure, player-built) | Raycast hits Layer 2 wall | Rule 5 constraint: Player can only dig Layer 1 → Invalid | Same as above; structure layer is removed via deconstruct action (方块放置系统), not dig |
| Target is Layer 4 (overlay marker) | Raycast hits transient effect tile | Layer 4 tiles have collision_shape=0 → no raycast collision → never selected | Cannot target overlay tiles |

**Layer Constraint**: Rule 5 enforces Layer 1 only. Structures (Layer 2) are removed via separate "deconstruct" system (方块放置系统 handles both placement and removal of buildables).

---

### 5. Digging Indestructible Blocks (Bedrock)

**Case**: Player attempts to dig bedrock or boundary blocks (destructibility=0).

| Scenario | Input | Expected Behavior | Feedback |
|----------|-------|-------------------|----------|
| Target is bedrock (ID 1, 10, 20) | Raycast returns bedrock coords | BlockTypeDB.get_destructibility(1) = 0 → Rule 2 validation fails → Invalid | Progress bar: Invalid; tooltip shows "不可破坏" |
| Target is null_tile (ID 0) | Corrupted world data returns ID 0 | BlockTypeDB treats ID 0 as error fallback (destructibility=0) → Invalid | Same handling as bedrock |

**Hardness Override**: BlockTypeDB returns hardness=255 for destructibility=0 blocks. Digging system never enters damage loop.

---

### 6. Tool Modifier Changes Mid-Dig

**Case**: Player is digging with a tool, then swaps to different tool or loses tool.

| Scenario | Trigger | Expected Behavior | Damage Effect |
|----------|---------|-------------------|----------------|
| Equip better tool during dig | Vehicle inventory swap event | tool_modifier updates on next frame → damage_per_frame increases | Damage accumulation continues with new modifier |
| Equip worse tool | Inventory swap | tool_modifier decreases → damage_per_frame slows | Progress bar updates reflect slower rate |
| Tool destroyed/lost | 战车损坏系统 event | tool_modifier → 0.5 (Tier 0, 徒手) | Player can continue digging at reduced efficiency |

**Runtime Rule**: tool_modifier is queried each frame from VehicleAttributes or PlayerInventory. No cached value; always fresh lookup.

---

### 7. Physics Frame Boundary Race Condition

**Case**: Block destruction triggers during collision system's shape update window.

| Scenario | Trigger | Expected Behavior | Safety Mechanism |
|----------|---------|-------------------|------------------|
| Destruction during collision update | damage_accumulated reaches hardness while BlockCollision is updating shapes | Rule 4 Phase 2: queue_tile_modification → operation deferred to next physics frame boundary | No in-frame collision shape mutation; prevents physics engine inconsistency |
| Multiple blocks destroyed same frame | Rapid dig completion on multiple cells | Each destruction queued separately; all execute at next frame boundary | Batch safe; BlockCollision handles queued operations in order |

**Safety Rule**: TileMapLayer.set_cell and collision polygon updates must happen at physics frame boundaries only. Digging system never calls set_cell directly — always via BlockCollision.queue_tile_modification.

---

### 8. Simultaneous Multi-Player Dig (Future Consideration)

**Case**: Two players dig the same block (multiplayer scenario, post-MVP).

| Scenario | Trigger | Expected Behavior | Handling |
|----------|---------|-------------------|----------|
| Two players target same cell | Both raycasts return same coords | Each player accumulates damage independently → combined damage may reach threshold faster | Damage sources tracked; progress bar shows combined effort |
| One player destroys cell while other still digging | Block deletion event | Other player's next validation fails → target invalid → damage discarded | Network sync handles race; authoritative server resolves |

**MVP Scope**: Single-player only. Multiplayer dig sync is Alpha/Full Vision scope.

---

### 9. High-Hardness Block with Low Tool Tier

**Case**: Player attempts to dig deep/abyss blocks with Tier 0 or Tier 1 tool.

| Scenario | Input | Expected Behavior | Player Feedback |
|----------|-------|-------------------|-----------------|
| ancient_mithril (220) with Tier 0 | hardness=220, modifier=0.5 | Valid → damage accumulates at 0.068/frame → ~54 seconds to destroy | Progress bar fills extremely slowly; player perceives "这要挖很久" — time investment decision |
| deep_stone (150) with Tier 0 | hardness=150, modifier=0.5 | Valid → ~10 seconds to destroy | Feels slow but achievable; encourages tool upgrade |

**Design Intent**: High-hardness + low-tier creates "time pressure" decision point (Pillar 2: 搜打撤节奏). Player must evaluate "值得挖吗？" No hard tool-tier lockout — all blocks theoretically diggable with persistence.

---

### 10. Damage Accumulation Persistence Across Session

**Case**: Player partially digs a block, exits game, returns later.

| Scenario | Trigger | Expected Behavior | Persistence |
|----------|---------|-------------------|-------------|
| Session ends with partial dig | Player quits, chunk unloaded | damage_accumulated stored in chunk runtime data (TileMap system responsibility) | If TileMap saves runtime data, damage persists; otherwise resets to 0 |
| Player returns to area | Chunk reloaded | damage_accumulated retrieved from saved state; player resumes from retained progress | MVP: No persistence guarantee; Alpha: Save system implements runtime state serialization |

**MVP Scope**: damage_accumulated is runtime state, not serialized. Player returns → damage resets to 0. This is acceptable for MVP scope; persistence added in Full Vision phase with Save System.

## Dependencies

### Upstream Dependencies

| System | Layer | Data Provided | Interface | Dependency Type |
|--------|-------|---------------|-----------|-----------------|
| **TileMap世界系统** | Foundation | Cell coords, block_id, runtime data storage (damage_accumulated) | `get_cell(layer, coords)`, `set_cell_runtime_data(coords, key, value)` | **Blocking** — Cannot dig without world state |
| **方块类型数据库** | Foundation | hardness, destructibility (diggable flag) | `BlockTypes.get_hardness(block_id)`, `BlockTypes.get_destructibility(block_id)` | **Blocking** — Cannot calculate damage without hardness |
| **输入控制系统** | Foundation | `dig` action state (active/inactive) | `InputControl.is_action_active("dig")` | **Blocking** — Cannot respond to input without input system |
| **战车属性系统** | Core | tool_tier (equipped tool level) | `VehicleAttributes.get_tool_tier()` | **Blocking** — Cannot apply tool_modifier without tool info |
| **下车状态系统** | Feature | tool_tier when player is on-foot | `PlayerInventory.get_tool_tier()` (if下车状态 active) | **Blocking** — Player on-foot needs different tool source |
| **方块碰撞系统** | Core | queue_tile_modification for safe deletion | `BlockCollision.queue_tile_modification(coords, DELETE)` | **Blocking** — Cannot safely delete blocks without collision queue |

### Downstream Dependent Systems

| System | Layer | Data Consumed | Interface Provided | Dependency Type |
|--------|-------|---------------|-------------------|-----------------|
| **资源掉落系统** | Core | block_id (for drop table lookup), coords | `ResourceDrop.spawn_drops(block_id, coords)` (triggered on destruction) | **Non-blocking** — Drop system handles spawn, digging only triggers |
| **音效系统** | Presentation | Dig pulse, block destruction sound | `AudioSystem.play_dig_pulse()`, `AudioSystem.play_block_destroyed()` | **Non-blocking** — Audio feedback not required for gameplay |
| **日夜循环系统** | Core | Time state for UI warning integration | Progress bar may display "remaining time vs retreat deadline" | **Indirect** — UI-layer dependency, not gameplay logic |
| **战车损坏系统** | Core | Tool durability/availability | If tool is damaged, tool_modifier may change | **Indirect** — Affects tool_modifier source, not dig logic |

### Dependency Interface Contract

**Data Contract (从上游读取):**

| Interface | Return Type | Failure Mode | Consumer Contract |
|-----------|-------------|--------------|-------------------|
| `TileMapLayer.get_cell_source_id(coords)` | int (source_id) | Returns -1 for empty cell or invalid coords | Digging system checks >= 0 before proceeding (0=valid source, -1=empty) |
| `BlockTypes.get_hardness(block_id)` | int (0-255) | Returns 255 for invalid ID or indestructible | Digging uses `max(hardness, 1)` for division safety |
| `BlockTypes.get_destructibility(block_id)` | int (0-1) | Returns 0 for invalid ID | Digging rejects if 0 (indestructible) |
| `InputControl.is_action_active("dig")` | bool | Returns false if input system not ready | Digging loop requires true to accumulate |
| `VehicleAttributes.get_tool_tier()` | int (0-3) | Returns 0 if no vehicle or not in vehicle | Default to Tier 0 (徒手) modifier=0.5 |
| `BlockCollision.queue_tile_modification(coords, DELETE)` | void | No return; operation queued | Deletion happens at next frame boundary |

**Trigger Contract (向下游触发):**

| Trigger | When | Data Passed | Consumer Contract |
|---------|------|-------------|-------------------|
| `ResourceDrop.spawn_drops(block_id, coords)` | On block destruction (Rule 4 Phase 3) | block_id for drop table, coords for spawn location | Resource system checks block_id has resource_type_id > 0 |
| `AudioSystem.play_dig_pulse()` | Each damage frame (optional) | No data; pulse sound | Audio system manages playback |
| `AudioSystem.play_block_destroyed()` | On block destruction | No data; destruction sound | Audio system manages playback |

---

### Critical Dependency Path (MVP)

```
InputControl → 方块挖掘系统 → BlockCollision → TileMap世界系统
BlockTypeDB → 方块挖掘系统 → ResourceDrop → Resource Database
VehicleAttributes → 方块挖掘系统 → tool_modifier → damage_per_frame
```

**MVP Sequence:** All upstream dependencies must be implemented before 方块挖掘系统 can function.

---

### Systems Not Dependent on 方块挖掘系统

| System | Reason |
|--------|--------|
| **时间系统** | Independent — time tracking, no dig interaction |
| **战车驾驶系统** | Independent — movement, collision; dig interrupts movement but movement system doesn't query dig |
| **敌人AI系统** | Independent — enemy behavior, no dig interaction (enemies destroy blocks via separate damage system) |
| **炮塔系统** | Independent — turret targeting, no dig interaction |

## Tuning Knobs

### Primary Tuning Knobs (影响挖掘节奏)

| Knob | Current Value | Safe Range | Gameplay Effect | Pillar Affected |
|------|---------------|------------|-----------------|-----------------|
| **BASE_DIG_RATE** | 30.0 damage/sec | 15.0-60.0 | 基准伤害速率。提高 → 所有方块挖得更快 → 搜打撤时间压力降低 | Pillar 2: 搜打撤节奏 |
| **MAX_DIG_RANGE** | 3.0 cells | 2.0-5.0 | 挖掘距离限制。提高 → 玩家可站更远挖掘 → 安全性增加 | Pillar 2: 搜打撤节奏 |
| **MAX_TOOL_TIER** | 3 (最高4.0 modifier) | 0-3 | 工具层级上限。防止超出定义范围的modifier值。架构约束，不建议修改。 | All pillars |
| **tool_modifier (各层级)** | Tier 0: 0.5, Tier 1: 1.0, Tier 2: 2.0, Tier 3: 4.0 | 0.25-8.0 | 工具效率倍率。调整层级比例 → 工具升级收益变化 | All pillars (economy) |

### Secondary Tuning Knobs (影响反馈体验)

| Knob | Current Value | Safe Range | Gameplay Effect |
|------|---------------|------------|-----------------|
| **Progress bar color thresholds** | DAMAGED: 50%, CRITICAL: 80% | 30-60% (DAMAGED), 70-90% (CRITICAL) | 进度条颜色变化时机。调整 → 视觉反馈紧迫感变化 |
| **Movement interruption tolerance** | velocity > 0.1 cells/sec triggers Blocked | 0.05-0.5 cells/sec | 移动打断挖掘的灵敏度。提高 → 更宽容的微移动容忍 |
| **Invalid target flash duration** | 0.5 sec | 0.2-1.0 sec | 无效目标提示闪烁时长 |

### Cross-System Tuning Knobs (依赖其他系统)

| Knob | Owner System | Current Value | Effect on Digging |
|------|--------------|---------------|-------------------|
| **hardness (per tile)** | BlockTypeDB | 5-220 (diggable range) | 直接影响挖掘时间。BlockTypeDB调优 → 挖掘节奏变化 |
| **CELL_SIZE** | TileMap世界系统 | 32 px | 固定值。改变影响MAX_DIG_RANGE像素计算和raycast精度 |
| **Physics frame rate** | Godot Engine | 60 fps | 固定值。改变影响damage_per_frame时间单位转换 |

### Tuning Scenarios

**Scenario A: 挖掘太快 → 搜打撤压力不足**
- Symptom: Player breezes through blocks, no time pressure decisions
- Adjustment: Reduce BASE_DIG_RATE from 30.0 to 20.0, or increase hardness values in BlockTypeDB
- Expected outcome: 挖掘时间延长 → 玖家需要更多评估"值得挖吗？"

**Scenario B: 挖掘太慢 → 玩家沮丧**
- Symptom: Player feels progress is too slow, drops digging activity
- Adjustment: Increase BASE_DIG_RATE to 40.0, or increase tool_modifier for Tier 2/3
- Expected outcome: 高级工具明显更快 → 工具升级动力增加

**Scenario C: Tier 0 (徒手) 完全无用**
- Symptom: Player always needs tool, no fallback option feels punishing
- Adjustment: Increase Tier 0 modifier from 0.5 to 1.0
- Expected outcome: 徒手挖沙土/泥土可行 → 紧急情况下仍有选项

**Scenario D: 高硬度方块永远不值得挖**
- Symptom: Player ignores deep/abyss blocks entirely
- Adjustment: Increase Tier 3 modifier to 6.0, or decrease hardness for resource ores (mithril_ore from 180 to 120)
- Expected outcome: 高级工具+稀有资源 → 时间投资有回报

### Knobs That Should NOT Be Tuned

| Knob | Reason |
|------|--------|
| **Layer restriction (Layer 1 only)** | 架构约束。改变会破坏世界层级逻辑。 |
| **Damage accumulation model (frame-based)** | 核心设计决策。改变为"hit-based"需重写整个系统。 |
| **Tool tier system (0-3)** | 架构决策。更多层级需扩展VehicleAttributes和PlayerInventory。 |
| **Retained damage persistence (no decay)** | 设计决策。添加decay需新状态机和UI提示。 |

## Visual/Audio Requirements

### Visual Requirements

| Requirement | Description | Implementation Owner |
|-------------|-------------|---------------------|
| **Progress Bar Display** | Floating progress bar above targeted cell, showing 0-100% completion with color phases (green→yellow→red) | UI System / Digging System HUD |
| **Block Damage Visual States** | Target block texture changes at 50% (cracked) and 80% (heavily damaged) thresholds, using damage variants from TileSet | TileMap World System (variant selection) |
| **Digging Cursor Indicator** | Visual indicator showing current target cell (highlight outline or reticle), distance-coded color (green=in-range, red=out-of-range) | UI System |
| **Particle Effects** | Small particle burst on each damage frame (dust/debris), intensity scales with damage_ratio | VFX System |
| **Destruction Animation** | Block crumbling animation on destruction (2-3 frame dissolve or shatter) | VFX System / TileMap system |
| **Invalid Target Feedback** | Red flash or "X" icon over invalid target for 0.5 sec | UI System |

### Audio Requirements

| Event | Audio Type | Trigger Condition | Sound Bank |
|-------|------------|-------------------|------------|
| **Dig Pulse** | Percussive hit sound (light→heavy based on hardness) | Each damage frame while actively digging | `dig_light`, `dig_medium`, `dig_heavy` |
| **Block Destroyed** | Crumbling/shatter sound | On block destruction completion | `block_break_small`, `block_break_large` |
| **Resource Drop** | Metallic/plink sound | When block with resource_type_id > 0 is destroyed | `resource_drop_crystal`, `resource_drop_metal` |
| **Invalid Target** | Error buzz or rejection sound | When target validation fails | `invalid_target` |
| **Tool Change** | Equip/unequip sound | When tool tier changes mid-dig | `tool_equip` |

### Visual-Audio Integration Matrix

| Damage Ratio | Visual State | Audio Intensity | Particle Density |
|--------------|--------------|-----------------|------------------|
| 0-30% | INTACT texture | Light dig pulse (soft sound) | Sparse dust particles |
| 30-50% | INTACT texture | Medium dig pulse | Moderate particles |
| 50-80% | DAMAGED texture (cracked) | Heavy dig pulse | Dense particles |
| 80-100% | CRITICAL texture (heavily cracked) | Heaviest pulse + tension sound | Maximum particles |
| 100% (destruction) | Crumble animation + flash | Block break + resource drop (if applicable) | Burst explosion |

### Asset Requirements

| Asset | Count | Size | Source |
|-------|-------|------|--------|
| **Progress bar texture** | 1 | 128×32 px | UI asset production |
| **Damage state particles** | 3 variants (dust, gravel, stone) | Sprite sheet | VFX asset production |
| **Destruction animation frames** | 3-5 per block type | Per-tile atlas slots | TileSet extension |
| **Audio samples** | ~8 total (dig_light/medium/heavy, break_small/large, resource_drop variants, invalid_target, tool_equip) | WAV/OGG files | Audio asset production |

## UI Requirements

### HUD Elements

| Element | Position | Display Logic | Update Frequency |
|---------|----------|---------------|------------------|
| **Dig Progress Bar** | Above targeted cell, floating | Active during dig; Hidden otherwise; Invalid flash on rejection | Per-frame (damage accumulation) |
| **Target Reticle** | Over targeted cell | Shows when valid target in range; disappears when no target or invalid | Per-frame (raycast result) |
| **Block Tooltip** | Near target cell or HUD corner | Shows block name, hardness, resource type on hover/aim | On target change |
| **Tool Tier Indicator** | HUD status area | Shows current equipped tool tier and modifier | On tool change |

### Progress Bar UI Specification

```
Layout:
┌─────────────────────────┐
│ ████████████░░░░ 65%    │  ← Yellow phase (DAMAGED)
│ 挖掘: 地表岩石          │  ← Target block name
└─────────────────────────┘

Dimensions:
- Width: 96 px (3 cells wide for visibility)
- Height: 24 px
- Anchor: Cell center, offset Y = -20 px (above cell)

Color Phases:
- 0-50%: Green (#4CAF50)
- 50-80%: Yellow (#FFC107)
- 80-100%: Red (#F44336)

Animation:
- Per-frame fill animation (smooth growth)
- Color gradient shift on damage (green→yellow→red) — no strobing effect
- Destruction: Flash white → fade out (single flash, <1Hz)

Accessibility Note:
WCAG 2.3.1 compliance: No rapid flashing (>3Hz). Color gradient provides feedback without seizure risk. Colorblind mode uses symbols (see UI Accessibility section).
```

### Target Reticle Specification

```
Layout:
  ╔══════╗
  ║  ○   ║  ← Target cell outline
  ╚══════╝

Visual:
- Outline: 4 px stroke, cell-sized (32×32)
- In-range: Green outline
- Out-of-range: Red outline, dashed
- Invalid target: Red X overlay

Animation:
- Appears instantly on valid target
- Fades when target lost (0.3 sec fade)
```

### Block Tooltip Specification

```
Layout:
┌────────────────────┐
│ 地表岩石           │
│ 硬度: 60 (中等)    │
│ 产出: 无           │
│ 时间: ~2秒         │
└────────────────────┘

Position: Offset from reticle (+30 px right)
Display: On aim hover, 0.5 sec delay to avoid spam
```

### UI Accessibility

| Requirement | Implementation |
|-------------|----------------|
| **Colorblind mode** | Progress bar uses symbols: empty circle (INTACT), half-filled (DAMAGED), full (CRITICAL) in addition to color |
| **Screen reader** | Progress percentage exposed as accessible text: "挖掘进度 65%, 目标: 地表岩石" |
| **High contrast** | Progress bar outline increased to 3 px, color phases use distinct values (not just hue shift) |

## Acceptance Criteria

### Core Mechanics Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-001** | Damage accumulates per frame while dig input active | Start dig on test block (hardness=60), hold dig for 2 seconds, verify damage_accumulated ≈ 60 (with tool_modifier=1.0) | Accumulated damage within ±5% of expected |
| **AC-002** | Block destruction triggers when damage reaches hardness | Accumulate damage to hardness threshold, verify block deleted and collision removed | Cell is empty after destruction trigger |
| **AC-003** | Target validation rejects empty cells | Aim raycast at empty cell, verify dig loop rejects → Invalid state | No damage accumulated, progress bar shows Invalid |
| **AC-004** | Target validation rejects out-of-range cells | Aim at cell 5 cells away (beyond MAX_DIG_RANGE=3), verify rejection | Invalid state, no damage |
| **AC-005** | Layer 1 only constraint enforced | Aim at Layer 2 structure tile, verify dig rejects | Invalid state, no damage |
| **AC-006** | Indestructible blocks rejected | Aim at bedrock (destructibility=0), verify immediate rejection | Invalid state, tooltip shows "不可破坏" |

### Tool Modifier Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-007** | Tier 0 modifier (0.5) produces half damage rate | Dig with no tool (Tier 0), measure damage per frame | damage ≈ (BASE_DIG_RATE × 0.5) / hardness |
| **AC-008** | Tier 1 modifier (1.0) produces baseline damage | Dig with Tier 1 tool, measure damage per frame | damage ≈ BASE_DIG_RATE / hardness |
| **AC-009** | Tier 3 modifier (4.0) produces 4x damage | Dig with Tier 3 tool, verify time to destruction is 1/4 of Tier 1 | Time ratio ≈ 1:4 for same hardness |
| **AC-010** | Tool tier swap mid-dig updates modifier | Start dig with Tier 1, swap to Tier 3, verify damage rate increases mid-dig | Damage rate changes within 1 frame of swap |

### Progress Bar Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-011** | Progress bar shows correct percentage | Dig 50% of hardness, verify progress bar at 50% | UI display matches calculated percentage ±2% |
| **AC-012** | Progress bar color transitions at 50% threshold | Accumulate to 50% damage, verify color changes to yellow (DAMAGED) | Visual state matches THRESHOLD_DAMAGED |
| **AC-013** | Progress bar color transitions at 80% threshold | Accumulate to 80% damage, verify color changes to red (CRITICAL) | Visual state matches THRESHOLD_CRITICAL |
| **AC-014** | Progress bar hides on target invalidation | Target becomes invalid (e.g., cell deleted externally), verify bar → Hidden | No progress bar visible for invalid target |

### Physics Safety Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-015** | Block deletion queued to physics frame boundary | Trigger destruction, use Godot profiler to verify set_cell call timestamp is at frame boundary (within first 16ms of frame) | No set_cell call recorded mid-frame (collision update window) |
| **AC-016** | Multiple destructions queued sequentially | Trigger 3 simultaneous destructions, verify all execute at frame boundary in order | Batch safe, no physics errors, all 3 cells empty within single frame |

### Integration Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-017** | Resource drop triggered on destruction | Destroy block with resource_type_id > 0, verify ResourceDrop.spawn_drops called | Resource entity spawned at coords |
| **AC-018** | No resource drop for resource_type_id = 0 | Destroy plain stone (resource_type_id=0), verify no spawn call | No resource entity |
| **AC-019** | BlockTypeDB hardness query integrated | Verify dig system calls BlockTypes.get_hardness(block_id) for each target | Query made, correct hardness returned |
| **AC-020** | Input system dig action integrated | Verify dig system checks InputControl.is_action_active("dig") each frame | Query made, active/inactive state correct |

### Edge Case Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-021** | Movement interrupts dig | Start dig, trigger vehicle movement, verify dig → Blocked state | Damage stops, progress bar frozen |
| **AC-022** | Movement stop resumes dig capability | After Blocked, stop movement, verify player can re-target and resume | New target starts fresh; old target retained |
| **AC-023** | Target switch retains previous damage | Dig block A to 50%, switch to block B, return to A, verify damage at 50% | Retained damage preserved |
| **AC-024** | hardness=0 bypasses dig loop | Target block with hardness=0 (instant destruction), verify immediate deletion without accumulation | No progress bar, instant destroy |
| **AC-025** | Degenerate values handled gracefully | Target invalid block_id (999), verify system handles without crash | Returns null/Invalid state, no exception |

### Performance Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-026** | Dig loop frame budget < 0.5ms | Profile dig loop using Godot profiler: measure validation + damage calc + UI update execution time per frame | Execution time ≤ 0.5ms per frame (measured via profiler, not "feels fast") |

**Alpha Scope (Post-MVP):**

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-027** | 100 simultaneous dig targets (stress test) | Simulate multiplayer scenario with 100 concurrent dig operations, measure frame time | Frame budget stays within 16.6ms total frame time |

### Pass/Fail Threshold

| Category | Pass Count | Fail Action |
|----------|------------|-------------|
| **Core Mechanics (AC-001 to AC-006)** | 必须100%通过 | 任一失败 → 核心逻辑错误，必须修复 |
| **Tool Modifier (AC-007 to AC-010)** | 必须100%通过 | 任一失败 → 工具系统集成错误 |
| **Progress Bar (AC-011 to AC-014)** | 必须100%通过 | 任一失败 → UI反馈错误 |
| **Physics Safety (AC-015 to AC-016)** | 必须100%通过 | 任一失败 → 物理引擎风险 |
| **Integration (AC-017 to AC-020)** | 必须100%通过 | 任一失败 → 跨系统集成失败 |
| **Edge Cases (AC-021 to AC-025)** | 必须100%通过 | 任一失败 → 边界处理缺失 |
| **Performance (AC-026)** | 必须通过 | 失败 → 性能优化 |

**MVP Total Criteria**: 26 (AC-001 to AC-026)
**Alpha Scope**: AC-027 (stress test)
**Required for MVP Implementation**: 100% pass on all MVP categories

## Open Questions

### High Priority (Implementation Blocking)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-001** | 战车属性系统的tool_tier接口是否已定义？Digging system queries `VehicleAttributes.get_tool_tier()` but interface not yet specified. | 战车属性系统 GDD设计者 | 战车属性系统实现前 | Cannot determine tool_modifier; fallback to Tier 0 always |
| **Q-002** | 下车状态系统的工具来源是否已定义？Player on-foot digs from PlayerInventory, but interface not yet specified. | 下车状态系统 GDD设计者 | 下车状态系统实现前 | On-foot digging defaults to Tier 0 or fails |
| **Q-003** | 资源掉落系统的spawn_drops接口签名是否已定义？Digging triggers `ResourceDrop.spawn_drops(block_id, coords)` but method may have different signature. | 资源掉落系统 GDD设计者 | 资源掉落系统实现前 | Destruction triggers may not spawn resources correctly |
| **Q-004** | BlockCollision.queue_tile_modification的具体实现是否已确认？Digging system relies on this for physics-safe deletion. | 方块碰撞系统实现者 | 方块碰撞系统实现前 | Deletion may cause physics engine errors |

### Medium Priority (Design Clarification)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-005** | 挖掘是否需要魔能消耗？战车驾驶系统消耗魔能，但挖掘是否也消耗？If yes, damage_per_frame formula needs魔能_factor. | Game Designer | 战车驾驶系统实现前 | May need to add魔能_cost mechanic mid-implementation |
| **Q-006** | 挖掘是否有冷却时间或hit-based而非frame-based？Current design is frame-based continuous. Alternative: cooldown per hit. | Game Designer | Digging system实现前 | Formula model may change completely |
| **Q-007** | 敌人是否可以破坏玩家挖掘中的方块？如果敌人攻击同一cell，damage_accumulated是否共享？ | 敌人AI系统 + 方块挖掘系统 | 敌人AI系统设计前 | Damage accumulation may need source tracking |

### Low Priority (Future Consideration)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-008** | 挖掘是否有"完成奖励"机制？如挖完特定方块获得XP或成就触发。 | Progression System设计者 | Alpha阶段 | No progression incentive for digging |
| **Q-009** | 多玩家同挖一格的同步策略？MVP single-player, but multiplayer support may need combined damage tracking. | Multiplayer架构设计者 | Alpha/Full Vision | Multiplayer dig sync not defined |
| **Q-010** | 挖掘进度是否在HUD显示预计剩余时间？当前设计显示百分比，但玩家可能想要"还需2秒"格式。 | UX Designer | Beta阶段 (UI完善) | Progress bar format may change |

### Assumptions Made (Temporary Decisions)

| Assumption | Rationale | Risk |
|------------|-----------|------|
| **VehicleAttributes.get_tool_tier() returns int 0-3** | Standard tier system assumption. Vehicle系统将使用此接口。 | If interface differs, Digging system adapter needed |
| **No魔能消耗 for digging** | 挖掘是物理动作，不消耗魔能。战车移动消耗魔能是驱动系统，挖掘是玩家体力。 | If魔能消耗 added, formula needs update |
| **Frame-based continuous damage** | 最简单的实现。Hit-based需要cooldown计时和状态机。 | If hit-based chosen, rewrite damage loop |
| **Single-player damage accumulation** | MVP scope. Multiplayer combined damage is post-MVP. | If multiplayer damage sharing needed, add source tracking |

### Resolution Tracking

| ID | Status | Resolution Date | Resolved By | Resolution Summary |
|----|--------|-----------------|-------------|-------------------|
| Q-001 | Open | — | — | Pending 战车属性系统GDD |
| Q-002 | Open | — | — | Pending 下车状态系统GDD |
| Q-003 | Open | — | — | Pending 资源掉落系统GDD |
| Q-004 | Open | — | — | Pending BlockCollision实现确认 |
| Q-005 | Open | — | — | Pending Game Designer决策 |
| Q-006 | Open | — | — | Pending Game Designer决策 |
| Q-007 | Open | — | — | Pending 敌人AI系统设计 |
| Q-008 | Open | — | — | Pending Progression系统设计 |
| Q-009 | Open | — | — | Pending Multiplayer架构设计 |
| Q-010 | Open | — | — | Pending UX Designer决策 |