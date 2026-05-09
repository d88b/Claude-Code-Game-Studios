class_name WaveHUD
extends Control

## 波次 HUD — 显示波次状态、预警、进度

@export var warning_label: Label
@export var active_label: Label
@export var complete_label: Label

var current_state: String = "IDLE"

func _ready():
	EventBus.wave_state_changed.connect(_on_state_changed)
	EventBus.wave_warning.connect(_on_wave_warning)
	EventBus.wave_started.connect(_on_wave_started)
	EventBus.wave_completed.connect(_on_wave_completed)

	_hide_all()

func _on_state_changed(new_state: String):
	current_state = new_state
	_hide_all()

	match current_state:
		"WARNING":
			warning_label.visible = true
		"ACTIVE":
			active_label.visible = true
		"COMPLETE":
			complete_label.visible = true

func _on_wave_warning(wave_num: int, countdown: float):
	warning_label.text = "第 %d 波来袭！准备时间: %d秒" % [wave_num, int(countdown)]

func _on_wave_started(wave_num: int, enemy_count: int):
	active_label.text = "第 %d 波 — 剩余敌人: %d" % [wave_num, enemy_count]

func _on_wave_completed(wave_num: int, reward_text: String):
	complete_label.text = "第 %d 波完成！奖励: %s" % [wave_num, reward_text]

func _hide_all():
	if warning_label: warning_label.visible = false
	if active_label: active_label.visible = false
	if complete_label: complete_label.visible = false
