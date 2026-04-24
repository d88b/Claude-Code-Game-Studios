# VFX Spec: Enemy Death Effects

**Owner**: technical-artist
**Priority**: Should Have (Sprint 4)
**Status**: Spec Ready — Implementation Pending

---

## Overview

为 4 个阵营敌人添加独特死亡动画和粒子效果，强化阵营视觉识别并提供击杀反馈。

---

## Faction Death VFX Requirements

### Faction 0: GRAVEYARD (墓园)

**效果**: 有机崩溃 → 粘液扩散

**VFX Elements**:
| Element | Type | Duration | Color |
|---------|------|----------|-------|
| 肢体蠕动崩溃 | Sprite Animation | 0.8s | 灰白 #808080 |
| 腐烂绿粘液粒子 | GPUParticles2D | 0.6s | 腐烂绿 #4A7C4A |
| 蜂巢碎片飞散 | GPUParticles2D | 0.4s | 灰白 |

**Audio**: 虫族崩溃声 + 粘液溅射声

**Implementation**:
- 创建 `graveyard_death.tscn` 场景
- 16-32 粘液粒子，向上飞散后落地
- Screen shake: None (Basic)

---

### Faction 1: HELL (地狱)

**效果**: 维度消散 → 深渊吸入

**VFX Elements**:
| Element | Type | Duration | Color |
|---------|------|----------|-------|
| 触手眼球消散 | Sprite Animation | 1.0s | 深渊紫黑 #1A0A2E |
| 深渊粒子吸入 | GPUParticles2D | 0.8s | 火焰橙 #FF4500 |
| 空间扭曲残留 | Shader Effect | 0.5s | 深渊紫黑 |

**Audio**: 深渊吸入声 + 低频震颤

**Implementation**:
- 创建 `hell_death.tscn` 场景
- 粒子向中心吸入（反向扩散）
- Screen shake: 0.1s (Elite), 0.3s (Boss)

---

### Faction 2: TOWER (塔楼)

**效果**: 机械解体 → 锈蚀崩溃

**VFX Elements**:
| Element | Type | Duration | Color |
|---------|------|----------|-------|
| 锈蚀方块解体 | Sprite Animation | 0.5s | 锈铁灰 #5C5C5C |
| 锈铁粒子飞散 | GPUParticles2D | 0.4s | 锈铁灰 |
| 电路残留火花 | GPUParticles2D | 0.3s | 电路蓝 #0080FF |

**Audio**: 机械崩溃声 + 电路短路声

**Implementation**:
- 创建 `tower_death.tscn` 场景
- 8-16 锈铁粒子，方形轨迹
- Screen shake: None (次要威胁)

---

### Faction 3: ELEMENT (元素)

**效果**: 晶石粉碎 → 光芒消散

**VFX Elements**:
| Element | Type | Duration | Color |
|---------|------|----------|-------|
| 晶石粉碎 | Sprite Animation | 0.6s | 晶石紫 #800080 |
| 光芒粒子消散 | GPUParticles2D | 0.8s | 光芒金 #FFD700 |
| 元素残留特效 | Shader Effect | 0.4s | 天气色 |

**Audio**: 晶石粉碎声 + 元素消散声

**Implementation**:
- 创建 `element_death.tscn` 场景
- 16-32 光芒粒子，向外扩散并淡出
- Screen shake: None (Basic), 0.1s (Elite)

---

## Tier Scaling

| Tier | Particle Count | Screen Shake | VFX Duration |
|------|----------------|--------------|--------------|
| Basic | 8-16 | None | 0.5-0.8s |
| Enhanced | 16-24 | 0.05s | 0.6-0.9s |
| Elite | 24-32 | 0.1s | 0.8-1.0s |
| Boss | 32-64 + flash | 0.3s + flash | 1.0-1.5s |

---

## Implementation Guide

### Step 1: Create Death VFX Scenes

为每个阵营创建独立场景：

```
src/vfx/death/
  ├── graveyard_death.tscn
  ├── hell_death.tscn
  ├── tower_death.tscn
  └── element_death.tscn
```

每个场景包含：
- GPUParticles2D (粒子系统)
- AnimationPlayer (Sprite 动画)
- AudioStreamPlayer (音效)

### Step 2: Implement _trigger_death_vfx()

在 `enemy_ai_controller.gd` 中替换 TODO:

```gdscript
func _trigger_death_vfx() -> void:
    # 加载阵营 VFX 场景
    var vfx_paths := {
        0: "res://src/vfx/death/graveyard_death.tscn",
        1: "res://src/vfx/death/hell_death.tscn",
        2: "res://src/vfx/death/tower_death.tscn",
        3: "res://src/vfx/death/element_death.tscn"
    }
    
    if not vfx_paths.has(faction):
        return
    
    var vfx_scene: PackedScene = load(vfx_paths[faction])
    if vfx_scene == null:
        return
    
    # 创建 VFX 实例
    var vfx: Node2D = vfx_scene.instantiate()
    vfx.position = position
    get_tree().current_scene.add_child(vfx)
    
    # 自动清理
    await get_tree().create_timer(1.5).timeout
    if is_instance_valid(vfx):
        vfx.queue_free()
```

### Step 3: Add Screen Shake (Optional)

如果需要 Screen shake:
```gdscript
# 在 vfx 场景中调用
GlobalSignals.screen_shake.emit(shake_intensity, shake_duration)
```

---

## Acceptance Criteria

- [ ] 4 个阵营各有独特死亡 VFX
- [ ] 粒子效果持续时间符合 Tier scaling
- [ ] Screen shake 对 Elite/Boss 有效
- [ ] 音效配合 VFX 播放
- [ ] VFX 自动清理 (1.5s 后)
- [ ] 性能测试: 10 同时死亡帧时间 < 18ms

---

## Assets Required

| Asset | Type | Count |
|-------|------|-------|
| 死亡 Sprite 动画 | SpriteFrames | 4 (per faction) |
| 粒子材质 | CanvasItemMaterial | 4 |
| 死亡音效 | AudioStream | 4 |

---

## Priority Assessment

Should Have (P3) — 增强 player fantasy 但不阻塞发布。

---

*VFX spec for Enemy Death — Sprint 4 Polish phase.*