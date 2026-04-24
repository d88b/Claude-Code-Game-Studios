# obstacle.gd
# 障碍物 — 用于碰撞测试
extends StaticBody2D

func _ready() -> void:
	add_to_group("obstacles")
	print("[Obstacle] Added to obstacles group at position: ", position)