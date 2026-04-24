# pure_test_vehicle.gd
# 简化战车控制器 — Vertical Slice MVP
extends Node2D

var move_speed: float = 400.0
var frame_count: int = 0

# === Camera bounds ===
const CAM_LEFT: float = 0
const CAM_RIGHT: float = 1280
const CAM_TOP: float = 0
const CAM_BOTTOM: float = 720

func _ready() -> void:
	print("[Vehicle] Ready — move_speed=", move_speed)

	# 设置相机限制
	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera != null:
		camera.limit_left = CAM_LEFT
		camera.limit_right = CAM_RIGHT
		camera.limit_top = CAM_TOP
		camera.limit_bottom = CAM_BOTTOM

func _process(delta: float) -> void:
	var input_dir: Vector2 = Vector2.ZERO

	# 使用 WASD + 方向键
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		input_dir.y -= 1
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		input_dir.y += 1
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		input_dir.x -= 1
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		input_dir.x += 1

	# 移动
	if input_dir.length() > 0.01:
		input_dir = input_dir.normalized()
		position += input_dir * move_speed * delta

	# 限制在边界内
	position.x = clamp(position.x, CAM_LEFT + 32, CAM_RIGHT - 32)
	position.y = clamp(position.y, CAM_TOP + 32, CAM_BOTTOM - 32)