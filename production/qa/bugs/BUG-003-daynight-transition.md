# BUG-003: Day/Night Transition Smoothness

**ID**: BUG-003
**Severity**: P4 (Polish)
**Story**: vfx-001
**Found**: 2026-04-24 (Playtest Expansion)
**Status**: Fixed

---

## Description

日夜阶段过渡不够平滑，玩家感知切换有"跳跃感"而非渐变。

**Root Cause**:
- 过渡时间 (30 game seconds) 可能过短
- 颜色插值不够平滑

---

## Reproduction Steps

1. 游戏运行，观察 DAWN → DAY 过渡
2. 观察 DAY → DUSK 过渡
3. 观察 DUSK → NIGHT 过渡

**Expected**: 平滑渐变，无明显跳跃感
**Actual**: 颜色切换有可见跳跃

---

## Fix Recommendation

1. 增加过渡时间 (30 → 45 game seconds)
2. 使用 smoother easing function (ease-in-out)
3. 添加渐变粒子效果增强过渡感

---

## Resolution

**Applied Fix**: TRANSITION_DURATION adjusted from 30 → 45 game seconds
**File Modified**: `src/daynight/day_night_cycle.gd:17`

---

## Acceptance Criteria

- [x] 过渡时间调整为 45 game seconds
- [ ] 使用 ease-in-out interpolation (deferred to visual polish)
- [ ] 3/3 玩家报告过渡平滑 (pending playtest verification)

---

## Priority Assessment

P4 — Visual polish，不阻塞发布。可在 Polish phase 或 Release phase 解决。

---

## Owner

technical-artist