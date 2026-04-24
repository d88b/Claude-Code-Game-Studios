# Story 001: Damage Accumulation

> **Epic**: BlockDiggingSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/block-digging-system.md`
**Requirement**: `TR-digging-001`, `TR-digging-002`

**ADR Governing Implementation**: ADR-008: Digging Architecture
**ADR Decision Summary**: Damage accumulation model，accumulated_damage >= block.difficulty → destroyed。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] accumulated_damage increments per frame during dig action
- [ ] block.difficulty determines destruction threshold
- [ ] accumulated_damage >= block.difficulty → block destroyed
- [ ] Tool modifier: tool_power / block.difficulty affects dig speed
- [ ] GlobalSignals.block_dug emitted on destruction
- [ ] queue_tile_modification for physics-safe deletion

---

## Implementation Notes

```gdscript
class_name DigController extends Node

var accumulated_damage: float = 0.0

func _process(delta: float) -> void:
    if InputManager.is_action_pressed("dig"):
        var target_pos = get_target_cell()
        var block_id = TileMapWorld.get_cell_at_position(target_pos)
        var difficulty = BlockTypeDB.get_hardness(block_id)
        var tool_power = get_current_tool_power()
        
        accumulated_damage += tool_power * delta
        if accumulated_damage >= difficulty:
            TileMapWorld.queue_tile_modification(target_pos, 0)  # Remove block
            GlobalSignals.block_dug.emit(target_pos, block_id)
```

---

## QA Test Cases

- **AC-1**: Damage accumulation
  - Given: block with difficulty = 100, tool_power = 50
  - When: dig for 2 seconds
  - Then: accumulated_damage = 100, block destroyed

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/digging/damage_accumulation_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: InputManager, TileMapWorld, BlockTypeDB
- Unlocks: ResourceDropSystem (receives block_dug)