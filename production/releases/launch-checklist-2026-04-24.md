# Launch Checklist: 铁锈魔潮

**Target Launch**: TBD (Dry Run)
**Generated**: 2026-04-24
**Platform**: PC (Steam / Epic Games Store)
**Engine**: Godot 4.6

---

## 1. Code Readiness

### Build Health

| Item | Status | Notes |
|------|--------|-------|
| Clean build on all target platforms | ✅ PASS | Engine initializes OK, no compile errors |
| Zero compiler warnings | ❓ MANUAL | Not verified in this scan |
| All unit tests passing | ❌ FAIL | 87/130 PASS (67%), 43 failures (env issues) |
| All integration tests passing | ❓ MANUAL | 1 integration test file exists |
| Performance benchmarks within targets | ✅ PASS | Frame budget ~8-10ms (within 16.6ms) |
| No memory leaks | ❓ NOT RUN | No soak test executed |
| Build size within platform limits | ❓ MANUAL | Not verified |
| Build version correctly set | ❓ MANUAL | Not verified |

### Code Quality

| Item | Status | Notes |
|------|--------|-------|
| TODO count | ⚠️ 5 | enemy_ai_controller, ambient_audio_manager, facility_controller, damage_receiver, vfx-spec |
| FIXME count | ⚠️ 0 | None found |
| HACK count | ⚠️ 0 | None found |
| Debug output in production | ⚠️ CONCERNS | 40 files with print(), partially gated with `OS.is_debug_build()` |
| Hardcoded dev/test values | ✅ PASS | None found |
| Feature flags set to production | ❓ MANUAL | Not verified |
| Error handling covers critical paths | ✅ PASS | push_error/push_warning in key systems |
| Crash reporting integrated | ❌ FAIL | No crash reporting system |

### Security

| Item | Status | Notes |
|------|--------|-------|
| No exposed API keys/credentials | ✅ PASS | None found |
| Save data encrypted | ❌ NOT IMPLEMENTED | Save system not implemented |
| Network communication secured | N/A | Single-player |
| Anti-cheat measures | N/A | Single-player |
| Input validation | N/A | Single-player |
| Privacy policy compliance | ❌ FAIL | No privacy policy document |

---

## 2. Content Readiness

### Assets

| Item | Status | Notes |
|------|--------|-------|
| Placeholder art replaced | ❌ **FAIL** | NO assets directory — only `assets/tilesets/block_types.tres` |
| Placeholder audio replaced | ❌ **FAIL** | NO audio files — assets/audio/ missing |
| Audio mix finalized | ❌ FAIL | No audio implemented (BUG-004) |
| VFX polished | ⚠️ PARTIAL | VFX spec exists, implementation pending |
| Missing/broken asset references | ❓ MANUAL | Not verified |
| Asset naming conventions | ❓ MANUAL | Not verified |

**Asset Inventory**:
- Sprites: **0 files**
- Audio: **0 files**
- VFX: **0 files** (spec only)
- Tilesets: **1 file** (block_types.tres)

### Text and Localization

| Item | Status | Notes |
|------|--------|-------|
| Player-facing text proofread | ❓ MANUAL | Not verified |
| No hardcoded strings | ❌ **FAIL** | 40 .gd files with hardcoded strings |
| Supported languages translated | ❌ FAIL | locale/ directory missing |
| Text fits UI in all languages | ❌ FAIL | No localization system |
| Font coverage verified | ❓ MANUAL | Not verified |
| Credits complete | ❌ FAIL | No credits sequence |

### Game Content

| Item | Status | Notes |
|------|--------|-------|
| All levels playable start-to-finish | ⚠️ PARTIAL | Vertical Slice validated, full game not complete |
| Tutorial flow complete | ❌ NOT IMPLEMENTED | No tutorial system |
| Achievements implemented | ❌ NOT IMPLEMENTED | No achievement system |
| Save/load works | ❌ NOT IMPLEMENTED | No save system |
| Difficulty settings balanced | ✅ PASS | difficulty-curve.md complete, tuning done |
| End-game/credits sequence | ❌ FAIL | No credits/ending |

---

## 3. Quality Assurance

### Testing

| Item | Status | Notes |
|------|--------|-------|
| Full regression suite passed | ❌ FAIL | 43/130 tests failing (env issues) |
| Zero S1 bugs | ✅ PASS | No S1 bugs |
| Zero S2 bugs | ✅ PASS | No S2 bugs |
| Soak test passed (8+ hours) | ❌ NOT RUN | No soak test |
| Multiplayer stress test | N/A | Single-player |
| Critical paths tested on all platforms | ⚠️ PARTIAL | Playtest validated core loop |
| Edge cases tested | ⚠️ PARTIAL | Unit tests cover formulas/edge cases |

### Platform Certification

| Item | Status | Notes |
|------|--------|-------|
| Steam SDK requirements | ❌ NOT DONE | No Steam integration |
| Epic SDK requirements | ❌ NOT DONE | No Epic integration |
| Console TRC/TCR | N/A | PC only (current) |
| Accessibility minimum standards | ⚠️ PLANNED | Standard tier committed, NOT implemented |
| Age ratings obtained | ❌ FAIL | No ESRB/PEGI rating |

### Performance

| Item | Status | Notes |
|------|--------|-------|
| Target FPS on minimum spec | ✅ PASS | ~8-10ms frame budget |
| Load times within budget | ❓ MANUAL | Not measured |
| Memory within budget | ⚠️ ADVISORY | Ceiling 512MB, not verified |
| Network bandwidth | N/A | Single-player |
| No frame hitches | ✅ PASS | Playtest noted "no frame spikes" |

---

## 4. Store and Distribution

### Store Pages

| Item | Status | Notes |
|------|--------|-------|
| Store page copy finalized | ❌ FAIL | No store page document |
| Screenshots current | ❌ FAIL | No assets → no screenshots |
| Trailers approved | ❌ FAIL | No trailer |
| Key art/capsule images | ❌ FAIL | No key art |
| System requirements accurate | ⚠️ PARTIAL | Tech prefs defined, not published |
| Pricing configured | ❌ FAIL | No pricing document |
| Pre-purchase campaigns | ❌ FAIL | No campaign |

### Legal

| Item | Status | Notes |
|------|--------|-------|
| EULA finalized | ❌ **FAIL** | No EULA document |
| Privacy policy published | ❌ **FAIL** | No privacy policy |
| Third-party attributions | ❓ MANUAL | No third-party libs documented |
| Music/audio licensing | ❌ FAIL | No audio assets |
| Trademark/IP clearance | ❓ MANUAL | Not verified |
| GDPR/CCPA compliance | ❌ FAIL | No data collection policy |

---

## 5. Infrastructure

### Servers

| Item | Status | Notes |
|------|--------|-------|
| Production servers | N/A | Single-player |
| Auto-scaling | N/A | |
| Database backups | N/A | |
| CDN for content | N/A | |
| DDoS protection | N/A | |
| Monitoring/alerting | N/A | |

### Analytics and Monitoring

| Item | Status | Notes |
|------|--------|-------|
| Analytics pipeline | ❌ NOT IMPLEMENTED | No analytics system |
| Crash reporting active | ❌ NOT IMPLEMENTED | No crash reporting |
| Server dashboards | N/A | Single-player |
| Key metrics tracked | ❌ FAIL | No telemetry |
| Alerts configured | ❌ FAIL | No alerting |

---

## 6. Community and Marketing

### Community Readiness

| Item | Status | Notes |
|------|--------|-------|
| Community guidelines | ❌ FAIL | No community doc |
| Moderation team briefed | ❌ FAIL | No moderation plan |
| Discord/forum channels | ❌ FAIL | No social setup |
| FAQ and known issues | ⚠️ PARTIAL | Bugs documented in production/qa/bugs/ |
| Support system | ❌ FAIL | No support email/ticketing |

### Marketing

| Item | Status | Notes |
|------|--------|-------|
| Launch trailer | ❌ FAIL | No trailer |
| Press/influencer keys | ❌ FAIL | No key distribution plan |
| Social media posts | ❌ FAIL | No social posts scheduled |
| Launch day blog post | ❌ FAIL | No dev update drafted |
| Patch notes published | ❌ FAIL | No patch notes |

---

## 7. Operations

### Team Readiness

| Item | Status | Notes |
|------|--------|-------|
| On-call schedule (72h) | ❌ FAIL | Solo developer? No on-call plan |
| Incident response playbook | ❌ FAIL | No playbook |
| Rollback plan | ❌ FAIL | No rollback plan |
| Hotfix pipeline tested | ❓ MANUAL | Not verified |
| Communication plan | ❌ FAIL | No plan |

### Day-One Plan

| Item | Status | Notes |
|------|--------|-------|
| Day-one patch prepared | ❓ N/A | No known issues requiring patch |
| Server unlock procedure | N/A | Single-player |
| Launch dashboard bookmarked | ❌ FAIL | No dashboard |
| War room established | ❌ FAIL | No war room |

---

## Go / No-Go Decision

### Summary Statistics

| Category | Total | Pass | Fail | Manual | Not Run |
|----------|-------|------|------|--------|---------|
| Code Readiness | 16 | 5 | 4 | 5 | 2 |
| Content Readiness | 17 | 1 | 14 | 2 | 0 |
| QA | 13 | 4 | 4 | 0 | 5 |
| Store/Distribution | 13 | 0 | 13 | 0 | 0 |
| Infrastructure | 6 | 0 | 2 | 0 | 4 (N/A) |
| Community/Marketing | 10 | 0 | 9 | 0 | 1 |
| Operations | 8 | 0 | 7 | 1 | 0 |
| **TOTAL** | **73** | **10** | **49** | **8** | **6** |

### Blocking Items (Must Resolve)

1. **NO GAME CONTENT** — Assets missing (sprites, audio, VFX)
2. **NOT LOCALIZED** — Hardcoded strings, no locale system
3. **NO LEGAL DOCUMENTS** — EULA, privacy policy, age ratings
4. **NO STORE PREP** — Store page, screenshots, trailer, pricing
5. **SAVE SYSTEM MISSING** — Cannot persist game progress
6. **TESTS FAILING** — 43/130 env failures (CI reliability)

### Conditional Items (Acceptable Risk)

- 5 TODOs (non-blocking, documented)
- 40 print() calls (partially gated with debug check)
- Accessibility planned but not implemented (Standard tier)
- Analytics/crash reporting not implemented (single-player, lower priority)

### Overall Status: ❌ **NOT READY**

---

### Sign-Offs Required

| Role | Status | Key Concern |
|------|--------|-------------|
| Creative Director | ⚠️ PENDING | Content/Assets missing |
| Technical Director | ⚠️ PENDING | Tests failing, save system missing |
| QA Lead | ⚠️ PENDING | Test env issues, soak test not run |
| Producer | ⚠️ PENDING | Store/legal prep missing |
| Release Manager | ⚠️ PENDING | No release checklist, build packaging not verified |

---

## Estimated Resolution Path

| Blocker | Est. Time | Priority |
|---------|-----------|----------|
| Create placeholder → final assets (sprites) | 3-5 days | P1 |
| Create audio assets | 1-2 days | P1 |
| Implement localization system | 2 days | P1 |
| Create EULA + Privacy Policy | 1 day | P1 |
| Implement save system | 2 days | P1 |
| Prepare store page + screenshots | 1 day | P1 |
| Fix test env issues | 2 days | P2 |
| Age rating submission | 1-2 weeks | P1 (external) |

**Total Estimate**: 12-15 days (excluding age rating external timeline)

---

## Next Steps

1. Return to Polish phase to complete missing content
2. Run `/localize` to externalize all hardcoded strings
3. Implement save system (new story)
4. Create legal documents (EULA, privacy policy)
5. Prepare store page content
6. Re-run `/launch-checklist` after blockers resolved

---

*Launch checklist generated by /launch-checklist skill — 2026-04-24.*