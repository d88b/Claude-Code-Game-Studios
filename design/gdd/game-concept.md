# Game Concept: 铁锈魔潮 (Rust Magic Tide)

*Created: 2026-04-22*
*Status: Approved*

---

## Elevator Pitch

> A 2D side-scrolling pixel post-apocalyptic survival-building game where you drive a magitech battle wagon to scavenge the surface, dig and build an underground fortress, and defend against periodic zombie tides.
>
> **Core action**: 挖掘建造 + 战车探索 + 搜打撤 + 尸潮防守
> **Setting**: 魔法门宇宙 × 末世废土
> **Goal**: 在地表崩溃的世界中向下生存，改装终极战车，击败深层BOSS

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | 2D横版像素末世生存建造（Survival-Building + Vehicle Exploration + Tower Defense） |
| **Platform** | PC (Steam / Epic Games Store) |
| **Target Audience** | Mastery-focused hardcore survival players; fans of 亿万僵尸, 重装机兵, 泰拉瑞亚 |
| **Player Count** | Single-player |
| **Session Length** | 30-60 minutes per exploration cycle; 3-5 minutes for defense phase |
| **Monetization** | Premium (one-time purchase) |
| **Estimated Scope** | Medium (1.5-2 months / 6 weeks solo, first game project) |
| **Comparable Titles** | 亿万僵尸, 重装机兵, 泰拉瑞亚, 我的世界, RimWorld |

---

## Core Fantasy

**在魔法门×末世废土的世界中，作为幸存者向下挖掘建造地下要塞，驾驶改装战车外出搜刮资源，抵御周期性尸潮。**

玩家体验的核心幻想是：
- **战车探索的自由与风险**：驾驶魔导战车在地表废墟中穿行，每次出发都是一次有计划的冒险——搜刮、战斗、撤退的节奏感
- **地下要塞的建设与守护**：亲手挖掘、设计、布置防御，看着要塞从浅层洞穴进化为多层堡垒
- **尸潮防守的压力与高潮**：每几个探索周期后，尸潮来袭，所有防御系统投入实战，成败在此一举
- **魔导科技的独特美学**：魔力晶石而非石油，符文炮塔而非电子设备，阵营科技分支而非通用升级

---

## Unique Hook

**重装机兵（战车）+ 亿万僵尸（防守）+ 泰拉瑞亚（挖掘建造）—— 三合一的独特融合。**

市场上已有：
- 亿万僵尸：优秀的尸潮防守，但无探索/建造
- 重装机兵：经典战车RPG，但无防守/挖掘
- 泰拉瑞亚：完善的挖掘建造，但无战车/尸潮防守

**铁锈魔潮的"AND ALSO"**：
- 像亿万僵尸的防守紧张感，AND ALSO 你要自己驾驶战车出去搜刮资源
- 像重装机兵的战车改装乐趣，AND ALSO 每次探索都有撤退时限和尸潮威胁
- 像泰拉瑞亚的挖掘建造自由，AND ALSO 你的建造直接服务于防守战

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Challenge** (obstacle course, mastery) | 1 (Primary) | 紧张的搜打撤节奏，惩罚性的失败后果（保留30%继承），不断升级的尸潮难度 |
| **Discovery** (exploration, secrets) | 2 | 多层地下探索，古代遗迹，阵营科技分支，未知区域 |
| **Fantasy** (make-believe, role-playing) | 3 | 魔法门×末世废土世界观，魔导科技设定，阵营势力敌人 |
| **Expression** (self-expression, creativity) | 4 | 战车改装自由度，要塞布局设计，防御系统配置 |
| **Sensation** (sensory pleasure) | 5 | 像素末世美学，战车驾驶重量感，尸潮冲击视觉 |
| **Narrative** (drama, story arc) | N/A | 无强叙事驱动，世界观作为背景 |
| **Fellowship** (social connection) | N/A | 无多人元素 |
| **Submission** (relaxation, comfort zone) | N/A | 游戏设计为紧张与惩罚性，非放松体验 |

### Key Dynamics (Emergent player behaviors)

1. **风险评估行为**：玩家会学会判断何时撤退——魔能剩余、战车耐久、天色黄昏、精英出现都是撤退信号
2. **搜打撤节奏内化**：玩家会自然形成"搜-打-撤"的行动模式，贪战者必受惩罚
3. **防御设计优化**：玩家会不断调整炮塔位置、陷阱布局，寻找最佳防守策略
4. **科技路线选择**：玩家会根据偏好选择阵营科技分支（城堡护甲/塔楼科技/地狱武器）

### Core Mechanics (Systems we build)

1. **方块挖掘与建造系统**：基于TileMap的挖掘、放置、墙体建造
2. **战车驾驶与魔能系统**：战车移动、魔能消耗、武器射击、损坏与维修
3. **搜打撤探索系统**：下车搜刮、背包转移、撤退判定、时间限制
4. **尸潮防守系统**：周期性尸潮、炮塔防御、失败梯度、Roguelite继承

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** (freedom, meaningful choice) | 玩家自主决定何时出发、去哪里、何时撤退、如何改装战车、如何布局防御 | Core |
| **Competence** (mastery, skill growth) | 精通战车驾驶节奏、了解敌人弱点、优化搜打撤决策、防守战术布局 | Core |
| **Relatedness** (connection, belonging) | 与末世废土世界的关联，魔法门宇宙的阵营势力 | Supporting |

### Player Type Appeal (Bartle Taxonomy)

- **✓ Achievers** (goal completion, collection, progression) — 科技解锁、战车改装蓝图、BOSS击杀、终极战车
- **✓ Explorers** (discovery, understanding systems, finding secrets) — 多层地下探索、遗迹发现、阵营科技分支、隐藏区域
- **✗ Socializers** (relationships, cooperation, community) — 无多人/社交元素
- **✗ Killers/Competitors** (domination, PvP, leaderboards) — 无PvP元素

### Flow State Design

- **Onboarding curve**: 第一天建立基础地堡，第一次战车出门（简单丧尸），第一次小尸潮防守（成功率高）
- **Difficulty scaling**: 尸潮强度随探索深度增加，敌人类型随天数解锁，深层区域危险度递增
- **Feedback clarity**: 魔能/耐久数值清晰显示，撤退警告明确提示，尸潮规模预估
- **Recovery from failure**: 失败后保留30%科技进度+战车图纸，玩家不会完全归零，有继续的动力

---

## Core Loop

### Moment-to-Moment (30 seconds)

- **地堡内**：挖掘方块、放置建筑、布置防御、维修战车
- **战车驾驶**：控制战车移动（方向键），消耗魔能，射击敌人
- **下车搜刮**：蹲伏潜行、打开容器、拾取物品、转移背包

**核心动词重量感**：战车移动有重量感（非轻飘跑酷），魔能消耗有紧迫感，撤退时机有压力感。

### Short-Term (5-15 minutes)

**搜打撤完整流程**：
1. 判断出发条件（耐久≥80%，魔能≥50%）
2. 选择探索区域（废弃城市/恶魔荒原/机械遗迹/元素矿洞）
3. 战车驾驶到达目的地
4. 下车搜刮废墟（背包20格 → 战车仓库100格）
5. 遭遇敌人战斗
6. 判断撤退时机（魔能<20% / 耐久<30% / 黄昏 / 精英出现）
7. 战车返回地堡

**"再搜一个废墟？"的心理博弈**：每次搜刮都是诱惑 vs 风险的决策。

### Session-Level (30-60 minutes)

**完整探索周期**：
1. 地堡准备（维修、补给、升级）
2. 战车出发探索（5-15分钟）
3. 返回地堡（卸载物资、升级）
4. 尸潮倒计时（可选择加固或再次出发）
5. 尸潮防守战（3-5分钟）
6. 防守成功 → 继续发育；防守失败 → 退守内层或游戏重置

**自然停止点**：防守成功后的休整期，玩家可选择继续或下线。

### Long-Term Progression

| 阶段 | 天数 | 目标 | 里程碑 |
|------|------|------|--------|
| **生存期** | 1-5 | 建立地堡、基础战车 | 第一次尸潮防守成功 |
| **发展期** | 6-15 | 升级战车、扩展地堡 | 秘银装甲战车，中层探索 |
| **危机期** | 16-25 | 强化防御、应对大尸潮 | 击败精英/恶魔BOSS |
| **终局期** | 26+ | 挑战深层BOSS、终极战车 | 深层地狱层探索，终极装备 |

### Retention Hooks

- **Curiosity**: 多层地下有什么？深层遗迹藏着什么科技？各阵营BOSS在哪里？
- **Investment**: 科技进度、战车改装蓝图、要塞建设成果——不想丢失
- **Mastery**: 优化搜打撤节奏、完善防守布局、战车改装策略

---

## Game Pillars

### Pillar 1: 战车即生命

战车是探索地表的唯一可行方式；无战车 = 极高风险步行，战车瘫痪 = 玩家需步行逃回或等待救援。

*Design test*: 如果一个设计让步行探索变得"舒适可行"（如强大步行武器、步行护甲），它违背了此支柱。步行必须保持高风险状态。

### Pillar 2: 搜打撤节奏

每次探索必须遵循 搜刮→战斗→撤退 的强制节奏，贪婪有代价。

*Design test*: 如果玩家可以无限停留地表而无惩罚机制（如无时间限制、无魔能消耗），它违背了此支柱。撤退必须有明确的触发条件和后果。

### Pillar 3: 尸潮即高潮

尸潮防守是每个探索周期的压力峰值；防守失败 = 有意义的损失（丢失资源、退守内层、保留30%继承）。

*Design test*: 如果尸潮可以轻松忽略或防守失败无代价（如无损失重试），它违背了此支柱。防守必须有真实的压力和后果。

### Pillar 4: 魔导科技美学

魔法门×末世废土的独特世界观；魔力晶石而非石油，符文炮塔而非电子设备，阵营科技分支定义玩家风格。

*Design test*: 如果设计引入纯科幻或纯奇幻元素而脱离魔导科技设定（如激光武器、纯魔法无科技），它违背了此支柱。

### Anti-Pillars (What This Game Is NOT)

- **NOT 步行探索舒适化**: 步行探索舒适化会削弱战车的核心地位，违背"战车即生命"支柱
- **NOT 无限停留地表**: 无限停留地表会破坏"搜打撤节奏"，让游戏变成无压力的观光
- **NOT 多人合作**: 首个项目、6周工期；多人系统会极大增加技术复杂度和工期风险
- **NOT 复杂叙事/剧情**: 核心是玩法循环，不是故事；复杂叙事会分散核心循环的开发资源
- **NOT 手游适配**: 精髓在于战车驾驶的战术重量感，手机触屏无法传达这种体验

---

## Visual Identity Anchor

### Visual Direction: 像素末世废土

**One-line visual rule**: 每一个像素都必须传达末世的荒凉、魔导科技的独特、战车的重量感。

**Supporting visual principles**:

1. **废土美学优先**：地表场景必须展现文明崩溃的痕迹——废墟、残骸、锈迹、腐蚀。不出现完好无损的现代建筑。
   *Design test*: 如果一个地表场景看起来像"正常城市"，它违反此原则。

2. **魔导科技区分**：战车、炮塔、设施必须展现魔导元素——符文、魔力晶石发光、秘银材质。不出现纯电子/石油科技外观。
   *Design test*: 如果战车看起来像"柴油卡车"而非"魔导战车"，它违反此原则。

3. **阵营视觉区分**：四大势力（墓园/地狱/塔楼/元素）必须有清晰的视觉标识——墓园=骨骼与死亡、地狱=火焰与恶魔、塔楼=机械与金属、元素=晶石与光芒。
   *Design test*: 如果玩家无法从视觉识别敌人所属阵营，它违反此原则。

**Color philosophy**: 主色调为锈色、灰暗、尘土色；阵营特色色为点缀——墓园（灰白+腐烂绿）、地狱（暗红+火焰橙）、塔楼（金属银+电路蓝）、元素（晶石紫+光芒金）。

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| **亿万僵尸** | 尸潮防守紧张感、炮塔防御系统、拆墙攻城机制 | 加入战车探索和挖掘建造，防守不是唯一玩法 | 验证防守品类市场热门 |
| **重装机兵** | 战车改装乐趣、战车损坏维修、多战车系统 | 加入搜打撤节奏和尸潮防守，探索有时间压力 | 验证战车RPG经典粉丝群体 |
| **泰拉瑞亚** | 方块挖掘建造自由度、多层地下探索、资源采集 | 加入战车和尸潮防守，建造服务于防守战 | 验证挖掘建造巨大市场 |
| **我的世界** | 建造自由度、防御塔设计 | 限制为2D横版，聚焦核心循环 | 验证建造品类普及度 |
| **魔法门** | 阵营势力设定、魔导科技世界观 | 融合末世废土背景，阵营作为敌人而非玩家选择 | 验证世界观差异化独特性 |

**Non-game inspirations**:
- **末日生存电影**（疯狂的麦克斯、僵尸世界大战）：废土美学、车辆改装、生存压力
- **魔幻奇幻作品**：魔导科技设定、符文魔法、阵营对立

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 18-35 |
| **Gaming experience** | Mid-core to Hardcore；有生存游戏/策略游戏经验 |
| **Time availability** | 30-60分钟探索周期；硬核玩家可能连续多个周期 |
| **Platform preference** | PC (Steam为主) |
| **Current games they play** | 亿万僵尸、泰拉瑞亚、RimWorld、缺氧、Factorio |
| **What they're looking for** | 挑战与精通体验；战车探索 + 要塞防守的独特融合；魔导科技美学 |
| **What would turn them away** | 过于休闲/轻松的体验；纯步行探索；复杂叙事打断循环；手游触屏适配 |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.6 — 2D像素友好、轻量免费、TileMap内置支持、GDScript易学 |
| **Key Technical Challenges** | 方块系统性能、战车物理与魔能系统、敌人AI（集群冲锋/追踪伏击/规律巡逻）、尸潮生成与管理 |
| **Art Style** | 2D像素艺术（16x16或32x32方块），末世废土美学 |
| **Art Pipeline Complexity** | Medium — 自定义像素资产，参考开源像素资产库 |
| **Audio Needs** | Moderate — 战车引擎声、武器射击、挖掘音效、尸潮警报、背景音乐 |
| **Networking** | None — 单机单玩家 |
| **Content Volume** | 4个地表区域 × 4个地下层级 × 4大势力敌人 × 多种战车改装 × 科技树 |
| **Procedural Systems** | 尸潮规模动态计算（基于噪音积累、探索深度、天数）；地下矿脉随机分布 |

---

## Risks and Open Questions

### Design Risks

- **四大系统融合是否能产生乐趣**：挖掘 + 战车 + 搜打撤 + 防守 的融合是否让玩家感到混乱而非有节奏感？
- **搜打撤节奏是否能内化**：玩家是否能学会判断撤退时机，还是会频繁"贪战致死"导致挫败？
- **尸潮防守是否能成为高潮而非负担**：防守战是否让玩家期待而非逃避？

### Technical Risks

- **首个Godot项目**：方块系统、战车物理、敌人AI的实现难度可能被低估
- **方块系统性能**：大规模挖掘/建造时TileMap性能是否稳定？
- **尸潮生成管理**：大量敌人同时生成时的性能与AI行为是否可控？

### Market Risks

- **品类融合的市场接受度**：战车探索 + 要塞防守 的融合是否有足够的受众？
- **硬核惩罚性设计**：失败保留30%继承是否对足够多的玩家有吸引力？

### Scope Risks

- **策划案内容丰富**：容易范围蔓延，超出6周工期
- **首个项目低估**：首次开发者常有工期低估倾向

### Open Questions

- **战车瘫痪后的步行逃回体验**：步行逃回是否足够紧张有趣而非纯挫败？需要原型验证
- **尸潮规模预估的准确性**：玩家是否能理解并信任预估系统？需要原型验证

---

## MVP Definition

**Core hypothesis**: 玩家是否觉得"挖掘 + 战车探索 + 搜打撤 + 防守"的核心循环有乐趣且节奏清晰？

**Required for MVP** (12天):

1. **方块挖掘/放置** — 验证挖掘建造的基础乐趣
2. **战车移动+魔能消耗** — 验证战车驾驶的重量感和资源紧张感
3. **一个废墟地图+搜刮** — 验证搜打撤的基础流程
4. **一个敌人（丧尸）** — 验证基础战斗
5. **搜打撤判定逻辑** — 验证撤退触发和后果
6. **地堡入口+一个炮塔** — 验证防守的基础机制

**Explicitly NOT in MVP**:

- 尸潮系统（第二阶段）
- 战车损坏维修（第二阶段）
- 多种敌人类型（第二阶段）
- 合成系统（第二阶段）
- 多层地下（第三阶段）
- 战车改装（第三阶段）

### Scope Tiers

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 基础地图、基础战车、丧尸、基础炮塔 | 核心循环验证 | 12天 |
| **Vertical Slice** | 完整搜打撤、尸潮系统、战车损坏、4种敌人 | 可发布版本核心 | 28天 |
| **Full Vision** | 多层地下、战车改装、难度曲线、存档、UI优化 | 完整可发布版本 | 42天 (6周) |
| **Expansion** | 多人合作、地下城副本、商队系统 | 未规划 | 首个项目不建议 |

---

## Next Steps

- [x] Get concept approval from user (已完成)
- [ ] Run `/setup-engine` to configure Godot 4 and populate version-aware reference docs
- [ ] Run `/art-bible` to create the visual identity specification (像素末世废土)
- [ ] Use `/design-review design/gdd/game-concept.md` to validate concept completeness
- [ ] Decompose the concept into individual systems with `/map-systems` — maps dependencies, assigns priorities, and creates the systems index
- [ ] Author per-system GDDs with `/design-system` — guided, section-by-section GDD writing for each system
- [ ] Plan the technical architecture with `/create-architecture` — produces the master architecture blueprint and Required ADR list
- [ ] Record key architectural decisions with `/architecture-decision (×N)` — write one ADR per decision in the Required ADR list
- [ ] Validate readiness to advance with `/gate-check` — phase gate before committing to production
- [ ] Prototype the riskiest system with `/prototype [战车探索]` — validate the core loop before full implementation
- [ ] Run `/playtest-report` after the prototype to validate the core hypothesis
- [ ] If validated, plan the first sprint with `/sprint-plan new`