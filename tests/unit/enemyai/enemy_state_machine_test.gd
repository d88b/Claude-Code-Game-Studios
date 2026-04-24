# enemy_state_machine_test.gd
# Unit tests for Story: Enemy AI State Machine
# tests/unit/enemyai/enemy_state_machine_test.gd

extends GutTest

const EnemyAIControllerScript := preload("res://src/ai/enemy_ai_controller.gd")
const EnemyTypeDBScript := preload("res://src/database/enemy_type_db.gd")

var _enemy_ai: Object
var _enemy_type_db: Object

# === Setup ===

func before_all() -> void:
	# 创建 EnemyTypeDB
	_enemy_type_db = EnemyTypeDBScript.new()
	add_child_autoqfree(_enemy_type_db)
	await get_tree().process_frame

func before_each() -> void:
	# 创建 EnemyAIController
	_enemy_ai = EnemyAIControllerScript.new()
	add_child_autoqfree(_enemy_ai)
	_enemy_ai.set_dependencies(_enemy_type_db, null, GlobalSignals, null)
	_enemy_ai.initialize(1)

# === 常量验证 ===

func test_detection_range_mult_is_2_0() -> void:
	assert_eq(_enemy_ai.DETECTION_RANGE_MULT, 2.0, "DETECTION_RANGE_MULT should be 2.0")

func test_state_lock_frames_is_3() -> void:
	assert_eq(_enemy_ai.STATE_LOCK_FRAMES, 3, "STATE_LOCK_FRAMES should be 3")

func test_max_path_retries_is_3() -> void:
	assert_eq(_enemy_ai.MAX_PATH_RETRIES, 3, "MAX_PATH_RETRIES should be 3")

func test_tracker_hunt_speed_mult_is_1_5() -> void:
	assert_eq(_enemy_ai.TRACKER_HUNT_SPEED_MULT, 1.5, "TRACKER_HUNT_SPEED_MULT should be 1.5")

func test_path_recalc_interval_tracker_is_0_1() -> void:
	assert_eq(_enemy_ai.PATH_RECALC_INTERVAL_TRACKER, 0.1, "PATH_RECALC_INTERVAL_TRACKER should be 0.1")

func test_path_recalc_interval_standard_is_0_5() -> void:
	assert_eq(_enemy_ai.PATH_RECALC_INTERVAL_STANDARD, 0.5, "PATH_RECALC_INTERVAL_STANDARD should be 0.5")

func test_idle_timeout_is_5_0() -> void:
	assert_eq(_enemy_ai.IDLE_TIMEOUT, 5.0, "IDLE_TIMEOUT should be 5.0")

# === 状态枚举测试 ===

func test_state_idle_is_0() -> void:
	assert_eq(_enemy_ai.EnemyState.IDLE, 0, "IDLE should be 0")

func test_state_move_to_target_is_1() -> void:
	assert_eq(_enemy_ai.EnemyState.MOVE_TO_TARGET, 1, "MOVE_TO_TARGET should be 1")

func test_state_attack_is_2() -> void:
	assert_eq(_enemy_ai.EnemyState.ATTACK, 2, "ATTACK should be 2")

func test_state_stun_is_3() -> void:
	assert_eq(_enemy_ai.EnemyState.STUN, 3, "STUN should be 3")

func test_state_dead_is_4() -> void:
	assert_eq(_enemy_ai.EnemyState.DEAD, 4, "DEAD should be 4")

# === behavior_hint 扩展状态测试 ===

func test_behavior_state_normal_is_0() -> void:
	assert_eq(_enemy_ai.BehaviorState.NORMAL, 0, "NORMAL should be 0")

func test_behavior_state_breaking_wall_is_1() -> void:
	assert_eq(_enemy_ai.BehaviorState.BREAKING_WALL, 1, "BREAKING_WALL should be 1")

func test_behavior_state_hunting_is_2() -> void:
	assert_eq(_enemy_ai.BehaviorState.HUNTING, 2, "HUNTING should be 2")

func test_behavior_state_patroling_is_3() -> void:
	assert_eq(_enemy_ai.BehaviorState.PATROLING, 3, "PATROLING should be 3")

func test_behavior_state_aiming_is_4() -> void:
	assert_eq(_enemy_ai.BehaviorState.AIMING, 4, "AIMING should be 4")

func test_behavior_state_hiding_is_5() -> void:
	assert_eq(_enemy_ai.BehaviorState.HIDING, 5, "HIDING should be 5")

func test_behavior_state_summoning_is_6() -> void:
	assert_eq(_enemy_ai.BehaviorState.SUMMONING, 6, "SUMMONING should be 6")

func test_behavior_state_buffing_is_7() -> void:
	assert_eq(_enemy_ai.BehaviorState.BUFFING, 7, "BUFFING should be 7")

# === 初始化测试 ===

func test_initialize_basic_enemy() -> void:
	_enemy_ai.initialize(1)
	assert_eq(_enemy_ai.enemy_id, 1, "enemy_id should be 1")
	assert_eq(_enemy_ai.health, 60.0, "basic enemy health should be 60")
	assert_eq(_enemy_ai.damage, 7.0, "basic enemy damage should be 7")
	assert_eq(_enemy_ai.base_speed, 90.0, "basic enemy speed should be 90")
	assert_eq(_enemy_ai.behavior_hint, "aggressive", "basic enemy behavior should be aggressive")

func test_initialize_swarm_enemy() -> void:
	_enemy_ai.initialize(4)
	assert_eq(_enemy_ai.enemy_id, 4, "enemy_id should be 4")
	assert_eq(_enemy_ai.behavior_hint, "swarm", "swarm enemy behavior should be swarm")

func test_initialize_wall_breaker_enemy() -> void:
	_enemy_ai.initialize(5)
	assert_eq(_enemy_ai.enemy_id, 5, "enemy_id should be 5")
	assert_eq(_enemy_ai.behavior_hint, "wall_breaker", "wall_breaker behavior should be wall_breaker")
	assert_eq(_enemy_ai.armor, 5.0, "wall_breaker armor should be 5")

func test_initialize_tracker_enemy() -> void:
	_enemy_ai.initialize(6)
	assert_eq(_enemy_ai.enemy_id, 6, "enemy_id should be 6")
	assert_eq(_enemy_ai.behavior_hint, "tracker", "tracker behavior should be tracker")
	assert_eq(_enemy_ai.speed_multiplier, 1.5, "tracker speed_multiplier should be 1.5")

func test_initialize_boss_enemy() -> void:
	_enemy_ai.initialize(100)
	assert_eq(_enemy_ai.enemy_id, 100, "enemy_id should be 100")
	assert_eq(_enemy_ai.health, 500.0, "boss health should be 500")
	assert_eq(_enemy_ai.behavior_hint, "boss", "boss behavior should be boss")

func test_initialize_unknown_enemy_uses_defaults() -> void:
	_enemy_ai.initialize(999)
	assert_eq(_enemy_ai.enemy_id, 999, "enemy_id should be 999")
	assert_true(_enemy_ai.is_initialized, "should still be initialized")

# === 状态机初始状态测试 ===

func test_initial_state_is_idle() -> void:
	assert_eq(_enemy_ai.current_state, _enemy_ai.EnemyState.IDLE, "Initial state should be IDLE")

func test_initial_behavior_state_is_normal() -> void:
	assert_eq(_enemy_ai.behavior_state, _enemy_ai.BehaviorState.NORMAL, "Initial behavior state should be NORMAL")

func test_initial_attack_timer_is_zero() -> void:
	assert_eq(_enemy_ai.attack_timer, 0.0, "attack_timer should start at 0")

func test_initial_state_lock_frames_is_zero() -> void:
	assert_eq(_enemy_ai.state_lock_frames, 0, "state_lock_frames should start at 0")

# === 状态转换测试 ===

func test_transition_to_move_to_target() -> void:
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.IDLE)
	_enemy_ai._transition_to_state(_enemy_ai.EnemyState.MOVE_TO_TARGET)
	assert_eq(_enemy_ai.current_state, _enemy_ai.EnemyState.MOVE_TO_TARGET, "Should transition to MOVE_TO_TARGET")

func test_transition_to_attack() -> void:
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.MOVE_TO_TARGET)
	_enemy_ai._transition_to_state(_enemy_ai.EnemyState.ATTACK)
	assert_eq(_enemy_ai.current_state, _enemy_ai.EnemyState.ATTACK, "Should transition to ATTACK")

func test_transition_to_dead() -> void:
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.IDLE)
	_enemy_ai._transition_to_state(_enemy_ai.EnemyState.DEAD)
	assert_eq(_enemy_ai.current_state, _enemy_ai.EnemyState.DEAD, "Should transition to DEAD")

func test_state_transition_applies_lock() -> void:
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.IDLE)
	_enemy_ai._transition_to_state(_enemy_ai.EnemyState.MOVE_TO_TARGET)
	assert_eq(_enemy_ai.state_lock_frames, _enemy_ai.STATE_LOCK_FRAMES, "Should apply state lock")

func test_no_transition_same_state() -> void:
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.IDLE)
	_enemy_ai._transition_to_state(_enemy_ai.EnemyState.IDLE)
	assert_eq(_enemy_ai.current_state, _enemy_ai.EnemyState.IDLE, "Should remain IDLE")

# === 伤害测试 ===

func test_take_damage_reduces_health() -> void:
	var initial_health: float = _enemy_ai.health
	_enemy_ai.take_damage(20.0)
	assert_lt(_enemy_ai.health, initial_health, "Health should decrease")

func test_take_damage_applies_armor() -> void:
	_enemy_ai.initialize(5)  # wall_breaker has armor=5
	var armor: float = _enemy_ai.armor
	var raw_damage: float = 20.0
	var expected: float = raw_damage * (1.0 - armor / 100.0)  # 20 * 0.95 = 19

	var initial_health: float = _enemy_ai.health
	_enemy_ai.take_damage(raw_damage)
	var actual_damage: float = initial_health - _enemy_ai.health

	assert_almost_eq(actual_damage, expected, 0.1, "Damage should be reduced by armor")

func test_take_damage_zero_armor() -> void:
	_enemy_ai.initialize(1)  # aggressive has armor=0
	var raw_damage: float = 20.0

	var initial_health: float = _enemy_ai.health
	_enemy_ai.take_damage(raw_damage)
	var actual_damage: float = initial_health - _enemy_ai.health

	assert_eq(actual_damage, raw_damage, "No armor reduction should apply")

func test_take_damage_transitions_to_dead() -> void:
	_enemy_ai.set_health_for_test(10.0)
	_enemy_ai.take_damage(100.0)
	assert_eq(_enemy_ai.current_state, _enemy_ai.EnemyState.DEAD, "Should transition to DEAD")

func test_take_damage_negative_health_clamped() -> void:
	_enemy_ai.take_damage(1000.0)
	assert_lt(_enemy_ai.health, 0.0, "Health can go negative")

# === 目标检测测试 ===

func test_detect_target_method_exists() -> void:
	assert_true(_enemy_ai.has_method("_detect_target"), "_detect_target should exist")

func test_detect_target_returns_null_without_vehicle() -> void:
	_enemy_ai.set_dependencies(_enemy_type_db, null, GlobalSignals, null)
	var target: Object = _enemy_ai._detect_target()
	assert_null(target, "Should return null without vehicle")

# === 信号测试 ===

func test_state_changed_signal_exists() -> void:
	assert_true(_enemy_ai.has_signal("state_changed"), "state_changed signal should exist")

func test_attack_triggered_signal_exists() -> void:
	assert_true(_enemy_ai.has_signal("attack_triggered"), "attack_triggered signal should exist")

func test_target_lost_signal_exists() -> void:
	assert_true(_enemy_ai.has_signal("target_lost"), "target_lost signal should exist")

func test_global_enemy_killed_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("enemy_killed"), "GlobalSignals.enemy_killed should exist")

# === 公共 API 测试 ===

func test_get_current_state_method_exists() -> void:
	assert_true(_enemy_ai.has_method("get_current_state"), "get_current_state should exist")

func test_get_health_method_exists() -> void:
	assert_true(_enemy_ai.has_method("get_health"), "get_health should exist")

func test_take_damage_method_exists() -> void:
	assert_true(_enemy_ai.has_method("take_damage"), "take_damage should exist")

func test_set_stun_method_exists() -> void:
	assert_true(_enemy_ai.has_method("set_stun"), "set_stun should exist")

func test_initialize_method_exists() -> void:
	assert_true(_enemy_ai.has_method("initialize"), "initialize should exist")

func test_set_dependencies_method_exists() -> void:
	assert_true(_enemy_ai.has_method("set_dependencies"), "set_dependencies should exist")

# === 测试辅助方法测试 ===

func test_set_state_for_test_method_exists() -> void:
	assert_true(_enemy_ai.has_method("set_state_for_test"), "set_state_for_test should exist")

func test_set_target_for_test_method_exists() -> void:
	assert_true(_enemy_ai.has_method("set_target_for_test"), "set_target_for_test should exist")

func test_set_health_for_test_method_exists() -> void:
	assert_true(_enemy_ai.has_method("set_health_for_test"), "set_health_for_test should exist")

func test_set_attack_timer_for_test_method_exists() -> void:
	assert_true(_enemy_ai.has_method("set_attack_timer_for_test"), "set_attack_timer_for_test should exist")

func test_set_position_for_test_method_exists() -> void:
	assert_true(_enemy_ai.has_method("set_position_for_test"), "set_position_for_test should exist")

# === behavior_hint 速度倍率测试 ===

func test_tracker_speed_multiplier_applied() -> void:
	_enemy_ai.initialize(6)  # tracker
	assert_eq(_enemy_ai.speed_multiplier, _enemy_ai.TRACKER_HUNT_SPEED_MULT, "Tracker should have speed multiplier")

func test_aggressive_speed_multiplier_is_1_0() -> void:
	_enemy_ai.initialize(1)  # aggressive
	assert_eq(_enemy_ai.speed_multiplier, 1.0, "Aggressive should have default multiplier")

func test_swarm_speed_multiplier_is_1_0() -> void:
	_enemy_ai.initialize(4)  # swarm
	assert_eq(_enemy_ai.speed_multiplier, 1.0, "Swarm should have default multiplier")

# === 边界值测试 ===

func test_detection_range_calculated_correctly() -> void:
	_enemy_ai.initialize(1)
	var expected: float = _enemy_ai.attack_range * _enemy_ai.DETECTION_RANGE_MULT
	assert_eq(_enemy_ai.detection_range, expected, "detection_range should be attack_range * multiplier")

func test_attack_range_default_is_32() -> void:
	_enemy_ai.initialize(1)
	assert_eq(_enemy_ai.attack_range, 32.0, "attack_range default should be 32")

func test_attack_cooldown_default_is_1_0() -> void:
	_enemy_ai.initialize(1)
	assert_eq(_enemy_ai.attack_cooldown, 1.0, "attack_cooldown default should be 1.0")

# === 依赖注入测试 ===

func test_set_dependencies_sets_enemy_type_db() -> void:
	var mock_db: Object = _enemy_type_db
	_enemy_ai.set_dependencies(mock_db, null, null, null)
	assert_eq(_enemy_ai._enemy_type_db, mock_db, "enemy_type_db should be set")

func test_is_initialized_true_after_initialize() -> void:
	_enemy_ai.initialize(1)
	assert_true(_enemy_ai.is_initialized, "is_initialized should be true")

# === 死亡处理测试 ===

func test_dead_state_stops_movement() -> void:
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.DEAD)
	_enemy_ai.velocity = Vector2(100, 100)
	_enemy_ai._execute_dead(0.016)
	assert_eq(_enemy_ai.velocity, Vector2.ZERO, "DEAD state should zero velocity")

func test_dead_state_emits_enemy_killed() -> void:
	var signal_emitted: bool = false
	var killed_id: int = -1
	GlobalSignals.enemy_killed.connect(func(p_id: int):
		signal_emitted = true
		killed_id = p_id
	)

	_enemy_ai.initialize(1)
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.IDLE)
	_enemy_ai._transition_to_state(_enemy_ai.EnemyState.DEAD)

	assert_true(signal_emitted, "enemy_killed should emit on death")
	assert_eq(killed_id, 1, "enemy_id should match")

# === 计时器更新测试 ===

func test_attack_timer_decreases_per_frame() -> void:
	_enemy_ai.set_attack_timer_for_test(1.0)
	_enemy_ai._update_timers(0.5)
	assert_lt(_enemy_ai.attack_timer, 1.0, "attack_timer should decrease")

func test_attack_timer_clamps_to_zero() -> void:
	_enemy_ai.set_attack_timer_for_test(0.1)
	_enemy_ai._update_timers(0.5)
	assert_lte(_enemy_ai.attack_timer, 0.0, "attack_timer should not go negative")

func test_path_recalc_timer_decreases() -> void:
	_enemy_ai.path_recalc_timer = 0.5
	_enemy_ai._update_timers(0.3)
	assert_lt(_enemy_ai.path_recalc_timer, 0.5, "path_recalc_timer should decrease")

# === IDLE 状态执行测试 ===

func test_idle_timer_increment_in_idle_state() -> void:
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.IDLE)
	_enemy_ai.idle_timer = 0.0
	_enemy_ai._execute_idle(0.1)
	assert_gt(_enemy_ai.idle_timer, 0.0, "idle_timer should increment")

func test_idle_timer_reset_after_timeout() -> void:
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.IDLE)
	_enemy_ai.idle_timer = _enemy_ai.IDLE_TIMEOUT
	_enemy_ai._execute_idle(0.016)
	assert_lt(_enemy_ai.idle_timer, _enemy_ai.IDLE_TIMEOUT, "idle_timer should reset after timeout")

# === STUN 状态测试 ===

func test_stun_zeros_velocity() -> void:
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.STUN)
	_enemy_ai.velocity = Vector2(100, 100)
	_enemy_ai._execute_stun(0.016)
	assert_eq(_enemy_ai.velocity, Vector2.ZERO, "STUN should zero velocity")

func test_set_stun_transitions_to_stun_state() -> void:
	_enemy_ai.set_state_for_test(_enemy_ai.EnemyState.IDLE)
	_enemy_ai.set_stun(1.0)
	assert_eq(_enemy_ai.current_state, _enemy_ai.EnemyState.STUN, "set_stun should transition to STUN")