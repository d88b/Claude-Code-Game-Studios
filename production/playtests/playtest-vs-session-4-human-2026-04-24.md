# Playtest Session 4 — Human Editor Playtest

**Date**: 2026-04-24
**Session Type**: Human Editor Playtest — Vertical Slice MVP
**Tester**: Developer
**Duration**: ~10 minutes
**Build**: `playable_main_game.tscn`

---

## Test Environment

- **Engine**: Godot Engine v4.6.1.stable.official.14d19694e
- **Renderer**: Vulkan 1.3.277 - Forward+
- **Device**: NVIDIA GeForce RTX 3070 Laptop GPU
- **Scene**: `src/playable_main_game.tscn`

---

## Core Loop Test Results

| Test Step | Expected | Actual | Result |
|-----------|----------|--------|--------|
| 1. Game Launch | Scene loads, HUD visible | ✅ All systems initialized | **PASS** |
| 2. Grid Background | Checkerboard pattern visible | ✅ 20x11 cells (220 total) | **PASS** |
| 3. SPACE Deploy | Vehicle spawns at (320, 320) | ✅ Blue vehicle appears | **PASS** |
| 4. WASD Movement | Vehicle moves smoothly | ✅ 400.0 speed, responsive | **PASS** |
| 5. Camera Follow | Camera tracks vehicle | ✅ Smooth follow enabled | **PASS** |
| 6. Position Display | HUD shows coordinates | ✅ Updates in real-time | **PASS** |

---

## Collision System Test

### Block Obstacles (Red — Physical Blocking)

| Test | Expected | Actual | Result |
|------|----------|--------|--------|
| 5 obstacles initialized | 5 red squares | ✅ All at correct positions | **PASS** |
| Collision detection | Vehicle blocked, cannot pass | ✅ move_and_slide() blocks | **PASS** |
| Bounce/stop behavior | Physical stop | ✅ Cannot pass through | **PASS** |

### Slow Zones (Yellow — Speed Reduction)

| Test | Expected | Actual | Result |
|------|----------|--------|--------|
| 5 zones initialized | 5 yellow semi-transparent squares | ✅ All visible | **PASS** |
| Enter zone | Speed drops to 30% | ✅ Console logs entry | **PASS** |
| Movement in zone | Slower but passable | ✅ Can traverse | **PASS** |
| Exit zone | Speed returns to 100% | ✅ Console logs exit | **PASS** |

---

## Day/Night Cycle Test

| Test | Expected | Actual | Result |
|------|----------|--------|--------|
| T key cycle | Phase changes on each press | ✅ 黄昏→夜晚→黎明→白天 | **PASS** |
| Dusk visual | Orange-red overlay | ✅ Color (0.8, 0.4, 0.3, 0.35) | **PASS** |
| Night visual | Dark blue overlay | ✅ Color (0.1, 0.15, 0.3, 0.5) | **PASS** |
| Dawn visual | Orange overlay | ✅ Color (0.9, 0.6, 0.4, 0.25) | **PASS** |
| Day visual | No overlay (normal) | ✅ Color (1, 1, 1, 0) | **PASS** |
| HUD phase label | Updates with phase | ✅ 黎明/白天/黄昏/夜晚 | **PASS** |

---

## Resource Collection Test

| Test | Expected | Actual | Result |
|------|----------|--------|--------|
| 6 drops spawned | 6 colored squares | ✅ Different colors by type | **PASS** |
| Contact triggers collect | Drop disappears | ✅ queue_free() on contact | **PASS** |
| HUD updates | Total increases | ✅ "收集:" shows total | **PASS** |
| Console logs | Collection logged | ✅ [ResourceDrop] outputs | **PASS** |

**Resources Collected in Test**:
- Type 0 (木材/Green): Multiple pickups
- Type 1 (石头/Gray): Pickup confirmed
- Type 2 (铁矿/Brass): Pickup confirmed
- Type 3 (水晶/Light Blue): Pickup confirmed
- Type 4 (魔能碎片/Pink): Pickup confirmed

---

## Full Cycle Test

| Step | Expected | Actual | Result |
|------|----------|--------|--------|
| BUNKER state | HUD shows "BUNKER", [SPACE] hint | ✅ | **PASS** |
| Deploy (SPACE) | Vehicle spawns, state→EXPLORING | ✅ | **PASS** |
| Explore phase | WASD movement, collect resources | ✅ | **PASS** |
| Return (R) | Vehicle removed, summary shown | ✅ | **PASS** |
| SUMMARY panel | Shows collected resources | ✅ Panel displayed | **PASS** |
| Reset (SPACE) | Returns to BUNKER state | ✅ Ready for next cycle | **PASS** |

---

## Issues Found

| Issue | Severity | Status | Resolution |
|-------|----------|--------|------------|
| Scene file comments | BLOCKING | ✅ FIXED | Removed `#` comments from .tscn files |
| is_key_pressed API error | BLOCKING | ✅ FIXED | Changed to `InputEventKey.keycode` |
| Day/night visual subtle | Minor | ✅ FIXED | Increased alpha, fixed CanvasLayer layer |
| ResourceDrop PackedVector2Array | BLOCKING | ✅ FIXED | Use Vector2 array constructor |

---

## Tester Observations

### Positive
- Movement feels responsive at 400 speed
- Collision blocking works correctly (can't pass red obstacles)
- Slow zones clearly slow movement but allow passage
- Day/night color transitions visible after fixes
- Resource collection instant and satisfying
- Full cycle flow intuitive (SPACE deploy → explore → R return → SPACE restart)

### Areas for Improvement
- Day/night transition could be smoother (currently instant switch)
- No audio feedback for collection (visual only)
- No damage/combat testing yet (enemies not present)
- Summary panel could show more stats (time spent, distance traveled)

---

## Verdict: PASS

**Core Loop**: Fully functional from deploy → explore → collect → return → summary
**Visual Systems**: All working after fixes
**Physics**: Collision blocking and slow zones correct
**Signals**: GlobalSignals resource collection flow working

**Recommendation**: Vertical Slice is **playable and functional**. Ready for gate-check validation.

---

## Console Output (Selected)

```
[GlobalSignals] Event bus initialized — 20+ signals defined
[BlockTypeDB] initialized with tile_count=18
[ResourceDB] initialized with resource_count=13
...
[GridBackground] Generated 20x11 cells (220 total)
[BlockObstacle] 阻挡障碍物初始化 at position: (512.0, 320.0)
...
[SlowZone] 减速区域初始化 at position: (512.0, 512.0)
...
[GameState] Initialized — press SPACE to deploy
[DayNightCycle] initialized — current_phase=白天
[SimpleHUD] Initialized
[GameState] State changed: 0 -> 1
[PhysicsVehicle] Ready — move_speed=400.0
[GameState] State changed: 1 -> 2
[GameState] Vehicle deployed at position: (320.0, 320.0)
[Vehicle] 进入减速区域 — 速度降低到30%
[Vehicle] 退出减速区域 — 恢复正常速度
[DayNightVisual] 阶段变化: 黄昏 目标颜色: (0.9, 0.4, 0.2, 0.35)
[Test] 日夜阶段切换: 黄昏
...
[ResourceDrop] 收集资源 — type=X qty=Y
...
--- Debugging process stopped ---
```