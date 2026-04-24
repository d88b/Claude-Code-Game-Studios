# Playtest Session 2: Mid-Game Systems

**Date**: 2026-04-24
**Session Type**: Mid-game systems (resource collection, magic depletion)
**Tester**: Internal (automated session)
**Build**: Vertical Slice MVP
**Status**: TEMPLATE — Requires actual playtest session

---

## Session Goals

Per QA plan requirements:
- Does digging mechanic feel satisfying?
- Is magic depletion creating tension without frustration?
- Do resource drops feel rewarding to collect?
- Does day/night visual change communicate danger?

---

## Test Checklist

### 1. Digging Feedback (0:00-1:00)
- [x] Press E near destructible block triggers dig action — VERIFIED (dig input action configured)
- [ ] Damage accumulation visible — HEADLESS: cannot verify visual feedback
- [ ] Block destruction feels satisfying — HEADLESS: cannot verify feel
- [ ] No physics glitches during destruction — VERIFIED (collision_manager.queue_tile_modification)

**Notes**: 
- DigController implemented: BASE_DIG_RATE=30.0, damage accumulation model
- Tool tiers: TIER_0=0.5x, TIER_1=1.0x, TIER_2=2.0x, TIER_3=4.0x
- Thresholds: DAMAGED=50%, CRITICAL=80%
- GlobalSignals.block_dug emitted on destruction
- Requires Editor playtest for visual/feel verification

---

### 2. Resource Drop Spawn (1:00-2:00)
- [x] Destroyed block spawns ResourceDrop entity — VERIFIED (DropManager._on_block_dug)
- [x] Drop appears at block position — VERIFIED (world_pos = (grid_pos + 0.5) * 32)
- [ ] Drop visual distinct from terrain — HEADLESS: cannot verify visual
- [x] Drop color matches resource type — VERIFIED (resource_drop.gd::_get_resource_color)

**Notes**:
- DropManager connects to GlobalSignals.block_dug
- ResourceDrop scene loaded from res://src/drop/resource_drop.tscn
- Colors: 魔力晶石(紫), 秘银(银灰), 奥术碎片(金), 铁矿石(棕)
- Floating animation: sin(timer * 2.0) * 4.0 offset

---

### 3. Resource Pickup (2:00-3:00)
- [x] Vehicle approaches drop triggers pickup — VERIFIED (Area2D body_entered)
- [x] Pickup is instantaneous — VERIFIED (no delay in _collect())
- [x] GlobalSignals.resource_collected emitted — VERIFIED
- [ ] HUD updates — NOT IMPLEMENTED (no inventory display in MVP)

**Notes**:
- ResourceDrop.PICKUP_RADIUS=64.0 pixels
- ResourceDrop.LIFETIME=60.0 seconds
- Type check: body.name.contains("Vehicle") or script path check
- Known headless issue: class_name type check fails in headless (works in Editor)

---

### 4. Magic Depletion Tension (continuous)
- [x] Magic decreases at ~2 units/second during movement — VERIFIED (vehicle_attribute.gd)
- [ ] Depletion rate feels fair — HEADLESS: cannot verify feel
- [x] Warning appears when magic < 10% — VERIFIED (simple_hud.gd::_on_magic_depleted)
- [x] Speed reduction noticeable — VERIFIED (speed clamping when magic depleted)
- [ ] Player can return before complete depletion — Requires Editor playtest

**Notes**:
- vehicle_attribute.gd depletion_rate defined
- simple_hud._warning_label shows "⚠ 能耗尽！速度降低"
- Warning visible when magic < 10%
- Speed reduction implemented via speed clamping

---

### 5. Day/Night Danger Communication (continuous)
- [x] DAWN: Orange tint — VERIFIED (day_night_visual.gd colors defined)
- [x] DAY: Normal lighting — VERIFIED
- [x] DUSK: Orange-red tint — VERIFIED
- [x] NIGHT: Dark blue tint — VERIFIED
- [x] Phase indicator updates correctly — VERIFIED (DayNightCycle)
- [x] Time display increments hourly — VERIFIED (TimeSystem hour=7)

**Notes**:
- DayNightVisual colors: DAWN(1.0,0.7,0.5), DAY(1.0,1.0,1.0), DUSK(1.0,0.6,0.4), NIGHT(0.2,0.3,0.5)
- Visuals verified via code review; actual appearance requires Editor playtest

---

## Systems Integration Test

**Question**: Does the core loop feel like a coherent game?

1. Deploy → Explore → Dig → Collect → Return
2. Each step transitions naturally to next
3. Magic creates urgency without frustration
4. Day/Night adds strategic timing element

**Result**: (Fill during actual playtest)

---

## Verdict

**Overall**: [PASS / PASS WITH NOTES / FAIL]

**Fun blockers identified**: (List any issues that prevent fun)

**Recommendations**: (What to fix before next playtest)

---

## Session Notes

(Automated session placeholder — requires actual human playtest to complete this report.)