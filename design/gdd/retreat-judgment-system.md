# 撤退判定系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 2 — 搜打撤节奏 (撤退决策的压力源)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #32 (from systems-index.md)

## Overview

撤退判定系统是监听战车状态并触发撤退决策信号的判定层系统。它订阅战车属性系统的耐久/魔能变化信号，查询时间系统的当前时段和日夜循环系统的危险倍率，持续比较当前状态值与预定义撤退阈值，当任一阈值触发时发射`retreat_warning_triggered`信号供下游UI系统消费。

**数据层职责**：
- 监听`durability_changed`和`magic_energy_changed`信号（来自战车属性系统）
- 查询`DayNightCycle.get_danger_multiplier()`获取时段危险系数
- 维护多级撤退阈值：魔能阈值(20%)、耐久阈值(30%)、时间阈值(黄昏时段)、危险阈值(高威胁事件)
- 比较当前比例值与阈值，触发对应级别的撤退警告
- 发射信号：`retreat_warning_triggered(level, reason, urgency)`供HUD/撤退警告UI订阅

**玩家影响层（间接）**：
- 撤退警告UI弹出，提示"魔能不足/耐久过低/天色将晚"
- HUD魔能/耐久条低于阈值时闪烁红光警报
- 撤退决策压力：玩家感受到"再搜一个废墟？"的风险与收益博弈
- 搜打撤节奏内化：撤退判定系统创造"何时撤退"的决策边界

**系统必要性**：没有撤退判定系统，游戏将无法：
- 将战车状态数值转化为撤退决策信号（战车属性变化无下游触发）
- 为玩家提供明确的撤退时机提示（搜打撤失去决策边界）
- 创造搜打撤节奏的决策压力（探索变成无风险漫游）
- 实现Pillar 2核心体验（搜打撤失去核心驱动）

**下游消费系统**：
- 撤退警告UI (#50) — 显示撤退警告弹窗
- HUD系统 (#49) — 显示阈值逼近的视觉反馈（闪烁、警报色）
- 撤退后果系统 (#33) — 处理撤退失败或超时的后果

## Player Fantasy

**情感目标：风险博弈的临界时刻**

玩家在撤退判定系统中面对的核心体验是**"再搜一个废墟？"的风险博弈**——每次撤退判定触发，都是玩家贪婪与理性之间的临界时刻。撤退不是被强制赶走，而是玩家主动权衡后做出的决策——这种"我选择撤退"而非"系统禁止继续"的感觉，是搜打撤节奏的核心张力。

**锚定时刻：**

1. **魔能耗尽前的最后一搏**：玩家看到魔能警告弹出（20%），HUD魔能条闪烁红光。此时距离车库还有15格路程，魔能剩余刚好够回去——或者刚好不够。玩家做出选择：立刻撤退保安全，还是冒险搜刮最后一个废墟（可能有魔力晶石补充）。这是"贪婪vs理性"的临界博弈，撤退判定系统创造的是这种选择的重量感，而非简单的"禁止继续"。

2. **黄昏将至的时间焦虑**：游戏时间显示17:45（黄昏即将来临），危险倍率将从1.0升至1.2。玩家看着远处还没搜完的废墟群，心里在计算"再搜一个要多久？天黑前来得及吗？"。撤退判定系统通过时段阈值创造的是时间焦虑——不是"天黑了不能继续"，而是"我判断来得及，冒险搜刮"的主动决策。

3. **耐久告急的生存抉择**：战车耐久跌至30%，红色闪烁警报开始。玩家刚搜完一个宝箱，获得稀有秘银——再搜一个可能有更好装备，但战车可能撑不住。撤退判定系统创造的是生存与收获的权衡——撤退不是失败，而是明智的止损。玩家感受到"我选择保护战车"的主动决策感。

**支柱服务：**

- **Pillar 2 (搜打撤节奏)**：撤退判定系统是该支柱的核心驱动——没有阈值判定，搜打撤变成无风险的观光；有了阈值，每次搜刮都伴随"够不够撤退？"的计算，搜打撤节奏内化为玩家的本能行为。

**语调示例：**

```
❌ "魔能低于20%，触发撤退警告"
✓ "魔力晶石的脉动变得急促——战车的续航只够最后的冲刺，是冒险还是归程？"

❌ "耐久30%，强制禁止继续探索"
✓ "装甲完整性警报——战车在呼喊：'我撑不住了'，撤退是明智的止损，不是失败"

❌ "黄昏时段危险系数×1.2"
✓ "太阳正在沉入废土——远处丧尸的低吼开始密集，天黑前你还敢再搜一个吗？"
```

**没有撤退判定系统，玩家失去什么：**
- 搜打撤失去决策边界 — 探索变成无风险的无限漫游
- Pillar 2的核心体验崩溃 — "再搜一个废墟？"失去真实的风险博弈
- 撤退失去主动决策感 — 撤退变成"系统禁止"而非"我选择"
- 战车的生命感被削弱 — 耐久/魔能告急失去情感重量，变成冷数字

## Detailed Design

### Core Rules

**Rule 1: Threshold Monitoring Architecture**

撤退判定系统作为Autoload单例运行，持续监听战车属性变化信号并执行阈值检查。

**监听信号列表：**

| Signal | Source | Trigger Condition | Payload |
|--------|--------|-------------------|---------|
| `durability_changed` | VehicleAttributeSystem | 耐久值变化 | `instance_id, old_ratio, new_ratio` |
| `magic_energy_changed` | VehicleAttributeSystem | 魔能值变化 | `instance_id, old_ratio, new_ratio` |
| `time_phase_changed` | DayNightCycle | 时段切换 | `phase, danger_mult` |

**主动查询接口：**

| Query | Source | Purpose |
|--------|--------|---------|
| `get_danger_multiplier()` | DayNightCycle | 获取当前危险倍率 |
| `get_time_of_day()` | TimeSystem | 获取当前游戏时间（用于黄昏预警） |
| `get_consumption_rate()` | MagicConsumption | 获取魔能消耗速率（用于续航预测） |
| `get_position()` | VehicleDriving | 获取战车位置（用于距离计算） |

---

**Rule 2: Threshold Definitions and Levels**

系统维护多级阈值，触发不同级别的警告。

**阈值层次结构：**

| Threshold Type | Level | Threshold Value | Warning Level | Description |
|----------------|-------|-----------------|---------------|-------------|
| 魔能警告阈值 | WARN | 0.20 (20%) | `WARNING` | 魔能低，建议开始撤退规划 |
| 魔能紧急阈值 | CRITICAL | 0.10 (10%) | `CRITICAL` | 魔能极低，必须立即撤退 |
| 耐久警告阈值 | WARN | 0.30 (30%) | `WARNING` | 耐久低，战车易损 |
| 耐久紧急阈值 | CRITICAL | 0.15 (15%) | `CRITICAL` | 耐久极低，瘫痪风险高 |
| 时间警告阈值 | WARN | 18:00 (黄昏开始) | `WARNING` | 黄昏将至，危险上升 |
| 时间紧急阈值 | CRITICAL | 19:30 (黄昏末期) | `CRITICAL` | 夜晚逼近，必须撤退 |
| 危险倍率阈值 | WARN | 1.2 (DUSK) | `WARNING` | 危险系数上升 |
| 危险倍率阈值 | CRITICAL | 1.5 (NIGHT) | `CRITICAL` | 夜晚高危，禁止继续 |

---

**Rule 3: Threshold Check Execution**

当属性变化信号到达时，系统执行阈值检查流程：

```
1. 接收属性变化信号
2. 读取新比例值 (new_ratio)
3. 遍历对应类型的阈值列表 (魔能/耐久)
4. 比较 new_ratio 与阈值
5. 若跨越阈值边界 → 计算警告级别
6. 发射 retreat_warning_triggered 信号
```

**阈值跨越判定逻辑：**

- 从安全区跨越到警告区（如魔能从25%降至18%）→ 触发`WARNING`级别
- 从警告区跨越到紧急区（如魔能从15%降至8%）→ 触发`CRITICAL`级别
- 同级别内的微小变化（如魔能从18%降至16%）→ 不触发新信号（避免噪音）

---

**Rule 4: Multi-Factor Warning Aggregation**

当多个阈值同时触发时，系统聚合警告级别：

**聚合规则：**

| Condition | Aggregated Level | Reason Priority |
|-----------|-----------------|-----------------|
| 单一阈值触发 | 对应级别 | 单原因显示 |
| 多个WARNING触发 | `WARNING` | 多原因合并显示 |
| WARNING + CRITICAL触发 | `CRITICAL` | CRITICAL优先显示 |
| 多个CRITICAL触发 | `CRITICAL` | 多原因合并显示（紧急警告） |

**信号payload定义：**

```gdscript
signal retreat_warning_triggered(level: WarningLevel, reasons: Array[WarningReason], urgency: float)

enum WarningLevel { NONE, WARNING, CRITICAL }
enum WarningReason { 
    MAGIC_LOW, MAGIC_CRITICAL, 
    DURABILITY_LOW, DURABILITY_CRITICAL, 
    TIME_DUSK, TIME_NIGHT,
    DANGER_HIGH
}
```

---

**Rule 5: Retreat Urgency Calculation**

警告触发时，系统计算撤退紧迫度供UI显示：

**紧迫度公式：**

```
urgency = max(
    magic_urgency,
    durability_urgency,
    time_urgency,
    danger_urgency
)
```

**各维度紧迫度计算：**

| Dimension | Urgency Formula |
|-----------|-----------------|
| 魔能紧迫度 | `magic_urgency = (threshold - current_magic_ratio) × MAGIC_WEIGHT` |
| 耐久紧迫度 | `durability_urgency = (threshold - current_durability_ratio) × DURABILITY_WEIGHT` |
| 时间紧迫度 | `time_urgency = (phase_end_time - current_time) / phase_duration × TIME_WEIGHT` |
| 危险紧迫度 | `danger_urgency = (danger_mult - 1.0) × DANGER_WEIGHT` |

---

**Rule 6: Signal Emission Frequency Control**

避免频繁发射信号造成UI噪音：

- 同级别警告在冷却期内不重复发射（冷却期=10真实秒）
- 级别升级时立即发射新信号（跨越冷却期）
- 级别降级时冷却期结束后发射解除信号

---

### States and Transitions

撤退判定系统无复杂状态机，但维护警告状态：

| State | Condition | Behavior |
|-------|-----------|----------|
| NORMAL | 所有阈值未触发 | 不发射警告信号，静默监测 |
| WARNING | 至少一个WARNING阈值触发 | 发射WARNING信号，UI显示轻度警告 |
| CRITICAL | 至少一个CRITICAL阈值触发 | 发射CRITICAL信号，UI显示紧急警告，可能强制限制行动 |

**状态转换表：**

| Current State | Trigger | Next State | Signal |
|---------------|---------|------------|--------|
| NORMAL | WARNING阈值跨越 | WARNING | `retreat_warning_triggered(WARNING, reasons)` |
| NORMAL | CRITICAL阈值跨越 | CRITICAL | `retreat_warning_triggered(CRITICAL, reasons)` |
| WARNING | CRITICAL阈值跨越 | CRITICAL | `retreat_warning_triggered(CRITICAL, reasons)` |
| WARNING | 所有阈值恢复安全区 | NORMAL | `retreat_warning_cleared()` |
| CRITICAL | WARNING阈值恢复但仍有CRITICAL | CRITICAL | 无新信号（保持CRITICAL） |
| CRITICAL | 所有阈值恢复安全区 | NORMAL | `retreat_warning_cleared()` |

---

### Interactions with Other Systems

| System | Direction | Data Interface | Nature |
|--------|-----------|----------------|--------|
| **战车属性系统 (#17)** | IN | `durability_changed`, `magic_energy_changed` signals | Signal listener |
| **日夜循环系统 (#15)** | IN | `time_phase_changed` signal, `get_danger_multiplier()` query | Signal + Query |
| **时间系统 (#8)** | IN | `get_time_of_day()` query | Query API |
| **魔能消耗计算 (#19)** | IN | `get_consumption_rate()` query | Query API |
| **撤退警告UI (#50)** | OUT | `retreat_warning_triggered` signal | Signal emitter |
| **HUD系统 (#49)** | OUT | `retreat_warning_triggered` signal | Signal emitter |
| **撤退后果系统 (#33)** | OUT | `retreat_warning_triggered` signal | Signal emitter |

## Formulas

### Formula 1: Threshold Crossing Detection

`crossed_threshold = (old_ratio > threshold AND new_ratio <= threshold) OR (old_ratio < threshold AND new_ratio >= threshold)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `old_ratio` | — | float | 0.0-1.0 | 属性变化前的比例值 |
| `new_ratio` | — | float | 0.0-1.0 | 属性变化后的比例值 |
| `threshold` | T | float | 0.10-0.50 | 阈值定义（魔能/耐久阈值） |

**Output Range:** boolean (true = 阈值跨越, false = 未跨越)

**Example:** old_ratio=0.25 (魔能25%), new_ratio=0.18 (魔能18%), threshold=0.20 → crossed_threshold = true (跨越魔能警告阈值)

---

### Formula 2: Retreat Urgency Calculation

`urgency = max(magic_urgency, durability_urgency, time_urgency, danger_urgency)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `magic_urgency` | MU | float | 0.0-1.0 | 魔能紧迫度 |
| `durability_urgency` | DU | float | 0.0-1.0 | 耐久紧迫度 |
| `time_urgency` | TU | float | 0.0-1.0 | 时间紧迫度 |
| `danger_urgency` | DGU | float | 0.0-1.0 | 危险紧迫度 |

**Output Range:** 0.0 to 1.0 (0=无紧迫, 1=极度紧迫)

**Sub-Formula 2a: Magic Urgency**

`magic_urgency = clamp((MAGIC_WARN_THRESHOLD - current_magic_ratio) × MAGIC_WEIGHT, 0.0, 1.0)`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `MAGIC_WARN_THRESHOLD` | float | 0.20 (locked) | 魔能警告阈值（registry） |
| `current_magic_ratio` | float | 0.0-1.0 | 当前魔能比例值 |
| `MAGIC_WEIGHT` | float | 2.0 (tuning) | 魔能紧迫度权重系数 |

**Example:** current_magic_ratio=0.15, MAGIC_WARN_THRESHOLD=0.20, MAGIC_WEIGHT=2.0 → magic_urgency = (0.20-0.15)×2.0 = 0.10

**Sub-Formula 2b: Durability Urgency**

`durability_urgency = clamp((DURABILITY_WARN_THRESHOLD - current_durability_ratio) × DURABILITY_WEIGHT, 0.0, 1.0)`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `DURABILITY_WARN_THRESHOLD` | float | 0.30 (locked) | 耐久警告阈值（registry） |
| `current_durability_ratio` | float | 0.0-1.0 | 当前耐久比例值 |
| `DURABILITY_WEIGHT` | float | 1.5 (tuning) | 耐久紧迫度权重系数 |

**Example:** current_durability_ratio=0.20, threshold=0.30, weight=1.5 → durability_urgency = (0.30-0.20)×1.5 = 0.15

**Sub-Formula 2c: Time Urgency**

`time_urgency = clamp((phase_remaining_ratio) × TIME_WEIGHT, 0.0, 1.0)`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `phase_remaining_ratio` | float | 0.0-1.0 | 当前时段剩余时间比例（phase_end_time - current_time / phase_duration） |
| `TIME_WEIGHT` | float | 1.0 (tuning) | 时间紧迫度权重系数 |

**Example:** current_time=18:30 (黄昏中期), phase_end_time=20:00, phase_duration=2h → remaining_ratio=0.75 → time_urgency = 0.75×1.0 = 0.75

**Sub-Formula 2d: Danger Urgency**

`danger_urgency = clamp((danger_mult - BASE_DANGER) × DANGER_WEIGHT, 0.0, 1.0)`

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `danger_mult` | float | 0.8-1.5 | 当前危险倍率（DayNightCycle） |
| `BASE_DANGER` | float | 1.0 | 基准危险值（DAY时段） |
| `DANGER_WEIGHT` | float | 0.5 (tuning) | 危险紧迫度权重系数 |

**Example:** danger_mult=1.5 (NIGHT), BASE_DANGER=1.0, DANGER_WEIGHT=0.5 → danger_urgency = (1.5-1.0)×0.5 = 0.25

---

### Formula 3: Signal Cooldown Timer

`cooldown_remaining = cooldown_duration - (current_time - last_signal_time)`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `cooldown_duration` | CD | float | 10.0 | 冷却期时长（真实秒） |
| `current_time` | — | float | 0-∞ | 当前真实时间（秒） |
| `last_signal_time` | LST | float | 0-∞ | 上次发射信号的时间（秒） |

**Output Range:** 0.0 to cooldown_duration (0=冷却结束，可发射新信号)

**Example:** cooldown_duration=10s, current_time=45s, last_signal_time=40s → cooldown_remaining = 10 - (45-40) = 5s (冷却期内，禁止发射)

---

### Formula 4: Multi-Threshold Priority Score

`priority_score = Σ(reason × weight) for each triggered threshold`

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `reason` | enum | WarningReason | 触发的警告原因枚举 |
| `weight` | float | 0.0-1.0 | 各原因的权重系数 |

**Reason Weight Table:**

| Reason | Weight | Description |
|--------|--------|-------------|
| MAGIC_CRITICAL | 1.0 | 魔能极低，最高优先 |
| DURABILITY_CRITICAL | 0.9 | 耐久极低，高优先 |
| MAGIC_LOW | 0.6 | 魔能低，中等优先 |
| DURABILITY_LOW | 0.5 | 耐久低，中等优先 |
| TIME_NIGHT | 0.8 | 夜晚迫近，高优先 |
| TIME_DUSK | 0.4 | 黄昏将至，低优先 |
| DANGER_HIGH | 0.3 | 危险系数高，低优先 |

**Output Range:** 0.0 to 5.0 (sum of max weights if all triggered)

**Example:** MAGIC_LOW + TIME_DUSK triggered → priority_score = 0.6 + 0.4 = 1.0

## Edge Cases

1. **If ratio exactly equals threshold (e.g., magic_ratio = 0.20)**: Treat as threshold crossed — trigger WARNING level. Rationale: 20% is already the warning boundary, player should be alerted immediately.

2. **If multiple thresholds cross simultaneously in same signal frame**: Aggregate all triggered reasons, emit single signal with combined reasons array. Rationale: Avoid signal spam, provide unified warning context.

3. **If ratio recovers above threshold but warning already triggered**: Emit `retreat_warning_cleared()` signal after cooldown period ends. Rationale: Clear warning state, inform UI that emergency resolved.

4. **If cooldown timer active but CRITICAL threshold crosses**: Override cooldown, immediately emit CRITICAL signal. Rationale: CRITICAL urgency overrides noise control — player must be alerted.

5. **If magic_ratio reaches 0.0 (complete depletion)**: Force CRITICAL level regardless of other thresholds. Rationale: Zero魔能 means immediate stranded state, highest urgency.

6. **If durability_ratio reaches 0.0 (战车瘫痪)**: Force CRITICAL level and emit `vehicle_disabled` signal (handled by VehicleDamageSystem). Rationale: 瘫痪is terminal state, retreat becomes forced.

7. **If DayNightCycle query fails (returns null)**: Assume danger_mult = 1.0 (DAY baseline). Log warning `"DayNightCycle query failed, assuming baseline danger"`. Rationale: Fail-safe default, don't block retreat logic.

8. **If time_phase_changed signal received while WARNING active**: Recalculate time_urgency, update warning if level changes. Rationale: Phase change affects danger urgency, warning should reflect new state.

9. **If player manually triggers retreat before threshold triggers**: No signal emitted — retreat is player's proactive decision. Rationale: System monitors thresholds, not player actions. Player can retreat anytime without warning.

10. **If retreat_warning_triggered signal has no subscribers**: Log debug `"Retreat warning emitted but no UI subscribers"`. Signal still emitted for future subscribers. Rationale: Signal emission should not depend on subscriber presence.

11. **If MAGIC_WEIGHT set to 0.0**: magic_urgency always = 0, magic threshold effectively disabled. Log warning `"MAGIC_WEIGHT=0 disables magic urgency"`. Use for debugging/tutorial modes.

12. **If urgency calculation produces value > 1.0**: Clamp to 1.0 (maximum urgency). Rationale: UI expects 0-1 range for visual display.

## Dependencies

### Upstream Dependencies (Required)

| System | ID | Status | Data Flow | Interface |
|--------|----|---------|-----------|-----------|
| **时间系统** | #8 | Designed | `get_time_of_day()` → returns current game time | Query API |
| **日夜循环系统** | #15 | Designed | `get_danger_multiplier()` → returns danger_mult (0.8-1.5), `time_phase_changed` signal | Query + Signal |
| **战车属性系统** | #17 | Designed | `durability_changed`, `magic_energy_changed` signals → ratio updates | Signal listener |
| **魔能消耗计算** | #19 | Designed | `get_consumption_rate()` → returns magic consumption per second | Query API |

### Downstream Dependents (Consumers)

| System | ID | Status | Data Flow | Interface |
|--------|----|---------|-----------|-----------|
| **撤退警告UI** | #50 | Not Started | `retreat_warning_triggered` signal → displays warning popup | Signal listener |
| **HUD系统** | #49 | Not Started | `retreat_warning_triggered` signal → threshold flash alerts | Signal listener |
| **撤退后果系统** | #33 | Not Started | `retreat_warning_triggered` signal → tracks retreat timing for consequence calculation | Signal listener |

### Dependency Nature

| Dependency | Nature | Without it... |
|------------|--------|---------------|
| 时间系统 | **Hard** | Cannot calculate time urgency — 黄昏预警无数据源 |
| 日夜循环系统 | **Hard** | Cannot calculate danger urgency — 危险倍率无数据源 |
| 战车属性系统 | **Hard** | Cannot monitor 魔能/耐久 ratio — 无属性变化信号 |
| 魔能消耗计算 | **Soft** | Consumption rate useful but not critical — can use fallback estimate |

### Provisional Dependencies

None. All upstream dependencies have designed GDDs.

## Tuning Knobs

| Knob ID | Knob Name | Value | Range | Affects | Notes |
|---------|-----------|-------|-------|---------|-------|
| **TK-015** | `MAGIC_WARN_THRESHOLD_OVERRIDE` | 0.20 | 0.10-0.30 | 魔能警告阈值 | Overrides registry VEHICLE_RETREAT_MAGIC_THRESHOLD for local tuning. Lower = earlier warning, higher = later warning. |
| **TK-016** | `DURABILITY_WARN_THRESHOLD_OVERRIDE` | 0.30 | 0.15-0.40 | 耐久警告阈值 | Overrides registry VEHICLE_RETREAT_DURABILITY_THRESHOLD. Lower = earlier warning, higher = later warning. |
| **TK-017** | `MAGIC_CRITICAL_THRESHOLD` | 0.10 | 0.05-0.15 | 魔能紧急阈值 | CRITICAL level trigger point. Lower = more lenient, higher = stricter. |
| **TK-018** | `DURABILITY_CRITICAL_THRESHOLD` | 0.15 | 0.10-0.25 | 耐久紧急阈值 | CRITICAL level trigger point. |
| **TK-019** | `MAGIC_WEIGHT` | 2.0 | 0.5-3.0 | 魔能紧迫度权重 | Higher = magic urgency dominates, lower = magic less prioritized. |
| **TK-020** | `DURABILITY_WEIGHT` | 1.5 | 0.5-2.5 | 耐久紧迫度权重 | Higher = durability urgency dominates. |
| **TK-021** | `TIME_WEIGHT` | 1.0 | 0.5-2.0 | 时间紧迫度权重 | Higher = time urgency dominates (黄昏预警更紧迫). |
| **TK-022** | `DANGER_WEIGHT` | 0.5 | 0.0-1.0 | 危险紧迫度权重 | Higher = danger multiplier affects urgency more. |
| **TK-023** | `SIGNAL_COOLDOWN_SECONDS` | 10.0 | 5.0-30.0 | 警告信号冷却期 | Higher = less signal noise, lower = more responsive warnings. |
| **TK-024** | `TIME_DUSK_WARN_HOUR` | 18 | 17-19 | 黄昏警告触发时间 | 游戏小时。Earlier = more time buffer, later = tighter timing. |
| **TK-025** | `TIME_NIGHT_CRITICAL_HOUR` | 20 | 19-21 | 夜晚紧急触发时间 | 游戏小时。Must align with DayNightCycle phase boundaries. |

### Knob Interactions

- **`MAGIC_WARN_THRESHOLD_OVERRIDE` × `MAGIC_WEIGHT`** — 魔能阈值与权重共同影响魔能紧迫度。低阈值×高权重 = 魔能警告极敏感。
- **`TIME_WEIGHT` × `TIME_DUSK_WARN_HOUR`** — 时间权重与黄昏触发时间共同影响时间紧迫度。早触发×高权重 = 黄昏预警主导决策。
- **`SIGNAL_COOLDOWN_SECONDS`** — 冷却期独立于紧迫度计算，仅影响信号发射频率，不影响警告判定本身。

### Tuning Validation Advisory

> **⚠️ Playtest Required**: 当前默认值来自game-concept.md的锁定阈值。建议测试：
> - 如果撤退警告触发太晚，玩家来不及撤退 → 提高`MAGIC_WARN_THRESHOLD_OVERRIDE`到0.25或降低`TIME_DUSK_WARN_HOUR`到17
> - 如果警告触发太频繁，干扰游戏体验 → 提高`SIGNAL_COOLDOWN_SECONDS`到15或降低权重系数
> - 如果魔能警告优先级不够 → 提高`MAGIC_WEIGHT`到2.5

## Acceptance Criteria

### Core Rule Coverage

**AC-01**: GIVEN magic_ratio changes from 0.25 to 0.18, WHEN threshold check executes with MAGIC_WARN_THRESHOLD=0.20, THEN crossed_threshold=true, WARNING level triggered.

**AC-02**: GIVEN durability_ratio changes from 0.35 to 0.25, WHEN threshold check executes with DURABILITY_WARN_THRESHOLD=0.30, THEN crossed_threshold=true, WARNING level triggered.

**AC-03**: GIVEN magic_ratio changes from 0.15 to 0.08, WHEN threshold check executes with MAGIC_CRITICAL_THRESHOLD=0.10, THEN crossed_threshold=true, CRITICAL level triggered.

**AC-04**: GIVEN current_time=18:00 (黄昏开始), WHEN time_threshold check executes with TIME_DUSK_WARN_HOUR=18, THEN time_urgency triggered, WARNING level includes TIME_DUSK reason.

**AC-05**: GIVEN magic_ratio=0.18 AND durability_ratio=0.25 simultaneously, WHEN multi-factor aggregation executes, THEN reasons=[MAGIC_LOW, DURABILITY_LOW], level=WARNING.

**AC-06**: GIVEN WARNING level active AND cooldown_remaining=5s, WHEN CRITICAL threshold crosses (magic_ratio=0.08), THEN cooldown overridden, CRITICAL signal immediately emitted.

### Formula Coverage

**AC-07**: GIVEN current_magic_ratio=0.15, MAGIC_WARN_THRESHOLD=0.20, MAGIC_WEIGHT=2.0, WHEN magic_urgency calculated, THEN magic_urgency = (0.20-0.15)×2.0 = 0.10.

**AC-08**: GIVEN danger_mult=1.5, BASE_DANGER=1.0, DANGER_WEIGHT=0.5, WHEN danger_urgency calculated, THEN danger_urgency = (1.5-1.0)×0.5 = 0.25.

**AC-09**: GIVEN magic_urgency=0.10, durability_urgency=0.15, time_urgency=0.75, danger_urgency=0.25, WHEN aggregate urgency calculated, THEN urgency = max(0.10, 0.15, 0.75, 0.25) = 0.75.

**AC-10**: GIVEN cooldown_duration=10s, current_time=45s, last_signal_time=40s, WHEN cooldown_remaining calculated, THEN cooldown_remaining = 10 - (45-40) = 5s.

### Edge Case Coverage

**AC-11**: GIVEN magic_ratio exactly equals 0.20, WHEN threshold check executes, THEN WARNING level triggered (exact threshold counts as crossed).

**AC-12**: GIVEN magic_ratio=0.0 (complete depletion), WHEN threshold check executes, THEN CRITICAL level forced regardless of other thresholds.

**AC-13**: GIVEN DayNightCycle query returns null, WHEN danger_urgency calculated, THEN fallback danger_mult=1.0 used, warning logged.

**AC-14**: GIVEN WARNING active AND ratio recovers above threshold (magic_ratio=0.25), WHEN cooldown ends, THEN `retreat_warning_cleared()` signal emitted.

**AC-15**: GIVEN urgency calculation produces 1.5 (>1.0), WHEN clamp applied, THEN urgency=1.0 (clamped to maximum).

### System Integration Coverage

**AC-16**: GIVEN `durability_changed` signal received from VehicleAttributeSystem, WHEN RetreatJudgment processes signal, THEN threshold check triggered within same frame.

**AC-17**: GIVEN `time_phase_changed(DUSK)` signal received, WHEN RetreatJudgment recalculates, THEN time_urgency updated, warning level may change.

**AC-18**: GIVEN `retreat_warning_triggered` signal emitted, WHEN no subscribers present, THEN signal still emitted, debug log `"no UI subscribers"`.

## Visual/Audio Requirements

撤退判定系统为纯判定层，无直接视觉/音频资源需求。警告信号由下游UI系统消费显示。

**信号触发下游视觉反馈（由撤退警告UI和HUD系统实现）：**

| Signal | Visual Effect | Audio Effect | Owner System |
|--------|---------------|--------------|--------------|
| `retreat_warning_triggered(WARNING)` | HUD魔能/耐久条黄色闪烁，轻度警报 | 低频警报音效 | 撤退警告UI (#50), HUD (#49) |
| `retreat_warning_triggered(CRITICAL)` | HUD魔能/耐久条红色脉冲，屏幕边缘红色警告光晕 | 高频警报音效，持续节奏 | 撤退警告UI (#50), HUD (#49) |
| `retreat_warning_cleared()` | 闪烁停止，恢复正常显示，解除警报音效 | 解除音效 | 撤退警告UI (#50), HUD (#49) |

**紧迫度可视化参数（供HUD系统消费）：**

| urgency value | Visual Intensity |
|---------------|-----------------|
| 0.0-0.3 | 低紧迫，黄色提示 |
| 0.3-0.6 | 中紧迫，橙色警告 |
| 0.6-1.0 | 高紧迫，红色紧急 |

## UI Requirements

撤退判定系统为数据层，UI需求由下游系统消费。

**撤退警告UI (#50) 显示需求：**

- **警告弹窗**：当`retreat_warning_triggered`信号到达时弹出警告弹窗
- **弹窗内容**：显示触发原因列表（reasons数组）、紧迫度数值（urgency）
- **弹窗样式**：WARNING级别=黄色边框，CRITICAL级别=红色边框+紧急图标
- **交互选项**：弹窗提供"立即撤退"和"继续探索"按钮（玩家决策）

**HUD系统 (#49) 显示需求：**

- **阈值逼近指示**：当ratio接近阈值时（如魔能25%逼近20%阈值），预先显示警告提示
- **闪烁动画**：当阈值触发时，对应资源条开始闪烁动画
- **紧迫度条**：HUD角落显示紧迫度进度条（0-100%映射urgency 0-1）

## Open Questions

1. **撤退后果系统(#33)如何处理超时撤退？**

   当前GDD定义撤退判定触发警告信号，但未定义"超时撤退"的处理逻辑。如果玩家忽视CRITICAL警告继续探索，撤退后果系统是否强制触发瘫痪/死亡后果？建议：撤退判定系统仅发射警告信号，后果由撤退后果系统独立处理。CRITICAL警告持续30真实秒后自动触发`retreat_failed`信号（待定义）。

   → **待定**：撤退后果系统(#33)设计时定义超时处理逻辑。

2. **魔能消耗速率预测如何实现？**

   当前GDD定义紧迫度计算，但未定义"续航预测"（魔能剩余可支撑多少路程）。撤退警告UI可能需要显示"魔能可支撑X格"的预测信息。建议：魔能消耗系统(#19)提供`get_remaining_range(magic_ratio)`接口，返回剩余续航格数。撤退判定系统查询此接口，计算到车库的距离是否足够。

   → **待定义**：魔能消耗系统(#19)是否需要续航预测接口。

3. **CRITICAL级别是否强制限制玩家行动？**

   当前GDD定义CRITICAL警告，但未定义是否强制阻止玩家继续探索。如果魔能归零或耐久归零，玩家是否被强制禁止行动？建议：CRITICAL警告仅显示UI提示，不强制阻止。玩家仍可冒险继续，但后果由撤退后果系统处理。这保持"玩家主动决策"而非"系统强制禁止"的核心体验。

   → **MVP简化**：CRITICAL警告仅UI提示，不强制阻止行动。后果由撤退后果系统处理。

4. **警告阈值是否需要动态调整（如载重影响）？**

   当前阈值固定（魔能20%、耐久30%）。但载重可能影响魔能消耗速率，高载重玩家可能需要更早撤退。建议：阈值固定，紧迫度计算中权重系数可tuning。载重影响已通过魔能消耗系统的`load_cost_modifier`体现，撤退紧迫度自然反映载重风险。

   → **设计决策**：阈值固定，载重影响通过紧迫度权重间接体现。