# Audio Spec: Ambient Sounds

**Owner**: sound-designer
**Priority**: Should Have (Sprint 4)
**Status**: Spec Ready — Assets Pending

---

## Overview

为四个 DayNight 阶段设计独特的环境音效，增强沉浸感和时间流逝的感知。

---

## Phase Ambient Requirements

### Phase 0: DAWN (黎明)

**氛围**: 从黑暗到光明，宁静过渡，微风初起

**Audio Elements**:
| Element | Type | Duration | Volume |
|---------|------|----------|--------|
| 黎明微风 | Looping Ambient | Continuous | -10 dB |
| 远处鸟鸣 | Sparse Event | Random 10-30s | -15 dB |

**Character**: 轻柔、清冷、充满希望

**File**: `assets/audio/ambient/dawn_wind.wav`
**Format**: WAV (16-bit, 44.1kHz)
**Loop**: Seamless loop (2-4s crossfade)

---

### Phase 1: DAY (白天)

**氛围**: 活力、明亮、温和风声

**Audio Elements**:
| Element | Type | Duration | Volume |
|---------|------|----------|--------|
| 白天微风 | Looping Ambient | Continuous | -12 dB |
| 远处活动声 | Sparse Event | Random 20-60s | -20 dB |

**Character**: 明快、稳定、日常感

**File**: `assets/audio/ambient/day_breeze.wav`
**Format**: WAV (16-bit, 44.1kHz)
**Loop**: Seamless loop (2-4s crossfade)

---

### Phase 2: DUSK (黄昏)

**氛围**: 收束、温暖、临近夜晚

**Audio Elements**:
| Element | Type | Duration | Volume |
|---------|------|----------|--------|
| 黄昏微风 | Looping Ambient | Continuous | -8 dB |
| 远处钟声 | Scheduled Event | Once at phase start | -5 dB |

**Character**: 温暖、收束、平静过渡

**File**: `assets/audio/ambient/dusk_calm.wav`
**Format**: WAV (16-bit, 44.1kHz)
**Loop**: Seamless loop (2-4s crossfade)

---

### Phase 3: NIGHT (夜晚)

**氛围**: 冷冽、神秘、危险感增强

**Audio Elements**:
| Element | Type | Duration | Volume |
|---------|------|----------|--------|
| 夜晚风声 | Looping Ambient | Continuous | -15 dB |
| 远处野兽声 | Sparse Event | Random 30-120s | -12 dB |

**Character**: 冷冽、压抑、潜在危险

**File**: `assets/audio/ambient/night_wind.wav`
**Format**: WAV (16-bit, 44.1kHz)
**Loop**: Seamless loop (2-4s crossfade)

---

## Technical Requirements

### Loop Quality

- **Seamless loop**: 音效循环点无明显跳跃或咔嗒声
- **Crossfade**: 2-4秒自然过渡区
- **No silence gaps**: 循环内无明显静音段

### File Format

- **Format**: WAV (无损，16-bit)
- **Sample Rate**: 44.1 kHz
- **Channels**: Stereo (左右声道区分环境感)
- **Bit Depth**: 16-bit

### Volume Calibration

- **基准**: 所有 ambient 音效相对于 master bus 为负 dB
- **范围**: -8 dB ~ -15 dB（不盖过重要游戏音效）
- **Night 特殊**: Night 音效比 Day 更低 dB，增强压抑感

---

## Implementation Notes

### Integration

`AmbientAudioManager.gd` 已实现基础框架：
- 监听 `GlobalSignals.day_phase_changed` 信号
- 自动切换阶段音效
- 支持暂停/继续和音量调节

### Pending Work

| Item | Owner | Priority |
|------|-------|----------|
| 4 个阶段音效 WAV 文件 | sound-designer | P3 |
| Audio bus 配置 (Ambient) | audio-director | P3 |
| 远处活动/野兽事件音效 | sound-designer | P3 |

---

## Acceptance Criteria

- [ ] 4 个阶段各有独特 ambient 音效
- [ ] 所有音效无缝循环 (无明显跳跃)
- [ ] Volume 层级符合规格 (不盖过游戏音效)
- [ ] WAV 文件放置在 `assets/audio/ambient/` 目录
- [ ] 阶段切换时音效平滑过渡 (无突然切换感)

---

## Audio Assets Required

| Asset | Type | Path |
|-------|------|------|
| dawn_wind.wav | Ambient Loop | assets/audio/ambient/dawn_wind.wav |
| day_breeze.wav | Ambient Loop | assets/audio/ambient/day_breeze.wav |
| dusk_calm.wav | Ambient Loop | assets/audio/ambient/dusk_calm.wav |
| night_wind.wav | Ambient Loop | assets/audio/ambient/night_wind.wav |

---

## Priority Assessment

Should Have (P3) — 增强 atmosphere 但不阻塞发布。音效可后期替换 placeholder。

---

*Audio spec for Ambient Sounds — Sprint 4 Polish phase.*