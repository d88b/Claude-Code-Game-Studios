class_name PatrolEnemy
extends Enemy

## 巡逻型敌人 — 在固定路径上来回巡逻，靠近时反击

@export var patrol_distance: float = 150.0

var patrol_start: Vector2
var patrol_progress: float = 0.0

func _ready():
	super._ready()
	patrol_start = position
	use_gravity = false

func _process(delta: float):
	if is_dead: return

	super._process(delta)

	# 检查是否有目标靠近
	var player = get_tree().get_first_node_in_group("player")
	if player and not player.is_dead:
		var distance = global_position.distance_to(player.global_position)
		if distance <= aggro_range:
			target = player
			_attack_target()
			return

	target = null

	# 来回巡逻
	patrol_progress += patrol_direction * speed * delta

	if patrol_progress > patrol_distance or patrol_progress < -patrol_distance:
		patrol_direction *= -1

	position.x += patrol_direction * speed * delta

	if patrol_direction < 0 and animated_sprite:
		animated_sprite.flip_h = true
	elif patrol_direction > 0 and animated_sprite:
		animated_sprite.flip_h = false

	if abs(patrol_direction) > 0:
		_play_animation("walk")
	else:
		_play_animation("idle")
