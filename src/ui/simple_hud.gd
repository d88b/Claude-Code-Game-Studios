# simple_hud.gd
# SimpleHUD — 垂直切片简易 HUD
## SimpleHUD — 垂直切片最小 HUD
## 显示：生命值、魔能、时间、日夜阶段、魔能耗尽警告、Elite警告

class_name SimpleHUD extends CanvasLayer

# === UI 节点引用 ===
var _health_bar: ProgressBar = null
var _magic_bar: ProgressBar = null
var _time_label: Label = null
var _phase_label: Label = null
var _warning_label: Label = null
var _elite_warning_label: Label = null  # Elite/Boss 警告标签
var _state_label: Label = null
var _deploy_hint_label: Label = null
var _return_hint_label: Label = null
var _pos_label: Label = null  # 位置显示
var _resource_label: Label = null  # 资源收集显示
var _summary_panel: PanelContainer = null  # 总结面板

# === 资源收集统计 ===
var _resources_collected: Dictionary = {}
var _total_resources: float = 0.0

# === 依赖引用 ===
var _vehicle_attribute: Node = null
var _global_signals: Node = null

# === 初始化 ===

func _ready() -> void:
	_global_signals = GlobalSignals

	# 创建 UI 元素
	_create_ui_elements()

	# 连接全局信号
	_connect_signals()

	print("[SimpleHUD] Initialized")

func _create_ui_elements() -> void:
	# 创建 Control 根节点作为 UI 容器
	var root_control: Control = Control.new()
	root_control.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root_control)

	# 创建容器面板
	var panel: PanelContainer = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
	panel.position = Vector2(10, 10)
	panel.custom_minimum_size = Vector2(300, 200)
	root_control.add_child(panel)

	# 创建 VBoxContainer 作为布局
	var vbox: VBoxContainer = VBoxContainer.new()
	panel.add_child(vbox)

	# === 生命值条 ===
	var health_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(health_hbox)

	var health_title: Label = Label.new()
	health_title.text = "HP:"
	health_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	health_hbox.add_child(health_title)

	_health_bar = ProgressBar.new()
	_health_bar.min_value = 0
	_health_bar.max_value = 100
	_health_bar.value = 100
	_health_bar.show_percentage = false
	_health_bar.custom_minimum_size = Vector2(200, 20)
	health_hbox.add_child(_health_bar)

	# === 魔能条 ===
	var magic_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(magic_hbox)

	var magic_title: Label = Label.new()
	magic_title.text = "MP:"
	magic_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	magic_hbox.add_child(magic_title)

	_magic_bar = ProgressBar.new()
	_magic_bar.min_value = 0
	_magic_bar.max_value = 100
	_magic_bar.value = 100
	_magic_bar.show_percentage = false
	_magic_bar.custom_minimum_size = Vector2(200, 20)
	magic_hbox.add_child(_magic_bar)

	# === 时间显示 ===
	var time_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(time_hbox)

	var time_title: Label = Label.new()
	time_title.text = LocalizationManager.tr("ui.hud.time_title")
	time_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	time_hbox.add_child(time_title)

	_time_label = Label.new()
	_time_label.text = LocalizationManager.tr_format("ui.hud.time_format", {"hour": "7"})
	_time_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	time_hbox.add_child(_time_label)

	# === 阶段显示 ===
	var phase_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(phase_hbox)

	var phase_title: Label = Label.new()
	phase_title.text = LocalizationManager.tr("ui.hud.phase_title")
	phase_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	phase_hbox.add_child(phase_title)

	_phase_label = Label.new()
	_phase_label.text = LocalizationManager.tr("ui.hud.phase.day")
	_phase_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	phase_hbox.add_child(_phase_label)

	# === 状态显示 ===
	var state_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(state_hbox)

	var state_title: Label = Label.new()
	state_title.text = LocalizationManager.tr("ui.hud.state_title")
	state_title.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	state_hbox.add_child(state_title)

	_state_label = Label.new()
	_state_label.text = LocalizationManager.tr("ui.hud.state.bunker")
	_state_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1, 1))
	state_hbox.add_child(_state_label)

	# === 魔能耗尽警告 ===
	_warning_label = Label.new()
	_warning_label.text = LocalizationManager.tr("ui.hud.warning.magic_depleted_speed")
	_warning_label.modulate = Color(1, 0.3, 0.3, 1)
	_warning_label.visible = false
	vbox.add_child(_warning_label)

	# === Elite/Boss 警告 ===
	_elite_warning_label = Label.new()
	_elite_warning_label.text = LocalizationManager.tr("ui.hud.warning.elite_appear")
	_elite_warning_label.modulate = Color(1, 0.5, 0, 1)  # 橙色警告
	_elite_warning_label.visible = false
	vbox.add_child(_elite_warning_label)

	# === 操作提示 ===
	_deploy_hint_label = Label.new()
	_deploy_hint_label.text = LocalizationManager.tr("ui.hud.deploy_hint")
	_deploy_hint_label.add_theme_color_override("font_color", Color(0.7, 1, 0.7, 1))
	vbox.add_child(_deploy_hint_label)

	_return_hint_label = Label.new()
	_return_hint_label.text = LocalizationManager.tr("ui.hud.return_hint")
	_return_hint_label.add_theme_color_override("font_color", Color(0.7, 0.7, 1, 1))
	_return_hint_label.visible = false
	vbox.add_child(_return_hint_label)

	# === 位置显示 ===
	var pos_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(pos_hbox)

	var pos_title: Label = Label.new()
	pos_title.text = "位置:"
	pos_title.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
	pos_hbox.add_child(pos_title)

	_pos_label = Label.new()
	_pos_label.text = "(0, 0)"
	_pos_label.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
	pos_hbox.add_child(_pos_label)

	# === 资源收集显示 ===
	var resource_hbox: HBoxContainer = HBoxContainer.new()
	vbox.add_child(resource_hbox)

	var resource_title: Label = Label.new()
	resource_title.text = "收集:"
	resource_title.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
	resource_hbox.add_child(resource_title)

	_resource_label = Label.new()
	_resource_label.text = "0"
	_resource_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
	resource_hbox.add_child(_resource_label)

func _connect_signals() -> void:
	if _global_signals != null:
		# 连接时间信号
		_global_signals.time_hour_changed.connect(_on_hour_changed)
		_global_signals.day_phase_changed.connect(_on_phase_changed)

		# 连接魔能信号
		_global_signals.magic_pool_changed.connect(_on_magic_changed)
		_global_signals.magic_depleted.connect(_on_magic_depleted)

		# 连接生命值信号（如果有战车）
		_global_signals.vehicle_damaged.connect(_on_vehicle_damaged)

		# 连接资源收集信号
		_global_signals.resource_collected.connect(_on_resource_collected)

		# 连接 Elite 警告信号
		_global_signals.elite_spawned.connect(_on_elite_spawned)

func _exit_tree() -> void:
	# 断开信号连接
	if _global_signals != null:
		if _global_signals.time_hour_changed.is_connected(_on_hour_changed):
			_global_signals.time_hour_changed.disconnect(_on_hour_changed)
		if _global_signals.day_phase_changed.is_connected(_on_phase_changed):
			_global_signals.day_phase_changed.disconnect(_on_phase_changed)
		if _global_signals.magic_pool_changed.is_connected(_on_magic_changed):
			_global_signals.magic_pool_changed.disconnect(_on_magic_changed)
		if _global_signals.magic_depleted.is_connected(_on_magic_depleted):
			_global_signals.magic_depleted.disconnect(_on_magic_depleted)
		if _global_signals.resource_collected.is_connected(_on_resource_collected):
			_global_signals.resource_collected.disconnect(_on_resource_collected)
		if _global_signals.elite_spawned.is_connected(_on_elite_spawned):
			_global_signals.elite_spawned.disconnect(_on_elite_spawned)

# === 设置战车引用 ===

func set_vehicle_attribute(vehicle_attr: Node) -> void:
	_vehicle_attribute = vehicle_attr

	if _vehicle_attribute != null:
		# 初始化显示值
		_health_bar.max_value = _vehicle_attribute.max_health
		_health_bar.value = _vehicle_attribute.current_health
		_magic_bar.max_value = _vehicle_attribute.max_magic
		_magic_bar.value = _vehicle_attribute.current_magic

		# 连接战车局部信号
		_vehicle_attribute.health_changed.connect(_on_health_changed_local)
		_vehicle_attribute.magic_changed.connect(_on_magic_changed_local)

func clear_vehicle_attribute() -> void:
	if _vehicle_attribute != null:
		if _vehicle_attribute.health_changed.is_connected(_on_health_changed_local):
			_vehicle_attribute.health_changed.disconnect(_on_health_changed_local)
		if _vehicle_attribute.magic_changed.is_connected(_on_magic_changed_local):
			_vehicle_attribute.magic_changed.disconnect(_on_magic_changed_local)
	_vehicle_attribute = null

	# 重置显示
	_health_bar.value = 100
	_magic_bar.value = 100
	_warning_label.visible = false

# === 信号回调 ===

func _on_hour_changed(hour: int) -> void:
	_time_label.text = LocalizationManager.tr_format("ui.hud.time_format", {"hour": str(hour)})

func _on_phase_changed(phase: int) -> void:
	var phase_keys: Array = ["ui.hud.phase.dawn", "ui.hud.phase.day", "ui.hud.phase.dusk", "ui.hud.phase.night"]
	_phase_label.text = LocalizationManager.tr(phase_keys[phase]) if phase < phase_keys.size() else "?"

func _on_magic_changed(current: float, max_magic: float) -> void:
	_magic_bar.max_value = max_magic
	_magic_bar.value = current

	# 检查是否脱离耗尽状态
	if current / max_magic >= 0.1:
		_warning_label.visible = false

func _on_magic_depleted() -> void:
	_warning_label.visible = true

func _on_elite_spawned(enemy_id: int, tier: int) -> void:
	# 显示 Elite 警告，3 秒后自动隐藏
	_elite_warning_label.visible = true

	# 根据 tier 更新警告文本
	if tier >= 3:  # Boss tier
		_elite_warning_label.text = LocalizationManager.tr("ui.hud.warning.boss_appear")
		_elite_warning_label.modulate = Color(1, 0.2, 0.2, 1)  # 红色（更高危险）
	else:
		_elite_warning_label.text = LocalizationManager.tr("ui.hud.warning.elite_appear")

	# 3 秒后隐藏警告
	await get_tree().create_timer(3.0).timeout
	_elite_warning_label.visible = false

func _on_vehicle_damaged(amount: float) -> void:
	# 从战车属性更新生命值显示
	if _vehicle_attribute != null:
		_health_bar.value = _vehicle_attribute.current_health

func _on_health_changed_local(current: float, max_health: float) -> void:
	_health_bar.max_value = max_health
	_health_bar.value = current

func _on_magic_changed_local(current: float, max_magic: float) -> void:
	_magic_bar.max_value = max_magic
	_magic_bar.value = current

# === 状态更新 ===

func set_game_state(state_name: String) -> void:
	_state_label.text = state_name

	# 根据状态切换提示显示
	_deploy_hint_label.visible = (state_name == "BUNKER")
	_return_hint_label.visible = (state_name == "EXPLORING")

	# 显示/隐藏总结面板
	if state_name == "SUMMARY":
		_show_summary()
	else:
		_hide_summary()

# === 位置更新 ===

func update_position(pos: Vector2) -> void:
	if _pos_label != null:
		_pos_label.text = "(%.0f, %.0f)" % [pos.x, pos.y]

# === 资源收集 ===

func _on_resource_collected(resource_id: int, quantity: float) -> void:
	if not _resources_collected.has(resource_id):
		_resources_collected[resource_id] = 0.0
	_resources_collected[resource_id] += quantity
	_total_resources += quantity

	# 更新显示
	if _resource_label != null:
		_resource_label.text = "%.0f" % _total_resources

	print("[SimpleHUD] 资源收集更新 — total=", _total_resources)

# === 总结面板 ===

func _show_summary() -> void:
	if _summary_panel != null:
		_summary_panel.visible = true
		return

	# 创建总结面板
	_create_summary_panel()

func _create_summary_panel() -> void:
	var root_control: Control = get_child(0)
	if root_control == null:
		return

	# 总结面板（居中显示）
	_summary_panel = PanelContainer.new()
	_summary_panel.set_anchors_preset(Control.PRESET_CENTER)
	_summary_panel.position = Vector2(-200, -150)
	_summary_panel.custom_minimum_size = Vector2(400, 300)
	root_control.add_child(_summary_panel)

	var vbox: VBoxContainer = VBoxContainer.new()
	_summary_panel.add_child(vbox)

	# 标题
	var title: Label = Label.new()
	title.text = "=== 探索结束 ==="
	title.add_theme_color_override("font_color", Color(1, 0.9, 0.5, 1))
	vbox.add_child(title)

	# 分隔线
	var sep1: HSeparator = HSeparator.new()
	vbox.add_child(sep1)

	# 资源收集统计
	var resource_title: Label = Label.new()
	resource_title.text = "资源收集:"
	resource_title.add_theme_color_override("font_color", Color(0.7, 1, 0.7, 1))
	vbox.add_child(resource_title)

	# 各类资源详情
	var resource_names: Array = ["木材", "石头", "铁矿", "水晶", "魔能碎片"]
	for i in range(5):
		var qty: float = _resources_collected.get(i, 0.0)
		if qty > 0:
			var detail: Label = Label.new()
			detail.text = "  %s: %.0f" % [resource_names[i], qty]
			detail.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))
			vbox.add_child(detail)

	# 总计
	var total_label: Label = Label.new()
	total_label.text = LocalizationManager.tr_format("ui.summary.total_format", {"total": str("%.0f" % _total_resources)})
	total_label.add_theme_color_override("font_color", Color(1, 1, 0.5, 1))
	vbox.add_child(total_label)

	# 分隔线
	var sep2: HSeparator = HSeparator.new()
	vbox.add_child(sep2)

	# 继续提示
	var continue_hint: Label = Label.new()
	continue_hint.text = LocalizationManager.tr("ui.summary.continue_hint")
	continue_hint.add_theme_color_override("font_color", Color(0.7, 1, 0.7, 1))
	vbox.add_child(continue_hint)

	print("[SimpleHUD] 总结面板显示 — total=", _total_resources)

func _hide_summary() -> void:
	if _summary_panel != null:
		_summary_panel.visible = false

	# 重置资源计数（准备下一次探索）
	if _state_label.text == "BUNKER":
		_resources_collected.clear()
		_total_resources = 0.0
		if _resource_label != null:
			_resource_label.text = "0"