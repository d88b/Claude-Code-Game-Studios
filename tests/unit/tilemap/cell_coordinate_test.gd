# tilemap_cell_coordinate_test.gd
# Unit tests for Story 002: Cell Coordinate System
# Tests verify coordinate conversion functions, bounds handling, edge cases

extends GutTest

# === 测试对象 ===

var _tilemap_world: TileMapWorld

func before_all() -> void:
	# 创建 TileMapWorld 实例
	_tilemap_world = TileMapWorld.new()
	add_child_autoqfree(_tilemap_world)

# === AC-1: world_to_cell basic conversion ===

func test_world_to_cell_basic_conversion() -> void:
	# Given: world_pos = Vector2(100.5, 200.7)
	var world_pos: Vector2 = Vector2(100.5, 200.7)
	# When: world_to_cell called
	var result: Vector2i = _tilemap_world.world_to_cell(world_pos)
	# Then: result = Vector2i(3, 6)
	assert_eq(result, Vector2i(3, 6), "100.5/32=3, 200.7/32=6")

func test_world_to_cell_fractional_positions() -> void:
	# 测试小数位置
	var cases: Array = [
		{input: Vector2(31.9, 31.9), expected: Vector2i(0, 0)},
		{input: Vector2(32.0, 32.0), expected: Vector2i(1, 1)},
		{input: Vector2(63.9, 63.9), expected: Vector2i(1, 1)},
		{input: Vector2(64.0, 64.0), expected: Vector2i(2, 2)},
	]
	for case in cases:
		var result: Vector2i = _tilemap_world.world_to_cell(case.input)
		assert_eq(result, case.expected, str(case.input) + " → " + str(case.expected))

func test_world_to_cell_zero_position() -> void:
	# Given: world_pos = Vector2(0, 0)
	var result: Vector2i = _tilemap_world.world_to_cell(Vector2(0, 0))
	# Then: result = Vector2i(0, 0)
	assert_eq(result, Vector2i(0, 0), "(0,0) should map to cell (0,0)")

# === AC-2: cell_to_world_center conversion ===

func test_cell_to_world_center_basic() -> void:
	# Given: grid_pos = Vector2i(10, 20)
	var grid_pos: Vector2i = Vector2i(10, 20)
	# When: cell_to_world_center called
	var result: Vector2 = _tilemap_world.cell_to_world_center(grid_pos)
	# Then: result = Vector2(336, 656) — (10+0.5)*32=336, (20+0.5)*32=656
	assert_eq(result, Vector2(336.0, 656.0), "Cell center should be (336, 656)")

func test_cell_to_world_center_origin() -> void:
	# Given: grid_pos = Vector2i(0, 0)
	var result: Vector2 = _tilemap_world.cell_to_world_center(Vector2i(0, 0))
	# Then: result = Vector2(16, 16) — (0+0.5)*32=16
	assert_eq(result, Vector2(16.0, 16.0), "Origin cell center should be (16, 16)")

func test_cell_to_world_center_negative() -> void:
	# Given: grid_pos = Vector2i(-10, -20)
	var result: Vector2 = _tilemap_world.cell_to_world_center(Vector2i(-10, -20))
	# Then: result = Vector2(-304, -624) — (-10+0.5)*32=-304
	assert_eq(result, Vector2(-304.0, -624.0), "Negative cell center")

# === AC-3: Bounds edge handling ===

func test_world_to_cell_bounds_clamp() -> void:
	# Given: world_pos = Vector2(32000, 32000)
	var result: Vector2i = _tilemap_world.world_to_cell(Vector2(32000, 32000))
	# Then: clamped to MAX_WORLD_BOUNDS = 1000
	assert_eq(result, Vector2i(1000, 1000), "Should clamp to MAX_WORLD_BOUNDS")

func test_world_to_cell_negative_bounds() -> void:
	# Given: world_pos = Vector2(-32000, -32000)
	var result: Vector2i = _tilemap_world.world_to_cell(Vector2(-32000, -32000))
	# Then: clamped to -MAX_WORLD_BOUNDS = -1000
	assert_eq(result, Vector2i(-1000, -1000), "Should clamp negative bounds")

func test_world_to_cell_exact_boundary() -> void:
	# Given: world_pos exactly at boundary
	var result: Vector2i = _tilemap_world.world_to_cell(Vector2(32000.0, 32000.0))
	assert_eq(result, Vector2i(1000, 1000), "Exact boundary should clamp")

func test_world_to_cell_within_bounds() -> void:
	# Given: valid world position
	var result: Vector2i = _tilemap_world.world_to_cell(Vector2(500, 500))
	assert_eq(result, Vector2i(15, 15), "500/32=15")

# === AC-4: Negative coordinate handling ===

func test_world_to_cell_negative_position() -> void:
	# Given: world_pos = Vector2(-64, -32)
	var result: Vector2i = _tilemap_world.world_to_cell(Vector2(-64, -32))
	# Then: result = Vector2i(-2, -1)
	assert_eq(result, Vector2i(-2, -1), "-64/32=-2, -32/32=-1")

func test_world_to_cell_negative_fractional() -> void:
	# Given: negative fractional position
	var result: Vector2i = _tilemap_world.world_to_cell(Vector2(-31.9, -31.9))
	# Then: rounds toward negative infinity
	assert_eq(result, Vector2i(-1, -1), "-31.9/32=-1 (floor)")

func test_world_to_cell_mixed_signs() -> void:
	# Given: mixed positive/negative
	var result: Vector2i = _tilemap_world.world_to_cell(Vector2(100, -100))
	assert_eq(result, Vector2i(3, -4), "100/32=3, -100/32=-4")

# === AC-5: CELL_SIZE constant ===

func test_cell_size_constant() -> void:
	assert_eq(_tilemap_world.CELL_SIZE, 32, "CELL_SIZE should be 32")

# === AC-6: chunk_id conversion ===

func test_get_chunk_id_for_pos() -> void:
	# Given: grid_pos = Vector2i(100, 200)
	var grid_pos: Vector2i = Vector2i(100, 200)
	# When: get_chunk_id_for_pos called
	var result: Vector2i = _tilemap_world.get_chunk_id_for_pos(grid_pos)
	# Then: result = Vector2i(3, 6) — 100/32=3, 200/32=6
	assert_eq(result, Vector2i(3, 6), "Chunk ID should be (3, 6)")

func test_get_chunk_id_for_origin() -> void:
	var result: Vector2i = _tilemap_world.get_chunk_id_for_pos(Vector2i(0, 0))
	assert_eq(result, Vector2i(0, 0), "Origin chunk ID")

func test_get_chunk_id_for_boundary() -> void:
	# Grid position at chunk boundary
	var result: Vector2i = _tilemap_world.get_chunk_id_for_pos(Vector2i(31, 31))
	assert_eq(result, Vector2i(0, 0), "31/32=0 (same chunk)")

	var result2: Vector2i = _tilemap_world.get_chunk_id_for_pos(Vector2i(32, 32))
	assert_eq(result2, Vector2i(1, 1), "32/32=1 (next chunk)")