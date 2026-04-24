# enemy_loading_test.gd
# Unit tests for Story: Enemy Definition Loading

extends GutTest

const EnemyTypeDBScript := preload("res://src/database/enemy_type_db.gd")

var _enemy_db: Object

func before_all() -> void:
	_enemy_db = EnemyTypeDBScript.new()
	add_child_autoqfree(_enemy_db)

func test_enemy_stats_valid_id() -> void:
	var stats: Object = _enemy_db.get_enemy_stats(1)
	assert_not_null(stats, "Enemy 1 should exist")

func test_enemy_stats_properties() -> void:
	var stats: Object = _enemy_db.get_enemy_stats(1)
	assert_gt(stats.health, 0, "Health should be positive")
	assert_gt(stats.damage, 0, "Damage should be positive")
	assert_gt(stats.speed, 0, "Speed should be positive")

func test_behavior_hint_valid() -> void:
	for enemy_id in _enemy_db.get_all_enemy_ids():
		var hint: String = _enemy_db.get_behavior_hint(enemy_id)
		assert_true(_enemy_db.is_valid_behavior_hint(hint), str(enemy_id) + " hint valid")

func test_behavior_hint_types() -> void:
	assert_true("aggressive" in EnemyTypeDBScript.BEHAVIOR_HINTS, "aggressive in hints")
	assert_true("swarm" in EnemyTypeDBScript.BEHAVIOR_HINTS, "swarm in hints")
	assert_true("wall_breaker" in EnemyTypeDBScript.BEHAVIOR_HINTS, "wall_breaker in hints")
	assert_true("boss" in EnemyTypeDBScript.BEHAVIOR_HINTS, "boss in hints")

func test_invalid_enemy_returns_null() -> void:
	var stats: Object = _enemy_db.get_enemy_stats(999)
	assert_null(stats, "Invalid enemy ID returns null")

func test_boss_exists() -> void:
	var boss: Object = _enemy_db.get_enemy_stats(100)
	assert_not_null(boss, "Boss (100) should exist")
	assert_eq(boss.behavior_hint, "boss", "Boss hint = boss")

func test_get_enemies_by_behavior() -> void:
	var aggressive: Array = _enemy_db.get_enemies_by_behavior("aggressive")
	assert_gt(aggressive.size(), 0, "Should have aggressive enemies")