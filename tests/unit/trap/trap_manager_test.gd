# trap_manager_test.gd
# TrapManager 测试 — trap-001
## TrapManager 测试
## 验证陷阱类型、配置映射、放置触发逻辑
## QA Plan: production/qa/qa-plan-sprint-5-2026-04-26.md

extends GutTest

# === 测试目标 ===
const TRAP_MANAGER_PATH: String = "res://src/trap/trap_manager.gd"

# === 常量 ===
const TRAP_TYPE_COUNT: int = 4  # SPIKE, SLOW, DAMAGE, EXPLOSIVE

# === 测试实例 ===
var trap_manager: Node = null

func before_each() -> void:
	var script: GDScript = load(TRAP_MANAGER_PATH)
	trap_manager = script.new()
	# 不调用 _ready()（需要场景树和 Autoload）

func after_each() -> void:
	if trap_manager != null and is_instance_valid(trap_manager):
		trap_manager.queue_free()
	trap_manager = null

# === 陷阱类型枚举测试 ===

## 测试陷阱类型枚举值
func test_trap_type_enum_values() -> void:
	assert_eq(trap_manager.TrapType.SPIKE, 0, "SPIKE enum value 0")
	assert_eq(trap_manager.TrapType.SLOW, 1, "SLOW enum value 1")
	assert_eq(trap_manager.TrapType.DAMAGE, 2, "DAMAGE enum value 2")
	assert_eq(trap_manager.TrapType.EXPLOSIVE, 3, "EXPLOSIVE enum value 3")

## 测试陷阱类型数量
func test_trap_type_count() -> void:
	var types: Array = [
		trap_manager.TrapType.SPIKE,
		trap_manager.TrapType.SLOW,
		trap_manager.TrapType.DAMAGE,
		trap_manager.TrapType.EXPLOSIVE
	]
	assert_eq(types.size(), TRAP_TYPE_COUNT, "Should have 4 trap types")

# === 陷阱配置映射测试 ===

## 测试陷阱配置完整性
func test_trap_configs_has_all_types() -> void:
	for trap_type: int in range(TRAP_TYPE_COUNT):
		assert_true(trap_manager.TRAP_CONFIGS.has(trap_type), "TRAP_CONFIGS should have type %d" % trap_type)

## 测试尖刺陷阱配置
func test_spike_trap_config() -> void:
	var config: Dictionary = trap_manager.TRAP_CONFIGS[trap_manager.TrapType.SPIKE]
	assert_eq(config["damage"], 25.0, "SPIKE damage = 25")
	assert_eq(config["slow_mult"], 1.0, "SPIKE slow_mult = 1.0")
	assert_eq(config["trigger_limit"], 3, "SPIKE trigger_limit = 3")
	assert_eq(config["aoe_radius"], 0.0, "SPIKE aoe_radius = 0")

## 测试减速陷阱配置
func test_slow_trap_config() -> void:
	var config: Dictionary = trap_manager.TRAP_CONFIGS[trap_manager.TrapType.SLOW]
	assert_eq(config["damage"], 0.0, "SLOW damage = 0")
	assert_eq(config["slow_mult"], 0.5, "SLOW slow_mult = 0.5")
	assert_eq(config["trigger_limit"], -1, "SLOW trigger_limit = -1 (infinite)")
	assert_eq(config["aoe_radius"], 64.0, "SLOW aoe_radius = 64")

## 测试伤害陷阱配置
func test_damage_trap_config() -> void:
	var config: Dictionary = trap_manager.TRAP_CONFIGS[trap_manager.TrapType.DAMAGE]
	assert_eq(config["damage"], 10.0, "DAMAGE damage = 10")
	assert_eq(config["slow_mult"], 0.8, "DAMAGE slow_mult = 0.8")
	assert_eq(config["duration"], 5.0, "DAMAGE duration = 5s")

## 测试爆炸陷阱配置
func test_explosive_trap_config() -> void:
	var config: Dictionary = trap_manager.TRAP_CONFIGS[trap_manager.TrapType.EXPLOSIVE]
	assert_eq(config["damage"], 60.0, "EXPLOSIVE damage = 60")
	assert_eq(config["trigger_limit"], 1, "EXPLOSIVE trigger_limit = 1 (single use)")
	assert_eq(config["aoe_radius"], 96.0, "EXPLOSIVE aoe_radius = 96")

# === 陷阱名称映射测试 ===

## 测试陷阱名称映射完整性
func test_trap_names_has_all_types() -> void:
	for trap_type: int in range(TRAP_TYPE_COUNT):
		assert_true(trap_manager.TRAP_NAMES.has(trap_type), "TRAP_NAMES should have type %d" % trap_type)

## 测试陷阱名称中文
func test_trap_names_chinese() -> void:
	assert_eq(trap_manager.TRAP_NAMES[trap_manager.TrapType.SPIKE], "尖刺陷阱", "SPIKE name = '尖刺陷阱'")
	assert_eq(trap_manager.TRAP_NAMES[trap_manager.TrapType.SLOW], "减速陷阱", "SLOW name = '减速陷阱'")
	assert_eq(trap_manager.TRAP_NAMES[trap_manager.TrapType.DAMAGE], "伤害陷阱", "DAMAGE name = '伤害陷阱'")
	assert_eq(trap_manager.TRAP_NAMES[trap_manager.TrapType.EXPLOSIVE], "爆炸陷阱", "EXPLOSIVE name = '爆炸陷阱'")

# === 陷阱成本映射测试 ===

## 测试陷阱成本映射完整性
func test_trap_costs_has_all_types() -> void:
	for trap_type: int in range(TRAP_TYPE_COUNT):
		assert_true(trap_manager.TRAP_COSTS.has(trap_type), "TRAP_COSTS should have type %d" % trap_type)

## 测试尖刺陷阱成本
func test_spike_trap_cost() -> void:
	var cost: Dictionary = trap_manager.TRAP_COSTS[trap_manager.TrapType.SPIKE]
	assert_true(cost.has("metal"), "SPIKE cost should have metal")
	assert_eq(cost["metal"], 5, "SPIKE metal cost = 5")

## 测试爆炸陷阱成本
func test_explosive_trap_cost() -> void:
	var cost: Dictionary = trap_manager.TRAP_COSTS[trap_manager.TrapType.EXPLOSIVE]
	assert_eq(cost["metal"], 15, "EXPLOSIVE metal cost = 15")
	assert_eq(cost["fuel"], 10, "EXPLOSIVE fuel cost = 10")

# === API 方法测试 ===

## 测试放置陷阱方法
func test_place_trap_method() -> void:
	assert_true(trap_manager.has_method("place_trap"), "Should have place_trap")

## 测试移除陷阱方法
func test_remove_trap_method() -> void:
	assert_true(trap_manager.has_method("remove_trap"), "Should have remove_trap")

## 测试获取陷阱数量方法
func test_get_trap_count_method() -> void:
	assert_true(trap_manager.has_method("get_trap_count"), "Should have get_trap_count")

## 测试获取陷阱数据方法
func test_get_trap_data_method() -> void:
	assert_true(trap_manager.has_method("get_trap_data"), "Should have get_trap_data")

## 测试获取所有陷阱方法
func test_get_all_traps_method() -> void:
	assert_true(trap_manager.has_method("get_all_traps"), "Should have get_all_traps")

## 测试获取陷阱名称方法
func test_get_trap_name_method() -> void:
	assert_true(trap_manager.has_method("get_trap_name"), "Should have get_trap_name")

## 测试获取陷阱成本方法
func test_get_trap_cost_method() -> void:
	assert_true(trap_manager.has_method("get_trap_cost"), "Should have get_trap_cost")

## 测试检查位置陷阱方法
func test_has_trap_at_position_method() -> void:
	assert_true(trap_manager.has_method("has_trap_at_position"), "Should have has_trap_at_position")

## 测试触发检测方法
func test_check_enemy_trigger_method() -> void:
	assert_true(trap_manager.has_method("check_enemy_trigger"), "Should have check_enemy_trigger")

## 测试触发陷阱方法
func test_trigger_trap_method() -> void:
	assert_true(trap_manager.has_method("trigger_trap"), "Should have trigger_trap")

## 测试范围效果方法
func test_apply_aoe_effect_method() -> void:
	assert_true(trap_manager.has_method("apply_aoe_effect"), "Should have apply_aoe_effect")

# === 默认状态测试 ===

## 测试默认陷阱列表为空
func test_default_traps_empty() -> void:
	assert_eq(trap_manager._placed_traps.size(), 0, "No traps initially")

## 测试默认陷阱 ID
func test_default_next_trap_id() -> void:
	assert_eq(trap_manager._next_trap_id, 1, "Next trap ID starts at 1")

## 测试默认陷阱数量
func test_default_trap_count() -> void:
	assert_eq(trap_manager.get_trap_count(), 0, "Trap count = 0 initially")

# === 陷阱放置测试 ===

## 测试放置陷阱返回 ID
func test_place_trap_returns_id() -> void:
	var trap_id: int = trap_manager.place_trap(trap_manager.TrapType.SPIKE, Vector2i(5, 5))
	assert_eq(trap_id, 1, "First trap ID = 1")

## 测试放置陷阱增加数量
func test_place_trap_increases_count() -> void:
	trap_manager.place_trap(trap_manager.TrapType.SPIKE, Vector2i(5, 5))
	assert_eq(trap_manager.get_trap_count(), 1, "Trap count = 1 after placement")

## 测试放置多个陷阱
func test_place_multiple_traps() -> void:
	trap_manager.place_trap(trap_manager.TrapType.SPIKE, Vector2i(5, 5))
	trap_manager.place_trap(trap_manager.TrapType.SLOW, Vector2i(10, 10))
	trap_manager.place_trap(trap_manager.TrapType.EXPLOSIVE, Vector2i(15, 15))
	assert_eq(trap_manager.get_trap_count(), 3, "Trap count = 3 after 3 placements")

## 测试放置陷阱存储数据
func test_place_trap_stores_data() -> void:
	var trap_id: int = trap_manager.place_trap(trap_manager.TrapType.DAMAGE, Vector2i(8, 8))
	var data: Dictionary = trap_manager.get_trap_data(trap_id)
	assert_true(data.has("id"), "Trap data should have id")
	assert_true(data.has("type"), "Trap data should have type")
	assert_true(data.has("grid_pos"), "Trap data should have grid_pos")
	assert_true(data.has("world_pos"), "Trap data should have world_pos")

## 测试陷阱世界位置计算
func test_trap_world_position_calculation() -> void:
	var trap_id: int = trap_manager.place_trap(trap_manager.TrapType.SPIKE, Vector2i(0, 0))
	var data: Dictionary = trap_manager.get_trap_data(trap_id)
	var world_pos: Vector2 = data["world_pos"]
	assert_eq(world_pos.x, 16.0, "World pos X = 16 for grid (0,0)")
	assert_eq(world_pos.y, 16.0, "World pos Y = 16 for grid (0,0)")

# === 陷阱移除测试 ===

## 测试移除陷阱减少数量
func test_remove_trap_decreases_count() -> void:
	var trap_id: int = trap_manager.place_trap(trap_manager.TrapType.SPIKE, Vector2i(5, 5))
	trap_manager.remove_trap(trap_id)
	assert_eq(trap_manager.get_trap_count(), 0, "Trap count = 0 after removal")

## 测试移除不存在陷阱返回 false
func test_remove_nonexistent_trap() -> void:
	var result: bool = trap_manager.remove_trap(99)
	assert_false(result, "Remove nonexistent trap should return false")

## 测试移除后陷阱 ID 递增继续
func test_trap_id_continues_after_remove() -> void:
	var trap_id1: int = trap_manager.place_trap(trap_manager.TrapType.SPIKE, Vector2i(5, 5))
	trap_manager.remove_trap(trap_id1)
	var trap_id2: int = trap_manager.place_trap(trap_manager.TrapType.SLOW, Vector2i(10, 10))
	assert_eq(trap_id2, 2, "Next trap ID = 2 (incremented)")

# === 位置检查测试 ===

## 测试位置陷阱检查
func test_has_trap_at_position() -> void:
	trap_manager.place_trap(trap_manager.TrapType.SPIKE, Vector2i(5, 5))
	assert_true(trap_manager.has_trap_at_position(Vector2i(5, 5)), "Should have trap at (5,5)")
	assert_false(trap_manager.has_trap_at_position(Vector2i(10, 10)), "Should not have trap at (10,10)")

## 测试获取位置陷阱 ID
func test_get_trap_at_position() -> void:
	var trap_id: int = trap_manager.place_trap(trap_manager.TrapType.SLOW, Vector2i(7, 7))
	var found_id: int = trap_manager.get_trap_at_position(Vector2i(7, 7))
	assert_eq(found_id, trap_id, "Should find trap ID at position")

## 测试空位置返回 -1
func test_get_trap_at_empty_position() -> void:
	var found_id: int = trap_manager.get_trap_at_position(Vector2i(99, 99))
	assert_eq(found_id, -1, "Empty position should return -1")

# === 陷阱名称查询测试 ===

## 测试按类型获取名称
func test_get_trap_name_by_type() -> void:
	assert_eq(trap_manager.get_trap_name(trap_manager.TrapType.SPIKE), "尖刺陷阱", "SPIKE name correct")
	assert_eq(trap_manager.get_trap_name(trap_manager.TrapType.SLOW), "减速陷阱", "SLOW name correct")

# === 边界测试 ===

## 测试无效陷阱类型名称
func test_invalid_trap_type_name() -> void:
	var name: String = trap_manager.get_trap_name(99)
	assert_eq(name, "未知", "Invalid type should return '未知'")

## 测试无效陷阱成本
func test_invalid_trap_type_cost() -> void:
	var cost: Dictionary = trap_manager.get_trap_cost(99)
	assert_eq(cost.size(), 0, "Invalid type should return empty cost")

## 测试触发半径范围
func test_trigger_radius_values() -> void:
	# SPIKE: 32px, SLOW: 48px, EXPLOSIVE: 32px
	var spike_radius: float = trap_manager.TRAP_CONFIGS[trap_manager.TrapType.SPIKE]["trigger_radius"]
	assert_eq(spike_radius, 32.0, "SPIKE trigger_radius = 32")

	var slow_radius: float = trap_manager.TRAP_CONFIGS[trap_manager.TrapType.SLOW]["trigger_radius"]
	assert_eq(slow_radius, 48.0, "SLOW trigger_radius = 48")

## 测试触发次数限制范围
func test_trigger_limit_values() -> void:
	# SPIKE: 3次, SLOW: 无限(-1), EXPLOSIVE: 1次
	assert_eq(trap_manager.TRAP_CONFIGS[trap_manager.TrapType.SPIKE]["trigger_limit"], 3, "SPIKE limit = 3")
	assert_eq(trap_manager.TRAP_CONFIGS[trap_manager.TrapType.SLOW]["trigger_limit"], -1, "SLOW limit = -1")
	assert_eq(trap_manager.TRAP_CONFIGS[trap_manager.TrapType.EXPLOSIVE]["trigger_limit"], 1, "EXPLOSIVE limit = 1")