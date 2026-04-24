extends Node
# ResourceDB — 资源类型数据库 (Autoload)
## ResourceDB — 资源类型数据库
## 从 entities.yaml 加载资源定义，提供 O(1) 查询接口
## Foundation layer database — 所有资源属性的数据源

# === 常量定义 ===
## 默认堆叠上限
const DEFAULT_STACK_SIZE: int = 100

# === 数据缓存 ===
## 资源数据缓存：{resource_id: ResourceDefinition}
var _resources: Dictionary = {}
## 资源数量
var resource_count: int = 0

# === 资源定义类 ===
class ResourceDefinition:
	## 资源类型 ID
	var resource_id: int = 0
	## 显示名称 (中文)
	var display_name: String = ""
	## 堆叠上限
	var max_stack_size: int = DEFAULT_STACK_SIZE
	## 资源类别
	var category: String = "raw_material"  # raw_material/processed/component/ammo
	## 显示图标路径
	var icon_path: String = ""

# === 初始化 ===

func _ready() -> void:
	_build_cache()
	print("[ResourceDB] initialized with resource_count=", resource_count)

func _build_cache() -> void:
	# MVP 资源定义
	_create_mvp_resources()

func _create_mvp_resources() -> void:
	# 铁锭 (151)
	var iron: ResourceDefinition = ResourceDefinition.new()
	iron.resource_id = 151
	iron.display_name = "铁锭"
	iron.max_stack_size = 100
	iron.category = "processed"
	_resources[151] = iron

	# 铜锭 (152)
	var copper: ResourceDefinition = ResourceDefinition.new()
	copper.resource_id = 152
	copper.display_name = "铜锭"
	copper.max_stack_size = 100
	copper.category = "processed"
	_resources[152] = copper

	# 基础零件 (160)
	var parts: ResourceDefinition = ResourceDefinition.new()
	parts.resource_id = 160
	parts.display_name = "基础零件"
	parts.max_stack_size = 100
	parts.category = "component"
	_resources[160] = parts

	# 魔力晶石 (101)
	var crystal: ResourceDefinition = ResourceDefinition.new()
	crystal.resource_id = 101
	crystal.display_name = "魔力晶石"
	crystal.max_stack_size = 50
	crystal.category = "raw_material"
	_resources[101] = crystal

	# 秘银 (102)
	var mithril: ResourceDefinition = ResourceDefinition.new()
	mithril.resource_id = 102
	mithril.display_name = "秘银"
	mithril.max_stack_size = 50
	mithril.category = "raw_material"
	_resources[102] = mithril

	# 奥术碎片 (103)
	var arcana: ResourceDefinition = ResourceDefinition.new()
	arcana.resource_id = 103
	arcana.display_name = "奥术碎片"
	arcana.max_stack_size = 100
	arcana.category = "raw_material"
	_resources[103] = arcana

	# 食物 (200)
	var food: ResourceDefinition = ResourceDefinition.new()
	food.resource_id = 200
	food.display_name = "食物"
	food.max_stack_size = 50
	food.category = "raw_material"
	_resources[200] = food

	# 弹药 (300-305)
	for i in range(300, 306):
		var ammo: ResourceDefinition = ResourceDefinition.new()
		ammo.resource_id = i
		ammo.display_name = "弹药 " + str(i)
		ammo.max_stack_size = 200
		ammo.category = "ammo"
		_resources[i] = ammo

	resource_count = _resources.size()

# === 查询 API ===

## 获取资源定义 — 返回 null 表示无效 ID
func get_resource(resource_id: int) -> ResourceDefinition:
	return _resources.get(resource_id, null)

## 获取堆叠上限
func get_max_stack_size(resource_id: int) -> int:
	var res: ResourceDefinition = get_resource(resource_id)
	if res == null:
		return 0
	return res.max_stack_size

## 获取显示名称
func get_display_name(resource_id: int) -> String:
	var res: ResourceDefinition = get_resource(resource_id)
	if res == null:
		return ""
	return res.display_name

## 获取资源类别
func get_category(resource_id: int) -> String:
	var res: ResourceDefinition = get_resource(resource_id)
	if res == null:
		return ""
	return res.category

## 获取指定类别的所有资源 ID
func get_resources_by_category(category: String) -> Array[int]:
	var result: Array[int] = []
	for res_id: int in _resources.keys():
		var res: ResourceDefinition = _resources[res_id]
		if res.category == category:
			result.append(res_id)
	return result

## 检查类别是否有效
func is_valid_category(category: String) -> bool:
	return category in ["raw_material", "processed", "component", "ammo"]

## 获取所有资源 ID
func get_all_resource_ids() -> Array[int]:
	return _resources.keys()