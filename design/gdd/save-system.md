# Save/Load System — 存档系统

> **Status**: Designed
> **Created**: 2026-04-25
> **Priority**: MVP (Release blocker)
> **Layer**: Foundation

---

## Overview

存档系统负责持久化游戏状态，确保玩家进度在退出游戏后可以恢复。核心功能包括：自动存档、手动存档、存档槽管理、存档验证。存档数据包含：战车状态、地堡布局、资源库存、时间进度、设施状态、探索区域进度。

**玩家体验**: 玩家退出游戏后，下次启动时能无缝恢复进度，不丢失任何探索成果。

---

## Player Fantasy

**情感目标**: 安全感与持续感

玩家在末世环境中投入大量时间建设地堡和改装战车，存档系统让这些努力有意义。每次启动游戏，玩家看到熟悉的布局和积累的资源，感受到"我昨天在这里，今天继续前进"的持续感。

**锚定时刻**: Day 10 时玩家花费了5小时建设复杂地堡防线，退出游戏后第二天启动，看到地堡完整无损、资源库存清晰、进度继续从 Day 10 开始——没有任何丢失，玩家信任游戏系统。

---

## Detailed Rules

### Core Rules

**Rule 1: 自动存档触发时机**

自动存档在以下时机触发：

| Trigger | Frequency | Reason |
|---------|-----------|---------|
| 返回地堡 (BUNKER 状态) | Every | 确保探索成果保存 |
| 设施建造完成 | Every | 防止建设成果丢失 |
| 设施拆除 | Every | 同步状态变化 |
| 战车改装完成 | Every | 保存战车配置 |
| Day 结束 (进入 NIGHT) | Every | 保存每日进度 |
| 游戏退出请求 | Every | 防止强制退出丢失 |

---

**Rule 2: 存档槽管理**

游戏支持 3 个存档槽：

| Slot | Name | Purpose |
|------|------|---------|
| Slot 1 | 主存档 | 默认游玩进度 |
| Slot 2 | 备份存档 | 手动备份 |
| Slot 3 | 测试存档 | 新版本测试/重玩 |

存档槽限制：
- 每个存档槽独立存储
- 存档文件大小上限：1MB
- 存档数量上限：3（不支持额外创建）

---

**Rule 3: 存档数据结构**

存档文件包含以下数据模块：

| Module | Data | Size Estimate |
|--------|------|---------------|
| `game_state` | 当前状态、天数、时间 | ~500 bytes |
| `vehicle` | 位置、生命值、魔能、配置 | ~1KB |
| `bunker_layout` | 已挖掘方块、已放置方块 | ~50KB (sparse storage) |
| `resources` | 资源库存字典 | ~2KB |
| `facilities` | 设施状态列表 | ~5KB |
| `areas` | 已发现区域、探索进度 | ~1KB |
| `stats` | 累计统计（击杀数、收集量） | ~500 bytes |
| `version` | 存档版本号、游戏版本 | ~100 bytes |

**Total Estimate**: ~60KB per save slot

---

**Rule 4: 存档文件格式**

存档使用 JSON 格式存储：

```
user://saves/save_slot_1.json
user://saves/save_slot_2.json
user://saves/save_slot_3.json
```

JSON 结构：
```json
{
  "version": "1.0.0",
  "game_version": "0.1.0-alpha",
  "saved_at": "2026-04-25T14:30:00Z",
  "game_state": { ... },
  "vehicle": { ... },
  "bunker_layout": { ... },
  "resources": { ... },
  "facilities": { ... },
  "areas": { ... },
  "stats": { ... }
}
```

---

**Rule 5: 存档验证**

加载存档时执行验证：

| Check | Failure Action |
|-------|----------------|
| 文件存在性 | 显示"存档不存在"提示 |
| JSON 解析 | 显示"存档损坏"提示 |
| 版本兼容性 | 尝试迁移或显示"版本不兼容" |
| 数据完整性 | 显示"存档数据损坏"提示 |

---

**Rule 6: 版本迁移**

存档版本迁移策略：

| From Version | To Version | Migration |
|--------------|------------|-----------|
| 1.0.x | 1.1.x | 自动迁移，添加新字段默认值 |
| 1.x | 2.x | 提示玩家存档不兼容，建议重新开始 |

---

## Formulas

### Formula 1: 存档文件大小估算

`save_size = base_size + layout_tiles × tile_entry_size + facilities × facility_entry_size`

**Variables**:

| Variable | Type | Value | Description |
|----------|------|-------|-------------|
| `base_size` | int | 60KB | 基础数据模块大小 |
| `layout_tiles` | int | 0-1000 | 已修改方块数量 |
| `tile_entry_size` | int | 50 bytes | 每个方块条目大小 |
| `facilities` | int | 0-20 | 设施数量 |
| `facility_entry_size` | int | 256 bytes | 每个设施条目大小 |

**Example**: 500 tiles + 10 facilities → 60KB + 500×50 + 10×256 = 60KB + 25KB + 2.5KB = ~87.5KB

---

### Formula 2: 自动存档间隔

`auto_save_interval = max(MIN_INTERVAL, last_action_time + BUFFER_TIME)`

**Variables**:

| Variable | Type | Value | Description |
|----------|------|-------|-------------|
| `MIN_INTERVAL` | float | 60 seconds | 最小存档间隔 |
| `BUFFER_TIME` | float | 30 seconds | 操作后缓冲时间 |
| `last_action_time` | float | Dynamic | 上次重要操作时间 |

**Output**: 防止频繁存档影响性能

---

## Edge Cases

1. **存档槽已满**: 玩家尝试存档到已有存档的槽位 → 显示覆盖确认对话框

2. **存档损坏恢复**: 存档文件部分损坏 → 尙尝试恢复基础数据（游戏状态），丢失 bunker_layout

3. **新游戏版本存档**: 游戏更新后存档版本不匹配 → 显示版本迁移对话框

4. **强制退出未存档**: 游戏崩溃或玩家强制关闭 → 下次启动显示"上次进度未保存"提示

5. **存档文件锁定**: 存档过程中游戏退出 → 使用原子写入（先写临时文件，再重命名）

6. **存档位置不可访问**: `user://` 目录权限问题 → 显示"存档失败"错误，建议检查权限

7. **跨平台存档迁移**: Steam vs Epic 存档位置不同 → 使用 Godot 标准 `user://` 路径，自动处理跨平台

---

## Dependencies

### Upstream Dependencies

| System | Status | Data Flow |
|--------|--------|-----------|
| **GameState** | Implemented | 状态枚举 → 存档 `game_state` |
| **VehicleAttribute** | Implemented | 生命值/魔能 → 存档 `vehicle` |
| **TileMapWorld** | Implemented | 方块布局 → 存档 `bunker_layout` |
| **ResourceDB** | Implemented | 资源库存 → 存档 `resources` |
| **FacilityController** | Implemented | 设施状态 → 存档 `facilities` |
| **AreaManager** | Implemented | 区域进度 → 存档 `areas` |

### Downstream Dependencies

| System | Status | Data Flow |
|--------|--------|-----------|
| **主菜单** | Not Implemented | 存档槽选择 → 加载存档 |
| **暂停菜单** | Not Implemented | 手动存档按钮 |
| **新游戏流程** | Not Implemented | 存档槽创建 |

---

## Tuning Knobs

| Knob ID | Knob Name | Default | Range | Affects |
|---------|-----------|---------|-------|---------|
| **TK-S001** | `AUTO_SAVE_MIN_INTERVAL` | 60s | 30-120s | 自动存档最小间隔 |
| **TK-S002** | `SAVE_FILE_SIZE_LIMIT` | 1MB | 512KB-2MB | 存档文件大小上限 |
| **TK-S003** | `MAX_SAVE_SLOTS` | 3 | 1-5 | 存档槽数量上限 |
| **TK-S004** | `SAVE_VERSION` | 1.0.0 | — | 当前存档版本号 |

---

## Acceptance Criteria

**AC-01**: GIVEN 玩家返回地堡, WHEN 自动存档触发, THEN 存档文件写入成功, 文件大小 ≤ 1MB.

**AC-02**: GIVEN 存档文件存在, WHEN 玩家选择加载存档, THEN 游戏状态恢复到存档时刻.

**AC-03**: GIVEN 存档文件损坏, WHEN 玩家尝试加载, THEN 显示"存档损坏"错误提示.

**AC-04**: GIVEN 存档版本 1.0, WHEN 游戏版本 1.1, THEN 存档自动迁移成功, 无数据丢失.

**AC-05**: GIVEN 玩家选择新游戏, WHEN 存档槽已有存档, THEN 显示"覆盖存档?"确认对话框.

**AC-06**: GIVEN 存档文件 500KB, WHEN 加载存档, THEN 加载时间 ≤ 2秒.

**AC-07**: GIVEN 3 个存档槽全部有存档, WHEN 玩家查看存档列表, THEN 显示所有存档的日期、天数、状态.

---

## Open Questions

| ID | Question | Owner | Target Resolution | Status |
|----|----------|-------|-------------------|--------|
| Q-S01 | 存档是否需要加密？防止玩家修改存档作弊？ | Technical Director | Before Alpha | Open |
| Q-S02 | Steam/Epic 云存档同步是否需要？ | Producer | Before Release | Open |
| Q-S03 | 存档是否包含成就进度？ | Game Designer | Before Release | Open |

---

## Implementation Priority

**Release blocker**: 存档系统是发布必需功能。

**Suggested Story Breakdown**:

| Story | Type | Estimate | Priority |
|-------|------|----------|----------|
| save-001: 存档数据结构设计 | Logic | 1 day | P1 |
| save-002: 自动存档触发实现 | Logic | 2 days | P1 |
| save-003: 存档加载实现 | Logic | 2 days | P1 |
| save-004: 存档槽管理 UI | UI | 1 day | P1 |
| save-005: 存档验证与迁移 | Logic | 1 day | P2 |

**Total Estimate**: 7 days

---

*Save System GDD — Created for Release blocker resolution.*