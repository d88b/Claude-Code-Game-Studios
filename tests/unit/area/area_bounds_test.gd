# area_bounds_test.gd
# Unit tests for Story: Area Bounds Manager
# tests/unit/area/area_bounds_test.gd

extends GutTest

const AreaManagerScript := preload("res://src/area/area_manager.gd")
const VehicleControllerScript := preload("res://src/driving/vehicle_controller.gd")

var _area_manager: Object
var _vehicle_controller: Object

# === Setup ===

func before_each() -> void:
	# 创建 VehicleController
	_vehicle_controller = VehicleControllerScript.new()
	add_child_autoqfree(_vehicle_controller)
	_vehicle_controller.position = Vector2(0, 0)

	# 创建 AreaManager
	_area_manager = AreaManagerScript.new()
	add_child_autoqfree(_area_manager)
	_area_manager.set_dependencies(_vehicle_controller, GlobalSignals, null)

# === 常量验证 ===

func test_enemy_base_density_is_4() -> void:
	assert_eq(_area_manager.ENEMY_BASE_DENSITY, 4, "ENEMY_BASE_DENSITY should be 4")

func test_base_rare_drop_is_0_05() -> void:
	assert_eq(_area_manager.BASE_RARE_DROP, 0.05, "BASE_RARE_DROP should be 0.05")

func test_rare_drop_increment_is_0_05() -> void:
	assert_eq(_area_manager.RARE_DROP_INCREMENT, 0.05, "RARE_DROP_INCREMENT should be 0.05")

func test_transition_display_duration_is_3_0() -> void:
	assert_eq(_area_manager.TRANSITION_DISPLAY_DURATION, 3.0, "TRANSITION_DISPLAY_DURATION should be 3.0")

func test_high_danger_warning_threshold_is_4() -> void:
	assert_eq(_area_manager.HIGH_DANGER_WARNING_THRESHOLD, 4, "HIGH_DANGER_WARNING_THRESHOLD should be 4")

func test_discovery_notification_duration_is_2_0() -> void:
	assert_eq(_area_manager.DISCOVERY_NOTIFICATION_DURATION, 2.0, "DISCOVERY_NOTIFICATION_DURATION should be 2.0")

func test_cell_size_is_32() -> void:
	assert_eq(_area_manager.CELL_SIZE, 32, "CELL_SIZE should be 32")

# === 初始状态测试 ===

func test_initial_area_count_is_4() -> void:
	assert_eq(_area_manager.area_definitions.size(), 4, "Should have 4 MVP areas")

func test_initial_current_area_is_bunker() -> void:
	assert_eq(_area_manager.current_area_id, 0, "Initial area should be bunker (id=0)")

func test_initial_danger_level_is_1() -> void:
	assert_eq(_area_manager.get_danger_level(), 1, "Initial danger should be 1")

func test_initial_loot_tier_is_1() -> void:
	assert_eq(_area_manager.get_loot_tier(), 1, "Initial loot tier should be 1")

func test_initial_area_name_is_bunker() -> void:
	assert_eq(_area_manager.get_area_name(), "地堡周边", "Initial area name should be bunker")

# === 信号测试 ===

func test_area_entered_signal_exists() -> void:
	assert_true(_area_manager.has_signal("area_entered"), "area_entered signal should exist")

func test_area_exited_signal_exists() -> void:
	assert_true(_area_manager.has_signal("area_exited"), "area_exited signal should exist")

func test_area_discovered_signal_exists() -> void:
	assert_true(_area_manager.has_signal("area_discovered"), "area_discovered signal should exist")

func test_global_area_entered_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("area_entered"), "GlobalSignals.area_entered should exist")

func test_global_area_exited_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("area_exited"), "GlobalSignals.area_exited should exist")

# === 公共 API 测试 ===

func test_get_current_area_method_exists() -> void:
	assert_true(_area_manager.has_method("get_current_area"), "get_current_area should exist")

func test_get_current_area_id_method_exists() -> void:
	assert_true(_area_manager.has_method("get_current_area_id"), "get_current_area_id should exist")

func test_get_danger_level_method_exists() -> void:
	assert_true(_area_manager.has_method("get_danger_level"), "get_danger_level should exist")

func test_get_loot_tier_method_exists() -> void:
	assert_true(_area_manager.has_method("get_loot_tier"), "get_loot_tier should exist")

func test_get_area_name_method_exists() -> void:
	assert_true(_area_manager.has_method("get_area_name"), "get_area_name should exist")

func test_get_loot_pools_method_exists() -> void:
	assert_true(_area_manager.has_method("get_loot_pools"), "get_loot_pools should exist")

func test_get_enemy_spawn_ids_method_exists() -> void:
	assert_true(_area_manager.has_method("get_enemy_spawn_ids"), "get_enemy_spawn_ids should exist")

func test_get_enemy_density_method_exists() -> void:
	assert_true(_area_manager.has_method("get_enemy_density"), "get_enemy_density should exist")

func test_get_rare_drop_chance_method_exists() -> void:
	assert_true(_area_manager.has_method("get_rare_drop_chance"), "get_rare_drop_chance should exist")

func test_get_danger_urgency_method_exists() -> void:
	assert_true(_area_manager.has_method("get_danger_urgency"), "get_danger_urgency should exist")

func test_get_area_info_method_exists() -> void:
	assert_true(_area_manager.has_method("get_area_info"), "get_area_info should exist")

func test_is_high_danger_method_exists() -> void:
	assert_true(_area_manager.has_method("is_high_danger"), "is_high_danger should exist")

func test_is_position_in_area_method_exists() -> void:
	assert_true(_area_manager.has_method("is_position_in_area"), "is_position_in_area should exist")

func test_get_all_areas_method_exists() -> void:
	assert_true(_area_manager.has_method("get_all_areas"), "get_all_areas should exist")

# === 区域定义测试 ===

func test_bunker_area_id_is_0() -> void:
	var areas: Array = _area_manager.get_all_areas()
	assert_eq(areas[0].area_id, 0, "Bunker area_id should be 0")

func test_city_area_id_is_1() -> void:
	var areas: Array = _area_manager.get_all_areas()
	assert_eq(areas[1].area_id, 1, "City area_id should be 1")

func test_demon_area_id_is_2() -> void:
	var areas: Array = _area_manager.get_all_areas()
	assert_eq(areas[2].area_id, 2, "Demon area_id should be 2")

func test_element_area_id_is_3() -> void:
	var areas: Array = _area_manager.get_all_areas()
	assert_eq(areas[3].area_id, 3, "Element area_id should be 3")

func test_city_danger_level_is_3() -> void:
	var areas: Array = _area_manager.get_all_areas()
	assert_eq(areas[1].danger_level, 3, "City danger should be 3")

func test_demon_danger_level_is_4() -> void:
	var areas: Array = _area_manager.get_all_areas()
	assert_eq(areas[2].danger_level, 4, "Demon danger should be 4")

func test_element_danger_level_is_5() -> void:
	var areas: Array = _area_manager.get_all_areas()
	assert_eq(areas[3].danger_level, 5, "Element danger should be 5")

func test_city_loot_tier_is_2() -> void:
	var areas: Array = _area_manager.get_all_areas()
	assert_eq(areas[1].loot_tier, 2, "City loot tier should be 2")

func test_demon_loot_tier_is_3() -> void:
	var areas: Array = _area_manager.get_all_areas()
	assert_eq(areas[2].loot_tier, 3, "Demon loot tier should be 3")

func test_element_loot_tier_is_4() -> void:
	var areas: Array = _area_manager.get_all_areas()
	assert_eq(areas[3].loot_tier, 4, "Element loot tier should be 4")

# === 公式测试 ===

func test_enemy_density_formula() -> void:
	# F1: enemy_density = danger_level × ENEMY_BASE_DENSITY
	_area_manager.current_area_id = 0
	assert_eq(_area_manager.get_enemy_density(), 4, "Density at danger=1 should be 4")

func test_enemy_density_danger_3() -> void:
	_area_manager.current_area_id = 1  # City with danger=3
	var area: Object = _area_manager.area_definitions[1]
	_area_manager.set_current_area_for_test(area)
	assert_eq(_area_manager.get_enemy_density(), 12, "Density at danger=3 should be 12")

func test_enemy_density_danger_5() -> void:
	_area_manager.current_area_id = 3  # Element with danger=5
	var area: Object = _area_manager.area_definitions[3]
	_area_manager.set_current_area_for_test(area)
	assert_eq(_area_manager.get_enemy_density(), 20, "Density at danger=5 should be 20")

func test_rare_drop_chance_formula() -> void:
	# F3: rare_drop_chance = BASE_RARE_DROP + loot_tier × RARE_DROP_INCREMENT
	_area_manager.current_area_id = 0
	assert_eq(_area_manager.get_rare_drop_chance(), 0.10, "Rare drop at tier=1 should be 10%")

func test_rare_drop_chance_tier_2() -> void:
	var area: Object = _area_manager.area_definitions[1]
	_area_manager.set_current_area_for_test(area)
	assert_eq(_area_manager.get_rare_drop_chance(), 0.15, "Rare drop at tier=2 should be 15%")

func test_rare_drop_chance_tier_4() -> void:
	var area: Object = _area_manager.area_definitions[3]
	_area_manager.set_current_area_for_test(area)
	assert_eq(_area_manager.get_rare_drop_chance(), 0.25, "Rare drop at tier=4 should be 25%")

func test_danger_urgency_formula() -> void:
	# F2: danger_urgency = danger_level × 0.5 × danger_mult
	_area_manager.current_area_id = 0
	assert_eq(_area_manager.get_danger_urgency(1.0), 0.5, "Urgency at danger=1, mult=1 should be 0.5")

func test_danger_urgency_with_multiplier() -> void:
	var area: Object = _area_manager.area_definitions[2]  # Demon danger=4
	_area_manager.set_current_area_for_test(area)
	assert_eq(_area_manager.get_danger_urgency(1.5), 3.0, "Urgency at danger=4, mult=1.5 should be 3.0")

# === get_area_info 测试 ===

func test_get_area_info_returns_dictionary() -> void:
	var info: Dictionary = _area_manager.get_area_info()
	assert_true(info.has("area_id"), "Info should have area_id")
	assert_true(info.has("name"), "Info should have name")
	assert_true(info.has("danger"), "Info should have danger")
	assert_true(info.has("loot_tier"), "Info should have loot_tier")
	assert_true(info.has("faction"), "Info should have faction")

func test_get_area_info_bunker_values() -> void:
	var info: Dictionary = _area_manager.get_area_info()
	assert_eq(info.area_id, 0, "Bunker area_id")
	assert_eq(info.name, "地堡周边", "Bunker name")
	assert_eq(info.danger, 1, "Bunker danger")
	assert_eq(info.loot_tier, 1, "Bunker loot tier")

# === is_high_danger 测试 ===

func test_is_high_danger_false_for_bunker() -> void:
	_area_manager.current_area_id = 0
	assert_false(_area_manager.is_high_danger(), "Bunker should not be high danger")

func test_is_high_danger_false_for_city() -> void:
	var area: Object = _area_manager.area_definitions[1]
	_area_manager.set_current_area_for_test(area)
	assert_false(_area_manager.is_high_danger(), "City (danger=3) should not be high danger")

func test_is_high_danger_true_for_demon() -> void:
	var area: Object = _area_manager.area_definitions[2]
	_area_manager.set_current_area_for_test(area)
	assert_true(_area_manager.is_high_danger(), "Demon (danger=4) should be high danger")

func test_is_high_danger_true_for_element() -> void:
	var area: Object = _area_manager.area_definitions[3]
	_area_manager.set_current_area_for_test(area)
	assert_true(_area_manager.is_high_danger(), "Element (danger=5) should be high danger")

# === is_position_in_area 测试 ===

func test_is_position_in_area_bunker_center() -> void:
	assert_true(_area_manager.is_position_in_area(Vector2(0, 0), 0), "Center should be in bunker")

func test_is_position_in_area_outside_bunker() -> void:
	assert_false(_area_manager.is_position_in_area(Vector2(1000, 0), 0), "Far position should not be in bunker")

func test_is_position_in_area_invalid_id() -> void:
	assert_false(_area_manager.is_position_in_area(Vector2(0, 0), 999), "Invalid area_id should return false")

# === 位置检测测试 ===

func test_find_area_at_position_method_exists() -> void:
	assert_true(_area_manager.has_method("_find_area_at_position"), "_find_area_at_position should exist")

func test_find_area_at_position_returns_bunker_for_origin() -> void:
	var area: Object = _area_manager._find_area_at_position(Vector2(0, 0))
	assert_eq(area.area_id, 0, "Origin should be in bunker")

func test_find_area_at_position_returns_city() -> void:
	# City bounds start at x=320
	var area: Object = _area_manager._find_area_at_position(Vector2(500, 0))
	assert_eq(area.area_id, 1, "Should be in city area")

func test_find_area_at_position_returns_demon() -> void:
	# Demon bounds start at x=1280
	var area: Object = _area_manager._find_area_at_position(Vector2(1500, 0))
	assert_eq(area.area_id, 2, "Should be in demon area")

func test_find_area_at_position_returns_element() -> void:
	# Element bounds start at x=2240
	var area: Object = _area_manager._find_area_at_position(Vector2(2500, 0))
	assert_eq(area.area_id, 3, "Should be in element area")

# === 区域转换测试 ===

func test_update_current_area_method_exists() -> void:
	assert_true(_area_manager.has_method("_update_current_area"), "_update_current_area should exist")

func test_area_transition_emits_entered_signal() -> void:
	var signal_emitted: bool = false
	var entered_id: int = -1
	var entered_name: String = ""
	_area_manager.area_entered.connect(func(p_id: int, p_name: String, _p_danger: int, _p_loot: int):
		signal_emitted = true
		entered_id = p_id
		entered_name = p_name
	)

	_area_manager._update_current_area(Vector2(500, 0))

	assert_true(signal_emitted, "area_entered should emit")
	assert_eq(entered_id, 1, "Should enter city")
	assert_eq(entered_name, "废弃城市", "City name should match")

func test_area_transition_emits_exited_signal() -> void:
	# 先进入城市
	_area_manager._update_current_area(Vector2(500, 0))

	var signal_emitted: bool = false
	var exited_id: int = -1
	_area_manager.area_exited.connect(func(p_id: int):
		signal_emitted = true
		exited_id = p_id
	)

	# 离开城市进入恶魔荒原
	_area_manager._update_current_area(Vector2(1500, 0))

	assert_true(signal_emitted, "area_exited should emit")
	assert_eq(exited_id, 1, "Should exit city")

# === 区域发现测试 ===

func test_area_discovered_signal_on_first_entry() -> void:
	# 重置发现状态
	_area_manager.area_definitions[1].discovered = false

	var signal_emitted: bool = false
	var discovered_id: int = -1
	_area_manager.area_discovered.connect(func(p_id: int, _p_name: String):
		signal_emitted = true
		discovered_id = p_id
	)

	_area_manager._update_current_area(Vector2(500, 0))

	assert_true(signal_emitted, "area_discovered should emit on first entry")
	assert_eq(discovered_id, 1, "Should discover city")

func test_area_discovered_not_emitted_on_second_entry() -> void:
	# 确保已发现
	_area_manager.area_definitions[1].discovered = true

	var signal_emitted: bool = false
	_area_manager.area_discovered.connect(func(_p_id: int, _p_name: String):
		signal_emitted = true
	)

	# 第一次进入地堡
	_area_manager._update_current_area(Vector2(0, 0))
	# 进入城市 (已发现)
	_area_manager._update_current_area(Vector2(500, 0))

	assert_false(signal_emitted, "area_discovered should not emit if already discovered")

# === loot_pools 和 enemy_spawn_ids 测试 ===

func test_get_loot_pools_returns_array() -> void:
	var pools: Array = _area_manager.get_loot_pools()
	assert_eq(pools.size(), 0, "Bunker should have empty loot pools")

func test_get_loot_pools_city() -> void:
	var area: Object = _area_manager.area_definitions[1]
	_area_manager.set_current_area_for_test(area)
	var pools: Array = _area_manager.get_loot_pools()
	assert_eq(pools.size(), 2, "City should have 2 loot pools")

func test_get_enemy_spawn_ids_returns_array() -> void:
	var spawns: Array = _area_manager.get_enemy_spawn_ids()
	assert_eq(spawns.size(), 0, "Bunker should have empty spawn ids")

func test_get_enemy_spawn_ids_city() -> void:
	var area: Object = _area_manager.area_definitions[1]
	_area_manager.set_current_area_for_test(area)
	var spawns: Array = _area_manager.get_enemy_spawn_ids()
	assert_eq(spawns.size(), 4, "City should have 4 spawn ids")

# === 边界验证测试 ===

func test_validate_no_overlap_method_exists() -> void:
	assert_true(_area_manager.has_method("validate_no_overlap"), "validate_no_overlap should exist")

func test_validate_no_overlap_returns_true_for_mvp() -> void:
	assert_true(_area_manager.validate_no_overlap(), "MVP areas should not overlap")

func test_validate_no_overlap_detects_overlap() -> void:
	# 创建重叠区域
	var overlapping: Object = _area_manager.AreaDefinition.new()
	overlapping.area_id = 99
	overlapping.bounds = Rect2(Vector2(0, 0), Vector2(640, 640))  # 与 bunker 重叠
	_area_manager.add_area_for_test(overlapping)

	assert_false(_area_manager.validate_no_overlap(), "Should detect overlap")

# === 测试辅助方法测试 ===

func test_set_current_area_for_test_method_exists() -> void:
	assert_true(_area_manager.has_method("set_current_area_for_test"), "set_current_area_for_test should exist")

func test_set_vehicle_position_for_test_method_exists() -> void:
	assert_true(_area_manager.has_method("set_vehicle_position_for_test"), "set_vehicle_position_for_test should exist")

func test_add_area_for_test_method_exists() -> void:
	assert_true(_area_manager.has_method("add_area_for_test"), "add_area_for_test should exist")

func test_clear_areas_for_test_method_exists() -> void:
	assert_true(_area_manager.has_method("clear_areas_for_test"), "clear_areas_for_test should exist")

# === 依赖注入测试 ===

func test_set_dependencies_method_exists() -> void:
	assert_true(_area_manager.has_method("set_dependencies"), "set_dependencies should exist")

func test_is_initialized_true_after_set_dependencies() -> void:
	_area_manager.set_dependencies(_vehicle_controller, GlobalSignals, null)
	assert_true(_area_manager.is_initialized, "is_initialized should be true")

# === 边界值测试 ===

func test_area_bounds_edge_inclusive_lower() -> void:
	# Bunker bounds start at (-320, -320)
	assert_true(_area_manager.is_position_in_area(Vector2(-320, -320), 0), "Lower edge should be inclusive")

func test_area_bounds_edge_exclusive_upper() -> void:
	# Bunker bounds end at (320, 320) exclusive
	assert_false(_area_manager.is_position_in_area(Vector2(320, 320), 0), "Upper edge should be exclusive")

# === AreaDefinition 类测试 ===

func test_area_definition_has_area_id() -> void:
	var area: Object = _area_manager.AreaDefinition.new()
	assert_true(area.has("area_id"), "AreaDefinition should have area_id")

func test_area_definition_has_display_name() -> void:
	var area: Object = _area_manager.AreaDefinition.new()
	assert_true(area.has("display_name"), "AreaDefinition should have display_name")

func test_area_definition_has_bounds() -> void:
	var area: Object = _area_manager.AreaDefinition.new()
	assert_true(area.has("bounds"), "AreaDefinition should have bounds")

func test_area_definition_has_danger_level() -> void:
	var area: Object = _area_manager.AreaDefinition.new()
	assert_true(area.has("danger_level"), "AreaDefinition should have danger_level")

func test_area_definition_has_loot_tier() -> void:
	var area: Object = _area_manager.AreaDefinition.new()
	assert_true(area.has("loot_tier"), "AreaDefinition should have loot_tier")