# ADR-002: Database Loading Strategy

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

所有静态数据数据库（BlockTypeDB, ResourceDB, EnemyTypeDB, BuildItemDB, VehicleTypeDB, ScavengeContainerDB）使用 RefCounted 单例 Autoload，从 entities.yaml 加载。这解决数据驱动设计的核心问题，确保所有游戏数值外部配置，禁止硬编码。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Resource loading, Data structures) |
| **Knowledge Risk** | LOW — RefCounted and Resource loading stable since Godot 3.x |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` (Resource loading unchanged) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — RefCounted and Resource API stable |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | None (Foundation layer, no dependencies) |
| **Enables** | All systems that read static data (TileMapWorld, VehicleController, EnemyAIController, etc.) |
| **Blocks** | All Core layer implementation until Accepted |
| **Ordering Note** | Must be created after ADR-005 (Event Bus) and ADR-001 (TileMap) — Foundation layer ADRs |

## Context

### Problem Statement

铁锈魔潮有 6 个静态数据数据库：
- BlockTypeDB: 方块类型（碰撞属性、挖掘难度、资源掉落）
- ResourceDB: 资源类型（堆叠上限、类别、显示名）
- EnemyTypeDB: 敌人类型（属性、行为提示、动画）
- BuildItemDB: 建造物品（成本、地形支持、放置规则）
- VehicleTypeDB: 战车类型（属性、状态定义）
- ScavengeContainerDB: 搜刮容器（战利品表、概率权重）

如何组织这些数据库，确保数据驱动、类型安全、性能高效？

### Current State

entities.yaml 定义了所有常量（TK-001 到 TK-048），但 GDD 中数据库结构分散在各自文档。

### Constraints

- 数据必须从 YAML 文件加载（禁止硬编码）
- 数据库必须是全局可访问（多个系统需要）
- 数据库必须类型安全（GDScript static typing）
- 加载必须在游戏启动前完成（Autoload phase）
- 内存占用必须合理（6 databases < 1MB total）

### Requirements

- 数据驱动：所有数值来自 YAML/JSON
- 全局访问：Autoload 单例
- 类型安全：每个数据库有明确接口
- 快速查询：O(1) 或 O(log n) lookup
- 易扩展：添加新数据类型无需改架构

## Decision

**RefCounted Autoload Database Pattern**：
- 每个数据库是一个 RefCounted 单例（Autoload）
- 数据从 entities.yaml 加载，解析为内部 Dictionary
- 公开明确的查询 API（get_by_id, get_by_category 等）
- 启动时一次性加载，运行时只读

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         DATABASE LOADING ARCHITECTURE                         │
└─────────────────────────────────────────────────────────────────────────────┘

entities.yaml (Source Data)
│
├─── tuning_knobs: TK-001 to TK-048 (constants)
├─── block_types: Block definitions
├─── resources: Resource definitions
├─── enemy_types: Enemy definitions
├─── build_items: Build item definitions
├─── vehicle_types: Vehicle definitions
└─── scavenge_containers: Container definitions
│
│ (Loaded at startup)
│
▼
GameConfig (Autoload — parses entities.yaml)
│
├─── load_all_databases() → calls each DB's load_from_yaml()
│
└─── get_tuning_knob(tk_id: String) → float
│
▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                     DATABASE SINGLETONS (RefCounted Autoloads)                │
└─────────────────────────────────────────────────────────────────────────────┘

BlockTypeDB (RefCounted Autoload)
│
├─── internal: {block_id: BlockDefinition}
├─── load_from_yaml(yaml_path: String)
├─── get_collision_profile(block_id: int) → CollisionProfile
├─── get_dig_difficulty(block_id: int) → float
├─── get_display_name(block_id: int) → String
└─── is_valid_block(block_id: int) → bool

ResourceDB (RefCounted Autoload)
│
├─── internal: {resource_id: ResourceDefinition}
├─── get_resource(resource_id: int) → ResourceDefinition
├─── get_max_stack_size(resource_id: int) → int
└─── can_store_in_vehicle(resource_id: int) → bool

EnemyTypeDB (RefCounted Autoload)
│
├─── internal: {enemy_id: EnemyDefinition}
├─── get_enemy_stats(enemy_id: int) → EnemyStats
├─── get_behavior_hint(enemy_id: int) → BehaviorHint
└─── is_valid_enemy(enemy_id: int) → bool

BuildItemDB (RefCounted Autoload)
│
├─── internal: {item_id: BuildItemDefinition}
├─── get_build_cost(item_id: int) → Dictionary
├─── check_terrain_support(item_id: int, terrain_type: int) → bool
└─── is_valid_build_item(item_id: int) → bool

VehicleTypeDB (RefCounted Autoload)
│
├─── internal: {vehicle_id: VehicleDefinition}
├─── get_vehicle_stats(vehicle_id: int) → VehicleStats
├─── get_default_vehicle() → int
└─── is_valid_vehicle(vehicle_id: int) → bool

ScavengeContainerDB (RefCounted Autoload)
│
├─── internal: {container_id: ContainerDefinition}
├─── get_loot_table(container_id: int) → LootTable
├─── roll_loot(container_id: int) → Array[ResourceDrop]
└─── is_valid_container(container_id: int) → bool


Data Definition Structures:
─────────────────────────────────────────────────────────────────────────────

BlockDefinition:
    id: int
    display_name: String      # 中文名称
    category: String          # terrain, structure, platform, facility
    collision_profile: CollisionProfile
    dig_difficulty: float
    resource_drops: Array[ResourceDrop]

CollisionProfile:
    is_solid: bool
    collision_layer: int      # 1=terrain, 2=structure, 4=platform
    friction: float

ResourceDefinition:
    id: int
    display_name: String
    stack_size: int           # 最大堆叠数
    category: String          # raw_material, processed, component, ammo

EnemyDefinition:
    id: int
    display_name: String
    stats: EnemyStats
    behavior_hint: BehaviorHint  # 8 types
    animations: Dictionary

EnemyStats:
    health: float
    damage: float
    armor: float
    speed: float

BehaviorHint: Enum
    aggressive, defensive, swarm, wall_breaker, tracker, ambusher, retreat_early, boss

BuildItemDefinition:
    id: int
    display_name: String
    cost: Dictionary          # {resource_id: count}
    terrain_support: Array[int]  # 可放置的 terrain 类型
    placement_rules: PlacementRule

VehicleDefinition:
    id: int
    display_name: String
    stats: VehicleStats
    state_machine: Array[String]  # GARAGE_IDLE, DEPLOYABLE, etc.

VehicleStats:
    max_health: float
    armor: float
    magic_pool: float
    max_speed: float
    acceleration_rate: float

ContainerDefinition:
    id: int
    display_name: String
    loot_table: LootTable

LootTable:
    entries: Array[LootEntry]
    total_weight: float

LootEntry:
    resource_id: int
    count_range: Vector2i     # min-max
    weight: float             # probability weight
─────────────────────────────────────────────────────────────────────────────
```

### Key Interfaces

```gdscript
# BlockTypeDB — Public API
# File: src/foundation/block_type_db.gd

class_name BlockTypeDB extends RefCounted

# === Internal State ===
var _definitions: Dictionary = {}  # {block_id: BlockDefinition}

# === Public Methods ===
func load_from_yaml(yaml_path: String) -> void:
    var file = FileAccess.open(yaml_path, FileAccess.READ)
    var yaml_data = YAML.parse(file.get_as_text())  # Assuming YAML parser
    for block_data in yaml_data["block_types"]:
        var def = BlockDefinition.from_dict(block_data)
        _definitions[def.id] = def

func get_collision_profile(block_type_id: int) -> CollisionProfile:
    if not _definitions.has(block_type_id):
        return CollisionProfile.DEFAULT_PASSABLE
    return _definitions[block_type_id].collision_profile

func get_dig_difficulty(block_type_id: int) -> float:
    if not _definitions.has(block_type_id):
        return -1.0  # Undiggable
    return _definitions[block_type_id].dig_difficulty

func get_display_name(block_type_id: int) -> String:
    if not _definitions.has(block_type_id):
        return "Unknown Block"
    return _definitions[block_type_id].display_name

func is_valid_block(block_type_id: int) -> bool:
    return _definitions.has(block_type_id)

func get_blocks_by_category(category: String) -> Array[int]:
    var result: Array[int] = []
    for block_id in _definitions:
        if _definitions[block_id].category == category:
            result.append(block_id)
    return result


# ResourceDB — Public API
# File: src/foundation/resource_db.gd

class_name ResourceDB extends RefCounted

var _definitions: Dictionary = {}

func load_from_yaml(yaml_path: String) -> void:
    # Similar to BlockTypeDB

func get_resource(resource_id: int) -> ResourceDefinition:
    return _definitions.get(resource_id, ResourceDefinition.DEFAULT)

func get_max_stack_size(resource_id: int) -> int:
    return _definitions[resource_id].stack_size

func get_category(resource_id: int) -> String:
    return _definitions[resource_id].category

func can_store_in_vehicle(resource_id: int) -> bool:
    # All resources except "special" category
    return _definitions[resource_id].category != "special"


# GameConfig — Tuning Knobs Access
# File: src/foundation/game_config.gd

class_name GameConfig extends RefCounted

var _tuning_knobs: Dictionary = {}  # {TK_id: float}

func load_from_yaml(yaml_path: String) -> void:
    var yaml_data = YAML.parse(FileAccess.open(yaml_path, FileAccess.READ).get_as_text())
    for tk in yaml_data["tuning_knobs"]:
        _tuning_knobs[tk["id"]] = tk["value"]

func get_tuning_knob(tk_id: String) -> float:
    # Example: GameConfig.get_tuning_knob("TK-013") returns 0.5 (MAGIC_COST_PER_CELL)
    return _tuning_knobs.get(tk_id, 0.0)

# Convenience constants (referenced by TK-ID):
const MAGIC_COST_PER_CELL: float = 0.5   # TK-013
const MAX_SWEPT_STEPS: int = 64          # TK-018
const SEPARATION_FORCE: float = 0.3      # TK-064
const STORAGE_CAPACITY: int = 100        # TK-032
```

### Implementation Guidelines

1. **Autoload Registration**: 在 `project.godot` 中注册所有数据库为 Autoload：
   - `GameConfig` → `game_config`
   - `BlockTypeDB` → `block_type_db`
   - `ResourceDB` → `resource_db`
   - `EnemyTypeDB` → `enemy_type_db`
   - `BuildItemDB` → `build_item_db`
   - `VehicleTypeDB` → `vehicle_type_db`
   - `ScavengeContainerDB` → `scavenge_container_db`

2. **YAML Parser**: 使用 Godot YAML parser addon 或自定义解析（YAML → JSON → Godot dict）

3. **Data Definition Classes**: 每个定义类型是一个独立的 `class_name`（BlockDefinition, ResourceDefinition 等）

4. **Startup Order**: GameConfig 最先加载，然后是各数据库（alphabetical 或 dependency order）

5. **Error Handling**: `is_valid_*()` 方法返回 bool，无效 ID 返回默认值或 -1

6. **中文注释**: 所有数据定义必须包含 `display_name` 中文名称

## Alternatives Considered

### Alternative 1: JSON Files per Database

- **Description**: 每个 DB 一个 JSON 文件（block_types.json, resources.json 等）
- **Pros**: 更易编辑，Godot 内置 JSON parser
- **Cons**: entities.yaml 已存在，拆分增加文件数量，同步困难
- **Estimated Effort**: 相同
- **Rejection Reason**: entities.yaml 是现有数据源，不应拆分

### Alternative 2: Godot Resource Files (.tres)

- **Description**: 使用 Godot Resource 系统（BlockTypeResource.tres）
- **Pros**: Godot 内置支持，编辑器可视化
- **Cons**: 不易批量编辑，YAML 更适合大量数据
- **Estimated Effort**: 更高
- **Rejection Reason**: YAML 是更灵活的批量数据格式

### Alternative 3: Inline Data (Hardcoded)

- **Description**: 数据直接写在 GDScript 中
- **Pros**: 最简单，无需加载
- **Cons**: 违反数据驱动原则，难以调整数值
- **Estimated Effort**: 更低
- **Rejection Reason**: 项目原则明确禁止硬编码，必须数据驱动

## Consequences

### Positive

- 数据驱动：所有数值来自 entities.yaml，调整无需改代码
- 类型安全：每个数据库有明确接口和返回类型
- 全局访问：Autoload 确保任何系统可查询数据
- 性能：O(1) Dictionary lookup
- 易扩展：添加新数据类型只需扩展 Definition class

### Negative

- Autoload 数量多（7 个数据库 Autoload）
- YAML parser 需额外依赖或自定义实现
- 启动加载时间增加（一次性加载所有数据）

### Neutral

- 这是数据驱动游戏的标准模式，无特殊创新

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| YAML parser 性能问题 | Low | Low | Test load time, consider JSON fallback |
| entities.yaml 格式错误 | Medium | Medium | Validate schema at startup |
| 数据库 ID 冲突 | Low | Medium | Cross-reference validation in /consistency-check |
| Autoload 数量过多 | Low | Low | 7 Autoloads is acceptable for 512MB budget |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| Memory (databases) | 0 | <1MB | 512MB ceiling |
| Load Time (startup) | 0 | <100ms total | <500ms acceptable |
| Query Time | 0 | O(1) dict lookup | <0.01ms per query |

估算：每数据库 100-500 entries，每个 entry 100 bytes → ~50KB per DB → ~350KB total。

## Migration Plan

新架构，无迁移。

**Rollback plan**: If YAML proves problematic, convert entities.yaml to JSON and use Godot built-in JSON parser.

## Validation Criteria

- [ ] All 6 database Autoloads registered in project.godot
- [ ] GameConfig.get_tuning_knob("TK-013") returns 0.5
- [ ] BlockTypeDB.get_collision_profile(1) returns valid CollisionProfile
- [ ] ResourceDB.get_max_stack_size(100) returns 100
- [ ] EnemyTypeDB.get_behavior_hint(1) returns valid BehaviorHint enum
- [ ] VehicleTypeDB.get_default_vehicle() returns valid vehicle_id
- [ ] ScavengeContainerDB.roll_loot(1) returns valid Array[ResourceDrop]
- [ ] All display_name fields contain Chinese text

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/block-type-database.md` | BlockTypeDB | Block collision profiles, dig difficulty | `get_collision_profile()`, `get_dig_difficulty()` |
| `design/gdd/resource-database.md` | ResourceDB | Stack size limits, categories | `get_max_stack_size()`, `get_category()` |
| `design/gdd/enemy-type-database.md` | EnemyTypeDB | Enemy stats, behavior hints | `get_enemy_stats()`, `get_behavior_hint()` |
| `design/gdd/build-item-database.md` | BuildItemDB | Build costs, terrain support | `get_build_cost()`, `check_terrain_support()` |
| `design/gdd/vehicle-type-database.md` | VehicleTypeDB | Vehicle stats, state definitions | `get_vehicle_stats()` |
| `design/gdd/scavenge-container-database.md` | ScavengeContainerDB | Loot tables, probability weights | `get_loot_table()`, `roll_loot()` |
| `design/registry/entities.yaml` | All | TK-001 to TK-048 constants | GameConfig.get_tuning_knob(tk_id) |

## Related

- ADR-001: TileMap System Architecture — uses BlockTypeDB for tile source_id, collision
- ADR-006: Collision System Architecture — uses BlockTypeDB.get_collision_profile()
- ADR-007: Vehicle State Machine Architecture — uses VehicleTypeDB.get_vehicle_stats()
- ADR-010: Enemy AI Architecture — uses EnemyTypeDB.get_behavior_hint()
- ADR-014: Facility System Architecture — uses BuildItemDB for facility definitions