# query_api_test.gd
# Unit tests for Story 005: Query API Implementation
# Tests verify BlockTypeDB query methods, edge cases, invalid ID handling

extends GutTest

const BlockTypeDBScript := preload("res://src/database/block_type_db.gd")

var _block_type_db: Object

func before_all() -> void:
	_block_type_db = BlockTypeDBScript.new()
	add_child_autoqfree(_block_type_db)

# === AC-1: Valid ID query ===

func test_get_tile_data_valid_id() -> void:
	# Given: tile_id = 100 (valid terrain tile)
	var result: Object = _block_type_db.get_tile_data(100)
	# Then: returns BlockDefinition
	assert_not_null(result, "Valid ID should return BlockDefinition")

func test_get_tile_data_properties() -> void:
	var data: Object = _block_type_db.get_tile_data(100)
	assert_eq(data.hardness, 60, "Terrain hardness should be 60")
	assert_eq(data.destructibility, 1, "Terrain should be destructible")

func test_get_tile_data_multiple_valid_ids() -> void:
	# 测试多个有效 ID
	for tile_id in [100, 500, 1000]:
		var data: Object = _block_type_db.get_tile_data(tile_id)
		assert_not_null(data, str(tile_id) + " should be valid")

# === AC-2: Invalid ID query ===

func test_get_tile_data_invalid_id() -> void:
	# Given: tile_id = 450 (invalid, not in allocation)
	var result: Object = _block_type_db.get_tile_data(450)
	# Then: returns null, no exception
	assert_null(result, "Invalid ID should return null")

func test_get_tile_data_negative_id() -> void:
	var result: Object = _block_type_db.get_tile_data(-1)
	assert_null(result, "Negative ID should return null")

func test_get_tile_data_out_of_range() -> void:
	# ID > 65535 (out of uint16 range)
	var result: Object = _block_type_db.get_tile_data(70000)
	assert_null(result, "ID > 65535 should return null")

# === AC-3: Hardness override for indestructible ===

func test_get_hardness_indestructible() -> void:
	# Given: tile_id = 1 (bedrock, destructibility=0)
	var hardness: int = _block_type_db.get_hardness(1)
	# Then: returns 255 (override), not stored hardness
	assert_eq(hardness, 255, "Indestructible tile should return 255")

func test_get_hardness_destructible() -> void:
	# destructibility=1 返回存储的硬度
	var hardness: int = _block_type_db.get_hardness(100)
	assert_eq(hardness, 60, "Destructible tile returns stored hardness")

func test_get_hardness_invalid_id() -> void:
	# 无效 ID 返回 255 (默认不可破坏)
	var hardness: int = _block_type_db.get_hardness(450)
	assert_eq(hardness, 255, "Invalid ID returns 255")

# === AC-4: Collision shape query ===

func test_get_collision_shape_solid() -> void:
	# 完整碰撞 (collision_shape=1)
	var shape: int = _block_type_db.get_collision_shape(100)
	assert_eq(shape, 1, "Solid tile should return 1")

func test_get_collision_shape_platform() -> void:
	# 平台碰撞 (collision_shape=2)
	var shape: int = _block_type_db.get_collision_shape(1510)
	assert_eq(shape, 2, "Platform should return 2")

func test_get_collision_shape_none() -> void:
	# 无碰撞 (collision_shape=0)
	var shape: int = _block_type_db.get_collision_shape(0)  # NULL_TILE
	assert_eq(shape, 0, "NULL_TILE should have no collision")

func test_get_collision_shape_invalid() -> void:
	var shape: int = _block_type_db.get_collision_shape(450)
	assert_eq(shape, 0, "Invalid ID returns 0 (no collision)")

# === AC-5: Buildability query ===

func test_is_buildable_natural() -> void:
	# 自然方块 (buildability=0)
	var result: bool = _block_type_db.is_buildable(100)
	assert_false(result, "Natural terrain should not be buildable")

func test_is_buildable_building() -> void:
	# 建筑方块 (buildability=1)
	var result: bool = _block_type_db.is_buildable(1000)
	assert_true(result, "Building should be buildable")

func test_is_buildable_invalid() -> void:
	var result: bool = _block_type_db.is_buildable(450)
	assert_false(result, "Invalid ID returns false")

# === AC-6: Layer validation ===

func test_can_place_on_layer_valid() -> void:
	# 建筑方块可在 structures layer (2) 放置
	var result: bool = _block_type_db.can_place_on_layer(1000, 2)
	assert_true(result, "Building can place on structures layer")

func test_can_place_on_layer_invalid() -> void:
	# 地形方块不能在 structures layer 放置
	var result: bool = _block_type_db.can_place_on_layer(100, 2)
	assert_false(result, "Terrain cannot place on structures layer")

func test_can_place_on_layer_terrain() -> void:
	# 地形方块可在 terrain_base layer (1)
	var result: bool = _block_type_db.can_place_on_layer(100, 1)
	assert_true(result, "Terrain can place on terrain_base layer")

func test_can_place_on_layer_platform() -> void:
	# 平台方块 (ID=1510) 可在 platforms layer (3)
	var result: bool = _block_type_db.can_place_on_layer(1510, 3)
	assert_true(result, "Platform can place on platforms layer")

func test_can_place_on_layer_invalid_id() -> void:
	var result: bool = _block_type_db.can_place_on_layer(450, 1)
	assert_false(result, "Invalid ID returns false")

# === Resource query ===

func test_get_resource_type_id() -> void:
	# 矿石有资源产出
	var resource_id: int = _block_type_db.get_resource_type_id(500)
	assert_gt(resource_id, 0, "Ore should have resource output")

func test_get_resource_multiplier() -> void:
	var multiplier: float = _block_type_db.get_resource_multiplier(500)
	assert_gt(multiplier, 0.0, "Resource multiplier should be positive")

# === Category query ===

func test_get_tiles_by_category() -> void:
	var terrain_tiles: Array = _block_type_db.get_tiles_by_category("terrain")
	assert_gt(terrain_tiles.size(), 0, "Should have terrain tiles")

func test_get_buildable_tiles() -> void:
	var buildable: Array = _block_type_db.get_buildable_tiles()
	assert_gt(buildable.size(), 0, "Should have buildable tiles")