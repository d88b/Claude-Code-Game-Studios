# Release Sprint: Launch Preparation

**铁锈魔潮 (Rust Magic Tide)**

> **Sprint**: Release-001
> **Duration**: 2026-04-26 to 2026-05-02 (1 week)
> **Goal**: 完成发布素材 + 平台集成
> **Mode**: Lean (gate skipped, pre-approved)

---

## Sprint Goal

完成所有发布必需素材创作和平台集成，使游戏达到 Launch Ready 状态。

---

## Must Have (Blocking)

| # | Story | Type | Est. Time | Owner | Status |
|---|-------|------|-----------|-------|--------|
| 1 | **assets-001**: Production Sprites | Visual | 3-5 days | Artist/Dev | ⏳ Pending |
| 2 | **screenshots-001**: Capture Screenshots | Visual | 4 hours | Dev | ⏳ Pending |
| 3 | **trailer-001**: Launch Trailer | Visual | 21 hours | Dev/Editor | ⏳ Pending |
| 4 | **keyart-001**: Capsule Images | Visual | 18 hours | Artist | ⏳ Pending |
| 5 | **age-001**: IARC Submission | Config | 1 hour | Producer | ⏳ Pending |
| 6 | **steam-001**: Steam SDK Integration | Integration | 2-3 hours | Dev | ⏳ Pending |

---

## Should Have (Advisory)

| # | Story | Type | Est. Time | Owner | Status |
|---|-------|------|-----------|-------|--------|
| 7 | **audio-001**: Audio Assets Creation | Audio | 2 days | Audio | ⏳ Pending |
| 8 | **tutorial-001**: Tutorial System | Logic | TBD | Dev | ⏳ Pending |
| 9 | **credits-001**: Credits Sequence | Visual | 2 hours | Dev | ⏳ Pending |

---

## Nice to Have (Optional)

| # | Story | Type | Est. Time | Owner | Status |
|---|-------|------|-----------|-------|--------|
| 10 | **analytics-001**: Telemetry System | Logic | TBD | Dev | ⏳ Pending |
| 11 | **crash-001**: Crash Reporting | Logic | TBD | Dev | ⏳ Pending |
| 12 | **achievement-001**: Achievement System | Logic | TBD | Dev | ⏳ Pending |

---

## Task Breakdown

### assets-001: Production Sprites

**Scope**: Replace 26 SVG placeholders with pixel art sprites

| Asset Category | Count | Style | Priority |
|----------------|-------|-------|----------|
| Vehicle (body/turret/wheel) | 3 | Pixel art, 64x48 | P1 |
| Enemies (zombie variants) | 5 | Pixel art, 32x48 | P1 |
| Drops (crystal/metal/organic/fuel/rare) | 5 | Pixel art, 16x16 | P2 |
| Facilities (turret/workshop/storage/generator/barrier) | 5 | Pixel art, 32x32 | P2 |
| UI Icons (health/magic/time/warning/day/night/cursors) | 8 | Pixel art, 24x24 | P2 |

**Style Guide Reference**: `design/art/art-bible.md`

---

### screenshots-001: Capture Screenshots

**Scope**: 5-10 screenshots for Steam/Epic store pages

| # | Content | Source | Status |
|---|---------|--------|--------|
| 1 | Vehicle exploration | `simple_hud.tscn` + vehicle | ⏳ |
| 2 | Digging/building | TileMap interaction | ⏳ |
| 3 | Zombie defense | Spawn wave active | ⏳ |
| 4 | Vehicle customization | Upgrade UI | ⏳ |
| 5 | Day/night comparison | DayNightCycle | ⏳ |

**Spec Reference**: `production/store/SCREENSHOT_SPEC.md`

**Capture Method**:
1. Run game in Godot Editor
2. Press F12 or use screenshot tool
3. Resolution: 1920x1080

---

### trailer-001: Launch Trailer

**Scope**: 60-90 second launch trailer

| Phase | Duration | Content |
|-------|----------|---------|
| Hook | 0-10s | Vehicle engine start, exit bunker |
| Exploration | 10-25s | Surface driving, resource pickup |
| Combat | 25-40s | Shooting zombies, explosion VFX |
| Building | 40-50s | Dig animation, facility placement |
| Defense | 50-65s | Tide attack, turret auto-fire |
| Day/Night | 65-75s | Phase transition visual |
| Title/CTA | 75-90s | Game title, Steam/Epic logos |

**Spec Reference**: `production/store/TRAILER_SCRIPT.md`

**Tools**: OBS Studio for capture, DaVinci Resolve for editing

---

### keyart-001: Capsule Images

**Scope**: 3 Steam capsules + 2 Epic images

| Platform | Size | Count | Status |
|----------|------|-------|--------|
| Steam Main Capsule | 616x353 | 1 | ⏳ |
| Steam Small Capsule | 200x112 | 1 | ⏳ |
| Steam Header Capsule | 460x215 | 1 | ⏳ |
| Epic Main | 1920x1080 | 1 | ⏳ |
| Epic Small | 256x256 | 1 | ⏳ |

**Spec Reference**: `production/store/KEY_ART_SPEC.md`

**Design Elements**: Vehicle + zombies + wasteland background

---

### age-001: IARC Submission

**Scope**: Submit age rating questionnaire

| Platform | System | Action |
|----------|--------|--------|
| Steam | IARC built-in | Answer questionnaire in Steamworks |
| Epic | IARC built-in | Answer questionnaire in EOS dashboard |

**Preparation**: `legal/AGE_RATINGS.md` has questionnaire answers ready

**Expected Rating**: Teen (13+) / PEGI 12

---

### steam-001: Steam SDK Integration

**Scope**: Basic Steamworks integration

| Feature | Required | Status |
|---------|----------|--------|
| Steam App ID | Required | ⏳ |
| Steam Init | Required | ⏳ |
| Achievements | Optional | Deferred |
| Cloud Save | Optional | Deferred |
| Stats/Leaderboards | Optional | Deferred |

**Implementation**: Use Godot Steam addon or GDExtension

---

## Time Estimate Summary

| Category | Total Time |
|----------|------------|
| **Must Have** | ~5-6 days |
| **Should Have** | ~2-3 days |
| **Nice to Have** | Deferred to post-launch |

---

## Sprint Workflow

### Daily Check-in

- Day 1: Start assets-001 (vehicle sprites)
- Day 2: Continue assets, start screenshots-001
- Day 3: Complete assets, start trailer capture
- Day 4: Trailer editing, start keyart
- Day 5: Complete keyart, submit IARC
- Day 6: Steam SDK integration
- Day 7: Final review, smoke test

---

## Success Criteria

- [ ] 26 production sprites created
- [ ] 5+ screenshots captured
- [ ] 60-90s trailer produced
- [ ] 5 capsule images created
- [ ] IARC questionnaire submitted
- [ ] Steam SDK integrated
- [ ] Smoke test passes with new assets

---

## Risks

| Risk | Mitigation |
|------|------------|
| Asset creation time > estimate | Start with most visible (vehicle/enemies) |
| Trailer editing complexity | Use simple cuts, avoid complex effects |
| IARC rejection | Content is mild (no blood/gore), expect pass |
| Steam SDK issues | Test with Steam dummy mode first |

---

## Next Session

Recommended start: **assets-001** (Production Sprites)

Or if assets will be outsourced: **screenshots-001** (Capture Screenshots) — can be done immediately in Editor

---

*Release Sprint Plan — 铁锈魔潮*
*Created: 2026-04-25*