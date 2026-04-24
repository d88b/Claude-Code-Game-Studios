# ADR-010: Enemy AI Architecture

## Status

Accepted

## Date

2026-04-24

## Last Verified

2026-04-24

## Decision Makers

create-architecture skill (Technical Director)

## Summary

敌人 AI 使用 NavigationAgent2D 进行 pathfinding，状态机 IDLE/PATROL/CHASE/ATTACK/FLEE/DEAD。behavior_hint 定义 8 种行为（aggressive/defensive/swarm/wall_breaker/tracker/ambusher/retreat_early/boss）。Boids separation 使用 SEPARATION_FORCE=0.3 (TK-064)。目标追踪 VehicleController.position。

## Engine Compatibility

| Field | Value |
|-------|-------|
| **Engine** | Godot 4.6 |
| **Domain** | Navigation (NavigationAgent2D, AI) |
| **Knowledge Risk** | HIGH — Dedicated 2D navigation server introduced in Godot 4.5+, post-cutoff |
| **References Consulted** | `docs/engine-reference/godot/modules/navigation.md` (4.5 2D nav server, API unchanged), `docs/engine-reference/godot/breaking-changes.md` (4.5 navigation) |
| **Post-Cutoff APIs Used** | NavigationServer2D (dedicated 2D server, Godot 4.5+) |
| **Verification Required** | Test NavigationAgent2D.get_next_path_position() with TileMapLayer collision; verify pathfinding accuracy; test boids separation with 10+ enemies |

> **⚠️ HIGH RISK**: Godot 4.5 introduced dedicated 2D navigation server. NavigationAgent2D API unchanged, but backend differs from training data examples. Must test on target engine version.

## ADR Dependencies

| Field | Value |
|-------|-------|
| **Depends On** | ADR-002 (EnemyTypeDB), ADR-001 (TileMapWorld), ADR-005 (Event Bus) |
| **Enables** | ADR-012 (Spawn System), TurretController (targeting) |
| **Blocks** | All enemy gameplay until Accepted |
| **Ordering Note** | Core layer — after Database and TileMap, before Spawn |

## Context

### Problem Statement

敌人需要多种 AI 行为：
- 8 种 behavior_hint（aggressive 直接冲锋，swarm 集群包围，wall_breaker 拆墙攻城等）
- Pathfinding to vehicle
- Boids separation（避免敌人重叠）
- State machine（IDLE → CHASE → ATTACK → FLEE → DEAD）
- Damage and death handling

### Requirements

- NavigationAgent2D pathfinding
- 8 behavior types from EnemyTypeDB
- State machine transitions
- Boids separation (SEPARATION_FORCE=0.3)
- Target: VehicleController.position

## Decision

**NavigationAgent2D + State Machine + Boids Separation**：

```
EnemyAIController._physics_process(delta):
│
├─── 1. State Machine Update:
│    match state:
│        IDLE:     patrol or wait
│        PATROL:   random movement in area
│        CHASE:    set_target(vehicle_position)
│        ATTACK:   attack if in range
│        FLEE:     retreat if health < threshold
│        DEAD:     cleanup
│
├─── 2. Navigation:
│    if state == CHASE:
│        nav_agent.target_position = VehicleController.position
│        if not nav_agent.is_navigation_finished():
│            next_pos = nav_agent.get_next_path_position()  # ⚠️ HIGH RISK
│            direction = global_position.direction_to(next_pos)
│            velocity = direction * speed
│
├─── 3. Boids Separation:
│    neighbors = SpawnManager.get_enemies_in_range(position, 5.0)
│    separation = apply_separation(neighbors)  # SEPARATION_FORCE = 0.3
│    velocity += separation
│
├─── 4. Move:
│    move_and_slide()
│
└─── 5. State Transitions:
│    if health < flee_threshold and behavior_hint != aggressive:
│        state = FLEE
│    if distance_to_vehicle < attack_range:
│        state = ATTACK
│    if health <= 0:
│        state = DEAD
│        GlobalSignals.enemy_killed.emit(enemy_id)
```

### Key Interfaces

```gdscript
enum EnemyState { IDLE, PATROL, CHASE, ATTACK, FLEE, DEAD }
enum BehaviorHint { aggressive, defensive, swarm, wall_breaker, tracker, ambusher, retreat_early, boss }

class_name EnemyAIController extends CharacterBody2D

@onready var nav_agent: NavigationAgent2D = $NavigationAgent2D

var state: EnemyState = EnemyState.IDLE
var behavior_hint: BehaviorHint
var target_position: Vector2

func set_target(world_pos: Vector2) -> void:
    nav_agent.target_position = world_pos  # ⚠️ 4.5+ 2D nav server

func get_next_path_position() -> Vector2:
    if nav_agent.is_navigation_finished():
        return global_position
    return nav_agent.get_next_path_position()  # ⚠️ HIGH RISK API

func apply_separation(neighbors: Array) -> Vector2:
    var separation = Vector2.ZERO
    for enemy in neighbors:
        if enemy != self:
            var diff = global_position - enemy.global_position
            separation += diff.normalized() * 0.3  # SEPARATION_FORCE TK-064
    return separation
```

## GDD Requirements Addressed

| GDD | Requirement | How Satisfied |
|-----|-------------|---------------|
| `enemy-ai-system.md` | NavigationAgent2D pathfinding | set_target(), get_next_path_position() |
| `enemy-ai-system.md` | 8 behavior_hint types | BehaviorHint enum |
| `enemy-ai-system.md` | Boids separation | SEPARATION_FORCE = 0.3 (TK-064) |
| `enemy-ai-system.md` | State machine | EnemyState enum with transitions |

## Related

- ADR-002: EnemyTypeDB — get_behavior_hint()
- ADR-012: Spawn System — SpawnManager creates enemies
- ADR-001: TileMapWorld — navigation mesh collision source