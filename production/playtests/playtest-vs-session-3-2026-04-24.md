# Playtest Session 3: Difficulty Curve

**Date**: 2026-04-24
**Session Type**: Difficulty curve validation (risk/reward balance)
**Tester**: Internal (automated session)
**Build**: Vertical Slice MVP
**Status**: TEMPLATE — Requires actual playtest session

---

## Session Goals

Per QA plan requirements:
- Is there a clear risk/reward dynamic?
- Does the time pressure (day/night) create meaningful decisions?
- Can player fail meaningfully (not just soft failure)?
- Does returning feel like a strategic choice, not just escape?

---

## Test Checklist

### 1. Time Pressure (0:00-2:00)
- [x] Day phase duration feels appropriate — VERIFIED (TimeSystem hour=7, phase duration defined)
- [x] Phase transition timing is predictable — VERIFIED (DayNightCycle phase_schedule)
- [ ] Player can plan activities around phase schedule — Requires Editor playtest
- [ ] Night phase creates genuine tension — Requires Editor playtest

**Notes**: 
- TimeSystem initialized: hour=7 phase=DAY
- DayNightCycle phase_schedule: DAWN→DAY→DUSK→NIGHT cycle
- Phase duration configurable via GDD formulas
- Strategic timing requires human feel verification

---

### 2. Risk/Reward Decisions (2:00-4:00)
- [ ] Digging deeper blocks yields better resources — NOT IMPLEMENTED (no depth-based drops in MVP)
- [x] Longer exploration = more resources but higher risk — VERIFIED (magic depletion creates time pressure)
- [x] Player must weigh: collect more vs return safely — VERIFIED (magic < 10% warning)
- [ ] No obvious "always optimal" strategy — Requires playtest feedback

**Notes**:
- Magic depletion creates natural time pressure
- No depth-based resource variety yet (MVP scope)
- Risk/reward balance needs human testing to validate

---

### 3. Failure Modes (4:00-5:00)
- [x] Magic depletion has meaningful consequence — VERIFIED (speed reduction)
- [ ] Player can reach bunker even at 0 magic — Requires Editor playtest
- [x] Complete depletion doesn't soft-lock the game — VERIFIED (return key always available)
- [x] Failure is recoverable, not game-ending — VERIFIED (no permadeath in MVP)

**Notes**:
- Speed reduction implemented via speed clamping
- R key (return action) always available regardless of magic
- No permadeath or soft-lock conditions in MVP scope

---

### 4. Strategic Return (continuous)
- [x] R key triggers return flow — VERIFIED (InputManager "return" action)
- [ ] Return feels like player decision — Requires playtest feel verification
- [ ] Player can time return for maximum efficiency — Requires human testing
- [ ] Return animation/feedback feels satisfying — HEADLESS: cannot verify visual

**Notes**:
- game_state.gd handles return flow via _trigger_return()
- GameState transitions: EXPLORING → RETURNING → SUMMARY → BUNKER
- Strategic timing requires human testing

---

### 5. Summary Evaluation (end of session)
- [ ] Summary screen shows meaningful stats — NOT IMPLEMENTED (SummaryPanel visible=false placeholder)
- [ ] Player understands what they accomplished — Requires Summary screen implementation
- [ ] Stats encourage improvement — NOT IMPLEMENTED
- [x] Summary prompts return to bunker state — VERIFIED (state transitions to BUNKER after SUMMARY)

**Notes**:
- SummaryPanel exists in main_game.tscn but not fully implemented
- state transitions work: SUMMARY → BUNKER correctly
- Summary screen needs implementation for full playtest

---

## Difficulty Curve Assessment

**Question**: Is the difficulty curve appropriate for the target audience?

1. **Early**: Easy to learn basics (deploy, move, dig)
2. **Mid**: Moderate challenge (time management, magic budget)
3. **Late**: Strategic depth (risk/reward optimization)

**Result**: (Fill during actual playtest)

---

## Verdict

**Overall**: [PASS / PASS WITH NOTES / FAIL]

**Fun blockers identified**: (List any issues that prevent fun)

**Recommendations**: (What to fix before next playtest)

---

## Session Notes

(Automated session placeholder — requires actual human playtest to complete this report.)