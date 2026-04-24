# ADR-007: Vehicle State Machine Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

战车状态机定义 5 状态：GARAGE_IDLE → DEPLOYABLE → DEPLOYED → DISABLED → DESTROYED。状态转换由 DamageReceiver.damage_state 和 MagicConsumption.depletion_state 驱动。VehicleAttribute 持有 current_health, current_magic_pool, cargo_contents。状态变化 emit GlobalSignals.vehicle_deployed, vehicle_destroyed。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (State Machine) |
| **Knowledge Risk** | LOW — State machine pattern standard, no engine API dependency |
| **References Consulted** | `design/gdd/vehicle-type-database.md` (state definitions), `design/gdd/vehicle-damage-system.md` |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test state transitions: damage → DISABLED, magic depletion → slowdown |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-002 (VehicleTypeDB), ADR-005 (Event Bus) |
| **Enables** | ADR-008 (Movement), DamageReceiver, FacilityController (magic link) |
| **Blocks** | All vehicle gameplay until Accepted |
| **Ordering Note** | Core layer — after Database, before Movement Integration |

## Context

### Problem Statement

战车有多种状态：
- GARAGE_IDLE: 在车库中，未部署
- DEPLOYABLE: 可部署到世界
- DEPLOYED: 在世界中，可控
- DISABLED: 损坏，无法移动
- DESTROYED: 完全摧毁

状态转换需要明确的条件和事件。

### Requirements

- 5 states with defined transitions
- DamageReceiver triggers DISABLED → DESTROYED
- MagicConsumption triggers slowdown (not state change)
- State changes emit GlobalSignals

## Decision

**Finite State Machine with Event-Driven Transitions**：

```
State Machine:
GARAGE_IDLE ──[deploy]──> DEPLOYABLE
DEPLOYABLE ──[enter_world]──> DEPLOYED
DEPLOYED ──[health < 20%]──> DISABLED
DISABLED ──[health <= 0]──> DESTROYED
DESTROYED ──[game restart]──> GARAGE_IDLE (new vehicle)

State Definitions:
GARAGE_IDLE:   In garage, not in world, cannot be controlled
DEPLOYABLE:    Ready to deploy, awaiting player command
DEPLOYED:      In world, controllable, movement/weapon active
DISABLED:      Health < 20%, cannot move, weapons offline
DESTROYED:     Health <= 0, vehicle lost, game state change

Events:
GlobalSignals.vehicle_deployed.emit(vehicle_id)  # DEPLOYABLE → DEPLOYED
GlobalSignals.vehicle_damaged.emit(amount)       # State check in DamageReceiver
GlobalSignals.vehicle_destroyed.emit(vehicle_id) # DISABLED → DESTROYED
```

### Key Interfaces

```gdscript
enum VehicleState {
    GARAGE_IDLE,
    DEPLOYABLE,
    DEPLOYED,
    DISABLED,
    DESTROYED
}

class_name VehicleAttribute extends RefCounted

var current_state: VehicleState = VehicleState.GARAGE_IDLE
var current_health: float
var current_magic_pool: float
var cargo_contents: Dictionary  # {resource_id: count}

func transition_to(new_state: VehicleState) -> void:
    if not _is_valid_transition(current_state, new_state):
        return
    current_state = new_state
    match new_state:
        VehicleState.DEPLOYED:
            GlobalSignals.vehicle_deployed.emit(vehicle_id)
        VehicleState.DESTROYED:
            GlobalSignals.vehicle_destroyed.emit(vehicle_id)
```

## GDD Requirements Addressed

| GDD | Requirement | How Satisfied |
|-----|-------------|---------------|
| `vehicle-type-database.md` | State machine definition | 5 states defined |
| `vehicle-damage-system.md` | Health thresholds | DISABLED at <20%, DESTROYED at <=0 |

## Related

- ADR-002: VehicleTypeDB provides state definitions
- ADR-005: GlobalSignals for state change events
- ADR-009: Magic Pool — affects movement but not state