# Story 001: Input Manager Autoload

> **Epic**: InputControlSystem
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/input-control-system.md`
**Requirement**: `TR-input-001`, `TR-input-002`

**ADR Governing Implementation**: ADR-003: Input System Architecture
**ADR Decision Summary**: InputManager Autoload 处理 dual-focus 系统（KB/gamepad vs mouse/touch）。⚠️ HIGH RISK: Godot 4.6 dual-focus 新特性。

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: Dual-focus 是 Godot 4.6 新特性，需验证行为。KB/gamepad focus 与 mouse/touch 独立。

---

## Acceptance Criteria

- [ ] InputManager Autoload 注册
- [ ] Dual-focus handling: track current_focus (KEYBOARD_GAMEPAD, MOUSE_TOUCH, BOTH)
- [ ] action_map 状态快照: move_up/down/left/right, fire, dig, place, menu_toggle, pause
- [ ] is_action_pressed(action) returns bool per frame
- [ ] get_mouse_position() returns world position (grid coordinates)
- [ ] get_joystick_direction() returns Vector2
- [ ] ⚠️ HIGH RISK: Dual-focus tested on target engine

---

## Implementation Notes

```gdscript
class_name InputManager extends Node

enum FocusMode { KEYBOARD_GAMEPAD, MOUSE_TOUCH, BOTH }

var current_focus: FocusMode
var action_map: Dictionary = {}  # {action_name: bool}
var mouse_position: Vector2
var joystick_direction: Vector2

func _process(delta: float) -> void:
    # Update action_map snapshot
    for action in ["move_up", "move_down", "move_left", "move_right", "fire", "dig", "place"]:
        action_map[action] = Input.is_action_pressed(action)
    
    # Track dual-focus (Godot 4.6 feature)
    _update_focus_mode()
```

---

## QA Test Cases

- **AC-1**: Action query
  - Given: player presses "move_up" key
  - When: is_action_pressed("move_up") called
  - Then: returns true for that frame

- **AC-2**: Dual-focus validation (HIGH RISK)
  - Given: KB input and mouse input simultaneously
  - When: current_focus checked
  - Then: FocusMode.BOTH correctly detected

---

## Test Evidence

**Type**: Integration
**Required**: `tests/unit/input/input_manager_test.gd`
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None (Foundation layer)
- Unlocks: VehicleController, UI systems