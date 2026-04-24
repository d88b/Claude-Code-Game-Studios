# Systems Index: 铁锈魔潮 (Rust Magic Tide)

> **Status**: Approved
> **Created**: 2026-04-22
> **Last Updated**: 2026-04-22
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

铁锈魔潮是一款融合了战车探索、挖掘建造、堡垒生态、尸潮防守的2D横版末世生存游戏。核心循环为：**搜打撤 → 返回建设 → 种田生产 → 尸潮防守 → 继续探索**。这是一个完美的生态闭环：

1. **外出探索**：驾驶战车搜刮资源（魔力晶石、秘银、食物）
2. **返回建设**：挖掘扩展地堡、建造防御设施、建造生态设施
3. **种田生产**：雨水收集灌溉、作物种植、食物储备
4. **尸潮防守**：所有建设成果的考验
5. **继续循环**：防守成功 → 更强探索 → 更好建设

**游戏支柱约束**：
- Pillar 1: 战车即生命 — 所有探索系统必须强化战车的必要性
- Pillar 2: 搜打撤节奏 — 所有时间/撤退系统必须创造紧张决策
- Pillar 3: 尸潮即高潮 — 所有防守系统必须有真实压力和后果
- Pillar 4: 魔导科技美学 — 所有科技系统必须融合赛博朋克魔导风格

**堡垒生态闭环设计**：
- 天气系统 → 雨水收集 → 种田灌溉 → 作物生产 → 食物储备 → 探索动力
- 搜刮资源 → 建造扩建 → 防御设施 → 尸潮防守 → 成功奖励 → 继续探索

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | TileMap世界系统 | World | MVP | Designed | design/gdd/tilemap-world-system.md | 无 |
| 2 | 方块类型数据库 | World | MVP | Designed | design/gdd/block-type-database.md | 无 |
| 3 | 资源数据库 | Economy | MVP | Designed | design/gdd/resource-database.md | 无 |
| 4 | 敌人类型数据库 | Combat | MVP | Designed | design/gdd/enemy-type-database.md | 无 |
| 5 | 建造物品数据库 | Build | MVP | Designed | design/gdd/build-item-database.md | 无 |
| 6 | 战车类型数据库 | Vehicle | MVP | Designed | design/gdd/vehicle-type-database.md | 无 |
| 7 | 搜刮容器数据库 | Explore | MVP | Designed | design/gdd/scavenge-container-database.md | 无 |
| 8 | 时间系统 | World | MVP | Designed | design/gdd/time-system.md | 无 |
| 9 | 输入控制系统 | Core | MVP | Designed | design/gdd/input-control-system.md | 无 |
| 10 | 摄像机系统 | Core | Full Vision | Not Started | — | 无 |
| 11 | 方块碰撞系统 | World | MVP | Approved | design/gdd/block-collision-system.md | TileMap世界系统 |
| 12 | 方块挖掘系统 | Build | MVP | Approved | design/gdd/block-digging-system.md | TileMap世界 + 方块类型数据库 + 输入控制 |
| 13 | 方块放置系统 | Build | MVP | Approved | design/gdd/block-placing-system.md | TileMap世界 + 建造物品数据库 + 建造验证 + 方块碰撞 |
| 14 | 资源掉落系统 | Economy | MVP | Designed | design/gdd/resource-drop-system.md | 方块类型数据库 + 资源数据库 |
| 15 | 日夜循环系统 | World | MVP | Designed | design/gdd/day-night-cycle-system.md | 时间系统 |
| 16 | 天气系统 | World | Vertical Slice | Not Started | — | 时间系统 |
| 17 | 战车属性系统 | Vehicle | MVP | Designed | design/gdd/vehicle-attribute-system.md | 战车类型数据库 |
| 18 | 战车驾驶系统 | Vehicle | MVP | Designed | design/gdd/vehicle-driving-system.md | 战车属性 + 输入控制 + TileMap世界 |
| 19 | 魔能消耗计算 | Vehicle | MVP | Designed | design/gdd/magic-energy-consumption.md | 战车属性系统 |
| 20 | 战车武器系统 | Vehicle | MVP | Designed | design/gdd/vehicle-weapon-system.md | 战车属性 + 资源数据库 |
| 21 | 战车损坏系统 | Vehicle | MVP | Designed | design/gdd/vehicle-damage-system.md | 战车属性系统 |
| 22 | 战车维修系统 | Vehicle | Vertical Slice | Not Started | — | 战车属性 + 资源数据库 + 战车仓库 |
| 23 | 战车改装系统 | Vehicle | Vertical Slice | Not Started | — | 战车属性系统 |
| 24 | 战车瘫痪处理 | Vehicle | Vertical Slice | Not Started | — | 战车属性 + 战车损坏 + 魔能消耗 |
| 25 | 战车回收系统 | Vehicle | Alpha | Not Started | — | 撤退后果 + 多战车管理 + 战车仓库 |
| 26 | 多战车管理 | Vehicle | Alpha | Not Started | — | 战车属性 + 战车瘫痪处理 + 战车仓库 |
| 27 | 探索区域系统 | Explore | MVP | Designed | design/gdd/exploration-area-system.md | TileMap世界系统 |
| 28 | 玩家背包系统 | Explore | Vertical Slice | Not Started | — | 资源数据库 |
| 29 | 战车仓库系统 | Explore | Vertical Slice | Not Started | — | 资源数据库 |
| 30 | 下车状态系统 | Explore | Vertical Slice | Not Started | — | 玩家背包系统 |
| 31 | 搜刮交互系统 | Explore | Vertical Slice | Not Started | — | 搜刮容器数据库 + 玩家背包 |
| 32 | 撤退判定系统 | Explore | MVP | Designed | design/gdd/retreat-judgment-system.md | 时间系统 + 日夜循环 + 战车属性 + 魔能消耗 + 战车损坏 |
| 33 | 撤退后果系统 | Explore | Vertical Slice | Not Started | — | 撤退判定 + 战车瘫痪处理 |
| 34 | 尸潮周期系统 | Defense | Alpha | Not Started | — | 时间系统 |
| 35 | 尸潮规模预估 | Defense | Alpha | Not Started | — | 尸潮周期 + 敌人类型数据库 |
| 36 | 敌人AI系统 | Combat | MVP | Designed | design/gdd/enemy-ai-system.md | 敌人类型数据库 |
| 37 | 敌人生成系统 | Combat | MVP | Designed | design/gdd/enemy-spawn-system.md | 敌人类型数据库 + TileMap世界 + 敌人AI |
| 38 | 炮塔系统 | Defense | MVP | Designed | design/gdd/turret-system.md | 资源数据库 + 建造物品数据库 + TileMap世界 + 敌人AI |
| 39 | 陷阱系统 | Defense | Vertical Slice | Not Started | — | 资源数据库 + 建造物品数据库 + TileMap世界 + 敌人AI |
| 40 | 防守失败梯度 | Defense | Alpha | Not Started | — | 炮塔 + 陷阱 + 地堡设施 + 闸门 |
| 41 | 战斗反馈系统 | Combat | Alpha | Not Started | — | 敌人AI + 炮塔 + 战车武器 |
| 42 | 科技解锁系统 | Progression | Vertical Slice | Not Started | — | 资源数据库 + 阵营科技 |
| 43 | 阵营科技系统 | Progression | Vertical Slice | Not Started | — | 科技解锁系统 |
| 44 | 资源合成系统 | Economy | Vertical Slice | Not Started | — | 资源数据库 + 阵营科技 |
| 45 | 建造验证系统 | Build | MVP | Designed | design/gdd/build-validation-system.md | 方块类型数据库 + 建造物品数据库 + TileMap世界 |
| 46 | 地堡设施系统 | Build | MVP | Designed | design/gdd/bunker-facility-system.md | 建造物品数据库 + 方块放置 + 建造验证 |
| 47 | 闸门系统 | Defense | Alpha | Not Started | — | 建造物品数据库 + 方块放置 + 建造验证 |
| 48 | 地图/废墟生成 | Explore | Alpha | Not Started | — | TileMap世界 + 探索区域 + 搜刮容器数据库 |
| 49 | HUD系统 | UI | Full Vision | Not Started | — | 战车属性 + 战车仓库 + 资源存储 + 时间 + 天气 |
| 50 | 撤退警告UI | UI | Full Vision | Not Started | — | 撤退判定系统 |
| 51 | 天气状态UI | UI | Full Vision | Not Started | — | 天气系统 |
| 52 | 音效系统 | Audio | Full Vision | Not Started | — | 战车驾驶 + 战车武器 + 方块挖掘 + 炮塔 + 敌人AI + 尸潮周期 |
| 53 | Roguelite继承系统 | Persistence | Full Vision | Not Started | — | 科技解锁 + 战车改装 |
| 54 | 存档系统 | Persistence | Full Vision | Not Started | — | Roguelite继承 + 资源存储 + 科技解锁 + 战车改装 |
| 55 | 进度追踪系统 | Meta | Full Vision | Not Started | — | 存档系统 + 科技解锁 |
| 56 | 雨水收集系统 | Eco | MVP | Not Started | — | 天气系统 + 地堡设施 |
| 57 | 种田系统 | Eco | MVP | Not Started | — | 雨水收集系统 + 地堡设施 |
| 58 | 食物/生存系统 | Eco | MVP | Not Started | — | 种田系统 + 资源数据库 |
| 59 | 魔力农场系统 | Eco | MVP | Not Started | — | 种田系统 + 资源数据库 |

---

## Categories

| Category | Description | Typical Systems |
|----------|-------------|-----------------|
| **World** | 地图、方块、时间、天气系统 | TileMap世界、方块类型、时间系统、天气系统 |
| **Vehicle** | 战车相关系统 | 战车属性、战车驾驶、战车损坏、战车改装、多战车管理 |
| **Explore** | 探索、搜刮、撤退系统 | 探索区域、搜刮交互、撤退判定、撤退后果 |
| **Combat** | 敌人、战斗系统 | 敌人AI、敌人生成、战斗反馈 |
| **Defense** | 防守系统 | 炮塔、陷阱、尸潮周期、防守失败梯度 |
| **Build** | 挖掘、建造系统 | 方块挖掘、方块放置、地堡设施、闸门 |
| **Economy** | 资源、合成系统 | 资源数据库、资源掉落、资源合成 |
| **Eco** | 堡垒生态、生存系统 | 雨水收集、种田系统、食物/生存、魔力农场 |
| **Progression** | 科技、解锁系统 | 科技解锁、阵营科技 |
| **Persistence** | 存档、继承系统 | Roguelite继承、存档系统 |
| **UI** | HUD、警告UI系统 | HUD系统、撤退警告UI、天气状态UI |
| **Audio** | 音效系统 | 音效系统 |
| **Meta** | 进度追踪等元系统 | 进度追踪系统 |
| **Core** | 输入、摄像机等基础系统 | 输入控制、摄像机系统 |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Design Urgency |
|------|------------|------------------|----------------|
| **MVP** | 核心循环验证必需。没有这些，无法测试"是否有乐趣？" | 第一可玩原型（12天） | Design FIRST |
| **Vertical Slice** | 完整体验扩展。一个区域的完整演示。 | 垂直切片（28天） | Design SECOND |
| **Alpha** | 所有玩法系统。完整机械范围，占位符内容可接受。 | Alpha里程碑（42天） | Design THIRD |
| **Full Vision** | 打磨、UI、存档等元系统。发布版本。 | Beta / Release | Design as needed |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **TileMap世界系统** — 所有空间操作的基础，方块位置存储、层级管理
2. **方块类型数据库** — 方块属性定义（硬度、资源产出、可建造）
3. **资源数据库** — 资源类型定义（魔力晶石、秘银、奥术碎片等）
4. **敌人类型数据库** — 敌人属性定义（血量、伤害、护甲、速度、阵营）
5. **建造物品数据库** — 建造物品定义（墙体、炮塔、陷阱、设施）
6. **战车类型数据库** — 战车基础属性定义（耐久、护甲、魔能、速度）
7. **搜刮容器数据库** — 容器类型定义（宝箱、废墟、敌人掉落）
8. **时间系统** — 基础时间流逝，是日夜循环、尸潮周期的基础
9. **输入控制系统** — 基础输入，战车驾驶、挖掘、下车行动的桥梁
10. **摄像机系统** — 基础视觉跟随（叶子系统，可延迟）

### Core Layer (depends on foundation)

1. **方块碰撞系统** — depends on: TileMap世界系统
2. **方块挖掘系统** — depends on: TileMap世界 + 方块类型数据库 + 输入控制
3. **方块放置系统** — depends on: TileMap世界 + 建造物品数据库 + 建造验证
4. **资源掉落系统** — depends on: 方块类型数据库 + 资源数据库
5. **日夜循环系统** — depends on: 时间系统
6. **战车属性系统** — depends on: 战车类型数据库
7. **战车驾驶系统** — depends on: 战车属性 + 输入控制 + TileMap世界
8. **魔能消耗计算** — depends on: 战车属性系统
9. **战车武器系统** — depends on: 战车属性 + 资源数据库
10. **战车损坏系统** — depends on: 战车属性系统
11. **探索区域系统** — depends on: TileMap世界系统
12. **敌人AI系统** — depends on: 敌人类型数据库
13. **敌人生成系统** — depends on: 敌人类型数据库 + TileMap世界 + 敌人AI
14. **炮塔系统** — depends on: 资源数据库 + 建造物品数据库 + TileMap世界 + 敌人AI
15. **撤退判定系统** — depends on: 时间系统 + 日夜循环 + 战车属性 + 魔能消耗 + 战车损坏

### Feature Layer (depends on core)

1. **建造验证系统** — depends on: 方块类型数据库 + 建造物品数据库 + TileMap世界
2. **地堡设施系统** — depends on: 建造物品数据库 + 方块放置 + 建造验证
3. **玩家背包系统** — depends on: 资源数据库
4. **战车仓库系统** — depends on: 资源数据库
5. **下车状态系统** — depends on: 玩家背包系统
6. **搜刮交互系统** — depends on: 搜刮容器数据库 + 玩家背包
7. **撤退后果系统** — depends on: 撤退判定 + 战车瘫痪处理
8. **战车瘫痪处理** — depends on: 战车属性 + 战车损坏 + 魔能消耗
9. **战车维修系统** — depends on: 战车属性 + 资源数据库 + 战车仓库
10. **战车改装系统** — depends on: 战车属性系统
11. **陷阱系统** — depends on: 资源数据库 + 建造物品数据库 + TileMap世界 + 敌人AI
12. **天气系统** — depends on: 时间系统
13. **科技解锁系统** — depends on: 资源数据库 + 阵营科技
14. **阵营科技系统** — depends on: 科技解锁系统
15. **资源合成系统** — depends on: 资源数据库 + 阵营科技
16. **多战车管理** — depends on: 战车属性 + 战车瘫痪处理 + 战车仓库
17. **地图/废墟生成** — depends on: TileMap世界 + 探索区域 + 搜刮容器数据库
18. **闸门系统** — depends on: 建造物品数据库 + 方块放置 + 建造验证
19. **雨水收集系统** — depends on: 天气系统 + 地堡设施系统
20. **种田系统** — depends on: 雨水收集系统 + 地堡设施系统
21. **食物/生存系统** — depends on: 种田系统 + 资源数据库
22. **魔力农场系统** — depends on: 种田系统 + 资源数据库

### Presentation Layer (depends on features)

1. **HUD系统** — depends on: 战车属性 + 战车仓库 + 资源存储 + 时间 + 天气
2. **撤退警告UI** — depends on: 撤退判定系统
3. **天气状态UI** — depends on: 天气系统
4. **音效系统** — depends on: 战车驾驶 + 战车武器 + 方块挖掘 + 炮塔 + 敌人AI + 尸潮周期
5. **战斗反馈系统** — depends on: 敌人AI + 炮塔 + 战车武器

### Polish Layer (depends on everything)

1. **尸潮周期系统** — depends on: 时间系统
2. **尸潮规模预估** — depends on: 尸潮周期 + 敌人类型数据库
3. **防守失败梯度** — depends on: 炮塔 + 陷阱 + 地堡设施 + 闸门
4. **战车回收系统** — depends on: 撤退后果 + 多战车管理 + 战车仓库
5. **Roguelite继承系统** — depends on: 科技解锁 + 战车改装
6. **存档系统** — depends on: Roguelite继承 + 资源存储 + 科技解锁 + 战车改装
7. **进度追踪系统** — depends on: 存档系统 + 科技解锁

---

## Recommended Design Order

| Order | System | Priority | Layer | Agent(s) | Est. Effort |
|-------|--------|----------|-------|----------|-------------|
| 1 | TileMap世界系统 | MVP | Foundation | game-designer + technical-director | M |
| 2 | 方块类型数据库 | MVP | Foundation | game-designer | S |
| 3 | 资源数据库 | MVP | Foundation | game-designer | S |
| 4 | 敌人类型数据库 | MVP | Foundation | game-designer | S |
| 5 | 建造物品数据库 | MVP | Foundation | game-designer | S |
| 6 | 战车类型数据库 | MVP | Foundation | game-designer | S |
| 7 | 搜刮容器数据库 | MVP | Foundation | game-designer | S |
| 8 | 时间系统 | MVP | Foundation | game-designer | S |
| 9 | 输入控制系统 | MVP | Foundation | game-designer | S |
| 10 | 方块碰撞系统 | MVP | Core | game-designer + technical-director | S |
| 11 | 方块挖掘系统 | MVP | Core | game-designer | M |
| 12 | 建造验证系统 | MVP | Feature | game-designer | S |
| 13 | 方块放置系统 | MVP | Core | game-designer | M |
| 14 | 资源掉落系统 | MVP | Core | game-designer | S |
| 15 | 日夜循环系统 | MVP | Core | game-designer | S |
| 16 | 战车属性系统 | MVP | Core | game-designer | S |
| 17 | 战车驾驶系统 | MVP | Core | game-designer + technical-director | L |
| 18 | 魔能消耗计算 | MVP | Core | game-designer | S |
| 19 | 战车武器系统 | MVP | Core | game-designer | M |
| 20 | 战车损坏系统 | MVP | Core | game-designer | M |
| 21 | 敌人AI系统 | MVP | Core | game-designer + ai-programmer | L |
| 22 | 敌人生成系统 | MVP | Core | game-designer + ai-programmer | M |
| 23 | 炮塔系统 | MVP | Core | game-designer | M |
| 24 | 撤退判定系统 | MVP | Core | game-designer | M |
| 25 | 地堡设施系统 | MVP | Feature | game-designer | M |
| 26 | 雨水收集系统 | MVP | Feature | game-designer | S |
| 27 | 种田系统 | MVP | Feature | game-designer | M |
| 28 | 食物/生存系统 | MVP | Feature | game-designer | M |
| 29 | 魔力农场系统 | MVP | Feature | game-designer | M |

---

## Circular Dependencies

- **None found** — 所有依赖关系都是单向的（Foundation → Core → Feature → Presentation → Polish）

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| **TileMap世界系统** | Technical | 大规模方块系统性能未验证 | 原型验证性能，使用Godot TileMap内置优化 |
| **战车驾驶系统** | Design | 战车重量感是否传达正确 | 原型验证手感，调整速度/加速度/碰撞反馈 |
| **敌人AI系统** | Technical + Design | 多种AI行为（集群冲锋/拆墙攻城/追踪伏击）复杂度高 | 分阶段实现，先实现集群冲锋，其他AI后续 |
| **炮塔系统** | Design | 炮塔是否让防守有乐趣 | 原型验证炮塔攻击感，调整伤害/射速/视觉反馈 |
| **撤退判定系统** | Design | 撤退警告是否抢夺焦点且不扰人 | UX原型测试，调整警告时机/强度 |
| **天气系统** | Design + Technical | 天气与战车交互是否平衡 | 分阶段实现，先实现视觉效果，再实现gameplay影响 |
| **尸潮周期系统** | Design | 尸潮频率是否合适 | 原型验证节奏，调整基础周期和噪音积累系数 |

---

## Progress Tracker

| Metric | Count |
|-------|-------|
| Total systems identified | 59 |
| Design docs started | 23 |
| Design docs reviewed | 4 |
| Design docs approved | 4 |
| MVP systems designed | 26/26 |
| Vertical Slice systems designed | 0/12 |
| Alpha systems designed | 0/9 |
| Full Vision systems designed | 0/8 |

---

## Next Steps

- [x] Review and approve this systems enumeration
- [x] Design TileMap世界系统 GDD
- [x] Design 方块类型数据库 GDD
- [x] Design 资源数据库 GDD
- [x] Design 敌人类型数据库 GDD
- [x] Design 建造物品数据库 GDD
- [x] Design 战车类型数据库 GDD
- [x] Design 搜刮容器数据库 GDD
- [x] Design 时间系统 GDD
- [x] Design 输入控制系统 GDD
- [ ] Run `/design-review` on completed GDDs (fresh session)
- [ ] Run `/consistency-check` to verify all database ID alignments
- [ ] Design MVP-tier systems next (use `/design-system [system-name]`)
  - Next system: `/design-system 方块碰撞系统` (#11)
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Prototype the highest-risk system early (`/prototype 战车驾驶系统`)