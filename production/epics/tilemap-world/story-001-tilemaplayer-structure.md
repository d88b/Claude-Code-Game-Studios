# Story 001: TileMapLayer Node Structure

> **Epic**: TileMapWorld
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/tilemap-world-system.md`
**Requirement**: `TR-tilemap-001`, `TR-tilemap-005`
*(5-layer structure, use TileMapLayer API)*

**ADR Governing Implementation**: ADR-001: TileMap System Architecture
**ADR Decision Summary**: 每个 layer 使用独立 TileMapLayer node，使用 Godot 4.3+ TileMapLayer API（非 deprecated TileMap）。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: TileMapLayer API stable since Godot 4.3, confirmed working in 4.6. TileMap (old API) is DEPRECATED.

**Control Manifest Rules (this layer)**:
- Required: Use TileMapLayer API (not deprecated TileMap) — one node per layer
- Required: 5 TileMapLayer nodes: background/terrain_base/structures/platforms/overlay
- Required: Cell coordinate system: grid_pos = world_pos / CELL_SIZE (32)
- Forbidden: Never use deprecated TileMap API

---

## Acceptance Criteria

*From GDD `design/gdd/tilemap-world-system.md`:*

- [ ] 5 TileMapLayer nodes created with correct z_index hierarchy (background=-10, terrain_base=0, structures=5, platforms=10, overlay=20)
- [ ] terrain_base_layer and structures_layer have collision enabled (collision_layer: 1 and 2)
- [ ] platforms_layer has one-way collision configured (collision_layer: 4)
- [ ] background_layer and overlay_layer have no collision (collision_layer: 0)
- [ ] TileMapWorld scene structure matches ADR-001 architecture diagram
- [ ] All layers use unified TileSet resource containing block type atlas

---

## Implementation Notes

*Derived from ADR-001 Implementation Guidelines:*

1. **TileMapLayer Node Setup**: 每个层是一个独立的 TileMapLayer node，在 TileMapWorld scene 中作为子节点
2. **TileSet Resource**: 创建统一的 TileSet resource，包含所有方块类型的 atlas
3. **Collision Layer Binding**: terrain_base_layer 和 structures_layer 启用 collision，使用 Godot physics collision layer
4. **Z-Index Configuration**:
   - BackgroundLayer: z_index = -10 (decorative, far distance)
   - TerrainBaseLayer: z_index = 0 (ground level)
   - StructuresLayer: z_index = 5 (walls, buildings)
   - PlatformsLayer: z_index = 10 (walkable surfaces)
   - OverlayLayer: z_index = 20 (visual effects, night overlay)

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Cell coordinate conversion (world_to_cell, cell_to_world_center)
- Story 003: Chunk loading/unloading logic
- Story 004: Procedural terrain generation
- Story 005: Tile damage state machine
- Story 006: Chunk persistence (modified_cells serialization)

---

## QA Test Cases

*For Integration stories — automated test specs:*

- **AC-1**: 5 TileMapLayer nodes exist in TileMapWorld scene
  - Given: TileMapWorld.tscn loaded
  - When: scene tree inspected
  - Then: 5 TileMapLayer child nodes found (BackgroundLayer, TerrainBaseLayer, StructuresLayer, PlatformsLayer, OverlayLayer)
  - Edge cases: None

- **AC-2**: Collision layers configured correctly
  - Given: TileMapWorld scene loaded
  - When: collision_layer property inspected on each TileMapLayer
  - Then: terrain_base_layer = 1, structures_layer = 2, platforms_layer = 4, background/overlay = 0
  - Edge cases: Verify collision_mask also configured

- **AC-3**: Z-index hierarchy matches specification
  - Given: TileMapWorld scene loaded
  - When: z_index property inspected on each TileMapLayer
  - Then: background=-10, terrain_base=0, structures=5, platforms=10, overlay=20
  - Edge cases: Verify CanvasItem.z_index behavior in rendering

---

## Test Evidence

**Story Type**: Integration
**Required evidence**: `tests/integration/tilemap/tilemaplayer_structure_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation layer, first story)
- Unlocks: Story 002, Story 003, Story 004, Story 005, Story 006