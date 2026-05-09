# Systems Index: 深海堡垒 (Deep Sea Fortress)

> **Status**: In Design
> **Created**: 2026-05-08
> **Last Updated**: 2026-05-08
> **Source Concept**: design/gdd/game-concept.md
> **Engine**: Godot 4.6
> **Perspective**: 横向2D (Terraria-style)

---

## Overview

深海堡垒是一款移动海上堡垒生存游戏。核心循环为：**航行 → 探索 → 建造 → 防守 → 下一海域**。独特卖点：移动基地、四层立体防线、船+潜艇双载体、搜打撤闭环。

**游戏支柱**：
- Pillar 1: 移动基地 — 堡垒本身在航行，不是固定点位
- Pillar 2: 立体防守 — 天空+水面+水下+内部四层防线
- Pillar 3: 搜打撤闭环 — 潜艇下潜探索海底，收集资源回船建造
- Pillar 4: 动态世界 — 海域持续移动，每次探索新地图

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | 操控系统 | Core | P0 | Designed | design/gdd/深海堡垒-操控系统.md | 无 |
| 2 | 战斗系统 | Core | P0 | Designed | design/gdd/深海堡垒-战斗系统.md | 操控系统 |
| 3 | 波次防守系统 | Gameplay | P0 | Designed | design/gdd/深海堡垒-波次防守系统.md | 战斗系统 + 敌人AI |
| 4 | 资源采集系统 | Gameplay | P0 | Designed | design/gdd/深海堡垒-资源采集系统.md | 操控系统 |
| 5 | 关卡布局系统 | Gameplay | P0 | Designed | design/gdd/深海堡垒-关卡布局系统.md | 无 |
| 6 | 敌人AI系统 | Gameplay | P0 | Designed | design/gdd/深海堡垒-敌人AI系统.md | 无 |
| 7 | 氧气能源系统 | Gameplay | P1 | Designed | design/gdd/深海堡垒-氧气能源系统.md | 资源采集系统 |
| 8 | 船只损伤修复系统 | Gameplay | P1 | Designed | design/gdd/深海堡垒-船只损伤修复系统.md | 战斗系统 |
| 9 | 物品系统 | Gameplay | P1 | Designed | design/gdd/深海堡垒-物品系统.md | 资源采集系统 |
| 10 | Boss战斗详细设计 | Feature | P1 | Designed | design/gdd/深海堡垒-Boss战斗详细设计.md | 战斗系统 + 敌人AI |
| 11 | 难度曲线设计 | Feature | P1 | Designed | design/gdd/深海堡垒-难度曲线设计.md | 波次防守 + Boss战斗 |
| 12 | 玩家成长系统 | Meta | P1 | Designed | design/gdd/深海堡垒-玩家成长系统.md | 资源采集 + 战斗系统 |
| 13 | 存档系统 | Meta | P1 | Designed | design/gdd/深海堡垒-存档系统.md | 无 |
| 14 | UI系统 | Presentation | P1 | Designed | design/gdd/深海堡垒-UI系统.md | 无 |
| 15 | 新手教程系统 | Presentation | P1 | Designed | design/gdd/深海堡垒-新手教程系统.md | 操控 + 战斗 + 资源采集 |
| 16 | 主菜单与Loading界面 | Presentation | P1 | Designed | design/gdd/深海堡垒-主菜单与Loading界面.md | UI系统 |
| 17 | 日夜循环系统 | Feature | P2 | Designed | design/gdd/深海堡垒-日夜循环系统.md | 时间系统 |
| 18 | 导航地图系统 | Feature | P2 | Designed | design/gdd/深海堡垒-导航地图系统.md | 关卡布局系统 |
| 19 | 怪物进化系统 | Feature | P2 | Designed | design/gdd/深海堡垒-怪物进化系统.md | 敌人AI系统 |
| 20 | 门锁系统 | Gameplay | P2 | Designed | design/gdd/深海堡垒-门锁系统.md | 关卡布局系统 |
| 21 | 船员系统(极简版) | Feature | P1 | Designed | design/gdd/深海堡垒-船员系统(极简版).md | 氧气能源系统 |
| 22 | 任务系统 | Feature | P2 | Designed | design/gdd/深海堡垒-任务系统.md | 玩家成长系统 |
| 23 | NPC系统 | Feature | P2 | Designed | design/gdd/深海堡垒-NPC系统.md | 经济系统 |
| 24 | 经济系统 | Meta | P2 | Designed | design/gdd/深海堡垒-经济系统.md | 物品系统 |
| 25 | 剧情系统设计 | Meta | P2 | Designed | design/gdd/深海堡垒-剧情系统设计.md | 任务系统 |
| 26 | 结局系统设计 | Meta | P2 | Designed | design/gdd/深海堡垒-结局系统设计.md | 剧情系统 |
| 27 | 音效系统 | Presentation | P2 | Designed | design/gdd/深海堡垒-音效系统.md | 战斗系统 |
| 28 | 设置菜单系统 | Presentation | P2 | Designed | design/gdd/深海堡垒-设置菜单系统.md | UI系统 |
| 29 | 实现补充内容 | Core | P1 | Designed | design/gdd/深海堡垒-实现补充内容.md | 无 |
| 30 | 发布准备 | Meta | P3 | Designed | design/gdd/深海堡垒-发布准备.md | 所有系统 |

## Balance & Reference Docs

| Document | Location | Purpose |
|----------|----------|---------|
| 怪物百科 | design/balance/深海堡垒-怪物百科.md | 敌人数据表 |
| 怪物百科-生化魔幻类 | design/balance/深海堡垒-怪物百科-生化魔幻类.md | 生化魔幻类敌人 |
| 怪物AI映射表 | docs/references/深海堡垒-怪物AI映射表.md | AI到怪物映射 |
| 物品经济属性表 | docs/references/深海堡垒-物品经济属性表.md | 物品经济数值 |
| NPC船员衔接规则 | docs/references/深海堡垒-NPC船员衔接规则.md | NPC与船员衔接 |

## Level & Scene Docs

| Document | Location | Purpose |
|----------|----------|---------|
| 关卡场景设计 | design/levels/深海堡垒-关卡场景设计.md | 关卡布局与房间 |
| 场景开发详细方案 | design/levels/深海堡垒-场景开发详细方案.md | 场景开发指南 |
| 素材制作指南 | design/levels/深海堡垒-素材制作指南.md | 美术素材规范 |

## Review Reports

| Report | Location |
|--------|----------|
| 第1-5轮审查 | design/reviews/ (5份审查报告) |

---

## Categories

| Category | Description | Systems |
|----------|-------------|---------|
| **Core** | 操控、战斗、输入基础 | 操控系统、战斗系统、实现补充内容 |
| **Gameplay** | 核心玩法循环系统 | 波次防守、资源采集、关卡布局、敌人AI、氧气能源、船只损伤、物品、门锁 |
| **Feature** | 扩展功能系统 | Boss战斗、难度曲线、日夜循环、导航地图、怪物进化、船员、任务、NPC |
| **Presentation** | UI、音效、菜单 | UI系统、音效系统、设置菜单、新手教程、主菜单 |
| **Meta** | 进度、存档、经济、叙事 | 玩家成长、经济系统、存档系统、剧情、结局、发布准备 |

---

## Recommended Design Order (for GDD format migration)

| Order | System | Priority | Category |
|-------|--------|----------|----------|
| 1 | 操控系统 | P0 | Core |
| 2 | 战斗系统 | P0 | Core |
| 3 | 资源采集系统 | P0 | Gameplay |
| 4 | 敌人AI系统 | P0 | Gameplay |
| 5 | 波次防守系统 | P0 | Gameplay |
| 6 | 关卡布局系统 | P0 | Gameplay |
| 7 | 氧气能源系统 | P1 | Gameplay |
| 8 | 船只损伤修复系统 | P1 | Gameplay |
| 9 | 物品系统 | P1 | Gameplay |
| 10 | UI系统 | P1 | Presentation |

---

## Circular Dependencies

- **None found** — 所有依赖关系均为单向（Core → Gameplay → Feature → Presentation → Meta）

---

## Progress Tracker

| Metric | Count |
|-------|-------|
| Total systems identified | 30 |
| Design docs migrated | 30/30 |
| Format-compliant (8 sections) | 0/30 (需格式转换) |
| Balance docs | 2 |
| Reference docs | 3 |
| Level docs | 3 |
| Review reports | 5 |

---

## Next Steps

- [ ] Run `/adopt full` — audit GDD format compliance (all 30 docs need 8-section format)
- [ ] Migrate GDDs to standard format using `/design-system retrofit`
- [ ] Run `/create-architecture` — bootstrap architecture from existing design docs
- [ ] Run `/map-systems` — if systems-index needs refinement
- [ ] Set review mode in `production/review-mode.txt`
