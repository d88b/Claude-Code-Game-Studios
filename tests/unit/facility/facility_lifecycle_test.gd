# facility_lifecycle_test.gd
# FacilityController 单元测试
## FacilityController 单元测试
## 测试设施实体生命周期的所有 acceptance criteria

extends GutTest

# === 脚本预加载 ===
const FacilityControllerScript := preload("res://src/facility/facility_controller.gd")

# === 测试常量 ===
const STORAGE_CAPACITY: int = 100  # TK-032
const MAGIC_LINK_DISTANCE: int = 10  # TK-047
const DEMOLITION_REFUND_RATE: float = 0.5  # TK-048
const FACILITY_STORAGE: int = 400
const FACILITY_WORKBENCH: int = 410

# === 本地枚举镜像 ===
enum FacilityState { IDLE, ACTIVE, DAMAGED, DESTROYED }

# === 测试变量 ===
var _controller: Node = null
var _mock_global_signals: MockGlobalSignals = null
var _mock_vehicle_attribute: MockVehicleAttribute = null
var _mock_tilemap_world: MockTileMapWorld = null

# === Mock 类 ===

class MockGlobalSignals extends RefCounted:
	var facility_created_emitted: bool = false
	var facility_destroyed_emitted: bool = false
	var facility_demolished_emitted: bool = false
	var facility_state_changed_emitted: bool = false
	var resource_dropped_emitted: bool = false
	var last_facility_id: int = 0
	var last_position: Vector2i = Vector2i.ZERO
	var last_state: int = 0
	var dropped_resources: Array[Dictionary] = []

	signal facility_created(facility_id: int, position: Vector2i)
	signal facility_destroyed(facility_id: int, position: Vector2i)
	signal facility_demolished(facility_id: int, position: Vector2i)
	signal facility_state_changed(facility_id: int, new_state: int)
	signal resource_dropped(resource_id: int, position: Vector2, quantity: float)
	signal block_placed(grid_pos: Vector2i, block_id: int, layer: int)

	func emit_facility_created(id: int, pos: Vector2i) -> void:
		facility_created_emitted = true
		last_facility_id = id
		last_position = pos

	func emit_facility_destroyed(id: int, pos: Vector2i) -> void:
		facility_destroyed_emitted = true
		last_facility_id = id
		last_position = pos

	func emit_facility_demolished(id: int, pos: Vector2i) -> void:
		facility_demolished_emitted = true
		last_facility_id = id
		last_position = pos

	func emit_facility_state_changed(id: int, state: int) -> void:
		facility_state_changed_emitted = true
		last_facility_id = id
		last_state = state

	func emit_resource_dropped(resource_id: int, pos: Vector2, qty: float) -> void:
		resource_dropped_emitted = true
		dropped_resources.append({"resource_id": resource_id, "position": pos, "quantity": qty})

class MockVehicleAttribute extends RefCounted:
	var current_magic: float = 100.0
	var max_magic: float = 100.0
	var parent_position: Vector2 = Vector2(0, 0)

	func can_afford_magic(amount: float) -> bool:
		return current_magic >= amount

	func consume_magic(amount: float) -> bool:
		if current_magic < amount:
			return false
		current_magic -= amount
		return true

	func replenish_magic(amount: float) -> void:
		current_magic = min(current_magic + amount, max_magic)

	func get_magic_energy_ratio() -> float:
		return current_magic / max_magic

	func get_parent() -> Node:
		var mock_node: Node = Node.new()
		mock_node.position = parent_position
		return mock_node

class MockTileMapWorld extends RefCounted:
	var cells: Dictionary = {}

	func get_cell_tile_data(coords: Vector2i) -> Object:
		return null

# === 测试生命周期 ===

func before_each() -> void:
	_controller = FacilityControllerScript.new()
	_mock_global_signals = MockGlobalSignals.new()
	_mock_vehicle_attribute = MockVehicleAttribute.new()
	_mock_tilemap_world = MockTileMapWorld.new()

	_controller.set_dependencies(_mock_global_signals, _mock_vehicle_attribute, _mock_tilemap_world)

func after_each() -> void:
	if _controller != null:
		_controller.queue_free()
	_controller = null
	_mock_global_signals = null
	_mock_vehicle_attribute = null
	_mock_tilemap_world = null

# === AC-01: 设施实体创建 ===

func test_facility_created_on_placement_storage() -> void:
	# 触发 block_placed 信号 (储物箱) — 发射 build_item_id
	_mock_global_signals.block_placed.emit(Vector2i(15, 20), FACILITY_STORAGE, 2)

	# 验证设施已创建
	var facility: Dictionary = _controller.get_facility_at(Vector2i(15, 20))
	assert_false(facility.is_empty(), "AC-01: Storage facility should be created")
	assert_eq(facility["build_item_id"], FACILITY_STORAGE, "AC-01: Should be storage box")

func test_facility_created_on_placement_workbench() -> void:
	# 触发 block_placed 信号 (工作台) — 发射 build_item_id
	_mock_global_signals.block_placed.emit(Vector2i(10, 10), FACILITY_WORKBENCH, 2)

	# 验证设施已创建
	var facility: Dictionary = _controller.get_facility_at(Vector2i(10, 10))
	assert_false(facility.is_empty(), "AC-01: Workbench facility should be created")
	assert_eq(facility["build_item_id"], FACILITY_WORKBENCH, "AC-01: Should be workbench")

# === AC-02: 设施绑定正确 cell ===

func test_facility_binds_to_correct_cell() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(25, 30), FACILITY_STORAGE, 2)

	var facility: Dictionary = _controller.get_facility_at(Vector2i(25, 30))
	assert_eq(facility["cell"], Vector2i(25, 30), "AC-02: Facility should bind to correct cell")

# === AC-03: 设施初始状态 IDLE ===

func test_facility_initial_state_idle() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(5, 5), FACILITY_STORAGE, 2)

	var facility: Dictionary = _controller.get_facility_at(Vector2i(5, 5))
	assert_eq(facility["state"], FacilityState.IDLE, "AC-03: Initial state should be IDLE")

# === AC-04: 储物箱内容初始化为空 ===

func test_storage_contents_initialized_empty() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)

	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))
	var contents: Array = facility["storage_contents"]

	assert_eq(contents.size(), STORAGE_CAPACITY, "AC-04: Storage should have 100 slots")

	for slot in contents:
		assert_eq(slot["resource_id"], 0, "AC-04: All slots should be empty (resource_id=0)")
		assert_eq(slot["quantity"], 0, "AC-04: All slots should have quantity=0")

# === AC-05: 非设施放置被忽略 ===

func test_non_facility_placement_ignored() -> void:
	# 放置墙体 (tile_id 不在 2000/2001 范围)
	_mock_global_signals.block_placed.emit(Vector2i(100, 100), 3000, 2)

	var facility: Dictionary = _controller.get_facility_at(Vector2i(100, 100))
	assert_true(facility.is_empty(), "AC-05: Non-facility placement should be ignored")

# === AC-06: 多设施独立跟踪 ===

func test_multiple_facilities_tracked_independently() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(1, 1), FACILITY_STORAGE, 2)
	_mock_global_signals.block_placed.emit(Vector2i(2, 2), FACILITY_STORAGE, 2)
	_mock_global_signals.block_placed.emit(Vector2i(3, 3), FACILITY_WORKBENCH, 2)

	var all_facilities: Array = _controller.get_all_facilities()
	assert_eq(all_facilities.size(), 3, "AC-06: Should track 3 facilities")

	# 验证 ID 不同
	var ids: Array = []
	for f in all_facilities:
		ids.append(f["facility_id"])
	assert_true(ids.has(1), "AC-06: Should have facility_id=1")
	assert_true(ids.has(2), "AC-06: Should have facility_id=2")
	assert_true(ids.has(3), "AC-06: Should have facility_id=3")

# === AC: GlobalSignals 发射 ===

func test_facility_created_signal_emitted() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(50, 50), FACILITY_STORAGE, 2)

	assert_true(_mock_global_signals.facility_created_emitted, "AC-06: facility_created signal should be emitted")
	assert_eq(_mock_global_signals.last_position, Vector2i(50, 50), "AC-06: Signal should contain correct position")

func test_facility_destroyed_signal_emitted() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(60, 60), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(60, 60))

	# 模拟伤害直到摧毁
	_controller.damage_facility(facility["facility_id"], 100.0)

	assert_true(_mock_global_signals.facility_destroyed_emitted, "AC-06: facility_destroyed signal should be emitted")

# === TK-032: 储物箱容量 100 slots ===

func test_storage_capacity_100_slots() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	assert_eq(facility["storage_contents"].size(), STORAGE_CAPACITY, "TK-032: Capacity should be 100")

func test_deposit_to_empty_slot() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	var deposited: int = _controller.deposit_resource(facility["facility_id"], 101, 50)
	assert_eq(deposited, 50, "AC-07: Should deposit 50")

	var contents: Array = _controller.get_storage_contents(facility["facility_id"])
	assert_eq(contents[0]["resource_id"], 101, "AC-07: Slot 0 should have iron")
	assert_eq(contents[0]["quantity"], 50, "AC-07: Slot 0 should have 50 iron")

func test_deposit_to_existing_slot_stacks() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.deposit_resource(facility["facility_id"], 101, 200)
	var deposited: int = _controller.deposit_resource(facility["facility_id"], 101, 30)

	assert_eq(deposited, 30, "AC-08: Should stack 30 more")

	var contents: Array = _controller.get_storage_contents(facility["facility_id"])
	assert_eq(contents[0]["quantity"], 230, "AC-08: Slot should have 230 total")

func test_deposit_rejects_when_full() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	# 填满所有槽位
	for i in range(STORAGE_CAPACITY):
		_controller.deposit_resource(facility["facility_id"], i + 100, 999)

	var deposited: int = _controller.deposit_resource(facility["facility_id"], 101, 50)
	assert_eq(deposited, 0, "AC-09: Should reject deposit when full")

func test_deposit_caps_at_stack_limit() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.deposit_resource(facility["facility_id"], 101, 900)
	var deposited: int = _controller.deposit_resource(facility["facility_id"], 101, 100)

	assert_eq(deposited, 99, "AC-10: Should cap at stack limit 999")

	var contents: Array = _controller.get_storage_contents(facility["facility_id"])
	assert_eq(contents[0]["quantity"], 999, "AC-10: Slot should be at max")

func test_withdraw_exact_amount() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.deposit_resource(facility["facility_id"], 101, 100)
	var withdrawn: int = _controller.withdraw_resource(facility["facility_id"], 101, 30)

	assert_eq(withdrawn, 30, "AC-11: Should withdraw exact amount")

	var contents: Array = _controller.get_storage_contents(facility["facility_id"])
	assert_eq(contents[0]["quantity"], 70, "AC-11: Remaining should be 70")

func test_withdraw_partial_when_insufficient() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.deposit_resource(facility["facility_id"], 101, 50)
	var withdrawn: int = _controller.withdraw_resource(facility["facility_id"], 101, 100)

	assert_eq(withdrawn, 50, "AC-12: Should withdraw available amount only")

func test_withdraw_zero_for_nonexistent() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	var withdrawn: int = _controller.withdraw_resource(facility["facility_id"], 999, 50)
	assert_eq(withdrawn, 0, "AC-13: Should return 0 for non-existent resource")

func test_remaining_slots_correct() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	# 填充 80 槽位
	for i in range(80):
		_controller.deposit_resource(facility["facility_id"], i + 100, 50)

	var remaining: int = _controller.get_remaining_slots(facility["facility_id"])
	assert_eq(remaining, 20, "AC-14: Should have 20 remaining slots")

func test_storage_locked_in_damaged_state() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.deposit_resource(facility["facility_id"], 101, 50)

	# 模拟损坏 (health_ratio < 0.30)
	_controller.damage_facility(facility["facility_id"], 40.0)
	_controller.set_facility_state(facility["facility_id"], FacilityState.DAMAGED)

	var deposited: int = _controller.deposit_resource(facility["facility_id"], 102, 50)
	assert_eq(deposited, 0, "AC-15: Should reject deposit in DAMAGED state")

# === TK-047: 魔能连接距离 ≤10 cells ===

func test_magic_connection_within_10_cells() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(5, 5), FACILITY_WORKBENCH, 2)  # 工作台
	var facility: Dictionary = _controller.get_facility_at(Vector2i(5, 5))

	# 战车在 (10, 10) — 距离 ≈ 7 cells
	_mock_vehicle_attribute.parent_position = Vector2(10 * 32, 10 * 32)

	var connected: bool = _controller.check_magic_connection(facility["cell"])
	assert_true(connected, "TK-047: Should be connected within 10 cells")

func test_magic_connection_beyond_10_cells() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_WORKBENCH, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	# 战车在 (15, 15) — 距离 > 10 cells
	_mock_vehicle_attribute.parent_position = Vector2(15 * 32, 15 * 32)

	var connected: bool = _controller.check_magic_connection(facility["cell"])
	assert_false(connected, "TK-047: Should NOT be connected beyond 10 cells")

# === TR-facility-003: 工作台合成 4 MVP recipes ===

func test_workbench_has_4_mvp_recipes() -> void:
	var recipes: Array = _controller.get_mvp_recipes()
	assert_eq(recipes.size(), 4, "TR-facility-003: Should have 4 MVP recipes")

func test_recipe_r001_iron_ingot() -> void:
	var recipes: Array = _controller.get_mvp_recipes()
	var r001: Dictionary = {}
	for r in recipes:
		if r["id"] == "R001":
			r001 = r
			break

	assert_false(r001.is_empty(), "Should find R001 recipe")
	assert_eq(r001["inputs"][0]["resource_id"], 101, "R001: Input should be iron ore")
	assert_eq(r001["inputs"][0]["quantity"], 5, "R001: Need 5 iron ore")
	assert_eq(r001["output"]["resource_id"], 151, "R001: Output should be iron ingot")
	assert_eq(r001["magic_cost"], 8, "R001: Magic cost should be 8")

func test_crafting_starts_with_valid_conditions() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(5, 5), FACILITY_WORKBENCH, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(5, 5))

	_mock_vehicle_attribute.parent_position = Vector2(5 * 32, 5 * 32)
	_mock_vehicle_attribute.current_magic = 100.0

	var started: bool = _controller.start_crafting(facility["facility_id"], "R001")
	assert_true(started, "AC-17: Should start crafting with valid conditions")

func test_crafting_fails_without_magic() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(5, 5), FACILITY_WORKBENCH, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(5, 5))

	_mock_vehicle_attribute.parent_position = Vector2(5 * 32, 5 * 32)
	_mock_vehicle_attribute.current_magic = 5.0  # 不够 8

	var started: bool = _controller.start_crafting(facility["facility_id"], "R001")
	assert_false(started, "AC-19: Should fail without enough magic")

func test_crafting_fails_without_magic_connection() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_WORKBENCH, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_mock_vehicle_attribute.parent_position = Vector2(20 * 32, 20 * 32)  # 距离 > 10

	var started: bool = _controller.start_crafting(facility["facility_id"], "R001")
	assert_false(started, "AC-20: Should fail without magic connection")

func test_crafting_progress_updates() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(5, 5), FACILITY_WORKBENCH, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(5, 5))

	_mock_vehicle_attribute.parent_position = Vector2(5 * 32, 5 * 32)
	_controller.start_crafting(facility["facility_id"], "R001")

	# 模拟 5 秒进度
	_controller.update_crafting_progress(facility["facility_id"], 5.0)

	var progress: float = _controller.get_craft_progress(facility["facility_id"])
	assert_almost_eq(progress, 0.5, 0.1, "AC-21: Progress should be ~50% after 5s")

func test_crafting_cancelled_with_refund() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(5, 5), FACILITY_WORKBENCH, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(5, 5))

	_mock_vehicle_attribute.parent_position = Vector2(5 * 32, 5 * 32)
	_mock_vehicle_attribute.current_magic = 50.0
	_controller.start_crafting(facility["facility_id"], "R001")

	var magic_before: float = _mock_vehicle_attribute.current_magic
	_controller.cancel_crafting(facility["facility_id"])

	assert_eq(_mock_vehicle_attribute.current_magic, magic_before + 8, "AC-23: Magic should be refunded")

func test_crafting_cancelled_on_damaged() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(5, 5), FACILITY_WORKBENCH, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(5, 5))

	_mock_vehicle_attribute.parent_position = Vector2(5 * 32, 5 * 32)
	_mock_vehicle_attribute.current_magic = 50.0
	_controller.start_crafting(facility["facility_id"], "R001")

	# 模拟损坏
	_controller.damage_facility(facility["facility_id"], 40.0)

	var current_recipe: Dictionary = _controller.get_facility_by_id(facility["facility_id"])["current_recipe"]
	assert_true(current_recipe == null or current_recipe.is_empty(), "AC-31: Crafting should be cancelled on DAMAGED")

# === TK-048: 拆除返还 50% ===

func test_demolition_returns_50_percent() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	var refund: Dictionary = _controller.demolish_facility(facility["facility_id"])

	# 储物箱成本: 铁×4, 木×6 → 返还 铁×2, 木×3
	assert_eq(refund["iron"], 2, "TK-048: Should refund 2 iron (50% of 4)")
	assert_eq(refund["wood"], 3, "TK-048: Should refund 3 wood (50% of 6)")

func test_demolition_drops_storage_contents() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.deposit_resource(facility["facility_id"], 101, 50)

	_controller.demolish_facility(facility["facility_id"])

	assert_true(_mock_global_signals.resource_dropped_emitted, "AC-34: Should emit drop signal")
	assert_eq(_mock_global_signals.dropped_resources.size(), 1, "AC-34: Should drop 1 resource pile")
	assert_eq(_mock_global_signals.dropped_resources[0]["resource_id"], 101, "AC-34: Should drop iron")
	assert_eq(_mock_global_signals.dropped_resources[0]["quantity"], 50, "AC-34: Should drop full quantity")

func test_demolition_signal_emitted() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.demolish_facility(facility["facility_id"])

	assert_true(_mock_global_signals.facility_demolished_emitted, "Should emit facility_demolished signal")

func test_facility_unregistered_after_demolish() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.demolish_facility(facility["facility_id"])

	var removed: Dictionary = _controller.get_facility_at(Vector2i(0, 0))
	assert_true(removed.is_empty(), "AC-37: Facility should be unregistered after removal")

# === 设施损坏测试 ===

func test_facility_health_decreases_on_attack() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	var initial_health: float = facility["health_ratio"]
	_controller.damage_facility(facility["facility_id"], 20.0)

	assert_lt(facility["health_ratio"], initial_health, "AC-26: Health should decrease on damage")

func test_damaged_state_at_30_percent() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	# 储物箱硬度 50，需要伤害 >35 才能让 health_ratio < 0.30
	_controller.damage_facility(facility["facility_id"], 40.0)

	assert_eq(facility["state"], FacilityState.DAMAGED, "AC-27: Should enter DAMAGED at <30%")

func test_destroyed_state_at_0_percent() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.damage_facility(facility["facility_id"], 100.0)

	# 设施应被移除
	var removed: Dictionary = _controller.get_facility_by_id(facility["facility_id"])
	assert_true(removed.is_empty(), "AC-28: Facility should be DESTROYED and removed")

func test_content_drops_on_destruction() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.deposit_resource(facility["facility_id"], 101, 50)
	_controller.damage_facility(facility["facility_id"], 100.0)

	assert_true(_mock_global_signals.resource_dropped_emitted, "AC-29: Should drop contents on destruction")

# === 辅助方法测试 ===

func test_find_empty_slot() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	var index: int = _controller.find_empty_slot(facility["facility_id"])
	assert_eq(index, 0, "Should find first empty slot")

func test_find_slot_by_resource() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.deposit_resource(facility["facility_id"], 101, 50)
	var index: int = _controller.find_slot_by_resource(facility["facility_id"], 101)
	assert_eq(index, 0, "Should find slot with iron")

func test_has_facility_at() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(10, 10), FACILITY_STORAGE, 2)

	assert_true(_controller.has_facility_at(Vector2i(10, 10)), "Should have facility at position")
	assert_false(_controller.has_facility_at(Vector2i(99, 99)), "Should NOT have facility at empty position")

# === 边界条件测试 ===

func test_deposit_overflow_handling() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	# 填满 1 个槽位到 999
	_controller.deposit_resource(facility["facility_id"], 101, 999)
	# 再存入 100，应该存入新槽位
	var deposited: int = _controller.deposit_resource(facility["facility_id"], 101, 100)

	assert_eq(deposited, 100, "Should overflow to new slot")

func test_withdraw_more_than_available() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(0, 0), FACILITY_STORAGE, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(0, 0))

	_controller.deposit_resource(facility["facility_id"], 101, 30)
	var withdrawn: int = _controller.withdraw_resource(facility["facility_id"], 101, 100)

	assert_eq(withdrawn, 30, "Should only withdraw available amount")

func test_crafting_resume_after_reconnect() -> void:
	_mock_global_signals.block_placed.emit(Vector2i(5, 5), FACILITY_WORKBENCH, 2)
	var facility: Dictionary = _controller.get_facility_at(Vector2i(5, 5))

	_mock_vehicle_attribute.parent_position = Vector2(5 * 32, 5 * 32)
	_controller.start_crafting(facility["facility_id"], "R001")

	# 进度到 30%
	_controller.update_crafting_progress(facility["facility_id"], 3.0)
	var progress_before_disconnect: float = _controller.get_craft_progress(facility["facility_id"])

	# 断开连接
	_mock_vehicle_attribute.parent_position = Vector2(20 * 32, 20 * 32)
	_controller.update_crafting_progress(facility["facility_id"], 2.0)

	# 进度不应增加
	var progress_during_disconnect: float = _controller.get_craft_progress(facility["facility_id"])
	assert_almost_eq(progress_during_disconnect, progress_before_disconnect, 0.1, "AC-24: Progress should pause during disconnect")

	# 恢复连接
	_mock_vehicle_attribute.parent_position = Vector2(5 * 32, 5 * 32)
	_controller.update_crafting_progress(facility["facility_id"], 2.0)

	# 进度应该继续
	var progress_after_reconnect: float = _controller.get_craft_progress(facility["facility_id"])
	assert_gt(progress_after_reconnect, progress_during_disconnect, "AC-25: Progress should resume after reconnect")