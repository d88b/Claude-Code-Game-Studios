# Store Preparation 索引

**铁锈魔潮**

> **版本**: 3.0
> **更新日期**: 2026-04-25
> **阶段**: Release Phase — Should Have + Nice to Have 完成

---

## 文档列表 (25 个)

### 规格文档 (5)

| 文档 | 文件名 | 状态 | 平台 |
|------|--------|------|------|
| 商店页面文案 | [STORE_PAGE_COPY.md](STORE_PAGE_COPY.md) | Draft 完成 | Steam/Epic |
| 截图规格 | [SCREENSHOT_SPEC.md](SCREENSHOT_SPEC.md) | 规格定义 | Steam/Epic |
| 预告片脚本 | [TRAILER_SCRIPT.md](TRAILER_SCRIPT.md) | Script 完成 | Steam/Epic |
| 定价策略 | [PRICING_STRATEGY.md](PRICING_STRATEGY.md) | Draft 完成 | Steam/Epic |
| 封面图规格 | [KEY_ART_SPEC.md](KEY_ART_SPEC.md) | 规格定义 | Steam/Epic |

### 操作指南 (5)

| 文档 | 文件名 | 状态 | 用途 |
|------|--------|------|------|
| 截图拍摄指南 | [SCREENSHOTS_CAPTURE_GUIDE.md](SCREENSHOTS_CAPTURE_GUIDE.md) | 完成 | Editor 截图操作 |
| Trailer 制作指南 | [TRAILER_PRODUCTION_GUIDE.md](TRAILER_PRODUCTION_GUIDE.md) | 完成 | OBS + DaVinci 流程 |
| Key Art 创作指南 | [KEYART_CREATION_GUIDE.md](KEYART_CREATION_GUIDE.md) | 完成 | 尺寸 + 设计构思 |
| IARC 提交指南 | [IARC_SUBMISSION_GUIDE.md](IARC_SUBMISSION_GUIDE.md) | 完成 | 年龄分级问卷 |
| Steam SDK 指南 | [STEAM_SDK_GUIDE.md](STEAM_SDK_GUIDE.md) | 完成 | Steamworks 集成 |

### 系统设计文档 (3)

| 文档 | 文件名 | 状态 | 实现状态 |
|------|--------|------|----------|
| 音频系统设计 | [AUDIO_DESIGN.md](AUDIO_DESIGN.md) | 完成 | AudioManager 已实现 |
| Credits 设计 | [CREDITS_DESIGN.md](CREDITS_DESIGN.md) | 完成 | CreditsScreen 已实现 |
| Tutorial 设计 | [TUTORIAL_DESIGN.md](TUTORIAL_DESIGN.md) | 完成 | TutorialManager 已实现 |

### 状态报告 (9)

| 文档 | 文件名 | 状态 | 用途 |
|------|--------|------|------|
| Release 清单 | [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) | 完成 | 完成状态追踪 |
| Release Phase 状态 | [RELEASE_PHASE_STATUS.md](RELEASE_PHASE_STATUS.md) | 完成 | Sprint 任务状态 |
| Release 状态报告 | [RELEASE_STATUS_REPORT.md](RELEASE_STATUS_REPORT.md) | 完成 | Blocker 解决汇总 |
| 会话总结 | [SESSION_SUMMARY_2026-04-25.md](SESSION_SUMMARY_2026-04-25.md) | 完成 | 本次会话工作汇总 |
| 会话完成 | [SESSION_COMPLETE.md](SESSION_COMPLETE.md) | 完成 | 会话完成清单 |
| Godot 启动验证 | [GODOT_STARTUP_VERIFICATION.md](GODOT_STARTUP_VERIFICATION.md) | 完成 | Editor 验证清单 |
| 系统验证报告 | [SYSTEM_VERIFICATION_REPORT.md](SYSTEM_VERIFICATION_REPORT.md) | 完成 | 系统状态汇总 |
| Git 提交建议 | [GIT_COMMIT_SUGGESTIONS.md](GIT_COMMIT_SUGGESTIONS.md) | 完成 | 提交策略 |
| 音频生成指南 | assets/audio/AUDIO_GENERATION_GUIDE.md | 完成 | sfxr.me 使用指南 |

---

## 集成系统文档 (3)

| 文档 | 路径 | 状态 | 实现状态 |
|------|------|------|----------|
| 遥测系统设计 | integration/analytics/ANALYTICS_DESIGN.md | 完成 | AnalyticsManager 已实现 |
| 崩溃报告设计 | integration/crash-reporting/CRASH_DESIGN.md | 完成 | CrashManager 已实现 |
| 成绩系统设计 | integration/achievements/ACHIEVEMENT_DESIGN.md | 完成 | AchievementManager 已实现 |

---

## Sprint 状态

| 优先级 | 完成 | 待完成 |
|--------|------|--------|
| Must Have | 0 | 6 (需外部依赖) |
| Should Have | 3 | 0 |
| Nice to Have | 3 | 0 |

### Must Have 待执行任务

| 任务 | 指南文档 | 预计时间 | 状态 |
|------|----------|----------|------|
| 拍摄截图 | SCREENSHOTS_CAPTURE_GUIDE.md | 4 小时 | 待 Godot Editor |
| 制作 Trailer | TRAILER_PRODUCTION_GUIDE.md | 21 小时 | 待 OBS + DaVinci |
| 创作 Key Art | KEYART_CREATION_GUIDE.md | 18 小时 | 待设计软件 |
| 提交 IARC | IARC_SUBMISSION_GUIDE.md | 1 小时 | 待 Steamworks 账号 |
| Steam SDK 集成 | STEAM_SDK_GUIDE.md | 2-3 小时 | 待 Steamworks 账号 |
| Production Sprites | - | 3-5 天 | 待美术资源 |

---

## 文件统计

| 类别 | 文件数 |
|------|--------|
| 规格文档 | 5 |
| 操作指南 | 5 |
| 系统设计 | 3 |
| 状态报告 | 9 |
| 集成系统 | 3 |
| 总计 | 25 |

---

## 下一步

### 立即可执行
1. 验证系统 - 在 Godot Editor 中运行并验证 (GODOT_STARTUP_VERIFICATION.md)
2. 创建音频 - 使用 sfxr.me 生成音效 (assets/audio/AUDIO_GENERATION_GUIDE.md)
3. 运行测试 - GUT Panel 验证所有测试通过

### 需要外部资源
4. 注册 Steamworks 开发者账号 ($100)
5. 下载 GodotSteam GDExtension
6. 使用设计软件创作 Key Art
7. 使用 OBS + DaVinci 制作 Trailer

---

*Store Preparation 索引 - Release Phase*
*Updated: 2026-04-25*