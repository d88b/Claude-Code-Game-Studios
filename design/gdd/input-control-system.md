# 输入控制系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-22
> **Implements Pillar**: Pillar 1 (战车即生命), Pillar 2 (搜打撤节奏)
> **Priority**: MVP | **Layer**: Foundation
> **System ID**: #9 (from systems-index.md)

## Overview

输入控制系统是管理所有玩家输入的Core层基础设施系统。它维护一个InputManager单例，通过Godot InputMap抽象原始键位/按钮输入为语义化动作名称（如`drive_forward`、`dig`、`place`），向下游系统分发动作事件。系统提供`is_action_pressed()`、`get_vector()`、`get_mouse_position()`等查询接口，以及`action_triggered`、`action_released`等信号通知。

作为Core层系统，输入控制系统是所有玩家交互的桥梁：**战车驾驶系统**查询`drive_*`动作获取移动输入，**方块挖掘系统**监听`dig`动作触发挖掘行为，**方块放置系统**响应`place`动作和鼠标位置进行建造。玩家不直接感知输入系统——他们按下按键、移动鼠标、握着游戏pad，感受到的是战车的响应、挖掘的反馈、放置的精准。输入系统将这些原始输入转化为游戏动作，确保响应一致性、支持重绑定、提供跨平台gamepad支持。

这服务于**Pillar 1（战车即生命）**——输入响应必须让战车驾驶感觉"我的手与战车的移动是直接连接的"；**Pillar 2（搜打撤节奏）**——快速、可靠的输入让玩家在撤退决策时不需要对抗controls。

**设计决策**：
- 使用Autoload singleton模式（extends Node），提供全局输入查询和事件分发
- 所有输入通过InputMap action abstraction — 不直接处理keycode/button_index
- 支持Keyboard/Mouse + Gamepad双输入方式，单一动作名映射多物理输入
- 提供Signal通知：`action_triggered(action_name)`, `action_released(action_name)`, `mouse_clicked(position)`

## Player Fantasy

玩家不直接感知输入控制系统——他们按下按键、移动鼠标、握着游戏pad，感受到的是**战车的响应**、**挖掘的反馈**、**撤退时的流畅决策**。输入系统是这种体验的隐形基础设施：它将物理输入转化为游戏动作，确保战车成为玩家意志的延伸，而非需要对抗的硬件接口。

**锚定时刻 1：第一次驾驶战车**

新玩家按下加速键，战车瞬间响应——引擎轰鸣、轮轴转动、灰尘飞扬。没有延迟。没有犹豫。这一刻凝固了**Pillar 1（战车即生命）**的核心承诺："这台机器听我的。"玩家后来切换到游戏pad，发现同样的即时响应——战车已经学会了读取它的驾驶员。这种统一的响应感来自InputMap抽象：键盘W、游戏pad左摇杆上推、自定义绑定都映射到同一个语义动作`drive_forward`。战车不关心硬件，它关心驾驶员的意图。

**锚定时刻 2：黄昏时的紧急撤退**

紧张战斗，燃料15%，尸群从三个方向逼近。玩家射击一组、后退、快速挖掘屏障、加速穿过缺口——五个动作在三秒内完成。每个输入被记录，每个响应即时。没有丢失指令。没有"我按了挖掘但没反应"的困惑。撤退成功是因为输入尊重了玩家的意图，而非硬件 quirks。这种流畅感来自输入系统的语义解耦：释放一个动作不阻塞另一个。**Pillar 2（搜打撤节奏）**的紧张决策不需要对抗controls——节奏完整。

**锚定时刻 3：信任机器当其他一切都失败**

废土不可预测——燃料枯竭、丧尸进化、天气转向。唯一的确定性是战车的响应。输入重绑定让每个玩家定制这种确定性：左撇子驾驶员将加速映射到小键盘，有运动障碍的玩家使用单按钮切换模式，老练幸存者将关键动作绑定到最熟悉的键位。InputMap抽象确保无论驾驶员如何指令，战车都服从。Pillar 1的承诺——"你的战车是你的生命线"——适用于所有玩家，不只是默认键位匹配的那部分人。

**没有输入系统，游戏失去什么：**

- **战车不再感觉像意志的延伸**——键盘玩家和游戏pad玩家体验不同；战车成为硬件特定行为的集合，而非统一机器
- **搜打撤节奏被打断**——玩家感受到"我按了键但没反应"或"我尝试撤退但战车没动"；撤退决策变成对抗controls而非对抗丧尸
- **部分玩家被排除**——无法到达WASD的玩家永远无法体验"战车响应我"的核心幻想；机器只服务于部分幸存者

## Detailed Design

### Core Rules

#### 1. Action Abstraction

**1.1 Naming Convention**
All InputMap actions follow `category_action` format:
- `drive_forward`, `drive_backward`, `drive_left`, `drive_right` — Vehicle movement
- `dig` — Block excavation
- `place` — Block placement
- `fire`, `aim` — Combat
- `ui_confirm`, `ui_cancel`, `ui_pause` — Interface navigation
- `camera_zoom_in`, `camera_zoom_out` — Camera control

**1.2 Action Registration**
Actions defined in `project.godot` via InputMap editor. Each action maps to one or more input events (key, mouse button, joystick axis, gamepad button). Default bindings preset; players remap via Settings UI (downstream — undesigned).

**1.3 Axis-Based Actions**
Analog inputs use paired actions:
- `drive_forward` / `drive_backward` → joystick Y-axis negative/positive
- `drive_left` / `drive_right` → joystick X-axis negative/positive
- `InputManager.get_vector()` returns normalized Vector2 with deadzone applied

---

#### 2. Input Query APIs

`InputManager` (autoload) provides:

| Method | Return | Purpose |
|--------|--------|---------|
| `is_action_pressed(action: StringName)` | bool | True if action currently held |
| `is_action_just_pressed(action: StringName)` | bool | True only on press transition frame |
| `is_action_just_released(action: StringName)` | bool | True only on release transition frame |
| `get_action_strength(action: StringName)` | float | 0.0–1.0 for analog; 0.0 or 1.0 for digital |
| `get_vector(neg_x, pos_x, neg_y, pos_y)` | Vector2 | Normalized directional input |
| `get_mouse_position()` | Vector2 | Viewport cursor position |
| `get_mouse_world_position(camera)` | Vector3 | Projected world position (requires camera) |
| `get_connected_gamepads()` | Array[int] | Connected device IDs |
| `is_gamepad_connected()` | bool | At least one gamepad active |
| `get_last_active_device()` | String | "gamepad", "keyboard", or "mouse" |

**API Properties:**
- All queries frame-accurate; state updates at `_input()` timing
- Thread-safe: queries return cached state from last frame
- Use `StringName` (`&"action"`) for performance in hot paths

---

#### 3. Event Dispatch

**3.1 Signal Definitions**

| Signal | Parameters | Emit Timing |
|--------|------------|-------------|
| `action_triggered` | `action: StringName` | Once on press transition |
| `action_released` | `action: StringName` | Once on release transition |
| `mouse_clicked` | `button: MouseButton, position: Vector2` | Mouse button press |
| `mouse_released` | `button: MouseButton, position: Vector2` | Mouse button release |
| `gamepad_connected` | `device_id: int` | Device detected/connected |
| `gamepad_disconnected` | `device_id: int` | Device unplugged |
| `input_method_changed` | `method: String` | Active device changed |

**3.2 Dispatch Process**
1. `_input(event)` captures raw events
2. Event matched against InputMap actions
3. State change → signal emitted
4. Signals dispatch **before `_process()`** of same frame
5. Driving inputs apply to **next physics tick** — no buffering

**Critical for Pillar 1**: Input processing completes within **one frame**. Driving inputs never queue — they apply immediately to physics simulation.

---

#### 4. Input Priority

**4.1 Priority Hierarchy**
When multiple inputs active simultaneously: **Gamepad > Keyboard > Mouse**

**4.2 Conflict Resolution**

| Scenario | Resolution |
|----------|------------|
| Gamepad + keyboard both steering | Gamepad analog takes priority; keyboard ignored while gamepad active |
| Keyboard + mouse same action | Keyboard takes priority |
| Two gamepads connected | `last_active_device` determines active controller |
| Axis + button same action (e.g., stick + key) | Axis value overrides button (analog precision) |

**4.3 Soft Merge for Axis Inputs**
- If gamepad neutral (< deadzone): keyboard applies
- If gamepad active: keyboard ignored
- Prevents "double acceleration" bugs while allowing fallback

---

#### 5. Digital-to-Analog Ramp Curve

**Critical for Pillar 1**: Keyboard steering must feel smooth, not twitchy.

Digital inputs simulate analog ramp:

```
steer_value = ramp_curve(hold_time)
where ramp_curve interpolates 0.0 → 1.0 over DIGITAL_RAMP_TIME
```

**Parameters (Tuning Knobs):**
- `DIGITAL_RAMP_TIME`: 200-400ms (steering ramp duration)
- `DIGITAL_RAMP_CURVE`: ease-out (quick initial, smooth near max)
- `DIGITAL_CANCEL_TIME`: 50-100ms (return to neutral on release)

**Implementation**: `InputManager` tracks `action_hold_time[action]` per digital input. `get_action_strength()` returns ramped value for keyboard sources.

---

#### 6. Mouse Handling

**6.1 Cursor Modes**

| Game State | Cursor Mode | Godot MouseMode |
|------------|-------------|-----------------|
| Exploration (下车) | Visible, free | `MOUSE_MODE_VISIBLE` |
| Driving | Hidden, confined | `MOUSE_MODE_HIDDEN` |
| Building/Placing | Visible, world-space | `MOUSE_MODE_VISIBLE` |
| Combat (shooting) | Visible if aim mode, hidden if auto-aim | Context-dependent |
| Menu/Pause | Visible, UI-space | `MOUSE_MODE_VISIBLE` |
| Hybrid driving + shooting | **Visible, vehicle-relative offset** | Custom turret cone |

**6.2 Hybrid Driving/Shooting Rule**
Mouse aims within ±90° "turret cone" relative to vehicle forward. Steering independent via keyboard/gamepad. Cursor locked to vehicle-relative offset during hybrid mode.

**6.3 Click Detection**
Mouse buttons emit `mouse_clicked`/`mouse_released` with position. Double-click detection downstream responsibility (timing check).

---

#### 7. Gamepad Support

**7.1 Device Detection**
- `_ready()` scans `Input.get_connected_joypads()`
- `Input.joy_connection_changed` signal captured
- `gamepad_connected`/`gamepad_disconnected` emitted

**7.2 Deadzone Configuration**

| Parameter | Default | Range | Purpose |
|-----------|---------|-------|---------|
| `DEADZONE_AXIS_INNER` | 0.15 | 0.05-0.25 | Ignore stick values below threshold |
| `DEADZONE_AXIS_OUTER` | 0.95 | 0.90-1.0 | Ignore edge values (hardware variance) |
| `DEADZONE_TRIGGER` | 0.10 | 0.05-0.20 | Trigger activation threshold |

Deadzone applies **before** `get_vector()` normalization.

**7.3 Vibration**
`start_vibration(device_id, weak, strong, duration)` — downstream systems call for collision feedback. `stop_vibration(device_id)` cancels.

---

### States and Transitions

Input system has no complex state machine. Primary states:

| State Dimension | Values | Transitions |
|----------------|--------|-------------|
| **Device State** | `last_active_device` | Updated on any input event |
| **Cursor State** | `MOUSE_MODE_*` | Changed by downstream systems (camera, menu) |
| **Action State** | `{action: pressed/released}` | Per-action binary state |

---

### Interactions with Other Systems

| Downstream System | Interface Used | Data Flow | Status |
|-------------------|----------------|-----------|--------|
| **战车驾驶系统 (#18)** | `get_vector("drive_*")`, `action_triggered` | Input → Movement | Undesigned |
| **方块挖掘系统 (#12)** | `is_action_pressed("dig")`, `mouse_clicked` | Input → Dig action | Undesigned |
| **方块放置系统 (#13)** | `is_action_pressed("place")`, `get_mouse_world_position()` | Input → Place action | Undesigned |
| **HUD系统 (#49)** | `get_last_active_device()` | Device → UI prompts | Undesigned |
| **音效系统 (#52)** | `action_triggered` (optional) | Input → Feedback sounds | Undesigned |

## Formulas

### 1. Digital Ramp Value Formula

**Formula:**
```
R(t) = 1 - (1 - t/T)^p    where t = min(hold_time, T)

Cancel (release):
R(t) = R_prev × (1 - Δt/C)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `hold_time` | t | float | [0, +∞) ms | Duration key held continuously |
| `DIGITAL_RAMP_TIME` | T | const | [200, 400] ms | Time to reach full strength |
| `DIGITAL_CANCEL_TIME` | C | const | [50, 100] ms | Time to return to neutral on release |
| `ease_power` | p | const | [1.5, 3.0] | Curve steepness; 2.0 = quadratic ease-out |
| `ramp_value` | R(t) | float | [0.0, 1.0] | Output strength |

**Output Range:** [0.0, 1.0]

**Example:** T=300ms, p=2.0, t=100ms → R = 1 - (0.667)^2 = 0.556

---

### 2. Deadzone-Adjusted Axis Value Formula

**Formula:**
```
V = sign(D) × clamp((|D| - I) / (O - I), 0.0, 1.0)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `raw_axis` | D | float | [-1.0, 1.0] | Raw hardware axis reading |
| `DEADZONE_AXIS_INNER` | I | const | [0.05, 0.20] | Inner deadzone threshold |
| `DEADZONE_AXIS_OUTER` | O | const | [0.90, 0.99] | Outer deadzone threshold |
| `adjusted_value` | V | float | [-1.0, 1.0] | Deadzone-adjusted output |

**Output Range:** [-1.0, 1.0]

**Example:** I=0.15, O=0.95, raw=0.50 → V = (0.35/0.80) = 0.4375

---

### 3. Soft Merge Strength Formula

**Formula (step merge):**
```
if |g| < T:  M = k
else:        M = g
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `keyboard_ramp_value` | k | float | [0.0, 1.0] | Digital ramp output |
| `gamepad_adjusted_value` | g | float | [-1.0, 1.0] | Deadzone-adjusted axis |
| `MERGE_THRESHOLD` | T | const | [0.05, 0.20] | Blend zone boundary |
| `merged_value` | M | float | [-1.0, 1.0] | Final combined input |

**Output Range:** [-1.0, 1.0]

---

### 4. `get_vector` Normalization Formula

**Formula:**
```
m = sqrt(X² + Y²)
if m < R: (X', Y') = (0.0, 0.0)
else:
  scale = min((m - R) / (1.0 - R), 1.0)
  (X', Y') = (X/m × scale, Y/m × scale)
```

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `merged_x` | X | float | [-1.0, 1.0] | Horizontal merged input |
| `merged_y` | Y | float | [-1.0, 1.0] | Vertical merged input |
| `magnitude` | m | float | [0.0, √2] | Raw vector magnitude |
| `RADIAL_DEADZONE` | R | const | [0.05, 0.20] | Circular deadzone radius |
| `output_vector` | (X', Y') | Vector2 | mag ≤ 1.0 | Normalized movement vector |

**Output Range:** Vector2 with magnitude ≤ 1.0

## Edge Cases

### 1. Multiple Input Devices Active Simultaneously

**If keyboard and gamepad both active for same axis**: Gamepad analog takes priority via soft merge (Formula 3). Keyboard ignored while gamepad magnitude ≥ MERGE_THRESHOLD. If gamepad neutral, keyboard applies.

**Example**: Keyboard ramp=0.7 + stick magnitude=0.05 → keyboard applies (M=0.7). Stick pushed to 0.40 → gamepad dominates (M=0.40).

---

### 2. Input Method Switch Mid-Action

**If player presses key then pushes stick while key held**: `last_active_device` updates. Soft merge switches immediately — gamepad takes priority, keyboard value frozen and replaced.

**Example**: Keyboard ramps to 0.6 over 150ms, stick pushed to 0.5 → output switches from 0.6 to 0.5 at next frame. No blending delay.

---

### 3. Gamepad Disconnected During Action

**If gamepad unplugged while stick held**: `gamepad_disconnected` signal emitted, `last_active_device` resets to "keyboard". If keyboard input active, ramp value applies. If keyboard inactive, steering drops to 0.0 (vehicle drifts).

---

### 4. Rebinding Creates Conflict

**If player remaps two actions to same key**: Settings UI shows warning "[Key] already bound to [Action]. Reassign?" Options: Swap, Cancel. InputManager does not resolve — UI prevents conflicts before write.

---

### 5. Hybrid Driving + Shooting Cursor Mode

**If player driving while aiming turret**: Mouse confined to "turret cone" (±90° from vehicle forward). Cursor position relative to vehicle. Steering via keyboard/gamepad independent. Mouse aims, not steers.

---

### 6. Multiple Gamepads Connected

**If two gamepads connected**: `last_active_device` tracks which received last input. Only active gamepad provides input. Inactive gamepad ignored until it receives event.

---

### 7. Key Pressed During Pause Menu

**If gameplay key pressed while pause open**: Pause sets `is_game_input_blocked = true`. InputManager ignores gameplay actions. Only `ui_*` actions processed. Resume releases block.

---

### 8. Mouse Capture During World-Space Interaction

**If player clicks world object**: `mouse_clicked` signal emits with viewport position. Downstream system projects to world space, decides interaction intent. InputManager does not interpret clicks.

## Dependencies

### Upstream Dependencies (This system depends on)

| System | Status | Interface Used | Purpose |
|--------|--------|----------------|---------|
| **None** | — | — | Foundation layer — zero upstream dependencies |

---

### Downstream Dependencies (Systems that depend on this)

| System | ID | Status | Interface Used | Purpose |
|--------|-----|--------|----------------|---------|
| **战车驾驶系统** | #18 | Not Started | `get_vector("drive_*")`, `action_triggered` | Movement input |
| **方块挖掘系统** | #12 | Not Started | `is_action_pressed("dig")`, `mouse_clicked` | Dig action trigger |
| **方块放置系统** | #13 | Not Started | `is_action_pressed("place")`, `get_mouse_world_position()` | Place target position |
| **HUD系统** | #49 | Not Started | `get_last_active_device()` | UI prompt switching |
| **音效系统** | #52 | Not Started | `action_triggered` (optional) | Input feedback sounds |
| **暂停/菜单系统** | TBD | Not Started | `is_game_input_blocked` flag | Block gameplay input |

---

### Interface Contract

**Input system MUST provide:**

| Interface | Type | Guarantee |
|-----------|------|-----------|
| `is_action_pressed(action)` | bool | Returns valid state for any registered action |
| `get_vector(...)` | Vector2 | Returns normalized vector with magnitude ≤ 1.0 |
| `get_mouse_position()` | Vector2 | Returns viewport position (0,0 to viewport_size) |
| `get_last_active_device()` | String | Returns "gamepad", "keyboard", or "mouse" |
| `action_triggered` signal | StringName | Emits once on press transition per action |
| `gamepad_connected` signal | int | Emits on device connection |

## Tuning Knobs

| Knob | Default | Safe Range | Unit | Gameplay Effect | Where Tuned |
|------|---------|------------|------|-----------------|-------------|
| `DIGITAL_RAMP_TIME` | 300 | 200-400 | ms | Keyboard steering ramp duration. Lower = snappier, Higher = smoother. | `input_manager.gd` constant |
| `DIGITAL_CANCEL_TIME` | 80 | 50-100 | ms | Return to neutral on key release. Lower = instant stop, Higher = gentle fade. | `input_manager.gd` constant |
| `ease_power` | 2.0 | 1.5-3.0 | — | Ramp curve shape. 1.5 = near-linear, 2.0 = ease-out, 3.0 = sharper ease-out. | `input_manager.gd` constant |
| `DEADZONE_AXIS_INNER` | 0.15 | 0.05-0.25 | ratio | Gamepad stick deadzone. Lower = hyper-responsive, Higher = forgiving. | `input_manager.gd` constant |
| `DEADZONE_AXIS_OUTER` | 0.95 | 0.90-0.99 | ratio | Edge values clamped. Hardware variance guard. | `input_manager.gd` constant |
| `DEADZONE_TRIGGER` | 0.10 | 0.05-0.20 | ratio | Trigger activation threshold. | `input_manager.gd` constant |
| `RADIAL_DEADZONE` | 0.15 | 0.05-0.20 | ratio | Circular deadzone for `get_vector()`. Prevents micro-drift. | `input_manager.gd` constant |
| `MERGE_THRESHOLD` | 0.15 | 0.05-0.20 | ratio | Soft merge boundary. Keyboard fallback zone. | `input_manager.gd` constant |

---

### Tuning Guidelines

**Digital Ramp Time (Pillar 1 — driving feel):**
- 200ms: Arcade-style, instant response — may feel twitchy
- 300ms: Recommended — smooth ramp, builds confidence
- 400ms: Forgiving, less precise — better for casual players

**Deadzone Inner (Pillar 1 — responsiveness):**
- 0.05: Hyper-responsive — worn sticks may drift
- 0.15: Recommended — standard, balanced
- 0.25: Forgiving — prevents accidental inputs, but less precise

**Ease Power (feel curve):**
- 1.5: Near-linear ramp — predictable but flat
- 2.0: Recommended — ease-out, quick start then smooth
- 3.0: Sharp ease-out — very quick initial, slower near max

## Visual/Audio Requirements

### Direct Visual Requirements (None)

Input system has no direct visual representation. It provides data to downstream systems that render input feedback.

**No direct visual elements owned by this system.**

---

### Downstream Visual Systems (Input-Dependent)

| System | Visual Element | Input Data Used | Requirement |
|--------|----------------|-----------------|-------------|
| **战车驾驶系统** | Steering wheel animation | `get_action_strength("drive_*")` | Wheel rotates within 16ms of input |
| **战车驾驶系统** | Vehicle lean/tilt | `get_vector()` | Hull visual responds to steering magnitude |
| **音效系统** | Engine pitch | `get_action_strength("drive_forward")` | Audio responds to throttle strength |
| **HUD系统** | Button prompt icons | `get_last_active_device()` | Prompt switches (keyboard icon vs gamepad icon) |

---

### Direct Audio Requirements (None)

Input system has no direct audio. It triggers downstream audio feedback.

---

### Downstream Audio Systems (Input-Dependent)

| System | Audio Element | Input Signal Used | Requirement |
|--------|----------------|-------------------|-------------|
| **音效系统** | Button press click (optional) | `action_triggered` | Optional: subtle click on menu confirm |
| **音效系统** | Gamepad connect chime | `gamepad_connected` | Chime when gamepad detected |
| **音效系统** | Gamepad disconnect warning | `gamepad_disconnected` | Warning sound when active gamepad unplugged |

---

### Input Feedback Timing

**Critical for Pillar 1**: All input-driven feedback must trigger within **same frame** as input receipt.

| Feedback Type | Budget | Owner System |
|----------------|--------|--------------|
| Steering animation | < 16ms | 战车驾驶 (#18) |
| Engine sound pitch | < 16ms | 音效系统 (#52) |
| Button prompt switch | < 1 frame | HUD系统 (#49) |

## UI Requirements

### Rebinding UI (Downstream — Settings System)

| Requirement | Specification | Owner |
|-------------|---------------|-------|
| All gameplay actions rebindable | Per accessibility standard — motor accessibility | Settings UI (undesigned) |
| Fixed actions (ESC, D-pad navigation) | Not exposed for rebinding | Settings UI |
| Conflict warning on duplicate binding | "[Key] already bound to [Action]. Swap or Cancel?" | Settings UI |
| Independent keyboard/gamepad bindings | Same action can have both keyboard and gamepad bindings | Settings UI |

---

### Input Method Detection UI

| UI Element | Input Data | Update Frequency |
|------------|------------|------------------|
| Button prompts | `get_last_active_device()` | On `input_method_changed` signal |
| Focus visualization | Godot 4.6 dual-focus (mouse vs keyboard/gamepad) | Automatic |

**Prompt switching**: When `input_method_changed` fires, HUD updates all button prompt icons to match active device (keyboard → WASD icon, gamepad → Xbox/PS icon).

---

### Cursor Mode Indicators

| Game State | Cursor Mode | Visual Indicator |
|------------|-------------|------------------|
| Exploration | Visible | No special indicator |
| Driving | Hidden | Optional: crosshair HUD element |
| Building | Visible + world-space | Placement ghost cursor |
| Menu | Visible | Standard UI cursor |

## Acceptance Criteria

### Core Rules

**AC-ACTION-001: Naming Convention**
**GIVEN** InputManager singleton loaded
**WHEN** querying any registered action
**THEN** all action names follow `category_action` format (regex `^[a-z]+_[a-z]+$`)

**AC-ACTION-002: Axis Pairing**
**GIVEN** gamepad stick mapped to paired actions
**WHEN** calling `get_vector()` for any stick position
**THEN** returned Vector2 magnitude ≤ 1.0

**AC-API-001: Frame-Accurate State**
**GIVEN** key pressed on frame N
**WHEN** querying `is_action_just_pressed()` during frame N
**THEN** returns `true` on frame N, `false` on frame N+1

**AC-API-002: Strength Range**
**GIVEN** any analog action
**WHEN** calling `get_action_strength()`
**THEN** return value in [0.0, 1.0]

**AC-API-003: Mouse Position Bounds**
**GIVEN** viewport size (W, H)
**WHEN** calling `get_mouse_position()`
**THEN** x in [0, W], y in [0, H]

**AC-API-004: Last Device Detection**
**GIVEN** keyboard was last, then gamepad pressed
**WHEN** calling `get_last_active_device()`
**THEN** returns "gamepad"

**AC-DISP-001: Signal Timing**
**GIVEN** action registered, listener connected
**WHEN** key pressed
**THEN** `action_triggered` emits before next `_process()`

**AC-DISP-002: Single Emit Per Transition**
**GIVEN** key held for 60 frames
**WHEN** counting emissions
**THEN** exactly 1 emission on press transition

**AC-PRIORITY-001: Gamepad Over Keyboard**
**GIVEN** gamepad magnitude 0.4 + keyboard held
**WHEN** querying merged input
**THEN** keyboard ignored, gamepad value 0.4 returned

**AC-PRIORITY-002: Keyboard Fallback**
**GIVEN** gamepad magnitude 0.03 (< threshold) + keyboard ramp 0.6
**WHEN** querying merged input
**THEN** keyboard value 0.6 returned

**AC-PRIORITY-003: Two Gamepads**
**GIVEN** gamepad 0 last active, gamepad 1 pressed
**WHEN** `get_last_active_device()` queried
**THEN** returns gamepad 1, gamepad 0 ignored

**AC-RAMP-001: Value at T=0**
**GIVEN** T=300ms, p=2.0, key held 0ms
**WHEN** `get_action_strength()` queried
**THEN** returns 0.0

**AC-RAMP-002: Value at T=100ms**
**GIVEN** T=300ms, p=2.0, key held 100ms
**WHEN** `get_action_strength()` queried
**THEN** returns 0.556 (±0.01)

**AC-RAMP-003: Value at T=300ms**
**GIVEN** T=300ms, key held ≥300ms
**WHEN** `get_action_strength()` queried
**THEN** returns 1.0

**AC-MOUSE-001: Exploration Cursor**
**GIVEN** exploration state active
**WHEN** querying cursor mode
**THEN** cursor visible (`MOUSE_MODE_VISIBLE`)

**AC-MOUSE-002: Driving Cursor**
**GIVEN** driving state active
**WHEN** querying cursor mode
**THEN** cursor hidden (`MOUSE_MODE_HIDDEN`)

**AC-GPAD-001: Detection on Ready**
**GIVEN** gamepad connected before launch
**WHEN** InputManager `_ready()` executes
**THEN** `is_gamepad_connected()` returns `true`

**AC-GPAD-002: Hot-Plug**
**GIVEN** no gamepad at start
**WHEN** gamepad plugged in
**THEN** `gamepad_connected` signal emits within 1 frame

**AC-GPAD-003: Disconnect**
**GIVEN** gamepad active
**WHEN** unplugged
**THEN** `gamepad_disconnected` signal emits, device returns "keyboard"

---

### Formulas

**AC-FORMULA-001: Ramp at t=50ms**
**GIVEN** T=300ms, p=2.0, t=50ms
**THEN** R(50) = 0.306 (±0.01)

**AC-FORMULA-002: Deadzone Inner**
**GIVEN** I=0.15, raw=0.10
**THEN** V=0.0 (below threshold)

**AC-FORMULA-003: Deadzone Outer**
**GIVEN** I=0.15, O=0.95, raw=0.98
**THEN** V=1.0 (clamped)

**AC-FORMULA-004: Merge Keyboard Fallback**
**GIVEN** T=0.15, k=0.6, g=0.10
**THEN** M=0.6 (keyboard applies)

**AC-FORMULA-005: Merge Gamepad Dominance**
**GIVEN** T=0.15, k=0.6, g=0.40
**THEN** M=0.40 (gamepad applies)

**AC-FORMULA-006: get_vector Radial Deadzone**
**GIVEN** R=0.15, X=0.10, Y=0.10
**THEN** output=(0.0, 0.0) (magnitude 0.141 < 0.15)

**AC-FORMULA-007: get_vector Normalized**
**GIVEN** X=0.6, Y=0.8, magnitude=1.0
**THEN** output=(0.6, 0.8) normalized to magnitude 1.0

---

### Edge Cases

**AC-EDGE-001: Multi-Device Same Axis**
**GIVEN** keyboard ramp=0.7 + gamepad magnitude=0.05 (< threshold)
**THEN** output=0.7 (keyboard)

**AC-EDGE-002: Method Switch Mid-Action**
**GIVEN** keyboard ramp=0.75, gamepad pushed to 0.5
**THEN** output switches immediately to 0.5 (no blending)

**AC-EDGE-003: Disconnect During Action**
**GIVEN** gamepad steering, unplugged
**THEN** steering drops to 0.0 if keyboard inactive

**AC-EDGE-004: Pause Blocks Gameplay**
**GIVEN** pause menu open, `is_game_input_blocked=true`
**WHEN** gameplay key pressed
**THEN** gameplay action NOT processed, only `ui_*` actions

---

### Integration

**AC-INT-001: Signal Contract**
**GIVEN** downstream connected to `action_triggered`
**WHEN** action "dig" pressed
**THEN** signal emits with `StringName` parameter

**AC-INT-002: API Type Contract**
**GIVEN** `get_vector()` called
**THEN** return type Vector2, components [-1.0, 1.0]

**AC-INT-003: Input Block Flag**
**GIVEN** `is_game_input_blocked=true`
**WHEN** gameplay action queried
**THEN** returns `false` for all non-UI actions

---

**Total ACs**: 35 (Core: 20, Formula: 7, Edge: 4, Integration: 3)

## Open Questions

### Q-01: Input Buffering Policy

**Question**: Should certain actions buffer when input arrives faster than game can process?

**Context**:
- Pillar 2 (搜打撤节奏) involves rapid sequences: shoot → brake → dig → accelerate
- No buffering: late inputs dropped → player frustration
- Full buffering: queue executes late → feels disconnected
- Smart buffering: some actions buffer, others don't

**Options**:
| Option | Tradeoff | Implication |
|--------|----------|-------------|
| No buffering | No delayed actions | Dropped inputs frustrate in tense moments |
| Smart buffering (dig/place buffer 1s) | Build actions forgive timing | Driving/combat never buffer — stay responsive |
| Full buffering (all actions 500ms) | All inputs preserved | Retreat feel breaks — delayed steering fatal |

**Resolution needed by**: 方块挖掘 (#12), 方块放置 (#13) design
**Currently blocked by**: Downstream systems undesigned

---

### Q-02: Analog Trigger Support

**Question**: Should gamepad triggers provide analog throttle/brake (variable strength)?

**Context**:
- Xbox/PS triggers are analog (0.0-1.0), not binary
- Driving feel could benefit from variable throttle pressure
- Adds complexity: mapping triggers to `drive_forward` action with strength

**Options**:
| Option | Tradeoff | Implication |
|--------|----------|-------------|
| Binary triggers (threshold) | Simple | Trigger = button press, full throttle or none |
| Analog triggers | More nuanced driving | Trigger pressure = throttle strength (Pillar 1 enhanced) |

**Resolution needed by**: 战车驾驶系统 (#18) design
**Currently blocked by**: Driving system undesigned

---

### Q-03: Accessibility Input Modes

**Question**: Should InputManager support accessibility input modes (toggle mode, hold-to-confirm)?

**Context**:
- Motor accessibility: some players cannot hold keys continuously
- Toggle mode: press once to start driving, press again to stop
- Hold-to-confirm: action requires hold for N ms to prevent accidental triggers

**Options**:
| Option | Tradeoff | Implication |
|--------|----------|-------------|
| Standard only | Simpler | No accessibility mode support |
| Toggle mode toggle | Accessible | Player toggles drive_forward once instead of holding |
| Both modes available | Maximum accessibility | Settings UI chooses per action |

**Resolution needed by**: Accessibility requirements review, Settings UI design
**Currently blocked by**: No accessibility spec yet