# AppRoot — 应用根节点
# 负责场景切换、全局状态管理、菜单/游戏流程控制

extends Control

# === 场景引用 ===
@onready var _main_menu: Control = $MainMenu
@onready var _pause_menu: Control = $PauseMenu
@onready var _credits_screen: Control = $CreditsScreen
@onready var _game_scene: Node = $GameScene

# === 状态 ===
var _current_state: String = "menu"  # menu, playing, paused, credits
var _previous_state: String = ""

# === 信号 ===
signal state_changed(new_state: String)

func _ready() -> void:
    # 连接菜单信号
    _connect_menu_signals()

    # 显示主菜单
    _show_main_menu()

    # 播放菜单音乐
    AudioManager.play_bgm("bgm_menu")

    print("[AppRoot] Initialized — State: menu")

func _connect_menu_signals() -> void:
    # MainMenu 信号
    if _main_menu:
        _main_menu.play_requested.connect(_on_play_requested)
        _main_menu.continue_requested.connect(_on_continue_requested)
        _main_menu.settings_requested.connect(_on_settings_requested)
        _main_menu.credits_requested.connect(_on_credits_requested)
        _main_menu.quit_requested.connect(_on_quit_requested)

    # PauseMenu 信号
    if _pause_menu:
        _pause_menu.resume_requested.connect(_on_resume_requested)
        _pause_menu.quit_to_menu_requested.connect(_on_quit_to_menu_requested)

    # CreditsScreen 信号
    if _credits_screen:
        _credits_screen.credits_completed.connect(_on_credits_completed)

    # GlobalSignals
    GlobalSignals.game_paused.connect(_on_game_paused)
    GlobalSignals.game_resumed.connect(_on_game_resumed)
    GlobalSignals.game_ended.connect(_on_game_ended)
    GlobalSignals.credits_finished.connect(_on_credits_finished)

# === 状态管理 ===

func _set_state(new_state: String) -> void:
    _previous_state = _current_state
    _current_state = new_state
    state_changed.emit(new_state)

    print("[AppRoot] State changed: %s → %s" % [_previous_state, new_state])

func get_current_state() -> String:
    return _current_state

# === 场景切换 ===

func _show_main_menu() -> void:
    _hide_all()
    _main_menu.visible = true
    _set_state("menu")

func _show_game() -> void:
    _hide_all()
    _game_scene.visible = true
    _set_state("playing")

    # 停止菜单音乐，开始游戏音乐
    AudioManager.stop_bgm()
    AudioManager.play_bgm("bgm_day")

func _show_pause_menu() -> void:
    _pause_menu.visible = true
    _set_state("paused")

func _hide_pause_menu() -> void:
    _pause_menu.visible = false
    _set_state("playing")

func _show_credits() -> void:
    _hide_all()
    _credits_screen.visible = true
    _credits_screen.start_credits()
    _set_state("credits")

func _hide_all() -> void:
    _main_menu.visible = false
    _pause_menu.visible = false
    _credits_screen.visible = false
    _game_scene.visible = false

# === 菜单回调 ===

func _on_play_requested(start_tutorial: bool) -> void:
    AudioManager.play_sfx("ui_confirm")

    if start_tutorial:
        # 启动教程模式
        TutorialManager.start_tutorial()

    _show_game()

    # 记录遥测
    AnalyticsManager.session_start(not SaveManager.has_setting("tutorial_completed"))

func _on_continue_requested() -> void:
    AudioManager.play_sfx("ui_confirm")

    # 加载存档
    if SaveManager.load_game():
        _show_game()
    else:
        # 无存档，显示主菜单
        _show_main_menu()

func _on_settings_requested() -> void:
    AudioManager.play_sfx("ui_click")
    # 设置面板在 MainMenu 内处理

func _on_credits_requested() -> void:
    AudioManager.play_sfx("ui_click")
    _show_credits()

func _on_quit_requested() -> void:
    AudioManager.play_sfx("ui_click")

    # 保存游戏状态
    if _current_state == "playing":
        SaveManager.auto_save()

    # 退出游戏
    get_tree().quit()

# === 暂停菜单回调 ===

func _on_resume_requested() -> void:
    _hide_pause_menu()

func _on_quit_to_menu_requested() -> void:
    AudioManager.stop_bgm()
    AudioManager.play_bgm("bgm_menu")

    _show_main_menu()

# === Credits 回调 ===

func _on_credits_completed() -> void:
    _show_main_menu()

func _on_credits_finished() -> void:
    _show_main_menu()

# === 游戏事件回调 ===

func _on_game_paused() -> void:
    if _current_state == "playing":
        _show_pause_menu()

func _on_game_resumed() -> void:
    if _current_state == "paused":
        _hide_pause_menu()

func _on_game_ended(reason: String) -> void:
    AudioManager.stop_bgm()

    if reason == "victory":
        AudioManager.play_bgm("bgm_victory")
        AnalyticsManager.explore_end(0, {}, 0, "victory")
    else:
        AudioManager.play_bgm("bgm_defeat")
        AnalyticsManager.explore_end(0, {}, 0, "defeat")

    # 返回主菜单
    await get_tree().create_timer(3.0).timeout
    _show_main_menu()

# === 输入处理 ===

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause"):
        if _current_state == "playing":
            GlobalSignals.game_paused.emit()
            get_viewport().set_input_as_handled()
        elif _current_state == "paused":
            GlobalSignals.game_resumed.emit()
            get_viewport().set_input_as_handled()

func _notification(what: int) -> void:
    if what == NOTIFICATION_WM_CLOSE_REQUEST:
        # 窗口关闭请求
        if SaveManager and _current_state == "playing":
            SaveManager.auto_save()

        # 记录会话结束
        if AnalyticsManager:
            var duration: int = (Time.get_ticks_msec() - AnalyticsManager._session_start_time) / 1000
            AnalyticsManager.session_end(duration, "window_close")