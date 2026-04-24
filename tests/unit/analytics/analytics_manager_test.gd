# AnalyticsManager Unit Tests
# Tests event recording, queue management, and offline caching
# Framework: GUT (Godot Unit Testing)

extends GutTest

var _analytics_manager: AnalyticsManager = null

func before_all() -> void:
    # 创建 AnalyticsManager 实例
    _analytics_manager = AnalyticsManager.new()
    add_child(_analytics_manager)
    await wait_for_signal(_analytics_manager.ready, 1.0)

func after_all() -> void:
    if _analytics_manager:
        _analytics_manager.queue_free()

# === 初始化测试 ===

func test_analytics_manager_initializes() -> void:
    assert_not_null(_analytics_manager, "AnalyticsManager should not be null")

func test_session_id_generated() -> void:
    var session_id: String = _analytics_manager.get_session_id()

    assert_not_null(session_id, "Session ID should be generated")
    assert_gt(session_id.length(), 0, "Session ID should not be empty")

func test_player_id_generated() -> void:
    var player_id: String = _analytics_manager.get_player_id()

    assert_not_null(player_id, "Player ID should be generated")
    assert_gt(player_id.length(), 0, "Player ID should not be empty")

func test_uuid_format_valid() -> void:
    var session_id: String = _analytics_manager.get_session_id()

    assert_true(UUID.is_valid(session_id), "Session ID should be valid UUID format")

# === 事件记录测试 ===

func test_record_event_adds_to_queue() -> void:
    _analytics_manager._event_queue.clear()

    _analytics_manager.record_event("test_event", {"test_data": 123})

    assert_eq(_analytics_manager.get_pending_events(), 1, "Event queue should have 1 event")

func test_event_contains_required_fields() -> void:
    _analytics_manager._event_queue.clear()

    _analytics_manager.record_event("test_event", {"value": 42})

    var event: Dictionary = _analytics_manager._event_queue[0]

    assert_has(event, "event_name", "Event should have event_name")
    assert_has(event, "event_timestamp", "Event should have timestamp")
    assert_has(event, "session_id", "Event should have session_id")
    assert_has(event, "player_id", "Event should have player_id")
    assert_has(event, "platform", "Event should have platform")
    assert_has(event, "event_data", "Event should have event_data")

func test_event_data_preserved() -> void:
    _analytics_manager._event_queue.clear()

    _analytics_manager.record_event("custom_event", {"key1": "value1", "key2": 100})

    var event: Dictionary = _analytics_manager._event_queue[0]
    var data: Dictionary = event["event_data"]

    assert_eq(data.get("key1", ""), "value1", "Event data key1 should be preserved")
    assert_eq(data.get("key2", 0), 100, "Event data key2 should be preserved")

# === Convenience Methods 测试 ===

func test_session_start_records_event() -> void:
    _analytics_manager._event_queue.clear()

    _analytics_manager.session_start(true)

    var event: Dictionary = _analytics_manager._event_queue[0]

    assert_eq(event["event_name"], "session_start", "Event name should be session_start")
    assert_eq(event["event_data"].get("first_launch", false), true, "first_launch should be true")

func test_explore_end_records_correct_data() -> void:
    _analytics_manager._event_queue.clear()

    _analytics_manager.explore_end(300, {"crystal": 10, "metal": 5}, 15, "success")

    var event: Dictionary = _analytics_manager._event_queue[0]

    assert_eq(event["event_name"], "explore_end", "Event name should be explore_end")
    assert_eq(event["event_data"].get("duration", 0), 300, "Duration should be recorded")
    assert_eq(event["event_data"].get("enemies_killed", 0), 15, "Enemies killed should be recorded")

func test_death_records_correct_data() -> void:
    _analytics_manager._event_queue.clear()

    _analytics_manager.death(10, 5, "zone_a", "zombie_basic")

    var event: Dictionary = _analytics_manager._event_queue[0]

    assert_eq(event["event_name"], "death", "Event name should be death")
    assert_eq(event["event_data"].get("hp_remaining", 0), 10, "HP should be recorded")
    assert_eq(event["event_data"].get("enemy_type", ""), "zombie_basic", "Enemy type should be recorded")

# === 队列管理测试 ===

func test_queue_max_size_enforced() -> void:
    _analytics_manager._event_queue.clear()

    for i in 150:  # 超过 MAX_QUEUE_SIZE (100)
        _analytics_manager.record_event("overflow_test", {"index": i})

    # 队列应该触发上传或限制大小
    # 在测试环境无网络，可能缓存
    var pending: int = _analytics_manager.get_pending_events()

    assert_lte(pending, 100, "Queue should not exceed MAX_QUEUE_SIZE")

func test_pending_events_count() -> void:
    _analytics_manager._event_queue.clear()

    for i in 5:
        _analytics_manager.record_event("count_test", {})

    assert_eq(_analytics_manager.get_pending_events(), 5, "Pending count should be 5")

# === 隐私控制测试 ===

func test_set_enabled_true() -> void:
    _analytics_manager.set_enabled(true)

    assert_true(_analytics_manager.is_enabled(), "Analytics should be enabled")

func test_set_enabled_false() -> void:
    _analytics_manager.set_enabled(true)
    _analytics_manager.record_event("before_disable", {})

    _analytics_manager.set_enabled(false)

    assert_false(_analytics_manager.is_enabled(), "Analytics should be disabled")
    assert_eq(_analytics_manager.get_pending_events(), 0, "Queue should be cleared when disabled")

func test_disabled_does_not_record() -> void:
    _analytics_manager.set_enabled(false)
    _analytics_manager._event_queue.clear()

    _analytics_manager.record_event("disabled_test", {})

    assert_eq(_analytics_manager.get_pending_events(), 0, "No events should be recorded when disabled")

# === 端点配置测试 ===

func test_set_endpoint() -> void:
    var new_endpoint: String = "https://new.endpoint.com/v2/events"
    _analytics_manager.set_endpoint(new_endpoint)

    assert_eq(_analytics_manager._endpoint_url, new_endpoint, "Endpoint should be updated")

func test_set_online_status() -> void:
    _analytics_manager.set_online_status(false)

    assert_false(_analytics_manager._is_online, "Online status should be false")

# === 统计测试 ===

func test_total_events_sent_initial_zero() -> void:
    # 新实例
    var sent: int = _analytics_manager.get_total_events_sent()

    assert_eq(sent, 0, "Initial sent count should be 0")

# === 缓存测试 ===

func test_cache_events_creates_file() -> void:
    _analytics_manager._event_queue.clear()
    _analytics_manager.record_event("cache_test", {"data": 1})

    _analytics_manager._cache_events()

    # 检查缓存文件存在
    assert_true(FileAccess.file_exists("user://analytics_cache.json"), "Cache file should exist")

func test_load_cached_events() -> void:
    # 创建缓存
    _analytics_manager._event_queue.clear()
    _analytics_manager.record_event("cached_event", {"id": 999})
    _analytics_manager._cache_events()

    # 清空队列，重新加载
    _analytics_manager._event_queue.clear()
    _analytics_manager._load_cached_events()

    assert_gt(_analytics_manager.get_pending_events(), 0, "Cached events should be loaded")

func test_clear_cache_removes_file() -> void:
    _analytics_manager._cache_events()
    _analytics_manager._clear_cache()

    assert_false(FileAccess.file_exists("user://analytics_cache.json"), "Cache file should be removed")

# === 边界条件测试 ===

func test_empty_event_data() -> void:
    _analytics_manager._event_queue.clear()

    _analytics_manager.record_event("empty_data_test", {})

    assert_eq(_analytics_manager.get_pending_events(), 1, "Event with empty data should still be recorded")

func test_large_event_data() -> void:
    _analytics_manager._event_queue.clear()

    var large_data: Dictionary = {}
    for i in 100:
        large_data["key_%d" % i] = i

    _analytics_manager.record_event("large_data_test", large_data)

    assert_eq(_analytics_manager.get_pending_events(), 1, "Large data event should be recorded")

func test_special_characters_in_event_name() -> void:
    _analytics_manager._event_queue.clear()

    _analytics_manager.record_event("test:event:with:special_chars", {"data": 1})

    assert_eq(_analytics_manager.get_pending_events(), 1, "Special chars in name should not crash")

func test_unicode_in_event_data() -> void:
    _analytics_manager._event_queue.clear()

    _analytics_manager.record_event("unicode_test", {"text": "铁锈魔潮 中文测试"})

    var event: Dictionary = _analytics_manager._event_queue[0]

    assert_eq(event["event_data"].get("text", ""), "铁锈魔潮 中文测试", "Unicode should be preserved")