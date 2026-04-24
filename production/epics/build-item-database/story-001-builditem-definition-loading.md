# Story 001: Build Item Definition Loading

> **Epic**: BuildItemDB
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/build-item-database.md`
**Requirement**: `TR-builditem-001`, `TR-builditem-002`

**ADR Governing Implementation**: ADR-002: Database Loading Strategy
**ADR Decision Summary**: BuildItemDB 是 RefCounted Autoload，存储配方成本、地形支持条件、放置规则。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Build item definitions loaded from entities.yaml
- [ ] get_build_cost(item_id) returns Dictionary {resource_id: count}
- [ ] check_terrain_support(item_id, terrain_type) returns bool
- [ ] 12 MVP build items defined: 墙体/炮塔/陷阱/设施/地板
- [ ] Cost formula: total_cost = base_cost * quantity

---

## Implementation Notes

```gdscript
class_name BuildItemDB extends RefCounted

class BuildItemDefinition:
    var item_id: int
    var display_name: String
    var category: String  # wall/turret/trap/facility/floor
    var base_cost: Dictionary  # {resource_id: count}
    var terrain_support_required: Array[String]

func get_build_cost(item_id: int) -> Dictionary:
    var item = _items.get(item_id, null)
    return item.base_cost if item else {}

func check_terrain_support(item_id: int, terrain_type: String) -> bool:
    var item = _items.get(item_id, null)
    return terrain_type in item.terrain_support_required if item else false
```

---

## QA Test Cases

- **AC-1**: Build cost query
  - Given: item_id = 1000 (wall_basic)
  - When: get_build_cost(1000) called
  - Then: returns {iron: 5, copper: 2}
- **AC-2**: Terrain support check
  - Given: item requires terrain_support = ["solid"]
  - When: check_terrain_support(item_id, "solid") called
  - Then: returns true

---

## Test Evidence

**Type**: Integration
**Required**: `tests/unit/builditem/builditem_loading_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation layer)
- Unlocks: BuildValidator, PlaceController