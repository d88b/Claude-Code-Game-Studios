extends Node
# DigController — 方块挖掘控制器
## DigController — 方块挖掘控制器
## 实现 damage accumulation model，处理挖掘输入和方块破坏
## Core layer system (GDD block-digging-system.md)

# === 常量定义 (来自 GDD) ===
## 基准挖掘速率 (damage/sec)
const BASE_DIG_RATE: float = 30.0
## 最大挖掘距离 (cells)
const MAX_DIG_RANGE: float = 3.0
## 单元格尺寸 (pixels)
const CELL_SIZE: int = 32
## 移动打断容忍度 (cells/sec)
const MOVEMENT_INTOLERANCE: float = 0.1

# === 工具层级倍率 ===
## Tier 0: 徒手 (0.5)
const TIER_0_MODIFIER: float = 0.5
## Tier 1: 基础工具 (1.0)
const TIER_1_MODIFIER: float = 1.0
## Tier 2: 强化工具 (2.0)
const TIER_2_MODIFIER: float = 2.0
## Tier 3: 魔导工具 (4.0)
const TIER_3_MODIFIER: float = 4.0

# === 进度条阈值 ===
## 损坏状态阈值 (50%)
const THRESHOLD_DAMAGED: float = 0.5
## 临界状态阈值 (80%)
const THRESHOLD_CRITICAL: float = 0.8

# === 挖掘状态枚举 ===
enum DigState {
	HIDDEN,     ## 无有效目标
	ACTIVE,     ## 持续挖掘中
	PAUSED,     ## 输入中断但目标仍有效
	BLOCKED,    ## 目标有效但无法继续 (如移动中)
	INVALID     ## 目标验证失败
}

# === 依赖引用 ===
## TileMapWorld 节点引用
var _tilemap_world: Node = null
## BlockTypeDB autoload 引用
var _block_type_db: Node = null
## CollisionManager 引用
var _collision_manager: Node = null
## GlobalSignals autoload 引用
var _global_signals: Node = null
## InputManager autoload 引用
var _input_manager: Node = null

# === 挖掘状态数据 ===
## 当前挖掘状态
var current_state: DigState = DigState.HIDDEN
## 当前目标单元格
var target_cell: Vector2i = Vector2i.ZERO
## 当前目标方块 ID
var target_block_id: int = 0
## 累积伤害
var accumulated_damage: float = 0.0
## 目标硬度
var target_hardness: int = 0
## 当前工具层级
var current_tool_tier: int = 0
## 玩家位置 (用于距离计算)
var player_position: Vector2 = Vector2.ZERO

# === 状态变更信号 ===
## 状态变更信号
signal state_changed(new_state: DigState)
## 进度更新信号
signal progress_updated(percent: float)
## 方块破坏信号
signal block_destroyed(cell: Vector2i, block_id: int)

# === 依赖注入 API ===

func set_tilemap_world(tilemap: Node) -> void:
	_tilemap_world = tilemap

func set_block_type_db(db: Node) -> void:
	_block_type_db = db

func set_collision_manager(manager: Node) -> void:
	_collision_manager = manager

func set_global_signals(signals: Node) -> void:
	_global_signals = signals

func set_input_manager(input: Node) -> void:
	_input_manager = input

func is_initialized() -> bool:
	return _tilemap_world != null and _block_type_db != null and _collision_manager != null

# === 查询 API ===

## 获取当前进度百分比
func get_progress_percent() -> float:
	if target_hardness <= 0:
		return 0.0
	return (accumulated_damage / float(target_hardness)) * 100.0

## 获取当前工具倍率
func get_tool_modifier() -> float:
	match current_tool_tier:
		0: return TIER_0_MODIFIER
		1: return TIER_1_MODIFIER
		2: return TIER_2_MODIFIER
		3: return TIER_3_MODIFIER
		_: return TIER_0_MODIFIER

## 检查目标是否有效
func is_target_valid() -> bool:
	return target_block_id > 0 and target_hardness > 0 and target_hardness < 255

## 检查目标是否在范围内
func is_target_in_range() -> bool:
	if player_position == Vector2.ZERO:
		return false
	var cell_center: Vector2 = Vector2(
		(target_cell.x + 0.5) * CELL_SIZE,
		(target_cell.y + 0.5) * CELL_SIZE
	)
	var distance: float = player_position.distance_to(cell_center)
	return distance <= MAX_DIG_RANGE * CELL_SIZE

## 获取预计破坏时间
func get_time_to_destroy() -> float:
	if target_hardness <= 0:
		return 0.0
	return float(target_hardness) / (BASE_DIG_RATE * get_tool_modifier())

# === 挖掘循环 ===

func _physics_process(delta: float) -> void:
	# 检查初始化
	if not is_initialized():
		return

	# 更新玩家位置 (stub — 应从战车属性系统获取)
	_update_player_position()

	# 检查挖掘输入
	var dig_active: bool = _check_dig_input()

	# 更新目标
	_update_target()

	# 验证目标
	_validate_target()

	# 处理挖掘循环
	if current_state == DigState.ACTIVE and dig_active:
		_process_dig_loop(delta)

	# 状态转换
	_update_state(dig_active)

# === 内部方法 ===

## 更新玩家位置 (stub)
func _update_player_position() -> void:
	# 从战车属性系统获取位置 (stub)
	player_position = Vector2(100.0, 100.0)

## 检查挖掘输入
func _check_dig_input() -> bool:
	if _input_manager == null:
		return false
	return Input.is_action_pressed("dig")

## 更新目标单元格
func _update_target() -> void:
	# 从光标位置计算目标 (stub — 应使用 raycast)
	# 当前使用玩家位置附近的单元格作为目标
	var player_cell: Vector2i = Vector2i(
		int(player_position.x / CELL_SIZE),
		int(player_position.y / CELL_SIZE)
	)

	# 检查玩家前方是否有方块
	var check_cell: Vector2i = player_cell + Vector2i(1, 0)

	if _tilemap_world != null:
		var tile_type: int = _tilemap_world.get_tile_type(check_cell, 1)
		if tile_type >= 0:
			target_cell = check_cell
			target_block_id = tile_type
			target_hardness = _block_type_db.get_hardness(tile_type)
			return

	# 无有效目标
	target_block_id = 0
	target_hardness = 0

## 验证目标有效性
func _validate_target() -> void:
	# 检查方块是否存在
	if target_block_id <= 0:
		current_state = DigState.INVALID
		return

	# 检查硬度 (不可破坏)
	if target_hardness >= 255:
		current_state = DigState.INVALID
		return

	# 检查距离
	if not is_target_in_range():
		current_state = DigState.INVALID
		return

	# 检查是否可破坏
	if _block_type_db != null:
		var destructibility: int = _block_type_db.get_tile_data(target_block_id).destructibility
		if destructibility == 0:
			current_state = DigState.INVALID
			return

## 处理挖掘循环
func _process_dig_loop(delta: float) -> void:
	if not is_target_valid():
		return

	# 计算伤害增量
	var damage_this_frame: float = BASE_DIG_RATE * get_tool_modifier() * delta

	# 累积伤害 (clamp 防止溢出)
	accumulated_damage = minf(accumulated_damage + damage_this_frame, float(target_hardness))

	# 发出进度更新信号
	var percent: float = get_progress_percent()
	progress_updated.emit(percent)

	# 检查是否达到阈值
	if accumulated_damage >= float(target_hardness):
		_trigger_block_destruction()

## 触发方块破坏
func _trigger_block_destruction() -> void:
	# 验证最终条件
	if accumulated_damage < float(target_hardness):
		return

	# 清除累积伤害
	accumulated_damage = 0.0

	# 排队方块删除 (物理帧安全)
	if _collision_manager != null:
		_collision_manager.queue_tile_modification(target_cell, 1, 0)  # layer=1, operation=DELETE

	# 发出方块破坏信号
	if _global_signals != null:
		_global_signals.block_dug.emit(target_cell, target_block_id)

	# 本地信号
	block_destroyed.emit(target_cell, target_block_id)

	# 更新状态
	current_state = DigState.HIDDEN
	state_changed.emit(current_state)

	# 清除目标
	target_block_id = 0
	target_hardness = 0

## 更新挖掘状态
func _update_state(dig_active: bool) -> void:
	var previous_state: DigState = current_state

	# 状态转换逻辑
	if current_state == DigState.INVALID:
		# 无效状态等待 0.5 秒后转 Hidden
		current_state = DigState.HIDDEN
	elif not is_target_valid():
		current_state = DigState.INVALID
	elif not dig_active and current_state == DigState.ACTIVE:
		current_state = DigState.PAUSED
	elif dig_active and current_state == DigState.PAUSED:
		current_state = DigState.ACTIVE
	elif dig_active and is_target_valid():
		if current_state != DigState.ACTIVE:
			current_state = DigState.ACTIVE

	# 发出状态变更信号
	if previous_state != current_state:
		state_changed.emit(current_state)

# === 设置工具层级 ===

func set_tool_tier(tier: int) -> void:
	current_tool_tier = clampi(tier, 0, 3)

# === 手动设置目标 (用于测试) ===

func set_target_for_test(cell: Vector2i, block_id: int, hardness: int) -> void:
	target_cell = cell
	target_block_id = block_id
	target_hardness = hardness
	accumulated_damage = 0.0

# === 重置累积伤害 ===

func reset_damage() -> void:
	accumulated_damage = 0.0

# === 生命周期 ===

func _ready() -> void:
	_auto_find_dependencies()
	print("[DigController] initialized — BASE_DIG_RATE=", BASE_DIG_RATE)

## 自动查找依赖
func _auto_find_dependencies() -> void:
	# 获取 BlockTypeDB autoload
	if _block_type_db == null:
		_block_type_db = get_node_or_null("/root/BlockTypeDB")

	# 获取 GlobalSignals autoload
	if _global_signals == null:
		_global_signals = get_node_or_null("/root/GlobalSignals")

	# 获取 InputManager autoload
	if _input_manager == null:
		_input_manager = get_node_or_null("/root/InputManager")