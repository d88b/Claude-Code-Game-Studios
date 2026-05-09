extends SceneTree

func _init():
    # Check original JPG
    var tex = load("res://assets/knight/knight_walk.jpg")
    if not tex:
        print("JPG NOT FOUND")
        quit()
        return

    var img = tex.get_image()
    var w = img.get_width()
    var h = img.get_height()
    print("Original JPG: ", w, "x", h)

    # Sample first frame region (0,0 to 320,720)
    print("--- Frame 0 region samples ---")
    var test_points = [
        Vector2i(10, 10),    # top-left corner
        Vector2i(160, 360),  # center
        Vector2i(310, 710),  # bottom-right corner
        Vector2i(5, 360),    # left edge middle
        Vector2i(315, 360),  # right edge middle
    ]
    for p in test_points:
        var c = img.get_pixelv(p)
        print("  (", p.x, ",", p.y, "): RGB(", int(c.r*255), ",", int(c.g*255), ",", int(c.b*255), ")")

    # Check cropped PNG
    var cropped_tex = load("res://assets/knight/frames/walk_0.png")
    if cropped_tex:
        var cropped_img = cropped_tex.get_image()
        print("\nCropped PNG: ", cropped_img.get_width(), "x", cropped_img.get_height())
        var cw = cropped_img.get_width()
        var ch = cropped_img.get_height()
        for cy in range(0, ch, max(1, ch/4)):
            var row = ""
            for cx in range(0, cw, max(1, cw/6)):
                var c = cropped_img.get_pixel(cx, cy)
                var a_str = str(int(c.a * 255))
                var pix = "(" + str(int(c.r*255)) + "," + str(int(c.g*255)) + "," + str(int(c.b*255)) + ",a" + a_str + ")"
                row += pix + " "
            print("  y=", cy, ": ", row)
    else:
        print("Cropped PNG NOT FOUND")

    quit()
