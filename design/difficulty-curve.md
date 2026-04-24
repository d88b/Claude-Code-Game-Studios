# 难度曲线设计

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-24
> **Implements Pillar**: Pillar 2 (搜打撤节奏), Pillar 3 (尸潮即高潮)
> **Priority**: Polish | **Layer**: Design

## Overview

难度曲线定义游戏难度随时间（天数）递增的节奏和规律。它整合日夜系统危险倍率、敌人解锁时机、尸潮规模增长、资源稀缺曲线等系统，确保玩家体验"生存期 → 发展期 → 危机期 → 终局期"的清晰递进，而非平坦或突然崩溃的难度。

**核心设计理念**：
- 难度递增必须有预警信号，让玩家感知"威胁在升级"
- 难度跳跃不可超过玩家应对能力，否则产生挫败而非挑战
- 难度曲线服务于"搜打撤节奏"和"尸潮即高潮"支柱

**玩家感知层**：
- Day 1-5: 新敌人逐渐出现，尸潮规模温和增长 → 学习期
- Day 6-10: 新阵营（地狱）解锁，危险倍率波动 → 压力递增期
- Day 11-15: 多阵营混合尸潮，资源需求提升 → 危机期
- Day 16+: Boss/精英频繁出现，终极挑战 → 终局期

## Player Fantasy

**情感目标：可预测的升级节奏，让玩家感知进步与压力并存**

难度曲线的玩家体验不是直接感知"数值增加"，而是通过以下间接体验：

1. **预警信号可读性**：
   - Day 3: 第一次看到"骨骼骷髅"（WALL_BREAKER）→ "拆墙敌人来了，需要加固防线"
   - Day 6: 第一次看到"地狱小鬼"（火焰色调）→ "新阵营出现了，速度更快"
   - Day 10: 第一次看到"骨甲骑士"（Elite级）→ "精英威胁来了，需要优先处理"

2. **节奏感内化**：
   - 学习期（Day 1-5）：每次尸潮难度增幅小，玩家有时间学习基础防御策略
   - 递增期（Day 6-10）：难度增幅明显但可控，玩家感受到"挑战升级"
   - 危机期（Day 11-15）：难度增幅陡峭，玩家需要优化策略才能存活
   - 终局期（Day 16+）：难度稳定高位，玩家已掌握策略，面对终极考验

3. **失败归因清晰**：
   - 失败不是因为"突然变难"，而是"我没注意到预警信号"或"我策略没跟上"
   - 可预测的难度让失败成为学习机会，而非挫败体验

**锚定时刻**：Day 6 第一次地狱阵营尸潮，玩家看到火焰色调的敌人涌现，感知到"新阵营 = 新威胁"，并调用前几天学习的防御策略应对，然后发现地狱敌人速度更快，需要调整策略。这一刻定义了难度曲线的"递增感"。

**支柱服务**：
- **Pillar 2 (搜打撤节奏)**: 日夜系统危险倍率创造"安全时段/危险时段"周期，玩家学会判断"何时撤退"
- **Pillar 3 (尸潮即高潮)**: 尸潮规模随天数递增，每次尸潮成为"能否应对升级威胁"的测试

## Detailed Design

### Core Rules

**Rule 1: 四阶段难度节奏**

难度曲线分为四个阶段，每个阶段有明确的难度增幅目标和玩家学习节奏。

| Phase | Days | Name | Difficulty Growth | Player Experience |
|-------|------|------|-------------------|-------------------|
| **Phase 1** | 1-5 | 生存期 | 基线 → +20% | 学习基础系统，建立防线 |
| **Phase 2** | 6-10 | 发展期 | +20% → +50% | 新阵营解锁，压力递增 |
| **Phase 3** | 11-15 | 危机期 | +50% → +100% | 多阵营混合，资源紧张 |
| **Phase 4** | 16+ | 终局期 | +100% (稳定高位) | 终极挑战，精通测试 |

---

**Rule 2: 敌人解锁节奏**

敌人按天数解锁，确保新威胁有预警信号。

| Unlock Day | Faction | Enemy Types | Difficulty Jump |
|------------|---------|-------------|-----------------|
| **Day 1** | 墓园 | graveyard_zombie_basic, graveyard_zombie_runner | 基线 |
| **Day 3** | 墓园 | graveyard_skeleton_basic (WALL_BREAKER) | +10% (拆墙威胁) |
| **Day 4** | 墓园 | graveyard_skeleton_archer (SNIPER_RANGE) | +10% (远程威胁) |
| **Day 6** | 地狱 | hell_imp_basic, hell_fire_sprite | +20% (新阵营，快速威胁) |
| **Day 7** | 地狱 | hell_demon_runner (TRACKER_HUNT) | +15% (追踪威胁) |
| **Day 8** | 地狱 | hell_explosion_imp (自爆) | +15% (自爆威胁) |
| **Day 10** | 墓园 | graveyard_bone_knight (Elite) | +25% (精英威胁) |
| **Day 11** | 塔楼 | tower_scrap_drone (远程) | +15% (机械阵营预览) |
| **Day 15+** | 塔楼/元素 | Full faction unlock | +30% (完整阵营混合) |

---

**Rule 3: 尸潮规模增长公式**

尸潮规模随天数线性增长，受危险倍率调节。

```
tide_base_count = BASE_SPAWN_COUNT + day × TIDE_GROWTH_RATE
tide_actual_count = tide_base_count × danger_multiplier × faction_mult
```

| Variable | Default | Range | Source |
|----------|---------|-------|--------|
| `BASE_SPAWN_COUNT` | 10 | 5-20 | Tuning Knob |
| `TIDE_GROWTH_RATE` | 2 | 1-5 | Tuning Knob (per day) |
| `danger_multiplier` | 0.8-1.5 | Dynamic | DayNightCycle.get_danger_multiplier() |
| `faction_mult` | 1.0-1.5 | Dynamic | 新阵营解锁时额外增长 |

---

**Rule 4: 日夜危险倍率节奏**

日夜系统提供周期性难度波动，创造"安全时段/危险时段"。

| Phase | Danger Multiplier | Effect on Spawn |
|-------|-------------------|-----------------|
| DAWN | 0.8 | 尸潮规模减少20% |
| DAY | 1.0 | 基线规模 |
| DUSK | 1.2 | 尸潮规模增加20% |
| NIGHT | 1.5 | 尸潮规模增加50%（高危时段） |

---

**Rule 5: 资源稀缺曲线**

资源需求随天数递增，但资源获取率保持相对稳定，创造"资源紧张感"。

| Day | Resource Demand | Scarcity Feel |
|-----|-----------------|---------------|
| 1-5 | 低（基础维修） | 资源充裕 |
| 6-10 | 中等（新阵营弹药需求） | 资源需管理 |
| 11-15 | 高（多阵营混合） | 资源紧张 |
| 16+ | 极高（Boss/Elite） | 资源优化必需 |

---

**Rule 6: 失败容错边界**

难度跳跃不可超过玩家应对能力，定义"失败容错边界"。

| Metric | Threshold | Rationale |
|--------|-----------|-----------|
| 单波次难度增幅 | ≤30% | 单波次增幅超过30%会导致玩家无法适应 |
| 单日难度增幅 | ≤15% | 每日增幅超过15%会产生突然崩溃感 |
| 连续失败容错 | 3次 | 连续失败3次后，难度曲线暂停增长，给玩家喘息窗口 |

### States and Transitions

难度曲线本身无状态机——它是静态设计规则，由多个系统共同实现：
- **日夜系统**: 提供 danger_multiplier 周期波动
- **敌人生成系统**: 读取 enemy_type_database 的 unlock_day 过滤敌人
- **尸潮周期系统**: 计算 tide_actual_count 应用规模增长

### Interactions with Other Systems

| System | Role | Data Interface |
|--------|------|----------------|
| **日夜循环系统** | 难度周期波动 | danger_multiplier → Spawn system |
| **敌人类型数据库** | 解锁时机定义 | unlock_day → Spawn filter |
| **敌人生成系统** | 规模计算执行 | tide_actual_count → Batch spawn |
| **撤退判定系统** | 风险评估依据 | danger_multiplier → Retreat threshold |
| **资源数据库** | 资源需求递增 | ammo_cost × faction_count → Scarcity feel |

## Formulas

### Formula 1: Tide Size Calculation

`tide_actual_count = (BASE_SPAWN_COUNT + day × TIDE_GROWTH_RATE) × danger_mult × faction_unlock_mult`

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `BASE_SPAWN_COUNT` | int | 10 | 基线生成数量 |
| `day` | int | 1-30 | 当前游戏天数 |
| `TIDE_GROWTH_RATE` | float | 2.0 | 每日递增量 |
| `danger_mult` | float | 0.8-1.5 | 日夜危险倍率 |
| `faction_unlock_mult` | float | 1.0-1.5 | 阵营解锁系数 |

**faction_unlock_mult 计算**:
- 单阵营: 1.0
- 双阵营解锁: 1.2
- 三阵营解锁: 1.35
- 四阵营解锁: 1.5

**Output Range**: 8-150 enemies per tide
**Example**: day=10, NIGHT phase, 双阵营 → tide = (10 + 10×2) × 1.5 × 1.2 = 54 enemies

---

### Formula 2: Wave Count Distribution

`wave_enemy_count = ceil(tide_actual_count / WAVE_COUNT_PER_TIDE × wave_index / WAVE_COUNT_PER_TIDE × danger_mult)`

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `tide_actual_count` | int | 8-150 | 总尸潮规模 |
| `WAVE_COUNT_PER_TIDE` | int | 5 | 波次数量 |
| `wave_index` | int | 1-5 | 当前波次索引 |
| `danger_mult` | float | 0.8-1.5 | 日夜危险倍率 |

**Output**: 敌人数量按波次递增分配（早期波次少，后期波次多）
**Example**: tide=50, wave_index=3, danger_mult=1.2 → wave_count = ceil(50/5 × 3/5 × 1.2) = ceil(12 × 0.6 × 1.2) = ceil(8.64) = 9

---

### Formula 3: Difficulty Index Calculation

`difficulty_index = day × 0.1 + faction_count × 0.15 + elite_ratio × 0.2 + night_phase_bonus`

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `day` | int | 1-30 | 当前天数 |
| `faction_count` | int | 1-4 | 已解锁阵营数量 |
| `elite_ratio` | float | 0.0-0.3 | Elite级敌人占比 |
| `night_phase_bonus` | float | 0-0.5 | 夜晚时段额外难度 |

**Output Range**: 0.1-3.5 (用于难度显示和平衡验证)
**Example**: day=10, faction_count=2, elite_ratio=0.1, night_phase_bonus=0.5 → index = 1.0 + 0.3 + 0.02 + 0.5 = 1.82

---

### Formula 4: Failure Recovery Window

`recovery_days = max(0, consecutive_failures × 0.5 - success_streak × 0.1)`

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `consecutive_failures` | int | 0-3 | 连续防守失败次数 |
| `success_streak` | int | 0-10 | 连续防守成功次数 |

**Output**: 难度曲线暂停增长的天数（给玩家喘息窗口）
**Example**: consecutive_failures=2, success_streak=0 → recovery_days = 1.0 (难度暂停增长1天)

## Edge Cases

1. **Day 1 无尸潮**: Day 1 为学习期，不触发尸潮，让玩家熟悉基础系统后再面对第一次尸潮（Day 2）。

2. **连续失败3次**: 触发 recovery_days=1.5，难度曲线暂停增长1.5天，给玩家重建防线的时间。同时降低下一波次 danger_mult 到 1.0（强制白天难度）。

3. **Day 30+ 难度上限**: difficulty_index 有上限值 3.5，超过后不再增长。防止"无限难度"导致玩家必败。

4. **阵营解锁缺失**: 如果某个阵营内容未完成（如元素阵营敌人未设计），faction_unlock_mult 使用实际解锁阵营数量计算，而非设计预期的阵营数量。

5. **Boss 日特殊处理**: Boss 日（Day 12/20/28）尸潮规模公式额外 ×1.5，但失败容错加倍（recovery_days × 2）。

6. **资源耗尽触发撤退**: 如果资源数据库显示资源耗尽，撤退判定系统强制触发撤退警告，即使 danger_mult 为低值。

7. **日夜系统失效**: 如果日夜系统未初始化，danger_mult 默认使用 1.0（基线），防止难度计算崩溃。

8. **敌人类型数据库缺失**: 如果敌人类型数据库未加载，使用 fallback 敌人列表（仅 graveyard_zombie_basic），防止生成系统崩溃。

## Dependencies

### Upstream Dependencies

| System | Status | Data Flow |
|--------|--------|-----------|
| **日夜循环系统** | Designed | danger_multiplier → 尸潮规模调节 |
| **敌人类型数据库** | Designed | unlock_day → 敌人解锁时机 |
| **资源数据库** | Designed | 资源需求 → 稀缺曲线 |

### Downstream Dependencies

| System | Status | Data Flow |
|--------|--------|-----------|
| **敌人生成系统** | Designed | tide_actual_count → 尸潮规模执行 |
| **撤退判定系统** | Designed | difficulty_index → 撤退阈值评估 |
| **HUD系统** | Not Started | difficulty_index → 难度显示 |

### Cross-System Data Flow

```
Days Progression → [敌人类型DB unlock_day filter] → [Enemy Spawn]
                 → [日夜Cycle danger_mult] → [Tide Size Calc]
                 → [Resource DB scarcity] → [Retreat Judgment]
```

## Tuning Knobs

### Core Difficulty Knobs

| Knob ID | Knob Name | Default | Range | Affects |
|---------|-----------|---------|-------|---------|
| **TK-D001** | `BASE_SPAWN_COUNT` | 10 | 5-20 | 尸潮基线规模 |
| **TK-D002** | `TIDE_GROWTH_RATE` | 2.0 | 1-5 | 每日递增量 |
| **TK-D003** | `DIFFICULTY_CAP` | 3.5 | 2-5 | 难度上限 |
| **TK-D004** | `RECOVERY_DAYS_MULT` | 0.5 | 0.3-1.0 | 失败喘息窗口系数 |

### Phase Difficulty Knobs

| Knob ID | Knob Name | Default | Range | Affects |
|---------|-----------|---------|-------|---------|
| **TK-D005** | `PHASE1_CAP` | 1.2 | 1.0-1.5 | Day 1-5 难度上限 |
| **TK-D006** | `PHASE2_CAP` | 1.8 | 1.5-2.5 | Day 6-10 难度上限 |
| **TK-D007** | `PHASE3_CAP` | 2.5 | 2-3 | Day 11-15 难度上限 |
| **TK-D008** | `PHASE4_CAP` | 3.5 | 3-5 | Day 16+ 难度上限 |

### Faction Unlock Knobs

| Knob ID | Knob Name | Default | Range | Affects |
|---------|-----------|---------|-------|---------|
| **TK-D009** | `FACTION1_MULT` | 1.0 | 1.0-1.2 | 单阵营规模系数 |
| **TK-D010** | `FACTION2_MULT` | 1.2 | 1.1-1.4 | 双阵营规模系数 |
| **TK-D011** | `FACTION3_MULT` | 1.35 | 1.2-1.5 | 三阵营规模系数 |
| **TK-D012** | `FACTION4_MULT` | 1.5 | 1.3-1.8 | 四阵营规模系数 |

### Failure Recovery Knobs

| Knob ID | Knob Name | Default | Range | Affects |
|---------|-----------|---------|-------|---------|
| **TK-D013** | `CONSECUTIVE_FAIL_THRESHOLD` | 3 | 2-5 | 触发喘息窗口的失败次数 |
| **TK-D014** | `RECOVERY_DIFFICULTY_REDUCTION` | 0.3 | 0.2-0.5 | 喘息期难度降低比例 |

### Knob Interactions

- **`TIDE_GROWTH_RATE` × `danger_mult`** — 实际递增速度取决于日夜周期
- **`PHASE_CAP` × `DIFFICULTY_CAP`** — 阶段上限不能超过全局上限
- **`FACTION_MULT` × `TIDE_GROWTH_RATE`** — 阵营解锁叠加每日递增

## Visual/Audio Requirements

难度曲线本身无直接视觉/音频需求，但需通过以下间接方式传达难度变化：

### Difficulty Warning Visuals

| Event | Visual Feedback | Timing |
|-------|-----------------|--------|
| 新敌人解锁 | 尸潮预警UI显示新敌人图标 | 尸潮开始前5秒 |
| 阵营解锁 | 生成区域出现阵营特有裂缝脉动 | 尸潮开始前10秒 |
| Elite/Boss出现 | 全屏警告闪烁 + 特殊图标 | 波次开始前3秒 |
| 夜晚来临 | 环境光渐暗 + 撤退警告UI | 黄昏阶段 |

### Difficulty Progression Audio

| Event | Audio Feedback | Intensity |
|-------|----------------|-----------|
| 阵营解锁 | 新阵营环境音效启动 | 低（背景） |
| 阵营解锁尸潮 | 阵营特有警报音效 | 中（预警） |
| Boss出现 | Boss专属警报音效 | 高（警报） |
| 夜晚来临 | 环境音效切换（远处丧尸低吼） | 中（背景） |

## UI Requirements

难度曲线通过 HUD 间接传达：

| UI Element | Display | Data Source |
|------------|---------|-------------|
| **尸潮预警** | 即将出现的敌人类型图标 | EnemyTypeDB.unlock_day |
| **当前阶段** | 日夜阶段图标 + 名称 | DayNightCycle.get_current_phase() |
| **难度指示器** | 当前难度指数 (可选) | difficulty_index 计算 |
| **撤退警告** | 黄昏/夜晚警告提示 | danger_mult threshold |

## Acceptance Criteria

### Core Rules Coverage

**AC-01**: GIVEN Day 1, WHEN tide system calculates spawn count, THEN BASE_SPAWN_COUNT=10, no TIDE_GROWTH_RATE applied (day=0 for growth), faction_mult=1.0 (single faction).

**AC-02**: GIVEN Day 6 (地狱阵营解锁), WHEN faction_unlock_mult calculated, THEN faction_unlock_mult=1.2 (two factions: 墓园 + 地狱).

**AC-03**: GIVEN NIGHT phase, WHEN danger_mult applied to tide, THEN tide_actual_count × 1.5 (50% increase from DAY baseline).

**AC-04**: GIVEN Day 10, WHEN difficulty_index calculated, THEN index = 10×0.1 + 2×0.15 + 0.1×0.2 + 0 = 1.32 (day + faction + elite + phase_bonus).

**AC-05**: GIVEN Day 16+, WHEN difficulty_index exceeds 3.5, THEN clamped to DIFFICULTY_CAP=3.5, no further growth.

### Formula Coverage

**AC-06**: GIVEN day=5, BASE=10, GROWTH=2, danger_mult=1.5 (NIGHT), faction_mult=1.0, WHEN tide_actual_count calculated, THEN tide = (10 + 5×2) × 1.5 × 1.0 = 30 enemies.

**AC-07**: GIVEN tide=50, wave_index=4 (4th wave), WAVE_COUNT=5, danger_mult=1.2, WHEN wave_enemy_count calculated, THEN wave = ceil(50/5 × 4/5 × 1.2) = ceil(10 × 0.8 × 1.2) = ceil(9.6) = 10 enemies.

**AC-08**: GIVEN consecutive_failures=3, success_streak=0, WHEN recovery_days calculated, THEN recovery = 3×0.5 = 1.5 days.

### Edge Case Coverage

**AC-09**: GIVEN Day 1, WHEN spawn system requests tide config, THEN no tide triggered (Day 1 learning period), first tide on Day 2.

**AC-10**: GIVEN consecutive_failures=3, WHEN recovery window triggered, THEN next tide danger_mult forced to 1.0 (DAY baseline), difficulty growth paused for 1.5 days.

**AC-11**: GIVEN Day 30+, WHEN difficulty_index calculated, THEN capped at 3.5 (DIFFICULTY_CAP), no infinite growth.

**AC-12**: GIVEN Boss day (Day 12/20/28), WHEN tide size calculated, THEN tide × 1.5 (Boss multiplier), recovery_days × 2 if failed.

### System Integration Coverage

**AC-13**: GIVEN DayNightCycle not initialized, WHEN spawn system queries danger_mult, THEN fallback to 1.0 (baseline), spawn proceeds without crash.

**AC-14**: GIVEN EnemyTypeDB not loaded, WHEN spawn system filters by unlock_day, THEN fallback to [graveyard_zombie_basic] only, spawn proceeds with minimal content.

**AC-15**: GIVEN ResourceDB shows resources depleted, WHEN retreat judgment evaluates, THEN forced retreat warning regardless of danger_mult value.

## Open Questions

| ID | Question | Owner | Target Resolution | Status |
|----|----------|-------|-------------------|--------|
| Q-001 | difficulty_index 是否需要在 HUD 显示？玩家是否会误解数值？ | UX Designer | Before HUD implementation | Open |
| Q-002 | recovery_days 是否需要视觉提示告知玩家"喘息期"？ | UX Designer | Before failure recovery implementation | Open |
| Q-003 | Day 30+ 难度上限是否需要动态调整？如果玩家通关太快或太慢？ | Content design | After playtest (Day 30+ content) | Open |
| Q-004 | 资源稀缺曲线的具体数值定义？需要资源数据库详细设计后确定 | ResourceDB GDD | After ResourceDB implementation | Open |