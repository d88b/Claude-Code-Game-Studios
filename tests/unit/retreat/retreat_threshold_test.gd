# retreat_threshold_test.gd
# Unit tests for Story: Retreat Threshold Detection
# tests/unit/retreat/retreat_threshold_test.gd

extends GutTest

const RetreatJudgeScript := preload("res://src/retreat/retreat_judge.gd")
const VehicleAttributeScript := preload("res://src/core/vehicle_attribute.gd")
const TimeSystemScript := preload("res://src/time/time_system.gd")

var _retreat_judge: Object
var _vehicle_attr: Object
var _time_system: Object

# === Setup ===

func before_each() -> void:
	# 创建 VehicleAttribute
	_vehicle_attr = VehicleAttributeScript.new()
	add_child_autoqfree(_vehicle_attr)
	_vehicle_attr.set_dependencies(VehicleTypeDB, GlobalSignals)
	_vehicle_attr.initialize(1)

	# 创建 TimeSystem
	_time_system = TimeSystemScript.new()
	add_child_autoqfree(_time_system)

	# 创建 RetreatJudge
	_retreat_judge = RetreatJudgeScript.new()
	add_child_autoqfree(_retreat_judge)
	_retreat_judge.set_dependencies(_vehicle_attr, _time_system, GlobalSignals)

# === 常量验证 ===

func test_health_critical_threshold_is_0_20() -> void:
	assert_eq(_retreat_judge.HEALTH_CRITICAL_THRESHOLD, 0.20, "HEALTH_CRITICAL_THRESHOLD should be 0.20")

func test_magic_depleted_threshold_is_0_10() -> void:
	assert_eq(_retreat_judge.MAGIC_DEPLETED_THRESHOLD, 0.10, "MAGIC_DEPLETED_THRESHOLD should be 0.10")

func test_check_interval_is_0_5() -> void:
	assert_eq(_retreat_judge.CHECK_INTERVAL, 0.5, "CHECK_INTERVAL should be 0.5")

# === 撤退原因枚举测试 ===

func test_reason_none_is_0() -> void:
	assert_eq(_retreat_judge.RetreatReason.NONE, 0, "NONE should be 0")

func test_reason_health_critical_is_1() -> void:
	assert_eq(_retreat_judge.RetreatReason.HEALTH_CRITICAL, 1, "HEALTH_CRITICAL should be 1")

func test_reason_magic_depleted_is_2() -> void:
	assert_eq(_retreat_judge.RetreatReason.MAGIC_DEPLETED, 2, "MAGIC_DEPLETED should be 2")

func test_reason_night_fall_is_3() -> void:
	assert_eq(_retreat_judge.RetreatReason.NIGHT_FALL, 3, "NIGHT_FALL should be 3")

func test_reason_multiple_is_4() -> void:
	assert_eq(_retreat_judge.RetreatReason.MULTIPLE, 4, "MULTIPLE should be 4")

# === 初始状态测试 ===

func test_initial_state_is_none() -> void:
	assert_eq(_retreat_judge.current_retreat_state, _retreat_judge.RetreatReason.NONE, "Initial state should be NONE")

func test_initial_warning_not_active() -> void:
	assert_false(_retreat_judge.is_warning_active(), "Warning should not be active initially")

func test_initial_reasons_empty() -> void:
	assert_eq(_retreat_judge.get_active_reasons().size(), 0, "Active reasons should be empty initially")

# === 生命值阈值检测测试 ===

func test_health_below_20_percent_triggers_warning() -> void:
	# Arrange — health = 15% (below 20% threshold)
	_vehicle_attr.set_health_for_test(15.0)  # 15/100 = 15%

	var signal_emitted: bool = false
	var reason: String = ""
	GlobalSignals.retreat_threshold_reached.connect(func(p_reason: String):
		signal_emitted = true
		reason = p_reason
	)

	# Act — 强制触发检查
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active")
	assert_eq(_retreat_judge.current_retreat_state, _retreat_judge.RetreatReason.HEALTH_CRITICAL, "State should be HEALTH_CRITICAL")
	assert_true(signal_emitted, "retreat_threshold_reached should emit")
	assert_eq(reason, "health_critical", "Reason should be health_critical")

func test_health_above_20_percent_no_warning() -> void:
	# Arrange — health = 25% (above 20% threshold)
	_vehicle_attr.set_health_for_test(25.0)  # 25/100 = 25%

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_false(_retreat_judge.is_warning_active(), "Warning should not be active at 25%")

func test_health_at_exactly_20_percent_no_warning() -> void:
	# Arrange — health = 20% exactly (at threshold, not below)
	_vehicle_attr.set_health_for_test(20.0)  # 20/100 = 20%

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert — at threshold should NOT trigger (only < 20% triggers)
	assert_false(_retreat_judge.is_warning_active(), "Warning should not be active at exactly 20%")

func test_health_at_19_percent_triggers_warning() -> void:
	# Arrange — health = 19% (below threshold)
	_vehicle_attr.set_health_for_test(19.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active at 19%")

func test_health_at_zero_triggers_warning() -> void:
	# Arrange — health = 0%
	_vehicle_attr.set_health_for_test(0.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active at 0%")

# === 魔能阈值检测测试 ===

func test_magic_below_10_percent_triggers_warning() -> void:
	# Arrange — magic = 5% (below 10% threshold)
	_vehicle_attr.set_magic_for_test(5.0)  # 5/100 = 5%
	_vehicle_attr.set_health_for_test(50.0)  # health above threshold

	var signal_emitted: bool = false
	var reason: String = ""
	GlobalSignals.retreat_threshold_reached.connect(func(p_reason: String):
		signal_emitted = true
		reason = p_reason
	)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active")
	assert_eq(_retreat_judge.current_retreat_state, _retreat_judge.RetreatReason.MAGIC_DEPLETED, "State should be MAGIC_DEPLETED")
	assert_true(signal_emitted, "retreat_threshold_reached should emit")
	assert_eq(reason, "magic_depleted", "Reason should be magic_depleted")

func test_magic_above_10_percent_no_warning() -> void:
	# Arrange — magic = 15% (above 10% threshold)
	_vehicle_attr.set_magic_for_test(15.0)
	_vehicle_attr.set_health_for_test(50.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_false(_retreat_judge.is_warning_active(), "Warning should not be active at 15% magic")

func test_magic_at_exactly_10_percent_no_warning() -> void:
	# Arrange — magic = 10% exactly
	_vehicle_attr.set_magic_for_test(10.0)
	_vehicle_attr.set_health_for_test(50.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert — at threshold should NOT trigger (only < 10% triggers)
	assert_false(_retreat_judge.is_warning_active(), "Warning should not be active at exactly 10% magic")

func test_magic_at_9_percent_triggers_warning() -> void:
	# Arrange — magic = 9%
	_vehicle_attr.set_magic_for_test(9.0)
	_vehicle_attr.set_health_for_test(50.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active at 9% magic")

# === 夜晚降临检测测试 ===

func test_night_phase_triggers_warning() -> void:
	# Arrange — set time to NIGHT phase (hour 19-05)
	_time_system.set_time(19 * 3600)  # 19:00 = NIGHT start
	_vehicle_attr.set_health_for_test(50.0)
	_vehicle_attr.set_magic_for_test(50.0)

	var signal_emitted: bool = false
	var reason: String = ""
	GlobalSignals.retreat_threshold_reached.connect(func(p_reason: String):
		signal_emitted = true
		reason = p_reason
	)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active at NIGHT")
	assert_eq(_retreat_judge.current_retreat_state, _retreat_judge.RetreatReason.NIGHT_FALL, "State should be NIGHT_FALL")
	assert_true(signal_emitted, "retreat_threshold_reached should emit")
	assert_eq(reason, "night_fall", "Reason should be night_fall")

func test_day_phase_no_warning() -> void:
	# Arrange — set time to DAY phase (hour 7-17)
	_time_system.set_time(10 * 3600)  # 10:00 = DAY
	_vehicle_attr.set_health_for_test(50.0)
	_vehicle_attr.set_magic_for_test(50.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_false(_retreat_judge.is_warning_active(), "Warning should not be active during DAY")

func test_dawn_phase_no_warning() -> void:
	# Arrange — set time to DAWN phase (hour 5-7)
	_time_system.set_time(6 * 3600)  # 06:00 = DAWN
	_vehicle_attr.set_health_for_test(50.0)
	_vehicle_attr.set_magic_for_test(50.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_false(_retreat_judge.is_warning_active(), "Warning should not be active during DAWN")

func test_dusk_phase_no_warning() -> void:
	# Arrange — set time to DUSK phase (hour 17-19)
	_time_system.set_time(18 * 3600)  # 18:00 = DUSK
	_vehicle_attr.set_health_for_test(50.0)
	_vehicle_attr.set_magic_for_test(50.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_false(_retreat_judge.is_warning_active(), "Warning should not be active during DUSK")

func test_night_at_23_hour_triggers_warning() -> void:
	# Arrange — set time to 23:00 (deep night)
	_time_system.set_time(23 * 3600)
	_vehicle_attr.set_health_for_test(50.0)
	_vehicle_attr.set_magic_for_test(50.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active at 23:00")

func test_night_at_03_hour_triggers_warning() -> void:
	# Arrange — set time to 03:00 (night before dawn)
	_time_system.set_time(3 * 3600)
	_vehicle_attr.set_health_for_test(50.0)
	_vehicle_attr.set_magic_for_test(50.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active at 03:00")

# === 多重阈值测试 ===

func test_health_and_magic_both_low_triggers_multiple_warning() -> void:
	# Arrange — both health < 20% and magic < 10%
	_vehicle_attr.set_health_for_test(15.0)  # 15%
	_vehicle_attr.set_magic_for_test(5.0)    # 5%
	_time_system.set_time(10 * 3600)         # DAY phase

	var signal_emitted: bool = false
	var reason: String = ""
	GlobalSignals.retreat_threshold_reached.connect(func(p_reason: String):
		signal_emitted = true
		reason = p_reason
	)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active")
	assert_eq(_retreat_judge.get_danger_count(), 2, "Should have 2 danger reasons")
	assert_eq(_retreat_judge.current_retreat_state, _retreat_judge.RetreatReason.MULTIPLE, "State should be MULTIPLE")
	assert_true(signal_emitted, "retreat_threshold_reached should emit")
	assert_eq(reason, "multiple_dangers", "Reason should be multiple_dangers")

func test_health_and_night_both_trigger_multiple_warning() -> void:
	# Arrange — health < 20% and NIGHT
	_vehicle_attr.set_health_for_test(15.0)
	_vehicle_attr.set_magic_for_test(50.0)
	_time_system.set_time(20 * 3600)  # NIGHT

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active")
	assert_eq(_retreat_judge.get_danger_count(), 2, "Should have 2 danger reasons")
	assert_eq(_retreat_judge.current_retreat_state, _retreat_judge.RetreatReason.MULTIPLE, "State should be MULTIPLE")

func test_all_three_thresholds_trigger_multiple_warning() -> void:
	# Arrange — all three: health, magic, night
	_vehicle_attr.set_health_for_test(15.0)
	_vehicle_attr.set_magic_for_test(5.0)
	_time_system.set_time(20 * 3600)  # NIGHT

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active")
	assert_eq(_retreat_judge.get_danger_count(), 3, "Should have 3 danger reasons")
	assert_eq(_retreat_judge.current_retreat_state, _retreat_judge.RetreatReason.MULTIPLE, "State should be MULTIPLE")

# === 警告解除测试 ===

func test_warning_clears_when_health_restored() -> void:
	# Arrange — initially low health
	_vehicle_attr.set_health_for_test(15.0)
	_retreat_judge._check_retreat_conditions()
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active initially")

	var signal_emitted: bool = false
	GlobalSignals.retreat_warning_cleared.connect(func():
		signal_emitted = true
	)

	# Act — restore health above threshold
	_vehicle_attr.set_health_for_test(30.0)  # 30%
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_false(_retreat_judge.is_warning_active(), "Warning should be cleared")
	assert_true(signal_emitted, "retreat_warning_cleared should emit")

func test_warning_clears_when_magic_restored() -> void:
	# Arrange — initially low magic
	_vehicle_attr.set_health_for_test(50.0)
	_vehicle_attr.set_magic_for_test(5.0)
	_retreat_judge._check_retreat_conditions()
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active initially")

	var signal_emitted: bool = false
	GlobalSignals.retreat_warning_cleared.connect(func():
		signal_emitted = true
	)

	# Act — restore magic above threshold
	_vehicle_attr.set_magic_for_test(20.0)
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_false(_retreat_judge.is_warning_active(), "Warning should be cleared")
	assert_true(signal_emitted, "retreat_warning_cleared should emit")

func test_warning_clears_when_day_starts() -> void:
	# Arrange — initially night
	_time_system.set_time(20 * 3600)  # NIGHT
	_vehicle_attr.set_health_for_test(50.0)
	_vehicle_attr.set_magic_for_test(50.0)
	_retreat_judge._check_retreat_conditions()
	assert_true(_retreat_judge.is_warning_active(), "Warning should be active initially")

	var signal_emitted: bool = false
	GlobalSignals.retreat_warning_cleared.connect(func():
		signal_emitted = true
	)

	# Act — advance to DAY
	_time_system.set_time(10 * 3600)  # DAY
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_false(_retreat_judge.is_warning_active(), "Warning should be cleared")
	assert_true(signal_emitted, "retreat_warning_cleared should emit")

func test_partial_clear_updates_reason() -> void:
	# Arrange — multiple dangers (health + magic)
	_vehicle_attr.set_health_for_test(15.0)
	_vehicle_attr.set_magic_for_test(5.0)
	_time_system.set_time(10 * 3600)  # DAY
	_retreat_judge._check_retreat_conditions()
	assert_eq(_retreat_judge.get_danger_count(), 2, "Should have 2 dangers initially")

	# Act — restore magic but health still low
	_vehicle_attr.set_magic_for_test(50.0)
	_retreat_judge._check_retreat_conditions()

	# Assert — warning still active but with single reason
	assert_true(_retreat_judge.is_warning_active(), "Warning should still be active")
	assert_eq(_retreat_judge.get_danger_count(), 1, "Should have 1 danger now")
	assert_eq(_retreat_judge.current_retreat_state, _retreat_judge.RetreatReason.HEALTH_CRITICAL, "State should be HEALTH_CRITICAL")

# === 信号不重复发射测试 ===

func test_no_signal_repeat_on_same_state() -> void:
	# Arrange
	_vehicle_attr.set_health_for_test(15.0)

	var signal_count: int = 0
	GlobalSignals.retreat_threshold_reached.connect(func(_p_reason: String):
		signal_count += 1
	)

	# Act — check twice with same conditions
	_retreat_judge._check_retreat_conditions()
	_retreat_judge._check_retreat_conditions()

	# Assert — should only emit once (no state change on second check)
	assert_eq(signal_count, 1, "Should only emit signal once for same state")

func test_no_clear_signal_without_warning() -> void:
	# Arrange — no warning active
	_vehicle_attr.set_health_for_test(50.0)
	_vehicle_attr.set_magic_for_test(50.0)
	_time_system.set_time(10 * 3600)  # DAY

	var signal_count: int = 0
	GlobalSignals.retreat_warning_cleared.connect(func():
		signal_count += 1
	)

	# Act — check when no warning
	_retreat_judge._check_retreat_conditions()

	# Assert — no signal should emit
	assert_eq(signal_count, 0, "Should not emit cleared signal when no warning was active")

# === 局部信号测试 ===

func test_local_warning_triggered_signal_emitted() -> void:
	# Arrange
	_vehicle_attr.set_health_for_test(15.0)

	var signal_emitted: bool = false
	var reason: int = -1
	_retreat_judge.retreat_warning_triggered.connect(func(p_reason: int):
		signal_emitted = true
		reason = p_reason
	)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(signal_emitted, "Local signal should emit")
	assert_eq(reason, _retreat_judge.RetreatReason.HEALTH_CRITICAL, "Local signal reason should match")

func test_local_warning_resolved_signal_emitted() -> void:
	# Arrange — trigger then clear
	_vehicle_attr.set_health_for_test(15.0)
	_retreat_judge._check_retreat_conditions()

	var signal_emitted: bool = false
	_retreat_judge.retreat_warning_resolved.connect(func():
		signal_emitted = true
	)

	# Act
	_vehicle_attr.set_health_for_test(50.0)
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(signal_emitted, "Local resolved signal should emit")

# === 公共 API 测试 ===

func test_get_retreat_state() -> void:
	_vehicle_attr.set_health_for_test(15.0)
	_retreat_judge._check_retreat_conditions()

	assert_eq(_retreat_judge.get_retreat_state(), _retreat_judge.RetreatReason.HEALTH_CRITICAL, "get_retreat_state should return current state")

func test_get_active_reasons() -> void:
	_vehicle_attr.set_health_for_test(15.0)
	_vehicle_attr.set_magic_for_test(5.0)
	_retreat_judge._check_retreat_conditions()

	var reasons: Array[int] = _retreat_judge.get_active_reasons()
	assert_eq(reasons.size(), 2, "Should return 2 reasons")

func test_get_danger_count() -> void:
	_vehicle_attr.set_health_for_test(15.0)
	_vehicle_attr.set_magic_for_test(5.0)
	_time_system.set_time(20 * 3600)  # NIGHT
	_retreat_judge._check_retreat_conditions()

	assert_eq(_retreat_judge.get_danger_count(), 3, "Should count 3 dangers")

# === 依赖注入测试 ===

func test_set_dependencies_method_exists() -> void:
	assert_true(_retreat_judge.has_method("set_dependencies"), "set_dependencies should exist")

# === 信号存在性测试 ===

func test_retreat_warning_triggered_signal_exists() -> void:
	assert_true(_retreat_judge.has_signal("retreat_warning_triggered"), "retreat_warning_triggered signal should exist")

func test_retreat_warning_resolved_signal_exists() -> void:
	assert_true(_retreat_judge.has_signal("retreat_warning_resolved"), "retreat_warning_resolved signal should exist")

func test_global_retreat_threshold_reached_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("retreat_threshold_reached"), "GlobalSignals.retreat_threshold_reached should exist")

func test_global_retreat_warning_cleared_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("retreat_warning_cleared"), "GlobalSignals.retreat_warning_cleared should exist")

# === 测试辅助方法测试 ===

func test_force_trigger_warning_method_exists() -> void:
	assert_true(_retreat_judge.has_method("force_trigger_warning"), "force_trigger_warning should exist")

func test_force_clear_warning_method_exists() -> void:
	assert_true(_retreat_judge.has_method("force_clear_warning"), "force_clear_warning should exist")

func test_force_trigger_warning_works() -> void:
	var signal_emitted: bool = false
	GlobalSignals.retreat_threshold_reached.connect(func(_p_reason: String):
		signal_emitted = true
	)

	_retreat_judge.force_trigger_warning(_retreat_judge.RetreatReason.HEALTH_CRITICAL)

	assert_true(signal_emitted, "force_trigger_warning should emit signal")
	assert_eq(_retreat_judge.current_retreat_state, _retreat_judge.RetreatReason.HEALTH_CRITICAL, "State should be set")

func test_force_clear_warning_works() -> void:
	# Arrange — set warning state
	_retreat_judge.force_trigger_warning(_retreat_judge.RetreatReason.HEALTH_CRITICAL)

	var signal_emitted: bool = false
	GlobalSignals.retreat_warning_cleared.connect(func():
		signal_emitted = true
	)

	_retreat_judge.force_clear_warning()

	assert_true(signal_emitted, "force_clear_warning should emit signal")
	assert_false(_retreat_judge.is_warning_active(), "Warning should be cleared")

# === 边界测试 ===

func test_health_just_below_threshold() -> void:
	# Arrange — health = 19.9% (just below 20%)
	_vehicle_attr.set_health_for_test(19.9)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Should trigger at 19.9%")

func test_magic_just_below_threshold() -> void:
	# Arrange — magic = 9.9% (just below 10%)
	_vehicle_attr.set_magic_for_test(9.9)
	_vehicle_attr.set_health_for_test(50.0)

	# Act
	_retreat_judge._check_retreat_conditions()

	# Assert
	assert_true(_retreat_judge.is_warning_active(), "Should trigger at 9.9% magic")

# === 状态转换顺序测试 ===

func test_priority_order_health_before_magic() -> void:
	# Arrange — both health and magic low, health is primary (more critical)
	_vehicle_attr.set_health_for_test(15.0)
	_vehicle_attr.set_magic_for_test(5.0)
	_time_system.set_time(10 * 3600)  # DAY

	# Act
	_retreat_judge._check_retreat_conditions()

	# When single reason, should return first detected
	# When multiple, should return MULTIPLE
	var reasons: Array[int] = _retreat_judge.get_active_reasons()
	assert_true(reasons.has(_retreat_judge.RetreatReason.HEALTH_CRITICAL), "Should include HEALTH_CRITICAL")
	assert_true(reasons.has(_retreat_judge.RetreatReason.MAGIC_DEPLETED), "Should include MAGIC_DEPLETED")