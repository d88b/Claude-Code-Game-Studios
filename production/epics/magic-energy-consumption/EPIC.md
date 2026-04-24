# Epic: Magic Energy Consumption

> **Layer**: Core
> **GDD**: design/gdd/magic-energy-consumption.md
> **Architecture Module**: MagicConsumptionCalculator
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

魔能消耗计算系统是战车所有魔能消耗行为的统一计算层。它为战车驾驶系统、战车武器系统及其他魔能消耗系统提供标准化的消耗公式和修正系数计算。系统从战车属性系统获取当前魔能状态和载重信息，根据消耗类型和上下文参数计算魔能消耗量。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Magic Pool Management | Logic | Ready | ADR-005 |

魔能消耗计算系统是战车所有魔能消耗行为的统一计算层。它为战车驾驶系统、战车武器系统及其他魔能消耗系统提供标准化的消耗公式和修正系数计算。系统从战车属性系统获取当前魔能状态和载重信息，根据消耗类型和上下文参数计算魔能消耗量。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-005: Event Bus Architecture | GlobalSignals.magic_consumed, magic_depleted | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-magic-001 | Magic pool management: consume/replenish with GlobalSignals events | ADR-005 ✅ |
| TR-magic-002 | Magic depletion behavior: slowdown vehicle velocity to 50% when pool < 10% (TK-014) | ADR-005 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/magic-energy-consumption.md` are verified
- Driving magic cost formula unit tests pass
- Weapon shot magic cost formula verified
- Accumulation and batching strategy verified
- Remaining range prediction verified

## Next Step

Run `/create-stories magic` to break this epic into implementable stories.