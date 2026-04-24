# AchievementManager — 成绩系统管理器
# 管理成绩解锁、进度追踪、Steam 同步
# Design: integration/achievements/ACHIEVEMENT_DESIGN.md

class_name AchievementManager extends Node

# === 配置 ===
const ACHIEVEMENT_FILE: String = "user://achievements.json"

# === 信号 ===
signal achievement_unlocked(achievement_id: String, achievement_name: String)
signal achievement_progress(achievement_id: String, current: int, target: int)

# === 成绩定义 ===
var _achievement_defs: Dictionary = {}

# === 状态 ===
var _unlocked: Dictionary = {}
var _progress: Dictionary = {}

# === 统计 ===
var _stats: Dictionary = {
    "explore_count": 0,
    "kill_count": 0,
    "build_count": 0,
    "resource_total": 0,
    "day_max": 0,
    "rare_count": 0,
    "death_count": 0
}

func _ready() -> void:
    _load_achievement_defs()
    _load_achievement_data()
    _setup_event_listeners()

    print("[AchievementManager] Initialized — %d/%d unlocked" % [_unlocked.size(), _achievement_defs.size()])

# === 定义加载 ===

func _load_achievement_defs() -> void:
    _achievement_defs = {
        # Exploration
        "explore_first": {
            "name": "初次探索",
            "desc": "第一次离开地堡",
            "category": "exploration",
            "hidden": false,
            "icon": "achievement_explore"
        },
        "explore_10": {
            "name": "熟悉地形",
            "desc": "完成 10 次探索",
            "category": "exploration",
            "target": 10,
            "hidden": false,
            "icon": "achievement_explore"
        },
        "explore_50": {
            "name": "探索大师",
            "desc": "完成 50 次探索",
            "category": "exploration",
            "target": 50,
            "hidden": false,
            "icon": "achievement_explore"
        },
        "explore_night": {
            "name": "夜行者",
            "desc": "在夜晚返回地堡",
            "category": "exploration",
            "hidden": false,
            "icon": "achievement_night"
        },
        "explore_full_day": {
            "name": "全天候",
            "desc": "从早到晚连续探索",
            "category": "exploration",
            "hidden": true,
            "icon": "achievement_explore"
        },

        # Combat
        "kill_first": {
            "name": "初次击杀",
            "desc": "击杀第一个敌人",
            "category": "combat",
            "hidden": false,
            "icon": "achievement_kill"
        },
        "kill_100": {
            "name": "战斗新手",
            "desc": "累计击杀 100 敌人",
            "category": "combat",
            "target": 100,
            "hidden": false,
            "icon": "achievement_kill"
        },
        "kill_500": {
            "name": "战斗老兵",
            "desc": "累计击杀 500 敌人",
            "category": "combat",
            "target": 500,
            "hidden": false,
            "icon": "achievement_kill"
        },
        "kill_boss": {
            "name": "Boss 猎人",
            "desc": "击杀 Boss",
            "category": "combat",
            "hidden": false,
            "icon": "achievement_boss"
        },
        "kill_wave": {
            "name": "波次清零",
            "desc": "单波次零敌人剩余",
            "category": "combat",
            "hidden": false,
            "icon": "achievement_wave"
        },
        "no_damage_wave": {
            "name": "完美防守",
            "desc": "单波次战车零伤害",
            "category": "combat",
            "hidden": false,
            "icon": "achievement_perfect"
        },

        # Building
        "build_first": {
            "name": "初次建造",
            "desc": "建造第一个设施",
            "category": "building",
            "hidden": false,
            "icon": "achievement_build"
        },
        "build_10": {
            "name": "建筑工",
            "desc": "建造 10 个设施",
            "category": "building",
            "target": 10,
            "hidden": false,
            "icon": "achievement_build"
        },
        "build_50": {
            "name": "建筑大师",
            "desc": "建造 50 个设施",
            "category": "building",
            "target": 50,
            "hidden": false,
            "icon": "achievement_build"
        },
        "turret_master": {
            "name": "炮塔专家",
            "desc": "同时激活 5 炮塔",
            "category": "building",
            "hidden": false,
            "icon": "achievement_turret"
        },
        "all_facilities": {
            "name": "设施全集",
            "desc": "使用所有设施类型",
            "category": "building",
            "hidden": true,
            "icon": "achievement_build"
        },

        # Resources
        "resource_1000": {
            "name": "收集者",
            "desc": "累计收集 1000 单位资源",
            "category": "resources",
            "target": 1000,
            "hidden": false,
            "icon": "achievement_resource"
        },
        "resource_10000": {
            "name": "资源大亨",
            "desc": "累计收集 10000 单位资源",
            "category": "resources",
            "target": 10000,
            "hidden": false,
            "icon": "achievement_resource"
        },
        "rare_pickup": {
            "name": "稀有发现",
            "desc": "拾取稀有物品",
            "category": "resources",
            "hidden": false,
            "icon": "achievement_rare"
        },
        "rare_10": {
            "name": "稀有猎人",
            "desc": "拾取 10 个稀有物品",
            "category": "resources",
            "target": 10,
            "hidden": false,
            "icon": "achievement_rare"
        },

        # Survival
        "survive_day_1": {
            "name": "第一天",
            "desc": "完成第一天",
            "category": "survival",
            "hidden": false,
            "icon": "achievement_day"
        },
        "survive_day_5": {
            "name": "五日生存",
            "desc": "完成第五天",
            "category": "survival",
            "hidden": false,
            "icon": "achievement_day"
        },
        "survive_day_10": {
            "name": "十日老兵",
            "desc": "完成第十天",
            "category": "survival",
            "hidden": false,
            "icon": "achievement_day"
        },
        "survive_day_30": {
            "name": "月度冠军",
            "desc": "完成第三十天",
            "category": "survival",
            "hidden": true,
            "icon": "achievement_day"
        },
        "low_hp_return": {
            "name": "险境逃生",
            "desc": "HP<10 时成功返回",
            "category": "survival",
            "hidden": false,
            "icon": "achievement_escape"
        },

        # Special
        "tutorial_complete": {
            "name": "教程完成",
            "desc": "完成新手教程",
            "category": "special",
            "hidden": false,
            "icon": "achievement_tutorial"
        },
        "skip_tutorial": {
            "name": "自学者",
            "desc": "跳过教程完成第一天",
            "category": "special",
            "hidden": true,
            "icon": "achievement_special"
        },
        "death_10": {
            "name": "持之以恒",
            "desc": "死亡 10 次后继续游戏",
            "category": "special",
            "hidden": true,
            "icon": "achievement_special"
        },
        "perfect_day": {
            "name": "完美一天",
            "desc": "单天: 零死亡、零失败、收集>500",
            "category": "special",
            "hidden": true,
            "icon": "achievement_perfect"
        }
    }

# === 数据加载/保存 ===

func _load_achievement_data() -> void:
    if not FileAccess.file_exists(ACHIEVEMENT_FILE):
        return

    var file: FileAccess = FileAccess.open(ACHIEVEMENT_FILE, FileAccess.READ)
    if file == null:
        return

    var content: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()
    if json.parse(content) == OK:
        _unlocked = json.data.get("unlocked", {})
        _progress = json.data.get("progress", {})
        _stats = json.data.get("stats", _stats)

func _save_achievement_data() -> void:
    var file: FileAccess = FileAccess.open(ACHIEVEMENT_FILE, FileAccess.WRITE)
    if file == null:
        return

    var data: Dictionary = {
        "unlocked": _unlocked,
        "progress": _progress,
        "stats": _stats
    }

    file.store_string(JSON.stringify(data))
    file.close()

# === 事件监听 ===

func _setup_event_listeners() -> void:
    # 监听游戏事件（通过 GlobalSignals）
    if GlobalSignals:
        GlobalSignals.explore_completed.connect(_on_explore_complete)
        GlobalSignals.enemy_killed.connect(_on_enemy_killed)
        GlobalSignals.facility_created.connect(_on_facility_created)
        GlobalSignals.resource_collected.connect(_on_resource_collected)
        GlobalSignals.day_completed.connect(_on_day_completed)
        GlobalSignals.tutorial_completed.connect(_on_tutorial_complete)
        GlobalSignals.wave_completed.connect(_on_wave_complete)
        GlobalSignals.player_death.connect(_on_player_death)
        GlobalSignals.retreat_success.connect(_on_retreat_success)

# === 解锁逻辑 ===

func check_achievement(achievement_id: String, increment: int = 1) -> void:
    if _unlocked.has(achievement_id):
        return  # 已解锁

    var def: Dictionary = _achievement_defs.get(achievement_id, {})
    if def.is_empty():
        return

    # 检查条件类型
    if def.has("target"):
        # 累计型成绩
        var current: int = _progress.get(achievement_id, 0) + increment
        _progress[achievement_id] = current

        if current >= def["target"]:
            unlock_achievement(achievement_id)
        else:
            achievement_progress.emit(achievement_id, current, def["target"])
    else:
        # 一次性成绩
        unlock_achievement(achievement_id)

func unlock_achievement(achievement_id: String) -> void:
    if _unlocked.has(achievement_id):
        return

    var def: Dictionary = _achievement_defs.get(achievement_id, {})
    var name: String = def.get("name", achievement_id)

    _unlocked[achievement_id] = {
        "timestamp": Time.get_datetime_string_from_system(),
        "name": name
    }

    _save_achievement_data()
    achievement_unlocked.emit(achievement_id, name)

    print("[Achievement] Unlocked: %s — %s" % [achievement_id, name])

    # Steam 同步（如果已集成）
    if SteamManager and SteamManager.is_initialized():
        SteamManager.set_achievement(achievement_id)

# === 事件回调 ===

func _on_explore_complete(success: bool) -> void:
    if success:
        _stats["explore_count"] += 1
        check_achievement("explore_first")
        check_achievement("explore_10")
        check_achievement("explore_50")

func _on_enemy_killed(enemy_type: String) -> void:
    _stats["kill_count"] += 1
    check_achievement("kill_first")
    check_achievement("kill_100")
    check_achievement("kill_500")

    if enemy_type == "boss" or enemy_type.contains("boss"):
        check_achievement("kill_boss")

func _on_facility_created(facility_type: String) -> void:
    _stats["build_count"] += 1
    check_achievement("build_first")
    check_achievement("build_10")
    check_achievement("build_50")

func _on_resource_collected(amount: int, resource_type: String) -> void:
    _stats["resource_total"] += amount
    check_achievement("resource_1000", amount)
    check_achievement("resource_10000", amount)

    if resource_type == "rare":
        _stats["rare_count"] += 1
        check_achievement("rare_pickup")
        check_achievement("rare_10")

func _on_day_completed(day_number: int) -> void:
    _stats["day_max"] = max(_stats["day_max"], day_number)

    if day_number >= 1:
        check_achievement("survive_day_1")
    if day_number >= 5:
        check_achievement("survive_day_5")
    if day_number >= 10:
        check_achievement("survive_day_10")
    if day_number >= 30:
        check_achievement("survive_day_30")

func _on_tutorial_complete() -> void:
    check_achievement("tutorial_complete")

func _on_wave_complete(enemies_remaining: int, hp_lost: int) -> void:
    if enemies_remaining == 0:
        check_achievement("kill_wave")
    if hp_lost == 0:
        check_achievement("no_damage_wave")

func _on_player_death() -> void:
    _stats["death_count"] += 1

func _on_retreat_success(hp: int, time: int) -> void:
    if hp < 10:
        check_achievement("low_hp_return")

# === 手动检查 ===

func check_turrets_active(count: int) -> void:
    if count >= 5:
        check_achievement("turret_master")

func check_night_retreat() -> void:
    check_achievement("explore_night")

func check_explore_duration(duration: float) -> void:
    if duration > 600:  # 10 分钟
        check_achievement("explore_full_day")

# === 公共 API ===

func is_unlocked(achievement_id: String) -> bool:
    return _unlocked.has(achievement_id)

func get_progress(achievement_id: String) -> Dictionary:
    var def: Dictionary = _achievement_defs.get(achievement_id, {})
    return {
        "current": _progress.get(achievement_id, 0),
        "target": def.get("target", 1)
    }

func get_all_unlocked() -> Dictionary:
    return _unlocked

func get_all_achievements() -> Dictionary:
    return _achievement_defs

func get_unlocked_count() -> int:
    return _unlocked.size()

func get_total_count() -> int:
    return _achievement_defs.size()

func get_category_achievements(category: String) -> Array:
    var result: Array = []
    for id in _achievement_defs:
        if _achievement_defs[id].get("category", "") == category:
            result.append(id)
    return result

func get_stats() -> Dictionary:
    return _stats

# === 重置 ===

func reset_all() -> void:
    _unlocked.clear()
    _progress.clear()
    _stats = {
        "explore_count": 0,
        "kill_count": 0,
        "build_count": 0,
        "resource_total": 0,
        "day_max": 0,
        "rare_count": 0,
        "death_count": 0
    }
    _save_achievement_data()

    print("[Achievement] All achievements reset")