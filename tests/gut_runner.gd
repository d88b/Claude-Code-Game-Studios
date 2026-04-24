#!/usr/bin/env godot
# gut_runner.gd — GUT test runner for headless execution (GUT 4.6 compatible)
# Uses GUT CLI directly with command line-style configuration
extends SceneTree

const GutCli := preload("res://addons/gut/cli/gut_cli.gd")

func _init() -> void:
	await _run_tests()

func _run_tests() -> void:
	# 创建 GUT CLI 实例
	var gut_cli: Node = GutCli.new()
	get_root().add_child(gut_cli)

	# 使用命令行参数方式配置测试
	# 通过 main() 函数传递参数
	gut_cli.main()

	# 等待一段时间让测试运行
	await create_timer(60.0).timeout

	# 退出
	quit(0)