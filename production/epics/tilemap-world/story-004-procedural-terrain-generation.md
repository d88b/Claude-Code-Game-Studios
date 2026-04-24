# Story 004: Procedural Terrain Generation

> **Epic**: TileMapWorld
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/tilemap-world-system.md`
**Requirement**: `TR-tilemap-003`
*(Procedural terrain generation with seed for consistency)*

**ADR Governing Implementation**: ADR-001: TileMap System Architecture
**ADR Decision Summary**: 使用 seed + chunk_id 作为程序生成输入，确保同一 seed 产生相同地形。

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Use Godot's seeded RNG (RandomNumberGenerator.seed). No post-cutoff API needed.

**Control Manifest Rules (this layer)**:
- Required: Procedural terrain generation with seed
- Required: Seed + chunk_id for deterministic generation
- Performance: Chunk generation <50ms

---

## Acceptance Criteria

*From GDD `design/gdd/tilemap-world-system.md`:*

- [ ] `_generate_terrain(ChunkData chunk)` fills cells_terrain_base, cells_structures with procedurally generated block IDs
- [ ] Same seed + same chunk_id always produces identical terrain (deterministic)
- [ ] Different seeds produce different terrain layouts
- [ ] Terrain includes: dirt (solid), rocks (solid), water (passable), caves (empty)
- [ ] Background layer (layer 0) generated with decorative tiles (no collision)
- [ ] Procedural noise function (e.g., cellular noise, perlin) for terrain distribution
- [ ] Generation performance <50ms per 32x32 chunk

---

## Implementation Notes

*Derived from ADR-001:*

```gdscript
var world_seed: int = 12345  # Configurable per game session

func _generate_terrain(chunk_data: ChunkData) -> void:
    var rng = RandomNumberGenerator.new()
    rng.seed = world_seed + chunk_data.chunk_id.x * 1000 + chunk_data.chunk_id.y
    
    # Use cellular noise or perlin for natural terrain distribution
    for x in range(CHUNK_SIZE):
        for y in range(CHUNK_SIZE):
            var noise_val = _get_noise_value(chunk_data.chunk_id, x, y)
            var block_id = _noise_to_block_type(noise_val)
            chunk_data.cells_terrain_base[y * CHUNK_SIZE + x] = block_id
```

Noise function options (per entities.yaml terrain profile):
- Cellular noise for cave systems
- Perlin noise for gradual terrain transitions
- Value noise for resource distribution

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 003: Chunk loading (calls _generate_terrain)
- Story 001: TileMapLayer rendering (generated cells applied to layers)
- BlockTypeDB: Block definitions (dirt, rock, water IDs from database)

---

## QA Test Cases

*For Logic stories — automated test specs:*

- **AC-1**: Deterministic generation
  - Given: world_seed = 12345, chunk_id = Vector2i(0, 0)
  - When: _generate_terrain called twice with same inputs
  - Then: cells_terrain_base arrays identical
  - Edge cases: Test different chunk_ids, different seeds

- **AC-2**: Seed variation produces different terrain
  - Given: seed_a = 12345, seed_b = 67890, chunk_id = Vector2i(0, 0)
  - When: _generate_terrain called with each seed
  - Then: cells_terrain_base arrays differ significantly (>50% cells different)
  - Edge cases: Test adjacent seeds (12345 vs 12346)

- **AC-3**: Terrain block types
  - Given: chunk generated with default seed
  - When: cells_terrain_base inspected
  - Then: contains dirt (solid), rocks (solid), water (passable), empty cells
  - Edge cases: Test chunk at specific position (e.g., spawn area has walkable terrain)

- **AC-4**: Background layer generation
  - Given: chunk generated
  - When: BackgroundLayer cells inspected
  - Then: decorative tiles present, no collision shapes
  - Edge cases: Verify background z_index = -10 renders behind terrain

- **AC-5**: Generation performance
  - Given: 32x32 chunk generation
  - When: _generate_terrain profiled
  - Then: execution time <50ms on target hardware
  - Edge cases: Profile worst-case (all cells require noise calculation)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tilemap/procedural_generation_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (TileMapLayer structure), Story 003 (Chunk loading calls generation)
- Unlocks: None (standalone generation logic)