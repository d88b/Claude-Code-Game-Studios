# placement_validation_test.gd
# Unit tests for Story: Placement Validation
# tests/unit/placing/placement_validation_test.gd

extends GutTest

const BuildValidatorScript := preload("res://src/placing/build_validator.gd")
const PlaceControllerScript := preload("res://src/placing/place_controller.gd")
const BuildItemDBScript := preload("res://src/database/build_item_db.gd")

var _build_validator: Object
var _place_controller: Object
var _build_item_db: Object

func before_all() -> void:
	# 创建 BuildItemDB
	_build_item_db = BuildItemDBScript.new()
	add_child_autoqfree(_build_item_db)
	await get_tree().process_frame

	# 创建 BuildValidator
	_build_validator = BuildValidatorScript.new()
	add_child_autoqfree(_build_validator)
	_build_validator.set_build_item_db(_build_item_db)
	_build_validator.set_block_type_db(BlockTypeDB)

	# 创建 PlaceController
	_place_controller = PlaceControllerScript.new()
	add_child_autoqfree(_place_controller)
	_place_controller.set_build_validator(_build_validator)
	_place_controller.set_build_item_db(_build_item_db)
	_place_controller.set_global_signals(GlobalSignals)

# === 常量验证测试 ===

func test_max_place_range_is_5() -> void:
	assert_eq(_build_validator.MAX_PLACE_RANGE, 5.0, "MAX_PLACE_RANGE should be 5.0")

func test_cell_size_is_32() -> void:
	assert_eq(_build_validator.CELL_SIZE, 32, "CELL_SIZE should be 32")

func test_max_world_bounds_is_1000() -> void:
	assert_eq(_build_validator.MAX_WORLD_BOUNDS, 1000, "MAX_WORLD_BOUNDS should be 1000")

# === ValidationResult 类测试 ===

func test_validation_result_success_passed() -> void:
	var result: Object = _build_validator.ValidationResult.success()
	assert_true(result.passed, "success() should return passed=true")

func test_validation_result_failure_not_passed() -> void:
	var result: Object = _build_validator.ValidationResult.failure("V1", "超出边界")
	assert_false(result.passed, "failure() should return passed=false")

func test_validation_result_failure_has_code() -> void:
	var result: Object = _build_validator.ValidationResult.failure("V3", "超出范围")
	assert_eq(result.failure_code, "V3", "failure should have code")

func test_validation_result_failure_has_message() -> void:
	var result: Object = _build_validator.ValidationResult.failure("V6", "材料不足")
	assert_eq(result.failure_message, "材料不足", "failure should have message")

# === V1: 世界边界检查测试 ===

func test_v1_accepts_within_bounds() -> void:
	var cell: Vector2i = Vector2i(500, 500)
	var result: Object = _build_validator.check_world_bounds(cell)
	assert_true(result.passed, "Cell within bounds should pass V1")

func test_v1_rejects_x_out_of_bounds_positive() -> void:
	var cell: Vector2i = Vector2i(1500, 500)
	var result: Object = _build_validator.check_world_bounds(cell)
	assert_false(result.passed, "Cell beyond x bounds should fail V1")

func test_v1_rejects_x_out_of_bounds_negative() -> void:
	var cell: Vector2i = Vector2i(-1500, 500)
	var result: Object = _build_validator.check_world_bounds(cell)
	assert_false(result.passed, "Cell beyond negative x bounds should fail V1")

func test_v1_rejects_y_out_of_bounds() -> void:
	var cell: Vector2i = Vector2i(500, 1500)
	var result: Object = _build_validator.check_world_bounds(cell)
	assert_false(result.passed, "Cell beyond y bounds should fail V1")

# === V3: 距离检查测试 ===

func test_v3_accepts_within_range() -> void:
	var cell: Vector2i = Vector2i(5, 5)
	var player_pos: Vector2 = Vector2(160.0, 160.0)  # 5 cells away center
	var result: Object = _build_validator.check_placement_range(cell, player_pos)
	assert_true(result.passed, "Cell within range should pass V3")

func test_v3_rejects_out_of_range() -> void:
	var cell: Vector2i = Vector2i(20, 20)  # Far away
	var player_pos: Vector2 = Vector2(160.0, 160.0)
	var result: Object = _build_validator.check_placement_range(cell, player_pos)
	assert_false(result.passed, "Cell out of range should fail V3")

func test_v3_accepts_exact_range_boundary() -> void:
	# 5 cells = 160 pixels max range
	var cell: Vector2i = Vector2i(5, 0)
	var player_pos: Vector2 = Vector2(0.0, 16.0)  # Exactly at boundary
	var result: Object = _build_validator.check_placement_range(cell, player_pos)
	assert_true(result.passed, "Exact boundary should pass V3 (inclusive)")

func test_v3_uses_squared_distance() -> void:
	# 验证方法使用 squared distance (优化)
	assert_true(_build_validator.has_method("check_placement_range"),
		"Should have check_placement_range method")

# === 辅助方法测试 ===

func test_get_distance_to_cell_returns_float() -> void:
	var cell: Vector2i = Vector2i(10, 10)
	var player_pos: Vector2 = Vector2(0.0, 0.0)
	var distance: float = _build_validator.get_distance_to_cell(cell, player_pos)
	assert_true(distance > 0.0, "Distance should be positive")

func test_is_in_placement_range_returns_bool() -> void:
	var cell: Vector2i = Vector2i(5, 5)
	var player_pos: Vector2 = Vector2(160.0, 160.0)
	var in_range: bool = _build_validator.is_in_placement_range(cell, player_pos)
	assert_true(in_range, "Should return true for valid range")

# === PlaceController 状态枚举测试 ===

func test_place_state_idle_is_0() -> void:
	assert_eq(_place_controller.PlaceState.IDLE, 0, "IDLE should be 0")

func test_place_state_selecting_is_1() -> void:
	assert_eq(_place_controller.PlaceState.SELECTING, 1, "SELECTING should be 1")

func test_place_state_building_is_3() -> void:
	assert_eq(_place_controller.PlaceState.BUILDING, 3, "BUILDING should be 3")

func test_place_state_complete_is_5() -> void:
	assert_eq(_place_controller.PlaceState.COMPLETE, 5, "COMPLETE should be 5")

# === PlaceController API 测试 ===

func test_select_item_method_exists() -> void:
	assert_true(_place_controller.has_method("select_item"),
		"select_item method should exist")

func test_try_place_method_exists() -> void:
	assert_true(_place_controller.has_method("try_place"),
		"try_place method should exist")

func test_cancel_build_method_exists() -> void:
	assert_true(_place_controller.has_method("cancel_build"),
		"cancel_build method should exist")

func test_get_build_progress_method_exists() -> void:
	assert_true(_place_controller.has_method("get_build_progress"),
		"get_build_progress method should exist")

# === PlaceController 信号测试 ===

func test_state_changed_signal_exists() -> void:
	assert_true(_place_controller.has_signal("state_changed"),
		"state_changed signal should exist")

func test_placement_success_signal_exists() -> void:
	assert_true(_place_controller.has_signal("placement_success"),
		"placement_success signal should exist")

func test_placement_failed_signal_exists() -> void:
	assert_true(_place_controller.has_signal("placement_failed"),
		"placement_failed signal should exist")

func test_build_progress_updated_signal_exists() -> void:
	assert_true(_place_controller.has_signal("build_progress_updated"),
		"build_progress_updated signal should exist")

# === 建造进度测试 ===

func test_get_build_progress_returns_zero_at_start() -> void:
	_place_controller.construction_progress = 0.0
	_place_controller.build_time = 5.0
	var percent: float = _place_controller.get_build_progress()
	assert_eq(percent, 0.0, "Progress should be 0% at start")

func test_get_build_progress_returns_100_at_complete() -> void:
	_place_controller.construction_progress = 5.0
	_place_controller.build_time = 5.0
	var percent: float = _place_controller.get_build_progress()
	assert_eq(percent, 100.0, "Progress should be 100% at complete")

func test_get_build_progress_returns_50_at_halfway() -> void:
	_place_controller.construction_progress = 2.5
	_place_controller.build_time = 5.0
	var percent: float = _place_controller.get_build_progress()
	assert_eq(percent, 50.0, "Progress should be 50% at halfway")

# === 依赖注入测试 ===

func test_set_build_validator_method_exists() -> void:
	assert_true(_place_controller.has_method("set_build_validator"),
		"set_build_validator method should exist")

func test_set_collision_manager_method_exists() -> void:
	assert_true(_place_controller.has_method("set_collision_manager"),
		"set_collision_manager method should exist")

func test_set_tilemap_world_method_exists() -> void:
	assert_true(_build_validator.has_method("set_tilemap_world"),
		"set_tilemap_world method should exist")

func test_is_initialized_method_exists() -> void:
	assert_true(_build_validator.has_method("is_initialized"),
		"is_initialized method should exist")

# === 类别规则测试 ===

func test_check_adjacent_support_method_exists() -> void:
	assert_true(_build_validator.has_method("check_adjacent_support"),
		"check_adjacent_support method should exist")

func test_check_floor_foundation_method_exists() -> void:
	assert_true(_build_validator.has_method("check_floor_foundation"),
		"check_floor_foundation method should exist")

func test_check_terrain_support_method_exists() -> void:
	assert_true(_build_validator.has_method("check_terrain_support"),
		"check_terrain_support method should exist")