# grid_background.gd
# 棋盘格背景生成器 — 使用 ColorRect 实现
extends Node2D

const CELL_SIZE: int = 64
const GRID_WIDTH: int = 20
const GRID_HEIGHT: int = 11

const COLOR_LIGHT: Color = Color(0.15, 0.15, 0.2, 1)
const COLOR_DARK: Color = Color(0.1, 0.1, 0.15, 1)

func _ready() -> void:
	_generate_grid()
	print("[GridBackground] Generated %dx%d cells (%d total)" % [GRID_WIDTH, GRID_HEIGHT, GRID_WIDTH * GRID_HEIGHT])

func _generate_grid() -> void:
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			# 使用 ColorRect 代替 Polygon2D，更简单可靠
			var rect: ColorRect = ColorRect.new()
			rect.position = Vector2(x * CELL_SIZE, y * CELL_SIZE)
			rect.size = Vector2(CELL_SIZE, CELL_SIZE)

			# 棋盘格颜色
			if (x + y) % 2 == 0:
				rect.color = COLOR_LIGHT
			else:
				rect.color = COLOR_DARK

			# 确保在最底层渲染
			rect.z_index = -10

			add_child(rect)