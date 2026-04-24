# game_state.gd
# GameState — 游戏状态管理器
## GameState — 游戏循环状态管理
## 控制 BUNKER → DEPLOY → EXPLORE → RETURN → SUMMARY 流程
## Vertical Slice MVP

class_name GameState extends Node

# === 状态枚举 ===
enum State {
	BUNKER,      ## 地堡状态：战车未部署，准备阶段
	DEPLOYING,   ## 部署中：战车正在出发
	EXPLORING,   ## 探索中：战车在地表行动
	RETURNING,   ## 返回中：撤退触发，战车返回
	SUMMARY      ## 总结：探索周期结束，显示结果
}

# === 信号 ===
signal state_changed(new_state: int)
signal vehicle_deployed(vehicle_node: Node)
signal vehicle_returned()

# === 状态变量 ===
var _current_state: int = State.BUNKER
var _vehicle_instance: Node = null
var _vehicle_spawn_position: Vector2 = Vector2(100, 100)

# === 探索周期统计 ===
var _cycle_start_time: float = 0.0
var _cycle_end_time: float = 0.0
var _resources_collected: Dictionary = {}

# === 依赖引用 ===
var _vehicle_scene: PackedScene = null
var _tilemap_world: Node = null
var _global_signals: Node = null
var _hud: Node = null  # HUD 引用，用于更新位置显示

# === 配置 ===
## 部署按键
const DEPLOY_KEY: String = "deploy"
## 撤退按键
const RETURN_KEY: String = "return"
## 战车场景路径
const VEHICLE_SCENE_PATH: String = "res://src/physics_vehicle.tscn"

# === 初始化 ===

func _ready() -> void:
	# 加载战车场景
	_vehicle_scene = load(VEHICLE_SCENE_PATH)
	if _vehicle_scene == null:
		push_error("[GameState] FAILED to load vehicle scene: " + VEHICLE_SCENE_PATH)
		return

	# 获取全局信号 autoload
	_global_signals = GlobalSignals

	# 获取 HUD 引用
	_hud = get_node_or_null("../HUD/SimpleHUD")
	if _hud == null:
		_hud = get_tree().current_scene.get_node_or_null("HUD/SimpleHUD")

	# 连接输入
	_connect_input()

	print("[GameState] Initialized — press SPACE to deploy")

func _connect_input() -> void:
	# 监听部署/撤退按键
	# 实际按键触发在 _unhandled_input 处理
	pass

func _process(_delta: float) -> void:
	# 更新 HUD 位置显示
	if _current_state == State.EXPLORING and _vehicle_instance != null and _hud != null:
		_hud.update_position(_vehicle_instance.position)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(DEPLOY_KEY):
		if _current_state == State.BUNKER:
			_deploy_vehicle()
		elif _current_state == State.SUMMARY:
			_reset_to_bunker()
		get_viewport().set_input_as_handled()

	if event.is_action_pressed(RETURN_KEY):
		if _current_state == State.EXPLORING:
			_trigger_return()
		get_viewport().set_input_as_handled()

# === 状态转换 ===

func get_current_state() -> int:
	return _current_state

func _set_state(new_state: int) -> void:
	if new_state == _current_state:
		return

	var old_state: int = _current_state
	_current_state = new_state

	emit_signal("state_changed", new_state)

	# 更新 HUD 状态显示
	if _hud != null:
		var state_names: Array = ["BUNKER", "DEPLOYING", "EXPLORING", "RETURNING", "SUMMARY"]
		_hud.set_game_state(state_names[new_state])

	print("[GameState] State changed: %d -> %d" % [old_state, new_state])

# === 部署逻辑 ===

func _deploy_vehicle() -> void:
	_set_state(State.DEPLOYING)

	# 创建战车实例
	_vehicle_instance = _vehicle_scene.instantiate()

	if _vehicle_instance == null:
		push_error("[GameState] Vehicle instantiation FAILED!")
		return

	# 设置战车初始位置
	_vehicle_instance.position = _vehicle_spawn_position

	# 添加到场景树
	get_tree().current_scene.add_child(_vehicle_instance)

	# 记录周期开始时间
	_cycle_start_time = TimeSystem.get_current_hour()
	_resources_collected.clear()

	# 连接资源收集信号
	if _global_signals != null:
		_global_signals.resource_collected.connect(_on_resource_collected)

	_set_state(State.EXPLORING)
	emit_signal("vehicle_deployed", _vehicle_instance)

	print("[GameState] Vehicle deployed at position: %s" % _vehicle_spawn_position)

# === 撤退逻辑 ===

func _trigger_return() -> void:
	_set_state(State.RETURNING)

	# 记录周期结束时间
	_cycle_end_time = TimeSystem.get_current_hour()

	# 断开资源收集信号
	if _global_signals != null:
		if _global_signals.resource_collected.is_connected(_on_resource_collected):
			_global_signals.resource_collected.disconnect(_on_resource_collected)

	# 移除战车实例
	if _vehicle_instance != null:
		_vehicle_instance.queue_free()
		_vehicle_instance = null

	emit_signal("vehicle_returned")
	_set_state(State.SUMMARY)

	# 显示总结（通过信号或直接调用 HUD）
	print("[GameState] Vehicle returned, duration: %.1f hours" % (_cycle_end_time - _cycle_start_time))

# === 重置到地堡状态 ===

func _reset_to_bunker() -> void:
	_set_state(State.BUNKER)
	print("[GameState] 重置到地堡状态 — 可以开始下一次探索")

# === 资源收集回调 ===

func _on_resource_collected(resource_id: int, quantity: float) -> void:
	if not _resources_collected.has(resource_id):
		_resources_collected[resource_id] = 0.0
	_resources_collected[resource_id] += quantity

# === 查询 API ===

func get_cycle_summary() -> Dictionary:
	return {
		"start_time": _cycle_start_time,
		"end_time": _cycle_end_time,
		"duration": _cycle_end_time - _cycle_start_time,
		"resources": _resources_collected.duplicate(),
		"total_resources": _resources_collected.values().reduce(func(a, b): return a + b, 0.0)
	}

func get_vehicle() -> Node:
	return _vehicle_instance

## 设置战车生成位置（用于测试）
func set_spawn_position(pos: Vector2) -> void:
	_vehicle_spawn_position = pos

## 设置 TileMapWorld 引用（用于坐标转换）
func set_tilemap_world(world: Node) -> void:
	_tilemap_world = world