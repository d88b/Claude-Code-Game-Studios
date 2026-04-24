# AudioManager — 音频管理器
# 负责背景音乐和音效播放，音量控制，Audio Bus 管理
# Design: production/store/AUDIO_DESIGN.md

class_name AudioManager extends Node

# === 配置 ===
const MASTER_VOLUME_KEY: String = "audio/master_volume"
const BGM_VOLUME_KEY: String = "audio/bgm_volume"
const SFX_VOLUME_KEY: String = "audio/sfx_volume"

# 音效路径
const SFX_PATH: String = "res://assets/audio/sfx/"
const BGM_PATH: String = "res://assets/audio/bgm/"

# === 信号 ===
signal bgm_changed(track_name: String)
signal sfx_played(sfx_name: String)

# === 节点 ===
var _bgm_player: AudioStreamPlayer = null
var _sfx_players: Array = []  # 音效播放器池
var _ambient_player: AudioStreamPlayer = null

# === 状态 ===
var _current_bgm: String = ""
var _sfx_pool_size: int = 8
var _sfx_enabled: bool = true
var _bgm_enabled: bool = true

func _ready() -> void:
    # 创建 Audio Bus（如果未配置）
    _ensure_audio_buses()

    # 创建 BGM 播放器
    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.bus = "BGM"
    add_child(_bgm_player)

    # 创建环境音播放器
    _ambient_player = AudioStreamPlayer.new()
    _ambient_player.bus = "SFX"
    add_child(_ambient_player)

    # 创建 SFX 播放器池
    for i in _sfx_pool_size:
        var player: AudioStreamPlayer = AudioStreamPlayer.new()
        player.bus = "SFX"
        add_child(player)
        _sfx_players.append(player)

    # 加载音量设置
    _load_volume_settings()

    print("[AudioManager] Initialized with %d SFX players" % _sfx_pool_size)

# === Audio Bus 配置 ===

func _ensure_audio_buses() -> void:
    # 确保 BGM 和 SFX Bus 存在
    var master_idx: int = AudioServer.get_bus_index("Master")
    if master_idx < 0:
        AudioServer.add_bus()
        AudioServer.set_bus_name(0, "Master")

    var bgm_idx: int = AudioServer.get_bus_index("BGM")
    if bgm_idx < 0:
        AudioServer.add_bus(AudioServer.get_bus_count())
        bgm_idx = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(bgm_idx, "BGM")
        AudioServer.set_bus_send(bgm_idx, "Master")

    var sfx_idx: int = AudioServer.get_bus_index("SFX")
    if sfx_idx < 0:
        AudioServer.add_bus(AudioServer.get_bus_count())
        sfx_idx = AudioServer.get_bus_count() - 1
        AudioServer.set_bus_name(sfx_idx, "SFX")
        AudioServer.set_bus_send(sfx_idx, "Master")

# === BGM 控制 ===

func play_bgm(track_name: String, fade_duration: float = 0.5) -> void:
    if track_name == _current_bgm and _bgm_player.playing:
        return

    if not _bgm_enabled:
        return

    var path: String = BGM_PATH + track_name + ".wav"

    # 检查文件是否存在
    if not ResourceLoader.exists(path):
        push_warning("[AudioManager] BGM not found: %s" % track_name)
        return

    var stream: AudioStream = load(path)
    if stream == null:
        push_warning("[AudioManager] Failed to load BGM: %s" % track_name)
        return

    # 淡出当前音乐
    if _bgm_player.playing and fade_duration > 0:
        _fade_out_bgm(fade_duration)
        await get_tree().create_timer(fade_duration).timeout

    _bgm_player.stream = stream
    _bgm_player.volume_db = 0
    _bgm_player.play()
    _current_bgm = track_name
    bgm_changed.emit(track_name)

    print("[AudioManager] BGM started: %s" % track_name)

func stop_bgm(fade_duration: float = 0.5) -> void:
    if fade_duration > 0 and _bgm_player.playing:
        _fade_out_bgm(fade_duration)
        await get_tree().create_timer(fade_duration).timeout

    _bgm_player.stop()
    _current_bgm = ""

func pause_bgm() -> void:
    _bgm_player.stream_paused = true

func resume_bgm() -> void:
    _bgm_player.stream_paused = false

func _fade_out_bgm(duration: float) -> void:
    var tween: Tween = create_tween()
    tween.tween_property(_bgm_player, "volume_db", -40, duration)

func _fade_in_bgm(duration: float) -> void:
    _bgm_player.volume_db = -40
    var tween: Tween = create_tween()
    tween.tween_property(_bgm_player, "volume_db", 0, duration)

# === SFX 控制 ===

func play_sfx(sfx_name: String, volume: float = 1.0, pitch_scale: float = 1.0) -> void:
    if not _sfx_enabled:
        return

    var path: String = SFX_PATH + sfx_name + ".wav"

    # 检查文件是否存在
    if not ResourceLoader.exists(path):
        push_warning("[AudioManager] SFX not found: %s" % sfx_name)
        return

    var stream: AudioStream = load(path)
    if stream == null:
        push_warning("[AudioManager] Failed to load SFX: %s" % sfx_name)
        return

    # 从池中获取空闲播放器
    var player: AudioStreamPlayer = _get_available_sfx_player()

    player.stream = stream
    player.volume_db = _linear_to_db(volume)
    player.pitch_scale = pitch_scale
    player.play()

    sfx_played.emit(sfx_name)

func play_sfx_at_position(sfx_name: String, position: Vector2, volume: float = 1.0) -> void:
    # 带位置信息的音效（用于 2D 空间音效）
    # 根据玩家位置调整音量和声像
    # 当前简化实现，直接播放
    play_sfx(sfx_name, volume)

func play_ambient(ambient_name: String, volume: float = 0.5) -> void:
    if not _sfx_enabled:
        return

    var path: String = SFX_PATH + ambient_name + ".wav"

    if not ResourceLoader.exists(path):
        push_warning("[AudioManager] Ambient not found: %s" % ambient_name)
        return

    var stream: AudioStream = load(path)
    _ambient_player.stream = stream
    _ambient_player.volume_db = _linear_to_db(volume)
    _ambient_player.play()

func stop_ambient() -> void:
    _ambient_player.stop()

func _get_available_sfx_player() -> AudioStreamPlayer:
    # 查找空闲播放器
    for player in _sfx_players:
        if not player.playing:
            return player

    # 池满，使用第一个（覆盖最旧的）
    return _sfx_players[0]

# === 音量控制 ===

func set_master_volume(volume: float) -> void:
    # volume: 0.0 - 1.0
    var db: float = _linear_to_db(volume)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
    _save_setting(MASTER_VOLUME_KEY, volume)

func set_bgm_volume(volume: float) -> void:
    var db: float = _linear_to_db(volume)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), db)
    _save_setting(BGM_VOLUME_KEY, volume)

func set_sfx_volume(volume: float) -> void:
    var db: float = _linear_to_db(volume)
    AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), db)
    _save_setting(SFX_VOLUME_KEY, volume)

func get_master_volume() -> float:
    return _db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("Master")))

func get_bgm_volume() -> float:
    return _db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM")))

func get_sfx_volume() -> float:
    return _db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))

# === 开关控制 ===

func set_bgm_enabled(enabled: bool) -> void:
    _bgm_enabled = enabled
    if not enabled and _bgm_player.playing:
        _bgm_player.stop()

func set_sfx_enabled(enabled: bool) -> void:
    _sfx_enabled = enabled
    if not enabled:
        # 停止所有音效
        for player in _sfx_players:
            if player.playing:
                player.stop()
        _ambient_player.stop()

func is_bgm_enabled() -> bool:
    return _bgm_enabled

func is_sfx_enabled() -> bool:
    return _sfx_enabled

# === 辅助函数 ===

func _linear_to_db(volume: float) -> float:
    # 将线性音量转换为 dB
    # volume=1.0 -> 0 dB, volume=0.0 -> -80 dB
    return linear_to_db(clampf(volume, 0.0001, 1.0))

func _db_to_linear(db: float) -> float:
    return db_to_linear(db)

# === 设置存储 ===

func _save_setting(key: String, value: float) -> void:
    # 使用 SaveManager 或 ConfigFile 存储
    if SaveManager and SaveManager.has_method("set_setting"):
        SaveManager.set_setting(key, value)
    else:
        # 直接写入文件
        var config: Dictionary = _load_config()
        config[key] = value
        _save_config(config)

func _load_volume_settings() -> void:
    var master: float = 1.0
    var bgm: float = 0.8
    var sfx: float = 1.0

    var config: Dictionary = _load_config()

    if config.has(MASTER_VOLUME_KEY):
        master = config[MASTER_VOLUME_KEY]
    if config.has(BGM_VOLUME_KEY):
        bgm = config[BGM_VOLUME_KEY]
    if config.has(SFX_VOLUME_KEY):
        sfx = config[SFX_VOLUME_KEY]

    set_master_volume(master)
    set_bgm_volume(bgm)
    set_sfx_volume(sfx)

func _load_config() -> Dictionary:
    const CONFIG_FILE: String = "user://audio_settings.json"

    if not FileAccess.file_exists(CONFIG_FILE):
        return {}

    var file: FileAccess = FileAccess.open(CONFIG_FILE, FileAccess.READ)
    if file == null:
        return {}

    var content: String = file.get_as_text()
    file.close()

    var json: JSON = JSON.new()
    if json.parse(content) == OK:
        return json.data

    return {}

func _save_config(config: Dictionary) -> void:
    const CONFIG_FILE: String = "user://audio_settings.json"

    var file: FileAccess = FileAccess.open(CONFIG_FILE, FileAccess.WRITE)
    if file == null:
        return

    file.store_string(JSON.stringify(config))
    file.close()

# === 公共 API ===

func get_current_bgm() -> String:
    return _current_bgm

func is_bgm_playing() -> bool:
    return _bgm_player.playing and not _bgm_player.stream_paused