# Audio Manifest — Placeholder Sound Effects & Music

> **Status**: Placeholder
> **Created**: 2026-04-25
> **Purpose**: Define required audio assets for blocker resolution

---

## Sound Effects (SFX)

### Combat Sounds
| ID | Filename | Category | Description | Duration Estimate |
|----|----------|----------|-------------|-------------------|
| SFX-001 | `sfx_fire.wav` | Weapon | 武器射击音效 | 0.3s |
| SFX-002 | `sfx_explosion.wav` | Weapon | 爆炸音效 | 0.8s |
| SFX-003 | `sfx_hit.wav` | Combat | 命中音效 | 0.2s |
| SFX-004 | `sfx_impact.wav` | Combat | 碰撞音效 | 0.3s |

### Vehicle Sounds
| ID | Filename | Category | Description | Duration Estimate |
|----|----------|----------|-------------|-------------------|
| SFX-005 | `sfx_engine_idle.wav` | Vehicle | 引擎怠速 | Loop |
| SFX-006 | `sfx_engine_accel.wav` | Vehicle | 引擎加速 | Loop |
| SFX-007 | `sfx_vehicle_deploy.wav` | Vehicle | 战车部署音效 | 1.0s |
| SFX-008 | `sfx_vehicle_return.wav` | Vehicle | 战车返回音效 | 1.0s |

### Digging Sounds
| ID | Filename | Category | Description | Duration Estimate |
|----|----------|----------|-------------|-------------------|
| SFX-009 | `sfx_dig_start.wav` | Dig | 开始挖掘 | 0.3s |
| SFX-010 | `sfx_dig_loop.wav` | Dig | 挖掘循环 | Loop |
| SFX-011 | `sfx_dig_complete.wav` | Dig | 挖掘完成（方块破坏） | 0.5s |

### Enemy Sounds
| ID | Filename | Category | Description | Duration Estimate |
|----|----------|----------|-------------|-------------------|
| SFX-012 | `sfx_zombie_idle.wav` | Enemy | 僵尸低吼 | Loop |
| SFX-013 | `sfx_zombie_attack.wav` | Enemy | 僵尸攻击 | 0.5s |
| SFX-014 | `sfx_zombie_death.wav` | Enemy | 僵尸死亡 | 0.8s |
| SFX-015 | `sfx_boss_roar.wav` | Enemy | BOSS咆哮 | 2.0s |

### Facility Sounds
| ID | Filename | Category | Description | Duration Estimate |
|----|----------|----------|-------------|-------------------|
| SFX-016 | `sfx_place.wav` | Build | 放置方块/设施 | 0.4s |
| SFX-017 | `sfx_remove.wav` | Build | 拆除方块/设施 | 0.3s |
| SFX-018 | `sfx_turret_fire.wav` | Facility | 炮塔射击 | 0.3s |
| SFX-019 | `sfx_generator_loop.wav` | Facility | 发电机运行 | Loop |

### Pickup/Drop Sounds
| ID | Filename | Category | Description | Duration Estimate |
|----|----------|----------|-------------|-------------------|
| SFX-020 | `sfx_pickup.wav` | Drop | 拾取资源 | 0.2s |
| SFX-021 | `sfx_drop_land.wav` | Drop | 资源掉落落地 | 0.3s |

### UI Sounds
| ID | Filename | Category | Description | Duration Estimate |
|----|----------|----------|-------------|-------------------|
| SFX-022 | `sfx_ui_click.wav` | UI | UI 点击 | 0.1s |
| SFX-023 | `sfx_ui_hover.wav` | UI | UI 悬停 | 0.05s |
| SFX-024 | `sfx_ui_confirm.wav` | UI | UI 确认 | 0.15s |
| SFX-025 | `sfx_ui_cancel.wav` | UI | UI 取消 | 0.15s |
| SFX-026 | `sfx_ui_warning.wav` | UI | UI 警告提示 | 0.5s |

### Day/Night Sounds
| ID | Filename | Category | Description | Duration Estimate |
|----|----------|----------|-------------|-------------------|
| SFX-027 | `sfx_phase_transition.wav` | Time | 阶段转换提示音 | 0.8s |
| SFX-028 | `sfx_day_start.wav` | Time | 白天开始 | 1.0s |
| SFX-029 | `sfx_night_start.wav` | Time | 夜晚开始 | 1.0s |

---

## Background Music (BGM)

| ID | Filename | Scene | Description | Duration |
|----|----------|-------|-------------|----------|
| BGM-001 | `bgm_exploration.wav` | Exploration | 探索场景背景音乐 | 2-3 min loop |
| BGM-002 | `bgm_bunker.wav` | Bunker | 地堡场景背景音乐 | 2-3 min loop |
| BGM-003 | `bgm_defense.wav` | Defense | 尸潮防守场景音乐 | 2-3 min loop |
| BGM-004 | `bgm_menu.wav` | Menu | 主菜单音乐 | 1-2 min loop |
| BGM-005 | `bgm_victory.wav` | Victory | 胜利结算音乐 | 30s |
| BGM-006 | `bgm_defeat.wav` | Defeat | 失败结算音乐 | 30s |

---

## Placeholder Status

**Total SFX**: 29 sounds
**Total BGM**: 6 tracks

**Current Status**: PLACEHOLDER (empty files / not implemented)

**Recommended for MVP**:
- Priority 1 (Must Have): SFX-001~004, SFX-007~008, SFX-009~011, SFX-020~021, BGM-001~003
- Priority 2 (Should Have): SFX-005~006, SFX-012~015, SFX-016~019, BGM-004
- Priority 3 (Nice to Have): SFX-022~029, BGM-005~006

---

## Technical Specifications

- **Format**: WAV (Godot default), optionally OGG for smaller size
- **Sample Rate**: 44100 Hz
- **Bit Depth**: 16-bit
- **Channels**: Mono for SFX, Stereo for BGM
- **Target Size**: SFX < 100KB each, BGM < 5MB each (compressed)

---

*Audio Manifest — Placeholder assets for blocker #1 resolution.*