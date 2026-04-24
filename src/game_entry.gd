# GameEntry — 游戏入口点
# 在游戏启动时初始化所有系统，确保 Autoload 正确加载
# Attached to AppRoot or main scene root

extends Node

# === 配置 ===
const MIN_LOAD_TIME: float = 0.5  # 最小加载显示时间

# === 状态 ===
var _systems_initialized: bool = false
var _load_start_time: float = 0.0

# === 信号 ===
signal all_systems_ready()

func _ready() -> void:
    _load_start_time = Time.get_ticks_msec() / 1000.0

    print("[GameEntry] Starting initialization...")

    # 等待所有 Autoload 初始化
    await _initialize_systems()

    # 显示启动信息
    _log_startup_info()

    _systems_initialized = true
    all_systems_ready.emit()

    print("[GameEntry] All systems initialized")

func _initialize_systems() -> void:
    # 等待一帧确保所有 Autoload 已加载
    await get_tree().process_frame

    # 检查关键系统
    _check_system("GlobalSignals", GlobalSignals)
    _check_system("LocalizationManager", LocalizationManager)
    _check_system("VersionManager", VersionManager)
    _check_system("AudioManager", AudioManager)
    _check_system("SaveManager", SaveManager)
    _check_system("AnalyticsManager", AnalyticsManager)
    _check_system("AchievementManager", AchievementManager)
    _check_system("CrashManager", CrashManager)
    _check_system("TutorialManager", TutorialManager)

    # 初始化版本信息
    if VersionManager:
        print("[GameEntry] Version: %s" % VersionManager.get_full_version_string())

    # 设置崩溃管理器场景
    if CrashManager:
        CrashManager.set_current_scene("startup")

func _check_system(name: String, instance: Node) -> void:
    if instance == null:
        push_error("[GameEntry] Critical system missing: %s" % name)
    else:
        print("[GameEntry] System loaded: %s" % name)

func _log_startup_info() -> void:
    print("========================================")
    print("  铁锈魔潮 — Rust Magic Tide")
    print("  Version: %s" % VersionManager.get_version())
    print("  Build: %d" % VersionManager.get_build_number())
    print("  Stage: %s" % VersionManager.get_stage())
    print("  Engine: %s" % Engine.get_version_info()["string"])
    print("========================================")

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        # 保存状态
        if _systems_initialized:
            if SaveManager:
                SaveManager.save_game()

            if AnalyticsManager:
                var duration: int = (Time.get_ticks_msec() - _load_start_time * 1000) / 1000
                AnalyticsManager.session_end(duration, "quit")

# === 公共 API ===

func is_initialized() -> bool:
    return _systems_initialized

func get_elapsed_load_time() -> float:
    return Time.get_ticks_msec() / 1000.0 - _load_start_time