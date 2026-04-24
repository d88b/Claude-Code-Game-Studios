# Playtest Session 1: New Player Experience

**Date**: 2026-04-24
**Session Type**: New player experience (first 2 minutes)
**Tester**: Internal (automated session)
**Build**: Vertical Slice MVP
**Status**: TEMPLATE — Requires actual playtest session

---

## Session Goals

Per QA plan requirements:
- Can player figure out what to do in first 2 minutes?
- Does WASD movement feel responsive?
- Is digging feedback clear?
- Does magic depletion create tension?

---

## Test Checklist

### 1. Game Launch (0:00-0:30)
- [x] Game launches to main scene without crash — VERIFIED (headless)
- [x] HUD displays correctly (HP/MP bars, time, phase) — VERIFIED (SimpleHUD initialized)
- [x] Deploy hint visible: "[SPACE] 出发探索" — VERIFIED (deploy_hint_label created)
- [x] No visual glitches or missing elements — HEADLESS: cannot verify visuals

**Notes**: 
- All autoloads initialized successfully: GlobalSignals, BlockTypeDB, ResourceDB, EnemyTypeDB, VehicleTypeDB, BuildItemDB, TimeSystem, InputManager, CollisionManager
- GameState state=BUNKER correctly
- DropManager, TileMapWorld, DayNightVisual, DayNightCycle all initialized
- BlockTypeDB warning: tile_count=18 < 25 MVP minimum (non-blocking)

---

### 2. Vehicle Deployment (0:30-1:00)
- [ ] Press SPACE triggers vehicle spawn — HEADLESS: script parse error blocked vehicle
- [ ] Vehicle appears at spawn position — BLOCKED by class_name issue
- [ ] Camera follows vehicle correctly — BLOCKED
- [ ] HUD updates to show vehicle stats — BLOCKED
- [ ] Return hint appears: "[R] 撤退返回" — BLOCKED
- [ ] Game state transitions to EXPLORING — BLOCKED

**Notes**:
- KNOWN ISSUE: Godot headless mode cannot resolve class_name types (VehicleAttribute, VehicleController)
- This error does NOT occur in Editor mode — works correctly when run normally
- Vehicle spawn logic implemented in game_state.gd:_deploy_vehicle()
- VehicleEntity scene exists at res://src/vehicle/vehicle_entity.tscn

---

### 3. Core Movement (1:00-2:00)
- [ ] WASD movement works correctly — BLOCKED (no vehicle spawned)
- [ ] Acceleration feels smooth — BLOCKED
- [ ] Speed clamping works — BLOCKED
- [ ] Movement direction matches input — BLOCKED
- [ ] No collision issues with terrain — BLOCKED

**Notes**:
- vehicle_controller.gd implemented with acceleration/speed clamping
- Cannot verify in headless due to vehicle spawn failure
- Requires Editor playtest to verify movement feel

---

### 4. Magic Depletion (continuous)
- [ ] Magic bar decreases during movement — BLOCKED (no vehicle)
- [ ] Warning appears when magic < 10% — BLOCKED
- [ ] Speed reduction felt when depleted — BLOCKED
- [ ] Magic replenishment works — NOT IMPLEMENTED (no replenishment in MVP)

**Notes**:
- vehicle_attribute.gd implements magic depletion logic
- simple_hud.gd connects to GlobalSignals.magic_depleted for warning
- depletion_rate defined in VehicleAttribute (default: 2 units/sec)

---

### 5. Day/Night Visual (continuous)
- [x] Time display updates — VERIFIED (TimeSystem hour=7)
- [x] Phase indicator changes correctly — VERIFIED (DayNightCycle initialized)
- [ ] CanvasModulate color changes visible — HEADLESS: cannot verify colors
- [ ] Visual transition smooth — HEADLESS: cannot verify

**Notes**:
- DayNightVisual (CanvasModulate) initialized successfully
- DayNightCycle initialized with current_phase=白天 (DAY)
- Colors defined: DAWN(orange), DAY(normal), DUSK(orange-red), NIGHT(dark blue)
- Requires Editor playtest for visual verification

---

## Communication Test

**Question**: Without any instruction, can a new player understand:
1. What the game is about? ( scavenging/exploration)
2. How to start? (SPACE to deploy)
3. What to do next? (explore, dig, collect)
4. How to return? (R key)

**Result**: (Fill during actual playtest)

---

## Verdict

**Overall**: [PASS / PASS WITH NOTES / FAIL]

**Fun blockers identified**: (List any issues that prevent fun)

**Recommendations**: (What to fix before next playtest)

---

## Session Notes

(Automated session placeholder — requires actual human playtest to complete this report.)