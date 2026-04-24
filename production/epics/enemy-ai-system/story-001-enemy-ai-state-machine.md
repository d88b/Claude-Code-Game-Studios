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

- [ ] State machine: IDLE → PATROL → CHASE → ATTACK → FLEE → DEAD
- [ ] NavigationAgent2D for pathfinding (set_target, get_next_path_position)
- [ ] Target acquisition: VehicleController.position for CHASE
- [ ] behavior_hint from EnemyTypeDB (8 types)
- [ ] GlobalSignals.enemy_killed emitted on death

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
**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: EnemyTypeDB, VehicleController, GlobalSignals, NavigationAgent2D (⚠️ HIGH)
- Unlocks: TurretSystem (target for turrets)