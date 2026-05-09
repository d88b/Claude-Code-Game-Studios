class_name PlayScene
extends Node

@export var screen_transition: ColorRect
@export var player_health_bar: PlayerHealthBar
@export var pause_menu: PauseMenu

var water_particles: GPUParticles2D
var deck_layer: TileMapLayer
var sea_floor_y = 0.0

func _ready():
	_register_deck_group()
	_build_sea_bed()
	_build_deck()
	_fill_ocean()
	_create_water_particles()

	await get_tree().process_frame

	var player = get_tree().get_first_node_in_group("player") as Player
	player.player_died.connect(_handle_game_over)
	AudioController.play_bg_music("play_scene")
	EventBus.game_paused.connect(_handle_paused)

	# 将玩家放在甲板中央
	if player:
		player.position = Vector2(0, sea_floor_y - 80)

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

## 把 Deck 层注册到 tilemap_layer 组供碰撞检测
func _register_deck_group():
	var map_node = get_node_or_null("Map")
	if not map_node: return

	for child in map_node.get_children():
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

	# 用深色瓦片做海底
	var sea_texture = load("res://assets/generated_tiles/ocean_tile.png")
	if sea_texture:
		source.texture = sea_texture
		source.create_tile(Vector2i(0, 0))
		tile_set.add_source(source)
		tile_set.tile_size = Vector2i(16, 16)

		seabed_layer.tile_set = tile_set

		# 生成海底瓦片
		for x in range(-200, 200):
			for y in range(-20, 280):
				seabed_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))

	print("[PlayScene] 海底已生成: ", seabed_layer.get_used_cells().size(), " 个瓦片")

## 生成矩形船甲板（漂浮在海面上）
func _build_deck():
	var map_node = get_node_or_null("Map")
	if not map_node: return

	var deck = map_node.get_node_or_null("Deck") as TileMapLayer
	if not deck: return

	if deck.tile_set != null and deck.get_used_cells().size() > 0:
		return

	print("[PlayScene] 生成船甲板...")

	var tile_set = TileSet.new()
	var source = TileSetAtlasSource.new()

	# 用木板纹理做甲板
	var deck_texture = load("res://assets/generated_tiles/road_tile.png")
	if not deck_texture:
		deck_texture = load("res://assets/generated_tiles/grass_tile.png")
	if not deck_texture:
		return

	source.texture = deck_texture
	source.create_tile(Vector2i(0, 0))
	tile_set.add_source(source)
	tile_set.tile_size = Vector2i(16, 16)

	deck.tile_set = tile_set

	# 甲板：宽 80 瓦片，高 3 瓦片（约 1280x48 像素）
	var deck_width = 80
	var deck_height = 3
	var deck_center_x = 0
	var deck_y = -4  # 甲板在海面上的高度

	for x in range(deck_width):
		for y in range(deck_height):
			deck.set_cell(Vector2i(deck_center_x - deck_width / 2 + x, deck_y + y), 0, Vector2i(0, 0))

	sea_floor_y = deck_y * 16
	var used = deck.get_used_cells()
	print("[PlayScene] 船甲板已生成: ", used.size(), " 个瓦片，海底 Y 坐标: ", sea_floor_y)

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
