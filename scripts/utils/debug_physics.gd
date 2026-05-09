## Debug script to verify ground detection coordinates.
## Attach to any node in PlayScene or call manually.
extends Node

func _ready():
	# Wait for everything to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	_run_debug()

func _run_debug():
	print("=== Physics Debug ===")
	print("")

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		print("ERROR: Player not found in group 'player'")
		return

	var pos = player.position
	print("1. Player position: ", pos)

	# Get sprite height
	var sprite_height = player.get_height()
	print("2. Sprite height: ", sprite_height)

	var feet_y = pos.y + sprite_height / 2.0
	print("3. Feet Y (world): ", feet_y)

	# Check tilemap layers
	var tilemap_layers = get_tree().get_nodes_in_group("tilemap_layer")
	print("4. TileMapLayer nodes in group 'tilemap_layer': ", tilemap_layers.size())

	for layer_node in tilemap_layers:
		var layer = layer_node as TileMapLayer
		if not layer:
			print("   WARNING: Node in group is NOT a TileMapLayer: ", layer_node.name)
			continue

		print("")
		print("   --- Layer: ", layer.name, " ---")
		print("   Layer position: ", layer.position)
		print("   Layer has tile_set: ", layer.tile_set != null)

		if layer.tile_set:
			var tile_size = layer.tile_set.tile_size
			print("   TileSet tile_size: ", tile_size)

			var used_cells = layer.get_used_cells()
			print("   Used cells count: ", used_cells.size())

			if used_cells.size() > 0:
				# Show Y range of used cells
				var min_y = used_cells[0].y
				var max_y = used_cells[0].y
				for c in used_cells:
					if c.y < min_y: min_y = c.y
					if c.y > max_y: max_y = c.y
				print("   Used cells Y range: ", min_y, " to ", max_y)

			# Manual calculation (BUG: uses int() truncation toward zero)
			var manual_tile_x = int(pos.x / tile_size.x)
			var manual_tile_y = int(feet_y / tile_size.y)
			print("")
			print("   5a. MANUAL tile coord (BUGGY, int toward zero): (", manual_tile_x, ", ", manual_tile_y, ")")

			# Correct calculation (floor division)
			var correct_tile_x = floori(pos.x / tile_size.x)
			var correct_tile_y = floori(feet_y / tile_size.y)
			print("   5b. CORRECT tile coord (floor toward -inf): (", correct_tile_x, ", ", correct_tile_y, ")")

			# Godot's local_to_map
			var feet_world = Vector2(pos.x, feet_y)
			var godot_tile = layer.local_to_map(feet_world)
			print("   5c. Godot local_to_map result: ", godot_tile)

			# Check tiles at all three calculated positions
			var manual_cell = Vector2i(manual_tile_x, manual_tile_y)
			var correct_cell = Vector2i(correct_tile_x, correct_tile_y)

			print("")
			print("   6. Tile existence checks:")
			print("      At MANUAL coord  (", manual_cell, "): source_id = ", layer.get_cell_source_id(manual_cell))
			print("      At CORRECT coord (", correct_cell, "): source_id = ", layer.get_cell_source_id(correct_cell))
			print("      At local_to_map  (", godot_tile, "): source_id = ", layer.get_cell_source_id(godot_tile))

			# Show what local_to_map gives for a few nearby positions
			print("")
			print("   7. local_to_map for nearby Y positions:")
			for test_y in [feet_y - 16, feet_y - 1, feet_y, feet_y + 1, feet_y + 16]:
				var test_pos = Vector2(pos.x, test_y)
				var test_tile = layer.local_to_map(test_pos)
				var tile_id = layer.get_cell_source_id(test_tile)
				print("      World Y=", test_y, " -> tile_y=", test_tile.y, " source_id=", tile_id)

	print("")
	print("=== End Physics Debug ===")
