# weapon_controller_test.gd
# Unit tests for Story: Weapon Firing System
# tests/unit/weapon/weapon_controller_test.gd

extends GutTest

const WeaponControllerScript := preload("res://src/weapon/weapon_controller.gd")
const VehicleAttributeScript := preload("res://src/core/vehicle_attribute.gd")

var _weapon: Object
var _vehicle_attr: Object

# === Setup ===

func before_each() -> void:
	# 创建 VehicleAttribute
	_vehicle_attr = VehicleAttributeScript.new()
	add_child_autoqfree(_vehicle_attr)
	_vehicle_attr.set_dependencies(VehicleTypeDB, GlobalSignals)
	_vehicle_attr.initialize(1)

	# 创建 WeaponController
	_weapon = WeaponControllerScript.new()
	add_child_autoqfree(_weapon)
	_weapon.set_dependencies(_vehicle_attr, GlobalSignals)
	_weapon.initialize(1)

# === 常量验证 ===

func test_minimum_damage_is_1() -> void:
	assert_eq(_weapon.MINIMUM_DAMAGE, 1, "MINIMUM_DAMAGE should be 1")

func test_max_armor_reduction_is_80_percent() -> void:
	assert_eq(_weapon.MAX_ARMOR_REDUCTION, 0.80, "MAX_ARMOR_REDUCTION should be 0.80")

func test_range_falloff_threshold_is_80_percent() -> void:
	assert_eq(_weapon.RANGE_FALLOFF_THRESHOLD, 0.80, "RANGE_FALLOFF_THRESHOLD should be 0.80")

func test_min_range_falloff_is_50_percent() -> void:
	assert_eq(_weapon.MIN_RANGE_FALLOFF, 0.50, "MIN_RANGE_FALLOFF should be 0.50")

func test_weapon_switch_cooldown_is_0_5_seconds() -> void:
	assert_eq(_weapon.WEAPON_SWITCH_COOLDOWN, 0.5, "WEAPON_SWITCH_COOLDOWN should be 0.5")

func test_aim_deadzone_is_0_15() -> void:
	assert_eq(_weapon.AIM_DEADZONE, 0.15, "AIM_DEADZONE should be 0.15")

# === 初始化测试 ===

func test_initialize_basic_weapon() -> void:
	# Arrange
	_weapon.initialize(1)

	# Assert
	assert_eq(_weapon.weapon_type_id, 1, "weapon_type_id should be 1")
	assert_eq(_weapon.base_damage, 20.0, "basic weapon damage should be 20")
	assert_eq(_weapon.fire_rate, 2.0, "basic weapon fire_rate should be 2.0")
	assert_eq(_weapon.magic_cost_per_shot, 10.0, "basic weapon magic_cost should be 10")

func test_initialize_fast_weapon() -> void:
	# Arrange
	_weapon.initialize(2)

	# Assert
	assert_eq(_weapon.weapon_type_id, 2, "weapon_type_id should be 2")
	assert_eq(_weapon.base_damage, 10.0, "fast weapon damage should be 10")
	assert_eq(_weapon.fire_rate, 5.0, "fast weapon fire_rate should be 5.0")
	assert_eq(_weapon.magic_cost_per_shot, 5.0, "fast weapon magic_cost should be 5")

func test_initialize_launcher_weapon() -> void:
	# Arrange
	_weapon.initialize(3)

	# Assert
	assert_eq(_weapon.weapon_type_id, 3, "weapon_type_id should be 3")
	assert_eq(_weapon.base_damage, 40.0, "launcher damage should be 40")
	assert_eq(_weapon.fire_rate, 1.0, "launcher fire_rate should be 1.0")
	assert_eq(_weapon.magic_cost_per_shot, 20.0, "launcher magic_cost should be 20")

func test_initialize_unknown_weapon_uses_defaults() -> void:
	# Arrange
	_weapon.initialize(999)

	# Assert — should use default values, no crash
	assert_eq(_weapon.weapon_type_id, 999, "weapon_type_id should be 999")

# === Cooldown 测试 ===

func test_cooldown_duration_formula() -> void:
	# Arrange
	_weapon.initialize(1)  # fire_rate = 2.0

	# Act
	var duration: float = _weapon.get_cooldown_duration()

	# Assert — cooldown = 1/fire_rate = 1/2 = 0.5 seconds
	assert_eq(duration, 0.5, "cooldown duration should be 0.5 seconds for fire_rate=2.0")

func test_cooldown_duration_slow_weapon() -> void:
	# Arrange
	_weapon.initialize(3)  # fire_rate = 1.0

	# Act
	var duration: float = _weapon.get_cooldown_duration()

	# Assert — cooldown = 1/1 = 1.0 seconds
	assert_eq(duration, 1.0, "cooldown duration should be 1.0 seconds for fire_rate=1.0")

func test_cooldown_duration_fast_weapon() -> void:
	# Arrange
	_weapon.initialize(2)  # fire_rate = 5.0

	# Act
	var duration: float = _weapon.get_cooldown_duration()

	# Assert — cooldown = 1/5 = 0.2 seconds
	assert_eq(duration, 0.2, "cooldown duration should be 0.2 seconds for fire_rate=5.0")

func test_cooldown_zero_initially() -> void:
	# Arrange
	_weapon.initialize(1)

	# Assert
	assert_eq(_weapon.cooldown_timer, 0.0, "cooldown_timer should start at 0")
	assert_true(_weapon.is_ready_to_fire, "is_ready_to_fire should start true")

func test_cooldown_decreases_per_frame() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.set_cooldown_for_test(0.5)

	# Act
	_weapon._process(0.3)  # Advance 0.3 seconds

	# Assert
	assert_almost_eq(_weapon.cooldown_timer, 0.2, 0.01, "cooldown should decrease by delta")

func test_cooldown_reaches_zero() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.set_cooldown_for_test(0.3)

	# Act
	_weapon._process(0.5)  # Advance more than cooldown

	# Assert
	assert_eq(_weapon.cooldown_timer, 0.0, "cooldown should be clamped to 0")
	assert_true(_weapon.is_ready_to_fire, "is_ready_to_fire should become true")

# === 射击测试 ===

func test_try_fire_success() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.set_position(Vector2(100, 100))
	_weapon.set_aim_direction(Vector2(1, 0))

	# Act
	var success: bool = _weapon.try_fire()

	# Assert
	assert_true(success, "try_fire should succeed")
	assert_eq(_weapon.cooldown_timer, 0.5, "cooldown should be set after fire")
	assert_false(_weapon.is_ready_to_fire, "is_ready_to_fire should be false after fire")

func test_try_fire_fails_when_cooldown_active() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.set_cooldown_for_test(0.3)

	# Act
	var success: bool = _weapon.try_fire()

	# Assert
	assert_false(success, "try_fire should fail when cooldown active")

func test_try_fire_fails_when_magic_insufficient() -> void:
	# Arrange
	_weapon.initialize(1)
	_vehicle_attr.set_magic_for_test(5.0)  # Only 5 magic, need 10

	# Act
	var success: bool = _weapon.try_fire()

	# Assert
	assert_false(success, "try_fire should fail when magic insufficient")
	assert_eq(_vehicle_attr.current_magic, 5.0, "magic should not change on failed fire")

func test_try_fire_consumes_magic() -> void:
	# Arrange
	_weapon.initialize(1)  # magic_cost = 10
	var initial_magic: float = _vehicle_attr.current_magic

	# Act
	_weapon.try_fire()

	# Assert
	assert_eq(_vehicle_attr.current_magic, initial_magic - 10.0, "magic should be consumed")

func test_try_fire_zero_magic_rejected() -> void:
	# Arrange
	_weapon.initialize(1)
	_vehicle_attr.set_magic_for_test(0.0)

	# Act
	var success: bool = _weapon.try_fire()

	# Assert
	assert_false(success, "try_fire should fail when magic is 0")

# === 伤害计算测试 ===

func test_calculate_damage_no_armor() -> void:
	# Arrange
	_weapon.initialize(1)  # base_damage = 20
	_weapon.efficiency_modifier = 1.0
	_weapon.disable_crit_for_test()  # crit_factor = 1.0

	# Act
	var damage: float = _weapon.calculate_damage(0.0, 0.0)  # No armor, close range

	# Assert — 20 * 1.0 * 1.0 * 1.0 * 1.0 = 20
	assert_eq(damage, 20.0, "damage should be 20 with no armor")

func test_calculate_damage_with_armor() -> void:
	# Arrange
	_weapon.initialize(1)  # base_damage = 20
	_weapon.disable_crit_for_test()

	# Act — 30% armor reduction
	var damage: float = _weapon.calculate_damage(30.0, 0.0)

	# Assert — 20 * 1.0 * 1.0 * 0.70 = 14
	assert_eq(damage, 14.0, "damage should be 14 with 30% armor")

func test_calculate_damage_max_armor() -> void:
	# Arrange
	_weapon.initialize(1)  # base_damage = 20
	_weapon.disable_crit_for_test()

	# Act — 80% armor reduction (max)
	var damage: float = _weapon.calculate_damage(80.0, 0.0)

	# Assert — 20 * 0.20 = 4
	assert_eq(damage, 4.0, "damage should be 4 with max 80% armor")

func test_calculate_damage_armor_exceeds_cap() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.disable_crit_for_test()

	# Act — 95% armor, should clamp to 80%
	var damage: float = _weapon.calculate_damage(95.0, 0.0)

	# Assert — should clamp to 80% reduction
	assert_eq(damage, 4.0, "armor > 80% should clamp to 80% reduction")

func test_calculate_damage_minimum_floor() -> void:
	# Arrange
	_weapon.initialize(2)  # base_damage = 10
	_weapon.disable_crit_for_test()

	# Act — 80% armor on low damage weapon
	var damage: float = _weapon.calculate_damage(80.0, 0.0)

	# Assert — 10 * 0.20 = 2, above minimum
	assert_eq(damage, 2.0, "damage should be 2, above minimum floor")

func test_calculate_damage_minimum_floor_applied() -> void:
	# Arrange
	_weapon.set_magic_cost_for_test(5.0)  # Just to have valid weapon
	_weapon.base_damage = 5.0  # Set directly for edge case
	_weapon.disable_crit_for_test()

	# Act — 80% armor, would be 1 damage (5 * 0.20 = 1)
	var damage: float = _weapon.calculate_damage(80.0, 0.0)

	# Assert — minimum floor = 1
	assert_eq(damage, 1.0, "minimum damage floor should be applied")

# === 暴击测试 ===

func test_crit_roll_succeeds_when_below_chance() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.set_crit_chance_for_test(1.0)  # 100% crit for test

	# Act
	var crit_factor: float = _weapon._roll_crit()

	# Assert
	assert_eq(crit_factor, 2.0, "crit_factor should be 2.0 when crit succeeds")

func test_crit_roll_fails_when_above_chance() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.set_crit_chance_for_test(0.0)  # 0% crit

	# Act
	var crit_factor: float = _weapon._roll_crit()

	# Assert
	assert_eq(crit_factor, 1.0, "crit_factor should be 1.0 when crit fails")

func test_calculate_damage_with_crit() -> void:
	# Arrange
	_weapon.initialize(1)  # base_damage = 20, crit_multiplier = 2.0
	_weapon.force_crit_for_test()

	# Act
	var damage: float = _weapon.calculate_damage(0.0, 0.0)

	# Assert — 20 * 2.0 = 40 (crit)
	assert_eq(damage, 40.0, "damage should be doubled with crit")

func test_calculate_damage_with_crit_and_armor() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.force_crit_for_test()

	# Act — 30% armor + crit
	var damage: float = _weapon.calculate_damage(30.0, 0.0)

	# Assert — 20 * 2.0 * 0.70 = 28
	assert_eq(damage, 28.0, "crit damage should be reduced by armor")

# === 射程衰减测试 ===

func test_range_falloff_within_threshold() -> void:
	# Arrange
	_weapon.initialize(1)  # range = 15, threshold = 12

	# Act — distance = 10 (within 80% threshold)
	var falloff: float = _weapon._calculate_range_falloff(10.0)

	# Assert
	assert_eq(falloff, 1.0, "no falloff within threshold")

func test_range_falloff_at_threshold() -> void:
	# Arrange
	_weapon.initialize(1)  # range = 15, threshold = 12

	# Act — distance = 12 (at threshold)
	var falloff: float = _weapon._calculate_range_falloff(12.0)

	# Assert
	assert_eq(falloff, 1.0, "no falloff at threshold boundary")

func test_range_falloff_at_max_range() -> void:
	# Arrange
	_weapon.initialize(1)  # range = 15

	# Act — distance = 15 (at max range)
	var falloff: float = _weapon._calculate_range_falloff(15.0)

	# Assert — should be minimum 0.5
	assert_eq(falloff, 0.5, "falloff should be minimum 0.5 at max range")

func test_range_falloff_beyond_range() -> void:
	# Arrange
	_weapon.initialize(1)  # range = 15

	# Act — distance = 20 (beyond range)
	var falloff: float = _weapon._calculate_range_falloff(20.0)

	# Assert — should clamp to minimum 0.5
	assert_eq(falloff, 0.5, "falloff should clamp to minimum beyond range")

func test_range_falloff_partial() -> void:
	# Arrange
	_weapon.initialize(1)  # range = 15, threshold = 12

	# Act — distance = 13.5 (halfway between threshold and max)
	var falloff: float = _weapon._calculate_range_falloff(13.5)

	# Assert — falloff = 1.0 - (1.5/3) * 0.5 = 1.0 - 0.25 = 0.75
	assert_eq(falloff, 0.75, "partial falloff should be 0.75")

func test_calculate_damage_with_range_falloff() -> void:
	# Arrange
	_weapon.initialize(1)  # base_damage = 20, range = 15
	_weapon.disable_crit_for_test()

	# Act — distance = 15 (max range, 50% falloff)
	var damage: float = _weapon.calculate_damage(0.0, 15.0)

	# Assert — 20 * 0.5 = 10
	assert_eq(damage, 10.0, "damage should be reduced by range falloff")

# === GlobalSignals 测试 ===

func test_try_fire_emits_turret_fired() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.vehicle_id = 1
	_weapon.set_position(Vector2(100, 100))
	_weapon.set_aim_direction(Vector2(1, 0))

	var signal_emitted: bool = false
	var turret_id: int = -1
	var pos: Vector2 = Vector2.ZERO
	var dir: Vector2 = Vector2.ZERO
	GlobalSignals.turret_fired.connect(func(p_turret_id: int, p_pos: Vector2, p_dir: Vector2):
		signal_emitted = true
		turret_id = p_turret_id
		pos = p_pos
		dir = p_dir
	)

	# Act
	_weapon.try_fire()

	# Assert
	assert_true(signal_emitted, "turret_fired should emit")
	assert_eq(turret_id, 1, "turret_id should match vehicle_id")
	assert_eq(pos, Vector2(100, 100), "position should match")
	assert_eq(dir, Vector2(1, 0), "direction should match")

func test_try_fire_emits_weapon_fired() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.set_position(Vector2(50, 50))

	var signal_emitted: bool = false
	var weapon_id: int = -1
	GlobalSignals.weapon_fired.connect(func(p_weapon_id: int, _p_pos: Vector2):
		signal_emitted = true
		weapon_id = p_weapon_id
	)

	# Act
	_weapon.try_fire()

	# Assert
	assert_true(signal_emitted, "weapon_fired should emit")
	assert_eq(weapon_id, 1, "weapon_id should match")

func test_on_hit_target_emits_turret_hit() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.disable_crit_for_test()

	var signal_emitted: bool = false
	var turret_id: int = -1
	var target_id: int = -1
	var damage: float = 0.0
	GlobalSignals.turret_hit.connect(func(p_turret_id: int, p_target_id: int, p_damage: float):
		signal_emitted = true
		turret_id = p_turret_id
		target_id = p_target_id
		damage = p_damage
	)

	# Act
	_weapon.on_hit_target(5, 30.0, 0.0)  # target_id=5, armor=30

	# Assert
	assert_true(signal_emitted, "turret_hit should emit")
	assert_eq(turret_id, 1, "turret_id should match vehicle_id")
	assert_eq(target_id, 5, "target_id should match")
	assert_eq(damage, 14.0, "damage should be calculated correctly")

# === 局部信号测试 ===

func test_weapon_fired_local_signal_emitted() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.set_position(Vector2(100, 100))

	var signal_emitted: bool = false
	_weapon.weapon_fired_local.connect(func(_p_weapon_id: int, _p_pos: Vector2, _p_dir: Vector2):
		signal_emitted = true
	)

	# Act
	_weapon.try_fire()

	# Assert
	assert_true(signal_emitted, "weapon_fired_local should emit")

func test_magic_insufficient_signal_emitted() -> void:
	# Arrange
	_weapon.initialize(1)
	_vehicle_attr.set_magic_for_test(5.0)

	var signal_emitted: bool = false
	var required: float = 0.0
	_weapon.magic_insufficient.connect(func(p_required: float):
		signal_emitted = true
		required = p_required
	)

	# Act
	_weapon.try_fire()

	# Assert
	assert_true(signal_emitted, "magic_insufficient should emit")
	assert_eq(required, 10.0, "required cost should match")

# === 辅助接口测试 ===

func test_can_fire_true_initially() -> void:
	# Arrange
	_weapon.initialize(1)

	# Assert
	assert_true(_weapon.can_fire(), "can_fire should be true initially")

func test_can_fire_false_when_cooldown() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.set_cooldown_for_test(0.3)

	# Assert
	assert_false(_weapon.can_fire(), "can_fire should be false during cooldown")

func test_can_fire_false_when_magic_low() -> void:
	# Arrange
	_weapon.initialize(1)
	_vehicle_attr.set_magic_for_test(5.0)

	# Assert
	assert_false(_weapon.can_fire(), "can_fire should be false when magic low")

func test_get_magic_cost() -> void:
	# Arrange
	_weapon.initialize(1)

	# Assert
	assert_eq(_weapon.get_magic_cost(), 10.0, "get_magic_cost should return 10")

func test_get_range() -> void:
	# Arrange
	_weapon.initialize(1)

	# Assert
	assert_eq(_weapon.get_range(), 15.0, "get_range should return 15")

func test_get_base_damage() -> void:
	# Arrange
	_weapon.initialize(1)

	# Assert
	assert_eq(_weapon.get_base_damage(), 20.0, "get_base_damage should return 20")

func test_get_cooldown_remaining() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.set_cooldown_for_test(0.4)

	# Assert
	assert_eq(_weapon.get_cooldown_remaining(), 0.4, "get_cooldown_remaining should return current cooldown")

# === 瞄准方向测试 ===

func test_set_aim_direction_normalizes() -> void:
	# Arrange
	_weapon.set_aim_direction(Vector2(3, 0))

	# Assert
	assert_eq(_weapon.aim_direction, Vector2(1, 0), "aim_direction should be normalized")

func test_set_aim_direction_deadzone_rejected() -> void:
	# Arrange
	_weapon.set_aim_direction(Vector2(1, 0))  # Set initial
	_weapon.set_aim_direction(Vector2(0.1, 0))  # Below deadzone

	# Assert
	assert_eq(_weapon.aim_direction, Vector2(1, 0), "aim_direction should not change below deadzone")

func test_set_aim_direction_zero_rejected() -> void:
	# Arrange
	_weapon.set_aim_direction(Vector2(1, 0))
	_weapon.set_aim_direction(Vector2.ZERO)

	# Assert
	assert_eq(_weapon.aim_direction, Vector2(1, 0), "aim_direction should not change for zero input")

# === 边界测试 ===

func test_damage_formula_integration() -> void:
	# Arrange
	_weapon.initialize(1)  # base_damage=20, range=15
	_weapon.force_crit_for_test()  # crit_factor=2.0

	# Act — armor=30, distance=13.5 (partial falloff=0.75)
	var damage: float = _weapon.calculate_damage(30.0, 13.5)

	# Expected: 20 * 1.0 * 2.0 * 0.70 * 0.75 = 20 * 2.0 * 0.525 = 21.0
	assert_eq(damage, 21.0, "full damage formula integration should produce 21")

func test_efficiency_modifier_applied() -> void:
	# Arrange
	_weapon.initialize(1)
	_weapon.efficiency_modifier = 1.5  # Modification bonus
	_weapon.disable_crit_for_test()

	# Act
	var damage: float = _weapon.calculate_damage(0.0, 0.0)

	# Assert — 20 * 1.5 = 30
	assert_eq(damage, 30.0, "efficiency_modifier should boost damage")

# === 依赖注入测试 ===

func test_set_dependencies_method_exists() -> void:
	assert_true(_weapon.has_method("set_dependencies"), "set_dependencies should exist")

func test_initialize_method_exists() -> void:
	assert_true(_weapon.has_method("initialize"), "initialize should exist")

# === 信号存在性测试 ===

func test_weapon_fired_local_signal_exists() -> void:
	assert_true(_weapon.has_signal("weapon_fired_local"), "weapon_fired_local signal should exist")

func test_weapon_hit_local_signal_exists() -> void:
	assert_true(_weapon.has_signal("weapon_hit_local"), "weapon_hit_local signal should exist")

func test_magic_insufficient_signal_exists() -> void:
	assert_true(_weapon.has_signal("magic_insufficient"), "magic_insufficient signal should exist")

func test_global_turret_fired_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("turret_fired"), "GlobalSignals.turret_fired should exist")

func test_global_turret_hit_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("turret_hit"), "GlobalSignals.turret_hit should exist")

# === 测试辅助方法测试 ===

func test_set_cooldown_for_test_method_exists() -> void:
	assert_true(_weapon.has_method("set_cooldown_for_test"), "set_cooldown_for_test should exist")

func test_set_magic_cost_for_test_method_exists() -> void:
	assert_true(_weapon.has_method("set_magic_cost_for_test"), "set_magic_cost_for_test should exist")

func test_set_crit_chance_for_test_method_exists() -> void:
	assert_true(_weapon.has_method("set_crit_chance_for_test"), "set_crit_chance_for_test should exist")

func test_force_crit_for_test_method_exists() -> void:
	assert_true(_weapon.has_method("force_crit_for_test"), "force_crit_for_test should exist")

func test_disable_crit_for_test_method_exists() -> void:
	assert_true(_weapon.has_method("disable_crit_for_test"), "disable_crit_for_test should exist")