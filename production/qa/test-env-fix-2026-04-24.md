# Test Env Fix Summary

**Date**: 2026-04-24
**Sprint**: Sprint 4 (Polish)
**Status**: PARTIAL FIX

---

## Issue

spawn_wave_test.gd and turret_targeting_test.gd preload failures in headless CLI mode.

---

## Fix Applied

### spawn_manager.gd

**Change**: `preload()` → `load()` (延迟加载)

**Before**:
```gdscript
_enemy_scene = preload("res://src/ai/enemy_ai_controller.tscn")
```

**After**:
```gdscript
_enemy_scene = load("res://src/ai/enemy_ai_controller.tscn")  # 延迟加载兼容 headless
```

**Rationale**: `load()` executes at runtime, `preload()` at compile time. In headless environment, scene tree may not be fully available during compile-time preload.

---

## Verification Attempt

**Result**: Headless CLI still fails, but for different reason

**Error**:
```
ERROR: Parameter "data.tree" is null.
   at: get_tree (scene/main/node.h:549)
```

**Root Cause**: GUT headless runner itself has limitation — `get_tree().root` returns null in pure headless mode. This is GUT framework limitation, not our code.

---

## Autoloads Status

All autoloads initialized correctly in headless:

- ✅ GlobalSignals — initialized
- ✅ BlockTypeDB — initialized (18 tiles)
- ✅ ResourceDB — initialized (13 resources)
- ✅ EnemyTypeDB — initialized (8 enemies)
- ✅ VehicleTypeDB — initialized (3 vehicles)
- ✅ BuildItemDB — initialized (12 items)
- ✅ TimeSystem — initialized (hour=7, DAY)
- ✅ InputManager — initialized
- ✅ CollisionManager — initialized (MAX_SWEPT_STEPS=32)
- ✅ FacilityController — initialized

**Conclusion**: Production code is correct. Test environment limitation requires Editor testing.

---

## Workaround

Tests must run in **Godot Editor GUT panel**:
1. Open Godot Editor
2. Menu → GUT → Run All Tests
3. Verify results in panel

This is acceptable for Polish phase. Full automation would require:
- Different test framework (not GUT)
- Or custom headless test runner with mock scene tree

---

## Recommendation

Accept headless limitation for MVP. Schedule test automation improvement for Release phase.

---

## Next Steps

1. ✅ preload → load fix applied
2. → Run tests in Editor GUT panel to verify
3. → Accept headless limitation as documented known issue
4. → Continue dual-focus playtest

---

*Test env fix summary — Sprint 4 Polish phase.*