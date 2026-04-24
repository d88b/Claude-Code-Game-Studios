# Epic: Scavenge Container Database

> **Layer**: Foundation
> **GDD**: design/gdd/scavenge-container-database.md
> **Architecture Module**: ScavengeContainerDB
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

ScavengeContainerDB 是搜刮容器定义的静态数据库，存储战利品表（loot_table with probability weights）、roll_loot算法。搜刮系统查询容器掉落通过此模块，支持概率权重随机抽取资源。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Scavenge Container Loading | Integration | Ready | ADR-002 |

ScavengeContainerDB 是搜刮容器定义的静态数据库，存储战利品表（loot_table with probability weights）、roll_loot算法。搜刮系统查询容器掉落通过此模块，支持概率权重随机抽取资源。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-002: Database Loading Strategy | RefCounted Autoload from entities.yaml | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-scavenge-001 | Container loot tables with probability weights | ADR-002 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/scavenge-container-database.md` are verified
- get_loot_table(), roll_loot() unit tests pass
- Probability weights verified through statistical testing

## Next Step

Run `/create-stories scavenge-container-database` to break this epic into implementable stories.