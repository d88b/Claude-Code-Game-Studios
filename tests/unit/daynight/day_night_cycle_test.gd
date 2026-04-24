# day_night_cycle_test.gd
# Unit tests for Story: Day-Night Phase Manager
# tests/unit/daynight/day_night_cycle_test.gd

extends GutTest

const DayNightCycleScript := preload("res://src/daynight/day_night_cycle.gd")

var _daynight_cycle: Object

func before_all() -> void:
	# 创建 DayNightCycle
	_daynight_cycle = DayNightCycleScript.new()
	add_child_autoqfree(_daynight_cycle)

	# 注入依赖
	_daynight_cycle.set_global_signals(GlobalSignals)
	await get_tree().process_frame

# === 常量验证测试 ===

func test_transition_duration_is_30() -> void:
	assert_eq(_daynight_cycle.TRANSITION_DURATION, 30.0, "TRANSITION_DURATION should be 30.0")

func test_danger_global_mult_is_1() -> void:
	assert_eq(_daynight_cycle.DANGER_GLOBAL_MULT, 1.0, "DANGER_GLOBAL_MULT should be 1.0")

func test_dawn_danger_mult_is_0_8() -> void:
	assert_eq(_daynight_cycle.DAWN_DANGER_MULT, 0.8, "DAWN_DANGER_MULT should be 0.8")

func test_day_danger_mult_is_1_0() -> void:
	assert_eq(_daynight_cycle.DAY_DANGER_MULT, 1.0, "DAY_DANGER_MULT should be 1.0")

func test_dusk_danger_mult_is_1_2() -> void:
	assert_eq(_daynight_cycle.DUSK_DANGER_MULT, 1.2, "DUSK_DANGER_MULT should be 1.2")

func test_night_danger_mult_is_1_5() -> void:
	assert_eq(_daynight_cycle.NIGHT_DANGER_MULT, 1.5, "NIGHT_DANGER_MULT should be 1.5")

# === 阶段枚举测试 ===

func test_phase_dawn_value() -> void:
	assert_eq(_daynight_cycle.Phase.DAWN, 0, "Phase.DAWN should be 0")

func test_phase_day_value() -> void:
	assert_eq(_daynight_cycle.Phase.DAY, 1, "Phase.DAY should be 1")

func test_phase_dusk_value() -> void:
	assert_eq(_daynight_cycle.Phase.DUSK, 2, "Phase.DUSK should be 2")

func test_phase_night_value() -> void:
	assert_eq(_daynight_cycle.Phase.NIGHT, 3, "Phase.NIGHT should be 3")

# === 亮度常量测试 ===

func test_dawn_brightness_range() -> void:
	assert_eq(_daynight_cycle.DAWN_BRIGHTNESS_START, 0.6, "DAWN start brightness")
	assert_eq(_daynight_cycle.DAWN_BRIGHTNESS_END, 0.9, "DAWN end brightness")

func test_day_brightness_is_1() -> void:
	assert_eq(_daynight_cycle.DAY_BRIGHTNESS, 1.0, "DAY brightness should be 1.0")

func test_dusk_brightness_range() -> void:
	assert_eq(_daynight_cycle.DUSK_BRIGHTNESS_START, 0.9, "DUSK start brightness")
	assert_eq(_daynight_cycle.DUSK_BRIGHTNESS_END, 0.5, "DUSK end brightness")

func test_night_brightness_is_0_3() -> void:
	assert_eq(_daynight_cycle.NIGHT_BRIGHTNESS, 0.3, "NIGHT brightness should be 0.3")

# === 查询 API 测试 ===

func test_get_current_phase_returns_phase() -> void:
	assert_true(_daynight_cycle.has_method("get_current_phase"),
		"get_current_phase method should exist")

func test_get_danger_multiplier_returns_float() -> void:
	var mult: float = _daynight_cycle.get_danger_multiplier()
	assert_true(mult > 0.0, "danger_multiplier should be positive")

func test_get_visual_params_returns_dict() -> void:
	var params: Dictionary = _daynight_cycle.get_visual_params()
	assert_true(params.has("brightness"), "visual_params should have brightness")
	assert_true(params.has("sky_color"), "visual_params should have sky_color")
	assert_true(params.has("fog_density"), "visual_params should have fog_density")

func test_get_phase_name_returns_string() -> void:
	var name: String = _daynight_cycle.get_phase_name()
	assert_true(name.length() > 0, "phase_name should not be empty")

# === 危险倍率计算测试 ===

func test_dawn_danger_multiplier_calculation() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DAWN)
	var mult: float = _daynight_cycle.get_danger_multiplier()
	assert_eq(mult, 0.8, "DAWN danger should be 0.8")

func test_day_danger_multiplier_calculation() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DAY)
	var mult: float = _daynight_cycle.get_danger_multiplier()
	assert_eq(mult, 1.0, "DAY danger should be 1.0")

func test_dusk_danger_multiplier_calculation() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DUSK)
	var mult: float = _daynight_cycle.get_danger_multiplier()
	assert_eq(mult, 1.2, "DUSK danger should be 1.2")

func test_night_danger_multiplier_calculation() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.NIGHT)
	var mult: float = _daynight_cycle.get_danger_multiplier()
	assert_eq(mult, 1.5, "NIGHT danger should be 1.5")

# === 视觉参数测试 ===

func test_dawn_sky_color_is_orange() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DAWN)
	var params: Dictionary = _daynight_cycle.get_visual_params()
	var color: Color = params.sky_color
	assert_true(color.r > color.b, "DAWN sky should be warm (orange)")

func test_day_sky_color_is_blue() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DAY)
	var params: Dictionary = _daynight_cycle.get_visual_params()
	var color: Color = params.sky_color
	assert_true(color.b > color.r, "DAY sky should be blue")

func test_night_fog_density_is_higher() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.NIGHT)
	var params_night: Dictionary = _daynight_cycle.get_visual_params()

	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DAY)
	var params_day: Dictionary = _daynight_cycle.get_visual_params()

	assert_true(params_night.fog_density > params_day.fog_density,
		"NIGHT fog should be denser than DAY")

# === 阶段名称测试 ===

func test_dawn_phase_name() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DAWN)
	assert_eq(_daynight_cycle.get_phase_name(), "黎明", "DAWN name should be 黎明")

func test_day_phase_name() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DAY)
	assert_eq(_daynight_cycle.get_phase_name(), "白天", "DAY name should be 白天")

func test_dusk_phase_name() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DUSK)
	assert_eq(_daynight_cycle.get_phase_name(), "黄昏", "DUSK name should be 黄昏")

func test_night_phase_name() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.NIGHT)
	assert_eq(_daynight_cycle.get_phase_name(), "夜晚", "NIGHT name should be 夜晚")

# === 过渡状态测试 ===

func test_transition_starts_on_phase_change() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DAY)
	_daynight_cycle._on_phase_changed(_daynight_cycle.Phase.DUSK)
	assert_true(_daynight_cycle.is_transitioning, "Should be transitioning after phase change")

func test_transition_completes_after_duration() -> void:
	_daynight_cycle.set_phase_for_test(_daynight_cycle.Phase.DAY)
	_daynight_cycle._on_phase_changed(_daynight_cycle.Phase.DUSK)
	_daynight_cycle.transition_timer = _daynight_cycle.TRANSITION_DURATION
	_daynight_cycle._process(0.0)
	assert_false(_daynight_cycle.is_transitioning, "Should not be transitioning after duration")

# === 信号测试 ===

func test_phase_effects_applied_signal_exists() -> void:
	assert_true(_daynight_cycle.has_signal("phase_effects_applied"),
		"phase_effects_applied signal should exist")

# === 依赖注入测试 ===

func test_set_time_system_method_exists() -> void:
	assert_true(_daynight_cycle.has_method("set_time_system"),
		"set_time_system method should exist")

func test_set_global_signals_method_exists() -> void:
	assert_true(_daynight_cycle.has_method("set_global_signals"),
		"set_global_signals method should exist")

func test_is_initialized_method_exists() -> void:
	assert_true(_daynight_cycle.has_method("is_initialized"),
		"is_initialized method should exist")

func test_set_phase_for_test_method_exists() -> void:
	assert_true(_daynight_cycle.has_method("set_phase_for_test"),
		"set_phase_for_test method should exist for testing")