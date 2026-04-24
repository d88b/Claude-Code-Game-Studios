extends Node
# BuildItemDB — 建造物品数据库 (Autoload)
## BuildItemDB — 建造物品数据库
## 从 entities.yaml 加载建造物品定义，提供 O(1) 查询接口
## Foundation layer database — 所有建造物品属性的数据源

# === 常量定义 ===
## 12 MVP 建造物品类别
const BUILD_CATEGORIES: Array[String] = ["wall", "turret", "trap", "facility", "floor"]

# === 数据缓存 ===
## 建造物品缓存：{item_id: BuildItemDefinition}
var _items: Dictionary = {}
## 物品数量
var item_count: int = 0

# === 建造物品定义类 ===
class BuildItemDefinition:
	## 物品类型 ID
	var item_id: int = 0
	## 显示名称 (中文)
	var display_name: String = ""
	## 物品类别
	var category: String = "wall"
	## 基础成本：{resource_id: quantity}
	var base_cost: Dictionary = {}
	## 所需地形支持类型
	var terrain_support_required: Array[String] = ["solid"]
	## 建造时间 (秒)
	var build_time: float = 1.0

# === 初始化 ===

func _ready() -> void:
	_build_cache()
	print("[BuildItemDB] initialized with item_count=", item_count)

func _build_cache() -> void:
	_create_mvp_build_items()

func _create_mvp_build_items() -> void:
	# 墙体 (1000-1003)
	for i in range(1000, 1004):
		var wall: BuildItemDefinition = BuildItemDefinition.new()
		wall.item_id = i
		wall.display_name = LocalizationManager.tr("build.wall.display_name") + " " + str(i)
		wall.category = "wall"
		wall.base_cost = {151: 5, 152: 2}  # 铁锭5, 铜锭2
		wall.terrain_support_required = ["solid"]
		wall.build_time = 2.0
		_items[i] = wall

	# 炮塔 (2000-2002)
	for i in range(2000, 2003):
		var turret: BuildItemDefinition = BuildItemDefinition.new()
		turret.item_id = i
		turret.display_name = LocalizationManager.tr("build.turret.display_name") + " " + str(i)
		turret.category = "turret"
		turret.base_cost = {151: 10, 160: 5}  # 铁锭10, 基础零件5
		turret.terrain_support_required = ["solid"]
		turret.build_time = 5.0
		_items[i] = turret

	# 陷阱 (3000)
	var trap: BuildItemDefinition = BuildItemDefinition.new()
	trap.item_id = 3000
	trap.display_name = LocalizationManager.tr("build.trap.display_name")
	trap.category = "trap"
	trap.base_cost = {151: 3}
	trap.terrain_support_required = ["solid", "passable"]
	trap.build_time = 1.0
	_items[3000] = trap

	# 设施 (4000-4002)
	for i in range(4000, 4003):
		var facility: BuildItemDefinition = BuildItemDefinition.new()
		facility.item_id = i
		facility.display_name = LocalizationManager.tr("build.facility.display_name") + " " + str(i)
		facility.category = "facility"
		facility.base_cost = {151: 15, 160: 10}
		facility.terrain_support_required = ["solid"]
		facility.build_time = 10.0
		_items[i] = facility

	# 地板 (5000)
	var floor: BuildItemDefinition = BuildItemDefinition.new()
	floor.item_id = 5000
	floor.display_name = LocalizationManager.tr("build.floor.display_name")
	floor.category = "floor"
	floor.base_cost = {151: 2}
	floor.terrain_support_required = []  # 任何地形
	floor.build_time = 0.5
	_items[5000] = floor

	item_count = _items.size()

# === 查询 API ===

## 获取建造物品定义 — 返回 null 表示无效 ID
func get_build_item(item_id: int) -> BuildItemDefinition:
	return _items.get(item_id, null)

## 获取建造成本
func get_build_cost(item_id: int) -> Dictionary:
	var item: BuildItemDefinition = get_build_item(item_id)
	if item == null:
		return {}
	return item.base_cost

## 获取计算后的总成本 (base_cost * quantity)
func get_total_cost(item_id: int, quantity: int) -> Dictionary:
	var base_cost: Dictionary = get_build_cost(item_id)
	var total: Dictionary = {}
	for resource_id: int in base_cost.keys():
		total[resource_id] = base_cost[resource_id] * quantity
	return total

## 检查地形支持
func check_terrain_support(item_id: int, terrain_type: String) -> bool:
	var item: BuildItemDefinition = get_build_item(item_id)
	if item == null:
		return false
	# 如果没有要求，支持任何地形
	if item.terrain_support_required.is_empty():
		return true
	return terrain_type in item.terrain_support_required

## 获取建造时间
func get_build_time(item_id: int) -> float:
	var item: BuildItemDefinition = get_build_item(item_id)
	if item == null:
		return 0.0
	return item.build_time

## 获取显示名称
func get_display_name(item_id: int) -> String:
	var item: BuildItemDefinition = get_build_item(item_id)
	if item == null:
		return ""
	return item.display_name

## 获取指定类别的所有物品 ID
func get_items_by_category(category: String) -> Array[int]:
	var result: Array[int] = []
	for item_id: int in _items.keys():
		var item: BuildItemDefinition = _items[item_id]
		if item.category == category:
			result.append(item_id)
	return result

## 检查类别是否有效
func is_valid_category(category: String) -> bool:
	return category in BUILD_CATEGORIES

## 获取所有物品 ID
func get_all_item_ids() -> Array[int]:
	return _items.keys()