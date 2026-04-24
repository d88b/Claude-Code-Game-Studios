# 敌人生成系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 3 (尸潮即高潮)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #37 (from systems-index.md)

## Overview

敌人生成系统是管理敌人实例动态创建的核心系统。根据尸潮配置（enemy_id列表、数量、位置范围）调用EnemyTypeDatabase读取敌人定义，在TileMapWorld指定位置创建敌人CharacterBody2D实例，初始化EnemyAI组件，并向下游系统暴露敌人列表供目标查询。

**数据层定位**：生成系统处理敌人实例的生命周期管理：
- 读取EnemyTypeDatabase的spawn_weight、unlock_day进行生成选择
- 调用TileMapWorld的`map_to_local()`转换cell→world坐标
- 使用PackedScene.instantiate()创建敌人节点，add_child()添加到场景
- 初始化EnemyAIController组件，传入enemy_id和初始位置
- 维护active_enemy_list供炮塔系统、陷阱系统查询目标

**玩家感知层**：玩家通过以下方式直接感知生成系统行为：
- 尸潮预警：UI显示即将到来的敌人类型图标（由生成配置决定）
- 敌人出现：在生成位置看到敌人实体从生成动画出现（淡入/召唤特效）
- 数量压迫：大规模生成创造视觉上的"尸潮"数量感
- 阵营识别：不同阵营敌人从不同区域生成（墓园从地面、地狱从深渊裂缝、塔楼从机械门、元素从晶石）

**系统必要性**：没有敌人生成系统，游戏将无法：
- 实现尸潮周期系统的生成需求（无法创建敌人实例）
- 为敌人AI系统提供运行实体（AI无敌人可驱动）
- 为炮塔系统提供攻击目标（炮塔无敌人可瞄准）
- 创造尸潮的真实视觉压力（敌人不出现）

**服务于支柱**：
- **Pillar 3 (尸潮即高潮)**：生成系统是尸潮"出现感"的核心来源——生成动画、生成位置、生成数量共同创造尸潮来临的视觉冲击。多类型敌人同时生成将"威胁预告"转化为"即时压力"。

## Player Fantasy

**情感目标：威胁降临的视觉冲击**

敌人生成系统创造"敌人出现"的戏剧性时刻，玩家感知分为两个层次：

1. **直接体验层**：玩家在尸潮开始时亲眼目睹敌人从生成点"涌现"——墓园阵营从地面裂缝爬出（蠕动上升动画），地狱阵营从深渊裂缝喷射而出（火焰粒子爆发），塔楼阵营从机械门中走出（锈铁门打开+机械步态），元素阵营从晶石中凝聚（光芒粒子聚合）。每次生成都是一个"威胁降临"的视觉事件，玩家能追踪生成位置并预判敌人动向。

2. **间接压迫层**：生成数量、生成节奏、生成位置组合创造"数量压迫感"。当生成系统连续创建50+敌人时，玩家感受到真正的"尸潮"压力——敌人不再是零散威胁，而是涌向防线的浪潮。生成节奏（每波次间隔）创造"喘息窗口"和"新一轮压力"的节奏交替，玩家在间隔期间修补防线、调整站位，然后迎接下一波生成。

**锚定时刻**：第一次尸潮来临，生成系统在3秒内连续创建20个墓园丧尸（SWARM_CHARGE）、3个骷髅拆墙工（WALL_BREAKER）、2个地狱小鬼（TRACKER_HUNT）。玩家看到地面裂缝同时涌出大量敌人，追踪小鬼从深渊裂缝射出，感受到多阵营、多类型同时出现的视觉冲击——这一刻定义了"尸潮即高潮"的核心体验。

**支柱服务**：生成系统直接服务**Pillar 3 (尸潮即高潮)**。生成动画、生成位置分布、生成数量规模共同构成尸潮的"出现仪式"——玩家不会感受到无中生有的敌人突然攻击，而是目睹威胁从明确的生成点涌向防线。这种可追踪的出现机制将尸潮从"随机压力"转化为"可应对的浪潮"。

## Detailed Design

### Core Rules

1. **生成请求接口**：生成系统接收生成配置（spawn_config），包含：enemy_id列表、每种类型数量、生成位置范围（spawn_zone）、生成延迟间隔（spawn_interval）。系统根据配置批量创建敌人实例。

2. **生成选择规则**：当需要生成敌人时，系统调用`EnemyTypeDatabase.get_enemies_by_unlock_day(current_day)`获取当天解锁敌人列表，然后根据spawn_weight进行加权随机选择：
   - 计算所有候选敌人的spawn_weight总和
   - 随机数`rand = randf() * total_weight`
   - 累加spawn_weight直到超过rand，选中该敌人类型

3. **位置生成规则**：生成位置从spawn_zone（预定义区域）中随机选取：
   - spawn_zone定义：`Rect2i(min_cell, max_cell)` 范围
   - 位置选择：`cell = Vector2i(randi_range(min.x, max.x), randi_range(min.y, max.y))`
   - 坐标转换：`world_pos = TileMapWorld.map_to_local(cell)`
   - 位置验证：检查该cell是否可行走（不在墙体内）

4. **实例创建流程**：创建敌人实例的完整流程：
   - 步骤1：调用`EnemyTypeDatabase.get_enemy_definition(enemy_id)`获取属性
   - 步骤2：`enemy_scene.instantiate()`创建CharacterBody2D节点
   - 步骤3：设置位置`enemy.position = world_pos`
   - 步骤4：初始化属性（health, damage, armor, speed等）
   - 步骤5：调用`enemy_ai.init_ai(enemy_id, position)`初始化AI组件
   - 步骤6：`spawn_container.add_child(enemy)`添加到场景
   - 步骤7：触发生成动画（淡入/特效）
   - 步骤8：添加到`active_enemy_list`

5. **阵营生成区域映射**：不同阵营敌人从不同spawn_zone生成：
   - 墓园(GRAVEYARD)：地面裂缝区域（world_y接近地面层）
   - 地狱(HELL)：深渊裂缝区域（world_y靠近边缘/阴影区）
   - 塔楼(TOWER)：机械门区域（墙体侧/建筑物边缘）
   - 元素(ELEMENT)：晶石节点区域（特定地标位置）

6. **敌人实例管理**：生成系统维护active_enemy_list供下游系统查询：
   - 添加：创建成功后立即加入列表
   - 移除：敌人死亡时从列表移除（监听death信号）
   - 查询接口：`get_active_enemies()`返回列表，`get_enemies_in_range(center, radius)`返回范围内敌人

### States and Transitions

生成系统本身无复杂状态机，采用单次执行模式：

| State | Name | Description | Entry Condition |
|-------|------|-------------|-----------------|
| IDLE | 待机 | 无生成请求 | 无spawn_config传入 |
| SPAWNING | 正在生成 | 执行批量生成 | spawn_config传入，生成未完成 |
| COMPLETE | 生成完成 | 等待下一请求 | 所有敌人生成完毕 |

**生成执行流程（SPAWNING状态内）**：

| Phase | Description | Duration |
|-------|-------------|----------|
| 批次准备 | 解析spawn_config，计算生成批次 | 0 (instant) |
| 批次生成 | 每spawn_interval生成一个敌人 | spawn_interval × total_count |
| 动画播放 | 每个敌人播放生成动画 | SPAWN_ANIMATION_DURATION (0.5s per enemy) |
| 完成确认 | 验证所有敌人已添加到列表 | 0 (instant) |

### Interactions with Other Systems

#### 上游系统依赖

| System | Interface | Data Flow | Owner |
|--------|-----------|-----------|-------|
| **EnemyTypeDatabase** | `get_enemy_definition(enemy_id)` → health, damage, armor, speed, behavior_hint, spawn_weight, unlock_day | 生成系统读取敌人属性进行实例创建 | Foundation层，Designed |
| **TileMapWorldSystem** | `map_to_local(cell)` → world_pos, `is_cell_solid(cell)` → walkability check | 生成系统使用坐标转换和可行走验证 | Foundation层，Designed |
| **尸潮周期系统** | spawn_config → enemy_id列表、数量、位置范围 | 尸潮系统传入生成配置触发生成 | Alpha层，Not Started |

#### 下游系统交互

| System | Interface | Data Flow | Owner |
|--------|-----------|-----------|-------|
| **EnemyAI系统** | `init_ai(enemy_id, position)` → AI组件初始化 | 生成系统创建敌人后初始化AI | Core层，Designed |
| **TurretSystem** | `get_active_enemies()` → enemy_list查询 | 炸塔系统查询敌人位置进行瞄准 | MVP层，Not Started |
| **陷阱系统** | `get_enemies_in_range(center, radius)` → 范围内敌人列表 | 陷阱触发检测敌人是否在范围 | Vertical Slice层，Not Started |
| **CombatFeedbackSystem** | death信号监听 → 移除active_enemy_list | 敌人死亡时更新列表 | Alpha层，Not Started |

#### Godot Engine组件依赖

| Component | Purpose | Usage Pattern |
|-----------|---------|---------------|
| **PackedScene** | 敌人预制体加载 | `preload("res://scenes/enemies/EnemyTemplate.tscn")` 加载模板，`instantiate()` 创建实例 |
| **Node.add_child()** | 添加到场景树 | 生成后调用`spawn_container.add_child(enemy)`激活节点 |
| **Timer节点** | 生成间隔控制 | 每spawn_interval触发下一个敌人生成 |
| **Signal** | 死亡监听 | `enemy.death_signal.connect(_on_enemy_death)` 监听移除事件 |

## Formulas

### 1. Spawn Weight Selection Probability

`selection_probability = spawn_weight / total_weight`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `spawn_weight` | float | 0.1-10.0 | EnemyTypeDB.spawn_weight |
| `total_weight` | float | sum of all candidates | Dynamic calculation |

**Output**: float — probability of this enemy type being selected
**Example**: spawn_weight=3.0, total_weight=15.0 → probability=0.20 (20% chance)

### 2. Spawn Interval Timing

`total_spawn_time = enemy_count × spawn_interval`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `enemy_count` | int | 1-100 | spawn_config.count |
| `spawn_interval` | float | 0.05-0.5 | Tuning Knob (SPAWN_INTERVAL_BASE) |

**Output**: float seconds — total time to spawn all enemies
**Example**: enemy_count=25, spawn_interval=0.1 → total_time=2.5 seconds

### 3. Batch Spawn Count Per Wave

`batch_count = ceil(total_count / wave_count)`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `total_count` | int | 10-100 | 尸潮规模预估 |
| `wave_count` | int | 1-10 | Tuning Knob (WAVE_COUNT_PER_TIDE) |

**Output**: int — enemies per batch/wave
**Example**: total_count=50, wave_count=5 → batch_count=10 enemies per wave

### 4. Active Enemy Limit

`can_spawn = active_count < MAX_ACTIVE_ENEMIES`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `active_count` | int | 0-∞ | active_enemy_list.size() |
| `MAX_ACTIVE_ENEMIES` | int | 50-200 | Tuning Knob (performance cap) |

**Output**: boolean — whether spawn is allowed
**Example**: active_count=75, MAX=100 → can_spawn=true; active_count=100, MAX=100 → can_spawn=false

### 5. Range Query Filter

`is_in_range = distance(enemy.position, center) <= radius`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `enemy.position` | Vector2 | world coords | Enemy instance |
| `center` | Vector2 | world coords | Query origin (turret/trap position) |
| `radius` | float | 32-512 | Query parameter |

**Output**: boolean — enemy is within query range
**Example**: enemy at (100, 200), center at (150, 200), radius=64 → distance=50, is_in_range=true

## Edge Cases

### 生成位置边界情况

1. **生成位置在墙体内**：当随机选取的cell位置被墙体占据（`is_cell_solid(cell) == true`）：
   - 重试策略：重新随机选取位置，最多重试`MAX_POSITION_RETRIES=5`次
   - 失败处理：如果5次重试都失败，使用fallback位置（spawn_zone边缘的安全点）
   - 日志记录：`"Spawn position blocked for enemy_id=[id], retry=[count]"`

2. **spawn_zone范围无效**：spawn_zone定义的范围完全不可行走（全部被墙体覆盖）：
   - 错误处理：拒绝生成配置，返回错误 `"spawn_zone [zone_id] has no valid positions"`
   - 建议修复：尸潮周期系统应配置多个spawn_zone作为备选

3. **生成位置超出world_bounds**：cell超出世界边界（`cell.x < -1000 or cell.x > 1000`）：
   - 拒绝生成：跳过该敌人，记录错误 `"Spawn position out of world bounds"`
   - spawn_zone验证：生成前应验证spawn_zone在有效范围内

### 生成数量边界情况

4. **达到MAX_ACTIVE_ENEMIES上限**：当active_count达到上限时：
   - 暂停生成：进入等待状态，直到敌人死亡释放名额
   - 队列机制：未生成的敌人进入spawn_queue，等待名额释放
   - 优先级：Boss级敌人优先生成（优先级=5），Basic级最低（优先级=1）

5. **敌人类型未解锁**：spawn_config包含未解锁的enemy_id（unlock_day > current_day）：
   - 过滤处理：从候选列表移除未解锁类型
   - 替代选择：如果全部未解锁，使用当前day解锁的fallback类型
   - 日志：`"enemy_id=[id] not unlocked for day=[current_day], filtered"`

6. **spawn_weight为0**：敌人类型spawn_weight=0（事件触发或特殊敌人）：
   - 排除处理：不参与加权随机选择，仅通过显式spawn_config指定
   - 验证规则：spawn_weight=0的敌人不能出现在随机池中

### 实例创建边界情况

7. **PackedScene加载失败**：敌人预制体场景加载失败（文件缺失或损坏）：
   - 错误处理：记录严重错误 `"Failed to load enemy scene for enemy_id=[id]"`
   - fallback实例：使用默认占位敌人（红色方块）代替，确保生成不中断
   - 设计约束：所有敌人预制体必须在预加载阶段验证存在

8. **AI初始化失败**：`enemy_ai.init_ai()`调用失败（AI组件缺失）：
   - 错误处理：敌人创建但AI未激活，表现为静止不动
   - 日志：`"AI initialization failed for enemy_id=[id], enemy will remain idle"`
   - 降级策略：敌人仍可被炮塔攻击、陷阱触发，但不主动移动

9. **敌人实例重复添加**：同一敌人实例被多次添加到active_enemy_list：
   - 防重机制：添加前检查`enemy in active_enemy_list`，已存在则跳过
   - 日志：`"Duplicate enemy instance detected, skip adding"`

### 下游查询边界情况

10. **active_enemy_list为空**：炮塔/陷阱查询时无活跃敌人：
    - 返回空列表：`get_active_enemies()`返回`[]`
    - 行为建议：炮塔进入待机状态，陷阱不触发
    - 日志级别：debug级别，不记录（正常情况）

11. **范围查询无匹配**：`get_enemies_in_range()`返回空列表：
    - 正常处理：返回空列表，下游系统根据自身逻辑处理
    - 性能优化：当active_count < 10时直接遍历；当active_count > 50时使用空间分区

12. **敌人查询时敌人刚死亡**：查询返回的敌人实例在下一帧死亡：
    - 引用失效：下游系统应检查`is_instance_valid(enemy)`再使用
    - 信号机制：推荐监听death信号而非依赖查询

## Dependencies

### Upstream Dependencies (Systems this one depends on)

| System | Dependency Type | Interface Used | Status |
|--------|-----------------|----------------|--------|
| **EnemyTypeDatabase** | Hard | `get_enemy_definition(enemy_id)` → health, damage, armor, speed, behavior_hint, spawn_weight, unlock_day | Designed |
| **TileMapWorldSystem** | Hard | `map_to_local(cell)` → world_pos, `is_cell_solid(cell)` → walkability | Designed |
| **尸潮周期系统** | Soft | spawn_config传入 → enemy_id列表、数量、位置范围 | Not Started |

**Dependency Nature**:
- **Hard dependency**: 生成系统无法运行若无EnemyTypeDatabase（缺少敌人定义）或TileMapWorldSystem（缺少坐标转换）
- **Soft dependency**: 尸潮周期系统未实现时，可通过手动spawn_config触发生成（调试/测试模式）

### Downstream Dependencies (Systems that depend on this one)

| System | Dependency Type | Interface Provided | Status |
|--------|-----------------|--------------------|--------|
| **EnemyAI系统** | Hard | 创建敌人实例 → `init_ai(enemy_id, position)`调用 | Designed |
| **TurretSystem** | Soft | `get_active_enemies()` → enemy_list查询 | Not Started |
| **陷阱系统** | Soft | `get_enemies_in_range(center, radius)` → 范围内敌人列表 | Not Started |
| **CombatFeedbackSystem** | Soft | death信号监听 → active_enemy_list移除 | Not Started |

**Dependency Nature**:
- **Hard dependency**: EnemyAI系统必须接收生成系统创建的敌人实例才能运行
- **Soft dependency**: 炮塔/陷阱/反馈系统增强体验但生成系统可独立运行

### Bidirectional Check

| Dependency | Listed Here | Listed in Target | Status |
|------------|-------------|------------------|--------|
| EnemySpawn → EnemyTypeDatabase | ✓ Listed as Hard | ✓ Listed in EnemyTypeDB (Section F) | ✅ Verified |
| EnemySpawn → TileMapWorldSystem | ✓ Listed as Hard | TileMap GDD does NOT list this (inbound ref only) | ✅ Correct |
| EnemySpawn → EnemyAI系统 | ✓ Listed as Hard | ✓ Listed in EnemyAI (Section F) as "生成系统创建敌人时初始化AI状态机" | ✅ Verified |
| Turret → EnemySpawn | ✓ Listed as Soft | — Target GDD not written | Pending |
| 尸潮周期 → EnemySpawn | ✓ Listed as Soft | — Target GDD not written | Pending |

**Note**: TileMapWorldSystem是Foundation层系统，EnemySpawn是其下游Core层系统。TileMap不主动依赖EnemySpawn，仅提供坐标转换接口。

### Cross-System Data Flow

```
尸潮周期系统 (spawn_config)
        ↓
EnemyTypeDatabase (enemy_id → definition)
TileMapWorldSystem (cell → world_pos)
        ↓
    EnemySpawn System (实例创建 + AI初始化)
        ↓
    active_enemy_list → [TurretSystem, 陷阱系统] (目标查询)
    death_signal → CombatFeedbackSystem (死亡反馈)
```

## Tuning Knobs

### Global Spawn Tuning Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `MAX_ACTIVE_ENEMIES` | 100 | 50-200 | 活跃敌人数量上限（性能限制） | ×50 = 小规模战场，×200 = 大规模尸潮（性能风险） |
| `MAX_POSITION_RETRIES` | 5 | 3-10 | 生成位置重试次数 | ×3 = 快速放弃，×10 = 持久尝试 |
| `SPAWN_INTERVAL_BASE` | 0.1 | 0.05-0.5 | 单个敌人生成间隔（秒） | ×0.05 = 快速涌现，×0.5 = 慢慢出现 |

### Wave Structure Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `WAVE_COUNT_PER_TIDE` | 5 | 1-10 | 每次尸潮波次数量 | ×1 = 单波爆发，×10 = 多波节奏 |
| `WAVE_INTERVAL` | 30 | 10-60 | 波次间隔时间（秒） | ×10 = 连续压力，×60 = 长喘息 |
| `BATCH_SPAWN_DELAY` | 0.5 | 0.3-1.0 | 同批次内敌人生成动画间隔（秒） | ×0.3 = 快速动画，×1.0 = 慢速出现 |

### Spawn Zone Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `SPAWN_ZONE_MIN_DISTANCE` | 10 | 5-30 | 生成区域距玩家最小距离（格） | ×5 = 近距生成（高压），×30 = 远距生成（预警） |
| `SPAWN_ZONE_WIDTH` | 20 | 10-50 | 生成区域宽度（格） | ×10 = 紧密集群点，×50 = 分散生成线 |
| `SPAWN_ZONE_SAFE_MARGIN` | 2 | 0-5 | 生成区域边缘安全距离（格） | ×0 = 可能生成在墙边，×5 = 确保远离墙体 |

### Animation Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `SPAWN_ANIMATION_DURATION` | 0.5 | 0.3-1.0 | 生成动画播放时长（秒） | ×0.3 = 快速出现，×1.0 = 慢慢显现 |
| `SPAWN_FADE_ALPHA_START` | 0.0 | 0.0-0.5 | 生成开始透明度 | ×0.0 = 完全隐形开始，×0.5 = 半透明开始 |
| `SPAWN_VFX_DURATION` | 1.0 | 0.5-2.0 | 生成特效持续时间（秒） | ×0.5 = 简短特效，×2.0 = 长特效（视觉冲击） |

### Performance Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `QUERY_USE_SPATIAL_PARTITION` | true | true/false | 范围查询是否使用空间分区 | false = 直接遍历（低active_count时），true = 分区优化（高active_count） |
| `DEATH_SIGNAL_QUEUE_SIZE` | 20 | 10-50 | 死亡信号处理队列大小 | ×10 = 小队列（可能堵塞），×50 = 大队列（平滑处理） |

### Knob Interactions

- **`MAX_ACTIVE_ENEMIES` × `WAVE_COUNT_PER_TIDE`** — 总敌人数 = active_limit × wave_count（高上限+多波次 = 大规模持续战斗）
- **`SPAWN_INTERVAL_BASE` × `batch_count`** — 批次生成时间 = interval × count（低间隔+大批次 = 快速涌现）
- **`WAVE_INTERVAL` vs `SPAWN_INTERVAL_BASE`** — 波次间隔 > 批次生成时间（节奏感：批次快、波次慢）
- **`SPAWN_ZONE_MIN_DISTANCE` × `SPAWN_ZONE_WIDTH`** — 生成区域位置 = player_pos - min_distance（近距离+窄区域 = 高压）

## Visual/Audio Requirements

### Spawn Animation Requirements

敌人生成必须有视觉动画传达"出现"时刻：

| 阵营 | 生成动画 | VFX效果 | 音效 |
|------|----------|----------|------|
| **墓园** | 地面裂缝蠕动上升 (0.5s) | 腐烂绿粘液粒子 + 地面裂缝特效 | 爬行声 + 粘液滴落 |
| **地狱** | 深渊裂缝喷射而出 (0.3s) | 火焰橙粒子爆发 + 深渊紫黑裂缝 | 火焰喷射 + 深渊呼啸 |
| **塔楼** | 机械门打开走出 (0.7s) | 锈铁门开动画 + 电路火花 | 机械门开启 + 金属脚步 |
| **元素** | 晶石光芒凝聚成形 (0.5s) | 晶石紫光芒聚合 + 元素附着特效 | 晶石凝聚 + 元素风声 |

### Spawn Zone Visual Indicators

生成区域应有视觉标识让玩家知道敌人将从哪里出现：

| 阵营 | 生成区域标识 | 触发时机 | 视觉特征 |
|------|--------------|----------|----------|
| **墓园** | 地面裂缝预兆 | 尸潮开始前5秒 | 地面蠕动 + 腐烂绿微光 |
| **地狱** | 深渊裂缝闪烁 | 尸潮开始前5秒 | 深渊紫黑脉动 + 火焰橙微光 |
| **塔楼** | 机械门活动 | 尸潮开始前5秒 | 锈铁门震动 + 电路蓝闪光 |
| **元素** | 晶石节点激活 | 尸潮开始前5秒 | 晶石紫光芒脉动 |

### Spawn Audio Events

| Event | 音效类型 | 强度 | 目的 |
|-------|----------|------|------|
| 生成区域激活 | 预警音效 | 低（环境） | 提示生成区域即将活动 |
| 单个敌人生成 | 阵营专属生成音效 | 中（即时） | 确认单个敌人出现 |
| 批次生成完成 | 批次结束音效 | 中（过渡） | 标记一批敌人已全部出现 |
| 波次开始 | 波次预警音效 | 高（警报） | 提示新一轮波次即将来临 |

## UI Requirements

### 无直接玩家UI需求

敌人生成系统是后台创建系统，玩家不直接交互。生成信息通过以下间接方式传达：

- **尸潮预警UI**：显示即将出现的敌人类型图标（由尸潮周期系统调用生成配置）
- **生成动画**：敌人出现通过视觉动画表现，非HUD显示
- **数量感知**：玩家通过看到敌人数量感知生成规模，无需计数UI

### 开发调试UI（非玩家）

- **生成统计面板**（开发模式）：显示active_count, spawn_queue_size, last_wave_time
- **生成位置可视化**（开发模式）：显示spawn_zone边界和生成点
- **敌人列表调试**（开发模式）：显示active_enemy_list内容（enemy_id, position, AI_state）

## Acceptance Criteria

### Core Rules Coverage

**AC-01**: GIVEN spawn_config with enemy_id=1000 (graveyard_zombie_basic) and count=5, WHEN spawn system processes config, THEN 5 enemy instances created at positions within spawn_zone, each initialized with EnemyTypeDB attributes.

**AC-02**: GIVEN spawn_config containing enemy_id=1005 (unlock_day=10) when current_day=5, WHEN spawn system filters candidates, THEN enemy_id=1005 excluded from spawn pool, only day ≤ 5 enemies eligible.

**AC-03**: GIVEN spawn_zone Rect2i(min=(0,0), max=(20,10)), WHEN position selection occurs, THEN selected cell coordinates within range [0-20, 0-10], world_pos converted via `map_to_local()`.

**AC-04**: GIVEN selected spawn position at cell=(5,5) where `is_cell_solid(5,5)=true`, WHEN position blocked detected, THEN retry up to MAX_POSITION_RETRIES=5 times, fallback to zone edge if all fail.

**AC-05**: GIVEN enemy instance created successfully, WHEN `add_child()` called, THEN enemy appears in scene tree, AI initialized via `init_ai(enemy_id, position)`, enemy added to active_enemy_list.

### Instance Creation Coverage

**AC-06**: GIVEN EnemyTypeDatabase.get_enemy_definition(1000) returns health=30, damage=5, speed=0.8, WHEN enemy instance created, THEN enemy.health=30, enemy.damage=5, enemy.speed=0.8 initialized.

**AC-07**: GIVEN enemy scene instantiation succeeds, WHEN AI initialization `init_ai(1000, world_pos)` called, THEN enemy has behavior_hint=SWARM_CHARGE (0), NavigationAgent2D configured with start position.

**AC-08**: GIVEN active_enemy_list contains 3 enemies, WHEN 4th enemy created and added, THEN list.size()=4, new enemy reference valid in list.

**AC-09**: GIVEN enemy receives death signal, WHEN `_on_enemy_death(enemy)` handler called, THEN enemy removed from active_enemy_list, list.size() decremented.

### Spawn Weight Selection Coverage

**AC-10**: GIVEN three enemies with spawn_weight=[3.0, 1.0, 1.5] (total=5.5), WHEN weighted random selection with rand=2.2, THEN selected enemy is second type (cumulative 3.0+1.0=4.0 > 2.2, first type weight sum 3.0 < 2.2).

**AC-11**: GIVEN all candidates have spawn_weight=0 (special event enemies), WHEN spawn pool checked, THEN no weighted random selection, only explicit spawn_config allowed.

**AC-12**: GIVEN spawn pool empty after unlock_day filter, WHEN fallback triggered, THEN use lowest unlock_day available enemies as fallback candidates.

### Active Limit Coverage

**AC-13**: GIVEN active_count=100 and MAX_ACTIVE_ENEMIES=100, WHEN new spawn request arrives, THEN spawn paused, request queued in spawn_queue.

**AC-14**: GIVEN enemy dies and active_count drops to 99, WHEN queue has pending spawns, THEN next queued spawn executes immediately.

**AC-15**: GIVEN spawn_queue contains Boss(priority=5) and Basic(priority=1), WHEN queue processed, THEN Boss spawned first (higher priority).

### Range Query Coverage

**AC-16**: GIVEN active_enemy_list=[enemy1 at (100,200), enemy2 at (200,200), enemy3 at (300,200)], WHEN `get_enemies_in_range(center=(150,200), radius=100)` called, THEN returns [enemy1, enemy2] (distances 50 and 50), enemy3 excluded (distance=150 > 100).

**AC-17**: GIVEN active_enemy_list empty, WHEN `get_active_enemies()` called, THEN returns empty array `[]`, no crash.

**AC-18**: GIVEN QUERY_USE_SPATIAL_PARTITION=true and active_count=75, WHEN range query executed, THEN uses spatial partition grid for O(√n) lookup, not O(n) full scan.

### Wave Structure Coverage

**AC-19**: GIVEN WAVE_COUNT_PER_TIDE=5 and total_count=50, WHEN batch_count calculated, THEN batch_count=10 enemies per wave.

**AC-20**: GIVEN SPAWN_INTERVAL_BASE=0.1 and batch_count=10, WHEN wave spawn executes, THEN total batch_spawn_time=1.0 seconds for 10 enemies.

**AC-21**: GIVEN WAVE_INTERVAL=30 seconds, WHEN wave 1 completes, THEN next wave starts after 30 second delay.

## Open Questions

| ID | Question | Owner | Target Resolution | Status |
|----|----------|-------|-------------------|--------|
| Q-001 | 生成动画是否需要"预生成"特效？敌人在正式生成前是否有可见的预兆（如裂缝脉动）？ | Art Director + VFX设计 | Before spawn VFX implementation | Open |
| Q-002 | 多阵营同时生成时，生成位置如何分布？是否需要阵营专属spawn_zone还是混合？ | Level Design系统 | Before 尸潮周期系统 implementation | Open |
| Q-003 | Boss生成是否有特殊处理？是否需要单独的生成仪式（长动画、全屏警告）？ | Boss系统设计 | Before Boss implementation (Day 12+) | Open |
| Q-004 | 空间分区实现选择：使用Godot内置空间分区还是自定义grid？性能差异如何？ | Performance验证 | After大规模测试 (Day 15+) | Open |
| Q-005 | 死亡信号处理是实时还是队列化？大量同时死亡（如炮塔AOE）如何避免堵塞？ | CombatFeedback系统 | Before CombatFeedback implementation | Open |
| Q-006 | spawn_config数据结构定义：由尸潮周期系统传入还是生成系统自行计算？接口契约如何定义？ | 尸潮周期系统 GDD | Before 尸潮周期系统 design | Open |