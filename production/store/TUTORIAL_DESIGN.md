# Tutorial System Design

**铁锈魔潮 (Rust Magic Tide)**

---

## 概述

Tutorial 系统引导新玩家理解核心玩法：战车驾驶、挖掘建造、尸潮防守。

---

## Tutorial 目标

| 阶段 | 目标 | 时长 |
|------|------|------|
| **新手引导** | 理解基本操作 | 2-3 分钟 |
| **系统教学** | 理解核心系统 | 5-10 分钟 |
| **首次探索** | 完成一个完整循环 | 10-15 分钟 |

---

## Tutorial 内容

### Phase 1: 基础操作 (2-3分钟)

| 步骤 | 内容 | 提示方式 |
|------|------|----------|
| 1 | WASD 移动战车 | 屏幕提示 + 箭头指示 |
| 2 | 鼠标瞄准射击 | 高亮炮塔 + 目标指示 |
| 3 | E 键挖掘 | 高亮方块 + 进度条 |
| 4 | Q 键放置 | 高亮设施位置 |

### Phase 2: 核心系统 (5-10分钟)

| 步骤 | 内容 | 提示方式 |
|------|------|----------|
| 1 | HP/MP 管理 | HUD 解说框 |
| 2 | 日夜循环 | 时间轴解说 |
| 3 | 资源收集 | 掉落物品解说 |
| 4 | 返回地堡 | Retreat 解说 |

### Phase 3: 首次探索 (10-15分钟)

| 步骤 | 内容 | 提示方式 |
|------|------|----------|
| 1 | 出发探索 | 任务提示 |
| 2 | 搜集资源 | 目标计数 |
| 3 | 遭遇敌人 | 战斗指导 |
| 4 | 安全返回 | 时间警告 |

---

## Tutorial UI

### 提示框设计

```
┌─────────────────────────────────────┐
│ 💡 提示: 移动战车                      │
│ 使用 WASD 键驾驶战车移动               │
│                                      │
│ [W] 向上                              │
│ [A] 向左   [S] 向下   [D] 向右         │
│                                      │
│              [下一步]                  │
└─────────────────────────────────────┘
```

### 高亮系统

- 目标区域高亮显示
- 箭头指示操作位置
- 动画引导点击位置

---

## Implementation

### Tutorial Manager

```gdscript
# src/ui/tutorial_manager.gd
class_name TutorialManager extends Node

signal tutorial_step_completed(step_id: int)
signal tutorial_phase_completed(phase_id: int)

enum Phase { BASICS, SYSTEMS, FIRST_EXPLORE }

var _current_phase: Phase = Phase.BASICS
var _current_step: int = 0
var _is_active: bool = false

var _tutorial_data: Array = [
    # Phase 0: Basics
    {
        "phase": 0,
        "steps": [
            {"id": 0, "text": "tutorial.move", "action": "move"},
            {"id": 1, "text": "tutorial.fire", "action": "fire"},
            {"id": 2, "text": "tutorial.dig", "action": "dig"},
            {"id": 3, "text": "tutorial.place", "action": "place"},
        ]
    },
    # Phase 1: Systems
    {
        "phase": 1,
        "steps": [
            {"id": 0, "text": "tutorial.hp_mp", "action": "show_hud"},
            {"id": 1, "text": "tutorial.daynight", "action": "show_time"},
            {"id": 2, "text": "tutorial.resources", "action": "collect"},
            {"id": 3, "text": "tutorial.return", "action": "retreat"},
        ]
    },
]

func start_tutorial() -> void:
    _is_active = true
    _current_phase = Phase.BASICS
    _current_step = 0
    _show_current_step()

func _show_current_step() -> void:
    var step_data: Dictionary = _tutorial_data[_current_phase]["steps"][_current_step]
    # 显示提示框
    # 高亮相关元素

func advance_step() -> void:
    _current_step += 1
    if _current_step >= _tutorial_data[_current_phase]["steps"].size():
        _complete_phase()
    else:
        _show_current_step()

func _complete_phase() -> void:
    tutorial_phase_completed.emit(_current_phase)
    _current_phase += 1
    _current_step = 0
    if _current_phase >= Phase.size():
        _complete_tutorial()
    else:
        _show_current_step()

func _complete_tutorial() -> void:
    _is_active = false
    print("[Tutorial] Complete!")
    # 返回正常游戏
```

---

## Tutorial 场景

创建 `src/tutorial/tutorial_scene.tscn`:

- 简化版游戏场景
- 预设引导路线
- 安全环境（无危险敌人）
- 目标物品已放置

---

## Skip 选项

- 玩家可选择跳过 Tutorial
- 设置保存: `tutorial_completed: bool`
- 首次启动询问是否需要 Tutorial

---

## Localization

添加 Tutorial 文本到 strings-en.json:

```json
{
  "tutorial.move": {
    "source": "使用 WASD 键移动战车",
    "context": "Tutorial: movement controls"
  },
  "tutorial.fire": {
    "source": "点击鼠标左键射击",
    "context": "Tutorial: firing controls"
  },
  "tutorial.dig": {
    "source": "按 E 键挖掘方块",
    "context": "Tutorial: digging controls"
  },
  "tutorial.place": {
    "source": "按 Q 键放置设施",
    "context": "Tutorial: placement controls"
  },
  "tutorial.hp_mp": {
    "source": "HP 是生命值，MP 是魔能",
    "context": "Tutorial: HUD explanation"
  },
  "tutorial.daynight": {
    "source": "夜晚更危险，尽快返回",
    "context": "Tutorial: day/night cycle"
  },
  "tutorial.resources": {
    "source": "收集资源用于建造",
    "context": "Tutorial: resource collection"
  },
  "tutorial.return": {
    "source": "按 R 键返回地堡",
    "context": "Tutorial: retreat controls"
  },
  "tutorial.skip_prompt": {
    "source": "跳过教程?",
    "context": "Tutorial skip prompt"
  }
}
```

---

## 文件清单

| 文件 | 路径 |
|------|------|
| Tutorial Manager | `src/ui/tutorial_manager.gd` |
| Tutorial Scene | `src/tutorial/tutorial_scene.tscn` |
| Tutorial Strings | `assets/data/strings/strings-en.json` |

---

*Tutorial System Design — 铁锈魔潮*