# Epic: Retreat Judgment System

> **Layer**: Core
> **GDD**: design/gdd/retreat-judgment-system.md
> **Architecture Module**: RetreatJudge
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

撤退判定系统是监听战车状态并触发撤退决策信号的判定层系统。它订阅战车属性系统的耐久/魔能变化信号，查询时间系统的当前时段和日夜循环系统的危险倍率，持续比较当前状态值与预定义撤退阈值，当任一阈值触发时发射retreat_warning_triggered信号供下游UI系统消费。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Retreat Threshold Detection | Logic | Ready | ADR-004, ADR-005, ADR-007 |

撤退判定系统是监听战车状态并触发撤退决策信号的判定层系统。它订阅战车属性系统的耐久/魔能变化信号，查询时间系统的当前时段和日夜循环系统的危险倍率，持续比较当前状态值与预定义撤退阈值，当任一阈值触发时发射retreat_warning_triggered信号供下游UI系统消费。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-004: Time System Architecture | TimeSystem.get_phase() for phase-based warnings | LOW |
| ADR-005: Event Bus Architecture | GlobalSignals.retreat_warning_triggered, retreat_warning_cleared | LOW |
| ADR-007: Vehicle State Machine Architecture | Retreat threshold integration with state transitions | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-retreat-001 | Retreat threshold: health < 20% OR magic_pool < 10% OR night_fall (TimeSystem.get_phase() == NIGHT) | ADR-007 ✅ |
| TR-retreat-002 | Retreat warning UI trigger: GlobalSignals.retreat_threshold_reached.emit(reason) | ADR-005 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/retreat-judgment-system.md` are verified
- Threshold crossing detection unit tests pass
- Urgency calculation formula verified
- Signal emission verified
- Multi-factor aggregation verified

## Next Step

Run `/create-stories retreat` to break this epic into implementable stories.