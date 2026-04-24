# vehicle_loading_test.gd
# Unit tests for Story: Vehicle Definition Loading

extends GutTest

const VehicleTypeDBScript := preload("res://src/database/vehicle_type_db.gd")

var _vehicle_db: Object

func before_all() -> void:
	_vehicle_db = VehicleTypeDBScript.new()
	add_child_autoqfree(_vehicle_db)

func test_vehicle_stats_valid_id() -> void:
	var stats: Object = _vehicle_db.get_vehicle_stats(1)
	assert_not_null(stats, "Vehicle 1 should exist")

func test_vehicle_stats_properties() -> void:
	var stats: Object = _vehicle_db.get_vehicle_stats(1)
	assert_gt(stats.max_health, 0, "max_health positive")
	assert_gt(stats.armor, 0, "armor non-negative")
	assert_gt(stats.magic_pool, 0, "magic_pool positive")
	assert_gt(stats.max_speed, 0, "max_speed positive")
	assert_gt(stats.acceleration_rate, 0, "acceleration_rate positive")

func test_state_machine_enum() -> void:
	assert_true(VehicleTypeDBScript.VehicleState.GARAGE_IDLE in range(5), "GARAGE_IDLE valid")
	assert_true(VehicleTypeDBScript.VehicleState.DEPLOYABLE in range(5), "DEPLOYABLE valid")
	assert_true(VehicleTypeDBScript.VehicleState.DEPLOYED in range(5), "DEPLOYED valid")
	assert_true(VehicleTypeDBScript.VehicleState.DISABLED in range(5), "DISABLED valid")
	assert_true(VehicleTypeDBScript.VehicleState.DESTROYED in range(5), "DESTROYED valid")

func test_disabled_threshold() -> void:
	assert_eq(_vehicle_db.DISABLED_THRESHOLD, 0.2, "Disabled threshold = 20%")

func test_destroyed_threshold() -> void:
	assert_eq(_vehicle_db.DESTROYED_THRESHOLD, 0.0, "Destroyed threshold = 0%")

func test_calculate_state_deployed() -> void:
	var state: int = _vehicle_db.calculate_state(1.0)
	assert_eq(state, VehicleTypeDBScript.VehicleState.DEPLOYED, "100% health = DEPLOYED")

func test_calculate_state_disabled() -> void:
	var state: int = _vehicle_db.calculate_state(0.1)
	assert_eq(state, VehicleTypeDBScript.VehicleState.DISABLED, "10% health = DISABLED")

func test_calculate_state_destroyed() -> void:
	var state: int = _vehicle_db.calculate_state(0.0)
	assert_eq(state, VehicleTypeDBScript.VehicleState.DESTROYED, "0% health = DESTROYED")

func test_invalid_vehicle_returns_null() -> void:
	var stats: Object = _vehicle_db.get_vehicle_stats(999)
	assert_null(stats, "Invalid vehicle ID returns null")

func test_can_transition_deployed_to_disabled() -> void:
	var can: bool = _vehicle_db.can_transition(VehicleTypeDBScript.VehicleState.DEPLOYED, VehicleTypeDBScript.VehicleState.DISABLED)
	assert_true(can, "DEPLOYED → DISABLED allowed")

func test_can_transition_disabled_to_destroyed() -> void:
	var can: bool = _vehicle_db.can_transition(VehicleTypeDBScript.VehicleState.DISABLED, VehicleTypeDBScript.VehicleState.DESTROYED)
	assert_true(can, "DISABLED → DESTROYED allowed")

func test_cannot_transition_destroyed() -> void:
	var can: bool = _vehicle_db.can_transition(VehicleTypeDBScript.VehicleState.DESTROYED, VehicleTypeDBScript.VehicleState.DEPLOYED)
	assert_false(can, "DESTROYED cannot transition")