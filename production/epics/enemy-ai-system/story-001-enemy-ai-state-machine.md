# Story 001: Enemy AI State Machine

> **Epic**: EnemyAISystem
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/enemy-ai-system.md`
**Requirement**: `TR-enemyai-001`, `TR-enemyai-002`, `TR-enemyai-003`, `TR-enemyai-004`

**ADR Governing Implementation**: ADR-010: Enemy AI Architecture, ADR-005: Event Bus
**ADR Decision Summary**: EnemyAIController 状态机 (IDLE/PATROL/CHASE/ATTACK/FLEE/DEAD)，⚠️ HIGH RISK: NavigationAgent2D (Godot 4.5+)。

**Engine**: Godot 4.6 | **Risk**: HIGH
**Engine Notes**: ⚠️ HIGH RISK: NavigationAgent2D 是 Godot 4.5+ 新特性，需验证 API。

---

## Acceptance Criteria

- [x] State machine: IDLE → MOVE_TO_TARGET → ATTACK → STUN → DEAD with transition logic
- [x] NavigationAgent2D for pathfinding (set_target_position, get_next_path_position)
- [x] Target acquisition: VehicleController.position for CHASE detection
- [x] behavior_hint from EnemyTypeDB (8 types: aggressive, defensive, swarm, wall_breaker, tracker, ambusher, retreat_early, boss)
- [x] GlobalSignals.enemy_killed emitted on death
- [x] State lock for debounce (STATE_LOCK_FRAMES = 3)
- [x] Attack timer countdown and reset on attack
- [x] Tracker speed multiplier (TRACKER_HUNT_SPEED_MULT = 1.5)

---

## Implementation Notes

```gdscript
class_name EnemyAIController extends CharacterBody2D

enum State { IDLE, PATROL, CHASE, ATTACK, FLEE, DEAD }

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D
var behavior_hint: String

func _ready() -> void:
    behavior_hint = EnemyTypeDB.get_behavior_hint(enemy_id)
    nav_agent.set_target(VehicleController.position)

func _physics_process(delta: float) -> void:
    var next_pos = nav_agent.get_next_path_position()
    velocity = (next_pos - position).normalized() * speed
    move_and_slide()
```

---

## Test Evidence

**Type**: Logic
**Required**: `tests/unit/enemyai/enemy_state_machine_test.gd`
**Status**: [x] Created — 70+ test cases covering state machine, behavior_hint, damage, signals, timers, transitions
**Note**: Tests must be run in Godot Editor GUT panel (headless mode class_name loading issue)
**Implementation**: EnemyAIController with NavigationAgent2D, state machine with debounce, behavior_hint speed multiplier
**Scene**: `src/ai/enemy_ai_controller.tscn` — CharacterBody2D + NavigationAgent2D child node

---

## Dependencies

- Depends on: EnemyTypeDB, VehicleController, GlobalSignals, NavigationAgent2D (⚠️ HIGH)
- Unlocks: TurretSystem (target for turrets)