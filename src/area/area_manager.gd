# area_manager.gd
# AreaManager — 探索区域管理器
## AreaManager — 探索区域管理器
## 定义区域边界、检测区域进出、提供区域元数据
## Core layer system (GDD exploration-area-system.md)

class_name AreaManager extends Node

# === 常量定义 (来自 GDD) ===
## 基础敌人密度
const ENEMY_BASE_DENSITY: int = 4
## 基础稀有掉落概率
const BASE_RARE_DROP: float = 0.05
## 稀有掉落增量
const RARE_DROP_INCREMENT: float = 0.05
## 区域过渡显示时长
const TRANSITION_DISPLAY_DURATION: float = 3.0
## 高危警告阈值
const HIGH_DANGER_WARNING_THRESHOLD: int = 4
## 发现通知时长
const DISCOVERY_NOTIFICATION_DURATION: float = 2.0
## 单元格尺寸
const CELL_SIZE: int = 32

# === 区域定义类 ===
class AreaDefinition:
	## 区域 ID
	var area_id: int = 0
	## 显示名称
	var display_name: String = ""
	## 区域边界 (像素坐标)
	var bounds: Rect2 = Rect2()
	## 危险等级 (1-5)
	var danger_level: int = 1
	## 战利品等级 (1-4)
	var loot_tier: int = 1
	## 阵营 ID (墓园=1, 地狱=2, 塔楼=3, 元素=4)
	var faction_id: int = 0
	## 战利品池 ID 列表
	var loot_pool_ids: Array[int] = []
	## 敌人生成 ID 列表
	var enemy_spawn_ids: Array[int] = []
	## 是否已发现
	var discovered: bool = false

# === 信号 ===
## 区域进入 (area_id: int, area_name: String, danger_level: int, loot_tier: int)
signal area_entered(area_id: int, area_name: String, danger_level: int, loot_tier: int)
## 区域离开 (area_id: int)
signal area_exited(area_id: int)
## 区域发现 (area_id: int, area_name: String)
signal area_discovered(area_id: int, area_name: String)

# === 状态变量 ===
## 区域定义列表
var area_definitions: Array[AreaDefinition] = []
## 当前区域
var current_area: AreaDefinition = null
## 当前区域 ID
var current_area_id: int = 0
## 上一次检测位置
var last_check_position: Vector2 = Vector2.ZERO
## 是否已初始化
var is_initialized: bool = false

# === 依赖引用 ===
var _vehicle_controller: Node = null
var _global_signals: Node = null
var _tilemap_world: Node = null

# === 初始化 ===

func _ready() -> void:
	_auto_find_dependencies()
	_create_mvp_areas()

	print("[AreaManager] initialized — area_count=%d" % area_definitions.size())

func _process(delta: float) -> void:
	if not is_initialized:
		return

	# 检测车辆位置变化
	_check_vehicle_position()

## 自动查找依赖节点
func _auto_find_dependencies() -> void:
	if _vehicle_controller == null:
		_vehicle_controller = get_node_or_null("/root/VehicleController")
	if _global_signals == null:
		_global_signals = get_node_or_null("/root/GlobalSignals")
	if _tilemap_world == null:
		_tilemap_world = get_node_or_null("/root/TileMapWorld")

## 设置依赖注入 (用于测试)
func set_dependencies(vehicle_controller: Node, global_signals: Node,
		tilemap_world: Node) -> void:
	_vehicle_controller = vehicle_controller
	_global_signals = global_signals
	_tilemap_world = tilemap_world
	is_initialized = true

## 创建 MVP 区域定义
func _create_mvp_areas() -> void:
	# 地堡周边 (默认安全区)
	var bunker: AreaDefinition = AreaDefinition.new()
	bunker.area_id = 0
	bunker.display_name = LocalizationManager.tr("area.bunker_perimeter.name")
	bunker.bounds = Rect2(Vector2(-320, -320), Vector2(640, 640))  # 20x20 格
	bunker.danger_level = 1
	bunker.loot_tier = 1
	bunker.faction_id = 0
	bunker.discovered = true
	area_definitions.append(bunker)

	# 废弃城市
	var city: AreaDefinition = AreaDefinition.new()
	city.area_id = 1
	city.display_name = LocalizationManager.tr("area.abandoned_city.name")
	city.bounds = Rect2(Vector2(320, -320), Vector2(960, 640))  # 30x20 格
	city.danger_level = 3
	city.loot_tier = 2
	city.faction_id = 1  # 墓园
	city.enemy_spawn_ids = [1, 2, 3, 4]
	city.loot_pool_ids = [101, 102]
	area_definitions.append(city)

	# 恶魔荒原
	var demon: AreaDefinition = AreaDefinition.new()
	demon.area_id = 2
	demon.display_name = LocalizationManager.tr("area.demon_wasteland.name")
	demon.bounds = Rect2(Vector2(1280, -320), Vector2(960, 640))
	demon.danger_level = 4
	demon.loot_tier = 3
	demon.faction_id = 2  # 地狱
	demon.enemy_spawn_ids = [5, 6, 7]
	demon.loot_pool_ids = [103, 104]
	area_definitions.append(demon)

	# 元素矿洞
	var element: AreaDefinition = AreaDefinition.new()
	element.area_id = 3
	element.display_name = LocalizationManager.tr("area.element_mine.name")
	element.bounds = Rect2(Vector2(2240, -320), Vector2(640, 640))
	element.danger_level = 5
	element.loot_tier = 4
	element.faction_id = 4  # 元素
	element.enemy_spawn_ids = [100]
	element.loot_pool_ids = [105]
	area_definitions.append(element)

	is_initialized = true

# === 位置检测 ===

func _check_vehicle_position() -> void:
	if _vehicle_controller == null:
		return

	var vehicle_pos: Vector2 = _vehicle_controller.position

	# 跳过未变化的位置
	if vehicle_pos == last_check_position:
		return

	last_check_position = vehicle_pos

	# 检测区域变化
	_update_current_area(vehicle_pos)

## 更新当前区域
func _update_current_area(vehicle_pos: Vector2) -> void:
	# 查找包含车辆位置的区域
	var new_area: AreaDefinition = _find_area_at_position(vehicle_pos)

	# 区域变化检测
	if new_area != current_area:
		# 离开旧区域
		if current_area != null:
			_emit_area_exited(current_area)

		# 进入新区域
		current_area = new_area
		current_area_id = new_area.area_id

		_emit_area_entered(new_area)

## 查找包含指定位置的区域
func _find_area_at_position(pos: Vector2) -> AreaDefinition:
	for area: AreaDefinition in area_definitions:
		if area.bounds.has_point(pos):
			return area

	# 未找到区域，返回地堡周边
	return area_definitions[0]  # area_id=0

# === 信号发射 ===

func _emit_area_entered(area: AreaDefinition) -> void:
	# 发现检测
	if not area.discovered:
		area.discovered = true
		area_discovered.emit(area.area_id, area.display_name)

	# 发射进入信号
	area_entered.emit(area.area_id, area.display_name, area.danger_level, area.loot_tier)

	# 发射全局信号
	if _global_signals != null and _global_signals.has_signal("area_entered"):
		_global_signals.area_entered.emit(area.area_id, area.display_name)

	print("[AreaManager] Entered area_id=%d, name='%s', danger=%d, loot=%d" % [area.area_id, area.display_name, area.danger_level, area.loot_tier])

func _emit_area_exited(area: AreaDefinition) -> void:
	area_exited.emit(area.area_id)

	# 发射全局信号
	if _global_signals != null and _global_signals.has_signal("area_exited"):
		_global_signals.area_exited.emit(area.area_id)

	print("[AreaManager] Exited area_id=%d" % area.area_id)

# === 公共 API ===

## 获取当前区域
func get_current_area() -> AreaDefinition:
	return current_area

## 获取当前区域 ID
func get_current_area_id() -> int:
	return current_area_id

## 获取当前危险等级
func get_danger_level() -> int:
	if current_area == null:
		return 1
	return current_area.danger_level

## 获取当前战利品等级
func get_loot_tier() -> int:
	if current_area == null:
		return 1
	return current_area.loot_tier

## 获取当前区域名称
func get_area_name() -> String:
	if current_area == null:
		return LocalizationManager.tr("area.bunker_perimeter.name")
	return current_area.display_name

## 获取当前区域战利品池
func get_loot_pools() -> Array[int]:
	if current_area == null:
		return []
	return current_area.loot_pool_ids

## 获取当前区域敌人生成 ID
func get_enemy_spawn_ids() -> Array[int]:
	if current_area == null:
		return []
	return current_area.enemy_spawn_ids

## 获取敌人密度 (公式 F1)
func get_enemy_density() -> int:
	return get_danger_level() * ENEMY_BASE_DENSITY

## 获取稀有掉落概率 (公式 F3)
func get_rare_drop_chance() -> float:
	return BASE_RARE_DROP + get_loot_tier() * RARE_DROP_INCREMENT

## 获取危险紧迫度贡献 (公式 F2)
func get_danger_urgency(danger_mult: float = 1.0) -> float:
	return get_danger_level() * 0.5 * danger_mult

## 获取区域信息字典
func get_area_info() -> Dictionary:
	if current_area == null:
		return {
			"area_id": 0,
			"name": "地堡周边",
			"danger": 1,
			"loot_tier": 1,
			"faction": 0
		}

	return {
		"area_id": current_area.area_id,
		"name": current_area.display_name,
		"danger": current_area.danger_level,
		"loot_tier": current_area.loot_tier,
		"faction": current_area.faction_id
	}

## 检查是否高危区域
func is_high_danger() -> bool:
	return get_danger_level() >= HIGH_DANGER_WARNING_THRESHOLD

## 检查位置是否在区域边界内
func is_position_in_area(pos: Vector2, area_id: int) -> bool:
	for area: AreaDefinition in area_definitions:
		if area.area_id == area_id:
			return area.bounds.has_point(pos)
	return false

## 获取所有区域定义
func get_all_areas() -> Array[AreaDefinition]:
	return area_definitions

# === 测试辅助 ===

func set_current_area_for_test(area: AreaDefinition) -> void:
	current_area = area
	current_area_id = area.area_id

func set_vehicle_position_for_test(pos: Vector2) -> void:
	last_check_position = pos

func add_area_for_test(area: AreaDefinition) -> void:
	area_definitions.append(area)

func clear_areas_for_test() -> void:
	area_definitions.clear()

# === 区域验证 ===

## 验证区域边界不重叠
func validate_no_overlap() -> bool:
	for i: int in range(area_definitions.size()):
		for j: int in range(i + 1, area_definitions.size()):
			var area_a: AreaDefinition = area_definitions[i]
			var area_b: AreaDefinition = area_definitions[j]

			# 检查边界重叠
			if area_a.bounds.intersects(area_b.bounds):
				push_warning("[AreaManager] Areas %d and %d have overlapping bounds" % [area_a.area_id, area_b.area_id])
				return false

	return true