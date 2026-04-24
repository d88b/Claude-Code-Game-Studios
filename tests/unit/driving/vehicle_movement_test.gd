# vehicle_movement_test.gd
# Unit tests for Story: Vehicle Movement Loop
# tests/unit/driving/vehicle_movement_test.gd
## TR-driving-001: Acceleration formula
## TR-driving-002: Speed clamp
## TR-driving-003: Magic consumption

extends GutTest

const VehicleControllerScript := preload("res://src/driving/vehicle_controller.gd")
const VehicleAttributeScript := preload("res://src/core/vehicle_attribute.gd")

var _controller: Object
var _mock_input: Object
var _mock_collision: Object
var _mock_vehicle_attr: Object
var _mock_vehicle_type_db: Object
var _mock_global_signals: Object

# === Mock 类定义 ===

class MockInputManager extends Node:
	## 模拟输入方向
	var mock_direction: Vector2 = Vector2.ZERO

	func get_joystick_direction() -> Vector2:
		return mock_direction

	func set_direction(dir: Vector2) -> void:
		mock_direction = dir

class MockCollisionManager extends Node:
	## 模拟碰撞结果
	var mock_hit: bool = false
	var mock_hit_cell: Vector2i = Vector2i.ZERO
	var mock_severity: float = 0.0
	var mock_remaining_velocity: Vector2 = Vector2.ZERO

	class MockResult:
		var hit: bool = false
		var hit_cell: Vector2i = Vector2i.ZERO
		var severity: float = 0.0
		var remaining_velocity: Vector2 = Vector2.ZERO
		var hit_position: Vector2 = Vector2.ZERO
		var hit_block_id: int = 0

		func _init(h: bool, c: Vector2i, s: float, r: Vector2) -> void:
			hit = h
			hit_cell = c
			severity = s
			remaining_velocity = r

	func check_swept_collision(body_rect: Rect2, velocity: Vector2) -> Object:
		if mock_hit:
			return MockResult.new(true, mock_hit_cell, mock_severity, mock_remaining_velocity)
		else:
			return MockResult.new(false, Vector2i.ZERO, 0.0, velocity)

	func set_collision_result(hit: bool, cell: Vector2i = Vector2i.ZERO, severity: float = 0.0, remaining: Vector2 = Vector2.ZERO) -> void:
		mock_hit = hit
		mock_hit_cell = cell
		mock_severity = severity
		mock_remaining_velocity = remaining

class MockVehicleTypeDB extends Node:
	class MockStats:
		var max_speed: float = 200.0
		var acceleration_rate: float = 500.0

	func get_vehicle_stats(vehicle_id: int) -> Object:
		return MockStats.new()

class MockGlobalSignals extends Node:
	## vehicle_damaged 信号记录
	var damaged_amount: float = 0.0
	var damaged_count: int = 0

	signal vehicle_damaged(amount: float)
	signal magic_pool_changed(current: float, max_pool: float)
	signal vehicle_state_changed(state: int)

	func emit_vehicle_damaged(amount: float) -> void:
		damaged_amount = amount
		damaged_count += 1

# === Setup ===

func before_each() -> void:
	# 创建 mock 对象
	_mock_input = MockInputManager.new()
	_mock_collision = MockCollisionManager.new()
	_mock_vehicle_type_db = MockVehicleTypeDB.new()
	_mock_global_signals = MockGlobalSignals.new()

	# 创建 VehicleAttribute
	_mock_vehicle_attr = VehicleAttributeScript.new()
	_mock_vehicle_attr.set_dependencies(_mock_vehicle_type_db, _mock_global_signals)
	_mock_vehicle_attr.initialize(1)

	# 创建 VehicleController
	_controller = VehicleControllerScript.new()
	_controller.set_dependencies(_mock_input, _mock_collision, _mock_vehicle_attr, _mock_vehicle_type_db, _mock_global_signals)
	add_child_autoqfree(_controller)

	# 同时添加 VehicleAttribute 作为子节点
	_controller.add_child(_mock_vehicle_attr)

func after_each() -> void:
	# 清理
	if _mock_input != null:
		_mock_input.queue_free()
	if _mock_collision != null:
		_mock_collision.queue_free()
	if _mock_vehicle_type_db != null:
		_mock_vehicle_type_db.queue_free()
	if _mock_global_signals != null:
		_mock_global_signals.queue_free()

# === TR-driving-001: 加速度公式测试 ===

func test_acceleration_formula_with_input() -> void:
	# Arrange
	var initial_velocity: Vector2 = Vector2.ZERO
	_controller.set_velocity_for_test(initial_velocity)
	_mock_input.set_direction(Vector2(1.0, 0.0))  # 向右
	var delta: float = 0.016  # 60fps
	var expected_accel: float = 500.0  # acceleration_rate

	# Act
	_controller._apply_acceleration(Vector2(1.0, 0.0), delta)

	# Assert
	var expected: float = expected_accel * delta  # 500 * 0.016 = 8.0
	assert_almost_eq(_controller.velocity.x, expected, 0.1, "TR-driving-001: velocity += accel * input * delta")

func test_acceleration_formula_with_diagonal_input() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2.ZERO)
	var input_dir: Vector2 = Vector2(1.0, 1.0).normalized()  # 对角线
	var delta: float = 0.016
	var accel: float = 500.0

	# Act
	_controller._apply_acceleration(input_dir, delta)

	# Assert
	var expected_length: float = accel * delta  # 加速度标量
	assert_almost_eq(_controller.velocity.length(), expected_length, 0.1, "Diagonal acceleration magnitude correct")

func test_acceleration_adds_to_existing_velocity() -> void:
	# Arrange
	var initial: Vector2 = Vector2(50.0, 0.0)
	_controller.set_velocity_for_test(initial)
	_mock_input.set_direction(Vector2(1.0, 0.0))
	var delta: float = 0.016

	# Act
	_controller._apply_acceleration(Vector2(1.0, 0.0), delta)

	# Assert
	var expected: float = 50.0 + 500.0 * delta  # 50 + 8 = 58
	assert_almost_eq(_controller.velocity.x, expected, 0.1, "Acceleration adds to existing velocity")

func test_deceleration_when_no_input() -> void:
	# Arrange
	var initial: Vector2 = Vector2(100.0, 0.0)
	_controller.set_velocity_for_test(initial)
	_mock_input.set_direction(Vector2.ZERO)  # 无输入
	var delta: float = 0.016

	# Act
	_controller._apply_acceleration(Vector2.ZERO, delta)

	# Assert
	var drag_factor: float = 1.0 - _controller.DRAG_COEFFICIENT * delta  # 1 - 0.016 = 0.984
	var expected: float = 100.0 * drag_factor
	assert_almost_eq(_controller.velocity.x, expected, 1.0, "Natural deceleration applied when no input")

# === TR-driving-002: 速度限制测试 ===

func test_speed_clamp_to_max_speed() -> void:
	# Arrange
	var excessive_velocity: Vector2 = Vector2(300.0, 0.0)  # 超过 max_speed=200
	_controller.set_velocity_for_test(excessive_velocity)

	# Act
	_controller._clamp_speed()

	# Assert
	assert_almost_eq(_controller.velocity.length(), 200.0, 0.1, "TR-driving-002: |velocity| <= max_speed")
	assert_eq(_controller.velocity.x, 200.0, "Velocity clamped to max_speed")

func test_speed_clamp_preserves_direction() -> void:
	# Arrange
	var excessive: Vector2 = Vector2(250.0, 250.0)  # 超过 max_speed
	_controller.set_velocity_for_test(excessive)

	# Act
	_controller._clamp_speed()

	# Assert
	assert_almost_eq(_controller.velocity.length(), 200.0, 0.1, "Speed clamped to max")
	# 方向应该保持不变 (只是长度限制)
	var original_angle: float = Vector2(250.0, 250.0).angle()
	assert_almost_eq(_controller.velocity.angle(), original_angle, 0.01, "Direction preserved after clamp")

func test_speed_clamp_no_change_when_below_max() -> void:
	# Arrange
	var normal: Vector2 = Vector2(50.0, 50.0)
	_controller.set_velocity_for_test(normal)

	# Act
	_controller._clamp_speed()

	# Assert
	assert_eq(_controller.velocity, normal, "Velocity unchanged when below max_speed")

# === TR-driving-003: 魔能消耗测试 ===

func test_magic_consumption_per_cell() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2(32.0, 0.0))  # 32 pixels/sec = 1 cell/sec
	_mock_vehicle_attr.set_magic_for_test(100.0)
	var delta: float = 1.0  # 1秒移动

	# Act
	var consumed: float = _controller._consume_magic_for_movement(delta)

	# Assert
	# cells_moved = 32 * 1 / 32 = 1 cell
	# magic_cost = 1 * 0.5 = 0.5
	assert_almost_eq(consumed, 0.5, 0.01, "TR-driving-003: cells * MAGIC_COST_PER_CELL")
	assert_almost_eq(_mock_vehicle_attr.current_magic, 99.5, 0.01, "Magic consumed correctly")

func test_magic_consumption_scaled_by_speed() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2(64.0, 0.0))  # 2 cells/sec
	_mock_vehicle_attr.set_magic_for_test(100.0)
	var delta: float = 1.0

	# Act
	var consumed: float = _controller._consume_magic_for_movement(delta)

	# Assert
	# cells_moved = 64 * 1 / 32 = 2 cells
	# magic_cost = 2 * 0.5 = 1.0
	assert_almost_eq(consumed, 1.0, 0.01, "Magic consumption scales with speed")

func test_magic_consumption_fractional_cell() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2(16.0, 0.0))  # 0.5 cell/sec
	_mock_vehicle_attr.set_magic_for_test(100.0)
	var delta: float = 1.0

	# Act
	var consumed: float = _controller._consume_magic_for_movement(delta)

	# Assert
	# cells_moved = 16 * 1 / 32 = 0.5 cells
	# magic_cost = 0.5 * 0.5 = 0.25
	assert_almost_eq(consumed, 0.25, 0.01, "Fractional cell consumption works")

func test_magic_depletion_slowdown() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2(200.0, 0.0))  # 高速
	_mock_vehicle_attr.set_magic_for_test(0.1)  # 魔能不足
	var delta: float = 0.1

	# Act
	var consumed: float = _controller._consume_magic_for_movement(delta)

	# Assert
	assert_eq(consumed, 0.0, "No magic consumed when depleted")
	# 魔能耗尽时速度减半
	assert_almost_eq(_controller.velocity.x, 100.0, 0.1, "Magic depletion causes slowdown (velocity *= 0.5)")

func test_zero_velocity_no_magic_consumption() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2.ZERO)
	_mock_vehicle_attr.set_magic_for_test(100.0)
	var delta: float = 1.0

	# Act
	var consumed: float = _controller._consume_magic_for_movement(delta)

	# Assert
	assert_eq(consumed, 0.0, "TR-driving-003: No magic consumption when velocity is zero")
	assert_eq(_mock_vehicle_attr.current_magic, 100.0, "Magic unchanged when not moving")

# === 碰撞响应测试 ===

func test_collision_response_bounce() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2(100.0, 0.0))
	_mock_collision.set_collision_result(true, Vector2i(5, 3), 0.5, Vector2(50.0, 0.0))

	var collision_result: Dictionary = {
		"hit": true,
		"hit_cell": Vector2i(5, 3),
		"severity": 0.5,
		"remaining_velocity": Vector2(50.0, 0.0)
	}

	# Act
	_controller._handle_collision(collision_result)

	# Assert
	# velocity = remaining * 0.5 = 50 * 0.5 = 25
	assert_almost_eq(_controller.velocity.x, 25.0, 0.1, "Collision response: velocity *= 0.5 bounce factor")

func test_collision_no_change_when_no_hit() -> void:
	# Arrange
	var initial: Vector2 = Vector2(100.0, 0.0)
	_controller.set_velocity_for_test(initial)
	_mock_collision.set_collision_result(false)

	# Act - 通过 _check_collision 返回无碰撞
	var collision: Dictionary = _controller._check_collision(0.016)

	# Assert
	assert_false(collision.hit, "No collision detected")

func test_collision_emits_signal() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2(100.0, 0.0))
	_mock_collision.set_collision_result(true, Vector2i(5, 3), 0.5, Vector2(50.0, 0.0))

	var signal_emitted: bool = false
	var signal_cell: Vector2i = Vector2i.ZERO
	var signal_severity: float = 0.0
	_controller.collision_detected.connect(func(cell: Vector2i, severity: float):
		signal_emitted = true
		signal_cell = cell
		signal_severity = severity
	)

	var collision_result: Dictionary = {
		"hit": true,
		"hit_cell": Vector2i(5, 3),
		"severity": 0.5,
		"remaining_velocity": Vector2(50.0, 0.0)
	}

	# Act
	_controller._handle_collision(collision_result)

	# Assert
	assert_true(signal_emitted, "collision_detected signal emitted")
	assert_eq(signal_cell, Vector2i(5, 3), "Signal contains hit_cell")
	assert_almost_eq(signal_severity, 0.5, 0.01, "Signal contains severity")

# === 朝向计算测试 ===

func test_orientation_updates_on_velocity_change() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2(100.0, 0.0))

	# Act
	var angle: float = _controller.get_orientation()

	# Assert
	assert_almost_eq(angle, 0.0, 0.01, "Orientation correct for velocity pointing right")

func test_orientation_diagonal_velocity() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2(100.0, 100.0))

	# Act
	var angle: float = _controller.get_orientation()

	# Assert
	var expected: float = Vector2(100.0, 100.0).angle()  # ~0.785 rad (45°)
	assert_almost_eq(angle, expected, 0.01, "Orientation correct for diagonal velocity")

func test_orientation_zero_velocity() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2.ZERO)

	# Act
	var angle: float = _controller.get_orientation()

	# Assert
	# Vector2.ZERO.angle() 返回 0.0
	assert_eq(angle, 0.0, "Zero velocity orientation is 0")

# === 公共 API 测试 ===

func test_get_vehicle_bounds_returns_rect2() -> void:
	# Arrange
	_controller.position = Vector2(100.0, 100.0)

	# Act
	var bounds: Rect2 = _controller.get_vehicle_bounds()

	# Assert
	# 2x2 cells = 64x64 pixels, centered on position
	assert_almost_eq(bounds.position.x, 100.0 - 32.0, 0.1, "Bounds left edge correct")
	assert_almost_eq(bounds.position.y, 100.0 - 32.0, 0.1, "Bounds top edge correct")
	assert_eq(bounds.size.x, 64.0, "Bounds width = 2 cells")
	assert_eq(bounds.size.y, 64.0, "Bounds height = 2 cells")

func test_get_current_velocity() -> void:
	# Arrange
	var test_vel: Vector2 = Vector2(50.0, 75.0)
	_controller.set_velocity_for_test(test_vel)

	# Act
	var vel: Vector2 = _controller.get_current_velocity()

	# Assert
	assert_eq(vel, test_vel, "get_current_velocity returns velocity")

func test_get_current_speed() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2(30.0, 40.0))

	# Act
	var speed: float = _controller.get_current_speed()

	# Assert
	var expected: float = Vector2(30.0, 40.0).length()  # 50
	assert_almost_eq(speed, expected, 0.1, "get_current_speed returns magnitude")

func test_stop_sets_zero_velocity() -> void:
	# Arrange
	_controller.set_velocity_for_test(Vector2(100.0, 100.0))

	# Act
	_controller.stop()

	# Assert
	assert_eq(_controller.velocity, Vector2.ZERO, "stop() sets velocity to zero")
	assert_eq(_controller.current_speed, 0.0, "stop() sets speed to zero")

# === 常量验证测试 ===

func test_cell_size_is_32() -> void:
	assert_eq(_controller.CELL_SIZE, 32, "CELL_SIZE should be 32")

func test_magic_cost_per_cell_is_0_5() -> void:
	assert_eq(_controller.MAGIC_COST_PER_CELL, 0.5, "TK-013: MAGIC_COST_PER_CELL should be 0.5")

func test_drag_coefficient_is_1_0() -> void:
	assert_eq(_controller.DRAG_COEFFICIENT, 1.0, "DRAG_COEFFICIENT should be 1.0")

func test_body_size_is_2x2_cells() -> void:
	assert_eq(_controller.BODY_WIDTH_CELLS, 2, "BODY_WIDTH_CELLS = 2")
	assert_eq(_controller.BODY_HEIGHT_CELLS, 2, "BODY_HEIGHT_CELLS = 2")

# === 信号存在性测试 ===

func test_velocity_changed_signal_exists() -> void:
	assert_true(_controller.has_signal("velocity_changed"), "velocity_changed signal exists")

func test_orientation_changed_signal_exists() -> void:
	assert_true(_controller.has_signal("orientation_changed"), "orientation_changed signal exists")

func test_collision_detected_signal_exists() -> void:
	assert_true(_controller.has_signal("collision_detected"), "collision_detected signal exists")

# === 依赖注入测试 ===

func test_set_dependencies_method_exists() -> void:
	assert_true(_controller.has_method("set_dependencies"), "set_dependencies method exists")

func test_initialize_method_exists() -> void:
	assert_true(_controller.has_method("initialize"), "initialize method exists")

# === 主循环方法测试 ===

func test_physics_process_method_exists() -> void:
	assert_true(_controller.has_method("_physics_process"), "_physics_process method exists")

func test_read_input_method_exists() -> void:
	assert_true(_controller.has_method("_read_input"), "_read_input method exists")

func test_apply_acceleration_method_exists() -> void:
	assert_true(_controller.has_method("_apply_acceleration"), "_apply_acceleration method exists")

func test_clamp_speed_method_exists() -> void:
	assert_true(_controller.has_method("_clamp_speed"), "_clamp_speed method exists")

func test_check_collision_method_exists() -> void:
	assert_true(_controller.has_method("_check_collision"), "_check_collision method exists")

func test_handle_collision_method_exists() -> void:
	assert_true(_controller.has_method("_handle_collision"), "_handle_collision method exists")

func test_consume_magic_for_movement_method_exists() -> void:
	assert_true(_controller.has_method("_consume_magic_for_movement"), "_consume_magic_for_movement method exists")

func test_apply_movement_method_exists() -> void:
	assert_true(_controller.has_method("_apply_movement"), "_apply_movement method exists")

func test_emit_events_method_exists() -> void:
	assert_true(_controller.has_method("_emit_events"), "_emit_events method exists")

# === 测试辅助方法测试 ===

func test_set_velocity_for_test_method_exists() -> void:
	assert_true(_controller.has_method("set_velocity_for_test"), "set_velocity_for_test method exists")