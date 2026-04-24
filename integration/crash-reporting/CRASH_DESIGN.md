# Crash Reporting Design

**铁锈魔潮 (Rust Magic Tide)**

---

## 目标

- 快速定位崩溃原因
- 收集崩溃上下文（场景、设备、操作）
- 监控崩溃率指标
- 优先修复高频崩溃

---

## 崩溃处理流程

```
崩溃发生
    ↓
捕获异常信息
    ↓
生成崩溃报告
    ↓
本地缓存
    ↓
下次启动上传
    ↓
开发者分析
    ↓
修复推送
```

---

## Crash Report Schema

```json
{
  "crash_id": "UUID",
  "timestamp": "ISO8601",
  "build_version": "string",
  "platform": "string",
  "device_info": {
    "os_version": "string",
    "cpu": "string",
    "gpu": "string",
    "memory_mb": "int",
    "screen_resolution": "string"
  },
  "game_state": {
    "scene": "string",
    "session_duration": "int",
    "day_number": "int",
    "player_hp": "int",
    "player_mp": "int"
  },
  "crash_info": {
    "error_type": "string",
    "error_message": "string",
    "stack_trace": "string",
    "stack_trace_hash": "string"
  },
  "logs": {
    "last_10_lines": "array<string>",
    "godot_version": "string"
  }
}
```

---

## Implementation

### CrashManager

```gdscript
# src/crash/crash_manager.gd
class_name CrashManager extends Node

# === 配置 ===
const CRASH_CACHE_DIR: String = "user://crash_reports/"
const MAX_CRASH_FILES: int = 10
const UPLOAD_ENDPOINT: String = "https://crash.example.com/v1/report"

# === 状态 ===
var _session_start_time: int = 0
var _current_scene: String = ""
var _game_state: Dictionary = {}

signal crash_report_uploaded(crash_id: String)

func _ready() -> void:
    # 创建缓存目录
    DirAccess.make_dir_recursive_absolute(CRASH_CACHE_DIR)
    
    # 记录会话开始
    _session_start_time = Time.get_ticks_msec()
    
    # 上传之前的崩溃报告
    _upload_pending_reports()
    
    # 监听场景变化
    get_tree().tree_changed.connect(_on_tree_changed)

# === Game State Tracking ===

func update_game_state(state: Dictionary) -> void:
    _game_state = state

func set_current_scene(scene: String) -> void:
    _current_scene = scene

# === Crash Capture ===

func capture_crash(error_type: String, error_message: String, stack_trace: String) -> void:
    var crash_id: String = UUID.generate()
    
    var report: Dictionary = {
        "crash_id": crash_id,
        "timestamp": Time.get_datetime_string_from_system(),
        "build_version": ProjectSettings.get_setting("application/config/version"),
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
            "last_10_lines": _get_recent_logs(),
            "godot_version": Engine.get_version_info()["string"]
        }
    }
    
    _save_crash_report(crash_id, report)
    AnalyticsManager.crash(error_type, _hash_stack_trace(stack_trace), _current_scene)

func _collect_device_info() -> Dictionary:
    return {
        "os_version": OS.get_version(),
        "cpu": OS.get_processor_name(),
        "gpu": RenderingServer.get_video_adapter_name(),
        "memory_mb": OS.get_static_memory_usage() / 1024 / 1024,
        "screen_resolution": "%dx%d" % [DisplayServer.screen_get_size().x, DisplayServer.screen_get_size().y]
    }

func _collect_game_state() -> Dictionary:
    var duration: int = (Time.get_ticks_msec() - _session_start_time) / 1000
    
    return {
        "scene": _current_scene,
        "session_duration": duration,
        "day_number": _game_state.get("day_number", 0),
        "player_hp": _game_state.get("player_hp", 0),
        "player_mp": _game_state.get("player_mp", 0)
    }

func _hash_stack_trace(stack: String) -> String:
    # 简化 hash：取前 3 行的 MD5
    var lines: Array = stack.split("\n")
    var key_lines: String = ""
    for i in min(3, lines.size()):
        key_lines += lines[i]
    
    return key_lines.md5_text()

func _get_recent_logs() -> Array:
    # Godot 日志提取需要特定配置
    # 这里返回空数组，实际可通过 Godot 的日志文件读取
    return []

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
    
    # 按时间排序，删除最旧的
    if files.size() > MAX_CRASH_FILES:
        files.sort()
        for i in files.size() - MAX_CRASH_FILES:
            dir.remove(files[i])

# === Upload ===

func _upload_pending_reports() -> void:
    var dir: DirAccess = DirAccess.open(CRASH_CACHE_DIR)
    if dir == null:
        return
    
    dir.list_dir_begin()
    var file: String = dir.get_next()
    while file != "":
        if not dir.current_is_dir() and file.ends_with(".json"):
            _upload_single_report(CRASH_CACHE_DIR + file)
        file = dir.get_next()
    dir.list_dir_end()

func _upload_single_report(file_path: String) -> void:
    var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
    if file == null:
        return
    
    var content: String = file.get_as_text()
    file.close()
    
    var json: JSON = JSON.new()
    if json.parse(content) != OK:
        return
    
    var report: Dictionary = json.data
    var crash_id: String = report.get("crash_id", "")
    
    var http: HTTPRequest = HTTPRequest.new()
    add_child(http)
    
    var headers: Array = ["Content-Type: application/json"]
    http.request(UPLOAD_ENDPOINT, headers, HTTPClient.METHOD_POST, content)
    http.request_completed.connect(_on_upload_completed.bind(http, file_path, crash_id))

func _on_upload_completed(result: int, code: int, headers: Array, body: Array, http: HTTPRequest, file_path: String, crash_id: String) -> void:
    http.queue_free()
    
    if code == 200 or code == 201:
        DirAccess.remove_absolute(file_path)
        crash_report_uploaded.emit(crash_id)
    else:
        push_warning("[CrashManager] Upload failed for crash: %s" % crash_id)

# === Manual Trigger (Debug) ===

func simulate_crash(error_type: String = "TEST_CRASH") -> void:
    capture_crash(error_type, "Simulated crash for testing", "Test stack trace\nLine 2\nLine 3")
```

---

## Godot 崩溃捕获

### 方案 A: Main Loop 错误捕获

```gdscript
# 在 Main.gd 或项目根节点
func _notification(what: int) -> void:
    if what == NOTIFICATION_CRASH:
        # Godot 崩溃通知（不保证能执行）
        CrashManager.capture_crash("ENGINE_CRASH", "Godot engine crash", "")
```

### 方案 B: 错误信号监听

```gdscript
# 监听 Godot 错误输出（需配置）
func _ready() -> void:
    # 捕获脚本错误
    # 注意：Godot 4.6 不直接暴露错误信号
    # 需通过 log 文件或自定义错误处理
```

### 方案 C: 包装关键函数

```gdscript
# 包装关键系统调用，捕获异常
func safe_call(func_ref: Callable, args: Array = []) -> Variant:
    var result: Variant = null
    try:
        result = func_ref.callv(args)
    except:
        CrashManager.capture_crash("SCRIPT_ERROR", str(func_ref), "")
    return result
```

---

## 崩溃指标监控

### Dashboard 显示

| 指标 | 计算方式 |
|------|---------|
| **崩溃率** | 崩溃会话数 / 总会话数 |
| **崩溃趋势** | 每日崩溃数折线图 |
| **高频崩溃** | 按 stack_trace_hash 分组计数 |
| **场景崩溃热点** | 按场景分组崩溃数 |
| **设备崩溃分布** | 按 GPU/OS 分组崩溃率 |

### 告警阈值

| 指标 | 阈值 | 响应 |
|------|------|------|
| 崩溃率 > 1% | 24小时内修复 |
| 单崩溃 > 10 次/天 | 最高优先级 |
| 新崩溃类型出现 | 48小时内分析 |

---

## 隐私合规

- 不收集个人信息
- Stack trace hash 匿名化（不包含用户数据）
- 设备信息仅用于兼容性分析
- 用户可关闭崩溃报告（Settings）

---

## 文件清单

| 文件 | 路径 |
|------|------|
| CrashManager | `src/crash/crash_manager.gd` |
| 崩溃缓存目录 | `user://crash_reports/` |

---

## Autoload 注册

```ini
[autoload]

CrashManager="*res://src/crash/crash_manager.gd"
```

---

## 可选第三方方案

| 服务 | 特点 |
|------|------|
| **BugSplat** | 专业崩溃报告，游戏支持 |
| **Sentry** | 通用错误追踪，GDScript SDK |
| **Steam Crash Reporting** | Steamworks 内置 |

---

*Crash Reporting Design — 铁锈魔潮*