# projectile_entity_test.gd
# ProjectileEntity 单元测试
## 测试弹道实体的核心功能

extends GutTest

# === 测试对象 ===
var projectile: Area2D = null
var mock_weapon_controller: Node = null

# === Setup/Teardown ===

func before_each() -> void:
	# 创建弹道实例
	projectile = ProjectileEntityScript.new()

	# 创建模拟 weapon_controller
	mock_weapon_controller = _create_mock_weapon_controller()

	add_child(projectile)

func after_each() -> void:
	if projectile != null and is_instance_valid(projectile):
		projectile.queue_free()
		projectile = null

	if mock_weapon_controller != null and is_instance_valid(mock_weapon_controller):
		mock_weapon_controller.queue_free()
		mock_weapon_controller = null

# === 辅助方法 ===

func _create_mock_weapon_controller() -> Node:
	var mock: Node = Node.new()
	mock.set_script(load("res://src/weapon/weapon_controller.gd"))
	mock.base_damage = 20.0
	mock.crit_chance = 0.0  # 禁用暴击便于测试
	return mock

# === 初始化测试 ===

func test_initialize_sets_basic_properties() -> void:
	var start_pos: Vector2 = Vector2(100, 100)
	var direction: Vector2 = Vector2.RIGHT
	var speed: float = 640.0
	var range_pixels: float = 480.0
	var damage: float = 20.0

	projectile.initialize(1, 1, start_pos, direction, speed, range_pixels, damage, mock_weapon_controller)

	assert_eq(projectile.weapon_type_id, 1, "weapon_type_id 应为 1")
	assert_eq(projectile.owner_id, 1, "owner_id 应为 1")
	assert_eq(projectile.speed, speed, "speed 应匹配")
	assert_eq(projectile.max_range, range_pixels, "max_range 应匹配")
	assert_eq(projectile.base_damage, damage, "base_damage 应匹配")
	assert_almost_eq(projectile.direction.x, 1.0, 0.01, "direction.x 应约等于 1")
	assert_almost_eq(projectile.direction.y, 0.0, 0.01, "direction.y 应约等于 0")
	assert_true(projectile.is_initialized, "is_initialized 应为 true")

func test_initialize_normalizes_direction() -> void:
	var start_pos: Vector2 = Vector2(100, 100)
	var unnormalized_dir: Vector2 = Vector2(3, 0)  # 未归一化

	projectile.initialize(1, 1, start_pos, unnormalized_dir, 640.0, 480.0, 20.0, null)

	# direction 应被归一化
	assert_almost_eq(projectile.direction.length(), 1.0, 0.01, "direction 应归一化")

func test_initialize_resets_traveled_distance() -> void:
	# 先移动一些距离
	projectile.initialize(1, 1, Vector2(100, 100), Vector2.RIGHT, 640.0, 480.0, 20.0, null)
	projectile.traveled_distance = 100.0  # 模拟已飞行

	# 重新初始化
	projectile.initialize(1, 1, Vector2(200, 200), Vector2.UP, 640.0, 480.0, 20.0, null)

	assert_eq(projectile.traveled_distance, 0.0, "重新初始化后 traveled_distance 应为 0")

# === 移动测试 ===

func test_physics_process_moves_projectile() -> void:
	var start_pos: Vector2 = Vector2(100, 100)
	var speed: float = 640.0  # 像素/秒

	projectile.initialize(1, 1, start_pos, Vector2.RIGHT, speed, 480.0, 20.0, null)

	# 模拟一帧 (16.6ms ≈ 1/60秒)
	simulate(projectile, 1, 1.0/60.0)

	var expected_move: float = speed / 60.0
	assert_almost_eq(projectile.traveled_distance, expected_move, 1.0, "飞行距离应约等于 speed * delta")
	assert_almost_eq(projectile.position.x, start_pos.x + expected_move, 1.0, "位置应更新")

func test_projectile_expires_at_max_range() -> void:
	var start_pos: Vector2 = Vector2(100, 100)
	var speed: float = 640.0
	var range_pixels: float = 480.0

	projectile.initialize(1, 1, start_pos, Vector2.RIGHT, speed, range_pixels, 20.0, null)

	# 模拟飞行直到射程结束
	# 480 pixels / 640 pixels/sec = 0.75 seconds
	simulate(projectile, 60, 0.75)

	# 弹道应该已消失或标记为命中
	assert_true(projectile.has_hit or not is_instance_valid(projectile), "弹道应消失或标记命中")

func test_projectile_times_out() -> void:
	projectile.initialize(1, 1, Vector2.ZERO, Vector2.RIGHT, 100.0, 100000.0, 20.0, null)  # 极大射程

	# 模拟超过最大飞行时间
	simulate(projectile, 300, 5.1)  # MAX_FLIGHT_TIME = 5.0

	# 弹道应消失
	assert_true(not is_instance_valid(projectile) or projectile.has_hit, "弹道应超时消失")

# === 伤害计算测试 ===

func test_calculate_damage_without_weapon_controller() -> void:
	projectile.initialize(1, 1, Vector2.ZERO, Vector2.RIGHT, 640.0, 480.0, 20.0, null)
	projectile.traveled_distance = 100.0

	# 创建模拟敌人
	var mock_enemy: Node2D = Node2D.new()
	mock_enemy.armor = 0.0
	add_child(mock_enemy)

	var damage: float = projectile._calculate_damage(mock_enemy)

	# 无 weapon_controller 时使用简单计算
	assert_almost_eq(damage, 20.0, 0.1, "无 weapon_controller 时伤害应约等于 base_damage")

	mock_enemy.queue_free()

func test_calculate_damage_with_armor() -> void:
	projectile.initialize(1, 1, Vector2.ZERO, Vector2.RIGHT, 640.0, 480.0, 20.0, mock_weapon_controller)

	# 创建高护甲敌人
	var mock_enemy: Node2D = Node2D.new()
	mock_enemy.armor = 50.0  # 50% 护甲
	add_child(mock_enemy)

	var damage: float = projectile._calculate_damage(mock_enemy)

	# 50% 护甲减伤 (最大 80%)
	# damage = base_damage * (1 - armor_reduction) = 20 * (1 - 0.5) = 10
	assert_almost_eq(damage, 10.0, 1.0, "50% 护甲应减少一半伤害")

	mock_enemy.queue_free()

# === 测试辅助功能 ===

func test_set_speed_for_test() -> void:
	projectile.set_speed_for_test(1000.0)
	assert_eq(projectile.speed, 1000.0, "speed 应更新")

func test_set_range_for_test() -> void:
	projectile.set_range_for_test(800.0)
	assert_eq(projectile.max_range, 800.0, "max_range 应更新")

func test_set_damage_for_test() -> void:
	projectile.set_damage_for_test(50.0)
	assert_eq(projectile.base_damage, 50.0, "base_damage 应更新")

func test_set_direction_for_test() -> void:
	projectile.set_direction_for_test(Vector2(1, 1))
	assert_almost_eq(projectile.direction.length(), 1.0, 0.01, "direction 应归一化")

# === 预加载 ===

const ProjectileEntityScript := preload("res://src/projectile/projectile_entity.gd")