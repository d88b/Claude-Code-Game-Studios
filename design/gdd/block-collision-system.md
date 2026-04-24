# 方块碰撞系统

> **Status**: Revised (MAJOR REVISION — 2026-04-23, Second Revision)
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 1 (战车即生命), Pillar 3 (尸潮即高潮)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #11 (from systems-index.md)
> **Review Verdict**: MAJOR REVISION NEEDED → Revised (First revision: 5 blockers resolved) → Second Revision (5 new P0 blockers resolved)

## Overview

方块碰撞系统是TileMap世界系统与物理世界的桥梁层。它将TileMap Layer 2（碰撞层）的collision_shape数据转换为Godot PhysicsBody2D可检测的碰撞形状，为战车、敌人、子弹等所有移动实体提供统一的碰撞检测接口。

**基础设施角色**：系统运行时无需人工干预。当TileMap加载区块时，方块碰撞系统自动从每个cell的collision_shape值（0=无碰撞, 1=完整碰撞, 2=平台碰撞）生成对应的CollisionShape2D节点，挂载到TileMap的静态碰撞体上。删除方块时，系统即时更新碰撞形状。

**玩家影响层**：玩家不直接操作此系统，但所有物理交互都依赖它：
- 战车驾驶的移动边界由碰撞形状定义——碰撞形状准确，战车才能"撞墙停止"而非"穿墙滑出"
- 尸潮防守的墙体完整性由碰撞形状验证——敌人AI寻路依赖碰撞数据判断"墙是否可穿透"
- 挖掘系统的破坏反馈由碰撞形状移除呈现——挖掉方块，碰撞消失，战车才能通过

**核心价值**：没有方块碰撞系统，TileMap只是视觉图层；有了它，TileMap才成为物理世界。所有Pillar 1（战车即生命）的驾驶手感、Pillar 3（尸潮即高潮）的防守压力，都建立在此系统的稳定性之上。

## Player Fantasy

方块碰撞系统是隐性的物理规则层——玩家不会"感受碰撞系统"，但他们会感受**物理世界的可信度**：

- **战车撞击墙壁**时的"硬停止"反馈——碰撞形状准确，战车才不会滑出地图边界或穿墙而过，玩家才能信任"墙是真的"
- **敌人被墙体阻挡**时的路径改变——碰撞数据正确，尸潮才会"撞墙绕路"而非"穿墙涌入"，防守才有意义
- **挖掘通道贯通**时的通行感——方块挖掉，碰撞消失，战车驶入新区域的顺畅感，是碰撞系统移除碰撞形状的结果

**玩家信任锚点**：当玩家看到战车稳定停在墙边、敌人被墙阻挡、挖掘后通道可通行，他们不会思考"碰撞系统工作正常"，但他们会**信任这个世界是物理连贯的**。这种信任是所有Pillar 1（战车即生命）驾驶体验和Pillar 3（尸潮即高潮）防守压力的基础。

**失败时的感觉**：如果碰撞系统失效，玩家不会说"碰撞系统坏了"，他们会说"战车穿墙了"、"敌人无视墙壁"、"挖掉的方块还在挡我"。这些是**物理可信度的崩溃**，而非系统故障的显性感知。

## Detailed Design

### Core Rules

**Rule 1: Collision Shape Generation is Automatic**
方块碰撞系统**不生成CollisionShape2D节点**。Godot 4.x TileMap通过TileSet physics layers自动处理碰撞形状。collision_shape值（0/1/2）已在block-type-database.md中映射到三个physics layers：

- physics_layer 0: COLLISION_TERRAIN (Layer 1 terrain_base)
- physics_layer 1: COLLISION_STRUCTURE (Layer 2 structures)
- physics_layer 2: COLLISION_PLATFORM (Layer 3 platforms)

**方块碰撞系统职责**：提供碰撞**查询API**和**事件信号**，而非碰撞形状生成。

---

**Rule 2: Collision Layer/Bitmask Configuration**

| Entity Type | Body Type | collision_layer | collision_mask | Behavior |
|-------------|-----------|-----------------|----------------|----------|
| 战车 (Battle Wagon) | CharacterBody2D | 64 (PLAYER_BODY) | 1+2+4 (terrain+structure+platform) | Detects all walls, can land on platforms |
| 行走敌人 (Walking Enemy) | CharacterBody2D | 8 (ENEMY_BODY) | 1+2 (terrain+structure) | Detects walls, **falls through platforms** |
| 飞行敌人 (Flying Enemy) | CharacterBody2D | 8 (ENEMY_BODY) | 0 (no collision) | Ignores all tile collision |
| 玩家子弹 (Player Projectile) | RigidBody2D | 0 | 1+2+8 (terrain+structure+ENEMY_BODY) | Hits walls and enemies |
| 敌人子弹 (Enemy Projectile) | RigidBody2D | 0 | 1+2+64 (terrain+structure+PLAYER_BODY) | Hits walls and player vehicle |

**collision_layer命名常量**（添加到entities.yaml）：
```gdscript
COLLISION_TERRAIN = 1      # Bit 0 (value 1)
COLLISION_STRUCTURE = 2    # Bit 1 (value 2)
COLLISION_PLATFORM = 4     # Bit 2 (value 4)
COLLISION_ENEMY_BODY = 8   # Bit 3 (value 8)
COLLISION_PLAYER_BODY = 64 # Bit 6 (value 64)
```

---

**Rule 3: One-Way Platform Collision (TileData Custom Property)**

平台碰撞（collision_shape=2）使用**per-tile TileData custom property**，而非physics_layer全局设置：

**Godot 4.6 Correct Approach**:
- One-way collision is set per-tile via `TileData.set_custom_data("one_way_collision", true)` in TileSet
- Requires defining a custom data layer in TileSet: `add_custom_data_layer("one_way_collision", TYPE_BOOL)`
- Alternatively, use **collision mask filtering** on the body side (recommended for this project)

**本项目采用 collision mask filtering**（更简洁，无需修改TileSet）：
- 战车 collision_mask = 1+2+4 → 包含COLLISION_PLATFORM (bit 2) → 可着陆平台，从下方穿过
- 行走敌人 collision_mask = 1+2 → **不含 bit 2** → 穿透平台下落（僵尸不使用平台）
- TileMap Layer 3 (platforms) 使用标准collision shape，one-way行为由body mask决定

**Implementation**:
```gdscript
# In VehicleTypeDatabase: Battle Wagon
collision_mask = COLLISION_TERRAIN | COLLISION_STRUCTURE | COLLISION_PLATFORM

# In EnemyTypeDatabase: Walking Enemy
collision_mask = COLLISION_TERRAIN | COLLISION_STRUCTURE  # No platform bit
```

---

**Rule 4: Tile Modification Queue (Physics Frame Safety)**

方块修改（挖掘删除、放置添加）**必须排队等待物理帧边界**执行：

```gdscript
# CollisionManager.gd
var _pending_modifications: Array[Dictionary] = []

# Extended interface supporting SET (creation) and DELETE (removal) operations
# Operation modes:
#   - DELETE: operation=0, tile_data ignored
#   - SET: operation=1, tile_data={source_id, atlas_coords, alternative_tile}
func queue_tile_modification(cell: Vector2i, layer: int, operation: int, tile_data: Dictionary = {}):
    _pending_modifications.append({
        cell=cell, 
        layer=layer, 
        operation=operation,
        tile_data=tile_data
    })

func _physics_process(_delta):
    if _pending_modifications.is_empty(): return
    
    for mod in _pending_modifications:
        if mod.operation == 0:  # DELETE
            # Clear cell: set_cell(layer, coords, source_id=-1)
            _tilemap.set_cell(mod.layer, mod.cell, -1)
        elif mod.operation == 1:  # SET
            # Create tile from tile_data
            var td = mod.tile_data
            _tilemap.set_cell(mod.layer, mod.cell, td.source_id, td.atlas_coords, td.alternative_tile)
        _emit_collision_change(mod.cell, mod.layer, mod.tile_type)
    
    _pending_modifications.clear()
```

**原因**：Godot物理引擎在物理帧开始时查询碰撞形状。中帧修改会导致：
- 物理体仍与已清空cell碰撞（形状未更新）
- 子弹穿透新放置墙体（形状未添加）

---

**Rule 5: Collision Query Types**

| Query Type | Method | Use Case | Notes |
|------------|--------|----------|-------|
| **Point** | `is_cell_solid(cell)` | Broad-phase check | 继承自TileMap系统 |
| **Area** | `get_tiles_in_rect(bounds)` | Vehicle bounds check | 继承自TileMap系统 |
| **Raycast** | `raycast_tile_collision(start, end, mask)` | Projectile LOS | Optimized with broad-phase first |
| **Shape** | `check_swept_collision(shape, motion)` | Vehicle movement | **新增**：支持大于cell的碰撞体 |
| **Nearest** | `get_nearest_collision(pos, radius, filter)` | WALL_BREAKER targeting | **新增**：敌人寻目标 |

---

**Rule 6: Collision Signal Architecture**

方块碰撞系统维护碰撞**事件信号**，供下游系统订阅：

| Signal | Parameters | Consumers | Purpose |
|--------|------------|-----------|---------|
| `collision_added(cell, layer)` | Vector2i cell, int layer | Enemy AI, Vehicle | Pathfinding/LOS update |
| `collision_removed(cell, layer)` | Vector2i cell, int layer | Enemy AI, Projectile | New path available |
| `navigation_changed(area)` | Rect2i area | Navigation2D | Nav mesh regeneration |
| `vehicle_collision(body, normal, severity)` | PhysicsBody2D, Vector2, float | Gamepad, Sound, UI | Pillar 1 collision feedback |

**Signal触发时机**：仅当collision_shape从0→非0（collision_added）或非0→0（collision_removed）时触发。同类型替换（如土墙→石墙）不触发信号。

---

**Rule 7: Collision Severity Calculation**

战车碰撞反馈强度由碰撞速度、角度、车辆耐久状态、障碍物重要性综合计算：

```gdscript
func _calculate_collision_severity(body: PhysicsBody2D, normal: Vector2, vehicle: VehicleStats) -> float:
    # Get velocity from appropriate property (Godot 4.6 body type handling)
    var velocity: Vector2
    if body is CharacterBody2D:
        velocity = body.velocity
    elif body is RigidBody2D:
        velocity = body.linear_velocity
    else:
        velocity = Vector2.ZERO
    
    var impact_speed := max(0.0, velocity.length() / CELL_SIZE)  # Convert to cells/sec
    var impact_angle := abs(velocity.normalized().dot(normal))
    var speed_ratio := impact_speed / MAX_VEHICLE_SPEED

    # Grazing collision baseline: high-speed sideways contact must have minimum feedback
    # (Pillar 1: physics world credibility — sliding at high speed should not feel silent)
    var grazing_baseline := 0.0
    if speed_ratio > 0.5 and impact_angle < 0.3:
        grazing_baseline = 0.15  # Minimum feedback for high-speed grazing

    # Context factors for Pillar 1 weight
    var integrity_factor := 1.0 + (1.0 - vehicle.integrity_ratio) * 0.5
    var obstacle_significance := _get_obstacle_significance(normal)

    var severity := grazing_baseline + speed_ratio * impact_angle * integrity_factor * obstacle_significance
    return clamp(severity, 0.0, 1.0)
```

**用途**：
- `severity > 0.7` → 强力游戏pad振动 + 碰撞音效 + 屏幕微震
- `severity > 0.3` → 中等振动 + 音效
- `severity < 0.3` → 轻微音效（轻擦）

---

### States and Transitions

此系统无显式状态机——它是对TileMap碰撞层的包装API层，响应式运行。

---

### Interactions with Other Systems

| System | Data Flow In | Data Flow Out | Interface Owner |
|--------|--------------|---------------|-----------------|
| **TileMap世界系统** | collision_shape values via `get_cell()` | collision query results | TileMap provides base APIs |
| **方块挖掘系统** | `queue_tile_modification(cell, layer, DELETE)` | `collision_removed` signal | CollisionManager receives queue |
| **方块放置系统** | `queue_tile_modification(cell, layer, SET, tile_data)` | `collision_added` signal | CollisionManager receives queue |
| **战车驾驶系统** | `check_swept_collision(vehicle_shape, velocity)` | `vehicle_collision` signal + collision result | CollisionManager provides query |
| **敌人AI系统** | `get_nearest_collision(pos, radius, filter)` | `collision_added/removed` signals | CollisionManager provides query |
| **炮塔系统** | `raycast_tile_collision(start, end, exclude_mask)` | collision query result | CollisionManager provides query |
| **Navigation2D** | `navigation_changed(area)` signal | — | CollisionManager emits signal |

**Godot 4.6 Integration Note**: TileMap collision通过TileSet physics layers自动处理。方块碰撞系统不创建CollisionShape2D节点——它提供查询API、信号事件、collision mask配置参考。

## Formulas

### Formula 1: Collision Severity Calculation

**Purpose**: Calculate collision feedback intensity for gamepad vibration, screen shake, and audio.

**Enhanced Formula with Vehicle Context** (addresses game-designer feedback):
```gdscript
severity = (speed_ratio * impact_angle) * integrity_factor * obstacle_significance

# Where:
# speed_ratio = impact_speed / MAX_VEHICLE_SPEED (cells/sec)
# integrity_factor = 1.0 + (1.0 - vehicle.integrity_ratio) * 0.5  # Low integrity = more dramatic
# obstacle_significance = 1.0 (normal), 2.0 (breach-critical walls during 尸潮)
```

**Variables Table**:

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `impact_speed` | float | [0.0, MAX_VEHICLE_SPEED] cells/sec | Vehicle velocity magnitude at collision moment |
| `MAX_VEHICLE_SPEED` | float | (0.0, INF) cells/sec | Constant from战车属性系统 (placeholder: 10.0 cells/sec) |
| `impact_angle` | float | [0.0, 1.0] | Collision alignment factor: `abs(dot(velocity.normalized(), collision_normal))` |
| `integrity_factor` | float | [1.0, 1.5] | Amplifier for low vehicle integrity (Pillar 1: 战车即生命) |
| `obstacle_significance` | float | [1.0, 2.0] | Wall importance multiplier (breach-critical = 2.0) |

**Boundary Tests**:
- impact_speed = 0 → severity = 0 (轻擦或静止接触) ✓
- impact_speed = MAX, angle = 1.0, integrity = 100%, significance = 1.0 → severity = 1.0 (标准碰撞) ✓
- impact_speed = MAX, angle = 1.0, integrity = 50%, significance = 1.0 → severity = 1.25 (低耐久碰撞更剧烈) ✓
- impact_speed = MAX, angle = 1.0, integrity = 50%, significance = 2.0 → severity = 2.5 → capped at 1.0 ✓
- impact_angle = 0 (parallel) → severity = 0 (滑擦) ✓

**Safety Guards**:
```gdscript
func _calculate_collision_severity(body: PhysicsBody2D, normal: Vector2, vehicle: VehicleStats) -> float:
    assert(MAX_VEHICLE_SPEED > 0.0, "MAX_VEHICLE_SPEED must be positive")
    
    # Get velocity from appropriate property (Godot 4.6)
    var velocity: Vector2
    if body is CharacterBody2D:
        velocity = body.velocity
    elif body is RigidBody2D:
        velocity = body.linear_velocity
    else:
        velocity = Vector2.ZERO
    
    var impact_speed := max(0.0, velocity.length() / CELL_SIZE)  # Convert to cells/sec
    var impact_angle := abs(velocity.normalized().dot(normal))
    impact_angle = clamp(impact_angle, 0.0, 1.0)
    
    # Context factors
    var integrity_factor := 1.0 + (1.0 - vehicle.integrity_ratio) * 0.5
    var obstacle_significance := _get_obstacle_significance(normal)
    
    var severity := (impact_speed / MAX_VEHICLE_SPEED) * impact_angle * integrity_factor * obstacle_significance
    return clamp(severity, 0.0, 1.0)

func _get_obstacle_significance(normal: Vector2) -> float:
    # Returns higher significance for breach-critical walls
    # Implementation: check if collision is defensive structure during 尸潮
    # Placeholder: return 1.0 (will be implemented with 尸潮系统 integration)
    return 1.0
```

**Output Range**: [0.0, 1.0] — mapped to feedback tiers:
- `> 0.7`: 强力振动 + 碰撞音效 + 屏幕微震 + **temporary speed reduction (5%)**
- `> 0.3`: 中等振动 + 音效 + **camera shake intensity proportional to severity**
- `≤ 0.3`: 轻微音效

---

### Formula 2: Swept Collision Detection (Vehicle-Sized Body)

**Purpose**: Detect collision for moving entities larger than a single cell (战车 = 2×2 cells).

**Algorithm**: DDA (Digital Differential Analyzer) cell traversal with motion length cap.

```gdscript
const MAX_SWEPT_STEPS: int = 64  # Cap for performance

func check_swept_collision(shape_rect: Rect2, motion: Vector2) -> Dictionary:
    var motion_length := motion.length()
    
    # Degenerate case: no motion
    if motion_length < EPSILON:
        return check_static_collision(shape_rect)
    
    var cells_to_check: Array[Vector2i] = []
    var steps := maxi(int(ceil(motion_length / CELL_SIZE)), 1)
    steps = mini(steps, MAX_SWEPT_STEPS)  # Cap steps
    var t_step := 1.0 / steps  # Always <= 1.0
    
    for i in range(steps + 1):
        var t := i * t_step
        var check_pos := shape_rect.position + motion * t
        var check_cell := world_to_cell(check_pos)
        for offset in _shape_cell_offsets:
            cells_to_check.append(check_cell + offset)
    
    # Deduplicate and check
    var seen: Dictionary = {}
    for cell in cells_to_check:
        if cell in seen: continue
        seen[cell] = true
        if is_cell_solid(cell):
            return {cell = cell, collision = true}
    
    return {collision = false}
```

**Variables Table**:

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `shape_rect` | Rect2 | size ≥ CELL_SIZE | Entity collision bounds (战车: 64×64 px) |
| `motion` | Vector2 | length [0.0, 2048 px] | Velocity × delta (capped) |
| `CELL_SIZE` | int | 32 px | Constant from TileMap system |
| `_shape_cell_offsets` | Array[Vector2i] | Fixed per entity | Cells shape spans (2×2 = [(0,0),(1,0),(0,1),(1,1)]) |
| `steps` | int | [1, MAX_SWEPT_STEPS] | Number of traversal steps |
| `EPSILON` | float | 0.001 | Minimum motion threshold |

**Boundary Tests**:
- motion.length() = 0 → static collision check ✓
- motion.length() = 1 px → steps = ceil(1/32) = 1 → single iteration ✓
- motion.length() = 500 px → steps = 16 → 16 iterations ✓
- motion.length() = 2000 px → steps = cap(64) → capped ✓

**Output**: `{cell: Vector2i, collision: bool}` — collision cell position if found.

---

### Formula 3: Broad-Phase Raycast Optimization

**Purpose**: Projectile collision detection optimized with broad-phase cell check before physics raycast.

**Algorithm**: DDA traversal for proper line-following cell visitation.

```gdscript
const MAX_RAYCAST_STEPS: int = 128

func raycast_tile_collision(start: Vector2, direction: Vector2, max_distance: float, mask: int) -> Dictionary:
    if direction.length_squared() < EPSILON:
        push_warning("raycast_tile_collision: zero direction")
        return {}
    
    var dir_normalized := direction.normalized()
    var current_cell := world_to_cell(start)
    var end_pos := start + dir_normalized * max_distance
    var end_cell := world_to_cell(end_pos)
    
    # DDA step calculation - compute distance to next cell boundary
    var step := Vector2i(
        1 if dir_normalized.x >= 0 else -1,
        1 if dir_normalized.y >= 0 else -1
    )

    var cell_size_f := float(CELL_SIZE)
    var cell_start := cell_to_world(current_cell)

    var t_max := Vector2()
    var t_delta := Vector2()

    if dir_normalized.x != 0:
        # Distance to next cell boundary (not midpoint)
        if step.x > 0:
            t_max.x = (cell_start.x + cell_size_f - start.x) / dir_normalized.x
        else:
            t_max.x = (cell_start.x - start.x) / dir_normalized.x
        t_delta.x = cell_size_f / abs(dir_normalized.x)
    else:
        t_max.x = INF

    if dir_normalized.y != 0:
        # Distance to next cell boundary (not midpoint)
        if step.y > 0:
            t_max.y = (cell_start.y + cell_size_f - start.y) / dir_normalized.y
        else:
            t_max.y = (cell_start.y - start.y) / dir_normalized.y
        t_delta.y = cell_size_f / abs(dir_normalized.y)
    else:
        t_max.y = INF
        t_delta.y = INF
    
    var steps := 0
    while steps < MAX_RAYCAST_STEPS:
        if is_cell_solid(current_cell):
            var space_state := get_world_2d().direct_space_state
            # Godot 4.6 signature: create(from, to, collision_mask, collide_with_areas)
            var query := PhysicsRayQueryParameters2D.create(start, end_pos, mask, false)
            return space_state.intersect_ray(query)
        
        if t_max.x < t_max.y:
            current_cell.x += step.x
            t_max.x += t_delta.x
        else:
            current_cell.y += step.y
            t_max.y += t_delta.y
        
        steps += 1
        
        if (step.x > 0 and current_cell.x > end_cell.x) or \
           (step.x < 0 and current_cell.x < end_cell.x) or \
           (step.y > 0 and current_cell.y > end_cell.y) or \
           (step.y < 0 and current_cell.y < end_cell.y):
            break
    
    return {}
```

**Variables Table**:

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `start` | Vector2 | Any | Ray origin (world coordinates) |
| `direction` | Vector2 | length > EPSILON | Ray direction (must be non-zero) |
| `max_distance` | float | [0.0, 4096 px] | Maximum ray travel distance |
| `mask` | int | Collision mask bits | Filter for which collision layers to detect |
| `t_max` | Vector2 | Per-axis | Time to next cell boundary in each axis |
| `t_delta` | Vector2 | Per-axis | Time per cell in each axis |

**Boundary Tests**:
- direction = Vector2.ZERO → early return {} ✓
- max_distance = 0 → end_cell == current_cell → single check ✓
- max_distance = 500 → steps ≈ 16 → capped at 128 ✓

**Output**: `{position: Vector2, normal: Vector2, collider: Object}` — physics raycast result.

---

### Formula 4: Nearest Collision Query (WALL_BREAKER Targeting)

**Purpose**: Find nearest destroyable collision cell within radius for WALL_BREAKER enemy targeting.

```gdscript
const MAX_SEARCH_RADIUS_CELLS: int = 32  # ~1024 pixels

func get_nearest_collision(pos: Vector2, radius: float, filter: int) -> Dictionary:
    if radius <= 0.0:
        return {}
    
    var center_cell := world_to_cell(pos)
    var radius_cells := int(radius / CELL_SIZE) + 1
    radius_cells = mini(radius_cells, MAX_SEARCH_RADIUS_CELLS)
    
    var nearest_cell: Vector2i
    var nearest_dist: float = INF
    
    for dx in range(-radius_cells, radius_cells + 1):
        for dy in range(-radius_cells, radius_cells + 1):
            var check_cell := center_cell + Vector2i(dx, dy)
            if not is_cell_solid(check_cell): continue
            if not matches_collision_filter(check_cell, filter): continue
            
            var cell_center := cell_to_world_center(check_cell)
            var dist := (cell_center - pos).length()
            
            if dist < nearest_dist:
                nearest_dist = dist
                nearest_cell = check_cell
    
    if nearest_dist < INF:
        return {cell = nearest_cell, distance = nearest_dist}
    return {}

## matches_collision_filter Interface Definition

**Purpose**: Filter collision cells by type for WALL_BREAKER targeting and other enemy AI queries.

```gdscript
# Collision filter bitmask constants
const FILTER_DESTROYABLE: int = 0x01     # Standard walls (wood, stone)
const FILTER_REINFORCED: int = 0x02      # Reinforced walls (iron, steel)
const FILTER_ALL_WALLS: int = 0xFF       # All wall types

func matches_collision_filter(cell: Vector2i, filter: int) -> bool:
    # Returns true if cell's block type matches the filter bitmask
    # Implementation depends on block_type_database integration
    var block_type_id := get_cell_block_type(cell)
    if block_type_id < 0:  # Empty or invalid cell
        return false
    
    # Map block_type_id to filter bits
    # This requires BlockTypeDatabase to expose block attributes
    var block_flags := _get_block_flags(block_type_id)
    return (block_flags & filter) != 0

func _get_block_flags(block_type_id: int) -> int:
    # Returns collision filter flags for block type
    # Flags derived from block_type_database.md attributes:
    # - destroyable blocks: FILTER_DESTROYABLE
    # - reinforced blocks: FILTER_REINFORCED
    # Implementation: query BlockTypeDatabase resource
    # ID ranges from block_type_database.md:
    # - 400-449: standard destroyable walls (wood, stone)
    # - 450-499: reinforced walls (iron, steel)
    if block_type_id >= 400 and block_type_id < 450:
        return FILTER_DESTROYABLE
    elif block_type_id >= 450 and block_type_id < 500:
        return FILTER_DESTROYABLE | FILTER_REINFORCED
    return 0
```

**Variables Table**:

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `pos` | Vector2 | Any | Enemy position (world coordinates) |
| `radius` | float | [0.0, 1024 px] | Search radius (capped) |
| `filter` | int | Collision filter bitmask | Filter for destroyable collisions (e.g., FILTER_DESTROYABLE = 0x01) |
| `radius_cells` | int | [1, 32] | Cells to search in each direction |
| `nearest_dist` | float | [0.0, INF] | Distance to nearest found collision |
| `FILTER_DESTROYABLE` | int | 0x01 | Bitmask for standard destroyable walls |
| `FILTER_REINFORCED` | int | 0x02 | Bitmask for reinforced walls |

**Boundary Tests**:
- radius = 0 → early return {} ✓
- radius < 0 → early return {} ✓
- radius = 1000 → radius_cells = cap(32) → 65×65 = 4,225 iterations (acceptable) ✓
- No solid cells → return {} ✓

**Output**: `{cell: Vector2i, distance: float}` — nearest collision cell and distance.

---

**Constants to Add to Registry**:
- `MAX_SWEPT_STEPS` = 64
- `MAX_RAYCAST_STEPS` = 128
- `MAX_SEARCH_RADIUS_CELLS` = 32
- `COLLISION_EPSILON` = 0.001

## Edge Cases

### Edge Case 1: Collision Modification During Physics Frame (Race Condition)

**Scenario**: 挖掘系统删除方块后，物理引擎可能已在该帧查询过碰撞形状，导致战车仍与已清空cell碰撞一帧。

**Expected Behavior**: 方块修改排队到物理帧边界执行（Rule 4）。修改在下一帧生效，当前帧物理结果不受影响。

**Resolution**: 
- 挖掘/放置系统调用`queue_tile_modification()`而非直接`set_cell()`
- CollisionManager在`_physics_process()`开始时批量应用修改
- 修改后立即发射`collision_removed`/`collision_added`信号

**Failure Mode**: 如果直接调用`set_cell()`，物理引擎可能：
- 让战车穿透新清空的区域（碰撞形状延迟消失）
- 或让子弹撞上已消失的墙体（碰撞形状延迟更新）

---

### Edge Case 2: Vehicle Positioned Exactly at Cell Boundary

**Scenario**: 战车碰撞体(64×64)跨越2×2 cells。当战车位置精确在cell边界时，shape_cell_offsets计算可能不一致。

**Expected Behavior**: `world_to_cell()`使用floor()取整，边界上的shape总是映射到一致的cell集合。

**Resolution**:
```gdscript
# Example: 64×64 shape at position (32.0, 32.0) (boundary)
# world_to_cell(32.0) = floor(32/32) = 1
# Offsets: [(1,1), (2,1), (1,2), (2,2)] — covers 4 cells correctly
```

**Failure Mode**: 如果使用round()而非floor()，位置微移可能导致shape映射到不同cell集合，造成碰撞检测跳跃。

---

### Edge Case 3: Projectile Hits Cell Corner vs Edge

**Scenario**: 子弹raycast命中cell角点时，physics raycast返回的normal可能不精确（角点碰撞normal不明确）。

**Expected Behavior**: 
- DDA traversal正确识别被命中的cell
- Physics raycast返回normal基于碰撞形状几何，而非cell中心
- 子弹反弹方向由physics normal决定

**Resolution**: 
- Raycast在DDA找到solid cell后，使用完整physics raycast（从start到end_pos）而非到cell中心
- Godot physics引擎正确处理角点碰撞normal

**Failure Mode**: 如果raycast终点设为cell中心而非实际射线终点，角点碰撞可能返回错误normal，子弹反弹方向异常。

---

### Edge Case 4: One-Way Platform Edge Collision (战车从侧面撞击)

**Scenario**: 战车从侧面撞向平台边缘（非从上方着陆），碰撞行为是什么？

**Expected Behavior**: 
- One-way platform只响应从上方来的碰撞（normal.y < 0）
- 侧面碰撞：战车穿透平台边缘，无碰撞响应
- 战车必须从上方接近才能着陆

**Resolution**: 
- **Collision mask filtering approach** (see Rule 3): one-way behavior implemented via body mask
- 战车collision_mask包含COLLISION_PLATFORM (bit 2, value 4)
- 行走敌人collision_mask不含bit 2 → 穿透平台
- Godot physics引擎自动处理：侧面碰撞忽略（基于碰撞形状几何），上方碰撞响应

**Failure Mode**: 如果collision mask配置错误，战车可能从侧面被平台阻挡，无法穿过平台下方区域。

---

### Edge Case 5: Multiple Cells Change in Same Physics Frame

**Scenario**: 炸弹爆炸同时删除10个方块，触发10次`collision_removed`信号。

**Expected Behavior**: 
- 10次`set_cell()`调用合并为单次批量修改
- `collision_removed`信号合并为单次`navigation_changed(area)`信号
- 下游系统（敌人AI）只更新一次pathfinding，而非10次

**Resolution**: 
- CollisionManager收集同帧所有修改，发射单次聚合信号
- 信号参数为受影响的区域（Rect2i），而非单个cell

```gdscript
func _physics_process(_delta):
    if _pending_modifications.is_empty(): return
    
    var affected_area := _calculate_affected_bounds(_pending_modifications)
    
    for mod in _pending_modifications:
        # Godot 4.6 signature: set_cell(layer, coords, source_id, atlas_coords, alternative_tile)
        _tilemap.set_cell(mod.layer, mod.cell, mod.source_id, mod.atlas_coords, mod.alternative_tile)
    
    # Emit aggregate signal
    navigation_changed.emit(affected_area)
    _pending_modifications.clear()
```

**Failure Mode**: 如果每个修改单独发射信号，敌人AI在同帧接收10次pathfinding更新请求，性能浪费或逻辑混乱。

---

### Edge Case 6: Navigation Mesh Update Delay During Enemy Pathfinding

**Scenario**: 挖掘系统删除墙体 → `navigation_changed`信号发射 → NavigationRegion2D开始regenerate → 敌人AI在此期间查询旧nav mesh路径。

**Expected Behavior**: 
- Navigation regeneration是异步操作（可能需1-2帧）
- 敌人AI使用"tentative path"：先尝试旧路径，遇到新开放区域后重新查询
- 或敌人AI等待nav mesh更新完成（适用于静态敌人）

**Resolution**: 
- 信号`navigation_changed`标记区域"pending update"
- 敌人AI收到信号后，重算路径前等待nav mesh `navigation_finished`信号
- 或敌人AI使用实时tile collision查询作为fallback（不依赖nav mesh）

**Failure Mode**: 如果敌人AI在nav mesh更新期间强制使用旧路径，可能穿过已开放的通道或撞上已消失的墙体。

---

### Edge Case 7: Zero Velocity Collision (战车静止被撞)

**Scenario**: 战车静止（velocity = 0），敌人子弹命中战车。碰撞severity计算为0，但碰撞真实发生。

**Expected Behavior**: 
- 碰撞severity = 0表示"无碰撞冲击感"，而非"无碰撞"
- 子弹命中判定独立于severity计算（使用collision_layer/mask）
- severity仅用于反馈强度，不影响碰撞是否发生

**Resolution**: 
- severity公式中impact_speed = max(0, velocity.length()) = 0
- severity = 0 → 轻微音效（子弹命中战车装甲）
- 子弹命中逻辑使用collision mask检测，不受severity影响

**Failure Mode**: 如果severity影响碰撞判定本身，静止战车可能不接收子弹命中，导致战斗逻辑错误。

---

### Edge Case 8: Enemy Mid-Path When Collision Removed

**Scenario**: 敌人AI正在沿路径移动，路径穿过某cell。挖掘系统删除该cell的collision → 路径不再有效。

**Expected Behavior**: 
- 敌人收到`collision_removed`信号
- 敌人重新计算路径（可能发现更短路径）
- 或敌人继续当前路径，跳过已清空cell

**Resolution**: 
- 敌人AI订阅`collision_removed`信号
- 信号参数包含cell → enemy检查cell是否在当前路径上
- 如果在路径上 → 触发`recalculate_path()`

**Failure Mode**: 如果敌人不订阅信号，继续沿旧路径移动，可能撞上已消失墙体（物理碰撞失败但路径逻辑错误）或错过新开放通道。

---

### Edge Case 9: Swept Collision Truncation for Fast Objects

**Scenario**: 战车速度极快（velocity × delta = 2000 px = 62.5 cells），steps被cap到MAX_SWEPT_STEPS=64，可能跳过中间cell。

**Expected Behavior**: 
- Cap确保性能（64 iterations × 4 offsets = 256 checks）
- 极端速度下可能遗漏碰撞 → **Mitigation required**

**Resolution**:
- **Design constraint**: `MAX_VEHICLE_SPEED × max_delta × CELL_SIZE ≤ MAX_SWEPT_STEPS × CELL_SIZE`
- Simplified: `MAX_VEHICLE_SPEED × max_delta ≤ MAX_SWEPT_STEPS cells`
- Example: MAX_VEHICLE_SPEED = 10 cells/sec, delta_max = 0.05s → motion = 0.5 cells → steps = 1 ✓
- **Level design guidance**: Defensive walls should be ≥2 cells thick for gameplay durability and visual weight, not collision safety
- **No fallback detection**: Ghost wall penetration is preferable to ghost collision stops (vehicle stopping in empty space)

**Failure Mode**: If战车速度设计超出cap覆盖范围, high-speed vehicle may penetrate 1-cell thin walls. Level design (thick walls) mitigates gameplay impact.

---

### Edge Case 10: Collision Layer Conflict (Cell Has Multiple Collision Types)

**Scenario**: TileMap cell在Layer 1有terrain碰撞，Layer 2有structure碰撞。两个碰撞形状重叠。

**Expected Behavior**: 
- Godot physics同时检测两个layer的碰撞
- 战车collision_mask包含bit 1+2 → 同时检测terrain和structure
- 碰撞normal来自两个形状的union

**Resolution**: 
- 正常行为：多个collision layer叠加等于更厚的碰撞体
- 战车撞墙时，terrain和structure同时提供碰撞响应
- 挖掘只删除structure layer → terrain仍提供碰撞

**Failure Mode**: 如果collision layer设计不一致，可能导致：
- 碰撞"重叠"导致战车被阻挡两次（性能浪费）
- 或碰撞"缺失"导致战车穿透（layer mask配置错误）

---

### Edge Case 11: Collision Signal Timing vs Entity Despawn

**Scenario**: 方块删除 → `collision_removed`信号发射 → 但订阅该信号的entity已被despawn（如战车驶离chunk）。

**Expected Behavior**: 
- 信号发射时检查订阅者是否仍active
- 或entity despawn时自动取消订阅

**Resolution**: 
- 使用Godot信号系统（自动处理disconnect）
- Entity在`_exit_tree()`时disconnect所有collision信号

**Failure Mode**: 如果entity未正确disconnect，信号可能触发已删除entity的回调，导致null reference错误。

## Dependencies

### Upstream Dependencies

| System | Layer | What It Provides | What This System Uses | Interface |
|--------|-------|------------------|----------------------|-----------|
| **TileMap世界系统** (#1) | Foundation | collision_shape data in Layer 2; CELL_SIZE constant; world_to_cell() / cell_to_world() APIs; is_cell_solid() query | All collision query functions depend on TileMap cell data; CELL_SIZE for DDA traversal; world_to_cell for coordinate conversion | CollisionManager wraps TileMap, does not replace it |

**Critical Interface**:
```gdscript
# TileMap世界系统 provides:
const CELL_SIZE: int = 32  # pixels
func world_to_cell(world_pos: Vector2) -> Vector2i
func cell_to_world(cell: Vector2i) -> Vector2
func get_cell_collision_shape(cell: Vector2i, layer: int) -> int  # 0/1/2
func is_cell_solid(cell: Vector2i) -> bool
# Godot 4.6 TileMap native: set_cell(layer, coords, source_id, atlas_coords, alternative_tile)
func set_cell(layer: int, coords: Vector2i, source_id: int = -1, atlas_coords: Vector2i = Vector2i(0, 0), alternative_tile: int = 0)
```

**Dependency Status**: TileMap世界系统 GDD exists (`design/gdd/tilemap-world-system.md`), Approved. Interface verified.

---

### Downstream Dependencies

| System | Layer | What It Needs | What This System Provides | Signal/API |
|--------|-------|---------------|--------------------------|------------|
| **方块挖掘系统** (#12) | Core | Collision removal when block destroyed; collision_removed event | queue_tile_modification(cell, layer, DELETE); collision_removed signal | API + Signal |
| **方块放置系统** | Core | Collision creation when block placed; collision_added event; placement collision preview | queue_tile_modification(cell, layer, SET, tile_data); collision_added signal; get_tiles_in_rect for placement validation | API + Signal |
| **战车驾驶系统** (#18) | Core | Vehicle-sized collision detection; collision response feedback; collision severity for gamepad vibration | check_swept_collision(shape, motion); vehicle_collision signal with severity | API + Signal |
| **敌人AI系统** (#36) | Core | Pathfinding collision map; collision change notification; nearest destroyable collision for WALL_BREAKER | get_nearest_collision(pos, radius, filter); collision_added/removed signals; is_cell_solid query | API + Signal |
| **炮塔系统** (#38) | Core | Line-of-sight collision check; placement collision validation | raycast_tile_collision(start, end, mask); get_tiles_in_rect for turret footprint | API |

**Dependency Status**: All downstream systems GDDs not yet written (Not Started in systems-index.md). Interface contracts defined here, to be respected when those GDDs are authored.

---

### Bidirectional References

**方块碰撞系统 must appear in downstream GDDs**:
- 方块挖掘系统.md → Dependencies section: "方块碰撞系统 (#11) — collision_removed signal"
- 方块放置系统.md → Dependencies section: "方块碰撞系统 (#11) — collision_added signal, placement preview"
- 战车驾驶系统.md → Dependencies section: "方块碰撞系统 (#11) — swept collision, vehicle_collision feedback"
- 敌人AI系统.md → Dependencies section: "方块碰撞系统 (#11) — collision signals, nearest collision query"
- 炮塔系统.md → Dependencies section: "方块碰撞系统 (#11) — raycast_tile_collision"

**TileMap世界系统 GDD already mentions 方块碰撞系统** (verify upon design review):
- tilemap-world-system.md → "方块碰撞系统 wraps collision queries and emits signals"

---

### Collision Mask Dependencies (Cross-System Constants)

Collision layer/bitmask constants defined here must be registered in entities.yaml and referenced by all physics-related systems:

| Constant | Value | Referenced By |
|----------|-------|---------------|
| `COLLISION_TERRAIN` | 1 | TileMap, Battle Wagon, Enemies, Projectiles |
| `COLLISION_STRUCTURE` | 2 | TileMap, Battle Wagon, Enemies, Projectiles |
| `COLLISION_PLATFORM` | 4 | TileMap, Battle Wagon (only) |
| `COLLISION_ENEMY_BODY` | 8 | Enemies, Player Projectiles |
| `COLLISION_PLAYER_BODY` | 64 | Battle Wagon, Enemy Projectiles |

**Registration**: These constants must be added to `entities.yaml` in Phase 5. All downstream systems (战车属性系统, 敌人类型数据库) must reference these IDs for collision_layer/mask configuration.

---

### Dependency Risk Assessment

| Dependency | Risk | Mitigation |
|------------|------|------------|
| TileMap世界系统 (upstream) | LOW — GDD exists, interface stable | CollisionManager wraps TileMap, does not modify it |
| 方块挖掘系统 (downstream) | MEDIUM — GDD not written | Signal contract defined here; 挖掘系统 author must use queue_tile_modification |
| 战车驾驶系统 (downstream) | MEDIUM — GDD not written | swept collision API defined here; 驾驶系统 must use check_swept_collision |
| 敌人AI系统 (downstream) | HIGH — depends on collision signals for pathfinding | Signal architecture is critical; must be verified in 敌人AI GDD |
| Collision mask constants | MEDIUM — must be consistent across all systems | Register in entities.yaml; consistency-check will catch conflicts |

## Tuning Knobs

| Knob Name | Default | Safe Range | Gameplay Effect | Tuning Notes |
|-----------|---------|------------|-----------------|--------------|
| `MAX_SWEPT_STEPS` | 64 | [16, 128] | Collision detection precision for fast-moving entities; higher = more accurate, lower = faster | Cap prevents performance spikes. If战车速度超过300 px/s, increase to 96 or 128. Lower for mobile optimization. |
| `MAX_RAYCAST_STEPS` | 128 | [32, 256] | Projectile collision range/precision; higher = longer accurate range, lower = truncation risk | Match to turret max range. If炮塔range > 500 px, increase. Lower for projectile-heavy scenes (尸潮). |
| `MAX_SEARCH_RADIUS_CELLS` | 32 | [8, 64] | WALL_BREAKER enemy detection range; higher = more wall targets, lower = focused targeting | 32 cells = 1024 px. Match to WALL_BREAKER behavior type detection_radius. |
| `COLLISION_EPSILON` | 0.001 | [0.0001, 0.01] | Minimum motion threshold; lower = detects tiny movements, higher = skips micro-collision | 0.001 px ≈ static. Increasing causes jitter on very slow objects. |
| `MAX_VEHICLE_SPEED` | 10.0 | [5.0, 15.0] cells/sec | Collision severity scaling anchor; affects gamepad vibration intensity; **Must align with vehicle-type-database.md speed units** | **Owned by战车属性系统** — placeholder here (10.0 cells/sec ≈ 320 px/sec). Changing affects severity formula globally. |
| `SEVERITY_THRESHOLD_HIGH` | 0.7 | [0.5, 0.95] | Strong collision feedback trigger; lower = more frequent strong feedback, higher = only major collisions | Affects gamepad vibration + screen shake. Tune for Pillar 1 "战车即生命" impact feel. |
| `SEVERITY_THRESHOLD_LOW` | 0.3 | [0.1, 0.5] | Light collision feedback trigger; lower = all collisions have audio, higher = only noticeable collisions | Affects collision sound frequency. Must be < SEVERITY_THRESHOLD_HIGH. |
| `SIGNAL_BATCH_ENABLED` | true | [true, false] | Aggregate multiple collision changes into single signal; true = efficient pathfinding updates, false = per-cell signals | Disable for debugging; enable for production (尸潮 high collision changes). |

---

### Tuning Guidance by Milestone

**MVP Phase**: 
- Focus on `MAX_VEHICLE_SPEED` and severity thresholds for Pillar 1 collision feel
- Set conservative caps (MAX_SWEPT_STEPS=64, MAX_RAYCAST_STEPS=128) for stability
- Enable SIGNAL_BATCH_ENABLED for performance baseline

**Vertical slice Phase**:
- Tune WALL_BREAKER detection (`MAX_SEARCH_RADIUS_CELLS`) when敌人AI系统 designed
- Tune severity thresholds based on playtest feedback ("collision feels too light" → lower thresholds)

**Alpha Phase**:
- Profile during尸潮 (100+ enemies, 50+ projectiles) → may need to increase caps
- Optimize for platform target (PC vs console vs mobile)

---

### Knob Interaction Matrix

| Knob A | Knob B | Interaction | Constraint |
|--------|--------|-------------|------------|
| `MAX_SWEPT_STEPS` | `MAX_VEHICLE_SPEED` | Steps must cover max motion per frame | `MAX_VEHICLE_SPEED × delta ≤ MAX_SWEPT_STEPS × CELL_SIZE` |
| `MAX_RAYCAST_STEPS` | 炮塔系统 `TURRET_RANGE` | Steps must cover max projectile travel | `TURRET_RANGE ≤ MAX_RAYCAST_STEPS × CELL_SIZE` |
| `SEVERITY_THRESHOLD_LOW` | `SEVERITY_THRESHOLD_HIGH` | Thresholds define feedback tiers | `LOW < HIGH < 1.0` |
| `MAX_SEARCH_RADIUS_CELLS` | 敌人AI `WALL_BREAKER_RANGE` | Detection range must align | `MAX_SEARCH_RADIUS_CELLS × CELL_SIZE ≥ WALL_BREAKER_RANGE` |

## Visual/Audio Requirements

### Visual Requirements

**No direct visual output** — Collision shapes are invisible physics constructs. However, collision **feedback** may require visual cues:

| Feedback Type | Trigger Condition | Visual Effect | Implementation Owner |
|---------------|-------------------|---------------|---------------------|
| Screen shake | severity > 0.7 | Camera shake (magnitude proportional to severity) | 摄像机系统 (#10) |
| Collision dust/debris | severity > 0.3 | Particle burst at collision point | VFX系统 (placeholder) |
| Vehicle bounce visual | any collision > severity 0.1 | Vehicle sprite recoil animation | 战车驾驶系统 (#18) |

**方块碰撞系统 responsibility**: Emit `vehicle_collision` signal with severity. **Not responsible** for actual visual effect execution.

---

### Audio Requirements

**Collision sounds triggered by severity thresholds**:

| Severity Range | Sound Category | Implementation Owner |
|----------------|----------------|---------------------|
| `> 0.7` | Heavy collision thud + metal scrape | 音效系统 (#52) |
| `> 0.3` | Medium collision bump | 音效系统 (#52) |
| `≤ 0.3` | Light scrape (optional) | 音效系统 (#52) |

**方块碰撞系统 responsibility**: Emit `vehicle_collision` signal with severity and collision point position. 音效系统 handles sound selection and playback.

**Signal Interface**:
```gdscript
signal vehicle_collision(body: PhysicsBody2D, collision_normal: Vector2, severity: float, collision_point: Vector2)
```

音效系统 subscribes to this signal and maps severity → sound asset.

---

### Gamepad Vibration Requirements

**Collision feedback via gamepad vibration** (Pillar 1: 战车即生命):

| Severity Range | Vibration Pattern | Implementation Owner |
|----------------|-------------------|---------------------|
| `> 0.7` | Strong vibration (magnitude 0.8, duration 200ms, both motors) | 输入控制系统 (#9) |
| `> 0.3` | Medium vibration (magnitude 0.5, duration 100ms, strong motor only) | 输入控制系统 (#9) |
| `≤ 0.3` | Light vibration (magnitude 0.2, duration 50ms, weak motor) | 输入控制系统 (#9) |

**方块碰撞系统 responsibility**: Emit `vehicle_collision` signal with severity. 输入控制系统 subscribes and triggers vibration via Godot InputEventJoypadMotion.

---

### No Direct Assets Required

方块碰撞系统本身**不包含**:
- No sprites, textures, or visual assets
- No audio files (sounds owned by音效系统)
- No particle effects (owned by VFX system)

**System is pure logic/API layer** — all feedback presentation handled by downstream systems.

## UI Requirements

### No Direct HUD Elements

方块碰撞系统**不直接显示在HUD** — 碰撞是隐性的物理规则，玩家不通过UI感知。

---

### Indirect UI Feedback (via Downstream Systems)

| UI Element | Trigger Condition | Purpose | Implementation Owner |
|------------|-------------------|---------|---------------------|
| Placement preview highlight | 方块放置系统 queries collision preview | Show "where would this block movement?" before commit | 方块放置系统 (#13) + HUD系统 (#49) |
| Blocked path warning | 撤退判定系统 detects collision blocking retreat path | "Route blocked" icon on HUD | 撤退判定系统 (#32) + HUD系统 (#49) |
| Enemy path indicator (debug) | 敌人AI系统 pathfinding blocked | Debug overlay showing enemy path collision points | 敌人AI系统 (#36) — debug only |

**方块碰撞系统 responsibility**: Provide collision query APIs (`get_tiles_in_rect`, `raycast_tile_collision`) for downstream systems to build UI feedback. **Not responsible** for UI rendering.

---

### Placement Collision Preview (Future Feature)

**方块放置系统** may need collision impact preview when player selects build item:

- **Ghost preview**: Show placement cell with collision outline
- **Impact overlay**: Highlight entities that would be blocked (战车 path, enemy lanes)
- **Query required**: `get_tiles_in_rect(placement_bounds)` + filter for collision cells

**Interface** (placeholder for 方块放置系统 GDD):
```gdscript
func preview_placement_collision(cell: Vector2i, tile_type: int) -> Dictionary:
    # Returns: {blocked_entities: Array, collision_added: bool}
```

**Note**: This UI requirement is **owned by方块放置系统**, not 方块碰撞系统. Collision system only provides the query API.

---

### Debug UI (Development Only)

For QA and debugging, collision system may expose:

| Debug Overlay | Purpose | Implementation |
|---------------|---------|----------------|
| Collision shape wireframe | Visualize all collision cells in scene | Godot `CollisionShape2D.debug_draw` enabled in editor |
| Collision query log | Print every collision query call | Optional logging in CollisionManager (debug build only) |
| Signal emission log | Track collision_added/removed events | Subscribe and print to console (debug mode) |

**Not part of production UI** — removed before release.

---

### Accessibility Considerations

**No direct accessibility requirement** — collision is physics-layer, not player-facing.

Indirect accessibility via downstream systems:
- Gamepad vibration for collision feedback (Pillar 1) — covered in Visual/Audio section
- Screen shake visual alternative for non-gamepad players — 摄像机系统 responsibility
- Sound cues for collision — 音效系统 responsibility

## Acceptance Criteria

### Query Correctness

| AC# | Criterion | Verification Method |
|-----|-----------|---------------------|
| AC1 | `is_cell_solid(cell)` returns `true` for cells with `collision_shape=1` | Unit test: setup TileMap cell with collision_shape=1, assert query returns true |
| AC2 | `is_cell_solid(cell)` returns `false` for cells with `collision_shape=0` | Unit test: setup cell with collision_shape=0, assert query returns false |
| AC3 | `raycast_tile_collision(start, end)` returns Dictionary with keys: `position` (Vector2i of first solid cell intersecting ray from start to end), `normal` (Vector2), or empty Dictionary if no collision | Unit test: ray from (0,0) to (100,0) across solid cell at (32,0), assert returns {position: (1,0), normal: (0,-1)} |
| AC4 | `check_swept_collision(shape_rect, motion)` returns `{collision: true, cell: Vector2i}` when shape intersects solid cell during motion | Unit test: 64×64 shape moving 10px toward solid cell, assert collision detected |
| AC5 | `get_nearest_collision(pos, radius, filter)` returns nearest solid cell within radius, `{cell: Vector2i, distance: float}` | Unit test: search radius 200px around pos, assert returned cell is solid and distance ≤ 200 |

---

### Signal Emission

| AC# | Criterion | Verification Method |
|-----|-----------|---------------------|
| AC6 | `collision_removed` signal emitted when cell `collision_shape` changes from 1→0 | Integration test: subscribe to signal, call `queue_tile_modification(cell, layer, DELETE)` on solid cell, await signal, assert received |
| AC7 | `collision_added` signal emitted when cell `collision_shape` changes from 0→1 | Integration test: subscribe to signal, call `queue_tile_modification(cell, layer, SET, tile_data)` on empty cell, await signal |
| AC8 | `vehicle_collision` signal emitted when CharacterBody2D velocity.magnitude > EPSILON and `get_slide_collision(0).collider` is TileMap | Integration test: spawn CharacterBody2D with velocity, move toward solid tile, await signal, assert received |
| AC9 | `vehicle_collision` signal includes `severity` parameter with value in range [0.0, 1.0] | Integration test: subscribe to signal, trigger collision, assert `0.0 <= severity <= 1.0` |

---

### Performance (Automated Benchmark Tests)

| AC# | Criterion | Verification Method |
|-----|-----------|---------------------|
| AC10 | Benchmark: `check_swept_collision` with motion.length=500px executes 100 iterations with mean time ≤ 0.5ms | Automated CI test: GDUnit4 benchmark with profiler, assert mean_time ≤ 0.5ms |
| AC11 | Benchmark: `raycast_tile_collision` with max_distance=500px executes 100 iterations with mean time ≤ 0.2ms | Automated CI test: GDUnit4 benchmark, assert mean_time ≤ 0.2ms |
| AC12 | Benchmark: `get_nearest_collision` with radius=128px executes 100 iterations with mean time ≤ 50ms | Automated CI test: GDUnit4 benchmark, assert mean_time ≤ 50ms (reduced from 1024px to 128px for realistic threshold) |

**Note**: These are automated non-functional requirements, not manual QA checks. Verified in CI pipeline.

---

### Edge Cases

| AC# | Criterion | Verification Method |
|-----|-----------|---------------------|
| AC13 | `check_swept_collision` with motion=Vector2.ZERO returns `{collision: true/false, cell: Vector2i}` based on static shape overlap (no motion traversal) | Unit test: motion=(0,0), shape overlapping solid cell → assert collision=true; shape not overlapping → assert collision=false |
| AC14 | `raycast_tile_collision` with direction=Vector2.ZERO returns empty Dictionary `{}` | Unit test: direction=(0,0), assert return == {} |
| AC15 | `get_nearest_collision` with radius ≤ 0 returns empty Dictionary `{}` | Unit test: radius=0 and radius=-100, assert return == {} |

---

### Severity Calculation

| AC# | Criterion | Verification Method |
|-----|-----------|---------------------|
| AC16 | `severity = 0.0` when `impact_speed = 0` | Unit test: call `_calculate_collision_severity` with velocity=(0,0), assert return == 0.0 |
| AC17 | `severity = 1.0` when `impact_speed = MAX_VEHICLE_SPEED` (10.0 cells/sec placeholder) and `impact_angle = 1.0` (normalized perpendicular impact), `integrity_factor = 1.0`, `obstacle_significance = 1.0` | Unit test: speed=10.0 cells/sec, normal=(1,0), velocity=(10,0) cells/sec, assert severity == 1.0 |
| AC18 | `severity` in range [0.0, 1.0] for all valid inputs (speed ≥ 0, angle [0,1]) | Fuzz test: 100 random inputs (speed 0-500, angle 0-1), assert all outputs in [0,1] |

---

### Integration

| AC# | Criterion | Verification Method |
|-----|-----------|---------------------|
| AC19 | `queue_tile_modification` changes are applied at next `_physics_process` call (not immediate) | Integration test: queue modification, query cell immediately → unchanged; call `_physics_process`, query cell → changed |
| AC20 | Multiple queued modifications emit single `navigation_changed` signal with aggregate affected area | Integration test: queue 10 modifications in same frame, await signal, assert signal_count == 1, verify area covers all modified cells |

---

### Total: 20 Acceptance Criteria

| Category | Count |
|----------|-------|
| Query Correctness | 5 |
| Signal Emission | 4 |
| Performance (Automated) | 3 |
| Edge Cases | 3 |
| Severity Calculation | 3 |
| Integration | 2 |

## Open Questions

### Q1: MAX_VEHICLE_SPEED Final Value

**Question**: `MAX_VEHICLE_SPEED` is currently placeholder 10.0 cells/sec. Final value depends on战车属性系统 design.

**Unit Alignment**: MUST match vehicle-type-database.md speed units (cells/sec, not px/sec). 
- Conversion: `speed_cells = speed_px / CELL_SIZE` (CELL_SIZE = 32 px)
- Example: 320 px/sec = 10.0 cells/sec

**Impact**: Affects collision severity calculation and swept collision step count. If战车速度 > 10 cells/sec, may need to increase `MAX_SWEPT_STEPS`.

**Resolution Path**: When战车属性系统 (#17) is designed, lock `MAX_VEHICLE_SPEED` value in cells/sec and update collision severity formula. Registry entry must use cells/sec unit.

**Owner**: 战车属性系统 GDD author

---

### Q2: Vehicle Collision Shape Size

**Question**: Draft assumes战车collision shape is 2×2 cells (64×64 px). Is this correct?

**Impact**: Affects `_shape_cell_offsets` array and swept collision performance. Larger shape = more cells to check.

**Resolution Path**: When战车属性系统 (#17) defines `vehicle_collision_size`, update `check_swept_collision` to support variable shape sizes.

**Owner**: 战车属性系统 GDD author

---

### Q3: Navigation Mesh Integration Approach

**Question**: Should collision changes update Godot NavigationRegion2D, or should敌人AI use tile-based pathfinding without nav mesh?

**Options**:
- **Option A**: Use Godot Navigation2D — regenerate nav mesh on collision changes (standard Godot pattern, but regeneration cost during尸潮)
- **Option B**: Custom tile pathfinding — enemies query collision directly, no nav mesh (faster updates, but more AI code)

**Impact**: Affects `navigation_changed` signal usage and enemy AI complexity.

**Resolution Path**: Decide in敌人AI系统 (#36) design. Flag here as dependency.

**Owner**: 敌人AI系统 GDD author + Technical Director

---

### Q4: Projectile Collision with Platforms

**Question**: Should player/enemy projectiles collide with one-way platforms (collision_shape=2)?

**Current Spec**: Projectiles collision_mask excludes bit 4 (COLLISION_PLATFORM) → bullets pass through platforms.

**Alternative**: Bullets hit platforms → may be intentional for certain turret types (mortar?).

**Resolution Path**: Decide in战车武器系统 (#20) and炮塔系统 (#38). If some projectiles should hit platforms, add collision mask variant.

**Owner**: 战车武器系统 + 炮塔系统 GDD authors

---

### Q5: Collision Severity Feedback Tuning

**Question**: Severity thresholds (0.3, 0.7) mapped to feedback tiers. Are these correct for Pillar 1 "战车即生命"?

**Impact**: Gamepad vibration intensity and collision sound frequency. Tuned values may change after playtest.

**Resolution Path**: Prototype战车驾驶系统, playtest collision feel, adjust thresholds based on feedback.

**Owner**: UX playtest + 战车驾驶系统 implementation

---

### Q6: Flying Enemy Collision Behavior

**Question**: Current spec: flying enemies collision_mask = 0 → ignore all tile collision. Is this intended?

**Alternative**: Flying enemies could collide with terrain/structures but not platforms — mask = 1+2 (exclude bit 4).

**Resolution Path**: Decide in敌人类型数据库 (#4) and敌人AI系统 (#36). Update collision mask if flying enemies need collision.

**Owner**: 敌人类型数据库 + 敌人AI系统 GDD authors

---

### Q7: Collision Signal Priority vs Physics Frame

**Question**: `collision_removed` signal emitted immediately after `_physics_process` applies modifications. Should signal be emitted before or after physics step completes?

**Current Spec**: Signal emitted after `set_cell()` calls — entities receive signal before next physics step.

**Risk**: If entity responds to signal during same physics step (e.g., recalculates path), may cause order-of-operations issues.

**Resolution Path**: Test in prototype, verify signal timing doesn't cause logic errors. May need deferred signal emission.

**Owner**: Technical Director + prototype validation

---

### Q8: Swept Collision for Fast Projectiles

**Question**: Bullets may travel > 500 px/frame (fast projectiles). Should bullets use swept collision or raycast?

**Current Spec**: Bullets use raycast (single line query). Swept collision is for vehicle-sized bodies.

**Alternative**: Very fast bullets could use swept collision to detect multi-cell penetration.

**Resolution Path**: Decide in战车武器系统 (#20). If bullets need swept collision, add projectile variant of `check_swept_collision`.

**Owner**: 战车武器系统 GDD author

---

### Q9: 尸潮 Collision Budget Strategy

**Question**: 尸潮 scenarios (100+ enemies, 50+ projectiles, 10+ WALL_BREAKER enemies) generate collision queries that exceed 16.6ms frame budget. Current tuning knobs (MAX_SEARCH_RADIUS_CELLS, MAX_RAYCAST_STEPS) cap individual query costs but do not limit concurrent query count.

**Analysis**:
- 100 enemies × swept collision = ~5ms
- 50 projectiles × raycast = ~4ms
- 10 WALL_BREAKER × nearest collision = 110-220ms (even with reduced radius)
- **Total**: 119-229ms → exceeds frame budget by 7-14x

**Options**:
- **Option A**: Query batching/throttling — queue excess collision queries, process max N per frame
- **Option B**: Spatial partitioning — quadtree/grid for nearest collision, O(log n) instead of O(n²)
- **Option C**: Deferred pathfinding — enemies use cached collision data, refresh on signal only
- **Option D**: Design constraint — limit 尸潮 enemy/projectile count in 尸潮规模预估 (#35)

**Resolution Path**: Decide in 尸潮规模预估 (#35) and 敌人AI系统 (#36). Add tuning knobs for MAX_CONCURRENT_COLLISION_QUERIES and COLLISION_QUERY_QUEUE_ENABLED.

**Owner**: 尸潮规模预估 + 敌人AI系统 + Technical Director

---

### Resolution Tracking

| Question | Blocking System | Priority | Status |
|----------|-----------------|----------|--------|
| Q1 | 战车属性系统 (#17) | HIGH — affects severity formula | Open |
| Q2 | 战车属性系统 (#17) | HIGH — affects swept collision | Open |
| Q3 | 敌人AI系统 (#36) | HIGH — nav mesh vs tile pathfinding | Open |
| Q4 | 战车武器系统 (#20), 炮塔系统 (#38) | MEDIUM — projectile behavior | Open |
| Q5 | Playtest feedback | MEDIUM — feel tuning | Open |
| Q6 | 敌人类型数据库 (#4) | MEDIUM — flying enemy collision | Open |
| Q7 | Prototype validation | LOW — signal timing edge case | Open |
| Q8 | 战车武器系统 (#20) | LOW — fast projectile edge case | Open |
| Q9 | 尸潮规模预估 (#35), 敌人AI系统 (#36) | HIGH — frame budget exceeds limit | Open |
| Q4 | 战车武器系统 (#20), 炮塔系统 (#38) | MEDIUM — projectile behavior | Open |
| Q5 | Playtest feedback | MEDIUM — feel tuning | Open |
| Q6 | 敌人类型数据库 (#4) | MEDIUM — flying enemy collision | Open |
| Q7 | Prototype validation | LOW — signal timing edge case | Open |
| Q8 | 战车武器系统 (#20) | LOW — fast projectile edge case | Open |