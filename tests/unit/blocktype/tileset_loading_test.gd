# tileset_loading_test.gd
# Unit tests for Story 004: TileSet Resource Loading
# Tests verify BlockTypeDB initialization, tile count, ID allocation

extends GutTest

const BlockTypeDBScript := preload("res://src/database/block_type_db.gd")

var _block_type_db: Object

func before_all() -> void:
	# 创建 BlockTypeDB 实例
	_block_type_db = BlockTypeDBScript.new()
	add_child_autoqfree(_block_type_db)

# === AC-1: TileSet resource loading ===

func test_tileset_loads_successfully() -> void:
	# TileSet 加载成功
	assert_true(_block_type_db.is_loaded(), "BlockTypeDB should be loaded")

func test_tileset_not_null() -> void:
	assert_not_null(_block_type_db._tile_set, "TileSet should not be null")

# === AC-2: Tile count validation ===

func test_tile_count_minimum() -> void:
	# tile_count >= 25 (MVP catalog minimum)
	assert_gt(_block_type_db.tile_count, 25, "tile_count should be >= 25")

func test_tile_count_positive() -> void:
	assert_gt(_block_type_db.tile_count, 0, "tile_count should be positive")

# === AC-3: Unique tile IDs ===

func test_unique_tile_ids() -> void:
	# 所有 tile_id 唯一
	var seen_ids: Dictionary = {}
	for tile_id: int in _block_type_db._tile_data_cache.keys():
		assert_false(seen_ids.has(tile_id), "tile_id " + str(tile_id) + " should be unique")
		seen_ids[tile_id] = true

# === AC-4: ID allocation scheme ===

func test_terrain_id_range() -> void:
	# 地形方块在 0-399
	var terrain_tiles: Array = _block_type_db.get_tiles_by_category("terrain")
	for tile_id in terrain_tiles:
		assert_gt(tile_id, -1, "terrain tile_id >= 0")
		assert_lt(tile_id, 400, "terrain tile_id < 400")

func test_ore_id_range() -> void:
	# 矿石在 500-999
	var ore_tiles: Array = _block_type_db.get_tiles_by_category("ore")
	for tile_id in ore_tiles:
		assert_gt(tile_id, 499, "ore tile_id >= 500")
		assert_lt(tile_id, 1000, "ore tile_id < 1000")

func test_building_id_range() -> void:
	# 建筑在 1000-2999
	var building_tiles: Array = _block_type_db.get_tiles_by_category("building")
	for tile_id in building_tiles:
		assert_gt(tile_id, 999, "building tile_id >= 1000")
		assert_lt(tile_id, 3000, "building tile_id < 3000")

# === AC-5: NULL_TILE definition ===

func test_null_tile_exists() -> void:
	var null_tile: Object = _block_type_db.get_tile_data(0)
	assert_not_null(null_tile, "NULL_TILE (ID=0) should exist")

func test_null_tile_hardness() -> void:
	var null_tile: Object = _block_type_db.get_tile_data(0)
	assert_eq(null_tile.hardness, 255, "NULL_TILE hardness should be 255")

func test_null_tile_destructibility() -> void:
	var null_tile: Object = _block_type_db.get_tile_data(0)
	assert_eq(null_tile.destructibility, 0, "NULL_TILE should be indestructible")

func test_bedrock_indestructible() -> void:
	# 基岩 (ID=1) destructibility = 0
	var bedrock: Object = _block_type_db.get_tile_data(1)
	assert_eq(bedrock.destructibility, 0, "Bedrock should be indestructible")

func test_bedrock_hardness_override() -> void:
	# get_hardness(1) 应返回 255 (不可破坏覆盖)
	var hardness: int = _block_type_db.get_hardness(1)
	assert_eq(hardness, 255, "Bedrock hardness should return 255 (indestructible)")