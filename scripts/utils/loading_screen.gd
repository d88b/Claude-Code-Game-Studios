class_name LoadingScreen
extends Control

## Loading 场景 — 场景切换时的过渡画面

@onready var progress_bar: ProgressBar = $ProgressBar
@onready var label: Label = $LoadLabel
@onready var title_label: Label = $TitleLabel

func _ready():
	progress_bar.value = 0.0
	label.text = "正在加载..."
	title_label.text = "深海堡垒"

	# 从 root 元数据获取目标场景
	var target = ""
	if get_tree().root.has_meta("loading_target"):
		target = get_tree().root.get_meta("loading_target")

	if target == "play_scene":
		label.text = "正在进入海域..."
		_load_and_go("res://scenes/play_scene.tscn")
	elif target == "home":
		label.text = "返回主菜单..."
		_load_and_go("res://scenes/home_scene.tscn")
	else:
		label.text = "加载中..."
		_load_and_go("res://scenes/home_scene.tscn")

func _load_and_go(scene_path: String):
	# 进度条动画
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 100.0, 1.2).set_ease(Tween.EASE_IN_OUT)
	await tween.finished

	# 切换到目标场景
	get_tree().change_scene_to_file(scene_path)
