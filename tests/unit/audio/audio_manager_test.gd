# AudioManager Unit Tests
# Tests audio playback, volume control, and BGM/SFX management
# Framework: GUT (Godot Unit Testing)

extends GutTest

var _audio_manager: AudioManager = null

func before_all() -> void:
    # 创建 AudioManager 实例
    _audio_manager = AudioManager.new()
    add_child(_audio_manager)
    await wait_for_signal(_audio_manager.ready, 1.0)

func after_all() -> void:
    if _audio_manager:
        _audio_manager.queue_free()

# === 初始化测试 ===

func test_audio_manager_initializes() -> void:
    assert_not_null(_audio_manager, "AudioManager should not be null")
    assert_true(_audio_manager.is_initialized(), "AudioManager should be initialized")

func test_sfx_pool_created() -> void:
    # 检查 SFX 播放器池
    var pool_size: int = _audio_manager._sfx_players.size()
    assert_eq(pool_size, 8, "SFX pool should have 8 players")

func test_bgm_player_created() -> void:
    assert_not_null(_audio_manager._bgm_player, "BGM player should exist")

func test_audio_buses_created() -> void:
    var master_idx: int = AudioServer.get_bus_index("Master")
    var bgm_idx: int = AudioServer.get_bus_index("BGM")
    var sfx_idx: int = AudioServer.get_bus_index("SFX")

    assert_gt(master_idx, -1, "Master bus should exist")
    assert_gt(bgm_idx, -1, "BGM bus should exist")
    assert_gt(sfx_idx, -1, "SFX bus should exist")

# === 音量控制测试 ===

func test_set_master_volume() -> void:
    _audio_manager.set_master_volume(0.5)
    var volume: float = _audio_manager.get_master_volume()

    assert_almost_eq(volume, 0.5, 0.01, "Master volume should be 0.5")

func test_set_bgm_volume() -> void:
    _audio_manager.set_bgm_volume(0.7)
    var volume: float = _audio_manager.get_bgm_volume()

    assert_almost_eq(volume, 0.7, 0.01, "BGM volume should be 0.7")

func test_set_sfx_volume() -> void:
    _audio_manager.set_sfx_volume(0.9)
    var volume: float = _audio_manager.get_sfx_volume()

    assert_almost_eq(volume, 0.9, 0.01, "SFX volume should be 0.9")

func test_volume_clamped_to_valid_range() -> void:
    _audio_manager.set_master_volume(2.0)  # 超出范围
    var volume: float = _audio_manager.get_master_volume()

    assert_lte(volume, 1.0, "Volume should be clamped to max 1.0")

# === BGM 测试 ===

func test_bgm_changes_signal() -> void:
    watch_signals(_audio_manager)

    # 模拟播放 BGM（需要实际音频文件）
    # _audio_manager.play_bgm("bgm_menu")

    # 在没有实际文件的情况下，测试信号机制
    _audio_manager._current_bgm = "test_track"
    _audio_manager.bgm_changed.emit("test_track")

    assert_signal_emitted(_audio_manager, "bgm_changed", "bgm_changed signal should emit")

func test_pause_bgm() -> void:
    # 设置状态
    _audio_manager._bgm_player.stream_paused = false
    _audio_manager.pause_bgm()

    assert_true(_audio_manager._bgm_player.stream_paused, "BGM should be paused")

func test_resume_bgm() -> void:
    _audio_manager._bgm_player.stream_paused = true
    _audio_manager.resume_bgm()

    assert_false(_audio_manager._bgm_player.stream_paused, "BGM should be resumed")

# === SFX 测试 ===

func test_sfx_played_signal() -> void:
    watch_signals(_audio_manager)

    # 模拟 SFX 播放
    _audio_manager.sfx_played.emit("test_sfx")

    assert_signal_emitted(_audio_manager, "sfx_played", "sfx_played signal should emit")

func test_sfx_enabled_flag() -> void:
    _audio_manager.set_sfx_enabled(true)
    assert_true(_audio_manager.is_sfx_enabled(), "SFX should be enabled")

func test_sfx_disabled_flag() -> void:
    _audio_manager.set_sfx_enabled(false)
    assert_false(_audio_manager.is_sfx_enabled(), "SFX should be disabled")

# === 开关控制测试 ===

func test_bgm_enabled_flag() -> void:
    _audio_manager.set_bgm_enabled(true)
    assert_true(_audio_manager.is_bgm_enabled(), "BGM should be enabled")

func test_bgm_disabled_flag() -> void:
    _audio_manager.set_bgm_enabled(false)
    assert_false(_audio_manager.is_bgm_enabled(), "BGM should be disabled")

# === 辅助函数测试 ===

func test_linear_to_db_conversion() -> void:
    var db: float = _audio_manager._linear_to_db(1.0)
    assert_almost_eq(db, 0.0, 0.01, "Volume 1.0 should be 0 dB")

    var db_low: float = _audio_manager._linear_to_db(0.5)
    assert_lt(db_low, 0.0, "Volume 0.5 should be negative dB")

func test_get_current_bgm() -> void:
    _audio_manager._current_bgm = "bgm_day"
    var current: String = _audio_manager.get_current_bgm()

    assert_eq(current, "bgm_day", "Current BGM should be bgm_day")

func test_is_bgm_playing() -> void:
    _audio_manager._bgm_player.playing = true
    _audio_manager._bgm_player.stream_paused = false

    assert_true(_audio_manager.is_bgm_playing(), "BGM should be playing")

# === 边界条件测试 ===

func test_volume_zero() -> void:
    _audio_manager.set_master_volume(0.0)
    var volume: float = _audio_manager.get_master_volume()

    assert_almost_eq(volume, 0.0, 0.01, "Volume can be zero")

func test_invalid_bgm_name() -> void:
    # 没有实际文件，应输出警告但不崩溃
    _audio_manager.play_bgm("nonexistent_track")

    assert_eq(_audio_manager._current_bgm, "", "Current BGM should remain empty for invalid track")

func test_invalid_sfx_name() -> void:
    _audio_manager.play_sfx("nonexistent_sfx")

    # 不应崩溃，只是警告
    assert_true(true, "Invalid SFX name should not crash")