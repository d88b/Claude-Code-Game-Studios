# collision_query_test.gd
# Unit tests for Story: Collision Query API
# tests/unit/collision/collision_query_test.gd

extends GutTest

const CollisionManagerScript := preload("res://src/collision/collision_manager.gd")
const TileMapWorldScript := preload("res://src/world/tilemap_world.gd")
const BlockTypeDBScript := preload("res://src/database/block_type_db.gd")

var _collision_manager: Object
var _mock_tilemap: Object
var _block_type_db: Object

func before_all() -> void:
	# 创建 BlockTypeDB (autoload)
	_block_type_db = BlockTypeDBScript.new()
	add_child_autoqfree(_block_type_db)
	await get_tree().process_frame

	# 创建 CollisionManager
	_collision_manager = CollisionManagerScript.new()
	add_child_autoqfree(_collision_manager)

	# 注入依赖
	_collision_manager.set_block_type_db(_block_type_db)
	_collision_manager.set_global_signals(GlobalSignals)

	# 创建 mock TileMapWorld
	_mock_tilemap = TileMapWorldScript.new()
	add_child_autoqfree(_mock_tilemap)
	await get_tree().process_frame
	_collision_manager.set_tilemap_world(_mock_tilemap)

# === 常量验证测试 ===

func test_max_swept_steps_is_64() -> void:
	assert_eq(_collision_manager.MAX_SWEPT_STEPS, 64, "MAX_SWEPT_STEPS should be 64")

func test_max_raycast_steps_is_128() -> void:
	assert_eq(_collision_manager.MAX_RAYCAST_STEPS, 128, "MAX_RAYCAST_STEPS should be 128")

func test_collision_epsilon_is_small() -> void:
	assert_almost_eq(_collision_manager.COLLISION_EPSILON, 0.001, 0.0001,
		"COLLISION_EPSILON should be 0.001")

func test_cell_size_is_32() -> void:
	assert_eq(_collision_manager.CELL_SIZE, 32, "CELL_SIZE should be 32")

func test_collision_layer_constants_correct() -> void:
	assert_eq(_collision_manager.COLLISION_TERRAIN, 1, "COLLISION_TERRAIN should be 1")
	assert_eq(_collision_manager.COLLISION_STRUCTURE, 2, "COLLISION_STRUCTURE should be 2")
	assert_eq(_collision_manager.COLLISION_PLATFORM, 4, "COLLISION_PLATFORM should be 4")
	assert_eq(_collision_manager.COLLISION_PLAYER_BODY, 64, "COLLISION_PLAYER_BODY should be 64")

# === 依赖注入测试 ===

func test_is_initialized_returns_true_after_setup() -> void:
	assert_true(_collision_manager.is_initialized(), "Should be initialized after setup")

func test_set_tilemap_world_method_exists() -> void:
	assert_true(_collision_manager.has_method("set_tilemap_world"),
		"set_tilemap_world method should exist")

func test_get_tilemap_world_returns_injected_ref() -> void:
	var ref: Object = _collision_manager.get_tilemap_world()
	assert_eq(ref, _mock_tilemap, "Should return injected TileMapWorld reference")

# === is_cell_solid 测试 ===

func test_is_cell_solid_returns_false_for_empty_cell() -> void:
	# Given: 空单元格 (超出加载范围)
	var cell: Vector2i = Vector2i(1000, 1000)

	# When: is_cell_solid 查询
	var result: bool = _collision_manager.is_cell_solid(cell)

	# Then: 返回 false (无方块)
	assert_false(result, "Empty cell should not be solid")

# === raycast_tile_collision 测试 ===

func test_raycast_returns_no_hit_for_zero_direction() -> void:
	# Given: 方向为零向量
	var start: Vector2 = Vector2(100.0, 100.0)
	var end: Vector2 = start  # 零距离

	# When: raycast
	var result: Object = _collision_manager.raycast_tile_collision(start, end)

	# Then: 返回无碰撞结果
	assert_false(result.position == Vector2.ZERO or result.block_id == 0,
		"Zero direction should return no hit")

func test_raycast_returns_no_hit_for_clear_path() -> void:
	# Given: raycast 从起点到终点 (无碰撞)
	var start: Vector2 = Vector2(0.0, 0.0)
	var end: Vector2 = Vector2(320.0, 0.0)  # 10 cells

	# When: raycast (空区域)
	var result: Object = _collision_manager.raycast_tile_collision(start, end)

	# Then: 无碰撞时返回无碰撞结果
	# (由于 TileMapWorld 无方块，应该返回空)
	assert_true(result.block_id == 0, "Clear path should have no collision")

# === check_swept_collision 测试 ===

func test_swept_collision_returns_no_collision_for_zero_velocity() -> void:
	# Given: 静止碰撞体
	var body_rect: Rect2 = Rect2(Vector2(100.0, 100.0), Vector2(64.0, 64.0))
	var velocity: Vector2 = Vector2.ZERO

	# When: swept collision
	var result: Object = _collision_manager.check_swept_collision(body_rect, velocity)

	# Then: 返回静态碰撞检测结果
	assert_false(result.hit, "Zero velocity should return static collision result")

func test_swept_collision_truncates_long_motion() -> void:
	# Given: 极长运动距离 (> MAX_SWEPT_STEPS cells)
	var body_rect: Rect2 = Rect2(Vector2(0.0, 0.0), Vector2(64.0, 64.0))
	var velocity: Vector2 = Vector2(3000.0, 0.0)  # ~94 cells

	# When: swept collision
	# (内部步数被截断到 MAX_SWEPT_STEPS)
	var result: Object = _collision_manager.check_swept_collision(body_rect, velocity)

	# Then: 方法应正确执行 (无崩溃)
	assert_true(result != null, "Should handle long motion without crash")

# === get_nearest_collision 测试 ===

func test_get_nearest_collision_returns_empty_for_zero_radius() -> void:
	# Given: 零搜索半径
	var pos: Vector2 = Vector2(100.0, 100.0)
	var radius: float = 0.0

	# When: 搜索最近碰撞
	var result: Dictionary = _collision_manager.get_nearest_collision(pos, radius)

	# Then: 返回空
	assert_true(result.is_empty(), "Zero radius should return empty result")

func test_get_nearest_collision_returns_empty_for_negative_radius() -> void:
	# Given: 负搜索半径
	var pos: Vector2 = Vector2(100.0, 100.0)
	var radius: float = -100.0

	# When: 搜索最近碰撞
	var result: Dictionary = _collision_manager.get_nearest_collision(pos, radius)

	# Then: 返回空
	assert_true(result.is_empty(), "Negative radius should return empty result")

# === calculate_severity 测试 ===

func test_severity_is_zero_for_zero_velocity() -> void:
	# Given: 零速度碰撞
	var velocity: Vector2 = Vector2.ZERO
	var integrity: float = 1.0
	var significance: float = 1.0

	# When: 计算严重程度
	var severity: float = _collision_manager.calculate_severity(velocity, integrity, significance)

	# Then: severity = 0.0
	assert_eq(severity, 0.0, "Zero velocity should produce zero severity")

func test_severity_is_clamped_to_1_0() -> void:
	# Given: 极高速度
	var velocity: Vector2 = Vector2(1000.0, 0.0)  # 高速度
	var integrity: float = 0.5  # 低完整度
	var significance: float = 2.0  # 高重要性

	# When: 计算严重程度
	var severity: float = _collision_manager.calculate_severity(velocity, integrity, significance)

	# Then: severity 被截断到 1.0
	assert_true(severity <= 1.0, "Severity should be clamped to 1.0 max")

func test_severity_formula_correct() -> void:
	# Given: 速度 = max_speed (10 cells/sec = 320 pixels/sec)
	var velocity: Vector2 = Vector2(320.0, 0.0)
	var integrity: float = 1.0
	var significance: float = 1.0

	# When: 计算严重程度
	var severity: float = _collision_manager.calculate_severity(velocity, integrity, significance)

	# Then: severity ≈ 1.0
	assert_almost_eq(severity, 1.0, 0.1, "Max speed + full integrity should produce severity ~1.0")

func test_severity_with_low_integrity_is_higher() -> void:
	# Given: 相同速度，不同完整度
	var velocity: Vector2 = Vector2(160.0, 0.0)  # 5 cells/sec
	var integrity_high: float = 1.0
	var integrity_low: float = 0.0
	var significance: float = 1.0

	var severity_high: float = _collision_manager.calculate_severity(velocity, integrity_high, significance)
	var severity_low: float = _collision_manager.calculate_severity(velocity, integrity_low, significance)

	# Then: 低完整度产生更高严重程度
	assert_true(severity_low > severity_high, "Low integrity should produce higher severity")

# === 坐标转换测试 ===

func test_world_to_cell_conversion() -> void:
	# Given: 世界坐标
	var world_pos: Vector2 = Vector2(64.0, 96.0)

	# When: 转换为单元格坐标
	var cell: Vector2i = _collision_manager.world_to_cell(world_pos)

	# Then: 正确转换
	assert_eq(cell.x, 2, "World 64 -> Cell 2")
	assert_eq(cell.y, 3, "World 96 -> Cell 3")

func test_cell_to_world_center_conversion() -> void:
	# Given: 单元格坐标
	var cell: Vector2i = Vector2i(2, 3)

	# When: 转换为世界坐标 (中心)
	var world: Vector2 = _collision_manager.cell_to_world_center(cell)

	# Then: 正确转换 (中心)
	assert_eq(world.x, 80.0, "Cell 2 center -> World 80")
	assert_eq(world.y, 112.0, "Cell 3 center -> World 112")

# === API 存在性测试 ===

func test_queue_tile_modification_exists() -> void:
	assert_true(_collision_manager.has_method("queue_tile_modification"),
		"queue_tile_modification method should exist")

func test_get_tiles_in_rect_exists() -> void:
	assert_true(_collision_manager.has_method("get_tiles_in_rect"),
		"get_tiles_in_rect method should exist")

func test_matches_collision_filter_exists() -> void:
	assert_true(_collision_manager.has_method("matches_collision_filter"),
		"matches_collision_filter method should exist")

func test_get_cell_collision_shape_exists() -> void:
	assert_true(_collision_manager.has_method("get_cell_collision_shape"),
		"get_cell_collision_shape method should exist")

# === 碰撞过滤器测试 ===

func test_filter_destroyable_constant_correct() -> void:
	assert_eq(_collision_manager.FILTER_DESTROYABLE, 0x01, "FILTER_DESTROYABLE should be 0x01")

func test_filter_reinforced_constant_correct() -> void:
	assert_eq(_collision_manager.FILTER_REINFORCED, 0x02, "FILTER_REINFORCED should be 0x02")

func test_filter_all_walls_constant_correct() -> void:
	assert_eq(_collision_manager.FILTER_ALL_WALLS, 0xFF, "FILTER_ALL_WALLS should be 0xFF")