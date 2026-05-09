class_name Projectile
extends Area2D

## 炮台射弹 — 直线飞行，碰撞敌人造成伤害

@export var speed: float = 300.0
@export var lifetime: float = 5.0

var velocity: Vector2 = Vector2.ZERO
var damage: float = 25.0
var _timer: float = 0.0

func _ready():
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	position += velocity * delta
	_timer += delta

	if _timer > lifetime:
		queue_free()

func set_direction(dir: Vector2):
	velocity = dir.normalized() * speed
	rotation = dir.angle()

func set_damage(dmg: float):
	damage = dmg

func _on_area_entered(area: Area2D):
	if area is Enemy or area.get_parent() is Enemy:
		var enemy = area as Enemy if area is Enemy else area.get_parent() as Enemy
		if enemy:
			enemy.apply_damage(damage)
		queue_free()

func _on_body_entered(body: Node2D):
	if body is Enemy:
		body.apply_damage(damage)
	queue_free()
