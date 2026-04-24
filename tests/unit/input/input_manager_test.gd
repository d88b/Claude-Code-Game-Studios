# input_manager_test.gd
# Unit tests for Story: Input Manager Autoload (HIGH RISK)

extends GutTest

const InputManagerScript := preload("res://src/input/input_manager.gd")

var _input_manager: Object

func before_all() -> void:
	_input_manager = InputManagerScript.new()
	add_child_autoqfree(_input_manager)

func test_input_manager_initialized() -> void:
	assert_not_null(_input_manager, "InputManager should exist")

func test_focus_mode_enum() -> void:
	# FocusMode enum values are 0, 1, 2
	assert_true(InputManagerScript.FocusMode.KEYBOARD_GAMEPAD in [0, 1, 2, 3], "KB/Gamepad mode")
	assert_true(InputManagerScript.FocusMode.MOUSE_TOUCH in [0, 1, 2, 3], "Mouse/Touch mode")
	assert_true(InputManagerScript.FocusMode.BOTH in [0, 1, 2, 3], "Both mode")

func test_action_map_initialized() -> void:
	for action: String in InputManagerScript.TRACKED_ACTIONS:
		assert_true(_input_manager.action_map.has(action), str(action) + " in action_map")

func test_is_action_pressed_returns_bool() -> void:
	var result: bool = _input_manager.is_action_pressed("move_up")
	assert_true(typeof(result) == TYPE_BOOL, "Should return bool")

func test_get_mouse_position_returns_vector2() -> void:
	var pos: Vector2 = _input_manager.get_mouse_position()
	assert_true(typeof(pos) == TYPE_VECTOR2, "Should return Vector2")

func test_get_joystick_direction_returns_vector2() -> void:
	var dir: Vector2 = _input_manager.get_joystick_direction()
	assert_true(typeof(dir) == TYPE_VECTOR2, "Should return Vector2")

func test_get_focus_mode_returns_enum() -> void:
	var mode: int = _input_manager.get_focus_mode()
	assert_true(mode in [InputManagerScript.FocusMode.KEYBOARD_GAMEPAD, InputManagerScript.FocusMode.MOUSE_TOUCH, InputManagerScript.FocusMode.BOTH], "Valid focus mode")

func test_joystick_dead_zone_applied() -> void:
	# 验证死区阈值存在
	assert_eq(_input_manager.JOYSTICK_DEAD_ZONE, 0.2, "Dead zone = 0.2")

func test_tracked_actions_complete() -> void:
	assert_true("move_up" in InputManagerScript.TRACKED_ACTIONS, "move_up tracked")
	assert_true("fire" in InputManagerScript.TRACKED_ACTIONS, "fire tracked")
	assert_true("dig" in InputManagerScript.TRACKED_ACTIONS, "dig tracked")
	assert_true("place" in InputManagerScript.TRACKED_ACTIONS, "place tracked")
	assert_true("pause" in InputManagerScript.TRACKED_ACTIONS, "pause tracked")