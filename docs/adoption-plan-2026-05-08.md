# Adoption Plan: 深海堡垒 → Claude-Code-Game-Studios

> **Generated**: 2026-05-08
> **Project phase**: Pre-Production
> **Engine**: Godot 4.6 + GDScript
> **Template version**: v1.0+
> **GDDs migrated**: 30 system docs + 5 balance/ref docs + 3 level docs + 5 review reports
> **Format compliance**: 0/30 GDDs compliant (all need 8-section format migration)

Work through these steps in order. Check off each item as you complete it.
Re-run `/adopt` anytime to check remaining gaps.

---

## Step 1: Bootstrap Infrastructure

### 1a. Set review mode
Create `production/review-mode.txt` with one of: `full`, `lean`, or `solo`.
- [ ] `production/review-mode.txt` created

### 1b. Set authoritative project stage
Run `/gate-check pre-production` or manually write `production/stage.txt`:
```
Pre-Production
```
- [ ] `production/stage.txt` written

### 1c. Create sprint tracking file
Run `/sprint-plan update`
- [ ] `production/sprint-status.yaml` created

---

## Step 2: Migrate GDD Format (Priority Order)

All 30 GDDs need format migration to include the 8 required sections:
1. Overview
2. Player Fantasy
3. Detailed Rules
4. Formulas
5. Edge Cases
6. Dependencies
7. Tuning Knobs
8. Acceptance Criteria

**Method**: For each GDD, run `/design-system retrofit design/gdd/[filename].md`

### Phase 2a: P0 Core Systems (do these first)

| # | GDD | Command | Est. |
|---|-----|---------|------|
| 1 | 操控系统 | `/design-system retrofit design/gdd/深海堡垒-操控系统.md` | 1 session |
| 2 | 战斗系统 | `/design-system retrofit design/gdd/深海堡垒-战斗系统.md` | 1 session |
| 3 | 资源采集系统 | `/design-system retrofit design/gdd/深海堡垒-资源采集系统.md` | 1 session |
| 4 | 敌人AI系统 | `/design-system retrofit design/gdd/深海堡垒-敌人AI系统.md` | 1 session |
| 5 | 波次防守系统 | `/design-system retrofit design/gdd/深海堡垒-波次防守系统.md` | 1 session |
| 6 | 关卡布局系统 | `/design-system retrofit design/gdd/深海堡垒-关卡布局系统.md` | 1 session |

- [ ] 操控系统 format migrated
- [ ] 战斗系统 format migrated
- [ ] 资源采集系统 format migrated
- [ ] 敌人AI系统 format migrated
- [ ] 波次防守系统 format migrated
- [ ] 关卡布局系统 format migrated

### Phase 2b: P1 Gameplay Systems

| # | GDD | Command | Est. |
|---|-----|---------|------|
| 7 | 氧气能源系统 | `/design-system retrofit design/gdd/深海堡垒-氧气能源系统.md` | 1 session |
| 8 | 船只损伤修复系统 | `/design-system retrofit design/gdd/深海堡垒-船只损伤修复系统.md` | 1 session |
| 9 | 物品系统 | `/design-system retrofit design/gdd/深海堡垒-物品系统.md` | 1 session |
| 10 | Boss战斗详细设计 | `/design-system retrofit design/gdd/深海堡垒-Boss战斗详细设计.md` | 1 session |
| 11 | 难度曲线设计 | `/design-system retrofit design/gdd/深海堡垒-难度曲线设计.md` | 1 session |
| 12 | 玩家成长系统 | `/design-system retrofit design/gdd/深海堡垒-玩家成长系统.md` | 1 session |
| 13 | 存档系统 | `/design-system retrofit design/gdd/深海堡垒-存档系统.md` | 1 session |
| 14 | UI系统 | `/design-system retrofit design/gdd/深海堡垒-UI系统.md` | 1 session |
| 15 | 新手教程系统 | `/design-system retrofit design/gdd/深海堡垒-新手教程系统.md` | 1 session |
| 16 | 主菜单与Loading界面 | `/design-system retrofit design/gdd/深海堡垒-主菜单与Loading界面.md` | 1 session |
| 17 | 船员系统(极简版) | `/design-system retrofit design/gdd/深海堡垒-船员系统(极简版).md` | 1 session |
| 18 | 实现补充内容 | `/design-system retrofit design/gdd/深海堡垒-实现补充内容.md` | 1 session |

- [ ] All P1 GDDs format migrated

### Phase 2c: P2+ Feature/Meta/Presentation Systems

| # | GDD | Command | Est. |
|---|-----|---------|------|
| 19 | 日夜循环系统 | `/design-system retrofit design/gdd/深海堡垒-日夜循环系统.md` | 1 session |
| 20 | 导航地图系统 | `/design-system retrofit design/gdd/深海堡垒-导航地图系统.md` | 1 session |
| 21 | 怪物进化系统 | `/design-system retrofit design/gdd/深海堡垒-怪物进化系统.md` | 1 session |
| 22 | 门锁系统 | `/design-system retrofit design/gdd/深海堡垒-门锁系统.md` | 1 session |
| 23 | 任务系统 | `/design-system retrofit design/gdd/深海堡垒-任务系统.md` | 1 session |
| 24 | NPC系统 | `/design-system retrofit design/gdd/深海堡垒-NPC系统.md` | 1 session |
| 25 | 经济系统 | `/design-system retrofit design/gdd/深海堡垒-经济系统.md` | 1 session |
| 26 | 剧情系统设计 | `/design-system retrofit design/gdd/深海堡垒-剧情系统设计.md` | 1 session |
| 27 | 结局系统设计 | `/design-system retrofit design/gdd/深海堡垒-结局系统设计.md` | 1 session |
| 28 | 音效系统 | `/design-system retrofit design/gdd/深海堡垒-音效系统.md` | 1 session |
| 29 | 设置菜单系统 | `/design-system retrofit design/gdd/深海堡垒-设置菜单系统.md` | 1 session |
| 30 | 发布准备 | `/design-system retrofit design/gdd/深海堡垒-发布准备.md` | 1 session |

- [ ] All P2+ GDDs format migrated

---

## Step 3: Architecture Setup

### 3a. Create first ADRs
Run `/architecture-decision` for each major technical decision. Minimum required before coding:

- [ ] ADR-0001: Engine selection (Godot 4.6 — already decided, document it)
- [ ] ADR-0002: 2D rendering approach (TileMap + Sprite2D)
- [ ] ADR-0003: Architecture pattern (component-based vs ECS)
- [ ] ADR-0004: State management (singletons vs dependency injection)
- [ ] ADR-0005: Save system architecture (JSON vs binary)

### 3b. Run architecture review
Run `/architecture-review` — this will bootstrap `tr-registry.yaml` from existing GDDs and ADRs.
- [ ] `docs/architecture/tr-registry.yaml` created

### 3c. Create control manifest
Run `/create-control-manifest`
- [ ] `docs/architecture/control-manifest.md` created

---

## Step 4: Sprint Planning

- [ ] Run `/create-epics` — map systems to epics
- [ ] Run `/create-stories` — break first epic into stories
- [ ] Run `/sprint-plan` — plan first sprint

---

## Step 5: Optional Improvements

- [ ] Rename GDD files from Chinese to English slugs (e.g., `combat-system.md`)
- [ ] Add `Status:` field to each GDD header
- [ ] Run `/review-all-gdds` for cross-document consistency check
- [ ] Run `/consistency-check` against balance data tables

---

## What to Expect from Existing Content

All 30 GDDs contain **substantive design content** — formulas, tables, enemy stats, UI layouts, etc. The migration is about **reorganizing existing content into the 8-section format**, not writing from scratch. The `/design-system retrofit` command will:
1. Read the existing Chinese-format document
2. Extract content into the appropriate 8-section headings
3. Flag any missing sections for collaborative authoring
4. Write the reformatted document back to the same file

---

## Re-run

Run `/adopt` again after completing Step 2 (all GDDs migrated) to verify format compliance.
