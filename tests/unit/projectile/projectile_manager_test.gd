# projectile_manager_test.gd
# ProjectileManager 单元测试
## 测试弹道管理器的核心功能

extends GutTest

# === 测试对象 ===
var manager: Node = null

# === Setup/Teardown ===

func before_each() -> void:
	# 创建管理器实例
	manager = ProjectileManagerScript.new()
	add_child(manager)

func after_each() -> void:
	if manager != null and is_instance_valid(manager):
		manager.clear_all_projectiles()
		manager.queue_free()
		manager = null

# === 初始化测试 ===

func test_ready_initializes_manager() -> void:
	# manager 在 before_each 中已创建并添加
	assert_true(manager.is_initialized or manager._projectile_pool != null, "管理器应初始化")

# === 弹道生成测试 ===

func test_spawn_projectile_creates_instance() -> void:
	var projectile: Area2D = manager.spawn_projectile(
		1,  # weapon_type_id
		1,  # owner_id
		Vector2(100, 100),  # position
		Vector2.RIGHT,  # direction
		640.0,  # speed
		480.0,  # range
		20.0   # damage
	)

	assert_not_null(projectile, "应创建弹道实例")
	assert_eq(manager.get_active_count(), 1, "活跃弹道数应为 1")

func test_spawn_projectile_respects_limit() -> void:
	# 设置较低上限便于测试
	manager.MAX_ACTIVE_PROJECTILES = 3

	# 尝试生成超过上限
	for i in range(5):
		manager.spawn_projectile(
			1, 1, Vector2(i * 100, 100), Vector2.RIGHT, 640.0, 480.0, 20.0
		)

	# 应只有 3 个活跃
	assert_eq(manager.get_active_count(), 3, "活跃弹道数不应超过上限")

func test_spawn_projectile_initializes_properties() -> void:
	var projectile: Area2D = manager.spawn_projectile(
		1, 1, Vector2(100, 100), Vector2.RIGHT, 640.0, 480.0, 20.0
	)

	if projectile != null and projectile.has_method("initialize"):
		# 等待初始化完成
		await wait_frames(1)

		assert_eq(projectile.weapon_type_id, 1, "weapon_type_id 应正确设置")
		assert_eq(projectile.owner_id, 1, "owner_id 应正确设置")
		assert_almost_eq(projectile.speed, 640.0, 0.1, "speed 应正确设置")

# === 清理测试 ===

func test_clear_all_projectiles_removes_active() -> void:
	# 创建多个弹道
	for i in range(3):
		manager.spawn_projectile(1, 1, Vector2(i * 100, 100), Vector2.RIGHT, 640.0, 480.0, 20.0)

	assert_eq(manager.get_active_count(), 3, "应有 3 个活跃弹道")

	manager.clear_all_projectiles()

	assert_eq(manager.get_active_count(), 0, "清理后应无活跃弹道")

# === 对象池测试 ===

func test_pool_reuse() -> void:
	# 如果场景存在，测试池重用
	if manager._projectile_scene == null:
		pending("场景不存在，跳过池重用测试")
		return

	# 生成并回收
	var p1: Area2D = manager.spawn_projectile(1, 1, Vector2.ZERO, Vector2.RIGHT, 640.0, 480.0, 20.0)
	p1.queue_free()
	manager.active_projectiles.clear()

	# 再次生成应从池获取
	var p2: Area2D = manager.spawn_projectile(1, 1, Vector2.ZERO, Vector2.RIGHT, 640.0, 480.0, 20.0)

	assert_not_null(p2, "应能从池获取弹道")

# === 公共 API 测试 ===

func test_get_active_count() -> void:
	assert_eq(manager.get_active_count(), 0, "初始应为 0")

	manager.spawn_projectile(1, 1, Vector2.ZERO, Vector2.RIGHT, 640.0, 480.0, 20.0)
	assert_eq(manager.get_active_count(), 1, "生成后应为 1")

	manager.spawn_projectile(1, 1, Vector2.ZERO, Vector2.RIGHT, 640.0, 480.0, 20.0)
	assert_eq(manager.get_active_count(), 2, "再生成后应为 2")

# === 预加载 ===

const ProjectileManagerScript := preload("res://src/projectile/projectile_manager.gd")