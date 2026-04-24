# Epic: Vehicle Type Database

> **Layer**: Foundation
> **GDD**: design/gdd/vehicle-type-database.md
> **Architecture Module**: VehicleTypeDB
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

VehicleTypeDB 是战车类型定义的静态数据库，存储基础属性（max_health/armor/magic_pool/max_speed/acceleration_rate）、状态机定义（GARAGE_IDLE → DEPLOYABLE → DEPLOYED → DISABLED → DESTROYED）。VehicleAttribute和VehicleController查询战车属性通过此模块。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Vehicle Definition Loading | Integration | Ready | ADR-002, ADR-007 |

VehicleTypeDB 是战车类型定义的静态数据库，存储基础属性（max_health/armor/magic_pool/max_speed/acceleration_rate）、状态机定义（GARAGE_IDLE → DEPLOYABLE → DEPLOYED → DISABLED → DESTROYED）。VehicleAttribute和VehicleController查询战车属性通过此模块。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-002: Database Loading Strategy | RefCounted Autoload from entities.yaml | LOW |
| ADR-007: Vehicle State Machine Architecture | 5-state machine with transitions | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-vehicletype-001 | Vehicle state machine: GARAGE_IDLE → DEPLOYABLE → DEPLOYED → DISABLED → DESTROYED | ADR-007 ✅ |
| TR-vehicletype-002 | Vehicle base stats: max_health, armor, magic_pool, max_speed, acceleration_rate | ADR-002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/vehicle-type-database.md` are verified
- get_vehicle_stats(), get_state_definition() unit tests pass
- State machine transitions verified

## Next Step

Run `/create-stories vehicle-type-database` to break this epic into implementable stories.