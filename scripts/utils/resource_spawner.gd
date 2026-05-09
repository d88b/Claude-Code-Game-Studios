class_name ResourceSpawner
extends Node

## 海底资源点生成器 — 在潜艇下潜区域程序化生成资源

@export var iron_ore_resource: ItemData
@export var deep_sea_ore_resource: ItemData
@export var bio_sample_resource: ItemData
@export var pickup_scene: PackedScene

## 在指定区域内生成资源点
func spawn_resources(world_width: int, surface_y: float, max_depth: float) -> void:
	if not pickup_scene:
		print("[ResourceSpawner] 警告：拾取场景未设置")
		return

	var iron_count = 15
	var deep_sea_count = 10
	var bio_count = 5

	for i in range(iron_count):
		_spawn_pickup(iron_ore_resource, world_width, surface_y, max_depth * 0.5)

	for i in range(deep_sea_count):
		_spawn_pickup(deep_sea_ore_resource, world_width, surface_y + max_depth * 0.3, max_depth * 0.4)

	for i in range(bio_count):
		_spawn_pickup(bio_sample_resource, world_width, surface_y + max_depth * 0.7, max_depth * 0.3)

	print("[ResourceSpawner] 资源点已生成: 铁矿x%d, 深海矿x%d, 生物样本x%d" % [iron_count, deep_sea_count, bio_count])

func _spawn_pickup(item: ItemData, world_width: int, base_y: float, depth_range: float) -> void:
	var pickup = pickup_scene.instantiate() as ItemPickup
	pickup.item_data = item
	pickup.amount = randi_range(1, 3)
	pickup.position = Vector2(randf_range(-world_width, world_width), base_y + randf_range(0, depth_range))
	add_child(pickup)
