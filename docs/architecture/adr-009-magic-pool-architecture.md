# ADR-009: Magic Pool Management Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

魔能池使用 MagicConsumption module，管理 current_pool (0-max_pool)。consume() 消耗魔能，replenish() 补充。魔能驱动移动、武器、设施。魔能耗尽时触发 slowdown（velocity *= 0.5）和 warning。MAGIC_COST_PER_CELL=0.5 (TK-013)，MAGIC_DEPLETION_THRESHOLD=0.1 (TK-014)。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Resource management) |
| **Knowledge Risk** | LOW — No engine API dependency |
| **References Consulted** | `design/gdd/magic-energy-consumption.md`, `design/registry/entities.yaml` (TK-013, TK-014) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test depletion warning, slowdown behavior |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-005 (Event Bus), ADR-002 (VehicleTypeDB for max_pool) |
| **Enables** | ADR-008 (Movement), ADR-011 (Weapon), ADR-014 (Facility magic link) |
| **Blocks** | Vehicle movement, weapon firing until Accepted |
| **Ordering Note** | Core layer — after Event Bus, before Movement Integration |

## Context

魔能是战车动力核心（"魔导科技美学" pillar）。所有动力消耗来自魔能池。

## Decision

**MagicConsumption Module with Pool Management**：

```gdscript
class_name MagicConsumption extends Node

var current_pool: float
var max_pool: float  # From VehicleTypeDB.get_vehicle_stats().magic_pool
var depletion_threshold: float = 0.1  # TK-014

func can_afford(cost: float) -> bool:
    return current_pool >= cost

func consume(cost: float) -> bool:
    if not can_afford(cost):
        return false
    current_pool -= cost
    GlobalSignals.magic_changed.emit(current_pool)
    if current_pool < max_pool * depletion_threshold:
        GlobalSignals.magic_depleted.emit()
    return true

func replenish(amount: float) -> void:
    current_pool = min(current_pool + amount, max_pool)
    GlobalSignals.magic_replenished.emit(amount)

func get_movement_cost(cells: int) -> float:
    return cells * 0.5  # TK-013 MAGIC_COST_PER_CELL
```

## GDD Requirements Addressed

| GDD | Requirement | How Satisfied |
|-----|-------------|---------------|
| `magic-energy-consumption.md` | MAGIC_COST_PER_CELL = 0.5 | TK-013 constant |
| `magic-energy-consumption.md` | Depletion threshold | TK-014 = 10%, triggers warning |

## Related

- ADR-008: Movement — consumes magic per cell
- ADR-011: Weapon — consumes magic per shot
- ADR-014: Facility — magic link for facility power