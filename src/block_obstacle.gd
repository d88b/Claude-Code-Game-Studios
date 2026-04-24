# block_obstacle.gd
# 阻挡障碍物 — 物理碰撞，战车无法穿过
extends StaticBody2D

func _ready() -> void:
	add_to_group("block_obstacles")
	print("[BlockObstacle] 阻挡障碍物初始化 at position: ", position)