# Sprint 3 — Vehicle Combat & Enemy Systems

**Start**: 2026-04-25
**End**: 2026-05-08 (2 weeks)
**Mode**: lean — PR-SPRINT gate skipped

---

## Sprint Goal

完成战车完整属性系统（属性、伤害、武器）+ 敌人 AI 基础 + 建造验证链 —— 实现 MVP 核心循环的战斗交互能力。

---

## Capacity

- **Total days**: 14 (2 weeks)
- **Buffer (20%)**: 3 days
- **Available**: 11 days
- **Velocity (Sprint 2)**: 6 Must Have stories in 14 days (0.43 stories/day for Must Have)
- **Adjusted**: Sprint 2 spent significant time on Vertical Slice + Gate Check; Sprint 3 should focus on pure implementation

---

## Tasks

### Must Have (Critical Path — 战车战斗系统)

| ID | Story | Epic | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 3-1 | Vehicle Attribute State | vehicle-attribute-system | 1 | Sprint 2 (driving) | health/magic tracking, GlobalSignals events, state transitions |
| 3-2 | Damage Receiver System | vehicle-damage-system | 1 | 3-1 | take_damage(), armor calculation, DESTROYED state |
| 3-3 | Weapon Firing System | vehicle-weapon-system | 2 | 3-1 | fire_weapon(), cooldown, projectile spawn, damage output |
| 3-4 | Validation Chain V1-V6 | build-validation-system | 2 | Sprint 2 (placing) | BuildValidator.validate_placement(), terrain/entity/resource checks |
| 3-5 | Enemy AI State Machine | enemy-ai-system | 2 ⚠️ HIGH | Sprint 2 | NavigationAgent2D verified, 6 states, target acquisition |
| 3-6 | Spawn Wave Timing | enemy-spawn-system | 1 | 3-5 | spawn_wave(), time-triggered waves, GlobalSignals.enemy_spawned |

### Should Have (防守 + 区域)

| ID | Story | Epic | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 3-7 | Turret Targeting | turret-system | 1 | 3-5, 3-3 | acquire_target(), fire_at_target(), auto-attack |
| 3-8 | Area Bounds Manager | exploration-area-system | 1 | Sprint 2 | area bounds definition, entry detection, GlobalSignals.area_entered |
| 3-9 | Retreat Threshold Detection | retreat-judgment-system | 1 | Sprint 2, 3-1 | check_threshold(), warning triggers, time/health/magic thresholds |

### Nice to Have (整合测试)

| ID | Story | Epic | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 3-10 | Resource Drop Entity (Formalize) | resource-drop-system | 1 | Sprint 2 | 从原型代码正式化，lifetime, pickup triggers |
| 3-11 | Facility Entity Lifecycle | bunker-facility-system | 2 | 3-4 | facility placement, power consumption, production cycle |
| 3-12 | Dual-focus Playtest (Deferred) | integration | 1 | 3-1~3-6 | KB/mouse + gamepad 同时测试，验证无冲突 |

---

## HIGH RISK Stories

| Story | Risk | Action |
|-------|------|--------|
| enemy-ai-system/story-001 | ADR-010 NavigationAgent2D (Godot 4.5+) | Read `docs/engine-reference/godot/modules/navigation.md` before coding |
| weapon-firing-system/story-001 | Projectile collision + damage integration | Verify CollisionManager integration for projectile queries |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| NavigationAgent2D API differs from docs | High | High | Read engine reference before implementation; verify in Editor |
| Weapon projectile performance | Medium | Medium | Profile with multiple enemies + turrets firing |
| BuildValidator V3-V6 edge cases | Low | Medium | Write comprehensive test cases covering all failure modes |
| Dual-focus integration test blocked | Low | Low | Deferred from Sprint 2; must complete in Sprint 3 |

---

## Dependencies on External Factors

- Sprint 2 Must Have systems stable (verified ✅)
- Vertical Slice validated (verified ✅ — human playtest PASS)
- NavigationAgent2D docs in engine-reference (⚠️ needs verification)

---

## Definition of Done for this Sprint

- [ ] All Must Have stories completed (6 stories)
- [ ] All stories pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-3-[date].md`)
- [ ] All Logic stories have passing tests (run in Editor GUT panel)
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS
- [ ] No S1 or S2 bugs in delivered features
- [ ] HIGH RISK items verified on Godot 4.6
- [ ] Dual-focus playtest completed (deferred from Sprint 2)

---

## Carryover from Sprint 2

| Task | Reason | New Estimate |
|------|--------|-------------|
| Dual-focus playtest (driving-001) | Deferred HIGH RISK | 1 day (Sprint 3 integration testing) |

---

> **Note**: PR-SPRINT gate skipped — Lean mode. Producer feasibility not required.

---

## Next Steps

1. `/qa-plan sprint` — define test cases per story (before implementation)
2. `/story-readiness production/epics/vehicle-attribute-system/story-001-vehicle-attribute-state.md`
3. `/dev-story [story-path]` — begin first story implementation