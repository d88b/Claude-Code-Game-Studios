# ADR-003: Input System Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

输入系统使用 InputManager Autoload，封装 Godot Input singleton，处理 dual-focus（KB/gamepad vs mouse/touch 分离）。提供 action_map 状态快照和 mouse_position。这解决跨模块输入访问问题，并正确处理 Godot 4.6 dual-focus 系统的 HIGH RISK API 变化。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Input (Input singleton, Focus management) |
| **Knowledge Risk** | HIGH — Dual-focus system introduced in Godot 4.6, post-cutoff |
| **References Consulted** | `docs/engine-reference/godot/modules/input.md` (dual-focus system), `docs/engine-reference/godot/breaking-changes.md` (4.6 UI dual-focus) |
| **Post-Cutoff APIs Used** | Dual-focus separation (KB/gamepad vs mouse/touch focus) — Godot 4.6 |
| **Verification Required** | Test with both keyboard/gamepad input AND mouse/touch input; verify focus state tracking; test gamepad navigation in UI |

> **⚠️ HIGH RISK**: Godot 4.6 introduced dual-focus system. Mouse/touch focus is now SEPARATE from keyboard/gamepad focus. `grab_focus()` only affects KB/gamepad focus, not mouse hover focus. Visual feedback may differ by input method. This ADR must be re-validated if engine upgrades beyond 4.6.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-005 (Event Bus Architecture) — GlobalSignals.action_changed, focus_changed |
| **Enables** | ADR-008 (Movement and Physics), VehicleController, DigController, PlaceController, MenuSystem |
| **Blocks** | All input-driven systems until Accepted |
| **Ordering Note** | Foundation layer — created after Event Bus, before Core Movement |

## Context

### Problem Statement

铁锈魔潮需要多种输入方式：
- Keyboard/Mouse: 战车驾驶 WASD，鼠标瞄准射击，鼠标点击挖掘/放置
- Gamepad: 战车驾驶 joystick，A 键射击，B 键挖掘
- UI Navigation: 键盘 Tab/gamepad D-pad 导航菜单
- 输入映射: `move_up`, `move_down`, `move_left`, `move_right`, `fire`, `dig`, `place`

如何统一处理输入，并正确应对 Godot 4.6 dual-focus 系统变化？

### Current State

GDD `design/gdd/input-control-system.md` 定义了输入映射，但未明确 dual-focus 处理机制。

### Constraints

- Godot 4.6 dual-focus: KB/gamepad focus ≠ mouse/touch focus
- 目标平台 PC (Steam/Epic)，支持 keyboard + mouse + gamepad
- UI 必须支持 gamepad navigation（console port 潜在需求）
- 输入必须在 frame budget 内处理（<0.5ms）
- 无 hover-only interactions（必须支持 gamepad）

### Requirements

- 输入抽象：InputManager 封装 Godot Input singleton
- 状态快照：action_map 提供当前按键状态（避免每帧多次查询）
- Mouse tracking: mouse_position (grid coordinates), mouse_action (click/drag)
- Gamepad support: joystick 方向，button 映射
- Dual-focus handling: 跟踪当前 focus type，正确处理 UI 导航
- 事件广播：action_changed, focus_changed, mouse_clicked

## Decision

**InputManager Autoload with Dual-Focus Handling**：
- InputManager 是 Autoload，封装 Input singleton
- 提供 `action_map` 状态快照（每帧更新）
- 提供 `mouse_position`（转换为 grid coordinates）
- 提供 `current_focus`（KB_GAMEPAD / MOUSE_TOUCH / BOTH）
- 正确处理 dual-focus：KB/gamepad 输入不影响 mouse hover 状态

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         INPUT SYSTEM ARCHITECTURE                             │
└─────────────────────────────────────────────────────────────────────────────┘

InputManager (Autoload)
│
├─── State Snapshot (per-frame):
│    ├─── action_map: Dictionary {
│    │         "move_up": bool,
│    │         "move_down": bool,
│    │         "move_left": bool,
│    │         "move_right": bool,
│    │         "fire": bool,
│    │         "dig": bool,
│    │         "place": bool,
│    │         "menu_toggle": bool,
│    │         "pause": bool
│    │     }
│    ├─── mouse_position: Vector2i (grid coordinates, pixels / CELL_SIZE)
│    ├─── mouse_action: MouseAction (NONE, LEFT_CLICK, RIGHT_CLICK, DRAG_START, DRAG_END)
│    ├─── joystick_direction: Vector2 (-1.0 to 1.0, normalized)
│    ├─── is_gamepad_active: bool (true if gamepad connected and used recently)
│    └─── current_focus: InputFocus (KEYBOARD_GAMEPAD, MOUSE_TOUCH, BOTH)
│
├─── _process(delta): update state snapshot
│    │
│    ├─── Update action_map from Input singleton
│    │         for action in ACTIONS:
│    │             action_map[action] = Input.is_action_pressed(action)
│    │
│    ├─── Update mouse_position
│    │         mouse_position = Input.get_mouse_position() / CELL_SIZE
│    │
│    ├─── Update joystick_direction
│    │         joystick_direction = Input.get_vector(
│    │             "move_left", "move_right", "move_up", "move_down")
│    │
│    ├─── Detect focus change
│    │         if Input.is_key_pressed() or Input.is_joy_button_pressed():
│    │             current_focus = InputFocus.KEYBOARD_GAMEPAD
│    │         elif mouse_moved_this_frame:
│    │             current_focus = InputFocus.MOUSE_TOUCH
│    │         emit focus_changed if different
│    │
│    └─── Detect gamepad connection/disconnection
│
├─── _input(event): handle discrete events
│    │
│    ├─── InputEventMouseButton:
│    │         if event.pressed:
│    │             mouse_action = MouseAction.LEFT_CLICK (button 1)
│    │                          or MouseAction.RIGHT_CLICK (button 2)
│    │             GlobalSignals.mouse_clicked.emit(mouse_position, button)
│    │         else:
│    │             mouse_action = MouseAction.NONE
│    │
│    ├─── InputEventMouseMotion:
│    │         track mouse_moved_this_frame = true
│    │
│    ├─── InputEventJoypadButton:
│    │         map to action (JOY_BUTTON_A → fire, JOY_BUTTON_B → dig)
│    │
│    └─── InputEventKey:
│    │         handle menu shortcuts (ESC → pause, TAB → menu_toggle)
│
├─── Public Methods:
│    ├─── is_action_pressed(action: StringName) → bool
│    ├─── is_action_just_pressed(action: StringName) → bool
│    ├─── get_current_focus() → InputFocus
│    ├─── get_joystick_direction() → Vector2
│    ├─── get_mouse_grid_position() → Vector2i
│    └─── is_gamepad_connected() → bool
│
└─── Constants:
     ├─── ACTIONS: Array[StringName] = [
     │         &"move_up", &"move_down", &"move_left", &"move_right",
     │         &"fire", &"dig", &"place", &"menu_toggle", &"pause"
     │     ]
     ├─── CELL_SIZE: int = 32  # From entities.yaml


Dual-Focus Handling (Godot 4.6):
─────────────────────────────────────────────────────────────────────────────
⚠️ CRITICAL: In Godot 4.6, KB/gamepad focus and mouse/touch focus are SEPARATE.

1. Keyboard/Gamepad Input:
   - WASD, joystick, gamepad buttons
   - Affects: action_map, joystick_direction
   - Focus state: KEYBOARD_GAMEPAD
   - UI: grab_focus() affects KB/gamepad focus only

2. Mouse/Touch Input:
   - Mouse movement, clicks, touch gestures
   - Affects: mouse_position, mouse_action
   - Focus state: MOUSE_TOUCH
   - UI: hover focus is separate from grab_focus()

3. BOTH State:
   - User may use both simultaneously (e.g., WASD + mouse aim)
   - Focus state: BOTH
   - Both action_map and mouse_position are valid

Implementation Rule:
- Do NOT assume mouse hover = keyboard focus
- Do NOT call grab_focus() expecting mouse focus
- Test with both input methods separately and together
─────────────────────────────────────────────────────────────────────────────
```

### Key Interfaces

```gdscript
# InputManager — Public API
# File: src/foundation/input_manager.gd

class_name InputManager extends Node

# === Constants ===
const CELL_SIZE: int = 32
const ACTIONS: Array[StringName] = [
    &"move_up", &"move_down", &"move_left", &"move_right",
    &"fire", &"dig", &"place", &"menu_toggle", &"pause"
]

# === State Snapshot ===
var action_map: Dictionary = {}  # {StringName: bool}
var mouse_position: Vector2i = Vector2i.ZERO  # Grid coordinates
var mouse_action: MouseAction = MouseAction.NONE
var joystick_direction: Vector2 = Vector2.ZERO
var is_gamepad_active: bool = false
var current_focus: InputFocus = InputFocus.KEYBOARD_GAMEPAD

# Internal tracking
var _mouse_moved_this_frame: bool = false
var _previous_action_map: Dictionary = {}  # For detecting changes

# === Public Methods ===

func is_action_pressed(action: StringName) -> bool:
    # Returns current state from action_map snapshot
    return action_map.get(action, false)

func is_action_just_pressed(action: StringName) -> bool:
    # Returns true if action changed from false to true this frame
    return action_map.get(action, false) and not _previous_action_map.get(action, false)

func get_current_focus() -> InputFocus:
    return current_focus

func get_joystick_direction() -> Vector2:
    return joystick_direction

func get_mouse_grid_position() -> Vector2i:
    return mouse_position

func get_mouse_world_position() -> Vector2:
    # Returns pixel coordinates (mouse_position * CELL_SIZE)
    return Vector2(mouse_position.x * CELL_SIZE, mouse_position.y * CELL_SIZE)

func is_gamepad_connected() -> bool:
    return Input.get_connected_joypads().size() > 0

# === Lifecycle ===

func _ready() -> void:
    # Initialize action_map
    for action in ACTIONS:
        action_map[action] = false
        _previous_action_map[action] = false
    # Check initial gamepad state
    is_gamepad_active = is_gamepad_connected()

func _process(delta: float) -> void:
    # Update state snapshot
    _update_action_map()
    _update_mouse_position()
    _update_joystick_direction()
    _detect_focus_change()
    _detect_gamepad_change()
    _mouse_moved_this_frame = false

func _input(event: InputEvent) -> void:
    # Handle discrete events
    if event is InputEventMouseButton:
        _handle_mouse_button(event)
    elif event is InputEventMouseMotion:
        _mouse_moved_this_frame = true
    elif event is InputEventJoypadButton:
        _handle_joypad_button(event)
    elif event is InputEventKey:
        _handle_key_event(event)

# === Internal Methods ===

func _update_action_map() -> void:
    for action in ACTIONS:
        var was_pressed = action_map[action]
        var is_pressed = Input.is_action_pressed(action)
        action_map[action] = is_pressed

        # Emit action_changed if state changed
        if was_pressed != is_pressed:
            GlobalSignals.action_changed.emit(action, is_pressed)

    # Store for next frame's "just_pressed" detection
    _previous_action_map = action_map.duplicate()

func _update_mouse_position() -> void:
    var mouse_pixel_pos = get_viewport().get_mouse_position()
    mouse_position = Vector2i(
        int(mouse_pixel_pos.x / CELL_SIZE),
        int(mouse_pixel_pos.y / CELL_SIZE)
    )

func _update_joystick_direction() -> void:
    joystick_direction = Input.get_vector(
        &"move_left", &"move_right", &"move_up", &"move_down"
    )

func _detect_focus_change() -> void:
    var new_focus: InputFocus

    # Check KB/gamepad activity
    var kb_active = false
    for action in ACTIONS:
        if Input.is_action_pressed(action):
            kb_active = true
            break

    var gamepad_active = joystick_direction != Vector2.ZERO or is_gamepad_active

    # Check mouse activity
    var mouse_active = _mouse_moved_this_frame or mouse_action != MouseAction.NONE

    if kb_active or gamepad_active:
        if mouse_active:
            new_focus = InputFocus.BOTH
        else:
            new_focus = InputFocus.KEYBOARD_GAMEPAD
    else:
        if mouse_active:
            new_focus = InputFocus.MOUSE_TOUCH
        else:
            # No input this frame, keep previous focus
            new_focus = current_focus

    if new_focus != current_focus:
        current_focus = new_focus
        GlobalSignals.focus_changed.emit(current_focus)

func _detect_gamepad_change() -> void:
    var connected = is_gamepad_connected()
    if connected != is_gamepad_active:
        is_gamepad_active = connected
        # Could emit gamepad_connected/disconnected signal if needed

func _handle_mouse_button(event: InputEventMouseButton) -> void:
    if event.pressed:
        if event.button_index == MOUSE_BUTTON_LEFT:
            mouse_action = MouseAction.LEFT_CLICK
        elif event.button_index == MOUSE_BUTTON_RIGHT:
            mouse_action = MouseAction.RIGHT_CLICK
        GlobalSignals.mouse_clicked.emit(mouse_position, event.button_index)
    else:
        mouse_action = MouseAction.NONE

func _handle_joypad_button(event: InputEventJoypadButton) -> void:
    # Map gamepad buttons to actions
    # This is handled by Input Map in project settings, but we track it here
    pass

func _handle_key_event(event: InputEventKey) -> void:
    # Handle special keys not in action map
    if event.keycode == KEY_ESCAPE and event.pressed:
        # Pause/menu toggle handled by action_map["pause"]
        pass


# MouseAction Enum
# File: src/foundation/mouse_action.gd

enum MouseAction {
    NONE,
    LEFT_CLICK,
    RIGHT_CLICK,
    DRAG_START,
    DRAG_END
}


# InputFocus Enum
# File: src/foundation/input_focus.gd

enum InputFocus {
    KEYBOARD_GAMEPAD,  # KB/gamepad input active
    MOUSE_TOUCH,       # Mouse/touch input active
    BOTH               # Both input methods active simultaneously
}
```

### Implementation Guidelines

1. **Input Map Configuration**: 在 Godot 项目设置中配置 Input Map：
   - `move_up`: W, Up Arrow, Joystick Up
   - `move_down`: S, Down Arrow, Joystick Down
   - `move_left`: A, Left Arrow, Joystick Left
   - `move_right`: D, Right Arrow, Joystick Right
   - `fire`: Space, Left Mouse, Joystick A
   - `dig`: F, Right Mouse, Joystick B
   - `place`: G, Middle Mouse, Joystick X
   - `menu_toggle`: Tab, Joystick Start
   - `pause`: Escape, Joystick Select

2. **Autoload Registration**: `InputManager` in `project.godot` as `input_manager`

3. **Dual-Focus Testing**:
   - Test keyboard only: WASD movement, no mouse
   - Test gamepad only: joystick movement, no KB
   - Test mouse only: click interactions, no KB/gamepad
   - Test BOTH: WASD + mouse aim (common FPS/strategy pattern)

4. **UI Navigation**: UI 必须支持 gamepad D-pad navigation，不能依赖 mouse hover

5. **No Hover-Only Interactions**: 所有 UI 交互必须有 gamepad/KB 替代方案

6. **Frame Budget**: action_map update 是 O(9) operations，<0.1ms

## Alternatives Considered

### Alternative 1: Direct Input Singleton Access

- **Description**: 每个系统直接调用 `Input.is_action_pressed()`
- **Pros**: 最简单，无抽象层
- **Cons**: 无状态快照（多次查询），无 focus tracking，分散调用点
- **Estimated Effort**: 更低
- **Rejection Reason**: 需要统一处理 dual-focus，需要状态快照避免重复查询

### Alternative 2: Event-Driven Only (No Snapshot)

- **Description**: 只使用 `_input(event)` 处理离散事件，无 per-frame snapshot
- **Pros**: 更符合 Godot 原生模式
- **Cons**: 持续按键（WASD movement）需要累积事件，难以处理
- **Estimated Effort**: 相同
- **Rejection Reason**: 持续按键（movement）需要 snapshot，不适合纯事件驱动

### Alternative 3: Per-Module Input Handling

- **Description**: VehicleController, DigController 各自处理输入
- **Pros**: 无全局依赖
- **Cons**: 输入逻辑分散，难以同步，难以处理 focus
- **Estimated Effort**: 更低
- **Rejection Reason**: 输入需要统一管理，尤其是 dual-focus 和 gamepad detection

## Consequences

### Positive

- 状态快照：避免每帧多次 Input singleton 查询
- Dual-focus handling：正确处理 Godot 4.6 分离 focus
- Focus tracking：UI 可根据 focus type 切换视觉反馈
- Gamepad support：统一检测 gamepad 连接状态
- 事件广播：action_changed, focus_changed 驱动 UI 更新

### Negative

- Autoload 依赖：所有输入系统依赖 InputManager
- 每帧 update overhead：action_map update（9 actions）每帧执行
- Dual-focus complexity：需要测试两种输入模式的分离

### Neutral

- 这是游戏输入系统的标准模式，但 dual-focus 是 Godot 4.6 特有变化

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| Dual-focus 行为不符合预期 | Medium | Medium | Test both input modes thoroughly |
| Gamepad 连接检测不准确 | Low | Low | Use Input.get_connected_joypads() API |
| Input Map 配置遗漏 | Medium | Low | 代码审查检查所有 action 定义 |
| Focus state 不稳定（频繁切换） | Low | Low | 保持 previous focus，只在实际变化时 emit |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (action_map update) | 0 | <0.1ms/frame | 16.6ms/frame |
| Memory (InputManager) | 0 | <1KB | 512MB ceiling |
| Events (per minute) | 0 | Variable | Low |

action_map update: 9 actions × Input.is_action_pressed() = 9 calls, ~0.05ms.

## Migration Plan

新架构，无迁移。

**Rollback plan**: If dual-focus proves problematic, can simplify to Alternative 1 (Direct Input singleton access), but loses focus tracking.

## Validation Criteria

- [ ] InputManager Autoload registered
- [ ] All 9 actions defined in Input Map
- [ ] is_action_pressed(&"move_up") returns correct state
- [ ] get_mouse_grid_position() returns valid grid coordinates
- [ ] get_joystick_direction() returns normalized Vector2
- [ ] get_current_focus() returns correct InputFocus enum
- [ ] GlobalSignals.focus_changed emitted on focus change
- [ ] Test keyboard-only input (WASD, no mouse)
- [ ] Test gamepad-only input (joystick, no KB)
- [ ] Test mouse-only input (click, no KB/gamepad)
- [ ] Test BOTH input (WASD + mouse simultaneously)
- [ ] UI navigable with gamepad D-pad (no mouse required)

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/input-control-system.md` | InputControl | Dual-focus input system (KB/gamepad vs mouse/touch) | InputFocus enum, focus tracking, correct dual-focus handling |
| `design/gdd/input-control-system.md` | InputControl | Input action mapping: move_up/down/left/right, fire, dig, place | ACTIONS constant, Input Map configuration |
| `design/gdd/vehicle-driving-system.md` | VehicleDriving | WASD/joystick for vehicle movement | InputManager.is_action_pressed(), joystick_direction |
| `design/gdd/block-digging-system.md` | BlockDigging | F/right-click for digging | InputManager.mouse_action, action_map["dig"] |
| `design/gdd/block-placing-system.md` | BlockPlacing | G/middle-click for placing | InputManager.mouse_action, action_map["place"] |

## Related

- ADR-005: Event Bus Architecture — GlobalSignals.action_changed, focus_changed, mouse_clicked
- ADR-008: Movement and Physics Integration — uses InputManager.joystick_direction
- ADR-007: Vehicle State Machine Architecture — uses InputManager.action_map for driving
- ADR-013: Build System Architecture — uses InputManager for dig/place actions