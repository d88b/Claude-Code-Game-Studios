# Analytics Telemetry Design

**铁锈魔潮 (Rust Magic Tide)**

---

## 遥测目标

- 理解玩家行为（留存、流失点、难度瓶颈）
- 验证设计假设（Fun hypothesis、难度曲线）
- 数据驱动平衡调整
- 监控技术健康（崩溃率、性能指标）

---

## 遥测架构

### 设计原则

1. **隐私优先**: 不收集个人信息，不追踪地理位置
2. **最小化采集**: 只采集设计决策所需数据
3. **透明告知**: 隐私政策明确说明数据用途
4. **GDPR/CCPA 合规**: 提供数据删除选项

### 技术方案

| 属性 | 选择 |
|------|------|
| **方案** | 自建轻量遥测 +可选第三方（GameAnalytics） |
| **传输** | HTTPS POST，JSON 格式 |
| **频率** | 批量上传，每 5 分钟或关卡结束 |
| **离线处理** | 本地缓存，联网后上传 |

---

## Event Schema

### 通用字段

```json
{
  "event_name": "string",
  "event_timestamp": "ISO8601",
  "session_id": "UUID",
  "player_id": "UUID (anonymous)",
  "build_version": "string",
  "platform": "string",
  "locale": "string",
  "event_data": {}
}
```

---

## 核心事件定义

### Session Events

| Event | 触发时机 | 数据字段 |
|-------|---------|---------|
| `session_start` | 游戏启动 | `first_launch: bool` |
| `session_end` | 游戏关闭 | `duration_seconds: int`, `exit_reason: string` |

### Gameplay Events

| Event | 触发时机 | 数据字段 |
|-------|---------|---------|
| `explore_start` | 出发探索 | `bunker_level: int`, `resources_held: dict` |
| `explore_end` | 返回/失败 | `duration: int`, `resources_collected: dict`, `enemies_killed: int`, `result: string` |
| `wave_start` | 夜晚波次开始 | `wave_number: int`, `day_count: int` |
| `wave_end` | 波次结束 | `wave_number: int`, `enemies_remaining: int`, `turrets_active: int`, `result: string` |
| `death` | 战车被毁 | `hp_remaining: int`, `mp_remaining: int`, `location: string`, `enemy_type: string` |
| `retreat` | 返回地堡 | `hp_at_retreat: int`, `resources_carried: dict`, `time_remaining: int` |

### Resource Events

| Event | 触发时机 | 数据字段 |
|-------|---------|---------|
| `resource_pickup` | 拾取资源 | `resource_type: string`, `amount: int`, `location: string` |
| `facility_build` | 建造设施 | `facility_type: string`, `cost: dict`, `position: string` |
| `facility_destroy` | 设施被毁 | `facility_type: string`, `age_seconds: int` |
| `turret_fire` | 炮塔射击 | `turret_type: string`, `damage: int` |

### Progression Events

| Event | 触发时机 | 数据字段 |
|-------|---------|---------|
| `day_complete` | 完成一个日循环 | `day_number: int`, `resources_total: dict` |
| `milestone_reached` | 达成里程碑 | `milestone_id: string` |
| `tutorial_step` | 教程步骤 | `step_id: int`, `skipped: bool` |

### Technical Events

| Event | 触发时机 | 数据字段 |
|-------|---------|---------|
| `performance_snapshot` | 每 5 分钟 | `fps_avg: int`, `fps_min: int`, `memory_mb: int` |
| `crash` | 崩溃发生 | `error_type: string`, `stack_trace_hash: string`, `scene: string` |
| `load_time` | 场景加载 | `scene_name: string`, `duration_ms: int` |

---

## Implementation

### AnalyticsManager

```gdscript
# src/analytics/analytics_manager.gd
class_name AnalyticsManager extends Node

# === 配置 ===
const ENDPOINT_URL: String = "https://analytics.example.com/v1/events"
const UPLOAD_INTERVAL: int = 300  # 5 分钟
const MAX_QUEUE_SIZE: int = 100
const CACHE_FILE: String = "user://analytics_cache.json"

# === 状态 ===
var _session_id: String = ""
var _player_id: String = ""
var _event_queue: Array[Dictionary] = []
var _upload_timer: float = 0.0
var _is_online: bool = false
var _enabled: bool = true

signal events_uploaded(count: int)

func _ready() -> void:
    # 生成匿名 ID
    _player_id = _generate_or_load_player_id()
    _session_id = UUID.generate()
    
    # 加载离线缓存
    _load_cached_events()
    
    # 检查网络
    _check_online_status()

func _process(delta: float) -> void:
    if not _enabled:
        return
    
    _upload_timer += delta
    if _upload_timer >= UPLOAD_INTERVAL:
        _upload_timer = 0.0
        _try_upload_events()

# === Event Recording ===

func record_event(event_name: String, data: Dictionary = {}) -> void:
    if not _enabled:
        return
    
    var event: Dictionary = {
        "event_name": event_name,
        "event_timestamp": Time.get_datetime_string_from_system(),
        "session_id": _session_id,
        "player_id": _player_id,
        "build_version": ProjectSettings.get_setting("application/config/version"),
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
    # 强制上传
    _try_upload_events()

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

func death(hp: int, mp: int, location: String, enemy: String) -> void:
    record_event("death", {
        "hp_remaining": hp,
        "mp_remaining": mp,
        "location": location,
        "enemy_type": enemy
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
    # 立即缓存，下次启动上传
    _cache_events()

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
    
    var err: int = http.request(ENDPOINT_URL, headers, HTTPClient.METHOD_POST, json)
    
    if err != OK:
        push_warning("[Analytics] Upload failed: %d" % err)
        _cache_events()
        http.queue_free()
        return
    
    # 等待响应
    http.request_completed.connect(_on_upload_completed.bind(http))

func _on_upload_completed(result: int, code: int, headers: Array, body: Array, http: HTTPRequest) -> void:
    http.queue_free()
    
    if code == 200 or code == 201:
        var count: int = _event_queue.size()
        _event_queue.clear()
        events_uploaded.emit(count)
        _clear_cache()
    else:
        push_warning("[Analytics] Upload failed with code: %d" % code)
        _cache_events()

# === Network Status ===

func _check_online_status() -> void:
    # 简单检查
    var http: HTTPRequest = HTTPRequest.new()
    add_child(http)
    http.request("https://api.example.com/ping", [], HTTPClient.METHOD_GET)
    http.request_completed.connect(_on_ping_completed.bind(http))

func _on_ping_completed(result: int, code: int, headers: Array, body: Array, http: HTTPRequest) -> void:
    http.queue_free()
    _is_online = (code == 200)

# === Cache ===

func _cache_events() -> void:
    var file: FileAccess = FileAccess.open(CACHE_FILE, FileAccess.WRITE)
    if file == null:
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
    if json.parse(content) == OK:
        var cached: Array = json.data
        for event in cached:
            _event_queue.append(event)
    
    _clear_cache()

func _clear_cache() -> void:
    if FileAccess.file_exists(CACHE_FILE):
        DirAccess.remove_absolute(CACHE_FILE)

# === Player ID ===

func _generate_or_load_player_id() -> String:
    const ID_FILE: String = "user://player_id.txt"
    
    if FileAccess.file_exists(ID_FILE):
        var file: FileAccess = FileAccess.open(ID_FILE, FileAccess.READ)
        if file != null:
            var id: String = file.get_as_text().strip_edges()
            file.close()
            if not id.is_empty():
                return id
    
    # 生成新 ID
    var new_id: String = UUID.generate()
    var file: FileAccess = FileAccess.open(ID_FILE, FileAccess.WRITE)
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
```

---

## UUID Helper

```gdscript
# src/utils/uuid.gd
class_name UUID

static func generate() -> String:
    # 简化 UUID 生成（Godot 4.6）
    var bytes: Array = []
    for i in 16:
        bytes.append(randi() % 256)
    
    # 设置版本位 (version 4)
    bytes[6] = (bytes[6] & 0x0F) | 0x40
    bytes[8] = (bytes[8] & 0x3F) | 0x80
    
    # 格式化
    return "%02x%02x%02x%02x-%02x%02x-%02x%02x-%02x%02x-%02x%02x%02x%02x%02x%02x" % bytes
```

---

## 数据分析指标

### 关键指标 (KPI)

| 指标 | 定义 | 目标值 |
|------|------|--------|
| **次日留存** | Day 1 Retention | > 30% |
| **7日留存** | Day 7 Retention | > 10% |
| **平均会话时长** | Avg Session Duration | > 15 min |
| **首次完成率** | Day 1 Complete Rate | > 80% |
| **崩溃率** | Crash Rate | < 1% |

### 行为分析

| 分析 | 用途 |
|------|------|
| **流失点分析** | 找出玩家退出最多的场景 |
| **难度曲线验证** | 比较实际死亡率 vs 设计曲线 |
| **资源经济分析** | 验证资源消耗/获取平衡 |
| **设施使用热度** | 确定哪些设施被使用最多 |

---

## 隐私合规

### GDPR 要求

- 隐私政策明确说明数据用途
- 用户可关闭遥测
- 提供数据删除请求渠道
- 数据不转移至第三方（除非明确说明）

### CCPA 要求

- 不出售个人信息
- 用户可要求删除数据
- 用户可拒绝数据收集

---

## 文件清单

| 文件 | 路径 |
|------|------|
| AnalyticsManager | `src/analytics/analytics_manager.gd` |
| UUID Helper | `src/utils/uuid.gd` |
| 隐私政策 | `legal/PRIVACY_POLICY.md` |

---

## Autoload 注册

```ini
[autoload]

AnalyticsManager="*res://src/analytics/analytics_manager.gd"
```

---

## 可选第三方方案

如果自建成本过高，可使用第三方服务：

| 服务 | 特点 |
|------|------|
| **GameAnalytics** | 免费，游戏专用，GDPR 合规 |
| **Unity Analytics** | Unity 专用（本项目不适用） |
| **Steam Analytics** | Steamworks 内置，需 Steam 账号 |

---

*Analytics Telemetry Design — 铁锈魔潮*