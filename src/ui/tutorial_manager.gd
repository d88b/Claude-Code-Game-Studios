# TutorialManager — 新手教程管理器
# 引导新玩家理解核心玩法：战车驾驶、挖掘建造、尸潮防守
# Design: production/store/TUTORIAL_DESIGN.md

extends Node

# === 信号 ===
signal tutorial_step_completed(step_id: int)
signal tutorial_phase_completed(phase_id: int)
signal tutorial_completed()
signal tutorial_skipped()

# === 阶段枚举 ===
enum Phase { BASICS, SYSTEMS, FIRST_EXPLORE, COMPLETE }

# === 状态 ===
var _current_phase: Phase = Phase.BASICS
var _current_step: int = 0
var _is_active: bool = false
var _is_paused: bool = false

# === 教程数据 ===
var _tutorial_data: Array[Dictionary] = [
    # Phase 0: Basics (2-3分钟)
    {
        "phase": Phase.BASICS,
        "title": "基础操作",
        "steps": [
            {
                "id": 0,
                "key": "tutorial.move",
                "text": "使用 WASD 键移动战车",
                "action": "move",
                "highlight": "vehicle",
                "required_input": "move"
            },
            {
                "id": 1,
                "key": "tutorial.fire",
                "text": "点击鼠标左键射击",
                "action": "fire",
                "highlight": "turret",
                "target_position": Vector2(100, 100),
                "required_input": "fire"
            },
            {
                "id": 2,
                "key": "tutorial.dig",
                "text": "按 E 键挖掘方块",
                "action": "dig",
                "highlight": "block",
                "target_block": Vector2i(5, 5),
                "required_input": "dig"
            },
            {
                "id": 3,
                "key": "tutorial.place",
                "text": "按 Q 键放置设施",
                "action": "place",
                "highlight": "build_area",
                "target_position": Vector2(200, 200),
                "required_input": "place"
            }
        ]
    },
    # Phase 1: Systems (5-10分钟)
    {
        "phase": Phase.SYSTEMS,
        "title": "核心系统",
        "steps": [
            {
                "id": 0,
                "key": "tutorial.hp_mp",
                "text": "HP 是生命值，MP 是魔能",
                "action": "show_hud",
                "highlight": "hud"
            },
            {
                "id": 1,
                "key": "tutorial.daynight",
                "text": "夜晚更危险，尽快返回",
                "action": "show_time",
                "highlight": "time_bar"
            },
            {
                "id": 2,
                "key": "tutorial.resources",
                "text": "收集资源用于建造",
                "action": "collect",
                "highlight": "drop_item",
                "wait_for_event": "resource_collected"
            },
            {
                "id": 3,
                "key": "tutorial.return",
                "text": "按 R 键返回地堡",
                "action": "retreat",
                "highlight": "retreat_button",
                "required_input": "return"
            }
        ]
    },
    # Phase 2: First Explore (10-15分钟)
    {
        "phase": Phase.FIRST_EXPLORE,
        "title": "首次探索",
        "steps": [
            {
                "id": 0,
                "key": "tutorial.explore_start",
                "text": "出发探索世界",
                "action": "explore_start",
                "highlight": "exit_bunker"
            },
            {
                "id": 1,
                "key": "tutorial.collect_resources",
                "text": "搜集足够的资源",
                "action": "collect_target",
                "target_resources": {"crystal": 10, "metal": 5},
                "wait_for_event": "explore_resource_target"
            },
            {
                "id": 2,
                "key": "tutorial.encounter_enemy",
                "text": "遭遇敌人，使用射击消灭",
                "action": "combat",
                "highlight": "enemy_zone",
                "wait_for_event": "enemy_killed"
            },
            {
                "id": 3,
                "key": "tutorial.safe_return",
                "text": "在夜晚前安全返回",
                "action": "return_safe",
                "highlight": "bunker",
                "time_warning": true,
                "required_input": "return"
            }
        ]
    }
]

# === UI 引用 ===
var _tutorial_ui: Control = null
var _highlight_overlay: Control = null

# === 进度追踪 ===
var _completed_steps: Array[int] = []
var _step_start_time: float = 0.0

func _ready() -> void:
    # 检查是否需要显示教程
    if _should_show_tutorial():
        _setup_tutorial_ui()

    print("[TutorialManager] Initialized — Tutorial status: %s" % ("needed" if _should_show_tutorial() else "completed"))

# === 启动条件 ===

func _should_show_tutorial() -> bool:
    # 检查保存数据中是否有教程完成标记
    if SaveManager and SaveManager.has_setting("tutorial_completed"):
        return not SaveManager.get_setting("tutorial_completed", false)

    # 新玩家，需要教程
    return true

func _setup_tutorial_ui() -> void:
    # 创建教程 UI（如果不存在）
    # 实际 UI 应在场景中预置
    pass

# === 教程控制 ===

func start_tutorial() -> void:
    _is_active = true
    _current_phase = Phase.BASICS
    _current_step = 0
    _completed_steps.clear()

    _show_current_step()
    AnalyticsManager.tutorial_step(0, false)

    print("[TutorialManager] Tutorial started")

func pause_tutorial() -> void:
    _is_paused = true
    _hide_current_step()

func resume_tutorial() -> void:
    _is_paused = false
    _show_current_step()

func skip_tutorial() -> void:
    _is_active = false
    _mark_tutorial_completed()

    tutorial_skipped.emit()
    AnalyticsManager.tutorial_step(_current_step, true)

    print("[TutorialManager] Tutorial skipped")

func _mark_tutorial_completed() -> void:
    if SaveManager:
        SaveManager.set_setting("tutorial_completed", true)
        SaveManager.save_game()

# === 步骤显示 ===

func _show_current_step() -> void:
    if _current_phase >= _tutorial_data.size():
        _complete_tutorial()
        return

    var phase_data: Dictionary = _tutorial_data[_current_phase]
    var steps: Array = phase_data["steps"]

    if _current_step >= steps.size():
        _complete_phase()
        return

    var step_data: Dictionary = steps[_current_step]
    _step_start_time = Time.get_ticks_msec() / 1000.0

    # 显示提示文本
    var text: String = LocalizationManager.tr(step_data["key"])
    _show_tutorial_prompt(text, step_data)

    # 高亮相关元素
    if step_data.has("highlight"):
        _show_highlight(step_data["highlight"], step_data)

    # 设置等待条件
    if step_data.has("required_input"):
        _wait_for_input(step_data["required_input"])
    elif step_data.has("wait_for_event"):
        _wait_for_event(step_data["wait_for_event"])

func _show_tutorial_prompt(text: String, step_data: Dictionary) -> void:
    # 通过 UI 显示提示
    if _tutorial_ui and _tutorial_ui.has_method("show_prompt"):
        _tutorial_ui.show_prompt(text, step_data)

    # 发送全局信号
    GlobalSignals.emit_signal("tutorial_prompt_shown", text)

func _show_highlight(target: String, step_data: Dictionary) -> void:
    # 高亮指定元素
    if _highlight_overlay and _highlight_overlay.has_method("highlight"):
        _highlight_overlay.highlight(target, step_data)

    GlobalSignals.emit_signal("tutorial_highlight_shown", target)

func _hide_current_step() -> void:
    if _tutorial_ui and _tutorial_ui.has_method("hide_prompt"):
        _tutorial_ui.hide_prompt()

    if _highlight_overlay and _highlight_overlay.has_method("clear"):
        _highlight_overlay.clear()

# === 进度推进 ===

func advance_step() -> void:
    var step_data: Dictionary = _get_current_step_data()

    # 记录完成时间
    var duration: float = Time.get_ticks_msec() / 1000.0 - _step_start_time
    AnalyticsManager.tutorial_step(step_data["id"], false)

    _completed_steps.append(step_data["id"])
    tutorial_step_completed.emit(step_data["id"])

    _current_step += 1

    if _current_step >= _tutorial_data[_current_phase]["steps"].size():
        _complete_phase()
    else:
        _show_current_step()

func _complete_phase() -> void:
    tutorial_phase_completed.emit(_current_phase)

    _current_phase += 1
    _current_step = 0

    if _current_phase >= Phase.COMPLETE:
        _complete_tutorial()
    else:
        _show_current_step()

func _complete_tutorial() -> void:
    _is_active = false
    _mark_tutorial_completed()

    tutorial_completed.emit()
    GlobalSignals.emit_signal("tutorial_completed")

    print("[TutorialManager] Tutorial completed — %d steps" % _completed_steps.size())

# === 输入/事件等待 ===

func _wait_for_input(input_action: String) -> void:
    # 监听输入事件
    # 在 _input 中处理
    pass

func _wait_for_event(event_name: String) -> void:
    # 监听游戏事件
    # 通过 GlobalSignals 连接
    pass

func _input(event: InputEvent) -> void:
    if not _is_active or _is_paused:
        return

    var step_data: Dictionary = _get_current_step_data()
    if not step_data.has("required_input"):
        return

    var required: String = step_data["required_input"]

    # 检查输入匹配
    if _check_input_match(event, required):
        advance_step()

func _check_input_match(event: InputEvent, required: String) -> bool:
    # 移动输入
    if required == "move":
        return event.is_action_pressed("move_up") or \
               event.is_action_pressed("move_down") or \
               event.is_action_pressed("move_left") or \
               event.is_action_pressed("move_right")

    # 其他输入
    return event.is_action_pressed(required)

# === 事件回调 ===

func _on_game_event(event_name: String) -> void:
    if not _is_active or _is_paused:
        return

    var step_data: Dictionary = _get_current_step_data()
    if not step_data.has("wait_for_event"):
        return

    if step_data["wait_for_event"] == event_name:
        advance_step()

# === 辅助 ===

func _get_current_step_data() -> Dictionary:
    if _current_phase >= _tutorial_data.size():
        return {}

    var phase_data: Dictionary = _tutorial_data[_current_phase]
    var steps: Array = phase_data["steps"]

    if _current_step >= steps.size():
        return {}

    return steps[_current_step]

# === 公共 API ===

func is_active() -> bool:
    return _is_active and not _is_paused

func get_current_phase() -> Phase:
    return _current_phase

func get_current_step() -> int:
    return _current_step

func get_phase_title() -> String:
    if _current_phase < _tutorial_data.size():
        return _tutorial_data[_current_phase]["title"]
    return ""

func get_step_progress() -> float:
    var total_steps: int = 0
    for phase in _tutorial_data:
        total_steps += phase["steps"].size()

    var completed: int = _completed_steps.size()
    return float(completed) / float(total_steps)

func set_ui(ui: Control) -> void:
    _tutorial_ui = ui

func set_highlight_overlay(overlay: Control) -> void:
    _highlight_overlay = overlay