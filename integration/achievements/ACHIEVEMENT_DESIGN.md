# Achievement System Design

**铁锈魔潮 (Rust Magic Tide)**

---

## 成就设计原则

1. **覆盖核心玩法**: 战斗、探索、建造、资源
2. **有意义的目标**: 成就代表里程碑，不是垃圾收集
3. **可见进度**: 长期成就显示进度条
4. **奖励有价值**: 解锁皮肤、称号、装饰

---

## 成绩分类

### 探索成就 (Exploration)

| ID | 成绩名 | 描述 | 条件 | 隐藏 |
|----|--------|------|------|------|
| `explore_first` | 初次探索 | 第一次离开地堡 | 完成首次探索 | 否 |
| `explore_10` | 熟悉地形 | 完成 10 次探索 | 10 次成功返回 | 否 |
| `explore_50` | 探索大师 | 完成 50 次探索 | 50 次成功返回 | 否 |
| `explore_night` | 夜行者 | 在夜晚返回地堡 | 夜晚时成功 Retreat | 否 |
| `explore_full_day` | 全天候 | 从早到晚连续探索 | 单次探索 > 10 分钟 | 否 |

### 战斗成就 (Combat)

| ID | 成绩名 | 描述 | 条件 | 隐藏 |
|----|--------|------|------|------|
| `kill_first` | 初次击杀 | 击杀第一个敌人 | 任何敌人死亡 | 否 |
| `kill_100` | 战斗新手 | 累计击杀 100 敌人 | 100 kills | 否 |
| `kill_500` | 战斗老兵 | 累计击杀 500 敌人 | 500 kills | 否 |
| `kill_boss` | Boss 猎人 | 击杀 Boss | Boss 死亡 | 否 |
| `kill_wave` | 波次清零 | 单波次零敌人剩余 | wave_end: enemies_remaining=0 | 否 |
| `no_damage_wave` | 完美防守 | 单波次战车零伤害 | wave_end: hp_lost=0 | 否 |

### 建造成就 (Building)

| ID | 成绩名 | 描述 | 条件 | 隐藏 |
|----|--------|------|------|------|
| `build_first` | 初次建造 | 建造第一个设施 | facility_build 事件 | 否 |
| `build_10` | 建筑工 | 建造 10 个设施 | 10 facilities | 否 |
| `build_50` | 建筑大师 | 建造 50 个设施 | 50 facilities | 否 |
| `turret_master` | 炮塔专家 | 同时激活 5 炮塔 | 5 turrets active | 否 |
| `all_facilities` | 设施全集 | 使用所有设施类型 | 每种至少建造 1 次 | 是 |

### 资源成就 (Resources)

| ID | 成绩名 | 描述 | 条件 | 隐藏 |
|----|--------|------|------|------|
| `resource_1000` | 收集者 | 累计收集 1000 单位资源 | total_resources >= 1000 | 否 |
| `resource_10000` | 资源大亨 | 紓计收集 10000 单位资源 | total_resources >= 10000 | 否 |
| `rare_pickup` | 稀有发现 | 拾取稀有物品 | pickup_rare 事件 | 否 |
| `rare_10` | 稀有猎人 | 拾取 10 个稀有物品 | 10 rare pickups | 否 |

### 生存成就 (Survival)

| ID | 成绩名 | 描述 | 条件 | 隐藏 |
|----|--------|------|------|------|
| `survive_day_1` | 第一天 | 完成第一天 | day_number >= 1 | 否 |
| `survive_day_5` | 五日生存 | 完成第五天 | day_number >= 5 | 否 |
| `survive_day_10` | 十日老兵 | 完成第十天 | day_number >= 10 | 否 |
| `survive_day_30` | 月度冠军 | 完成第三十天 | day_number >= 30 | 是 |
| `low_hp_return` | 险境逃生 | HP<10 时成功返回 | retreat: hp<10 | 否 |

### 特殊成就 (Special)

| ID | 成绩名 | 描述 | 条件 | 隐藏 |
|----|--------|------|------|------|
| `tutorial_complete` | 教程完成 | 完成新手教程 | tutorial 所有步骤完成 | 否 |
| `skip_tutorial` | 自学者 | 跳过教程完成第一天 | skip_tutorial + day_1 | 是 |
| `death_10` | 持之以恒 | 死亡 10 次后继续游戏 | death_count >= 10 + 继续游戏 | 是 |
| `perfect_day` | 完美一天 | 单天: 零死亡、零失败、收集>500 | 特定组合条件 | 是 |

---

## Implementation

### AchievementManager

```gdscript
# src/achievement/achievement_manager.gd
class_name AchievementManager extends Node

# === 配置 ===
const ACHIEVEMENT_FILE: String = "user://achievements.json"

# === 成绩定义 ===
var _achievement_defs: Dictionary = {}

# === 状态 ===
var _unlocked: Dictionary = {}
var _progress: Dictionary = {}

signal achievement_unlocked(achievement_id: String, achievement_name: String)
signal achievement_progress(achievement_id: String, current: int, target: int)

func _ready() -> void:
    _load_achievement_defs()
    _load_achievement_data()
    _setup_event_listeners()

# === 定义加载 ===

func _load_achievement_defs() -> void:
    # 成绩定义可从 JSON 文件加载或硬编码
    _achievement_defs = {
        # Exploration
        "explore_first": {"name": "初次探索", "desc": "第一次离开地堡", "category": "exploration", "hidden": false},
        "explore_10": {"name": "熟悉地形", "desc": "完成 10 次探索", "category": "exploration", "target": 10, "hidden": false},
        "explore_50": {"name": "探索大师", "desc": "完成 50 次探索", "category": "exploration", "target": 50, "hidden": false},
        "explore_night": {"name": "夜行者", "desc": "在夜晚返回地堡", "category": "exploration", "hidden": false},
        
        # Combat
        "kill_first": {"name": "初次击杀", "desc": "击杀第一个敌人", "category": "combat", "hidden": false},
        "kill_100": {"name": "战斗新手", "desc": "累计击杀 100 敌人", "category": "combat", "target": 100, "hidden": false},
        "kill_500": {"name": "战斗老兵", "desc": "累计击杀 500 敌人", "category": "combat", "target": 500, "hidden": false},
        "kill_boss": {"name": "Boss 猎人", "desc": "击杀 Boss", "category": "combat", "hidden": false},
        "no_damage_wave": {"name": "完美防守", "desc": "单波次战车零伤害", "category": "combat", "hidden": false},
        
        # Building
        "build_first": {"name": "初次建造", "desc": "建造第一个设施", "category": "building", "hidden": false},
        "build_10": {"name": "建筑工", "desc": "建造 10 个设施", "category": "building", "target": 10, "hidden": false},
        "build_50": {"name": "建筑大师", "desc": "建造 50 个设施", "category": "building", "target": 50, "hidden": false},
        
        # Resources
        "resource_1000": {"name": "收集者", "desc": "累计收集 1000 单位资源", "category": "resources", "target": 1000, "hidden": false},
        "resource_10000": {"name": "资源大亨", "desc": "累计收集 10000 单位资源", "category": "resources", "target": 10000, "hidden": false},
        
        # Survival
        "survive_day_1": {"name": "第一天", "desc": "完成第一天", "category": "survival", "hidden": false},
        "survive_day_5": {"name": "五日生存", "desc": "完成第五天", "category": "survival", "hidden": false},
        "survive_day_10": {"name": "十日老兵", "desc": "完成第十天", "category": "survival", "hidden": false},
        
        # Special
        "tutorial_complete": {"name": "教程完成", "desc": "完成新手教程", "category": "special", "hidden": false},
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

func _save_achievement_data() -> void:
    var file: FileAccess = FileAccess.open(ACHIEVEMENT_FILE, FileAccess.WRITE)
    if file == null:
        return
    
    var data: Dictionary = {
        "unlocked": _unlocked,
        "progress": _progress
    }
    
    file.store_string(JSON.stringify(data))
    file.close()

# === 事件监听 ===

func _setup_event_listeners() -> void:
    # 监听游戏事件
    GlobalSignals.explore_completed.connect(_on_explore_complete)
    GlobalSignals.enemy_killed.connect(_on_enemy_killed)
    GlobalSignals.facility_created.connect(_on_facility_created)
    GlobalSignals.resource_collected.connect(_on_resource_collected)
    GlobalSignals.day_completed.connect(_on_day_completed)
    GlobalSignals.tutorial_completed.connect(_on_tutorial_complete)
    GlobalSignals.wave_completed.connect(_on_wave_complete)

# === 解锁检查 ===

func check_achievement(achievement_id: String, value: Variant = null) -> void:
    if _unlocked.has(achievement_id):
        return  # 已解锁
    
    var def: Dictionary = _achievement_defs.get(achievement_id, {})
    if def.is_empty():
        return
    
    # 检查条件类型
    if def.has("target"):
        # 累计型成绩
        var current: int = _progress.get(achievement_id, 0)
        if value != null:
            current += int(value)
        
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
    
    print("[Achievement] Unlocked: %s" % name)
    
    # Steam 成绩同步（如果已集成）
    if SteamManager.is_initialized():
        _sync_to_steam(achievement_id)

# === 事件回调 ===

func _on_explore_complete(success: bool) -> void:
    if success:
        check_achievement("explore_first")
        check_achievement("explore_10", 1)
        check_achievement("explore_50", 1)

func _on_enemy_killed(enemy_type: String) -> void:
    check_achievement("kill_first")
    check_achievement("kill_100", 1)
    check_achievement("kill_500", 1)
    
    if enemy_type == "boss":
        check_achievement("kill_boss")

func _on_facility_created(facility_type: String) -> void:
    check_achievement("build_first")
    check_achievement("build_10", 1)
    check_achievement("build_50", 1)

func _on_resource_collected(amount: int) -> void:
    check_achievement("resource_1000", amount)
    check_achievement("resource_10000", amount)

func _on_day_completed(day_number: int) -> void:
    if day_number >= 1:
        check_achievement("survive_day_1")
    if day_number >= 5:
        check_achievement("survive_day_5")
    if day_number >= 10:
        check_achievement("survive_day_10")

func _on_tutorial_complete() -> void:
    check_achievement("tutorial_complete")

func _on_wave_complete(enemies_remaining: int, hp_lost: int) -> void:
    if enemies_remaining == 0:
        check_achievement("kill_wave")
    if hp_lost == 0:
        check_achievement("no_damage_wave")

# === Steam 同步 ===

func _sync_to_steam(achievement_id: String) -> void:
    # GodotSteam API 调用
    # Steam.set_achievement(achievement_id)
    pass

# === 公共 API ===

func is_unlocked(achievement_id: String) -> bool:
    return _unlocked.has(achievement_id)

func get_progress(achievement_id: String) -> Dictionary:
    return {
        "current": _progress.get(achievement_id, 0),
        "target": _achievement_defs.get(achievement_id, {}).get("target", 1)
    }

func get_all_unlocked() -> Dictionary:
    return _unlocked

func get_all_achievements() -> Dictionary:
    return _achievement_defs

func get_unlocked_count() -> int:
    return _unlocked.size()

func get_total_count() -> int:
    return _achievement_defs.size()
```

---

## 成就 UI

### 成就列表界面

```
┌─────────────────────────────────────────────────────────────┐
│ 成绩                                      [已解锁: 12/25]   │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🏆 初次探索                          ✓ 已解锁           │ │
│ │    第一次离开地堡                                        │ │
│ │    解锁于: 2026-04-25                                    │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ⭐ 熟悉地形                          进度: 3/10         │ │
│ │    完成 10 次探索                                        │ │
│ │    ████████░░░░░░░░░░░░ 30%                              │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🔒 ???                               [隐藏]              │ │
│ │    继续探索来解锁这个成就                                 │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### 解锁通知

```
┌─────────────────────────────────────┐
│ 🏆 成绩解锁!                         │
│                                      │
│ 探索大师                             │
│ 完成 50 次探索                        │
│                                      │
│          [关闭]                       │
└─────────────────────────────────────┘
```

---

## Steam 成绩配置

在 Steamworks Dashboard 配置成绩：

| 步骤 | 操作 |
|------|------|
| 1 | 进入 Stats & Achievements |
| 2 | 创建每个成绩 (ID、名称、描述、图标) |
| 3 | 上传成绩图标 (64x64 PNG) |
| 4 | 设置显示属性 (隐藏/显示) |
| 5 | 发布配置 |

---

## 文件清单

| 文件 | 路径 |
|------|------|
| AchievementManager | `src/achievement/achievement_manager.gd` |
| 成绩定义数据 | `assets/data/achievements.json` (可选) |
| 成绩 UI | `src/ui/achievement_screen.tscn` |

---

## Autoload 注册

```ini
[autoload]

AchievementManager="*res://src/achievement/achievement_manager.gd"
```

---

## 依赖

- 需要 `SteamManager` (Steam SDK 集成后)
- 需要 `GlobalSignals` (事件总线)
- 需要 `UUID` (生成唯一 ID)

---

*Achievement System Design — 铁锈魔潮*