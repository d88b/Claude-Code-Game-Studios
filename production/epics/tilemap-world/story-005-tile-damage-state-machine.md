# Story 005: Tile Damage State Machine

> **Epic**: TileMapWorld
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/tilemap-world-system.md`
**Requirement**: Implicit from GDD (tile damage, state transitions, destruction)
*(Not explicit TR-ID, derived from Damage and State Tests acceptance criteria)*

**ADR Governing Implementation**: ADR-001: TileMap System Architecture, ADR-005: Event Bus Architecture
**ADR Decision Summary**: Tile state machine (INTACT → DAMAGED → CRITICAL → DESTROYED)，GlobalSignals.block_dug emitted on destruction.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state machine, uses GlobalSignals for event emission.

**Control Manifest Rules (this layer)**:
- Required: GlobalSignals for cross-module communication (block_dug, block_placed)
- Required: Signal naming: snake_case past tense
- Required: All Signal parameters must have type annotations

---

## Acceptance Criteria

*From GDD `design/gdd/tilemap-world-system.md`, Damage and State Tests:*

- [ ] Tile state machine: INTACT → DAMAGED (damage ≥ 1) → CRITICAL (damage ≥ 80% hardness) → DESTROYED (damage ≥ hardness)
- [ ] `apply_damage(grid_pos, amount)` accumulates damage and transitions state
- [ ] Tile with hardness 100, damage 0 → apply_damage(30) → state DAMAGED, damage_accumulated = 30
- [ ] Tile with hardness 100, damage 79 → apply_damage(1) → state CRITICAL, damage_accumulated = 80
- [ ] Tile with hardness 100, damage 99 → apply_damage(1) → state DESTROYED, tile cleared, resources spawned
- [ ] Overflow damage returned: apply_damage(50) on hardness 100, damage 60 → returns 10 (damage beyond destruction)
- [ ] Low-hardness tiles skip CRITICAL: hardness 3, damage 2 → apply_damage(1) → INTACT to DESTROYED directly
- [ ] GlobalSignals.block_dug emitted on tile destruction

---

## Implementation Notes

*Derived from ADR-001, ADR-005:*

```gdscript
enum TileState { INTACT, DAMAGED, CRITICAL, DESTROYED }

class TileDamageData:
    var grid_pos: Vector2i
    var hardness: int
    var damage_accumulated: int = 0
    var state: TileState = TileState.INTACT

func apply_damage(grid_pos: Vector2i, amount: int) -> int:
    var tile = _get_tile_data(grid_pos)
    if tile.state == TileState.DESTROYED:
        return amount  # Already destroyed, return full damage
    
    tile.damage_accumulated += amount
    _update_tile_state(tile)
    
    if tile.state == TileState.DESTROYED:
        var overflow = tile.damage_accumulated - tile.hardness
        _destroy_tile(grid_pos)
        GlobalSignals.block_dug.emit(grid_pos, tile.block_id)
        return overflow
    
    return 0  # No overflow

func _update_tile_state(tile: TileDamageData) -> void:
    var damage_ratio = float(tile.damage_accumulated) / float(tile.hardness)
    if tile.damage_accumulated >= tile.hardness:
        tile.state = TileState.DESTROYED
    elif damage_ratio >= 0.8:
        tile.state = TileState.CRITICAL
    elif tile.damage_accumulated > 0:
        tile.state = TileState.DAMAGED
    else:
        tile.state = TileState.INTACT
```

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 003: Chunk loading (applies cells to TileMapLayers)
- ResourceDropSystem: Resource spawning on tile destruction (separate epic)
- BlockTypeDB: hardness values from block definitions

---

## QA Test Cases

*For Logic stories — automated test specs:*

- **AC-1**: INTACT to DAMAGED transition
  - Given: tile with hardness 100, damage 0
  - When: apply_damage(30) called
  - Then: state = DAMAGED, damage_accumulated = 30
  - Edge cases: Test damage = 1 (minimal damage)

- **AC-2**: DAMAGED to CRITICAL transition
  - Given: tile with hardness 100, damage 79
  - When: apply_damage(1) called
  - Then: state = CRITICAL, damage_accumulated = 80
  - Edge cases: Test exact 80% threshold (damage = 80)

- **AC-3**: CRITICAL to DESTROYED transition
  - Given: tile with hardness 100, damage 99
  - When: apply_damage(1) called
  - Then: state = DESTROYED, tile cleared, GlobalSignals.block_dug emitted
  - Edge cases: Test damage overflow

- **AC-4**: Overflow damage calculation
  - Given: tile with hardness 100, damage 60
  - When: apply_damage(50) called
  - Then: returns overflow = 10 (60+50-100)
  - Edge cases: Test exact destruction (damage = hardness)

- **AC-5**: Low-hardness skips CRITICAL
  - Given: tile with hardness 3, damage 2
  - When: apply_damage(1) called
  - Then: state transitions INTACT → DESTROYED directly (no CRITICAL)
  - Edge cases: Test hardness = 1 (destroyed on first hit)

- **AC-6**: GlobalSignals emission
  - Given: tile destroyed by apply_damage
  - When: destruction occurs
  - Then: GlobalSignals.block_dug.emit(grid_pos, block_id) called
  - Edge cases: Verify signal parameter types (Vector2i, int)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/tilemap/tile_damage_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (TileMapLayer structure), Story 002 (Cell coordinate), Story 003 (Chunk loaded)
- Unlocks: ResourceDropSystem (receives block_dug signal), BlockDiggingSystem (uses apply_damage)