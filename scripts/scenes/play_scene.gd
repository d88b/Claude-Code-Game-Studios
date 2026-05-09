class_name PlayScene
extends Node

@export var screen_transition: ColorRect
@export var player_health_bar: PlayerHealthBar
@export var pause_menu: PauseMenu
@export var resource_hud: ResourceHUD

var water_particles: GPUParticles2D
var deck_layer: TileMapLayer
var sea_floor_y = 0.0
var ship: Ship
var submarine: Submarine

func _ready():
	_build_ship()
	_register_deck_group()
	_build_sea_bed()
	_fill_ocean()
	_create_water_particles()
	_place_turret()
	_place_submarine()
	_spawn_resources()
	_setup_enemy_spawner()

	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player") as Player
	player.player_died.connect(_handle_game_over)
	AudioController.play_bg_music("play_scene")
	EventBus.game_paused.connect(_handle_paused)

	# 将玩家放在甲板中央
	if player:
		player.position = Vector2(0, sea_floor_y - 80)

## 创建船体容器（包含甲板、炮台等）
func _build_ship():
	var map_node = get_node_or_null("Map")
	if not map_node: return

	ship = Ship.new()
	ship.name = "Ship"

	# 将 Map 下的所有 TileMapLayer 移到 Ship 下
	var layers_to_move = []
	for child in map_node.get_children():
		if child is TileMapLayer:
			layers_to_move.append(child)

	for layer in layers_to_move:
		layer.reparent(ship)

	add_child(ship)
	print("[PlayScene] 船体容器已创建")

## 把 Deck 层注册到 tilemap_layer 组供碰撞检测
func _register_deck_group():
	# 等待 Ship 节点创建后再查找
	await get_tree().process_frame

	var ship_node = get_node_or_null("Ship")
	if not ship_node: return

	for child in ship_node.get_children():
		if child is TileMapLayer and child.name == "Deck":
			child.add_to_group("tilemap_layer")
			deck_layer = child
			print("[PlayScene] 已将 Deck 加入 tilemap_layer 组")
			return

## 程序生成海底（深色背景）
func _build_sea_bed():
	var map_node = get_node_or_null("Map")
	if not map_node: return

	var seabed_layer = map_node.get_node_or_null("SeaBed") as TileMapLayer
	if not seabed_layer: return

	if seabed_layer.tile_set != null and seabed_layer.get_used_cells().size() > 0:
		return

	print("[PlayScene] 生成海底...")

	var tile_set = TileSet.new()
	var source = TileSetAtlasSource.new()

	var sea_texture = load("res://assets/generated_tiles/ocean_tile.png")
	if sea_texture:
		source.texture = sea_texture
		source.create_tile(Vector2i(0, 0))
		tile_set.add_source(source)
		tile_set.tile_size = Vector2i(16, 16)

		seabed_layer.tile_set = tile_set

		for x in range(-200, 200):
			for y in range(-20, 280):
				seabed_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	print("[PlayScene] 海底已生成: ", seabed_layer.get_used_cells().size(), " 个瓦片")

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

	var ocean_texture = load("res://assets/generated_tiles/ocean_tile.png")
	if ocean_texture:
		source.texture = ocean_texture
		source.create_tile(Vector2i(0, 0))
		tile_set.add_source(source)
		tile_set.tile_size = Vector2i(16, 16)

		ocean_layer.tile_set = tile_set

		for x in range(-200, 200):
			for y in range(-60, 280):
				ocean_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	# 应用水波 shader
	var water_shader = load("res://shaders/water_wave.gdshader")
	if water_shader:
		var shader_mat = ShaderMaterial.new()
		shader_mat.shader = water_shader
		ocean_layer.material = shader_mat

	print("[PlayScene] 海面已填充")

## 放置基础炮台
func _place_turret():
	var turret_scene = load("res://scenes/turret.tscn")
	if not turret_scene: return

	var turret = turret_scene.instantiate() as Turret
	turret.position = Vector2(100, sea_floor_y - 50)

	# 等 Ship 创建后放置
	var ship_node = get_node_or_null("Ship")
	if ship_node:
		ship_node.add_child(turret)
		print("[PlayScene] 炮台已放置在船上")

## 放置潜艇（船体底部）
func _place_submarine():
	var sub_scene_file = load("res://scenes/submarine.tscn")
	if not sub_scene_file:
		print("[PlayScene] 警告：潜艇场景未找到")
		return

	submarine = sub_scene_file.instantiate() as Submarine

	# 等 Ship 创建后放置
	var ship_node = get_node_or_null("Ship")
	if ship_node:
		submarine.surface_y = ship_node.position.y + 80
		submarine.position = Vector2(0, submarine.surface_y)
		add_child(submarine)
		print("[PlayScene] 潜艇已放置在船底")

	EventBus.player_in_submarine.connect(_on_submarine_state_changed)

## 在海底生成资源点
func _spawn_resources():
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

## 设置敌人生成器
func _setup_enemy_spawner():
	var chaser_scene = load("res://scenes/enemies/chaser_enemy.tscn")
	var patrol_scene = load("res://scenes/enemies/patrol_enemy.tscn")
	if not chaser_scene or not patrol_scene:
		print("[PlayScene] 警告：敌人场景未找到")
		return

	var spawner = EnemySpawner.new()
	spawner.name = "EnemySpawner"
	spawner.packed_enemies = [chaser_scene, patrol_scene]
	spawner.spawn_interval = 4.0
	spawner.max_active_enemies = 6
	spawner.min_spawn_radius = 350
	spawner.max_spawn_radius = 550

	# 跟随船移动
	add_child(spawner)

	await get_tree().process_frame
	if ship:
		spawner.follow_target = ship

	print("[PlayScene] 敌人生成器已配置")

func _on_submarine_state_changed(is_inside: bool):
	# 切换相机跟随目标
	var camera = get_node_or_null("Camera2D") as Camera2D
	if not camera: return

	if is_inside and submarine:
		camera.make_current()
		camera.global_position = submarine.global_position
	elif ship:
		camera.make_current()
		camera.global_position = ship.global_position + Vector2(0, 100)

func _create_water_particles():
	water_particles = GPUParticles2D.new()
	water_particles.name = "WaterParticles"
	water_particles.position = Vector2(0, 64)
	water_particles.z_index = 20
	water_particles.amount = 200
	water_particles.lifetime = 3.0
	water_particles.one_shot = false
	water_particles.preprocess = 1.0
	water_particles.emitting = true

	var mat = ParticleProcessMaterial.new()

	water_particles.process_material = mat
	add_child(water_particles)

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


func fade_out_overlay():
	var tween = create_tween()
	tween.tween_property(
		screen_transition,
		"color:a",
		0.0,
		1.0
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT)
	return tween

func fade_in_overlay():
	var tween = create_tween()
	tween.tween_property(
		screen_transition,
		"color:a",
		1.0,
		1.0
	).set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN)
	return tween

func _on_pause_btn_pressed():
	EventBus.game_paused.emit(true)
	pause_menu.show()
	get_tree().paused = true

func _handle_paused(paused: bool):
	if paused:
		screen_transition.color = Color(0,0,0, 0.5)
	else:
		screen_transition.color = Color(0,0,0,0)
