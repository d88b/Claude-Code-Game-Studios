"""创建独立测试场景，直接显示骑士PNG"""
import os

OUT_DIR = "d:/ai/Claude-Code-Game-Studios/assets/knight/frames"

# Count frames per animation
counts = {
    "idle": 6, "walk": 4, "attack": 4,
    "hurt": 3, "jump": 4, "death": 6
}

lines = ['[gd_scene load_steps=2 format=3]', '',
         '[ext_resource type="Script" path="res://scripts/test_display.gd" id="1"]', '',
         '[node name="TestDisplay" type="Node2D"]', 'script = ExtResource("1")']

# Create the scene file
with open('d:/ai/Claude-Code-Game-Studios/scenes/test_display.tscn', 'w') as f:
    f.write('\n'.join(lines))

# Create the script
script = '''extends Node2D

func _ready():
    var y = 0
    for anim_name in ["idle", "walk", "attack", "hurt", "jump", "death"]:
        var count = 0
        while true:
            var path = "res://assets/knight/frames/" + anim_name + "_" + str(count) + ".png"
            var tex = load(path)
            if not tex:
                break

            var sprite = Sprite2D.new()
            sprite.texture = tex
            sprite.position = Vector2(count * 100, y)
            add_child(sprite)
            count += 1
        y += 200
'''

with open('d:/ai/Claude-Code-Game-Studios/scripts/test_display.gd', 'w') as f:
    f.write(script)

print("Created test_display scene")
