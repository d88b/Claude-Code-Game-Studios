# save_manager.gd
# SaveManager — 存档系统管理器
## SaveManager — 自动存档、手动存档、存档加载管理

extends Node

# === 配置常量 ===
const SAVE_DIR: String = "user://saves/"
const MAX_SAVE_SLOTS: int = 3  # TK-S003
const SAVE_VERSION: String = "1.0.0"  # TK-S004
const SAVE_FILE_SIZE_LIMIT: int = 1048576  # 1MB, TK-S002

# === 信号 ===
signal save_completed(slot_id: int, success: bool)
signal load_completed(slot_id: int, success: bool)
signal save_error(error_message: String)
signal load_error(error_message: String)

# === 状态变量 ===
var _current_slot: int = 1
var _is_initialized: bool = false
var _last_save_time: float = 0.0

# === 依赖引用 ===
var _game_state: Node = null
var _tilemap_world: Node = null
var _facility_controller: Node = null
var _area_manager: Node = null
var _global_signals: Node = null

# === 初始化 ===

func _ready() -> void:
	# 确保 save 目录存在
	_ensure_save_directory()

	# 获取依赖引用
	_get_dependencies()

	# 连接全局信号
	_connect_signals()

	_is_initialized = true
	print("[SaveManager] Initialized — save_dir=%s, max_slots=%d" % [SAVE_DIR, MAX_SAVE_SLOTS])

func _ensure_save_directory() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		push_error("[SaveManager] Cannot access user:// directory")
		return

	if not dir.dir_exists("saves"):
		var err: int = dir.make_dir("saves")
		if err != OK:
			push_error("[SaveManager] Failed to create saves directory: error=%d" % err)
		else:
			print("[SaveManager] Created saves directory")

func _get_dependencies() -> void:
	_global_signals = get_node_or_null("/root/GlobalSignals")
	_game_state = get_node_or_null("/root/GameState")  # Note: GameState is not autoload
	_tilemap_world = get_tree().get_first_node_in_group("tilemap_world")
	_facility_controller = get_node_or_null("/root/FacilityController")
	_area_manager = get_node_or_null("/root/AreaManager")

func _connect_signals() -> void:
	if _global_signals != null:
		# 连接状态变化信号（返回地堡时自动存档）
		if _global_signals.has_signal("game_state_changed"):
			_global_signals.game_state_changed.connect(_on_game_state_changed)

		# 连接设施建造完成信号
		if _global_signals.has_signal("facility_created"):
			_global_signals.facility_created.connect(_on_facility_created)

		# 连接设施拆除信号
		if _global_signals.has_signal("facility_destroyed"):
			_global_signals.facility_destroyed.connect(_on_facility_destroyed)

# === 公共 API ===

## 切换当前存档槽
func set_current_slot(slot_id: int) -> bool:
	if slot_id < 1 or slot_id > MAX_SAVE_SLOTS:
		push_warning("[SaveManager] Invalid slot_id=%d, valid range 1-%d" % [slot_id, MAX_SAVE_SLOTS])
		return false
	_current_slot = slot_id
	print("[SaveManager] Current slot set to %d" % slot_id)
	return true

## 获取当前存档槽
func get_current_slot() -> int:
	return _current_slot

## 自动存档（返回地堡时触发）
func auto_save() -> bool:
	if not _is_initialized:
		push_warning("[SaveManager] Not initialized, cannot save")
		return false

	var save_data: Dictionary = _collect_save_data()
	var success: bool = _write_save(_current_slot, save_data)

	if success:
		_last_save_time = Time.get_ticks_msec() / 1000.0
		save_completed.emit(_current_slot, true)
		print("[SaveManager] Auto-save complete — slot=%d, size=%d bytes" % [_current_slot, save_data.size()])
	else:
		save_error.emit("Auto-save failed")

	return success

## 手动存档
func manual_save(slot_id: int = -1) -> bool:
	if slot_id == -1:
		slot_id = _current_slot

	if not _is_initialized:
		push_warning("[SaveManager] Not initialized, cannot save")
		return false

	var save_data: Dictionary = _collect_save_data()
	var success: bool = _write_save(slot_id, save_data)

	if success:
		_last_save_time = Time.get_ticks_msec() / 1000.0
		save_completed.emit(slot_id, true)
		print("[SaveManager] Manual-save complete — slot=%d" % slot_id)
	else:
		save_error.emit("Manual save failed for slot %d" % slot_id)

	return success

## 加载存档
func load_save(slot_id: int = -1) -> bool:
	if slot_id == -1:
		slot_id = _current_slot

	var path: String = SAVE_DIR + "save_slot_%d.json" % slot_id

	if not FileAccess.file_exists(path):
		push_warning("[SaveManager] Save file not found: %s" % path)
		load_error.emit("存档不存在")
		return false

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Cannot read file: %s" % path)
		load_error.emit("无法读取存档")
		return false

	var json_text: String = file.get_as_text()
	file.close()

	# 检查文件大小
	if json_text.length() > SAVE_FILE_SIZE_LIMIT:
		push_warning("[SaveManager] Save file exceeds limit: %d bytes" % json_text.length())

	# 解析 JSON
	var json_obj: JSON = JSON.new()
	var parse_err: int = json_obj.parse(json_text)
	if parse_err != OK:
		push_error("[SaveManager] JSON parse error at line %d: %s" % [json_obj.get_error_line(), json_obj.get_error_message()])
		load_error.emit("存档损坏")
		return false

	var data: Dictionary = json_obj.get_data()

	# 验证数据结构
	if not _validate_save_data(data):
		push_error("[SaveManager] Invalid save data structure")
		load_error.emit("存档数据损坏")
		return false

	# 版本迁移
	var save_version: String = data.get("version", "0.0.0")
	if save_version != SAVE_VERSION:
		data = _migrate_save(data, save_version)

	# 应用存档数据
	var success: bool = _apply_save_data(data)

	if success:
		_current_slot = slot_id
		load_completed.emit(slot_id, true)
		print("[SaveManager] Load complete — slot=%d, version=%s" % [slot_id, save_version])
	else:
		load_error.emit("存档加载失败")

	return success

## 检查存档是否存在
func has_save(slot_id: int) -> bool:
	var path: String = SAVE_DIR + "save_slot_%d.json" % slot_id
	return FileAccess.file_exists(path)

## 获取存档摘要信息
func get_save_summary(slot_id: int) -> Dictionary:
	var path: String = SAVE_DIR + "save_slot_%d.json" % slot_id

	if not FileAccess.file_exists(path):
		return {"exists": false}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {"exists": false, "error": "Cannot read file"}

	var json_text: String = file.get_as_text()
	file.close()

	var json_obj: JSON = JSON.new()
	if json_obj.parse(json_text) != OK:
		return {"exists": false, "error": "JSON parse error"}

	var data: Dictionary = json_obj.get_data()

	return {
		"exists": true,
		"slot_id": slot_id,
		"saved_at": data.get("saved_at", "Unknown"),
		"version": data.get("version", "Unknown"),
		"game_version": data.get("game_version", "Unknown"),
		"day": data.get("game_state", {}).get("day", 1),
		"state": data.get("game_state", {}).get("state", "BUNKER")
	}

## 删除存档
func delete_save(slot_id: int) -> bool:
	var path: String = SAVE_DIR + "save_slot_%d.json" % slot_id

	if not FileAccess.file_exists(path):
		return false

	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir == null:
		push_error("[SaveManager] Cannot open saves directory")
		return false

	var err: int = dir.remove(path)
	if err != OK:
		push_error("[SaveManager] Failed to delete save: error=%d" % err)
		return false

	print("[SaveManager] Save deleted — slot=%d" % slot_id)
	return true

## 获取所有存档槽摘要
func get_all_save_summaries() -> Array:
	var summaries: Array = []
	for slot_id in range(1, MAX_SAVE_SLOTS + 1):
		summaries.append(get_save_summary(slot_id))
	return summaries

# === 数据收集 ===

func _collect_save_data() -> Dictionary:
	return {
		"version": SAVE_VERSION,
		"game_version": _get_game_version(),
		"saved_at": Time.get_datetime_string_from_system(),
		"game_state": _collect_game_state(),
		"vehicle": _collect_vehicle_data(),
		"bunker_layout": _collect_bunker_layout(),
		"resources": _collect_resources(),
		"facilities": _collect_facilities(),
		"areas": _collect_areas(),
		"stats": _collect_stats()
	}

func _get_game_version() -> String:
	return ProjectSettings.get_setting("application/config/version") if ProjectSettings.has_setting("application/config/version") else "0.1.0-alpha"

func _collect_game_state() -> Dictionary:
	# GameState 数据
	var state_data: Dictionary = {
		"state": "BUNKER",
		"day": 1,
		"hour": 7
	}

	# 从 TimeSystem 获取时间数据
	var time_system: Node = get_node_or_null("/root/TimeSystem")
	if time_system != null and time_system.has_method("get_day"):
		state_data["day"] = time_system.get_day()
		state_data["hour"] = time_system.get_hour()

	# 从 GameState 获取状态（如果有实例）
	if _game_state != null:
		state_data["state"] = _game_state.get("_current_state_name") if _game_state.has_method("get") else "BUNKER"
if state_data["state"] == null:
	state_data["state"] = "BUNKER"

	return state_data

func _collect_vehicle_data() -> Dictionary:
	var vehicle_data: Dictionary = {
		"position": {"x": 100.0, "y": 100.0},
		"health": 100.0,
		"magic": 100.0,
		"vehicle_type_id": 1
	}

	# 尝试从场景获取战车数据
	var vehicle: Node = get_tree().get_first_node_in_group("vehicle")
	if vehicle != null:
		vehicle_data["position"] = {"x": vehicle.position.x, "y": vehicle.position.y}

		# 获取 VehicleAttribute
		var attr: Node = vehicle.get_node_or_null("VehicleAttribute")
		if attr != null:
			vehicle_data["health"] = attr.get("current_health", 100.0)
			vehicle_data["magic"] = attr.get("current_magic", 100.0)
			vehicle_data["vehicle_type_id"] = attr.get("vehicle_type_id", 1)

	return vehicle_data

func _collect_bunker_layout() -> Dictionary:
	var layout_data: Dictionary = {
		"modified_cells": [],
		"placed_blocks": []
	}

	# 从 TileMapWorld 获取布局数据
	if _tilemap_world != null and _tilemap_world.has_method("get_modified_cells"):
		layout_data["modified_cells"] = _tilemap_world.get_modified_cells()

	if _tilemap_world != null and _tilemap_world.has_method("get_placed_blocks"):
		layout_data["placed_blocks"] = _tilemap_world.get_placed_blocks()

	return layout_data

func _collect_resources() -> Dictionary:
	var resources_data: Dictionary = {}

	# 从 ResourceDB 或 FacilityController 获取资源库存
	if _facility_controller != null and _facility_controller.has_method("get_all_inventory"):
		resources_data = _facility_controller.get_all_inventory()

	return resources_data

func _collect_facilities() -> Dictionary:
	var facilities_data: Dictionary = {
		"facilities": []
	}

	# 从 FacilityController 获取设施数据
	if _facility_controller != null and _facility_controller.has_method("get_all_facilities"):
		facilities_data["facilities"] = _facility_controller.get_all_facilities()

	return facilities_data

func _collect_areas() -> Dictionary:
	var areas_data: Dictionary = {
		"current_area_id": 0,
		"discovered_areas": [0]
	}

	# 从 AreaManager 获取区域数据
	if _area_manager != null:
		if _area_manager.has_method("get_current_area_id"):
			areas_data["current_area_id"] = _area_manager.get_current_area_id()
		if _area_manager.has_method("get_discovered_areas"):
			areas_data["discovered_areas"] = _area_manager.get_discovered_areas()

	return areas_data

func _collect_stats() -> Dictionary:
	return {
		"total_resources_collected": 0.0,
		"total_enemies_killed": 0,
		"total_days_played": 0
	}

# === 存档写入 ===

func _write_save(slot_id: int, data: Dictionary) -> bool:
	var path: String = SAVE_DIR + "save_slot_%d.json" % slot_id
	var temp_path: String = SAVE_DIR + "save_slot_%d.tmp" % slot_id

	# 先写入临时文件（原子写入）
	var file: FileAccess = FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Cannot write to temp file: %s" % temp_path)
		return false

	var json_text: String = JSON.stringify(data)
	file.store_string(json_text)
	file.close()

	# 重命名临时文件为正式存档
	var dir: DirAccess = DirAccess.open(SAVE_DIR)
	if dir == null:
		push_error("[SaveManager] Cannot open saves directory for rename")
		return false

	# 删除旧存档（如果存在）
	if FileAccess.file_exists(path):
		dir.remove(path)

	# 重命名临时文件
	var err: int = dir.rename(temp_path, path)
	if err != OK:
		push_error("[SaveManager] Failed to rename temp file: error=%d" % err)
		return false

	return true

# === 存档验证 ===

func _validate_save_data(data: Dictionary) -> bool:
	# 必需字段检查
	var required_fields: Array = ["version", "game_state", "vehicle", "bunker_layout"]
	for field: String in required_fields:
		if not data.has(field):
			push_error("[SaveManager] Missing required field: %s" % field)
			return false

	return true

# === 版本迁移 ===

func _migrate_save(data: Dictionary, from_version: String) -> Dictionary:
	print("[SaveManager] Migrating save from version %s to %s" % [from_version, SAVE_VERSION])

	# 迁移逻辑：添加缺失字段
	if not data.has("stats"):
		data["stats"] = _collect_stats()

	# 更新版本号
	data["version"] = SAVE_VERSION

	return data

# === 存档应用 ===

func _apply_save_data(data: Dictionary) -> bool:
	# 应用 GameState
	_apply_game_state(data.get("game_state", {}))

	# 应用 Vehicle 数据
	_apply_vehicle_data(data.get("vehicle", {}))

	# 应用 Bunker Layout
	_apply_bunker_layout(data.get("bunker_layout", {}))

	# 应用 Resources
	_apply_resources(data.get("resources", {}))

	# 应用 Facilities
	_apply_facilities(data.get("facilities", {}))

	# 应用 Areas
	_apply_areas(data.get("areas", {}))

	return true

func _apply_game_state(state_data: Dictionary) -> void:
	var time_system: Node = get_node_or_null("/root/TimeSystem")
	if time_system != null:
		if time_system.has_method("set_day"):
			time_system.set_day(state_data.get("day", 1))
		if time_system.has_method("set_hour"):
			time_system.set_hour(state_data.get("hour", 7))

func _apply_vehicle_data(vehicle_data: Dictionary) -> void:
	var vehicle: Node = get_tree().get_first_node_in_group("vehicle")
	if vehicle != null:
		var pos_data: Dictionary = vehicle_data.get("position", {"x": 100.0, "y": 100.0})
		vehicle.position = Vector2(pos_data.get("x", 100.0), pos_data.get("y", 100.0))

		var attr: Node = vehicle.get_node_or_null("VehicleAttribute")
		if attr != null:
			if attr.has_method("set_health"):
				attr.set_health(vehicle_data.get("health", 100.0))
			if attr.has_method("set_magic"):
				attr.set_magic(vehicle_data.get("magic", 100.0))

func _apply_bunker_layout(layout_data: Dictionary) -> void:
	if _tilemap_world != null and _tilemap_world.has_method("apply_layout"):
		_tilemap_world.apply_layout(layout_data)

func _apply_resources(resources_data: Dictionary) -> void:
	if _facility_controller != null and _facility_controller.has_method("set_inventory"):
		_facility_controller.set_inventory(resources_data)

func _apply_facilities(facilities_data: Dictionary) -> void:
	if _facility_controller != null and _facility_controller.has_method("restore_facilities"):
		_facility_controller.restore_facilities(facilities_data.get("facilities", []))

func _apply_areas(areas_data: Dictionary) -> void:
	if _area_manager != null:
		if _area_manager.has_method("set_discovered_areas"):
			_area_manager.set_discovered_areas(areas_data.get("discovered_areas", [0]))

# === 信号回调 ===

func _on_game_state_changed(new_state: int) -> void:
	# 状态变化时检查是否需要自动存档
	# 返回地堡 (BUNKER 状态) 时触发存档
	if new_state == 0:  # BUNKER enum value
		auto_save()

func _on_facility_created(facility_id: int, build_item_id: int, grid_pos: Vector2i) -> void:
	# 设施建造完成时存档
	auto_save()

func _on_facility_destroyed(facility_id: int) -> void:
	# 设施拆除时存档
	auto_save()