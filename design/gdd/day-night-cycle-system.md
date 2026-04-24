# 日夜循环系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 2 — 搜打撤节奏 (夜晚高危驱动撤退决策)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #15 (from systems-index.md)

## Overview

日夜循环系统是时间系统的时间阶段信号到视觉和游戏效果层的桥梁。它监听时间系统发出的 `time_phase_changed(phase)` 信号，根据当前阶段（黎明/白天/黄昏/夜晚）触发对应的视觉效果和游戏难度调整。

**数据层职责**：
- 接收 `time_phase_changed(phase)` 信号，识别新阶段
- 应用阶段对应的视觉参数：环境光颜色、亮度、天空色调
- 应用阶段对应的游戏参数：危险等级倍率、敌人生成率修正
- 发射 `phase_effects_applied(phase)` 信号通知下游系统效果已生效

**玩家影响层（间接）**：
- 夜晚环境变暗，视野受限，远处丧尸低吼增多——视觉传达"危险升级"
- 夜晚敌人生成率提高，危险等级倍率生效——游戏难度传达"夜间高危"
- 黄昏时分撤退压力增加，玩家学会"日落前撤退"的节奏感——Pillar 2决策压力

**核心价值**：日夜循环系统将时间系统的抽象阶段数据转化为玩家可感知的环境变化和难度调整。没有它，时间只是计数器；有了它，时间成为"风险/安全周期"的驱动因素。

**下游消费系统**：
- 撤退判定系统 — 查询当前危险等级倍率
- 敌人生成系统 — 查询敌人生成率修正
- HUD系统 — 显示当前阶段名称和图标

## Player Fantasy

日夜循环系统没有直接的玩家幻想——它是效果触发层，玩家不会"感知"到阶段切换的执行。玩家体验的是阶段效果在实际游戏中的表现：夜晚的黑暗压迫感、白天的相对安全感、黄昏的"撤退倒计时"焦虑感。

**玩家间接体验（由阶段效果驱动）**：

- **夜晚压迫感**: 夜幕降临，环境光亮度降至30%，视野受限，远处丧尸低吼增多。玩家感受到"现在很危险"——视觉和音效共同传达夜晚的高风险状态。
- **白天安全感**: 白天环境明亮（亮度100%），敌人活动减少。玩家感受到"现在可以安心探索"——阶段效果创造了风险/安全周期。
- **黄昏焦虑感**: 黄昏时分，环境光渐暗，UI显示"黄昏警告"。玩家感受到"太阳快下山了，还要多久撤退？"——这是Pillar 2（搜打撤节奏）的核心决策点。

**支柱间接贡献**：

- **Pillar 2: 搜打撤节奏** — 日夜循环创造了"安全时段"与"危险时段"的周期。玩家学会判断"还有多久天黑？"、"天黑前能再搜一个吗？"。阶段切换时间定义了这种节奏的边界。

## Detailed Design

### Core Rules

**Rule 1: Phase Signal Subscription**

日夜循环系统订阅时间系统的 `time_phase_changed(phase)` 信号。信号参数为 `TimePhase` 枚举值（DAWN/DAY/DUSK/NIGHT）。收到信号后，系统立即触发效果应用流程。

**Phase枚举值（继承自时间系统）**：

| Phase | Value | 时间范围 | 视觉效果 | 游戏效果 |
|-------|-------|----------|----------|----------|
| DAWN | 0 | 05:00-07:00 | 光照渐亮，暖色调 | 危险等级×0.8 |
| DAY | 1 | 07:00-18:00 | 光照100%，蓝白色调 | 危险等级×1.0（基准） |
| DUSK | 2 | 18:00-20:00 | 光照渐暗，橙红色调 | 危险等级×1.2 |
| NIGHT | 3 | 20:00-05:00 | 光照30%，深蓝暗色调 | 危险等级×1.5 |

---

**Rule 2: Visual Effects Application**

阶段切换时，系统应用环境光参数到场景的 `Environment` 节点。

**视觉参数定义**：

| Phase | Ambient Brightness | Sky Color | Fog Density | Transition Duration |
|-------|-------------------|-----------|-------------|---------------------|
| DAWN | 0.6 → 0.9 | 橙→浅蓝 | 0.01 | 30 game seconds |
| DAY | 1.0 | 浅蓝 | 0.005 | 0 (instant) |
| DUSK | 0.9 → 0.5 | 浅蓝→橙红 | 0.01 → 0.02 | 30 game seconds |
| NIGHT | 0.3 | 深蓝黑 | 0.03 | 30 game seconds |

**过渡规则**：
- DAWN→DAY 和 DUSK→NIGHT 使用30游戏秒渐变过渡（平滑视觉体验）
- DAY→DUSK 和 NIGHT→DAWN 同样使用渐变过渡
- 过渡期间参数线性插值：`current = start + (end - start) × (elapsed / duration)`
- 过渡完成后锁定参数至目标值

---

**Rule 3: Gameplay Effects Application**

阶段切换时，系统更新全局危险等级倍率，供下游系统查询。

**危险等级倍率公式**：

```
danger_multiplier = PHASE_DANGER_BASE × DANGER_GLOBAL_MULT
```

**Phase基准倍率**：

| Phase | PHASE_DANGER_BASE |
|-------|-------------------|
| DAWN | 0.8 |
| DAY | 1.0 |
| DUSK | 1.2 |
| NIGHT | 1.5 |

**全局调优参数**：`DANGER_GLOBAL_MULT`（默认=1.0，范围0.5-2.0）

---

**Rule 4: Query Interface**

系统提供查询接口供下游系统使用。

```gdscript
# DayNightCycle.gd (autoload singleton)
class_name DayNightCycle

func get_current_phase() -> TimePhase
func get_danger_multiplier() -> float
func get_visual_params() -> Dictionary  # {brightness, sky_color, fog_density}
func get_phase_time_remaining() -> float  # seconds until next phase
```

---

**Rule 5: Phase Effects Signal**

效果应用完成后，系统发射确认信号供下游系统订阅。

```gdscript
signal phase_effects_applied(phase: TimePhase, danger_mult: float)
```

---

### States and Transitions

日夜循环系统无内部状态机——它的"状态"由当前TimePhase决定，继承自时间系统。

**Phase-Driven Behavior**：

| Phase | Visual State | Gameplay State | Signal Output |
|-------|--------------|----------------|---------------|
| DAWN | 渐亮过渡中/已完成 | danger_mult=0.8 | `phase_effects_applied(DAWN, 0.8)` |
| DAY | 光照100%锁定 | danger_mult=1.0 | `phase_effects_applied(DAY, 1.0)` |
| DUSK | 渐暗过渡中/已完成 | danger_mult=1.2 | `phase_effects_applied(DUSK, 1.2)` |
| NIGHT | 光照30%锁定 | danger_mult=1.5 | `phase_effects_applied(NIGHT, 1.5)` |

---

### Interactions with Other Systems

| System | Direction | Data Interface | Nature |
|--------|-----------|----------------|--------|
| **时间系统 (#8)** | IN | `time_phase_changed(phase)` signal | Signal listener |
| **撤退判定系统 (#32)** | OUT | `get_danger_multiplier()` → returns float | Query API |
| **敌人生成系统 (#37)** | OUT | `get_danger_multiplier()` → affects spawn rate | Query API |
| **HUD系统 (#49)** | OUT | `get_current_phase()` → returns TimePhase | Query API |
| **Audio系统 (#52)** | OUT | `phase_effects_applied` → triggers ambient sound changes | Signal emitter |

## Formulas

### Formula 1: Danger Multiplier Calculation

`danger_multiplier = PHASE_DANGER_BASE × DANGER_GLOBAL_MULT`

**Variables:**

| Variable | Symbol | Type | Range | Description |
|----------|--------|------|-------|-------------|
| `PHASE_DANGER_BASE` | — | float | 0.8-1.5 | Phase基准倍率，由当前TimePhase决定 |
| `DANGER_GLOBAL_MULT` | DGM | float | 0.5-2.0 | 全局危险等级调优参数（tuning knob） |

**Phase基准倍率表:**

| Phase | PHASE_DANGER_BASE |
|-------|-------------------|
| DAWN | 0.8 |
| DAY | 1.0 |
| DUSK | 1.2 |
| NIGHT | 1.5 |

**Output Range:** 0.4 (DAWN × 0.5) to 3.0 (NIGHT × 2.0)

**Example:** NIGHT phase, DGM=1.0 → danger_multiplier = 1.5 × 1.0 = 1.5

---

### Formula 2: Visual Parameter Interpolation

`current_value = start_value + (end_value - start_value) × (elapsed_time / transition_duration)`

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `start_value` | float | 0.0-1.0 | 过渡起始值（当前phase的锁定值） |
| `end_value` | float | 0.0-1.0 | 过渡目标值（新phase的锁定值） |
| `elapsed_time` | float | 0-30 | 已经过的游戏秒数（从phase切换开始） |
| `transition_duration` | float | 30 | 固定过渡时长（游戏秒） |

**Output Range:** Linear interpolation from start_value to end_value

**Example:** DAWN→DAY brightness transition
- start_value=0.6 (DAWN brightness at phase end)
- end_value=1.0 (DAY brightness)
- elapsed_time=15s → current = 0.6 + (1.0-0.6) × (15/30) = 0.8

---

### Formula 3: Phase Time Remaining (Query from Time System)

`phase_time_remaining = TimeSystem.get_phase_remaining_seconds()`

**Note:** 此值由时间系统计算并提供。日夜循环系统通过查询接口获取，不自行计算。

**Output Range:** 0 to 7200 (最长phase为DAY，12小时=7200游戏秒)

---

### Formula 4: Phase Time Remaining (Real Seconds)

`real_seconds_remaining = phase_time_remaining / BASE_TIME_SCALE`

**Variables:**

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `phase_time_remaining` | float | 0-7200 | 游戏秒（来自时间系统） |
| `BASE_TIME_SCALE` | float | 72.0 | 时间倍率（1 real sec = 72 game sec） |

**Output Range:** 0 to 100 real seconds

**Example:** phase_time_remaining=3600 (game seconds) → real_seconds = 3600/72 = 50 seconds

## Edge Cases

1. **If `time_phase_changed` signal received while visual transition is still active**: Interrupt the previous transition, immediately set current interpolated values as start, then begin new transition to the new phase's target values. Rationale: Prevents visual glitch when rapid phase changes occur (e.g., debug/testing scenarios).

2. **If `DANGER_GLOBAL_MULT` set to 0.0**: All danger multipliers become 0. No gameplay effects applied. Log warning `"DANGER_GLOBAL_MULT=0.0 disables all phase danger effects"`. Use for special scenarios (e.g., tutorial safe zone).

3. **If `DANGER_GLOBAL_MULT` exceeds 2.0**: Clamp to max value 2.0. Log warning `"DANGER_GLOBAL_MULT=[value] clamped to 2.0"`. Rationale: Prevents runaway danger scaling that breaks game balance.

4. **If `TimeSystem` query returns null for `get_phase_remaining_seconds()`: Return fallback value `0.0`. Log warning `"TimeSystem query failed — phase time unknown"`. Downstream systems should handle gracefully.

5. **If phase transition duration (30 game seconds) exceeds phase length**: Rare edge case if time scale is dramatically slowed. In practice, shortest phases (DAWN/DUSK) are 2 hours = 7200 game seconds, always > 30s transition.

6. **If multiple systems query `get_danger_multiplier()` simultaneously**: Return cached value — no recalculation needed. The multiplier is fixed per phase until next `time_phase_changed`.

7. **If downstream system subscribes to `phase_effects_applied` but signal never emitted**: Log error `"phase_effects_applied not emitted after [N] seconds"`. Indicates upstream failure in signal chain. Timeout threshold: 5 real seconds after phase change.

8. **If visual parameters exceed valid ranges (e.g., brightness > 1.0)**: Clamp to valid range [0.0, 1.0]. Log warning `"Brightness clamped from [value] to 1.0"`. Rationale: Prevents rendering artifacts from invalid Environment values.

9. **If fog density calculation produces negative value**: Treat as 0.0 (no fog). Minimum fog density is 0.0.

10. **If phase change occurs during pause/menu state**: Visual effects still apply, but danger multiplier changes deferred until gameplay resumes. Query `get_danger_multiplier()` returns pre-pause value during pause.

## Dependencies

### Upstream Dependencies (Required)

| System | ID | Status | Data Flow | Interface |
|--------|----|---------|-----------|-----------|
| **时间系统** | #8 | Designed | Emits `time_phase_changed(phase: TimePhase)` signal | Signal source |

### Downstream Dependents (Consumers)

| System | ID | Status | Data Flow | Interface |
|--------|----|---------|-----------|-----------|
| **撤退判定系统** | #32 | Not Started | Queries `get_danger_multiplier()` → returns float | Query API |
| **敌人生成系统** | #37 | Designed | Queries `get_danger_multiplier()` → affects spawn rate | Query API |
| **HUD系统** | #49 | Not Started | Queries `get_current_phase()` → returns TimePhase | Query API |

### Dependency Nature

| Dependency | Nature | Without it... |
|------------|--------|---------------|
| 时间系统 | **Hard** | No phase change signal — system never triggers |

### Provisional Dependencies

All downstream dependents are documented in systems-index.md. No provisional assumptions required.

## Tuning Knobs

| Knob ID | Knob Name | Value | Range | Affects | Notes |
|---------|-----------|-------|-------|---------|-------|
| **TK-006** | `DANGER_GLOBAL_MULT` | 1.0 | 0.5-2.0 | All danger multipliers | ×2.0 = 夜晚危险等级×3.0；×0.5 = 所有时段更安全 |
| **TK-007** | `TRANSITION_DURATION` | 30 | 10-60 | Visual transition smoothness | 游戏秒；值越大过渡越平滑，但切换感越弱 |

### Knob Interactions

- **`DANGER_GLOBAL_MULT` × `PHASE_DANGER_BASE`** — 最终危险倍率 = phase基准 × 全局倍率。全局倍率对所有phase均匀缩放，保持相对比例不变。
- **`TRANSITION_DURATION`** — 仅影响视觉效果，不影响gameplay效果生效时机（danger multiplier在phase切换时立即更新）。

### Tuning Validation Advisory

> **⚠️ Playtest Required**: 当前默认值（DANGER_GLOBAL_MULT=1.0）可能需要根据实际撤退压力调整：
> - 如果夜晚危险感不足，玩家不撤退 → 提高DANGER_GLOBAL_MULT到1.2-1.5
> - 如果夜晚太危险，玩家被迫过早撤退 → 降低到0.8
> - 如果黄昏警告时间太短（玩家来不及撤退） → 检查时间系统的phase边界配置

## Visual/Audio Requirements

日夜循环系统是效果触发层，无直接视觉/音频资源需求。视觉效果由Godot Environment节点参数控制（brightness, sky_color, fog_density），不需要额外素材。Audio系统订阅`phase_effects_applied`信号自行触发环境音效变化。

## UI Requirements

无直接UI需求。HUD系统通过`get_current_phase()`查询显示当前阶段图标，撤退警告UI通过`get_danger_multiplier()`判断警告级别。

## Acceptance Criteria

### Core Rule Coverage

**AC-01**: GIVEN `time_phase_changed(NIGHT)` signal received, WHEN system processes signal, THEN `get_danger_multiplier()` returns 1.5 (PHASE_DANGER_BASE × DGM=1.0).

**AC-02**: GIVEN `time_phase_changed(DAWN)` signal received, WHEN system processes signal, THEN `get_danger_multiplier()` returns 0.8.

**AC-03**: GIVEN `time_phase_changed(DAY)` signal received, WHEN system processes signal, THEN visual params brightness=1.0, sky_color=浅蓝, fog_density=0.005 applied immediately.

**AC-04**: GIVEN `time_phase_changed(DUSK)` signal received, WHEN visual transition starts, THEN brightness interpolates from current to 0.5 over 30 game seconds.

**AC-05**: GIVEN phase effects applied, WHEN downstream system subscribed to `phase_effects_applied`, THEN signal emitted with phase and danger_mult within same frame.

### Formula Coverage

**AC-06**: GIVEN DANGER_GLOBAL_MULT=1.5, WHEN NIGHT phase active, THEN danger_multiplier = 1.5 × 1.5 = 2.25.

**AC-07**: GIVEN visual transition elapsed_time=15s, transition_duration=30s, start=0.6, end=1.0, WHEN interpolation calculated, THEN current_value = 0.8.

**AC-08**: GIVEN phase_time_remaining=3600 game seconds, BASE_TIME_SCALE=72.0, WHEN real seconds calculated, THEN real_seconds_remaining = 50.

### Edge Case Coverage

**AC-09**: GIVEN visual transition active (elapsed=10s), WHEN new phase change signal received, THEN previous transition interrupted, new transition started from current interpolated value.

**AC-10**: GIVEN DANGER_GLOBAL_MULT=0.0, WHEN phase change processed, THEN danger_multiplier=0 for all phases, warning logged.

**AC-11**: GIVEN DANGER_GLOBAL_MULT=3.0, WHEN knob applied, THEN value clamped to 2.0, warning logged.

**AC-12**: GIVEN TimeSystem query returns null, WHEN `get_phase_time_remaining()` called, THEN returns 0.0, warning logged.

**AC-13**: GIVEN phase change during pause state, WHEN `get_danger_multiplier()` queried, THEN returns pre-pause value (deferred update).

### System Integration Coverage

**AC-14**: GIVEN multiple systems query `get_danger_multiplier()` in same frame, WHEN phase active, THEN all receive same cached value (no recalculation).

**AC-15**: GIVEN `phase_effects_applied` signal subscription, WHEN signal not emitted within 5 real seconds after phase change, THEN error logged indicating upstream failure.

## Open Questions

None. All core questions resolved by inheriting from 时间系统 design (phase boundaries, BASE_TIME_SCALE, signal architecture).