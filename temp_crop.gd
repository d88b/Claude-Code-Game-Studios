extends SceneTree

func _init():
    var base = "res://assets/knight/"
    var out_dir = "res://assets/knight/frames/"
    DirAccess.make_dir_recursive_absolute(out_dir)

    var configs = {
        "idle": {"file": "knight_idle.jpg", "cols": 3, "rows": 2},
        "walk": {"file": "knight_walk.jpg", "cols": 4, "rows": 1},
        "attack": {"file": "knight_attack.jpg", "cols": 4, "rows": 1},
        "hurt": {"file": "knight_hurt.jpg", "cols": 3, "rows": 1},
        "jump": {"file": "knight_jump.jpg", "cols": 4, "rows": 1},
        "death": {"file": "knight_death.jpg", "cols": 3, "rows": 2},
    }

    for name in configs:
        var cfg = configs[name]
        var tex = load(base + cfg.file)
        if not tex:
            print("FAILED: " + name)
            continue

        var img = tex.get_image()
        img.convert(Image.FORMAT_RGBA8)
        var fw = img.get_width() / cfg.cols
        var fh = img.get_height() / cfg.rows
        var count = cfg.cols * cfg.rows

        var src_data = img.get_data()
        var img_w = img.get_width()

        for i in range(count):
            var col_num = i % cfg.cols
            var row_num = i / cfg.cols
            var px = col_num * fw
            var py = row_num * fh

            # 构建帧的字节数据
            var frame_bytes = PackedByteArray()
            frame_bytes.resize(fw * fh * 4)

            for fy in range(fh):
                for fx in range(fw):
                    var src_idx = ((py + fy) * img_w + (px + fx)) * 4
                    var r = src_data[src_idx]
                    var g = src_data[src_idx + 1]
                    var b = src_data[src_idx + 2]
                    var dst_idx = (fy * fw + fx) * 4

                    var avg = (r + g + b) / 3
                    if avg > 35:
                        frame_bytes[dst_idx] = r
                        frame_bytes[dst_idx + 1] = g
                        frame_bytes[dst_idx + 2] = b
                        frame_bytes[dst_idx + 3] = 255

            var frame = Image.create_from_data(fw, fh, false, Image.FORMAT_RGBA8, frame_bytes)

            # 裁剪
            var cropped = crop_to_content(frame, fw, fh)

            var fname = out_dir + name + "_" + str(i) + ".png"
            cropped.save_png(fname)
            print("Saved: " + fname + " (" + str(cropped.get_width()) + "x" + str(cropped.get_height()) + ")")

    quit()

func crop_to_content(img: Image, w: int, h: int) -> Image:
    var data = img.get_data()

    var min_x = w, max_x = 0, min_y = h, max_y = 0
    var found = false

    for y in range(h):
        for x in range(w):
            var idx = (y * w + x) * 4 + 3
            if data[idx] > 25:
                found = true
                if x < min_x: min_x = x
                if x > max_x: max_x = x
                if y < min_y: min_y = y
                if y > max_y: max_y = y

    if not found:
        return img

    var pad = 4
    min_x = maxi(0, min_x - pad)
    max_x = mini(w - 1, max_x + pad)
    min_y = maxi(0, min_y - pad)
    max_y = mini(h - 1, max_y + pad)

    var cw = max_x - min_x + 1
    var ch = max_y - min_y + 1

    var result = Image.create(cw, ch, false, Image.FORMAT_RGBA8)
    result.blit_rect(img, Rect2i(min_x, min_y, cw, ch), Vector2i.ZERO)
    return result
