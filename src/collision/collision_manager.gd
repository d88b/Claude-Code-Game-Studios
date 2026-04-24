extends Node
# CollisionManager — 方块碰撞查询系统
## CollisionManager — 方块碰撞查询系统
## 提供 swept collision、raycast、solid cell 查询接口
## Core layer system (ADR-006, GDD block-collision-system.md)
##
## 依赖注入: 需要通过 set_tilemap_world() 设置 TileMapWorld 引用
## 或在场景树中查找名为 "TileMapWorld" 的节点

# === 常量定义 (来自 entities.yaml) ===
## Swept collision 最大步数 (TK-018) — 32 for performance optimization
const MAX_SWEPT_STEPS: int = 32
## Raycast 最大步数
const MAX_RAYCAST_STEPS: int = 128
## 碰撞检测最小阈值
const COLLISION_EPSILON: float = 0.001
## 最大搜索半径 (单元格)
const MAX_SEARCH_RADIUS_CELLS: int = 32
## 严重程度基准值 (TK-019)
const SEVERITY_BASE: float = 100.0
## 严重程度阈值 — 强碰撞
const SEVERITY_THRESHOLD_HIGH: float = 0.7
## 严重程度阈值 — 轻碰撞
const SEVERITY_THRESHOLD_LOW: float = 0.3

# === 单元格尺寸常量 ===
## 单元格尺寸 (像素) — 与 TileMapWorld.CELL_SIZE 同步
const CELL_SIZE: int = 32

# === 碰撞层级常量 ===
## 地形碰撞层 (Bit 0)
const COLLISION_TERRAIN: int = 1
## 建筑碰撞层 (Bit 1)
const COLLISION_STRUCTURE: int = 2
## 平台碰撞层 (Bit 2)
const COLLISION_PLATFORM: int = 4
## 敌人碰撞层 (Bit 3)
const COLLISION_ENEMY_BODY: int = 8
## 战车碰撞层 (Bit 6)
const COLLISION_PLAYER_BODY: int = 64

# === 碰撞过滤器常量 ===
## 可破坏墙壁过滤器
const FILTER_DESTROYABLE: int = 0x01
## 加固墙壁过滤器
const FILTER_REINFORCED: int = 0x02
## 所有墙壁过滤器
const FILTER_ALL_WALLS: int = 0xFF

# === 依赖引用 ===
## TileMapWorld 节点引用 (外部注入或场景查找)
var _tilemap_world: Node = null
## BlockTypeDB autoload 引用
var _block_type_db: Node = null
## GlobalSignals autoload 引用
var _global_signals: Node = null

# === 待处理修改队列 ===
## 按帧排队等待物理帧边界执行
var _pending_modifications: Array[Dictionary] = []

# === 碰撞结果类 ===
class SweptCollisionResult:
	## 是否碰撞
	var hit: bool = false
	## 碰撞位置
	var hit_position: Vector2 = Vector2.ZERO
	## 碰撞单元格
	var hit_cell: Vector2i = Vector2i.ZERO
	## 碰撞方块 ID
	var hit_block_id: int = 0
	## 剩余速度
	var remaining_velocity: Vector2 = Vector2.ZERO
	## 碰撞严重程度
	var severity: float = 0.0

	func _init(h: bool = false, pos: Vector2 = Vector2.ZERO, cell: Vector2i = Vector2i.ZERO,
			block: int = 0, rem: Vector2 = Vector2.ZERO, sev: float = 0.0) -> void:
		hit = h
		hit_position = pos
		hit_cell = cell
		hit_block_id = block
		remaining_velocity = rem
		severity = sev

	static func no_collision() -> SweptCollisionResult:
		return SweptCollisionResult.new()

	static func collision(pos: Vector2, cell: Vector2i, block: int, rem: Vector2, sev: float) -> SweptCollisionResult:
		return SweptCollisionResult.new(true, pos, cell, block, rem, sev)

# === Raycast 结果类 ===
class RaycastResult:
	## 碰撞位置
	var position: Vector2 = Vector2.ZERO
	## 碰撞单元格
	var cell: Vector2i = Vector2i.ZERO
	## 碰撞法线
	var normal: Vector2 = Vector2.ZERO
	## 碰撞方块 ID
	var block_id: int = 0

	func _init(pos: Vector2 = Vector2.ZERO, c: Vector2i = Vector2i.ZERO,
			n: Vector2 = Vector2.ZERO, b: int = 0) -> void:
		position = pos
		cell = c
		normal = n
		block_id = b

	static func no_hit() -> RaycastResult:
		return RaycastResult.new()

# === 依赖注入 API ===

## 设置 TileMapWorld 引用 (依赖注入)
func set_tilemap_world(tilemap: Node) -> void:
	_tilemap_world = tilemap

## 设置 BlockTypeDB 引用 (依赖注入)
func set_block_type_db(db: Node) -> void:
	_block_type_db = db

## 设置 GlobalSignals 引用 (依赖注入)
func set_global_signals(signals: Node) -> void:
	_global_signals = signals

## 获取 TileMapWorld 引用
func get_tilemap_world() -> Node:
	return _tilemap_world

## 检查依赖是否已初始化
func is_initialized() -> bool:
	return _tilemap_world != null and _block_type_db != null

# === 查询 API ===

## 检查单元格是否为实心 (碰撞层查询)
## grid_pos: 单元格坐标
## 返回: true 表示该位置有碰撞方块
func is_cell_solid(grid_pos: Vector2i) -> bool:
	if not is_initialized():
		push_warning("[CollisionManager] Dependencies not initialized")
		return false

	# 检查碰撞层
	var tile_type: int = _tilemap_world.get_tile_type(grid_pos, 1)  # terrain_base
	if tile_type >= 0:
		var collision_shape: int = _block_type_db.get_collision_shape(tile_type)
		if collision_shape == 1:  # FULL collision
			return true

	tile_type = _tilemap_world.get_tile_type(grid_pos, 2)  # structures
	if tile_type >= 0:
		var collision_shape: int = _block_type_db.get_collision_shape(tile_type)
		if collision_shape == 1:  # FULL collision
			return true

	# 平台层 (collision_shape=2) 不算实心
	return false

## 获取单元格碰撞形状 (0=无, 1=完整, 2=平台)
func get_cell_collision_shape(grid_pos: Vector2i) -> int:
	if not is_initialized():
		return 0

	# 先检查建筑层
	var tile_type: int = _tilemap_world.get_tile_type(grid_pos, 2)
	if tile_type >= 0:
		return _block_type_db.get_collision_shape(tile_type)

	# 再检查地形层
	tile_type = _tilemap_world.get_tile_type(grid_pos, 1)
	if tile_type >= 0:
		return _block_type_db.get_collision_shape(tile_type)

	return 0  # 无碰撞

## Raycast 碰撞检测 (DDA traversal)
## start: 起点世界坐标
## end: 终点世界坐标
## mask: 碰撞掩码 (可选)
## 返回: RaycastResult 或空结果
func raycast_tile_collision(start: Vector2, end: Vector2, mask: int = COLLISION_TERRAIN | COLLISION_STRUCTURE) -> RaycastResult:
	if not is_initialized():
		return RaycastResult.no_hit()

	var direction: Vector2 = end - start
	var distance: float = direction.length()

	if distance < COLLISION_EPSILON:
		return RaycastResult.no_hit()

	var dir_normalized: Vector2 = direction.normalized()
	var cell_size_f: float = float(CELL_SIZE)

	# DDA 初始化
	var current_cell: Vector2i = world_to_cell(start)
	var end_cell: Vector2i = world_to_cell(end)

	var step: Vector2i = Vector2i(
		1 if dir_normalized.x >= 0 else -1,
		1 if dir_normalized.y >= 0 else -1
	)

	var cell_start: Vector2 = cell_to_world_top_left(current_cell)

	var t_max: Vector2 = Vector2()
	var t_delta: Vector2 = Vector2()

	# X 轴 DDA 参数
	if dir_normalized.x != 0:
		if step.x > 0:
			t_max.x = (cell_start.x + cell_size_f - start.x) / dir_normalized.x
		else:
			t_max.x = (cell_start.x - start.x) / dir_normalized.x
		t_delta.x = cell_size_f / abs(dir_normalized.x)
	else:
		t_max.x = INF

	# Y 轴 DDA 参数
	if dir_normalized.y != 0:
		if step.y > 0:
			t_max.y = (cell_start.y + cell_size_f - start.y) / dir_normalized.y
		else:
			t_max.y = (cell_start.y - start.y) / dir_normalized.y
		t_delta.y = cell_size_f / abs(dir_normalized.y)
	else:
		t_max.y = INF

	var steps: int = 0

	while steps < MAX_RAYCAST_STEPS:
		# 检查当前单元格碰撞
		if is_cell_solid(current_cell):
			var collision_pos: Vector2 = start + dir_normalized * min(t_max.x, t_max.y) * cell_size_f
			var normal: Vector2 = _calculate_raycast_normal(step, t_max)
			var block_id: int = _get_block_id_at(current_cell)
			return RaycastResult.new(collision_pos, current_cell, normal, block_id)

		# DDA 步进
		if t_max.x < t_max.y:
			current_cell.x += step.x
			t_max.x += t_delta.x
		else:
			current_cell.y += step.y
			t_max.y += t_delta.y

		steps += 1

		# 到达终点检查
		if (step.x > 0 and current_cell.x > end_cell.x) or \
			(step.x < 0 and current_cell.x < end_cell.x) or \
			(step.y > 0 and current_cell.y > end_cell.y) or \
			(step.y < 0 and current_cell.y < end_cell.y):
			break

	return RaycastResult.no_hit()

## Swept collision 检测 (DDA traversal for vehicle-sized body)
## body_rect: 碰撞体边界 (世界坐标)
## velocity: 速度向量
## 返回: SweptCollisionResult
func check_swept_collision(body_rect: Rect2, velocity: Vector2) -> SweptCollisionResult:
	if not is_initialized():
		return SweptCollisionResult.no_collision()

	var motion_length: float = velocity.length()

	# 静止检测
	if motion_length < COLLISION_EPSILON:
		return _check_static_collision(body_rect)

	# DDA traversal
	var cell_size_f: float = float(CELL_SIZE)
	var steps: int = maxi(int(ceil(motion_length / cell_size_f)), 1)
	steps = mini(steps, MAX_SWEPT_STEPS)

	var t_step: float = 1.0 / float(steps)
	var direction: Vector2 = velocity.normalized()

	# 碰撞体单元格偏移 (假设 2x2 碰撞体)
	var shape_offsets: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1)
	]

	var seen_cells: Dictionary = {}

	for i in range(steps + 1):
		var t: float = float(i) * t_step
		var check_pos: Vector2 = body_rect.position + velocity * t
		var check_cell: Vector2i = world_to_cell(check_pos)

		for offset: Vector2i in shape_offsets:
			var cell: Vector2i = check_cell + offset
			if cell in seen_cells:
				continue
			seen_cells[cell] = true

			if is_cell_solid(cell):
				var hit_pos: Vector2 = check_pos
				var remaining: Vector2 = velocity * (1.0 - t)
				var block_id: int = _get_block_id_at(cell)
				var severity: float = calculate_severity(velocity, 1.0, 1.0, 1.0)
				return SweptCollisionResult.collision(hit_pos, cell, block_id, remaining, severity)

	return SweptCollisionResult.no_collision()

## 静态碰撞检测 (无运动)
func _check_static_collision(body_rect: Rect2) -> SweptCollisionResult:
	if not is_initialized():
		return SweptCollisionResult.no_collision()

	var shape_offsets: Array[Vector2i] = [
		Vector2i(0, 0), Vector2i(1, 0),
		Vector2i(0, 1), Vector2i(1, 1)
	]

	var start_cell: Vector2i = world_to_cell(body_rect.position)

	for offset: Vector2i in shape_offsets:
		var cell: Vector2i = start_cell + offset
		if is_cell_solid(cell):
			var block_id: int = _get_block_id_at(cell)
			return SweptCollisionResult.collision(body_rect.position, cell, block_id, Vector2.ZERO, 0.0)

	return SweptCollisionResult.no_collision()

## 搜索最近碰撞 (WALL_BREAKER 目标定位)
## pos: 搜索中心 (世界坐标)
## radius: 搜索半径 (像素)
## filter: 碰撞过滤器掩码
## 返回: Dictionary {cell, distance} 或空
func get_nearest_collision(pos: Vector2, radius: float, filter: int = FILTER_ALL_WALLS) -> Dictionary:
	if radius <= 0.0 or not is_initialized():
		return {}

	var center_cell: Vector2i = world_to_cell(pos)
	var radius_cells: int = int(radius / CELL_SIZE) + 1
	radius_cells = mini(radius_cells, MAX_SEARCH_RADIUS_CELLS)

	var nearest_cell: Vector2i
	var nearest_dist: float = INF

	for dx in range(-radius_cells, radius_cells + 1):
		for dy in range(-radius_cells, radius_cells + 1):
			var check_cell: Vector2i = center_cell + Vector2i(dx, dy)
			if not is_cell_solid(check_cell):
				continue
			if not matches_collision_filter(check_cell, filter):
				continue

			var cell_center: Vector2 = cell_to_world_center(check_cell)
			var dist: float = (cell_center - pos).length()

			if dist < nearest_dist:
				nearest_dist = dist
				nearest_cell = check_cell

	if nearest_dist < INF:
		return {cell = nearest_cell, distance = nearest_dist}
	return {}

## 检查单元格是否匹配碰撞过滤器
func matches_collision_filter(cell: Vector2i, filter: int) -> bool:
	var block_id: int = _get_block_id_at(cell)
	if block_id <= 0:
		return false

	# ID 范围映射 (来自 block_type_database.md)
	# 400-449: 标准可破坏墙壁
	# 450-499: 加固墙壁
	var block_flags: int = _get_block_flags(block_id)
	return (block_flags & filter) != 0

## 获取方块过滤器标志
func _get_block_flags(block_id: int) -> int:
	# ID 100-199: 地形方块 (可破坏)
	if block_id >= 100 and block_id < 200:
		return FILTER_DESTROYABLE
	# ID 1000-1499: 建筑方块 (可破坏)
	if block_id >= 1000 and block_id < 1500:
		return FILTER_DESTROYABLE
	# ID 1500-1999: 加固建筑
	if block_id >= 1500 and block_id < 2000:
		return FILTER_DESTROYABLE | FILTER_REINFORCED
	return 0

## 计算碰撞严重程度
## velocity: 碰撞速度
## integrity_ratio: 战车完整度 (0.0-1.0)
## obstacle_significance: 障碍物重要性 (1.0-2.0)
## 返回: 严重程度值 [0.0, 1.0]
func calculate_severity(velocity: Vector2, integrity_ratio: float, obstacle_significance: float, max_speed: float = 10.0) -> float:
	var impact_speed: float = velocity.length() / float(CELL_SIZE)  # 转换为 cells/sec

	# 速度比例
	var speed_ratio: float = impact_speed / max_speed
	speed_ratio = clampf(speed_ratio, 0.0, 1.0)

	# 完整度因子 (低完整度 = 更剧烈)
	var integrity_factor: float = 1.0 + (1.0 - integrity_ratio) * 0.5

	# 高速滑擦最小反馈
	var grazing_baseline: float = 0.0
	if speed_ratio > 0.5:
		grazing_baseline = 0.15

	# 严重程度公式
	var severity: float = grazing_baseline + speed_ratio * integrity_factor * obstacle_significance
	return clampf(severity, 0.0, 1.0)

# === 方块修改队列 ===

## 排队方块修改 (物理帧安全)
## cell: 单元格坐标
## layer: 层级索引
## operation: 操作类型 (0=DELETE, 1=SET)
## tile_data: 方块数据 (SET 时需要)
func queue_tile_modification(cell: Vector2i, layer: int, operation: int, tile_data: Dictionary = {}) -> void:
	_pending_modifications.append({
		cell = cell,
		layer = layer,
		operation = operation,
		tile_data = tile_data
	})

## 物理帧处理排队修改
func _physics_process(_delta: float) -> void:
	if _pending_modifications.is_empty():
		return

	var affected_cells: Array[Vector2i] = []

	for mod: Dictionary in _pending_modifications:
		var cell: Vector2i = mod.cell
		var layer: int = mod.layer

		# 记录受影响单元格
		if not cell in affected_cells:
			affected_cells.append(cell)

		# 发出碰撞变化信号 (通过 GlobalSignals autoload)
		if _global_signals != null:
			if mod.operation == 0:  # DELETE
				_global_signals.block_dug.emit(cell, 0)
			elif mod.operation == 1:  # SET
				var block_id: int = mod.tile_data.get("block_id", 0)
				_global_signals.block_placed.emit(cell, block_id, layer)

	_pending_modifications.clear()

# === 坐标转换辅助方法 ===

## 世界坐标 → 单元格坐标
func world_to_cell(world_pos: Vector2) -> Vector2i:
	var x: int = int(world_pos.x / CELL_SIZE)
	var y: int = int(world_pos.y / CELL_SIZE)
	return Vector2i(x, y)

## 单元格坐标 → 世界坐标 (单元格中心)
func cell_to_world_center(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		(grid_pos.x + 0.5) * CELL_SIZE,
		(grid_pos.y + 0.5) * CELL_SIZE
	)

## 单元格坐标 → 世界坐标 (单元格左上角)
func cell_to_world_top_left(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * CELL_SIZE,
		grid_pos.y * CELL_SIZE
	)

# === 内部辅助方法 ===

## 获取单元格方块 ID
func _get_block_id_at(cell: Vector2i) -> int:
	if not is_initialized():
		return 0

	var tile_type: int = _tilemap_world.get_tile_type(cell, 2)
	if tile_type >= 0:
		return tile_type

	tile_type = _tilemap_world.get_tile_type(cell, 1)
	if tile_type >= 0:
		return tile_type

	return 0

## 计算 raycast 碰撞法线
func _calculate_raycast_normal(step: Vector2i, t_max: Vector2) -> Vector2:
	if t_max.x < t_max.y:
		return Vector2(-step.x, 0.0)
	else:
		return Vector2(0.0, -step.y)

## 获取指定单元格区域内的所有方块
func get_tiles_in_rect(bounds: Rect2) -> Array[Vector2i]:
	if not is_initialized():
		return []

	var result: Array[Vector2i] = []
	var start_cell: Vector2i = world_to_cell(bounds.position)
	var end_cell: Vector2i = world_to_cell(bounds.end)

	for x in range(start_cell.x, end_cell.x + 1):
		for y in range(start_cell.y, end_cell.y + 1):
			var cell: Vector2i = Vector2i(x, y)
			if is_cell_solid(cell):
				result.append(cell)

	return result

# === 生命周期 ===

func _ready() -> void:
	# 自动查找依赖 (如果未手动注入)
	_auto_find_dependencies()
	print("[CollisionManager] initialized — MAX_SWEPT_STEPS=", MAX_SWEPT_STEPS)

## 自动查找场景中的依赖节点
func _auto_find_dependencies() -> void:
	# 查找 TileMapWorld 节点 (多种方式)
	if _tilemap_world == null:
		# 方式 1: 通过 group 查找
		var tilemap := get_tree().get_first_node_in_group("tilemap_world")
		if tilemap != null:
			_tilemap_world = tilemap
		# 方式 2: 当前场景的子节点查找
		elif get_tree().current_scene != null:
			for child in get_tree().current_scene.get_children():
				if child.name == "TileMapWorld" or child.is_in_group("tilemap_world"):
					_tilemap_world = child
					break
		# 方式 3: 父节点查找 (非 autoload 模式)
		elif get_parent() != null and get_parent().has_node("TileMapWorld"):
			_tilemap_world = get_parent().get_node("TileMapWorld")

	# 获取 BlockTypeDB autoload (通过场景树)
	if _block_type_db == null:
		_block_type_db = get_node_or_null("/root/BlockTypeDB")

	# 获取 GlobalSignals autoload (通过场景树)
	if _global_signals == null:
		_global_signals = get_node_or_null("/root/GlobalSignals")