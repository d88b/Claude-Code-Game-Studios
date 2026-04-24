# chunk_loading_test.gd
# Unit tests for Story 003: Chunk Loading System

extends GutTest

var _tilemap_world: TileMapWorld

func before_all() -> void:
	var scene: PackedScene = load("res://src/world/tilemap_world.tscn")
	_tilemap_world = scene.instantiate()
	add_child_autoqfree(_tilemap_world)

func test_get_chunk_id_for_pos() -> void:
	var result: Vector2i = _tilemap_world.get_chunk_id_for_pos(Vector2i(100, 200))
	assert_eq(result, Vector2i(3, 6), "100/32=3, 200/32=6")

func test_get_chunk_id_for_boundary() -> void:
	var result1: Vector2i = _tilemap_world.get_chunk_id_for_pos(Vector2i(31, 31))
	assert_eq(result1, Vector2i(0, 0), "31/32=0")
	var result2: Vector2i = _tilemap_world.get_chunk_id_for_pos(Vector2i(32, 32))
	assert_eq(result2, Vector2i(1, 1), "32/32=1")

func test_get_chunk_id_negative() -> void:
	var result: Vector2i = _tilemap_world.get_chunk_id_for_pos(Vector2i(-64, -32))
	assert_eq(result, Vector2i(-2, -1), "-64/32=-2, -32/32=-1")

func test_chunk_size_constant() -> void:
	assert_eq(_tilemap_world.CHUNK_SIZE, 32, "CHUNK_SIZE = 32")

func test_load_radius_constant() -> void:
	assert_eq(_tilemap_world.LOAD_RADIUS, 3, "LOAD_RADIUS = 3")

func test_unload_delay_constant() -> void:
	assert_eq(_tilemap_world.UNLOAD_DELAY, 30.0, "UNLOAD_DELAY = 30s")

func test_world_seed_exists() -> void:
	assert_gt(_tilemap_world.world_seed, 0, "world_seed should be set")