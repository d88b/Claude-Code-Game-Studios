# slow_zone.gd
# 减速区域 — 战车可以穿过但速度降低
extends Area2D

func _ready() -> void:
	add_to_group("slow_zones")
	print("[SlowZone] 减速区域初始化 at position: ", position)