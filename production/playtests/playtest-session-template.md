# Playtest Session Template — Polish Phase

**Date**: [DATE]
**Player ID**: [ID]
**Experience Level**: [New/Mid/Hardcore]
**Session Duration**: [minutes]

---

## Pre-Session Checklist

- [ ] Build stable (smoke check PASS)
- [ ] Performance profiling PASS (frame budget OK)
- [ ] Playtest device ready (PC + KB/Mouse + optional Gamepad)
- [ ] Recording setup (screen capture + notes)

---

## Session Goals

验证以下核心假设：
1. **难度曲线可预测性**: 玩家是否感知威胁升级有预警信号？
2. **双阵营解锁节奏**: Day 6 地狱阵营解锁是否产生明显压力递增？
3. **失败归因清晰**: 失败时玩家是否能判断原因（而非"突然变难"）？

---

## Playtest Flow

### Phase 1: Learning Period (Day 1-5)

**观察点**:
- [ ] 玩家是否理解基础操作（战车驾驶、挖掘、建造）
- [ ] 第一次尸潮 (Day 2) 是否有足够时间学习防御策略
- [ ] 第一次看到"骨骼骷髅"(Day 3) 是否识别为"拆墙威胁"

**记录**: 
- 学习时间: [minutes]
- 第一次尸潮应对: [成功/失败]
- 预警信号识别: [清晰/模糊/未注意到]

---

### Phase 2: Pressure Increase (Day 6-10)

**观察点**:
- [ ] 地狱阵营解锁 (Day 6) 是否被玩家感知为"新威胁"
- [ ] 玩家是否调整策略应对快速敌人
- [ ] 资源管理是否成为关注点

**记录**:
- 新阵营识别: [立即/延迟/未注意]
- 策略调整: [主动/被动/未调整]
- 资源紧张感: [明显/轻微/无感]

---

### Phase 3: Crisis Period (Day 11-15) [Optional — if time permits]

**观察点**:
- [ ] 多阵营混合是否产生"混乱"或"挑战"感
- [ ] Elite/Boss 出现是否被优先处理
- [ ] 防守失败是否触发"撤退优化"思考

**记录**:
- 多阵营混合感受: [挑战/混乱/无感]
- Elite/Boss 处理: [优先/忽略/被动]
- 失败归因: [清晰/模糊/挫败]

---

## Post-Session Interview

### 难度感知问题

1. "你觉得难度是突然增加还是逐渐递增？"
   - [ ] 逐渐递增，有预警
   - [ ] 有一些跳跃，但可理解
   - [ ] 突然变难，无法适应

2. "新敌人出现时，你能从外观判断其威胁类型吗？"
   - [ ] 能，视觉特征清晰
   - [ ] 大部分能
   - [ ] 不能，需要试错

3. "失败时，你能否判断原因是什么？"
   - [ ] 能，策略没跟上
   - [ ] 大概能
   - [ ] 不能，感觉突然崩溃

### 核心循环问题

4. "搜打撤节奏是否自然形成？"
   - [ ] 是，学会了判断撤退时机
   - [ ] 大部分时间能判断
   - [ ] 否，经常贪战或过早撤退

5. "尸潮防守是否成为'高潮'而非负担？"
   - [ ] 是，期待尸潮来临
   - [ ] 中等，紧张但有趣
   - [ ] 否，感觉压力过大

---

## Tuning Knob Recommendations

基于本次 session，建议调整：

| Knob | Current | Recommended | Reason |
|------|---------|-------------|--------|
| BASE_SPAWN_COUNT | 10 | [value] | [reason] |
| TIDE_GROWTH_RATE | 2.0 | [value] | [reason] |
| PHASE1_CAP | 1.2 | [value] | [reason] |
| DANGER_GLOBAL_MULT | 1.0 | [value] | [reason] |

---

## Summary

**总体评价**: [Excellent/Good/Needs Work/Failed]

**核心问题**: [描述最大问题]

**优先修复**: [描述最需要调整的内容]

**可保留**: [描述体验良好的内容]

---

## Next Action

- [ ] Update difficulty-curve.md tuning knobs
- [ ] Log bugs in production/qa/bugs/
- [ ] Schedule follow-up session if needed

---

*Session template for Polish phase playtest expansion.*