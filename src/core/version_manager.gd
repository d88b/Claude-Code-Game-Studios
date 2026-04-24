# VersionManager — 版本信息管理器
# 读取版本号、构建号、发布日期等信息
# Design: assets/data/version.json schema

class_name VersionManager extends Node

# === 配置 ===
const VERSION_FILE: String = "res://assets/data/version.json"

# === 状态 ===
var _version_data: Dictionary = {}

# === 信号 ===
signal version_loaded(version: String)

func _ready() -> void:
    _load_version_data()

func _load_version_data() -> void:
    if not FileAccess.file_exists(VERSION_FILE):
        push_warning("[VersionManager] Version file not found")
        _version_data = _get_default_version()
        return

    var file: FileAccess = FileAccess.open(VERSION_FILE, FileAccess.READ)
    if file == null:
        push_warning("[VersionManager] Failed to open version file")
        _version_data = _get_default_version()
        return

    var content: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()
    if json.parse(content) != OK:
        push_warning("[VersionManager] Failed to parse version JSON")
        _version_data = _get_default_version()
        return

    _version_data = json.data
    version_loaded.emit(get_version())

    print("[VersionManager] Loaded version: %s" % get_version())

func _get_default_version() -> Dictionary:
    return {
        "version": "0.1.0-dev",
        "build_number": 0,
        "release_date": Time.get_datetime_string_from_system(),
        "stage": "development"
    }

# === 公共 API ===

func get_version() -> String:
    return _version_data.get("version", "unknown")

func get_build_number() -> int:
    return _version_data.get("build_number", 0)

func get_release_date() -> String:
    return _version_data.get("release_date", "")

func get_stage() -> String:
    return _version_data.get("stage", "unknown")

func get_game_title() -> String:
    var meta: Dictionary = _version_data.get("metadata", {})
    return meta.get("game_title", "铁锈魔潮")

func get_game_title_en() -> String:
    var meta: Dictionary = _version_data.get("metadata", {})
    return meta.get("game_title_en", "Rust Magic Tide")

func get_developer() -> String:
    var meta: Dictionary = _version_data.get("metadata", {})
    return meta.get("developer", "Unknown")

func get_website() -> String:
    var meta: Dictionary = _version_data.get("metadata", {})
    return meta.get("website", "")

func get_engine_version() -> String:
    var compat: Dictionary = _version_data.get("compatibility", {})
    return compat.get("engine", "Godot 4.6")

func get_full_version_string() -> String:
    return "%s (build %d)" % [get_version(), get_build_number()]

func is_release() -> bool:
    var stage: String = get_stage()
    return stage in ["release", "polish"]

func is_alpha() -> bool:
    return get_version().contains("alpha")

func is_beta() -> bool:
    return get_version().contains("beta")

func get_platforms() -> Array:
    return _version_data.get("platforms", ["windows"])

func get_changelog() -> String:
    return _version_data.get("changelog", "")