# 敌人AI系统

> **Status**: Designed
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Implements Pillar**: Pillar 3 (尸潮即高潮)
> **Priority**: MVP | **Layer**: Core
> **System ID**: #36 (from systems-index.md)

## Overview

敌人AI系统是管理所有敌人实例行为决策的核心系统。每个敌人实例拥有独立的AI状态机，根据其behavior_hint类型执行不同的行为模式：集群冲锋向玩家/防御设施移动、拆墙攻城优先攻击墙体结构、追踪猎杀锁定战车目标、远程狙击保持距离射击等。系统从敌人类型数据库读取behavior_hint和属性参数，实时计算目标选择、路径规划、攻击触发，驱动敌人CharacterBody2D移动和攻击。

**数据层定位**：AI系统处理每帧的敌人行为决策：
- 读取EnemyTypeDB的behavior_hint决定行为模式
- 维护每个敌人实例的AI状态机（状态转换、目标追踪、攻击冷却）
- 调用NavigationServer2D进行路径规划（目标位置 → 路径点列表）
- 驱动CharacterBody2D执行move_and_slide移动
- 触发攻击信号（attack_signal → EnemyDamage系统）

**玩家感知层**：玩家通过以下方式直接感知敌人AI行为：
- 尸潮中僵尸集群冲锋的压迫感（成群结队向防线逼近）
- 骷髅拆墙工专注攻击墙体的威胁（防线被针对性突破）
- 地狱小鬼追踪战车的紧张感（高速敌人锁定玩家）
- 骷髅弓手远程射击的躲避需求（距离威胁需要战术应对）
- Boss召唤增援的战场扩张（单体威胁演变为群体压力）

**系统必要性**：没有敌人AI系统，游戏将无法：
- 区分不同敌人的行为差异（所有敌人执行相同逻辑）
- 实现behavior_hint定义的8种AI模式（behavior_hint字段无意义）
- 创造尸潮的真实战术压力（敌人不攻击或不移动）
- 为炮塔系统提供有效目标（炮塔无敌人可射击）
- 为战斗反馈系统提供攻击事件源（无攻击事件可反馈）

**服务于支柱**：
- **Pillar 3 (尸潮即高潮)**：敌人AI系统是尸潮"威胁感"的核心来源——不同behavior_hint创造不同的战术挑战，集群冲锋是数量压力，拆墙攻城是针对性突破，远程狙击是距离威胁。AI行为多样性将尸潮从"数值堆叠"转化为"战术博弈"。

## Player Fantasy

**情感目标：战术压迫的肾上腺激涌**

玩家面对尸潮时，敌人AI系统应创造"识别威胁→动态应对→生存压力"的节奏体验：

1. **威胁识别感**：尸潮冲锋时，玩家能迅速识别不同敌人类型的行为差异——僵尸集群如潮水般压向防线，骷髅拆墙工绕过正面专攻薄弱墙体，地狱小鬼高速追踪锁定战车，骷髅弓手保持距离远程骚扰。每种behavior_hint创造可识别的威胁模式，玩家需在瞬息万变的战场中判断优先处理目标。

2. **动态战场感**：敌人不是静态的数值障碍，而是根据战场状态实时决策的威胁。当战车移动时，追踪猎杀型敌人会重新计算追击路径；当墙体被破坏时，拆墙攻城型敌人会转移攻击目标；当增援被召唤时，战场压力瞬间升级。玩家感受到敌人"在思考"，每一次战术决策都有敌人行为反馈。

3. **生存紧迫感**：多类型敌人协同攻击创造真实的生存压力——集群冲锋消耗防线火力，拆墙工针对性突破造成缺口，追踪猎杀迫使玩家放弃静止策略，远程狙击提供持续骚扰。玩家必须在"守住防线"与"保持机动"之间权衡，每一波尸潮都是战术博弈而非数值消耗。

**锚定时刻**：第一次尸潮攻击，玩家同时面对集群冲锋（数量压迫）、拆墙攻城（针对性突破）、追踪猎杀（战车威胁）三种行为模式的协同攻击。这一刻玩家感受到敌人AI系统的核心体验——不同威胁类型的组合创造真实战术压力，玩家必须识别优先级并动态调整策略。

**支柱服务**：敌人AI系统直接服务**Pillar 3 (尸潮即高潮)**。behavior_hint定义的8种AI行为将尸潮从"数值堆叠"转化为"战术博弈"——每种敌人类型创造不同的威胁模式，尸潮的压力来自多类型协同而非单纯数量。AI行为多样性是尸潮"真实威胁感"的核心来源。

## Detailed Design

### Core Rules

1. **AI实例架构**：每个敌人实例拥有独立的AI状态机（StateMachine），由`EnemyAIController`组件管理。状态机读取`EnemyTypeDatabase`的`behavior_hint`字段决定初始行为模式，实时处理状态转换、目标追踪、攻击触发。

2. **状态机规则**：状态机采用枚举状态（enum EnemyState），每个状态对应特定的行为逻辑。状态转换由条件触发器驱动（目标进入范围、攻击冷却完成、目标丢失等）。状态机每帧执行`update(delta)`计算下一行为。

3. **behavior_hint映射规则**：MVP阶段实现全部8种AI行为模式，每种模式定义目标选择策略、路径规划方式、攻击触发条件：

| behavior_hint | 目标选择 | 路径规划 | 攻击触发 |
|---------------|----------|----------|----------|
| SWARM_CHARGE (0) | 最近玩家/防御设施 | 直接路径，集群松散 | 接触时触发 |
| WALL_BREAKER (1) | 最近墙体结构 | 绕过障碍直奔墙体 | 墙体碰撞时触发 |
| TRACKER_HUNT (2) | 战车目标（移动优先） | 追踪路径，动态更新 | 战车碰撞时触发 |
| PATROL_GUARD (3) | 区域内玩家 | 区域巡逻路径 | 玩家进入范围触发 |
| SNIPER_RANGE (4) | 范围内玩家 | 保持攻击距离 | 攻击冷却完成时触发 |
| AMBUSHER_HIDE (5) | 接近玩家 | 隐藏位置固定 | 玩家触发区域时攻击 |
| SUMMONER_CALL (6) | 无主动目标 | 后线安全位置 | 定期召唤增援 |
| SUPPORT_BUFF (7) | 附近敌人 | 保持后线位置 | 附近敌人存在时增强 |

4. **路径规划规则**：所有路径规划通过`NavigationServer2D`实现。敌人实例使用`NavigationAgent2D`组件进行路径计算：
   - `set_target_position(target)` 设置目标位置
   - `get_next_path_position()` 获取下一个路径点
   - 每帧调用`move_and_slide(velocity)`执行移动
   - **路径重算频率采用动态速率**：
     - TRACKER_HUNT类型：每0.1秒重新计算（高速追踪需求）
     - 其他类型：每0.5秒重新计算（标准更新频率）
     - 静态目标（WALL_BREAKER攻击固定墙体）：无需频繁重算

5. **攻击触发规则**：攻击触发由攻击冷却（attack_cooldown）和攻击范围（attack_range）控制：
   - 每个敌人实例维护`attack_timer`（float），初始化为0
   - 当目标在attack_range内且attack_timer <= 0时，触发攻击
   - 攻击触发后，attack_timer重置为attack_cooldown值（从EnemyTypeDB读取）
   - 攻击信号发送至`EnemyDamageSystem`处理伤害计算

6. **目标优先级规则**：当多个有效目标存在时，目标选择基于距离和威胁优先级：
   - 基础距离计算：`distance = position.distance_to(target.position)`
   - 墙体优先（WALL_BREAKER）：墙体目标权重×2.0
   - 战车优先（TRACKER_HUNT）：战车目标权重×1.5，优先追踪移动目标而非静止设施
   - 最终优先级 = distance × (1 / target_weight)

### States and Transitions

#### 基础状态枚举

| State | Name | Description | Entry Condition |
|-------|------|-------------|-----------------|
| IDLE | 待机 | 无目标，原地待机 | 无有效目标 |
| MOVE_TO_TARGET | 向目标移动 | 向选定目标路径移动 | 有目标且距离 > attack_range |
| ATTACK | 攻击 | 执行攻击动作 | 目标在attack_range内且attack_timer <= 0 |
| STUN | 眩晕 | 无法行动 | 受到眩晕效果 |
| DEAD | 死亡 | 死亡处理 | health <= 0 |

#### 状态转换表

| Current State | Transition Condition | Next State |
|---------------|----------------------|------------|
| IDLE | 目标进入感知范围 | MOVE_TO_TARGET |
| IDLE | 无目标持续5秒 | 保持IDLE |
| MOVE_TO_TARGET | 目标进入attack_range且attack_timer <= 0 | ATTACK |
| MOVE_TO_TARGET | 目标丢失（超出感知范围或死亡） | IDLE |
| MOVE_TO_TARGET | 目标变更（优先级更新） | MOVE_TO_TARGET（重新路径） |
| ATTACK | 攻击完成 | MOVE_TO_TARGET（若目标仍存在） |
| ATTACK | 目标死亡 | IDLE |
| ATTACK | attack_timer重置 | MOVE_TO_TARGET（等待冷却） |
| STUN | 眩晕效果结束 | IDLE |
| ANY | health <= 0 | DEAD |

#### behavior_hint专属状态扩展

每种behavior_hint在基础状态上扩展专属状态：

| behavior_hint | 专属状态 | 状态描述 | 状态转换 |
|---------------|----------|----------|----------|
| SWARM_CHARGE | 无扩展 | 使用基础状态 | — |
| WALL_BREAKER | BREAKING_WALL | 攻击墙体状态（持续攻击直到墙体破坏） | ATTACK → BREAKING_WALL（墙体目标锁定） → IDLE（墙体破坏） |
| TRACKER_HUNT | HUNTING | 高速追击状态（速度×1.5） | MOVE_TO_TARGET → HUNTING（战车锁定） → MOVE_TO_TARGET（战车丢失） |
| PATROL_GUARD | PATROLING | 区域巡逻状态（按预设路径移动） | IDLE → PATROLING（无威胁） → MOVE_TO_TARGET（玩家进入范围） |
| SNIPER_RANGE | AIMING | 瞄准状态（射击准备，0.3秒延迟） | MOVE_TO_TARGET → AIMING（目标在range） → ATTACK（瞄准完成） |
| AMBUSHER_HIDE | HIDING | 隐藏状态（静止等待触发，透明度×0.3） | IDLE → HIDING（初始化） → ATTACK（玩家触发） → HIDING（攻击后） |
| SUMMONER_CALL | SUMMONING | 召唤状态（召唤动作，2秒延迟） | MOVE_TO_TARGET → SUMMONING（到达后线） → IDLE（召唤完成） |
| SUPPORT_BUFF | BUFFING | 增强状态（增强附近敌人，光环效果） | MOVE_TO_TARGET → BUFFING（到达后线） → BUFFING（持续增强） |

### Interactions with Other Systems

#### 上游系统依赖

| System | Interface | Data Flow | Owner |
|--------|-----------|-----------|-------|
| **EnemyTypeDatabase** | `get_enemy_definition(enemy_id)` → behavior_hint, speed, attack_range, attack_cooldown, damage | AI系统读取behavior_hint决定行为模式，读取speed/attack_range/attack_cooldown/damage参数 | Foundation层，Designed |
| **TileMapWorldSystem** | 方块位置查询 → 可行走区域判断（NavigationServer2D依赖） | AI路径规划需知道哪些方块可行走，TileMap定义NavigationPolygon | Foundation层，Designed |

#### 下游系统交互

| System | Interface | Data Flow | Owner |
|--------|-----------|-----------|-------|
| **EnemySpawnSystem** | 创建敌人实例 → 初始化AI组件 | 生成系统创建敌人时初始化AI状态机，传入enemy_id，设置初始位置 | Core层，Not Started |
| **EnemyDamageSystem** | 攻击信号 → `attack_signal.emit(target, damage, damage_source_type)` | AI系统触发攻击时发送信号，伤害系统计算并应用伤害 | Combat层，Not Started |
| **TurretSystem** | 敌人位置 → 炮塔目标选择（被动查询） | 炮塔系统查询敌人位置进行瞄准，敌人AI无需主动交互 | Defense层，Not Started |
| **CombatFeedbackSystem** | 攻击事件 → 视觉/音效反馈 | AI系统触发攻击时，反馈系统显示攻击效果（攻击动画、攻击音效） | Presentation层，Not Started |

#### Godot Engine组件依赖

| Component | Purpose | Usage Pattern |
|-----------|---------|---------------|
| **NavigationAgent2D** | 路径规划组件 | 每个敌人实例附加NavigationAgent2D，调用`get_next_path_position()`获取路径点，`set_target_position()`设置目标 |
| **NavigationServer2D** | 路径计算服务 | 通过NavigationAgent2D间接调用，Godot 4.6内置支持 |
| **CharacterBody2D** | 移动执行 | AI计算velocity向量，调用`move_and_slide(velocity)`执行物理移动 |
| **Timer节点** | 攻击冷却计时 | 每个敌人实例附加Timer节点（或使用float累加），控制attack_cooldown |

## Formulas

### 1. Velocity Calculation

`velocity = direction × speed × speed_multiplier`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `direction` | Vector2 | normalized (0-1) | `position.direction_to(next_path_point)` |
| `speed` | float | 0.5-5.0 | EnemyTypeDB.speed |
| `speed_multiplier` | float | 1.0-2.0 | State-specific modifier (HUNTING×1.5) |

**Output**: Vector2 velocity for `move_and_slide()`
**Example**: direction=(1,0), speed=2.5, multiplier=1.0 → velocity=(2.5, 0)

### 2. Target Priority Score

`priority_score = distance × (1 / target_weight)`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `distance` | float | 0-∞ px | `position.distance_to(target.position)` |
| `target_weight` | float | 1.0-2.0 | behavior_hint决定（墙体×2.0，战车×1.5） |

**Output**: float — 越低优先级越高（距离近且权重高）
**Example**: distance=100, weight=2.0 → priority_score=50（墙体优先）; distance=80, weight=1.0 → priority_score=80（玩家次优）

### 3. Attack Timer Countdown

`attack_timer_new = attack_timer_old - delta`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `attack_timer_old` | float | 0-5.0 | 当前计时值 |
| `delta` | float | 0-0.033 | 帧时间（60fps ≈ 0.0167s） |

**Output**: float — 新计时值
**Attack condition**: `attack_timer <= 0 AND target_in_range`

**Reset on attack**: `attack_timer = attack_cooldown`（从EnemyTypeDB读取）

**Example**: attack_timer=0.5, delta=0.016 → attack_timer_new=0.484; 30帧后（0.5s）attack_timer≈0

### 4. Path Recalculation Timer

`path_timer_new = path_timer_old - delta`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `path_timer_old` | float | 0-0.5 | 当前计时值 |
| `delta` | float | 0-0.033 | 帧时间 |

**Recalc condition**: `path_timer <= 0`

**Reset intervals**: 
- TRACKER_HUNT: `path_timer = 0.1`
- Other types: `path_timer = 0.5`

**Example**: TRACKER_HUNT path_timer=0.1, 6帧后（0.1s）触发路径重算

### 5. HUNTING Speed Multiplier

`hunting_speed = base_speed × TRACKER_HUNT_SPEED_MULT`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `base_speed` | float | 0.5-5.0 | EnemyTypeDB.speed |
| `TRACKER_HUNT_SPEED_MULT` | float | 1.5 | Tuning Knob（可调整） |

**Output**: float — 追击状态下的移动速度
**Example**: base_speed=2.5, multiplier=1.5 → hunting_speed=3.75

### 6. Target Detection Range

`is_in_range = distance <= detection_range`

**Variables:**
| Variable | Type | Range | Source |
|----------|------|-------|--------|
| `distance` | float | 0-∞ px | `position.distance_to(target.position)` |
| `detection_range` | float | 5-20 格 | EnemyTypeDB.attack_range × DETECTION_RANGE_MULT |

**Detection multiplier**: `DETECTION_RANGE_MULT = 2.0`（检测范围大于攻击范围）

**Example**: attack_range=1.5格(48px), DETECTION_RANGE_MULT=2.0 → detection_range=96px

## Edge Cases

### 路径规划边界情况

1. **目标位置不可达**：当`NavigationAgent2D.target_position`设置为目标位置后，若路径计算失败（目标在障碍物内或NavigationPolygon外）：
   - 状态转换：MOVE_TO_TARGET → IDLE
   - 日志记录：`"Path unreachable for enemy_id=[id], target_position=[pos]"`
   - 行为：敌人原地待机，等待下一路径重算周期重新尝试

2. **NavigationPolygon未配置**：若TileMap未定义NavigationPolygon（可行走区域）：
   - 回退行为：使用简单直线移动（`velocity = direction_to(target) × speed`）
   - 日志警告：`"NavigationPolygon not defined, using fallback direct movement"`
   - 设计约束：NavigationPolygon必须在MVP阶段配置

3. **路径点列表为空**：若`get_next_path_position()`返回当前位置（无路径点）：
   - 判断条件：`path_position.distance_to(self.position) < 5px`
   - 行为：重新调用`set_target_position()`触发路径重算
   - 最大重试：3次，超过后进入IDLE状态

### 目标选择边界情况

4. **多个相同优先级目标**：当`priority_score`计算结果相同（两个目标距离权重相同）：
   - 解析策略：选择第一个计算的目标（数组顺序）
   - 替代策略：随机选择（`randi() % target_count`）
   - MVP默认：选择第一个目标，避免随机性引入不确定性

5. **目标突然消失**：目标在攻击范围内但突然销毁（如炮塔被破坏、战车撤退）：
   - 状态转换：ATTACK → IDLE（立即）
   - attack_timer不重置，保持当前值（避免新目标立即可攻击）
   - 下帧重新计算目标优先级

6. **目标无效（null引用）**：目标引用为null时：
   - 检查：`if target == null or not is_instance_valid(target)`
   - 行为：强制转换至IDLE状态
   - 日志：`"Target reference lost for enemy_id=[id]"`

### 状态转换边界情况

7. **连续状态转换防抖**：防止状态在单帧内多次转换（如IDLE→MOVE→ATTACK→IDLE循环）：
   - 状态锁定：每次状态转换后锁定`STATE_LOCK_FRAMES=3`帧
   - 锁定期间：不响应新转换条件
   - 锁定解除后：正常状态机逻辑

8. **死亡状态优先级最高**：任何状态遇到`health <= 0`必须立即转换至DEAD：
   - 优先级规则：DEAD状态优先于所有其他转换
   - 行为：停止移动、停止攻击、触发死亡动画
   - 数据清理：释放NavigationAgent2D资源

### 行为类型专属边界情况

9. **SWARM_CHARGE集群重叠**：多个集群冲锋敌人路径重叠导致堆叠：
   - 分散算法：`velocity += separation_force`（Boids算法分离）
   - 分散力度：`SEPARATION_FORCE = 0.3`
   - 检测半径：`SEPARATION_RADIUS = 32px`
   - 效果：敌人自然分散，避免堆叠在单点

10. **WALL_BREAKER墙体不存在**：WALL_BREAKER目标选择无墙体时：
    - 回退行为：目标切换为最近玩家（target_weight=1.0）
    - 日志：`"No wall targets for WALL_BREAKER, fallback to player"`
    - 状态：MOVE_TO_TARGET（正常追击）

11. **TRACKER_HUNT战车未部署**：战车在车库中时TRACKER_HUNT无法追踪：
    - 判断：`vehicle_state == IN_GARAGE`
    - 行为：回退至SWARM_CHARGE模式（目标选择最近玩家）
    - 日志：`"Vehicle in garage, TRACKER_HUNT fallback to SWARM_CHARGE"`

12. **SNIPER_RANGE被近身**：SNIPER_RANGE类型敌人被玩家接近（distance < attack_range）：
    - 行为：触发撤退路径计算（`set_target_position(flee_position)`）
    - 撤退距离：`FLEE_DISTANCE = attack_range × 1.5`
    - 状态：MOVE_TO_TARGET（远离玩家）

13. **AMBUSHER_HIDE触发前被发现**：隐藏状态被炮塔攻击发现：
    - 行为：立即退出HIDING状态，透明度恢复至1.0
    - 状态转换：HIDING → MOVE_TO_TARGET（主动攻击）
    - 日志：`"Ambusher revealed by turret attack"`

14. **SUMMONER_CALL召唤上限**：召唤者达到最大召唤数量：
    - 判断：`summoned_count >= MAX_SUMMONS`（默认=5）
    - 行为：停止召唤，进入IDLE状态
    - 日志：`"Summoner reached max summons=[count]"`

15. **SUPPORT_BUFF无附近敌人**：附近无其他敌人可增强：
    - 判断：`nearby_enemy_count == 0`
    - 行为：进入IDLE状态，等待其他敌人靠近
    - 增强半径：`BUFF_RADIUS = 96px`

## Dependencies

### Upstream Dependencies (Systems this one depends on)

| System | Dependency Type | Interface Used | Status |
|--------|-----------------|----------------|--------|
| **EnemyTypeDatabase** | Hard | `get_enemy_definition(enemy_id)` → behavior_hint, speed, attack_range, attack_cooldown, damage | Designed |
| **TileMapWorldSystem** | Hard | NavigationPolygon定义 → 可行走区域 | Designed |

**Dependency Nature**:
- **Hard dependency**: 敌人AI系统无法运行若无EnemyTypeDatabase（缺少behavior_hint定义）或TileMapWorldSystem（缺少可行走区域）
- **Interface contract**: EnemyTypeDatabase必须提供behavior_hint字段（int 0-7），TileMap必须配置NavigationPolygon

### Downstream Dependencies (Systems that depend on this one)

| System | Dependency Type | Interface Provided | Status |
|--------|-----------------|--------------------|--------|
| **EnemySpawnSystem** | Hard | AI组件初始化接口 → `init_ai(enemy_id, position)` | Not Started |
| **EnemyDamageSystem** | Hard | 攻击信号 → `attack_signal.emit(target, damage, source_type)` | Not Started |
| **TurretSystem** | Soft | 敌人位置暴露 → 炮塔可查询进行瞄准 | Not Started |
| **CombatFeedbackSystem** | Soft | 攻击事件 → 触发视觉/音效反馈 | Not Started |

**Dependency Nature**:
- **Hard dependency**: EnemySpawnSystem创建敌人实例需初始化AI组件；EnemyDamageSystem需接收攻击信号
- **Soft dependency**: TurretSystem可独立运行但需敌人位置数据；CombatFeedbackSystem增强体验但非必需

### Bidirectional Check

| Dependency | Listed Here | Listed in Target | Status |
|------------|-------------|------------------|--------|
| EnemyAI → EnemyTypeDatabase | ✓ Listed as Hard | ✓ Listed in EnemyTypeDB Dependencies (Section F) | ✅ Verified |
| EnemyAI → TileMapWorldSystem | ✓ Listed as Hard | TileMap GDD does NOT list this (inbound ref only) | ✅ Correct |
| EnemySpawn → EnemyAI | ✓ Listed as Hard | — Target GDD not written | Pending |
| EnemyDamage → EnemyAI | ✓ Listed as Hard | — Target GDD not written | Pending |
| Turret → EnemyAI | ✓ Listed as Soft | — Target GDD not written | Pending |

**Note**: TileMapWorldSystem是Foundation层系统，EnemyAI是其下游Core层系统。TileMap不主动依赖EnemyAI，仅提供可行走区域数据。

### Cross-System Data Flow

```
EnemyTypeDatabase (behavior_hint, speed, attack_range)
        ↓
    EnemyAI System (状态机计算, 路径规划)
        ↓
    [attack_signal] → EnemyDamageSystem (伤害计算)
        ↓
    [enemy_position] → TurretSystem (瞄准目标)
```

## Tuning Knobs

### Global AI Tuning Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `DETECTION_RANGE_MULT` | 2.0 | 1.0-3.0 | 检测范围倍率（attack_range × MULT） | ×1.0 = 接触检测，×3.0 = 预警检测 |
| `STATE_LOCK_FRAMES` | 3 | 1-10 | 状态转换锁定帧数 | ×1 = 无防抖，×10 = 状态转换延迟 |
| `MAX_PATH_RETRIES` | 3 | 1-10 | 路径重算最大重试次数 | ×1 = 快速放弃，×10 = 持久重算 |

### Path Planning Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `PATH_RECALC_INTERVAL_TRACKER` | 0.1 | 0.05-0.3 | TRACKER_HUNT路径重算间隔（秒） | ×0.05 = 实时追踪，×0.3 = 滞后追踪 |
| `PATH_RECALC_INTERVAL_STANDARD` | 0.5 | 0.2-1.0 | 标准类型路径重算间隔（秒） | ×0.2 = 高频重算，×1.0 = 低频优化 |

### Behavior-Specific Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `TRACKER_HUNT_SPEED_MULT` | 1.5 | 1.0-2.0 | 追击状态速度倍率 | ×1.0 = 正常速度，×2.0 = 高速追击 |
| `SEPARATION_FORCE` | 0.3 | 0.0-1.0 | SWARM集群分散力度 | ×0.0 = 无分散（堆叠），×1.0 = 强分散 |
| `SEPARATION_RADIUS` | 32 | 16-64 | SWARM分散检测半径（px） | ×16 = 紧密集群，×64 = 疏散集群 |
| `FLEE_DISTANCE_MULT` | 1.5 | 1.0-3.0 | SNIPER撤退距离倍率 | ×1.0 = attack_range，×3.0 = 远距撤退 |
| `MAX_SUMMONS` | 5 | 1-10 | SUMMONER最大召唤数量 | ×1 = 单次召唤，×10 = 大规模增援 |
| `BUFF_RADIUS` | 96 | 48-192 | SUPPORT增强检测半径（px） | ×48 = 紧密增强，×192 = 大范围增强 |
| `AMBUSH_ALPHA` | 0.3 | 0.0-0.5 | AMBUSHER隐藏透明度 | ×0.0 = 完全隐形，×0.5 = 半透明可见 |

### Timing Knobs

| Knob | Default | Range | Purpose | Extreme Behavior |
|------|---------|-------|---------|------------------|
| `AIMING_DELAY` | 0.3 | 0.1-0.5 | SNIPER瞄准延迟（秒） | ×0.1 = 快速射击，×0.5 = 慢速瞄准 |
| `SUMMONING_DELAY` | 2.0 | 1.0-5.0 | SUMMONER召唤延迟（秒） | ×1.0 = 快速召唤，×5.0 = 慢速增援 |
| `IDLE_TIMEOUT` | 5.0 | 1.0-10.0 | IDLE状态超时（秒） | ×1.0 = 快速重检，×10.0 = 慢速响应 |

### Knob Interactions

- **`TRACKER_HUNT_SPEED_MULT` × `speed`** — 追击速度 = 基础速度 × 倍率（高倍率+高基础速度 = 极速追击）
- **`SEPARATION_FORCE` × `SEPARATION_RADIUS`** — 分散效果 = 力度 × 检测范围（高力度+大半径 = 疏散尸潮）
- **`PATH_RECALC_INTERVAL_TRACKER` vs `PATH_RECALC_INTERVAL_STANDARD`** — 追踪型需要更频繁重算（低间隔 = 高精度追踪）
- **`DETECTION_RANGE_MULT` × `attack_range`** — 检测范围 = 攻击范围 × 倍率（高倍率 = 预警检测，低倍率 = 接触检测）

## Visual/Audio Requirements

### Enemy Visual Behavior Indicators

敌人AI行为必须通过视觉传达，让玩家能识别敌人当前状态和意图：

| AI状态 | 视觉指示 | VFX效果 | 目的 |
|--------|----------|----------|------|
| IDLE | 轻微动画（呼吸/漂浮） | 无特效 | 表示敌人"等待中" |
| MOVE_TO_TARGET | 移动动画 + 方向指示 | 无特效 | 表示敌人"正在逼近" |
| ATTACK | 攻击准备动画 → 攻击执行 | 攻击光效/粒子 | 表示敌人"即将攻击/正在攻击" |
| STUN | 眩晕摇晃动画 | 眩晕星号粒子 | 表示敌人"无法行动" |
| DEAD | 死亡崩溃动画 | 死亡粒子消散 | 表示敌人"已死亡" |

### behavior_hint专属视觉特征

每种behavior_hint必须有独特的视觉特征，让玩家在0.5秒内识别威胁类型：

| behavior_hint | 视觉特征 | 状态标识 | 识别规则 |
|---------------|----------|----------|----------|
| SWARM_CHARGE | 密集集群移动，无特殊发光 | 移动动画节奏一致 | 集群逼近 = 数量威胁 |
| WALL_BREAKER | 携带拆墙工具（锤/钻），目标锁定墙体 | 专攻墙体动画 | 锤/钻图标 = 墙体威胁 |
| TRACKER_HUNT | 高速移动，红色追踪光束 | 追踪锁定光效 | 红色光束 = 战车威胁 |
| PATROL_GUARD | 规律巡逻路径，区域标记光圈 | 区域光圈显示 | 区域光圈 = 区域威胁 |
| SNIPER_RANGE | 保持距离，瞄准光束 | 瞄准光效 + 距离保持 | 远距瞄准 = 远程威胁 |
| AMBUSHER_HIDE | 半透明隐藏，触发区域标记 | 透明度变化 | 半透明 = 潜在伏击 |
| SUMMONER_CALL | 召唤手势，召唤光效 | 召唤光效 + 增援出现 | 召唤手势 = 增援威胁 |
| SUPPORT_BUFF | 光环增强，增强效果扩散 | 增强光环显示 | 光环扩散 = 增强威胁 |

### Audio Behavior Indicators

敌人AI行为必须有音频反馈，增强威胁感知：

| AI事件 | 音效类型 | 音效强度 | 目的 |
|--------|----------|----------|------|
| 目标锁定 | 低频警告音 | 低（环境） | 提示敌人已检测到目标 |
| 攻击准备 | 高频警告音 | 中（警报） | 提示即将攻击 |
| 攻击触发 | 攻击动作音效 | 高（即时） | 即时攻击反馈 |
| 状态转换 | 状态切换音效 | 低（过渡） | 状态变化反馈 |
| 追踪锁定 | 追踪锁定警告音 | 中（警报） | TRACKER_HUNT专属警告 |
| 召唤增援 | 召唤音效 | 高（警报） | SUMMONER专属警告 |

### behavior_hint专属音效

| behavior_hint | 专属音效 | 音效触发时机 |
|---------------|----------|--------------|
| SWARM_CHARGE | 集群移动脚步声（多敌人叠加） | 移动时持续 |
| WALL_BREAKER | 拆墙撞击音效 | 墙体攻击时 |
| TRACKER_HUNT | 追踪锁定警告音 + 高速移动风声 | 锁定战车时 + 移动时 |
| SNIPER_RANGE | 瞄准警告音 + 射击音效 | 瞄准开始 + 攻击时 |
| AMBUSHER_HIDE | 伏击触发音效（突然出现） | 伏击触发时 |
| SUMMONER_CALL | 召唤手势音效 + 增援出现音效 | 召唤开始 + 增援生成时 |
| SUPPORT_BUFF | 增强光环激活音效 | 增强激活时 |

## UI Requirements

敌人AI系统是纯后台系统，无直接UI交互。所有AI状态信息通过敌人视觉表现间接传达。

### 无直接UI需求

- 敌人AI状态（IDLE/MOVE/ATTACK）通过敌人动画和VFX表现，无需HUD显示
- behavior_hint类型通过敌人视觉特征识别，无需图标/标签
- 攻击冷却、路径规划等内部状态无需UI暴露

### 间接UI依赖（下游系统）

| 下游系统 | UI需求来源 | 信息传递 |
|----------|------------|----------|
| **CombatFeedbackSystem** | 攻击事件 → HUD伤害显示 | AI触发攻击时，反馈系统显示伤害数字 |
| **TurretSystem** | 敌人位置 → 瞄准UI | AI暴露位置供炮塔瞄准线显示 |
| **HUDSystem** | 尸潮预警 → 敌人数量显示 | 生成系统统计敌人数量，AI无直接贡献 |

### 开发调试需求（非玩家UI）

- **AI状态可视化**（开发模式）：开发者可通过调试开关显示敌人当前状态标签
- **路径可视化**（开发模式）：开发者可显示NavigationAgent2D路径线用于调试
- **目标优先级可视化**（开发模式）：开发者可显示目标优先级分数用于调优

## Acceptance Criteria

### Core Behavior Coverage

**AC-01**: GIVEN an enemy instance with behavior_hint=SWARM_CHARGE, WHEN initialized, THEN enemy moves toward nearest player/defense target via NavigationAgent2D, triggers attack on collision contact.

**AC-02**: GIVEN an enemy instance with behavior_hint=WALL_BREAKER, WHEN multiple targets exist (player + wall), THEN enemy prioritizes wall target (target_weight×2.0), attacks wall structure exclusively.

**AC-03**: GIVEN an enemy instance with behavior_hint=TRACKER_HUNT, WHEN vehicle moves at speed=2.5, THEN enemy recalculates path every 0.1 seconds (PATH_RECALC_INTERVAL_TRACKER), moves at hunting_speed = base_speed × 1.5.

**AC-04**: GIVEN an enemy instance with behavior_hint=SNIPER_RANGE, WHEN player approaches within attack_range, THEN enemy triggers flee behavior, sets target_position to position + flee_distance direction.

**AC-05**: GIVEN an enemy instance in MOVE_TO_TARGET state, WHEN target enters attack_range AND attack_timer <= 0, THEN state transitions to ATTACK, attack_signal emitted, attack_timer reset to attack_cooldown.

### State Machine Coverage

**AC-06**: GIVEN an enemy instance in IDLE state, WHEN no target exists for IDLE_TIMEOUT seconds (5.0s), THEN enemy remains in IDLE, no state transition occurs.

**AC-07**: GIVEN an enemy instance in ATTACK state, WHEN target dies mid-attack, THEN state transitions to IDLE immediately, attack_timer NOT reset (preserves cooldown for next target).

**AC-08**: GIVEN an enemy instance with health <= 0 in ANY state, THEN state transitions to DEAD immediately (highest priority override), movement stops, death animation triggers.

**AC-09**: GIVEN state transition from A to B, WHEN STATE_LOCK_FRAMES=3, THEN no further transitions allowed for 3 frames (debounce prevents flip-flop).

### Path Planning Coverage

**AC-10**: GIVEN an enemy instance with unreachable target (NavigationPolygon boundary), WHEN path recalculation fails MAX_PATH_RETRIES times (3), THEN enemy enters IDLE state, logs warning `"Path unreachable for enemy_id=[id]"`.

**AC-11**: GIVEN NavigationPolygon not configured on TileMap, WHEN enemy attempts path planning, THEN fallback to direct movement (`velocity = direction_to(target) × speed`), logs warning `"NavigationPolygon not defined"`.

**AC-12**: GIVEN TRACKER_HUNT enemy chasing vehicle, WHEN vehicle changes direction, THEN path recalculated within PATH_RECALC_INTERVAL_TRACKER (0.1s), new path reflects updated vehicle position.

### Behavior-Specific Coverage

**AC-13**: GIVEN multiple SWARM_CHARGE enemies overlapping at same position, WHEN SEPARATION_FORCE=0.3 and SEPARATION_RADIUS=32, THEN enemies apply Boids separation, velocities adjusted to spread apart within 1-2 seconds.

**AC-14**: GIVEN WALL_BREAKER enemy with no wall targets available, WHEN fallback triggered, THEN enemy switches target to nearest player (target_weight=1.0), behavior becomes SWARM_CHARGE equivalent.

**AC-15**: GIVEN TRACKER_HUNT enemy when vehicle is in garage (IN_GARAGE state), WHEN fallback triggered, THEN enemy behavior reverts to SWARM_CHARGE, logs `"Vehicle in garage, TRACKER_HUNT fallback to SWARM_CHARGE"`.

**AC-16**: GIVEN AMBUSHER_HIDE enemy in HIDING state with AMBUSH_ALPHA=0.3, WHEN player enters trigger zone, THEN enemy transparency resets to 1.0, state transitions to ATTACK, ambush revealed.

**AC-17**: GIVEN SUMMONER_CALL enemy, WHEN summoned_count reaches MAX_SUMMONS (5), THEN enemy enters IDLE state, stops summoning, logs `"Summoner reached max summons=5"`.

**AC-18**: GIVEN SUPPORT_BUFF enemy, WHEN nearby_enemy_count=0 (no enemies in BUFF_RADIUS=96), THEN enemy enters IDLE state, waits for other enemies to enter radius.

### Formula Coverage

**AC-19**: GIVEN enemy with speed=2.5 in HUNTING state (TRACKER_HUNT_SPEED_MULT=1.5), WHEN velocity calculated, THEN velocity magnitude = 2.5 × 1.5 = 3.75.

**AC-20**: GIVEN two targets at distance=100 and distance=80, WHEN priority_score calculated (target_weight=1.0 for both), THEN priority_scores = 100 and 80, closer target (80) selected.

**AC-21**: GIVEN target at distance=50 with wall target_weight=2.0, WHEN priority_score calculated, THEN priority_score = 50 × (1/2.0) = 25, wall prioritized over player at same distance.

**AC-22**: GIVEN enemy with attack_cooldown=1.0s, WHEN attack triggered, THEN attack_timer reset to 1.0, countdown begins: after 60 frames (1s), attack_timer=0 ready for next attack.

## Open Questions

| ID | Question | Owner | Target Resolution | Status |
|----|----------|-------|-------------------|--------|
| Q-001 | NavigationPolygon生成自动化：TileMap可行走区域应自动生成还是手动配置？自动生成可能与动态方块（挖掘/放置）冲突。 | TileMapWorldSystem GDD | Before EnemyAI implementation | Open |
| Q-002 | 多目标选择策略优化：当前采用priority_score计算，是否需要更复杂策略（如威胁类型优先、玩家意图预测）？ | EnemyAI原型测试 | After basic implementation | Open |
| Q-003 | SUMMONER召唤类型选择：召唤哪种敌人类型？是否应从EnemyTypeDB读取召唤配置还是硬编码？ | EnemyTypeDatabase扩展 | Before SUMMONER implementation (Day 10+) | Open |
| Q-004 | PATROL_GUARD巡逻路径定义：巡逻路径应预设（场景配置）还是动态生成？路径节点数据结构如何定义？ | LevelDesign系统 | Before PATROL implementation (Day 12+) | Open |
| Q-005 | Boids分离算法性能：大量SWARM_CHARGE敌人时，分离计算是否影响帧率？是否需要优化（空间分区、批量计算）？ | Performance验证 | After大规模尸潮原型 (Day 15+) | Open |
| Q-006 | AMBUSHER触发区域定义：触发区域形状和大小如何定义？是否需要场景配置或预设模板？ | LevelDesign系统 | Before AMBUSHER implementation (Day 10+) | Open |
| Q-007 | SUPPORT增强效果具体化：增强哪些属性（伤害/速度/护甲）？增强倍率如何定义？是否从EnemyTypeDB读取？ | EnemyTypeDatabase扩展 | Before SUPPORT implementation (Day 12+) | Open |
| Q-008 | Boss behavior_hint组合：Boss敌人是否支持多种behavior_hint组合（如SUMMONER + SUPPORT）？如何实现多行为切换？ | Boss系统设计 | Before Boss implementation (Day 12+) | Open |