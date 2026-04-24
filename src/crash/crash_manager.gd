# CrashManager — 崩溃报告管理器
# 捕获崩溃信息，生成报告，下次启动上传
# Design: integration/crash-reporting/CRASH_DESIGN.md

extends Node

# === 配置 ===
const CRASH_CACHE_DIR: String = "user://crash_reports/"
const MAX_CRASH_FILES: int = 10
const PLAYER_ID_FILE: String = "user://player_id.txt"

# === 信号 ===
signal crash_report_uploaded(crash_id: String)
signal crash_report_saved(crash_id: String)

# === 状态 ===
var _session_start_time: int = 0
var _current_scene: String = ""
var _game_state: Dictionary = {}
var _crash_count: int = 0

# === 上传状态 ===
var _is_uploading: bool = false
var _upload_endpoint: String = "https://crash.example.com/v1/report"

func _ready() -> void:
    # 创建缓存目录
    DirAccess.make_dir_recursive_absolute(CRASH_CACHE_DIR)

    # 记录会话开始
    _session_start_time = Time.get_ticks_msec()

    # 上传之前的崩溃报告
    _upload_pending_reports()

    print("[CrashManager] Initialized — Pending reports: %d" % _count_pending_reports())

# === Game State Tracking ===

func update_game_state(state: Dictionary) -> void:
    # 更新当前游戏状态，用于崩溃上下文
    _game_state = state

func set_current_scene(scene: String) -> void:
    _current_scene = scene

# === Crash Capture ===

func capture_crash(error_type: String, error_message: String, stack_trace: String) -> void:
    var crash_id: String = UUID.generate()

    var report: Dictionary = {
        "crash_id": crash_id,
        "timestamp": Time.get_datetime_string_from_system(),
        "build_version": ProjectSettings.get_setting("application/config/version", "0.1.0"),
        "platform": OS.get_name(),
        "device_info": _collect_device_info(),
        "game_state": _collect_game_state(),
        "crash_info": {
            "error_type": error_type,
            "error_message": error_message,
            "stack_trace": stack_trace,
            "stack_trace_hash": _hash_stack_trace(stack_trace)
        },
        "logs": {
            "last_10_lines": [],  # 需要配置 Godot 日志输出
            "godot_version": Engine.get_version_info()["string"]
        }
    }

    _save_crash_report(crash_id, report)
    _crash_count += 1

    # 发送遥测事件
    if AnalyticsManager:
        AnalyticsManager.crash(error_type, _hash_stack_trace(stack_trace), _current_scene)

    crash_report_saved.emit(crash_id)
    print("[CrashManager] Crash captured: %s — %s" % [crash_id, error_type])

func _collect_device_info() -> Dictionary:
    return {
        "os_version": OS.get_version(),
        "cpu": OS.get_processor_name() if OS.get_processor_name() else "unknown",
        "gpu": RenderingServer.get_video_adapter_name() if RenderingServer.get_video_adapter_name() else "unknown",
        "memory_mb": OS.get_static_memory_usage() / 1024 / 1024,
        "screen_resolution": "%dx%d" % [
            DisplayServer.screen_get_size().x if DisplayServer.screen_get_size() else 0,
            DisplayServer.screen_get_size().y if DisplayServer.screen_get_size() else 0
        ]
    }

func _collect_game_state() -> Dictionary:
    var duration: int = (Time.get_ticks_msec() - _session_start_time) / 1000

    return {
        "scene": _current_scene,
        "session_duration": duration,
        "day_number": _game_state.get("day_number", 0),
        "player_hp": _game_state.get("player_hp", 0),
        "player_mp": _game_state.get("player_mp", 0),
        "explore_active": _game_state.get("explore_active", false)
    }

func _hash_stack_trace(stack: String) -> String:
    # 简化 hash：取前 3 行的 MD5，用于去重
    var lines: Array = stack.split("\n")
    var key_lines: String = ""
    for i in min(3, lines.size()):
        key_lines += lines[i]

    return key_lines.md5_text()

# === Save ===

func _save_crash_report(crash_id: String, report: Dictionary) -> void:
    var file_path: String = CRASH_CACHE_DIR + crash_id + ".json"
    var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)

    if file == null:
        push_error("[CrashManager] Failed to save crash report: %s" % crash_id)
        return

    file.store_string(JSON.stringify(report))
    file.close()

    # 清理旧报告
    _cleanup_old_reports()

func _cleanup_old_reports() -> void:
    var dir: DirAccess = DirAccess.open(CRASH_CACHE_DIR)
    if dir == null:
        return

    var files: Array = []
    dir.list_dir_begin()
    var file: String = dir.get_next()
    while file != "":
        if not dir.current_is_dir() and file.ends_with(".json"):
            files.append(file)
        file = dir.get_next()
    dir.list_dir_end()

    # 按文件名排序（包含时间戳）
    files.sort()

    # 删除最旧的报告
    if files.size() > MAX_CRASH_FILES:
        for i in files.size() - MAX_CRASH_FILES:
            dir.remove(files[i])
            print("[CrashManager] Removed old report: %s" % files[i])

# === Upload ===

func _upload_pending_reports() -> void:
    if _is_uploading:
        return

    var pending: int = _count_pending_reports()
    if pending == 0:
        return

    _is_uploading = true

    var dir: DirAccess = DirAccess.open(CRASH_CACHE_DIR)
    if dir == null:
        _is_uploading = false
        return

    dir.list_dir_begin()
    var file: String = dir.get_next()
    while file != "":
        if not dir.current_is_dir() and file.ends_with(".json"):
            _upload_single_report(CRASH_CACHE_DIR + file)
            # 等待上传完成（简化处理）
            await get_tree().create_timer(0.1).timeout
        file = dir.get_next()
    dir.list_dir_end()

    _is_uploading = false

func _upload_single_report(file_path: String) -> void:
    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return

    var content: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()
    if json.parse(content) != OK:
        DirAccess.remove_absolute(file_path)
        return

    var report: Dictionary = json.data
    var crash_id: String = report.get("crash_id", "")

    var http: HTTPRequest = HTTPRequest.new()
    add_child(http)

    var headers: Array = ["Content-Type: application/json"]
    var err: int = http.request(_upload_endpoint, headers, HTTPClient.METHOD_POST, content)

    if err != OK:
        push_warning("[CrashManager] Upload request failed: %s" % crash_id)
        http.queue_free()
        return

    http.request_completed.connect(_on_upload_completed.bind(http, file_path, crash_id))

func _on_upload_completed(result: int, code: int, headers: Array, body: Array, http: HTTPRequest, file_path: String, crash_id: String) -> void:
    http.queue_free()

    if code == 200 or code == 201:
        DirAccess.remove_absolute(file_path)
        crash_report_uploaded.emit(crash_id)
        print("[CrashManager] Report uploaded: %s" % crash_id)
    else:
        push_warning("[CrashManager] Upload failed (code %d): %s" % [code, crash_id])

# === 辅助 ===

func _count_pending_reports() -> int:
    var dir: DirAccess = DirAccess.open(CRASH_CACHE_DIR)
    if dir == null:
        return 0

    var count: int = 0
    dir.list_dir_begin()
    var file: String = dir.get_next()
    while file != "":
        if not dir.current_is_dir() and file.ends_with(".json"):
            count += 1
        file = dir.get_next()
    dir.list_dir_end()

    return count

# === Manual Trigger (Debug) ===

func simulate_crash(error_type: String = "TEST_CRASH") -> void:
    capture_crash(error_type, "Simulated crash for testing", "Test stack trace\nLine 2\nLine 3")
    print("[CrashManager] Simulated crash created")

# === 错误处理包装器 ===

func safe_call(func_ref: Callable, args: Array = [], context: String = "") -> Variant:
    var result: Variant = null
    try:
        result = func_ref.callv(args)
    except:
        var error: String = "Safe call failed: %s" % context
        capture_crash("SCRIPT_ERROR", error, str(func_ref))
    return result

# === 公共 API ===

func get_crash_count() -> int:
    return _crash_count

func get_pending_count() -> int:
    return _count_pending_reports()

func set_upload_endpoint(url: String) -> void:
    _upload_endpoint = url

func has_pending_reports() -> bool:
    return _count_pending_reports() > 0