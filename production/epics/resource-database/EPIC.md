# Epic: Resource Database

> **Layer**: Foundation
> **GDD**: design/gdd/resource-database.md
> **Architecture Module**: ResourceDB
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

ResourceDB 是资源类型定义的静态数据库，存储堆叠上限（100 for most）、分类（raw_material/processed/component/ammo）、显示名。新增MVP资源：铁锭(151)、铜锭(152)、基础零件(160)。所有系统查询资源属性通过此模块。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Resource Definition Loading | Integration | Ready | ADR-002 |

ResourceDB 是资源类型定义的静态数据库，存储堆叠上限（100 for most）、分类（raw_material/processed/component/ammo）、显示名。新增MVP资源：铁锭(151)、铜锭(152)、基础零件(160)。所有系统查询资源属性通过此模块。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-002: Database Loading Strategy | RefCounted Autoload from entities.yaml | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-resource-001 | Resource stack size limits: 100 for most raw materials | ADR-002 ✅ |
| TR-resource-002 | Resource categories: raw_material, processed, component, ammo | ADR-002 ✅ |
| TR-resource-003 | New MVP resources: 铁锭(151), 铜锭(152), 基础零件(160) | ADR-002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/resource-database.md` are verified
- get_resource(), get_max_stack_size() unit tests pass
- New MVP resources (151, 152, 160) defined and queryable

## Next Step

Run `/create-stories resource-database` to break this epic into implementable stories.