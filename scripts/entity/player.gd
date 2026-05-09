class_name Player
extends Entity

## 玩家实体 — 深海堡垒版本，在甲板上移动，可进入潜艇

@export var speed: float = 120.0

## 船体跟随：玩家在船上时随船移动
var ship_parent: Ship = null
## 潜艇交互
var current_submarine: Submarine = null
var in_submarine: bool = false

signal player_died(player: Player)

func _ready():
	super._ready()
	add_to_group("player")

	## 查找船体父节点
	await get_tree().process_frame
	for child in get_tree().current_scene.get_children():
		if child is Ship:
			ship_parent = child as Ship
			break

	EventBus.player_in_submarine.connect(_on_submarine_state_changed)
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.player_energy_changed.emit(current_energy, max_energy)

func _process(delta: float):
	if is_dead: return
	if in_submarine: return  # 潜艇内不处理玩家逻辑

	_handle_submarine_interaction(delta)
	_handle_movement(delta)
	_apply_physics(delta)

## 检测附近潜艇并处理进入
func _handle_submarine_interaction(delta: float):
	if in_submarine: return

	var submarines = get_tree().get_nodes_in_group("submarine")
	current_submarine = null

	for node in submarines:
		var sub = node as Submarine
		if sub and not sub.is_dead:
			var dist = global_position.distance_to(sub.global_position)
			if dist < 60.0:
				current_submarine = sub
				break

	if current_submarine and Input.is_action_just_pressed("enter_submarine"):
		current_submarine.enter_submarine(self)

func _on_submarine_state_changed(is_inside: bool):
	in_submarine = is_inside
	if not is_inside:
		current_submarine = null

func _handle_movement(delta: float):
	var horizontal = Input.get_axis("left", "right")

	# 随船移动
	if ship_parent:
		position.x += ship_parent.current_speed * delta

	# 水平移动（相对于船）
	position.x += horizontal * speed * delta

	# 跳跃
	if Input.is_action_just_pressed("jump"):
		_try_jump()

	# 朝向
	if horizontal > 0:
		animated_sprite.flip_h = false
	elif horizontal < 0:
		animated_sprite.flip_h = true

func apply_damage(damage: float) -> bool:
	var can_apply = super.apply_damage(damage)
	if can_apply:
		EventBus.player_health_changed.emit(current_health, max_health)
	return can_apply

func spend_energy(energy: float):
	current_energy -= energy
	EventBus.player_energy_changed.emit(current_energy, max_energy)

func _handle_regen_energy(delta: float):
	if current_energy >= max_energy:
		current_energy = max_energy
		return
	energy_timer += delta
	if energy_timer >= energy_regen_freq:
		energy_timer = 0
		current_energy += energy_regen_tick_value
		EventBus.player_energy_changed.emit(current_energy, max_energy)

func _on_animated_sprite_2d_animation_finished():
	if current_anim_name == "die":
		player_died.emit(self)
