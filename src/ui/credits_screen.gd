# CreditsScreen — Credits 滚动界面
# 自动滚动显示开发团队、工具技术、法律信息
# Design: production/store/CREDITS_DESIGN.md

extends Control

# === 节点引用 ===
@onready var _scroll_container: ScrollContainer = $ScrollContainer
@onready var _vbox: VBoxContainer = $ScrollContainer/VBoxContainer
@onready var _skip_button: Button = $SkipButton
@onready var _title_label: Label = $ScrollContainer/VBoxContainer/TitleLabel
@onready var _version_label: Label = $ScrollContainer/VBoxContainer/VersionLabel

# === 配置 ===
const SCROLL_SPEED: float = 50.0  # pixels per second
const SCROLL_PAUSE_AT_TOP: float = 2.0  # 开始前暂停
const SCROLL_PAUSE_AT_END: float = 3.0  # 结束后暂停

# === 状态 ===
var _is_scrolling: bool = false
var _scroll_timer: float = 0.0
var _pause_timer: float = 0.0
var _at_bottom: bool = false
var _auto_close: bool = true

# === 信号 ===
signal credits_completed()

func _ready() -> void:
    # 设置跳过按钮
    if _skip_button:
        _skip_button.pressed.connect(_on_skip_pressed)
        _skip_button.text = LocalizationManager.translate("credits.skip")

    # 初始化显示
    _setup_credits_content()

    # 开始滚动前的暂停
    _pause_timer = SCROLL_PAUSE_AT_TOP

    print("[CreditsScreen] Ready")

func _process(delta: float) -> void:
    # 暂停阶段
    if _pause_timer > 0:
        _pause_timer -= delta
        if _pause_timer <= 0:
            _is_scrolling = true
        return

    # 滚动阶段
    if _is_scrolling and not _at_bottom:
        _scroll_container.scroll_vertical += int(SCROLL_SPEED * delta)

        # 检测底部
        if _scroll_container.scroll_vertical >= _scroll_container.get_scroll_max():
            _at_bottom = true
            _is_scrolling = false
            _pause_timer = SCROLL_PAUSE_AT_END

    # 结束阶段
    if _at_bottom and _pause_timer <= 0:
        _on_credits_complete()

func _setup_credits_content() -> void:
    # 设置标题
    if _title_label:
        _title_label.text = LocalizationManager.translate("credits.title")
        _title_label.add_theme_font_size_override("font_size", 48)

    if _version_label:
        _version_label.text = LocalizationManager.translate("credits.version")

    # 添加各部分内容
    _add_section_header(LocalizationManager.translate("credits.development"))
    _add_content_block([
        LocalizationManager.translate("credits.game_design") + "\n[Game Designer]",
        LocalizationManager.translate("credits.programming") + "\n[Programmer]",
        LocalizationManager.translate("credits.art") + "\n[Artist]",
        LocalizationManager.translate("credits.audio") + "\n[Sound Designer]",
        LocalizationManager.translate("credits.qa") + "\n[QA Tester]"
    ])

    _add_section_header(LocalizationManager.translate("credits.tools"))
    _add_content_block([
        LocalizationManager.translate("credits.engine") + "\nGodot 4.6",
        LocalizationManager.translate("credits.testing") + "\nGUT (Godot Unit Testing)",
        LocalizationManager.translate("credits.special_thanks") + "\nGodot Community\nGUT Contributors"
    ])

    _add_section_header(LocalizationManager.translate("credits.legal"))
    _add_content_block([
        LocalizationManager.translate("credits.eula") + "\nlegal/EULA.md",
        LocalizationManager.translate("credits.privacy") + "\nlegal/PRIVACY_POLICY.md",
        LocalizationManager.translate("credits.age_ratings") + "\nESRB Teen, PEGI 12"
    ])

    # 结尾感谢
    _add_section_header(LocalizationManager.translate("credits.thanks"))
    _add_content_block([
        LocalizationManager.translate("credits.game_name_zh"),
        LocalizationManager.translate("credits.game_name_en"),
        LocalizationManager.translate("credits.website")
    ])

func _add_section_header(text: String) -> void:
    var label: Label = Label.new()
    label.text = text
    label.add_theme_font_size_override("font_size", 32)
    label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))  # 金色
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

    # 上方间距
    _vbox.add_spacer(true)
    _vbox.add_child(label)
    _vbox.add_spacer(false)

func _add_content_block(lines: Array) -> void:
    for line in lines:
        var label: Label = Label.new()
        label.text = line
        label.add_theme_font_size_override("font_size", 24)
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.autowrap_mode = TextServer.AUTOWRAP_WORD
        _vbox.add_child(label)

func _on_skip_pressed() -> void:
    _on_credits_complete()

func _on_credits_complete() -> void:
    credits_completed.emit()

    if _auto_close:
        hide()
        # 返回主菜单
        GlobalSignals.emit_signal("credits_finished")

func _input(event: InputEvent) -> void:
    # ESC 或任意键跳过
    if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
        _on_skip_pressed()
        get_viewport().set_input_as_handled()

# === 公共 API ===

func start_credits() -> void:
    show()
    _scroll_container.scroll_vertical = 0
    _is_scrolling = false
    _at_bottom = false
    _pause_timer = SCROLL_PAUSE_AT_TOP

func set_auto_close(auto: bool) -> void:
    _auto_close = auto

func set_scroll_speed(speed: float) -> void:
    SCROLL_SPEED = speed