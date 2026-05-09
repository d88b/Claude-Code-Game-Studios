# weather_manager_test.gd
# WeatherManager 测试 — weather-001
## WeatherManager 测试
## 验证天气类型、效果映射、日夜集成
## QA Plan: production/qa/qa-plan-sprint-5-2026-04-26.md

extends GutTest

# === 测试目标 ===
const WEATHER_MANAGER_PATH: String = "res://src/weather/weather_manager.gd"

# === 常量 ===
const WEATHER_TYPE_COUNT: int = 4  # CLEAR, CLOUDY, RAIN, STORM

# === 测试实例 ===
var weather_manager: Node = null

func before_each() -> void:
	var script: GDScript = load(WEATHER_MANAGER_PATH)
	weather_manager = script.new()
	# 不调用 _ready()（需要场景树和 Autoload）

func after_each() -> void:
	if weather_manager != null and is_instance_valid(weather_manager):
		weather_manager.queue_free()
	weather_manager = null

# === 天气类型枚举测试 ===

## 测试天气类型枚举值
func test_weather_type_enum_values() -> void:
	assert_eq(weather_manager.WeatherType.CLEAR, 0, "CLEAR enum value 0")
	assert_eq(weather_manager.WeatherType.CLOUDY, 1, "CLOUDY enum value 1")
	assert_eq(weather_manager.WeatherType.RAIN, 2, "RAIN enum value 2")
	assert_eq(weather_manager.WeatherType.STORM, 3, "STORM enum value 3")

## 测试天气类型数量
func test_weather_type_count() -> void:
	# 验证枚举数量
	var types: Array = [
		weather_manager.WeatherType.CLEAR,
		weather_manager.WeatherType.CLOUDY,
		weather_manager.WeatherType.RAIN,
		weather_manager.WeatherType.STORM
	]
	assert_eq(types.size(), WEATHER_TYPE_COUNT, "Should have 4 weather types")

# === 天气效果映射测试 ===

## 测试天气效果映射完整性
func test_weather_effects_has_all_types() -> void:
	for weather_type: int in range(WEATHER_TYPE_COUNT):
		assert_true(weather_manager.WEATHER_EFFECTS.has(weather_type), "WEATHER_EFFECTS should have type %d" % weather_type)

## 测试晴天效果默认值
func test_clear_weather_effects() -> void:
	var effects: Dictionary = weather_manager.WEATHER_EFFECTS[weather_manager.WeatherType.CLEAR]
	assert_eq(effects["visibility_mult"], 1.0, "CLEAR visibility = 1.0")
	assert_eq(effects["speed_mult"], 1.0, "CLEAR speed = 1.0")
	assert_eq(effects["accuracy_mult"], 1.0, "CLEAR accuracy = 1.0")
	assert_eq(effects["spawn_rate_mult"], 1.0, "CLEAR spawn_rate = 1.0")

## 测试雨天效果减速
func test_rain_weather_effects() -> void:
	var effects: Dictionary = weather_manager.WEATHER_EFFECTS[weather_manager.WeatherType.RAIN]
	assert_eq(effects["visibility_mult"], 0.7, "RAIN visibility = 0.7")
	assert_eq(effects["speed_mult"], 0.85, "RAIN speed = 0.85")
	assert_eq(effects["accuracy_mult"], 0.8, "RAIN accuracy = 0.8")
	assert_eq(effects["spawn_rate_mult"], 1.2, "RAIN spawn_rate = 1.2")

## 测试风暴效果大幅减速
func test_storm_weather_effects() -> void:
	var effects: Dictionary = weather_manager.WEATHER_EFFECTS[weather_manager.WeatherType.STORM]
	assert_eq(effects["visibility_mult"], 0.5, "STORM visibility = 0.5")
	assert_eq(effects["speed_mult"], 0.6, "STORM speed = 0.6")
	assert_eq(effects["accuracy_mult"], 0.6, "STORM accuracy = 0.6")
	assert_eq(effects["spawn_rate_mult"], 1.5, "STORM spawn_rate = 1.5")

# === 天气名称映射测试 ===

## 测试天气名称映射完整性
func test_weather_names_has_all_types() -> void:
	for weather_type: int in range(WEATHER_TYPE_COUNT):
		assert_true(weather_manager.WEATHER_NAMES.has(weather_type), "WEATHER_NAMES should have type %d" % weather_type)

## 测试天气名称中文
func test_weather_names_chinese() -> void:
	assert_eq(weather_manager.WEATHER_NAMES[weather_manager.WeatherType.CLEAR], "晴朗", "CLEAR name = '晴朗'")
	assert_eq(weather_manager.WEATHER_NAMES[weather_manager.WeatherType.CLOUDY], "多云", "CLOUDY name = '多云'")
	assert_eq(weather_manager.WEATHER_NAMES[weather_manager.WeatherType.RAIN], "雨天", "RAIN name = '雨天'")
	assert_eq(weather_manager.WEATHER_NAMES[weather_manager.WeatherType.STORM], "风暴", "STORM name = '风暴'")

# === 天气概率映射测试 ===

## 测试日夜阶段概率映射完整性
func test_weather_probability_has_all_phases() -> void:
	for phase: int in range(4):  # DAWN, DAY, DUSK, NIGHT
		assert_true(weather_manager.WEATHER_PROBABILITY_BY_PHASE.has(phase), "WEATHER_PROBABILITY should have phase %d" % phase)

## 测试黎明天气概率
func test_dawn_weather_probability() -> void:
	var probs: Dictionary = weather_manager.WEATHER_PROBABILITY_BY_PHASE[0]
	assert_eq(probs[weather_manager.WeatherType.CLEAR], 0.6, "DAWN CLEAR prob = 0.6")
	assert_eq(probs[weather_manager.WeatherType.STORM], 0.0, "DAWN STORM prob = 0.0")

## 测试夜晚天气概率（风暴更高）
func test_night_weather_probability() -> void:
	var probs: Dictionary = weather_manager.WEATHER_PROBABILITY_BY_PHASE[3]
	assert_eq(probs[weather_manager.WeatherType.CLEAR], 0.2, "NIGHT CLEAR prob = 0.2")
	assert_eq(probs[weather_manager.WeatherType.STORM], 0.2, "NIGHT STORM prob = 0.2")

## 测试概率总和为1
func test_probability_sum_is_one() -> void:
	for phase: int in range(4):
		var probs: Dictionary = weather_manager.WEATHER_PROBABILITY_BY_PHASE[phase]
		var total: float = 0.0
		for prob: float in probs.values():
			total += prob
		assert_almost_eq(total, 1.0, 0.01, "Phase %d probability sum should be 1.0" % phase)

# === API 方法测试 ===

## 测试获取当前天气方法
func test_get_current_weather_method() -> void:
	assert_true(weather_manager.has_method("get_current_weather"), "Should have get_current_weather")

## 测试获取效果方法
func test_get_current_effects_method() -> void:
	assert_true(weather_manager.has_method("get_current_effects"), "Should have get_current_effects")

## 测试获取视野系数方法
func test_get_visibility_multiplier_method() -> void:
	assert_true(weather_manager.has_method("get_visibility_multiplier"), "Should have get_visibility_multiplier")

## 测试获取速度系数方法
func test_get_speed_multiplier_method() -> void:
	assert_true(weather_manager.has_method("get_speed_multiplier"), "Should have get_speed_multiplier")

## 测试获取精度系数方法
func test_get_accuracy_multiplier_method() -> void:
	assert_true(weather_manager.has_method("get_accuracy_multiplier"), "Should have get_accuracy_multiplier")

## 测试获取生成系数方法
func test_get_spawn_rate_multiplier_method() -> void:
	assert_true(weather_manager.has_method("get_spawn_rate_multiplier"), "Should have get_spawn_rate_multiplier")

## 测试获取天气名称方法
func test_get_weather_name_method() -> void:
	assert_true(weather_manager.has_method("get_weather_name"), "Should have get_weather_name")

## 测试设置天气方法
func test_set_weather_method() -> void:
	assert_true(weather_manager.has_method("set_weather"), "Should have set_weather")

## 测试随机天气方法
func test_randomize_weather_for_phase_method() -> void:
	assert_true(weather_manager.has_method("randomize_weather_for_phase"), "Should have randomize_weather_for_phase")

## 测试触发风暴方法
func test_trigger_storm_method() -> void:
	assert_true(weather_manager.has_method("trigger_storm"), "Should have trigger_storm")

# === 默认状态测试 ===

## 测试默认天气为晴天
func test_default_weather_is_clear() -> void:
	assert_eq(weather_manager._current_weather, weather_manager.WeatherType.CLEAR, "Default weather should be CLEAR")

## 测试默认效果初始化
func test_default_effects_initialized() -> void:
	# 手动调用效果应用
	weather_manager._apply_weather_effects()
	assert_eq(weather_manager._current_effects["visibility_mult"], 1.0, "Default effects should be CLEAR effects")

## 测试天气名称默认
func test_default_weather_name() -> void:
	weather_manager._current_weather = weather_manager.WeatherType.CLEAR
	assert_eq(weather_manager.get_weather_name(), "晴朗", "Default name should be '晴朗'")

# === 天气变化测试 ===

## 测试设置天气更新状态
func test_set_weather_updates_state() -> void:
	weather_manager.set_weather(weather_manager.WeatherType.RAIN, 300.0)
	assert_eq(weather_manager._current_weather, weather_manager.WeatherType.RAIN, "Weather should update to RAIN")
	assert_eq(weather_manager._weather_duration, 300.0, "Duration should be set")

## 测试设置天气更新效果
func test_set_weather_updates_effects() -> void:
	weather_manager.set_weather(weather_manager.WeatherType.STORM, 180.0)
	assert_eq(weather_manager.get_speed_multiplier(), 0.6, "Speed mult should be 0.6 after STORM")

## 测试相同天气不触发变化
func test_set_same_weather_no_change() -> void:
	weather_manager._current_weather = weather_manager.WeatherType.CLEAR
	weather_manager._current_effects = weather_manager.WEATHER_EFFECTS[weather_manager.WeatherType.CLEAR]

	# 设置相同天气
	weather_manager.set_weather(weather_manager.WeatherType.CLEAR, 300.0)

	# 验证未改变（duration 可能更新）
	assert_eq(weather_manager._current_weather, weather_manager.WeatherType.CLEAR, "Should remain CLEAR")

## 测试触发风暴
func test_trigger_storm_sets_storm() -> void:
	weather_manager.trigger_storm()
	assert_eq(weather_manager._current_weather, weather_manager.WeatherType.STORM, "Should be STORM")
	assert_eq(weather_manager._weather_duration, 180.0, "Storm duration = 180s")

# === 天气名称查询测试 ===

## 测试按类型获取名称
func test_get_weather_name_by_type() -> void:
	assert_eq(weather_manager.get_weather_name_by_type(weather_manager.WeatherType.RAIN), "雨天", "RAIN name = '雨天'")
	assert_eq(weather_manager.get_weather_name_by_type(weather_manager.WeatherType.STORM), "风暴", "STORM name = '风暴'")

# === 边界测试 ===

## 测试无效天气类型名称
func test_invalid_weather_type_name() -> void:
	var name: String = weather_manager.get_weather_name_by_type(99)
	assert_eq(name, "未知", "Invalid type should return '未知'")

## 测试持续时间范围
func test_weather_duration_range() -> void:
	# 测试各阶段持续时间计算
	var dawn_dur: float = weather_manager._get_weather_duration_for_phase(0)
	assert_true(dawn_dur >= 300.0 and dawn_dur <= 600.0, "DAWN duration 5-10 min")

	var dusk_dur: float = weather_manager._get_weather_duration_for_phase(2)
	assert_true(dusk_dur >= 180.0 and dusk_dur <= 300.0, "DUSK duration 3-5 min")

	var night_dur: float = weather_manager._get_weather_duration_for_phase(3)
	assert_true(night_dur >= 120.0 and night_dur <= 240.0, "NIGHT duration 2-4 min")