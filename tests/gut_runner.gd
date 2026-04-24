#!/usr/bin/env godot
# gut_runner.gd — GUT test runner for headless execution
extends SceneTree

func _init() -> void:
	await _run_tests()

func _run_tests() -> void:
	var gut: Object = await load("res://addons/gut/gut_cmdln.gd").new()
	gut.set_include_files(["res://tests/unit/collision/collision_query_test.gd"])
	gut.run_tests()
	await gut.get_tree().process_frame
	quit()