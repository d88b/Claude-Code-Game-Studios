# weapon_system_test.gd
# 武器系统测试 — content-002
## 武器系统测试
## 验证机枪和炮弹武器的行为逻辑
## QA Plan: production/qa/qa-plan-sprint-5-2026-04-26.md

extends GutTest

# === 测试目标 ===
const WEAPON_CONTROLLER_PATH: String = "res://src/weapon/weapon_controller.gd"
const PROJECTILE_ENTITY_PATH: String = "res://src/projectile/projectile_entity.gd"

# === 常量引用 ===
var CELL_SIZE: int = 32

# === 测试实例 ===
var weapon_controller: Node = null
var projectile_entity: Area2D = null

func before_each() -> void:
	# 创建武器控制器实例
	var weapon_script: GDScript = load(WEAPON_CONTROLLER_PATH)
	weapon_controller = weapon_script.new()

	# 创建弹道实体实例
	var projectile_script: GDScript = load(PROJECTILE_ENTITY_PATH)
	projectile_entity = projectile_script.new()

func after_each() -> void:
	if weapon_controller != null and is_instance_valid(weapon_controller):
		weapon_controller.queue_free()
	weapon_controller = null

	if projectile_entity != null and is_instance_valid(projectile_entity):
		projectile_entity.queue_free()
	projectile_entity = null

# === 武器类型定义测试 ===

## 测试机枪武器初始化 (weapon_id = 5)
func test_machine_gun_initialization() -> void:
	weapon_controller.initialize(5)

	assert_eq(weapon_controller.weapon_type_id, 5, "Weapon ID should be 5")
	assert_eq(weapon_controller.base_damage, 8.0, "Machine gun damage should be 8.0")
	assert_eq(weapon_controller.fire_rate, 10.0, "Machine gun fire_rate should be 10.0 (high frequency)")
	assert_eq(weapon_controller.fire_mode, weapon_controller.FireMode.AUTO, "Machine gun should be AUTO fire mode")
	assert_eq(weapon_controller.range_cells, 8.0, "Machine gun range should be 8 cells")
	assert_eq(weapon_controller.magic_cost_per_shot, 2.0, "Machine gun magic cost should be 2.0")
	assert_eq(weapon_controller.explosion_radius, 0.0, "Machine gun should have no explosion radius")

## 测试炮弹武器初始化 (weapon_id = 6)
func test_cannon_initialization() -> void:
	weapon_controller.initialize(6)

	assert_eq(weapon_controller.weapon_type_id, 6, "Weapon ID should be 6")
	assert_eq(weapon_controller.base_damage, 60.0, "Cannon damage should be 60.0 (high)")
	assert_eq(weapon_controller.fire_rate, 1.5, "Cannon fire_rate should be 1.5 (slow)")
	assert_eq(weapon_controller.fire_mode, weapon_controller.FireMode.SINGLE, "Cannon should be SINGLE fire mode")
	assert_eq(weapon_controller.range_cells, 20.0, "Cannon range should be 20 cells")
	assert_eq(weapon_controller.magic_cost_per_shot, 15.0, "Cannon magic cost should be 15.0")
	assert_eq(weapon_controller.explosion_radius, 3.0, "Cannon should have explosion radius 3.0")

## 测试爆炸武器判断
func test_is_explosive_method() -> void:
	# 机枪不是爆炸武器
	weapon_controller.initialize(5)
	assert_false(weapon_controller.is_explosive(), "Machine gun should not be explosive")

	# 炮弹是爆炸武器
	weapon_controller.initialize(6)
	assert_true(weapon_controller.is_explosive(), "Cannon should be explosive")

## 测试获取爆炸半径
func test_get_explosion_radius() -> void:
	weapon_controller.initialize(6)
	var radius: float = weapon_controller.get_explosion_radius()
	assert_eq(radius, 3.0, "Cannon explosion radius should be 3.0")

# === 弹道爆炸测试 ===

## 测试弹道初始化带爆炸半径
func test_projectile_with_explosion_radius() -> void:
	projectile_entity.initialize(
		6,  # weapon_type_id (cannon)
		1,  # owner_id
		Vector2(0, 0),  # position
		Vector2.RIGHT,  # direction
		576.0,  # speed (18 cells/sec * 32)
		640.0,  # range (20 cells * 32)
		60.0,  # damage
		null,  # weapon_controller
		96.0   # explosion_radius (3 cells * 32)
	)

	assert_eq(projectile_entity.weapon_type_id, 6, "Projectile weapon_type_id should be 6")
	assert_eq(projectile_entity.explosion_radius, 96.0, "Projectile explosion radius should be 96 pixels")
	assert_true(projectile_entity.is_initialized, "Projectile should be initialized")

## 测试机枪弹道无爆炸半径
func test_machine_gun_projectile_no_explosion() -> void:
	projectile_entity.initialize(
		5,  # weapon_type_id (machine gun)
		1,  # owner_id
		Vector2(0, 0),  # position
		Vector2.RIGHT,  # direction
		1120.0,  # speed (35 cells/sec * 32)
		256.0,  # range (8 cells * 32)
		8.0,  # damage
		null,  # weapon_controller
		0.0   # explosion_radius (no explosion)
	)

	assert_eq(projectile_entity.explosion_radius, 0.0, "Machine gun projectile should have no explosion radius")

# === 射击频率测试 ===

## 测试机枪高频射击 cooldown
func test_machine_gun_high_fire_rate() -> void:
	weapon_controller.initialize(5)

	# 机枪 cooldown = 1/10 = 0.1 秒
	var cooldown_duration: float = weapon_controller.get_cooldown_duration()
	assert_almost_eq(cooldown_duration, 0.1, 0.01, "Machine gun cooldown should be 0.1 seconds")

## 测试炮弹慢速射击 cooldown
func test_cannon_slow_fire_rate() -> void:
	weapon_controller.initialize(6)

	# 炮弹 cooldown = 1/1.5 = 0.667 秒
	var cooldown_duration: float = weapon_controller.get_cooldown_duration()
	assert_almost_eq(cooldown_duration, 0.667, 0.05, "Cannon cooldown should be ~0.667 seconds")

# === 伤害计算测试 ===

## 测试机枪低单发伤害
func test_machine_gun_low_damage_per_shot() -> void:
	weapon_controller.initialize(5)

	var damage: float = weapon_controller.calculate_damage(0.0, 0.0)
	assert_eq(damage, 8.0, "Machine gun base damage should be 8.0")

## 测试炮弹高单发伤害
func test_cannon_high_damage_per_shot() -> void:
	weapon_controller.initialize(6)

	var damage: float = weapon_controller.calculate_damage(0.0, 0.0)
	assert_eq(damage, 60.0, "Cannon base damage should be 60.0")

## 测试炮弹护甲减伤
func test_cannon_damage_with_armor() -> void:
	weapon_controller.initialize(6)

	# 10%护甲减伤
	var damage_with_armor: float = weapon_controller.calculate_damage(10.0, 0.0)
	var expected: float = 60.0 * (1.0 - 0.10)  # 54.0
	assert_almost_eq(damage_with_armor, expected, 1.0, "Cannon damage should be reduced by armor")

# === 射程测试 ===

## 测试机枪短射程
func test_machine_gun_short_range() -> void:
	weapon_controller.initialize(5)
	assert_eq(weapon_controller.get_range(), 8.0, "Machine gun range should be 8 cells")

## 测试炮弹远射程
func test_cannon_long_range() -> void:
	weapon_controller.initialize(6)
	assert_eq(weapon_controller.get_range(), 20.0, "Cannon range should be 20 cells")

# === 魔能消耗测试 ===

## 测试机枪低魔能消耗
func test_machine_gun_low_magic_cost() -> void:
	weapon_controller.initialize(5)
	assert_eq(weapon_controller.get_magic_cost(), 2.0, "Machine gun magic cost should be 2.0")

## 测试炮弹中等魔能消耗
func test_cannon_medium_magic_cost() -> void:
	weapon_controller.initialize(6)
	assert_eq(weapon_controller.get_magic_cost(), 15.0, "Cannon magic cost should be 15.0")

# === 武器切换测试 ===

## 测试从基础炮切换到机枪
func test_weapon_switch_to_machine_gun() -> void:
	weapon_controller.initialize(1)  # 先初始化基础炮
	assert_eq(weapon_controller.weapon_type_id, 1, "Initial weapon should be basic cannon")

	weapon_controller.initialize(5)  # 切换到机枪
	assert_eq(weapon_controller.weapon_type_id, 5, "Weapon should be switched to machine gun")
	assert_eq(weapon_controller.fire_rate, 10.0, "Fire rate should update to 10.0")

## 测试从机枪切换到炮弹
func test_weapon_switch_to_cannon() -> void:
	weapon_controller.initialize(5)  # 机枪
	weapon_controller.initialize(6)  # 炮弹

	assert_eq(weapon_controller.explosion_radius, 3.0, "Explosion radius should update to 3.0")

# === 边界测试 ===

## 测试无效武器 ID 使用默认值
func test_invalid_weapon_id_defaults() -> void:
	weapon_controller.initialize(999)

	assert_eq(weapon_controller.base_damage, 20.0, "Invalid weapon ID should use default damage")
	assert_eq(weapon_controller.fire_rate, 2.0, "Invalid weapon ID should use default fire_rate")

## 测试爆炸半径零值
func test_zero_explosion_radius() -> void:
	projectile_entity.initialize(1, 1, Vector2.ZERO, Vector2.RIGHT, 640.0, 480.0, 20.0, null, 0.0)
	assert_eq(projectile_entity.explosion_radius, 0.0, "Zero explosion radius should be valid")

## 测试最大爆炸半径
func test_max_explosion_radius() -> void:
	projectile_entity.initialize(6, 1, Vector2.ZERO, Vector2.RIGHT, 576.0, 640.0, 60.0, null, 100.0)
	assert_eq(projectile_entity.explosion_radius, 100.0, "Large explosion radius should be valid")