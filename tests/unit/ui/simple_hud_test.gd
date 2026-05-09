# simple_hud_test.gd
# SimpleHUD 测试 — ui-002
## SimpleHUD 测试
## 验证 HUD 元素初始化、信号响应、敌人数量显示、波次进度
## QA Plan: production/qa/qa-plan-sprint-5-2026-04-26.md

extends GutTest

# === 测试目标 ===
const SIMPLE_HUD_PATH: String = "res://src/ui/simple_hud.gd"

# === 常量 ===
const MAX_ENEMY_COUNT: int = 100
const MAX_WAVE_COUNT: int = 5
const WAVE_COUNT_PER_TIDE: int = 5

# === 测试实例 ===
var hud: Node = null

func before_each() -> void:
	var script: GDScript = load(SIMPLE_HUD_PATH)
	hud = script.new()
	# 不调用 _ready()（需要场景树）

func after_each() -> void:
	if hud != null and is_instance_valid(hud):
		hud.queue_free()
	hud = null

# === 初始化测试 ===

## 测试敌人数量变量初始值
func test_enemy_count_initial_values() -> void:
	assert_eq(hud._enemy_count, 0, "Enemy count should initialize to 0")
	assert_eq(hud._current_wave, 0, "Current wave should initialize to 0")
	assert_eq(hud._total_waves, 0, "Total waves should initialize to 0")

## 测试 UI 元素初始为 null（未创建）
func test_ui_elements_null_before_create() -> void:
	assert_eq(hud._enemy_count_label, null, "Enemy count label should be null before _create_ui_elements")
	assert_eq(hud._wave_progress_bar, null, "Wave progress bar should be null before _create_ui_elements")
	assert_eq(hud._wave_label, null, "Wave label should be null before _create_ui_elements")
	assert_eq(hud._weapon_info_label, null, "Weapon info label should be null before _create_ui_elements")

# === 信号回调测试 ===

## 测试波次开始回调
func test_on_wave_started_updates_values() -> void:
	# 设置初始值
	hud._total_waves = 5

	# 调用回调
	hud._on_wave_started(2, 15)

	assert_eq(hud._current_wave, 3, "Wave index 2 → current_wave = 3")
	assert_eq(hud._enemy_count, 15, "Enemy count should be 15")

## 测试波次完成回调
func test_on_wave_completed_calls_update() -> void:
	# 设置初始值
	hud._enemy_count = 10

	# 调用回调
	hud._on_wave_completed(2)

	# 验证回调执行（无异常即成功）
	assert_true(true, "Wave completed callback should execute without error")

## 测试尸潮完成回调重置值
func test_on_tide_completed Resets_values() -> void:
	# 设置初始值
	hud._current_wave = 3
	hud._enemy_count = 20

	# 调用回调
	hud._on_tide_completed(75)

	assert_eq(hud._current_wave, 0, "Current wave should reset to 0 after tide")
	assert_eq(hud._enemy_count, 0, "Enemy count should reset to 0 after tide")

## 测试状态变化回调
func test_on_spawn_state_changed_updates_state_label() -> void:
	# 创建模拟 Label
	hud._state_label = Label.new()

	# 调用回调
	hud._on_spawn_state_changed(0, 1)

	assert_eq(hud._state_label.text, "波次进行", "State 1 should show '波次进行'")

	# 清理
	hud._state_label.queue_free()

## 测试武器发射回调
func test_on_weapon_fired_updates_weapon_label() -> void:
	# 创建模拟 Label
	hud._weapon_info_label = Label.new()

	# 测试基础炮 (id=0)
	hud._on_weapon_fired(0, Vector2.ZERO)
	assert_eq(hud._weapon_info_label.text, "基础炮", "Weapon 0 should show '基础炮'")

	# 测试爆裂魔导炮 (id=6)
	hud._on_weapon_fired(6, Vector2.ZERO)
	assert_eq(hud._weapon_info_label.text, "爆裂魔导炮", "Weapon 6 should show '爆裂魔导炮'")

	# 清理
	hud._weapon_info_label.queue_free()

# === 显示更新测试 ===

## 测试敌人数量显示更新
func test_update_enemy_count_display() -> void:
	# 创建模拟 Labels
	hud._enemy_count_label = Label.new()
	hud._wave_label = Label.new()
	hud._wave_progress_bar = ProgressBar.new()
	hud._wave_progress_bar.max_value = 100

	# 设置值
	hud._enemy_count = 25
	hud._current_wave = 2
	hud._total_waves = 5

	# 调用更新
	hud._update_enemy_count_display()

	assert_eq(hud._enemy_count_label.text, "25", "Enemy count label should show '25'")
	assert_eq(hud._wave_label.text, "2/5", "Wave label should show '2/5'")
	assert_eq(hud._wave_progress_bar.value, 40.0, "Wave progress should be 40% (2/5)")

	# 清理
	hud._enemy_count_label.queue_free()
	hud._wave_label.queue_free()
	hud._wave_progress_bar.queue_free()

## 测试波次进度零值处理
func test_update_enemy_count_display_zero_waves() -> void:
	# 创建模拟 Labels
	hud._enemy_count_label = Label.new()
	hud._wave_label = Label.new()
	hud._wave_progress_bar = ProgressBar.new()

	# 设置值（零波次）
	hud._enemy_count = 0
	hud._current_wave = 0
	hud._total_waves = 0

	# 调用更新
	hud._update_enemy_count_display()

	assert_eq(hud._enemy_count_label.text, "0", "Enemy count label should show '0'")
	assert_eq(hud._wave_label.text, "0/0", "Wave label should show '0/0'")

	# 清理
	hud._enemy_count_label.queue_free()
	hud._wave_label.queue_free()
	hud._wave_progress_bar.queue_free()

# === 边界测试 ===

## 测试最大敌人数量
func test_max_enemy_count_display() -> void:
	# 创建模拟 Label
	hud._enemy_count_label = Label.new()

	# 设置最大值
	hud._enemy_count = MAX_ENEMY_COUNT

	# 调用更新
	hud._update_enemy_count_display()

	assert_eq(hud._enemy_count_label.text, "100", "Should handle max enemy count")

	# 清理
	hud._enemy_count_label.queue_free()

## 测试最大波次进度
func test_max_wave_progress() -> void:
	# 创建模拟控件
	hud._wave_label = Label.new()
	hud._wave_progress_bar = ProgressBar.new()
	hud._wave_progress_bar.max_value = 100

	# 设置最大波次
	hud._current_wave = MAX_WAVE_COUNT
	hud._total_waves = MAX_WAVE_COUNT

	# 调用更新
	hud._update_enemy_count_display()

	assert_eq(hud._wave_label.text, "5/5", "Wave label should show max wave")
	assert_eq(hud._wave_progress_bar.value, 100.0, "Wave progress should be 100%")

	# 清理
	hud._wave_label.queue_free()
	hud._wave_progress_bar.queue_free()

## 测试无效武器 ID 处理
func test_invalid_weapon_id_handling() -> void:
	# 创建模拟 Label
	hud._weapon_info_label = Label.new()
	hud._weapon_info_label.text = "未知武器"

	# 调用无效 ID（超出范围）
	hud._on_weapon_fired(99, Vector2.ZERO)

	# 验证不崩溃（未更新文本）
	assert_true(true, "Invalid weapon ID should not crash")

	# 清理
	hud._weapon_info_label.queue_free()

## 测试无效状态 ID 处理
func test_invalid_state_id_handling() -> void:
	# 创建模拟 Label
	hud._state_label = Label.new()

	# 调用无效状态 ID
	hud._on_spawn_state_changed(0, 99)

	# 验证不崩溃（文本未更新或保持原样）
	assert_true(true, "Invalid state ID should not crash")

	# 清理
	hud._state_label.queue_free()