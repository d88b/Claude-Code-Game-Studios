class_name ChaserEnemy
extends Enemy

## 追击型敌人 — 主动追击目标并攻击

func _ready():
	super._ready()
	# 追击型敌人默认无重力（水面漂浮）
	use_gravity = false

func _process(delta: float):
	if is_dead: return

	super._process(delta)

	target = _find_target()

	if target:
		var distance = global_position.distance_to(target.global_position)
		if distance <= aggro_range:
			is_chasing = true

		if is_chasing:
			if distance > attack_range:
				_move_towards_target(delta)
			else:
				_attack_target()
	else:
		is_chasing = false

	# 动画
	if is_chasing:
		_play_animation("walk")
	else:
		_play_animation("idle")
