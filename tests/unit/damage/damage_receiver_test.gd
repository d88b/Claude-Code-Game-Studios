# damage_receiver_test.gd
# Unit tests for Story: Damage Receiver System
# tests/unit/damage/damage_receiver_test.gd

extends GutTest

const DamageReceiverScript := preload("res://src/damage/damage_receiver.gd")
const VehicleAttributeScript := preload("res://src/core/vehicle_attribute.gd")
const VehicleTypeDBScript := preload("res://src/database/vehicle_type_db.gd")

var _damage_receiver: Object
var _vehicle_attr: Object

# === Setup ===

func before_each() -> void:
	# 创建 VehicleAttribute
	_vehicle_attr = VehicleAttributeScript.new()
	add_child_autoqfree(_vehicle_attr)
	_vehicle_attr.set_dependencies(VehicleTypeDB, GlobalSignals)
	_vehicle_attr.initialize(1)

	# 创建 DamageReceiver
	_damage_receiver = DamageReceiverScript.new()
	add_child_autoqfree(_damage_receiver)
	_damage_receiver.set_dependencies(_vehicle_attr, VehicleTypeDB, GlobalSignals)
	_damage_receiver.initialize(1)

# === 常量验证 ===

func test_max_armor_reduction_is_80_percent() -> void:
	assert_eq(_damage_receiver.MAX_ARMOR_REDUCTION, 0.80, "MAX_ARMOR_REDUCTION should be 0.80")

func test_minimum_damage_is_1() -> void:
	assert_eq(_damage_receiver.MINIMUM_DAMAGE, 1, "MINIMUM_DAMAGE should be 1")

func test_collision_armor_effectiveness_is_50_percent() -> void:
	assert_eq(_damage_receiver.COLLISION_ARMOR_EFFECTIVENESS, 0.50, "COLLISION_ARMOR_EFFECTIVENESS should be 0.50")

# === 初始化测试 ===

func test_initialize_from_vehicle_type() -> void:
	# Arrange
	_damage_receiver.initialize(1)  # 基础战车 armor=5

	# Assert
	assert_eq(_damage_receiver.vehicle_id, 1, "vehicle_id should be 1")
	assert_eq(_damage_receiver.armor, 5.0, "armor should be 5 from VehicleTypeDB")

func test_initialize_heavy_vehicle() -> void:
	# Arrange
	_damage_receiver.initialize(2)  # 重甲战车 armor=15

	# Assert
	assert_eq(_damage_receiver.vehicle_id, 2, "vehicle_id should be 2")
	assert_eq(_damage_receiver.armor, 15.0, "heavy vehicle armor should be 15")

func test_initialize_fast_vehicle() -> void:
	# Arrange
	_damage_receiver.initialize(3)  # 快速战车 armor=2

	# Assert
	assert_eq(_damage_receiver.vehicle_id, 3, "vehicle_id should be 3")
	assert_eq(_damage_receiver.armor, 2.0, "fast vehicle armor should be 2")

# === 伤害计算测试 ===

func test_calculate_actual_damage_no_armor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)
	var source_type: int = DamageReceiverScript.DamageSourceType.ENEMY_MELEE

	# Act
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 50.0)

	# Assert — armor=0 → no reduction → actual=50
	assert_eq(actual, 50.0, "No armor should result in full damage")

func test_calculate_actual_damage_light_armor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(20.0)  # 20% reduction
	var source_type: int = DamageReceiverScript.DamageSourceType.ENEMY_MELEE

	# Act
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 50.0)

	# Assert — 20 armor = 20% reduction → actual = 50 * 0.80 = 40
	assert_eq(actual, 40.0, "20% armor reduction should result in 40 damage")

func test_calculate_actual_damage_medium_armor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(50.0)  # 50% reduction
	var source_type: int = DamageReceiverScript.DamageSourceType.ENEMY_MELEE

	# Act
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 50.0)

	# Assert — 50 armor = 50% reduction → actual = 50 * 0.50 = 25
	assert_eq(actual, 25.0, "50% armor reduction should result in 25 damage")

func test_calculate_actual_damage_heavy_armor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(80.0)  # 80% reduction (max)
	var source_type: int = DamageReceiverScript.DamageSourceType.ENEMY_MELEE

	# Act
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 50.0)

	# Assert — 80 armor = 80% reduction (max) → actual = 50 * 0.20 = 10
	assert_eq(actual, 10.0, "80% armor reduction should result in 10 damage")

func test_calculate_actual_damage_armor_exceeds_cap() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(95.0)  # Exceeds max 80%
	var source_type: int = DamageReceiverScript.DamageSourceType.ENEMY_MELEE

	# Act
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 50.0)

	# Assert — clamped to 80% reduction → actual = 50 * 0.20 = 10
	assert_eq(actual, 10.0, "Armor exceeding cap should be clamped to 80% reduction")

func test_calculate_actual_damage_minimum_floor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(80.0)
	var source_type: int = DamageReceiverScript.DamageSourceType.ENEMY_MELEE

	# Act — raw=5, after 80% reduction = 1, floor = 1
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 5.0)

	# Assert
	assert_eq(actual, 1.0, "Minimum damage floor should be 1")

func test_calculate_actual_damage_below_floor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(80.0)
	var source_type: int = DamageReceiverScript.DamageSourceType.ENEMY_MELEE

	# Act — raw=3, after 80% reduction = 0.6, floor to 1
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 3.0)

	# Assert
	assert_eq(actual, 1.0, "Damage below floor should be clamped to 1")

# === 碰撞伤害测试 ===

func test_calculate_collision_damage_no_armor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)
	var source_type: int = DamageReceiverScript.DamageSourceType.COLLISION_IMPACT

	# Act
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 10.0)

	# Assert — no armor → full collision damage
	assert_eq(actual, 10.0, "No armor collision should result in full damage")

func test_calculate_collision_damage_heavy_armor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(80.0)  # 80% armor, 50% effective for collision
	var source_type: int = DamageReceiverScript.DamageSourceType.COLLISION_IMPACT

	# Act — effective_armor = 80 * 0.50 = 40 → 40% reduction → actual = 10 * 0.60 = 6
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 10.0)

	# Assert
	assert_eq(actual, 6.0, "Collision with 80 armor (50% effective) should result in 6 damage")

func test_calculate_collision_damage_medium_armor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(50.0)  # 50% armor, 50% effective = 25% reduction
	var source_type: int = DamageReceiverScript.DamageSourceType.COLLISION_IMPACT

	# Act — effective_armor = 50 * 0.50 = 25 → 25% reduction → actual = 20 * 0.75 = 15
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 20.0)

	# Assert
	assert_eq(actual, 15.0, "Collision with 50 armor should result in 15 damage")

# === 环境伤害测试 ===

func test_calculate_environment_damage_bypasses_armor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(80.0)  # Heavy armor
	var source_type: int = DamageReceiverScript.DamageSourceType.ENVIRONMENT

	# Act
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 50.0)

	# Assert — environment damage bypasses armor
	assert_eq(actual, 50.0, "Environment damage should bypass armor")

func test_calculate_environment_damage_minimum_floor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(80.0)
	var source_type: int = DamageReceiverScript.DamageSourceType.ENVIRONMENT

	# Act
	var actual: float = _damage_receiver.calculate_actual_damage(source_type, 0.5)

	# Assert — minimum floor still applies
	assert_eq(actual, 1.0, "Environment damage below floor should be clamped to 1")

# === receive_damage 测试 ===

func test_receive_damage_applies_to_vehicle_attribute() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(20.0)  # 20% reduction
	var initial_health: float = _vehicle_attr.current_health

	# Act
	var actual: float = _damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 50.0)

	# Assert
	assert_eq(actual, 40.0, "Actual damage should be 40")
	assert_eq(_vehicle_attr.current_health, initial_health - 40.0, "Health should be reduced by actual damage")

func test_receive_damage_zero_skipped() -> void:
	# Arrange
	var initial_health: float = _vehicle_attr.current_health

	# Act
	var actual: float = _damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 0.0)

	# Assert
	assert_eq(actual, 0.0, "Zero damage should return 0")
	assert_eq(_vehicle_attr.current_health, initial_health, "Health should not change")

func test_receive_damage_negative_skipped() -> void:
	# Arrange
	var initial_health: float = _vehicle_attr.current_health

	# Act
	var actual: float = _damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, -10.0)

	# Assert
	assert_eq(actual, 0.0, "Negative damage should return 0")
	assert_eq(_vehicle_attr.current_health, initial_health, "Health should not change")

# === 状态转换测试 ===

func test_damage_triggers_disabled_state() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)  # No armor for predictable damage
	# VehicleAttribute max_health = 100, DISABLED threshold = 20%

	# Act — damage to bring health below 20% (health < 20)
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 85.0)

	# Assert
	var state: int = _vehicle_attr.get_current_state()
	assert_eq(state, VehicleTypeDBScript.VehicleState.DISABLED, "State should be DISABLED at 15% health")

func test_damage_triggers_destroyed_state() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)

	# Act — damage to bring health to 0
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 100.0)

	# Assert
	var state: int = _vehicle_attr.get_current_state()
	assert_eq(state, VehicleTypeDBScript.VehicleState.DESTROYED, "State should be DESTROYED at 0 health")

func test_damage_rejected_on_disabled_vehicle() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 100.0)  # DESTROYED
	var health_after_destroyed: float = _vehicle_attr.current_health

	# Act — try to damage destroyed vehicle
	var actual: float = _damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 50.0)

	# Assert
	assert_eq(actual, 0.0, "Damage should be rejected on destroyed vehicle")
	assert_eq(_vehicle_attr.current_health, health_after_destroyed, "Health should not change")

# === GlobalSignals 测试 ===

func test_receive_damage_emits_global_vehicle_damaged() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)
	var signal_emitted: bool = false
	var damage_amount: float = 0.0
	GlobalSignals.vehicle_damaged.connect(func(amount: float):
		signal_emitted = true
		damage_amount = amount
	)

	# Act
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 25.0)

	# Assert
	assert_true(signal_emitted, "GlobalSignals.vehicle_damaged should emit")
	assert_eq(damage_amount, 25.0, "Damage amount should match")

func test_damage_triggers_global_vehicle_destroyed() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)
	var signal_emitted: bool = false
	var destroyed_id: int = -1
	GlobalSignals.vehicle_destroyed.connect(func(vehicle_id: int):
		signal_emitted = true
		destroyed_id = vehicle_id
	)

	# Act
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 100.0)

	# Assert
	assert_true(signal_emitted, "GlobalSignals.vehicle_destroyed should emit")
	assert_eq(destroyed_id, 1, "Destroyed vehicle_id should be 1")

# === 局部信号测试 ===

func test_damage_received_signal_emitted() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(20.0)
	var signal_emitted: bool = false
	var source_type: int = -1
	var raw: float = 0.0
	var actual: float = 0.0
	_damage_receiver.damage_received.connect(func(p_source: int, p_raw: float, p_actual: float):
		signal_emitted = true
		source_type = p_source
		raw = p_raw
		actual = p_actual
	)

	# Act
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 50.0)

	# Assert
	assert_true(signal_emitted, "damage_received signal should emit")
	assert_eq(source_type, DamageReceiverScript.DamageSourceType.ENEMY_MELEE, "Source type should match")
	assert_eq(raw, 50.0, "Raw damage should match")
	assert_eq(actual, 40.0, "Actual damage should match (after 20% reduction)")

func test_armor_effective_signal_emitted() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(20.0)  # Blocks 10 damage
	var signal_emitted: bool = false
	var blocked: float = 0.0
	_damage_receiver.armor_effective.connect(func(p_blocked: float):
		signal_emitted = true
		blocked = p_blocked
	)

	# Act
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 50.0)

	# Assert
	assert_true(signal_emitted, "armor_effective signal should emit when armor blocks damage")
	assert_eq(blocked, 10.0, "Blocked damage should be 10 (20% of 50)")

func test_armor_effective_no_signal_zero_block() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)  # No armor, no block
	var signal_count: int = 0
	_damage_receiver.armor_effective.connect(func(_p_blocked: float):
		signal_count += 1
	)

	# Act
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 50.0)

	# Assert
	assert_eq(signal_count, 0, "armor_effective should NOT emit when no damage blocked")

# === 辅助查询测试 ===

func test_get_armor() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(25.0)

	# Act
	var armor: float = _damage_receiver.get_armor()

	# Assert
	assert_eq(armor, 25.0, "get_armor should return current armor")

func test_get_max_armor_reduction() -> void:
	assert_eq(_damage_receiver.get_max_armor_reduction(), 0.80, "get_max_armor_reduction should return 0.80")

func test_get_minimum_damage() -> void:
	assert_eq(_damage_receiver.get_minimum_damage(), 1, "get_minimum_damage should return 1")

# === 边界测试 ===

func test_boundary_at_disabled_threshold() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)
	# VehicleAttribute max_health = 100, DISABLED threshold = 20% (< 20 health)

	# Act — damage to 20 health (exactly at threshold, should NOT be DISABLED)
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 80.0)

	# Assert — 20% exactly is still DEPLOYED
	var state: int = _vehicle_attr.get_current_state()
	assert_eq(state, VehicleTypeDBScript.VehicleState.DEPLOYED, "At exactly 20% should still be DEPLOYED")

func test_boundary_below_disabled_threshold() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)

	# Act — damage to 19 health (below threshold)
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 81.0)

	# Assert
	var state: int = _vehicle_attr.get_current_state()
	assert_eq(state, VehicleTypeDBScript.VehicleState.DISABLED, "Below 20% should be DISABLED")

func test_accumulated_damage_crosses_multiple_thresholds() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(0.0)

	# Act — single large damage from 100% to 0%
	_damage_receiver.receive_damage(DamageReceiverScript.DamageSourceType.ENEMY_MELEE, 100.0)

	# Assert — should be DESTROYED, not DISABLED
	var state: int = _vehicle_attr.get_current_state()
	assert_eq(state, VehicleTypeDBScript.VehicleState.DESTROYED, "Should transition directly to DESTROYED")

# === 依赖注入测试 ===

func test_set_dependencies_method_exists() -> void:
	assert_true(_damage_receiver.has_method("set_dependencies"), "set_dependencies should exist")

func test_initialize_method_exists() -> void:
	assert_true(_damage_receiver.has_method("initialize"), "initialize should exist")

# === 信号存在性测试 ===

func test_damage_received_signal_exists() -> void:
	assert_true(_damage_receiver.has_signal("damage_received"), "damage_received signal should exist")

func test_armor_effective_signal_exists() -> void:
	assert_true(_damage_receiver.has_signal("armor_effective"), "armor_effective signal should exist")

# === 测试辅助方法测试 ===

func test_set_armor_for_test_method_exists() -> void:
	assert_true(_damage_receiver.has_method("set_armor_for_test"), "set_armor_for_test should exist")

func test_set_armor_for_test_works() -> void:
	# Arrange
	_damage_receiver.set_armor_for_test(50.0)

	# Act
	var armor: float = _damage_receiver.get_armor()

	# Assert
	assert_eq(armor, 50.0, "set_armor_for_test should update armor value")