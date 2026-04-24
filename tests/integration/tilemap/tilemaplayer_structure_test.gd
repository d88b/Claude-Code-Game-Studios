# tilemaplayer_structure_test.gd
# Integration tests for Story 001: TileMapLayer Node Structure
# Tests verify scene structure, z_index hierarchy, and collision layer configuration

extends GutTest

# === 测试前准备 ===

var _tilemap_world: TileMapWorld

func before_all() -> void:
	# 加载 TileMapWorld 场景
	var scene: PackedScene = load("res://src/world/tilemap_world.tscn")
	_tilemap_world = scene.instantiate()
	add_child_autoqfree(_tilemap_world)

# === AC-1: 5 TileMapLayer nodes exist ===

func test_five_tilemaplayer_nodes_exist() -> void:
	# 验证 5 个 TileMapLayer 子节点存在
	var tilemap_layers: Array = _tilemap_world.get_children().filter(
		func(child: Node) -> bool: return child is TileMapLayer
	)
	assert_eq(tilemap_layers.size(), 5, "Expected 5 TileMapLayer nodes")

func test_layer_names_correct() -> void:
	# 验证层级节点名称正确
	assert_has_node(_tilemap_world, "BackgroundLayer", "BackgroundLayer missing")
	assert_has_node(_tilemap_world, "TerrainBaseLayer", "TerrainBaseLayer missing")
	assert_has_node(_tilemap_world, "StructuresLayer", "StructuresLayer missing")
	assert_has_node(_tilemap_world, "PlatformsLayer", "PlatformsLayer missing")
	assert_has_node(_tilemap_world, "OverlayLayer", "OverlayLayer missing")

func assert_has_node(parent: Node, name: String, message: String) -> void:
	var node: Node = parent.get_node_or_null(name)
	assert_not_null(node, message)

# === AC-2: Collision layers configured ===

func test_terrain_base_collision_layer() -> void:
	# terrain_base_layer collision_layer = 1
	var layer: TileMapLayer = _tilemap_world.get_node("TerrainBaseLayer")
	assert_eq(layer.collision_layer, 1, "TerrainBaseLayer collision_layer should be 1")

func test_structures_collision_layer() -> void:
	# structures_layer collision_layer = 2
	var layer: TileMapLayer = _tilemap_world.get_node("StructuresLayer")
	assert_eq(layer.collision_layer, 2, "StructuresLayer collision_layer should be 2")

func test_platforms_collision_layer() -> void:
	# platforms_layer collision_layer = 4
	var layer: TileMapLayer = _tilemap_world.get_node("PlatformsLayer")
	assert_eq(layer.collision_layer, 4, "PlatformsLayer collision_layer should be 4")

func test_background_no_collision() -> void:
	# background_layer collision_layer = 0
	var layer: TileMapLayer = _tilemap_world.get_node("BackgroundLayer")
	assert_eq(layer.collision_layer, 0, "BackgroundLayer should have no collision")

func test_overlay_no_collision() -> void:
	# overlay_layer collision_layer = 0
	var layer: TileMapLayer = _tilemap_world.get_node("OverlayLayer")
	assert_eq(layer.collision_layer, 0, "OverlayLayer should have no collision")

# === AC-3: Z-index hierarchy ===

func test_background_z_index() -> void:
	# background z_index = -10
	var layer: TileMapLayer = _tilemap_world.get_node("BackgroundLayer")
	assert_eq(layer.z_index, -10, "BackgroundLayer z_index should be -10")

func test_terrain_base_z_index() -> void:
	# terrain_base z_index = 0
	var layer: TileMapLayer = _tilemap_world.get_node("TerrainBaseLayer")
	assert_eq(layer.z_index, 0, "TerrainBaseLayer z_index should be 0")

func test_structures_z_index() -> void:
	# structures z_index = 5
	var layer: TileMapLayer = _tilemap_world.get_node("StructuresLayer")
	assert_eq(layer.z_index, 5, "StructuresLayer z_index should be 5")

func test_platforms_z_index() -> void:
	# platforms z_index = 10
	var layer: TileMapLayer = _tilemap_world.get_node("PlatformsLayer")
	assert_eq(layer.z_index, 10, "PlatformsLayer z_index should be 10")

func test_overlay_z_index() -> void:
	# overlay z_index = 20
	var layer: TileMapLayer = _tilemap_world.get_node("OverlayLayer")
	assert_eq(layer.z_index, 20, "OverlayLayer z_index should be 20")

# === TileSet resource verification ===

func test_all_layers_use_same_tileset() -> void:
	# 验证所有层级使用统一 TileSet
	var tileset: TileSet = load("res://assets/tilesets/block_types.tres")

	for layer_name in ["BackgroundLayer", "TerrainBaseLayer", "StructuresLayer", "PlatformsLayer", "OverlayLayer"]:
		var layer: TileMapLayer = _tilemap_world.get_node(layer_name)
		assert_eq(layer.tile_set, tileset, layer_name + " should use unified TileSet")

# === 常量验证 ===

func test_cell_size_constant() -> void:
	# CELL_SIZE = 32
	assert_eq(_tilemap_world.CELL_SIZE, 32, "CELL_SIZE should be 32")

func test_chunk_size_constant() -> void:
	# CHUNK_SIZE = 32
	assert_eq(_tilemap_world.CHUNK_SIZE, 32, "CHUNK_SIZE should be 32")

func test_load_radius_constant() -> void:
	# LOAD_RADIUS = 3
	assert_eq(_tilemap_world.LOAD_RADIUS, 3, "LOAD_RADIUS should be 3")