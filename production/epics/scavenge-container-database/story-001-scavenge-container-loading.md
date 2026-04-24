# Story 001: Scavenge Container Loading

> **Epic**: ScavengeContainerDB
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/scavenge-container-database.md`
**Requirement**: `TR-scavenge-001`

**ADR Governing Implementation**: ADR-002: Database Loading Strategy
**ADR Decision Summary**: ScavengeContainerDB 存储 loot_table 和 roll_loot 算法，支持概率权重随机抽取。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] Container definitions loaded from entities.yaml
- [ ] get_loot_table(container_id) returns loot entries with probability weights
- [ ] roll_loot(container_id) returns random resource list based on weights
- [ ] Statistical testing validates probability distribution

---

## Implementation Notes

```gdscript
class_name ScavengeContainerDB extends RefCounted

class LootEntry:
    var resource_id: int
    var weight: float
    var min_count: int
    var max_count: int

func roll_loot(container_id: int) -> Array[Dictionary]:
    var table = get_loot_table(container_id)
    # Weighted random selection
    var total_weight = table.sum weights
    var roll = randf() * total_weight
    # Select entries based on roll
```

---

## QA Test Cases

- **AC-1**: Loot table query
  - Given: container_id = 1
  - When: get_loot_table(1) called
  - Then: returns Array of LootEntry with weights

---

## Test Evidence

**Type**: Integration
**Required**: `tests/unit/scavenge/scavenge_loading_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation layer)
- Unlocks: ScavengeSystem