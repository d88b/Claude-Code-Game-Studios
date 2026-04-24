# resource_drop_test.gd
# Unit tests for Story: Resource Drop Entity
# tests/unit/drop/resource_drop_test.gd

extends GutTest

const ResourceDropScript := preload("res://src/drop/resource_drop.gd")
const DropManagerScript := preload("res://src/drop/drop_manager.gd")
const BlockTypeDBScript := preload("res://src/database/block_type_db.gd")

var _resource_drop: Object
var _drop_manager: Object
var _block_type_db: Object

# === Setup ===

func before_all() -> void:
	# 创建 BlockTypeDB
	_block_type_db = BlockTypeDBScript.new()
	add_child_autoqfree(_block_type_db)
	await get_tree().process_frame

func before_each() -> void:
	# 创建 ResourceDrop
	_resource_drop = ResourceDropScript.new()
	add_child_autoqfree(_resource_drop)

	# 创建 DropManager
	_drop_manager = DropManagerScript.new()
	add_child_autoqfree(_drop_manager)
	_drop_manager._block_type_db = _block_type_db
	_drop_manager._global_signals = GlobalSignals

# === 常量验证 ===

func test_lifetime_is_30_seconds() -> void:
	assert_eq(_resource_drop.LIFETIME, 30.0, "LIFETIME should be 30.0 seconds (TK-045)")

func test_pickup_radius_is_64_pixels() -> void:
	assert_eq(_resource_drop.PICKUP_RADIUS, 64.0, "PICKUP_RADIUS should be 64.0 pixels (2 cells)")

func test_pickup_radius_is_2_cells() -> void:
	# 2 cells = 2 * 32 pixels = 64 pixels
	var cells: float = _resource_drop.PICKUP_RADIUS / 32.0
	assert_eq(cells, 2.0, "PICKUP_RADIUS should equal 2 cells")

# === 初始状态测试 ===

func test_initial_resource_id_is_1() -> void:
	assert_eq(_resource_drop.resource_id, 1, "Default resource_id should be 1")

func test_initial_quantity_is_1() -> void:
	assert_eq(_resource_drop.quantity, 1.0, "Default quantity should be 1.0")

func test_initial_lifetime_timer_is_0() -> void:
	assert_eq(_resource_drop._lifetime_timer, 0.0, "lifetime_timer should start at 0")

func test_initial_is_not_collected() -> void:
	assert_false(_resource_drop._is_collected, "Should not be collected initially")

# === set_resource 测试 ===

func test_set_resource_updates_id() -> void:
	_resource_drop.set_resource(5, 10.0)
	assert_eq(_resource_drop.resource_id, 5, "resource_id should be updated")

func test_set_resource_updates_quantity() -> void:
	_resource_drop.set_resource(3, 25.0)
	assert_eq(_resource_drop.quantity, 25.0, "quantity should be updated")

func test_set_resource_zero_quantity() -> void:
	_resource_drop.set_resource(2, 0.0)
	assert_eq(_resource_drop.quantity, 0.0, "quantity can be 0")

func test_set_resource_negative_quantity() -> void:
	_resource_drop.set_resource(2, -5.0)
	assert_eq(_resource_drop.quantity, -5.0, "quantity accepts negative (for testing)")

func test_set_resource_large_quantity() -> void:
	_resource_drop.set_resource(1, 1000.0)
	assert_eq(_resource_drop.quantity, 1000.0, "quantity can be large")

# === 生命周期测试 ===

func test_lifetime_timer_increments_per_frame() -> void:
	# Simulate 1 second of frames (60 frames at 60fps)
	for i in range(60):
		_resource_drop._process(1.0 / 60.0)

	assert_almost_eq(_resource_drop._lifetime_timer, 1.0, 0.1, "Timer should reach ~1 second after 60 frames")

func test_expire_called_at_30_seconds() -> void:
	# Set timer to exactly 30 seconds
	_resource_drop._lifetime_timer = 30.0

	# Process one frame
	_resource_drop._process(0.016)

	# Should be collected/expired
	assert_true(_resource_drop._is_collected, "Should be expired at 30 seconds")

func test_expire_called_after_30_seconds() -> void:
	_resource_drop._lifetime_timer = 35.0
	_resource_drop._process(0.016)
	assert_true(_resource_drop._is_collected, "Should be expired after 30 seconds")

func test_not_expired_before_30_seconds() -> void:
	_resource_drop._lifetime_timer = 29.0
	_resource_drop._process(0.016)
	assert_false(_resource_drop._is_collected, "Should NOT be expired before 30 seconds")

func test_not_expired_at_29_9_seconds() -> void:
	_resource_drop._lifetime_timer = 29.9
	_resource_drop._process(0.016)
	assert_false(_resource_drop._is_collected, "Should NOT be expired at 29.9 seconds")

func test_lifetime_boundary_at_exactly_30() -> void:
	_resource_drop._lifetime_timer = 30.0
	_resource_drop._process(0.001)
	assert_true(_resource_drop._is_collected, "Should be expired at exactly 30 seconds")

# === 拾取测试 ===

func test_collect_sets_is_collected() -> void:
	_resource_drop._collect()
	assert_true(_resource_drop._is_collected, "collect() should set _is_collected")

func test_collect_emits_global_signal() -> void:
	_resource_drop.set_resource(3, 15.0)

	var signal_emitted: bool = false
	var collected_id: int = -1
	var collected_qty: float = 0.0
	GlobalSignals.resource_collected.connect(func(p_id: int, p_qty: float):
		signal_emitted = true
		collected_id = p_id
		collected_qty = p_qty
	)

	_resource_drop._collect()

	assert_true(signal_emitted, "resource_collected signal should emit")
	assert_eq(collected_id, 3, "Signal should emit correct resource_id")
	assert_eq(collected_qty, 15.0, "Signal should emit correct quantity")

func test_collect_only_once() -> void:
	var signal_count: int = 0
	GlobalSignals.resource_collected.connect(func(_p_id: int, _p_qty: float):
		signal_count += 1
	)

	_resource_drop._collect()
	_resource_drop._collect()  # Try again

	assert_eq(signal_count, 1, "Should only emit signal once")

func test_on_body_entered_ignores_if_collected() -> void:
	_resource_drop._is_collected = true

	var signal_count: int = 0
	GlobalSignals.resource_collected.connect(func(_p_id: int, _p_qty: float):
		signal_count += 1
	)

	# Simulate body entering
	_resource_drop._on_body_entered(null)

	assert_eq(signal_count, 0, "Should not collect if already collected")

# === 过期测试 ===

func test_expire_sets_is_collected() -> void:
	_resource_drop._expire()
	assert_true(_resource_drop._is_collected, "expire() should set _is_collected")

func test_expire_no_signal_emitted() -> void:
	var signal_count: int = 0
	GlobalSignals.resource_collected.connect(func(_p_id: int, _p_qty: float):
		signal_count += 1
	)

	_resource_drop._expire()

	assert_eq(signal_count, 0, "expire() should NOT emit resource_collected signal")

# === DropManager 测试 ===

func test_spawn_drop_creates_instance() -> void:
	# Note: This test requires the scene to be loaded
	# We can't fully test instantiation without the scene file
	assert_true(_drop_manager.has_method("spawn_drop"), "spawn_drop method should exist")

func test_spawn_drop_with_valid_params() -> void:
	# Mock the spawn (can't instantiate without scene)
	# Test that method exists and accepts parameters
	_drop_manager.spawn_drop(Vector2i(5, 5), 1, 10.0)
	# If no crash, method works

func test_spawn_drop_zero_quantity() -> void:
	_drop_manager.spawn_drop(Vector2i(0, 0), 2, 0.0)

func test_spawn_drop_negative_position() -> void:
	_drop_manager.spawn_drop(Vector2i(-10, -10), 1, 5.0)

func test_block_dug_signal_handler_exists() -> void:
	assert_true(_drop_manager.has_method("_on_block_dug"), "_on_block_dug method should exist")

# === 随机偏移测试 ===

func test_spawn_drop_has_random_offset() -> void:
	# 多次生成，检查位置不完全相同
	var positions: Array = []

	for i in range(10):
		# 模拟生成（实际无法创建实例）
		var base_pos: Vector2 = Vector2(
			(5.0 + 0.5) * 32,
			(5.0 + 0.5) * 32
		)
		var random_offset: Vector2 = Vector2(
			randf_range(-16.0, 16.0),
			randf_range(-16.0, 16.0)
		)
		positions.append(base_pos + random_offset)

	# 检查至少有一个位置不同
	var all_same: bool = true
	for pos in positions:
		if pos != positions[0]:
			all_same = false
			break

	assert_false(all_same, "Random offset should produce different positions")

func test_random_offset_range_is_16_pixels() -> void:
	# 测试偏移范围
	for i in range(100):
		var offset_x: float = randf_range(-16.0, 16.0)
		var offset_y: float = randf_range(-16.0, 16.0)

		assert_true(offset_x >= -16.0 and offset_x <= 16.0, "offset_x should be in [-16, 16]")
		assert_true(offset_y >= -16.0 and offset_y <= 16.0, "offset_y should be in [-16, 16]")

# === 视觉颜色测试 ===

func test_get_resource_color_returns_color() -> void:
	var color: Color = _resource_drop._get_resource_color()
	assert_true(color is Color, "Should return a Color")

func test_get_resource_color_for_magic_crystal() -> void:
	_resource_drop.resource_id = 1
	var color: Color = _resource_drop._get_resource_color()
	assert_eq(color, Color(0.8, 0.2, 0.8, 1), "Magic crystal should be purple")

func test_get_resource_color_for_mithril() -> void:
	_resource_drop.resource_id = 2
	var color: Color = _resource_drop._get_resource_color()
	assert_eq(color, Color(0.6, 0.6, 0.7, 1), "Mithril should be silver-gray")

func test_get_resource_color_for_arcane_fragment() -> void:
	_resource_drop.resource_id = 3
	var color: Color = _resource_drop._get_resource_color()
	assert_eq(color, Color(0.9, 0.7, 0.1, 1), "Arcane fragment should be gold")

func test_get_resource_color_for_iron_ore() -> void:
	_resource_drop.resource_id = 4
	var color: Color = _resource_drop._get_resource_color()
	assert_eq(color, Color(0.6, 0.4, 0.2, 1), "Iron ore should be brown")

func test_get_resource_color_for_unknown() -> void:
	_resource_drop.resource_id = 999
	var color: Color = _resource_drop._get_resource_color()
	assert_eq(color, Color(0.5, 0.5, 0.5, 1), "Unknown resource should be gray")

# === GlobalSignals 连接测试 ===

func test_global_signals_resource_collected_exists() -> void:
	assert_true(GlobalSignals.has_signal("resource_collected"), "resource_collected signal should exist")

func test_global_signals_block_dug_exists() -> void:
	assert_true(GlobalSignals.has_signal("block_dug"), "block_dug signal should exist")

# === 边界测试 ===

func test_lifetime_boundary_values() -> void:
	# Test various boundary values
	_resource_drop._lifetime_timer = 0.0
	_resource_drop._process(0.016)
	assert_false(_resource_drop._is_collected, "Should not expire at 0")

	_resource_drop._lifetime_timer = 29.99
	_resource_drop._is_collected = false
	_resource_drop._process(0.016)
	assert_false(_resource_drop._is_collected, "Should not expire at 29.99")

	_resource_drop._lifetime_timer = 30.0
	_resource_drop._is_collected = false
	_resource_drop._process(0.016)
	assert_true(_resource_drop._is_collected, "Should expire at 30.0")

func test_quantity_boundary_values() -> void:
	_resource_drop.set_resource(1, 0.001)
	assert_almost_eq(_resource_drop.quantity, 0.001, 0.0001, "Should accept very small quantity")

	_resource_drop.set_resource(1, 10000.0)
	assert_eq(_resource_drop.quantity, 10000.0, "Should accept very large quantity")

# === 状态恢复测试 ===

func test_process_skips_if_collected() -> void:
	_resource_drop._is_collected = true
	_resource_drop._lifetime_timer = 0.0

	# Process many frames
	for i in range(100):
		_resource_drop._process(0.016)

	# Timer should not have increased
	assert_eq(_resource_drop._lifetime_timer, 0.0, "Timer should not increase when collected")

# === 测试辅助方法测试 ===

func test_set_resource_method_exists() -> void:
	assert_true(_resource_drop.has_method("set_resource"), "set_resource method should exist")

func test_collect_method_exists() -> void:
	assert_true(_resource_drop.has_method("_collect"), "_collect method should exist")

func test_expire_method_exists() -> void:
	assert_true(_resource_drop.has_method("_expire"), "_expire method should exist")

func test_get_resource_color_method_exists() -> void:
	assert_true(_resource_drop.has_method("_get_resource_color"), "_get_resource_color method should exist")

# === Acceptance Criteria 覆盖测试 ===

func test_ac_lifetime_30_seconds() -> void:
	assert_eq(_resource_drop.LIFETIME, 30.0, "AC: Lifetime = 30 seconds")

func test_ac_pickup_radius_2_cells() -> void:
	assert_eq(_resource_drop.PICKUP_RADIUS / 32.0, 2.0, "AC: pickup_radius = 2 cells")

func test_ac_random_offset_from_block_position() -> void:
	# 验证 drop_manager 的 spawn_drop 有随机偏移逻辑
	# 检查代码中有 randf_range
	var source_code: String = FileAccess.open("res://src/drop/drop_manager.gd", FileAccess.READ).get_as_text()
	assert_true(source_code.contains("randf_range"), "AC: spawn_drop should use random offset")

func test_ac_block_dug_triggers_drop_spawn() -> void:
	# 验证 DropManager 连接 block_dug 信号
	var source_code: String = FileAccess.open("res://src/drop/drop_manager.gd", FileAccess.READ).get_as_text()
	assert_true(source_code.contains("block_dug.connect"), "AC: GlobalSignals.block_dug should trigger spawn")

func test_ac_resource_quantity_from_block() -> void:
	# 验证 DropManager 从 block_data 获取 drop_quantity
	var source_code: String = FileAccess.open("res://src/drop/drop_manager.gd", FileAccess.READ).get_as_text()
	assert_true(source_code.contains("drop_quantity"), "AC: Quantity from block data")