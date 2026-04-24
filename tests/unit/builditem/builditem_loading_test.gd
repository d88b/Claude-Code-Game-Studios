# builditem_loading_test.gd
# Unit tests for Story: Build Item Definition Loading

extends GutTest

const BuildItemDBScript := preload("res://src/database/build_item_db.gd")

var _build_item_db: Object

func before_all() -> void:
	_build_item_db = BuildItemDBScript.new()
	add_child_autoqfree(_build_item_db)

func test_build_item_exists() -> void:
	var item: Object = _build_item_db.get_build_item(1000)
	assert_not_null(item, "Wall (1000) should exist")

func test_build_cost_returns_dict() -> void:
	var cost: Dictionary = _build_item_db.get_build_cost(1000)
	assert_true(typeof(cost) == TYPE_DICTIONARY, "Should return Dictionary")
	assert_gt(cost.size(), 0, "Cost should have entries")

func test_build_cost_iron() -> void:
	var cost: Dictionary = _build_item_db.get_build_cost(1000)
	assert_true(cost.has(151), "Cost should include iron (151)")

func test_total_cost_calculation() -> void:
	var total: Dictionary = _build_item_db.get_total_cost(1000, 2)
	var base: Dictionary = _build_item_db.get_build_cost(1000)
	for res_id: int in base.keys():
		assert_eq(total[res_id], base[res_id] * 2, "Total = base * 2")

func test_terrain_support_solid() -> void:
	var can: bool = _build_item_db.check_terrain_support(1000, "solid")
	assert_true(can, "Wall can be on solid terrain")

func test_terrain_support_passable() -> void:
	var can: bool = _build_item_db.check_terrain_support(1000, "passable")
	assert_false(can, "Wall cannot be on passable terrain")

func test_terrain_support_any() -> void:
	# 地板支持任何地形
	var can1: bool = _build_item_db.check_terrain_support(5000, "solid")
	var can2: bool = _build_item_db.check_terrain_support(5000, "passable")
	assert_true(can1, "Floor on solid")
	assert_true(can2, "Floor on passable")

func test_12_mvp_items() -> void:
	assert_gt(_build_item_db.item_count, 12, "Should have 12+ MVP items")

func test_categories() -> void:
	assert_true(_build_item_db.is_valid_category("wall"), "wall valid")
	assert_true(_build_item_db.is_valid_category("turret"), "turret valid")
	assert_true(_build_item_db.is_valid_category("trap"), "trap valid")
	assert_true(_build_item_db.is_valid_category("facility"), "facility valid")
	assert_true(_build_item_db.is_valid_category("floor"), "floor valid")

func test_invalid_item_returns_null() -> void:
	var item: Object = _build_item_db.get_build_item(999)
	assert_null(item, "Invalid item ID returns null")

func test_get_items_by_category() -> void:
	var walls: Array = _build_item_db.get_items_by_category("wall")
	assert_gt(walls.size(), 0, "Should have wall items")

func test_build_time() -> void:
	var time: float = _build_item_db.get_build_time(1000)
	assert_gt(time, 0, "Build time should be positive")