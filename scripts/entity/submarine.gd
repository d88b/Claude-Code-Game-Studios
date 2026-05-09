class_name Submarine
extends Entity

## 潜艇实体 — 可在水中上下左右移动，有深度系统

@export var speed: float = 80.0
@export var max_depth: float = 500.0
@export var pressure_damage_rate: float = 5.0

var current_depth: float = 0.0
var passenger: Player = null
var surface_y: float = 0.0
var is_diving: bool = false

signal depth_changed(current_depth: float, max_depth: float)

func _ready():
	super._ready()
	surface_y = position.y
	add_to_group("submarine")

func _process(delta: float):
	if is_dead: return

	if is_diving:
		_handle_submarine_movement(delta)
		_handle_resource_collection(delta)
		_check_depth_pressure(delta)

func _handle_submarine_movement(delta: float):
	var h_input = Input.get_axis("left", "right")
	var v_input = 0.0

	if is_diving:
		v_input = Input.get_axis("speed_up", "speed_down")

	var movement = Vector2(h_input, v_input).normalized()
	position += movement * speed * delta

	current_depth = max(0.0, position.y - surface_y)

	if abs(h_input) > 0:
		animated_sprite.flip_h = h_input < 0

	depth_changed.emit(current_depth, max_depth)

	if is_diving:
		EventBus.submarine_depth_changed.emit(current_depth, max_depth)

func _handle_resource_collection(delta: float):
	if not is_diving: return

	var pickups = get_tree().get_nodes_in_group("item_pickup")
	for node in pickups:
		var pickup = node as ItemPickup
		if pickup and not pickup.collected:
			var dist = global_position.distance_to(pickup.global_position)
			if dist < 50.0 and Input.is_action_just_pressed("interact"):
				pickup.collect()
				return

	# 离开潜艇（在潜艇内按 E 返回船面）
	if Input.is_action_just_pressed("enter_submarine"):
		exit_submarine()

func _check_depth_pressure(delta: float):
	if current_depth > max_depth * 0.9:
		var excess = current_depth - max_depth * 0.9
		var pressure_dmg = excess * pressure_damage_rate * delta / max_depth
		apply_damage(pressure_dmg)

func start_dive():
	is_diving = true
	EventBus.submarine_dive_started.emit()

func return_to_surface():
	is_diving = false
	current_depth = 0.0
	position.y = surface_y
	EventBus.submarine_returned_to_surface.emit()

func enter_submarine(player: Player):
	if passenger != null: return

	passenger = player
	player.visible = false
	player.process_mode = Node.PROCESS_MODE_DISABLED
	EventBus.player_in_submarine.emit(true)
	start_dive()

func exit_submarine():
	if passenger == null: return

	passenger.visible = true
	passenger.process_mode = Node.PROCESS_MODE_ALWAYS
	passenger.position = position + Vector2(0, -50)
	passenger = null
	EventBus.player_in_submarine.emit(false)
	return_to_surface()
