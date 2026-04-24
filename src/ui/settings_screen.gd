# SettingsScreen — 设置界面
# 音频设置、画面设置、游戏设置、隐私设置
# Design: design/ux/main-menu.md settings section

extends Control

# === 节点引用 ===
@onready var _close_button: Button = $SettingsContainer/CloseButton
@onready var _master_slider: HSlider = $SettingsContainer/VBoxContainer/AudioSection/MasterSlider
@onready var _bgm_slider: HSlider = $SettingsContainer/VBoxContainer/AudioSection/BGMSlider
@onready var _sfx_slider: HSlider = $SettingsContainer/VBoxContainer/AudioSection/SFXSlider
@onready var _analytics_checkbox: CheckBox = $SettingsContainer/VBoxContainer/PrivacySection/AnalyticsCheckBox

# === 信号 ===
signal settings_closed()

func _ready() -> void:
    _setup_localized_text()
    _connect_signals()
    _load_settings()

func _setup_localized_text() -> void:
    # 音频设置标签
    $SettingsContainer/VBoxContainer/TitleLabel.text = LocalizationManager.tr("menu.main.settings")

    $SettingsContainer/VBoxContainer/AudioSection/MasterLabel.text = LocalizationManager.tr("audio.settings.master")
    $SettingsContainer/VBoxContainer/AudioSection/BGMLabel.text = LocalizationManager.tr("audio.settings.bgm")
    $SettingsContainer/VBoxContainer/AudioSection/SFXLabel.text = LocalizationManager.tr("audio.settings.sfx")

    _close_button.text = LocalizationManager.tr("menu.pause.resume")

func _connect_signals() -> void:
    _close_button.pressed.connect(_on_close_pressed)

    _master_slider.value_changed.connect(_on_master_changed)
    _bgm_slider.value_changed.connect(_on_bgm_changed)
    _sfx_slider.value_changed.connect(_on_sfx_changed)

    _analytics_checkbox.toggled.connect(_on_analytics_toggled)

func _load_settings() -> void:
    # 加载音频设置
    if AudioManager:
        _master_slider.value = AudioManager.get_master_volume()
        _bgm_slider.value = AudioManager.get_bgm_volume()
        _sfx_slider.value = AudioManager.get_sfx_volume()

    # 加载隐私设置
    if AnalyticsManager:
        _analytics_checkbox.button_pressed = AnalyticsManager.is_enabled()

# === 音频回调 ===

func _on_master_changed(value: float) -> void:
    AudioManager.play_sfx("ui_click")
    AudioManager.set_master_volume(value)

func _on_bgm_changed(value: float) -> void:
    AudioManager.set_bgm_volume(value)

func _on_sfx_changed(value: float) -> void:
    AudioManager.play_sfx("ui_click")
    AudioManager.set_sfx_volume(value)

# === 隐私回调 ===

func _on_analytics_toggled(enabled: bool) -> void:
    AudioManager.play_sfx("ui_click")
    AnalyticsManager.set_enabled(enabled)

# === 关闭 ===

func _on_close_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    hide()
    settings_closed.emit()

# === 输入 ===

func _input(event: InputEvent) -> void:
    if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
        _on_close_pressed()
        get_viewport().set_input_as_handled()

# === 公共 API ===

func show_settings() -> void:
    show()
    _load_settings()

func hide_settings() -> void:
    hide()