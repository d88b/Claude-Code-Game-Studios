# Create better placeholder tile images
extends SceneTree

func _init() -> void:
    print("[TileGen] Creating better tile images...")
    randomize()

    # 创建 64x64 的纹理图像，更明显
    var tile_size = 64

    # 土地 - 棕色带噪点
    var dirt_img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
    for x in range(tile_size):
        for y in range(tile_size):
            var base_color = Color(0.55, 0.35, 0.15)
            var noise = (randf() - 0.5) * 0.1
            dirt_img.set_pixel(x, y, Color(base_color.r + noise, base_color.g + noise, base_color.b + noise, 1.0))
    # 添加边框
    for i in range(tile_size):
        dirt_img.set_pixel(i, 0, Color(0.4, 0.25, 0.1))
        dirt_img.set_pixel(i, tile_size-1, Color(0.4, 0.25, 0.1))
        dirt_img.set_pixel(0, i, Color(0.4, 0.25, 0.1))
        dirt_img.set_pixel(tile_size-1, i, Color(0.4, 0.25, 0.1))
    dirt_img.save_png("res://assets/tilesets/atlas/dirt.png")
    print("[TileGen] Saved dirt.png")

    # 石头 - 灰色带纹理
    var stone_img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
    for x in range(tile_size):
        for y in range(tile_size):
            var base_color = Color(0.5, 0.5, 0.55)
            var noise = (randf() - 0.5) * 0.15
            stone_img.set_pixel(x, y, Color(base_color.r + noise, base_color.g + noise, base_color.b + noise, 1.0))
    for i in range(tile_size):
        stone_img.set_pixel(i, 0, Color(0.35, 0.35, 0.4))
        stone_img.set_pixel(i, tile_size-1, Color(0.35, 0.35, 0.4))
        stone_img.set_pixel(0, i, Color(0.35, 0.35, 0.4))
        stone_img.set_pixel(tile_size-1, i, Color(0.35, 0.35, 0.4))
    stone_img.save_png("res://assets/tilesets/atlas/stone.png")
    print("[TileGen] Saved stone.png")

    # 矿石 - 金色带亮点
    var ore_img = Image.create(tile_size, tile_size, false, Image.FORMAT_RGBA8)
    for x in range(tile_size):
        for y in range(tile_size):
            var base_color = Color(0.75, 0.55, 0.15)
            var noise = (randf() - 0.5) * 0.2
            ore_img.set_pixel(x, y, Color(base_color.r + noise, base_color.g + noise * 0.5, base_color.b, 1.0))
    # 添加亮点（矿石闪光）
    for _i in range(8):
        var px = randi() % (tile_size - 4) + 2
        var py = randi() % (tile_size - 4) + 2
        ore_img.set_pixel(px, py, Color(1.0, 0.9, 0.5))
    for i in range(tile_size):
        ore_img.set_pixel(i, 0, Color(0.5, 0.35, 0.1))
        ore_img.set_pixel(i, tile_size-1, Color(0.5, 0.35, 0.1))
        ore_img.set_pixel(0, i, Color(0.5, 0.35, 0.1))
        ore_img.set_pixel(tile_size-1, i, Color(0.5, 0.35, 0.1))
    ore_img.save_png("res://assets/tilesets/atlas/ore.png")
    print("[TileGen] Saved ore.png")

    print("[TileGen] Done! Tile size: %dx%d" % [tile_size, tile_size])
    quit()