# VFX Manifest — Placeholder Visual Effects

> **Status**: Placeholder
> **Created**: 2026-04-25
> **Purpose**: Define required VFX assets for blocker resolution

---

## Particle Effects

### Combat Particles
| ID | Filename | Category | Description | Particle Count |
|----|----------|----------|-------------|----------------|
| VFX-001 | `particles_bullet_trail.tres` | Weapon | 子弹轨迹粒子 | 10-20 |
| VFX-002 | `particles_explosion.tres` | Weapon | 爆炸粒子 | 50-100 |
| VFX-003 | `particles_hit_spark.tres` | Combat | 命中火花粒子 | 10-30 |
| VFX-004 | `particles_impact_dust.tres` | Combat | 碰撞尘土粒子 | 20-40 |

### Vehicle Particles
| ID | Filename | Category | Description | Particle Count |
|----|----------|----------|-------------|----------------|
| VFX-005 | `particles_engine_smoke.tres` | Vehicle | 引擎尾气烟雾 | 5-10 (continuous) |
| VFX-006 | `particles_deploy_flash.tres` | Vehicle | 部署闪光效果 | 30-50 |

### Digging Particles
| ID | Filename | Category | Description | Particle Count |
|----|----------|----------|-------------|----------------|
| VFX-007 | `particles_dig_debris.tres` | Dig | 挖掘碎片粒子 | 10-20 per hit |
| VFX-008 | `particles_dig_dust.tres` | Dig | 挖掘尘土粒子 | 20-30 per hit |

### Enemy Particles
| ID | Filename | Category | Description | Particle Count |
|----|----------|----------|-------------|----------------|
| VFX-009 | `particles_zombie_death.tres` | Enemy | 僵尸死亡粒子 | 30-50 |
| VFX-010 | `particles_boss_death.tres` | Enemy | BOSS死亡粒子 | 100-200 |

### Pickup Particles
| ID | Filename | Category | Description | Particle Count |
|----|----------|----------|-------------|----------------|
| VFX-011 | `particles_pickup_sparkle.tres` | Drop | 拾取闪光粒子 | 10-20 |
| VFX-012 | `particles_drop_glow.tres` | Drop | 资源掉落发光粒子 | 5-10 |

---

## Shader Materials

### Utility Shaders
| ID | Filename | Category | Description |
|----|----------|----------|-------------|
| SHD-001 | `shader_glow.gdshader` | Visual | 发光效果 shader |
| SHD-002 | `shader_outline.gdshader` | Visual | 边缘描边 shader |
| SHD-003 | `shader_flash.gdshader` | Visual | 闪白效果 shader (damage indicator) |
| SHD-004 | `shader_fade.gdshader` | Visual | 渐隐渐现 shader |

### Environment Shaders
| ID | Filename | Category | Description |
|----|----------|----------|-------------|
| SHD-005 | `shader_daynight_modulate.gdshader` | Time | 日夜颜色调制 shader |
| SHD-006 | `shader_fog_overlay.gdshader` | Environment | 雾气叠加 shader |

### Magic Shaders
| ID | Filename | Category | Description |
|----|----------|----------|-------------|
| SHD-007 | `shader_magic_pulse.gdshader` | Magic | 魔力脉冲效果 |
| SHD-008 | `shader_magic_depleted.gdshader` | Magic | 魔力耗尽警告效果 |

---

## Placeholder Implementation

### Priority 1 (Must Have for MVP)
- VFX-001 (bullet trail)
- VFX-002 (explosion)
- VFX-007 (dig debris)
- VFX-011 (pickup sparkle)
- SHD-003 (flash for damage)
- SHD-005 (daynight modulate)

### Priority 2 (Should Have)
- VFX-003~004 (hit/impact)
- VFX-005 (engine smoke)
- VFX-009 (zombie death)
- SHD-001 (glow)
- SHD-007~008 (magic effects)

### Priority 3 (Nice to Have)
- VFX-006 (deploy flash)
- VFX-008 (dig dust)
- VFX-010 (boss death)
- VFX-012 (drop glow)
- SHD-002 (outline)
- SHD-004 (fade)
- SHD-006 (fog)

---

## Technical Specifications

- **Particle System**: Godot GPUParticles2D
- **Texture Size**: 16x16 to 64x64 pixels for particle sprites
- **Emission Shapes**: Point, Sphere, Box depending on effect
- **Shader Language**: Godot Shader Language (.gdshader)
- **Performance Target**: < 1000 active particles at any time

---

*VFX Manifest — Placeholder assets for blocker #1 resolution.*