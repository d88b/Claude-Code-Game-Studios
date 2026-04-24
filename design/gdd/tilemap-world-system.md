# TileMap世界系统

> **Status**: Designed (pending review)
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-22
> **Section Status**: Overview ✓ | Player Fantasy ✓ | Detailed Design ✓ | Formulas ✓ | Edge Cases ✓ | Dependencies ✓ | Tuning Knobs ✓ | Visual/Audio ✓ | UI ✓ | Acceptance Criteria ✓ | Open Questions ✓
> **Implements Pillar**: Foundation for all pillars — enables every other system
> **Priority**: MVP | **Layer**: Foundation
> **System ID**: #1 (from systems-index.md)

## Overview

The TileMap世界系统 is the foundational spatial representation for the entire game world — a 2D grid-based data structure that stores all tile positions, layer assignments, collision shapes, and serves as the coordinate system for every entity, vehicle, projectile, and building. It is the single source of truth for "where things are" in the 铁锈魔潮 universe.

Players do not interact with the TileMap directly as a system — they interact with the visible world it renders. Every action in the game (digging a block, placing a turret, driving the battle wagon, spawning an enemy, planting crops) queries or modifies the TileMap through downstream systems. The grid itself is invisible; the player sees the rendered tiles, the collision feedback, and the spatial consequences of their actions.

Without this system, the game has no spatial dimension — no coordinate space for movement, no collision detection for vehicles and projectiles, no placement validation for buildings, no exploration areas, and no world to defend. It is the bedrock on which every other MVP system is built.

**Key data responsibilities:**
- Grid cell storage (tile type per cell, per layer)
- Layer management (background, foreground, collision, navigation)
- Coordinate system (integer cell positions, world-to-cell conversion)
- Tile type lookup (what tile is at (x, y)? Is it solid? Is it destructible?)
- Collision shape provision (provides collision polygons to PhysicsBody2D systems)

**Downstream consumers (systems that depend on this):**
- 方块碰撞系统 — reads collision layer
- 方块挖掘系统 — modifies tile cells, checks tile hardness
- 方块放置系统 — modifies tile cells, validates placement
- 战车驾驶系统 — reads collision for movement, queries world position to cell
- 探索区域系统 — defines regions by cell boundaries
- 敌人生成系统 — spawns at valid cell positions
- 炮塔系统 — places at valid cell positions
- 地堡设施系统 — places facilities at cell positions
- 雨水收集系统 / 种田系统 — defines farm plots by cell coordinates

## Player Fantasy

### Primary Fantasy: 地下圣所的边界

The TileMap system delivers the emotional promise of **security through definition** — the grid is the boundary between *player-owned space* and the hostile world outside. Walls are not decoration; they are survival made tangible.

**Peak moment**: The first zombie tide arrives. The player has spent the previous cycle digging tunnels, sealing breaches, positioning turrets, and reinforcing key chokepoints. Now the horde crashes against their constructions — and *holds*. The player watches from behind their walls as the grid they built becomes a line of life and death. Every tile they placed, every tunnel they sealed, every defensive position they carved — all of it matters in this moment of violent validation.

**What the player feels**:
- When placing a wall tile: *"This tile is my shield against the darkness."*
- When a wall breaks during a tide: *"The breach is real. My defenses have failed somewhere concrete."*
- When standing in a sealed bunker: *"I am inside. The world outside is hostile. The boundary is clear."*

**Design implications for the TileMap**:
- Wall tiles must feel *substantial* — audiovisual weight when zombies pound on them, visible damage states that progress toward destruction
- The moment a wall tile breaks must be dramatic — not a silent disappearance, but a breach with consequences (sound alarm, visual crack, debris burst)
- Player-built structures should look different from natural formations (welded seams on metal panels, reinforced concrete texture, magitech glow at structural joints)
- The grid should reveal strategic information — enemy positions through thin walls, structural weak points, resource deposits visible in cross-section
- Ambient sound should encode "safety" vs. "danger" — sealed spaces hum differently than unexplored tunnels

**Pillar alignment**:
- **Pillar 3: 尸潮即高潮** — The grid is the physical manifestation of the defense phase. Without the TileMap defining wall positions, the zombie tide has no target to attack and no breach points to threaten.
- **Pillar 1: 战车即生命** — The grid defines the terrain the battle wagon traverses. Collision shapes in the TileMap determine where the wagon can go and where it must stop.
- **Pillar 4: 魔导科技美学** — Wall tiles and defensive structures should carry magitech visual signatures (runes, crystal inlays, arcane energy at joints).

## Detailed Design

### Core Rules

#### 1. Grid Structure

**Cell properties:**

- **Cell size**: 32x32 pixels (Godot TileMap `tile_size` property)
- **Coordinate system**: `Vector2i` integer cell coordinates, origin at world (0, 0)
- **Coordinate convention**: `(x, y)` where `x` increases rightward, `y` increases downward (Godot standard)
- **World bounds**: Minimum `(-1000, -1000)` to maximum `(1000, 1000)` — 2001x2001 cells, ~64km virtual world
- **Active area**: Only cells within loaded chunks are processed; unloaded cells are null (empty)
- **Chunk size**: 32x32 cells per chunk (1024 tiles, 32KB data per chunk approximate)
- **Layer count**: 5 fixed layers, indexed 0-4 (see Layer Types below)

**Coordinate conversion rules:**

1. World position to cell: `cell = Vector2i(floor(world_pos.x / CELL_SIZE), floor(world_pos.y / CELL_SIZE))`
2. Cell to world position (center): `world_center = Vector2((cell.x + 0.5) * CELL_SIZE, (cell.y + 0.5) * CELL_SIZE)`
3. Cell to world position (top-left): `world_top_left = Vector2(cell.x * CELL_SIZE, cell.y * CELL_SIZE)`
4. All downstream systems MUST use `TileMapWorld.local_to_map(Vector2 position)` for conversion — never calculate manually
5. All downstream systems MUST use `TileMapWorld.map_to_local(Vector2i cell)` for inverse conversion

**Chunk loading/unloading rules:**

1. Chunks are loaded when any active entity (player wagon, spawned enemy, placed turret) enters within 2 chunk radius
2. Chunks are unloaded when no active entity has been within 3 chunk radius for 30 seconds
3. On unload, chunk data is serialized to disk (save file) or discarded if temporary (unmodified generated terrain)
4. Modified chunks (player-built tiles) MUST persist on unload — never discard player modifications
5. Chunk modification flag is set when any tile in chunk differs from generated baseline

#### 2. Tile Data Model

**Each cell stores:**

| Data Field | Type | Source | Description |
|------------|------|--------|-------------|
| `tile_type_id` | int (0-65535) | TileSet resource | Unique identifier mapping to TileData resource |
| `layer_index` | int (0-4) | TileMap layer | Which layer this tile occupies (immutable per layer) |
| `variant_index` | int (0-255) | TileData | Visual variant for texture variety |
| `custom_data_0` | int | TileData | Block hardness (0-255, consumed by digging system) |
| `custom_data_1` | int | TileData | Block destructibility flag (0=indestructible, 1=destructible) |
| `custom_data_2` | int | TileData | Resource output type ID (0=none, >0=resource database ID) |
| `custom_data_3` | float | TileData | Resource output quantity multiplier (0.0-10.0) |
| `custom_data_4` | int | TileData | Buildability flag (0=natural, 1=player-buildable) |
| `custom_data_5` | int | TileData | Collision shape type (0=none, 1=full, 2=platform, 3=custom) |

**Tile existence rule:**

- A cell is "empty" if `tile_type_id == -1` (Godot TileMap default for empty cells)
- A cell is "occupied" if `tile_type_id >= 0`
- Empty cells return null for all custom data queries

**Tile uniqueness rule:**

- Each tile_type_id maps to exactly one TileData resource definition
- TileData resources are stored in `assets/data/tile_data/` as `.tres` files
- TileData definitions are immutable at runtime — modifications require new tile_type_id

**Runtime tile state (per-cell, not in TileData):**

| Field | Type | Stored In | Description |
|-------|------|-----------|-------------|
| `damage_accumulated` | float | Runtime dictionary | Damage taken toward destruction (0.0 to hardness) |
| `last_damage_source` | int | Runtime dictionary | Source of damage (0=none, 1=dig tool, 2=enemy, 3=explosion) |
| `temporary_visual_override` | int | Runtime dictionary | Damage state visual variant override (-1=none) |

1. Runtime tile state is stored in `TileMapWorld._cell_runtime_state: Dictionary` keyed by `Vector2i` cell
2. Runtime state is initialized when first damage is applied to a tile
3. Runtime state is cleared when tile is destroyed or repaired to full
4. Runtime state persists across chunk unload/load for modified tiles

#### 3. Layer Types

**Layer index and purpose:**

| Index | Layer Name | Purpose | Collision | Visible |
|-------|------------|---------|-----------|---------|
| 0 | `background` | Environmental decoration, distant terrain | None | Yes, 50% opacity |
| 1 | `terrain_base` | Natural ground, cave walls, indestructible bedrock | Full collision | Yes |
| 2 | `structures` | Player-built walls, facilities, defensive structures | Full collision | Yes |
| 3 | `platforms` | Walkable platforms, scaffolds, partial collision | Platform collision | Yes |
| 4 | `overlay` | Temporary markers, damage indicators, spawn points | None | Yes, transient |

**Layer ordering rule:**

- Layers render in index order: background (0) is farthest, overlay (4) is nearest to camera
- Godot TileMap `y_sort_origin` is disabled — strict layer ordering applies globally
- Z-index for each TileMap layer node: `z_index = layer_index * 10`

**Layer collision rule:**

| Layer | Collision Shape | Physics Layer Bit | Navigation |
|-------|----------------|-------------------|------------|
| background | None | N/A | Not walkable |
| terrain_base | Full rect (32x32) | Bit 0 (COLLISION_TERRAIN, value 1) | Walkable if empty |
| structures | Full rect (32x32) | Bit 1 (COLLISION_STRUCTURE, value 2) | Walkable if empty |
| platforms | Platform (top 8px solid) | Bit 2 (COLLISION_PLATFORM, value 4) | Walkable from above |
| overlay | None | N/A | Not walkable |

**Layer occupancy rule:**

1. A cell can have tiles on multiple layers simultaneously (e.g., background + terrain_base + structures)
2. A cell cannot have more than one tile per layer — `set_cell` overwrites existing tile
3. Collision query checks layers 1, 2, 3 in order — first non-empty tile determines collision result
4. Navigation query treats layers 1, 2 as blocking; layer 3 as passable from above only

**Layer-specific tile placement rules:**

| Layer | Can Place | Can Remove | Placement Validation |
|-------|-----------|------------|---------------------|
| background | Never by player | Never | Generated only |
| terrain_base | Never by player | Only by digging system | Depends on hardness, requires tool |
| structures | Yes, by player | Yes, by player or destruction | Requires adjacent solid tile or foundation |
| platforms | Yes, by player | Yes, by player or destruction | Requires support from below or side |
| overlay | System-managed only | System-managed only | No player interaction |

#### 4. Tile Lookup API

**Primary lookup methods (exposed by `TileMapWorld` singleton):**

```gdscript
# Returns TileData resource for tile at cell, or null if empty
func get_tile_data(cell: Vector2i, layer: int) -> TileData

# Returns tile_type_id at cell, or -1 if empty
func get_tile_type(cell: Vector2i, layer: int) -> int

# Returns custom_data value at cell for specified index, or default if empty
func get_tile_custom_data(cell: Vector2i, layer: int, data_index: int) -> Variant

# Returns true if any collision layer (1-3) has non-empty tile at cell
func is_cell_solid(cell: Vector2i) -> bool

# Returns true if cell has tile on specified layer
func is_cell_occupied(cell: Vector2i, layer: int) -> bool

# Returns hardness value for tile at cell (terrain_base or structures), or 255 if indestructible
func get_tile_hardness(cell: Vector2i) -> int

# Returns the primary collision tile at cell (checks layers 1→2→3, returns first occupied)
func get_collision_tile(cell: Vector2i) -> Dictionary  # {layer: int, tile_type: int, TileData: TileData}
```

**Coordinate conversion methods:**

```gdscript
# Converts world Vector2 position to cell Vector2i
func world_to_cell(world_pos: Vector2) -> Vector2i

# Converts cell Vector2i to world center position Vector2
func cell_to_world_center(cell: Vector2i) -> Vector2

# Converts cell Vector2i to world top-left position Vector2
func cell_to_world_corner(cell: Vector2i) -> Vector2
```

**Batch lookup methods:**

```gdscript
# Returns array of cells within rectangle that match condition
func query_cells_in_rect(bounds: Rect2i, condition: Callable) -> Array[Vector2i]

# Returns array of cells in radius around center that are solid
func get_solid_cells_in_radius(center: Vector2i, radius_cells: int) -> Array[Vector2i]

# Returns the nearest empty cell to target (for spawn placement)
func find_nearest_empty_cell(target: Vector2i, max_search_radius: int) -> Vector2i
```

**Lookup behavior rules:**

1. All lookup methods return immediately for loaded chunks
2. Lookup on unloaded chunks returns default/null — caller must handle unloaded state
3. Lookup methods are thread-safe for read operations — no mutex needed
4. Lookup methods do not trigger chunk loading — caller must ensure chunk is loaded
5. `is_cell_solid` is the primary collision check for physics systems — optimized path

#### 5. Tile Modification API

**Primary modification methods:**

```gdscript
# Sets tile at cell on specified layer. Returns true if successful.
func set_tile(cell: Vector2i, layer: int, tile_type_id: int, variant: int = 0) -> bool

# Clears tile at cell on specified layer. Returns true if cell was occupied.
func clear_tile(cell: Vector2i, layer: int) -> bool

# Applies damage to tile at cell. Returns damage_result dictionary.
func apply_damage(cell: Vector2i, layer: int, damage_amount: float, source: int) -> Dictionary

# Repairs tile at cell. Returns true if repair successful.
func repair_tile(cell: Vector2i, layer: int, repair_amount: float) -> bool
```

**Modification result dictionary:**

| Key | Type | Description |
|-----|------|-------------|
| `success` | bool | Whether modification completed |
| `tile_destroyed` | bool | Whether tile was destroyed by this damage |
| `remaining_damage` | float | Damage leftover if tile destroyed early |
| `resource_spawned` | Array | Resource IDs spawned if tile destroyed |
| `failure_reason` | String | Reason if success=false (e.g., "indestructible", "chunk_unloaded") |

**Modification validation rules:**

1. `set_tile` on layer 0 (background) always fails — background is immutable
2. `set_tile` on layer 1 (terrain_base) always fails — terrain is dig-only, not placeable
3. `set_tile` on layer 2 (structures) requires placement validation (see below)
4. `set_tile` on layer 3 (platforms) requires support validation (see below)
5. `set_tile` on layer 4 (overlay) is restricted to system calls only — rejects player-initiated calls
6. `clear_tile` follows same layer rules as `set_tile` for layer validity
7. All modification methods fail silently if chunk is unloaded — caller must ensure chunk loaded

**Structure placement validation (layer 2):**

```gdscript
func can_place_structure(cell: Vector2i, tile_type_id: int) -> bool:
    # Rule 1: Cell must be empty on layer 2
    if is_cell_occupied(cell, 2): return false
    
    # Rule 2: Adjacent cells must have solid foundation
    var adjacent = [cell + Vector2i.UP, cell + Vector2i.DOWN, cell + Vector2i.LEFT, cell + Vector2i.RIGHT]
    var has_foundation = false
    for adj in adjacent:
        if is_cell_solid(adj): has_foundation = true
    
    if not has_foundation: return false
    
    # Rule 3: Tile type must have buildability flag (custom_data_4 == 1)
    var tile_data = TileSetResource.get_tile_data(tile_type_id)
    if tile_data.get_custom_data("buildable") != 1: return false
    
    return true
```

**Platform placement validation (layer 3):**

```gdscript
func can_place_platform(cell: Vector2i, tile_type_id: int) -> bool:
    # Rule 1: Cell must be empty on layer 3
    if is_cell_occupied(cell, 3): return false
    
    # Rule 2: Must have support from below or side
    var below = cell + Vector2i.DOWN
    var sides = [cell + Vector2i.LEFT, cell + Vector2i.RIGHT]
    
    var has_support = false
    if is_cell_solid(below): has_support = true
    for side in sides:
        if is_cell_occupied(side, 2) or is_cell_occupied(side, 3): has_support = true
    
    if not has_support: return false
    
    return true
```

**Batch modification methods:**

```gdscript
# Sets tiles in a rectangular area. Returns count of successful placements.
func fill_rect(bounds: Rect2i, layer: int, tile_type_id: int) -> int

# Clears all tiles in a rectangular area on specified layer. Returns count cleared.
func clear_rect(bounds: Rect2i, layer: int) -> int

# Batch damage application. Returns array of result dictionaries.
func apply_damage_batch(cells: Array[Vector2i], layer: int, damage: float, source: int) -> Array[Dictionary]
```

**Batch modification rules:**

1. Batch operations skip invalid cells silently — do not abort on single failure
2. Batch operations are atomic for chunk consistency — all modifications in one chunk commit together
3. Batch operations trigger single visual update — no per-cell refresh
4. Batch operations do not spawn resources individually — resources collected and spawned at batch end

#### 6. Collision Provision

**Collision shape definition:**

- All collision tiles use rectangular collision polygons defined in TileSet
- Full collision tiles: 32x32 rectangle, origin at (0, 0)
- Platform tiles: 32x8 rectangle at top of cell, origin at (0, -12)

**Collision layer bit assignment:**

| Physics Layer | Bit Index | Name | Used By |
|---------------|-----------|------|---------|
| `COLLISION_TERRAIN` | 1 | Natural terrain | Battle wagon, enemies, projectiles |
| `COLLISION_STRUCTURE` | 2 | Player-built structures | Battle wagon, enemies, projectiles |
| `COLLISION_PLATFORM` | 3 | Platforms, scaffolds | Player character, walking enemies |

**Collision query API:**

```gdscript
# Returns true if world position is inside a solid tile collision shape
func is_position_solid(world_pos: Vector2) -> bool

# Returns the first solid tile intersecting a line segment (for projectiles)
func raycast_tile_collision(start: Vector2, end: Vector2) -> Dictionary

# Returns all tiles intersecting a rectangle (for vehicle collision)
func get_tiles_in_rect(world_rect: Rect2) -> Array[Dictionary]
```

**Raycast result dictionary:**

| Key | Type | Description |
|-----|------|-------------|
| `hit` | bool | Whether collision was found |
| `cell` | Vector2i | Cell of collision tile |
| `layer` | int | Layer of collision tile |
| `tile_type` | int | Tile type ID |
| `collision_point` | Vector2 | World position of collision |
| `collision_normal` | Vector2 | Normal vector at collision surface |

**Godot integration:**

1. TileMap node `collision_layer` is set to bits 1 + 2 + 3 (all terrain collision)
2. TileMap node `collision_mask` is set to 0 (TileMap does not detect collisions, only provides)
3. PhysicsBody2D nodes query TileMap collision via `TileMapWorld` API, not Godot direct collision
4. Godot PhysicsDirectSpaceState2D can query TileMap collision shapes directly via `intersect_point`
5. For performance, physics bodies should use `TileMapWorld.is_cell_solid(cell)` for broad phase

**Collision response rule:**

- TileMap collision is static — collision shapes do not move
- Dynamic collision (moving enemies, projectiles) uses PhysicsBody2D nodes
- PhysicsBody2D vs TileMap collision is handled by Godot physics engine
- TileMap does not receive collision callbacks — only provides collision geometry

**Collision optimization rules:**

1. Broad phase: Check `is_cell_solid(cell)` before detailed collision query
2. Vehicle collision: Use `get_tiles_in_rect(vehicle_bounds)` for area query
3. Projectile collision: Use `raycast_tile_collision` for line-of-travel check
4. Movement collision: Check cells along movement path, not continuous physics
5. Collision queries cache results for 1 frame — repeated queries same frame return cached value

### States and Transitions

#### Tile Lifecycle States

Each tile in the TileMap has a lifecycle state that determines its behavior and visual representation.

| State | Condition | Visual Representation | Behavior |
|-------|-----------|----------------------|----------|
| `INTACT` | `damage_accumulated == 0` | Normal tile texture | Full collision, normal hardness |
| `DAMAGED` | `damage_accumulated > 0 AND damage_accumulated < hardness` | Damage overlay (cracks, chips) | Full collision, reduced effectiveness on next damage |
| `CRITICAL` | `damage_accumulated >= hardness * 0.8` | Heavy damage overlay (gaps, fissures) | Full collision, imminent destruction |
| `DESTROYED` | `damage_accumulated >= hardness` | Tile erased, debris particles spawn | No collision, cell becomes empty |

**State transition rules:**

1. `INTACT → DAMAGED`: When `apply_damage()` first succeeds on a tile
2. `DAMAGED → CRITICAL`: When `damage_accumulated` crosses 80% of `hardness`
3. `CRITICAL → DESTROYED`: When `damage_accumulated >= hardness`
4. `DAMAGED → INTACT`: When `repair_tile()` restores damage to 0
5. `CRITICAL → INTACT`: When `repair_tile()` restores damage to 0
6. No other transitions are valid — tiles cannot skip states

**State persistence:**

- Tile state persists across chunk unload/load for modified tiles
- DESTROYED state is permanent — tile cannot be restored, cell is empty
- Runtime state dictionary entry is removed when tile reaches DESTROYED

#### Chunk Loading States

Each chunk in the world has a loading state that determines whether its tiles are accessible.

| State | Condition | Tiles Accessible | Behavior |
|-------|-----------|------------------|----------|
| `UNLOADED` | Chunk not in memory | No — queries return null | Data on disk or not generated |
| `LOADING` | Chunk being deserialized | No — queries blocked | Transition state, brief duration |
| `ACTIVE` | Chunk loaded, entity nearby | Yes — all queries valid | Normal operation |
| `FROZEN` | Chunk loaded, no nearby entities | Yes — read-only | Cached, awaiting unload check |
| `UNLOADING` | Chunk being serialized | No — queries blocked | Transition to UNLOADED |

**State transition rules:**

1. `UNLOADED → LOADING`: When entity enters 2-chunk radius
2. `LOADING → ACTIVE`: When chunk data fully loaded
3. `ACTIVE → FROZEN`: When no entity within 3-chunk radius for 5 seconds
4. `FROZEN → ACTIVE`: When entity re-enters 2-chunk radius
5. `FROZEN → UNLOADING`: When no entity within 3-chunk radius for 30 seconds
6. `UNLOADING → UNLOADED`: When chunk data fully serialized
7. No other transitions are valid — chunks cannot skip LOADING/UNLOADING

**Chunk state during gameplay:**

- Battle wagon movement triggers chunk loading proactively (predictive loading based on velocity)
- Zombie tide spawns trigger chunk loading for defense area
- Player-built modifications in FROZEN chunks remain accessible for placement validation

### Interactions with Other Systems

This section details the specific data interfaces between TileMap世界系统 and each downstream consumer. For each system, we define: what TileMap provides, what the consumer calls, and the timing/context of interaction.

#### 方块碰撞系统

**Data TileMap provides:**
- Collision layer bit assignments (COLLISION_TERRAIN, COLLISION_STRUCTURE, COLLISION_PLATFORM)
- Tile collision shapes via Godot TileMap physics integration
- `is_cell_solid(cell)` for broad-phase collision check

**Consumer calls:**
- `is_cell_solid(cell)` — before detailed physics collision
- `get_collision_tile(cell)` — for collision response (damage to tile, bounce angle)
- `raycast_tile_collision(start, end)` — for line-based collision (projectiles, laser weapons)

**Interaction timing:**
- Every physics frame for continuous collision (battle wagon, walking enemies)
- Per-shot for projectile collision
- Per-tick for continuous damage sources (acid spray, fire)

**Interface contract:**
- TileMap guarantees collision query returns in <0.1ms for loaded chunks
- Collision consumer handles null results for unloaded chunks (treat as empty)

#### 方块挖掘系统

**Data TileMap provides:**
- Tile hardness (`custom_data_0`) for each terrain tile
- Tile destructibility flag (`custom_data_1`)
- Resource output type and quantity (`custom_data_2`, `custom_data_3`)
- Runtime damage state (`damage_accumulated`)

**Consumer calls:**
- `get_tile_hardness(cell)` — before each damage application
- `get_tile_custom_data(cell, layer, 1)` — check destructibility
- `apply_damage(cell, layer_1, damage_amount, source=1)` — apply dig tool damage
- `get_tile_custom_data(cell, layer, 2)` — get resource type if tile destroyed
- `get_tile_custom_data(cell, layer, 3)` — get resource quantity multiplier

**Interaction timing:**
- Per-dig-action (player holds dig button, damage applied per tick)
- Rate depends on dig tool power (defined in separate system)

**Interface contract:**
- TileMap returns hardness 255 for indestructible tiles — digging system must handle (no damage applied)
- TileMap spawns resources on destruction — digging system receives resource IDs, not actual items
- TileMap updates visual damage state — digging system does not manage visuals

#### 方块放置系统

**Data TileMap provides:**
- Cell occupancy status for all layers
- Placement validation API (`can_place_structure`, `can_place_platform`)
- Foundation requirement check (adjacent solid tiles)

**Consumer calls:**
- `is_cell_occupied(cell, layer)` — check if placement target is empty
- `can_place_structure(cell, tile_type_id)` — validate structure placement
- `can_place_platform(cell, tile_type_id)` — validate platform placement
- `set_tile(cell, layer_2, tile_type_id)` — place structure
- `set_tile(cell, layer_3, tile_type_id)` — place platform
- `is_cell_solid(adjacent_cells)` — check foundation support

**Interaction timing:**
- Per-placement-action (player clicks place button)
- Batch placement for multi-cell structures (turrets, facilities)

**Interface contract:**
- TileMap rejects placement if validation fails — placement system must handle rejection (show feedback)
- TileMap does not consume resources — placement system must deduct materials before calling set_tile
- TileMap does not provide placement preview — placement system manages preview overlay

#### 战车驾驶系统

**Data TileMap provides:**
- World-to-cell coordinate conversion
- Collision geometry for vehicle movement
- Solid cell detection for movement blocking

**Consumer calls:**
- `world_to_cell(vehicle_position)` — convert position to cell for collision check
- `is_cell_solid(cell)` — broad-phase collision check for movement direction
- `get_tiles_in_rect(vehicle_bounds)` — area collision for vehicle body
- `cell_to_world_center(cell)` — snap vehicle to cell if needed

**Interaction timing:**
- Every physics frame during vehicle movement
- Per-frame rate: collision check at vehicle velocity update rate

**Interface contract:**
- TileMap collision is static — vehicle system handles dynamic collision response (bounce, stop)
- TileMap does not apply damage to vehicle from collision — vehicle system manages collision damage
- TileMap guarantees cell conversion is deterministic — same world position always maps to same cell

#### 探索区域系统

**Data TileMap provides:**
- Cell boundaries for region definition
- Cell occupancy for area traversal validation
- Query cells in rect for area scanning

**Consumer calls:**
- `query_cells_in_rect(region_bounds, condition)` — scan region for features
- `is_cell_occupied(cell, layer)` — check if cell has specific tile type
- `world_to_cell(world_pos)` — convert exploration marker to cell

**Interaction timing:**
- On region initialization (load area definition)
- On area change trigger (player enters new region)

**Interface contract:**
- TileMap does not define regions — exploration system defines boundaries, TileMap provides cell grid
- TileMap queries are read-only — exploration system does not modify tiles

#### 敌人生成系统

**Data TileMap provides:**
- Valid spawn position detection (empty cells)
- Solid cell detection for spawn avoidance
- Cell coordinate system for spawn position

**Consumer calls:**
- `find_nearest_empty_cell(target, max_radius)` — find valid spawn location
- `is_cell_solid(cell)` — verify spawn position is not inside wall
- `cell_to_world_center(cell)` — convert spawn cell to world position

**Interaction timing:**
- Per-enemy-spawn (zombie tide wave, patrol spawn)
- Batch spawn for zombie tide (multiple enemies per wave)

**Interface contract:**
- TileMap does not spawn enemies — enemy spawn system receives cell, spawns entity at world position
- TileMap does not track spawned entities — enemy spawn system manages entity lifecycle
- TileMap may return null for unloaded chunks — spawn system must handle (delay spawn or pick alternate location)

#### 炮塔系统

**Data TileMap provides:**
- Placement validation for turret structures
- Foundation check (solid tile below)
- Cell occupancy for turret position

**Consumer calls:**
- `can_place_structure(cell, turret_tile_id)` — validate turret placement
- `is_cell_solid(cell + Vector2i.DOWN)` — check foundation below turret
- `set_tile(cell, layer_2, turret_tile_id)` — place turret tile
- `is_cell_occupied(cell, layer_2)` — check if turret exists at position
- `clear_tile(cell, layer_2)` — remove destroyed turret

**Interaction timing:**
- Per-turret-placement (player builds turret)
- Per-turret-destruction (turret destroyed by enemy)
- Per-targeting-frame (turret queries line of sight)

**Interface contract:**
- TileMap places turret tile — turret system manages turret entity (weapon logic, targeting)
- TileMap tracks turret tile — turret system tracks turret entity, must synchronize on destruction
- TileMap provides collision for turret — enemies collide with turret tile, turret system handles damage

#### 地堡设施系统

**Data TileMap provides:**
- Multi-cell placement validation for facilities
- Foundation check for large structures
- Cell occupancy for facility footprint

**Consumer calls:**
- `fill_rect(facility_bounds, layer_2, facility_tile_id)` — place facility footprint
- `is_cell_occupied(cell, layer)` — check facility presence
- `query_cells_in_rect(facility_bounds, condition)` — verify all cells empty before placement
- `clear_rect(facility_bounds, layer_2)` — remove facility

**Interaction timing:**
- Per-facility-placement (player builds facility)
- Per-facility-destruction (facility destroyed or dismantled)

**Interface contract:**
- TileMap places facility tiles — facility system manages facility logic (production, storage)
- TileMap does not define facility function — facility system maps tile type to facility behavior
- TileMap provides facility footprint — facility system must handle multi-cell logic

#### 雨水收集系统

**Data TileMap provides:**
- Cell coordinates for collector coverage area
- Cell occupancy for collector placement
- Cell-to-world conversion for rain simulation

**Consumer calls:**
- `query_cells_in_rect(collector_bounds, condition)` — scan coverage area
- `world_to_cell(rain_drop_position)` — map rain to cell
- `cell_to_world_center(cell)` — position collector visuals

**Interaction timing:**
- Per-frame during rain weather (rain drops fall)
- Per-collector-placement (player builds collector)

**Interface contract:**
- TileMap does not simulate rain — rain system manages weather, TileMap provides spatial grid
- TileMap does not store water — rain system manages water storage, TileMap provides position

#### 种田系统

**Data TileMap provides:**
- Cell boundaries for farm plot definition
- Cell occupancy for plot placement
- Cell coordinate system for crop positioning

**Consumer calls:**
- `fill_rect(plot_bounds, layer_2, soil_tile_id)` — place farm plot soil
- `is_cell_occupied(cell, layer_2)` — check if plot exists
- `set_tile(cell, layer_4, crop_marker_id)` — place crop overlay marker
- `clear_tile(cell, layer_4)` — remove harvested crop marker
- `query_cells_in_rect(plot_bounds, condition)` — scan all crops in plot

**Interaction timing:**
- Per-plot-placement (player designates farm area)
- Per-crop-stage (crop grows, overlay marker updates)
- Per-harvest (player harvests, overlay marker removed)

**Interface contract:**
- TileMap provides cell grid — farming system manages crop logic (growth stages, harvest yield)
- TileMap overlay layer is transient — farming system updates overlay markers, TileMap does not persist them
- TileMap does not store crop state — farming system manages crop lifecycle data

## Formulas

### 1. Damage Accumulation Formula

The `damage_accumulation` formula defines how damage from multiple sources accumulates toward tile destruction, handling overflow for piercing attacks and ensuring consistent damage accounting.

```
damage_accumulated_new = min(damage_accumulated_old + damage_amount, hardness)

overflow_damage = max(0, damage_accumulated_old + damage_amount - hardness)

effective_damage = min(damage_amount, hardness - damage_accumulated_old)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `damage_accumulated_old` | D_old | float | 0.0 – hardness | Current accumulated damage before this hit |
| `damage_accumulated_new` | D_new | float | 0.0 – hardness | Accumulated damage after this hit (clamped) |
| `damage_amount` | D_in | float | 0.0 – ∞ | Damage applied by this action (from caller) |
| `hardness` | H | int | 1 – 255 | Tile hardness value (custom_data_0) |
| `overflow_damage` | D_overflow | float | 0.0 – ∞ | Excess damage after tile destroyed |
| `effective_damage` | D_eff | float | 0.0 – hardness | Actual damage contributed toward destruction |

**Output Range:** `damage_accumulated_new`: 0.0 to H (hardness value)
**Overflow Range:** 0.0 to potentially large values for high-damage attacks

**Example:**
```
Tile: Stone wall (hardness = 100)
Before hit: damage_accumulated_old = 60
Incoming damage: damage_amount = 50 (pickaxe strike)

damage_accumulated_new = min(60 + 50, 100) = 100  (tile destroyed)
overflow_damage = max(0, 60 + 50 - 100) = 10
effective_damage = min(50, 100 - 60) = 40

Result: Tile destroyed with 10 overflow damage (lost, no carryover to adjacent tile in this system)
```

**Overflow handling rule:**
- Overflow damage is NOT carried to adjacent tiles by default
- Overflow is returned in the `remaining_damage` field of the result dictionary
- Caller (digging system, projectile system) may choose to apply overflow elsewhere (e.g., projectile continues through destroyed tile)

---

### 2. State Transition Threshold Formula

The `tile_state` formula determines the visual and behavioral state of a tile based on damage accumulation relative to hardness.

```
tile_state = 
    INTACT      if damage_accumulated == 0
    DAMAGED     if 0 < damage_accumulated < H * threshold_critical
    CRITICAL    if damage_accumulated >= H * threshold_critical AND damage_accumulated < H
    DESTROYED   if damage_accumulated >= H

damage_ratio = damage_accumulated / hardness

threshold_critical = 0.8 (default, tunable)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `damage_accumulated` | D | float | 0.0 – H | Current accumulated damage |
| `hardness` | H | int | 1 – 255 | Tile hardness value (custom_data_0) |
| `damage_ratio` | R_d | float | 0.0 – 1.0 | Damage as proportion of hardness |
| `threshold_critical` | T_crit | float | 0.5 – 0.95 | Damage ratio at which CRITICAL state begins |
| `tile_state` | S | enum | INTACT/DAMAGED/CRITICAL/DESTROYED | Current tile lifecycle state |

**Output Range:** 4 discrete states (INTACT, DAMAGED, CRITICAL, DESTROYED)
**Default Threshold:** T_crit = 0.8 (tile enters CRITICAL at 80% damage)

**Example:**
```
Tile: Reinforced concrete (hardness = 180)
Current damage: damage_accumulated = 140

damage_ratio = 140 / 180 = 0.778 (77.8%)
threshold_critical = 0.8

tile_state = DAMAGED (since 0 < 140 < 180 * 0.8 = 144)

Result: Tile shows crack overlay, normal collision, next hit may push to CRITICAL
```

**State-specific behavior:**

| State | Visual | Collision | Audio Hint | Special Behavior |
|-------|--------|-----------|------------|------------------|
| INTACT | Normal texture | Full | None | None |
| DAMAGED | Crack overlay (alpha = R_d * 0.5) | Full | Light crackle on hit | None |
| CRITICAL | Heavy crack (alpha = 0.7), fissures visible | Full but permeable | Loud warning sound | 20% chance debris falls on next hit |
| DESTROYED | Tile removed, debris particles | None | Destruction sound | Resources spawned |

---

### 3. Chunk Loading Priority Formula

When multiple entities trigger chunk loading simultaneously, the `chunk_priority` formula determines loading order to minimize player-facing latency.

```
chunk_priority_score = 
    entity_priority * 1000 
    - distance_cells_to_entity * priority_distance_weight
    + chunk_urgency_bonus

chunk_priority_score越高 = 优先级越高 (load first)

priority_distance_weight = 10 (default)
chunk_urgency_bonus = 
    500 if chunk_contains_player_modifications
    200 if chunk_in_entity_velocity_path
    0 otherwise
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `entity_priority` | P_e | int | 1 – 10 | Entity type priority (player highest) |
| `distance_cells_to_entity` | D_c | int | 0 – 64 | Manhattan distance in cells to nearest triggering entity |
| `priority_distance_weight` | W_d | int | 5 – 20 | Weight applied to distance penalty |
| `chunk_urgency_bonus` | B_u | int | 0 – 500 | Bonus for modified chunks or predicted path |
| `chunk_priority_score` | S_p | int | 0 – 10500 | Final priority score (higher = load first) |

**Entity Priority Values:**

| Entity Type | P_e Value | Reason |
|-------------|-----------|--------|
| Battle wagon (player) | 10 | Player experience critical |
| Player character | 10 | Player experience critical |
| Active turret | 7 | Defensive structure, needs collision |
| Active enemy (targeting) | 6 | Combat requires loaded chunks |
| Projectile in flight | 5 | Projectile path needs collision data |
| Idle enemy (patrol) | 3 | Background activity |
| Ambient entity | 1 | Non-critical |

**Output Range:** 0 to 10500 (integer priority score)
**Higher score = Load first**

**Example:**
```
Scenario: Battle wagon at chunk (10, 10), moving east at velocity 8 cells/sec
Chunks needing load: (11, 10), (12, 10), (11, 9), (11, 11)

Chunk (11, 10):
- entity_priority = 10 (player wagon)
- distance_cells = 32 (1 chunk away = 32 cells)
- chunk_urgency_bonus = 200 (in velocity path, wagon moving east)
- priority_distance_weight = 10
- score = 10 * 1000 - 32 * 10 + 200 = 10000 - 320 + 200 = 9880

Chunk (12, 10):
- entity_priority = 10
- distance_cells = 64 (2 chunks away)
- chunk_urgency_bonus = 200 (in velocity path, predicted need)
- score = 10 * 1000 - 64 * 10 + 200 = 10000 - 640 + 200 = 9560

Chunk (11, 9) [adjacent but not in path]:
- entity_priority = 10
- distance_cells = 33 (diagonal)
- chunk_urgency_bonus = 0 (not in velocity path)
- score = 10 * 1000 - 33 * 10 + 0 = 10000 - 330 = 9670

Loading order: (11, 10) → (11, 9) → (12, 10)
```

**Velocity path prediction rule:**
- If entity velocity > 2 cells/sec, chunks in velocity direction get +200 urgency
- Predicted path extends 3 chunks ahead based on velocity direction
- Velocity prediction updated every 0.5 seconds

---

### 4. Chunk Unload Timer Formula

The `chunk_unload_timer` formula determines when chunks transition from FROZEN to UNLOADING after no entities remain nearby.

```
unload_timer_remaining = 
    max(0, unload_timer_duration - time_since_last_entity_exit)

time_since_last_entity_exit = current_time - last_entity_proximity_time

unload_timer_duration = 30.0 seconds (default, tunable)

timer_reset_condition = 
    any_entity within unload_check_radius (3 chunks)

unload_check_radius = 3 chunks = 96 cells
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `unload_timer_duration` | T_unload | float | 10.0 – 60.0 | Maximum seconds before forced unload |
| `unload_timer_remaining` | T_rem | float | 0.0 – T_unload | Remaining time before unload triggers |
| `time_since_last_entity_exit` | T_elapsed | float | 0.0 – ∞ | Seconds since last entity left radius |
| `current_time` | t_now | float | ∞ | Current game time in seconds |
| `last_entity_proximity_time` | t_last | float | ∞ | Time when last entity was in radius |
| `unload_check_radius` | R_unload | int | 2 – 5 | Chunk radius for unload trigger check |

**Per-chunk timer state:**

| Timer State | Condition | Action |
|-------------|-----------|--------|
| `NOT_STARTED` | Entity in 2-chunk load radius | No countdown, chunk ACTIVE |
| `COUNTING` | No entity in 3-chunk radius, T_elapsed < T_unload | Countdown active, chunk FROZEN |
| `READY_TO_UNLOAD` | T_elapsed >= T_unload | Trigger UNLOADING transition |
| `RESET` | Entity re-enters 3-chunk radius | Timer reset to T_unload, chunk ACTIVE |

**Output Range:** Timer countdown from 30.0s to 0.0s
**Trigger:** Unload when timer reaches 0.0s

**Example:**
```
Chunk (15, 20) timeline:
t=0s: Player wagon enters 2-chunk radius → chunk loads, timer NOT_STARTED
t=45s: Player wagon leaves 3-chunk radius → timer starts COUNTING at T_rem = 30.0s
t=50s: T_elapsed = 5s → T_rem = 30.0 - 5.0 = 25.0s remaining
t=60s: Enemy spawns near chunk (in 3-chunk radius) → timer RESET to 30.0s
t=65s: Enemy killed, no entities nearby → timer COUNTING again
t=95s: T_elapsed = 30.0s → T_rem = 0.0s → UNLOADING triggered
t=97s: Chunk serialized and UNLOADED
```

**Timer persistence rule:**
- Timer state persists across FROZEN → ACTIVE → FROZEN cycles
- If entity re-enters during countdown, timer resets to full duration (no partial save)
- Modified chunks get +10 second bonus to timer (player-built structures protected longer)

**Modified chunk bonus:**
```
unload_timer_duration_modified = unload_timer_duration + modification_bonus

modification_bonus = 
    10.0 if chunk.has_modifications == true
    0.0 otherwise
```

---

### 5. Resource Output Formula

When a tile is destroyed, the `resource_spawn` formula determines what and how many resources spawn at the tile location.

```
resource_quantity = 
    floor(base_quantity * quantity_multiplier * random_factor)

random_factor = randf_range(0.8, 1.2)  [uniform distribution]

base_quantity = 
    1 if resource_type <= 100 (common resources)
    2 if resource_type in 101-200 (uncommon resources)
    3 if resource_type in 201-300 (rare resources)
    5 if resource_type > 300 (precious resources)

quantity_multiplier = custom_data_3 (from TileData)

spawn_positions = 
    [cell_center] for quantity 1-2
    [cell_center + spread_offsets] for quantity 3+  [spread within 16px radius]
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `resource_type` | R_id | int | 0 – 65535 | Resource database ID (custom_data_2) |
| `base_quantity` | Q_base | int | 1 – 5 | Base drop count by resource tier |
| `quantity_multiplier` | M_q | float | 0.5 – 10.0 | Tile-specific multiplier (custom_data_3) |
| `random_factor` | F_rand | float | 0.8 – 1.2 | Random variance per destruction |
| `resource_quantity` | Q_final | int | 0 – 60 | Final count of resources to spawn |
| `spawn_position` | P_spawn | Vector2 | World coords | Where resource entity spawns |

**Resource Tier Mapping:**

| Resource Type ID Range | Tier | Q_base | Example Resources |
|------------------------|------|--------|-------------------|
| 0 | None | 0 | No resource (empty drop) |
| 1 – 100 | Common | 1 | Stone, dirt, wood scraps |
| 101 – 200 | Uncommon | 2 | Iron ore, copper, sand |
| 201 – 300 | Rare | 3 | Gold ore, crystal shards, magitech components |
| 301+ | Precious | 5 | Ancient artifacts, rare gems, legendary materials |

**Output Range:** 0 to 60 resources per tile destruction
**Spawn delay:** Resources spawn 0.2s after tile destruction (visual gap for debris)

**Example:**
```
Tile: Gold ore vein (resource_type = 250, tier Rare)
custom_data_2 = 250 (gold ore ID)
custom_data_3 = 1.5 (rich vein multiplier)

base_quantity = 3 (Rare tier)
quantity_multiplier = 1.5
random_factor = randf_range(0.8, 1.2) → assume 1.05 this roll

resource_quantity = floor(3 * 1.5 * 1.05) = floor(4.725) = 4

Result: 4 gold ore items spawn at tile position + random offsets within 16px
```

**Special resource rules:**

1. **Zero-resource tiles**: If `custom_data_2 == 0`, no resources spawn (empty drop)
2. **Indestructible tiles**: Never spawn resources (cannot be destroyed)
3. **Multi-layer destruction**: Resources spawn from the destroyed layer only (not all layers at cell)
4. **Batch destruction**: Resources collected and spawned at batch center (not per-cell)
5. **Tool bonus**: External system may apply tool multiplier — TileMap formula is base only

**Spread offset calculation:**
```
spread_offsets = [
    Vector2(randf_range(-16, 16), randf_range(-16, 16))
    for each resource in range(Q_final)
]

# Ensure no overlap: offsets recalculated if distance between any two < 8px
```

---

### Formula Summary Table

| Formula | Primary Output | Key Inputs | Tunable Parameter |
|---------|---------------|------------|-------------------|
| Damage Accumulation | `damage_accumulated_new` | D_in, H | None (linear) |
| State Transition | `tile_state` | D, H | `threshold_critical` (0.5-0.95) |
| Chunk Priority | `chunk_priority_score` | P_e, D_c | `priority_distance_weight` (5-20) |
| Unload Timer | `unload_timer_remaining` | T_elapsed | `unload_timer_duration` (10-60s) |
| Resource Output | `resource_quantity` | R_id, M_q | `random_factor` range (0.7-1.3) |

## Edge Cases

### Boundary Conditions

- **If tile hardness is 0**: Tile is destroyed by any non-zero damage immediately. Damage-percentage calculations must handle division-by-zero gracefully (return 100% damage ratio).
- **If damage value is 0**: State remains unchanged. No state recalculation, no event dispatch, no visual update — zero-damage calls are ignored.
- **If accumulated damage exactly equals hardness**: Tile reaches DESTROYED state immediately. No "one more hit" requirement — equality triggers destruction.
- **If entity queries tile at negative world coordinates**: Return null/air tile, not exception. World-to-chunk mapping must handle negative indices correctly.
- **If entity queries tile at `int.MaxValue` coordinates**: Math overflow in chunk index calculation. Clamp query to valid world bounds (-1000 to 1000 cells) before processing.
- **If code attempts to set tile on layer -1 or layer 5**: Validation rejects with `failure_reason = "invalid_layer"`. Layer index validated before array access.
- **If tile hardness is 3 and damage is 2 (66.67%)**: Tile is DAMAGED. One more damage (total=3) → DESTROYED. CRITICAL state is skipped for low-hardness tiles. This is intended — CRITICAL requires ≥80% threshold.

### Simultaneous Events

- **If two damage sources apply to same tile in same frame**: Damage is queued and processed at end-of-frame in order of receipt. No race condition — batch processing ensures atomic accumulation.
- **If accumulated damage causes state skip (INTACT → DESTROYED)**: Intermediate state events (DAMAGED, CRITICAL) are emitted even if skipped, for statistics and listeners. Event queue ensures all transitions fire.
- **If same chunk is requested to load twice in one frame**: Idempotent load — only one chunk instance created. Duplicate requests are ignored.
- **If chunk load fails (disk error, corrupted data)**: Chunk is populated with empty/default tiles and flagged as "error state". Game continues with placeholder terrain; error logged for repair.
- **If multiple entities trigger load for same chunk simultaneously**: Thread-safe chunk dictionary ensures single instance. Lock-free atomic check-and-create pattern.

### Timing Conflicts

- **If chunk unload timer completes while tile modification is in progress**: Modification lock flag prevents unload during active writes. Unload deferred until lock released.
- **If entity enters chunk boundary exactly as 30s timer expires**: Unload checks for nearby entities after timer expiry, not before. Entity proximity resets timer immediately.
- **If tile reaches CRITICAL and receives additional damage in same frame**: DESTROYED transition queued after CRITICAL visual/audio effects complete. Minimum 0.5s delay for CRITICAL feedback.
- **If chunk is unloaded while tiles are in DAMAGED/CRITICAL state**: On reload, tile damage state persists in saved chunk data. No "repair by unload/reload" exploit.

### Player Unintended Interactions

- **If player damages tile to exactly CRITICAL threshold and stops**: Tile remains CRITICAL indefinitely with no decay. Pre-damage strategy is allowed — not an exploit, emergent gameplay.
- **If player discovers tiles with hardness 1**: Instant destruction intended for specific weak materials (sand, loose dirt). Not a balance issue.
- **If player repeatedly crosses chunk boundary without entering 30s safe radius**: Load/unload cycling prevented by edge-proximity check for boundary chunks, not center-only.
- **If player places entity exactly at chunk boundary**: Entity registered to the chunk containing its center point. No duplicate registration, no missed updates.
- **If resource spawn has deterministic RNG seeded by position**: Intended — consistent drops per tile type. No farming exploit, resources are per-tile-type, not per-instance.
- **If destruction of multi-tile structure spawns resources for each tile**: Intended — each tile has independent resource output. Building/destroying for resources costs materials, no infinite generation.
- **If overlay layer can block damage to underlying layers**: Overlay has no collision (layer 4). Damage passes through. No protective shield exploit.

### Data Integrity

- **If `get_tile_data()` returns null for loaded chunk**: Null means "air" (empty cell). Downstream code must handle null gracefully — treat as empty, not error.
- **If TileData has invalid state enum value (e.g., 99)**: Default to INTACT state. Invalid values logged, not crashed.
- **If chunk file has mismatched tile count**: Truncation handled — missing tiles filled with empty. Extra data ignored. Chunk validated on load.
- **If chunk version is older than current system**: Migration logic applies. Missing version defaults to oldest supported version, triggers migration.
- **If damage accumulation uses integer math**: Precision stable. No floating-point rounding errors. Use integer comparison for thresholds.
- **If unload timer uses `Time.get_ticks_msec()` (monotonic)**: Immune to system clock changes. Timer behavior consistent regardless of external clock.

## Dependencies

### Upstream Dependencies

None. TileMap世界系统 is a Foundation layer system with no upstream dependencies.

### Downstream Consumers (systems that depend on this)

| System | Direction | Nature of Dependency |
|--------|-----------|---------------------|
| 方块碰撞系统 | Collision depends on TileMap | Reads collision layer, queries `is_cell_solid()` for collision detection |
| 方块挖掘系统 | Digging depends on TileMap | Calls `apply_damage()` on terrain_base layer, reads `get_tile_hardness()` |
| 方块放置系统 | Placement depends on TileMap | Calls `set_tile()` on structures/platforms layers, uses placement validation |
| 战车驾驶系统 | Movement depends on TileMap | Queries `is_cell_solid()` for movement collision, uses `world_to_cell()` coordinate conversion |
| 探索区域系统 | Regions depend on TileMap | Defines region boundaries by cell coordinates, queries cells in rect |
| 敌人生成系统 | Spawning depends on TileMap | Uses `find_nearest_empty_cell()` for valid spawn positions |
| 炮塔系统 | Turrets depend on TileMap | Calls `set_tile()` for turret placement, queries `is_cell_solid()` for foundation check |
| 地堡设施系统 | Facilities depend on TileMap | Calls `set_tile()` for facility placement at cell positions |
| 雨水收集系统 | Collection depends on TileMap | Defines collector coverage by cell coordinates |
| 种田系统 | Farming depends on TileMap | Defines farm plot boundaries by cell coordinates, queries cell occupancy |

## Tuning Knobs

| Knob Name | Variable | Default | Range | Safe Range | What Breaks If Extreme |
|-----------|----------|---------|-------|------------|------------------------|
| `CELL_SIZE` | Cell pixel size | 32 | 16-64 | 24-40 | Below 24: visual detail too coarse for magitech aesthetic. Above 40: chunk density too low, memory overhead increases. |
| `CHUNK_SIZE` | Cells per chunk | 32 | 16-64 | 24-48 | Below 24: load/unload churn too frequent. Above 48: single-chunk memory footprint exceeds budget (48×48×1024 tiles ≈ 150KB). |
| `LOAD_RADIUS_CHUNKS` | Chunks to load around entity | 2 | 1-5 | 2-3 | Below 2: entity enters unloaded chunks, collision fails. Above 3: memory footprint exceeds budget during exploration. |
| `UNLOAD_RADIUS_CHUNKS` | Distance to trigger unload timer | 3 | 2-6 | 3-4 | Below 3: player sees chunks unload while still visible. Above 4: memory holds chunks too long after departure. |
| `UNLOAD_TIMER_SECONDS` | Delay before unload | 30 | 10-120 | 20-45 | Below 20: rapid load/unload cycling on boundary orbiting. Above 45: memory pressure during long sessions. |
| `THRESHOLD_CRITICAL` | Damage ratio for CRITICAL state | 0.8 | 0.5-0.95 | 0.7-0.85 | Below 0.7: CRITICAL too early, visual feedback dilutes. Above 0.85: CRITICAL nearly overlaps DESTROYED, no warning time. |
| `MAX_WORLD_BOUNDS` | World coordinate limit | 1000 | 500-5000 | 800-2000 | Below 800: exploration feels constrained. Above 2000: chunk dictionary memory exceeds 512MB budget. |
| `DAMAGE_BATCH_FRAME_LIMIT` | Max damage calls per frame | 100 | 50-500 | 75-200 | Below 75: large explosions stall (queued damage waits). Above 200: frame time exceeds 16.6ms budget during tide events. |
| `RESOURCE_RANDOM_FACTOR_MIN` | Minimum randomness multiplier | 0.8 | 0.5-1.0 | 0.7-0.9 | Below 0.7: drops feel consistently low, frustrating. Above 0.9: randomness range too narrow, feels deterministic. |
| `RESOURCE_RANDOM_FACTOR_MAX` | Maximum randomness multiplier | 1.2 | 1.0-1.5 | 1.1-1.3 | Below 1.1: no lucky drops, no excitement. Above 1.3: lucky drops too rare, feels unfair when others get them. |
| `PRIORITY_DISTANCE_WEIGHT` | Chunk priority score distance penalty | 10 | 5-20 | 8-15 | Below 8: distant chunks load equally, memory bloat. Above 15: distant chunks load too slowly, entity collision fails. |
| `VELOCITY_PREDICTION_BONUS` | Bonus for directional chunk loading | 200 | 0-500 | 100-300 | Below 100: no predictive loading, wagon enters unloaded terrain. Above 300: over-prediction loads unnecessary chunks. |

### Tuning Knob Interaction Matrix

| Knob A | Knob B | Interaction |
|--------|--------|-------------|
| `CELL_SIZE` | `CHUNK_SIZE` | Changing CELL_SIZE without adjusting CHUNK_SIZE changes chunk memory footprint (tiles per chunk = CHUNK_SIZE²). |
| `LOAD_RADIUS` | `UNLOAD_RADIUS` | UNLOAD_RADIUS must be ≥ LOAD_RADIUS + 1 to prevent immediate unload after load. |
| `UNLOAD_TIMER` | `VELOCITY_PREDICTION` | Fast-moving wagon needs longer unload timer; short timer + high velocity = chunks unload behind wagon while still visible. |
| `THRESHOLD_CRITICAL` | `DAMAGE_BATCH_LIMIT` | High CRITICAL threshold + low batch limit = CRITICAL state may never fire during rapid destruction. |

## Visual/Audio Requirements

### 1. Tile Appearance Per Layer

Each layer has distinct visual identity aligned with art bible principles and the Player Fantasy of "security through definition."

#### Layer 0: Background (Decoration Layer)

**Visual Purpose**: Environmental storytelling, depth perception, atmospheric mood-setting.

| Visual Property | Specification | Art Bible Alignment |
|----------------|---------------|---------------------|
| **Opacity** | 50% alpha blend | Creates distance illusion, supports mood atmosphere rules |
| **Texture Style** | Digital painting, coarse brush strokes | "概念美术质感而非真实材质" per art bible |
| **Color Temperature** | Cool-neutral (sky gray #4A5568 base) | "天空灰" per art bible, creates atmospheric depth |
| **Content Types** | Distant terrain silhouettes, environmental narrative elements | "视觉叙事元素" per art bible |
| **Weather Response** | Tinted by current weather filter | "天气交互叙事" core principle |

**Background Tile Categories**:

| Category | Visual Features | Narrative Purpose |
|----------|-----------------|-------------------|
| **Distant Ruins** | Faint building silhouettes, neon residue glow (霓虹蓝 #00D4FF, 30% opacity) | "末世崩溃时间" — sudden abandonment traces |
| **Horizon Elements** | Sky gradient, distant mountains, cloud formations | Atmospheric depth, weather integration |
| **Cave Background** | Rock texture patterns, mineral vein hints | Underground atmosphere, resource discovery hints |
| **Faction Infiltration Traces** | Faction-specific visual residue (虫族蜂巢纹, 克苏鲁触手阴影, 锈蚀机械轮廓) | "阵营入侵痕迹" — who came before |

**Technical Implementation**:
- Godot `CanvasItem.modulate` set to `Color(1.0, 1.0, 1.0, 0.5)` for alpha blend
- Weather filter applied via shader overlay (`weather_[type].gdshader`)
- No collision, no player interaction — purely decorative

---

#### Layer 1: Terrain Base (Natural Ground/Walls)

**Visual Purpose**: Indestructible world foundation, collision geometry provider, natural formation contrast against player-built structures.

| Visual Property | Specification | Art Bible Alignment |
|----------------|---------------|---------------------|
| **Opacity** | 100% solid | Primary visual layer, defines world geometry |
| **Texture Style** | Digital painting, rough brush strokes, natural erosion patterns | "废土美学" — surfaces show civilization collapse traces |
| **Color Temperature** | Per-area type (see Area Color Temperature Rules in art bible) | "锈色+天空灰" for surface, "秘银银+暖烛光" for shallow bunker |
| **Collision Visual** | Implicit — tile presence = collision boundary | "墙壁作为生存实体" — walls feel substantial |
| **Weather Response** | Surface layer affected by weather; underground unaffected | Weather system integration |

**Terrain Tile Categories**:

| Category | Visual Features | Color Palette | Player Fantasy Support |
|----------|-----------------|---------------|------------------------|
| **Surface Bedrock** | Solid rock texture, weathering marks, indestructible indicator (subtle rune glow) | 锈色 #8B4513 + 天空灰 #4A5568 | "不可撼动的世界边界" — defines permanent geography |
| **Cave Walls** | Natural rock formations, mineral deposits visible in cross-section, hardness indicated by texture density | 泥土色 + 秘银银残留 | "探索发现的回报" — visible resources hint at excavation rewards |
| **Deep Abyss Rock** | Twisted geometric patterns, 克苏鲁 influence (轻微触手纹理, 眼球图案痕迹) | 深渊紫黑 #1A0A2E + 腐烂绿 #556B2F | "深渊渗透" — terror escalation as player digs deeper |
| **Indestructible Core** | Dense material texture, faint magitech residue (符文金 #FFD700 残留), clear visual distinction from destructible | 秘银银 #B8C4CE enhanced | "安全边界确认" — player knows this won't break during defense |

**Natural vs Player-Built Visual Distinction**:
- Natural terrain has irregular edges, weathering patterns, organic decay traces
- Player-built structures (layer 2) have straight edges, uniform materials, magitech glow at joints
- This distinction supports "我如何生存" — player traces vs world traces

**Hardness Visual Indicator System**:
- Low hardness (1-50): Loose texture, visible gaps, sand/dirt appearance
- Medium hardness (51-100): Compact texture, moderate density, stone appearance
- High hardness (101-180): Dense texture, reinforced appearance, concrete/metal hints
- Maximum hardness (181-255): Solid glow indicators, indestructible rune traces, bedrock appearance

**Technical Implementation**:
- TileSet `tile_shape` = Rectangle (32x32)
- Collision polygon defined in TileSet, physics layer bit 1 (COLLISION_TERRAIN)
- Variant system for visual variety (0-255 variants per tile type)
- Shader for hardness indicator: subtle glow intensity = hardness / 255

---

#### Layer 2: Structures (Player-Built)

**Visual Purpose**: Tangible player ownership, survival achievements, defensive boundary — the core of "地下圣所的边界" fantasy.

| Visual Property | Specification | Art Bible Alignment |
|----------------|---------------|---------------------|
| **Opacity** | 100% solid | Player-built assets demand full visibility |
| **Texture Style** | Digital painting, refined brush strokes, clean manufactured edges | "赛博朋克魔导美学" — welded seams, reinforced panels, magitech glow |
| **Color Temperature** | 秘银银 #B8C4CE base + 霓虹蓝 #00D4FF structural glow | "玩家科技" per art bible faction palette |
| **Collision Visual** | Implicit + structural glow at collision edges | "墙壁作为生存实体" — weight when zombies pound |
| **Weather Response** | Structural glow adjusts intensity (暴风雨: enhanced glow for visibility) | Weather-aware visual feedback |

**Structure Tile Categories**:

| Category | Visual Features | Color Palette | Player Fantasy Support |
|----------|-----------------|---------------|------------------------|
| **Basic Wall** | Welded seam patterns, reinforced concrete texture, subtle 霓虹蓝 glow at joints | 秘银银 base + 霓虹蓝 joint glow | "基础防御边界" — first line of survival |
| **Reinforced Wall** | Thicker texture, layered material appearance, enhanced 霓虹蓝 circuit patterns, 魔导符文刻蚀 | 秘银银 + 霓虹蓝 enhanced + 符文金 accent | "升级的安心感" — player upgrade feels meaningful |
| **Magitech Wall** | Advanced magitech aesthetics: rune circuits, crystal inlays at stress points, pulsing glow rhythm | 霓虹蓝 dominant + 符文金 circuits + 晶石紫 #8B5CF6 accents | "魔导科技美学实现" — pillar 4 alignment |
| **Faction-Specialized Walls** | Faction visual signatures integrated (see Faction Wall Styles below) | Per-faction palette | "阵营选择视觉确认" — player faction choice visible |

**Faction Wall Styles** (player can build faction-specific walls after unlocking):

| Faction | Wall Visual Signature | Unique Feature |
|---------|----------------------|----------------|
| **Graveyard (虫族防御)** | Bio-organic surface texture, 腐烂绿 tint, 蜂巢结构 patterns, 粘液滴落 visual residue | "用敌人材料对抗敌人" — dark survival aesthetic |
| **Hell (克苏鲁抗性)** | 深渊紫黑 base, 触手-inspired reinforcement shapes, 眼球图案 as structural anchors, 抗扭曲 runes | "深渊防护" — resistance to克苏鲁 influence |
| **Tower (机械加固)** | 锈色 enhanced, industrial join patterns, 破损蓝 circuit traces, 机械焊缝 aesthetic | "工业务实" —低调 but functional |
| **Element (天气适应)** | 霓虹蓝 base + weather-responsive glow, 晶石 textures, elemental rune circuits | "天气融合" — wall adapts to current weather |

**Player-Built vs Natural Visual Distinction** (Critical for Player Fantasy):

| Visual Element | Natural (Layer 1) | Player-Built (Layer 2) | Purpose |
|----------------|-------------------|------------------------|---------|
| **Edge Shape** | Irregular, weathered, organic decay | Straight, uniform, manufactured precision | Clear ownership distinction |
| **Material Texture** | Natural erosion, biological decay traces | Welded seams, reinforced panels, assembly marks | "这是我建造的" feeling |
| **Joint Treatment** | Natural fractures, weathering cracks | 霓虹蓝 glow at joints, 魔导符文 circuits | "魔导科技美学" signature |
| **Surface Pattern** | Random organic patterns | Intentional structural patterns, faction designs | Player choice expression |
| **Damage Appearance** | Natural erosion, mineral loss | Structural damage, breach marks, player-repairable | "我的防线有痕迹" narrative |

**Structure Age Indicator** (optional polish):
- Newly placed: Clean edges, bright glow, pristine texture
- 1 cycle old: Slight weathering, glow slightly dimmed
- Multiple cycles: Visible wear, player-repair opportunity (future polish feature)

**Technical Implementation**:
- TileSet with faction-specific tile types (prefix naming: `structure_wall_[faction]_[tier]`)
- Shader for structural glow: pulse rhythm 0.5s cycle, intensity varies by wall tier
- Collision polygon physics layer bit 2 (COLLISION_STRUCTURE)
- Placement validation visual: foundation requirement highlighted (see Placement Feedback section)

---

#### Layer 3: Platforms (Partial Collision)

**Visual Purpose**: Movement facilitation, traversal options, scaffolding aesthetic.

| Visual Property | Specification | Art Bible Alignment |
|----------------|---------------|---------------------|
| **Opacity** | 100% solid | Functional traversal elements require visibility |
| **Texture Style** | Digital painting, functional brush strokes, industrial aesthetic | "废土工业美学" — scaffolds, walkways, temporary structures |
| **Color Temperature** | 秘银银 #B8C4CE + darker shading for depth | "金属质感" per art bible |
| **Collision Visual** | Top 8px solid visual indicator (slightly raised appearance) | Clear traversal boundary |
| **Weather Response** | Rust accumulation visual in 暴风雨/沙尘暴 weather | Weather wear effect |

**Platform Tile Categories**:

| Category | Visual Features | Color Palette | Traversal Purpose |
|----------|-----------------|---------------|-------------------|
| **Wooden Platform** | Wooden plank texture, support brackets, slight decay appearance | 木色 + 锈色 brackets | Basic traversal, destructible |
| **Metal Platform** | Industrial metal texture, rivet patterns, support beams | 秘银银 + 锈色 accents | Reinforced traversal, higher durability |
| **Magitech Platform** | Magitech circuit patterns, 霓虹蓝 edge glow, floating runes | 霓虹蓝 + 秘银银 | Advanced traversal, faction unlock |
| **Scaffold Platform** | Temporary construction aesthetic, visible support poles, functional appearance | 锈色 dominant | Construction/traversal hybrid |

**Platform Collision Visual Indicator**:
- Top edge has subtle raised appearance (top 8px visually distinct)
- Shadow beneath platform indicates pass-through zone
- Player can drop through from above (visual affordance: slight gap at edge)

**Technical Implementation**:
- TileSet collision polygon: top 8px rectangle only (platform collision)
- Physics layer bit 3 (COLLISION_PLATFORM)
- Shader for pass-through visual: subtle gradient from solid top to transparent bottom

---

#### Layer 4: Overlay (Transient Markers)

**Visual Purpose**: System feedback, temporary indicators, non-gameplay visual cues.

| Visual Property | Specification | Art Bible Alignment |
|----------------|---------------|---------------------|
| **Opacity** | Variable (50-100% based on marker type) | Transient nature, not permanent world elements |
| **Texture Style** | Minimal, iconographic, UI-aligned | HUD style consistency per art bible UI section |
| **Color Temperature** | Per-marker semantic color | Semantic color usage per art bible |
| **Collision Visual** | None — overlay has no collision | Pure visual layer |
| **Weather Response** | None — overlay independent of weather | System feedback layer |

**Overlay Marker Types**:

| Marker Type | Visual Features | Color | Duration | Trigger |
|-------------|-----------------|-------|----------|---------|
| **Spawn Point Indicator** | Subtle rune glow, pulsing rhythm | 霓虹蓝 | Until spawn complete | Enemy spawn system |
| **Damage Flash** | Tile border flash, impact indication | 火焰橙 #FF6B35 | 0.2s per hit | Damage application |
| **Placement Preview** | Ghost tile outline, validity indicator (green/red) | 绿 #3CB371 (valid) / 红 (invalid) | While placement UI active | Placement system |
| **Foundation Requirement** | Highlighted adjacent tiles needing foundation | 秘银银 outline | During placement preview | Placement validation |
| **Resource Drop Indicator** | Sparkle effect, item spawn location | 霓虹蓝 + 金色光泽 | 1s after drop | Resource spawn |
| **Enemy Path Marker** | Temporary path indicator for spawned enemies | 阵营色 (per enemy faction) | Until path complete | Enemy spawn system |
| **Warning Zone** | 区域警告标记, danger indication | 火焰橙 pulsing | Until warning clears | Defense system |

**Technical Implementation**:
- Managed by system, not player-accessible
- Timer-based auto-clear (see Duration column)
- No collision, no save persistence — pure runtime visual

---

### 2. Tile Damage State Visuals

**Core Design Philosophy**: Damage must be dramatic, not silent disappearance. The Player Fantasy demands "墙壁破坏是真实事件" — breach with consequences.

#### Damage State Visual Progression

| State | Damage Ratio | Visual Effect | VFX Type | Intensity | Art Bible Color |
|-------|--------------|---------------|----------|-----------|-----------------|
| **INTACT** | 0% | Normal tile texture | None | 0 | Default tile palette |
| **DAMAGED** | 1% - 79% | Crack overlay | Decal overlay | Alpha = damage_ratio * 0.5 (max 0.4) | 火焰橙 #FF6B35 (crack lines) |
| **CRITICAL** | 80% - 99% | Heavy fissure, structural glow pulse | Decal + Particle preview | Alpha = 0.7, particles preview (5% spawn rate per frame) | 深渊紫黑 #1A0A2E + 火焰橙 |
| **DESTROYED** | 100% | Tile removed, debris burst | Particle burst + Decal residue | Full burst (see Destruction Event) | 火焰橙 + 霓虹蓝 (magitech debris) |

#### State-Specific Visual Details

**INTACT State Visuals**:
- Normal tile texture at full opacity
- No overlay effects
- Structural glow (layer 2 only) at base intensity (tier-dependent)
- Collision visual implicit (tile presence = solid)

**DAMAGED State Visuals**:
- **Crack Decal Overlay**: Applied via shader overlay
  - Crack patterns: 3 variant sets (stone cracks, metal fractures, organic breaks)
  - Crack pattern selection based on tile material type
  - Alpha intensity: `clamp(damage_ratio * 0.5, 0.1, 0.4)` — visible but not overwhelming
  - Crack color: 火焰橙 #FF6B35 with slight opacity variation
- **Structural Glow Reduction**: Player-built structures (layer 2) glow intensity reduced by damage_ratio * 0.3
- **Edge Highlight**: Tile edges subtly highlighted with damage color (indicates weak point)
- **Material Type Visual Response**:

| Material Type | Crack Pattern | Visual Behavior |
|---------------|---------------|-----------------|
| Stone/Rock | Radiating fracture lines, jagged edges | Natural fracture aesthetic |
| Metal/Structure | Linear stress cracks, weld separation lines | Industrial damage aesthetic |
| Magitech | Rune circuit breaks, crystal fissures, glow interruption | Magitech-specific damage |
| Organic/虫族 | Organic tears, 粘液 residue at cracks | Bio-organic damage aesthetic |
| 克苏鲁 material | Dimensional rift patterns, twisted cracks | Cosmic horror damage aesthetic |

**CRITICAL State Visuals**:
- **Heavy Fissure Overlay**:
  - Fissure patterns: wider crack lines, visible gaps in tile texture
  - Alpha intensity: 0.7 (high visibility)
  - Gap indication: texture appears to have holes (simulate structural breach imminent)
  - Color: 深渊紫黑 #1A0A2E (main fissure) + 火焰橙 #FF6B35 (edge glow)
- **Structural Glow Pulse**:
  - Player-built structures: pulsing glow rhythm at 2x speed (0.25s cycle)
  - Glow color shifts to 火焰橙 during pulse peaks (warning indicator)
  - Intensity variation: 0.5 to 1.0 (flickering effect)
- **Particle Preview**:
  - Small debris particles spawn at 5% rate per frame (visual warning)
  - Particle type: "pre-destruction" particles (small dust/碎片)
  - Particle duration: 0.5s lifespan, fade out
  - Particle color: material-type color + 火焰橙 accent
- **Audio-Visual Sync**: CRITICAL state triggers ambient warning sound (see Audio section)

**DESTROYED State Visuals** (see Destruction Event section for full details):
- Immediate tile removal (cell becomes empty)
- Debris particle burst (main destruction event)
- Decal residue at former tile location (temporary)
- Structural gap visual (for player-built walls: breach hole outline)

#### Damage State Transition Visual Flow

```
INTACT → DAMAGED:
  - On first damage: crack decal overlay appears at alpha 0.1
  - Structural glow (layer 2) dims by 0.03 (first hit indicator)
  - Edge highlight appears (subtle)

DAMAGED → CRITICAL:
  - At 80% threshold: fissure overlay replaces crack overlay
  - Structural glow pulse activates
  - Particle preview begins
  - Color shifts: 火焰橙 → 深渊紫黑 dominant

CRITICAL → DESTROYED:
  - Full destruction event triggers (see section 3)
  - No gradual transition — dramatic breach moment
```

#### Visual Distinction by Layer

| Layer | DAMAGED Visual | CRITICAL Visual | DESTROYED Visual |
|-------|----------------|-----------------|------------------|
| **Terrain Base (Layer 1)** | Natural erosion cracks, mineral loss appearance | Rock fissures, imminent collapse appearance | Natural debris burst, rock fragments |
| **Structures (Layer 2)** | Weld separation, structural cracks, glow dimming | Structural breach imminent, glow pulse warning | Dramatic breach debris, magitech fragments, 火焰橙 burst |
| **Platforms (Layer 3)** | Support bracket cracks, platform sagging visual | Platform collapse warning, edge separation | Platform collapse debris, functional fragments |

#### Damage Visual Technical Implementation

- Shader-based overlay system: `tile_damage_overlay.gdshader`
  - Uniforms: `damage_ratio` (0.0-1.0), `damage_state` (int 0-3), `material_type` (int)
  - Decal textures: `crack_decal_[material].png`, `fissure_decal_[material].png`
- Runtime state tracking: `_cell_runtime_state` dictionary stores visual parameters
- Visual update triggered on damage application, not continuous polling
- Performance optimization: batch visual update for multi-tile damage (explosions)

---

### 3. Tile Destruction Event

**Core Design Philosophy**: Destruction must be dramatic — breach with sound alarm, visual crack, debris burst. This is the "防线失守" moment that defines the Player Fantasy peak.

#### Destruction Event Sequence

| Phase | Time | Visual Effect | Audio Effect | Particle Effect | Purpose |
|-------|------|---------------|--------------|-----------------|---------|
| **1. Impact Flash** | 0.0s - 0.15s | Tile flash white → 火焰橙 | Impact sound (material-specific) | None | Final hit indication |
| **2. Texture Collapse** | 0.15s - 0.25s | Tile texture fades out (scale shrinks to 0.8x) | Destruction sound (material-specific) | Pre-burst particles (small debris) | Destruction animation |
| **3. Debris Burst** | 0.25s - 0.8s | Tile removed, decal residue appears | Debris sound (continuous) | Main debris burst (20-40 particles) | Main destruction event |
| **4. Decal Residue** | 0.8s - 2.0s | Decal at former tile location (fade out) | Fade-out ambient sound | Residual dust particles (5-10) | aftermath visual |
| **5. Resource Spawn** | 0.2s - 0.5s (offset) | Sparkle effect at spawn position | Resource drop sound | Sparkle particles (3-5) | Reward visual |

#### Debris Particle Burst Specification

**Main Burst Parameters**:

| Parameter | Value | Range | Purpose |
|-----------|-------|-------|---------|
| **Particle Count** | 25 | 20-40 | Depends on tile material density |
| **Initial Velocity** | 150-300 px/s | 100-400 | Material weight affects velocity |
| **Direction Spread** | 360° spread | — | Radial burst from tile center |
| **Gravity Effect** | 200 px/s² | 150-300 | Gravity pulls debris down |
| **Lifetime** | 0.6-1.0s | 0.5-1.5s | Material weight affects lifetime |
| **Size Range** | 4-16px | 2-20px | Material density affects size |
| **Fade Out** | Linear alpha fade from 1.0 to 0.0 over last 0.3s | — | Smooth fade |

**Debris Particle Appearance by Material**:

| Material Type | Particle Appearance | Color Palette | Unique Feature |
|---------------|---------------------|---------------|----------------|
| **Stone/Rock** | Angular rock fragments, irregular shapes | 锈色 #8B4513 + 天空灰 #4A5568 | Natural rock debris |
| **Metal/Structure** | Metal shards, bent fragments, 霓虹蓝 glow fragments | 秘银银 #B8C4CE + 霓虹蓝 #00D4FF | Magitech debris glow |
| **Magitech Material** | Rune fragments, crystal shards, glowing debris | 霓虹蓝 #00D4FF + 符文金 #FFD700 + 晶石紫 #8B5CF6 | Magitech-specific glow |
| **Wood/Platform** | Wooden splinters, plank fragments | 木色 + 锈色 | Natural organic debris |
| **虫族 Material** | Organic fragments, 粘液 drops, bio-debris | 腐烂绿 #556B2F + 粘液青 #4A9B8F | Bio-organic appearance |
| **克苏鲁 Material** | Twisted fragments, dimensional rift particles | 深渊紫黑 #1A0A2E + 火焰橙 #FF6B35 | Cosmic horror debris |

**Debris Particle Physics**:
- Particles affected by current weather (暴风雨: reduced velocity, 沙尘暴: obscured appearance)
- Particles collide with ground tiles (layer 1 collision) but not other debris
- Particles bounce once on collision (velocity reduced by 50%)
- Magitech debris particles glow during lifetime (霓虹蓝 glow fades with particle fade)

#### Decal Residue Specification

**Decal Properties**:
- **Duration**: 2.0s at former tile location
- **Alpha**: Starts at 0.7, fades to 0.0 over 2.0s
- **Texture**: Scattered debris pattern, "remnants of destruction"
- **Color**: Material-type color + 火焰橙 overlay
- **Size**: Slightly larger than tile (36x36 px) to indicate former location

**Decal Purpose**:
- Marks former tile location for player awareness
- Supports "防线失守痕迹" — player sees where breach occurred
- Temporary — clears after 2.0s to avoid visual clutter

#### Screen Effects for Critical Destruction

**When Critical Tile is Destroyed (structure layer walls during defense)**:

| Screen Effect | Trigger | Effect | Duration |
|---------------|---------|--------|----------|
| **Screen Shake** | Wall breach during zombie tide | 0.5 intensity shake, radial from breach point | 0.3s |
| **Breach Flash** | Player-built wall destroyed | 火焰橙 flash at screen edge nearest breach | 0.2s |
| **Warning UI Spike** | Structure destroyed | HUD warning border pulses 火焰橙 | 1.0s |

**Screen Effect Purpose**:
- "防线失守必须有后果" — player feels the breach
- Visual attention redirected to breach location
- Supports defense phase tension per pillar 3 "尸潮即高潮"

#### Destruction Event Technical Implementation

**VFX Implementation**:
- Particle system: `GPUParticles2D` with material-specific particle texture
- Particle spawn: triggered by `apply_damage()` returning `tile_destroyed = true`
- Decal: `CanvasItem` with shader for fade-out effect
- Screen shake: Camera `offset` manipulation, intensity based on tile importance

**Event Dispatch**:
- Signal: `tile_destroyed(cell: Vector2i, layer: int, tile_type: int)`
- Consumers: Defense system (breach alert), Audio system (destruction sound), Resource spawn system
- Timing: Signal fires at phase 2 (Texture Collapse) for downstream system coordination

---

### 4. Tile Placement Feedback

**Core Design Philosophy**: Placement must validate, preview, and celebrate. Player needs clear feedback on where they can build and confirmation when placement succeeds.

#### Placement Preview Visual

**Preview Elements During Placement UI Active**:

| Element | Visual | Color | Behavior | Purpose |
|---------|--------|-------|----------|---------|
| **Ghost Tile Outline** | Semi-transparent tile texture at placement cursor | 秘银银 #B8C4CE (valid) / 火焰橙 #FF6B35 (invalid) | Follows cursor, 0.6 alpha | Placement intent indication |
| **Foundation Highlight** | Adjacent tiles highlighted if foundation required | 秘银银 outline (foundation present) / 火焰橙 outline (foundation missing) | Static highlight around cursor | Foundation requirement visibility |
| **Grid Snap Indicator** | Cell grid visible at placement area | 天空灰 #4A5568 grid lines | 0.3 alpha, follows cursor movement | Grid awareness for placement |
| **Validity Indicator** | Icon at cursor indicating placement validity | ✓ (valid) / ✗ (invalid) | Icon changes based on validation result | Clear validity signal |

**Preview Shader Effects**:
- Ghost tile shader: `placement_preview.gdshader`
  - Uniforms: `validity` (bool), `alpha` (float)
  - Valid: 秘银银 base, slight 霓虹蓝 glow at edges
  - Invalid: 火焰橙 base, pulsing at 0.5s rhythm (warning)

**Foundation Validation Visual**:

When player attempts to place structure requiring foundation:
- Solid adjacent cells highlighted with 秘银银 outline (foundation available)
- Empty adjacent cells (no foundation) highlighted with 火焰橙 outline pulsing
- Text hint appears: "需要相邻固体作为基础" (if foundation missing)
- Foundation requirement persists until valid placement found or placement cancelled

#### Placement Success Visual

**Success Sequence**:

| Phase | Time | Visual Effect | Audio Effect | Purpose |
|-------|------|---------------|--------------|---------|
| **1. Placement Confirm** | 0.0s | Ghost tile fades in to full tile (alpha 0.6 → 1.0) | Placement success sound | Placement confirmation |
| **2. Structural Glow Activation** | 0.1s - 0.3s | 霓虹蓝 glow at joints activates (fade-in) | Glow activation sound | "我的防线建立了" feeling |
| **3. Foundation Pulse** | 0.2s - 0.5s | Foundation tiles pulse briefly (acknowledgment) | None | Foundation connection acknowledgment |
| **4. Resource Deduction Flash** | 0.0s - 0.2s | HUD resource count flashes (deduction indicator) | Resource deduction sound | Cost visibility |

**Placement Success VFX**:
- Tile fades in: 0.3s transition from ghost to full tile
- Structural glow fade-in: 0.2s from 0.0 to base intensity
- Foundation pulse: adjacent solid tiles pulse 秘银银 outline at 0.3 alpha, 0.2s duration
- No particle burst for placement (unlike destruction) — construction is calm, deliberate

#### Placement Failure Visual

**Failure Feedback**:

| Failure Reason | Visual | Audio | Hint Text |
|----------------|--------|-------|-----------|
| **Cell Occupied** | 火焰橙 flash at occupied cell | Error sound | "位置已被占用" |
| **No Foundation** | 火焰橙 outline at missing foundation cells | Error sound | "需要相邻固体作为基础" |
| **Resource Insufficient** | HUD resource flashes 火焰橙 | Error sound | "资源不足" |
| **Invalid Layer** | Layer icon flashes 火焰橙 | Error sound | "无法在此层放置" |
| **Chunk Unloaded** | Area dims slightly | Error sound | "区域未加载" |

**Failure Visual Duration**: 0.5s, then clears
**Error Sound**: Short, distinct error tone (not same as placement success)

#### Placement Audio Feedback

| Audio Event | Sound Type | Timing | Purpose |
|-------------|------------|--------|---------|
| **Placement Success** | Construction confirmation sound (material-specific: metal clang, stone placement, magitech activation) | At placement confirm (phase 1) | Success confirmation |
| **Structural Glow Activation** | Magitech activation sound (霓虹蓝 glow sound) | At glow activation (phase 2) | "魔导科技美学" audio reinforcement |
| **Placement Failure** | Error tone (short, sharp) | On any failure | Clear failure indication |
| **Resource Deduction** | Resource spend sound (subtle) | At deduction (phase 4) | Cost awareness |

#### Batch Placement Visual Feedback

**For multi-cell placement (turrets, facilities)**:

| Element | Visual | Duration | Purpose |
|---------|--------|----------|---------|
| **Area Preview** | Rectangular outline for facility footprint | During preview | Multi-cell visibility |
| **Cell-by-Cell Placement** | Sequential tile fade-in (0.1s per cell) | During placement | Construction rhythm |
| **Completion Glow** | Full facility glow activates at completion | 0.5s after last tile | Completion celebration |
| **Foundation Check** | All foundation cells checked simultaneously | Before placement | Batch validation |

#### Placement Visual Technical Implementation

- Placement preview managed by `方块放置系统` (Placement System), not TileMap
- TileMap provides `can_place_structure()` and `can_place_platform()` validation
- Preview shader applied via temporary `CanvasItem` at cursor position
- Success/failure feedback managed by Placement System, TileMap confirms via `set_tile()` return

---

### 5. Chunk Loading/Unloading Feedback

**Core Design Philosophy**: Chunk transitions should be invisible to player. Loading/unloading is technical optimization, not gameplay event.

#### Loading Visual: None Required

**Design Decision**: Chunk loading has NO player-facing visual feedback.

**Reasons**:
- Loading is background optimization — visual indicator would distract
- Player never "sees" chunk loading — it happens ahead of entity movement
- Predictive loading (velocity path) ensures chunks ready before player arrives
- No gameplay meaning in loading state — not part of Player Fantasy

**Technical Loading Indicators (Developer-Only)**:
- Debug mode: chunk bounds outline visible (天空灰, 0.1 alpha)
- Debug mode: loading timer displayed in dev overlay
- Production mode: NO visual indicators

#### Unloading Visual: None Required

**Design Decision**: Chunk unloading has NO player-facing visual feedback.

**Reasons**:
- Unloading happens behind player (entity departed 30+ seconds ago)
- Player never in unloaded area by design — impossible to witness
- Modified chunks persist (never truly "lost" to player)
- Unloading is memory management, not gameplay event

**Edge Case Handling**:
- If player somehow enters FROZEN chunk (debug/test scenario): chunk immediately reloads, no visual
- If chunk unload fails (disk error): placeholder tiles appear, error logged (not player-facing)

#### Chunk Boundary Visual: None in Production

**Design Decision**: Chunk boundaries invisible to player in production build.

**Reasons**:
- Cell grid is the player's spatial reference (32x32 cells visible via placement preview)
- Chunk grid (32x32 chunks = 1024x1024 cells) is technical division, not gameplay reference
- Chunk boundaries have no gameplay meaning — would confuse player

**Developer Mode Chunk Visualization**:
- Debug toggle: chunk bounds visible as 天空灰 outline (0.2 alpha)
- Purpose: debugging load/unload behavior, performance profiling
- NOT visible in production build

#### Technical Transition Handling

**Loading Transition**:
- `UNLOADED → LOADING → ACTIVE`: no visual pause, tiles appear immediately
- Predictive loading: chunks loaded before player arrival, no "pop-in"
- If loading delay occurs (>0.5s): placeholder tiles (天空灰) briefly appear, replaced on load complete

**Unloading Transition**:
- `FROZEN → UNLOADING → UNLOADED`: happens in background, no visual
- Modified chunk serialization: immediate, no visual interruption
- Unload timer invisible — player never aware of countdown

**Performance Target**: Loading delay <0.2s for any chunk — imperceptible to player.

---

### 6. Ambient Environmental Audio

**Core Design Philosophy**: Audio encodes "安全" vs "危险" — sealed spaces hum differently than unexplored tunnels. Supports Player Fantasy of "边界确认" through sound.

#### Audio Environment Types

| Environment Type | Definition | Base Audio | Art Bible Mood | Layer Composition |
|------------------|------------|------------|----------------|-------------------|
| **Enclosed Safe Zone** | Player-built sealed bunker, all exits blocked by structures | Calm ambient hum, magitech resonance | "地堡内（挖掘建造）" — 安全但紧张 | Layer 2 walls enclose area |
| **Enclosed Unknown** | Natural cave, no player-built walls, unexplored | Echoing silence, distant sounds | "深层地下探索" — 恐惧与好奇 | Layer 1 terrain encloses, no layer 2 |
| **Open Surface** | No enclosure, sky visible, exposed position | Wind, weather-dependent sounds | "地表探索（晴天/暴风雨）" — varies by weather | Layer 0 background only |
| **Surface Near Structure** | Near player-built structure, partial shelter | Mixed ambient, structure hum + weather | "战车出发" — 边缘状态 | Layer 2 nearby but not enclosing |
| **Breach Zone** | Wall destroyed, tunnel exposed to enemies | Alarm sound, chaotic ambient | "防守失败/退守内层" — 挫败 | Layer 2 breach visible |
| **Deep Abyss** | Below safety threshold, 克苏鲁 influence zone | Low-frequency dread, whispers | "克苏鲁遭遇" — 深层恐惧 | Layer 1 deep terrain, 克苏鲁 texture |

#### Ambient Audio Parameters by Environment

**Enclosed Safe Zone Audio**:
- **Base Sound**: Magitech resonance hum (霓虹蓝-themed low frequency hum)
- **Intensity**: 0.6 (calm, reassuring)
- **Additional Layers**: Player activity sounds (digging, placement) audible clearly
- **Weather Influence**: None (sealed from weather)
- **Faction Influence**: Faction-specific hum variations (if player uses faction walls)

**Enclosed Unknown Audio**:
- **Base Sound**: Echoing silence (minimal ambient, occasional distant drip/rock settle)
- **Intensity**: 0.3 (sparse, unsettling)
- **Additional Layers**: Echo effect on all sounds, distance ambiguity
- **Weather Influence**: None (underground)
- **克苏鲁 Influence**: Increases at depth (see Deep Abyss)

**Open Surface Audio**:
- **Base Sound**: Weather-dependent wind ambient
- **晴天**: Clear wind, distant bird/bio sounds (minimal), 魔能晶石 hum audible
- **暴风雨**: Rain overlay, thunder distant, wind intensity 0.8
- **沙尘暴**: Dust wind howl, muted sounds, intensity 0.7
- **雷暴**: Thunder loud, lightning crack, intensity peaks at lightning
- **雾霾**: Muffled sounds, low-frequency dread base
- **Intensity**: 0.4-0.9 (weather-dependent)

**Surface Near Structure Audio**:
- **Base Sound**: Mixed — weather ambient + structure hum (faint)
- **Structure Hum**: Magitech resonance at 0.3 intensity (distant, shelter hint)
- **Weather Influence**: Full weather effect (not sheltered)
- **Transition**: Gradual shift from Open Surface to Enclosed Safe Zone as player enters structure

**Breach Zone Audio**:
- **Base Sound**: Alarm sound (火火焰橙-themed pulse rhythm) + chaotic ambient
- **Intensity**: 0.9 (emergency state)
- **Additional Layers**: Enemy sounds audible through breach, debris sounds
- **Duration**: Until breach repaired or player retreats

**Deep Abyss Audio**:
- **Base Sound**: Low-frequency dread hum (深渊紫黑-themed, unsettling)
- **Intensity**: 0.7-0.9 (increases with depth)
- **Additional Layers**: Whispers layer (克苏鲁 influence), sounds slightly distorted
- **Weather Influence**: None
- **特殊效果**: Player sounds echo differently, 克苏鲁 "gaze" sound at extreme depth

#### Tile-Damage-Triggered Audio

| Damage State | Audio Trigger | Sound Type | Purpose |
|--------------|---------------|------------|---------|
| **INTACT → DAMAGED** | First damage applied | Material-specific crack sound | Damage acknowledgment |
| **DAMAGED (per hit)** | Each additional damage | Light crackle sound | Damage progress indication |
| **CRITICAL** | Threshold reached | Loud warning sound + ambient dread increase | Imminent destruction warning |
| **DESTROYED** | Destruction event | Material-specific destruction sound + debris cascade | Destruction confirmation |

**Material-Specific Damage Sounds**:

| Material | DAMAGED Sound | CRITICAL Sound | DESTROYED Sound |
|----------|---------------|----------------|-----------------|
| **Stone/Rock** | Rock crack sound | Rock fissure warning | Rock collapse + rubble |
| **Metal/Structure** | Metal stress sound | Metal breach warning | Metal crash + clang |
| **Magitech** | Rune break sound | Magitech alarm | Magitech explosion + glow fade |
| **Wood** | Wood crack | Wood snap warning | Wood collapse + splinter |
| **虫族 Material** | Organic tear sound | Bio-structure warning | Organic collapse + 粘液 sound |
| **克苏鲁 Material** | Dimensional rift sound | 克苏鲁 breach warning | Dimensional collapse + dread burst |

#### Placement Audio

| Placement Event | Sound Type | Faction Variation | Purpose |
|-----------------|------------|-------------------|---------|
| **Structure Success** | Construction confirm (material-specific) | Faction-specific confirm sound | Placement success |
| **Platform Success** | Platform placement sound | None | Placement success |
| **Structural Glow Activation** | Magitech activation sound | Faction glow variations | "我的防线建立了" audio |
| **Placement Failure** | Error tone | None | Clear failure indication |

#### Audio Environment Detection Logic

**Environment Detection Algorithm** (simplified):

```gdscript
func get_audio_environment(player_cell: Vector2i) -> int:
    # Check enclosure
    var enclosure_check = check_enclosure(player_cell)
    
    if enclosure_check == ENCLOSED_SAFE:
        return AUDIO_ENV_ENCLOSURED_SAFE
    elif enclosure_check == ENCLOSED_UNKNOWN:
        # Check depth
        if player_cell.y > DEPTH_ABYSS_THRESHOLD:
            return AUDIO_ENV_DEEP_ABYSS
        return AUDIO_ENV_ENCLOSURED_UNKNOWN
    
    # Surface check
    if is_surface(player_cell):
        # Check proximity to structure
        if has_nearby_structure(player_cell, radius=5):
            return AUDIO_ENV_SURFACE_NEAR_STRUCTURE
        return AUDIO_ENV_OPEN_SURFACE
    
    # Breach check
    if has_breach_nearby(player_cell):
        return AUDIO_ENV_BREACH_ZONE
    
    return AUDIO_ENV_ENCLOSURED_UNKNOWN
```

**Enclosure Check Logic**:
- Scan 8-direction connectivity from player position
- If all paths blocked by layer 2 (structures): ENCLOSED_SAFE
- If all paths blocked by layer 1 (terrain) only: ENCLOSED_UNKNOWN
- If any path reaches surface (no blocking tiles): OPEN_SURFACE

#### Audio Transition Rules

| Transition | Transition Time | Audio Blend | Purpose |
|------------|-----------------|-------------|---------|
| **Open Surface → Enclosed Safe** | 2.0s | Weather fade out + structure hum fade in | Entering shelter |
| **Enclosed Safe → Open Surface** | 1.5s | Structure hum fade out + weather fade in | Leaving shelter |
| **Safe → Breach Zone** | 0.5s (fast) | Alarm overlay immediately | Emergency response |
| **Unknown → Deep Abyss** | 3.0s (gradual) | Dread increase + whispers fade in | Terror escalation |
| **Weather Change** | 30s (per art bible) | Weather audio transition | Weather system sync |

#### Ambient Audio Technical Implementation

- Audio system: `AudioStreamPlayer2D` for position-dependent ambient
- Zone detection: TileMap query for enclosure (layer 1/2 occupancy check)
- Audio layers: Multiple simultaneous streams (base ambient + weather + effects)
- Faction influence: Faction-specific hum variations via audio variant selection
- Performance: Audio streams loaded/unloaded with chunks (ambient tied to chunk)

---

### Visual/Audio Summary Table

| System Aspect | Visual System | Audio System | VFX Types | Player Fantasy Support |
|---------------|---------------|--------------|-----------|------------------------|
| **Layer Appearance** | Per-layer texture, color, opacity | Per-environment ambient | Shader overlays, texture variants | "边界定义" visual clarity |
| **Damage States** | Crack/fissure overlays, glow pulse | Material-specific damage sounds | Decal overlays, particle preview | "防线有痕迹" narrative |
| **Destruction Event** | Debris burst, decal residue, screen shake | Destruction cascade sounds | Particle burst, screen effects | "防线失守 dramatic" peak |
| **Placement Feedback** | Ghost preview, validity indicator, success fade-in | Placement confirm sounds | Preview shader, glow activation | "我建造的边界" feeling |
| **Chunk Loading** | None (invisible) | None (invisible) | None | Technical optimization, not gameplay |
| **Ambient Audio** | Environment type visual | Per-environment audio | Audio layers, transitions | "安全/危险 encoded" in sound |

## UI Requirements

TileMap世界系统 has **no direct player-facing UI**. The grid is invisible infrastructure — players see rendered tiles, not the system that stores them.

### UI Responsibilities Delegated to Downstream Systems

| TileMap Function | UI Owned By | UI Description |
|------------------|-------------|----------------|
| Tile damage state | 方块挖掘系统 | Damage progress bar, hardness display |
| Tile placement preview | 方块放置系统 | Ghost tile overlay, validity indicator |
| Tile coordinate info | 战车驾驶系统 HUD | Cell position display (optional debug) |
| Chunk status | None | Debug only — no player-facing chunk UI |

### Debug/Developer UI (Not Visible to Players)

| Debug Element | Description | When Visible |
|----------------|-------------|--------------|
| Chunk boundary overlay | Wireframe rectangles showing chunk extents | Debug mode toggle (`F3`) |
| Cell coordinate overlay | Grid lines showing 32px cell divisions | Debug mode toggle (`F3`) |
| Layer occupancy overlay | Color-coded tiles showing layer presence | Debug mode toggle (`F3`) |
| Damage state overlay | Heatmap showing tile damage accumulation | Debug mode toggle (`F3`) |
| Collision shape overlay | Wireframe showing collision polygons | Debug mode toggle (`F3`) |

**Debug UI implementation notes:**
- Debug overlays use CanvasLayer with Z-index above game layer
- Debug toggle persists across sessions (`production/debug-mode.txt`)
- Debug overlays do not affect gameplay — read-only visualization
- Debug overlays disabled in release builds (compile-time flag)

## Acceptance Criteria

### Grid Structure Tests

- **GIVEN** a world position `(100.5, 200.7)`, **WHEN** `world_to_cell()` is called, **THEN** the result is `Vector2i(3, 6)` (floor division by CELL_SIZE=32).
- **GIVEN** a cell `Vector2i(10, 20)`, **WHEN** `cell_to_world_center()` is called, **THEN** the result is `Vector2(336, 656)` (cell center at `(10.5, 20.5) * 32`).
- **GIVEN** a world position at bounds edge `(32000, 32000)`, **WHEN** coordinate conversion is called, **THEN** result is clamped to `Vector2i(1000, 1000)` (no out-of-bounds coordinates).
- **GIVEN** a negative world position `(-64, -32)`, **WHEN** coordinate conversion is called, **THEN** result is `Vector2i(-2, -1)` (negative indices handled correctly).

### Tile Lookup Tests

- **GIVEN** an occupied cell on layer 1 with hardness 50, **WHEN** `get_tile_hardness()` is called, **THEN** the result is `50`.
- **GIVEN** an empty cell, **WHEN** `get_tile_hardness()` is called, **THEN** the result is `255` (indestructible default for empty).
- **GIVEN** a cell with tiles on layers 1, 2, 3, **WHEN** `is_cell_solid()` is called, **THEN** the result is `true` (first occupied layer determines solidity).
- **GIVEN** a cell with empty on layers 1, 2 but tile on layer 0 (background), **WHEN** `is_cell_solid()` is called, **THEN** the result is `false` (background has no collision).

### Damage and State Tests

- **GIVEN** a tile with hardness 100 and damage 0, **WHEN** `apply_damage(30)` is called, **THEN** `damage_accumulated` is 30 and state is `DAMAGED`.
- **GIVEN** a tile with hardness 100 and damage 79, **WHEN** `apply_damage(1)` is called, **THEN** `damage_accumulated` is 80 and state is `CRITICAL`.
- **GIVEN** a tile with hardness 100 and damage 99, **WHEN** `apply_damage(1)` is called, **THEN** state is `DESTROYED`, tile is cleared, resources spawned.
- **GIVEN** a tile with hardness 100 and damage 60, **WHEN** `apply_damage(50)` is called, **THEN** overflow returned is `10` (damage beyond destruction returned).
- **GIVEN** a tile with hardness 3 and damage 2, **WHEN** `apply_damage(1)` is called, **THEN** state transitions directly from `DAMAGED` to `DESTROYED` (CRITICAL skipped for low-hardness).

### Chunk Loading Tests

- **GIVEN** a player entity at chunk (5, 5), **WHEN** chunks are loaded, **THEN** chunks (3-7, 3-7) are all loaded (2-chunk radius).
- **GIVEN** a chunk that was modified (player-built tile), **WHEN** the chunk is unloaded, **THEN** chunk data is serialized to disk (not discarded).
- **GIVEN** a chunk that was generated but unmodified, **WHEN** the chunk is unloaded, **THEN** chunk data is discarded (regenerated on next load).
- **GIVEN** no entities within 3-chunk radius for 30 seconds, **WHEN** unload timer triggers, **THEN** chunks transition to UNLOADING then UNLOADED.
- **GIVEN** an entity enters 2-chunk radius during unload timer countdown, **WHEN** proximity is detected, **THEN** timer resets to 30 seconds.

### Collision Tests

- **GIVEN** a tile on layer 1 with collision type `full`, **WHEN** collision query is performed, **THEN** Godot physics detects collision with 32x32 polygon.
- **GIVEN** a tile on layer 3 with collision type `platform`, **WHEN** collision query from above is performed, **THEN** collision detected at top 8px of cell.
- **GIVEN** a tile on layer 3 with collision type `platform`, **WHEN** collision query from below is performed, **THEN** no collision detected (platform is one-way).
- **GIVEN** a projectile path from `(100, 100)` to `(500, 100)`, **WHEN** `raycast_tile_collision()` is called, **THEN** first solid tile intersection is returned with collision point and normal.

### Placement Validation Tests

- **GIVEN** an empty cell on layer 2 with solid adjacent tile, **WHEN** `can_place_structure()` is called, **THEN** result is `true`.
- **GIVEN** an occupied cell on layer 2, **WHEN** `can_place_structure()` is called, **THEN** result is `false` (cell not empty).
- **GIVEN** an empty cell on layer 2 with no solid adjacent tiles, **WHEN** `can_place_structure()` is called, **THEN** result is `false` (no foundation).
- **GIVEN** an empty cell on layer 3 with solid tile below, **WHEN** `can_place_platform()` is called, **THEN** result is `true` (supported from below).
- **GIVEN** an empty cell on layer 3 with no support, **WHEN** `can_place_platform()` is called, **THEN** result is `false`.

### Resource Output Tests

- **GIVEN** a tile destroyed with resource type 150 (tier=2, base=2), multiplier 1.0, **WHEN** destruction completes, **THEN** 1-3 resource items spawn (base × random_factor × multiplier).
- **GIVEN** a tile destroyed with resource type 0, **WHEN** destruction completes, **THEN** no resources spawn (empty drop).
- **GIVEN** a tile destroyed with resource type 250 (tier=3, base=3), multiplier 2.0, **WHEN** destruction completes, **THEN** 4-8 resource items spawn (base × multiplier × random 0.8-1.2).

### Performance Tests

- **GIVEN** 1000 concurrent damage calls, **WHEN** processed in one frame, **THEN** frame time ≤ 16.6ms (damage batched, single visual update).
- **GIVEN** 50 loaded chunks, **WHEN** player moves at max velocity, **THEN** chunk loading completes in ≤ 0.2s (imperceptible to player).
- **GIVEN** a chunk with 1024 tiles, **WHEN** serialized to disk, **THEN** file size ≤ 32KB (memory budget per chunk).
- **GIVEN** world with 1000 chunks loaded, **WHEN** total memory queried, **THEN** TileMap memory ≤ 32MB (within 512MB total budget).

## Open Questions

| Question | Owner | Target Resolution | Notes |
|----------|-------|-------------------|-------|
| Should tile damage decay over time (auto-repair)? | Game Designer | Before Vertical Slice | Currently damage persists until repaired or destroyed. Auto-decay would reduce strategic pre-damage gameplay. |
| Should overflow damage carry to adjacent tiles? | Game Designer | Before MVP prototype | Currently overflow returned to caller. Cascade destruction could create chain-reaction mechanics for explosions. |
| Should platform tiles be destructible by enemies from below? | Game Designer | Before Vertical Slice | Currently platforms are one-way collision. If enemies can destroy from below, player defensive positions are more vulnerable. |
| Should background layer (layer 0) be dynamically generated or static per region? | World Builder | Before Alpha | Currently background is decoration only. Dynamic generation could show weather effects, faction influence spreading. |
| What is the maximum number of chunks that can be loaded simultaneously before memory exhaustion? | Technical Director | Before MVP prototype | Need performance profiling to validate 512MB budget assumption. |
| Should chunk unload timer use absolute time or relative to last modification? | Systems Designer | Before Alpha | Currently timer starts when entity exits radius. Modification-based timer would protect recently-built structures longer. |
| How should tile hardness be displayed to player during digging? | UX Designer | Before Vertical Slice | Currently hardness is internal data. Player needs feedback on "this will take 3 hits" vs "this will take 30 hits". |
| Should resource spawn RNG be deterministic per-tile or per-destruction-event? | Economy Designer | Before Vertical Slice | Currently deterministic per-tile (seeded by position). Per-event RNG would prevent memorization farming. |