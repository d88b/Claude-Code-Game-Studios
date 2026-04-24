# Screenshots Capture Guide

**Story**: screenshots-001
**Date**: 2026-04-25

---

## 准备工作

### 1. 打开 Godot Editor

```bash
# 启动 Godot Editor
godot4 --editor
```

或直接打开项目: `D:\ai\Claude-Code-Game-Studios\project.godot`

### 2. 打开主游戏场景

- 在 Editor 中打开 `src/playable_main_game.tscn` 或 `src/world/tilemap_world.tscn`
- 按 F6 运行当前场景

---

## 截图方法

### 方法 1: Godot 内置截图

1. 运行游戏后按 **F12** 或 **Ctrl+S** (某些配置)
2. 截图保存到 `user://` 目录
3. 需要查找截图位置

### 方法 2: Windows 截图工具

1. 运行游戏
2. 按 **Win + Shift + S** 打开截图工具
3. 选择区域截图
4. 保存到 `production/store/screenshots/`

### 方法 3: OBS Studio

1. 打开 OBS Studio
2. 添加 "Game Capture" 源
3. 选择 Godot 窗口
4. 按 **F10** 截图

---

## 需要拍摄的截图 (10 张)

### Screenshot 1: 战车探索

**场景**: 地表废土
**要求**:
- 战车在画面中央
- 地形/废墟背景可见
- HUD 显示 (HP/MP/时间)

**操作**:
- F6 运行 `src/playable_main_game.tscn`
- 驾驶战车移动
- 截图

---

### Screenshot 2: 挖掘建造

**场景**: 地堡内部
**要求**:
- 玩家正在挖掘方块
- 或放置设施
- 可见交互反馈

**操作**:
- 按下 dig 输入 (E 键)
- 鼠标指向方块
- 截图挖掘动画

---

### Screenshot 3: 尸潮防守

**场景**: 防守波次
**要求**:
- 多个僵尸敌人可见
- 炮塔/战车射击
- 紧张战斗氛围

**操作**:
- 等待 spawn wave 触发
- 或手动触发敌人
- 截图战斗场景

---

### Screenshot 4: 资源收集

**场景**: 资源掉落
**要求**:
- 资源掉落物品可见
- 战车接近拾取
- 收集反馈

**操作**:
- 消灭敌人触发掉落
- 截图掉落物品

---

### Screenshot 5: 日夜对比 (白天)

**场景**: 白天环境
**要求**:
- 明亮色调
- 天空/光照清晰

**操作**:
- 等待 Day phase
- 截图明亮场景

---

### Screenshot 6: 日夜对比 (夜晚)

**场景**: 夜晚环境
**要求**:
- 暗色调
- 危险氛围
- 对比白天截图

**操作**:
- 等待 Night phase
- 截图暗色场景

---

### Screenshot 7: HUD 界面

**场景**: HUD 完整显示
**要求**:
- HP/MP bars
- 时间显示
- 阶段指示器
- 警告提示

**操作**:
- 截图 HUD 区域
- 可裁剪为 1920x200 区域

---

### Screenshot 8: 设施布局

**场景**: 地堡俯视
**要求**:
- 多个设施可见
- 布局清晰

**操作**:
- 暂停游戏
- 截图地堡布局

---

### Screenshot 9: BOSS/敌人类型

**场景**: 不同敌人
**要求**:
- 展示僵尸多样性
- 或 BOSS 出现

**操作**:
- 触发不同敌人类型
- 截图敌人展示

---

### Screenshot 10: 危险警告

**场景**: 魔能耗尽警告
**要求**:
- 警告 UI 显示
- 紧迫感

**操作**:
- 消耗魔能到低值
- 截图警告提示

---

## 截图规格

| 项目 | 规格 |
|------|------|
| **分辨率** | 1920x1080 (16:9) |
| **格式** | PNG |
| **命名** | `screenshot_XX_description.png` |

---

## 截图后期处理

### 允许的处理
- 轻微亮度调整
- 裁剪为标准分辨率

### 禁止的处理
- 添加不存在的内容
- 过度滤镜

---

## 截图保存位置

```
D:\ai\Claude-Code-Game-Studios\production\store\screenshots\
```

创建目录:

```bash
mkdir -p production/store/screenshots
```

---

## 截图检查清单

| # | 内容 | 文件名 | 状态 |
|---|------|--------|------|
| 1 | 战车探索 | screenshot_01_exploration.png | ⏳ |
| 2 | 挖掘建造 | screenshot_02_building.png | ⏳ |
| 3 | 尸潮防守 | screenshot_03_defense.png | ⏳ |
| 4 | 资源收集 | screenshot_04_collection.png | ⏳ |
| 5 | 白天场景 | screenshot_05_day.png | ⏳ |
| 6 | 夜晚场景 | screenshot_06_night.png | ⏳ |
| 7 | HUD 界面 | screenshot_07_hud.png | ⏳ |
| 8 | 设施布局 | screenshot_08_layout.png | ⏳ |
| 9 | 敌人类型 | screenshot_09_enemies.png | ⏳ |
| 10 | 危险警告 | screenshot_10_warning.png | ⏳ |

---

## 完成后

截图完成后，将文件放入 `production/store/screenshots/` 目录。

然后运行验证:

```bash
ls production/store/screenshots/
# 应显示 10 个 PNG 文件
```

---

*Screenshots Capture Guide — screenshots-001*