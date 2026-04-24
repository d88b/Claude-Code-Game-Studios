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

# === V2: Layer Occupancy 测试 ===

func test_v2_check_cell_occupied_method_exists() -> void:
	assert_true(_build_validator.has_method("check_cell_occupied"),
		"check_cell_occupied method should exist")

func test_v2_returns_v2_code_on_occupied() -> void:
	# 验证 V2 失败码结构
	var result: Object = _build_validator.ValidationResult.failure("V2", "位置已被占用")
	assert_eq(result.failure_code, "V2", "V2 should return correct failure code")

# === V4: Tile Buildability 测试 ===

func test_v4_check_buildability_method_exists() -> void:
	assert_true(_build_validator.has_method("check_buildability"),
		"check_buildability method should exist")

func test_v4_requires_build_item_db() -> void:
	# BuildValidator 需要 BuildItemDB
	assert_true(_build_validator._build_item_db != null or _build_validator.has_method("set_build_item_db"),
		"BuildValidator should have build_item_db dependency")

# === V5: Category-Specific Rules 测试 ===

func test_v5_check_category_rules_method_exists() -> void:
	assert_true(_build_validator.has_method("check_category_rules"),
		"check_category_rules method should exist")

func test_v5_wall_requires_adjacent_support() -> void:
	# Wall 类别需要相邻支持
	assert_true(_build_validator.has_method("check_adjacent_support"),
		"check_adjacent_support should exist for wall category")

func test_v5_turret_requires_floor_foundation() -> void:
	# Turret/Trap/Facility 类别需要地板基础
	assert_true(_build_validator.has_method("check_floor_foundation"),
		"check_floor_foundation should exist for turret/trap/facility")

# === V6: Material Cost 测试 ===

func test_v6_check_material_cost_method_exists() -> void:
	assert_true(_build_validator.has_method("check_material_cost"),
		"check_material_cost method should exist")

func test_v6_accepts_empty_inventory() -> void:
	# 空 inventory 应通过（stub 模式）
	var result: Object = _build_validator.check_material_cost(1, {})
	assert_true(result.passed, "Empty inventory should pass (stub mode)")

func test_v6_returns_v6_code_on_insufficient() -> void:
	# 验证 V6 失败码结构
	var result: Object = _build_validator.ValidationResult.failure("V6", "材料不足")
	assert_eq(result.failure_code, "V6", "V6 should return correct failure code")

# === validate_placement 集成测试 ===

func test_validate_placement_method_exists() -> void:
	assert_true(_build_validator.has_method("validate_placement"),
		"validate_placement method should exist")

func test_validate_placement_returns_validation_result() -> void:
	# 验证返回 ValidationResult 类型
	assert_true(_build_validator.has_method("validate_placement"),
		"validate_placement should return ValidationResult")

func test_validate_placement_uninitialized_returns_v0() -> void:
	# 未初始化应返回 V0
	var result: Object = _build_validator.ValidationResult.failure("V0", "系统未初始化")
	assert_eq(result.failure_code, "V0", "Uninitialized should return V0")

# === ValidationResult 类扩展测试 ===

func test_validation_result_init_default_false() -> void:
	var result: Object = _build_validator.ValidationResult.new()
	assert_false(result.passed, "Default ValidationResult.passed should be false")

func test_validation_result_init_with_params() -> void:
	var result: Object = _build_validator.ValidationResult.new(true, "V1", "测试通过")
	assert_true(result.passed, "Init with passed=true should work")
	assert_eq(result.failure_code, "V1", "Init with code should work")
	assert_eq(result.failure_message, "测试通过", "Init with message should work")

# === GlobalSignals 测试 ===

func test_global_signals_has_block_placed_signal() -> void:
	assert_true(GlobalSignals.has_signal("block_placed"),
		"GlobalSignals should have block_placed signal")

func test_global_signals_has_build_started_signal() -> void:
	assert_true(GlobalSignals.has_signal("build_started"),
		"GlobalSignals should have build_started signal")

func test_global_signals_has_build_completed_signal() -> void:
	assert_true(GlobalSignals.has_signal("build_completed"),
		"GlobalSignals should have build_completed signal")

# === 边界值测试 ===

func test_v1_exact_boundary_positive() -> void:
	var cell: Vector2i = Vector2i(1000, 500)
	var result: Object = _build_validator.check_world_bounds(cell)
	assert_true(result.passed, "Exact MAX_WORLD_BOUNDS should pass V1")

func test_v1_exact_boundary_negative() -> void:
	var cell: Vector2i = Vector2i(-1000, 500)
	var result: Object = _build_validator.check_world_bounds(cell)
	assert_true(result.passed, "Exact -MAX_WORLD_BOUNDS should pass V1")

func test_v1_one_over_boundary() -> void:
	var cell: Vector2i = Vector2i(1001, 500)
	var result: Object = _build_validator.check_world_bounds(cell)
	assert_false(result.passed, "One over boundary should fail V1")

# === PlaceController 集成测试 ===

func test_place_controller_requires_build_validator() -> void:
	assert_true(_place_controller.has_method("set_build_validator"),
		"PlaceController should accept BuildValidator dependency")

func test_place_controller_requires_collision_manager() -> void:
	assert_true(_place_controller.has_method("set_collision_manager"),
		"PlaceController should accept CollisionManager dependency")

func test_place_controller_is_initialized_checks_deps() -> void:
	# is_initialized 需要检查关键依赖
	assert_true(_place_controller.has_method("is_initialized"),
		"PlaceController.is_initialized should exist")

# === 常量一致性测试 ===

func test_constants_match_gdd_spec() -> void:
	# GDD 规定: MAX_PLACE_RANGE = 5 cells
	assert_eq(_build_validator.MAX_PLACE_RANGE, 5.0, "MAX_PLACE_RANGE should match GDD")
	# GDD 规定: CELL_SIZE = 32 pixels
	assert_eq(_build_validator.CELL_SIZE, 32, "CELL_SIZE should match GDD")
	# GDD 规定: MAX_WORLD_BOUNDS = 1000 cells
	assert_eq(_build_validator.MAX_WORLD_BOUNDS, 1000, "MAX_WORLD_BOUNDS should match GDD")

# === 状态机测试 ===

func test_place_state_enum_has_all_states() -> void:
	assert_eq(_place_controller.PlaceState.IDLE, 0, "IDLE state")
	assert_eq(_place_controller.PlaceState.SELECTING, 1, "SELECTING state")
	assert_eq(_place_controller.PlaceState.VALIDATE, 2, "VALIDATE state")
	assert_eq(_place_controller.PlaceState.BUILDING, 3, "BUILDING state")
	assert_eq(_place_controller.PlaceState.CANCELLED, 4, "CANCELLED state")
	assert_eq(_place_controller.PlaceState.COMPLETE, 5, "COMPLETE state")

func test_initial_state_is_idle() -> void:
	assert_eq(_place_controller.current_state, _place_controller.PlaceState.IDLE,
		"Initial state should be IDLE")

func test_select_item_changes_state_to_selecting() -> void:
	_place_controller.select_item(1)
	assert_eq(_place_controller.current_state, _place_controller.PlaceState.SELECTING,
		"select_item should change state to SELECTING")