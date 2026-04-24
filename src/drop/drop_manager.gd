# drop_manager.gd
# DropManager — 资源掉落管理器
## DropManager — 资源掉落管理器
## 监听 GlobalSignals.block_dug 信号，在方块被摧毁时生成资源掉落
## Vertical Slice MVP

class_name DropManager extends Node

# === 配置 ===
## 资源掉落场景路径
const RESOURCE_DROP_PATH: String = "res://src/drop/resource_drop.tscn"

# === 依赖 ===
var _resource_drop_scene: PackedScene = null
var _global_signals: Node = null
var _block_type_db: Node = null

# === 初始化 ===

func _ready() -> void:
	# 加载资源掉落场景
	_resource_drop_scene = load(RESOURCE_DROP_PATH)

	# 获取 autoload 引用
	_global_signals = GlobalSignals
	_block_type_db = BlockTypeDB

	# 连接信号
	if _global_signals != null:
		_global_signals.block_dug.connect(_on_block_dug)

	print("[DropManager] Initialized")

func _exit_tree() -> void:
	# 断开信号连接
	if _global_signals != null:
		if _global_signals.block_dug.is_connected(_on_block_dug):
			_global_signals.block_dug.disconnect(_on_block_dug)

# === 信号回调 ===

func _on_block_dug(grid_pos: Vector2i, block_id: int) -> void:
	# 检查该方块是否有资源掉落
	if _block_type_db == null:
		return

	# 获取方块数据
	var block_data: Object = _block_type_db.get_tile_data(block_id)
	if block_data == null:
		return

	# 检查是否有掉落定义
	var drop_resource_id: int = block_data.drop_resource_id if block_data.has("drop_resource_id") else 0
	var drop_quantity: float = block_data.drop_quantity if block_data.has("drop_quantity") else 1.0

	# 如果没有掉落，跳过
	if drop_resource_id <= 0:
		return

	# 生成资源掉落
	spawn_drop(grid_pos, drop_resource_id, drop_quantity)

# === 生成掉落 ===

func spawn_drop(grid_pos: Vector2i, resource_id: int, quantity: float) -> void:
	if _resource_drop_scene == null:
		push_warning("[DropManager] Resource drop scene not loaded")
		return

	# 计算世界坐标 (单元格中心)
	var base_pos: Vector2 = Vector2(
		(grid_pos.x + 0.5) * 32,
		(grid_pos.y + 0.5) * 32
	)

	# 添加随机偏移 (±16 像素，约半个单元格)
	var random_offset: Vector2 = Vector2(
		randf_range(-16.0, 16.0),
		randf_range(-16.0, 16.0)
	)
	var world_pos: Vector2 = base_pos + random_offset

	# 创建掉落实例
	var drop_instance: Node = _resource_drop_scene.instantiate()

	# 设置资源属性
	drop_instance.set_resource(resource_id, quantity)

	# 设置位置
	drop_instance.position = world_pos

	# 添加到场景树 (添加到当前场景)
	get_tree().current_scene.add_child(drop_instance)

	print("[DropManager] Spawned drop at %s: resource_id=%d, quantity=%.1f" % [world_pos, resource_id, quantity])