# procedural_generation_test.gd
# Unit tests for Story 004: Procedural Terrain Generation

extends GutTest

var _tilemap_world: TileMapWorld

func before_all() -> void:
	var scene: PackedScene = load("res://src/world/tilemap_world.tscn")
	_tilemap_world = scene.instantiate()
	add_child_autoqfree(_tilemap_world)

func test_same_seed_produces_same_terrain() -> void:
	# 设置种子
	_tilemap_world.world_seed = 12345

	# 生成两次，应该相同
	var chunk_data1: TileMapWorld.ChunkData = TileMapWorld.ChunkData.new(Vector2i(0, 0))
	_tilemap_world._generate_terrain(chunk_data1)

	var chunk_data2: TileMapWorld.ChunkData = TileMapWorld.ChunkData.new(Vector2i(0, 0))
	_tilemap_world.world_seed = 12345  # 重置种子
	_tilemap_world._generate_terrain(chunk_data2)

	# 比较数组
	assert_eq(chunk_data1.cells_terrain_base, chunk_data2.cells_terrain_base, "Same seed = same terrain")

func test_different_seed_different_terrain() -> void:
	_tilemap_world.world_seed = 12345
	var chunk_data1: TileMapWorld.ChunkData = TileMapWorld.ChunkData.new(Vector2i(0, 0))
	_tilemap_world._generate_terrain(chunk_data1)

	_tilemap_world.world_seed = 67890
	var chunk_data2: TileMapWorld.ChunkData = TileMapWorld.ChunkData.new(Vector2i(0, 0))
	_tilemap_world._generate_terrain(chunk_data2)

	assert_ne(chunk_data1.cells_terrain_base, chunk_data2.cells_terrain_base, "Different seed = different terrain")

func test_noise_to_block_type_valid() -> void:
	# 验证返回的方块类型有效
	for noise_val in [0.0, 0.1, 0.3, 0.5, 0.7, 0.9]:
		var block_id: int = _tilemap_world._noise_to_block_type(noise_val)
		assert_gt(block_id, -1, str(noise_val) + " produces valid block_id")

func test_chunk_data_initialized() -> void:
	var chunk_data: TileMapWorld.ChunkData = TileMapWorld.ChunkData.new(Vector2i(5, 10))
	assert_eq(chunk_data.chunk_id, Vector2i(5, 10), "chunk_id initialized")
	assert_eq(chunk_data.cells_terrain_base.size(), 1024, "terrain array size = 1024")
	assert_eq(chunk_data.cells_structures.size(), 1024, "structures array size = 1024")