class_name Entity
extends Node2D

@export var max_energy: float = 100
@export var max_health: float = 50
@export var damage_text_color: Color = Color.FIREBRICK

@export var energy_regen_freq = 0.5
@export var energy_regen_tick_value = 3

## 物理参数
@export var gravity: float = 800.0       ## 重力加速度
@export var jump_force: float = 350.0     ## 跳跃力度
@export var fall_max_speed: float = 600.0 ## 最大下落速度

var current_anim: AnimationWrapper
var current_health: float
var current_energy: float
var is_dead: bool = false
var turning_cooldown = 0.0
var energy_timer = 0.0

## 物理状态
var vertical_velocity: float = 0.0
var is_on_ground: bool = false
var _ground_y: float = 0.0

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	current_health = max_health
	current_energy = max_energy
	animated_sprite.material = animated_sprite.material.duplicate()
	animated_sprite.animation_finished.connect(on_animation_finished)
	
func _exit_tree():
	animated_sprite.animation_finished.disconnect(on_animation_finished)
	
func apply_damage(damage: float) -> bool:
	if is_dead: return false
	
	current_health -=damage
	current_health = max(0, current_health)
	_show_damage_taken_effect()
	_show_damage_popup(damage)
	
	if current_health == 0:
		print(name, " is dead!")
		is_dead = true
		play_animation(AnimationWrapper.new("die", true))
	
	return true
			
func play_animation(anim: AnimationWrapper):
	if animated_sprite.animation == anim.name: return
	
	if (
		current_anim != null and current_anim.is_high_priority
		and not anim.is_high_priority
	): return
	
	current_anim = anim
	animated_sprite.play(anim.name)
	
func turn_to_position(pos: Vector2):
	if position.x > pos.x and not animated_sprite.flip_h:
		animated_sprite.flip_h = true
	elif position.x < pos.x and animated_sprite.flip_h:
		animated_sprite.flip_h = false
	
func on_animation_finished():
	current_anim = null

## 物理更新：应用重力 + 地面检测
func _apply_physics(delta: float) -> void:
	if is_dead: return

	# 应用重力
	vertical_velocity += gravity * delta
	vertical_velocity = min(vertical_velocity, fall_max_speed)
	position.y += vertical_velocity * delta

	# 地面检测
	_check_ground()

	# 落地时重置速度
	if is_on_ground and vertical_velocity > 0:
		vertical_velocity = 0.0

## 跳跃（仅在地面上有效）
func _try_jump() -> bool:
	if is_on_ground:
		vertical_velocity = -jump_force
		is_on_ground = false
		return true
	return false

## 检测是否在地面上（使用多点检测 + 精确对齐）
func _check_ground() -> void:
	is_on_ground = false
	var tree = get_tree()
	if not tree: return

	var sprite_height = get_height()
	var feet_y = position.y + sprite_height / 2.0

	for node in tree.get_nodes_in_group("tilemap_layer"):
		var layer = node as TileMapLayer
		if not layer or not layer.tile_set: continue

		var tile_size = layer.tile_set.tile_size
		var feet_world = Vector2(position.x, feet_y)
		var cell_pos = layer.local_to_map(feet_world)

		if layer.get_cell_source_id(cell_pos) >= 0:
			is_on_ground = true
			_ground_y = cell_pos.y * tile_size.y - sprite_height / 2.0
			if position.y > _ground_y:
				position.y = _ground_y
			return
	
func get_height() -> float:
	var anim = animated_sprite.animation
	var frame_tex = animated_sprite.sprite_frames.get_frame_texture(anim, 0)
	var height = frame_tex.get_height()
	return height * scale.y
	
func get_current_texture() -> Texture2D:
	return animated_sprite.sprite_frames.get_frame_texture(animated_sprite.animation, animated_sprite.frame)
	
func spend_energy(energy: float): pass

func _show_damage_popup(damage: float):
	var height = get_height()
	var spawn_position = Vector2(position.x, position.y - (height * 0.5))
	FloatText.show_damage_text(str(int(damage)), spawn_position, damage_text_color)
	
func _show_damage_taken_effect():
	if animated_sprite.material != null:
		for i in 2:
			animated_sprite.material.set_shader_parameter("is_hurt", true)
			await get_tree().create_timer(0.05).timeout
			animated_sprite.material.set_shader_parameter("is_hurt", false)
			await get_tree().create_timer(0.05).timeout
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
