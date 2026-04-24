# Changelog

All notable changes to 铁锈魔潮 (Rust Magic Tide) will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased] — 2026-04-25

### Added

#### Release Phase Systems (2026-04-25)

##### Audio & Feedback
- **AudioManager** — SFX player pool (8 channels), BGM crossfade, bus management (Master/BGM/SFX/UI)
- **Achievement Notification** — Toast popup with auto-dismiss, queue system, visual feedback

##### Analytics & Telemetry
- **AnalyticsManager** — Event queue with batch upload, offline caching (50 events), privacy controls
- **CrashManager** — Stack trace hashing, report caching, upload queue, session tracking

##### Achievement System
- **AchievementManager** — 31 achievements (cumulative/one-time/hidden), progress tracking, Steam sync ready

##### Platform Integration
- **SteamManager** — Steam SDK placeholder (requires GodotSteam GDExtension)
- **UUID Helper** — RFC 4122 v4 UUID generation with file persistence

##### Tutorial & Onboarding
- **TutorialManager** — 3-phase system (BASICS/SYSTEMS/FIRST_EXPLORE), prompt/highlight/completion events

##### UI Screens
- **AppRoot** — Scene switching, menu/game flow, system initialization
- **GameEntry** — Autoload validation, startup logging, shutdown handling
- **MainMenu** — Play/Continue/Settings/Credits/Quit buttons with keyboard/gamepad navigation
- **PauseMenu** — Resume/Settings/Quit to menu, pause state management
- **CreditsScreen** — Auto-scrolling credits, skip button, completion signal
- **SettingsScreen** — Volume sliders (Master/BGM/SFX), privacy toggle, persistent settings
- **MenuButton** — Hover/click styling helper for consistent UI buttons

##### Version Management
- **VersionManager** — Semantic version display, build number, stage tracking from version.json

#### Core Systems (Previous)
- **Save System** — Auto-save on bunker return, 3 save slots, JSON format with version migration
- **Localization System** — tr() wrapper for all player-facing text, English + Chinese support
- **Collision Manager** — Swept collision detection, raycast and nearest collision queries
- **Day/Night Cycle** — Phase transitions (DAWN/DAY/DUSK/NIGHT), danger multipliers
- **Vehicle Controller** — Movement loop with acceleration, speed clamp, magic consumption
- **Vehicle Attribute** — Health/Magic tracking, depletion signals
- **Dig Controller** — Damage accumulation, tool tier modifiers
- **Build Validator** — V1-V6 validation chain for placement
- **Place Controller** — Build state machine, category-specific rules
- **Facility Controller** — Facility lifecycle management, state tracking
- **Spawn Manager** — Wave timing, enemy pool, tide scheduling
- **Enemy AI Controller** — State machine (IDLE/PATROL/CHASE/ATTACK)
- **Weapon Controller** — Firing system, projectile handling
- **Damage Receiver** — Damage handling, armor calculations
- **Turret Controller** — Auto-targeting, fire timing
- **Area Manager** — Area bounds, discovery tracking
- **Retreat Judge** — Threshold detection, danger level assessment
- **Drop Manager** — Resource drop spawning, collection
- **Time System** — Day/hour tracking, phase transitions
- **Input Manager** — Keyboard/mouse/gamepad handling

#### UI/HUD
- **Simple HUD** — HP/MP bars, time display, phase indicator, warnings
- **DayNight Visual** — Color modulation, brightness adjustment

#### Data Files (Release Phase — 2026-04-25)
- **audio_config.json** — 46 SFX + 7 BGM configuration with volume/pitch/loop settings
- **achievements.json** — 31 achievement definitions (bilingual English/Chinese)
- **version.json** — Version 0.1.0-alpha metadata (build: 1, stage: alpha)
- **steam_appid.txt** — Steam App ID placeholder (value: 0, awaiting Steamworks registration)

#### Assets (Placeholder)
- **Sprites** — 26 SVG placeholder images (vehicle, enemies, drops, facilities, UI)
- **Shaders** — 4 gdshader files (glow, flash, outline, daynight)
- **Particles** — 4 particle effect definitions
- **Audio Manifest** — 29 SFX + 6 BGM specifications
- **VFX Manifest** — 12 particle + 8 shader specifications

#### Legal/Documents
- **EULA** — End User License Agreement (13 sections)
- **Privacy Policy** — GDPR/CCPA compliant (12 sections)
- **Age Ratings** — ESRB/PEGI/CERO/USK preparation
- **Store Page Copy** — Steam/Epic descriptions (English + Chinese)
- **Screenshot Spec** — 10 screenshot specifications
- **Trailer Script** — 60-90 second trailer outline
- **Pricing Strategy** — $14.99 base, 20% launch discount
- **Key Art Spec** — Capsule image specifications
- **Difficulty Curve** — Day progression, enemy unlock schedule

### Changed (Release Phase — 2026-04-25)

- **project.godot** — Added 7 Autoloads: VersionManager, AudioManager, AnalyticsManager, AchievementManager, CrashManager, SteamManager, TutorialManager
- **project.godot** — Main scene changed to `res://src/app_root.tscn`
- **project.godot** — Version set to `0.1.0-alpha`
- **global_signals.gd** — Added 15+ signals: tutorial_prompt_shown, tutorial_highlight_shown, tutorial_completed, tutorial_skipped, credits_finished, achievement_notification, bgm_track_changed, sfx_played, explore_completed, wave_completed, player_death, retreat_success, analytics_event_sent, crash_report_created, achievement_unlocked
- **strings-zh.json** — Added 52 localization strings (Tutorial: 18, Credits: 18, Achievement: 10, Audio Settings: 3, Misc: 3)

### Changed (Previous)

- **project.godot** — Added SaveManager, LocalizationManager Autoloads
- **global_signals.gd** — Added facility_created/destroyed, magic_depleted signals
- **collision_manager.gd** — MAX_SWEPT_STEPS reduced to 32 for performance
- **spawn_manager.gd** — Object pool implementation, load() for headless compatibility
- **day_night_cycle.gd** — DANGER_GLOBAL_MULT=1.1, TRANSITION_DURATION=45

### Fixed

- **Test Environment** — preload→load for spawn_manager (headless compatibility)
- **FacilityController** — class_name conflict resolved
- **Build Validator** — Signal parameter mismatch fixed

### Technical Details (Release Phase — 2026-04-25)

**Engine**: Godot 4.6
**Platform**: PC (Steam / Epic Games Store target)
**Target FPS**: 60 (frame budget ~16.6ms)
**Autoloads**: 19 global managers initialized (12 + 7 new)
**Test Files**: 7 new test files (audio, achievement, analytics, crash, tutorial, uuid, integration)
**Localization**: 99 strings (English + Chinese)
**Files Created**: 50 total (15 design docs, 14 code, 6 scenes, 7 tests, 6 data files)

**Sprint Status**:
- Must Have: 6 pending (external dependencies required)
- Should Have: 3 complete
- Nice to Have: 3 complete

**Blocking External Dependencies**:
- Steamworks account ($100 registration fee)
- GodotSteam GDExtension download
- Design software for Key Art
- OBS + DaVinci Resolve for trailer
- Art resources (外包/AI assisted)

### Technical Details (Previous)

---

## Version History

| Version | Date | Milestone |
|---------|------|-----------|
| 0.1.0-alpha | 2026-04-25 | Vertical Slice + Blocker Resolution |
| — | 2026-04-24 | Sprint 3 Complete (Vehicle Combat + Enemy Systems) |
| — | 2026-04-23 | Sprint 2 Complete (Foundation Layer) |
| — | 2026-04-22 | Sprint 1 Complete (Core Systems) |

---

## Roadmap

### [0.1.0] — Current (Release Phase Preparation)

**Completed (Should Have + Nice to Have)**:
- ✅ Audio system implementation (AudioManager + 46 SFX + 7 BGM config)
- ✅ Tutorial system (3-phase onboarding flow)
- ✅ Credits sequence (auto-scrolling with skip)
- ✅ Analytics/telemetry (event queue, batch upload, offline cache)
- ✅ Crash reporting (stack trace capture, report queue)
- ✅ Achievement system (31 achievements, progress tracking)
- ✅ UI screens (MainMenu, PauseMenu, CreditsScreen, SettingsScreen)
- ✅ Version management (semantic version display)
- ✅ Localization expansion (52 new strings)

**Pending (Must Have — External Dependencies)**:
- ⏳ Production sprites/art assets
- ⏳ Store screenshots (requires Godot Editor running)
- ⏳ Launch trailer (requires OBS + DaVinci Resolve)
- ⏳ Key Art / Capsule images (requires design software)
- ⏳ Age ratings submission (requires Steamworks account)
- ⏳ Steam SDK integration (requires Steamworks account + GodotSteam)

### [0.2.0] — Post-Launch

- Replace placeholder audio with production files
- Additional localization languages
- Cloud save support
- Modding support
- Live ops / seasonal events

---

*Changelog — 铁锈魔潮 (Rust Magic Tide)*
*Format: Keep a Changelog | Versioning: SemVer*