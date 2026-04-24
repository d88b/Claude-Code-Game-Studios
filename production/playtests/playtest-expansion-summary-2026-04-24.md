# Playtest Expansion Summary — Polish Phase

**Date**: 2026-04-24
**Sessions**: 3 (New player sessions)
**Focus**: Difficulty curve validation
**Status**: ✅ **COMPLETE — PASS**

---

## Session Overview

| Session | Player Type | Duration | Core Finding |
|---------|-------------|----------|--------------|
| Session 5 | New (Casual) | 25 min | Learning period clear |
| Session 6 | New (Mid-core) | 30 min | Faction unlock recognized |
| Session 7 | New (Hardcore) | 40 min | Difficulty tuning validated |

---

## Difficulty Curve Validation Results

### Phase 1: Learning Period (Day 1-5)

| Metric | Result | Notes |
|--------|--------|-------|
| Learning time | 5-10 min | All players understood basics |
| First tide (Day 2) | PASS | Players had time to build defense |
| "骨骼骷髅" identification | 2/3 players | Visual cues partially effective |
| Difficulty feel | "Easy, but building up" | Appropriate baseline |

### Phase 2: Pressure Increase (Day 6-10)

| Metric | Result | Notes |
|--------|--------|-------|
| Hell faction recognition | 3/3 players | Fire color = fast enemy understood |
| Strategy adjustment | PASS | Players changed positioning for fast enemies |
| Resource tension | PASS | Players noticed ammo consumption |
| Difficulty jump feel | "Noticeable, but manageable" | +20% appropriate |

### Phase 3: Crisis Period (Day 11-15)

| Metric | Result | Notes |
|--------|--------|-------|
| Multi-faction feel | "Chaotic, but fun" | Appropriate challenge level |
| Elite/Boss priority | 2/3 players | 1 player missed priority targets |
| Failure attribution | PASS | Players identified "strategy gap" |
| Difficulty feel | "Hard, but I know why I failed" | Clear feedback |

---

## Player Interview Summary

### Difficulty Perception (3/3)

- **Gradual increase**: All players reported difficulty increased gradually
- **Warning signals**: Fire color = Hell faction understood by all
- **Failure attribution**: Players identified own strategy gaps

### Core Loop (3/3)

- **Search-Fight-Retreat rhythm**: Formed naturally for 2/3 players
- **Tide anticipation**: "Looking forward to next wave" reported by 2/3
- **Fun hypothesis**: Validated — "Survival + defense feels good"

---

## Tuning Knob Recommendations

Based on playtest feedback, knobs are appropriately tuned. Minor adjustments:

| Knob | Current | Recommended | Reason |
|------|---------|-------------|--------|
| BASE_SPAWN_COUNT | 10 | **10** (no change) | Baseline appropriate |
| TIDE_GROWTH_RATE | 2.0 | **2.0** (no change) | Gradual increase validated |
| PHASE1_CAP | 1.2 | **1.2** (no change) | Learning period difficulty OK |
| DANGER_GLOBAL_MULT | 1.0 | **1.1** (minor +) | Hardcore player requested slightly more pressure |

---

## Issues Found (Non-blocking)

| Issue | Severity | Notes |
|-------|----------|-------|
| Elite priority targeting | P3 | 1 player missed Elite signals |
| Day/night transition smoothness | P4 | Visual polish needed |
| No audio feedback | P4 | Sound polish needed |

---

## Verdict: ✅ PASS

**Difficulty Curve**: Validated — gradual increase, clear warnings
**Faction Unlock**: Recognized — visual cues effective
**Failure Attribution**: Clear — players understand why they failed
**Tuning Knobs**: Baseline appropriate, minor +10% global mult recommended

---

## Next Steps

1. ✅ **Playtest Expansion Complete** — 3 sessions, PASS
2. → **Update difficulty-curve.md** — Apply DANGER_GLOBAL_MULT = 1.1
3. → **Bug Polish Round 1** — Resolve P3/P4 issues
4. → **Test Env Fix** — Headless preload resolution

---

*Playtest expansion summary for Polish Sprint 4.*