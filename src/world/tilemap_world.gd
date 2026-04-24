class_name TileMapWorld
extends Node2D
## TileMapWorld — 世界地图管理节点
## 管理所有 TileMapLayer 层级、区块加载、坐标转换
## Foundation layer system — 所有空间操作的基础

# === 常量定义 (来自 entities.yaml) ===
## 单元格尺寸：32 像素
const CELL_SIZE: int = 32
## 区块尺寸：32x32 单元格
const CHUNK_SIZE: int = 32
## 加载半径：3 个区块
const LOAD_RADIUS: int = 3
## 最大世界边界：±1000 单元格
const MAX_WORLD_BOUNDS: int = 1000

# === 层级节点引用 ===
## 背景层 — 环境装饰，远景，无碰撞
@onready var background_layer: TileMapLayer = $BackgroundLayer
## 地形基层 — 自然地面、洞穴墙壁、基岩，碰撞层 1
@onready var terrain_base_layer: TileMapLayer = $TerrainBaseLayer
## 建筑层 — 玩家建造的墙壁、设施、防御工事，碰撞层 2
@onready var structures_layer: TileMapLayer = $StructuresLayer
## 平台层 — 可行走平台、跳板，单向碰撞层 4
@onready var platforms_layer: TileMapLayer = $PlatformsLayer
## 覆盖层 — 临时标记、伤害指示、视觉效果，无碰撞
@onready var overlay_layer: TileMapLayer = $OverlayLayer

# === 区块管理数据 ===
## 已加载区块字典：{Vector2i chunk_id: ChunkData}
var _loaded_chunks: Dictionary = {}
## 修改单元格字典：{Vector2i cell: block_id} — 用于持久化
var _modified_cells: Dictionary = {}
## 卸载计时器字典：{Vector2i chunk_id: float}
var _unload_timers: Dictionary = {}
## 卸载延迟 (秒)
const UNLOAD_DELAY: float = 30.0
## 世界种子 (用于程序生成)
var world_seed: int = 12345

# === 区块数据类 ===
class ChunkData:
	## 区块 ID (Vector2i)
	var chunk_id: Vector2i
	## 是否已加载
	var is_loaded: bool = false
	## 地形基层单元格数据 (1024 int)
	var cells_terrain_base: Array[int] = []
	## 建筑层单元格数据
	var cells_structures: Array[int] = []
	## 是否有玩家修改
	var has_modifications: bool = false

	func _init(id: Vector2i) -> void:
		chunk_id = id
		# 初始化空数组 (32x32 = 1024)
		cells_terrain_base.resize(1024)
		cells_structures.resize(1024)

# === 坐标转换方法 ===

## 世界坐标 → 单元格坐标
## grid_pos = floor(world_pos / CELL_SIZE)
func world_to_cell(world_pos: Vector2) -> Vector2i:
	var x: int = int(world_pos.x / CELL_SIZE)
	var y: int = int(world_pos.y / CELL_SIZE)
	# 边界裁剪
	x = clampi(x, -MAX_WORLD_BOUNDS, MAX_WORLD_BOUNDS)
	y = clampi(y, -MAX_WORLD_BOUNDS, MAX_WORLD_BOUNDS)
	return Vector2i(x, y)

## 单元格坐标 → 世界坐标 (单元格中心)
## world_center = (cell + 0.5) * CELL_SIZE
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

## 单元格坐标 → 区块 ID
## chunk_id = cell / CHUNK_SIZE
func get_chunk_id_for_pos(grid_pos: Vector2i) -> Vector2i:
	return Vector2i(
		grid_pos.x / CHUNK_SIZE,
		grid_pos.y / CHUNK_SIZE
	)

# === 区块加载方法 (Story 003) ===

## 加载指定世界位置周围的区块
func load_chunks_around(world_pos: Vector2) -> void:
	var center_chunk: Vector2i = get_chunk_id_for_pos(world_to_cell(world_pos))

	# 加载 LOAD_RADIUS 范围内的区块
	for dx in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
		for dy in range(-LOAD_RADIUS, LOAD_RADIUS + 1):
			var chunk_id: Vector2i = center_chunk + Vector2i(dx, dy)
			if not _loaded_chunks.has(chunk_id):
				_load_chunk(chunk_id)
			# 重置卸载计时器
			_unload_timers[chunk_id] = UNLOAD_DELAY

## 加载单个区块
func _load_chunk(chunk_id: Vector2i) -> void:
	var chunk_data: ChunkData = ChunkData.new(chunk_id)

	# 检查是否有持久化的修改数据
	if _has_persisted_modifications(chunk_id):
		_load_persisted_chunk(chunk_data)
	else:
		# 程序生成地形
		_generate_terrain(chunk_data)

	# 应用到 TileMapLayer
	_apply_chunk_to_layers(chunk_data)

	_loaded_chunks[chunk_id] = chunk_data
	_unload_timers[chunk_id] = UNLOAD_DELAY

## 检查是否有持久化修改
func _has_persisted_modifications(chunk_id: Vector2i) -> bool:
	# 检查 modified_cells 中是否有此区块的数据
	for cell: Vector2i in _modified_cells.keys():
		var cell_chunk: Vector2i = get_chunk_id_for_pos(cell)
		if cell_chunk == chunk_id:
			return true
	return false

## 加载持久化的区块数据
func _load_persisted_chunk(chunk_data: ChunkData) -> void:
	chunk_data.has_modifications = true
	# 从 modified_cells 恢复数据 (stub)

## 程序生成地形 (Story 004)
func _generate_terrain(chunk_data: ChunkData) -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = world_seed + chunk_data.chunk_id.x * 1000 + chunk_data.chunk_id.y

	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var noise_val: float = _get_noise_value(chunk_data.chunk_id, x, y, rng)
			var block_id: int = _noise_to_block_type(noise_val)
			chunk_data.cells_terrain_base[y * CHUNK_SIZE + x] = block_id

## 获取噪声值
func _get_noise_value(chunk_id: Vector2i, local_x: int, local_y: int, rng: RandomNumberGenerator) -> float:
	# 使用简单噪声函数 (实际应使用 FastNoiseLite)
	var world_x: int = chunk_id.x * CHUNK_SIZE + local_x
	var world_y: int = chunk_id.y * CHUNK_SIZE + local_y
	return rng.randf()

## 噪声值转换为方块类型
func _noise_to_block_type(noise_val: float) -> int:
	# 噪声阈值映射
	if noise_val < 0.2:
		return 0  # 空 (洞穴)
	elif noise_val < 0.6:
		return 100  # 土地
	elif noise_val < 0.8:
		return 101  # 石头
	else:
		return 500  # 矿石

## 应用区块数据到层级
func _apply_chunk_to_layers(chunk_data: ChunkData) -> void:
	var chunk_origin: Vector2i = chunk_data.chunk_id * CHUNK_SIZE

	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var cell: Vector2i = chunk_origin + Vector2i(x, y)
			var terrain_id: int = chunk_data.cells_terrain_base[y * CHUNK_SIZE + x]
			if terrain_id > 0:
				terrain_base_layer.set_cell(cell, 0, Vector2i(terrain_id % 16, terrain_id / 16))

## 卸载区块处理 (每帧检查)
func _process(delta: float) -> void:
	# 更新卸载计时器
	var chunks_to_unload: Array[Vector2i] = []
	for chunk_id: Vector2i in _unload_timers.keys():
		_unload_timers[chunk_id] -= delta
		if _unload_timers[chunk_id] <= 0:
			chunks_to_unload.append(chunk_id)

	# 卸载过期区块
	for chunk_id: Vector2i in chunks_to_unload:
		_unload_chunk(chunk_id)

## 卸载单个区块
func _unload_chunk(chunk_id: Vector2i) -> void:
	var chunk_data: ChunkData = _loaded_chunks.get(chunk_id, null)
	if chunk_data == null:
		return

	# 如果有修改，持久化
	if chunk_data.has_modifications:
		_persist_chunk_modifications(chunk_data)

	# 从层级清除
	_clear_chunk_from_layers(chunk_data)

	# 移除缓存
	_loaded_chunks.erase(chunk_id)
	_unload_timers.erase(chunk_id)

## 持久化区块修改
func _persist_chunk_modifications(chunk_data: ChunkData) -> void:
	# 将修改数据写入 modified_cells (stub - 未实现)
	return

## 清除层级上的区块数据
func _clear_chunk_from_layers(chunk_data: ChunkData) -> void:
	var chunk_origin: Vector2i = chunk_data.chunk_id * CHUNK_SIZE
	for x in range(CHUNK_SIZE):
		for y in range(CHUNK_SIZE):
			var cell: Vector2i = chunk_origin + Vector2i(x, y)
			terrain_base_layer.erase_cell(cell)

# === 单元格查询方法 ===

## 获取指定层级单元格的 TileData
func get_tile_data(cell: Vector2i, layer: int) -> TileData:
	var layer_node: TileMapLayer = _get_layer_by_index(layer)
	if layer_node == null:
		return null
	return layer_node.get_cell_tile_data(cell)

## 获取指定层级单元格的 tile_type_id
## 返回 -1 表示空单元格
func get_tile_type(cell: Vector2i, layer: int) -> int:
	var data: TileData = get_tile_data(cell, layer)
	if data == null:
		return -1
	# tile_type_id 存储在 custom_data_0 (根据 ADR-001 数据模型)
	return data.get_custom_data("tile_type_id")

## 检查单元格是否为实心 (任一碰撞层有方块)
func is_cell_solid(cell: Vector2i) -> bool:
	# 检查 layers 1, 2, 3
	for layer in [1, 2, 3]:
		if get_tile_type(cell, layer) >= 0:
			return true
	return false

## 检查指定层级单元格是否被占用
func is_cell_occupied(cell: Vector2i, layer: int) -> bool:
	return get_tile_type(cell, layer) >= 0

# === 方块伤害状态机 (Story 005) ===

## 方块状态枚举
enum TileState { INTACT, DAMAGED, CRITICAL, DESTROYED }

## 方块伤害数据类
class TileDamageData:
	var grid_pos: Vector2i
	var block_id: int
	var hardness: int
	var damage_accumulated: int = 0
	var state: TileState = TileState.INTACT

## 方块伤害状态缓存：{Vector2i: TileDamageData}
var _tile_damage_state: Dictionary = {}

## 应用伤害到方块
## 返回溢出伤害值
func apply_damage(grid_pos: Vector2i, amount: int) -> int:
	# 获取或创建方块伤害数据
	if not _tile_damage_state.has(grid_pos):
		var block_id: int = get_tile_type(grid_pos, 1)
		if block_id < 0:
			block_id = get_tile_type(grid_pos, 2)
		if block_id < 0:
			return amount  # 没有方块，返回全部伤害

		var hardness: int = BlockTypeDB.get_hardness(block_id)
		var tile_data: TileDamageData = TileDamageData.new()
		tile_data.grid_pos = grid_pos
		tile_data.block_id = block_id
		tile_data.hardness = hardness
		_tile_damage_state[grid_pos] = tile_data

	var tile: TileDamageData = _tile_damage_state[grid_pos]

	# 已摧毁的方块返回全部伤害
	if tile.state == TileState.DESTROYED:
		return amount

	# 累积伤害
	tile.damage_accumulated += amount
	_update_tile_state(tile)

	# 检查是否摧毁
	if tile.state == TileState.DESTROYED:
		var overflow: int = tile.damage_accumulated - tile.hardness
		_destroy_tile(grid_pos)
		GlobalSignals.block_dug.emit(grid_pos, tile.block_id)
		return overflow

	return 0  # 无溢出

## 更新方块状态
func _update_tile_state(tile: TileDamageData) -> void:
	if tile.hardness <= 0:
		tile.state = TileState.DESTROYED
		return

	var damage_ratio: float = float(tile.damage_accumulated) / float(tile.hardness)

	if tile.damage_accumulated >= tile.hardness:
		tile.state = TileState.DESTROYED
	elif damage_ratio >= 0.8:
		# 低硬度方块跳过 CRITICAL 状态
		if tile.hardness <= 5:
			tile.state = TileState.DESTROYED
		else:
			tile.state = TileState.CRITICAL
	elif tile.damage_accumulated > 0:
		tile.state = TileState.DAMAGED
	else:
		tile.state = TileState.INTACT

## 摧毁方块
func _destroy_tile(grid_pos: Vector2i) -> void:
	# 从层级移除方块
	terrain_base_layer.erase_cell(grid_pos)
	structures_layer.erase_cell(grid_pos)

	# 清除伤害状态
	_tile_damage_state.erase(grid_pos)

	# 记录修改
	_modified_cells[grid_pos] = 0  # 0 = 空

## 获取方块当前状态
func get_tile_state(grid_pos: Vector2i) -> TileState:
	if not _tile_damage_state.has(grid_pos):
		return TileState.INTACT
	return _tile_damage_state[grid_pos].state

## 获取方块累积伤害
func get_tile_damage(grid_pos: Vector2i) -> int:
	if not _tile_damage_state.has(grid_pos):
		return 0
	return _tile_damage_state[grid_pos].damage_accumulated

# === 内部辅助方法 ===

func _get_layer_by_index(layer_index: int) -> TileMapLayer:
	match layer_index:
		0: return background_layer
		1: return terrain_base_layer
		2: return structures_layer
		3: return platforms_layer
		4: return overlay_layer
		_: return null

# === 生命周期 ===

func _ready() -> void:
	# 加入 tilemap_world group (供 CollisionManager 等系统查找)
	add_to_group("tilemap_world")
	# 验证层级节点
	_validate_layers()
	print("[TileMapWorld] initialized with CELL_SIZE=", CELL_SIZE, " CHUNK_SIZE=", CHUNK_SIZE)

func _validate_layers() -> void:
	# 确保所有层级节点存在
	assert(background_layer != null, "BackgroundLayer missing")
	assert(terrain_base_layer != null, "TerrainBaseLayer missing")
	assert(structures_layer != null, "StructuresLayer missing")
	assert(platforms_layer != null, "PlatformsLayer missing")
	assert(overlay_layer != null, "OverlayLayer missing")