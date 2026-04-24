# 方块类型数据库

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-22
> **Implements Pillar**: Foundation for all pillars — defines material properties
> **Priority**: MVP | **Layer**: Foundation
> **System ID**: #2 (from systems-index.md)

## Overview

方块类型数据库是游戏中所有方块类型定义的单一数据源。每个方块类型定义了该方块在游戏世界中的物理属性、行为规则和资源产出，供TileMap世界系统和下游消费系统（挖掘、碰撞、资源掉落）查询使用。

方块类型数据库不产生任何游戏逻辑行为——它纯粹是静态数据定义。玩家不与"方块类型数据库"交互，而是与具体的方块实例（出现在世界中的方块）交互。每个放置在TileMap中的方块单元格引用一个方块类型ID，从数据库中读取该方块类型的属性。

**数据模型契约（继承自TileMap世界系统）:**

每个方块类型必须定义以下属性，映射到TileMap的`custom_data`字段：
- `hardness` (custom_data_0): 破坏难度，0-255，影响挖掘所需时间和工具需求
- `destructibility` (custom_data_1): 是否可破坏，0=不可破坏（基岩、边界），1=可破坏
- `resource_type_id` (custom_data_2): 破坏后产出的资源类型ID，0=无产出
- `resource_multiplier` (custom_data_3): 资源产出数量倍率，0.0-10.0
- `buildability` (custom_data_4): 是否可被玩家建造，0=自然生成（地形），1=可建造
- `collision_shape` (custom_data_5): 碰撞形状类型，0=无碰撞，1=完整碰撞，2=平台碰撞

**数据库职责:**
- 定义所有方块类型及其属性
- 提供方块类型查询API（按ID、按名称、按类别）
- 存储方块类型的视觉变体映射
- 定义方块类型的层级分配规则（哪些方块可出现在哪些层）
- 提供方块类型分类（地形方块、建造方块、装饰方块）

**下游消费系统:**
- TileMap世界系统 — 查询方块属性以填充单元格custom_data
- 方块挖掘系统 — 查询hardness和destructibility决定挖掘行为
- 方块碰撞系统 — 查询collision_shape决定碰撞检测
- 资源掉落系统 — 查询resource_type_id和resource_multiplier计算掉落

## Player Fantasy

方块类型数据库没有直接的玩家幻想——它是静态数据基础设施，玩家不会"感知"到数据库的存在。玩家体验的是数据库定义的方块类型在实际游戏中的表现：不同材料的挖掘手感、不同方块的外观差异、破坏后获得的资源。

### 玩家间接体验（由数据库定义的材料属性驱动）

- **挖掘手感差异**: 挖掘"松软泥土"（hardness=5）快速流畅，挖掘"坚硬岩石"（hardness=80）费力缓慢，挖掘"秘银矿脉"（hardness=150）需要高级工具。数据库的hardness值定义了这种手感差异。
- **材料辨识**: 玩家通过方块外观识别材料类型——"这是铁矿"（resource_type=铁矿ID）、"这是普通石头"（resource_type=0）。数据库定义了方块与资源的关联，让玩家学会辨识有价值的目标。
- **建造选择**: 玩家建造时选择不同方块类型——"用秘银墙"（hardness=200）vs"用普通木墙"（hardness=30）。数据库的buildability和hardness定义了建造选项及其防御价值。

### 支柱间接贡献

- **Pillar 2: 搜打撤节奏** — hardness值差异创造了"判断挖掘时间"的决策点。玩家在高硬度方块前需要评估"挖掘这个值得花多少时间？是否影响撤退时限？"
- **Pillar 3: 尸潮即高潮** — 建造方块的hardness定义了防御墙的持久力。高硬度墙=更长的防守时间，低硬度墙=更快被突破。
- **Pillar 4: 魔导科技美学** — 方块类型名称和视觉变体映射传递魔导科技材料风格（秘银、魔力晶石、符文金属）。

## Detailed Design

### Core Rules

#### 1. Tile Type Data Structure

每个方块类型定义为一个独立的TileData资源，存储在Godot TileSet中。所有方块类型共享统一的数据结构，确保下游系统可以一致地查询属性。

**Primary Tile Type Fields (存储在TileData资源):**

| Field Name | Type | Range | Default | Description | Custom Data Mapping |
|------------|------|-------|---------|-------------|---------------------|
| `tile_type_id` | int | 0-65535 | — | Unique identifier for this tile type | TileSet atlas tile index |
| `name` | string | — | — | Internal identifier (e.g., "stone", "iron_ore") | TileData resource filename |
| `display_name` | string | — | — | Localized name for UI display | Not stored in TileData, lookup via LocalizationManager |
| `hardness` | int | 0-255 | 50 | Destruction difficulty; affects dig time and tool requirement | custom_data_0 |
| `destructibility` | int | 0-1 | 1 | 0=indestructible (bedrock, boundary), 1=destructible | custom_data_1 |
| `resource_type_id` | int | 0-65535 | 0 | Resource database ID spawned on destruction; 0=no resource | custom_data_2 |
| `resource_multiplier` | float | 0.0-10.0 | 1.0 | Quantity multiplier for resource drops | custom_data_3 |
| `buildability` | int | 0-1 | 0 | 0=natural (terrain-generated only), 1=buildable (player can place) | custom_data_4 |
| `collision_shape` | int | 0-2 | 1 | Collision geometry type | custom_data_5 |

**Collision Shape Type Values:**

| Value | Name | Collision Geometry | Use Case |
|-------|------|-------------------|----------|
| 0 | `NONE` | No collision polygon | Background decoration, overlay markers |
| 1 | `FULL` | Full 32x32 rectangle collision | Walls, solid terrain, structures |
| 2 | `PLATFORM` | Top 8px solid, bottom passable | Walkable platforms, scaffolds |

> **MVP Note**: CUSTOM collision (value 3) removed from MVP scope. Layer validation matrix has no layer accepting custom collision. If needed in Vertical Slice, define `custom_collision_layer_bits` field and update layer validation rules.

**Extended Tile Type Fields (不映射到custom_data，存储在TileData metadata):**

| Field Name | Type | Range | Default | Description |
|------------|------|-------|---------|-------------|
| `layer_allowed` | Array[int] | [0-4] | [1] | Which TileMap layers this tile can appear on |
| `variants` | Array[VariantDef] | 0-255 | [] | Visual variations for texture variety |
| `texture_path` | string | — | — | Godot resource path to tile texture atlas |
| `category` | string | — | "terrain" | Classification for organization |
| `description` | string | — | "" | Internal documentation note |

**Variant Definition Structure:**

```gdscript
# VariantDef structure (stored in variants array)
class VariantDef:
    var variant_index: int      # 0-255, unique within tile type
    var texture_offset: Vector2i # Offset in atlas texture
    var weight: float           # 0.0-1.0, probability weight for random selection
    var condition: String       # Optional condition for conditional variant (e.g., "damaged", "corner")
```

**Field Validation Rules:**

1. `tile_type_id` must be unique across all tile types in the TileSet
2. `hardness` of 0 is valid (instant destruction) — only for special weak materials; requires special handling in dig progress formula (see Formulas section)
3. `destructibility = 0` implies `hardness = 255` internally (override for indestructible)
4. `resource_type_id` must reference valid resource database entry if > 0
5. `buildability = 1` requires `collision_shape > 0` (buildable tiles must have collision)
6. `layer_allowed` cannot be empty — must include at least one valid layer index
7. `variants` array limited to 255 entries maximum per tile type
8. **Contradiction validation**: If `resource_type_id > 0` AND `resource_multiplier = 0.0`, this is invalid configuration — tile would spawn "zero resources". Either set `resource_type_id = 0` (no resource) or set `resource_multiplier >= 0.5`.

---

#### 2. Tile Type ID Allocation Scheme

方块类型ID按类别和层级分配，确保ID范围可预测、可扩展、易于查询。

**ID Range Allocation:**

| ID Range | Category | Layer Assignment | Description |
|----------|----------|------------------|-------------|
| 0-99 | `terrain_indestructible` | Layer 1 only | Indestructible terrain (bedrock, boundaries) |
| 100-199 | `terrain_surface` | Layer 1 only | Surface natural terrain (surface stone, surface dirt) |
| 200-299 | `terrain_cave` | Layer 1 only | Cave natural terrain (cave stone, cave dirt) |
| 300-399 | `terrain_deep` | Layer 1 only | Deep underground terrain (abyss rock, deep stone) |
| 400-499 | `terrain_special` | Layer 1 only | Special terrain (teleporter pads, spawn points) |
| 500-999 | `resource_ores` | Layer 1 only | Resource-bearing ores (iron ore, gold ore, crystal deposits) |
| 1000-1499 | `building_walls` | Layer 2 only | Player-buildable wall structures |
| 1500-1999 | `building_floors` | Layer 2, 3 | Player-buildable floor/platform structures |
| 2000-2499 | `building_facilities` | Layer 2 only | Facility tiles (storage, production, generators) |
| 2500-2999 | `building_defense` | Layer 2 only | Defensive structures (turrets, traps, barricades) |
| 3000-3499 | `decoration` | Layer 0, 4 | Decoration and overlay tiles |
| 3500-3999 | `special_effects` | Layer 4 only | Temporary effect tiles (damage indicators, markers) |
| 4000-65535 | `reserved_expansion` | — | Reserved for future content expansion |

**ID Allocation Rules:**

1. IDs are allocated in contiguous blocks by category
2. Each category has 100-500 ID slots; unused slots reserved for future additions
3. New tile types must use the next available ID in their category range
4. ID must never be reassigned — deprecated IDs marked `status: deprecated` in registry
5. Tile type with `tile_type_id = 0` is reserved as "null tile" (error fallback)

**Category to Layer Mapping:**

| Category | Primary Layer | Allowed Layers | Placement Rules |
|----------|--------------|----------------|-----------------|
| `terrain_*` | 1 | [1] | Terrain tiles only on terrain_base layer; generated only, no player placement |
| `building_*` | 2 | [2, 3] | Building tiles on structures (layer 2) or platforms (layer 3); player-placed |
| `resource_ores` | 1 | [1] | Resource ores only on terrain_base; generated only, discovered by mining |
| `decoration` | 0, 4 | [0, 4] | Background (layer 0) or overlay (layer 4); no collision |
| `special_effects` | 4 | [4] | Temporary overlay tiles; system-managed, transient |

---

#### 3. Tile Type Storage Format

方块类型数据存储在Godot TileSet资源文件中，遵循Godot 4.6的资源格式规范。

**File Structure:**

```
assets/
├── data/
│   └── tilesets/
│       └── block_types_tileset.tres     # Master TileSet resource (contains all TileData)
├── textures/
│   └── tiles/
│       ├── terrain_atlas.png            # Terrain tile texture atlas
│       ├── building_atlas.png           # Building tile texture atlas
│       ├── resource_atlas.png           # Resource ore texture atlas
│       └── decoration_atlas.png         # Decoration texture atlas
```

> **Godot 4.x Note**: TileData cannot be stored as separate `.tres` files. All tile data must be embedded within the TileSet resource. The TileSet stores tiles under `sources/N/atlas/tiles/coords/` paths internally.

**TileSet Resource Structure (Godot 4.6):**

```gdscript
# block_types_tileset.tres structure
[gd_resource type="TileSet" format=3]

[resource]
tile_size = Vector2i(32, 32)  # Matches CELL_SIZE from TileMap system

# Atlas sources (texture sources)
sources/0 = SubResource("AtlasTexture_terrain")
sources/1 = SubResource("AtlasTexture_building")
sources/2 = SubResource("AtlasTexture_resource")
sources/3 = SubResource("AtlasTexture_decoration")

# Custom data layers (Godot 4.x requires name and type per layer)
# type values: 0=nil, 1=bool, 2=int, 3=float, 4=string, 5-7=other
custom_data_layers/0/name = "hardness"
custom_data_layers/0/type = 2       # Variant.Type INT (value 2)
custom_data_layers/1/name = "destructibility"
custom_data_layers/1/type = 2       # INT
custom_data_layers/2/name = "resource_type_id"
custom_data_layers/2/type = 2       # INT
custom_data_layers/3/name = "resource_multiplier"
custom_data_layers/3/type = 3       # Variant.Type FLOAT (value 3)
custom_data_layers/4/name = "buildability"
custom_data_layers/4/type = 2       # INT
custom_data_layers/5/name = "collision_shape"
custom_data_layers/5/type = 2       # INT

# Physics layers (Godot 4.x requires collision_layer and collision_mask per layer)
# collision_layer uses bit values (1 << bit_index)
physics_layers/0/collision_layer = 1   # Bit 0: COLLISION_TERRAIN
physics_layers/0/collision_mask = 0    # Tiles don't detect collisions
physics_layers/1/collision_layer = 2   # Bit 1: COLLISION_STRUCTURE
physics_layers/1/collision_mask = 0
physics_layers/2/collision_layer = 4   # Bit 2: COLLISION_PLATFORM (1 << 2 = 4)
physics_layers/2/collision_mask = 0
```

**TileData Per-Tile Structure:**

每个atlas tile在TileSet中定义以下属性：

```gdscript
# Example: Stone terrain tile (ID 100)
tiles/100:
    atlas_source_id = 0  # terrain_atlas
    atlas_coords = Vector2i(0, 0)  # Position in atlas
    alternative_id = 0  # Default variant
    
    # Custom data values
    custom_data_0 = 80   # hardness
    custom_data_1 = 1    # destructibility
    custom_data_2 = 0    # resource_type_id (none)
    custom_data_3 = 1.0  # resource_multiplier
    custom_data_4 = 0    # buildability (natural)
    custom_data_5 = 1    # collision_shape (full)
    
    # Collision polygon (for collision_shape = 1)
    physics_layer_0_polygon = [Vector2(0,0), Vector2(32,0), Vector2(32,32), Vector2(0,32)]
    
    # Visual variants
    alternatives/0 = {}  # Default variant
    alternatives/1 = {}  # Cracked variant (for DAMAGED state)
    alternatives/2 = {}  # Heavy damage variant (for CRITICAL state)
```

**Variant Handling:**

1. Default variant (`alternative_id = 0`) is the base texture
2. Damage variants (`alternative_id = 1, 2`) are automatically selected by TileMap system based on damage state
3. Random variants (`alternative_id = 3-255`) are selected at tile placement for visual variety
4. Variant selection uses weighted random based on `weight` field in variant definition

**Resource File Naming Convention:**

- TileSet master file: `block_types_tileset.tres`
- Texture atlas: `[category]_atlas.png`
- All filenames use snake_case
- TileData is embedded in TileSet; no separate files

---

#### 4. Tile Type Query API

方块类型数据库通过`BlockTypeDatabase`单例提供查询接口，供所有下游系统使用。

**Singleton Registration:**

```gdscript
# BlockTypeDatabase.gd (autoload singleton)
class_name BlockTypeDatabase
extends Node

# Autoload name: "BlockTypes"
# Note: Autoloads must extend Node for proper lifecycle (_ready, _process, scene tree access)
```

**Primary Query Methods:**

```gdscript
# === Basic Lookup ===

# Returns TileData resource for given tile_type_id, or null if invalid
func get_tile_data(tile_type_id: int) -> TileData

# Returns tile type name (internal identifier) for given ID
func get_tile_name(tile_type_id: int) -> String

# Returns display name (localized) for given ID
func get_display_name(tile_type_id: int) -> String

# Returns full tile type definition dictionary for given ID
func get_tile_definition(tile_type_id: int) -> Dictionary

# === Property Query ===

# Returns hardness value for tile type (0-255, returns 255 for indestructible)
func get_hardness(tile_type_id: int) -> int

# Returns destructibility flag (0 or 1)
func get_destructibility(tile_type_id: int) -> int

# Returns resource type ID spawned on destruction (0 = none)
func get_resource_type_id(tile_type_id: int) -> int

# Returns resource quantity multiplier (0.0-10.0)
func get_resource_multiplier(tile_type_id: int) -> float

# Returns buildability flag (0 = natural, 1 = buildable)
func get_buildability(tile_type_id: int) -> int

# Returns collision shape type (0-3)
func get_collision_shape(tile_type_id: int) -> int

# Returns array of allowed layers for tile type
func get_allowed_layers(tile_type_id: int) -> Array[int]

# === Category Query ===

# Returns all tile types in specified category
func get_tiles_by_category(category: String) -> Array[int]

# Returns category name for given tile type ID
func get_category_for_tile(tile_type_id: int) -> String

# Returns all tile types with specified buildability value
func get_buildable_tiles() -> Array[int]

# Returns all tile types with specified destructibility value
func get_destructible_tiles() -> Array[int]

# === Validation ===

# Returns true if tile_type_id is valid (exists in database)
func is_valid_tile_type(tile_type_id: int) -> bool

# Returns true if tile can be placed on specified layer
func can_place_on_layer(tile_type_id: int, layer: int) -> bool

# Returns true if tile type has collision (collision_shape > 0)
func has_collision(tile_type_id: int) -> bool

# Returns true if tile type is buildable by player
func is_buildable(tile_type_id: int) -> bool

# Returns true if tile type spawns resources on destruction
func spawns_resources(tile_type_id: int) -> bool

# === Variant Query ===

# Returns variant count for tile type
func get_variant_count(tile_type_id: int) -> int

# Returns weighted random variant index for tile type
func get_random_variant(tile_type_id: int) -> int

# Returns damage variant index for tile state (INTACT/DAMAGED/CRITICAL)
func get_damage_variant(tile_type_id: int, state: String) -> int
```

**Query Return Format:**

```gdscript
# get_tile_definition returns this dictionary structure:
{
    "tile_type_id": int,
    "name": String,
    "display_name": String,
    "category": String,
    "hardness": int,
    "destructibility": int,
    "resource_type_id": int,
    "resource_multiplier": float,
    "buildability": int,
    "collision_shape": int,
    "layer_allowed": Array[int],
    "variants": Array[VariantDef],
    "texture_path": String,
    "description": String
}
```

**Query Behavior Rules:**

1. All query methods return immediately — no async loading, database is pre-loaded
2. Invalid tile_type_id returns null or default value (0 for int, "" for string, false for bool)
3. Query methods are thread-safe for read operations — no mutex needed
4. Database is loaded once at game start, immutable during gameplay
5. Localization lookup (`get_display_name`) delegates to LocalizationManager

---

#### 5. Initial Tile Type Catalog (MVP)

以下是MVP阶段必需的方块类型定义。每个方块类型包含完整属性定义。

**Terrain Blocks (Layer 1, Generated Only):**

| ID | Name | Display Name | Hardness | Destructibility | Resource ID | Multiplier | Buildability | Collision | Layer |
|----|------|--------------|----------|-----------------|-------------|------------|--------------|-----------|-------|
| 0 | `null_tile` | "无效方块" | 255 | 0 | 0 | 0.0 | 0 | 0 | [1] |
| 1 | `bedrock_surface` | "地表基岩" | 255 | 0 | 0 | 0.0 | 0 | 1 | [1] |
| 10 | `bedrock_cave` | "洞穴基岩" | 255 | 0 | 0 | 0.0 | 0 | 1 | [1] |
| 20 | `bedrock_deep` | "深层基岩" | 255 | 0 | 0 | 0.0 | 0 | 1 | [1] |
| 100 | `surface_stone` | "地表岩石" | 60 | 1 | 0 | 1.0 | 0 | 1 | [1] |
| 110 | `surface_dirt` | "地表泥土" | 15 | 1 | 0 | 1.0 | 0 | 1 | [1] |
| 120 | `surface_sand` | "地表沙土" | 5 | 1 | 0 | 0.5 | 0 | 1 | [1] |
| 200 | `cave_stone` | "洞穴岩石" | 100 | 1 | 0 | 1.2 | 0 | 1 | [1] |
| 210 | `cave_dirt` | "洞穴泥土" | 25 | 1 | 0 | 1.0 | 0 | 1 | [1] |
| 220 | `cave_gravel` | "洞穴碎石" | 8 | 1 | 0 | 0.5 | 0 | 1 | [1] |
| 300 | `deep_stone` | "深层岩石" | 150 | 1 | 0 | 1.5 | 0 | 1 | [1] |
| 310 | `abyss_rock` | "深渊岩石" | 210 | 1 | 0 | 2.0 | 0 | 1 | [1] |

**Resource Ore Blocks (Layer 1, Generated Only):**

| ID | Name | Display Name | Hardness | Destructibility | Resource ID | Multiplier | Buildability | Collision | Layer |
|----|------|--------------|----------|-----------------|-------------|------------|--------------|-----------|-------|
| 500 | `iron_ore` | "铁矿脉" | 120 | 1 | 101 | 1.0 | 0 | 1 | [1] |
| 510 | `copper_ore` | "铜矿脉" | 100 | 1 | 102 | 1.0 | 0 | 1 | [1] |
| 520 | `coal_deposit` | "煤矿层" | 60 | 1 | 103 | 1.5 | 0 | 1 | [1] |
| 600 | `crystal_shard` | "魔力晶石碎片" | 80 | 1 | 201 | 1.0 | 0 | 1 | [1] |
| 610 | `crystal_cluster` | "魔力晶石簇" | 140 | 1 | 202 | 2.0 | 0 | 1 | [1] |
| 700 | `mithril_ore` | "秘银矿脉" | 180 | 1 | 301 | 1.0 | 0 | 1 | [1] |
| 710 | `ancient_mithril` | "古代秘银" | 220 | 1 | 302 | 3.0 | 0 | 1 | [1] |
| 800 | `gold_ore` | "金矿脉" | 150 | 1 | 203 | 1.0 | 0 | 1 | [1] |

**Building Blocks (Layer 2-3, Player-Buildable):**

| ID | Name | Display Name | Hardness | Destructibility | Resource ID | Multiplier | Buildability | Collision | Layer |
|----|------|--------------|----------|-----------------|-------------|------------|--------------|-----------|-------|
| 1000 | `wall_basic` | "基础墙体" | 40 | 1 | 0 | 0.0 | 1 | 1 | [2] |
| 1010 | `wall_stone` | "石墙" | 70 | 1 | 0 | 0.0 | 1 | 1 | [2] |
| 1020 | `wall_reinforced` | "加固墙" | 100 | 1 | 0 | 0.0 | 1 | 1 | [2] |
| 1030 | `wall_rune` | "符文墙" | 140 | 1 | 0 | 0.0 | 1 | 1 | [2] |
| 1040 | `wall_mithril` | "秘银墙" | 200 | 1 | 0 | 0.0 | 1 | 1 | [2] |
| 1500 | `floor_basic` | "基础地板" | 25 | 1 | 0 | 0.0 | 1 | 1 | [2, 3] |
| 1510 | `platform_wooden` | "木质平台" | 15 | 1 | 0 | 0.0 | 1 | 2 | [3] |
| 1520 | `platform_metal` | "金属平台" | 35 | 1 | 0 | 0.0 | 1 | 2 | [3] |
| 2000 | `facility_storage_basic` | "基础储物箱" | 50 | 1 | 0 | 0.0 | 1 | 1 | [2] |
| 2001 | `facility_workbench` | "工作台" | 40 | 1 | 0 | 0.0 | 1 | 1 | [2] |
| 2500 | `turret_base` | "炮塔基座" | 85 | 1 | 0 | 0.0 | 1 | 1 | [2] |
| 2501 | `turret_base_rune` | "符文炮塔基座" | 120 | 1 | 0 | 0.0 | 1 | 1 | [2] |
| 2502 | `trap_spikes_tile` | "尖刺陷阱tile" | 30 | 1 | 0 | 0.0 | 1 | 0 | [2] |

**Decoration Blocks (Layer 0-4, No Collision):**

| ID | Name | Display Name | Hardness | Destructibility | Resource ID | Multiplier | Buildability | Collision | Layer |
|----|------|--------------|----------|-----------------|-------------|------------|--------------|-----------|-------|
| 3000 | `bg_ruins_distant` | "远处废墟背景" | 0 | 0 | 0 | 0.0 | 0 | 0 | [0] |
| 3010 | `bg_cave_dark` | "洞穴暗影背景" | 0 | 0 | 0 | 0.0 | 0 | 0 | [0] |
| 3500 | `marker_spawn` | "生成点标记" | 0 | 0 | 0 | 0.0 | 0 | 0 | [4] |
| 3510 | `indicator_damage_light` | "轻度损伤指示" | 0 | 0 | 0 | 0.0 | 0 | 0 | [4] |
| 3520 | `indicator_damage_heavy` | "重度损伤指示" | 0 | 0 | 0 | 0.0 | 0 | 0 | [4] |

**Hardness Design Rationale (Game Pillar Support):**

| Hardness Range | Mining Time | Tool Requirement | Pillar Support |
|----------------|-------------|------------------|----------------|
| 0-20 | Instant-2 sec | No tool required | Surface exploration freedom |
| 21-60 | 2-5 sec | Basic tool | Early game mining rhythm |
| 61-100 | 5-10 sec | Standard tool | 搜打撤 timing pressure |
| 101-150 | 10-15 sec | Advanced tool | Resource scarcity, risk assessment |
| 151-200 | 15-20 sec | Specialized tool | 尸潮防守 preparation investment |
| 201-255 | 20+ sec or indestructible | Maximum tier or impossible | Strategic boundaries |

---

#### 6. Layer Assignment Rules

方块类型与TileMap层级的分配关系决定方块在世界中的位置和功能。

**Layer Assignment Validation Matrix:**

| Layer Index | Layer Name | Allowed Tile Categories | Collision Provided | Player Can Place | Player Can Remove |
|-------------|------------|------------------------|-------------------|------------------|-------------------|
| 0 | `background` | `decoration` only | None | No | No |
| 1 | `terrain_base` | `terrain_*`, `resource_ores` | Full (collision_shape=1) | No | Digging system only |
| 2 | `structures` | `building_walls`, `building_facilities`, `building_defense` | Full (collision_shape=1) | Yes (if buildability=1) | Yes |
| 3 | `platforms` | `building_floors` (platform type only) | Platform (collision_shape=2) | Yes (if buildability=1) | Yes |
| 4 | `overlay` | `decoration`, `special_effects` | None | No | System-managed only |

**Layer Assignment Rules:**

1. **Category-to-Layer Mapping**: Each tile category has predefined allowed layers (see ID Allocation Scheme)
2. **Single Primary Layer**: Most tile types have one primary layer; `building_floors` can appear on layers 2 or 3
3. **Layer Validation**: When placing tile, system checks `layer_allowed` array; placement rejected if layer not in array
4. **Terrain Immutability**: Layer 1 tiles cannot be placed by player; only generated or removed by digging
5. **Structure Placement**: Layer 2 tiles require foundation validation (adjacent solid tile)
6. **Platform Placement**: Layer 3 tiles require support validation (solid below or adjacent platform)
7. **Overlay Transient**: Layer 4 tiles are system-managed; no player interaction

**Layer Collision Priority:**

When multiple layers have tiles at same cell, collision is resolved by layer priority:

```gdscript
# Collision resolution order (highest priority first)
COLLISION_PRIORITY = [2, 1, 3]  # structures > terrain_base > platforms

# Query collision: check layers in priority order, return first occupied tile
func get_primary_collision_tile(cell: Vector2i) -> Dictionary:
    for layer in COLLISION_PRIORITY:
        if TileMapWorld.is_cell_occupied(cell, layer):
            return TileMapWorld.get_collision_tile(cell, layer)
    return {}  # No collision at cell
```

**Special Layer Rules:**

1. **Background Layer (0)**: 
   - Only decoration tiles with `collision_shape = 0`
   - Rendered at 50% opacity per TileMap system spec
   - Never modified by player; generated with world

2. **Terrain Layer (1)**:
   - All `terrain_*` and `resource_ores` tiles
   - `destructibility` determines if player can remove (dig system)
   - `buildability = 0` for all terrain tiles (never player-placed)

3. **Structures Layer (2)**:
   - Player-built walls, facilities, defense structures
   - `buildability = 1` required for player placement
   - Foundation required: adjacent solid tile (layer 1 or 2)
   - Can be damaged by enemies during 尸潮

4. **Platforms Layer (3)**:
   - Walkable platforms with top-only collision
   - `collision_shape = 2` required
   - Support required: solid below (layer 1 or 2) or adjacent platform

5. **Overlay Layer (4)**:
   - Temporary markers, damage indicators, spawn points
   - `collision_shape = 0` required
   - System-managed; transient (not saved to disk)
   - Updated by game systems, not player action

**Layer Assignment Validation Algorithm:**

```gdscript
func validate_layer_assignment(tile_type_id: int, target_layer: int) -> bool:
    # Rule 1: Check tile type exists
    if not BlockTypes.is_valid_tile_type(tile_type_id):
        return false
    
    # Rule 2: Check layer is in tile's allowed layers
    var allowed_layers = BlockTypes.get_allowed_layers(tile_type_id)
    if target_layer not in allowed_layers:
        return false
    
    # Rule 3: Check collision shape matches layer requirements
    var collision_shape = BlockTypes.get_collision_shape(tile_type_id)
    
    # Background and overlay require no collision
    if target_layer in [0, 4] and collision_shape != 0:
        return false
    
    # Structures require full collision
    if target_layer == 2 and collision_shape != 1:
        return false
    
    # Platforms require platform collision
    if target_layer == 3 and collision_shape != 2:
        return false
    
    # Terrain allows full or platform collision
    if target_layer == 1 and collision_shape not in [1, 2]:
        return false
    
    return true
```

**Example Layer Assignments:**

| Tile Type | Primary Layer | Collision Provided | Player Action |
|-----------|---------------|-------------------|---------------|
| `surface_stone` (ID 100) | Layer 1 | Full collision | Cannot place, can dig if tool sufficient |
| `iron_ore` (ID 500) | Layer 1 | Full collision | Cannot place, dig yields iron resource |
| `wall_basic` (ID 1000) | Layer 2 | Full collision | Can place (requires materials), can remove |
| `platform_wooden` (ID 1510) | Layer 3 | Platform collision | Can place (requires support), can remove |
| `bg_ruins_distant` (ID 3000) | Layer 0 | No collision | Generated only, no player interaction |
| `marker_spawn` (ID 3500) | Layer 4 | No collision | System-managed, transient |

### States and Transitions

方块类型数据库是静态数据定义系统，不管理运行时状态。每个方块类型定义在数据创建后即固定不变。运行时的方块实例状态由TileMap世界系统管理。

#### Tile Type Definition States

每个方块类型定义有以下生命周期状态：

| State | Condition | Description |
|-------|-----------|-------------|
| `ACTIVE` | Tile type defined and available in TileSet | Tile type can be placed in world and queried |
| `DEPRECATED` | Tile type marked deprecated in registry | Tile type no longer used in new content, existing instances remain functional |
| `PLANNED` | Tile type defined in GDD but not yet implemented | Tile type ID reserved, no TileData resource created |

**State transition rules:**

1. `PLANNED → ACTIVE`: When TileData resource is created and added to TileSet
2. `ACTIVE → DEPRECATED`: When tile type is removed from content pipeline (existing world instances unaffected)
3. No other transitions valid — tile type definitions do not change at runtime

#### Runtime Tile Instance States (Owned by TileMap世界系统)

方块类型数据库不管理运行时状态。运行时方块实例的状态（INTACT/DAMAGED/CRITICAL/DESTROYED）由TileMap世界系统管理，详见`design/gdd/tilemap-world-system.md`。

### Interactions with Other Systems

#### Upstream Systems (无)

方块类型数据库是Foundation层系统，无上游依赖。数据定义独立于其他系统。

#### Downstream Consumer Systems

| Consumer System | Primary Data Consumed | Query Methods Used | Timing |
|-----------------|----------------------|-------------------|--------|
| **TileMap世界系统** | hardness, destructibility, collision_shape, all custom_data | `get_tile_type()`, `get_hardness()`, `get_custom_data()` | On tile placement, on chunk generation, on tile lookup |
| **方块挖掘系统** | hardness, destructibility | `get_hardness()`, `is_destructible()` | Before each damage application, for tool requirement check |
| **方块碰撞系统** | collision_shape | `get_collision_shape()` | Every collision query frame |
| **资源掉落系统** | resource_type_id, resource_multiplier | `get_resource_type()`, `get_resource_multiplier()` | On tile destruction event |
| **方块放置系统** | buildability, layer_allowed | `is_buildable()`, `get_allowed_layers()` | On placement validation check |
| **地堡设施系统** | buildability, hardness for facility tiles | `get_tile_type_by_name()`, `get_hardness()` | On facility construction |

#### Detailed Interaction Specifications

##### TileMap世界系统

**Data provided:**
- Full tile type definition on chunk generation (terrain tile assignment)
- Custom data values for each cell (hardness, destructibility, etc.)

**Query methods called:**
- `BlockTypes.get_tile_type(tile_type_id)` — retrieve full tile definition
- `BlockTypes.get_hardness(tile_type_id)` — retrieve hardness for damage state
- `BlockTypes.get_custom_data(tile_type_id, data_index)` — retrieve specific custom_data field

**Interaction contract:**
- TileMap queries BlockTypes once per tile type (cached), not per-cell
- BlockTypes returns immutable data — TileMap stores the values, BlockTypes does not track instances

##### 方块挖掘系统

**Data provided:**
- Hardness value for damage accumulation calculation
- Destructibility flag for indestructible tile rejection

**Query methods called:**
- `BlockTypes.get_hardness(tile_type_id)` — determine damage required for destruction
- `BlockTypes.is_destructible(tile_type_id)` — check if tile can be damaged

**Interaction contract:**
- Digging system checks destructibility before applying damage
- If `destructibility = 0`, digging system rejects action immediately (no damage applied)
- Hardness 255 for indestructible tiles is returned even if `hardness` field differs (override rule)

##### 方块碰撞系统

**Data provided:**
- Collision shape type for physics layer assignment

**Query methods called:**
- `BlockTypes.get_collision_shape(tile_type_id)` — determine collision polygon type

**Interaction contract:**
- Collision system uses collision_shape value to determine physics behavior
- Value 0 (NONE): No collision polygon, entity passes through
- Value 1 (FULL): Full 32x32 collision, blocks all movement
- Value 2 (PLATFORM): Top 8px collision only, allows jump-through from below

##### 资源掉落系统

**Data provided:**
- Resource type ID for resource spawn selection
- Resource multiplier for quantity calculation

**Query methods called:**
- `BlockTypes.get_resource_type(tile_type_id)` — determine which resource to spawn
- `BlockTypes.get_resource_multiplier(tile_type_id)` — determine quantity multiplier

**Interaction contract:**
- If `resource_type_id = 0`, no resources spawn (empty drop)
- Resource system must query resource database (separate system) for actual resource data
- BlockTypes provides tile→resource mapping, not resource definitions

##### 方块放置系统

**Data provided:**
- Buildability flag for placement permission
- Allowed layers for placement target validation

**Query methods called:**
- `BlockTypes.is_buildable(tile_type_id)` — check if player can place this tile
- `BlockTypes.get_allowed_layers(tile_type_id)` — check which layers accept this tile
- `BlockTypes.validate_layer_assignment(tile_type_id, target_layer)` — full validation

**Interaction contract:**
- Placement system validates buildability before showing tile in build menu
- Placement system validates layer assignment before placing tile
- Invalid placements rejected with failure reason

## Formulas

方块类型数据库不执行数值计算。所有数值由数据定义直接提供。以下为数据库的恒定规则（非公式）：

### Constant Rules (恒定规则)

| Rule | Definition | Applies To |
|------|------------|------------|
| `HARDNESS_OVERRIDE_INDESTRUCTIBLE` | If `destructibility = 0`, return hardness = 255 regardless of stored value | Indestructible tiles (bedrock, boundaries) |
| `HARDNESS_ZERO_INSTANT_DESTRUCTION` | If `hardness = 0`, bypass dig progress bar calculation — immediate destruction, no damage accumulation | Weak materials (sand, gravel); special handling required in Digging System |
| `COLLISION_LAYER_MAPPING` | collision_shape = 1 → physics bit 1+2; collision_shape = 2 → physics bit 3 | All tiles with collision |
| `LAYER_VALIDATION_MATRIX` | Layer 0/4 require collision_shape = 0; Layer 2 requires collision_shape = 1; Layer 3 requires collision_shape = 2 | All layer assignment checks |

### Query Behavior Rules

**Tile type lookup by ID:**

```
get_tile_type(tile_type_id):
    if tile_type_id == 0:
        return NULL_TILE_DEFINITION
    if tile_type_id not in registered_tile_types:
        return null (error: "tile_type_id not found")
    return TileData resource at tile_type_id index
```

**Hardness query with override:**

```
get_hardness(tile_type_id):
    tile_data = get_tile_type(tile_type_id)
    if tile_data.destructibility == 0:
        return 255 (override: indestructible)
    return tile_data.hardness
```

**Collision shape to physics layer bit mapping:**

```
get_physics_layer_bits(tile_type_id):
    collision_shape = get_collision_shape(tile_type_id)
    if collision_shape == 0:
        return 0 (no physics layer)
    if collision_shape == 1:
        return COLLISION_TERRAIN | COLLISION_STRUCTURE (bits 1+2)
    if collision_shape == 2:
        return COLLISION_PLATFORM (bit 3)
    # collision_shape values 0-2 only for MVP; no custom collision
```

## Edge Cases

### 1. Invalid Tile Type ID Query

**Case**: System queries tile type with ID that does not exist in the database.

| Scenario | Input | Expected Behavior | Recovery |
|----------|-------|-------------------|----------|
| `tile_type_id = 0` | `get_tile_type(0)` | Return `NULL_TILE_DEFINITION` (tile_type_id=0 is reserved error fallback) | No error thrown; downstream system handles null response |
| `tile_type_id < 0` | `get_tile_type(-1)` | Return `null`, log warning: "Invalid tile_type_id: -1 (negative)" | Downstream system checks for null and fails gracefully |
| `tile_type_id > 65535` | `get_tile_type(70000)` | Return `null`, log warning: "Invalid tile_type_id: 70000 (exceeds 16-bit range)" | Downstream system checks for null |
| `tile_type_id` not registered | `get_tile_type(450)` (ID range 400-499 is empty) | Return `null`, log warning: "tile_type_id 450 not found in registry" | Downstream system handles missing tile |

**Implementation Rule**: All query methods must handle invalid IDs by returning `null` or the appropriate default (0 for int, "" for string, false for bool) without throwing exceptions. The database never crashes on invalid input.

---

### 2. Missing Tile Type Definition (PLANNED State)

**Case**: Tile type ID is reserved in the allocation scheme but TileData resource not yet created (PLANNED state).

| Scenario | Trigger | Expected Behavior | Resolution |
|----------|---------|-------------------|------------|
| Query PLANNED tile | `get_tile_type(400)` (terrain_special slot, not implemented) | Return `null`, log warning: "tile_type_id 400 is in PLANNED state (not yet implemented)" | Developer must create TileData resource and mark ACTIVE in registry |
| World generation references PLANNED tile | Map generator assigns ID 400 | Chunk generation fails gracefully: use fallback tile (ID 100 surface_stone) with logged error | Map generation config must only reference ACTIVE tiles |

**Design Test**: Before world generation, run `BlockTypes.validate_all_active(tile_ids_in_use)` to catch PLANNED tile references.

---

### 3. Deprecated Tile Types in Existing Saves

**Case**: Player loads a save file containing tile instances of deprecated tile types.

| Scenario | Input | Expected Behavior | Player Experience |
|----------|-------|-------------------|-------------------|
| Deprecated tile in world | Save contains tile_type_id=1050 (deprecated wall type) | BlockTypes returns DEPRECATED definition (still exists in TileSet) | Tile renders normally, functions normally — no player-visible difference |
| Deprecated tile in player inventory | Player has "Old Wall" item referencing ID 1050 | Inventory system allows placement, but item is marked as deprecated in UI (optional: show warning) | Player can still use deprecated items; no forced removal |
| Deprecated tile queried by digging system | Player digs deprecated tile | Digging proceeds normally using stored hardness value | Deprecated tiles remain fully functional in existing instances |

**Deprecation Rule**: DEPRECATED tile types remain in TileSet and respond to queries. They are removed from build menu and new content generation, but existing instances are never broken. Deprecation is a content pipeline state, not a runtime behavior change.

---

### 4. Resource ID Reference to Non-Existent Resource

**Case**: Tile type defines `resource_type_id` that does not exist in the Resource Database.

| Scenario | Input | Expected Behavior | Recovery |
|----------|-------|-------------------|----------|
| Resource ID not in Resource Database | Tile defines `resource_type_id=999` (no matching resource entry) | On tile destruction, Resource Drop System logs error: "Resource ID 999 not found" → spawns nothing | No crash; player gets no resource drop (empty result) |
| Resource Database not yet loaded | Query before Resource Database initialization | BlockTypes returns stored `resource_type_id` value; Resource Drop System must handle lookup failure | Resource Drop System validates resource existence before spawning |

**Cross-System Contract**: BlockTypes provides tile→resource ID mapping. Resource Database owns resource definitions. BlockTypes does not validate resource existence at tile definition time — that validation belongs to Resource Drop System at destruction time.

---

### 5. Invalid Layer Assignment Attempt

**Case**: System attempts to place tile on a layer not in the tile's `layer_allowed` array.

| Scenario | Input | Expected Behavior | Recovery |
|----------|-------|-------------------|----------|
| Terrain tile on Layer 2 | Attempt to place ID 100 (surface_stone) on Layer 2 | `can_place_on_layer(100, 2)` returns `false`; placement rejected | Placement system shows error: "Tile cannot be placed on this layer" |
| Platform tile on Layer 1 | Attempt to place ID 1510 (platform_wooden) on Layer 1 | `can_place_on_layer(1510, 1)` returns `false` (platforms allowed on Layer 3 only) | Placement rejected with layer mismatch error |
| Building tile on Layer 4 | Attempt to place ID 1000 (wall_basic) on Layer 4 | `can_place_on_layer(1000, 4)` returns `false` (overlay is for effects only) | Placement rejected |
| Valid multi-layer tile | ID 1500 (floor_basic) on Layer 2 OR Layer 3 | Both valid — `layer_allowed = [2, 3]` | Placement succeeds on either layer |

**Layer Assignment Test**: Placement system must call `BlockTypes.can_place_on_layer(tile_type_id, target_layer)` before every placement attempt.

---

### 6. Collision Shape Mismatch for Layer Requirements

**Case**: Tile type's `collision_shape` does not match the collision requirements of the target layer.

| Scenario | Input | Expected Behavior | System Response |
|----------|-------|-------------------|-----------------|
| `collision_shape=1` on Layer 4 | Attempt to place full collision tile on overlay layer | `validate_layer_assignment()` returns `false` — Layer 4 requires `collision_shape=0` | Rejected at validation; cannot place |
| `collision_shape=0` on Layer 2 | Attempt to place no-collision tile on structures layer | `validate_layer_assignment()` returns `false` — Layer 2 requires `collision_shape=1` | Rejected — structures must have collision |
| `collision_shape=2` on Layer 2 | Platform collision tile on structures layer | `validate_layer_assignment()` returns `false` — Layer 2 requires full collision, not platform | Rejected — wrong collision type |

**Collision-Layer Matrix**: Enforced by `validate_layer_assignment()` algorithm (see Core Rules Section 6). This validation happens at placement time, not at tile definition time.

---

### 7. Buildability Validation Edge Cases

**Case**: Queries related to player build permission for tile types.

| Scenario | Input | Expected Behavior | System Response |
|----------|-------|-------------------|-----------------|
| Natural tile in build menu | Player attempts to build ID 100 (surface_stone) | `is_buildable(100)` returns `false` — `buildability=0` | Tile not shown in build menu; placement rejected if attempted |
| Buildable tile without materials | Player has no resources for ID 1030 (wall_mithril) | BlockTypes returns `true` for `is_buildable()`, but Placement System checks resource inventory separately | BlockTypes says "buildable", Placement System says "insufficient materials" — two separate validations |
| Indestructible tile is buildable | Tile type defines `destructibility=0` AND `buildability=1` | Valid configuration (e.g., permanent structure) — player can place but cannot remove | Placement allowed; digging system rejects removal |

---

### 8. Variant Selection Edge Cases

**Case**: Visual variant selection for tile textures.

| Scenario | Input | Expected Behavior | Result |
|----------|-------|-------------------|--------|
| Tile has no variants | `get_variant_count(100)` returns `0` | `get_random_variant(100)` returns `0` (default variant) | Always uses base texture |
| Empty variants array | `variants = []` in definition | Treat as variant count 0; use `alternative_id = 0` | No error; default variant used |
| All variants have weight 0 | `variants = [{weight: 0.0}, {weight: 0.0}]` | Weighted random fails; fallback to first variant (index 0) | Log warning; use first variant |
| Single variant dominates | `variants = [{weight: 0.9}, {weight: 0.1}]` | 90% chance variant 0, 10% chance variant 1 | Normal weighted selection |
| Damage variant missing | `get_damage_variant(tile_id, "CRITICAL")` but tile has no CRITICAL variant | Return `0` (default variant) — damage state uses base texture | No visual damage feedback for this tile type |

**Variant Weight Calculation**: Use Godot's `randf_weighted()` or equivalent. If total weight = 0, default to variant index 0 without error.

---

### 9. Tile Type Definition Conflict (Duplicate IDs)

**Case**: Two tile types attempt to use the same `tile_type_id`.

| Scenario | Trigger | Expected Behavior | Resolution |
|----------|---------|-------------------|------------|
| Duplicate ID in TileSet | Developer adds two tiles with ID 100 | Godot TileSet resource cannot have duplicate atlas indices — one overwrites the other | Caught at TileSet resource creation; developer must fix ID allocation |
| ID conflict in expansion content | Mod adds tile claiming ID 500 (conflicts with base game iron_ore) | ID allocation scheme prevents this: expansion must use reserved range 4000+ | Expansion content rejected if ID outside reserved range |

**ID Allocation Guard**: All tile type additions must go through `BlockTypes.allocate_tile_type_id(category)` which returns the next available ID in the category range. Manual ID assignment is forbidden.

---

### 10. Tile Data Import/Load Failures

**Case**: TileSet resource fails to load or TileData resources are corrupted.

| Scenario | Trigger | Expected Behavior | Recovery |
|----------|---------|-------------------|----------|
| TileSet resource missing | `block_types_tileset.tres` not found | BlockTypes singleton fails to load; game crashes on startup | Critical error — TileSet must exist for game to run |
| TileData corrupted | Tile definition has malformed data (e.g., hardness="abc" instead of int) | Godot resource loader returns `null` for corrupted TileData; BlockTypes logs error for that tile ID | Tile ID becomes invalid; queries return null |
| TileSet version mismatch | TileSet created in Godot 4.5, loaded in Godot 4.6 | Godot's resource converter handles migration automatically | No action needed unless breaking change documented |

**Load Verification**: BlockTypes singleton runs `validate_all_tile_types()` on initialization, logging warnings for any tile IDs that failed to load.

---

### 11. Cross-System Query During System Initialization

**Case**: Downstream system queries BlockTypes before BlockTypes singleton is initialized.

| Scenario | Trigger | Expected Behavior | Resolution |
|----------|---------|-------------------|------------|
| Early query before autoload | System queries `BlockTypes.get_hardness(100)` during `_init()` | BlockTypes autoload not ready → returns `null` | Downstream systems must query in `_ready()` or after BlockTypes signal `block_types_loaded` |
| Chunk generation before BlockTypes ready | World generator runs before BlockTypes initialized | Chunk generation deferred until BlockTypes signals ready | World system subscribes to `block_types_loaded` signal |

**Initialization Order**: BlockTypes autoload must be first in autoload list. Downstream systems must not query in `_init()`.

---

### 12. Tile Type Removal (Active → Deleted)

**Case**: Developer removes a tile type completely (not deprecated, actually deleted).

| Scenario | Trigger | Expected Behavior | Risk |
|----------|---------|-------------------|------|
| Delete tile from TileSet | Remove tile ID 1010 from TileSet resource | Queries for ID 1010 return `null`; existing world instances show missing texture (Godot fallback) | Breaks existing saves — forbidden for released content |
| Delete after content patch | Post-launch patch removes tile ID 1010 | All existing instances become invalid; player sees broken tiles | **Never allowed** — use DEPRECATED state instead, never delete |

**Tile Removal Policy**: Tile types can only transition ACTIVE → DEPRECATED. Complete deletion from TileSet is forbidden after any content has been released using that tile type.

## Dependencies

方块类型数据库是Foundation层系统，无上游依赖。以下列出下游依赖系统及其数据需求。

### Upstream Dependencies (无)

方块类型数据库是静态数据定义系统，不依赖任何其他游戏系统。数据定义独立于运行时状态、引擎配置、或外部资源数据库。

**External Dependencies (非游戏系统):**
- **Godot TileSet资源系统** — 数据存储载体（引擎内置，非游戏逻辑）
- **Resource文件系统** — TileData资源持久化（引擎内置）

这些是引擎基础设施，不属于游戏系统依赖图。

---

### Downstream Dependencies

以下系统依赖方块类型数据库的数据定义：

| System | Priority | Layer | Data Consumed | Query Methods | Dependency Type |
|--------|----------|-------|---------------|---------------|-----------------|
| **TileMap世界系统** | MVP | Core | hardness, destructibility, collision_shape, all custom_data | `get_tile_data()`, `get_hardness()`, `get_collision_shape()` | **Blocking** — TileMap cannot function without tile type definitions |
| **方块挖掘系统** | MVP | Core | hardness, destructibility | `get_hardness()`, `is_destructible()` | **Blocking** — Digging requires hardness to calculate damage |
| **方块碰撞系统** | MVP | Core | collision_shape | `get_collision_shape()` | **Blocking** — Collision needs shape type for physics |
| **资源掉落系统** | MVP | Core | resource_type_id, resource_multiplier | `get_resource_type_id()`, `get_resource_multiplier()` | **Blocking** — Resource drop requires tile→resource mapping |
| **方块放置系统** | MVP | Core | buildability, layer_allowed | `is_buildable()`, `get_allowed_layers()` | **Blocking** — Placement validation requires buildability rules |
| **建造验证系统** | MVP | Feature | layer_allowed, collision_shape | `validate_layer_assignment()` | **Blocking** — Validation algorithm uses layer rules |
| **地堡设施系统** | MVP | Feature | buildability, hardness for facility tiles | `is_buildable()`, `get_tile_type_by_name()` | **Blocking** — Facility construction requires tile definitions |
| **炮塔系统** | MVP | Core | buildability for turret base tile | `is_buildable()` | **Blocking** — Turret placement requires buildable base |
| **陷阱系统** | Vertical Slice | Feature | buildability for trap tiles | `is_buildable()` | **Non-blocking** — Trap tiles are extension content |
| **HUD系统** | Full Vision | Presentation | display_name for tile tooltips | `get_display_name()` | **Non-blocking** — UI queries for display, not gameplay |
| **存档系统** | Full Vision | Polish | tile_type_id serialization (no direct query) | Indirect — save stores IDs, not definitions | **Non-blocking** — Save format references tile IDs |

---

### Dependency Interface Contract

方块类型数据库向下游系统提供以下接口承诺：

#### Data Contract (数据契约)

| Interface | Return Type | Failure Mode | Consumer Contract |
|-----------|-------------|--------------|-------------------|
| `get_tile_data(tile_type_id)` | TileData or `null` | Return `null` for invalid ID | Consumer must handle `null` gracefully |
| `get_hardness(tile_type_id)` | int (0-255) | Return 255 for invalid ID or indestructible | Consumer uses for damage calculation |
| `get_destructibility(tile_type_id)` | int (0-1) | Return 0 for invalid ID | Consumer checks before damage application |
| `get_collision_shape(tile_type_id)` | int (0-2) | Return 0 for invalid ID | Consumer uses for physics layer assignment |
| `get_resource_type_id(tile_type_id)` | int | Return 0 for invalid ID or no resource | Consumer checks > 0 before spawn |
| `get_resource_multiplier(tile_type_id)` | float (0.0-10.0) | Return 1.0 for invalid ID | Consumer multiplies base drop quantity |
| `get_buildability(tile_type_id)` | int (0-1) | Return 0 for invalid ID | Consumer checks before placement menu |
| `get_allowed_layers(tile_type_id)` | Array[int] | Return `[1]` (terrain layer) for invalid ID | Consumer validates placement target |
| `is_valid_tile_type(tile_type_id)` | bool | Return `false` for invalid ID | Consumer uses for pre-validation |

#### Timing Contract (时序契约)

| Constraint | Requirement |
|------------|-------------|
| **Query latency** | Immediate return — no async loading, no delay |
| **Initialization order** | BlockTypes must be loaded before any consumer system queries |
| **Thread safety** | All read queries are thread-safe (database immutable after load) |
| **Cache expectation** | Consumers may cache query results per tile type (not per instance) — BlockTypes does not invalidate caches |

#### Versioning Contract (版本契约)

| Constraint | Requirement |
|------------|-------------|
| **ID stability** | Tile type IDs never change after assignment |
| **Deprecation handling** | Deprecated tile types remain queryable; consumers receive valid data |
| **Forward compatibility** | New tile types added to reserved ID ranges do not break existing content |
| **Save compatibility** | Tile type definitions must not be deleted — existing save references remain valid |

---

### Critical Dependency Path (MVP)

方块类型数据库是以下MVP系统链的Foundation起点：

```
BlockTypeDatabase → TileMap世界系统 → 方块碰撞系统 → 战车驾驶系统
BlockTypeDatabase → TileMap世界系统 → 方块挖掘系统 → 撤退判定系统
BlockTypeDatabase → 方块放置系统 → 地堡设施系统 → 尸潮防守
BlockTypeDatabase → 资源掉落系统 → 玩家背包系统 → 搜刮交互系统
```

**MVP系统必须在BlockTypeDatabase完成后才能设计**：
- TileMap世界系统需要tile属性定义才能实现单元格存储
- 方块挖掘系统需要hardness值才能实现伤害累积
- 方块碰撞系统需要collision_shape才能实现物理检测

---

### Dependency Risk Assessment

| Risk | System | Mitigation |
|------|--------|------------|
| **BlockTypes singleton fails to load** | All downstream systems | Critical — game cannot run without tile definitions. Mitigation: TileSet resource is bundled with game; load failure = launch failure |
| **Tile type definition missing** | Consumer queries | Non-critical — query returns null, consumer handles gracefully. Mitigation: ID allocation scheme ensures no gaps in implemented ranges |
| **Resource Database not ready** | Resource Drop System | Non-critical — BlockTypes provides ID, Resource Database validates existence. Mitigation: Resource Drop System handles missing resource gracefully |
| **ID conflict from mod/expansion** | All consumers | Non-critical — reserved ID ranges prevent conflict. Mitigation: Expansion content must use 4000+ range |

---

### Systems Not Dependent on BlockTypeDatabase

以下系统不依赖方块类型数据库：

| System | Reason |
|--------|--------|
| **时间系统** | Independent — pure time tracking |
| **输入控制系统** | Independent — input mapping, no tile interaction |
| **战车属性系统** | Independent — vehicle stats, no tile queries |
| **敌人类型数据库** | Independent — enemy definitions, separate data domain |
| **资源数据库** | Independent — resource definitions, cross-referenced but not dependent (BlockTypes stores IDs, not definitions) |

## Tuning Knobs

方块类型数据库的调优参数主要影响游戏节奏、资源经济、和防守难度。以下参数在实现后可通过外部配置调整（不修改代码）。

### Primary Tuning Knobs (影响核心玩法)

| Knob | Current Value | Safe Range | Gameplay Effect | Pillar Affected |
|------|---------------|------------|-----------------|-----------------|
| **硬度基准值 (Hardness baseline)** | Defined per tile type (see Initial Catalog) | ±50% per tile | 挖掘时间 = hardness × 基准系数。提高硬度 → 挖掘更慢 → 搜打撤时间压力增加 | Pillar 2: 搜打撤节奏 |
| **硬度层级比例 (Hardness tier ratio)** | 地表:60 → 洞穴:100 (67%) → 深层:150 (50%) → 深渊:210 (40%) | 1.4-2.0倍率 (minimum 40% jump for perceptibility) | 深度与挖掘难度关联。调整比例 → 探索深度决策变化 | Pillar 2: 搜打撤节奏 |
| **资源产出倍率基准 (Resource multiplier baseline)** | 1.0 for terrain, 1.5-3.0 for ores | 0.5-5.0 | 每个矿脉产出量。提高倍率 → 资源更丰富 → 建造更快 | All pillars (economy) |
| **建造墙体硬度范围 (Wall hardness range)** | Basic:40 → Stone:70 → Reinforced:100 → Rune:140 → Mithril:200 | 20-255 | 墙体防御持久力。提高硬度 → 尸潮突破更慢 → 防守更容易 | Pillar 3: 尸潮即高潮 |
| **不可破坏标记 (Indestructible flag)** | bedrock: destructibility=0 | Fixed — never change | 边界和基岩不可挖。改变会破坏世界完整性 | World integrity |

### Secondary Tuning Knobs (影响次要体验)

| Knob | Current Value | Safe Range | Gameplay Effect |
|------|---------------|------------|-----------------|
| **地形硬度方差 (Terrain hardness variance)** | ±10 per terrain type | ±5-20 | 同类地形硬度差异，创造"软硬点"随机性 |
| **视觉变体数量 (Variant count per tile)** | 0-3 random variants per tile | 0-10 | 视觉多样性。过多变体增加纹理内存 |
| **损坏状态变体阈值 (Damage variant threshold)** | DAMAGED at 50% damage, CRITICAL at 80% damage | 0.4-0.7 (DAMAGED), 0.7-0.95 (CRITICAL) | 方块损坏视觉反馈时机。依赖TileMap系统THRESHOLD_CRITICAL=0.8 |

### Economy Tuning Knobs (资源产出平衡)

| Knob | Current Value | Safe Range | Gameplay Effect | Formula Dependency |
|------|---------------|------------|-----------------|-------------------|
| **铁矿脉产出倍率** | `iron_ore`: multiplier=1.0 | 0.5-3.0 | 铁资源产出量 | 资源掉落系统: `drop_count = base_drop × multiplier` |
| **魔力晶石产出倍率** | `crystal_cluster`: multiplier=2.0 | 1.0-5.0 | 魔力资源产出量 | 同上 |
| **秘银矿脉产出倍率** | `mithril_ore`: multiplier=1.0, `ancient_mithril`: multiplier=3.0 | 0.5-5.0 | 稀有资源稀缺性 | 同上 |
| **煤矿产出倍率** | `coal_deposit`: multiplier=1.5 | 0.5-3.0 | 燃料/基础资源产出 | 同上 |

### Defense Tuning Knobs (尸潮防守平衡)

| Knob | Current Value | Safe Range | Gameplay Effect | Pillar Affected |
|------|---------------|------------|-----------------|-----------------|
| **基础墙体持久时间** | hardness=50 → 约5秒防御时间 (enemy damage rate TBD) | 30-150 hardness | 新手防线持久力。太低 → 尸潮太快突破 | Pillar 3: 尸潮即高潮 |
| **秘银墙持久时间** | hardness=200 → 约20秒防御时间 | 150-255 hardness | 高级防线持久力。最高硬度定义防守上限 | Pillar 3: 尸潮即高潮 |
| **墙体硬度层级比例 (Wall tier ratio)** | Basic:50 → Stone:80 → Reinforced:120 → Mithril:200 | 1.2-2.0倍率 | 墙体升级收益。比例太低 → 升级不明显 | Pillar 3: 尸潮即高潮 |

### Knobs That Should NOT Be Tuned (固定值)

| Knob | Reason |
|------|--------|
| **CELL_SIZE=32** | 来自TileMap世界系统，已在registry注册。改变需重新缩放所有纹理资产。 |
| **ID allocation ranges** | ID分配范围是架构决策，改变会破坏跨系统引用一致性。 |
| **Layer assignment rules** | 层级分配是架构约束，改变需修改TileMap、碰撞、渲染多个系统。 |
| **Collision shape values (0-3)** | 碰撞形状枚举是引擎集成约定，改变需修改物理系统实现。 |

### Tuning Implementation

所有调优参数存储在以下位置：

| Parameter Type | Storage Location | Load Time | Edit Method |
|----------------|------------------|-----------|-------------|
| **Tile type hardness** | TileData custom_data_0 | Game startup (TileSet load) | Edit TileSet resource in Godot editor |
| **Resource multiplier** | TileData custom_data_3 | Game startup | Edit TileSet resource in Godot editor |
| **Buildability flag** | TileData custom_data_4 | Game startup | Edit TileSet resource in Godot editor |
| **Damage thresholds** | TileMap system constants (registry) | Game startup | Edit entities.yaml constants |

**调优流程**：
1. 在Godot编辑器中修改TileSet资源的TileData属性
2. 运行测试场景验证挖掘时间、资源产出
3. 运行尸潮防守测试验证墙体持久时间
4. 提交TileSet资源变更

### Tuning Validation Tests

| Test | Method | Success Criterion |
|------|--------|-------------------|
| **挖掘时间验证** | 挖掘各硬度方块，测量实际破坏时间 | 时间 ≈ hardness × 基准系数 (±10%) |
| **资源产出验证** | 破坏矿脉，统计产出数量 | 数量 = base_drop × multiplier (±0 variance) |
| **墙体防守验证** | 尸潮攻击各硬度墙体，测量突破时间 | 时间 ≈ hardness / enemy_damage_rate |
| **层级穿越验证** | 从地表挖到深渊，测量总时间 | 总时间 ≈ 累计硬度值，符合预期探索节奏 |

## Visual/Audio Requirements

方块类型数据库是纯数据系统，不直接产生视觉或音频输出。视觉和音频需求由下游消费系统（TileMap渲染、挖掘反馈、资源掉落）实现。以下列出数据库需要提供的视觉/音频数据映射。

### Visual Data Provided by BlockTypeDatabase

数据库为视觉系统提供以下数据映射：

| Data | Type | Consumer System | Visual Effect |
|------|------|-----------------|---------------|
| **texture_path** | Resource path | TileMap renderer | 确定方块纹理来源。每个tile type指向texture atlas中的对应位置。 |
| **variants** | Array[VariantDef] | TileMap renderer | 确定方块视觉变体。随机变体创造纹理多样性；损坏变体显示方块状态。 |
| **display_name** | Localized string | HUD tooltips | 确定方块名称显示。玩家悬停/瞄准方块时显示名称。 |
| **layer_allowed** | Array[int] | Camera/LOD system | 确定方块渲染层级。背景层(Layer 0)渲染50%透明度；其他层正常渲染。 |

### Texture Requirements (Asset Production)

方块类型数据库定义了纹理需求，由资产管线实现：

| Texture Category | Atlas File | Tile Count | Texture Size per Tile | Total Atlas Size |
|------------------|------------|------------|----------------------|------------------|
| **Terrain** | `terrain_atlas.png` | 12 tiles | 32×32 px | 384×32 px (12 tiles wide) or 192×64 px (6×2 grid) |
| **Resource Ores** | `resource_atlas.png` | 8 tiles | 32×32 px | 256×32 px or 128×64 px |
| **Building Walls** | `building_atlas.png` | 5 wall tiles | 32×32 px | 160×32 px or 80×64 px |
| **Building Floors** | Same atlas | 3 floor/platform tiles | 32×32 px | Included in building_atlas |
| **Decoration** | `decoration_atlas.png` | 5 tiles | 32×32 px | 160×32 px or 80×64 px |

**Variant Texture Layout**: 每个tile type的变体纹理存储在同一atlas行的连续位置。例如`surface_stone`基础纹理在(0,0)，变体在(1,0)、(2,0)等。

**Damage Variant Requirements**: 每个可破坏tile type需要3个视觉状态：
- **INTACT**: 基础纹理 (alternative_id=0)
- **DAMAGED**: 轻微损坏纹理 (alternative_id=1) — 裂纹、碎片效果
- **CRITICAL**: 严重损坏纹理 (alternative_id=2) — 深裂纹、即将崩塌视觉效果

### Audio Data Provided by BlockTypeDatabase

数据库不直接提供音频数据。音频反馈由下游系统根据tile属性动态选择：

| Audio Event | Consumer System | Data Used | Audio Selection Logic |
|-------------|-----------------|-----------|----------------------|
| **挖掘打击音效** | 方块挖掘系统 | hardness, collision_shape | hardness高 → 重击音效；hardness低 → 轻击音效。collision_shape=0 → 无音效（无碰撞）。 |
| **方块破坏音效** | 方块挖掘系统 | hardness, resource_type_id | 破坏时播放崩溃音效。resource_type_id>0 → 附加资源掉落叮咚声。 |
| **方块放置音效** | 方块放置系统 | collision_shape | collision_shape=1 → 重放置声；collision_shape=2 → 轻放置声（平台）。 |
| **碰撞音效** | 战车驾驶系统 | collision_shape | 战车撞墙 → 碰撞声。collision_shape=1 → 硬碰撞声；collision_shape=2 → 软着陆声。 |

**Audio Design Note**: 方块类型数据库不存储音频文件路径。音频映射由AudioManager根据tile属性动态选择（如"stone_dig_heavy"、"stone_break"、"metal_place"等音频bank）。这允许音频系统集中管理音效资产，避免数据库与音频资产耦合。

### Visual Requirements Summary

| Requirement | Owner System | Implementation Notes |
|-------------|--------------|---------------------|
| **纹理资产** | Asset Production | 每个tile type需要32×32纹理 + 变体 + 损坏状态纹理 |
| **纹理Atlas布局** | BlockTypeDatabase | texture_path和variants数组定义atlas坐标映射 |
| **损坏状态视觉** | TileMap世界系统 | 根据damage_ratio选择damage_variant纹理 |
| **方块名称显示** | HUD系统 | 查询display_name显示tooltip |
| **层级渲染效果** | TileMap世界系统 | Layer 0背景50%透明度；Layer 4 overlay transient rendering |

### Audio Requirements Summary

| Requirement | Owner System | Implementation Notes |
|-------------|--------------|---------------------|
| **挖掘音效bank** | Audio系统 | 根据hardness区间选择dig_light/dig_medium/dig_heavy |
| **破坏音效bank** | Audio系统 | 破坏时播放break_small/break_large + 资源掉落音效 |
| **放置音效bank** | Audio系统 | 根据collision_shape选择place_heavy/place_light |
| **碰撞音效bank** | Audio系统 | 战车碰撞根据collision_shape选择collision_hard/soft |

## UI Requirements

方块类型数据库为UI系统提供数据支持，但数据库本身不渲染UI。以下列出UI系统需要从数据库获取的数据和显示需求。

### UI Data Provided by BlockTypeDatabase

| UI Element | Data Source | Display Context | Consumer System |
|------------|-------------|-----------------|-----------------|
| **方块Tooltip名称** | `get_display_name(tile_type_id)` | 玩家悬停/瞄准方块时显示 | HUD系统 / 瞄准系统 |
| **方块Tooltip属性** | `get_hardness()`, `get_destructibility()`, `get_resource_type_id()` | Tooltip详情面板显示方块属性 | HUD系统 |
| **建造菜单方块列表** | `get_buildable_tiles()` → filter by available materials | 建造菜单显示可建造方块 | 建造系统UI |
| **建造方块属性** | `get_hardness()`, `get_display_name()` | 建造菜单显示方块防御值和名称 | 建造系统UI |
| **挖掘进度条** | `get_hardness()` (用于进度计算) | HUD显示挖掘进度百分比 | 方块挖掘系统UI |
| **资源预览** | `get_resource_type_id()` → Resource Database lookup | 方块破坏前显示预期资源产出 | HUD系统 |

### UI Display Requirements

#### Tooltip Display (方块信息悬浮窗)

| Element | Format | Data Query |
|---------|--------|------------|
| **方块名称** | "地表岩石" (localized) | `get_display_name(tile_type_id)` |
| **硬度等级** | "硬度: 中等 (80)" | `get_hardness(tile_type_id)` + hardness→text mapping |
| **可破坏性** | "可破坏" or "不可破坏" | `get_destructibility(tile_type_id)` = 1 → "可破坏"; 0 → "不可破坏" |
| **资源产出** | "产出: 无" or "产出: 铁矿 (×1.0)" | `get_resource_type_id()` > 0 → lookup resource name; 0 → "无" |
| **建造状态** | "自然方块" or "可建造" | `get_buildability()` = 1 → "可建造"; 0 → "自然方块" |

**Tooltip Layout**:
```
┌─────────────────────┐
│ 地表岩石            │
│ ─────────────────── │
│ 硬度: 中等 (80)     │
│ 可破坏              │
│ 产出: 无            │
│ 自然方块            │
└─────────────────────┘
```

#### Build Menu Display (建造菜单方块列表)

| Element | Format | Data Query |
|---------|--------|------------|
| **方块图标** | Tile texture thumbnail | Texture atlas extraction at tile_type_id position |
| **方块名称** | "基础墙体" (localized) | `get_display_name(tile_type_id)` |
| **防御值** | "防御: ★★☆☆☆" or "硬度: 50" | `get_hardness()` → star rating mapping |
| **材料需求** | (From Resource Database, not BlockTypes) | Resource cost lookup |
| **可建造状态** | ✓ or locked icon | `get_buildability()` + material availability check |

**Build Menu Layout**:
```
┌──────────────────────────┐
│ 建造菜单                 │
│ ──────────────────────── │
│ [图标] 基础墙体  ★★☆☆☆  │
│        需要: 石块×5      │
│                          │
│ [图标] 石墙      ★★★☆☆  │
│        需要: 石块×10     │
│                          │
│ [图标] 秘银墙    ★★★★★  │
│        需要: 秘银×3 锁定 │
└──────────────────────────┘
```

**Hardness to Star Rating Mapping**:

| Hardness Range | Star Rating | Display |
|----------------|-------------|---------|
| 0-40 | ★☆☆☆☆ | Very weak |
| 41-80 | ★★☆☆☆ | Weak |
| 81-120 | ★★★☆☆ | Medium |
| 121-180 | ★★★★☆ | Strong |
| 181-255 | ★★★★★ | Very strong |

#### Dig Progress Bar (挖掘进度条)

| Element | Format | Data Query |
|---------|--------|------------|
| **进度条百分比** | 0-100% | `progress = accumulated_damage / hardness` |
| **进度条颜色** | 绿色(0-50%) → 黄色(50-80%) → 红色(80-100%) | Mapping from THRESHOLD_CRITICAL=0.8 |
| **进度条动画** | 增长动画 + 打击反馈闪烁 | Animated by Digging System |

**Dig Progress Bar Layout**:
```
┌────────────────────┐
│ 挖掘: 地表岩石     │
│ ████████░░░░ 65%   │ ← Yellow phase
└────────────────────┘
```

### UI Localization Requirements

| Data | Localization Key | Language Support |
|------|-----------------|------------------|
| **display_name** | `tile_[tile_name]` | All supported languages (中文, English, etc.) |
| **hardness_text** | `hardness_[level]` ("very_weak", "weak", "medium", "strong", "very_strong") | All supported languages |
| **buildability_text** | `buildability_[type]` ("natural", "buildable") | All supported languages |

**Localization Implementation**: BlockTypeDatabase stores internal tile name (e.g., "surface_stone"). HUD系统调用`LocalizationManager.get_localized("tile_surface_stone")`获取显示名称。数据库不存储localized strings。

### UI Accessibility Requirements

| Requirement | Implementation |
|-------------|----------------|
| **Screen reader support** | Tooltip content exposed as accessible text; screen reader reads tile name + attributes |
| **High contrast mode** | Star rating replaced with numeric hardness value; color coding replaced with symbols |
| **Colorblind support** | Progress bar uses shape coding (checkered pattern for DAMAGED, striped for CRITICAL) in addition to color |

### UI Systems That Query BlockTypeDatabase

| UI System | Query Frequency | Data Used |
|-----------|-----------------|-----------|
| **HUD Tooltip System** | On hover/aim change (per-frame check) | display_name, hardness, destructibility, resource_type_id, buildability |
| **Build Menu System** | On menu open (once) | All buildable tiles, hardness, display_name |
| **Dig Progress UI** | Per damage tick (实时更新) | hardness (for progress calculation) |
| **Resource Preview UI** | On aim change | resource_type_id (preview potential drop) |

## Acceptance Criteria

以下测试标准用于验证方块类型数据库的实现是否满足设计规范。所有标准必须通过才能标记系统为"Ready for Implementation"。

### Data Integrity Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-001** | TileSet资源加载成功 | 启动游戏，检查BlockTypes autoload初始化状态 | BlockTypes._ready()完成，无error log，tile_count >= 25 (MVP catalog minimum) |
| **AC-002** | Tile type ID无重复 | 检查TileSet atlas indices | 每个atlas index (tile_type_id)唯一，无冲突 |
| **AC-003** | ID分配符合allocation scheme | 验证每个tile的ID在正确range | terrain tiles在0-399, ores在500-999, buildings在1000-2999 |
| **AC-004** | Custom_data字段映射正确 | 检查TileSet custom_data_layers配置 | custom_data_0-5正确映射到hardness/destructibility/resource_type_id/resource_multiplier/buildability/collision_shape |
| **AC-005** | Hardness值在有效范围 | 检查所有tile hardness值 | 所有hardness在0-255范围 |
| **AC-006** | Destructibility值有效 | 检查所有tile destructibility值 | 所有destructibility为0或1 |
| **AC-007** | Resource multiplier值有效 | 检查所有tile resource_multiplier值 | 所有multiplier在0.0-10.0范围 |
| **AC-008** | Layer_allowed数组有效 | 检查所有tile layer_allowed | 每个tile至少一个layer在数组中，layer值在0-4范围 |

### Query API Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-009** | Valid ID查询返回正确数据 | `get_tile_data(100)` → verify返回surface_stone定义 | 返回的TileData包含正确hardness=80, destructibility=1, 等 |
| **AC-010** | Invalid ID查询返回null | `get_tile_data(450)` (ID不存在) | 返回`null`, 无exception抛出 |
| **AC-011** | ID=0返回NULL_TILE定义 | `get_tile_data(0)` | 返回预定义的NULL_TILE_DEFINITION (hardness=255, destructibility=0) |
| **AC-012** | Hardness override生效 | `get_hardness(1)` (bedrock, destructibility=0) | 返回255 (override), 不是TileData存储的hardness值 |
| **AC-013** | Category查询正确 | `get_tiles_by_category("terrain_surface")` | 返回ID 100-199范围的tile列表 |
| **AC-014** | Buildable查询正确 | `get_buildable_tiles()` | 返回所有buildability=1的tile列表 (ID 1000+范围) |
| **AC-015** | Layer validation正确 | `can_place_on_layer(100, 2)` (surface_stone on Layer 2) | 返回`false` (terrain不能在Layer 2) |
| **AC-016** | Collision shape查询正确 | `get_collision_shape(1510)` (platform_wooden) | 返回2 (PLATFORM collision) |

### Integration Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-017** | Query API返回TileData资源 | 调用`BlockTypes.get_tile_data(100)`并验证返回类型 | 返回值是TileData资源对象（非null），包含custom_data字段 |
| **AC-018** | Hardness值可通过API读取 | 调用`BlockTypes.get_hardness(100)` | 返回值=60（surface_stone recalibrated hardness），类型为int |
| **AC-019** | Collision shape可通过API读取 | 调用`BlockTypes.get_collision_shape(1510)` | 返回值=2（PLATFORM collision），类型为int |
| **AC-020** | Resource mapping可通过API读取 | 调用`BlockTypes.get_resource_type_id(500)`和`get_resource_multiplier(500)` | resource_type_id=101，multiplier=1.0，类型匹配（int/float） |
| **AC-021** | Buildability validation可通过API查询 | 调用`BlockTypes.is_buildable(100)`和`is_buildable(1000)` | 返回false（terrain不可建）和true（wall_basic可建） |
| **AC-022** | Display name lookup委托LocalizationManager | 调用`BlockTypes.get_display_name(100)`返回内部name | 返回"surface_stone"（internal identifier），LocalizationManager负责localized显示 |

### Performance Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-023** | Single query latency < 0.1ms | 在GDScript中循环调用`get_tile_data(100)` 1000次，测量总耗时/1000 | 平均单次查询耗时 ≤ 0.1ms（immediate return，no async） |
| **AC-024** | TileSet resource load time < 500ms | 在游戏启动时测量BlockTypes autoload初始化耗时（从_enter_tree到_ready完成） | TileSet加载耗时 ≤ 500ms（不影响启动体验） |
| **AC-025** | BlockTypes memory footprint < 2MB | 使用Godot性能监视器测量BlockTypes singleton内存占用 | 内存占用 ≤ 2MB（TileSet资源轻量，约25 tiles × ~80KB/tile） |

### Edge Case Handling Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-026** | Negative ID返回null | `get_tile_type(-1)` | 返回`null`, 无crash |
| **AC-027** | ID超过65535返回null | `get_tile_type(70000)` | 返回`null`, 无crash |
| **AC-028** | Deprecated tile behavior simulated | 手动标记tile_type_id=1000为deprecated（修改registry metadata），调用`get_tile_data(1000)` | 查询返回有效TileData（deprecated不改变运行时行为），buildability查询仍返回true |
| **AC-029** | PLANNED tile返回null | `get_tile_data(400)` (PLANNED state) | 返回`null`, log warning |
| **AC-030** | Empty variants数组正确处理 | `get_random_variant(tile_id)` for tile with `variants=[]` | 返回0 (default variant), 无error |
| **AC-031** | All variants weight=0正确处理 | `get_random_variant(tile_id)` for tile with all weight=0 | 返回0 (fallback), log warning |

### MVP Tile Catalog Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-032** | Terrain tiles defined | 检查ID range 0-399中ACTIVE tile count | Terrain category包含12 tiles: null_tile(0), bedrock(1,10,20), surface(100,110,120), cave(200,210,220), deep(300), abyss(310) |
| **AC-033** | Resource ore tiles defined | 检查ID range 500-999中ACTIVE tile count | Resource_ores category包含8 tiles: iron(500), copper(510), coal(520), crystal(600,610), mithril(700,710), gold(800) |
| **AC-034** | Building wall tiles defined | 检查ID range 1000-1499中ACTIVE tile count | Building_walls category包含5 tiles: wall_basic(1000), wall_stone(1010), wall_reinforced(1020), wall_rune(1030), wall_mithril(1040) |
| **AC-035** | Platform tiles defined | 检查ID range 1500-1999中ACTIVE tile count | Building_floors category包含3 tiles: floor_basic(1500), platform_wooden(1510), platform_metal(1520) |
| **AC-036** | Decoration tiles defined | 检查ID range 3000-3499中ACTIVE tile count | Decoration category包含5 tiles: bg_ruins(3000), bg_cave(3010), marker_spawn(3500), indicator_damage(3510,3520) |

### Documentation Criteria

| ID | Criterion | Test Method | Pass Condition |
|----|-----------|-------------|----------------|
| **AC-037** | API doc comments complete | 检查BlockTypeDatabase.gd所有public方法有doc comments | 每个public方法（get_tile_data, get_hardness, etc）有@brief description和@param/@return标注 |
| **AC-038** | Systems-index updated | 检查systems-index.md Status column | 方块类型数据库status="Designed"，Design Doc列指向block-type-database.md |
| **AC-039** | Entity registry constants registered | 检查entities.yaml constants section | CELL_SIZE=32已在registry（来自TileMap系统）， hardness tier values不需要额外注册（per-tile配置） |

### Pass/Fail Threshold

| Category | Pass Count | Fail Action |
|----------|------------|-------------|
| **Data Integrity (AC-001 to AC-008)** | 必须100%通过 | 任一失败 → 无法实现，必须修复TileSet资源 |
| **Query API (AC-009 to AC-016)** | 必须100%通过 | 任一失败 → API实现错误，必须修复代码 |
| **Integration (AC-017 to AC-022)** | 必须100%通过 | 任一失败 → 跨系统契约违反，必须修复接口 |
| **Performance (AC-023 to AC-025)** | 必须通过 | 任一失败 → 性能优化，但可进入实现阶段 |
| **Edge Cases (AC-026 to AC-031)** | 必须100%通过 | 任一失败 → 边界处理缺失，必须补充 |
| **MVP Catalog (AC-032 to AC-036)** | 必须100%通过 | 任一失败 → 内容不足，必须补充tile定义 |
| **Documentation (AC-037 to AC-039)** | 必须100%通过 | 任一失败 → 文档不完整，无法进入实现 |

**Total Criteria**: 39
**Required for Implementation**: 100% pass on all categories

## Open Questions

以下问题在GDD设计阶段未能完全解决，需要在实现前或实现过程中澄清。

### High Priority (Implementation Blocking)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-001** | 资源数据库的resource_type_id分配是否已定义？BlockTypeDatabase引用resource_type_id（如铁矿=101），但Resource Database尚未设计。 | 资源数据库GDD设计者 | Resource Drop System实现前 | 无法验证tile→resource映射是否有效，资源掉落测试无法进行 |
| **Q-002** | 挖掘系统的damage_rate公式是否已确定？BlockTypeDatabase定义hardness值，但挖掘时间计算依赖damage_rate。 | 方块挖掘系统GDD设计者 | Digging System实现前 | 无法验证hardness值是否产生正确的挖掘节奏 |
| **Q-003** | 敌人类型数据库的enemy_damage_rate是否已确定？墙体防守验证需要enemy_damage_rate计算突破时间。 | 敌人类型数据库GDD设计者 | 尸潮防守测试前 | 无法验证wall hardness是否产生正确的防守持久时间 |
| **Q-004** | TileMap系统是否已确认custom_data字段索引映射？BlockTypeDatabase定义custom_data_0-5映射，但需TileMap系统确认契约一致。 | TileMap世界系统实现者 | BlockTypeDatabase实现前 | 字段索引不一致会导致数据错位 |

### Medium Priority (Design Clarification)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-005** | 是否需要支持动态添加tile type（mod/expansion支持）？当前设计假设静态TileSet，但未来可能需要动态注册。 | Technical Director + Producer | Alpha里程碑前 | 影响ID allocation scheme扩展策略和资源加载架构 |
| **Q-006** | 是否需要tile type的分类标签（tags）？当前只有category字段，但可能需要更灵活的分类（如"耐火"、"导电"等属性标签）。 | Game Designer | 地堡设施系统设计前 | 设施系统可能需要特殊tile属性，影响数据结构扩展 |
| **Q-007** | 损坏状态变体是否由TileMap系统统一管理还是BlockTypeDatabase定义？当前假设由TileMap系统根据THRESHOLD_CRITICAL选择变体，但变体索引定义在BlockTypeDatabase。 | TileMap系统 + BlockTypeDatabase | 实现前 | 变体选择逻辑归属不清，可能重复实现或遗漏 |

### Low Priority (Future Consideration)

| ID | Question | Owner | Resolution Needed Before | Impact if Unresolved |
|----|----------|-------|-------------------------|----------------------|
| **Q-008** | 是否需要tile type的本地化描述文本（description field）？当前只有display_name和内部description（documentation only）。 | UX Designer | Beta阶段（UI完善） | 不影响MVP实现，但可能影响Tooltip丰富度 |
| **Q-009** | 是否需要tile type的音效映射存储在数据库内？当前设计假设AudioManager根据hardness动态选择，但可能需要直接存储audio_id。 | Audio Designer + Technical Director | Audio系统实现前 | 影响音效选择架构（集中管理vs分散定义） |
| **Q-010** | Deprecated tile的处理策略：是否需要在UI中显示deprecated标记？当前设计假设deprecated tiles保持功能，但UI可能需要警告。 | UX Designer | 存档系统实现前 | 影响deprecated tiles的用户体验处理 |

### Resolution Tracking

| ID | Status | Resolution Date | Resolved By | Resolution Summary |
|----|--------|-----------------|-------------|-------------------|
| Q-001 | Open | — | — | Pending 资源数据库GDD |
| Q-002 | Open | — | — | Pending 方块挖掘系统GDD |
| Q-003 | Open | — | — | Pending 敌人类型数据库GDD |
| Q-004 | Open | — | — | Pending TileMap系统实现确认 |
| Q-005 | Open | — | — | Pending Technical Director决策 |
| Q-006 | Open | — | — | Pending Game Designer决策 |
| Q-007 | Open | — | — | Pending TileMap + BlockTypeDatabase协调 |
| Q-008 | Open | — | — | Pending UX Designer决策 |
| Q-009 | Open | — | — | Pending Audio Designer决策 |
| Q-010 | Open | — | — | Pending UX Designer决策 |

### Assumptions Made (Temporary Decisions)

| Assumption | Rationale | Risk |
|------------|-----------|------|
| **resource_type_id值假设正确** | 依据common game design practice（铁矿=101, 铜矿=102等），Resource Database将采用类似ID scheme | 如果Resource Database使用不同ID scheme，需要更新BlockTypeDatabase的resource_type_id值 |
| **damage_rate假设为1.0** | 用于hardness值基准设定（hardness=80 → 约80次hit）。实际值在Digging System设计时确定 | 如果damage_rate不同，可能需要调整所有hardness值 |
| **custom_data字段索引固定** | 假设TileMap系统遵循block-type-database.md定义的映射顺序 | 如果TileMap系统使用不同顺序，需要同步修改 |
| **不支持动态tile添加** | MVP阶段使用静态TileSet，简化实现复杂度 | Alpha阶段可能需要重新设计资源加载架构 |