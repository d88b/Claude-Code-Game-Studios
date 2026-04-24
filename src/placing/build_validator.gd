extends Node
# BuildValidator — 建造验证器
## BuildValidator — 建造验证器
## 执行 V1-V6 验证链，检查放置条件
## Core layer system (GDD block-placing-system.md)

# === 常量定义 (来自 GDD) ===
## 最大放置距离 (cells)
const MAX_PLACE_RANGE: float = 5.0
## 单元格尺寸 (pixels)
const CELL_SIZE: int = 32
## 世界边界限制
const MAX_WORLD_BOUNDS: int = 1000

# === 验证结果类 ===
class ValidationResult:
	## 是否通过
	var passed: bool = false
	## 失败原因 (V1-V6)
	var failure_code: String = ""
	## 失败消息
	var failure_message: String = ""

	func _init(p: bool = false, code: String = "", msg: String = "") -> void:
		passed = p
		failure_code = code
		failure_message = msg

	static func success() -> ValidationResult:
		return ValidationResult.new(true, "", "")

	static func failure(code: String, msg: String) -> ValidationResult:
		return ValidationResult.new(false, code, msg)

# === 依赖引用 ===
## TileMapWorld 节点引用
var _tilemap_world: Node = null
## BlockTypeDB autoload 引用
var _block_type_db: Node = null
## BuildItemDB autoload 引用
var _build_item_db: Node = null
## CollisionManager 引用
var _collision_manager: Node = null

# === 依赖注入 API ===

func set_tilemap_world(tilemap: Node) -> void:
	_tilemap_world = tilemap

func set_block_type_db(db: Node) -> void:
	_block_type_db = db

func set_build_item_db(db: Node) -> void:
	_build_item_db = db

func set_collision_manager(manager: Node) -> void:
	_collision_manager = manager

func is_initialized() -> bool:
	return _tilemap_world != null and _build_item_db != null

# === 验证 API ===

## 执行完整验证链
func validate_placement(item_id: int, target_cell: Vector2i, player_pos: Vector2, inventory: Dictionary = {}) -> ValidationResult:
	if not is_initialized():
		return ValidationResult.failure("V0", "系统未初始化")

	# V1: 世界边界检查
	var v1: ValidationResult = check_world_bounds(target_cell)
	if not v1.passed:
		return v1

	# V2: 占用检查 (Layer 2)
	var v2: ValidationResult = check_cell_occupied(target_cell)
	if not v2.passed:
		return v2

	# V3: 距离检查
	var v3: ValidationResult = check_placement_range(target_cell, player_pos)
	if not v3.passed:
		return v3

	# V4: 可建造性检查
	var v4: ValidationResult = check_buildability(item_id)
	if not v4.passed:
		return v4

	# V5: 类别特定规则
	var v5: ValidationResult = check_category_rules(item_id, target_cell)
	if not v5.passed:
		return v5

	# V6: 材料检查
	var v6: ValidationResult = check_material_cost(item_id, inventory)
	if not v6.passed:
		return v6

	return ValidationResult.success()

# === 单项验证检查 ===

## V1: 世界边界检查
func check_world_bounds(cell: Vector2i) -> ValidationResult:
	if cell.x < -MAX_WORLD_BOUNDS or cell.x > MAX_WORLD_BOUNDS:
		return ValidationResult.failure("V1", "超出世界边界")
	if cell.y < -MAX_WORLD_BOUNDS or cell.y > MAX_WORLD_BOUNDS:
		return ValidationResult.failure("V1", "超出世界边界")
	return ValidationResult.success()

## V2: 占用检查 (Layer 2)
func check_cell_occupied(cell: Vector2i) -> ValidationResult:
	if _tilemap_world == null:
		return ValidationResult.failure("V2", "TileMapWorld 未初始化")

	var tile_type: int = _tilemap_world.get_tile_type(cell, 2)  # Layer 2 = structures
	if tile_type >= 0:
		return ValidationResult.failure("V2", "位置已被占用")
	return ValidationResult.success()

## V3: 距离检查
func check_placement_range(cell: Vector2i, player_pos: Vector2) -> ValidationResult:
	var cell_center: Vector2 = Vector2(
		(cell.x + 0.5) * CELL_SIZE,
		(cell.y + 0.5) * CELL_SIZE
	)

	var distance_sq: float = player_pos.distance_squared_to(cell_center)
	var max_range_sq: float = (MAX_PLACE_RANGE * CELL_SIZE) * (MAX_PLACE_RANGE * CELL_SIZE)

	if distance_sq > max_range_sq:
		return ValidationResult.failure("V3", "超出放置范围")
	return ValidationResult.success()

## V4: 可建造性检查
func check_buildability(item_id: int) -> ValidationResult:
	if _build_item_db == null:
		return ValidationResult.failure("V4", "BuildItemDB 未初始化")

	var item: Object = _build_item_db.get_build_item(item_id)
	if item == null:
		return ValidationResult.failure("V4", "建造物品不存在")

	if not _block_type_db.is_buildable(item.output_tile_id):
		return ValidationResult.failure("V4", "此方块不可建造")

	return ValidationResult.success()

## V5: 类别特定规则检查
func check_category_rules(item_id: int, cell: Vector2i) -> ValidationResult:
	if _build_item_db == null:
		return ValidationResult.failure("V5", "BuildItemDB 未初始化")

	var item: Object = _build_item_db.get_build_item(item_id)
	if item == null:
		return ValidationResult.failure("V5", "建造物品不存在")

	var category: String = item.category

	# 类别规则映射
	match category:
		"floor":
			return ValidationResult.success()  # 无要求
		"wall":
			return check_adjacent_support(cell)
		"turret", "trap", "facility":
			return check_floor_foundation(cell)
		_:
			return ValidationResult.success()

## 检查相邻支持 (wall 类别)
func check_adjacent_support(cell: Vector2i) -> ValidationResult:
	# 检查四方向邻居
	var neighbors: Array[Vector2i] = [
		cell + Vector2i(0, -1),  # 上
		cell + Vector2i(0, 1),   # 下
		cell + Vector2i(-1, 0),  # 左
		cell + Vector2i(1, 0)    # 右
	]

	for neighbor: Vector2i in neighbors:
		# 检查 Layer 1 (floor) 或 Layer 2 (wall)
		var floor_type: int = _tilemap_world.get_tile_type(neighbor, 1)
		var wall_type: int = _tilemap_world.get_tile_type(neighbor, 2)

		if floor_type >= 0 or wall_type >= 0:
			return ValidationResult.success()

	return ValidationResult.failure("V5", "墙壁需要相邻支持")

## 检查地板基础 (turret/trap/facility 类别)
func check_floor_foundation(cell: Vector2i) -> ValidationResult:
	var floor_type: int = _tilemap_world.get_tile_type(cell, 1)
	if floor_type < 0:
		return ValidationResult.failure("V5", "需要地板基础")
	return ValidationResult.success()

## V6: 材料检查
func check_material_cost(item_id: int, inventory: Dictionary) -> ValidationResult:
	if _build_item_db == null:
		return ValidationResult.failure("V6", "BuildItemDB 未初始化")

	if inventory.is_empty():
		return ValidationResult.success()  # stub: 无库存系统时跳过

	var cost: Dictionary = _build_item_db.get_build_cost(item_id)

	for resource_id: int in cost.keys():
		var required: int = cost[resource_id]
		var available: int = inventory.get(resource_id, 0)

		if available < required:
			return ValidationResult.failure("V6", "材料不足")

	return ValidationResult.success()

## 检查地形支持 (BuildItemDB 接口)
func check_terrain_support(item_id: int, terrain_type: String) -> bool:
	if _build_item_db == null:
		return false
	return _build_item_db.check_terrain_support(item_id, terrain_type)

# === 辅助方法 ===

## 计算距离 (用于 UI 显示)
func get_distance_to_cell(cell: Vector2i, player_pos: Vector2) -> float:
	var cell_center: Vector2 = Vector2(
		(cell.x + 0.5) * CELL_SIZE,
		(cell.y + 0.5) * CELL_SIZE
	)
	return player_pos.distance_to(cell_center)

## 检查是否在放置范围内
func is_in_placement_range(cell: Vector2i, player_pos: Vector2) -> bool:
	var result: ValidationResult = check_placement_range(cell, player_pos)
	return result.passed

# === 生命周期 ===

func _ready() -> void:
	_auto_find_dependencies()
	print("[BuildValidator] initialized — MAX_PLACE_RANGE=", MAX_PLACE_RANGE)

## 自动查找依赖
func _auto_find_dependencies() -> void:
	if _block_type_db == null:
		_block_type_db = get_node_or_null("/root/BlockTypeDB")
	if _build_item_db == null:
		_build_item_db = get_node_or_null("/root/BuildItemDB")