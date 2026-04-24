# PauseMenu — 暂停菜单界面
# 暂停游戏，显示继续/设置/返回主菜单选项
# Design: design/ux/pause-menu.md

extends Control

# === 节点引用 ===
@onready var _pause_title: Label = $PausePanel/PauseContent/PauseTitle
@onready var _resume_button: Button = $PausePanel/PauseContent/ResumeButton
@onready var _settings_button: Button = $PausePanel/PauseContent/SettingsButton
@onready var _quit_to_menu_button: Button = $PausePanel/PauseContent/QuitToMenuButton

@onready var _settings_overlay: Control = $SettingsOverlay
@onready var _master_slider: HSlider = $SettingsOverlay/SettingsContainer/SettingsVBox/AudioSection/MasterVolumeSlider
@onready var _bgm_slider: HSlider = $SettingsOverlay/SettingsContainer/SettingsVBox/AudioSection/BGMVolumeSlider
@onready var _sfx_slider: HSlider = $SettingsOverlay/SettingsContainer/SettingsVBox/AudioSection/SFXVolumeSlider
@onready var _close_settings_button: Button = $SettingsOverlay/SettingsContainer/SettingsVBox/CloseSettingsButton

# === 状态 ===
var _is_paused: bool = false

# === 信号 ===
signal resume_requested()
signal settings_requested()
signal quit_to_menu_requested()

func _ready() -> void:
    # 设置本地化文本
    _setup_localized_text()

    # 连接按钮信号
    _connect_buttons()

    # 加载音量设置
    _load_volume_settings()

    # 默认隐藏
    visible = false

    print("[PauseMenu] Ready")

func _setup_localized_text() -> void:
    _pause_title.text = LocalizationManager.tr("menu.pause.title")
    _resume_button.text = LocalizationManager.tr("menu.pause.resume")
    _settings_button.text = LocalizationManager.tr("menu.pause.settings")
    _quit_to_menu_button.text = LocalizationManager.tr("menu.pause.quit_to_menu")

func _connect_buttons() -> void:
    _resume_button.pressed.connect(_on_resume_pressed)
    _settings_button.pressed.connect(_on_settings_pressed)
    _quit_to_menu_button.pressed.connect(_on_quit_to_menu_pressed)

    _master_slider.value_changed.connect(_on_master_volume_changed)
    _bgm_slider.value_changed.connect(_on_bgm_volume_changed)
    _sfx_slider.value_changed.connect(_on_sfx_volume_changed)
    _close_settings_button.pressed.connect(_on_close_settings)

func _load_volume_settings() -> void:
    if AudioManager:
        _master_slider.value = AudioManager.get_master_volume()
        _bgm_slider.value = AudioManager.get_bgm_volume()
        _sfx_slider.value = AudioManager.get_sfx_volume()

# === 暂停控制 ===

func show_pause_menu() -> void:
    visible = true
    _is_paused = true
    _settings_overlay.visible = false

    # 暂停游戏
    get_tree().paused = true

    # 暂停音乐
    if AudioManager:
        AudioManager.pause_bgm()

    AudioManager.play_sfx("menu_open")

func hide_pause_menu() -> void:
    visible = false
    _is_paused = false

    # 恢复游戏
    get_tree().paused = false

    # 恢复音乐
    if AudioManager:
        AudioManager.resume_bgm()

func toggle_pause() -> void:
    if _is_paused:
        hide_pause_menu()
    else:
        show_pause_menu()

# === 按钮回调 ===

func _on_resume_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    hide_pause_menu()
    resume_requested.emit()

func _on_settings_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    _show_settings()

func _on_quit_to_menu_pressed() -> void:
    AudioManager.play_sfx("ui_click")

    # 保存当前状态
    if SaveManager:
        SaveManager.auto_save()

    hide_pause_menu()
    quit_to_menu_requested.emit()

# === 设置面板 ===

func _show_settings() -> void:
    _settings_overlay.visible = true

func _hide_settings() -> void:
    _settings_overlay.visible = false

func _on_close_settings() -> void:
    AudioManager.play_sfx("ui_click")
    _hide_settings()

func _on_master_volume_changed(value: float) -> void:
    if AudioManager:
        AudioManager.set_master_volume(value)

func _on_bgm_volume_changed(value: float) -> void:
    if AudioManager:
        AudioManager.set_bgm_volume(value)

func _on_sfx_volume_changed(value: float) -> void:
    if AudioManager:
        AudioManager.set_sfx_volume(value)

# === 输入处理 ===

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
        if _settings_overlay.visible:
            _hide_settings()
        elif _is_paused:
            hide_pause_menu()
            resume_requested.emit()
        get_viewport().set_input_as_handled()

# === 公共 API ===

func is_paused() -> bool:
    return _is_paused