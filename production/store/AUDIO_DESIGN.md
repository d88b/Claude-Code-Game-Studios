# Audio Assets Design

**铁锈魔潮 (Rust Magic Tide)**

---

## 音效分类

### 1. 战车音效 (Vehicle)

| 音效 | 文件名 | 说明 |
|------|--------|------|
| **引擎启动** | `vehicle_engine_start.wav` | 0.5s，战车启动 |
| **引擎循环** | `vehicle_engine_loop.wav` | 循环，驾驶中 |
| **引擎停止** | `vehicle_engine_stop.wav` | 0.3s，停止 |
| **炮塔旋转** | `turret_rotate.wav` | 短促，瞄准 |
| **射击** | `weapon_fire.wav` | 主武器射击 |
| **弹药空** | `weapon_empty.wav` | 无弹药点击 |

### 2. 挖掘音效 (Digging)

| 音效 | 文件名 | 说明 |
|------|--------|------|
| **挖掘开始** | `dig_start.wav` | 按E键 |
| **挖掘循环** | `dig_loop.wav` | 持续挖掘 |
| **挖掘完成** | `dig_complete.wav` | 方块破坏 |
| **挖掘失败** | `dig_fail.wav` | 无法挖掘 |

### 3. 放置音效 (Placement)

| 音效 | 文件名 | 说明 |
|------|--------|------|
| **放置成功** | `place_success.wav` | 设施放置 |
| **放置失败** | `place_fail.wav` | 无法放置 |
| **设施激活** | `facility_activate.wav` | 设施启动 |
| **设施销毁** | `facility_destroy.wav` | 设施被毁 |

### 4. 敌人音效 (Enemies)

| 音效 | 文件名 | 说明 |
|------|--------|------|
| **僵尸行走** | `zombie_walk.wav` | 循环，移动 |
| **僵尸攻击** | `zombie_attack.wav` | 攻击 |
| **僵尸死亡** | `zombie_death.wav` | 死亡 |
| **Boss 出场** | `boss_spawn.wav` | Boss 登场 |
| **Boss 技能** | `boss_skill.wav` | 特殊攻击 |

### 5. 资源音效 (Resources)

| 音效 | 文件名 | 说明 |
|------|--------|------|
| **掉落** | `drop_spawn.wav` | 物品掉落 |
| **拾取** | `pickup_generic.wav` | 通用拾取 |
| **水晶** | `pickup_crystal.wav` | 水晶拾取 |
| **金属** | `pickup_metal.wav` | 金属拾取 |
| **有机物** | `pickup_organic.wav` | 有机物拾取 |
| **燃料** | `pickup_fuel.wav` | 燃料拾取 |
| **稀有** | `pickup_rare.wav` | 稀有物品 |

### 6. UI 音效 (UI)

| 音效 | 文件名 | 说明 |
|------|--------|------|
| **按钮点击** | `ui_click.wav` | 菜单交互 |
| **按钮悬停** | `ui_hover.wav` | 鼠标悬停 |
| **菜单打开** | `menu_open.wav` | 打开菜单 |
| **菜单关闭** | `menu_close.wav` | 关闭菜单 |
| **确认** | `ui_confirm.wav` | 确认操作 |
| **取消** | `ui_cancel.wav` | 取消操作 |
| **警告** | `ui_warning.wav` | 警告提示 |
| **成功** | `ui_success.wav` | 操作成功 |

### 7. 游戏状态音效 (Game State)

| 音效 | 文件名 | 说明 |
|------|--------|------|
| **日夜切换** | `daynight_transition.wav` | 昼夜切换 |
| **夜晚警告** | `night_warning.wav` | 夜晚来临 |
| **返回地堡** | `retreat_start.wav` | Retreat 激活 |
| **返回完成** | `retreat_complete.wav` | 安全返回 |
| **HP 低警告** | `health_low.wav` | HP < 20% |
| **MP 低警告** | `magic_low.wav` | MP < 20% |
| **游戏胜利** | `game_victory.wav` | 成功防守 |
| **游戏失败** | `game_defeat.wav` | 战车被毁 |

---

## 背景音乐 (BGM)

| 音乐 | 文件名 | 使用场景 |
|------|--------|----------|
| **主菜单** | `bgm_menu.wav` | 菜单界面 |
| **日间探索** | `bgm_day.wav` | 白天探索 |
| **夜间防守** | `bgm_night.wav` | 夜晚防守 |
| **Boss 战斗** | `bgm_boss.wav` | Boss 战 |
| **地堡休整** | `bgm_bunker.wav` | 地堡内 |
| **胜利** | `bgm_victory.wav` | 结算胜利 |
| **失败** | `bgm_defeat.wav` | 结算失败 |

---

## 音效规格

### 格式

| 属性 | 规格 |
|------|------|
| **格式** | WAV ( uncompressed ) |
| **采样率** | 44100 Hz |
| **位深** | 16-bit |
| **声道** | 单声道（音效） / 立体声（BGM） |
| **大小限制** | 音效 < 100KB，BGM < 5MB |

### 风格

- **整体风格**: 工业 + 魔幻融合
- **战车**: 机械感，金属碰撞
- **魔法**: 低沉神秘，能量波动
- **僵尸**: 沙哑，腐烂感
- **UI**: 清脆，不刺耳

---

## Implementation

### AudioManager

```gdscript
# src/audio/audio_manager.gd
class_name AudioManager extends Node

# === 配置 ===
const MASTER_VOLUME_KEY: String = "audio/master_volume"
const BGM_VOLUME_KEY: String = "audio/bgm_volume"
const SFX_VOLUME_KEY: String = "audio/sfx_volume"

# === 音效路径 ===
const SFX_PATH: String = "res://assets/audio/sfx/"
const BGM_PATH: String = "res://assets/audio/bgm/"

# === 节点 ===
var _bgm_player: AudioStreamPlayer = null
var _sfx_players: Array[AudioStreamPlayer] = []

# === 状态 ===
var _current_bgm: String = ""
var _sfx_pool_size: int = 8

signal bgm_changed(track_name: String)

func _ready() -> void:
    # 创建 BGM 播放器
    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = "BGM"
    add_child(_bgm_player)
    
    # 创建 SFX 播放器池
    for i in _sfx_pool_size:
        var player: AudioStreamPlayer = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        _sfx_players.append(player)
    
    # 加载音量设置
    _load_volume_settings()

# === BGM ===

func play_bgm(track_name: String) -> void:
    if track_name == _current_bgm:
        return
    
    var path: String = BGM_PATH + track_name + ".wav"
    var stream: AudioStream = load(path)
    
    if stream == null:
        push_error("[AudioManager] BGM not found: %s" % track_name)
        return
    
    _bgm_player.stream = stream
    _bgm_player.play()
    _current_bgm = track_name
    bgm_changed.emit(track_name)

func stop_bgm() -> void:
    _bgm_player.stop()
    _current_bgm = ""

func pause_bgm() -> void:
    _bgm_player.stream_paused = true

func resume_bgm() -> void:
    _bgm_player.stream_paused = false

# === SFX ===

func play_sfx(sfx_name: String, volume: float = 1.0) -> void:
    var path: String = SFX_PATH + sfx_name + ".wav"
    var stream: AudioStream = load(path)
    
    if stream == null:
        push_warning("[AudioManager] SFX not found: %s" % sfx_name)
        return
    
    # 从池中获取空闲播放器
    for player in _sfx_players:
        if not player.playing:
            player.stream = stream
            player.volume_db = _linear_to_db(volume)
            player.play()
            return
    
    # 池满，使用第一个（覆盖）
    _sfx_players[0].stream = stream
    _sfx_players[0].volume_db = _linear_to_db(volume)
    _sfx_players[0].play()

# === 音量控制 ===

func set_master_volume(volume: float) -> void:
    AudioServer.set_bus_volume_db(0, _linear_to_db(volume))
    _save_setting(MASTER_VOLUME_KEY, volume)

func set_bgm_volume(volume: float) -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), _linear_to_db(volume))
    _save_setting(BGM_VOLUME_KEY, volume)

func set_sfx_volume(volume: float) -> void:
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), _linear_to_db(volume))
    _save_setting(SFX_VOLUME_KEY, volume)

func get_master_volume() -> float:
    return _db_to_linear(AudioServer.get_bus_volume_db(0))

func get_bgm_volume() -> float:
    return _db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM")))

func get_sfx_volume() -> float:
    return _db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))

# === 辅助 ===

func _linear_to_db(volume: float) -> float:
    return linear_to_db(clampf(volume, 0.0, 1.0))

func _db_to_linear(db: float) -> float:
    return db_to_linear(db)

func _save_setting(key: String, value: float) -> void:
    ConfigFile.set_value(key, value)

func _load_volume_settings() -> void:
    var master: float = ConfigFile.get_value(MASTER_VOLUME_KEY, 1.0)
    var bgm: float = ConfigFile.get_value(BGM_VOLUME_KEY, 0.8)
    var sfx: float = ConfigFile.get_value(SFX_VOLUME_KEY, 1.0)
    
    set_master_volume(master)
    set_bgm_volume(bgm)
    set_sfx_volume(sfx)
```

---

## Audio Bus 配置

在 `project.godot` 中配置 Audio Bus:

```ini
[audio]

bus/0/name="Master"
bus/0/solo=false
bus/0/mute=false
bus/0/volume_db=0

bus/1/name="BGM"
bus/1/solo=false
bus/1/mute=false
bus/1/volume_db=-2
bus/1/send="Master"

bus/2/name="SFX"
bus/2/solo=false
bus/2/mute=false
bus/2/volume_db=0
bus/2/send="Master"
```

---

## Autoload 注册

在 `project.godot` 添加:

```ini
[autoload]

AudioManager="*res://src/audio/audio_manager.gd"
```

---

## 音效触发时机

| 触发点 | 音效 | 调用代码位置 |
|--------|------|-------------|
| 战车移动 | `vehicle_engine_loop` | VehicleMovementLoop |
| 武器射击 | `weapon_fire` | WeaponFiringSystem |
| 挖掘方块 | `dig_start/loop/complete` | DiggingController |
| 放置设施 | `place_success` | PlacementValidator |
| 敌人死亡 | `zombie_death` | EnemyAIStateMachine |
| 资源拾取 | `pickup_*` | ResourceDropEntity |
| 日夜切换 | `daynight_transition` | DayNightPhaseManager |
| 返回地堡 | `retreat_start/complete` | RetreatThresholdDetection |
| HP/MP 低 | `health_low/magic_low` | VehicleAttributeState |
| 菜单交互 | `ui_click/hover` | UIScreenController |

---

## 文件清单

| 文件 | 路径 |
|------|------|
| AudioManager | `src/audio/audio_manager.gd` |
| 音效文件 | `assets/audio/sfx/*.wav` |
| BGM 文件 | `assets/audio/bgm/*.wav` |
| Audio Bus 配置 | `project.godot` |

---

## 优先级

| 分类 | 数量 | 必需性 |
|------|------|--------|
| **战车音效** | 6 | Must Have |
| **敌人音效** | 5 | Must Have |
| **UI 音效** | 8 | Should Have |
| **资源音效** | 7 | Should Have |
| **挖掘音效** | 4 | Should Have |
| **放置音效** | 4 | Should Have |
| **游戏状态** | 8 | Should Have |
| **BGM** | 7 | Nice to Have |

---

*Audio Assets Design — 铁锈魔潮*