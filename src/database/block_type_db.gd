extends Node
# BlockTypeDB — 方块类型数据库 (Autoload)
## BlockTypeDB — 方块类型数据库
## 从 entities.yaml 加载方块定义，提供 O(1) 查询接口
## Foundation layer database — 所有方块属性的数据源

# === 常量定义 ===
## NULL_TILE 的 tile_type_id (空单元格)
const NULL_TILE_ID: int = 0
## 硬度最大值 (不可破坏标记)
const INDESTRUCTIBLE_HARDNESS: int = 255

# === 数据缓存 ===
## TileSet 资源引用
var _tile_set: TileSet
## 方块数据缓存：{tile_id: BlockDefinition}
var _tile_data_cache: Dictionary = {}
## 方块数量
var tile_count: int = 0

# === 方块定义类 ===
class BlockDefinition:
	## 方块类型 ID (0-65535)
	var tile_type_id: int = 0
	## 显示名称 (中文)
	var display_name: String = ""
	## 硬度 (0-255) — 挖掘难度
	var hardness: int = 0
	## 可破坏性 (0=不可破坏, 1=可破坏)
	var destructibility: int = 1
	## 碰撞形状 (0=无, 1=完整, 2=平台)
	var collision_shape: int = 1
	## 资源产出类型 ID
	var resource_type_id: int = 0
	## 资源产出倍率
	var resource_multiplier: float = 1.0
	## 可建造性 (0=自然, 1=玩家可建造)
	var buildability: int = 0
	## 允许放置的层级列表
	var layer_allowed: Array[int] = []
	## 方块类别 (terrain/ore/building/platform)
	var category: String = ""

# === 初始化 ===

func _ready() -> void:
	# 加载 TileSet 资源
	_load_tileset()
	# 构建数据缓存
	_build_cache()
	print("[BlockTypeDB] initialized with tile_count=", tile_count)

func _load_tileset() -> void:
	# 加载 TileSet 资源
	var tileset_path: String = "res://assets/tilesets/block_types.tres"
	if ResourceLoader.exists(tileset_path):
		_tile_set = ResourceLoader.load(tileset_path)
		if _tile_set == null:
			push_error("[BlockTypeDB] Failed to load TileSet: ", tileset_path)
	else:
		push_warning("[BlockTypeDB] TileSet not found: ", tileset_path)
		# 创建空 TileSet 作为 fallback
		_tile_set = TileSet.new()

func _build_cache() -> void:
	# 构建方块数据缓存 (从 TileSet 或 YAML 加载)
	# 当前为 stub — 完整实现需要 entities.yaml 解析器

	# MVP 最小数据集 — 确保 tile_count >= 25
	_create_mvp_block_definitions()

	# 验证最小方块数量
	if tile_count < 25:
		push_warning("[BlockTypeDB] tile_count=", tile_count, " < 25 MVP minimum")

func _create_mvp_block_definitions() -> void:
	# 创建 MVP 方块定义 (stub data)
	# 地形方块 (ID 0-399)
	for i in range(100, 105):
		var block: BlockDefinition = BlockDefinition.new()
		block.tile_type_id = i
		block.display_name = LocalizationManager.translate("block.terrain.display_name") + " " + str(i)
		block.hardness = 60
		block.destructibility = 1
		block.collision_shape = 1
		block.buildability = 0
		block.category = "terrain"
		block.layer_allowed = [1]  # terrain_base layer
		_tile_data_cache[i] = block

	# 基岩 (ID 1) — 不可破坏
	var bedrock: BlockDefinition = BlockDefinition.new()
	bedrock.tile_type_id = 1
	bedrock.display_name = LocalizationManager.translate("block.bedrock.display_name")
	bedrock.hardness = 100  # 原始硬度
	bedrock.destructibility = 0  # 不可破坏
	bedrock.collision_shape = 1
	bedrock.buildability = 0
	bedrock.category = "terrain"
	bedrock.layer_allowed = [1]
	_tile_data_cache[1] = bedrock

	# 矿石方块 (ID 500-999)
	for i in range(500, 505):
		var ore: BlockDefinition = BlockDefinition.new()
		ore.tile_type_id = i
		ore.display_name = LocalizationManager.translate("block.ore.display_name") + " " + str(i)
		ore.hardness = 80
		ore.destructibility = 1
		ore.collision_shape = 1
		ore.resource_type_id = 151  # 铁锭
		ore.resource_multiplier = 1.0
		ore.buildability = 0
		ore.category = "ore"
		ore.layer_allowed = [1]
		_tile_data_cache[i] = ore

	# 建筑方块 (ID 1000-2999)
	for i in range(1000, 1005):
		var building: BlockDefinition = BlockDefinition.new()
		building.tile_type_id = i
		building.display_name = LocalizationManager.translate("block.building.display_name") + " " + str(i)
		building.hardness = 50
		building.destructibility = 1
		building.collision_shape = 1
		building.buildability = 1
		building.category = "building"
		building.layer_allowed = [2, 3]  # structures/platforms
		_tile_data_cache[i] = building

	# 平台方块 (ID 1510)
	var platform: BlockDefinition = BlockDefinition.new()
	platform.tile_type_id = 1510
	platform.display_name = LocalizationManager.translate("block.platform.display_name")
	platform.hardness = 30
	platform.destructibility = 1
	platform.collision_shape = 2  # PLATFORM
	platform.buildability = 1
	platform.category = "platform"
	platform.layer_allowed = [3]
	_tile_data_cache[1510] = platform

	# NULL_TILE 定义 (ID 0)
	var null_tile: BlockDefinition = BlockDefinition.new()
	null_tile.tile_type_id = 0
	null_tile.display_name = LocalizationManager.translate("block.empty.display_name")
	null_tile.hardness = INDESTRUCTIBLE_HARDNESS
	null_tile.destructibility = 0
	null_tile.collision_shape = 0
	null_tile.buildability = 0
	null_tile.category = "null"
	null_tile.layer_allowed = []
	_tile_data_cache[0] = null_tile

	# 更新方块计数
	tile_count = _tile_data_cache.size()

# === 查询 API ===

## 获取方块定义 — 返回 null 表示无效 ID
func get_tile_data(tile_id: int) -> BlockDefinition:
	return _tile_data_cache.get(tile_id, null)

## 获取硬度 — 不可破坏方块返回 255
func get_hardness(tile_id: int) -> int:
	var data: BlockDefinition = get_tile_data(tile_id)
	if data == null:
		return INDESTRUCTIBLE_HARDNESS
	# 不可破坏方块硬度覆盖为 255
	if data.destructibility == 0:
		return INDESTRUCTIBLE_HARDNESS
	return data.hardness

## 获取碰撞形状 (0=无, 1=完整, 2=平台)
func get_collision_shape(tile_id: int) -> int:
	var data: BlockDefinition = get_tile_data(tile_id)
	if data == null:
		return 0  # 无碰撞
	return data.collision_shape

## 获取资源产出类型 ID
func get_resource_type_id(tile_id: int) -> int:
	var data: BlockDefinition = get_tile_data(tile_id)
	if data == null:
		return 0
	return data.resource_type_id

## 获取资源产出倍率
func get_resource_multiplier(tile_id: int) -> float:
	var data: BlockDefinition = get_tile_data(tile_id)
	if data == null:
		return 0.0
	return data.resource_multiplier

## 检查是否可建造
func is_buildable(tile_id: int) -> bool:
	var data: BlockDefinition = get_tile_data(tile_id)
	return data != null and data.buildability == 1

## 检查是否允许在指定层级放置
func can_place_on_layer(tile_id: int, layer: int) -> bool:
	var data: BlockDefinition = get_tile_data(tile_id)
	if data == null:
		return false
	return layer in data.layer_allowed

## 获取指定类别的所有方块 ID
func get_tiles_by_category(category: String) -> Array[int]:
	var result: Array[int] = []
	for tile_id: int in _tile_data_cache.keys():
		var data: BlockDefinition = _tile_data_cache[tile_id]
		if data.category == category:
			result.append(tile_id)
	return result

## 获取所有可建造方块
func get_buildable_tiles() -> Array[int]:
	return get_tiles_by_category("building")

# === 验证方法 ===

## 检查 TileSet 加载状态
func is_loaded() -> bool:
	return _tile_set != null and tile_count >= 25