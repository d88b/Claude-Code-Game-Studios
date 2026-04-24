# Story 001: Dual-focus Playtest

> **Epic**: Integration Validation
> **Status**: Backlog
> **Layer**: Polish
> **Type**: Integration
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/systems-index.md` (核心循环定义)
**Requirement**: 核心循环验证 — 搜打撤 ↔ 返回建设 两个焦点切换体验

**游戏核心循环**:
```
外出探索 → 搜打撤 → 返回建设 → 种田生产 → 尸潮防守 → 继续探索
```

**双焦点定义**:
- **探索焦点**: 战车驾驶 + 敌人战斗 + 资源搜刮 + 撤退决策
- **建设焦点**: 基地挖掘 + 设施建造 + 炮塔防御 + 种田生产

**ADR Governing Implementation**: 无 (playtest story)
**Engine**: Godot 4.6 | **Risk**: MEDIUM (设计验证风险)

---

## Acceptance Criteria

- [ ] 探索焦点 → 建设焦点切换流畅，玩家明确感知"回到基地"
- [ ] 建设焦点 → 探索焦点切换有明确触发（如"尸潮结束"或"资源不足"）
- [ ] 两个焦点各有独立的核心目标，不相互干扰焦点状态
- [ ] 紧张感在探索焦点上升，在建设焦点释放/转化为生产力
- [ ] 焦点切换频率符合设计预期（约 5-10 分钟一个探索周期）
- [ ] 玩家在焦点切换时不感到"失去进度"或"节奏断裂"
- [ ] 撤退决策在探索焦点内有足够时间窗口，不被迫打断建设进度

---

## Playtest Protocol

### Session Setup
- **Target player**: 新玩家 + 有策略游戏经验的玩家
- **Session length**: 30 分钟
- **Playtest type**: 焦点切换体验验证
- **Min sessions**: 2 (每种玩家类型各 1)

### Observation Checklist
- 玩家是否在探索时有明确目标感（资源目标 + 撤退窗口）
- 玩家是否在建设时有明确目标感（设施需求 + 防御准备）
- 焦点切换时玩家是否有短暂的困惑或迷失
- 玩家是否自发表达"紧张 → 放松"的节奏变化
- 玩家是否抱怨"节奏太快"或"节奏太慢"

### Questions to Ask
- "你觉得什么时候应该回到基地？"
- "建设基地时，你是否想着下次探索要做什么？"
- "探索时，你是否担心基地的安全？"
- "两个玩法之间切换，你的感觉是？"

---

## Test Evidence

**Type**: Integration (Playtest)
**Required**: `production/playtests/dual-focus-playtest-sprint-3.md`
**Status**: [ ] Not yet created

**Evidence to capture**:
- Playtest session notes (观察 checklist 填写)
- 玩家回答记录
- 录屏片段（焦点切换时刻）
- Designer/QA-lead sign-off

---

## Dependencies

- Depends on: vehicle-001 (战车属性), enemy-001 (敌人AI), weapon-001 (武器系统)
- Depends on: buildvalid-001 (建造验证), facility-001 (设施系统) — 建议
- Enables: Sprint 4 完整循环验证

---

## Notes

此 story 是 Sprint 3 的 nice-to-have，作为早期验证点。完整的双焦点体验验证需要：
- 尸潮防守系统 (Defense 层)
- 种田系统 (Eco 层)
- 撤退后果系统 (Explore 层)

当前 Sprint 3 仅实现探索焦点核心 + 建设焦点基础，此 playtest 验证的是 **最小焦点切换** 体验：
- 战车驾驶 → 基地挖掘
- 敌人战斗 → 炮塔防御

---

## Schedule

- **Trigger**: vehicle-001, enemy-001, weapon-001 完成后
- **Duration**: 1 天 (playtest + 分析)
- **Owner**: qa-lead