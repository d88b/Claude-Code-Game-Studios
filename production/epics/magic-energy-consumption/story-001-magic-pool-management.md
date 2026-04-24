# Story 001: Magic Pool Management

> **Epic**: MagicEnergyConsumption
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/magic-energy-consumption.md`
**Requirement**: `TR-magic-001`, `TR-magic-002`

**ADR Governing Implementation**: ADR-005: Event Bus Architecture
**ADR Decision Summary**: MagicConsumptionCalculator 提供 consume/replenish，emit GlobalSignals。

**Engine**: Godot 4.6 | **Risk**: LOW

---

## Acceptance Criteria

- [ ] consume_magic(amount) deducts from magic_pool
- [ ] replenish_magic(amount) adds to magic_pool
- [ ] GlobalSignals.magic_consumed emitted on consumption
- [ ] GlobalSignals.magic_depleted emitted when pool < 10%
- [ ] Depletion behavior: velocity *= 0.5 (TK-014)
- [ ] MAGIC_COST_PER_CELL = 0.5 (TK-013)

---

## Implementation Notes

```gdscript
class_name MagicConsumptionCalculator extends Node

const MAGIC_COST_PER_CELL: float = 0.5  # TK-013
const DEPLETION_THRESHOLD: float = 0.1  # TK-014 (10%)

func consume_magic(amount: float) -> bool:
    if VehicleAttribute.current_magic < amount:
        return false  # Insufficient magic
    
    VehicleAttribute.current_magic -= amount
    GlobalSignals.magic_consumed.emit(amount)
    
    if VehicleAttribute.get_magic_ratio() < DEPLETION_THRESHOLD:
        GlobalSignals.magic_depleted.emit()
        VehicleController.velocity *= 0.5  # Slowdown
    
    return true
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/magic/magic_consumption_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: VehicleAttribute, VehicleController, GlobalSignals
- Unlocks: VehicleDrivingSystem, WeaponController