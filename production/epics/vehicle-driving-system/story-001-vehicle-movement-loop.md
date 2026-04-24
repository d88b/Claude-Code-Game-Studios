# Story 001: Vehicle Movement Loop

> **Epic**: VehicleDrivingSystem
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/vehicle-driving-system.md`
**Requirement**: `TR-driving-001`, `TR-driving-002`, `TR-driving-003`

**ADR Governing Implementation**: ADR-003: Input System (⚠️ HIGH), ADR-005: Event Bus
**ADR Decision Summary**: VehicleController 执行 Input → velocity → collision → magic → apply 循环。

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: ⚠️ HIGH RISK: Dual-focus 是 Godot 4.6 新特性，需验证 KB/gamepad 与 mouse/touch 分离行为。

---

## Acceptance Criteria

- [ ] Acceleration: velocity += acceleration_rate * input_direction * delta
- [ ] Speed clamp: |velocity| <= max_speed (from VehicleTypeDB)
- [ ] Magic consumption: cells * MAGIC_COST_PER_CELL (TK-013 = 0.5)
- [ ] Collision response via CollisionManager.check_swept_collision()
- [ ] ⚠️ HIGH RISK: Dual-focus tested on target engine

---

## Implementation Notes

```gdscript
class_name VehicleController extends CharacterBody2D

const MAGIC_COST_PER_CELL: float = 0.5  # TK-013

func _physics_process(delta: float) -> void:
    # Input → velocity
    var input_dir = InputManager.get_joystick_direction()
    velocity += acceleration_rate * input_dir * delta
    
    # Speed clamp
    velocity = velocity.limit_length(max_speed)
    
    # Collision check
    var collision = CollisionManager.check_swept_collision(body_rect, velocity)
    if collision.hit:
        velocity *= 0.5  # Bounce factor
    
    # Magic consumption
    var cells_moved = velocity.length() / CELL_SIZE
    VehicleAttribute.consume_magic(cells_moved * MAGIC_COST_PER_CELL)
    
    # Apply movement
    move_and_slide()
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/driving/vehicle_movement_test.gd`
**Status**: [x] Created — 38 test cases covering TR-driving-001/002/003

---

## Dependencies

- Depends on: InputManager (⚠️ HIGH), CollisionManager, VehicleAttribute
- Unlocks: ExplorationAreaSystem

---

## Completion Notes

**Completed**: 2026-04-24
**Criteria**: 4/5 passing (1 deferred — Dual-focus requires Godot 4.6 playtest)
**Deviations**: 
- ADVISORY: Base class `Node2D` instead of `CharacterBody2D` — ADR-006 compliant (swept collision instead of move_and_slide)
- Extra files: `vehicle_attribute.gd` created as dependency prerequisite
**Test Evidence**: Logic — `tests/unit/driving/vehicle_movement_test.gd` (38 test cases)
**Code Review**: Complete — APPROVED WITH SUGGESTIONS (minor style issues, non-blocking)