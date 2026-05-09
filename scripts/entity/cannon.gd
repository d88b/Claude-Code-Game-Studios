class_name Cannon
extends Node2D

## 船侧炮 — 向船体侧面发射，射程较短，伤害较高

@export var fire_rate: float = 2.0
@export var range: float = 300.0
@export var damage: float = 40.0
@export var projectile_scene: PackedScene

var fire_timer: float = 0.0
var target: Enemy = null

signal cannon_fired(cannon: Cannon)

func _process(delta: float):
	fire_timer += delta
	target = _find_nearest_enemy()

	if target and fire_timer >= fire_rate and projectile_scene:
		_fire()
		fire_timer = 0.0

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

func _fire():
	if not target or not projectile_scene: return

	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	projectile.global_position = global_position
	projectile.set_direction(target.global_position - global_position)
	projectile.set_damage(damage)

	cannon_fired.emit(self)
