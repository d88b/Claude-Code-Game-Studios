"""
增强程序化瓷砖纹理的边框，使地图网格线更明显
修改 play_scene.gd 中的 _generate_procedural_tile 函数
"""

# 需要添加到 _generate_procedural_tile 函数末尾的代码
ENHANCEMENT_CODE = '''
# 在生成纹理后添加边缘边框（使瓷砖边界更明显）
func _add_tile_border(img: Image, border_color: Color, border_width: int = 1) -> void:
	var w = img.get_width()
	var h = img.get_height()
	
	# 上边框
	for x in range(w):
		for bw in range(border_width):
			if bw < h:
				img.set_pixel(x, bw, border_color)
	
	# 下边框
	for x in range(w):
		for bw in range(border_width):
			if h - 1 - bw >= 0:
				img.set_pixel(x, h - 1 - bw, border_color)
	
	# 左边框
	for y in range(h):
		for bw in range(border_width):
			if bw < w:
				img.set_pixel(bw, y, border_color)
	
	# 右边框
	for y in range(h):
		for bw in range(border_width):
			if w - 1 - bw >= 0:
				img.set_pixel(w - 1 - bw, y, border_color)
'''

print("请将以下代码添加到 play_scene.gd 的 _generate_procedural_tile 函数中：")
print("在返回 ImageTexture.create_from_image(img) 之前添加：")
print()
print("# 添加细微的边框线增强瓷砖边界可见性")
print("_add_tile_border(img, Color(0.1, 0.1, 0.1, 0.15), 1)")
print()
print("并添加 _add_tile_border 辅助函数（见上方 ENHANCEMENT_CODE）")
