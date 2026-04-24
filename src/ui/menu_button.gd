# MenuButton — 菜单按钮辅助脚本
# 提供统一的按钮样式和交互行为

extends Button

# === 配置 ===
@export var hover_color: Color = Color(1.0, 0.9, 0.5)
@export var normal_color: Color = Color(0.8, 0.8, 0.8)
@export var pressed_color: Color = Color(0.6, 0.6, 0.6)

# === 状态 ===
var _is_hovered: bool = false

func _ready() -> void:
    # 设置初始样式
    _update_style(normal_color)

    # 连接信号
    mouse_entered.connect(_on_mouse_entered)
    mouse_exited.connect(_on_mouse_exited)
    pressed.connect(_on_button_pressed)

func _on_mouse_entered() -> void:
    _is_hovered = true
    _update_style(hover_color)

    # 播放悬停音效
    if AudioManager:
        AudioManager.play_sfx("ui_hover")

func _on_mouse_exited() -> void:
    _is_hovered = false
    _update_style(normal_color)

func _on_button_pressed() -> void:
    _update_style(pressed_color)

    # 等待一帧后恢复
    await get_tree().process_frame
    if _is_hovered:
        _update_style(hover_color)
    else:
        _update_style(normal_color)

func _update_style(color: Color) -> void:
    # 更新文字颜色
    add_theme_color_override("font_color", color)
    add_theme_color_override("font_hover_color", hover_color)
    add_theme_color_override("font_pressed_color", pressed_color)

# === 公共 API ===

func set_text_localized(key: String) -> void:
    text = LocalizationManager.translate(key)