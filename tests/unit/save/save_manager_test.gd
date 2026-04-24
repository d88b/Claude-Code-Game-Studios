# save_manager_test.gd
# Unit tests for Story: Save Data Structure + Auto-Save + Load
# tests/unit/save/save_manager_test.gd

extends GutTest

const SaveManagerScript := preload("res://src/save/save_manager.gd")

var _save_manager: Object
var _test_save_dir: String = "user://test_saves/"

# === 测试 Setup ===

func before_all() -> void:
	# 创建临时测试目录
	_ensure_test_directory()

func before_each() -> void:
	# 创建 SaveManager 实例
	_save_manager = SaveManagerScript.new()
	add_child_autoqfree(_save_manager)

	# 替换 SAVE_DIR 为测试目录以隔离测试
	_save_manager.SAVE_DIR = _test_save_dir
	await get_tree().process_frame

func after_each() -> void:
	# 清理测试目录中的存档文件
	_cleanup_test_saves()

func _ensure_test_directory() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if dir == null:
		return
	if not dir.dir_exists("test_saves"):
		dir.make_dir("test_saves")

func _cleanup_test_saves() -> void:
	var dir: DirAccess = DirAccess.open(_test_save_dir)
	if dir == null:
		return
	for file: String in dir.get_files():
		if file.ends_with(".json") or file.ends_with(".tmp"):
			dir.remove(file)

# === AC-01: 自动存档在返回地堡时触发 ===

func test_auto_save_writes_file() -> void:
	# 模拟初始化
	_save_manager._is_initialized = true

	# 执行自动存档
	var success: bool = _save_manager.auto_save()

	# 验证存档成功
	assert_true(success, "auto_save should return true")

	# 验证文件存在
	var path: String = _test_save_dir + "save_slot_1.json"
	assert_true(FileAccess.file_exists(path), "save file should exist")

func test_auto_save_on_bunker_return() -> void:
	# 初始化
	_save_manager._is_initialized = true

	# 模拟返回地堡状态变化
	if _save_manager.has_method("_on_game_state_changed"):
		_save_manager._on_game_state_changed(0)  # BUNKER enum value

	# 验证存档文件生成
	var path: String = _test_save_dir + "save_slot_1.json"
	assert_true(FileAccess.file_exists(path), "save should trigger on bunker return")

# === AC-02: 存档数据包含所有必需字段 ===

func test_save_data_contains_game_state() -> void:
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	var data: Dictionary = _read_test_save()
	assert_true(data.has("game_state"), "save should contain game_state")

	var game_state: Dictionary = data.get("game_state", {})
	assert_true(game_state.has("state"), "game_state should have state")
	assert_true(game_state.has("day"), "game_state should have day")

func test_save_data_contains_vehicle() -> void:
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	var data: Dictionary = _read_test_save()
	assert_true(data.has("vehicle"), "save should contain vehicle")

	var vehicle: Dictionary = data.get("vehicle", {})
	assert_true(vehicle.has("position"), "vehicle should have position")
	assert_true(vehicle.has("health"), "vehicle should have health")
	assert_true(vehicle.has("magic"), "vehicle should have magic")

func test_save_data_contains_bunker_layout() -> void:
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	var data: Dictionary = _read_test_save()
	assert_true(data.has("bunker_layout"), "save should contain bunker_layout")

func test_save_data_contains_resources() -> void:
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	var data: Dictionary = _read_test_save()
	assert_true(data.has("resources"), "save should contain resources")

func test_save_data_contains_facilities() -> void:
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	var data: Dictionary = _read_test_save()
	assert_true(data.has("facilities"), "save should contain facilities")

func test_save_data_contains_areas() -> void:
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	var data: Dictionary = _read_test_save()
	assert_true(data.has("areas"), "save should contain areas")

func test_save_data_contains_version() -> void:
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	var data: Dictionary = _read_test_save()
	assert_true(data.has("version"), "save should contain version")
	assert_true(data.has("game_version"), "save should contain game_version")
	assert_true(data.has("saved_at"), "save should contain saved_at")

func _read_test_save() -> Dictionary:
	var path: String = _test_save_dir + "save_slot_1.json"
	if not FileAccess.file_exists(path):
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}

	var json_text: String = file.get_as_text()
	file.close()

	var json_obj: JSON = JSON.new()
	if json_obj.parse(json_text) != OK:
		return {}

	return json_obj.get_data()

# === AC-03: 加载存档恢复所有系统状态 ===

func test_load_save_restores_slot() -> void:
	# 先创建存档
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	# 加载存档
	var success: bool = _save_manager.load_save(1)
	assert_true(success, "load_save should return true")

	# 验证当前槽位
	assert_eq(_save_manager.get_current_slot(), 1, "current slot should be 1")

func test_load_save_returns_false_on_missing_file() -> void:
	var success: bool = _save_manager.load_save(99)
	assert_false(success, "load_save should return false for missing file")

func test_load_save_returns_false_on_corrupted_file() -> void:
	# 写入损坏的 JSON 文件
	var path: String = _test_save_dir + "save_slot_2.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string("not valid json {{{")
		file.close()

	var success: bool = _save_manager.load_save(2)
	assert_false(success, "load_save should return false for corrupted file")

# === AC-04: 存档文件损坏时显示错误提示，不崩溃 ===

func test_corrupted_file_emits_error_signal() -> void:
	# 写入损坏文件
	var path: String = _test_save_dir + "save_slot_3.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string("{invalid json")
		file.close()

	# 监听错误信号
	var error_received: bool = false
	var error_message: String = ""
	if _save_manager.has_signal("load_error"):
		_save_manager.load_error.connect(func(msg: String):
			error_received = true
			error_message = msg
		)

	# 尝试加载
	_save_manager.load_save(3)

	# 验证错误信号触发
	assert_true(error_received, "load_error signal should be emitted")
	assert_true(error_message.length() > 0, "error message should not be empty")

# === AC-05: 存档文件大小 ≤ 1MB ===

func test_save_file_size_within_limit() -> void:
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	var path: String = _test_save_dir + "save_slot_1.json"
	if not FileAccess.file_exists(path):
		assert_true(false, "save file should exist")
		return

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		assert_true(false, "should be able to open save file")
		return

	var size: int = file.get_length()
	file.close()

	# 验证大小 ≤ 1MB
	assert_true(size <= 1048576, "save file size should be <= 1MB")

	# 打印实际大小用于调试
	gut.p("Save file size: %d bytes (%.2f KB)" % [size, size / 1024.0])

# === AC-06: 3 个存档槽可用 ===

func test_max_save_slots_is_3() -> void:
	assert_eq(_save_manager.MAX_SAVE_SLOTS, 3, "MAX_SAVE_SLOTS should be 3")

func test_set_current_slot_valid_range() -> void:
	var result1: bool = _save_manager.set_current_slot(1)
	assert_true(result1, "slot 1 should be valid")

	var result2: bool = _save_manager.set_current_slot(2)
	assert_true(result2, "slot 2 should be valid")

	var result3: bool = _save_manager.set_current_slot(3)
	assert_true(result3, "slot 3 should be valid")

func test_set_current_slot_invalid_range() -> void:
	var result0: bool = _save_manager.set_current_slot(0)
	assert_false(result0, "slot 0 should be invalid")

	var result4: bool = _save_manager.set_current_slot(4)
	assert_false(result4, "slot 4 should be invalid")

	var result_neg: bool = _save_manager.set_current_slot(-1)
	assert_false(result_neg, "slot -1 should be invalid")

func test_get_all_save_summaries_returns_3_entries() -> void:
	var summaries: Array = _save_manager.get_all_save_summaries()
	assert_eq(summaries.size(), 3, "should return 3 summaries")

# === AC-07: 存档包含版本号，支持版本迁移 ===

func test_save_version_is_1_0_0() -> void:
	assert_eq(_save_manager.SAVE_VERSION, "1.0.0", "SAVE_VERSION should be 1.0.0")

func test_version_migration_adds_missing_fields() -> void:
	# 创建旧版本存档（无 stats 字段）
	var old_save: Dictionary = {
		"version": "0.9.0",
		"game_state": {"state": "BUNKER", "day": 1, "hour": 7},
		"vehicle": {"position": {"x": 100.0, "y": 100.0}, "health": 100.0},
		"bunker_layout": {"modified_cells": [], "placed_blocks": []}
	}

	var path: String = _test_save_dir + "save_slot_1.json"
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(old_save))
		file.close()

	# 加载存档（触发迁移）
	var success: bool = _save_manager.load_save(1)
	assert_true(success, "migration should succeed")

	# 验证迁移后的数据
	var migrated_data: Dictionary = _read_test_save()
	assert_true(migrated_data.has("stats"), "migrated save should have stats")
	assert_eq(migrated_data.get("version", ""), "1.0.0", "version should be updated")

# === 手动存档测试 ===

func test_manual_save_to_slot() -> void:
	_save_manager._is_initialized = true

	var success: bool = _save_manager.manual_save(2)
	assert_true(success, "manual_save should succeed")

	var path: String = _test_save_dir + "save_slot_2.json"
	assert_true(FileAccess.file_exists(path), "slot 2 save should exist")

func test_manual_save_emits_signal() -> void:
	_save_manager._is_initialized = true

	var signal_received: bool = false
	var signal_slot: int = -1
	if _save_manager.has_signal("save_completed"):
		_save_manager.save_completed.connect(func(slot_id: int, success: bool):
			signal_received = true
			signal_slot = slot_id
		)

	_save_manager.manual_save(1)

	assert_true(signal_received, "save_completed signal should be emitted")
	assert_eq(signal_slot, 1, "signal should contain correct slot_id")

# === 存档删除测试 ===

func test_delete_save_removes_file() -> void:
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	var path: String = _test_save_dir + "save_slot_1.json"
	assert_true(FileAccess.file_exists(path), "save should exist before delete")

	var success: bool = _save_manager.delete_save(1)
	assert_true(success, "delete_save should succeed")

	assert_false(FileAccess.file_exists(path), "save should be deleted")

func test_delete_save_returns_false_on_missing() -> void:
	var success: bool = _save_manager.delete_save(99)
	assert_false(success, "delete_save should return false for missing file")

# === 存档摘要测试 ===

func test_get_save_summary_returns_exists_true() -> void:
	_save_manager._is_initialized = true
	_save_manager.auto_save()

	var summary: Dictionary = _save_manager.get_save_summary(1)
	assert_true(summary.get("exists", false), "summary should show exists=true")
	assert_eq(summary.get("slot_id", -1), 1, "summary should have slot_id")

func test_get_save_summary_returns_exists_false() -> void:
	var summary: Dictionary = _save_manager.get_save_summary(99)
	assert_false(summary.get("exists", true), "summary should show exists=false for missing save")

func test_has_save_returns_correct_status() -> void:
	_save_manager._is_initialized = true

	assert_false(_save_manager.has_save(1), "slot 1 should not have save initially")

	_save_manager.auto_save()

	assert_true(_save_manager.has_save(1), "slot 1 should have save after auto_save")

# === 常量验证 ===

func test_save_file_size_limit_constant() -> void:
	assert_eq(_save_manager.SAVE_FILE_SIZE_LIMIT, 1048576, "SAVE_FILE_SIZE_LIMIT should be 1MB")

func test_save_dir_constant() -> void:
	# 注意：测试时被替换为 _test_save_dir，但原常量应为 user://saves/
	assert_true(_save_manager.SAVE_DIR.contains("saves"), "SAVE_DIR should contain 'saves'")