# MainMenu — 主菜单界面
# 显示游戏标题、开始/继续/设置/退出按钮
# Design: design/ux/main-menu.md

extends Control

# === 节点引用 ===
@onready var _title_label: Label = $TitleContainer/TitleLabel
@onready var _subtitle_label: Label = $TitleContainer/SubtitleLabel
@onready var _version_label: Label = $TitleContainer/VersionLabel
@onready var _play_button: Button = $MenuButtons/PlayButton
@onready var _continue_button: Button = $MenuButtons/ContinueButton
@onready var _settings_button: Button = $MenuButtons/SettingsButton
@onready var _credits_button: Button = $MenuButtons/CreditsButton
@onready var _quit_button: Button = $MenuButtons/QuitButton

@onready var _tutorial_prompt: Control = $TutorialPrompt
@onready var _tutorial_yes_button: Button = $TutorialPrompt/PromptPanel/PromptContent/PromptButtons/YesButton
@onready var _tutorial_skip_button: Button = $TutorialPrompt/PromptPanel/PromptContent/PromptButtons/SkipButton

@onready var _settings_panel: Control = $SettingsPanel
@onready var _master_slider: HSlider = $SettingsPanel/SettingsContainer/SettingsVBox/AudioSection/MasterVolumeSlider
@onready var _bgm_slider: HSlider = $SettingsPanel/SettingsContainer/SettingsVBox/AudioSection/BGMVolumeSlider
@onready var _sfx_slider: HSlider = $SettingsPanel/SettingsContainer/SettingsVBox/AudioSection/SFXVolumeSlider
@onready var _close_settings_button: Button = $SettingsPanel/SettingsContainer/SettingsVBox/CloseSettingsButton

# === 状态 ===
var _has_save_data: bool = false

# === 信号 ===
signal play_requested(start_tutorial: bool)
signal continue_requested()
signal settings_requested()
signal credits_requested()
signal quit_requested()

func _ready() -> void:
    # 设置本地化文本
    _setup_localized_text()

    # 检查是否有存档
    _check_save_data()

    # 连接按钮信号
    _connect_buttons()

    # 加载音量设置
    _load_volume_settings()

    # 播放菜单音乐
    if AudioManager:
        AudioManager.play_bgm("bgm_menu")

    print("[MainMenu] Ready — Has save: %s" % _has_save_data)

func _setup_localized_text() -> void:
    _title_label.text = LocalizationManager.translate("menu.main.title")
    _play_button.text = LocalizationManager.translate("menu.main.play")
    _continue_button.text = LocalizationManager.translate("menu.main.continue") if _has_save_data else "新游戏"
    _settings_button.text = LocalizationManager.translate("menu.main.settings")
    _quit_button.text = LocalizationManager.translate("menu.main.quit")

    # 版本号
    var version: String = ProjectSettings.get_setting("application/config/version") if ProjectSettings.has_setting("application/config/version") else "0.1.0"
    _version_label.text = "v%s" % version

func _check_save_data() -> void:
    if SaveManager:
        _has_save_data = SaveManager.has_save_data()

    # 显示/隐藏继续按钮
    if _continue_button:
        _continue_button.visible = _has_save_data

func _connect_buttons() -> void:
    _play_button.pressed.connect(_on_play_pressed)
    _continue_button.pressed.connect(_on_continue_pressed)
    _settings_button.pressed.connect(_on_settings_pressed)
    _credits_button.pressed.connect(_on_credits_pressed)
    _quit_button.pressed.connect(_on_quit_pressed)

    _tutorial_yes_button.pressed.connect(_on_tutorial_yes)
    _tutorial_skip_button.pressed.connect(_on_tutorial_skip)

    _master_slider.value_changed.connect(_on_master_volume_changed)
    _bgm_slider.value_changed.connect(_on_bgm_volume_changed)
    _sfx_slider.value_changed.connect(_on_sfx_volume_changed)
    _close_settings_button.pressed.connect(_on_close_settings)

func _load_volume_settings() -> void:
    if AudioManager:
        _master_slider.value = AudioManager.get_master_volume()
        _bgm_slider.value = AudioManager.get_bgm_volume()
        _sfx_slider.value = AudioManager.get_sfx_volume()

# === 按钮回调 ===

func _on_play_pressed() -> void:
    AudioManager.play_sfx("ui_click")

    # 检查是否需要显示教程提示
    if SaveManager and SaveManager.has_setting("tutorial_completed"):
        if not SaveManager.get_setting("tutorial_completed", false):
            _show_tutorial_prompt()
        else:
            play_requested.emit(false)
    else:
        _show_tutorial_prompt()

func _on_continue_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    continue_requested.emit()

func _on_settings_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    _show_settings()

func _on_credits_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    credits_requested.emit()

func _on_quit_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    quit_requested.emit()

# === 教程提示 ===

func _show_tutorial_prompt() -> void:
    _tutorial_prompt.visible = true

func _hide_tutorial_prompt() -> void:
    _tutorial_prompt.visible = false

func _on_tutorial_yes() -> void:
    AudioManager.play_sfx("ui_confirm")
    _hide_tutorial_prompt()
    play_requested.emit(true)

func _on_tutorial_skip() -> void:
    AudioManager.play_sfx("ui_cancel")
    _hide_tutorial_prompt()
    play_requested.emit(false)

# === 设置面板 ===

func _show_settings() -> void:
    _settings_panel.visible = true

func _hide_settings() -> void:
    _settings_panel.visible = false

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
    if event.is_action_pressed("ui_cancel"):
        if _settings_panel.visible:
            _hide_settings()
        elif _tutorial_prompt.visible:
            _hide_tutorial_prompt()
        get_viewport().set_input_as_handled()

# === 公共 API ===

func show_menu() -> void:
    visible = true
    _check_save_data()
    AudioManager.play_bgm("bgm_menu")

func hide_menu() -> void:
    visible = false