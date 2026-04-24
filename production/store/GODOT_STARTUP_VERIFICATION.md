# Godot Editor 启动验证清单

**铁锈魔潮**

> 使用此清单在 Godot Editor 中验证所有 Release Phase 系统
> **日期**: 2026-04-25

---

## 验证步骤

### 1. 打开项目

```
1. 打开 Godot 4.6 Editor
2. 导入项目: D:\ai\Claude-Code-Game-Studios
3. 等待资源重新扫描完成
```

### 2. 检查 Autoload 加载

打开 `Output` 面板，查看启动日志：

**期望输出**:
```
[GlobalSignals] Event bus initialized — 35+ signals defined
[LocalizationManager] Loaded XX strings for locale: zh
[VersionManager] Version: 0.1.0-alpha
[AudioManager] SFX pool initialized (8 players)
[AnalyticsManager] Session started: [UUID]
[AchievementManager] Loaded XX achievements
[CrashManager] Initialized
[SteamManager] Initialized (placeholder mode)
[TutorialManager] Initialized
[GameEntry] All systems initialized
```

**失败检查**:
- 如果任何 Manager 报错，检查 `project.godot` Autoload 配置
- 确保 Autoload 路径正确 (例如 `res://src/audio/audio_manager.gd`)

### 3. 运行主场景

点击 `Play` 按钮运行 `res://src/app_root.tscn`

**期望行为**:
- MainMenu 显示正确
- BGM 播放 (bgm_menu - 需要音频文件)
- 按钮 UI 交互正常

**按钮测试**:
| 按钮 | 期望行为 |
|------|----------|
| 开始游戏 | 进入 GameScene，Tutorial 启动 |
| 继续游戏 | 尝试加载存档 |
| 设置 | 打开 SettingsScreen |
| 制作名单 | 滚动显示 CreditsScreen |
| 退出 | 退出游戏 |

### 4. 测试暂停菜单

游戏中按 `ESC` 或 `Pause` 键：

**期望行为**:
- PauseMenu 显示
- 游戏暂停
- 音乐停止或降低音量
- Resume/Quit 按钮正常工作

### 5. 运行 GUT 测试

打开 `GUT` 面板:

```
1. 点击 Editor → GUT Panel
2. 选择测试目录: tests/unit
3. 点击 Run All Tests
```

**期望结果**:
- 所有 Release Phase 测试通过
- 新增测试文件:
  - `tests/unit/audio/audio_manager_test.gd`
  - `tests/unit/achievement/achievement_manager_test.gd`
  - `tests/unit/analytics/analytics_manager_test.gd`
  - `tests/unit/crash/crash_manager_test.gd`
  - `tests/unit/ui/tutorial_manager_test.gd`
  - `tests/unit/utils/uuid_test.gd`
  - `tests/integration/release_systems_test.gd`

### 6. 验证数据加载

检查以下数据文件加载正常：

| 文件 | 验证方式 |
|------|----------|
| `audio_config.json` | AudioManager._audio_config 存在 |
| `achievements.json` | AchievementManager._definitions 存在 |
| `version.json` | VersionManager 显示正确版本 |
| `strings-zh.json` | LocalizationManager.tr() 返回中文 |

### 7. 检查 GlobalSignals

在脚本中添加测试信号：

```gdscript
# 在任意节点 _ready() 中添加
GlobalSignals.sfx_played.connect(func(sfx_name): print("SFX: %s" % sfx_name))
GlobalSignals.achievement_notification.connect(func(id, name): print("Achievement: %s" % name))
GlobalSignals.tutorial_completed.connect(func(): print("Tutorial Done"))
```

---

## 常见问题修复

### 问题 1: Autoload 未加载

**症状**: `Get "res://src/audio/audio_manager.gd"` 报错

**修复**:
- 打开 `project.godot`
- 检查 `[autoload]` 部分
- 确保路径格式正确: `ManagerName="*res://src/path/manager.gd"`

### 问题 2: 音频文件缺失

**症状**: `AudioManager.play_sfx()` 无声音

**修复**:
- 使用 sfxr.me 生成音频文件
- 放入 `assets/audio/sfx/` 对应目录
- 确保 `audio_config.json` 中的文件名匹配

### 问题 3: 测试失败

**症状**: GUT 测试报错 `preload` 或 `class_name`

**修复**:
- 已知问题: headless 模式限制
- 在 Editor GUT 面板运行测试 (非 CLI)
- 参考: `production/qa/test-env-fix-final-2026-04-25.md`

### 问题 4: 场景引用缺失

**症状**: `@onready var _main_menu = $MainMenu` 返回 null

**修复**:
- 打开 `app_root.tscn`
- 确保子节点名称正确: `MainMenu`, `PauseMenu`, `CreditsScreen`, `GameScene`
- 检查节点路径

---

## 验证完成清单

- [ ] 项目在 Godot 4.6 中打开无错误
- [ ] 所有 Autoload 正常加载
- [ ] MainMenu 显示并可交互
- [ ] PauseMenu 正常工作
- [ ] CreditsScreen 滚动正常
- [ ] SettingsScreen 显示正常
- [ ] GUT 测试全部通过
- [ ] GlobalSignals 连接正常
- [ ] 数据文件正确加载

---

## 下一步

验证完成后：
1. 使用 sfxr.me 创建音频文件 (见 `AUDIO_GENERATION_GUIDE.md`)
2. 运行游戏截图 (见 `SCREENSHOTS_CAPTURE_GUIDE.md`)
3. 注册 Steamworks 账号
4. 开始 Must Have 任务

---

*Godot Editor Startup Verification Checklist — 铁锈魔潮*
*Generated: 2026-04-25*