@tool
extends EditorPlugin

var menu_item := "生成地图"

func _enter_tree():
	add_tool_menu_item(menu_item, _on_generate_map)

func _exit_tree():
	remove_tool_menu_item(menu_item)

func _on_generate_map():
	var root = get_tree().edited_scene_root
	if not root:
		push_error("[MapGenerator] 没有打开的场景")
		return

	var map_node = root.get_node_or_null("Map")
	if not map_node:
		push_error("[MapGenerator] 找不到 Map 节点")
		return

	var gen = map_node.get_script().new()

	gen.sky_layer = map_node.get_node_or_null("Sky")
	gen.ocean_layer = map_node.get_node_or_null("Ocean")
	gen.grass_layer = map_node.get_node_or_null("Grass")
	gen.ground_layer = map_node.get_node_or_null("Ground")
	gen.roads_layer = map_node.get_node_or_null("Roads")
	gen.decoration_layer = map_node.get_node_or_null("Decoration")

	gen.map_width = 200
	gen.map_height = 30
	gen.road_spacing = 40
	gen.road_width = 3
	gen.decoration_density = 0.05
	gen.ground_height = 4

	gen._generate()
