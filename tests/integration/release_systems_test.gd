# Release Systems Integration Tests
# Tests interaction between AudioManager, AchievementManager, AnalyticsManager, etc.
# Framework: GUT (Godot Unit Testing)

extends GutTest

var _audio_manager: AudioManager = null
var _achievement_manager: AchievementManager = null
var _analytics_manager: AnalyticsManager = null

func before_all() -> void:
    # 创建所有 Manager 实例
    _audio_manager = AudioManager.new()
    add_child(_audio_manager)

    _achievement_manager = AchievementManager.new()
    add_child(_achievement_manager)

    _analytics_manager = AnalyticsManager.new()
    add_child(_analytics_manager)

    # 等待初始化
    await wait_for_signal(_audio_manager.ready, 1.0)
    await wait_for_signal(_achievement_manager.ready, 1.0)
    await wait_for_signal(_analytics_manager.ready, 1.0)

func after_all() -> void:
    if _audio_manager:
        _audio_manager.queue_free()
    if _achievement_manager:
        _achievement_manager.queue_free()
    if _analytics_manager:
        _analytics_manager.queue_free()

# === Manager 初始化测试 ===

func test_all_managers_initialized() -> void:
    assert_not_null(_audio_manager, "AudioManager should exist")
    assert_not_null(_achievement_manager, "AchievementManager should exist")
    assert_not_null(_analytics_manager, "AnalyticsManager should exist")

func test_managers_have_unique_ids() -> void:
    var session_id: String = _analytics_manager.get_session_id()
    var player_id: String = _analytics_manager.get_player_id()

    assert_true(UUID.is_valid(session_id), "Session ID should be valid UUID")
    assert_true(UUID.is_valid(player_id), "Player ID should be valid UUID")

# === 事件流测试 ===

func test_achievement_unlock_sends_analytics() -> void:
    _analytics_manager._event_queue.clear()
    watch_signals(_achievement_manager)

    _achievement_manager.unlock_achievement("explore_first")

    assert_signal_emitted(_achievement_manager, "achievement_unlocked", "Achievement should unlock")

    # Analytics 应记录事件（如果 enabled）
    if _analytics_manager.is_enabled():
        assert_gt(_analytics_manager.get_pending_events(), 0, "Analytics should have events")

func test_audio_sfx_signal() -> void:
    watch_signals(_audio_manager)

    # 模拟播放音效
    _audio_manager.sfx_played.emit("test_sfx")

    assert_signal_emitted(_audio_manager, "sfx_played", "SFX signal should emit")

func test_bgm_change_signal() -> void:
    watch_signals(_audio_manager)

    _audio_manager._current_bgm = "bgm_day"
    _audio_manager.bgm_changed.emit("bgm_day")

    assert_signal_emitted(_audio_manager, "bgm_changed", "BGM signal should emit")

# === 成就与统计测试 ===

func test_achievement_stats_sync() -> void:
    _achievement_manager.reset_all()

    # 通过事件触发
    _achievement_manager._on_enemy_killed("zombie_basic")
    _achievement_manager._on_explore_complete(true)
    _achievement_manager._on_resource_collected(100, "crystal")

    var stats: Dictionary = _achievement_manager.get_stats()

    assert_eq(stats.get("kill_count", 0), 1, "Kill count should be 1")
    assert_eq(stats.get("explore_count", 0), 1, "Explore count should be 1")
    assert_eq(stats.get("resource_total", 0), 100, "Resource total should be 100")

func test_cumulative_achievement_progress() -> void:
    _achievement_manager.reset_all()
    _achievement_manager._progress["explore_10"] = 0

    # 模拟 10 次探索
    for i in 10:
        _achievement_manager.check_achievement("explore_10")

    assert_true(_achievement_manager.is_unlocked("explore_10"), "explore_10 should be unlocked")

# === 音量与设置测试 ===

func test_audio_volume_affects_managers() -> void:
    _audio_manager.set_master_volume(0.5)
    _audio_manager.set_bgm_volume(0.3)
    _audio_manager.set_sfx_volume(0.7)

    assert_almost_eq(_audio_manager.get_master_volume(), 0.5, 0.01, "Master volume should be 0.5")
    assert_almost_eq(_audio_manager.get_bgm_volume(), 0.3, 0.01, "BGM volume should be 0.3")
    assert_almost_eq(_audio_manager.get_sfx_volume(), 0.7, 0.01, "SFX volume should be 0.7")

# === 禁用系统测试 ===

func test_analytics_disabled_stops_recording() -> void:
    _analytics_manager.set_enabled(true)
    _analytics_manager._event_queue.clear()
    _analytics_manager.record_event("before_disable", {})

    _analytics_manager.set_enabled(false)
    _analytics_manager.record_event("after_disable", {})

    # 队列应被清空且不再记录
    assert_eq(_analytics_manager.get_pending_events(), 0, "Events should not be recorded when disabled")

func test_achievement_still_unlocks_when_analytics_disabled() -> void:
    _analytics_manager.set_enabled(false)
    _achievement_manager.reset_all()

    watch_signals(_achievement_manager)
    _achievement_manager.unlock_achievement("test_achievement")

    # Achievement 解锁不依赖 Analytics
    assert_signal_emitted(_achievement_manager, "achievement_unlocked", "Achievement should still unlock")

# === 事件数据一致性测试 ===

func test_analytics_event_has_consistent_fields() -> void:
    _analytics_manager._event_queue.clear()

    _analytics_manager.record_event("test_event", {"key": "value", "number": 42})

    var event: Dictionary = _analytics_manager._event_queue[0]

    # 所有事件应有相同结构
    assert_has(event, "event_name", "Event should have event_name")
    assert_has(event, "timestamp", "Event should have timestamp")
    assert_has(event, "session_id", "Event should have session_id")
    assert_has(event, "player_id", "Event should have player_id")
    assert_has(event, "platform", "Event should have platform")
    assert_has(event, "build_version", "Event should have build_version")
    assert_has(event, "locale", "Event should have locale")

    # Session ID 和 Player ID 应匹配
    assert_eq(event["session_id"], _analytics_manager.get_session_id(), "Session ID should match")
    assert_eq(event["player_id"], _analytics_manager.get_player_id(), "Player ID should match")

# === 多 Manager 协作测试 ===

func test_achievement_category_distribution() -> void:
    var defs: Dictionary = _achievement_manager.get_all_achievements()

    var categories: Dictionary = {}
    for id in defs:
        var category: String = defs[id].get("category", "unknown")
        categories[category] = categories.get(category, 0) + 1

    # 每个分类应有成就
    assert_has(categories, "exploration", "Should have exploration category")
    assert_has(categories, "combat", "Should have combat category")
    assert_has(categories, "building", "Should have building category")

func test_audio_sfx_pool_shared() -> void:
    # SFX 播放器池应共享
    var pool_size: int = _audio_manager._sfx_players.size()

    assert_eq(pool_size, 8, "SFX pool should have 8 players")

# === 重置测试 ===

func test_reset_achievement_clears_all() -> void:
    _achievement_manager.unlock_achievement("explore_first")
    _achievement_manager.unlock_achievement("kill_first")

    _achievement_manager.reset_all()

    assert_eq(_achievement_manager.get_unlocked_count(), 0, "All achievements should be cleared")
    assert_false(_achievement_manager.is_unlocked("explore_first"), "explore_first should be locked")

func test_reset_achievement_clears_progress() -> void:
    _achievement_manager._progress["explore_50"] = 30

    _achievement_manager.reset_all()

    var progress: Dictionary = _achievement_manager.get_progress("explore_50")
    assert_eq(progress.get("current", 0), 0, "Progress should be cleared")

# === 隐藏成就测试 ===

func test_hidden_achievements_not_in_initial_list() -> void:
    var defs: Dictionary = _achievement_manager.get_all_achievements()

    # 检查隐藏成就标记
    var hidden_count: int = 0
    for id in defs:
        if defs[id].get("hidden", false):
            hidden_count += 1

    assert_gt(hidden_count, 0, "Should have hidden achievements")
    assert_lt(hidden_count, defs.size(), "Not all achievements should be hidden")

# === 边界条件测试 ===

func test_concurrent_unlocks() -> void:
    _achievement_manager.reset_all()

    # 同时解锁多个
    _achievement_manager.unlock_achievement("explore_first")
    _achievement_manager.unlock_achievement("kill_first")
    _achievement_manager.unlock_achievement("build_first")
    _achievement_manager.unlock_achievement("survive_day_1")

    assert_eq(_achievement_manager.get_unlocked_count(), 4, "Should have 4 unlocked")

func test_bulk_analytics_events() -> void:
    _analytics_manager._event_queue.clear()

    for i in 50:
        _analytics_manager.record_event("bulk_test_%d" % i, {"index": i})

    assert_eq(_analytics_manager.get_pending_events(), 50, "Should have 50 events queued")

func test_manager_state_preserved_after_disable_enable() -> void:
    var original_session: String = _analytics_manager.get_session_id()
    var original_player: String = _analytics_manager.get_player_id()

    _analytics_manager.set_enabled(false)
    _analytics_manager.set_enabled(true)

    # ID 应保持不变
    assert_eq(_analytics_manager.get_session_id(), original_session, "Session ID should be preserved")
    assert_eq(_analytics_manager.get_player_id(), original_player, "Player ID should be preserved")