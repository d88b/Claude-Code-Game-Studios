# 时间系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-22
> **Implements Pillar**: Pillar 2 (搜打撤节奏), Pillar 3 (尸潮即高潮)
> **Priority**: MVP | **Layer**: Foundation
> **System ID**: #8 (from systems-index.md)

## Overview

时间系统是管理游戏世界时间流逝的基础设施层系统。它维护一个全局GameTime单例，追踪游戏开始以来的累计秒数、当前游戏日数、时间段（昼夜循环段）、加速/暂停状态。系统提供`get_game_time()`、`get_days_elapsed()`、`get_time_of_day()`等查询接口供下游系统调用。

作为Foundation层系统，时间系统是所有周期性游戏行为的基础：**日夜循环系统**查询时间段触发光照/敌人行为变化，**撤退判定系统**追踪探索持续时间判断撤退时机，**尸潮周期系统**累计天数触发周期性防守事件。玩家不直接与时间系统交互，但感受到其下游效应——倒计时压力、日夜变化、尸潮逼近。这服务于Pillar 2（搜打撤节奏）——时间创造决策紧迫感；Pillar 3（尸潮即高潮）——天数累计驱动防守周期。

**设计决策**：
- 使用Autoload singleton模式（extends Node），提供全局时间查询接口
- 游戏时间与实时时间解耦：1 real second = configurable game seconds（默认60秒=1游戏分钟）
- 支持时间加速（×2、×5）和暂停（UI暂停/战车维修时）
- 提供Signal通知时间变化：`time_advanced(delta)`、`day_started(day_num)`、`time_phase_changed(phase)`

## Player Fantasy

玩家不直接与时间系统交互，而是通过其下游效应体验"时间流逝"的游戏意义：

- **探索时的紧迫感**：撤退倒计时显示在HUD，每秒流逝都在提醒"还能再搜一个废墟吗？"——时间系统为撤退判定提供数据，玩家感受到的是Pillar 2的决策压力
- **日夜变化的环境反馈**：从白天进入黄昏，光照渐暗，远处传来更多丧尸低吼——时间系统为日夜循环提供时间段数据，玩家感受到的是环境风险升级
- **尸潮逼近的周期压力**：每N天一次尸潮防守，倒计时天数显示在UI——时间系统为尸潮周期提供天数累计，玩家感受到的是"下次防守还有多久？"

**锚定时刻**：第一次在黄昏时分被迫撤退，战车魔能只剩15%，远处尸潮警报响起。玩家意识到"时间不等人"——这不是时间系统的直接体验，而是搜打撤节奏的真实压力。时间系统是这种体验的数学基础。

## Detailed Design

### Core Rules

#### 1. Game Time Data Structure

GameTime单例维护全局游戏时间状态：

| 字段名 | 类型 | 初始值 | 说明 |
|--------|------|--------|------|
| `total_game_seconds` | float | 0.0 | 累计游戏秒数（游戏内时间） |
| `days_elapsed` | int | 0 | 已过去的天数（从第0天开始） |
| `current_phase` | TimePhase | DAWN | 当前时间阶段（黎明/白天/黄昏/夜晚） |
| `speed_multiplier` | float | 1.0 | 时间流速倍率 |
| `is_paused` | bool | false | 时间暂停状态 |
| `session_start_time` | float | 0.0 | 当前探索会话开始时间（真实时间） |

**TimePhase枚举：**

```
enum TimePhase { DAWN, DAY, DUSK, NIGHT }
```

---

#### 2. Time Flow Rules

**时间推进公式（每帧）：**

```
game_seconds_elapsed = delta × BASE_TIME_SCALE × speed_multiplier
total_game_seconds += game_seconds_elapsed
```

**常量定义：**

| 常量名 | 值 | 说明 |
|--------|-----|------|
| `GAME_SECONDS_PER_DAY` | 86400 | 一天的游戏秒数（24小时×3600秒） |
| `BASE_TIME_SCALE` | 72.0 | 基础时间缩放比（1真实秒 = 72游戏秒） |
| `REAL_SECONDS_PER_GAME_DAY` | 1200 | 一个游戏日 = 20真实分钟 |

**时间推进规则：**

1. 每帧在`_process(delta)`中推进，若`is_paused = false`
2. 推进后检查跨天（天数变化）和阶段变化
3. 发射`time_advanced`信号通知下游系统

**暂停触发条件：**

| 条件 | is_paused | 说明 |
|------|-----------|------|
| 游戏启动加载 | true | 初始化完成前 |
| 主菜单界面 | true | 未进入游戏 |
| 对话/剧情演出 | true | 脚本控制阶段 |
| 暂停菜单打开 | true | 玩家主动暂停 |
| 撤退结算界面 | true | 回合结算 |

**不暂停的条件（时间继续流逝）：**

- 建造模式
- 物品栏界面
- 地图界面
- 战车驾驶（核心玩法）

---

#### 3. Day Cycle Definition

**游戏日与真实时间映射：**

| 映射关系 | 值 |
|----------|-----|
| 1 游戏日 | 20 真实分钟 |
| 1 游戏小时 | 50 真实秒 |
| 默认探索会话 | 1.5-3 游戏日 |

**跨天检测规则：**

```
current_day = int(total_game_seconds / GAME_SECONDS_PER_DAY)
if current_day > days_elapsed:
    emit day_started(current_day, days_elapsed)
    days_elapsed = current_day
```

---

#### 4. Time Phase System

**时间阶段边界定义：**

| 阶段 | 游戏时间范围 | 持续时长 | 真实时长 | 危险等级 |
|------|-------------|----------|----------|----------|
| DAWN（黎明） | 05:00 - 07:00 | 2小时 | 1分40秒 | 中 |
| DAY（白天） | 07:00 - 18:00 | 11小时 | 9分10秒 | 低 |
| DUSK（黄昏） | 18:00 - 20:00 | 2小时 | 1分40秒 | 中 |
| NIGHT（夜晚） | 20:00 - 05:00 | 9小时 | 7分30秒 | 高 |

**阶段判定逻辑：**

```gdscript
func determine_phase(hour: float) -> TimePhase:
    if hour >= 5.0 and hour < 7.0: return DAWN
    elif hour >= 7.0 and hour < 18.0: return DAY
    elif hour >= 18.0 and hour < 20.0: return DUSK
    else: return NIGHT
```

---

#### 5. Time Manipulation Rules

**时间倍率选项（建造模式）：**

| 倍率 | speed_multiplier | 适用场景 |
|------|------------------|----------|
| 正常 | 1.0 | 默认/探索模式 |
| 快速 | 2.0 | 建造模式 |
| 极速 | 5.0 | 安全区深层建造 |

**倍率限制：**

- 探索模式禁止改变时间倍率
- 范围限制：`clamp(multiplier, 0.5, 5.0)`

---

#### 6. Signal/Event Architecture

**TimeSignals单例信号：**

| 信号 | 参数 | 发射时机 |
|------|------|----------|
| `time_advanced` | game_seconds: float | 每帧推进 |
| `hour_changed` | hour, previous_hour | 每游戏小时边界 |
| `day_started` | day, previous_day | 每游戏日边界 |
| `phase_changed` | new_phase, old_phase | 阶段边界 |
| `time_paused` | source: String | 暂停触发 |
| `time_resumed` | source: String | 暂停解除 |
| `time_speed_changed` | multiplier: float | 倍率改变 |

---

#### 7. Query API

**基础查询：**

```gdscript
func get_game_time() -> Dictionary  # 返回完整时间状态
func get_days_elapsed() -> int       # 天数计数
func get_current_phase() -> TimePhase  # 当前阶段
func get_current_hour() -> float     # 当前小时（0.0-24.0）
func get_time_of_day() -> float      # 当天进度（0.0-1.0）
```

**会话追踪（搜打撤判定用）：**

```gdscript
func start_exploration_session() -> String  # 开始探索，返回session_id
func end_exploration_session(id) -> Dictionary  # 结束探索，返回duration
func get_session_duration() -> float  # 当前会话真实秒数
```

**判定辅助：**

```gdscript
func is_day() -> bool
func is_night() -> bool
func is_dangerous_time() -> bool  # DUSK或NIGHT
func get_seconds_until_phase(target) -> float  # 到目标阶段剩余秒数
```

---

### States and Transitions

时间系统本身无复杂状态机，但`is_paused`和`speed_multiplier`影响时间推进：

| 状态维度 | 值 | 转换条件 |
|----------|-----|----------|
| **Flow状态** | RUNNING / PAUSED | 玩家暂停/剧情触发/结算界面 |
| **Speed状态** | NORMAL / FAST / VERY_FAST | 建造模式激活 |
| **Phase状态** | DAWN → DAY → DUSK → NIGHT → DAWN | 时间推进触发阶段边界 |

---

### Interactions with Other Systems

**下游系统接口契约：**

| 下游系统 | 接口调用 | 数据流向 | 用途 |
|----------|----------|----------|------|
| **日夜循环系统 (#15)** | `get_current_phase()`, `phase_changed`信号 | Time → DayNight | 阶段变化触发光照切换 |
| **撤退判定系统 (#32)** | `get_session_duration()`, `get_current_hour()` | Time → Retreat | 探索时长+时间段判定撤退时机 |
| **尸潮周期系统 (#34)** | `get_days_elapsed()`, `day_started`信号 | Time → TideCycle | 天数累计触发尸潮 |
| **天气系统 (#16)** | `get_time_of_day()` | Time → Weather | 时间段触发天气变化 |

## Formulas

### 1. Game Time Advancement

**Formula:**
```
game_seconds_elapsed = delta × BASE_TIME_SCALE × speed_multiplier
total_game_seconds += game_seconds_elapsed
```

**Variables:**

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `delta` | float | 0.0167 (60fps) | Engine `_process()` |
| `BASE_TIME_SCALE` | float | 72.0 | Constant |
| `speed_multiplier` | float | 0.5 - 5.0 | Speed state |

**Output Range:**
- Normal speed: ~1.2 game seconds per real frame
- Fast speed (×2): ~2.4 game seconds per real frame
- Very fast (×5): ~6.0 game seconds per real frame

---

### 2. Day Elapsed Calculation

**Formula:**
```
days_elapsed = floor(total_game_seconds / GAME_SECONDS_PER_DAY)
```

**Variables:**

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `total_game_seconds` | float | 0.0 - ∞ | Accumulated time |
| `GAME_SECONDS_PER_DAY` | int | 86400 | Constant |

**Output Range:** 0 - ∞ (integer days elapsed)

---

### 3. Current Hour Calculation

**Formula:**
```
GAME_SECONDS_PER_HOUR = 3600
current_hour = fmod(total_game_seconds, GAME_SECONDS_PER_DAY) / GAME_SECONDS_PER_HOUR
```

**Variables:**

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `total_game_seconds` | float | 0.0 - ∞ | Accumulated time |
| `GAME_SECONDS_PER_DAY` | int | 86400 | Constant |
| `GAME_SECONDS_PER_HOUR` | int | 3600 | Constant |

**Output Range:** 0.0 - 24.0 (float representing hour of day)

---

### 4. Time Phase Determination

**Formula:**
```
func determine_phase(hour: float) -> TimePhase:
    if hour >= 5.0 and hour < 7.0: return DAWN
    elif hour >= 7.0 and hour < 18.0: return DAY
    elif hour >= 18.0 and hour < 20.0: return DUSK
    else: return NIGHT
```

**Input Range:** 0.0 - 24.0 (hour)

**Output:** TimePhase enum (DAWN / DAY / DUSK / NIGHT)

---

### 5. Seconds Until Target Phase

**Formula:**
```
seconds_until_phase = calculate_phase_boundary(target_phase) - total_game_seconds
if seconds_until_phase < 0:
    seconds_until_phase += GAME_SECONDS_PER_DAY  # Wrap to next day
```

**Variables:**

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `target_phase` | TimePhase | enum | Caller request |
| `total_game_seconds` | float | 0.0 - ∞ | Accumulated time |

**Phase Boundary Hours:**
- DAWN: 5:00 = 18000 game seconds
- DAY: 7:00 = 25200 game seconds
- DUSK: 18:00 = 64800 game seconds
- NIGHT: 20:00 = 72000 game seconds

**Output Range:** 0.0 - GAME_SECONDS_PER_DAY (positive seconds until transition)

---

### 6. Session Duration

**Formula:**
```
session_duration = current_real_time - session_start_time
```

**Variables:**

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `current_real_time` | float | Engine time | `Time.get_ticks_msec() / 1000.0` |
| `session_start_time` | float | Session start | Stored on `start_exploration_session()` |

**Output Range:** 0.0 - ∞ (real seconds elapsed in session)

---

### 7. Real-to-Game Time Conversion

**Formula:**
```
game_time_from_real = real_seconds × BASE_TIME_SCALE × speed_multiplier
real_time_from_game = game_seconds / (BASE_TIME_SCALE × speed_multiplier)
```

**Variables:**

| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `real_seconds` | float | 0.0 - ∞ | User input / UI display |
| `game_seconds` | float | 0.0 - ∞ | System time |
| `BASE_TIME_SCALE` | float | 72.0 | Constant |
| `speed_multiplier` | float | 0.5 - 5.0 | Speed state |

**Example Outputs:**
- 60 real seconds → 72 game minutes (normal speed)
- 20 real minutes → 1 game day (normal speed)

## Edge Cases

### 1. Game Startup / Initialization

**Edge Case:** Game loads for first time, `total_game_seconds = 0.0`

**Handling:**
- System initializes with `current_phase = DAWN` (5:00-7:00 range)
- `days_elapsed = 0` (Day 0, not Day 1 — first full day completes when days_elapsed = 1)
- `is_paused = true` until game finishes loading
- On game start, emit `phase_changed(DAWN, null)` (no previous phase)
- All query APIs return valid values immediately after initialization

---

### 2. Extended Session (Time Overflow)

**Edge Case:** Player plays for extremely long time (hours), `total_game_seconds` grows very large

**Handling:**
- No overflow concern: GDScript float handles values up to ~1e308
- At 20 real minutes per game day, 100 real hours = 300 game days
- 300 game days = 25,920,000 game seconds — well within float precision
- No practical limit — continue accumulating normally

---

### 3. Phase Boundary Exact Match

**Edge Case:** `current_hour` hits exactly 7.0 (DAWN → DAY boundary)

**Handling:**
- Phase boundaries use `>= start AND < end` pattern
- At exactly 7.0: `hour >= 7.0 and hour < 18.0` → DAY
- DAWN range: `>= 5.0 and < 7.0` → excludes 7.0
- Transition triggers at first frame where hour crosses boundary
- Emit `phase_changed(DAY, DAWN)` once — no repeated emissions at same boundary

---

### 4. Speed Multiplier Transitions

**Edge Case:** Player changes speed from 1.0 → 5.0 while time is advancing

**Handling:**
- Speed change is instantaneous — next frame uses new multiplier
- Emit `time_speed_changed(5.0)` signal immediately
- No interpolation or ramping — game time scale jumps
- Downstream systems receive signal and may adjust behavior (e.g., faster construction animations)
- `clamp(multiplier, 0.5, 5.0)` prevents invalid values from external input

---

### 5. Pause During Phase Transition

**Edge Case:** Time hits phase boundary, then pause is triggered same frame

**Handling:**
- Phase transition detection happens in `_process()` before pause check
- If `is_paused` changes to true after phase detection, phase signal still emits
- Example: Player pauses menu at exact moment DAWN → DAY transition
- Result: `phase_changed(DAY, DAWN)` emitted, then `time_paused("menu")`
- Time frozen at DAY phase — no rollback

---

### 6. Multiple Pause Sources

**Edge Case:** Dialogue pause and menu pause both active simultaneously

**Handling:**
- `is_paused` is boolean — no tracking of "why" paused
- Multiple sources can set `is_paused = true`
- All sources must release before time resumes
- Signal `time_paused(source)` emitted for each pause trigger
- Signal `time_resumed(source)` emitted for each resume
- Downstream systems track pause stack if needed (not Time system responsibility)

---

### 7. Day Boundary During Exploration Session

**Edge Case:** Exploration session spans multiple game days

**Handling:**
- Session tracks real time duration, not game time
- `session_duration` continues accumulating across day boundaries
- `day_started` signals emitted normally during session
- Retreat判定 system may use `get_days_elapsed()` to check multi-day exploration
- No special handling needed — session is continuous real-time counter

---

### 8. Query API at Midnight

**Edge Case:** `get_current_hour()` called at 0.0 (midnight, NIGHT phase)

**Handling:**
- `fmod(total_game_seconds, 86400)` returns 0.0 at midnight
- Phase determination: 0.0 falls in NIGHT range (20:00 - 05:00)
- NIGHT covers hours 20-24 AND 0-5 — midnight is valid NIGHT
- Query returns `hour = 0.0`, `phase = NIGHT`
- UI displays "00:00" or "深夜" depending on localization

---

### 9. Time Paused While Speed Multiplier Active

**Edge Case:** Fast speed (×5) active, then pause triggered

**Handling:**
- `speed_multiplier` persists during pause
- When `time_resumed`, multiplier still at ×5
- Time advances at ×5 rate immediately after resume
- No reset to normal speed — player's speed choice is preserved

---

### 10. Exploration Session Abandoned

**Edge Case:** Player starts exploration session, then cancels/quits before completing

**Handling:**
- `start_exploration_session()` returns session_id
- If `end_exploration_session()` never called, session state persists
- On next session start, previous session_id is overwritten
- Previous session's duration is lost — not persisted to save data
- Retreat判定系统 handles incomplete session in its own logic (not Time responsibility)

## Dependencies

### Upstream Dependencies (This system depends on)

| System | Status | Interface Used | Purpose |
|--------|--------|----------------|---------|
| **None** | — | — | Foundation layer system, no upstream dependencies |

Time system is a Foundation layer system with zero upstream dependencies. It provides time data to all downstream systems.

---

### Downstream Dependencies (Systems that depend on this)

| System | ID | Status | Interface Used | Purpose |
|--------|-----|--------|----------------|---------|
| **日夜循环系统** | #15 | Not Started | `get_current_phase()`, `phase_changed` signal | Determine lighting/ambiance state |
| **撤退判定系统** | #32 | Not Started | `get_session_duration()`, `get_current_hour()` | Calculate exploration time limit |
| **尸潮周期系统** | #34 | Not Started | `get_days_elapsed()`, `day_started` signal | Trigger periodic defense events |
| **天气系统** | #16 | Not Started | `get_time_of_day()` | Time-based weather transitions |
| **HUD系统** | #49 | Not Started | `get_current_hour()`, `get_days_elapsed()` | Display time/days in UI |
| **探索区域系统** | #27 | Not Started | `get_session_duration()` | Time-limited exploration zones |

---

### Interface Contract

**Time system MUST provide:**

| Interface | Type | Guarantee |
|-----------|------|-----------|
| `get_game_time()` | Dictionary | Returns `{total_seconds, days_elapsed, current_phase, current_hour, is_paused, speed_multiplier}` |
| `get_days_elapsed()` | int | Returns integer ≥ 0 |
| `get_current_phase()` | TimePhase | Returns valid enum (DAWN/DAY/DUSK/NIGHT) |
| `get_current_hour()` | float | Returns 0.0 - 24.0 |
| `get_time_of_day()` | float | Returns 0.0 - 1.0 (day progress) |
| `is_day()` | bool | Returns true if DAY or DAWN |
| `is_night()` | bool | Returns true if NIGHT or DUSK |
| `is_dangerous_time()` | bool | Returns true if DUSK or NIGHT |
| `get_seconds_until_phase(target)` | float | Returns positive seconds or 0.0 |
| `start_exploration_session()` | String | Returns unique session_id |
| `end_exploration_session(id)` | Dictionary | Returns `{duration_seconds, start_phase, end_phase}` |
| `get_session_duration()` | float | Returns real seconds ≥ 0.0 |

**Signals MUST emit:**

| Signal | Parameters | Emit Timing |
|--------|------------|-------------|
| `time_advanced` | `game_seconds: float` | Every frame when not paused |
| `hour_changed` | `hour: int, previous_hour: int` | When hour boundary crossed |
| `day_started` | `day: int, previous_day: int` | When day boundary crossed |
| `phase_changed` | `new_phase: TimePhase, old_phase: TimePhase` | When phase boundary crossed |
| `time_paused` | `source: String` | When pause triggered |
| `time_resumed` | `source: String` | When pause released |
| `time_speed_changed` | `multiplier: float` | When speed changes |

---

### Data Flow Diagram

```
┌─────────────────────┐
│   Time System (#8)  │
│   (GameTime.gd)     │
├─────────────────────┤
│ total_game_seconds  │─────► 日夜循环系统 (#15) ─► Lighting/Ambiance
│ days_elapsed        │─────► 尸潮周期系统 (#34) ─► Defense Events
│ current_phase       │─────► 撤退判定系统 (#32) ─► Retreat Warning
│ current_hour        │─────► 天气系统 (#16) ─► Weather Transitions
│ session_duration    │─────► HUD系统 (#49) ─► Time Display
└─────────────────────┘

Signals emitted:
  phase_changed ──► 日夜循环系统 (lighting switch)
  day_started ───► 尸潮周期系统 (tide trigger check)
  time_advanced ─► 所有下游系统 (polling option)
```

---

### Dependency Risk Assessment

| Risk | Description | Mitigation |
|------|-------------|------------|
| **High downstream count** | 6+ systems depend on time data | Interface is stable — changes cascade widely. Review all dependents before modifying API. |
| **Signal emission timing** | Phase/day transitions must emit exactly once | Careful boundary detection logic prevents duplicate emissions |
| **Session tracking** | Retreat判定 relies on session duration | Session state is ephemeral — not saved between sessions. Retreat system handles incomplete sessions. |

---

### Integration Notes

1. **日夜循环系统**: Calls `get_current_phase()` to determine lighting state. Should also listen to `phase_changed` signal for immediate transitions without polling.

2. **撤退判定系统**: Uses `get_session_duration()` for exploration time limit AND `get_current_hour()` + `is_dangerous_time()` for time-based retreat pressure.

3. **尸潮周期系统**: Counts days via `get_days_elapsed()` and listens to `day_started` signal to trigger tide events every N days.

4. **天气系统**: May transition weather based on `get_time_of_day()` (e.g., more storms at night).

## Tuning Knobs

### Time Scale Knobs

| Knob | Default | Safe Range | Unit | Gameplay Effect | Where Tuned |
|------|---------|------------|------|-----------------|-------------|
| `BASE_TIME_SCALE` | 72.0 | 36.0 - 180.0 | game seconds per real second | Controls overall time flow speed. Lower = slower time (more exploration time), Higher = faster time (more pressure). | `game_time.gd` constant |
| `REAL_SECONDS_PER_GAME_DAY` | 1200 | 600 - 2400 | real seconds | How long one game day feels to player. 20 min default, can adjust for session length preferences. | Derived from BASE_TIME_SCALE |

---

### Phase Duration Knobs

| Knob | Default | Safe Range | Unit | Gameplay Effect | Where Tuned |
|------|---------|------------|------|-----------------|-------------|
| `DAWN_START_HOUR` | 5.0 | 4.0 - 6.0 | game hour | When dawn begins. Shifts risk transition timing. | `game_time.gd` phase boundaries |
| `DAWN_END_HOUR` | 7.0 | 6.0 - 8.0 | game hour | When dawn ends and day begins. | `game_time.gd` phase boundaries |
| `DAY_END_HOUR` | 18.0 | 16.0 - 20.0 | game hour | When day ends and dusk begins. Longer day = more safe exploration time. | `game_time.gd` phase boundaries |
| `DUSK_END_HOUR` | 20.0 | 19.0 - 21.0 | game hour | When dusk ends and night begins. | `game_time.gd` phase boundaries |

**Phase Duration Effects:**
- Extend DAY (7-18 → 7-20): +2 hours safe time = ~100 more real seconds per day for exploration
- Shorten NIGHT (20-5 → 22-5): -2 hours danger = less retreat pressure
- Adjusting phase boundaries directly affects Pillar 2 (搜打撤节奏)

---

### Speed Multiplier Knobs

| Knob | Default | Safe Range | Unit | Gameplay Effect | Where Tuned |
|------|---------|------------|------|-----------------|-------------|
| `NORMAL_SPEED` | 1.0 | 1.0 | multiplier | Fixed — default exploration speed | `game_time.gd` constant |
| `FAST_SPEED` | 2.0 | 1.5 - 3.0 | multiplier | Construction mode speed. Higher = faster building but less immersion. | `game_time.gd` constant |
| `VERY_FAST_SPEED` | 5.0 | 3.0 - 10.0 | multiplier | Deep construction speed. Only in safe zones. Higher = rapid iteration but may feel "gamey". | `game_time.gd` constant |
| `MIN_SPEED` | 0.5 | 0.5 - 1.0 | multiplier | Lower bound clamp. Prevents accidentally too-slow time. | `game_time.gd` clamp |
| `MAX_SPEED` | 5.0 | 3.0 - 10.0 | multiplier | Upper bound clamp. Prevents accidentally too-fast time. | `game_time.gd` clamp |

---

### Session Tracking Knobs

| Knob | Default | Safe Range | Unit | Gameplay Effect | Where Tuned |
|------|---------|------------|------|-----------------|-------------|
| `DEFAULT_SESSION_LIMIT` | 3600 | 1800 - 7200 | real seconds | Default exploration session duration limit (used by Retreat system). 60 min default. | `game_time.gd` constant or external config |
| `SESSION_WARNING_THRESHOLD` | 0.75 | 0.5 - 0.9 | fraction | When to show retreat warning (75% of session limit elapsed). | Retreat判定 system, not Time system |

---

### Retreat Pressure Knobs (Integration with #32)

These knobs are owned by Retreat判定系统 (#32), but depend on Time system data:

| Knob | Default | Safe Range | Unit | Time Data Used | Gameplay Effect |
|------|---------|------------|------|----------------|-----------------|
| `NIGHT_RETREAT_THRESHOLD` | 0.8 | 0.5 - 1.0 | fraction of night | `get_seconds_until_phase(DAWN)` | How far into night before forced retreat warning |
| `DUSK_WARNING_TRIGGER` | immediate | — | boolean | `get_current_phase() == DUSK` | Show warning immediately when dusk starts |

---

### Tuning Guidelines

**When adjusting time scale:**
1. Test exploration sessions with new scale — players should feel "enough time" but also "pressure to return"
2. Verify尸潮周期 alignment — tide events still feel periodic with new day length
3. Check日夜循环 — lighting transitions should feel smooth, not jerky

**When adjusting phase boundaries:**
1. Track total safe time vs. danger time per day
2. Ensure DAY phase is longest (player spends most time in safe exploration)
3. NIGHT should be shortest but most dangerous (creates urgency)
4. DUSK is transition warning — gives player 2 hours to prepare retreat

**When adjusting speed multipliers:**
1. Test construction mode with ×2 and ×5 — does building feel too fast or too slow?
2. Verify save/load doesn't corrupt speed state
3. Ensure ×5 is only available in truly safe zones (not during exploration)

---

### Knob Access Pattern

All tuning knobs are defined as constants in `game_time.gd`:

```gdscript
const BASE_TIME_SCALE: float = 72.0
const GAME_SECONDS_PER_DAY: int = 86400
const GAME_SECONDS_PER_HOUR: int = 3600

# Phase boundaries
const DAWN_START: float = 5.0
const DAWN_END: float = 7.0
const DAY_END: float = 18.0
const DUSK_END: float = 20.0

# Speed limits
const MIN_SPEED: float = 0.5
const MAX_SPEED: float = 5.0
const FAST_SPEED: float = 2.0
const VERY_FAST_SPEED: float = 5.0
```

Designers can request tuning by editing these constants. Code changes require re-export of autoload.

## Visual/Audio Requirements

### Direct Visual Requirements

Time system itself has no direct visual representation. It provides data to downstream systems that render time visually.

**No direct visual elements owned by this system.**

---

### Downstream Visual Systems (Time-Dependent)

| System | Visual Element | Time Data Used | Requirement |
|--------|----------------|----------------|-------------|
| **日夜循环系统 (#15)** | Lighting color/intensity | `get_current_phase()` | Phase change must trigger immediate lighting transition |
| **日夜循环系统 (#15)** | Skybox/atmosphere | `get_time_of_day()` | Continuous sky color gradient based on day progress |
| **HUD系统 (#49)** | Clock display | `get_current_hour()` | Digital or analog clock showing current game time |
| **HUD系统 (#49)** | Day counter | `get_days_elapsed()` | Numerical day display (Day N) |
| **撤退警告UI (#50)** | Countdown timer | `get_session_duration()` + Retreat system limit | Visual countdown showing time until forced retreat |

---

### Direct Audio Requirements

Time system has no direct audio. It provides timing triggers for downstream audio.

**No direct audio elements owned by this system.**

---

### Downstream Audio Systems (Time-Dependent)

| System | Audio Element | Time Data Used | Requirement |
|--------|----------------|----------------|-------------|
| **日夜循环系统 (#15)** | Ambient sounds | `get_current_phase()` | Phase change triggers ambient sound swap (birds → crickets) |
| **音效系统 (#52)** | Day transition chime | `day_started` signal | Optional: chime/sound effect when new day begins |
| **音效系统 (#52)** | Night danger stinger | `phase_changed(NIGHT)` | Optional: warning sound when entering dangerous phase |
| **撤退警告UI (#50)** | Retreat alarm | `phase_changed(DUSK)` + Retreat system | Warning sound when retreat timer activates |

---

### Signal-to-Visual/Audio Mapping

| Time Signal | Visual Response | Audio Response | Owner System |
|-------------|-----------------|----------------|--------------|
| `phase_changed(DAWN)` | Lighting warm-up (blue → gold) | Birds start chirping | 日夜循环 (#15), 音效 (#52) |
| `phase_changed(DAY)` | Full daylight (bright) | Day ambiance active | 日夜循环 (#15), 音效 (#52) |
| `phase_changed(DUSK)` | Lighting dim (orange → purple) | Wind picks up, ambiance shift | 日夜循环 (#15), 音效 (#52) |
| `phase_changed(NIGHT)` | Darkness (deep blue/black) | Crickets, distant zombie groans | 日夜循环 (#15), 音效 (#52) |
| `day_started` | Optional UI flash | Optional day chime | HUD (#49), 音效 (#52) |
| `time_paused` | Pause overlay appears | Music pauses/shifts | UI, Audio systems |

---

### Visual Feedback Timing

**Phase transition must feel instantaneous:**

When `phase_changed` signal emits, downstream visual systems should transition within:
- **Lighting color**: ≤ 0.5 seconds (smooth gradient over phase duration)
- **Ambiance swap**: ≤ 0.3 seconds (immediate sound change)
- **UI update**: ≤ 0.1 seconds (clock should never lag)

**No visual lag acceptable.** Time system provides precise timing data; downstream systems must respect it.

---

### Accessibility Considerations

| Visual Element | Accessibility Backup | Implementation |
|----------------|----------------------|----------------|
| Phase lighting change | Phase icon in HUD (sun/moon symbol) | HUD系统 (#49) provides icon alongside clock |
| Night danger indicator | Colorblind-safe warning icon | 撤退警告UI (#50) uses shape + color for danger |
| Session countdown | Numeric display (not just bar) | HUD shows exact seconds remaining |

---

### Audio Accessibility

| Audio Element | Accessibility Backup | Implementation |
|---------------|----------------------|----------------|
| Phase ambiance change | Visual icon change + optional text | HUD icon updates with phase |
| Retreat alarm | Visual flashing warning + sound | 撤退警告UI provides both |

---

### Integration Notes

**Time system does NOT request visual/audio assets.** It only provides data and signals. All visual/audio implementation belongs to:
- 日夜循环系统 (#15) — lighting, skybox, ambiance
- HUD系统 (#49) — clock, day counter, phase icons
- 音效系统 (#52) — ambient sounds, transition effects
- 撤退警告UI (#50) — countdown display, warnings

Design documents for those systems should reference this section for their time-dependent requirements.

## UI Requirements

### Direct UI Elements (Owned by HUD系统 #49)

Time system provides data for HUD display, but does not own UI implementation.

**Time system does NOT render UI.** All UI elements are implemented by HUD系统 (#49).

---

### HUD Time Display Requirements

| UI Element | Data Source | Display Format | Update Frequency | Owner |
|------------|-------------|----------------|------------------|-------|
| **Clock** | `get_current_hour()` | "HH:MM" (e.g., "14:30") or analog clock | Every frame (smooth) | HUD (#49) |
| **Day Counter** | `get_days_elapsed()` | "Day N" (e.g., "Day 3") | On day boundary change | HUD (#49) |
| **Phase Icon** | `get_current_phase()` | Icon: ☀ (DAY), 🌅 (DAWN), 🌆 (DUSK), 🌙 (NIGHT) | On phase change | HUD (#49) |
| **Speed Indicator** | `speed_multiplier` | "×1" / "×2" / "×5" text or icon | On speed change | HUD (#49) |

---

### Clock Display Options

**Format A — Digital Clock:**
```
┌──────────┐
│  14:30   │  ← get_current_hour() formatted as HH:MM
│  Day 3   │  ← get_days_elapsed() + 1 (show Day 1, not Day 0)
└──────────┘
```

**Format B — Analog Clock:**
```
     12
   ┌─────┐
 9│  •  │3   ← Clock hand position from get_current_hour()
   └─────┘
     6
   Day 3
```

**Format C — Phase-Based:**
```
┌────────────────┐
│  🌆 Dusk       │  ← Phase icon + name
│  18:45         │  ← Current time
│  Day 3         │  ← Day counter
└────────────────┘
```

HUD system selects format based on game aesthetic. Time system provides raw data for all formats.

---

### Phase Icon Design

| Phase | Icon | Color Suggestion | Display Context |
|-------|------|------------------|-----------------|
| DAWN | 🌅 (sunrise) | Warm orange | Safe zone approaching |
| DAY | ☀ (sun) | Bright yellow | Safe zone, active exploration |
| DUSK | 🌆 (sunset) | Purple/orange | Warning zone, retreat advised |
| NIGHT | 🌙 (moon) | Deep blue | Danger zone, retreat pressure |

Icons should be recognizable at glance. HUD system owns icon asset selection.

---

### Speed Indicator Display

| Speed | Display | Context | Color |
|-------|---------|---------|-------|
| ×1 (Normal) | "×1" or no indicator | Default exploration | Neutral/hidden |
| ×2 (Fast) | "×2" visible | Construction mode | Green (positive) |
| ×5 (Very Fast) | "×5" visible | Deep construction | Yellow/Gold (attention) |

Speed indicator only shown when `speed_multiplier > 1.0`. Hidden during normal exploration.

---

### Retreat Warning UI Integration (#50)

Time system provides session duration, but Retreat判定系统 (#50) owns warning display:

| Warning Stage | Time Data Used | UI Response | Owner |
|---------------|----------------|-------------|-------|
| **Early warning** | `get_session_duration() > DEFAULT_SESSION_LIMIT × 0.5` | Subtle indicator | 撤退警告UI (#50) |
| **Late warning** | `get_session_duration() > DEFAULT_SESSION_LIMIT × 0.75` | Flashing countdown | 撤退警告UI (#50) |
| **Dusk warning** | `get_current_phase() == DUSK` | Phase icon flashes | 撤退警告UI (#50) |
| **Critical** | Retreat判定 system logic | Full-screen warning | 撤退警告UI (#50) |

Time system only provides raw data. Warning thresholds and display logic belong to Retreat系统.

---

### Pause Indicator

| State | UI Response | Data Source |
|-------|-------------|-------------|
| `is_paused = true` | Pause overlay, clock frozen | Time system `is_paused` |
| `is_paused = false` | Normal HUD, clock advancing | Time system `is_paused` |

Pause overlay should clearly show frozen time state. Clock stops updating visually.

---

### UI Update Performance

**Clock update must be smooth:**
- Digital clock: Update text every frame for smooth minute progression
- Analog clock: Update hand rotation every frame
- Phase icon: Update only on `phase_changed` signal (not every frame)
- Day counter: Update only on `day_started` signal

**No performance concern:** Time queries are O(1) dictionary lookups. HUD can query every frame without issue.

---

### UI Layout Suggestion

Time display typically positioned in HUD corner:
```
┌────────────────────────────────────┐
│                                    │
│   [Health] [Mana] [Resources]      │
│                                    │
│              ...                   │
│                                    │
│  ┌──────────┐                      │
│  │ 🌆 18:45 │  ← Time + Phase      │
│  │  Day 3   │  ← Day counter       │
│  │  ×2      │  ← Speed (if active) │
│  └──────────┘                      │
└────────────────────────────────────┘
```

HUD system (#49) owns exact positioning. Time system provides data only.

---

### Accessibility Requirements

| UI Element | Accessibility Need | Implementation |
|------------|--------------------|----------------|
| Clock | Screen reader support | Text description "Current time: 14 hours 30 minutes, Day 3" |
| Phase icon | Colorblind backup | Phase name text alongside icon (e.g., "Dusk") |
| Speed indicator | Clear meaning | Text label "Construction speed ×2" |
| Retreat countdown | High visibility | Large numeric display, color change, shape warning |

HUD system implements accessibility. Time system provides accessible text data via query APIs.

## Acceptance Criteria

### AC-01: Time Initialization

**Given:** Game starts for first time
**When:** GameTime autoload initializes
**Then:**
- `total_game_seconds = 0.0`
- `days_elapsed = 0`
- `current_phase = DAWN`
- `is_paused = true`
- All query APIs return valid values immediately

**Test:** Automated — call all APIs after autoload ready, verify defaults

---

### AC-02: Time Advancement

**Given:** Game is running, `is_paused = false`, `speed_multiplier = 1.0`
**When:** `_process(delta)` executes
**Then:**
- `total_game_seconds` increases by `delta × 72.0`
- After 20 real seconds: `total_game_seconds` has increased by ~1440 game seconds (~0.4 game hours)
- After 20 real minutes: `days_elapsed` has increased by 1

**Test:** Automated — simulate 20 real minutes of frames, verify day elapsed count

---

### AC-03: Phase Boundary Detection

**Given:** Time advancing normally
**When:** `current_hour` crosses from 6.99 to 7.00 (DAWN → DAY boundary)
**Then:**
- `phase_changed(DAY, DAWN)` signal emits exactly once
- `get_current_phase()` returns DAY
- Signal emits on first frame where hour ≥ 7.0

**Test:** Automated — advance time to 6:59, then to 7:00, verify signal count = 1

---

### AC-04: Day Boundary Detection

**Given:** Time advancing, `total_game_seconds` approaching 86400
**When:** `total_game_seconds` crosses 86400 (end of Day 0)
**Then:**
- `day_started(1, 0)` signal emits exactly once
- `get_days_elapsed()` returns 1
- `get_current_hour()` resets to 0.0-24.0 range (midnight)

**Test:** Automated — advance time to exactly 86400 game seconds, verify day change

---

### AC-05: Pause Functionality

**Given:** Time is advancing
**When:** `set_paused(true, "menu")` called
**Then:**
- `is_paused = true`
- `time_paused("menu")` signal emits
- Time stops advancing (subsequent `_process` calls do not increase `total_game_seconds`)
- `get_game_time()` returns frozen state

**Test:** Automated — call pause, simulate frames, verify time frozen

---

### AC-06: Resume Functionality

**Given:** Time is paused
**When:** `set_paused(false, "menu")` called
**Then:**
- `is_paused = false`
- `time_resumed("menu")` signal emits
- Time resumes advancing (next `_process` increases `total_game_seconds`)
- Speed multiplier persists (no reset to 1.0)

**Test:** Automated — pause → resume → verify time advancing at same speed

---

### AC-07: Speed Multiplier

**Given:** Time advancing at `speed_multiplier = 1.0`
**When:** `set_speed_multiplier(2.0)` called
**Then:**
- `speed_multiplier = 2.0`
- `time_speed_changed(2.0)` signal emits
- Next frame advances `game_seconds_elapsed = delta × 72.0 × 2.0`

**Test:** Automated — change speed, verify doubled advancement rate

---

### AC-08: Speed Multiplier Bounds

**Given:** External code calls `set_speed_multiplier(10.0)` (beyond MAX_SPEED)
**When:** Function executes
**Then:**
- `speed_multiplier` is clamped to `MAX_SPEED` (5.0)
- No signal emitted (value rejected)
- Time continues at ×5 speed

**Test:** Automated — attempt invalid speeds, verify clamp behavior

---

### AC-09: Query API Accuracy

**Given:** `total_game_seconds = 27000` (7.5 hours into day)
**When:** All query APIs called
**Then:**
- `get_days_elapsed()` returns 0
- `get_current_hour()` returns 7.5
- `get_current_phase()` returns DAY (7.0 ≤ 7.5 < 18.0)
- `get_time_of_day()` returns 0.3125 (27000 / 86400)
- `is_day()` returns true
- `is_night()` returns false
- `is_dangerous_time()` returns false

**Test:** Automated — set specific total_game_seconds, verify all query outputs

---

### AC-10: Session Tracking

**Given:** Player starts exploration
**When:** `start_exploration_session()` called
**Then:**
- Returns unique session_id string
- `session_start_time` records current real time
- `get_session_duration()` returns 0.0 immediately after start

**Test:** Automated — start session, verify duration tracking starts

---

### AC-11: Session Duration

**Given:** Exploration session started 60 real seconds ago
**When:** `get_session_duration()` called
**Then:**
- Returns ~60.0 (real seconds, not game seconds)
- Duration continues increasing if time advancing or paused

**Test:** Automated — start session, wait, verify duration increases

---

### AC-12: Session End

**Given:** Exploration session active
**When:** `end_exploration_session(session_id)` called
**Then:**
- Returns Dictionary `{duration_seconds, start_phase, end_phase}`
- `duration_seconds` matches `get_session_duration()` at call time
- `start_phase` was phase when session started
- `end_phase` is current phase at call time

**Test:** Automated — start → advance time → end, verify return data

---

### AC-13: Seconds Until Phase

**Given:** Current time is 6:00 (DAWN), target is DAY (starts 7:00)
**When:** `get_seconds_until_phase(DAY)` called
**Then:**
- Returns 3600 game seconds (1 hour until DAY)
- Converted to real seconds: 50 real seconds (3600 / 72)

**Test:** Automated — set time to known phase, query seconds to next phase

---

### AC-14: Night Wrap-Around

**Given:** Current time is 23:00 (NIGHT), target is DAWN (starts 5:00 next day)
**When:** `get_seconds_until_phase(DAWN)` called
**Then:**
- Returns positive seconds wrapping to next day
- Calculation: (5:00 next day - 23:00 current) = 6 hours = 21600 game seconds

**Test:** Automated — set time to late night, verify wrap-around calculation

---

### AC-15: Signal Emission Timing

**Given:** Multiple phase boundaries in quick succession (testing edge case)
**When:** Time advances rapidly through DAWN → DAY → DUSK in one frame
**Then:**
- Each boundary crossing emits signal exactly once
- Signals emit in order: `phase_changed(DAY, DAWN)`, `phase_changed(DUSK, DAY)`
- No skipped boundaries even at high speed

**Test:** Automated — advance time from 6:59 to 18:01 in single step, verify signal sequence

---

### Integration Acceptance Criteria (Require Downstream Systems)

### AC-INT-01: 日夜循环 Integration

**Given:** 日夜循环系统 (#15) is implemented and listening to `phase_changed`
**When:** Time crosses DAWN → DAY boundary
**Then:** Lighting system receives signal and transitions lighting within 0.5 seconds

**Test:** Integration — requires日夜循环 system, verify lighting responds to signal

---

### AC-INT-02: 撤退判定 Integration

**Given:** 撤退判定系统 (#32) is implemented
**When:** Player explores for 45 real minutes (75% of 60-minute session)
**Then:** Retreat system receives session duration and triggers warning UI

**Test:** Integration — requires Retreat system, verify warning triggered

---

### AC-INT-03: 尸潮周期 Integration

**Given:** 尸潮周期系统 (#34) is implemented and listening to `day_started`
**When:** `day_started(5, 4)` signal emits (Day 5 begins)
**Then:** Tide system checks if Day 5 is tide day and triggers event if configured

**Test:** Integration — requires Tide system, verify tide check on day boundary

---

### AC-INT-04: HUD Integration

**Given:** HUD系统 (#49) is implemented
**When:** Time advances from 14:00 to 14:01
**Then:** Clock display updates to show "14:01" (or smooth analog transition)

**Test:** Integration — requires HUD, verify clock updates continuously

## Open Questions

### Q-01: Save/Load Time State

**Question:** Should `total_game_seconds` and `days_elapsed` persist across save/load?

**Context:**
- Current design treats time as session-level (ephemeral)
- If player saves on Day 3, quits, loads later — should time reset to Day 0 or resume at Day 3?
- Roguelite games typically reset progress between runs
- 但铁锈魔潮 has persistent base construction — saves may need time persistence

**Options:**
| Option | Tradeoff | Implication |
|--------|----------|-------------|
| **Reset on load** | Roguelite feel | Each load = fresh session. Construction persists but time resets. May disconnect events from player's actual session length. |
| **Persist on load** | Persistent world | Time saved. Days elapsed matches actual play history.尸潮周期 aligns with player's real days played. |
| **Hybrid** | Different for different modes | Exploration mode resets, Base mode persists. Complex but serves both gameplay needs. |

**Resolution needed by:** Alpha milestone (存档系统 #54 implementation)
**Currently blocked by:** No存档系统 GDD yet (#54 — Full Vision tier)

---

### Q-02: Multi-Session Day Count

**Question:** Should `days_elapsed` accumulate across multiple sessions (player plays 3 sessions over 3 days)?

**Context:**
- Roguelite games often count "runs" separately from "total play sessions"
- If player plays 20 minutes Monday, 20 minutes Tuesday — is that Day 2 (total) or Day 1 each session?
- 尸潮周期 system (#34) needs day count for tide scheduling

**Options:**
| Option | Tradeoff | Implication |
|--------|----------|-------------|
| **Per-session reset** | Roguelite pattern | Each exploration = Day 0. Tide events scheduled per exploration. Simpler for players to understand. |
| **Total accumulation** | Persistent progression | Total days played = days_elapsed. Tide events scheduled across entire play history. Rewards long-term players. |
| **Exploration sessions counted** | Hybrid | days_elapsed = number of completed探索sessions. Not real time, but meaningful count. |

**Resolution needed by:** 尸潮周期系统 (#34) design
**Currently blocked by:** 尸潮周期 (#34 — Alpha tier, not yet designed)

---

### Q-03: Time During Base Construction

**Question:** Should time advance during base construction mode (安全区) or pause?

**Context:**
- Current design allows speed multiplier ×2 and ×5 during construction
- If time advances during construction, player's day count increases without exploration
- If time pauses, construction feels "outside time" — may disconnect from world continuity

**Options:**
| Option | Tradeoff | Implication |
|--------|----------|-------------|
| **Time advances (with speed)** | World continuity | Construction contributes to day count. Player may hit tide event while building. Pressure to build quickly. |
| **Time pauses in base** | Safe building | Construction is timeless. No tide pressure during base work. Player can build without time stress. |
| **Time advances but tide disabled in base** | Safe but continuous | Time passes for day count, but tide events don't trigger during base mode. |m

**Resolution needed by:** 建造验证系统 (#45) or 地堡设施系统 (#46) design
**Currently blocked by:** No base-mode design docs yet

---

### Q-04: Phase Transition Animation Duration

**Question:** Should phase transitions be instant or animated (gradual lighting change)?

**Context:**
- Time system emits `phase_changed` signal immediately at boundary
- 日夜循环系统 (#15) receives signal and should transition lighting
- Instant transition may feel jarring (sudden darkness)
- Gradual transition (2-5 seconds) may feel smoother but technically "wrong" (time says DAY but lighting still DAWN)

**Options:**
| Option | Tradeoff | Implication |
|--------|----------|-------------|
| **Instant transition** | Technically accurate | Lighting matches time exactly. Player feels "it's now DAY, light changes now". May feel abrupt. |
| **Gradual transition (2 sec)** | Smoother feel | Lighting transitions over 2 seconds after boundary. Player sees smooth dawn → day. Time system says DAY, lighting says "becoming DAY". |
| **Anticipate transition** | Most smooth | Lighting starts changing 30 seconds before boundary. Player anticipates phase change. Requires日夜循环 to query `get_seconds_until_phase()`. |

**Resolution needed by:** 日夜循环系统 (#15) design
**Currently blocked by:** 日夜循环 (#15 — MVP tier, not yet designed)

---

### Q-05: Session Limit Configuration

**Question:** Should `DEFAULT_SESSION_LIMIT` be hardcoded or configurable by player settings?

**Context:**
- Default 60 minutes may not suit all players (casual vs. hardcore)
- Hardcoded value is simpler but not player-friendly
- Configurable value adds complexity (settings UI, validation)

**Options:**
| Option | Tradeoff | Implication |
|--------|----------|-------------|
| **Hardcoded constant** | Simple, balanced | All players get same 60-minute default. Designers tune via BASE_TIME_SCALE. |
| **Player settings (dropdown)** | Player agency | Player chooses 30/60/90 minute sessions. Requires settings UI and validation. |
| **Dynamic (based on difficulty)** | Difficulty scaling | Easy mode = longer sessions, Hard mode = shorter. No player choice, but difficulty-aligned. |

**Resolution needed by:** 撤退判定系统 (#32) design or Settings UI (if player-configurable)
**Currently blocked by:** 撤退判定 (#32 — MVP tier, not yet designed)

---

### Q-06: Speed Multiplier Availability in Exploration

**Question:** Should speed multiplier ×5 be available during exploration mode?

**Context:**
- Current design restricts ×5 to "安全区深层建造"
- Exploration mode is inherently risky — should time be manipulable?
- If ×5 available in exploration, player can rush through危险phases quickly
- If ×5 restricted, player has no time agency during exploration

**Options:**
| Option | Tradeoff | Implication |
|--------|----------|-------------|
| **×5 restricted to base only** | Consistent pressure | Exploration always at ×1. Player can't manipulate time during搜打撤. Time pressure is real. |
| **×5 available in exploration** | Player agency | Player can rush time (e.g., skip long night). May feel "gamey" and reduce tension. |
| **×2 available in exploration, ×5 only in base** | Limited agency | Player can double time during exploration but not quintuple. Some time agency without full control. |

**Resolution needed by:** 建造验证系统 (#45) design or 探索区域系统 (#27) design
**Currently blocked by:** No exploration-mode boundary design yet

---

### Q-07: Real-Time vs. Game-Time for Session Duration

**Question:** Should `get_session_duration()` return real seconds or game seconds?

**Context:**
- Current design uses real seconds (session tracks real time elapsed)
- Game seconds would be `total_game_seconds` accumulated during session
- Real seconds is simpler but disconnected from game time scale
- Game seconds matches player's perceived "how long have I been exploring in-game?"

**Options:**
| Option | Tradeoff | Implication |
|--------|----------|-------------|
| **Real seconds (current)** | Simple, consistent | Session duration = real time played. Independent of speed multiplier. Easy to understand. |
| **Game seconds** | In-game feel | Session duration = game time elapsed. Player feels "I've been exploring for 3 game hours". Changes with speed multiplier. |
| **Both available** | Maximum info | API returns both real and game seconds. Downstream systems choose which to use. |m

**Resolution needed by:** 撤退判定系统 (#32) design
**Currently blocked by:** 撤退判定 (#32 — MVP tier, not yet designed)

---

### Resolution Tracker

| Question | Blocking System | Priority | Status |
|----------|-----------------|----------|--------|
| Q-01 | 存档系统 (#54) | Full Vision | Open |
| Q-02 | 尸潮周期 (#34) | Alpha | Open |
| Q-03 | 建造验证 (#45) | MVP | Open |
| Q-04 | 日夜循环 (#15) | MVP | Open |
| Q-05 | 撤退判定 (#32) | MVP | Open |
| Q-06 | 建造验证 (#45) | MVP | Open |
| Q-07 | 撤退判定 (#32) | MVP | Open |

**High-priority open questions (MVP blockers):** Q-03, Q-04, Q-05, Q-06, Q-07
**These should be resolved when designing downstream MVP systems (#15, #32, #45).**