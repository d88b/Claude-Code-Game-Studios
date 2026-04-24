# Difficulty Tuning Summary

**Date**: 2026-04-24
**Sprint**: Sprint 4 (Polish)
**Status**: COMPLETE

---

## Tuning Knob Changes

Based on Playtest Expansion feedback (3 sessions), tuning knobs adjusted:

| Knob | Before | After | Impact |
|------|--------|-------|--------|
| DANGER_GLOBAL_MULT | 1.0 | **1.1** | +10% all danger multipliers |
| TRANSITION_DURATION | 30.0 | **45.0** | +50% smoother transitions |

---

## Files Modified

### day_night_cycle.gd

```gdscript
## 全局危险倍率调优参数 (TK-006) — 1.1 from playtest feedback (10% increase)
const DANGER_GLOBAL_MULT: float = 1.1

## 过渡时长 (游戏秒) — 45 for smoother visual transitions (TK-007 updated)
const TRANSITION_DURATION: float = 45.0
```

---

## Impact Analysis

### DANGER_GLOBAL_MULT = 1.1

**Effect on phase danger multipliers**:

| Phase | Before (×1.0) | After (×1.1) |
|-------|---------------|--------------|
| DAWN | 0.8 | **0.88** |
| DAY | 1.0 | **1.1** |
| DUSK | 1.2 | **1.32** |
| NIGHT | 1.5 | **1.65** |

**Gameplay impact**:
- Baseline DAY danger +10% → slightly more pressure during safe period
- NIGHT danger +10% → more urgent retreat pressure
- Hardcore player feedback addressed: "slightly more pressure"

---

## Playtest Validation Required

Before finalizing tuning knobs, recommend:

1. Run 1-2 validation sessions with adjusted values
2. Confirm difficulty feel matches target: "Hard, but I know why I failed"
3. If feedback shows over-pressure, revert DANGER_GLOBAL_MULT to 1.0

---

## Deferred Tuning

| Knob | Current | Recommended | Reason |
|------|---------|-------------|--------|
| BASE_SPAWN_COUNT | 10 | 10 (no change) | Baseline appropriate |
| TIDE_GROWTH_RATE | 2.0 | 2.0 (no change) | Gradual increase validated |
| PHASE1_CAP | 1.2 | 1.2 (no change) | Learning period difficulty OK |

---

## Next Steps

1. ✅ Difficulty Tuning — DANGER_GLOBAL_MULT = 1.1 applied
2. → **Validation Playtest** — 1-2 sessions with new values
3. → **Test Env Fix** — Resolve headless preload issues
4. → **Dual-focus Playtest** — KB + Gamepad integration test

---

*Difficulty tuning summary — Sprint 4 Polish phase.*