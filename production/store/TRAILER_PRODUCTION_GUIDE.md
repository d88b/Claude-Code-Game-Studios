# Trailer Production Guide

**Story**: trailer-001
**Date**: 2026-04-25
**Duration**: 60-90 seconds

---

## 工具准备

| 工具 | 用途 | 下载 |
|------|------|------|
| **OBS Studio** | 游戏录像 | https://obsproject.com |
| **DaVinci Resolve** | 视频剪辑 (免费) | https://www.blackmagicdesign.com/products/davinciresolve |
| **FFmpeg** | 格式转换 | https://ffmpeg.org |

---

## 录像规格

| 项目 | 规格 |
|------|------|
| **分辨率** | 1920x1080 (1080p) |
| **帧率** | 60 fps |
| **格式** | MP4 (H.264) |
| **码率** | 8-12 Mbps |

---

## 录像采集步骤

### OBS Studio 配置

1. 打开 OBS Studio
2. 添加 **Game Capture** 源
   - Mode: "Capture specific window"
   - Window: "Godot Engine"
3. 设置输出:
   - Output Mode: Advanced
   - Recording Format: mp4
   - Encoder: x264
   - Rate Control: CRF, CRF=20
   - FPS: 60

### 录像场景清单

| Phase | 时长 | 场景 | 录像时长 |
|-------|------|------|----------|
| Hook | 0-10s | 战车启动驶出地堡 | 30s 原素材 |
| Exploration | 10-25s | 地表驾驶探索 | 60s 原素材 |
| Combat | 25-40s | 射击僵尸战斗 | 45s 原素材 |
| Building | 40-50s | 挖掘方块放置设施 | 30s 原素材 |
| Defense | 50-65s | 尸潮攻击防守 | 45s 原素材 |
| Day/Night | 65-75s | 日夜过渡循环 | 20s 原素材 |

**总录像时长**: ~230秒 (剪辑后 60-90秒)

---

## 录像采集操作

### Phase 1: Hook (战车启动)

```
场景: 地堡内部 → 出口
动作:
1. 战车静止在地堡出口
2. 按下启动键，引擎音效
3. 战车缓缓驶出，阳光照射
4. 转换到地表视角

录制时长: 30-40秒
```

### Phase 2: Exploration (探索)

```
场景: 地表废土
动作:
1. 战车在地表驾驶
2. 经过废墟地形
3. 资源掉落出现
4. 战车经过拾取

录制时长: 60秒
```

### Phase 3: Combat (战斗)

```
场景: 僵尸遭遇
动作:
1. 僵尸群出现
2. 战车炮塔瞄准
3. 开火射击
4. 僵尸消灭效果

录制时长: 45秒
```

### Phase 4: Building (建造)

```
场景: 地堡内部
动作:
1. 挖掘方块动画
2. 放置炮塔设施
3. 设施激活发光

录制时长: 30秒
```

### Phase 5: Defense (防守)

```
场景: 尸潮波次
动作:
1. 夜幕降临
2. 僵尸从边缘涌入
3. 炮塔自动开火
4. 爆炸粒子效果

录制时长: 45秒
```

### Phase 6: Day/Night (日夜)

```
场景: 固定位置
动作:
1. 白天 → 黄昏过渡
2. 天空颜色变化
3. 光线变化

录制时长: 20秒 (快速过渡)
```

---

## 剪辑流程 (DaVinci Resolve)

### 1. 导入素材

- 将所有录像文件导入 DaVinci Resolve
- 创建新项目: "RustMagicTide_LaunchTrailer"

### 2. 剪辑时间轴

| 时间 | 内容 | 剪辑动作 |
|------|------|----------|
| 0:00-0:05 | 战车静止 | 静态开场 |
| 0:05-0:10 | 驾驶驶出 | 慢动作 → 正常 |
| 0:10-0:15 | 地表远景 | 建立镜头 |
| 0:15-0:25 | 驾驶 + 拾取 | 快切多镜头 |
| 0:25-0:30 | 僵尸出现 | 建立镜头 |
| 0:30-0:40 | 战斗射击 | 快切动作 |
| 0:40-0:50 | 挖掘建造 | 加速剪辑 |
| 0:50-0:65 | 尸潮防守 | 高潮音乐 |
| 0:65-0:75 | 日夜循环 | 时间压缩 |
| 0:75-0:90 | 标题结尾 | 黑屏 → Logo |

### 3. 文字叠加

| 时间 | 文字 | 位置 |
|------|------|------|
| 0:10 | "EXPLORE THE WASTELAND" | 底部居中 |
| 0:25 | "MAGITECH BATTLE WAGON" | 底部居中 |
| 0:40 | "BUILD YOUR FORTRESS" | 底部居中 |
| 0:50 | "DEFEND AGAINST TIDES" | 底部居中 |
| 0:65 | "DAY/NIGHT CYCLE" | 底部居中 |
| 0:75 | "RUST MAGIC TIDE" | 中央 |
| 0:85 | "COMING TO STEAM & EPIC" | 标题下方 |

### 4. 音频同步

- BGM: 选择节奏感强的背景音乐
- SFX: 确保音效与动作同步
- 音乐高潮点: Combat + Defense phases

### 5. 导出

```
设置:
- Format: MP4
- Codec: H.264
- Resolution: 1920x1080
- Frame Rate: 60
- Bit Rate: 8-12 Mbps
- Audio: AAC, 192 kbps
```

---

## 文字模板

### 标题设计

```
Font: Bold Sans-serif
Size: 48-60pt
Color: White
Shadow: Black, 2px offset
Animation: Fade in/out (0.5s)
```

### 中文版本

如需中文版本，创建第二个时间轴:

```
EXPLORE THE WASTELAND → 探索废土
MAGITECH BATTLE WAGON → 魔导战车
BUILD YOUR FORTRESS → 建造堡垒
DEFEND AGAINST TIDES → 防守尸潮
DAY/NIGHT CYCLE → 日夜循环
```

---

## 音频素材

| 类型 | 文件 | 用途 |
|------|------|------|
| BGM | bgm_trailer.wav | 背景音乐 (需创作) |
| SFX | sfx_engine.wav | 引擎启动 |
| SFX | sfx_fire.wav | 武器射击 |
| SFX | sfx_explosion.wav | 爆炸效果 |
| SFX | sfx_place.wav | 建造放置 |
| Logo | sfx_logo.wav | 标题出现音效 |

---

## 最终输出

| 版本 | 文件名 | 规格 |
|------|--------|------|
| 主版本 | trailer_launch_en.mp4 | 1920x1080, 60fps |
| 中文版 | trailer_launch_zh.mp4 | 1920x1080, 60fps |

---

## 检查清单

| 项目 | 检查 |
|------|------|
| 分辨率正确 | 1920x1080 |
| 帧率正确 | 60fps |
| 文件大小 | ≤ 100MB |
| 音频同步 | 动作匹配音效 |
| 文字清晰 | 无拼写错误 |
| 时长正确 | 60-90秒 |

---

*Trailer Production Guide — trailer-001*