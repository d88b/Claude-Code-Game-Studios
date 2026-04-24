# 音频生成指南

**铁锈魔潮**

> 本脚本帮助生成占位音频文件，使用在线工具或本地命令。

---

## 快速生成方案

### 方案 A: 使用 sfxr.me (推荐)

1. 打开浏览器访问: https://sfxr.me/
2. 选择音效类型:
   - **Pickup/Coin** → 用于 pickup_*.wav
   - **Laser/Shoot** → 用于 weapon_fire.wav, turret_rotate.wav
   - **Explosion** → 用于 dig_complete.wav, facility_destroy.wav
   - **Powerup** → 用于 pickup_rare.wav, game_victory.wav
   - **Hit/Hurt** → 用于 zombie_attack.wav, dig_fail.wav
   - **Jump** → 用于 vehicle_engine_start.wav
   - **Blip/Select** → 用于 ui_click.wav, ui_hover.wav
3. 点击 **Randomize** 生成随机音效
4. 微调参数直到满意
5. 点击 **Export WAV** 下载
6. 重命名文件并放入对应目录

### 方案 B: 使用 Bfxr (桌面应用)

下载地址: https://www.bfxr.net/

### 方案 C: 使用 Audacity 手工制作

1. 打开 Audacity
2. 生成 → 噪声/音调
3. 应用效果 (回声、失真等)
4. 导出为 WAV

---

## BGM 来源

### 免费 BGM 网站

| 网站 | 说明 |
|------|------|
| https://freepd.com | CC0 公有领域音乐 |
| https://incompetech.com | Kevin MacLeod 免费 BGM |
| https://opengameart.org | 游戏音乐素材库 |
| https://mixkit.co | 免费 BGM 和 SFX |

### AI 音乐生成 (可选)

| 工具 | 说明 |
|------|------|
| https://suno.com | AI 音乐生成 |
| https://elevenlabs.io | AI 音效生成 |

---

## 文件清单

### SFX (46 files)

```
assets/audio/sfx/
├── vehicle/
│   ├── vehicle_engine_start.wav
│   ├── vehicle_engine_loop.wav
│   ├── vehicle_engine_stop.wav
│   ├── turret_rotate.wav
│   ├── weapon_fire.wav
│   └── weapon_empty.wav
├── digging/
│   ├── dig_start.wav
│   ├── dig_loop.wav
│   ├── dig_complete.wav
│   └── dig_fail.wav
├── placement/
│   ├── place_success.wav
│   ├── place_fail.wav
│   ├── facility_activate.wav
│   └── facility_destroy.wav
├── enemies/
│   ├── zombie_walk.wav
│   ├── zombie_attack.wav
│   ├── zombie_death.wav
│   ├── boss_spawn.wav
│   └── boss_skill.wav
├── resources/
│   ├── drop_spawn.wav
│   ├── pickup_generic.wav
│   ├── pickup_crystal.wav
│   ├── pickup_metal.wav
│   ├── pickup_organic.wav
│   ├── pickup_fuel.wav
│   └── pickup_rare.wav
├── ui/
│   ├── ui_click.wav
│   ├── ui_hover.wav
│   ├── ui_confirm.wav
│   ├── ui_cancel.wav
│   ├── ui_warning.wav
│   ├── ui_success.wav
│   ├── menu_open.wav
│   └── menu_close.wav
└── game_state/
│   ├── daynight_transition.wav
│   ├── night_warning.wav
│   ├── retreat_start.wav
│   ├── retreat_complete.wav
│   ├── health_low.wav
│   ├── magic_low.wav
│   ├── game_victory.wav
│   └── game_defeat.wav
```

### BGM (7 files)

```
assets/audio/bgm/
├── bgm_menu.wav
├── bgm_day.wav
├── bgm_night.wav
├── bgm_boss.wav
├── bgm_bunker.wav
├── bgm_victory.wav
└── bgm_defeat.wav
```

---

## 音效风格参考

| 类别 | 风格关键词 | sfxr.me 类型 |
|------|-----------|--------------|
| **战车/机械** | 工业感、金属碰撞 | Laser/Shoot |
| **挖掘** | 沉重、撞击 | Explosion/Hit |
| **放置** | 清脆、确认感 | Powerup |
| **敌人** | 沙哑、腐烂、沉重 | Hit/Hurt |
| **资源** | 轻快、闪烁 | Pickup/Coin |
| **UI** | 清脆、简洁 | Blip/Select |
| **游戏状态** |戏剧性、标志性 | Powerup/Explosion |

---

## 下一步

1. 使用 sfxr.me 生成首批 P1 音效 (19 files)
2. 从 freepd.com 下载 BGM 占位
3. 将文件放入对应目录
4. 在 Godot Editor 中验证音频加载

---

*Audio Generation Guide — 铁锈魔潮*
*Generated: 2026-04-25*