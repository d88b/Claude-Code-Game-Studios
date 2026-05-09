class_name WaveManager
extends Node

## 波次管理器 — 组织敌人进攻节奏，提供"准备→进攻→奖励"循环

enum WaveState { IDLE, WARNING, ACTIVE, COMPLETE, REWARD }

var current_wave: int = 0
var state: WaveState = WaveState.IDLE
var enemies_to_spawn: int = 0
var enemies_alive: int = 0
var spawn_timer: float = 0.0
var wave_delay: float = 0.0

## 波次配置
@export var chaser_enemy_scene: PackedScene
@export var patrol_enemy_scene: PackedScene
@export var iron_ore_reward: ItemData
@export var initial_wave_delay: float = 10.0  # 第一波前的准备时间
@export var warning_duration: float = 5.0      # 预警持续时间
@export var reward_duration: float = 3.0       # 奖励展示时间

var _enemy_spawner: EnemySpawner = null
var _underwater_spawner: EnemySpawner = null

func _ready():
	pass

func _process(delta: float):
	match state:
		WaveState.IDLE:
			_handle_idle(delta)
		WaveState.WARNING:
			_handle_warning(delta)
		WaveState.ACTIVE:
			_handle_active(delta)
		WaveState.COMPLETE:
			_handle_complete(delta)
		WaveState.REWARD:
			_handle_reward(delta)

func setup(spawner: EnemySpawner, underwater: EnemySpawner = null):
	_enemy_spawner = spawner
	_underwater_spawner = underwater

func _handle_idle(delta: float):
	wave_delay += delta
	if wave_delay >= initial_wave_delay:
		_start_next_wave()

func _handle_warning(delta: float):
	wave_delay += delta
	EventBus.wave_warning.emit(current_wave, max(0, warning_duration - wave_delay))
	if wave_delay >= warning_duration:
		_begin_wave()

func _handle_active(delta: float):
	# 持续生成敌人
	spawn_timer += delta
	var interval = _get_spawn_interval()

	if spawn_timer >= interval and enemies_to_spawn > 0:
		spawn_timer = 0
		_spawn_wave_enemy()
		enemies_to_spawn -= 1

	# 检查是否所有敌人都被消灭
	if enemies_to_spawn <= 0 and _count_alive_enemies() == 0:
		_complete_wave()

func _handle_complete(delta: float):
	wave_delay += delta
	if wave_delay >= 1.0:  # 短暂延迟后进入奖励
		_give_rewards()
		state = WaveState.REWARD
		wave_delay = 0

func _handle_reward(delta: float):
	wave_delay += delta
	EventBus.wave_completed.emit(current_wave, _get_reward_text())
	if wave_delay >= reward_duration:
		GameManager.next_sea_area()
		_reset_for_next_wave()

func _start_next_wave():
	current_wave += 1
	enemies_to_spawn = _get_wave_enemy_count()
	state = WaveState.WARNING
	wave_delay = 0
	GameManager.set_phase(GameManager.GamePhase.DEFENSE)
	EventBus.wave_state_changed.emit("WARNING")
	EventBus.wave_warning.emit(current_wave, warning_duration)
	print("[WaveManager] 第 %d 波预警" % current_wave)

func _begin_wave():
	state = WaveState.ACTIVE
	wave_delay = 0
	spawn_timer = 0
	EventBus.wave_state_changed.emit("ACTIVE")
	EventBus.wave_started.emit(current_wave, enemies_to_spawn)
	print("[WaveManager] 第 %d 波开始，敌人数量: %d" % [current_wave, enemies_to_spawn])

func _complete_wave():
	state = WaveState.COMPLETE
	wave_delay = 0
	EventBus.wave_state_changed.emit("COMPLETE")
	print("[WaveManager] 第 %d 波完成" % current_wave)

func _give_rewards():
	var iron_amount = _get_wave_iron_reward()
	if iron_ore_reward:
		ResourceManager.add_item(iron_ore_reward, iron_amount)

func _reset_for_next_wave():
	state = WaveState.IDLE
	wave_delay = 0
	EventBus.wave_state_changed.emit("IDLE")
	print("[WaveManager] 等待下一波")

func _spawn_wave_enemy():
	if not _enemy_spawner: return
	var enemy_scene = _get_random_enemy_for_wave()
	if not enemy_scene: return

	var enemy = enemy_scene.instantiate() as Enemy
	var spawn_radius = randf_range(_enemy_spawner.min_spawn_radius, _enemy_spawner.max_spawn_radius)
	var dir = Vector2(randf_range(-1.0, 1.0), randf_range(-0.3, 0.3)).normalized()
	var spawn_pos = dir * spawn_radius

	if _enemy_spawner.follow_target:
		spawn_pos += _enemy_spawner.follow_target.global_position

	enemy.global_position = spawn_pos
	get_parent().add_child(enemy)
	enemies_alive += 1

	# 监听敌人死亡
	enemy.tree_exiting.connect(_on_enemy_removed)

func _on_enemy_removed():
	enemies_alive = max(0, enemies_alive - 1)

func _count_alive_enemies() -> int:
	var count = 0
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy = node as Enemy
		if enemy and not enemy.is_dead:
			count += 1
	return count

func _get_wave_enemy_count() -> int:
	return 3 + current_wave * 2

func _get_wave_enemy_types() -> Array:
	var types = []
	types.append(chaser_enemy_scene)
	if current_wave >= 2 and patrol_enemy_scene:
		types.append(patrol_enemy_scene)
	return types

func _get_random_enemy_for_wave() -> PackedScene:
	var types = _get_wave_enemy_types()
	if types.is_empty(): return null
	return types[randi() % types.size()]

func _get_spawn_interval() -> float:
	return max(0.5, 2.0 - current_wave * 0.15)

func _get_wave_iron_reward() -> int:
	return 2 + current_wave

func _get_reward_text() -> String:
	return "+%d 铁矿" % _get_wave_iron_reward()
