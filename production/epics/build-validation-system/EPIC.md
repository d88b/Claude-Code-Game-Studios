# Epic: Build Validation System

> **Layer**: Feature
> **GDD**: design/gdd/build-validation-system.md
> **Architecture Module**: BuildValidator
> **Status**: Ready
> **Stories**: 1 story created — see Stories table below

## Overview

建造验证系统是建造流程的规则检查层——在玩家选择建造物品并点击目标位置后，系统执行一系列验证检查，确认建造请求是否合法可执行。验证通过后，建造请求传递给方块放置系统执行；验证失败则返回错误代码和反馈信息，阻止建造执行。

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | Validation Chain V1-V6 | Logic | Ready | ADR-005 |

建造验证系统是建造流程的规则检查层——在玩家选择建造物品并点击目标位置后，系统执行一系列验证检查，确认建造请求是否合法可执行。验证通过后，建造请求传递给方块放置系统执行；验证失败则返回错误代码和反馈信息，阻止建造执行。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-005: Event Bus Architecture | Validation signals for placement feedback | LOW |

Note: ADR coverage pending — this epic will create validation-specific ADR during implementation.

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-buildvalid-001 | Terrain support check: block_type requires specific terrain layer type for placement | ADR-005 ✅ |
| TR-buildvalid-002 | Entity collision check: no overlap with existing entities at placement position | ADR-005 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/build-validation-system.md` are verified
- V1-V6 validation chain unit tests pass
- Error message generation verified
- Placement preview integration verified

## Next Step

Run `/create-stories buildvalid` to break this epic into implementable stories.