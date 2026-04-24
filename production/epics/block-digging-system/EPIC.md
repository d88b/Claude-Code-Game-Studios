# Epic: Block Digging System

> **Layer**: Core
> **GDD**: design/gdd/block-digging-system.md
> **Architecture Module**: DigController
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

方块挖掘系统是玩家与世界交互的核心动作层。玩家按下"挖掘"键，系统从TileMapLayer读取方块硬度，计算每帧的伤害积累，在进度条达到阈值时删除方块并移除碰撞。它将方块类型数据库的硬度数据转化为玩家感知的"挖掘手感"，将输入控制系统的dig动作转化为有反馈的交互循环。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Damage Accumulation | Logic | Ready | ADR-008 |

方块挖掘系统是玩家与世界交互的核心动作层。玩家按下"挖掘"键，系统从TileMapLayer读取方块硬度，计算每帧的伤害积累，在进度条达到阈值时删除方块并移除碰撞。它将方块类型数据库的硬度数据转化为玩家感知的"挖掘手感"，将输入控制系统的dig动作转化为有反馈的交互循环。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-008: Digging Architecture | Damage accumulation model, physics-safe deletion via queue_tile_modification | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-digging-001 | Dig progress: accumulated_damage >= block.difficulty → block destroyed | ADR-008 ✅ |
| TR-digging-002 | Dig tool modifiers: tool_power / block.difficulty affects dig speed | ADR-008 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/block-digging-system.md` are verified
- Damage accumulation logic unit tests pass
- Block deletion via queue_tile_modification verified (physics-safe)
- Tool modifier system verified (Tier 0-3)

## Next Step

Run `/create-stories digging` to break this epic into implementable stories.