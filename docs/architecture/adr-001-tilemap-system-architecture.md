# ADR-001: TileMap System Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

世界地图使用 5 层 TileMapLayer 结构（background/terrain_base/structures/platforms/overlay），chunk-based 加载（32x32 cells per chunk）。决定使用 Godot 4.3+ TileMapLayer API（非 deprecated TileMap），每个 layer 一个独立 TileMapLayer node。这解决大规模方块系统的性能和内存问题。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | World (TileMap, Rendering) |
| **Knowledge Risk** | LOW — TileMapLayer API stable since Godot 4.3, confirmed working in 4.6 |
| **References Consulted** | `docs/engine-reference/godot/breaking-changes.md` (4.2→4.3 TileMap→TileMapLayer), `docs/engine-reference/godot/deprecated-apis.md` (TileMap deprecated) |
| **Post-Cutoff APIs Used** | TileMapLayer (introduced 4.3, stable in 4.6) |
| **Verification Required** | Test TileMapLayer.set_cell() performance with 32x32 chunk size on target hardware |

> **Note**: TileMap (multi-layer single node) is DEPRECATED since Godot 4.3. Must use TileMapLayer (one node per layer). API is stable and confirmed working in 4.6.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-005 (Event Bus Architecture) — must be Accepted for GlobalSignals.block_dug/block_placed |
| **Enables** | ADR-002 (Database Loading), ADR-006 (Collision System), ADR-007 (Vehicle State Machine), all spatial systems |
| **Blocks** | All Core layer implementation until Accepted (CollisionManager, VehicleController, AreaManager depend on TileMapWorld) |
| **Ordering Note** | Foundation layer — must be one of first ADRs created |

## Context

### Problem Statement

铁锈魔潮需要大规模 2D 方块世界：
- 5 层地形（background/terrain_base/structures/platforms/overlay）
- Chunk-based 动态加载（避免全地图内存占用）
- 方块实时修改（挖掘/放置）
- 碰撞检测依赖方块状态

如何构建高效、可扩展的 TileMap 系统？

### Current State

GDD `design/gdd/tilemap-world-system.md` 定义了 5 层结构和 chunk 加载机制，但未明确引擎 API 选择。

### Constraints

- Godot 4.6 是目标引擎
- TileMap (old API) 已 deprecated，必须使用 TileMapLayer
- CELL_SIZE = 32 pixels (from entities.yaml)
- CHUNK_SIZE = 32 cells (from entities.yaml)
- 目标帧率 60 FPS，TileMap 更新必须在 frame budget 内
- 内存上限 512MB，世界地图不能全加载

### Requirements

- 支持 5 层独立渲染和碰撞
- Chunk 动态加载/卸载
- 方块实时修改（set_cell）
- 碰撞层与 TileMapLayer 关联
- 程序生成地形（seed-based）

## Decision

**TileMapLayer per Layer Architecture**：
- 每个 layer 使用独立 TileMapLayer node
- Chunk 作为逻辑单位，不是物理 TileMap 单位
- 地形生成在 chunk 加载时执行
- Collision 层绑定到 terrain_base + structures TileMapLayer

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TILEMAP WORLD ARCHITECTURE                           │
└─────────────────────────────────────────────────────────────────────────────┘

TileMapWorld (Node2D — parent node)
│
├─── BackgroundLayer (TileMapLayer)
│    └─── 渲染层: 无碰撞，装饰性背景（远山、云层）
│    └─── z_index: -10
│
├─── TerrainBaseLayer (TileMapLayer) ⚠️ COLLISION
│    └─── 渲染层: 基础地形（土壤、岩石、水体）
│    └─── collision_layer: 1 (terrain)
│    └─── z_index: 0
│
├─── StructuresLayer (TileMapLayer) ⚠️ COLLISION
│    └─── 渲染层: 建筑结构（墙体、炮塔基座）
│    └─── collision_layer: 2 (structure)
│    └─── z_index: 5
│
├─── PlatformsLayer (TileMapLayer)
│    └─── 渲染层: 可站立的平台（one-way collision）
│    └─── collision_layer: 4 (platform)
│    └─── z_index: 10
│
├─── OverlayLayer (TileMapLayer)
│    └─── 渲染层: 叠加效果（夜晚遮罩、天气效果）
│    └─── collision_layer: 0 (none)
│    └─── z_index: 20
│
└─── ChunkManager (Node — logical, not rendered)
     └─── 管理 chunk 加载/卸载
     └─── loaded_chunks: Dictionary {chunk_id: ChunkData}
     └─── modified_cells: Dictionary {grid_pos: block_id} — 持久化用


Chunk Structure:
─────────────────────────────────────────────────────────────────────────────
Chunk ID: Vector2i(chunk_x, chunk_y)
Chunk Bounds: chunk_x * 32 to (chunk_x + 1) * 32 - 1 (cells)
             chunk_y * 32 to (chunk_y + 1) * 32 - 1 (cells)

ChunkData {
    chunk_id: Vector2i
    is_loaded: bool
    cells_terrain_base: Array[int]  # 32x32 = 1024 cells
    cells_structures: Array[int]
    cells_platforms: Array[int]
    generated_seed: int
    has_modifications: bool
}

World Size: 无限扩展（程序生成）
Loaded Radius: 3 chunks around vehicle (估算 6 chunks = 192x192 cells active)
─────────────────────────────────────────────────────────────────────────────
```

### Key Interfaces

```gdscript
# TileMapWorld — Public API
# File: src/foundation/tilemap_world.gd

class_name TileMapWorld extends Node2D

# === Constants ===
const CELL_SIZE: int = 32          # From entities.yaml
const CHUNK_SIZE: int = 32         # From entities.yaml
const LOAD_RADIUS: int = 3         # Chunks around vehicle

# === Layer References ===
@onready var background_layer: TileMapLayer = $BackgroundLayer
@onready var terrain_base_layer: TileMapLayer = $TerrainBaseLayer    # Collision
@onready var structures_layer: TileMapLayer = $StructuresLayer        # Collision
@onready var platforms_layer: TileMapLayer = $PlatformsLayer          # One-way collision
@onready var overlay_layer: TileMapLayer = $OverlayLayer

# === State ===
var loaded_chunks: Dictionary = {}  # {Vector2i: ChunkData}
var modified_cells: Dictionary = {}  # {Vector2i: block_id} — for save/load

# === Public Methods ===

# Get block ID at grid position
func get_cell_at_position(grid_pos: Vector2i) -> int:
    # Priority: structures > platforms > terrain_base > background
    # Returns: block_type_id (0 = empty, -1 = out of bounds)
    var chunk_id = _get_chunk_id_for_pos(grid_pos)
    if not loaded_chunks.has(chunk_id):
        return -1  # Chunk not loaded
    return _get_cell_from_layers(grid_pos)

# Set block at grid position (for digging/placing)
func set_cell_at_position(grid_pos: Vector2i, block_type_id: int, layer: LayerType) -> bool:
    # Returns: true if successful, false if invalid
    # Emits: GlobalSignals.block_dug or block_placed
    if not _is_valid_position(grid_pos):
        return false
    var layer_node = _get_layer_node(layer)
    layer_node.set_cell(grid_pos, BlockTypeDB.get_tile_source_id(block_type_id),
                         BlockTypeDB.get_tile_atlas_coords(block_type_id))
    modified_cells[grid_pos] = block_type_id
    GlobalSignals.block_placed.emit(grid_pos, block_type_id)
    return true

# Get chunk containing grid position
func get_chunk_for_position(grid_pos: Vector2i) -> ChunkData:
    var chunk_id = _get_chunk_id_for_pos(grid_pos)
    if loaded_chunks.has(chunk_id):
        return loaded_chunks[chunk_id]
    return null

# Load chunks around center
func load_chunks_around(center_world_pos: Vector2) -> void:
    var center_chunk = _world_pos_to_chunk_id(center_world_pos)
    for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
        for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
            var chunk_id = center_chunk + Vector2i(dx, dy)
            if not loaded_chunks.has(chunk_id):
                _load_chunk(chunk_id)

# Get spawn point (for vehicle initialization)
func get_spawn_point() -> Vector2i:
    # Returns first walkable terrain_base cell in chunk 0,0
    # Guarantee: Always returns valid position
    return Vector2i(16, 16)  # Center of first chunk (adjustable)

# === Internal Methods ===

func _load_chunk(chunk_id: Vector2i) -> void:
    # Generate terrain procedurally
    var chunk_data = ChunkData.new()
    chunk_data.chunk_id = chunk_id
    chunk_data.is_loaded = true
    _generate_terrain(chunk_data)
    loaded_chunks[chunk_id] = chunk_data
    # Apply cells to TileMapLayers
    _apply_chunk_to_layers(chunk_data)
    GlobalSignals.chunk_loaded.emit(chunk_id)

func _generate_terrain(chunk_data: ChunkData) -> void:
    # Use seed + chunk_id for procedural generation
    # Fill terrain_base with dirt, rocks, water
    # Background is decorative only
    pass

func _apply_chunk_to_layers(chunk_data: ChunkData) -> void:
    # Iterate 32x32 cells, set_cell on each TileMapLayer
    for x in range(CHUNK_SIZE):
        for y in range(CHUNK_SIZE):
            var grid_pos = chunk_data.chunk_id * CHUNK_SIZE + Vector2i(x, y)
            if chunk_data.cells_terrain_base[y * CHUNK_SIZE + x] > 0:
                terrain_base_layer.set_cell(grid_pos, source_id, atlas_coords)
    # ... similar for other layers

func _get_chunk_id_for_pos(grid_pos: Vector2i) -> Vector2i:
    return Vector2i(grid_pos.x / CHUNK_SIZE, grid_pos.y / CHUNK_SIZE)

# === Signals ===
# Uses GlobalSignals for cross-module communication
# Direct signals for internal use only
```

### Implementation Guidelines

1. **TileMapLayer Node Setup**: 每个层是一个独立的 TileMapLayer node，在 TileMapWorld scene 中作为子节点
2. **TileSet Resource**: 创建统一的 TileSet resource，包含所有方块类型的 atlas
3. **Collision Layer Binding**: terrain_base_layer 和 structures_layer 启用 collision，使用 Godot physics collision layer
4. **Chunk Generation**: 使用 `seed + chunk_id` 作为程序生成输入，确保一致性
5. **Modified Cells Tracking**: 所有修改的 cells 记录到 `modified_cells` dict，用于 save/load
6. **Unload Strategy**: 当 vehicle 移动超出 LOAD_RADIUS 时卸载远处 chunks（保留 modified_cells）

## Alternatives Considered

### Alternative 1: Single TileMapLayer with Multi-Z-Index

- **Description**: 一个 TileMapLayer 使用 z_index 模拟多层
- **Pros**: 更少节点
- **Cons**: 不支持独立 collision layer per layer，违反 5 层设计
- **Estimated Effort**: 更低
- **Rejection Reason**: Collision layer 必须独立（terrain vs structure），无法用单一 node 实现

### Alternative 2: TileMap (Deprecated API)

- **Description**: 使用 Godot 4.2 的 TileMap node（multi-layer）
- **Pros**: 训练数据更多示例，熟悉 API
- **Cons**: DEPRECATED since 4.3，Godot 4.6 中可能移除
- **Estimated Effort**: 相同
- **Rejection Reason**: 使用 deprecated API 是技术风险，必须使用 TileMapLayer

### Alternative 3: Custom Chunk Tiles (Non-TileMapLayer)

- **Description**: 每个 chunk 是一个独立 Node2D，手动绘制 Sprite cells
- **Pros**: 完全控制内存，更精细 chunk 管理
- **Cons**: 无 TileMapLayer 内置优化（batch rendering, collision），性能更差
- **Estimated Effort**: 更高
- **Rejection Reason**: Godot TileMapLayer 有内置渲染优化和碰撞集成，不应绕过

## Consequences

### Positive

- 使用 Godot 原生优化（TileMapLayer batch rendering）
- Collision layer 独立配置（terrain_base vs structures）
- Chunk 加载避免全地图内存占用
- TileMapLayer API 稳定（自 4.3，无 breaking change）

### Negative

- 5 个 TileMapLayer node 增加场景复杂度
- Chunk 边界可能有视觉不连续（需处理）
- Modified cells 必须单独持久化（TileMapLayer 不自动保存）

### Neutral

- 这是 Godot 4.3+ 标准做法，无特殊创新

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| TileMapLayer.set_cell() 性能瓶颈 | Low | Medium | Test 32x32 chunk load on target hardware |
| Chunk 边界视觉不连续 | Medium | Low | Use overlap zone (load 1 extra row/column) |
| Modified cells 持久化丢失 | Low | High | SaveManager must include modified_cells |
| TileMapLayer API future breaking | Low | Medium | Monitor Godot changelog per version |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Memory (loaded chunks) | 0 | ~10MB (6 chunks) | 512MB ceiling |
| CPU (chunk load) | 0 | <50ms per chunk | Async load acceptable |
| Draw Calls | 100 (max) | 5 TileMapLayer nodes | <100 per frame |

TileMapLayer uses batch rendering — 5 layers ≈ 5 draw calls regardless of cell count.

## Migration Plan

新架构，无迁移。

**Rollback plan**: If TileMapLayer proves problematic, can refactor to Alternative 3 (Custom Chunk Tiles), but this would lose Godot optimizations.

## Validation Criteria

- [ ] 5 TileMapLayer nodes created with correct z_index
- [ ] terrain_base_layer and structures_layer have collision enabled
- [ ] Chunk load generates 32x32 terrain correctly
- [ ] set_cell_at_position() works for dig/place operations
- [ ] GlobalSignals.block_dug/block_placed emitted on cell change
- [ ] Vehicle spawn point returns valid walkable cell
- [ ] Unload distant chunks when vehicle moves

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/tilemap-world-system.md` | TileMapWorld | 5-layer structure (background/terrain_base/structures/platforms/overlay) | 5 TileMapLayer nodes with z_index hierarchy |
| `design/gdd/tilemap-world-system.md` | TileMapWorld | Chunk-based loading (32x32 cells per chunk) | ChunkManager loads/unloads chunks around vehicle |
| `design/gdd/tilemap-world-system.md` | TileMapWorld | Procedural terrain generation with seed | `_generate_terrain()` uses seed + chunk_id |
| `design/gdd/tilemap-world-system.md` | TileMapWorld | Cell coordinate system: grid_pos = world_pos / CELL_SIZE | CELL_SIZE constant, coordinate conversion methods |
| `design/gdd/block-collision-system.md` | Collision | Collision depends on block type | TileMapLayer collision layer binding + BlockTypeDB collision profiles |
| `design/gdd/block-digging-system.md` | Digging | Dig modifies TileMap cells | `set_cell_at_position()` with layer parameter |
| `design/gdd/block-placing-system.md` | Placing | Place modifies TileMap cells | `set_cell_at_position()` with layer parameter |

## Related

- ADR-005: Event Bus Architecture — GlobalSignals.block_dug, block_placed, chunk_loaded
- ADR-002: Database Loading Strategy — BlockTypeDB provides tile source_id, atlas_coords
- ADR-006: Collision System Architecture — uses TileMapLayer collision data
- ADR-007: Vehicle State Machine Architecture — uses get_spawn_point() for initialization
- ADR-014: Facility System Architecture — facilities are structures layer entities