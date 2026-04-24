# facility_controller.gd
# FacilityController - 设施实体生命周期管理
## FacilityController — 设施实体生命周期管理
## 监听 block_placed 信号，创建设施实体，管理状态，处理拆除
## Feature layer system (ADR-014, TR-facility-001 to TR-facility-005)
## Note: Autoload singleton — no class_name to avoid naming conflict

extends Node

# === 常量 (TK-IDs from entities.yaml) ===
## 储物箱槽位数量 (TK-032)
const STORAGE_CAPACITY: int = 100
## 魔能连接距离 (TK-047)
const MAGIC_LINK_DISTANCE: int = 10
## 拆除材料返还比例 (TK-048)
const DEMOLITION_REFUND_RATE: float = 0.5
## 设施交互距离
const INTERACTION_RANGE: int = 2

# === 状态枚举 ===
enum FacilityState { IDLE, ACTIVE, DAMAGED, DESTROYED }

# === 设施类型 ID ===
const FACILITY_STORAGE: int = 400  # 储物箱
const FACILITY_WORKBENCH: int = 410  # 工作台

# === MVP 合成配方 ===
# Recipe 结构: {id, inputs: [{resource_id, quantity}], output: {resource_id, quantity}, magic_cost, craft_time}
var _mvp_recipes: Array[Dictionary] = [
	{
		id = "R001",
		inputs = [{"resource_id": 101, "quantity": 5}],  # 铁矿×5
		output = {"resource_id": 151, "quantity": 1},  # 铁锭×1
		magic_cost = 8,
		craft_time = 10.0,
		display_name = "铁矿 → 铁锭"
	},
	{
		id = "R002",
		inputs = [{"resource_id": 102, "quantity": 5}],  # 铜矿×5
		output = {"resource_id": 152, "quantity": 1},  # 铜锭×1
		magic_cost = 8,
		craft_time = 10.0,
		display_name = "铜矿 → 铜锭"
	},
	{
		id = "R003",
		inputs = [{"resource_id": 201, "quantity": 3}],  # 晶石碎片×3
		output = {"resource_id": 202, "quantity": 1},  # 晶石簇×1
		magic_cost = 15,
		craft_time = 15.0,
		display_name = "晶石碎片 → 晶石簇"
	},
	{
		id = "R004",
		inputs = [
			{"resource_id": 151, "quantity": 2},  # 铁锭×2
			{"resource_id": 152, "quantity": 1}   # 铜锭×1
		],
		output = {"resource_id": 160, "quantity": 1},  # 基础零件×1
		magic_cost = 12,
		craft_time = 12.0,
		display_name = "铁锭+铜锭 → 基础零件"
	}
]

# === 设施注册表 ===
## 所有设施实体的字典 {facility_id: FacilityEntityData}
var _facilities: Dictionary = {}
## 下一个 facility_id
var _next_facility_id: int = 1

# === 依赖注入 ===
var _global_signals: Object = null
var _vehicle_attribute: Object = null
var _tilemap_world: Object = null

# === 初始化 ===

func _ready() -> void:
	# 尝试自动获取依赖
	if _global_signals == null:
		_global_signals = GlobalSignals
	if _vehicle_attribute == null:
		_vehicle_attribute = get_node_or_null("/root/VehicleAttribute")
	if _tilemap_world == null:
		_tilemap_world = get_node_or_null("/root/TileMapWorld")

	# 连接信号
	if _global_signals != null:
		_global_signals.block_placed.connect(_on_block_placed)

	print("[FacilityController] Initialized — listening for block_placed")

## 设置依赖注入（用于测试）
func set_dependencies(global_signals: Object, vehicle_attribute: Object, tilemap_world: Object) -> void:
	_global_signals = global_signals
	_vehicle_attribute = vehicle_attribute
	_tilemap_world = tilemap_world

	if _global_signals != null:
		# 先断开旧连接（如果存在）
		if _global_signals.block_placed.is_connected(_on_block_placed):
			_global_signals.block_placed.disconnect(_on_block_placed)
		_global_signals.block_placed.connect(_on_block_placed)

# === 信号处理 ===

## 处理方块放置信号 — 检查是否为设施类型并创建实体
## 注意: block_placed 信号发射的是 build_item_id (来自 PlaceController)
func _on_block_placed(grid_pos: Vector2i, block_id: int, layer: int) -> void:
	# block_id 已经是 build_item_id (400/410)，直接检查
	if block_id != FACILITY_STORAGE and block_id != FACILITY_WORKBENCH:
		return  # 不是设施，忽略

	_create_facility(block_id, grid_pos)

# === 设施创建 (TR-facility-001) ===

## 创建设施实体
func _create_facility(build_item_id: int, grid_pos: Vector2i) -> Dictionary:
	var facility_id: int = _next_facility_id
	_next_facility_id += 1

	var facility_data: Dictionary = {
		"facility_id": facility_id,
		"build_item_id": build_item_id,
		"cell": grid_pos,
		"state": FacilityState.IDLE,
		"health_ratio": 1.0,
		"base_hardness": _get_facility_hardness(build_item_id),
		"storage_contents": [],  # 仅储物箱使用
		"current_recipe": null,  # 仅工作台使用
		"craft_progress": 0.0,   # 仅工作台使用
		"magic_powered": false   # 仅工作台使用
	}

	# 初始化储物箱内容 (100 空槽位)
	if build_item_id == FACILITY_STORAGE:
		facility_data["storage_contents"] = _init_empty_storage()

	# 注册设施
	_facilities[facility_id] = facility_data

	# 发射信号
	if _global_signals != null:
		_global_signals.facility_created.emit(facility_id, grid_pos)

	print("[FacilityController] Facility created: id=%d, type=%d, cell=%s" % [facility_id, build_item_id, str(grid_pos)])
	return facility_data

## 初始化空储物箱 (100 空槽位)
func _init_empty_storage() -> Array[Dictionary]:
	var slots: Array[Dictionary] = []
	for i in range(STORAGE_CAPACITY):
		slots.append({"resource_id": 0, "quantity": 0})
	return slots

# === 设施查询 ===

## 根据 grid_pos 获取设施实体
func get_facility_at(grid_pos: Vector2i) -> Dictionary:
	for facility_id in _facilities:
		var facility: Dictionary = _facilities[facility_id]
		if facility["cell"] == grid_pos:
			return facility
	return {}

## 根据 facility_id 获取设施实体
func get_facility_by_id(facility_id: int) -> Dictionary:
	if _facilities.has(facility_id):
		return _facilities[facility_id]
	return {}

## 获取所有设施实体
func get_all_facilities() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for facility_id in _facilities:
		result.append(_facilities[facility_id])
	return result

## 检查 cell 是否有设施
func has_facility_at(grid_pos: Vector2i) -> bool:
	return not get_facility_at(grid_pos).is_empty()

# === 储物箱功能 (TR-facility-002) ===

## 存入资源到储物箱
## 返回实际存入数量
func deposit_resource(facility_id: int, resource_id: int, amount: int) -> int:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty():
		return 0

	if facility["build_item_id"] != FACILITY_STORAGE:
		return 0  # 不是储物箱

	if facility["state"] == FacilityState.DAMAGED:
		print("[FacilityController] Storage box damaged, cannot deposit")
		return 0

	var contents: Array = facility["storage_contents"]
	var remaining: int = amount

	# 1. 尝试堆叠到已有槽位
	for slot in contents:
		if slot["resource_id"] == resource_id and slot["quantity"] < 999:
			var can_add: int = min(remaining, 999 - slot["quantity"])
			slot["quantity"] += can_add
			remaining -= can_add
			if remaining == 0:
				break

	# 2. 存入空槽位
	if remaining > 0:
		for slot in contents:
			if slot["resource_id"] == 0:
				slot["resource_id"] = resource_id
				slot["quantity"] = min(remaining, 999)
				remaining -= slot["quantity"]
				if remaining == 0:
					break

	var deposited: int = amount - remaining
	print("[FacilityController] Deposit: resource=%d, requested=%d, deposited=%d" % [resource_id, amount, deposited])
	return deposited

## 从储物箱取出资源
## 返回实际取出数量
func withdraw_resource(facility_id: int, resource_id: int, amount: int) -> int:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty():
		return 0

	if facility["build_item_id"] != FACILITY_STORAGE:
		return 0

	if facility["state"] == FacilityState.DAMAGED:
		print("[FacilityController] Storage box damaged, cannot withdraw")
		return 0

	var contents: Array = facility["storage_contents"]
	var withdrawn: int = 0
	var remaining_request: int = amount

	# 从槽位中取出
	for slot in contents:
		if slot["resource_id"] == resource_id and slot["quantity"] > 0:
			var can_take: int = min(remaining_request, slot["quantity"])
			slot["quantity"] -= can_take
			withdrawn += can_take
			remaining_request -= can_take

			# 清空槽位
			if slot["quantity"] == 0:
				slot["resource_id"] = 0

			if remaining_request == 0:
				break

	print("[FacilityController] Withdraw: resource=%d, requested=%d, withdrawn=%d" % [resource_id, amount, withdrawn])
	return withdrawn

## 获取储物箱内容
func get_storage_contents(facility_id: int) -> Array[Dictionary]:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty() or facility["build_item_id"] != FACILITY_STORAGE:
		return []
	return facility["storage_contents"]

## 获取剩余空槽位数量
func get_remaining_slots(facility_id: int) -> int:
	var contents: Array = get_storage_contents(facility_id)
	if contents.is_empty():
		return 0

	var count: int = 0
	for slot in contents:
		if slot["resource_id"] == 0:
			count += 1
	return count

## 查找空槽位索引
func find_empty_slot(facility_id: int) -> int:
	var contents: Array = get_storage_contents(facility_id)
	for i in range(contents.size()):
		if contents[i]["resource_id"] == 0:
			return i
	return -1

## 查找特定资源的槽位索引
func find_slot_by_resource(facility_id: int, resource_id: int) -> int:
	var contents: Array = get_storage_contents(facility_id)
	for i in range(contents.size()):
		if contents[i]["resource_id"] == resource_id:
			return i
	return -1

# === 工作台功能 (TR-facility-003, TR-facility-004) ===

## 获取 MVP 配方列表
func get_mvp_recipes() -> Array[Dictionary]:
	return _mvp_recipes

## 检查魔能连接 (工作台必须在战车 10 cells 范围内)
func check_magic_connection(workbench_cell: Vector2i) -> bool:
	if _vehicle_attribute == null:
		return false

	# 获取战车位置 (通过 VehicleAttribute 的父节点)
	var vehicle_node: Node = _vehicle_attribute.get_parent()
	if vehicle_node == null:
		return false

	var vehicle_pos: Vector2 = vehicle_node.position
	var vehicle_cell: Vector2i = Vector2i(
		int(vehicle_pos.x / 32),
		int(vehicle_pos.y / 32)
	)

	var distance: float = workbench_cell.distance_to(Vector2(vehicle_cell.x, vehicle_cell.y))
	return distance <= MAGIC_LINK_DISTANCE

## 开始合成
## 返回 true 表示合成开始，false 表示条件不满足
func start_crafting(facility_id: int, recipe_id: String) -> bool:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty():
		return false

	if facility["build_item_id"] != FACILITY_WORKBENCH:
		return false

	if facility["state"] == FacilityState.DAMAGED:
		print("[FacilityController] Workbench damaged, cannot craft")
		return false

	# 查找配方
	var recipe: Dictionary = {}
	for r in _mvp_recipes:
		if r["id"] == recipe_id:
			recipe = r
			break

	if recipe.is_empty():
		print("[FacilityController] Recipe not found: %s" % recipe_id)
		return false

	# 验证魔能连接
	if not check_magic_connection(facility["cell"]):
		print("[FacilityController] Magic connection broken")
		return false

	# 验证魔能充足
	if _vehicle_attribute == null:
		return false

	var magic_cost: int = recipe["magic_cost"]
	if not _vehicle_attribute.can_afford_magic(magic_cost):
		print("[FacilityController] Magic insufficient: need %d" % magic_cost)
		return false

	# 执行：扣除魔能，设置配方
	_vehicle_attribute.consume_magic(magic_cost)
	facility["current_recipe"] = recipe
	facility["craft_progress"] = 0.0
	facility["magic_powered"] = true

	print("[FacilityController] Crafting started: facility=%d, recipe=%s" % [facility_id, recipe_id])
	return true

## 更新合成进度 (每帧调用)
func update_crafting_progress(facility_id: int, delta: float) -> void:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty():
		return

	if facility["current_recipe"] == null:
		return

	# 检查魔能连接
	if not check_magic_connection(facility["cell"]):
		# 连接断开，暂停但不取消
		facility["magic_powered"] = false
		return

	facility["magic_powered"] = true
	var craft_time: float = facility["current_recipe"]["craft_time"]
	facility["craft_progress"] += delta

	# 完成检查
	if facility["craft_progress"] >= craft_time:
		_complete_crafting(facility_id)

## 完成合成
func _complete_crafting(facility_id: int) -> void:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty() or facility["current_recipe"] == null:
		return

	var recipe: Dictionary = facility["current_recipe"]
	var output: Dictionary = recipe["output"]

	print("[FacilityController] Crafting complete: output resource=%d, quantity=%d" % [output["resource_id"], output["quantity"]])

	# TODO: 输出到玩家背包或战车仓库 (依赖背包系统)
	# 暂时发射信号通知
	if _global_signals != null:
		_global_signals.resource_dropped.emit(output["resource_id"], Vector2(facility["cell"].x * 32, facility["cell"].y * 32), output["quantity"])

	# 清除合成状态
	facility["current_recipe"] = null
	facility["craft_progress"] = 0.0

## 取消合成 (返还魔能)
func cancel_crafting(facility_id: int) -> void:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty() or facility["current_recipe"] == null:
		return

	var recipe: Dictionary = facility["current_recipe"]
	var magic_cost: int = recipe["magic_cost"]

	# 返还魔能
	if _vehicle_attribute != null:
		_vehicle_attribute.replenish_magic(magic_cost)

	facility["current_recipe"] = null
	facility["craft_progress"] = 0.0
	print("[FacilityController] Crafting cancelled, magic refunded: %d" % magic_cost)

## 获取合成进度 (0.0 ~ 1.0)
func get_craft_progress(facility_id: int) -> float:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty() or facility["current_recipe"] == null:
		return 0.0

	var craft_time: float = facility["current_recipe"]["craft_time"]
	return clamp(facility["craft_progress"] / craft_time, 0.0, 1.0)

# === 设施状态管理 ===

## 获取设施状态
func get_facility_state(facility_id: int) -> int:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty():
		return FacilityState.DESTROYED
	return facility["state"]

## 设置设施状态（用于测试）
func set_facility_state(facility_id: int, new_state: int) -> void:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty():
		return

	var old_state: int = facility["state"]
	facility["state"] = new_state

	if old_state != new_state and _global_signals != null:
		_global_signals.facility_state_changed.emit(facility_id, new_state)

	print("[FacilityController] State changed: facility=%d, %d -> %d" % [facility_id, old_state, new_state])

## 设施受到伤害
func damage_facility(facility_id: int, damage_amount: float) -> void:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty():
		return

	var base_hardness: float = facility["base_hardness"]
	if base_hardness <= 0:
		return

	var damage_ratio: float = damage_amount / base_hardness
	facility["health_ratio"] = max(facility["health_ratio"] - damage_ratio, 0.0)

	# 状态转换检查
	var new_state: int = _calculate_state_from_health(facility["health_ratio"])
	if new_state != facility["state"]:
		_transition_facility_state(facility_id, new_state)

	print("[FacilityController] Facility damaged: id=%d, health_ratio=%.2f" % [facility_id, facility["health_ratio"]])

## 根据耐久比例计算状态
func _calculate_state_from_health(health_ratio: float) -> int:
	if health_ratio <= 0.0:
		return FacilityState.DESTROYED
	elif health_ratio < 0.30:
		return FacilityState.DAMAGED
	else:
		return FacilityState.ACTIVE

## 状态转换处理
func _transition_facility_state(facility_id: int, new_state: int) -> void:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty():
		return

	var old_state: int = facility["state"]
	facility["state"] = new_state

	# 发射状态变化信号
	if _global_signals != null:
		_global_signals.facility_state_changed.emit(facility_id, new_state)

	# 特殊处理：摧毁
	if new_state == FacilityState.DESTROYED:
		_on_facility_destroyed(facility_id)

	# 特殊处理：损坏（工作台取消合成）
	if new_state == FacilityState.DAMAGED and old_state == FacilityState.ACTIVE:
		if facility["build_item_id"] == FACILITY_WORKBENCH and facility["current_recipe"] != null:
			cancel_crafting(facility_id)

	print("[FacilityController] Facility state: id=%d, %d -> %d" % [facility_id, old_state, new_state])

## 设施被摧毁处理
func _on_facility_destroyed(facility_id: int) -> void:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty():
		return

	# 储物箱：内容掉落
	if facility["build_item_id"] == FACILITY_STORAGE:
		_spawn_content_drops(facility)

	# 发射摧毁信号
	if _global_signals != null:
		_global_signals.facility_destroyed.emit(facility_id, facility["cell"])

	# 移除设施
	_facilities.erase(facility_id)
	print("[FacilityController] Facility destroyed: id=%d" % facility_id)

## 生成内容掉落
func _spawn_content_drops(facility: Dictionary) -> void:
	var contents: Array = facility["storage_contents"]
	var cell: Vector2i = facility["cell"]
	var base_pos: Vector2 = Vector2(cell.x * 32 + 16, cell.y * 32 + 16)

	for slot in contents:
		if slot["resource_id"] != 0 and slot["quantity"] > 0:
			# 随机偏移
			var random_offset: Vector2 = Vector2(
				randf_range(-16.0, 16.0),
				randf_range(-16.0, 16.0)
			)
			var world_pos: Vector2 = base_pos + random_offset

			# 发射掉落信号
			if _global_signals != null:
				_global_signals.resource_dropped.emit(slot["resource_id"], world_pos, slot["quantity"])

			print("[FacilityController] Drop spawned: resource=%d, quantity=%d" % [slot["resource_id"], slot["quantity"]])

# === 设施拆除 (TR-facility-005) ===

## 拆除设施（返还 50% 材料）
func demolish_facility(facility_id: int) -> Dictionary:
	var facility: Dictionary = get_facility_by_id(facility_id)
	if facility.is_empty():
		return {}

	# 储物箱内容处理：100% 掉落
	if facility["build_item_id"] == FACILITY_STORAGE:
		_spawn_content_drops(facility)

	# 计算材料返还 (50%)
	var refund: Dictionary = _calculate_demolition_refund(facility["build_item_id"])

	# 发射拆除信号
	if _global_signals != null:
		_global_signals.facility_demolished.emit(facility_id, facility["cell"])

	# 移除设施
	_facilities.erase(facility_id)

	print("[FacilityController] Facility demolished: id=%d, refund=%s" % [facility_id, str(refund)])
	return refund

## 计算拆除材料返还
func _calculate_demolition_refund(build_item_id: int) -> Dictionary:
	# 储物箱成本: 铁×4, 木×6 (假设)
	if build_item_id == FACILITY_STORAGE:
		return {
			"iron": int(4 * DEMOLITION_REFUND_RATE),
			"wood": int(6 * DEMOLITION_REFUND_RATE)
		}
	# 工作台成本: 铁×2, 木×4 (假设)
	elif build_item_id == FACILITY_WORKBENCH:
		return {
			"iron": int(2 * DEMOLITION_REFUND_RATE),
			"wood": int(4 * DEMOLITION_REFUND_RATE)
		}
	return {}

# === 辅助方法 ===

## 根据 tile_id 获取 build_item_id
func _get_build_item_id_for_tile(tile_id: int) -> int:
	# MVP 简化：直接映射
	# tile_id 2000 -> 储物箱 (400)
	# tile_id 2001 -> 工作台 (410)
	if tile_id == 2000:
		return FACILITY_STORAGE
	elif tile_id == 2001:
		return FACILITY_WORKBENCH
	return 0

## 获取设施基础硬度
func _get_facility_hardness(build_item_id: int) -> float:
	if build_item_id == FACILITY_STORAGE:
		return 50.0  # 储物箱硬度
	elif build_item_id == FACILITY_WORKBENCH:
		return 40.0  # 工作台硬度
	return 30.0

# === _process 循环 ===

func _process(delta: float) -> void:
	# 更新所有工作台的合成进度
	for facility_id in _facilities:
		var facility: Dictionary = _facilities[facility_id]
		if facility["build_item_id"] == FACILITY_WORKBENCH and facility["current_recipe"] != null:
			update_crafting_progress(facility_id, delta)