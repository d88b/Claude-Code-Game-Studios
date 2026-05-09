class_name Ship
extends Node2D

## 船体自动移动系统
## 船自动水平前进，玩家可加速/减速

@export var base_speed: float = 40.0
@export var min_speed: float = 20.0
@export var max_speed: float = 80.0
@export var acceleration: float = 15.0
@export var deceleration: float = 10.0

var current_speed: float

signal ship_speed_changed(current_speed: float, min_speed: float, max_speed: float)
signal ship_destroyed

func _ready():
	current_speed = base_speed
	add_to_group("ship")
	EventBus.ship_speed_changed.emit(current_speed, min_speed, max_speed)

func _process(delta: float):
	_handle_speed_input(delta)
	position.x += current_speed * delta

func _handle_speed_input(delta: float):
	var speeding_up = Input.is_action_pressed("speed_up")
	var slowing_down = Input.is_action_pressed("speed_down")

	if speeding_up:
		current_speed = min(current_speed + acceleration * delta, max_speed)
	elif slowing_down:
		current_speed = max(current_speed - deceleration * delta, min_speed)
	else:
		current_speed = lerp(current_speed, base_speed, 0.5 * delta)

	EventBus.ship_speed_changed.emit(current_speed, min_speed, max_speed)
