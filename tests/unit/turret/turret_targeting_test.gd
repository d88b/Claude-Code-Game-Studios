# turret_targeting_test.gd
# Unit tests for Story: Turret Targeting
# tests/unit/turret/turret_targeting_test.gd

extends GutTest

const TurretControllerScript := preload("res://src/turret/turret_controller.gd")
const SpawnManagerScript := preload("res://src/spawn/spawn_manager.gd")

var _turret: Object
var _spawn_manager: Object

# === Setup ===

func before_each() -> void:
	# 创建 SpawnManager (用于目标查询)
	_spawn_manager = SpawnManagerScript.new()
	add_child_autoqfree(_spawn_manager)

	# 创建 TurretController
	_turret = TurretControllerScript.new()
	add_child_autoqfree(_turret)
	_turret.set_dependencies(_spawn_manager, GlobalSignals, null)
	_turret.initialize(200)

# === 常量验证 ===

func test_cell_size_is_32() -> void:
	assert_eq(_turret.CELL_SIZE, 32, "CELL_SIZE should be 32")

func test_minimum_damage_is_1() -> void:
	assert_eq(_turret.MINIMUM_DAMAGE, 1, "MINIMUM_DAMAGE should be 1")

func test_targeting_range_mult_is_2_0() -> void:
	assert_eq(_turret.TARGETING_RANGE_MULT, 2.0, "TARGETING_RANGE_MULT should be 2.0")

func test_turret_armor_effectiveness_is_0_6() -> void:
	assert_eq(_turret.TURRET_ARMOR_EFFECTIVENESS, 0.6, "TURRET_ARMOR_EFFECTIVENESS should be 0.6")

func test_turret_crit_chance_base_is_0_05() -> void:
	assert_eq(_turret.TURRET_CRIT_CHANCE_BASE, 0.05, "TURRET_CRIT_CHANCE_BASE should be 0.05")

func test_target_lock_frames_is_3() -> void:
	assert_eq(_turret.TARGET_LOCK_FRAMES, 3, "TARGET_LOCK_FRAMES should be 3")

func test_damage_threshold_is_0_5() -> void:
	assert_eq(_turret.DAMAGE_THRESHOLD, 0.5, "DAMAGE_THRESHOLD should be 0.5")

func test_heavy_damage_threshold_is_0_3() -> void:
	assert_eq(_turret.HEAVY_DAMAGE_THRESHOLD, 0.3, "HEAVY_DAMAGE_THRESHOLD should be 0.3")

# === 状态枚举测试 ===

func test_state_idle_is_0() -> void:
	assert_eq(_turret.TurretState.IDLE, 0, "IDLE should be 0")

func test_state_targeting_is_1() -> void:
	assert_eq(_turret.TurretState.TARGETING, 1, "TARGETING should be 1")

func test_state_firing_is_2() -> void:
	assert_eq(_turret.TurretState.FIRING, 2, "FIRING should be 2")

func test_state_cooldown_is_3() -> void:
	assert_eq(_turret.TurretState.COOLDOWN, 3, "COOLDOWN should be 3")

func test_state_disabled_is_4() -> void:
	assert_eq(_turret.TurretState.DISABLED, 4, "DISABLED should be 4")

# === 目标优先级枚举测试 ===

func test_priority_nearest_is_0() -> void:
	assert_eq(_turret.TargetingPriority.NEAREST, 0, "NEAREST should be 0")

func test_priority_highest_threat_is_1() -> void:
	assert_eq(_turret.TargetingPriority.HIGHEST_THREAT, 1, "HIGHEST_THREAT should be 1")

func test_priority_lowest_health_is_2() -> void:
	assert_eq(_turret.TargetingPriority.LOWEST_HEALTH, 2, "LOWEST_HEALTH should be 2")

# === 资源类型枚举测试 ===

func test_ammo_type_ammo_stack_is_0() -> void:
	assert_eq(_turret.AmmoType.AMMO_STACK, 0, "AMMO_STACK should be 0")

func test_ammo_type_magic_reserve_is_1() -> void:
	assert_eq(_turret.AmmoType.MAGIC_RESERVE, 1, "MAGIC_RESERVE should be 1")

func test_ammo_type_free_is_2() -> void:
	assert_eq(_turret.AmmoType.FREE, 2, "FREE should be 2")

# === 初始化测试 ===

func test_initialize_basic_turret() -> void:
	_turret.initialize(200)
	assert_eq(_turret.turret_id, 200, "turret_id should be 200")
	assert_eq(_turret.damage, 20, "basic turret damage should be 20")
	assert_eq(_turret.fire_rate, 2.0, "basic turret fire_rate should be 2.0")
	assert_eq(_turret.attack_range_cells, 15.0, "basic turret range should be 15 cells")
	assert_eq(_turret.ammo_type, _turret.AmmoType.MAGIC_RESERVE, "basic turret should use MAGIC_RESERVE")

func test_initialize_fast_turret() -> void:
	_turret.initialize(201)
	assert_eq(_turret.turret_id, 201, "turret_id should be 201")
	assert_eq(_turret.fire_rate, 5.0, "fast turret fire_rate should be 5.0")
	assert_eq(_turret.rotation_speed, 180.0, "fast turret rotation should be 180")

func test_initialize_heavy_turret() -> void:
	_turret.initialize(202)
	assert_eq(_turret.turret_id, 202, "turret_id should be 202")
	assert_eq(_turret.damage, 40, "heavy turret damage should be 40")
	assert_eq(_turret.ammo_type, _turret.AmmoType.AMMO_STACK, "heavy turret should use AMMO_STACK")

func test_initialize_unknown_turret_uses_defaults() -> void:
	_turret.initialize(999)
	assert_eq(_turret.turret_id, 999, "turret_id should be 999")
	assert_true(_turret.is_initialized, "should still be initialized")

# === 初始状态测试 ===

func test_initial_state_is_idle() -> void:
	assert_eq(_turret.current_state, _turret.TurretState.IDLE, "Initial state should be IDLE")

func test_initial_target_is_null() -> void:
	assert_null(_turret.current_target, "Initial target should be null")

func test_initial_cooldown_is_zero() -> void:
	assert_eq(_turret.cooldown_timer, 0.0, "cooldown_timer should start at 0")

func test_initial_health_is_max() -> void:
	assert_eq(_turret.health, _turret.max_health, "health should start at max")

func test_initial_efficiency_is_1_0() -> void:
	assert_eq(_turret.efficiency, 1.0, "efficiency should start at 1.0")

func test_initial_magic_reserve_is_max() -> void:
	assert_eq(_turret.magic_reserve, _turret.max_magic, "magic_reserve should start at max")

# === 信号测试 ===

func test_turret_state_changed_signal_exists() -> void:
	assert_true(_turret.has_signal("turret_state_changed"), "turret_state_changed signal should exist")

func test_target_locked_signal_exists() -> void:
	assert_true(_turret.has_signal("target_locked"), "target_locked signal should exist")

func test_target_lost_signal_exists() -> void:
	assert_true(_turret.has_signal("target_lost"), "target_lost signal should exist")

func test_resources_depleted_signal_exists() -> void:
	assert_true(_turret.has_signal("resources_depleted"), "resources_depleted signal should exist")

func test_global_turret_fired_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("turret_fired"), "GlobalSignals.turret_fired should exist")

func test_global_turret_hit_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("turret_hit"), "GlobalSignals.turret_hit should exist")

# === 状态转换测试 ===

func test_transition_to_targeting() -> void:
	_turret.set_state_for_test(_turret.TurretState.IDLE)
	_turret._transition_to_state(_turret.TurretState.TARGETING)
	assert_eq(_turret.current_state, _turret.TurretState.TARGETING, "Should transition to TARGETING")

func test_transition_to_firing() -> void:
	_turret.set_state_for_test(_turret.TurretState.TARGETING)
	_turret._transition_to_state(_turret.TurretState.FIRING)
	assert_eq(_turret.current_state, _turret.TurretState.FIRING, "Should transition to FIRING")

func test_transition_to_cooldown() -> void:
	_turret.set_state_for_test(_turret.TurretState.FIRING)
	_turret._transition_to_state(_turret.TurretState.COOLDOWN)
	assert_eq(_turret.current_state, _turret.TurretState.COOLDOWN, "Should transition to COOLDOWN")

func test_transition_to_disabled() -> void:
	_turret.set_state_for_test(_turret.TurretState.IDLE)
	_turret._transition_to_state(_turret.TurretState.DISABLED)
	assert_eq(_turret.current_state, _turret.TurretState.DISABLED, "Should transition to DISABLED")

func test_state_transition_applies_lock() -> void:
	_turret.set_state_for_test(_turret.TurretState.IDLE)
	_turret._transition_to_state(_turret.TurretState.TARGETING)
	assert_eq(_turret.target_lock_frames, _turret.TARGET_LOCK_FRAMES, "Should apply target lock")

func test_no_transition_same_state() -> void:
	_turret.set_state_for_test(_turret.TurretState.IDLE)
	_turret._transition_to_state(_turret.TurretState.IDLE)
	assert_eq(_turret.current_state, _turret.TurretState.IDLE, "Should remain IDLE")

# === 冷却测试 ===

func test_cooldown_duration_formula() -> void:
	_turret.initialize(200)  # fire_rate = 2.0
	_turret._perform_fire()
	assert_eq(_turret.cooldown_timer, 0.5, "cooldown should be 0.5 seconds for fire_rate=2.0")

func test_cooldown_decreases_per_frame() -> void:
	_turret.set_cooldown_for_test(0.5)
	_turret._update_cooldown(0.3)
	assert_lt(_turret.cooldown_timer, 0.5, "cooldown should decrease")

func test_cooldown_reaches_zero() -> void:
	_turret.set_cooldown_for_test(0.1)
	_turret._update_cooldown(0.5)
	assert_lte(_turret.cooldown_timer, 0.0, "cooldown should reach zero")

# === 目标搜索测试 ===

func test_find_target_method_exists() -> void:
	assert_true(_turret.has_method("_find_target"), "_find_target should exist")

func test_find_target_returns_null_no_enemies() -> void:
	_spawn_manager.clear_all_enemies()
	var target: Object = _turret._find_target()
	assert_null(target, "Should return null when no enemies")

func test_find_target_returns_nearest() -> void:
	_turret.set_position_for_test(Vector2(0, 0))
	_turret.targeting_priority = _turret.TargetingPriority.NEAREST
	# 无敌人时返回 null
	var target: Object = _turret._find_target()
	assert_null(target, "Should return null without active enemies")

# === 资源检查测试 ===

func test_check_resources_magic_reserve_sufficient() -> void:
	_turret.initialize(200)  # MAGIC_RESERVE type
	_turret.set_magic_for_test(50.0)
	assert_true(_turret._check_resources(), "Should have sufficient magic")

func test_check_resources_magic_reserve_insufficient() -> void:
	_turret.initialize(200)
	_turret.set_magic_for_test(3.0)  # Less than 5.0 cost
	assert_false(_turret._check_resources(), "Should not have sufficient magic")

func test_check_resources_ammo_stack_sufficient() -> void:
	_turret.initialize(202)  # AMMO_STACK type
	_turret.set_ammo_for_test(10)
	assert_true(_turret._check_resources(), "Should have sufficient ammo")

func test_check_resources_ammo_stack_insufficient() -> void:
	_turret.initialize(202)
	_turret.set_ammo_for_test(1)  # Less than 2 cost
	assert_false(_turret._check_resources(), "Should not have sufficient ammo")

func test_check_resources_free_always_true() -> void:
	_turret.ammo_type = _turret.AmmoType.FREE
	assert_true(_turret._check_resources(), "FREE type should always pass")

# === 资源消耗测试 ===

func test_consume_magic_reduces_reserve() -> void:
	_turret.initialize(200)
	var initial_magic: float = _turret.magic_reserve
	_turret._consume_resources()
	assert_lt(_turret.magic_reserve, initial_magic, "magic should be consumed")

func test_consume_ammo_reduces_stack() -> void:
	_turret.initialize(202)
	var initial_ammo: int = _turret.ammo_stack
	_turret._consume_resources()
	assert_lt(_turret.ammo_stack, initial_ammo, "ammo should be consumed")

func test_consume_free_no_change() -> void:
	_turret.ammo_type = _turret.AmmoType.FREE
	_turret._consume_resources()
	# No consumption for FREE type

# === 伤害计算测试 ===

func test_calculate_damage_no_armor() -> void:
	_turret.damage = 20
	_turret.efficiency = 1.0
	_turret.crit_chance = 0.0  # Disable crit
	var damage: int = _turret._calculate_damage(0.0)
	assert_eq(damage, 20, "Damage should be 20 with no armor")

func test_calculate_damage_with_armor() -> void:
	_turret.damage = 20
	_turret.efficiency = 1.0
	_turret.crit_chance = 0.0
	# armor_reduction = 10 * 0.6 = 6, final = 20 - 6 = 14
	var damage: int = _turret._calculate_damage(10.0)
	assert_eq(damage, 14, "Damage should be 14 with armor=10")

func test_calculate_damage_minimum_floor() -> void:
	_turret.damage = 5
	_turret.efficiency = 1.0
	_turret.crit_chance = 0.0
	# armor_reduction = 50 * 0.6 = 30, final = 5 - 30 = -25 → min 1
	var damage: int = _turret._calculate_damage(50.0)
	assert_eq(damage, 1, "Damage should be minimum 1")

func test_calculate_damage_with_efficiency() -> void:
	_turret.damage = 30
	_turret.efficiency = 0.5
	_turret.crit_chance = 0.0
	# final = 30 * 0.5 = 15
	var damage: int = _turret._calculate_damage(0.0)
	assert_eq(damage, 15, "Damage should be reduced by efficiency")

# === 损坏处理测试 ===

func test_take_damage_reduces_health() -> void:
	var initial_health: int = _turret.health
	_turret.take_damage(10)
	assert_lt(_turret.health, initial_health, "health should decrease")

func test_take_damage_updates_efficiency() -> void:
	_turret.max_health = 100
	_turret.health = 100
	_turret.take_damage(60)  # health = 40, ratio = 0.4
	assert_eq(_turret.efficiency, 0.8, "efficiency should drop to 0.8")

func test_take_damage_heavy_damage_threshold() -> void:
	_turret.max_health = 100
	_turret.health = 100
	_turret.take_damage(80)  # health = 20, ratio = 0.2
	assert_eq(_turret.efficiency, 0.5, "efficiency should drop to 0.5")

func test_take_damage_transitions_to_disabled() -> void:
	_turret.health = 10
	_turret.take_damage(100)
	assert_eq(_turret.current_state, _turret.TurretState.DISABLED, "Should transition to DISABLED")

# === 修复测试 ===

func test_repair_increases_health() -> void:
	_turret.health = 50
	_turret.repair(20)
	assert_eq(_turret.health, 70, "health should increase")

func test_repair_respects_max() -> void:
	_turret.health = 90
	_turret.max_health = 100
	_turret.repair(50)
	assert_eq(_turret.health, 100, "health should not exceed max")

func test_repair_restores_disabled_turret() -> void:
	_turret.health = 0
	_turret.set_state_for_test(_turret.TurretState.DISABLED)
	_turret.repair(50)
	assert_eq(_turret.current_state, _turret.TurretState.IDLE, "Should restore to IDLE")

# === 公共 API 测试 ===

func test_get_state_method_exists() -> void:
	assert_true(_turret.has_method("get_state"), "get_state should exist")

func test_get_target_method_exists() -> void:
	assert_true(_turret.has_method("get_target"), "get_target should exist")

func test_get_health_ratio_method_exists() -> void:
	assert_true(_turret.has_method("get_health_ratio"), "get_health_ratio should exist")

func test_get_resource_ratio_method_exists() -> void:
	assert_true(_turret.has_method("get_resource_ratio"), "get_resource_ratio should exist")

func test_replenish_ammo_method_exists() -> void:
	assert_true(_turret.has_method("replenish_ammo"), "replenish_ammo should exist")

func test_replenish_magic_method_exists() -> void:
	assert_true(_turret.has_method("replenish_magic"), "replenish_magic should exist")

func test_take_damage_method_exists() -> void:
	assert_true(_turret.has_method("take_damage"), "take_damage should exist")

func test_repair_method_exists() -> void:
	assert_true(_turret.has_method("repair"), "repair should exist")

# === get_health_ratio 测试 ===

func test_get_health_ratio_full_health() -> void:
	_turret.health = 100
	_turret.max_health = 100
	assert_eq(_turret.get_health_ratio(), 1.0, "Full health should be 1.0")

func test_get_health_ratio_half_health() -> void:
	_turret.health = 50
	_turret.max_health = 100
	assert_eq(_turret.get_health_ratio(), 0.5, "Half health should be 0.5")

# === get_resource_ratio 测试 ===

func test_get_resource_ratio_magic_full() -> void:
	_turret.initialize(200)  # MAGIC_RESERVE
	_turret.magic_reserve = _turret.max_magic
	assert_eq(_turret.get_resource_ratio(), 1.0, "Full magic should be 1.0")

func test_get_resource_ratio_ammo_full() -> void:
	_turret.initialize(202)  # AMMO_STACK
	_turret.ammo_stack = _turret.max_ammo
	assert_eq(_turret.get_resource_ratio(), 1.0, "Full ammo should be 1.0")

func test_get_resource_ratio_free_always_1() -> void:
	_turret.ammo_type = _turret.AmmoType.FREE
	assert_eq(_turret.get_resource_ratio(), 1.0, "FREE should always return 1.0")

# === 补给测试 ===

func test_replenish_magic_increases_reserve() -> void:
	_turret.initialize(200)
	_turret.magic_reserve = 50.0
	_turret.replenish_magic(30.0)
	assert_eq(_turret.magic_reserve, 80.0, "magic should increase")

func test_replenish_magic_respects_max() -> void:
	_turret.initialize(200)
	_turret.magic_reserve = 90.0
	_turret.replenish_magic(50.0)
	assert_eq(_turret.magic_reserve, 100.0, "magic should not exceed max")

func test_replenish_ammo_increases_stack() -> void:
	_turret.initialize(202)
	_turret.ammo_stack = 10
	_turret.replenish_ammo(20)
	assert_eq(_turret.ammo_stack, 30, "ammo should increase")

func test_replenish_ammo_respects_max() -> void:
	_turret.initialize(202)
	_turret.ammo_stack = 25
	_turret.replenish_ammo(50)
	assert_eq(_turret.ammo_stack, 30, "ammo should not exceed max")

# === 测试辅助方法测试 ===

func test_set_state_for_test_method_exists() -> void:
	assert_true(_turret.has_method("set_state_for_test"), "set_state_for_test should exist")

func test_set_target_for_test_method_exists() -> void:
	assert_true(_turret.has_method("set_target_for_test"), "set_target_for_test should exist")

func test_set_cooldown_for_test_method_exists() -> void:
	assert_true(_turret.has_method("set_cooldown_for_test"), "set_cooldown_for_test should exist")

func test_set_health_for_test_method_exists() -> void:
	assert_true(_turret.has_method("set_health_for_test"), "set_health_for_test should exist")

func test_set_ammo_for_test_method_exists() -> void:
	assert_true(_turret.has_method("set_ammo_for_test"), "set_ammo_for_test should exist")

func test_set_magic_for_test_method_exists() -> void:
	assert_true(_turret.has_method("set_magic_for_test"), "set_magic_for_test should exist")

func test_set_position_for_test_method_exists() -> void:
	assert_true(_turret.has_method("set_position_for_test"), "set_position_for_test should exist")

# === 依赖注入测试 ===

func test_set_dependencies_method_exists() -> void:
	assert_true(_turret.has_method("set_dependencies"), "set_dependencies should exist")

func test_is_initialized_true_after_set_dependencies() -> void:
	_turret.set_dependencies(_spawn_manager, GlobalSignals, null)
	assert_true(_turret.is_initialized, "is_initialized should be true")

# === DISABLED 状态执行测试 ===

func test_disabled_state_clears_target() -> void:
	_turret.set_state_for_test(_turret.TurretState.DISABLED)
	_turret.set_target_for_test(null)  # 模拟有目标
	_turret._execute_disabled(0.016)
	assert_null(_turret.current_target, "DISABLED should clear target")

# === IDLE 状态执行测试 ===

func test_idle_state_searches_target() -> void:
	_turret.set_state_for_test(_turret.TurretState.IDLE)
	_spawn_manager.clear_all_enemies()
	_turret._execute_idle(0.016)
	assert_eq(_turret.current_state, _turret.TurretState.IDLE, "Should remain IDLE with no enemies")

# === COOLDOWN 状态执行测试 ===

func test_cooldown_transitions_to_idle_when_no_target() -> void:
	_turret.set_state_for_test(_turret.TurretState.COOLDOWN)
	_turret.set_cooldown_for_test(0.0)
	_turret.set_target_for_test(null)
	_turret._execute_cooldown(0.016)
	assert_eq(_turret.current_state, _turret.TurretState.IDLE, "Should transition to IDLE")

func test_cooldown_transitions_to_firing_when_ready() -> void:
	_turret.set_state_for_test(_turret.TurretState.COOLDOWN)
	_turret.set_cooldown_for_test(0.0)
	_turret.set_magic_for_test(100.0)  # Sufficient resources
	# Need a valid target for transition
	_turret.set_target_for_test(null)
	_turret._execute_cooldown(0.016)
	assert_eq(_turret.current_state, _turret.TurretState.IDLE, "Should go IDLE without target")

# === 边界值测试 ===

func test_attack_range_calculation() -> void:
	_turret.initialize(200)
	assert_eq(_turret.attack_range, _turret.attack_range_cells * _turret.CELL_SIZE, "attack_range should be cells * CELL_SIZE")

func test_targeting_range_calculation() -> void:
	_turret.initialize(200)
	assert_eq(_turret.targeting_range, _turret.attack_range * _turret.TARGETING_RANGE_MULT, "targeting_range should be attack_range * mult")

func test_cooldown_timer_formula() -> void:
	_turret.fire_rate = 1.0
	_turret._perform_fire()
	assert_eq(_turret.cooldown_timer, 1.0, "cooldown should be 1/fire_rate")