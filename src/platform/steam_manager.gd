# SteamManager — Steamworks 集成管理器
# 处理 Steam SDK 初始化、成就同步、云存储等
# Design: production/store/STEAM_SDK_GUIDE.md
# 注意: 完整实现需要 GodotSteam GDExtension

extends Node

# === 配置 ===
# 替换为实际 App ID
const STEAM_APP_ID: int = 0  # TODO: 填入实际 Steam App ID

# === 信号 ===
signal steam_initialized(success: bool)
signal steam_error(error_message: String)
signal achievement_set(achievement_id: String)

# === 状态 ===
var _is_initialized: bool = false
var _steam_id: int = 0
var _user_name: String = ""
var _test_mode: bool = false

# === Steam SDK 状态 ===
var _steam_available: bool = false

func _ready() -> void:
    # 检查是否在 Steam 环境运行
    if not OS.has_feature("steam"):
        if OS.is_debug_build():
            # Debug 模式使用测试模式
            _test_mode = true
            _is_initialized = true
            print("[SteamManager] Test mode initialized (debug build)")
        else:
            push_warning("[SteamManager] Not running in Steam environment")
            steam_initialized.emit(false)
        return

    # 尝试初始化 Steam
    _init_steam()

func _init_steam() -> void:
    # 完整实现需要 GodotSteam GDExtension
    # 当前为占位实现

    if STEAM_APP_ID == 0:
        push_warning("[SteamManager] Steam App ID not configured")
        steam_initialized.emit(false)
        return

    # TODO: GodotSteam API 调用
    # Steam.init()
    # Steam.isSteamRunning()

    _is_initialized = true
    _steam_id = _get_steam_id()
    _user_name = _get_user_name()

    steam_initialized.emit(true)
    print("[SteamManager] Initialized — Steam ID: %d, User: %s" % [_steam_id, _user_name])

func _get_steam_id() -> int:
    # TODO: GodotSteam API
    # return Steam.getSteamID()
    return 0

func _get_user_name() -> String:
    # TODO: GodotSteam API
    # return Steam.getPersonaName()
    return "Player"

# === 公共 API ===

func is_initialized() -> bool:
    return _is_initialized

func get_steam_id() -> int:
    return _steam_id

func get_user_name() -> String:
    return _user_name

func is_test_mode() -> bool:
    return _test_mode

# === 成绩 API ===

func set_achievement(achievement_id: String) -> bool:
    if not _is_initialized:
        return false

    if _test_mode:
        print("[SteamManager] Test mode: achievement set — %s" % achievement_id)
        achievement_set.emit(achievement_id)
        return true

    # TODO: GodotSteam API
    # Steam.setAchievement(achievement_id)
    # Steam.storeStats()

    achievement_set.emit(achievement_id)
    return true

func clear_achievement(achievement_id: String) -> bool:
    if not _is_initialized:
        return false

    if _test_mode:
        print("[SteamManager] Test mode: achievement cleared — %s" % achievement_id)
        return true

    # TODO: GodotSteam API
    # Steam.clearAchievement(achievement_id)
    # Steam.storeStats()

    return true

func get_achievement(achievement_id: String) -> bool:
    if not _is_initialized:
        return false

    if _test_mode:
        return false

    # TODO: GodotSteam API
    # return Steam.getAchievement(achievement_id)
    return false

# === 统计 API ===

func set_stat_int(stat_name: String, value: int) -> bool:
    if not _is_initialized:
        return false

    if _test_mode:
        print("[SteamManager] Test mode: stat set — %s = %d" % [stat_name, value])
        return true

    # TODO: GodotSteam API
    # Steam.setStatInt(stat_name, value)
    # Steam.storeStats()

    return true

func get_stat_int(stat_name: String) -> int:
    if not _is_initialized:
        return 0

    if _test_mode:
        return 0

    # TODO: GodotSteam API
    # return Steam.getStatInt(stat_name)
    return 0

func set_stat_float(stat_name: String, value: float) -> bool:
    if not _is_initialized:
        return false

    if _test_mode:
        print("[SteamManager] Test mode: stat set — %s = %f" % [stat_name, value])
        return true

    # TODO: GodotSteam API
    # Steam.setStatFloat(stat_name, value)
    # Steam.storeStats()

    return true

func get_stat_float(stat_name: String) -> float:
    if not _is_initialized:
        return 0.0

    if _test_mode:
        return 0.0

    # TODO: GodotSteam API
    # return Steam.getStatFloat(stat_name)
    return 0.0

# === 云存储 API ===

func cloud_save(key: String, data: Dictionary) -> bool:
    if not _is_initialized:
        return false

    if _test_mode:
        print("[SteamManager] Test mode: cloud save — %s" % key)
        return true

    # TODO: GodotSteam API
    # Steam.fileWrite(key, JSON.stringify(data))

    return true

func cloud_load(key: String) -> Dictionary:
    if not _is_initialized:
        return {}

    if _test_mode:
        return {}

    # TODO: GodotSteam API
    # var content: String = Steam.fileRead(key)
    # return JSON.parse_string(content)

    return {}

func cloud_delete(key: String) -> bool:
    if not _is_initialized:
        return false

    if _test_mode:
        print("[SteamManager] Test mode: cloud delete — %s" % key)
        return true

    # TODO: GodotSteam API
    # Steam.fileDelete(key)

    return true

# === Steam App ID 文件 ===

func create_steam_appid_file() -> void:
    # 创建 steam_appid.txt 文件（发布时需要）
    if STEAM_APP_ID == 0:
        return

    var file: FileAccess = FileAccess.open("res://steam_appid.txt", FileAccess.WRITE)
    if file != null:
        file.store_string(str(STEAM_APP_ID))
        file.close()
        print("[SteamManager] steam_appid.txt created — App ID: %d" % STEAM_APP_ID)

# === 错误处理 ===

func _on_steam_error(error_code: int) -> void:
    var message: String = "Steam error code: %d" % error_code
    steam_error.emit(message)
    push_error("[SteamManager] %s" % message)