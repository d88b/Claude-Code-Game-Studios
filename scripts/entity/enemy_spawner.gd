class_name EnemySpawner
extends Node

## 敌人生成器 — 跟随目标（船）移动，在指定区域生成敌人

@export var packed_enemies: Array[PackedScene] = []
@export var spawn_interval: float = 3.0
@export var follow_target: Node2D = null
@export var max_active_enemies: int = 8

@export var min_spawn_radius: float = 300
@export var max_spawn_radius: float = 500
@export var spawn_depth_offset: float = 0.0  # 水下深度偏移（正值=更深）

var spawn_timer: float = 0.0

func _process(delta: float):
	if packed_enemies.is_empty(): return

	spawn_timer += delta

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0

		var active_count = get_tree().get_nodes_in_group("enemy").size()
		if active_count < max_active_enemies:
			spawn_enemy()

func spawn_enemy():
	if packed_enemies.is_empty(): return

	var idx = randi() % packed_enemies.size()
	var enemy_scene = packed_enemies[idx]
	if not enemy_scene: return

	var enemy = enemy_scene.instantiate() as Enemy

	var spawn_radius = randf_range(min_spawn_radius, max_spawn_radius)
	var dir = Vector2(randf_range(-1.0, 1.0), randf_range(-0.3, 0.3)).normalized()
	var spawn_pos = dir * spawn_radius

	if follow_target:
		spawn_pos += follow_target.global_position

	spawn_pos.y += spawn_depth_offset
	enemy.global_position = spawn_pos

	get_parent().add_child(enemy)
