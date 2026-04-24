# Sprint 4 — Polish Phase

**Start**: 2026-04-25
**End**: 2026-05-08 (2 weeks)
**Mode**: lean — PR-SPRINT gate skipped
**Phase**: Polish

---

## Sprint Goal

性能验证 + Playtest 扩展 + Bug polish + Difficulty tuning —— 确保游戏达到可发布质量标准。

---

## Capacity

- **Total days**: 14 (2 weeks)
- **Buffer (20%)**: 3 days
- **Available**: 11 days
- **Previous Phase**: Production (Sprint 3 COMPLETE — all Must Have done)
- **Focus**: Polish 优先，非新功能开发

---

## Tasks

### Must Have (Critical Path — 发布质量)

| ID | Story | Type | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 4-1 | Runtime Profiling | Integration | 1 | Perf hotspots fixed | Godot profiler confirms frame budget OK |
| 4-2 | Playtest Expansion (3 sessions) | Visual/Feel | 2 | Vertical Slice stable | ≥3 new player sessions documented |
| 4-3 | Bug Polish Round 1 | Logic | 2 | QA sign-off | All S1/S2 bugs resolved |
| 4-4 | Difficulty Tuning | Config/Data | 1 | difficulty-curve.md | TK-D knobs calibrated from playtest data |
| 4-5 | Test Env Fix | Logic | 2 | Sprint 3 env issues | Headless preload issues resolved |
| 4-6 | Dual-focus Playtest | Integration | 1 | KB/M + Gamepad | Dual input verified, no conflicts |

### Should Have (体验优化)

| ID | Story | Type | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 4-7 | VFX Polish: Enemy Death | Visual/Feel | 1 | Enemy type DB | 4 faction death animations + sounds |
| 4-8 | UI Polish: HUD Feedback | UI | 1 | HUD spec | Smooth transitions, clear warnings |
| 4-9 | Audio Polish: Ambient | Visual/Feel | 1 | DayNight phase | Phase-aware ambient sounds |

### Nice to Have (可选优化)

| ID | Story | Type | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 4-10 | Accessibility: Text Scaling | UI | 1 | accessibility-req | 1.5× text scaling works |
| 4-11 | Asset Polish: Placeholder replacement | Visual/Feel | 2 | Art bible | 5 placeholder sprites replaced |
| 4-12 | Localization Prep | Config/Data | 1 | No hardcoded strings | All strings in locale files |

---

## HIGH RISK Stories

| Story | Risk | Action |
|-------|------|--------|
| Test Env Fix | Headless preload requires engine understanding | May need GDExtension specialist if preload fails in CLI |
| Dual-focus Playtest | Integration test complexity | Use real hardware (KB + gamepad), not simulated |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Profiler shows new hotspots | Medium | Medium | Re-run perf-profile after tuning |
| Playtest reveals new S1 bugs | High | High | Reserve buffer days for Bug Polish Round 2 |
| Test env fix takes longer | Medium | Low | Accept headless limitation, focus on Editor tests |
| Difficulty tuning feedback loop | Medium | Medium | Run playtest → tune → retest cycle |

---

## Dependencies on External Factors

- Performance hotspots fixed (✅ DONE — print gated, pool added, steps reduced)
- difficulty-curve.md created (✅ DONE)
- QA sign-off APPROVED WITH CONDITIONS (✅ DONE)
- Godot Editor profiling capability (needs verification)

---

## Definition of Done for this Sprint

- [ ] Runtime profiling confirms frame budget OK (≤16ms)
- [ ] ≥3 playtest sessions completed with new players
- [ ] All S1/S2 bugs from playtest resolved
- [ ] Difficulty knobs calibrated per playtest feedback
- [ ] Test env preload issues resolved OR documented workaround
- [ ] Dual-focus playtest verified (KB + gamepad)
- [ ] QA sign-off for Polish: APPROVED
- [ ] Gate check Polish → Release PASS

---

## Carryover from Sprint 3

| Task | Reason | New Estimate |
|------|--------|-------------|
| Test env issues (43 failures) | Headless preload limitations | 2 days (Polish focus) |
| dualfocus-001 | Deferred backlog item | 1 day (Must Have in Polish) |

---

## Polish Phase Checklist (Pre-Release)

From gate-check requirements:

- [x] Performance profile exists
- [x] Performance hotspots fixed
- [x] difficulty-curve.md created
- [ ] Runtime profiling confirms gains
- [ ] ≥3 playtest sessions (new players)
- [ ] No S1/S2 bugs
- [ ] All UX specs verified
- [ ] Accessibility basics covered
- [ ] Localization prep (strings externalized)

---

> **Note**: PR-SPRINT gate skipped — Lean mode. Focus on polish, not new features.

---

## Next Steps

1. Run Godot Editor profiler to confirm performance gains
2. Schedule playtest sessions with new players
3. `/qa-plan sprint` for Polish phase
4. Begin Bug Polish Round 1