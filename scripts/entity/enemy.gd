class_name Enemy
extends Entity

## 敌人基类 — 支持水面/水下两种模式，通用攻击系统

@export var use_gravity: bool = true
@export var speed: float = 60.0
@export var stop_distance: float = 30.0
@export var aggro_range: float = 300.0
@export var attack_damage: float = 10.0
@export var attack_range: float = 40.0
@export var attack_cooldown: float = 1.5
@export var hit_particles: CPUParticles2D

## 掉落配置
@export var drop_chance: float = 0.5
@export var drop_item: ItemData
@export var drop_amount: int = 1

var target: Node2D = null
var is_chasing: bool = false
var attack_timer: float = 0.0
var memory_timer: float = 0.0
var patrol_direction: float = 1.0
var last_position: Vector2
var current_speed: float = 0.0

func _ready():
	super._ready()
	add_to_group("enemy")
	last_position = position

func _process(delta: float):
	if is_dead: return

	attack_timer = max(0, attack_timer - delta)

	if use_gravity:
		_apply_physics(delta)

func _find_target() -> Node2D:
	var player = get_tree().get_first_node_in_group("player")
	var ship = get_tree().get_first_node_in_group("ship")

	# 优先找玩家，如果没有就找船
	if player and not player.is_dead and not player.in_submarine:
		return player
	if ship:
		return ship

	return null

func _move_towards_target(delta: float):
	if not target: return

	var direction = (target.global_position - global_position).normalized()
	position += direction * speed * delta

	if direction.x != 0:
		if animated_sprite:
			animated_sprite.flip_h = direction.x < 0

func _attack_target():
	if not target or attack_timer > 0: return

	var distance = global_position.distance_to(target.global_position)
	if distance <= attack_range:
		if target.has_method("apply_damage"):
			target.apply_damage(attack_damage)
			attack_timer = attack_cooldown

func _show_damage_taken_effect():
	super._show_damage_taken_effect()

	if hit_particles != null:
		hit_particles.emitting = true

func _on_death():
	# 掉落资源
	if drop_item and randf() < drop_chance:
		var pickup_scene = load("res://scenes/item_pickup.tscn")
		if pickup_scene:
			var pickup = pickup_scene.instantiate() as ItemPickup
			pickup.item_data = drop_item
			pickup.amount = drop_amount
			pickup.position = position
			get_parent().add_child(pickup)

	queue_free()

func _on_animated_sprite_2d_animation_finished():
	if current_anim and current_anim.name == "die":
		_on_death()
