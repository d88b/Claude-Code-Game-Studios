# vehicle_attribute_test.gd
# Unit tests for Story: Vehicle Attribute State
# tests/unit/vehicleattr/vehicle_attribute_test.gd

extends GutTest

const VehicleAttributeScript := preload("res://src/core/vehicle_attribute.gd")
const VehicleTypeDBScript := preload("res://src/database/vehicle_type_db.gd")

var _vehicle_attr: Object

# === Setup ===

func before_each() -> void:
	# 创建 VehicleAttribute
	_vehicle_attr = VehicleAttributeScript.new()
	add_child_autoqfree(_vehicle_attr)

	# 注入依赖（使用全局 autoload）
	_vehicle_attr.set_dependencies(VehicleTypeDB, GlobalSignals)

# === 初始化测试 ===

func test_initialization_from_vehicle_type() -> void:
	# Arrange
	_vehicle_attr.initialize(1)

	# Assert
	assert_eq(_vehicle_attr.vehicle_id, 1, "vehicle_id should be 1")
	assert_eq(_vehicle_attr.max_health, 100.0, "max_health should be 100")
	assert_eq(_vehicle_attr.max_magic, 100.0, "max_magic should be 100")
	assert_eq(_vehicle_attr.current_health, 100.0, "current_health should start at max")
	assert_eq(_vehicle_attr.current_magic, 100.0, "current_magic should start at max")

func test_initialization_heavy_vehicle() -> void:
	# Arrange
	_vehicle_attr.initialize(2)  # 重甲战车

	# Assert
	assert_eq(_vehicle_attr.vehicle_id, 2, "vehicle_id should be 2")
	assert_eq(_vehicle_attr.max_health, 200.0, "heavy vehicle max_health should be 200")
	assert_eq(_vehicle_attr.max_magic, 80.0, "heavy vehicle max_magic should be 80")

func test_initialization_fast_vehicle() -> void:
	# Arrange
	_vehicle_attr.initialize(3)  # 快速战车

	# Assert
	assert_eq(_vehicle_attr.vehicle_id, 3, "vehicle_id should be 3")
	assert_eq(_vehicle_attr.max_health, 80.0, "fast vehicle max_health should be 80")
	assert_eq(_vehicle_attr.max_magic, 120.0, "fast vehicle max_magic should be 120")

# === 常量验证测试 ===

func test_disabled_threshold_is_20_percent() -> void:
	assert_eq(_vehicle_attr.DISABLED_HEALTH_THRESHOLD, 0.20, "DISABLED threshold should be 20%")

func test_destroyed_threshold_is_0() -> void:
	assert_eq(_vehicle_attr.DESTROYED_HEALTH_THRESHOLD, 0.0, "DESTROYED threshold should be 0")

func test_magic_depletion_threshold_is_10_percent() -> void:
	assert_eq(_vehicle_attr.MAGIC_DEPLETION_THRESHOLD, 0.10, "Magic depletion threshold should be 10%")

# === 伤害测试 ===

func test_take_damage_reduces_health() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	var initial_health: float = _vehicle_attr.current_health

	# Act
	_vehicle_attr.take_damage(25.0)

	# Assert
	assert_eq(_vehicle_attr.current_health, initial_health - 25.0, "Health should be reduced by damage")

func test_take_damage_does_not_go_negative() -> void:
	# Arrange
	_vehicle_attr.initialize(1)

	# Act
	_vehicle_attr.take_damage(150.0)  # More than max_health

	# Assert
	assert_eq(_vehicle_attr.current_health, 0.0, "Health should not go negative")

func test_take_damage_zero_ignored() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	var initial_health: float = _vehicle_attr.current_health

	# Act
	_vehicle_attr.take_damage(0.0)

	# Assert
	assert_eq(_vehicle_attr.current_health, initial_health, "Zero damage should be ignored")

func test_take_damage_negative_ignored() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	var initial_health: float = _vehicle_attr.current_health

	# Act
	_vehicle_attr.take_damage(-10.0)

	# Assert
	assert_eq(_vehicle_attr.current_health, initial_health, "Negative damage should be ignored")

# === 耐久度比例测试 ===

func test_durability_ratio_calculation() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.take_damage(25.0)  # 75/100

	# Act
	var ratio: float = _vehicle_attr.get_durability_ratio()

	# Assert
	assert_eq(ratio, 0.75, "Ratio should be 75%")

func test_durability_ratio_full_health() -> void:
	# Arrange
	_vehicle_attr.initialize(1)

	# Act
	var ratio: float = _vehicle_attr.get_durability_ratio()

	# Assert
	assert_eq(ratio, 1.0, "Full health ratio should be 1.0")

func test_durability_ratio_zero_health() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_health_for_test(0.0)

	# Act
	var ratio: float = _vehicle_attr.get_durability_ratio()

	# Assert
	assert_eq(ratio, 0.0, "Zero health ratio should be 0.0")

func test_durability_ratio_clamps_to_range() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_health_for_test(150.0)  # Over max

	# Act
	var ratio: float = _vehicle_attr.get_durability_ratio()

	# Assert
	assert_eq(ratio, 1.0, "Ratio should clamp to 1.0 max")

func test_durability_ratio_zero_max_health() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.max_health = 0.0

	# Act
	var ratio: float = _vehicle_attr.get_durability_ratio()

	# Assert
	assert_eq(ratio, 0.0, "Ratio should be 0.0 when max_health is 0")

# === 状态转换测试 ===

func test_disabled_threshold_transition() -> void:
	# Arrange
	_vehicle_attr.initialize(1)  # max_health = 100
	# 需要 health < 20%，即 health < 20

	# Act
	_vehicle_attr.take_damage(81.0)  # health = 19 (19%)

	# Assert
	var state: int = _vehicle_attr.get_current_state()
	assert_eq(state, VehicleTypeDBScript.VehicleState.DISABLED, "State should be DISABLED at 19%")

func test_destroyed_threshold_transition() -> void:
	# Arrange
	_vehicle_attr.initialize(1)

	# Act
	_vehicle_attr.take_damage(100.0)  # health = 0

	# Assert
	var state: int = _vehicle_attr.get_current_state()
	assert_eq(state, VehicleTypeDBScript.VehicleState.DESTROYED, "State should be DESTROYED at 0%")

func test_no_state_change_above_threshold() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.take_damage(10.0)  # 90% health, still DEPLOYED

	# Assert
	var state: int = _vehicle_attr.get_current_state()
	assert_eq(state, VehicleTypeDBScript.VehicleState.DEPLOYED, "State should stay DEPLOYED above 20%")

func test_repair_from_disabled_to_deployed() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.take_damage(85.0)  # health = 15, DISABLED

	# Act
	_vehicle_attr.repair(30.0)  # health = 45, > 20%

	# Assert
	var state: int = _vehicle_attr.get_current_state()
	assert_eq(state, VehicleTypeDBScript.VehicleState.DEPLOYED, "Repair should restore to DEPLOYED")

func test_boundary_at_20_percent_stays_deployed() -> void:
	# Arrange
	_vehicle_attr.initialize(1)  # max_health = 100
	# health = 20 exactly (20%)

	# Act
	_vehicle_attr.take_damage(80.0)  # health = 20

	# Assert
	var state: int = _vehicle_attr.get_current_state()
	assert_eq(state, VehicleTypeDBScript.VehicleState.DEPLOYED, "State should be DEPLOYED at exactly 20%")

# === 魔能消耗测试 ===

func test_consume_magic_success() -> void:
	# Arrange
	_vehicle_attr.initialize(1)  # max_magic = 100

	# Act
	var success: bool = _vehicle_attr.consume_magic(30.0)

	# Assert
	assert_true(success, "Consume should succeed")
	assert_eq(_vehicle_attr.current_magic, 70.0, "Magic should be reduced")

func test_consume_magic_failure_when_depleted() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(10.0)  # Only 10 magic left

	# Act
	var success: bool = _vehicle_attr.consume_magic(50.0)  # Need 50

	# Assert
	assert_false(success, "Consume should fail when insufficient")
	assert_eq(_vehicle_attr.current_magic, 10.0, "Magic should not change")

func test_consume_magic_exact_amount() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(50.0)

	# Act
	var success: bool = _vehicle_attr.consume_magic(50.0)

	# Assert
	assert_true(success, "Consume exact amount should succeed")
	assert_eq(_vehicle_attr.current_magic, 0.0, "Magic should be zero")

func test_consume_magic_zero_allowed() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	var initial_magic: float = _vehicle_attr.current_magic

	# Act
	var success: bool = _vehicle_attr.consume_magic(0.0)

	# Assert
	assert_true(success, "Zero consume should succeed")
	assert_eq(_vehicle_attr.current_magic, initial_magic, "Magic unchanged for zero consume")

# === 魔能恢复测试 ===

func test_replenish_magic() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.consume_magic(50.0)  # magic = 50

	# Act
	_vehicle_attr.replenish_magic(30.0)

	# Assert
	assert_eq(_vehicle_attr.current_magic, 80.0, "Magic should increase")

func test_replenish_magic_caps_at_max() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.consume_magic(10.0)  # magic = 90

	# Act
	_vehicle_attr.replenish_magic(50.0)  # Would go to 140, capped at 100

	# Assert
	assert_eq(_vehicle_attr.current_magic, 100.0, "Magic should cap at max")

func test_replenish_magic_zero_ignored() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.consume_magic(50.0)
	var current: float = _vehicle_attr.current_magic

	# Act
	_vehicle_attr.replenish_magic(0.0)

	# Assert
	assert_eq(_vehicle_attr.current_magic, current, "Zero replenish should be ignored")

# === 魔能比例测试 ===

func test_magic_ratio_calculation() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.consume_magic(30.0)  # magic = 70

	# Act
	var ratio: float = _vehicle_attr.get_magic_energy_ratio()

	# Assert
	assert_eq(ratio, 0.70, "Magic ratio should be 70%")

func test_magic_ratio_full() -> void:
	# Arrange
	_vehicle_attr.initialize(1)

	# Act
	var ratio: float = _vehicle_attr.get_magic_energy_ratio()

	# Assert
	assert_eq(ratio, 1.0, "Full magic ratio should be 1.0")

func test_magic_ratio_zero() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(0.0)

	# Act
	var ratio: float = _vehicle_attr.get_magic_energy_ratio()

	# Assert
	assert_eq(ratio, 0.0, "Zero magic ratio should be 0.0")

func test_magic_ratio_clamps_to_range() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(150.0)

	# Act
	var ratio: float = _vehicle_attr.get_magic_energy_ratio()

	# Assert
	assert_eq(ratio, 1.0, "Ratio should clamp to 1.0 max")

func test_magic_ratio_zero_max_magic() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.max_magic = 0.0

	# Act
	var ratio: float = _vehicle_attr.get_magic_energy_ratio()

	# Assert
	assert_eq(ratio, 0.0, "Ratio should be 0.0 when max_magic is 0")

func test_is_magic_depleted_threshold() -> void:
	# Arrange
	_vehicle_attr.initialize(1)  # max_magic = 100
	_vehicle_attr.set_magic_for_test(9.0)  # 9% < 10%

	# Act
	var depleted: bool = _vehicle_attr.is_magic_depleted()

	# Assert
	assert_true(depleted, "Should be depleted below 10% threshold")

func test_is_magic_not_depleted_above_threshold() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(15.0)  # 15% > 10%

	# Act
	var depleted: bool = _vehicle_attr.is_magic_depleted()

	# Assert
	assert_false(depleted, "Should not be depleted above 10% threshold")

func test_is_magic_not_depleted_at_threshold() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(10.0)  # exactly 10%

	# Act
	var depleted: bool = _vehicle_attr.is_magic_depleted()

	# Assert
	assert_false(depleted, "Should not be depleted at exactly 10%")

func test_can_afford_magic_true() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(50.0)

	# Act
	var can_afford: bool = _vehicle_attr.can_afford_magic(30.0)

	# Assert
	assert_true(can_afford, "Should be able to afford 30 magic")

func test_can_afford_magic_false() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(20.0)

	# Act
	var can_afford: bool = _vehicle_attr.can_afford_magic(30.0)

	# Assert
	assert_false(can_afford, "Should not be able to afford 30 magic")

func test_can_afford_magic_exact() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(30.0)

	# Act
	var can_afford: bool = _vehicle_attr.can_afford_magic(30.0)

	# Assert
	assert_true(can_afford, "Should be able to afford exact amount")

# === 查询 API 测试 ===

func test_get_current_state_returns_int() -> void:
	# Arrange
	_vehicle_attr.initialize(1)

	# Act
	var state: int = _vehicle_attr.get_current_state()

	# Assert
	assert_eq(state, VehicleTypeDBScript.VehicleState.DEPLOYED, "Initial state should be DEPLOYED")

# === 依赖注入测试 ===

func test_set_dependencies_method_exists() -> void:
	assert_true(_vehicle_attr.has_method("set_dependencies"), "set_dependencies should exist")

func test_initialize_method_exists() -> void:
	assert_true(_vehicle_attr.has_method("initialize"), "initialize should exist")

# === 信号测试 ===

func test_health_changed_signal_exists() -> void:
	assert_true(_vehicle_attr.has_signal("health_changed"), "health_changed signal should exist")

func test_magic_changed_signal_exists() -> void:
	assert_true(_vehicle_attr.has_signal("magic_changed"), "magic_changed signal should exist")

func test_state_changed_signal_exists() -> void:
	assert_true(_vehicle_attr.has_signal("state_changed"), "state_changed signal should exist")

# === 测试辅助方法测试 ===

func test_set_health_for_test_method_exists() -> void:
	assert_true(_vehicle_attr.has_method("set_health_for_test"), "set_health_for_test should exist")

func test_set_magic_for_test_method_exists() -> void:
	assert_true(_vehicle_attr.has_method("set_magic_for_test"), "set_magic_for_test should exist")

func test_set_state_for_test_method_exists() -> void:
	assert_true(_vehicle_attr.has_method("set_state_for_test"), "set_state_for_test should exist")

# === GlobalSignals.vehicle_damaged 测试 ===

func test_take_damage_emits_global_signal() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	var signal_emitted: bool = false
	var damage_amount: float = 0.0
	GlobalSignals.vehicle_damaged.connect(func(amount: float):
		signal_emitted = true
		damage_amount = amount
	)

	# Act
	_vehicle_attr.take_damage(25.0)

	# Assert
	assert_true(signal_emitted, "GlobalSignals.vehicle_damaged should emit")
	assert_eq(damage_amount, 25.0, "Damage amount should match")

func test_take_damage_zero_no_global_signal() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	var signal_count: int = 0
	GlobalSignals.vehicle_damaged.connect(func(_amount: float):
		signal_count += 1
	)

	# Act
	_vehicle_attr.take_damage(0.0)

	# Assert
	assert_eq(signal_count, 0, "Zero damage should not emit global signal")

func test_take_damage_negative_no_global_signal() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	var signal_count: int = 0
	GlobalSignals.vehicle_damaged.connect(func(_amount: float):
		signal_count += 1
	)

	# Act
	_vehicle_attr.take_damage(-10.0)

	# Assert
	assert_eq(signal_count, 0, "Negative damage should not emit global signal")

# === GlobalSignals.magic_pool_changed 测试 ===

func test_consume_magic_emits_global_signal() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	var signal_emitted: bool = false
	GlobalSignals.magic_pool_changed.connect(func(_current: float, _max: float):
		signal_emitted = true
	)

	# Act
	_vehicle_attr.consume_magic(25.0)

	# Assert
	assert_true(signal_emitted, "GlobalSignals.magic_pool_changed should emit")

func test_replenish_magic_emits_global_signal() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.consume_magic(50.0)
	var signal_emitted: bool = false
	GlobalSignals.magic_pool_changed.connect(func(_current: float, _max: float):
		signal_emitted = true
	)

	# Act
	_vehicle_attr.replenish_magic(25.0)

	# Assert
	assert_true(signal_emitted, "GlobalSignals.magic_pool_changed should emit")

# === GlobalSignals.vehicle_state_changed 测试 ===

func test_state_transition_emits_global_signal() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	var signal_emitted: bool = false
	var new_state: int = -1
	GlobalSignals.vehicle_state_changed.connect(func(state: int):
		signal_emitted = true
		new_state = state
	)

	# Act
	_vehicle_attr.take_damage(81.0)  # triggers DISABLED

	# Assert
	assert_true(signal_emitted, "GlobalSignals.vehicle_state_changed should emit")
	assert_eq(new_state, VehicleTypeDBScript.VehicleState.DISABLED, "New state should be DISABLED")

# === GlobalSignals.vehicle_destroyed 测试 ===

func test_destroyed_emits_global_signal() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	var signal_emitted: bool = false
	var destroyed_id: int = -1
	GlobalSignals.vehicle_destroyed.connect(func(vehicle_id: int):
		signal_emitted = true
		destroyed_id = vehicle_id
	)

	# Act
	_vehicle_attr.take_damage(100.0)  # triggers DESTROYED

	# Assert
	assert_true(signal_emitted, "GlobalSignals.vehicle_destroyed should emit")
	assert_eq(destroyed_id, 1, "Destroyed vehicle_id should be 1")

# === GlobalSignals.magic_depleted 测试 ===

func test_magic_depleted_signal_exists() -> void:
	assert_true(GlobalSignals.has_signal("magic_depleted"), "magic_depleted signal should exist in GlobalSignals")

func test_consume_magic_crosses_threshold_emits_depleted() -> void:
	# Arrange
	_vehicle_attr.initialize(1)  # max_magic = 100
	_vehicle_attr.set_magic_for_test(15.0)  # 15%, above threshold

	var signal_emitted: bool = false
	GlobalSignals.magic_depleted.connect(func():
		signal_emitted = true
	)

	# Act — consume to cross threshold (15 -> 5, below 10%)
	_vehicle_attr.consume_magic(10.0)

	# Assert
	assert_true(signal_emitted, "magic_depleted should emit when crossing threshold")
	assert_almost_eq(_vehicle_attr.current_magic, 5.0, 0.1, "Magic should be 5 after consumption")

func test_consume_magic_already_depleted_no_signal() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(5.0)  # Already below threshold

	var signal_count: int = 0
	GlobalSignals.magic_depleted.connect(func():
		signal_count += 1
	)

	# Act — consume more (still depleted)
	_vehicle_attr.consume_magic(2.0)

	# Assert — should NOT emit again
	assert_eq(signal_count, 0, "magic_depleted should NOT emit when already depleted")

func test_replenish_magic_above_threshold_clears_depleted() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.set_magic_for_test(5.0)  # Below threshold

	# Act — replenish above threshold
	_vehicle_attr.replenish_magic(20.0)

	# Assert
	assert_false(_vehicle_attr.is_magic_depleted(), "Should not be depleted after replenish")

# === 修复测试 ===

func test_repair_caps_at_max() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.take_damage(10.0)  # health = 90

	# Act
	_vehicle_attr.repair(50.0)  # would go to 140, capped at 100

	# Assert
	assert_eq(_vehicle_attr.current_health, 100.0, "Repair should cap at max_health")

func test_repair_zero_ignored() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.take_damage(30.0)
	var current: float = _vehicle_attr.current_health

	# Act
	_vehicle_attr.repair(0.0)

	# Assert
	assert_eq(_vehicle_attr.current_health, current, "Zero repair should be ignored")

func test_repair_negative_ignored() -> void:
	# Arrange
	_vehicle_attr.initialize(1)
	_vehicle_attr.take_damage(30.0)
	var current: float = _vehicle_attr.current_health

	# Act
	_vehicle_attr.repair(-10.0)

	# Assert
	assert_eq(_vehicle_attr.current_health, current, "Negative repair should be ignored")