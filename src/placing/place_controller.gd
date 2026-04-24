extends Node
# PlaceController — 方块放置控制器
## PlaceController — 方块放置控制器
## 管理 Select → Validate → Commit → Place 流程
## Core layer system (GDD block-placing-system.md)

# === 常量定义 ===
## 单元格尺寸 (pixels)
const CELL_SIZE: int = 32

# === 状态枚举 ===
enum PlaceState {
	IDLE,        ## 无建造物品选择
	SELECTING,   ## 物品在手中，等待放置
	VALIDATE,    ## 执行验证检查
	BUILDING,    ## 建造进度进行中
	CANCELLED,   ## 玩家取消建造
	COMPLETE     ## 放置完成
}

# === 依赖引用 ===
## BuildValidator 引用
var _build_validator: Node = null
## TileMapWorld 引用
var _tilemap_world: Node = null
## CollisionManager 引用
var _collision_manager: Node = null
## GlobalSignals 引用
var _global_signals: Node = null
## BuildItemDB 引用
var _build_item_db: Node = null

# === 状态数据 ===
## 当前状态
var current_state: PlaceState = PlaceState.IDLE
## 当前选中物品 ID
var selected_item_id: int = 0
## 目标单元格
var target_cell: Vector2i = Vector2i.ZERO
## 玩家位置
var player_position: Vector2 = Vector2.ZERO
## 建造进度 (秒)
var construction_progress: float = 0.0
## 建造时间 (秒)
var build_time: float = 5.0
## 已扣除材料缓存 (用于取消返还)
var deducted_materials: Dictionary = {}

# === 信号 ===
## 状态变更信号
signal state_changed(new_state: PlaceState)
## 放置成功信号
signal placement_success(cell: Vector2i, item_id: int)
## 放置失败信号
signal placement_failed(reason: String)
## 建造进度更新信号
signal build_progress_updated(percent: float)

# === 依赖注入 API ===

func set_build_validator(validator: Node) -> void:
	_build_validator = validator

func set_tilemap_world(tilemap: Node) -> void:
	_tilemap_world = tilemap

func set_collision_manager(manager: Node) -> void:
	_collision_manager = manager

func set_global_signals(signals: Node) -> void:
	_global_signals = signals

func set_build_item_db(db: Node) -> void:
	_build_item_db = db

func is_initialized() -> bool:
	return _build_validator != null and _collision_manager != null

# === 公共 API ===

## 选择建造物品
func select_item(item_id: int) -> void:
	selected_item_id = item_id
	current_state = PlaceState.SELECTING
	state_changed.emit(current_state)

	# 获取建造时间
	if _build_item_db != null:
		build_time = _build_item_db.get_build_time(item_id)

## 尝试放置
func try_place(cell: Vector2i, player_pos: Vector2, inventory: Dictionary = {}) -> bool:
	if not is_initialized():
		placement_failed.emit("系统未初始化")
		return false

	if selected_item_id <= 0:
		placement_failed.emit("未选择建造物品")
		return false

	target_cell = cell
	player_position = player_pos

	# 执行验证
	var result: Object = _build_validator.validate_placement(
		selected_item_id, target_cell, player_pos, inventory
	)

	if not result.passed:
		current_state = PlaceState.IDLE
		placement_failed.emit(result.failure_message)
		state_changed.emit(current_state)
		return false

	# 扣除材料 (原子操作)
	deducted_materials = _build_item_db.get_build_cost(selected_item_id)

	# 开始建造
	current_state = PlaceState.BUILDING
	construction_progress = 0.0
	state_changed.emit(current_state)

	return true

## 取消建造
func cancel_build() -> void:
	if current_state != PlaceState.BUILDING:
		return

	# 返还材料 (stub — 需要 inventory 系统)
	deducted_materials.clear()

	current_state = PlaceState.CANCELLED
	state_changed.emit(current_state)

	# 返回 IDLE
	current_state = PlaceState.IDLE
	state_changed.emit(current_state)

## 获取建造进度百分比
func get_build_progress() -> float:
	if build_time <= 0:
		return 100.0
	return (construction_progress / build_time) * 100.0

# === 每帧处理 ===

func _process(delta: float) -> void:
	# 处理建造进度
	if current_state == PlaceState.BUILDING:
		construction_progress += delta

		var percent: float = get_build_progress()
		build_progress_updated.emit(percent)

		# 检查是否完成
		if construction_progress >= build_time:
			_complete_placement()

# === 内部方法 ===

## 完成放置
func _complete_placement() -> void:
	if not is_initialized():
		return

	# 获取输出方块 ID
	var item: Object = _build_item_db.get_build_item(selected_item_id)
	var output_tile_id: int = 0
	if item != null:
		output_tile_id = item.output_tile_id

	# 排队方块创建 (物理帧安全)
	_collision_manager.queue_tile_modification(
		target_cell, 2, 1,  # layer=2 (structures), operation=SET
		{block_id = output_tile_id}
	)

	# 发出成功信号
	if _global_signals != null:
		_global_signals.block_placed.emit(target_cell, selected_item_id, 2)

	placement_success.emit(target_cell, selected_item_id)

	# 更新状态
	current_state = PlaceState.COMPLETE
	state_changed.emit(current_state)

	# 返回 SELECTING (可继续放置)
	current_state = PlaceState.SELECTING
	construction_progress = 0.0
	state_changed.emit(current_state)

# === 测试辅助方法 ===

func set_target_for_test(cell: Vector2i, item_id: int) -> void:
	target_cell = cell
	selected_item_id = item_id

# === 生命周期 ===

func _ready() -> void:
	_auto_find_dependencies()
	print("[PlaceController] initialized")

## 自动查找依赖
func _auto_find_dependencies() -> void:
	if _build_item_db == null:
		_build_item_db = get_node_or_null("/root/BuildItemDB")
	if _global_signals == null:
		_global_signals = get_node_or_null("/root/GlobalSignals")