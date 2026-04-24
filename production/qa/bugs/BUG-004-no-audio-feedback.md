# BUG-004: No Audio Feedback

**ID**: BUG-004
**Severity**: P4 (Polish)
**Story**: audio-001
**Found**: 2026-04-24 (Playtest Expansion)
**Status**: Open

---

## Description

游戏目前无音频反馈：无音效、无环境音、无 UI 音效。玩家体验缺少听觉维度。

**Root Cause**:
- Audio 系统未实现 (design-only stage)
- 当前 Vertical Slice 为纯视觉体验

---

## Reproduction Steps

1. 游戏运行任何场景
2. 观察 — 无任何音效

**Expected**: 有基础音效反馈
**Actual**: 完全静音

---

## Fix Recommendation

**Minimum Viable Audio** (Polish phase):
1. 射击音效 (武器)
2. 碰撞音效 (战车)
3. 资源收集音效 (拾取)
4. 日夜阶段环境音变化

**Full Audio** (Release phase):
1. 阵营专属敌人音效
2. 背景音乐循环
3. UI 点击音效

---

## Acceptance Criteria

- [ ] 武器射击音效添加
- [ ] 战车碰撞音效添加
- [ ] 资源收集音效添加
- [ ] 日夜阶段环境音变化

---

## Priority Assessment

P4 — Audio polish，不阻塞发布。可在 Polish phase 实现 minimum viable audio。

---

## Owner

sound-designer