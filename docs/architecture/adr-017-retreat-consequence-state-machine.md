# ADR-017: Retreat Consequence State Machine Architecture

## Status

Proposed

## Date

2026-04-25

## Decision Makers

architecture-decision skill

## Summary

撤退后果系统采用 4 状态机（IDLE → CRITICAL_TRACKING → CONSEQUENCE_APPLYING → RECOVERY）追踪 CRITICAL 警告超时。状态转换由 `retreat_warning_triggered` 和 `vehicle_state_changed` 信号驱动。系统计算后果严重度并发射 `retreat_failed`、`consequence_applied` 信号。数据持久化支持 Roguelite 继承系统消费。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Core (State Machine) |
| **Knowledge Risk** | LOW — State machine pattern standard per ADR-007 precedent, no engine API dependency |
| **References Consulted** | ADR-007 (Vehicle State Machine pattern), ADR-005 (GlobalSignals) |
| **Post-Cutoff APIs Used** | None |
| **Verification Required** | Test state transitions: IDLE→CRITICAL_TRACKING→CONSEQUENCE_APPLYING |

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-005 (GlobalSignals — Accepted), ADR-007 (State Machine pattern — Accepted) |
| **Enables** | 战车瘫痪处理系统 (#24 — provisional), Roguelite继承系统 (#53 — data consumer) |
| **Blocks** | Retreat consequence implementation, walk-back triggered flow |
| **Ordering Note** | Core layer — after Event Bus and Vehicle State Machine |

## Context

### Problem Statement

撤退后果系统需要追踪 CRITICAL 警告持续时间并执行后果处理。核心问题：
1. 如何追踪 `critical_warning_start_time` 并检测超时？
2. 如何定义后果处理的各个阶段（警告追踪、后果执行、恢复）？
3. 如何计算后果严重度并发射信号供下游消费？
4. 如何持久化失败累计数据供 Roguelite 继承系统消费？

### Requirements

From `retreat-consequence-system.md`:

- 4-state machine: IDLE, CRITICAL_TRACKING, CONSEQUENCE_APPLYING, RECOVERY
- Timeout detection: `timeout_elapsed >= CRITICAL_TIMEOUT_SECONDS`
- Severity calculation: Formula 2 (base_severity × duration_factor × load_factor × danger_factor)
- Signal interfaces: `retreat_failed`, `retreat_success`, `retreat_timeout_averted`, `consequence_applied`
- Data persistence: `failure_count`, `total_severity_accumulated` for Roguelite inheritance

## Decision

**Finite State Machine with Event-Driven Transitions + Severity Calculation Pipeline**：

### State Machine Architecture

```
State Machine:
IDLE ──[retreat_warning_triggered(CRITICAL)]──> CRITICAL_TRACKING
CRITICAL_TRACKING ──[timeout_elapsed >= 30s]──> CONSEQUENCE_APPLYING
CRITICAL_TRACKING ──[retreat_warning_cleared]──> IDLE
CRITICAL_TRACKING ──[玩家返回车库]──> IDLE (retreat_timeout_averted)
CONSEQUENCE_APPLYING ──[后果处理完成]──> RECOVERY
RECOVERY ──[玩家步行返回车库]──> IDLE

State Definitions:
IDLE:                 无 CRITICAL 警告，静默状态
CRITICAL_TRACKING:    CRITICAL 警告触发，计时器活跃
CONSEQUENCE_APPLYING: 超时触发或战车状态转换，执行后果
RECOVERY:             后果执行完成，等待玩家返回

Provisional Interface (战车瘫痪处理 #24):
CONSEQUENCE_APPLYING ──[walk_back_triggered]──> On-Foot State System (#30)
```

### Key Interfaces

```gdscript
# === GlobalSignals 新增事件 ===
# File: src/foundation/global_signals.gd (extends ADR-005)

# === Retreat Consequence Events ===
signal retreat_warning_triggered(level: WarningLevel, reasons: Array[WarningReason], urgency: float)  # From RetreatJudgment (#32)
signal retreat_warning_cleared()  # From RetreatJudgment (#32)
signal retreat_failed(reasons: Array[WarningReason])  # From RetreatConsequence
signal retreat_success()  # From RetreatConsequence (玩家主动返回车库)
signal retreat_timeout_averted()  # From RetreatConsequence (CRITICAL期间成功返回)
signal consequence_applied(consequence_type: ConsequenceType, severity: float)  # From RetreatConsequence
signal walk_back_triggered(vehicle_position: Vector2i, vehicle_state: VehicleState)  # Provisional — to 战车瘫痪处理 #24

# === Enums ===
enum ConsequenceState {
    IDLE,
    CRITICAL_TRACKING,
    CONSEQUENCE_APPLYING,
    RECOVERY
}

enum ConsequenceType {
    RESOURCE_LOSS,      # Type 1: 资源损失
    VEHICLE_DISABLED,   # Type 2: 战车瘫痪
    VEHICLE_DESTROYED,  # Type 3: 战车毁坏
    WALK_BACK,          # Type 4: 步行逃回
    INHERITANCE_PENALTY # Type 5: 继承惩罚
}

enum WarningLevel { NONE, WARNING, CRITICAL }  # From RetreatJudgment (#32)
enum WarningReason { ... }  # From RetreatJudgment (#32)

# === RetreatConsequence Controller ===
class_name RetreatConsequence extends Node

var current_state: ConsequenceState = ConsequenceState.IDLE
var critical_warning_start_time: float = 0.0  # 游戏时间戳
var consequence_severity: float = 0.0
var failure_count: int = 0  # 跨run持久化
var total_severity_accumulated: float = 0.0  # 跨run持久化
var last_failure_reasons: Array[WarningReason] = []

# Tuning Knobs (from GDD #33)
const CRITICAL_TIMEOUT_SECONDS: float = 30.0  # TK-033-01
const BASE_LOSS_RATIO: float = 0.20  # TK-033-02
const MAX_LOSS_RATIO: float = 0.80  # TK-033-03

func _ready() -> void:
    GlobalSignals.retreat_warning_triggered.connect(_on_retreat_warning_triggered)
    GlobalSignals.retreat_warning_cleared.connect(_on_retreat_warning_cleared)
    GlobalSignals.vehicle_state_changed.connect(_on_vehicle_state_changed)

func transition_to(new_state: ConsequenceState) -> void:
    if not _is_valid_transition(current_state, new_state):
        return
    current_state = new_state
    match new_state:
        ConsequenceState.CRITICAL_TRACKING:
            critical_warning_start_time = TimeSystem.get_game_time()
        ConsequenceState.CONSEQUENCE_APPLYING:
            apply_consequence()
        ConsequenceState.IDLE:
            if critical_warning_start_time > 0:
                GlobalSignals.retreat_timeout_averted.emit()
            critical_warning_start_time = 0.0

func _is_valid_transition(from: ConsequenceState, to: ConsequenceState) -> bool:
    var valid_transitions = {
        ConsequenceState.IDLE: [ConsequenceState.CRITICAL_TRACKING],
        ConsequenceState.CRITICAL_TRACKING: [ConsequenceState.CONSEQUENCE_APPLYING, ConsequenceState.IDLE],
        ConsequenceState.CONSEQUENCE_APPLYING: [ConsequenceState.RECOVERY],
        ConsequenceState.RECOVERY: [ConsequenceState.IDLE]
    }
    return to in valid_transitions.get(from, [])

func check_timeout() -> void:
    if current_state != ConsequenceState.CRITICAL_TRACKING:
        return
    var timeout_elapsed = TimeSystem.get_game_time() - critical_warning_start_time
    if timeout_elapsed >= CRITICAL_TIMEOUT_SECONDS:
        transition_to(ConsequenceState.CONSEQUENCE_APPLYING)

func apply_consequence() -> void:
    consequence_severity = calculate_severity()
    failure_count += 1
    total_severity_accumulated += consequence_severity
    
    # Determine consequence type
    var consequence_type = determine_consequence_type()
    
    GlobalSignals.retreat_failed.emit(last_failure_reasons)
    GlobalSignals.consequence_applied.emit(consequence_type, consequence_severity)
    
    if consequence_type == ConsequenceType.VEHICLE_DISABLED or consequence_type == ConsequenceType.VEHICLE_DESTROYED:
        GlobalSignals.walk_back_triggered.emit(_get_vehicle_position(), _get_vehicle_state())
    
    transition_to(ConsequenceState.RECOVERY)

func calculate_severity() -> float:
    # Formula 2 from GDD #33
    var base_severity = get_base_severity()
    var duration_factor = clamp(timeout_elapsed / CRITICAL_TIMEOUT_SECONDS, 1.0, 3.0)
    var load_factor = clamp(VehicleAttribute.get_load_ratio(), 0.5, 2.0)
    var danger_factor = DayNightCycle.get_danger_multiplier() / 1.0  # BASE_DANGER
    
    var severity = base_severity * duration_factor * load_factor * danger_factor
    return clamp(severity, 0.0, 2.0)
```

## Alternatives Considered

### Alternative 1: Timer Node Instead of State Machine

- **Description**: 使用 Godot Timer node 追踪 CRITICAL 超时，无需状态机
- **Pros**: 更简单，利用 Godot 原生 Timer API
- **Cons**: 无法追踪后果处理的完整流程（APPLYING → RECOVERY），Timer 无法表达状态
- **Rejection Reason**: 后果处理是多阶段流程，Timer 无法表达 CONSEQUENCE_APPLYING 和 RECOVERY 状态

### Alternative 2: Separate Timer System

- **Description**: 拆分计时器和后果处理为两个独立系统
- **Pros**: 模块更小，职责分离
- **Cons**: 系统间通信复杂，计时器触发后果处理需要额外信号
- **Rejection Reason**: 计时器和后果处理紧密耦合，拆分增加不必要的通信开销

## Consequences

### Positive
- 状态机清晰表达后果处理流程的各个阶段
- Severity 公式提供可配置的后果严厉度
- Provisional 接口预留战车瘫痪处理协调点
- 数据持久化支持 Roguelite 继承系统消费

### Negative
- Provisional 接口依赖战车瘫痪处理 #24 设计完成后才能确认
- Severity 公式需要 playtest 验证平衡性

### Risks
- 战车瘫痪处理 #24 Not Started → 接口可能需要修改
- Severity 公式平衡性不确定 → 需要 playtest 调整 tuning knobs

## GDD Requirements Addressed

| GDD | Requirement | How This ADR Satisfies It |
|-----|-------------|--------------------------|
| `retreat-consequence-system.md` Rule 1 | CRITICAL 超时检测 | `check_timeout()` + `critical_warning_start_time` tracking |
| `retreat-consequence-system.md` Rule 2 | 后果类型定义 | `ConsequenceType` enum (5 types) |
| `retreat-consequence-system.md` Rule 3 | 严重度计算 | `calculate_severity()` implements Formula 2 |
| `retreat-consequence-system.md` Rule 4 | 撤退成功处理 | `retreat_success` signal, IDLE transition |
| `retreat-consequence-system.md` Rule 5 | 战车状态监听 | `_on_vehicle_state_changed()` triggers DISABLED/DESTROYED consequences |
| `retreat-consequence-system.md` Rule 6 | 步行逃回风险 | `walk_back_triggered` provisional signal |
| `retreat-consequence-system.md` Rule 7 | 多次失败累计 | `failure_count`, `total_severity_accumulated` persistence |
| `retreat-consequence-system.md` States | 4-state machine | `ConsequenceState` enum with IDLE→CRITICAL_TRACKING→CONSEQUENCE_APPLYING→RECOVERY |
| `retreat-consequence-system.md` Formulas 1-6 | Timeout, Severity, Resource Loss, Walk-Back Time, Risk, Accumulation | All formulas implemented or delegated to calculation methods |

## Performance Implications

| Metric | Impact |
|--------|--------|
| CPU (timeout check) | <0.01ms/frame (single comparison) |
| CPU (severity calculation) | <0.05ms (4 multiplications + clamp) |
| Memory (state data) | <100 bytes |

State machine transition is O(1), severity calculation is O(1).

## Migration Plan

New system — no migration.

## Validation Criteria

- [ ] RetreatConsequence controller implemented with 4-state machine
- [ ] GlobalSignals extended with retreat consequence events
- [ ] `check_timeout()` called in `_process()` or `_physics_process()`
- [ ] Severity calculation matches Formula 2 from GDD #33
- [ ] `failure_count` persisted to SaveManager
- [ ] Provisional `walk_back_triggered` signal documented for #24 coordination

## Related

- ADR-005: GlobalSignals event bus
- ADR-007: Vehicle State Machine pattern precedent
- retreat-consequence-system.md: Full GDD specification
- retreat-judgment-system.md: Upstream warning signal source