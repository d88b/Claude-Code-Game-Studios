extends SceneTree

func _init():
    # 直接加载knight.tscn并检查纹理
    var knight_scene = load("res://scenes/knight.tscn")
    if not knight_scene:
        print("FAILED to load knight.tscn")
        quit()
        return

    print("knight.tscn loaded successfully")

    # 实例化场景
    var knight_instance = knight_scene.instantiate()
    var animated_sprite = knight_instance.get_node("AnimatedSprite2D")

    # 检查当前帧纹理
    var sprite_frames = animated_sprite.sprite_frames
    var anims = sprite_frames.get_animation_names()
    print("Animations: ", anims)

    for anim in anims:
        var frame_count = sprite_frames.get_frame_count(anim)
        print("  ", anim, ": ", frame_count, " frames")
        for i in range(frame_count):
            var tex = sprite_frames.get_frame_texture(anim, i)
            if tex:
                print("    Frame ", i, ": ", tex.resource_path if tex is Texture2D else "N/A", " size: ", tex.get_width(), "x", tex.get_height())
            else:
                print("    Frame ", i, ": NULL")

    quit()
