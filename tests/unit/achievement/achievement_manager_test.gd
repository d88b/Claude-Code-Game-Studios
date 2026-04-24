# AchievementManager Unit Tests
# Tests achievement unlocking, progress tracking, and Steam sync
# Framework: GUT (Godot Unit Testing)

extends GutTest

var _achievement_manager: AchievementManager = null

func before_all() -> void:
    # 创建 AchievementManager 实例
    _achievement_manager = AchievementManager.new()
    add_child(_achievement_manager)
    await wait_for_signal(_achievement_manager.ready, 1.0)

func after_all() -> void:
    if _achievement_manager:
        _achievement_manager.queue_free()

# === 初始化测试 ===

func test_achievement_manager_initializes() -> void:
    assert_not_null(_achievement_manager, "AchievementManager should not be null")

func test_achievement_definitions_loaded() -> void:
    var defs: Dictionary = _achievement_manager.get_all_achievements()
    assert_gt(defs.size(), 0, "Achievement definitions should be loaded")

func test_initial_unlocked_count_zero() -> void:
    # 新实例应无解锁
    var count: int = _achievement_manager.get_unlocked_count()
    assert_eq(count, 0, "Initial unlocked count should be 0")

# === 解锁测试 ===

func test_unlock_one_time_achievement() -> void:
    watch_signals(_achievement_manager)

    _achievement_manager.unlock_achievement("explore_first")

    assert_true(_achievement_manager.is_unlocked("explore_first"), "explore_first should be unlocked")
    assert_signal_emitted(_achievement_manager, "achievement_unlocked", "unlock signal should emit")

func test_unlock_cumulative_achievement() -> void:
    # 累计型需要多次触发
    for i in 10:
        _achievement_manager.check_achievement("explore_10")

    assert_true(_achievement_manager.is_unlocked("explore_10"), "explore_10 should be unlocked after 10 checks")

func test_achievement_not_unlocked_before_target() -> void:
    _achievement_manager._progress["explore_50"] = 25

    assert_false(_achievement_manager.is_unlocked("explore_50"), "explore_50 should not be unlocked at 25/50")

func test_progress_signal_for_cumulative() -> void:
    watch_signals(_achievement_manager)

    _achievement_manager.check_achievement("explore_10")

    assert_signal_emitted(_achievement_manager, "achievement_progress", "progress signal should emit")

func test_progress_increments_correctly() -> void:
    _achievement_manager._progress["kill_100"] = 0

    for i in 5:
        _achievement_manager.check_achievement("kill_100")

    var current: int = _achievement_manager._progress.get("kill_100", 0)
    assert_eq(current, 5, "Progress should be 5 after 5 checks")

# === 统计追踪测试 ===

func test_stats_initial_state() -> void:
    var stats: Dictionary = _achievement_manager.get_stats()

    assert_eq(stats.get("explore_count", -1), 0, "explore_count should start at 0")
    assert_eq(stats.get("kill_count", -1), 0, "kill_count should start at 0")

func test_stats_update_on_event() -> void:
    _achievement_manager._on_enemy_killed("zombie_basic")
    _achievement_manager._on_explore_complete(true)

    var stats: Dictionary = _achievement_manager.get_stats()

    assert_eq(stats.get("kill_count", 0), 1, "kill_count should be 1")
    assert_eq(stats.get("explore_count", 0), 1, "explore_count should be 1")

# === 分类测试 ===

func test_get_category_achievements() -> void:
    var combat: Array = _achievement_manager.get_category_achievements("combat")

    assert_gt(combat.size(), 0, "Combat category should have achievements")
    assert_true(combat.has("kill_first"), "kill_first should be in combat category")

func test_categories_exist() -> void:
    var defs: Dictionary = _achievement_manager.get_all_achievements()

    for id in defs:
        var category: String = defs[id].get("category", "")
        assert_not_null(category, "Achievement %s should have category" % id)

# === 隐藏成就测试 ===

func test_hidden_achievement_flag() -> void:
    var defs: Dictionary = _achievement_manager.get_all_achievements()

    assert_true(defs["survive_day_30"].get("hidden", false), "survive_day_30 should be hidden")
    assert_false(defs["survive_day_1"].get("hidden", false), "survive_day_1 should not be hidden")

# === 进度获取测试 ===

func test_get_progress_for_unlocked() -> void:
    _achievement_manager.unlock_achievement("explore_first")

    var progress: Dictionary = _achievement_manager.get_progress("explore_first")

    # 一次性成就，进度应为完成
    assert_eq(progress.get("current", 0), 1, "One-time achievement progress should be 1")

func test_get_progress_for_cumulative() -> void:
    _achievement_manager._progress["explore_50"] = 30

    var progress: Dictionary = _achievement_manager.get_progress("explore_50")

    assert_eq(progress.get("current", 0), 30, "Current progress should be 30")
    assert_eq(progress.get("target", 0), 50, "Target should be 50")

# === 重置测试 ===

func test_reset_all_clears_unlocked() -> void:
    _achievement_manager.unlock_achievement("explore_first")
    _achievement_manager.unlock_achievement("kill_first")

    _achievement_manager.reset_all()

    assert_eq(_achievement_manager.get_unlocked_count(), 0, "All achievements should be cleared")
    assert_false(_achievement_manager.is_unlocked("explore_first"), "explore_first should be locked after reset")

func test_reset_clears_progress() -> void:
    _achievement_manager._progress["explore_10"] = 5

    _achievement_manager.reset_all()

    var progress: Dictionary = _achievement_manager.get_progress("explore_10")
    assert_eq(progress.get("current", 0), 0, "Progress should be 0 after reset")

func test_reset_clears_stats() -> void:
    _achievement_manager._stats["kill_count"] = 100

    _achievement_manager.reset_all()

    var stats: Dictionary = _achievement_manager.get_stats()
    assert_eq(stats.get("kill_count", 0), 0, "Stats should be cleared")

# === 总数测试 ===

func test_get_total_count() -> void:
    var total: int = _achievement_manager.get_total_count()
    assert_gt(total, 20, "Total achievements should be > 20")

func test_unlocked_count_after_multiple_unlocks() -> void:
    _achievement_manager.unlock_achievement("explore_first")
    _achievement_manager.unlock_achievement("kill_first")
    _achievement_manager.unlock_achievement("build_first")

    var count: int = _achievement_manager.get_unlocked_count()
    assert_eq(count, 3, "Unlocked count should be 3")

# === 事件回调测试 ===

func test_on_resource_collected_updates_stats() -> void:
    _achievement_manager._on_resource_collected(50, "crystal")

    var stats: Dictionary = _achievement_manager.get_stats()
    assert_eq(stats.get("resource_total", 0), 50, "resource_total should be 50")

func test_on_rare_pickup_unlocks_achievement() -> void:
    _achievement_manager._on_resource_collected(1, "rare")

    assert_true(_achievement_manager.is_unlocked("rare_pickup"), "rare_pickup should be unlocked")

func test_on_day_completed_updates_max_day() -> void:
    _achievement_manager._on_day_completed(5)
    _achievement_manager._on_day_completed(3)

    var stats: Dictionary = _achievement_manager.get_stats()
    assert_eq(stats.get("day_max", 0), 5, "day_max should be 5 (max of 5 and 3)")

func test_on_wave_complete_no_damage() -> void:
    watch_signals(_achievement_manager)

    _achievement_manager._on_wave_complete(0, 0)  # enemies_remaining=0, hp_lost=0

    assert_true(_achievement_manager.is_unlocked("kill_wave"), "kill_wave should be unlocked")
    assert_true(_achievement_manager.is_unlocked("no_damage_wave"), "no_damage_wave should be unlocked")

# === 边界条件测试 ===

func test_unlock_already_unlocked_no_duplicate() -> void:
    _achievement_manager.unlock_achievement("explore_first")
    var count1: int = _achievement_manager.get_unlocked_count()

    _achievement_manager.unlock_achievement("explore_first")  # 再次解锁
    var count2: int = _achievement_manager.get_unlocked_count()

    assert_eq(count1, count2, "Unlocking same achievement should not increase count")

func test_invalid_achievement_id() -> void:
    _achievement_manager.check_achievement("nonexistent")

    # 不应崩溃
    assert_true(true, "Invalid achievement ID should not crash")

func test_check_achievement_after_unlock() -> void:
    _achievement_manager.unlock_achievement("explore_first")

    # 再次检查，不应增加进度
    _achievement_manager.check_achievement("explore_first")

    assert_true(_achievement_manager.is_unlocked("explore_first"), "Should still be unlocked")