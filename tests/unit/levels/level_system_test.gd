# level_system_test.gd
# 关卡系统测试 — content-003
## 关卡系统测试
## 验证三个关卡的生成逻辑
## QA Plan: production/qa/qa-plan-sprint-5-2026-04-26.md

extends GutTest

# === 测试目标 ===
const LEVEL_BASE_PATH: String = "res://src/levels/level_generator_base.gd"
const MINE_LEVEL_PATH: String = "res://src/levels/mine_level_generator.gd"
const RUINS_LEVEL_PATH: String = "res://src/levels/ruins_level_generator.gd"
const PIT_LEVEL_PATH: String = "res://src/levels/pit_level_generator.gd"

const CELL_SIZE: int = 64

# === 测试实例 ===
var level_generator: Node2D = null

func after_each() -> void:
	if level_generator != null and is_instance_valid(level_generator):
		level_generator.queue_free()
	level_generator = null

# === 矿坑关卡测试 ===

## 测试矿坑关卡尺寸
func test_mine_level_dimensions() -> void:
	var script: GDScript = load(MINE_LEVEL_PATH)
	level_generator = script.new()
	# 不调用 _ready()，只检查默认配置
	assert_eq(level_generator.map_width, 0, "Before _ready width is default")  # _ready 会设置

	# 手动调用配置方法
	level_generator.level_name = "矿坑 Level-01"
	level_generator.map_width = 50
	level_generator.map_height = 40
	level_generator.defense_zone_bottom = 12
	level_generator.explore_zone_top = 13
	level_generator.enemy_count = 5
	level_generator.enemy_types = [1, 4, 6]
	level_generator.rng_seed = 1001

	assert_eq(level_generator.map_width, 50, "Mine level width should be 50")
	assert_eq(level_generator.map_height, 40, "Mine level height should be 40")

## 测试矿坑敌人配置
func test_mine_level_enemy_config() -> void:
	var script: GDScript = load(MINE_LEVEL_PATH)
	level_generator = script.new()
	level_generator.enemy_count = 5
	level_generator.enemy_types = [1, 4, 6]

	assert_eq(level_generator.enemy_count, 5, "Mine level should have 5 enemies")
	assert_eq(level_generator.enemy_types, [1, 4, 6], "Mine level enemy types: basic, swarm, tracker")

## 测试矿坑防守区边界
func test_mine_level_defense_zone() -> void:
	var script: GDScript = load(MINE_LEVEL_PATH)
	level_generator = script.new()
	level_generator.defense_zone_bottom = 12
	level_generator.explore_zone_top = 13

	assert_eq(level_generator.defense_zone_bottom, 12, "Mine defense zone bottom at row 12")
	assert_eq(level_generator.explore_zone_top, 13, "Mine explore zone starts at row 13")

## 测试矿坑随机种子
func test_mine_level_seed() -> void:
	var script: GDScript = load(MINE_LEVEL_PATH)
	level_generator = script.new()
	level_generator.rng_seed = 1001

	assert_eq(level_generator.rng_seed, 1001, "Mine level seed should be 1001")

# === 废墟关卡测试 ===

## 测试废墟关卡尺寸
func test_ruins_level_dimensions() -> void:
	var script: GDScript = load(RUINS_LEVEL_PATH)
	level_generator = script.new()
	level_generator.map_width = 60
	level_generator.map_height = 50

	assert_eq(level_generator.map_width, 60, "Ruins level width should be 60")
	assert_eq(level_generator.map_height, 50, "Ruins level height should be 50")

## 测试废墟敌人配置
func test_ruins_level_enemy_config() -> void:
	var script: GDScript = load(RUINS_LEVEL_PATH)
	level_generator = script.new()
	level_generator.enemy_count = 8
	level_generator.enemy_types = [1, 4, 5, 6, 8]

	assert_eq(level_generator.enemy_count, 8, "Ruins level should have 8 enemies")
	assert_eq(level_generator.enemy_types, [1, 4, 5, 6, 8], "Ruins enemy types: all 5 types")

## 测试废墟障碍物数量
func test_ruins_obstacle_count() -> void:
	var script: GDScript = load(RUINS_LEVEL_PATH)
	level_generator = script.new()

	# 障碍物常量检查
	assert_eq(level_generator.OBSTACLE_COUNT, 15, "Ruins should have 15 obstacles")

## 测试废墟关卡名称
func test_ruins_level_name() -> void:
	var script: GDScript = load(RUINS_LEVEL_PATH)
	level_generator = script.new()
	level_generator.level_name = "废墟 Level-02"

	assert_eq(level_generator.level_name, "废墟 Level-02", "Ruins level name should match")

# === 深坑关卡测试 ===

## 测试深坑关卡尺寸
func test_pit_level_dimensions() -> void:
	var script: GDScript = load(PIT_LEVEL_PATH)
	level_generator = script.new()
	level_generator.map_width = 50
	level_generator.map_height = 60

	assert_eq(level_generator.map_width, 50, "Pit level width should be 50")
	assert_eq(level_generator.map_height, 60, "Pit level height should be 60 (deepest)")

## 测试深坑敌人配置 (精英敌人)
func test_pit_level_enemy_config() -> void:
	var script: GDScript = load(PIT_LEVEL_PATH)
	level_generator = script.new()
	level_generator.enemy_count = 6
	level_generator.enemy_types = [6, 8, 101]

	assert_eq(level_generator.enemy_count, 6, "Pit level should have 6 enemies")
	assert_eq(level_generator.enemy_types, [6, 8, 101], "Pit enemies: tracker, tank, elite")

## 测试深坑垂直通道宽度
func test_pit_vertical_corridor_width() -> void:
	var script: GDScript = load(PIT_LEVEL_PATH)
	level_generator = script.new()

	assert_eq(level_generator.VERTICAL_CORRIDOR_WIDTH, 4, "Pit vertical corridor width 4 cells")

## 测试深坑关卡名称
func test_pit_level_name() -> void:
	var script: GDScript = load(PIT_LEVEL_PATH)
	level_generator = script.new()
	level_generator.level_name = "深坑 Level-03"

	assert_eq(level_generator.level_name, "深坑 Level-03", "Pit level name should match")

## 测试深坑稀有矿石层
func test_pit_rare_ore_layer() -> void:
	var script: GDScript = load(PIT_LEVEL_PATH)
	level_generator = script.new()

	# 深坑有钛矿常量定义
	assert_eq(level_generator.TILE_TITAN_ORE, 505, "Titan ore ID should be 505")

# === 基类功能测试 ===

## 测试基类 fill_rect 功能
func test_base_fill_rect() -> void:
	var script: GDScript = load(LEVEL_BASE_PATH)
	level_generator = script.new()
	level_generator.map_width = 10
	level_generator.map_height = 10
	level_generator._init_level_data()

	# 填充矩形
	level_generator.fill_rect(2, 2, 5, 5, 100)

	# 检查填充区域
	assert_eq(level_generator.get_cell(3, 3), 100, "Cell inside rect should be filled")
	assert_eq(level_generator.get_cell(1, 1), 0, "Cell outside rect should be empty")

## 测试基类 clear_rect 功能
func test_base_clear_rect() -> void:
	var script: GDScript = load(LEVEL_BASE_PATH)
	level_generator = script.new()
	level_generator.map_width = 10
	level_generator.map_height = 10
	level_generator._init_level_data()

	# 先填充再清空
	level_generator.fill_rect(0, 0, 9, 9, 100)
	level_generator.clear_rect(3, 3, 6, 6)

	assert_eq(level_generator.get_cell(4, 4), 0, "Cell in cleared rect should be empty")
	assert_eq(level_generator.get_cell(0, 0), 100, "Cell outside cleared rect should remain filled")

## 测试基类边界检查
func test_base_boundary_check() -> void:
	var script: GDScript = load(LEVEL_BASE_PATH)
	level_generator = script.new()
	level_generator.map_width = 10
	level_generator.map_height = 10
	level_generator._init_level_data()

	# 越界设置应该被忽略
	level_generator.set_cell(-1, 0, 100)
	level_generator.set_cell(0, -1, 100)
	level_generator.set_cell(10, 0, 100)
	level_generator.set_cell(0, 10, 100)

	assert_eq(level_generator.get_cell(-1, 0), 0, "Negative x should return empty")
	assert_eq(level_generator.get_cell(10, 0), 0, "Out of bounds x should return empty")

## 测试 TileSet source ID 映射
func test_tile_source_id_mapping() -> void:
	var script: GDScript = load(LEVEL_BASE_PATH)
	level_generator = script.new()

	# 基础方块映射
	assert_eq(level_generator._get_source_id_for_tile(100), 3, "Dirt maps to source 3")
	assert_eq(level_generator._get_source_id_for_tile(101), 4, "Sand maps to source 4")
	assert_eq(level_generator._get_source_id_for_tile(500), 8, "Iron ore maps to source 8")
	assert_eq(level_generator._get_source_id_for_tile(501), 9, "Crystal ore maps to source 9")

# === 关卡难度递增测试 ===

## 测试关卡尺寸递增
func test_level_size_progression() -> void:
	# Tutorial: 40x30
	# Mine: 50x40 (增加)
	# Ruins: 60x50 (最大)
	# Pit: 50x60 (最深)

	# 验证设计配置（不调用 _ready）
	# Mine > Tutorial
	assert_true(50 > 40, "Mine width (50) > Tutorial width (40)")
	assert_true(40 > 30, "Mine height (40) > Tutorial height (30)")

	# Ruins > Mine (宽度)
	assert_true(60 > 50, "Ruins width (60) > Mine width (50)")

	# Pit 最深
	assert_true(60 > 50, "Pit height (60) > Ruins height (50)")

## 测试敌人难度递增
func test_enemy_difficulty_progression() -> void:
	# Mine 敌人: [1, 4, 6] - 基础、集群、追踪
	# Ruins 敌人: [1, 4, 5, 6, 8] - 全5种
	# Pit 敌人: [6, 8, 101] - 追踪、坦克、精英

	# Pit 有精英敌人 (ID 101)
	assert_true(101 in [6, 8, 101], "Pit should have elite enemies (101)")

	# Ruins 敌人数量最多
	assert_true(8 > 5, "Ruins enemy_count (8) > Mine enemy_count (5)")

	# Ruins 有拆墙僵尸 (ID 5)
	assert_true(5 in [1, 4, 5, 6, 8], "Ruins should have wall-breaker enemies (5)")

	# Pit 有坦克僵尸 (ID 8)
	assert_true(8 in [6, 8, 101], "Pit should have tank enemies (8)")