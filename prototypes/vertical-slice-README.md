# Vertical Slice Prototype

**Created**: 2026-04-24
**Last Updated**: 2026-04-24
**Status**: ✅ **VALIDATED — Human Playtest PASS**
**Scope**: MVP Core Loop Demonstration

---

## Prototype Goal

Demonstrate minimal playable loop:
- Start in bunker → Deploy vehicle → Explore surface → Collect resources → Return safely

**Result**: ✅ Core loop fully functional

---

## Build Location

- **Main Scene**: `res://src/playable_main_game.tscn`
- **Vehicle Entity**: `res://src/physics_vehicle.tscn`
- **Obstacles**: `res://src/block_obstacle.tscn`, `res://src/slow_zone.tscn`
- **Resources**: `res://src/resource_drop.tscn`
- **Visual Systems**: `res://src/daynight/daynight_visual.gd`, `res://src/grid_background.gd`

---

## How to Run

1. Open project in Godot 4.6 Editor
2. Press F5 to run `playable_main_game.tscn`
3. Press SPACE to deploy vehicle
4. Use WASD to move around
5. Press T to cycle day/night phases (test mode)
6. Press R to return to bunker (summary shown)

---

## Systems Demonstrated

| System | Implementation | Verification |
|--------|----------------|--------------|
| Game State Flow | game_state.gd | ✅ BUNKER→DEPLOY→EXPLORE→RETURN→SUMMARY |
| Vehicle Movement | physics_vehicle.gd | ✅ WASD movement, 400 speed, responsive |
| Physical Blocking | block_obstacle.gd | ✅ Red obstacles block passage |
| Speed Reduction | slow_zone.gd | ✅ Yellow zones slow to 30% |
| Day/Night Visual | daynight_visual.gd | ✅ Color overlays (黄昏/夜晚/黎明/白天) |
| Resource Collection | resource_drop.gd | ✅ Pickup on contact, HUD updates |
| HUD Display | simple_hud.gd | ✅ HP/MP bars, position, collected count |
| Grid Background | grid_background.gd | ✅ 20x11 checkerboard cells |
| Collision Layers | layer/mask system | ✅ Block (layer 2) vs Slow (layer 4) |

---

## Human Playtest Results

**Session 4**: 2026-04-24 — Human Editor Playtest

| Test | Result |
|------|--------|
| Game Launch | ✅ PASS — All systems initialized |
| Grid Background | ✅ PASS — 20x11 checkerboard visible |
| Deploy (SPACE) | ✅ PASS — Vehicle spawns correctly |
| WASD Movement | ✅ PASS — Responsive, 400 speed |
| Collision Blocking | ✅ PASS — Red obstacles block movement |
| Slow Zones | ✅ PASS — Speed drops 30%, can traverse |
| Day/Night Visual | ✅ PASS — Color overlays visible |
| Resource Collection | ✅ PASS — Drops collected, HUD updates |
| Return (R) | ✅ PASS — Summary panel shown |
| Full Cycle | ✅ PASS — Deploy→Explore→Collect→Return |

**Tester Feedback**:
- Movement responsive and intuitive
- Collision blocking works correctly
- Resource collection instant and satisfying
- Full cycle flow easy to understand

---

## Prototype Validation Checklist

- [x] Game launches without crash
- [x] All autoloads initialize (GlobalSignals, databases, systems)
- [x] HUD displays correctly
- [x] Deploy hint visible
- [x] Vehicle spawns and moves
- [x] Collision blocking functional
- [x] Slow zones reduce speed
- [x] Resource drops collect correctly
- [x] Day/night transitions visible
- [x] Return flow works
- [x] Summary panel displays
- [x] Full cycle complete

---

## Issues Resolved During Testing

| Issue | Severity | Resolution |
|-------|----------|------------|
| Scene file comments blocking load | BLOCKING | Removed `#` from .tscn files |
| `is_key_pressed` API error | BLOCKING | Fixed to `InputEventKey.keycode` |
| Day/night visual not visible | Minor | Increased alpha, fixed CanvasLayer layer |
| `PackedVector2Array` constructor | BLOCKING | Use Vector2 array format |

---

## Known Limitations (Acceptable for Prototype)

1. **Placeholder Visuals**: Colored rectangles for vehicle and obstacles
   - Not final art, acceptable for MVP prototype

2. **No Audio**: Visual feedback only
   - Audio systems deferred to later sprint

3. **No Combat**: Enemies not present
   - Combat systems in separate epic

4. **Instant Day/Night Switch**: No gradual transition
   - T key cycles instantly for testing

---

## Conclusion

**Vertical Slice Prototype: ✅ VALIDATED**

The core loop is functional, responsive, and understandable. Human playtest confirms:
- Movement feels good
- Collision mechanics work
- Resource collection satisfying
- Cycle flow intuitive

**Recommendation**: Gate-check for Pre-Production → Production transition.