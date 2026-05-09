class_name PlayScene
extends Node2D

## 深海堡垒游戏主场景

@export var screen_transition: ColorRect
@export var player_health_bar: PlayerHealthBar
@export var pause_menu: PauseMenu
@export var resource_hud: ResourceHUD
@export var wave_hud: WaveHUD

var sea_floor_y: float = 0.0
var ship: Ship
var submarine: Submarine

func _ready():
	# 获取场景中已有的节点
	ship = get_node_or_null("Ship") as Ship
	submarine = get_node_or_null("Submarine") as Submarine

	# 将 Deck 注册到 tilemap_layer 组
	var deck = get_node_or_null("Ship/Deck") as TileMapLayer
	if deck:
		deck.add_to_group("tilemap_layer")

	# 初始化潜艇
	if submarine:
		submarine.surface_y = 80.0
		EventBus.player_in_submarine.connect(_on_submarine_state_changed)

	# 填充海底和海面
	_build_sea_bed()
	_fill_ocean()

	# 放置武器
	_place_turret()

	# 生成资源
	_spawn_resources()

	# 设置敌人和波次
	_setup_enemy_spawner()

	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player") as Player
	if player:
		player.player_died.connect(_handle_game_over)
		player.position = Vector2(0, sea_floor_y - 80)

	AudioController.play_bg_music("play_scene")
	EventBus.game_paused.connect(_handle_paused)

	# 设置游戏状态
	GameManager.set_state(GameManager.GameState.PLAYING)
	GameManager.set_phase(GameManager.GamePhase.NAVIGATION)

	_show_phase_banner("海域 %d — 航行中" % GameManager.current_sea_area)
	GameManager.phase_changed.connect(_on_phase_changed)

## 填充海底瓦片
func _build_sea_bed():
	var map_node = get_node_or_null("Map")
	if not map_node: return

	var seabed_layer = map_node.get_node_or_null("SeaBed") as TileMapLayer
	if not seabed_layer: return

	if seabed_layer.get_used_cells().size() > 0:
		return

	print("[PlayScene] 生成海底...")

	var tile_set = TileSet.new()
	var source = TileSetAtlasSource.new()
	var tex = load("res://assets/generated_tiles/ocean_tile.png")
	if tex:
		source.texture = tex
		source.create_tile(Vector2i(0, 0))
		tile_set.add_source(source)
		tile_set.tile_size = Vector2i(16, 16)
		seabed_layer.tile_set = tile_set

		for x in range(-200, 200):
			for y in range(-20, 280):
				seabed_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	print("[PlayScene] 海底已生成")

## 填充海面层 + 应用水波 shader
func _fill_ocean():
	var map_node = get_node_or_null("Map")
	if not map_node: return

	var ocean_layer = map_node.get_node_or_null("Ocean") as TileMapLayer
	if not ocean_layer: return

	if ocean_layer.get_used_cells().size() > 0:
		return

	print("[PlayScene] 填充海面...")

	var tile_set = TileSet.new()
	var source = TileSetAtlasSource.new()
	var tex = load("res://assets/generated_tiles/ocean_tile.png")
	if tex:
		source.texture = tex
		source.create_tile(Vector2i(0, 0))
		tile_set.add_source(source)
		tile_set.tile_size = Vector2i(16, 16)
		ocean_layer.tile_set = tile_set

		for x in range(-200, 200):
			for y in range(-60, 280):
				ocean_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	var water_shader = load("res://shaders/water_wave.gdshader")
	if water_shader:
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = water_shader
		ocean_layer.material = shader_mat

	print("[PlayScene] 海面已填充")

## 放置炮台和侧炮
func _place_turret():
	var turret_scene = load("res://scenes/turret.tscn")
	var cannon_scene = load("res://scenes/cannon.tscn")
	if not turret_scene or not ship: return

	var turret = turret_scene.instantiate() as Turret
	turret.position = Vector2(100, sea_floor_y - 50)
	ship.add_child(turret)
	print("[PlayScene] 炮台已放置")

	if cannon_scene:
		var cannon = cannon_scene.instantiate() as Cannon
		cannon.position = Vector2(-80, sea_floor_y - 30)
		ship.add_child(cannon)
		print("[PlayScene] 侧炮已放置")

## 在海底生成资源点
func _spawn_resources():
	if not submarine: return

	var spawner = ResourceSpawner.new()
	spawner.name = "ResourceSpawner"
	add_child(spawner)

	var iron_ore = load("res://resources/item_data/iron_ore.tres") as ItemData
	var deep_sea_ore = load("res://resources/item_data/deep_sea_ore.tres") as ItemData
	var bio_sample = load("res://resources/item_data/bio_sample.tres") as ItemData

	var pickup_scene = load("res://scenes/item_pickup.tscn")
	if not pickup_scene:
		print("[PlayScene] 警告：拾取场景未找到")
		return

	spawner.iron_ore_resource = iron_ore
	spawner.deep_sea_ore_resource = deep_sea_ore
	spawner.bio_sample_resource = bio_sample
	spawner.pickup_scene = pickup_scene

	spawner.spawn_resources(600, submarine.surface_y, submarine.max_depth)

## 设置敌人生成器 + 波次管理
func _setup_enemy_spawner():
	var chaser_scene = load("res://scenes/enemies/chaser_enemy.tscn")
	var patrol_scene = load("res://scenes/enemies/patrol_enemy.tscn")
	if not chaser_scene or not patrol_scene:
		print("[PlayScene] 警告：敌人场景未找到")
		return

	var spawner = EnemySpawner.new()
	spawner.name = "EnemySpawner"
	spawner.packed_enemies = [chaser_scene, patrol_scene] as Array[PackedScene]
	spawner.spawn_interval = 4.0
	spawner.max_active_enemies = 6
	spawner.min_spawn_radius = 350
	spawner.max_spawn_radius = 550
	spawner.auto_spawn = false

	add_child(spawner)

	var underwater_spawner = EnemySpawner.new()
	underwater_spawner.name = "UnderwaterEnemySpawner"
	underwater_spawner.packed_enemies = [patrol_scene] as Array[PackedScene]
	underwater_spawner.spawn_interval = 6.0
	underwater_spawner.max_active_enemies = 4
	underwater_spawner.min_spawn_radius = 400
	underwater_spawner.max_spawn_radius = 600
	underwater_spawner.spawn_depth_offset = 200.0

	add_child(underwater_spawner)

	if ship:
		spawner.follow_target = ship

	var wave_mgr = WaveManager.new()
	wave_mgr.name = "WaveManager"
	wave_mgr.chaser_enemy_scene = chaser_scene
	wave_mgr.patrol_enemy_scene = patrol_scene
	wave_mgr.iron_ore_reward = load("res://resources/item_data/iron_ore.tres") as ItemData
	wave_mgr.initial_wave_delay = 8.0
	add_child(wave_mgr)

	wave_mgr.setup(spawner, underwater_spawner)
	print("[PlayScene] 敌人生成器 + 波次系统已配置")

func _on_submarine_state_changed(is_inside: bool):
	var camera = get_node_or_null("Camera2D") as Camera2D
	if not camera: return

	if is_inside and submarine:
		camera.make_current()
		camera.global_position = submarine.global_position
	elif ship:
		camera.make_current()
		camera.global_position = ship.global_position + Vector2(0, 100)

func _handle_game_over(player: Player):
	var tween = fade_in_overlay()
	await tween.finished
	player.position = Vector2(0, -80)

	tween = await fade_out_overlay()
	await tween.finished

	player.current_health = player.max_health
	player.current_energy = player.max_energy
	player.is_dead = false
	player.vertical_velocity = 0.0

	EventBus.player_health_changed.emit(player.current_health, player.max_health)
	EventBus.player_energy_changed.emit(player.current_energy, player.max_energy)

func _on_phase_changed(new_phase: GameManager.GamePhase):
	var phase_names = {
		GameManager.GamePhase.NAVIGATION: "海域 %d — 航行中" % GameManager.current_sea_area,
		GameManager.GamePhase.EXPLORATION: "探索阶段",
		GameManager.GamePhase.DEFENSE: "第 %d 波 — 防守！" % GameManager.current_sea_area,
		GameManager.GamePhase.REWARD: "防守完成 — 奖励阶段"
	}
	var text = phase_names.get(new_phase, "")
	if text:
		_show_phase_banner(text)

func _show_phase_banner(text: String):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_CENTER)
	label.offset_left = -250
	label.offset_top = -25
	label.offset_right = 250
	label.offset_bottom = 25
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1, 1, 1, 1))

	add_child(label)

	label.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 0.3).set_ease(Tween.EASE_OUT)
	tween.parallel()
	tween.tween_property(label, "modulate:a", 0.0, 0.5).set_delay(2.5)
	await tween.finished
	label.queue_free()

func fade_out_overlay():
	var tween = create_tween()
	tween.tween_property(screen_transition, "color:a", 0.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	return tween

func fade_in_overlay():
	var tween = create_tween()
	tween.tween_property(screen_transition, "color:a", 1.0, 1.0).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	return tween

func _on_pause_btn_pressed():
	EventBus.game_paused.emit(true)
	pause_menu.show()
	get_tree().paused = true

func _handle_paused(paused: bool):
	if paused:
		screen_transition.color = Color(0, 0, 0, 0.5)
	else:
		screen_transition.color = Color(0, 0, 0, 0)
