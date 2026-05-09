# 为 TileMapLayer 添加网格线辅助脚本
# 将此脚本附加到 TileMapLayer 节点上

extends TileMapLayer

@export var show_grid_lines: bool = true
@export var grid_color: Color = Color(0.2, 0.2, 0.2, 0.3)
@export var grid_line_width: float = 1.0

var _grid_lines: Array[Line2D] = []

func _ready():
	if show_grid_lines:
		_draw_grid_lines()

func _draw_grid_lines():
	# 清除现有网格线
	for line in _grid_lines:
		line.queue_free()
	_grid_lines.clear()

	# 获取地图边界
	var used_cells = get_used_cells()
	if used_cells.is_empty():
		return

	var min_x = used_cells[0].x
	var max_x = used_cells[0].x
	var min_y = used_cells[0].y
	var max_y = used_cells[0].y

	for cell in used_cells:
		min_x = min(min_x, cell.x)
		max_x = max(max_x, cell.x)
		min_y = min(min_y, cell.y)
		max_y = max(max_y, cell.y)

	# 创建水平线
	for y in range(min_y, max_y + 2):
		var line = Line2D.new()
		line.default_color = grid_color
		line.width = grid_line_width
		line.add_point(Vector2(min_x * tile_set.tile_size.x, y * tile_set.tile_size.y))
		line.add_point(Vector2((max_x + 1) * tile_set.tile_size.x, y * tile_set.tile_size.y))
		add_child(line)
		_grid_lines.append(line)

	# 创建垂直线
	for x in range(min_x, max_x + 2):
		var line = Line2D.new()
		line.default_color = grid_color
		line.width = grid_line_width
		line.add_point(Vector2(x * tile_set.tile_size.x, min_y * tile_set.tile_size.y))
		line.add_point(Vector2(x * tile_set.tile_size.x, (max_y + 1) * tile_set.tile_size.y))
		add_child(line)
		_grid_lines.append(line)
