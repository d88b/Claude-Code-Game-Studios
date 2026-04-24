# Epic: Bunker Facility System

> **Layer**: Feature
> **GDD**: design/gdd/bunker-facility-system.md
> **Architecture Module**: FacilityController
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

地堡设施系统是设施实体的生命周期管理器和功能实现层——它接收方块放置系统的设施放置信号，创建对应的设施实体，管理设施的运行状态（激活/损坏），实现设施的具体功能（储物箱的存储、工作台的合成），并处理设施的损坏和拆除。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Facility Entity Lifecycle | Logic | Ready | ADR-005, ADR-007 |

地堡设施系统是设施实体的生命周期管理器和功能实现层——它接收方块放置系统的设施放置信号，创建对应的设施实体，管理设施的运行状态（激活/损坏），实现设施的具体功能（储物箱的存储、工作台的合成），并处理设施的损坏和拆除。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-005: Event Bus Architecture | GlobalSignals.facility_created, facility_destroyed | LOW |
| ADR-007: Vehicle State Machine Architecture | Facility state machine (IDLE/ACTIVE/DAMAGED/DESTROYED) | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-facility-001 | Facility entity lifecycle: create → interact → damage → demolish with state management | ADR-007 ✅ |
| TR-facility-002 | Storage box capacity: 100 slots per box (TK-032 STORAGE_CAPACITY) | ADR-005 ✅ |
| TR-facility-003 | Workbench crafting: 4 MVP recipes with cost and craft_time | ADR-005 ✅ |
| TR-facility-004 | Magic connection: facility within 10 cells of vehicle for power (TK-047) | ADR-005 ✅ |
| TR-facility-005 | Demolition refund: 50% of build cost returned (TK-048 DEMOLITION_REFUND_RATE) | ADR-005 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/bunker-facility-system.md` are verified
- Storage box deposit/withdraw unit tests pass
- Workbench crafting verified
- Facility damage and content drop verified
- Magic connection validation verified

## Next Step

Run `/create-stories facility` to break this epic into implementable stories.