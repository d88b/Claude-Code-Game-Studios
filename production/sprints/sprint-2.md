# Sprint 2 — Core Layer Systems

**Start**: 2026-05-08
**End**: 2026-05-21 (2 weeks)
**Mode**: lean — PR-SPRINT gate skipped

---

## Sprint Goal

实现 Core 层核心系统：战车移动、碰撞检测、魔能消耗、伤害系统、日夜循环 —— 建立核心游戏循环的基础架构。

---

## Capacity

- **Total days**: 14 (2 weeks)
- **Buffer (20%)**: 3 days
- **Available**: 11 days
- **Velocity (Sprint 1)**: 13 stories in 14 days (0.93 stories/day)

---

## Tasks

### Must Have (Critical Path — 战车核心循环)

| ID | Story | Epic | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 2-1 | Collision Query API | block-collision-system | 2 | Sprint 1 | swept_collision_check(), calculate_severity() pass tests |
| 2-2 | Damage Accumulation | block-digging-system | 2 | 2-1 | dig_progress tracking, tile destruction events |
| 2-3 | Placement Validation | block-placing-system | 2 | 2-1, 2-2 | BuildValidator.validate_placement() works |
| 2-4 | Day-Night Phase Manager | day-night-cycle-system | 1 | Sprint 1 | CanvasModulate.color updates per phase |
| 2-5 | Vehicle Movement Loop | vehicle-driving-system | 3 | 2-1 ⚠️ HIGH | velocity, collision correction, input-driven movement |
| 2-6 | Magic Pool Management | magic-energy-consumption | 1 | 2-5 | consume(), replenish(), depletion handling |

### Should Have (战车属性与战斗)

| ID | Story | Epic | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 3-1 | Vehicle Attribute State | vehicle-attribute-system | 1 | 2-5 | health/magic tracking, GlobalSignals events |
| 3-2 | Damage Receiver System | vehicle-damage-system | 1 | 2-1, 3-1 | take_damage(), armor calculation, state transitions |
| 3-3 | Weapon Firing System | vehicle-weapon-system | 2 | 2-5 | fire_weapon(), cooldown, projectile spawn |
| 3-4 | Resource Drop Entity | resource-drop-system | 1 | Sprint 1 | spawn_drop(), pickup_drop(), lifetime |

### Nice to Have (敌人与区域)

| ID | Story | Epic | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 4-1 | Enemy AI State Machine | enemy-ai-system | 2 ⚠️ HIGH | 2-5 | NavigationAgent2D verified, 6 states |
| 4-2 | Spawn Wave Timing | enemy-spawn-system | 1 | 4-1 | spawn_wave(), GlobalSignals.time triggers |
| 4-3 | Turret Targeting | turret-system | 1 | 4-1, 3-3 | acquire_target(), fire_at_target() |
| 4-4 | Area Bounds Manager | exploration-area-system | 1 | 2-5 | area bounds, entry detection |
| 4-5 | Retreat Threshold Detection | retreat-judgment-system | 1 | 2-4, 3-1, 2-6 | check_threshold(), warning triggers |

---

## HIGH RISK Stories

| Story | Risk | Action |
|-------|------|--------|
| vehicle-driving-system/story-001 | ADR-003 Dual-focus + ADR-008 Movement loop | Test on Godot 4.6 with KB/mouse/gamepad |
| enemy-ai-system/story-001 | ADR-010 NavigationAgent2D (Godot 4.5+) | Verify NavigationServer2D API before coding |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| NavigationAgent2D API differs from docs | High | High | Read engine-reference/godot/modules/navigation.md before coding |
| Swept collision exceeds 1ms budget | Medium | Medium | Profile on target hardware, reduce MAX_SWEPT_STEPS if needed |
| Dual-focus input conflicts with movement | Medium | High | Manual playtest KB/mouse/gamepad simultaneously |
| Magic pool depletion logic unclear | Low | Medium | Review ADR-009 formulas before implementation |

---

## Dependencies on External Factors

- Sprint 1 Foundation layer must be stable (verified ✅)
- InputManager dual-focus tested on Godot 4.6 (verified ✅)
- NavigationAgent2D docs available in engine-reference (⚠️ needs verification)

---

## Definition of Done for this Sprint

- [ ] All Must Have stories completed (6 stories)
- [ ] All Should Have stories completed (4 stories, stretch goal)
- [ ] All stories pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-2-[date].md`)
- [ ] All Logic/Integration stories have passing tests
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS
- [ ] No S1 or S2 bugs in delivered features
- [ ] HIGH RISK items verified on Godot 4.6

---

> **Note**: PR-SPRINT gate skipped — Lean mode. Producer feasibility not required.

---

## Next Steps

1. `/qa-plan sprint` — define test cases per story (before implementation)
2. `/story-readiness production/epics/block-collision-system/story-001-collision-query-api.md`
3. `/dev-story [story-path]` — begin first story implementation