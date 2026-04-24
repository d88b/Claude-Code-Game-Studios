# QA Test Plan: Sprint 3

**Date**: 2026-04-24
**Sprint**: Sprint 3 (Vehicle Combat & Enemy Systems + Facility)
**Engine**: Godot 4.6.1
**Story Count**: 12 (11 in scope, 1 backlog)

---

## Scope

Sprint 3 包含 11 个 Logic stories 和 1 个 Integration story (dualfocus-001 已移至 backlog)。本次 QA cycle 覆盖所有已完成的 Logic stories，验证自动化测试通过。

---

## Story Classification Table

| Story ID | Title | Type | Automated Required | Manual Required | Status |
|----------|-------|------|--------------------|-----------------|--------|
| vehicle-001 | Vehicle Attribute State | Logic | ✅ Unit test | — | DONE |
| damage-001 | Damage Receiver System | Logic | ✅ Unit test | — | DONE |
| weapon-001 | Weapon Firing System | Logic | ✅ Unit test | — | DONE |
| buildvalid-001 | Placement Validation | Logic | ✅ Unit test | — | DONE |
| enemy-001 | Enemy AI State Machine | Logic | ✅ Unit test | — | DONE |
| spawn-001 | Spawn Wave Timing | Logic | ✅ Unit test | — | DONE |
| turret-001 | Turret Targeting | Logic | ✅ Unit test | — | DONE |
| area-001 | Area Bounds Manager | Logic | ✅ Unit test | — | DONE |
| retreat-001 | Retreat Threshold Test | Logic | ✅ Unit test | — | DONE |
| drop-001 | Resource Drop Test | Logic | ✅ Unit test | — | DONE |
| facility-001 | Facility Entity Lifecycle | Logic | ✅ Unit test | — | DONE |
| dualfocus-001 | Dual Focus System | Integration | Playtest deferred | 📋 Backlog | NOT IN SCOPE |

---

## Automated Test Requirements

所有 11 个 Logic stories 已有对应的单元测试文件：

| Story | Test File | Expected Path |
|-------|-----------|---------------|
| vehicle-001 | vehicle_attribute_test.gd | `tests/unit/vehicleattr/` |
| damage-001 | damage_receiver_test.gd | `tests/unit/damage/` |
| weapon-001 | weapon_controller_test.gd | `tests/unit/weapon/` |
| buildvalid-001 | placement_validation_test.gd | `tests/unit/placing/` |
| enemy-001 | enemy_state_machine_test.gd | `tests/unit/enemyai/` |
| spawn-001 | spawn_wave_test.gd | `tests/unit/spawn/` |
| turret-001 | turret_targeting_test.gd | `tests/unit/turret/` |
| area-001 | area_bounds_test.gd | `tests/unit/area/` |
| retreat-001 | retreat_threshold_test.gd | `tests/unit/retreat/` |
| drop-001 | resource_drop_test.gd | `tests/unit/drop/` |
| facility-001 | facility_lifecycle_test.gd | `tests/unit/facility/` |

**Verification Method**: 在 Godot Editor GUT panel 运行全部测试，确认所有 PASS。

---

## Manual QA Scope

**Manual QA Sessions Required**: 0

本次 QA cycle 无手动测试需求：
- 所有 Logic stories 已有自动化测试覆盖
- dualfocus-001 (Integration) 已移至 backlog，playtest deferred
- Visual/Feel/UI stories 无新增
- Smoke Check 已在 2026-04-24 执行并通过 (PASS WITH WARNINGS)

---

## Out of Scope

以下内容不在本次 QA cycle 范围内：

1. **dualfocus-001 (Dual Focus System)** — Integration story，playtest deferred to backlog
2. **Save/Load 系统** — 尚未实现 (Smoke Check marked N/A)
3. **End-to-end gameplay sessions** — 需完整游戏循环，超出 Sprint 3 范围
4. **Platform-specific testing** — PC target only，无 console/mobile verification needed

---

## Entry Criteria

QA cycle 启动前必须满足：

- ✅ Smoke Check 已执行: `production/qa/smoke-sprint-3-2026-04-24.md` — PASS WITH WARNINGS
- ✅ Build 稳定: 启动无崩溃，facility-001 blocking issues 已修复
- ✅ 所有 Logic stories 有测试文件: 11/11 COVERED
- ✅ Sprint 3 stories 状态: 11/12 done (dualfocus-001 backlog)

---

## Exit Criteria

QA cycle 完成条件：

1. **All automated tests PASS** — 在 Godot Editor GUT panel 确认
2. **No S1/S2 bugs open** — 如有阻塞性 bug，必须先修复
3. **Smoke Check verdict ≥ PASS WITH WARNINGS** — 已满足
4. **QA Sign-Off Report written** — `production/qa/qa-signoff-sprint-3-2026-04-24.md`

---

## Test Execution Plan

### Step 1: Automated Test Verification
- 在 Godot Editor 打开 GUT panel
- 运行 `tests/unit/` 下所有测试
- 记录结果：总测试数、PASS/FAIL count、失败测试名称

### Step 2: Manual Confirmation (Optional)
- 如 automated tests 全部 PASS，无需 manual QA session
- 如有任何 FAIL，进入 Bug Triage 流程

### Step 3: Sign-Off Report Generation
- 收集所有测试结果
- 生成 QA Sign-Off Report
- Verdict: APPROVED / APPROVED WITH CONDITIONS / NOT APPROVED

---

## Warnings from Smoke Check

以下 warnings 在 Smoke Check 中记录，不影响 QA hand-off 但需在 Sign-Off Report 中提及：

1. Automated tests NOT RUN in headless mode — 需在 Godot Editor 手动确认
2. dualfocus-001 playtest deferred (integration story backlog)