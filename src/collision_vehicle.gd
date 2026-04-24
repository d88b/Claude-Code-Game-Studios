# collision_vehicle.gd
# 带碰撞检测的战车控制器 — Vertical Slice 测试版
extends Node2D

var move_speed: float = 400.0

# === Camera bounds ===
const CAM_LEFT: float = 0
const CAM_RIGHT: float = 1280
const CAM_TOP: float = 0
const CAM_BOTTOM: float = 720

# === 碰撞检测 ===
var _collision_area: Area2D = null
var _is_colliding: bool = false
var _collision_normal: Vector2 = Vector2.ZERO

func _ready() -> void:
	print("[CollisionVehicle] Ready — move_speed=", move_speed)

	# 设置相机限制
	var camera: Camera2D = get_node_or_null("Camera2D")
	if camera != null:
		camera.limit_left = CAM_LEFT
		camera.limit_right = CAM_RIGHT
		camera.limit_top = CAM_TOP
		camera.limit_bottom = CAM_BOTTOM

	# 获取碰撞区域
	_collision_area = get_node_or_null("CollisionArea")
	if _collision_area != null:
		_collision_area.body_entered.connect(_on_body_entered)
		_collision_area.body_exited.connect(_on_body_exited)

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

		# 碰撞时减速
		var speed: float = move_speed
		if _is_colliding:
			speed *= 0.3  # 碰撞时减速到30%

		position += input_dir * speed * delta

	# 限制在边界内
	position.x = clamp(position.x, CAM_LEFT + 32, CAM_RIGHT - 32)
	position.y = clamp(position.y, CAM_TOP + 32, CAM_BOTTOM - 32)

# === 碰撞回调 ===

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("obstacles"):
		_is_colliding = true
		print("[Vehicle] 碰撞进入: ", body.name)

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("obstacles"):
		_is_colliding = false
		print("[Vehicle] 碰撞退出: ", body.name)