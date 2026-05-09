class_name Turret
extends Node2D

## 基础炮台 — 自动瞄准并射击最近敌人

@export var fire_rate: float = 1.0
@export var range: float = 400.0
@export var damage: float = 25.0
@export var projectile_scene: PackedScene

var fire_timer: float = 0.0
var target: Enemy = null
var is_aiming: bool = false

signal turret_fired(turret: Turret)
signal target_locked(target: Enemy)

func _process(delta: float):
	fire_timer += delta
	target = _find_nearest_enemy()

	if target:
		is_aiming = true
		_rotate_towards_target()
		EventBus.target_locked.emit(target)

		if fire_timer >= fire_rate and projectile_scene:
			_fire()
			fire_timer = 0.0
	else:
		is_aiming = false

func _find_nearest_enemy() -> Enemy:
	var enemies = get_tree().get_nodes_in_group("enemy")
	var nearest: Enemy = null
	var nearest_dist = range

	for node in enemies:
		var enemy = node as Enemy
		if enemy and not enemy.is_dead:
			var dist = global_position.distance_to(enemy.global_position)
			if dist < nearest_dist:
				nearest_dist = dist
				nearest = enemy

	return nearest

func _rotate_towards_target():
	if not target: return
	var direction = target.global_position - global_position
	rotation = direction.angle()

func _fire():
	if not target or not projectile_scene: return

	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.set_direction(target.global_position - global_position)
	projectile.set_damage(damage)

	EventBus.turret_fired.emit(self)
