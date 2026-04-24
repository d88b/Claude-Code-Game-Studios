# Story 002: Custom Data Field Mapping

> **Epic**: BlockTypeDB
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/block-type-database.md`
**Requirement**: `TR-blocktype-001` (collision profiles), `TR-blocktype-002` (dig difficulty)
*(Custom data fields: hardness, destructibility, resource_type_id, resource_multiplier, buildability, collision_shape)*

**ADR Governing Implementation**: ADR-002: Database Loading Strategy
**ADR Decision Summary**: TileSet custom_data_0-5 maps to block properties. Hardness 0-255, destructibility 0/1.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: TileData.set_custom_data() API stable. Custom data layers configured in TileSet resource.

**Control Manifest Rules (this layer)**:
- Required: All static data from entities.yaml
- Required: O(1) lookup via Dictionary

---

## Acceptance Criteria

*From GDD `design/gdd/block-type-database.md`, Data Integrity Criteria:*

- [ ] custom_data_0 maps to hardness (0-255 range)
- [ ] custom_data_1 maps to destructibility (0 or 1)
- [ ] custom_data_2 maps to resource_type_id (int)
- [ ] custom_data_3 maps to resource_multiplier (0.0-10.0 range)
- [ ] custom_data_4 maps to buildability (0 or 1)
- [ ] custom_data_5 maps to collision_shape (0=NONE, 1=FULL, 2=PLATFORM)
- [ ] layer_allowed array valid: at least one layer per tile, values in 0-4 range
- [ ] All hardness values validated in 0-255 range
- [ ] All resource_multiplier values validated in 0.0-10.0 range

---

## Implementation Notes

*Derived from ADR-002:*

TileSet custom_data_layers configuration:
- Layer 0: hardness (int, 0-255)
- Layer 1: destructibility (int, 0=indestructible, 1=destructible)
- Layer 2: resource_type_id (int, references ResourceDB)
- Layer 3: resource_multiplier (float, 0.0-10.0)
- Layer 4: buildability (int, 0=not buildable, 1=buildable)
- Layer 5: collision_shape (int, 0=NONE, 1=FULL, 2=PLATFORM)

```gdscript
class BlockDefinition:
    var tile_id: int
    var hardness: int          # custom_data_0
    var destructibility: int   # custom_data_1
    var resource_type_id: int  # custom_data_2
    var resource_multiplier: float  # custom_data_3
    var buildability: int      # custom_data_4
    var collision_shape: int   # custom_data_5
    var layer_allowed: Array[int]
    var display_name: String
```

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 001: TileSet resource loading
- Story 003: Query API to read custom data values
- entities.yaml: Custom data values defined in source YAML

---

## QA Test Cases

*For Logic stories — automated test specs:*

- **AC-1**: Hardness field mapping
  - Given: TileData with custom_data_0 = 80
  - When: BlockDefinition.hardness read
  - Then: hardness = 80, in range 0-255
  - Edge cases: Test hardness = 0 (instant destroy), hardness = 255 (indestructible)

- **AC-2**: Destructibility field validation
  - Given: TileData with custom_data_1 = 1
  - When: BlockDefinition.destructibility read
  - Then: destructibility = 1 (destructible)
  - Edge cases: Test destructibility = 0 (bedrock, indestructible)

- **AC-3**: Resource multiplier validation
  - Given: TileData with custom_data_3 = 2.0
  - When: BlockDefinition.resource_multiplier read
  - Then: resource_multiplier = 2.0, in range 0.0-10.0
  - Edge cases: Test multiplier = 0.0 (no resources), multiplier = 10.0 (max)

- **AC-4**: Collision shape mapping
  - Given: TileData with custom_data_5 = 2
  - When: BlockDefinition.collision_shape read
  - Then: collision_shape = 2 (PLATFORM)
  - Edge cases: Test collision_shape = 0 (NONE), = 1 (FULL)

- **AC-5**: Layer_allowed validation
  - Given: TileData with layer_allowed = [0, 1]
  - When: BlockDefinition.layer_allowed read
  - Then: array contains at least one value, all in range 0-4
  - Edge cases: Test empty array (invalid), values outside 0-4 (invalid)

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/blocktype/custom_data_mapping_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001 (TileSet resource loaded)
- Unlocks: Story 003 (Query API reads mapped fields)