# BUG-001: Elite Priority Targeting Signal

**ID**: BUG-001
**Severity**: P3 (Minor)
**Story**: playtest-expansion
**Found**: 2026-04-24 (Playtest Session 5/7)
**Status**: Open

---

## Description

玩家在 Day 10 Elite (骨甲骑士) 出现时，未识别为优先处理目标。1/3 玩家错过 Elite 信号，导致防线被拆墙攻击突破。

**Root Cause**: 
- Elite 发光标识不够明显
- 无明确的 "Elite 出现" UI 警告

---

## Reproduction Steps

1. 游戏进行到 Day 10
2. Elite 级敌人 (graveyard_bone_knight) 生成
3. 观察玩家是否识别并优先处理

**Expected**: 玩家立即识别 Elite 并调整火力优先级
**Actual**: 1/3 玩家未注意到 Elite，继续攻击 Basic 级敌人

---

## Fix Recommendation

1. **Visual**: 增强 Elite 发光强度 (腐烂绿 → 更强脉动)
2. **UI**: 添加 "Elite 出现" 警告提示 (HUD 闪烁 + 图标)
3. **Audio**: 添加 Elite 专属生成音效

---

## Acceptance Criteria

- [ ] Elite 发光标识更明显 (发光强度 ×1.5)
- [ ] HUD 显示 "Elite 警告" (3秒闪烁)
- [ ] 3/3 玩家识别 Elite 并优先处理

---

## Priority Assessment

P3 — 不阻塞发布，但影响难度曲线体验清晰度。建议在 Polish phase 解决。

---

## Owner

technical-artist + ui-programmer