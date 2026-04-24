# Story 001: Resource Drop Entity

> **Epic**: ResourceDropSystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/resource-drop-system.md`
**Requirement**: `TR-drop-001`, `TR-drop-002`

**ADR Governing Implementation**: ADR-002: Database Loading Strategy
**ADR Decision Summary**: DropController 监听 block_dug，生成 ResourceDropEntity（lifetime=30s）。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] ResourceDropEntity lifetime = 30 seconds default
- [ ] pickup_radius = 2 cells for collection
- [ ] Drop spawn: random offset from destroyed block position
- [ ] GlobalSignals.block_dug triggers drop spawn
- [ ] Resource quantity from block's resource_type_id and multiplier

---

## Implementation Notes

```gdscript
class_name ResourceDropEntity extends Area2D

const LIFETIME: float = 30.0
const PICKUP_RADIUS: float = 64.0  # 2 cells

var resource_id: int
var count: int
var lifetime_timer: float = LIFETIME

func _ready() -> void:
    # Connect to pickup detection
    body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
    lifetime_timer -= delta
    if lifetime_timer <= 0:
        queue_free()
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/drop/resource_drop_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: TileMapWorld (block_dug signal), ResourceDB
- Unlocks: VehicleAttribute (pickup collection)