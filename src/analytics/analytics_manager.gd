# AnalyticsManager — 遥测数据管理器
# 收集玩家行为数据，批量上传，支持离线缓存
# Design: integration/analytics/ANALYTICS_DESIGN.md

extends Node

# === 配置 ===
const UPLOAD_INTERVAL: int = 300  # 5 分钟
const MAX_QUEUE_SIZE: int = 100
const CACHE_FILE: String = "user://analytics_cache.json"
const PLAYER_ID_FILE: String = "user://player_id.txt"

# === 信号 ===
signal events_uploaded(count: int)
signal upload_failed(error: String)

# === 状态 ===
var _session_id: String = ""
var _player_id: String = ""
var _event_queue: Array[Dictionary] = []
var _upload_timer: float = 0.0
var _is_online: bool = true
var _enabled: bool = true
var _endpoint_url: String = "https://analytics.example.com/v1/events"

# === 统计 ===
var _total_events_sent: int = 0
var _session_start_time: int = 0

func _ready() -> void:
    # 生成匿名 ID
    _player_id = _generate_or_load_player_id()
    _session_id = UUID.generate()
    _session_start_time = Time.get_ticks_msec()

    # 加载离线缓存
    _load_cached_events()

    # 记录会话开始
    session_start()

    print("[AnalyticsManager] Initialized — Player: %s, Session: %s" % [_player_id, _session_id])

func _process(delta: float) -> void:
    if not _enabled:
        return

    _upload_timer += delta
    if _upload_timer >= UPLOAD_INTERVAL:
        _upload_timer = 0.0
        _try_upload_events()

func _exit_tree() -> void:
    # 记录会话结束
    var duration: int = (Time.get_ticks_msec() - _session_start_time) / 1000
    session_end(duration)

    # 强制上传
    _try_upload_events()
    _cache_events()

# === Event Recording ===

func record_event(event_name: String, data: Dictionary = {}) -> void:
    if not _enabled:
        return

    var event: Dictionary = {
        "event_name": event_name,
        "event_timestamp": Time.get_datetime_string_from_system(),
        "session_id": _session_id,
        "player_id": _player_id,
        "build_version": ProjectSettings.get_setting("application/config/version") if ProjectSettings.has_setting("application/config/version") else "0.1.0",
        "platform": OS.get_name(),
        "locale": TranslationServer.get_locale(),
        "event_data": data
    }

    _event_queue.append(event)

    # 队列满时强制上传
    if _event_queue.size() >= MAX_QUEUE_SIZE:
        _try_upload_events()

# === Convenience Methods ===

func session_start(first_launch: bool = false) -> void:
    record_event("session_start", {"first_launch": first_launch})

func session_end(duration: int, reason: String = "normal") -> void:
    record_event("session_end", {
        "duration_seconds": duration,
        "exit_reason": reason
    })

func explore_start(bunker_level: int, resources: Dictionary) -> void:
    record_event("explore_start", {
        "bunker_level": bunker_level,
        "resources_held": resources
    })

func explore_end(duration: int, collected: Dictionary, killed: int, result: String) -> void:
    record_event("explore_end", {
        "duration": duration,
        "resources_collected": collected,
        "enemies_killed": killed,
        "result": result
    })

func wave_start(wave_number: int, day_count: int) -> void:
    record_event("wave_start", {
        "wave_number": wave_number,
        "day_count": day_count
    })

func wave_end(wave_number: int, enemies_remaining: int, turrets_active: int, result: String) -> void:
    record_event("wave_end", {
        "wave_number": wave_number,
        "enemies_remaining": enemies_remaining,
        "turrets_active": turrets_active,
        "result": result
    })

func death(hp: int, mp: int, location: String, enemy: String) -> void:
    record_event("death", {
        "hp_remaining": hp,
        "mp_remaining": mp,
        "location": location,
        "enemy_type": enemy
    })

func retreat(hp: int, resources: Dictionary, time_remaining: int) -> void:
    record_event("retreat", {
        "hp_at_retreat": hp,
        "resources_carried": resources,
        "time_remaining": time_remaining
    })

func resource_pickup(resource_type: String, amount: int, location: String) -> void:
    record_event("resource_pickup", {
        "resource_type": resource_type,
        "amount": amount,
        "location": location
    })

func facility_build(facility_type: String, cost: Dictionary, position: Vector2) -> void:
    record_event("facility_build", {
        "facility_type": facility_type,
        "cost": cost,
        "position": {"x": position.x, "y": position.y}
    })

func facility_destroy(facility_type: String, age_seconds: int) -> void:
    record_event("facility_destroy", {
        "facility_type": facility_type,
        "age_seconds": age_seconds
    })

func day_complete(day_number: int, resources_total: Dictionary) -> void:
    record_event("day_complete", {
        "day_number": day_number,
        "resources_total": resources_total
    })

func tutorial_step(step_id: int, skipped: bool) -> void:
    record_event("tutorial_step", {
        "step_id": step_id,
        "skipped": skipped
    })

func performance_snapshot(fps_avg: int, fps_min: int, memory: int) -> void:
    record_event("performance_snapshot", {
        "fps_avg": fps_avg,
        "fps_min": fps_min,
        "memory_mb": memory
    })

func crash(error: String, stack_hash: String, scene: String) -> void:
    record_event("crash", {
        "error_type": error,
        "stack_trace_hash": stack_hash,
        "scene": scene
    })

# === Upload ===

func _try_upload_events() -> void:
    if _event_queue.is_empty():
        return

    if not _is_online:
        _cache_events()
        return

    var payload: Dictionary = {
        "events": _event_queue
    }

    var http: HTTPRequest = HTTPRequest.new()
    add_child(http)

    var json: String = JSON.stringify(payload)
    var headers: Array = ["Content-Type: application/json"]

    var err: int = http.request(_endpoint_url, headers, HTTPClient.METHOD_POST, json)

    if err != OK:
        push_warning("[AnalyticsManager] Upload request failed: %d" % err)
        _cache_events()
        http.queue_free()
        return

    http.request_completed.connect(_on_upload_completed.bind(http))

func _on_upload_completed(result: int, code: int, headers: Array, body: Array, http: HTTPRequest) -> void:
    http.queue_free()

    if code == 200 or code == 201:
        var count: int = _event_queue.size()
        _event_queue.clear()
        _total_events_sent += count
        events_uploaded.emit(count)
        _clear_cache()
    else:
        var error: String = "HTTP code: %d" % code
        push_warning("[AnalyticsManager] Upload failed: %s" % error)
        upload_failed.emit(error)
        _cache_events()

# === Cache ===

func _cache_events() -> void:
    if _event_queue.is_empty():
        return

    var file: FileAccess = FileAccess.open(CACHE_FILE, FileAccess.WRITE)
    if file == null:
        push_warning("[AnalyticsManager] Failed to cache events")
        return

    file.store_string(JSON.stringify(_event_queue))
    file.close()

func _load_cached_events() -> void:
    if not FileAccess.file_exists(CACHE_FILE):
        return

    var file: FileAccess = FileAccess.open(CACHE_FILE, FileAccess.READ)
    if file == null:
        return

    var content: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()
    if json.parse(content) == OK and json.data is Array:
        for event in json.data:
            _event_queue.append(event)

    _clear_cache()

func _clear_cache() -> void:
    if FileAccess.file_exists(CACHE_FILE):
        DirAccess.remove_absolute(CACHE_FILE)

# === Player ID ===

func _generate_or_load_player_id() -> String:
    if FileAccess.file_exists(PLAYER_ID_FILE):
        var file: FileAccess = FileAccess.open(PLAYER_ID_FILE, FileAccess.READ)
        if file != null:
            var id: String = file.get_as_text().strip_edges()
            file.close()
            if not id.is_empty():
                return id

    # 生成新 ID
    var new_id: String = UUID.generate()
    var file: FileAccess = FileAccess.open(PLAYER_ID_FILE, FileAccess.WRITE)
    if file != null:
        file.store_string(new_id)
        file.close()

    return new_id

# === Privacy Control ===

func set_enabled(enabled: bool) -> void:
    _enabled = enabled
    if not enabled:
        _event_queue.clear()
        _clear_cache()

func is_enabled() -> bool:
    return _enabled

func set_endpoint(url: String) -> void:
    _endpoint_url = url

func set_online_status(online: bool) -> void:
    _is_online = online

# === Statistics ===

func get_session_id() -> String:
    return _session_id

func get_player_id() -> String:
    return _player_id

func get_pending_events() -> int:
    return _event_queue.size()

func get_total_events_sent() -> int:
    return _total_events_sent