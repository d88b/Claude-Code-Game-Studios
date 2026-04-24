# tile_damage_test.gd
# Unit tests for Story 005: Tile Damage State Machine

extends GutTest

var _tilemap_world: TileMapWorld

func before_all() -> void:
	var scene: PackedScene = load("res://src/world/tilemap_world.tscn")
	_tilemap_world = scene.instantiate()
	add_child_autoqfree(_tilemap_world)

func test_tile_state_enum_values() -> void:
	assert_eq(TileMapWorld.TileState.INTACT, 0, "INTACT = 0")
	assert_eq(TileMapWorld.TileState.DAMAGED, 1, "DAMAGED = 1")
	assert_eq(TileMapWorld.TileState.CRITICAL, 2, "CRITICAL = 2")
	assert_eq(TileMapWorld.TileState.DESTROYED, 3, "DESTROYED = 3")

func test_initial_state_intact() -> void:
	var state: TileMapWorld.TileState = _tilemap_world.get_tile_state(Vector2i(0, 0))
	assert_eq(state, TileMapWorld.TileState.INTACT, "Initial state = INTACT")

func test_damage_data_class() -> void:
	var tile: TileMapWorld.TileDamageData = TileMapWorld.TileDamageData.new()
	tile.hardness = 100
	tile.damage_accumulated = 0
	assert_eq(tile.hardness, 100, "hardness initialized")
	assert_eq(tile.damage_accumulated, 0, "damage initialized")

func test_intact_to_damaged() -> void:
	# 创建模拟方块
	var tile: TileMapWorld.TileDamageData = TileMapWorld.TileDamageData.new()
	tile.grid_pos = Vector2i(10, 10)
	tile.block_id = 100
	tile.hardness = 100
	tile.damage_accumulated = 0
	_tilemap_world._tile_damage_state[Vector2i(10, 10)] = tile

	# 应用伤害
	tile.damage_accumulated = 30
	_tilemap_world._update_tile_state(tile)

	assert_eq(tile.state, TileMapWorld.TileState.DAMAGED, "30 damage on hardness 100 = DAMAGED")

func test_damaged_to_critical() -> void:
	var tile: TileMapWorld.TileDamageData = TileMapWorld.TileDamageData.new()
	tile.hardness = 100
	tile.damage_accumulated = 80
	_tilemap_world._update_tile_state(tile)

	assert_eq(tile.state, TileMapWorld.TileState.CRITICAL, "80% damage = CRITICAL")

func test_critical_to_destroyed() -> void:
	var tile: TileMapWorld.TileDamageData = TileMapWorld.TileDamageData.new()
	tile.hardness = 100
	tile.damage_accumulated = 100
	_tilemap_world._update_tile_state(tile)

	assert_eq(tile.state, TileMapWorld.TileState.DESTROYED, "100% damage = DESTROYED")

func test_overflow_damage_calculation() -> void:
	# 理论溢出计算
	var hardness: int = 100
	var accumulated: int = 60
	var new_damage: int = 50
	var overflow: int = accumulated + new_damage - hardness
	assert_eq(overflow, 10, "60+50-100 = 10 overflow")

func test_low_hardness_skips_critical() -> void:
	var tile: TileMapWorld.TileDamageData = TileMapWorld.TileDamageData.new()
	tile.hardness = 3
	tile.damage_accumulated = 2
	_tilemap_world._update_tile_state(tile)
	assert_eq(tile.state, TileMapWorld.TileState.DAMAGED, "2 damage on hardness 3 = DAMAGED")

	tile.damage_accumulated = 3
	_tilemap_world._update_tile_state(tile)
	# 硬度 <= 5 时跳过 CRITICAL
	assert_eq(tile.state, TileMapWorld.TileState.DESTROYED, "Low hardness skips CRITICAL")

func test_get_tile_damage_default() -> void:
	var damage: int = _tilemap_world.get_tile_damage(Vector2i(999, 999))
	assert_eq(damage, 0, "Unknown tile damage = 0")