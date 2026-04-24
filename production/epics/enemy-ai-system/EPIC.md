# Epic: Enemy AI System

> **Layer**: Core
> **GDD**: design/gdd/enemy-ai-system.md
> **Architecture Module**: EnemyAIController
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

敌人AI系统是管理所有敌人实例行为决策的核心系统。每个敌人实例拥有独立的AI状态机，根据其behavior_hint类型执行不同的行为模式：集群冲锋、拆墙攻城、追踪猎杀、远程狙击等。系统从敌人类型数据库读取behavior_hint和属性参数，实时计算目标选择、路径规划、攻击触发，驱动敌人CharacterBody2D移动和攻击。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Enemy AI State Machine | Logic | Ready | ADR-010 (⚠️ HIGH), ADR-005 |

敌人AI系统是管理所有敌人实例行为决策的核心系统。每个敌人实例拥有独立的AI状态机，根据其behavior_hint类型执行不同的行为模式：集群冲锋、拆墙攻城、追踪猎杀、远程狙击等。系统从敌人类型数据库读取behavior_hint和属性参数，实时计算目标选择、路径规划、攻击触发，驱动敌人CharacterBody2D移动和攻击。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-010: Navigation Agent Architecture | NavigationAgent2D for pathfinding, dedicated 2D navigation server | ⚠️ HIGH (Godot 4.5+) |
| ADR-005: Event Bus Architecture | GlobalSignals.enemy_attack, enemy_killed | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-enemyai-001 | NavigationAgent2D for pathfinding (Godot 4.5+ dedicated 2D navigation server) | ADR-010 ✅ |
| TR-enemyai-002 | State machine: IDLE → PATROL → CHASE → ATTACK → FLEE → DEAD | ADR-010 ✅ |
| TR-enemyai-003 | Boids separation force: SEPARATION_FORCE = 0.3 (TK-064) to prevent enemy overlap | ADR-010 ✅ |
| TR-enemyai-004 | Target acquisition: vehicle.position for hostile enemies (CHASE state) | ADR-010 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/enemy-ai-system.md` are verified
- State machine transitions unit tests pass
- NavigationAgent2D pathfinding verified on target engine (⚠️ HIGH RISK)
- Boids separation verified
- ⚠️ HIGH RISK: NavigationAgent2D tested on Godot 4.6 (post-cutoff API)

## Next Step

Run `/create-stories enemyai` to break this epic into implementable stories.