extends Node

var packed_play_scene: PackedScene = preload("res://scenes/play_scene.tscn")
var packed_home_scene: PackedScene = preload("res://scenes/home_scene.tscn")
var packed_loading_scene: PackedScene = preload("res://scenes/loading_scene.tscn")

func _ready():
	pass

func go_to_play_scene():
	get_tree().root.set_meta("loading_target", "play_scene")
	get_tree().change_scene_to_packed(packed_loading_scene)

func go_to_home_scene():
	get_tree().root.set_meta("loading_target", "home")
	get_tree().change_scene_to_packed(packed_loading_scene)
