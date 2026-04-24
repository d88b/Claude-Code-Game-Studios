extends Node
# EnemyTypeDB — 敌人类型数据库 (Autoload)
## EnemyTypeDB — 敌人类型数据库
## 从 entities.yaml 加载敌人定义，提供 O(1) 查询接口
## Foundation layer database — 所有敌人属性的数据源

# === 常量定义 ===
## 8 种行为提示类型
const BEHAVIOR_HINTS: Array[String] = [
	"aggressive",      # 攻击型 — 直冲目标
	"defensive",       # 防守型 — 保护区域
	"swarm",           # 集群型 — 群体行动
	"wall_breaker",    # 拆墙型 — 优先攻击墙壁
	"tracker",         # 追踪型 — 持续追踪目标
	"ambusher",        # 伏击型 — 隐藏后突袭
	"retreat_early",   # 早退型 — 受伤后撤退
	"boss"             # Boss型 — 特殊行为
]

# === 数据缓存 ===
## 敌人数据缓存：{enemy_id: EnemyStats}
var _enemies: Dictionary = {}
## 敌人数量
var enemy_count: int = 0

# === 敌人定义类 ===
class EnemyStats:
	## 敌人类型 ID
	var enemy_id: int = 0
	## 显示名称 (中文)
	var display_name: String = ""
	## 生命值
	var health: float = 100.0
	## 伤害值
	var damage: float = 10.0
	## 护甲值
	var armor: float = 0.0
	## 移动速度
	var speed: float = 100.0
	## 行为提示
	var behavior_hint: String = "aggressive"

# === 初始化 ===

func _ready() -> void:
	_build_cache()
	print("[EnemyTypeDB] initialized with enemy_count=", enemy_count)

func _build_cache() -> void:
	_create_mvp_enemies()

func _create_mvp_enemies() -> void:
	# 普通僵尸 (1-3)
	for i in range(1, 4):
		var zombie: EnemyStats = EnemyStats.new()
		zombie.enemy_id = i
		zombie.display_name = "普通僵尸 " + str(i)
		zombie.health = 50.0 + i * 10.0
		zombie.damage = 5.0 + i * 2.0
		zombie.armor = 0.0
		zombie.speed = 80.0 + i * 10.0
		zombie.behavior_hint = "aggressive"
		_enemies[i] = zombie

	# 集群僵尸 (4)
	var swarm: EnemyStats = EnemyStats.new()
	swarm.enemy_id = 4
	swarm.display_name = "集群僵尸"
	swarm.health = 30.0
	swarm.damage = 3.0
	swarm.armor = 0.0
	swarm.speed = 120.0
	swarm.behavior_hint = "swarm"
	_enemies[4] = swarm

	# 拆墙僵尸 (5)
	var breaker: EnemyStats = EnemyStats.new()
	breaker.enemy_id = 5
	breaker.display_name = "拆墙僵尸"
	breaker.health = 100.0
	breaker.damage = 20.0
	breaker.armor = 5.0
	breaker.speed = 60.0
	breaker.behavior_hint = "wall_breaker"
	_enemies[5] = breaker

	# 追踪僵尸 (6)
	var tracker: EnemyStats = EnemyStats.new()
	tracker.enemy_id = 6
	tracker.display_name = "追踪僵尸"
	tracker.health = 80.0
	tracker.damage = 15.0
	tracker.armor = 2.0
	tracker.speed = 100.0
	tracker.behavior_hint = "tracker"
	_enemies[6] = tracker

	# 伏击僵尸 (7)
	var ambusher: EnemyStats = EnemyStats.new()
	ambusher.enemy_id = 7
	ambusher.display_name = "伏击僵尸"
	ambusher.health = 60.0
	ambusher.damage = 25.0
	ambusher.armor = 0.0
	ambusher.speed = 150.0
	ambusher.behavior_hint = "ambusher"
	_enemies[7] = ambusher

	# Boss (100)
	var boss: EnemyStats = EnemyStats.new()
	boss.enemy_id = 100
	boss.display_name = "尸潮首领"
	boss.health = 500.0
	boss.damage = 50.0
	boss.armor = 20.0
	boss.speed = 70.0
	boss.behavior_hint = "boss"
	_enemies[100] = boss

	enemy_count = _enemies.size()

# === 查询 API ===

## 获取敌人属性 — 返回 null 表示无效 ID
func get_enemy_stats(enemy_id: int) -> EnemyStats:
	return _enemies.get(enemy_id, null)

## 获取行为提示
func get_behavior_hint(enemy_id: int) -> String:
	var stats: EnemyStats = get_enemy_stats(enemy_id)
	if stats == null:
		return ""
	return stats.behavior_hint

## 获取显示名称
func get_display_name(enemy_id: int) -> String:
	var stats: EnemyStats = get_enemy_stats(enemy_id)
	if stats == null:
		return ""
	return stats.display_name

## 检查行为提示是否有效
func is_valid_behavior_hint(hint: String) -> bool:
	return hint in BEHAVIOR_HINTS

## 获取指定行为的所有敌人 ID
func get_enemies_by_behavior(hint: String) -> Array[int]:
	var result: Array[int] = []
	for enemy_id: int in _enemies.keys():
		var stats: EnemyStats = _enemies[enemy_id]
		if stats.behavior_hint == hint:
			result.append(enemy_id)
	return result

## 获取所有敌人 ID
func get_all_enemy_ids() -> Array[int]:
	return _enemies.keys()