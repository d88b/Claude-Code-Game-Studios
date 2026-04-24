# resource_loading_test.gd
# Unit tests for Story: Resource Definition Loading

extends GutTest

const ResourceDBScript := preload("res://src/database/resource_db.gd")

var _resource_db: Object

func before_all() -> void:
	_resource_db = ResourceDBScript.new()
	add_child_autoqfree(_resource_db)

func test_iron_ingot_exists() -> void:
	var res: Object = _resource_db.get_resource(151)
	assert_not_null(res, "Iron ingot (151) should exist")

func test_copper_ingot_exists() -> void:
	var res: Object = _resource_db.get_resource(152)
	assert_not_null(res, "Copper ingot (152) should exist")

func test_basic_parts_exists() -> void:
	var res: Object = _resource_db.get_resource(160)
	assert_not_null(res, "Basic parts (160) should exist")

func test_max_stack_size() -> void:
	var stack: int = _resource_db.get_max_stack_size(151)
	assert_eq(stack, 100, "Iron ingot stack size = 100")

func test_category_processed() -> void:
	var category: String = _resource_db.get_category(151)
	assert_eq(category, "processed", "Iron ingot category = processed")

func test_category_raw_material() -> void:
	var category: String = _resource_db.get_category(101)
	assert_eq(category, "raw_material", "Crystal category = raw_material")

func test_invalid_id_returns_null() -> void:
	var res: Object = _resource_db.get_resource(999)
	assert_null(res, "Invalid ID should return null")

func test_valid_categories() -> void:
	assert_true(_resource_db.is_valid_category("raw_material"), "raw_material valid")
	assert_true(_resource_db.is_valid_category("processed"), "processed valid")
	assert_true(_resource_db.is_valid_category("component"), "component valid")
	assert_true(_resource_db.is_valid_category("ammo"), "ammo valid")
	assert_false(_resource_db.is_valid_category("invalid"), "invalid category")