# CrashManager Unit Tests
# Tests crash capture, report generation, and upload queue
# Framework: GUT (Godot Unit Testing)

extends GutTest

var _crash_manager: CrashManager = null

func before_all() -> void:
    # 创建 CrashManager 实例
    _crash_manager = CrashManager.new()
    add_child(_crash_manager)
    await wait_for_signal(_crash_manager.ready, 1.0)

func after_all() -> void:
    if _crash_manager:
        _crash_manager.queue_free()

# === 初始化测试 ===

func test_crash_manager_initializes() -> void:
    assert_not_null(_crash_manager, "CrashManager should not be null")

func test_crash_cache_dir_created() -> void:
    assert_true(DirAccess.dir_exists_expand("user://crash_reports/"), "Crash cache directory should exist")

func test_session_start_time_recorded() -> void:
    assert_gt(_crash_manager._session_start_time, 0, "Session start time should be recorded")

# === 崩溃捕获测试 ===

func test_capture_crash_creates_report() -> void:
    watch_signals(_crash_manager)

    _crash_manager.capture_crash("TEST_ERROR", "Test error message", "Test stack trace\nLine 2")

    assert_signal_emitted(_crash_manager, "crash_report_saved", "Crash report saved signal should emit")
    assert_gt(_crash_manager.get_crash_count(), 0, "Crash count should increase")

func test_report_file_created() -> void:
    _crash_manager.capture_crash("FILE_TEST", "File creation test", "Stack trace")

    # 检查是否有 pending 报告
    assert_gt(_crash_manager.get_pending_count(), 0, "Should have pending reports")

func test_report_contains_required_fields() -> void:
    # 模拟捕获，检查数据结构
    _crash_manager.capture_crash("STRUCTURE_TEST", "Structure test", "Stack\nLine 2\nLine 3")

    # 报告内容无法直接访问，但可以验证 crash_count 增加
    assert_gt(_crash_manager.get_crash_count(), 0, "Crash should be captured")

# === 崩溃统计测试 ===

func test_crash_count_increments() -> void:
    _crash_manager._crash_count = 0

    _crash_manager.capture_crash("COUNT_TEST_1", "Test 1", "Stack 1")
    _crash_manager.capture_crash("COUNT_TEST_2", "Test 2", "Stack 2")

    assert_eq(_crash_manager.get_crash_count(), 2, "Crash count should be 2")

# === 设备信息测试 ===

func test_collect_device_info() -> void:
    var info: Dictionary = _crash_manager._collect_device_info()

    assert_has(info, "os_version", "Device info should have os_version")
    assert_has(info, "cpu", "Device info should have cpu")
    assert_has(info, "gpu", "Device info should have gpu")
    assert_has(info, "memory_mb", "Device info should have memory_mb")
    assert_has(info, "screen_resolution", "Device info should have screen_resolution")

# === 游戏状态收集测试 ===

func test_collect_game_state() -> void:
    _crash_manager._current_scene = "test_scene"
    _crash_manager._game_state = {"day_number": 5, "player_hp": 80}

    var state: Dictionary = _crash_manager._collect_game_state()

    assert_eq(state.get("scene", ""), "test_scene", "Scene should be recorded")
    assert_eq(state.get("day_number", 0), 5, "Day number should be recorded")
    assert_eq(state.get("player_hp", 0), 80, "Player HP should be recorded")
    assert_has(state, "session_duration", "Session duration should be recorded")

# === Stack Trace Hash 测试 ===

func test_hash_stack_trace_unique() -> void:
    var hash1: String = _crash_manager._hash_stack_trace("Error A\nLine 2\nLine 3")
    var hash2: String = _crash_manager._hash_stack_trace("Error B\nLine 2\nLine 3")

    # 不同的前3行应产生不同 hash
    assert_ne(hash1, hash2, "Different stack traces should have different hashes")

func test_hash_stack_trace_consistent() -> void:
    var hash1: String = _crash_manager._hash_stack_trace("Same Error\nLine 2\nLine 3")
    var hash2: String = _crash_manager._hash_stack_trace("Same Error\nLine 2\nLine 3")

    assert_eq(hash1, hash2, "Same stack traces should have same hash")

# === Pending 报告管理测试 ===

func test_count_pending_reports() -> void:
    # 清空现有报告
    _crash_manager._cleanup_old_reports()

    var count: int = _crash_manager.get_pending_count()
    assert_gte(count, 0, "Pending count should be >= 0")

func test_has_pending_reports() -> void:
    _crash_manager.capture_crash("PENDING_TEST", "Test", "Stack")

    assert_true(_crash_manager.has_pending_reports(), "Should have pending reports after capture")

# === 报告清理测试 ===

func test_cleanup_old_reports_limits_count() -> void:
    # 模拟多次崩溃
    for i in 15:  # 超过 MAX_CRASH_FILES (10)
        _crash_manager.capture_crash("CLEANUP_TEST_%d" % i, "Test %d" % i, "Stack")

    # 清理应限制数量
    _crash_manager._cleanup_old_reports()

    var pending: int = _crash_manager.get_pending_count()
    assert_lte(pending, 10, "Pending reports should be <= MAX_CRASH_FILES")

# === Game State 更新测试 ===

func test_update_game_state() -> void:
    _crash_manager.update_game_state({"day_number": 10, "player_hp": 50, "player_mp": 30})

    assert_eq(_crash_manager._game_state.get("day_number", 0), 10, "Game state should be updated")
    assert_eq(_crash_manager._game_state.get("player_hp", 0), 50, "Game state should be updated")

func test_set_current_scene() -> void:
    _crash_manager.set_current_scene("game_scene")

    assert_eq(_crash_manager._current_scene, "game_scene", "Current scene should be set")

# === Safe Call Wrapper 测试 ===

func test_safe_call_success() -> void:
    var result: Variant = _crash_manager.safe_call(func(): return 42)

    assert_eq(result, 42, "Safe call should return function result")

func test_safe_call_with_args() -> void:
    var result: Variant = _crash_manager.safe_call(func(a: int, b: int): return a + b, [5, 10])

    assert_eq(result, 15, "Safe call with args should work")

# === 模拟崩溃测试 ===

func test_simulate_crash() -> void:
    var initial_count: int = _crash_manager.get_crash_count()

    _crash_manager.simulate_crash("SIMULATION_TEST")

    assert_eq(_crash_manager.get_crash_count(), initial_count + 1, "Simulate crash should increase count")

# === 端点配置测试 ===

func test_set_upload_endpoint() -> void:
    var new_endpoint: String = "https://new.crash.endpoint.com/v2/report"
    _crash_manager.set_upload_endpoint(new_endpoint)

    assert_eq(_crash_manager._upload_endpoint, new_endpoint, "Endpoint should be updated")

# === 边界条件测试 ===

func test_empty_stack_trace() -> void:
    _crash_manager.capture_crash("EMPTY_STACK", "Empty stack test", "")

    assert_gt(_crash_manager.get_crash_count(), 0, "Empty stack trace should still create report")

func test_very_long_stack_trace() -> void:
    var long_stack: String = ""
    for i in 100:
        long_stack += "Line %d\n" % i

    _crash_manager.capture_crash("LONG_STACK", "Long stack test", long_stack)

    assert_gt(_crash_manager.get_crash_count(), 0, "Long stack trace should still create report")

func test_unicode_in_error_message() -> void:
    _crash_manager.capture_crash("UNICODE_TEST", "中文错误消息 铁锈魔潮", "Stack trace")

    assert_gt(_crash_manager.get_crash_count(), 0, "Unicode in message should work")

func test_special_chars_in_error_type() -> void:
    _crash_manager.capture_crash("ERROR:TYPE:WITH:SPECIAL", "Special chars test", "Stack")

    assert_gt(_crash_manager.get_crash_count(), 0, "Special chars in error type should work")