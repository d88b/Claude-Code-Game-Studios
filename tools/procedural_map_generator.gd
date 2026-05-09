# 程序化地图生成器
# 用法：编辑器顶部菜单 项目 → 工具 → 生成地图

@tool
extends Node

## 地图尺寸（瓦片数量）- 横向布局
@export var map_width: int = 200
@export var map_height: int = 30

## 道路参数
@export var road_spacing: int = 40  ## 道路之间的瓦片间隔
@export var road_width: int = 3     ## 道路宽度（瓦片）

## 装饰密度（0-1，越高越密集）
@export_range(0.0, 1.0) var decoration_density: float = 0.05

## 地面高度（从地图底部算起的瓦片行数）
@export var ground_height: int = 4

## TileMapLayer 引用
@export var sky_layer: TileMapLayer
@export var ocean_layer: TileMapLayer
@export var grass_layer: TileMapLayer
@export var ground_layer: TileMapLayer
@export var roads_layer: TileMapLayer
@export var decoration_layer: TileMapLayer

func _make_tileset(texture_path: String) -> TileSet:
	var tileset = TileSet.new()
	var texture = load(texture_path)
	if not texture:
		push_error("无法加载纹理: " + texture_path)
		return null
	var source = TileSetAtlasSource.new()
	source.texture = texture
	var atlas_coord = Vector2i(0, 0)
	if not source.has_tile(atlas_coord):
		source.create_tile(atlas_coord)
	tileset.add_source(source)
	return tileset

func _generate():
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var sky_ts = _make_tileset("res://assets/generated_tiles/sky_tile.png")
	var ocean_ts = _make_tileset("res://assets/generated_tiles/ocean_tile.png")
	var grass_ts = _make_tileset("res://assets/generated_tiles/grass_tile.png")
	var ground_ts = _make_tileset("res://assets/generated_tiles/ground_tile.png")
	var road_ts = _make_tileset("res://assets/generated_tiles/road_tile.png")
	var fence_ts = _make_tileset("res://assets/generated_tiles/fence_tile.png")

	# 设置 TileSet
	if sky_layer and sky_ts:
		sky_layer.clear(); sky_layer.tile_set = sky_ts
	if ocean_layer and ocean_ts:
		ocean_layer.clear(); ocean_layer.tile_set = ocean_ts
	if grass_layer and grass_ts:
		grass_layer.clear(); grass_layer.tile_set = grass_ts
	if ground_layer and ground_ts:
		ground_layer.clear(); ground_layer.tile_set = ground_ts
	if roads_layer and road_ts:
		roads_layer.clear(); roads_layer.tile_set = road_ts
	if decoration_layer and fence_ts:
		decoration_layer.clear(); decoration_layer.tile_set = fence_ts

	print("[MapGenerator] 开始生成横向地图: %d x %d" % [map_width, map_height])

	# 1. 天空（全屏背景）
	_generate_sky()

	# 2. 海洋（随机水塘，在地面以上）
	_generate_ocean(rng)

	# 3. 草地（随机分布，不覆盖地面）
	_generate_grass(rng)

	# 4. 地面（底部 solid 层，用于站立）
	_generate_ground()

	# 5. 道路网格
	_generate_roads(rng)

	# 6. 栅栏装饰
	_generate_fences(rng)

	_update_editor_view()
	print("[MapGenerator] 地图生成完成！记得按 Ctrl+S 保存场景")

func _update_editor_view():
	for layer in [sky_layer, ocean_layer, grass_layer, ground_layer, roads_layer, decoration_layer]:
		if layer: layer.set_meta("edited", true)

func _generate_sky():
	if not sky_layer: return
	for x in range(-map_width / 2, map_width / 2):
		for y in range(-map_height / 2, map_height / 2):
			sky_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
	print("  天空铺完")

func _generate_ocean(rng: RandomNumberGenerator):
	if not ocean_layer: return
	var half_w = map_width / 2
	var ground_top = map_height / 2 - ground_height
	var count = 0

	# 生成几个水塘
	var pond_count = rng.randi_range(2, 4)
	for p in range(pond_count):
		var cx = rng.randi_range(-half_w + 10, half_w - 10)
		var cy = rng.randi_range(-half_w + 5, ground_top - 3)  # 在地面之上
		var radius = rng.randi_range(2, 5)
		for dx in range(-radius, radius + 1):
			for dy in range(-radius, radius + 1):
				if dx*dx + dy*dy <= radius*radius:
					var px = cx + dx
					var py = cy + dy
					if abs(px) < half_w and abs(py) < ground_top:
						ocean_layer.set_cell(Vector2i(px, py), 0, Vector2i(0, 0))
						count += 1
	print("  海洋生成: %d 个水块" % count)

func _generate_grass(rng: RandomNumberGenerator):
	if not grass_layer:
		push_error("Grass Layer 未设置！"); return
	var half_w = map_width / 2
	var ground_top = map_height / 2 - ground_height
	var count = 0
	for x in range(-half_w, half_w):
		for y in range(-map_height / 2, ground_top):
			if ocean_layer and ocean_layer.get_cell_tile_data(Vector2i(x, y)): continue
			if rng.randf() < 0.7:
				grass_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
				count += 1
	print("  草地完成: %d 个" % count)

func _generate_ground():
	if not ground_layer:
		push_error("Ground Layer 未设置！"); return
	var half_w = map_width / 2
	var ground_top = map_height / 2 - ground_height
	var count = 0
	for x in range(-half_w, half_w):
		for y in range(ground_top, map_height / 2):
			ground_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
			count += 1
	print("  地面完成: %d x %d (solid 层)" % [map_width, ground_height])

func _generate_roads(rng: RandomNumberGenerator):
	if not roads_layer:
		push_warning("Roads Layer 未设置"); return
	var half_w = map_width / 2
	var ground_top = map_height / 2 - ground_height

	# 横向主路（在地面上）
	var road_y = ground_top
	for rw in range(road_width):
		for x in range(-half_w, half_w):
			roads_layer.set_cell(Vector2i(x, road_y + rw), 0, Vector2i(0, 0))

	# 纵向小路（间隔分布）
	var road_x = -half_w + road_spacing
	while road_x < half_w:
		for rw in range(road_width):
			for y in range(ground_top, ground_top + road_width + 2):
				roads_layer.set_cell(Vector2i(road_x + rw, y), 0, Vector2i(0, 0))
		road_x += road_spacing

	_generate_side_roads(rng, half_w, ground_top)
	print("  道路完成")

func _generate_side_roads(rng: RandomNumberGenerator, half_w: int, ground_top: int):
	var count = rng.randi_range(5, 10)
	for i in range(count):
		var sx = rng.randi_range(-half_w + 5, half_w - 5)
		var length = rng.randi_range(2, 8)
		for step in range(length):
			roads_layer.set_cell(Vector2i(sx + step, ground_top), 0, Vector2i(0, 0))

func _generate_fences(rng: RandomNumberGenerator):
	if not decoration_layer:
		push_warning("Decoration Layer 未设置"); return
	var half_w = map_width / 2
	var ground_top = map_height / 2 - ground_height
	var count = 0
	for x in range(-half_w, half_w):
		for y in range(-map_height / 2, ground_top):
			if grass_layer and grass_layer.get_cell_tile_data(Vector2i(x, y)):
				if rng.randf() < decoration_density:
					decoration_layer.set_cell(Vector2i(x, y), 0, Vector2i(0, 0))
					count += 1
	print("  栅栏完成: %d 个" % count)
