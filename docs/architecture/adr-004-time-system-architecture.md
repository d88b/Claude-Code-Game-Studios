# ADR-004: Time System Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

时间系统使用全局 Autoload（TimeSystem），管理游戏时钟、时间尺度、日夜计数。1 real second = 60 game seconds，10 分钟 real time = 1 day cycle。时间变化通过 GlobalSignals emit 事件（time_hour_changed, day_phase_changed）。这解决所有时间驱动系统的同步问题。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (Time, Clock) |
| **Knowledge Risk** | LOW — Time singleton stable since Godot 4.0 |
| **References Consulted** | `docs/engine-reference/godot/VERSION.md` (Time API unchanged) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | None — Time API is stable |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-005 (Event Bus Architecture) — GlobalSignals.time_hour_changed, day_phase_changed |
| **Enables** | ADR-010 (Enemy AI — spawning timing), ADR-016 (Retreat Judgment — night detection), Day/Night cycle |
| **Blocks** | DayNightCycle, SpawnManager, RetreatJudge until Accepted |
| **Ordering Note** | Foundation layer — created after Event Bus |

## Context

### Problem Statement

铁锈魔潮的核心循环依赖时间：
- 日夜循环驱动敌人行为变化（白天探索，夜晚防守）
- 撤退判定依赖时间（夜晚降临触发警告）
- 敌人生成依赖时间（spawn interval）
- 游戏节奏由时间控制（搜打撤有时间压力）

如何构建统一的时间系统，驱动所有依赖时间的模块？

### Current State

GDD `design/gdd/time-system.md` 定义了时间尺度（1 real second = 60 game seconds），但未明确全局时钟实现。

### Constraints

- 时间必须是全局可访问（多个系统依赖）
- 时间流逝必须可控（暂停、加速）
- 时间事件必须广播（GlobalSignals）
- 时间精度必须足够（小时级别，不是帧级别）
- 时间持久化必须支持（save/load）

### Requirements

- 全局时钟：Autoload 单例
- 时间尺度：可配置（默认 60x）
- 日夜计数：day_count 追踪
- 事件广播：hour change, day/night transition
- 暂停支持：暂停时时间停止
- 持久化：current_time, day_count 可保存

## Decision

**TimeSystem Autoload with Event-Driven Broadcast**：
- TimeSystem 是全局 Autoload，管理 current_time（游戏秒）和 day_count
- 每帧更新时间（delta * time_scale）
- 小时变化时 emit GlobalSignals.time_hour_changed
- 日夜相位变化时 emit GlobalSignals.day_phase_changed

### Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         TIME SYSTEM ARCHITECTURE                              │
└─────────────────────────────────────────────────────────────────────────────┘

TimeSystem (Autoload)
│
├─── current_time: float       # 游戏秒 (0 = 00:00, 86400 = 24:00)
├─── day_count: int            # 天数计数 (day 1, 2, 3...)
├─── time_scale: float         # 时间尺度 (default 60x)
├─── is_paused: bool           # 暂停状态
│
├─── _process(delta):          # 每帧更新时间
│    │
│    ├─── if not is_paused:
│    │    current_time += delta * time_scale
│    │
│    │    # Check hour boundary
│    │    current_hour = floor(current_time / 3600) % 24
│    │    if current_hour != previous_hour:
│    │        GlobalSignals.time_hour_changed.emit(current_hour)
│    │        previous_hour = current_hour
│    │
│    │    # Check day boundary
│    │    if current_time >= 86400:
│    │        current_time -= 86400
│    │        day_count += 1
│    │        GlobalSignals.day_started.emit(day_count)
│    │
│    │    # Check phase boundary (dawn/day/dusk/night)
│    │    current_phase = _get_phase(current_hour)
│    │    if current_phase != previous_phase:
│    │        GlobalSignals.day_phase_changed.emit(current_phase)
│    │        previous_phase = current_phase
│
├─── Public Methods:
│    ├─── get_current_time() → float
│    ├─── get_current_hour() → int (0-23)
│    ├─── get_day_count() → int
│    ├─── get_phase() → DayPhase
│    ├─── set_time_scale(scale: float)
│    ├─── pause()
│    ├─── resume()
│    ├─── set_time(seconds: float)  # For save/load
│
└─── Constants:
     ├─── TIME_SCALE_DEFAULT: float = 60.0  # 1 real sec = 60 game sec
     ├─── SECONDS_PER_DAY: int = 86400
     ├─── SECONDS_PER_HOUR: int = 3600
     ├─── DAWN_START: int = 5   # 05:00
     ├─── DAY_START: int = 7    # 07:00
     ├─── DUSK_START: int = 17  # 17:00
     ├─── NIGHT_START: int = 19 # 19:00


Day Phase Definitions:
─────────────────────────────────────────────────────────────────────────────
Phase: DAWN   (05:00 - 07:00)  # 日出，光线渐亮
Phase: DAY    (07:00 - 17:00)  # 白天，探索时间
Phase: DUSK   (17:00 - 19:00)  # 日落，光线渐暗
Phase: NIGHT  (19:00 - 05:00)  # 夜晚，防守压力

Phase Duration (game time):
DAWN:   2 hours  = 7200 game seconds
DAY:    10 hours = 36000 game seconds
DUSK:   2 hours  = 7200 game seconds
NIGHT:  10 hours = 36000 game seconds

Real Time per Phase (time_scale = 60):
DAWN:   2 minutes
DAY:    10 minutes
DUSK:   2 minutes
NIGHT:  10 minutes
─────────────────────────────────────────────────────────────────────────────
```

### Key Interfaces

```gdscript
# TimeSystem — Public API
# File: src/foundation/time_system.gd

class_name TimeSystem extends Node

# === Constants ===
const TIME_SCALE_DEFAULT: float = 60.0
const SECONDS_PER_DAY: int = 86400
const SECONDS_PER_HOUR: int = 3600

# Phase boundaries (hour)
const DAWN_START: int = 5
const DAY_START: int = 7
const DUSK_START: int = 17
const NIGHT_START: int = 19

# === State ===
var current_time: float = 0.0  # Game seconds (0-86400 per day)
var day_count: int = 1         # Day 1 starts at game start
var time_scale: float = TIME_SCALE_DEFAULT
var is_paused: bool = false

# Internal tracking for event emission
var _previous_hour: int = -1
var _previous_phase: DayPhase = DayPhase.NIGHT

# === Public Methods ===

func get_current_time() -> float:
    return current_time

func get_current_hour() -> int:
    # Returns 0-23 (hour of day)
    return int(current_time / SECONDS_PER_HOUR) % 24

func get_day_count() -> int:
    return day_count

func get_phase() -> DayPhase:
    return _get_phase(get_current_hour())

func set_time_scale(scale: float) -> void:
    # scale = 60 → 1 real sec = 60 game sec (10 min real = 1 day)
    # scale = 120 → 2x speed
    # scale = 0 → time stopped (pause)
    time_scale = scale

func pause() -> void:
    is_paused = true
    # Note: Does NOT emit signal — pause is local state

func resume() -> void:
    is_paused = false

func set_time(seconds: float) -> void:
    # For save/load restoration
    # Recalculates hour/phase and emits appropriate signals
    current_time = seconds
    _emit_time_events()

func reset() -> void:
    # For new game
    current_time = 0.0
    day_count = 1
    _previous_hour = -1
    _previous_phase = DayPhase.NIGHT

# === Internal Methods ===

func _process(delta: float) -> void:
    if is_paused:
        return

    current_time += delta * time_scale

    # Check day boundary
    if current_time >= SECONDS_PER_DAY:
        current_time -= SECONDS_PER_DAY
        day_count += 1
        GlobalSignals.day_started.emit(day_count)

    # Check hour boundary
    var current_hour = get_current_hour()
    if current_hour != _previous_hour:
        GlobalSignals.time_hour_changed.emit(current_hour)
        _previous_hour = current_hour

    # Check phase boundary
    var current_phase = _get_phase(current_hour)
    if current_phase != _previous_phase:
        GlobalSignals.day_phase_changed.emit(current_phase)
        if current_phase == DayPhase.NIGHT:
            GlobalSignals.night_started.emit()
        elif current_phase == DayPhase.DAY:
            GlobalSignals.day_started.emit(day_count)
        _previous_phase = current_phase

func _get_phase(hour: int) -> DayPhase:
    if hour >= DAWN_START and hour < DAY_START:
        return DayPhase.DAWN
    elif hour >= DAY_START and hour < DUSK_START:
        return DayPhase.DAY
    elif hour >= DUSK_START and hour < NIGHT_START:
        return DayPhase.DUSK
    else:
        return DayPhase.NIGHT

func _emit_time_events() -> void:
    # Emit events after time set (for save/load)
    var current_hour = get_current_hour()
    GlobalSignals.time_hour_changed.emit(current_hour)
    _previous_hour = current_hour

    var current_phase = _get_phase(current_hour)
    GlobalSignals.day_phase_changed.emit(current_phase)
    _previous_phase = current_phase


# DayPhase Enum
# File: src/foundation/day_phase.gd

enum DayPhase {
    DAWN,   # 日出
    DAY,    # 白天
    DUSK,   # 日落
    NIGHT   # 夜晚
}
```

### Implementation Guidelines

1. **Autoload Registration**: `TimeSystem` in `project.godot` as `time_system`
2. **Process Mode**: Use `_process()` (not `_physics_process()`) — time runs even when physics paused
3. **Pause Handling**: `is_paused` bool — game pause menu sets this
4. **Event Order**: hour_changed → phase_changed → day_started/night_started
5. **Save/Load**: `set_time(seconds)` recalculates state and emits events
6. **UI Display**: HUD subscribes to `time_hour_changed` to update clock display

## Alternatives Considered

### Alternative 1: Per-Module Time Tracking

- **Description**: 每个系统自己追踪时间（独立 delta accumulator）
- **Pros**: 无全局依赖
- **Cons**: 时间不一致（各系统有 drift），难以同步，难以暂停
- **Estimated Effort**: 更低
- **Rejection Reason**: 多个系统依赖同一时间源，必须统一

### Alternative 2: Real-Time Clock (OS Time)

- **Description**: 使用 OS.get_system_time_secs() 作为时间源
- **Pros**: 绝对时间，无需计算
- **Cons**: 无法控制时间尺度（加速/暂停），无法持久化（save/load）
- **Estimated Effort**: 更低
- **Rejection Reason**: 游戏时间必须可控，不能依赖 OS 时间

### Alternative 3: Frame-Count Based Time

- **Description**: 每帧增加固定值（frame_count += 1, time = frame_count / 60）
- **Pros**: 最简单
- **Cons**: 帧率变化影响时间流逝，不稳定
- **Estimated Effort**: 更低
- **Rejection Reason**: 帧率不稳定时时间不准确，delta-based 更可靠

## Consequences

### Positive

- 全局统一时间：所有系统依赖同一时间源
- 事件驱动：时间变化自动广播，无需主动查询
- 可控制：暂停、加速功能简单实现
- 可持久化：current_time, day_count 可 save/load
- 节奏控制：10 分钟 real time = 1 day cycle，符合搜打撤设计

### Negative

- Autoload 依赖：所有时间敏感系统依赖 GlobalSignals
- 事件频率：hour_changed 每 10 秒 real emit（需注意订阅方性能）
- 暂停逻辑：暂停时需显式调用 pause()

### Neutral

- 这是游戏时间系统的标准模式，无特殊创新

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|-----------|
| 时间 drift（帧率变化） | Low | Low | delta-based accumulation, not frame-count |
| 暂停逻辑遗漏 | Medium | Low | 代码审查检查 pause() 调用点 |
| 事件订阅过多影响性能 | Low | Low | hour_changed 频率低（每 10 秒 real） |
| Save/load 时间未恢复 | Low | Medium | SaveManager 必须调用 set_time() |

## Performance Implications

| Metric | Before | Expected After | Budget |
|--------|--------|---------------|--------|
| CPU (time update) | 0 | <0.01ms/frame | 16.6ms/frame |
| Memory (TimeSystem) | 0 | <100 bytes | 512MB ceiling |
| Events (per minute real) | 0 | 6 hour_changed, 1-2 phase_changed | Low |

估算：每 10 秒 real emit 1 hour_changed，每 2-10 分钟 emit 1 phase_changed → 每 10 分钟 real emit ~10 events。

## Migration Plan

新架构，无迁移。

**Rollback plan**: If event-driven time proves problematic, can refactor to polling (systems query time_system.get_current_time() in _process).

## Validation Criteria

- [ ] TimeSystem Autoload registered
- [ ] get_current_hour() returns 0-23 correctly
- [ ] get_phase() returns correct DayPhase enum
- [ ] GlobalSignals.time_hour_changed emitted on hour boundary
- [ ] GlobalSignals.day_phase_changed emitted on phase boundary
- [ ] pause() stops time accumulation
- [ ] set_time() restores time and emits events
- [ ] 10 minutes real time = 1 day cycle (verify in playtest)

## GDD Requirements Addressed

| GDD Document | System | Requirement | How This ADR Satisfies It |
|-------------|--------|-------------|--------------------------|
| `design/gdd/time-system.md` | TimeSystem | 1 real second = 60 game seconds | time_scale = 60.0 constant |
| `design/gdd/time-system.md` | TimeSystem | Day/night cycle duration: 10 minutes real | TIME_SCALE_DEFAULT = 60, 86400 game sec / day |
| `design/gdd/day-night-cycle-system.md` | DayNight | Ambient lighting changes per time phase | GlobalSignals.day_phase_changed drives DayNightCycle |
| `design/gdd/enemy-spawn-system.md` | EnemySpawn | Spawn timing based on time | GlobalSignals.time_hour_changed triggers spawn waves |
| `design/gdd/retreat-judgment-system.md` | RetreatJudge | Night fall triggers retreat warning | GlobalSignals.day_phase_changed (NIGHT) triggers RetreatJudge |

## Related

- ADR-005: Event Bus Architecture — GlobalSignals.time_hour_changed, day_phase_changed, day_started, night_started
- ADR-010: Enemy AI Architecture — subscribes to time events for spawn timing
- ADR-016: Exploration Area Architecture — RetreatJudge subscribes to phase changes
- ADR-019: Day/Night Visual Rendering — DayNightCycle subscribes to phase changes