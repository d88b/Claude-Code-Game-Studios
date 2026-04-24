# AchievementNotification — 成就解锁通知弹窗
# 显示解锁成就的名称和描述，自动消失

extends Control

# === 节点引用 ===
@onready var _title_label: Label = $NotificationPanel/VBoxContainer/TitleLabel
@onready var _achievement_name: Label = $NotificationPanel/VBoxContainer/AchievementName
@onready var _achievement_desc: Label = $NotificationPanel/VBoxContainer/AchievementDesc
@onready var _close_button: Button = $NotificationPanel/VBoxContainer/CloseButton

# === 配置 ===
const DISPLAY_DURATION: float = 3.0  # 自动关闭时间
const SLIDE_IN_DURATION: float = 0.3

# === 状态 ===
var _current_achievement_id: String = ""
var _display_timer: float = 0.0
var _is_displaying: bool = false

func _ready() -> void:
    visible = false

    # 连接信号
    _close_button.pressed.connect(_on_close_pressed)

    # 监听成就解锁信号
    AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)

    print("[AchievementNotification] Ready")

func _process(delta: float) -> void:
    if _is_displaying:
        _display_timer -= delta

        if _display_timer <= 0:
            _hide_notification()

func _on_achievement_unlocked(achievement_id: String, achievement_name: String) -> void:
    _show_notification(achievement_id, achievement_name)

func _show_notification(achievement_id: String, achievement_name: String) -> void:
    _current_achievement_id = achievement_id

    # 设置文本
    _title_label.text = LocalizationManager.tr("achievement.unlocked_title")
    _achievement_name.text = achievement_name

    # 获取描述
    var defs: Dictionary = AchievementManager.get_all_achievements()
    var def: Dictionary = defs.get(achievement_id, {})
    _achievement_desc.text = def.get("desc", "")

    # 显示通知
    visible = true
    _is_displaying = true
    _display_timer = DISPLAY_DURATION

    # 播放解锁音效
    AudioManager.play_sfx("ui_success")

    # 滑入动画
    _slide_in()

func _hide_notification() -> void:
    _is_displaying = false
    visible = false

func _slide_in() -> void:
    # 从右侧滑入
    var start_pos: Vector2 = Vector2(1280, 50)
    var end_pos: Vector2 = Vector2(1280 - 300, 50)

    position = start_pos

    var tween: Tween = create_tween()
    tween.tween_property(self, "position", end_pos, SLIDE_IN_DURATION)

func _on_close_pressed() -> void:
    AudioManager.play_sfx("ui_click")
    _hide_notification()

# === 公共 API ===

func show_for_achievement(achievement_id: String) -> void:
    var defs: Dictionary = AchievementManager.get_all_achievements()
    var def: Dictionary = defs.get(achievement_id, {})
    var name: String = def.get("name", achievement_id)

    _show_notification(achievement_id, name)