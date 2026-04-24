# Git 提交建议

**铁锈魔潮**

> **日期**: 2026-04-25
> **会话**: Release Phase Implementation
> **更改**: 32 修改 + 128 新增文件

---

## 提交策略建议

### Option A: 单次大提交 (推荐)

适合 Release Phase 作为一个完整里程碑：

```
feat(release): implement Release Phase systems

- Add AudioManager with SFX pool and BGM control
- Add AnalyticsManager with event queue and offline cache
- Add AchievementManager with 31 achievements and Steam sync
- Add CrashManager with stack trace hashing
- Add SteamManager placeholder (requires Steamworks)
- Add TutorialManager with 3-phase onboarding
- Add VersionManager for semantic version display
- Add MainMenu/PauseMenu/CreditsScreen/SettingsScreen UI
- Add AppRoot scene switching and state management
- Add UUID helper for RFC 4122 v4 generation
- Update GlobalSignals with 15+ new signals
- Add 52 localization strings (Tutorial/Credits/Achievement)
- Register 7 new Autoloads in project.godot
- Add audio_config.json (46 SFX + 7 BGM)
- Add achievements.json (31 achievements)
- Add version.json (0.1.0-alpha)
- Create audio directory structure (7 SFX categories)
- Add comprehensive test suite (7 test files)
- Add integration tests for release systems

Files: +128, Modified: 32
Autoloads: 19 total (12 + 7 new)
Signals: 35+ defined
Tests: 7 new (audio/achievement/analytics/crash/tutorial/uuid/integration)
```

### Option B: 分组提交

按系统分组提交：

1. **提交 1: Core Infrastructure**
   ```
   feat(core): add VersionManager and UUID helper
   - VersionManager reads version.json
   - UUID generates RFC 4122 v4 IDs
   - AppRoot scene switching system
   ```

2. **提交 2: Audio System**
   ```
   feat(audio): implement AudioManager and audio config
   - SFX player pool (8 channels)
   - BGM crossfade control
   - Audio Bus management
   - audio_config.json with 46 SFX + 7 BGM
   ```

3. **提交 3: Analytics & Crash**
   ```
   feat(analytics): implement telemetry and crash reporting
   - AnalyticsManager with event queue
   - CrashManager with stack trace hashing
   - Offline caching support
   ```

4. **提交 4: Achievement System**
   ```
   feat(achievement): implement achievement system
   - 31 achievements (cumulative/one-time/hidden)
   - AchievementManager with progress tracking
   - Steam sync ready
   - achievements.json config
   ```

5. **提交 5: Tutorial & Credits**
   ```
   feat(ui): add tutorial and credits screens
   - TutorialManager 3-phase system
   - CreditsScreen auto-scrolling
   - AchievementNotification popup
   ```

6. **提交 6: Main UI**
   ```
   feat(ui): implement main menu and pause menu
   - MainMenu with play/continue/settings/credits/quit
   - PauseMenu with resume/quit to menu
   - SettingsScreen with volume sliders
   - MenuButton hover/click styling
   ```

7. **提交 7: Documentation**
   ```
   docs(release): add Release Phase documentation
   - 15 design documents
   - 5 operation guides
   - 6 status reports
   - CHANGELOG update
   ```

---

## 文件分类

### 新增源代码 (14 个)

| 文件 | 路径 | 大小 |
|------|------|------|
| audio_manager.gd | src/audio/ | 9.4 KB |
| uuid.gd | src/utils/ | 2.3 KB |
| analytics_manager.gd | src/analytics/ | 8.8 KB |
| achievement_manager.gd | src/achievement/ | 14.5 KB |
| crash_manager.gd | src/crash/ | 8.3 KB |
| steam_manager.gd | src/platform/ | 5.9 KB |
| tutorial_manager.gd | src/ui/ | 11.3 KB |
| version_manager.gd | src/core/ | 3.0 KB |
| main_menu.gd | src/ui/ | 6.2 KB |
| pause_menu.gd | src/ui/ | 3.5 KB |
| credits_screen.gd | src/ui/ | 4.1 KB |
| settings_screen.gd | src/ui/ | 2.9 KB |
| achievement_notification.gd | src/ui/ | 2.5 KB |
| app_root.gd | src/ | 5.6 KB |
| game_entry.gd | src/ | 2.8 KB |

### 新增场景 (6 个)

| 文件 | 路径 |
|------|------|
| app_root.tscn | src/ |
| main_menu.tscn | src/ui/ |
| pause_menu.tscn | src/ui/ |
| credits_screen.tscn | src/ui/ |
| settings_screen.tscn | src/ui/ |
| achievement_notification.tscn | src/ui/ |

### 新增测试 (7 个)

| 文件 | 路径 |
|------|------|
| audio_manager_test.gd | tests/unit/audio/ |
| achievement_manager_test.gd | tests/unit/achievement/ |
| analytics_manager_test.gd | tests/unit/analytics/ |
| crash_manager_test.gd | tests/unit/crash/ |
| tutorial_manager_test.gd | tests/unit/ui/ |
| uuid_test.gd | tests/unit/utils/ |
| release_systems_test.gd | tests/integration/ |

### 新增数据 (6 个)

| 文件 | 路径 |
|------|------|
| strings-zh.json | assets/data/strings/ |
| audio_config.json | assets/data/ |
| achievements.json | assets/data/ |
| version.json | assets/data/ |
| steam_appid.txt | root |
| GlobalSignals (updated) | src/events/ |

### 新增文档 (22 个)

| 类别 | 数量 |
|------|------|
| 设计文档 | 15 |
| 操作指南 | 5 |
| 状态报告 | 6 |
| 集成文档 | 3 |

---

## 提交命令

### 单次提交

```bash
git add -A
git commit -m "feat(release): implement Release Phase systems..."
git push origin main
```

### 分组提交

```bash
# 提交 1: Core
git add src/core/version_manager.gd src/utils/uuid.gd src/app_root.gd src/app_root.tscn src/game_entry.gd
git commit -m "feat(core): add VersionManager and UUID helper"

# 提交 2: Audio
git add src/audio/ assets/audio/ assets/data/audio_config.json
git commit -m "feat(audio): implement AudioManager and audio config"

# 提交 3: Analytics
git add src/analytics/ src/crash/ integration/analytics/ integration/crash-reporting/
git commit -m "feat(analytics): implement telemetry and crash reporting"

# 提交 4: Achievement
git add src/achievement/ src/ui/achievement_notification.gd src/ui/achievement_notification.tscn assets/data/achievements.json integration/achievements/
git commit -m "feat(achievement): implement achievement system"

# 提交 5: Tutorial & Credits
git add src/ui/tutorial_manager.gd src/ui/credits_screen.gd src/ui/credits_screen.tscn production/store/TUTORIAL_DESIGN.md production/store/CREDITS_DESIGN.md
git commit -m "feat(ui): add tutorial and credits screens"

# 提交 6: Main UI
git add src/ui/main_menu.gd src/ui/main_menu.tscn src/ui/pause_menu.gd src/ui/pause_menu.tscn src/ui/settings_screen.gd src/ui/settings_screen.tscn src/ui/menu_button.gd design/ux/main-menu.md design/ux/pause-menu.md
git commit -m "feat(ui): implement main menu and pause menu"

# 提交 7: Documentation
git add production/store/ docs/CHANGELOG.md assets/data/version.json steam_appid.txt project.godot src/events/global_signals.gd assets/data/strings/
git commit -m "docs(release): add Release Phase documentation"
```

---

## 推送前检查

1. 确认所有文件添加
   ```bash
   git status
   ```

2. 确认提交内容
   ```bash
   git log --oneline -7
   ```

3. 推送
   ```bash
   git push origin main
   ```

---

## 推送后验证

1. GitHub Actions CI 运行检查
2. 确认提交出现在远程仓库
3. 更新 Release Phase 状态文档

---

*Git Commit Suggestions — 铁锈魔潮*
*Generated: 2026-04-25*