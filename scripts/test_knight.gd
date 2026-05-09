extends Node2D

func _ready():
    # 加载所有PNG并显示
    var y_offset = 0
    var x_offset = 0

    for name in ["idle", "walk", "attack", "hurt", "jump", "death"]:
        for i in range(6):
            var path = "res://assets/knight/frames/" + name + "_" + str(i) + ".png"
            var tex = load(path)
            if tex:
                var sprite = Sprite2D.new()
                sprite.texture = tex
                sprite.position = Vector2(x_offset, y_offset)
                add_child(sprite)
                print("Loaded: " + path + " size: " + str(tex.get_width()) + "x" + str(tex.get_height()))
            x_offset += 100
        y_offset += 100
        x_offset = 0
