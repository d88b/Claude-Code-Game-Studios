# Story 001: Facility Entity Lifecycle

> **Epic**: BunkerFacilitySystem
> **Status**: Ready
> **Layer**: Feature
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/bunker-facility-system.md`
**Requirement**: `TR-facility-001`, `TR-facility-002`, `TR-facility-003`, `TR-facility-004`, `TR-facility-005`

**ADR Governing Implementation**: ADR-005: Event Bus, ADR-007: Vehicle State Machine
**ADR Decision Summary**: FacilityController 管理 facility 实例生命周期（create → interact → damage → demolish）。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Facility entity lifecycle: create → interact → damage → demolish with state management
- [ ] Storage box capacity: 100 slots per box (TK-032 STORAGE_CAPACITY)
- [ ] Workbench crafting: 4 MVP recipes with cost and craft_time
- [ ] Magic connection: facility within 10 cells of vehicle for power (TK-047)
- [ ] Demolition refund: 50% of build cost returned (TK-048 DEMOLITION_REFUND_RATE)
- [ ] GlobalSignals.facility_created, facility_destroyed emitted

---

## Implementation Notes

```gdscript
class_name FacilityController extends Node

enum FacilityState { IDLE, ACTIVE, DAMAGED, DESTROYED }

const STORAGE_CAPACITY: int = 100  # TK-032
const MAGIC_LINK_DISTANCE: int = 10  # TK-047 cells
const DEMOLITION_REFUND_RATE: float = 0.5  # TK-048

var contents: Array[ResourceSlot] = []  # Storage contents

func create_facility(facility_id: int, grid_pos: Vector2i) -> void:
    GlobalSignals.facility_created.emit(facility_id, grid_pos)

func demolish_facility(facility_id: int) -> void:
    var refund = build_cost * DEMOLITION_REFUND_RATE
    VehicleAttribute.add_resources(refund)
    GlobalSignals.facility_destroyed.emit(facility_id)
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/facility/facility_lifecycle_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: TileMapWorld, VehicleAttribute, GlobalSignals
- Unlocks: TurretSystem (linked storage)