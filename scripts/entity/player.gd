class_name Player
extends Entity

@export var speed: float = 20
@export var weapon: Node2D
@export var footstep_clip: AudioConfig
@export var footstep_interval = 0.3
@export var spell_bar: SpellBar = null

var is_moving: bool = false
var weapon_right: Vector2
var weapon_left: Vector2
var spawn_location: Vector2
var footstep_timer = 0.0

## 船体跟随：玩家在船上时随船移动
var ship_parent: Ship = null
## 潜艇交互
var current_submarine: Submarine = null
var in_submarine: bool = false

@onready var ability_controller: AbilityController = $AbilityController
@onready var footstep_effect: FootstepEffect = $FootstepEffect

signal player_died(player: Player)

func _ready():
	super._ready()
	add_to_group("player")
	weapon_right = weapon.position
	weapon_left = self.position + (self.position - weapon.position)
	spawn_location = position
	
	var abilities = ability_controller.abilities
	
	for ability_idx in range(abilities.size()):
		var ability = abilities[ability_idx]
		spell_bar.register_ability(ability, ability_idx)
		
	EventBus.play_cast_ability.connect(_handle_ability)
	EventBus.player_health_changed.emit(current_health, max_health)
	EventBus.player_energy_changed.emit(current_energy, max_energy)

	## 查找船体父节点 — 在 PlayScene 根节点下查找 Ship
	await get_tree().process_frame
	for child in get_tree().current_scene.get_children():
		if child is Ship:
			ship_parent = child as Ship
			break

	EventBus.player_in_submarine.connect(_on_submarine_state_changed)
	
	
func _process(delta: float):
	if is_dead: return

	if in_submarine:
		return  # 潜艇内不处理玩家逻辑

	_handle_submarine_interaction(delta)
	_handle_movemment(delta)
	_apply_physics(delta)  # 应用重力
	_handle_footstep_sound(delta)
	_handle_regen_energy(delta)
	_handle_animation()

## 检测附近潜艇并处理进入/离开
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

	if current_submarine and Input.is_action_just_pressed("interact"):
		current_submarine.enter_submarine(self)

func _on_submarine_state_changed(is_inside: bool):
	in_submarine = is_inside

	if not is_inside:
		current_submarine = null
		position = Vector2.ZERO  # 重置到默认位置
	
func _handle_regen_energy(delta: float):
	if current_energy >= max_energy:
		current_energy = max_energy
		return
		
	energy_timer += delta
	
	if energy_timer >= energy_regen_freq:
		energy_timer = 0
		current_energy += energy_regen_tick_value
		EventBus.player_energy_changed.emit(current_energy, max_energy)
	

func _handle_ability(ability: Ability):
	ability_controller.trigger_ability(ability)

func _handle_movemment(delta: float):
	is_moving = false
	turning_cooldown = max(0, turning_cooldown - delta)
	var horizontal = Input.get_axis("left", "right")

	# 船体跟随：玩家随船移动
	if ship_parent:
		position.x += ship_parent.current_speed * delta

	# 水平移动（相对于船）
	var n_movement = Vector2(horizontal, 0)
	self.position += n_movement * speed * delta

	# 跳跃
	if Input.is_action_just_pressed("jump"):
		_try_jump()

	if abs(horizontal) > 0:
		is_moving = true
		footstep_effect.play()

		if turning_cooldown == 0:
			if horizontal > 0:
				animated_sprite.flip_h = false
			elif horizontal < 0:
				animated_sprite.flip_h = true

func _handle_footstep_sound(delta: float):
	if is_moving:
		footstep_timer += delta
		if footstep_timer >= footstep_interval:
			AudioController.play(footstep_clip, global_position)
			footstep_timer = 0.0
	else:
		footstep_timer = 0.0

func _handle_animation():
	if is_moving:
		play_animation(AnimationWrapper.new("run"))
	else:
		play_animation(AnimationWrapper.new("idle"))
				
func _on_animated_sprite_2d_animation_finished():
	if current_anim.name == "die":
		player_died.emit(self)
		
		
func apply_damage(damage: float) -> bool:
	var can_apply = super.apply_damage(damage)
	
	if can_apply:
		EventBus.player_health_changed.emit(current_health, max_health)
		
	return can_apply
	
func spend_energy(energy: float):
	current_energy -= energy
	EventBus.player_energy_changed.emit(current_energy, max_energy)
		
		
		
		
		
		
		
		
		
		
		
		
