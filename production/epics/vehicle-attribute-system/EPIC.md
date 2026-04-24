# Epic: Vehicle Attribute System

> **Layer**: Core
> **GDD**: design/gdd/vehicle-attribute-system.md
> **Architecture Module**: VehicleAttribute
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

战车属性系统是管理战车实例运行时状态的核心系统。每个战车实例拥有独立的属性状态：当前耐久值、当前魔能值、载重量、武器装备配置、改装安装状态。系统从战车类型数据库读取类型定义，初始化实例属性，并为所有下游系统提供统一的属性查询接口。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Vehicle Attribute State | Logic | Ready | ADR-007, ADR-002 |

战车属性系统是管理战车实例运行时状态的核心系统。每个战车实例拥有独立的属性状态：当前耐久值、当前魔能值、载重量、武器装备配置、改装安装状态。系统从战车类型数据库读取类型定义，初始化实例属性，并为所有下游系统提供统一的属性查询接口。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-007: Vehicle State Machine Architecture | 5-state machine with transitions | LOW |
| ADR-002: Database Loading Strategy | RefCounted Autoload from entities.yaml | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-vehicleattr-001 | Current health tracking with damage events (emit GlobalSignals.vehicle_damaged) | ADR-007 ✅ |
| TR-vehicleattr-002 | Current magic pool tracking with consumption events (emit GlobalSignals.magic_changed) | ADR-007 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/vehicle-attribute-system.md` are verified
- get_durability_ratio(), get_magic_energy_ratio() unit tests pass
- State transitions (GARAGE_IDLE → DEPLOYABLE → DEPLOYED) verified
- Signal emission (durability_changed, magic_energy_changed) verified

## Next Step

Run `/create-stories vehicleattr` to break this epic into implementable stories.