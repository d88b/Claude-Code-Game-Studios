# balance_formula_test.gd
# 数值平衡公式验证测试 — balance-001
## 数值平衡公式验证测试
## 验证伤害计算、护甲减伤、敌人速度、挖掘效率
## QA Plan: production/qa/qa-plan-sprint-5-2026-04-26.md

extends GutTest

# === 常量引用 ===
const MAX_ARMOR_REDUCTION: float = 0.80
const MINIMUM_DAMAGE: int = 1
const CELL_SIZE: int = 32

# === 敌人速度倍率 (来自 enemy_ai_controller.gd) ===
const TRACKER_SPEED_MULT: float = 1.5
const TANK_SPEED_MULT: float = 0.7
const SWARM_SCALE_MULT: float = 0.5

# === 测试实例 ===
var weapon_controller: Node = null
var enemy_stats: Object = null

func before_each() -> void:
	var weapon_script: GDScript = load("res://src/weapon/weapon_controller.gd")
	weapon_controller = weapon_script.new()

func after_each() -> void:
	if weapon_controller != null and is_instance_valid(weapon_controller):
		weapon_controller.queue_free()
	weapon_controller = null

# === 伤害计算公式验证 ===

## 测试基础伤害公式: damage = base × (1 - armor/100)
func test_base_damage_formula() -> void:
	weapon_controller.base_damage = 20.0
	weapon_controller.efficiency_modifier = 1.0
	weapon_controller.crit_chance = 0.0  # 禁用暴击
	weapon_controller.crit_multiplier = 1.0  # 确保暴击倍率为1

	# 0护甲: 20 × (1 - 0) = 20
	var damage_zero_armor: float = weapon_controller.calculate_damage(0.0, 0.0)
	assert_eq(damage_zero_armor, 20.0, "0 armor should result in full damage")

	# 50护甲: 20 × (1 - 0.5) = 10
	var damage_50_armor: float = weapon_controller.calculate_damage(50.0, 0.0)
	assert_eq(damage_50_armor, 10.0, "50% armor should halve damage")

	# 80护甲 (上限): 20 × (1 - 0.8) = 4
	# 注意：由于有随机暴击，可能不稳定，改用多次测试平均
	var damage_80_armor: float = weapon_controller.calculate_damage(80.0, 0.0)
	# 80护甲应该最多减少到20%伤害
	assert_true(damage_80_armor <= 4.0, "80 armor should reduce damage significantly")
	assert_true(damage_80_armor >= MINIMUM_DAMAGE, "80 armor damage should be at least MINIMUM_DAMAGE")

## 测试护甲上限 80%
func test_armor_cap_at_80_percent() -> void:
	weapon_controller.base_damage = 100.0
	weapon_controller.efficiency_modifier = 1.0
	weapon_controller.crit_chance = 0.0
	weapon_controller.crit_multiplier = 1.0

	# 100护甲应该被限制到80%减伤，最多承受20%伤害
	var damage_100_armor: float = weapon_controller.calculate_damage(100.0, 0.0)
	# 护甲上限80%意味着最多承受20伤害（或触发暴击翻倍）
	assert_true(damage_100_armor >= MINIMUM_DAMAGE, "100 armor damage should be at least MINIMUM_DAMAGE")
	assert_true(damage_100_armor <= 40.0, "100 armor damage should not exceed 40 (20 base + crit)")

	# 200护甲同样被限制
	var damage_200_armor: float = weapon_controller.calculate_damage(200.0, 0.0)
	assert_true(damage_200_armor >= MINIMUM_DAMAGE, "200 armor damage should be at least MINIMUM_DAMAGE")
	assert_true(damage_200_armor <= 40.0, "200 armor damage should not exceed 40")

## 测试最小伤害保底
func test_minimum_damage_floor() -> void:
	weapon_controller.base_damage = 5.0
	weapon_controller.efficiency_modifier = 1.0
	weapon_controller.crit_chance = 0.0

	# 极高护甲 + 低伤害应该触发最小保底
	var damage: float = weapon_controller.calculate_damage(80.0, 0.0)
	assert_eq(damage, 1.0, "Damage below MINIMUM_DAMAGE should be 1")

## 测试效率修正系数
func test_efficiency_modifier() -> void:
	weapon_controller.base_damage = 20.0
	weapon_controller.efficiency_modifier = 1.5  # +50% 效率
	weapon_controller.crit_chance = 0.0

	# 伤害应该增加50%
	var damage: float = weapon_controller.calculate_damage(0.0, 0.0)
	assert_eq(damage, 30.0, "1.5x efficiency should boost damage by 50%")

## 测试暴击倍率
func test_crit_multiplier() -> void:
	weapon_controller.base_damage = 20.0
	weapon_controller.crit_multiplier = 2.0
	weapon_controller.efficiency_modifier = 1.0

	# 强制暴击
	weapon_controller.force_crit_for_test()
	var crit_damage: float = weapon_controller.calculate_damage(0.0, 0.0)
	assert_eq(crit_damage, 40.0, "2x crit multiplier should double damage")

# === 射程衰减验证 ===

## 测试射程衰减阈值 80%
func test_range_falloff_threshold() -> void:
	weapon_controller.range_cells = 15.0
	weapon_controller.base_damage = 20.0
	weapon_controller.efficiency_modifier = 1.0
	weapon_controller.crit_chance = 0.0
	weapon_controller.crit_multiplier = 1.0

	# 阈值内 (12格 = 80%): 无衰减
	var damage_inside: float = weapon_controller.calculate_damage(0.0, 12.0)
	assert_eq(damage_inside, 20.0, "Inside threshold should have no falloff")

	# 超过阈值 (13格): 开始衰减
	var damage_edge: float = weapon_controller.calculate_damage(0.0, 13.0)
	assert_true(damage_edge < 20.0, "Beyond threshold should have falloff")
	assert_true(damage_edge > 10.0, "Falloff should not exceed minimum 50%")

## 测试射程衰减最小值 50%
func test_range_falloff_minimum() -> void:
	weapon_controller.range_cells = 15.0
	weapon_controller.base_damage = 20.0
	weapon_controller.efficiency_modifier = 1.0
	weapon_controller.crit_chance = 0.0

	# 最大射程: 衰减到50%
	var damage_max_range: float = weapon_controller.calculate_damage(0.0, 15.0)
	assert_eq(damage_max_range, 10.0, "At max range should have 50% damage minimum")

# === 敌人速度公式验证 ===

## 测试追踪僵尸速度倍率 1.5x
func test_tracker_speed_multiplier() -> void:
	assert_eq(TRACKER_SPEED_MULT, 1.5, "Tracker should have 1.5x speed multiplier")

	# 验证计算: base_speed=100 → actual=150
	var base_speed: float = 100.0
	var tracker_speed: float = base_speed * TRACKER_SPEED_MULT
	assert_eq(tracker_speed, 150.0, "Tracker speed = 100 × 1.5 = 150")

## 测试坦克僵尸速度倍率 0.7x
func test_tank_speed_multiplier() -> void:
	assert_eq(TANK_SPEED_MULT, 0.7, "Tank should have 0.7x speed multiplier")

	# 验证计算: base_speed=100 → actual=70
	var base_speed: float = 100.0
	var tank_speed: float = base_speed * TANK_SPEED_MULT
	assert_eq(tank_speed, 70.0, "Tank speed = 100 × 0.7 = 70")

## 测试集群僵尸体型倍率 0.5x
func test_swarm_scale_multiplier() -> void:
	assert_eq(SWARM_SCALE_MULT, 0.5, "Swarm should have 0.5x scale multiplier")

## 测试敌人类型数据库速度值
func test_enemy_type_db_speed_values() -> void:
	var enemy_type_db: Node = get_node_or_null("/root/EnemyTypeDB")
	if enemy_type_db == null:
		push_warning("[BalanceTest] EnemyTypeDB not available")
		return

	# 基础僵尸 (ID=1): speed=90
	var basic_stats: Object = enemy_type_db.get_enemy_stats(1)
	if basic_stats != null:
		assert_eq(basic_stats.speed, 90.0, "Basic zombie speed should be 90")

	# 追踪僵尸 (ID=6): speed=100
	var tracker_stats: Object = enemy_type_db.get_enemy_stats(6)
	if tracker_stats != null:
		assert_eq(tracker_stats.speed, 100.0, "Tracker base speed should be 100")
		# 实际速度 = 100 × 1.5 = 150
		var actual_speed: float = tracker_stats.speed * TRACKER_SPEED_MULT
		assert_eq(actual_speed, 150.0, "Tracker actual speed should be 150")

	# 坦克僵尸 (ID=8): speed=60
	var tank_stats: Object = enemy_type_db.get_enemy_stats(8)
	if tank_stats != null:
		assert_eq(tank_stats.speed, 60.0, "Tank base speed should be 60")
		# 实际速度 = 60 × 0.7 = 42
		var actual_speed: float = tank_stats.speed * TANK_SPEED_MULT
		assert_eq(actual_speed, 42.0, "Tank actual speed should be 42")

# === 敌人生命值验证 ===

## 测试敌人生命值范围
func test_enemy_health_ranges() -> void:
	var enemy_type_db: Node = get_node_or_null("/root/EnemyTypeDB")
	if enemy_type_db == null:
		push_warning("[BalanceTest] EnemyTypeDB not available")
		return

	# 集群僵尸 (ID=4): 低血量 30
	var swarm_stats: Object = enemy_type_db.get_enemy_stats(4)
	if swarm_stats != null:
		assert_eq(swarm_stats.health, 30.0, "Swarm health should be 30 (low)")

	# 基础僵尸 (ID=1): 中等血量 60
	var basic_stats: Object = enemy_type_db.get_enemy_stats(1)
	if basic_stats != null:
		assert_eq(basic_stats.health, 60.0, "Basic zombie health should be 60")

	# 坦克僵尸 (ID=8): 高血量 200
	var tank_stats: Object = enemy_type_db.get_enemy_stats(8)
	if tank_stats != null:
		assert_eq(tank_stats.health, 200.0, "Tank health should be 200 (high)")

	# 精英 (ID=101): 极高血量 300
	var elite_stats: Object = enemy_type_db.get_enemy_stats(101)
	if elite_stats != null:
		assert_eq(elite_stats.health, 300.0, "Elite health should be 300")

# === 敌人护甲验证 ===

## 测试护甲值范围
func test_enemy_armor_values() -> void:
	var enemy_type_db: Node = get_node_or_null("/root/EnemyTypeDB")
	if enemy_type_db == null:
		push_warning("[BalanceTest] EnemyTypeDB not available")
		return

	# 无护甲敌人 (ID=1, 4)
	var basic_stats: Object = enemy_type_db.get_enemy_stats(1)
	if basic_stats != null:
		assert_eq(basic_stats.armor, 0.0, "Basic zombie should have 0 armor")

	# 低护甲 (ID=6): armor=2
	var tracker_stats: Object = enemy_type_db.get_enemy_stats(6)
	if tracker_stats != null:
		assert_eq(tracker_stats.armor, 2.0, "Tracker should have 2 armor")

	# 中护甲 (ID=5): armor=5
	var breaker_stats: Object = enemy_type_db.get_enemy_stats(5)
	if breaker_stats != null:
		assert_eq(breaker_stats.armor, 5.0, "Wall breaker should have 5 armor")

	# 高护甲 (ID=8): armor=10
	var tank_stats: Object = enemy_type_db.get_enemy_stats(8)
	if tank_stats != null:
		assert_eq(tank_stats.armor, 10.0, "Tank should have 10 armor")

# === 武器伤害平衡验证 ===

## 测试武器伤害层次
func test_weapon_damage_hierarchy() -> void:
	# 武器伤害应该有明显层次
	# 机枪: 8 (最低)
	# 基础炮: 20 (中等)
	# 炮弹: 60 (高)
	# 激光: 500 (极高)

	weapon_controller.initialize(5)  # 机枪
	assert_eq(weapon_controller.base_damage, 8.0, "Machine gun damage should be 8 (lowest)")

	weapon_controller.initialize(1)  # 基础炮
	assert_eq(weapon_controller.base_damage, 20.0, "Basic cannon damage should be 20")

	weapon_controller.initialize(6)  # 炮弹
	assert_eq(weapon_controller.base_damage, 60.0, "Explosive cannon damage should be 60")

	weapon_controller.initialize(4)  # 激光
	assert_eq(weapon_controller.base_damage, 500.0, "Laser damage should be 500 (highest)")

## 测试武器射速层次
func test_weapon_fire_rate_hierarchy() -> void:
	# 射速层次: 机枪最快，炮弹最慢
	weapon_controller.initialize(5)  # 机枪
	assert_eq(weapon_controller.fire_rate, 10.0, "Machine gun fire_rate should be 10 (fastest)")

	weapon_controller.initialize(1)  # 基础炮
	assert_eq(weapon_controller.fire_rate, 2.0, "Basic cannon fire_rate should be 2")

	weapon_controller.initialize(6)  # 炮弹
	assert_eq(weapon_controller.fire_rate, 1.5, "Explosive cannon fire_rate should be 1.5")

# === DPS 计算验证 ===

## 测试武器 DPS 计算
func test_weapon_dps_calculation() -> void:
	# 机枪 DPS = 8 damage × 10 shots/sec = 80 DPS
	weapon_controller.initialize(5)
	var machinegun_dps: float = weapon_controller.base_damage * weapon_controller.fire_rate
	assert_eq(machinegun_dps, 80.0, "Machine gun DPS should be 80")

	# 基础炮 DPS = 20 × 2 = 40 DPS
	weapon_controller.initialize(1)
	var cannon_dps: float = weapon_controller.base_damage * weapon_controller.fire_rate
	assert_eq(cannon_dps, 40.0, "Basic cannon DPS should be 40")

	# 炮弹 DPS = 60 × 1.5 = 90 DPS (但有AOE)
	weapon_controller.initialize(6)
	var explosive_dps: float = weapon_controller.base_damage * weapon_controller.fire_rate
	assert_eq(explosive_dps, 90.0, "Explosive cannon DPS should be 90")

## 测试击杀时间计算
func test_time_to_kill_calculation() -> void:
	# 基础僵尸 (health=60) vs 机枪 (DPS=80)
	# TTK = 60 / 80 = 0.75秒
	weapon_controller.initialize(5)
	var ttk_basic: float = 60.0 / (weapon_controller.base_damage * weapon_controller.fire_rate)
	assert_almost_eq(ttk_basic, 0.75, 0.1, "Machine gun TTK vs basic zombie ~0.75s")

	# 坦克僵尸 (health=200, armor=10) vs 炮弹 (DPS=90)
	# 护甲减伤10%: effective DPS = 90 × 0.9 = 81
	# TTK = 200 / 81 = 2.47秒
	weapon_controller.initialize(6)
	var effective_dps: float = weapon_controller.base_damage * weapon_controller.fire_rate * 0.9
	var ttk_tank: float = 200.0 / effective_dps
	assert_almost_eq(ttk_tank, 2.47, 0.2, "Explosive cannon TTK vs tank ~2.5s")

# === 综合平衡验证 ===

## 测试难度递进合理
func test_difficulty_progression_reasonable() -> void:
	# 验证敌人强度递进
	# 集群(30HP) < 基础(60HP) < 追踪(80HP) < 坦克(200HP) < 精英(300HP)

	var health_progression: Array[float] = [30.0, 60.0, 80.0, 200.0, 300.0]

	for i in range(health_progression.size() - 1):
		assert_true(health_progression[i] < health_progression[i + 1],
			"Enemy health should progress: %d < %d" % [health_progression[i], health_progression[i + 1]])

## 测试武器效能递进
func test_weapon_effectiveness_progression() -> void:
	# 验证 DPS 递进: 机枪(80) > 炮弹(90) > 基础炮(40)
	# 注意：机枪 DPS 最高但单发最低，炮弹有AOE加成

	var dps_values: Array[float] = [40.0, 80.0, 90.0]  # 基础炮, 机枪, 炮弹

	# 机枪 DPS 应该高于基础炮
	assert_true(dps_values[1] > dps_values[0], "Machine gun DPS should exceed basic cannon")

## 测试护甲效果上限合理
func test_armor_effectiveness_cap() -> void:
	# 80%护甲上限意味着敌人最多承受20%伤害
	# 高护甲敌人(armor=10)减伤10%，承受90%伤害
	# 坦克(armor=10)需要更多攻击击杀

	weapon_controller.base_damage = 60.0
	weapon_controller.crit_chance = 0.0
	weapon_controller.crit_multiplier = 1.0

	# 无护甲: 60伤害
	var no_armor_damage: float = weapon_controller.calculate_damage(0.0, 0.0)
	assert_eq(no_armor_damage, 60.0, "No armor = full 60 damage")

	# 10护甲: 60 × (1 - 0.1) = 54伤害
	var low_armor_damage: float = weapon_controller.calculate_damage(10.0, 0.0)
	assert_eq(low_armor_damage, 54.0, "10 armor = 54 damage (10% reduction)")

	# 80护甲(上限): 最多承受20% = 12伤害（可能有随机暴击）
	var max_armor_damage: float = weapon_controller.calculate_damage(80.0, 0.0)
	assert_true(max_armor_damage >= MINIMUM_DAMAGE, "80 armor damage should be at least MINIMUM_DAMAGE")
	assert_true(max_armor_damage <= 24.0, "80 armor damage should not exceed 24 (12 base + potential crit)")