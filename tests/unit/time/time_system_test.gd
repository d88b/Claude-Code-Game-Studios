# time_system_test.gd
# Unit tests for Story 006: Time System Autoload
# Tests verify time scale, hour/phase calculations, signal emissions

extends GutTest

const TimeSystemScript := preload("res://src/time/time_system.gd")

var _time_system: Object

func before_all() -> void:
	# 创建 TimeSystem 实例
	_time_system = TimeSystemScript.new()
	add_child_autoqfree(_time_system)

# === AC-1: Time scale validation ===

func test_time_scale_default() -> void:
	# TIME_SCALE = 60 (1 real second = 60 game seconds)
	assert_eq(_time_system.TIME_SCALE_DEFAULT, 60.0, "TIME_SCALE should be 60")

func test_time_scale_applied() -> void:
	assert_eq(_time_system.time_scale, 60.0, "Default time_scale should be 60")

func test_time_scale_modifiable() -> void:
	_time_system.set_time_scale(120.0)
	assert_eq(_time_system.time_scale, 120.0, "time_scale should be modifiable")
	# Reset
	_time_system.set_time_scale(60.0)

# === AC-2: Day cycle duration ===

func test_day_duration() -> void:
	# 10 minutes real time = 1 day cycle
	assert_eq(_time_system.DAY_DURATION_SECONDS, 600.0, "Day duration 10 min")

# === AC-3: get_current_hour returns 0-23 ===

func test_get_current_hour_range() -> void:
	var hour: int = _time_system.get_current_hour()
	assert_gt(hour, -1, "hour >= 0")
	assert_lt(hour, 24, "hour < 24")

func test_get_current_hour_at_midnight() -> void:
	_time_system.set_time(0.0)
	assert_eq(_time_system.get_current_hour(), 0, "Midnight = hour 0")

func test_get_current_hour_at_noon() -> void:
	_time_system.set_time(12.0 * 3600.0)  # 12:00
	assert_eq(_time_system.get_current_hour(), 12, "Noon = hour 12")

func test_get_current_hour_at_end_of_day() -> void:
	_time_system.set_time(23.5 * 3600.0)  # 23:30
	assert_eq(_time_system.get_current_hour(), 23, "End of day = hour 23")

# === AC-4: get_phase returns DAWN/DAY/DUSK/NIGHT ===

func test_get_phase_returns_enum() -> void:
	var phase: int = _time_system.get_phase()
	assert_true(phase in [TimeSystemScript.DayPhase.DAWN, TimeSystemScript.DayPhase.DAY, TimeSystemScript.DayPhase.DUSK, TimeSystemScript.DayPhase.NIGHT], "Valid phase")

func test_phase_night_early() -> void:
	# hour < 5 → NIGHT
	_time_system.set_time(3.0 * 3600.0)  # 3:00 AM
	assert_eq(_time_system.get_phase(), TimeSystemScript.DayPhase.NIGHT, "3 AM = NIGHT")

func test_phase_dawn() -> void:
	# hour 5-6 → DAWN
	_time_system.set_time(6.0 * 3600.0)  # 6:00 AM
	assert_eq(_time_system.get_phase(), TimeSystemScript.DayPhase.DAWN, "6 AM = DAWN")

func test_phase_day() -> void:
	# hour 7-16 → DAY
	_time_system.set_time(10.0 * 3600.0)  # 10:00 AM
	assert_eq(_time_system.get_phase(), TimeSystemScript.DayPhase.DAY, "10 AM = DAY")

func test_phase_dusk() -> void:
	# hour 17-18 → DUSK
	_time_system.set_time(18.0 * 3600.0)  # 18:00 (6 PM)
	assert_eq(_time_system.get_phase(), TimeSystemScript.DayPhase.DUSK, "6 PM = DUSK")

func test_phase_night_late() -> void:
	# hour 19-23 → NIGHT
	_time_system.set_time(20.0 * 3600.0)  # 20:00 (8 PM)
	assert_eq(_time_system.get_phase(), TimeSystemScript.DayPhase.NIGHT, "8 PM = NIGHT")

# === AC-5: Phase boundaries ===

func test_phase_boundary_dawn_start() -> void:
	# hour 5 → DAWN starts
	_time_system.set_time(5.0 * 3600.0)
	assert_eq(_time_system.get_phase(), TimeSystemScript.DayPhase.DAWN, "5:00 = DAWN start")

func test_phase_boundary_day_start() -> void:
	# hour 7 → DAY starts
	_time_system.set_time(7.0 * 3600.0)
	assert_eq(_time_system.get_phase(), TimeSystemScript.DayPhase.DAY, "7:00 = DAY start")

func test_phase_boundary_dusk_start() -> void:
	# hour 17 → DUSK starts
	_time_system.set_time(17.0 * 3600.0)
	assert_eq(_time_system.get_phase(), TimeSystemScript.DayPhase.DUSK, "17:00 = DUSK start")

func test_phase_boundary_night_start() -> void:
	# hour 19 → NIGHT starts
	_time_system.set_time(19.0 * 3600.0)
	assert_eq(_time_system.get_phase(), TimeSystemScript.DayPhase.NIGHT, "19:00 = NIGHT start")

# === AC-6: Signal emissions ===

func test_signal_time_hour_changed_emitted() -> void:
	# 监听信号
	watch_signals(_time_system)
	_time_system.set_time(0.0)
	_time_system.set_time(1.0 * 3600.0)  # 1:00
	assert_signal_emitted(_time_system, "time_hour_changed", "Hour change should emit signal")

func test_signal_day_phase_changed_emitted() -> void:
	watch_signals(_time_system)
	_time_system.set_time(6.0 * 3600.0)  # DAWN
	_time_system.set_time(7.0 * 3600.0)  # DAY
	assert_signal_emitted(_time_system, "day_phase_changed", "Phase change should emit signal")

# === Day count ===

func test_day_count_initial() -> void:
	_time_system.set_time(0.0)
	assert_eq(_time_system.get_day_count(), 0, "Initial day count = 0")

func test_day_count_after_one_day() -> void:
	_time_system.set_time(86400.0)  # 24 hours
	assert_eq(_time_system.get_day_count(), 1, "After 24 hours = day 1")

# === Danger multiplier ===

func test_danger_multiplier_day() -> void:
	_time_system.set_time(10.0 * 3600.0)  # DAY
	assert_eq(_time_system.get_danger_multiplier(), 1.0, "Day danger = 1.0")

func test_danger_multiplier_night() -> void:
	_time_system.set_time(20.0 * 3600.0)  # NIGHT
	assert_eq(_time_system.get_danger_multiplier(), 2.0, "Night danger = 2.0")