# Sprint 1 — Foundation Layer Core

**Start**: 2026-04-24
**End**: 2026-05-07 (2 weeks)
**Mode**: lean — PR-SPRINT gate skipped

---

## Sprint Goal

建立 Foundation 层核心架构：TileMapWorld、BlockTypeDB、TimeSystem、InputManager、GlobalSignals —— 为所有 Core/Feature 层实现提供基础设施。

---

## Capacity

- **Total days**: 14 (2 weeks)
- **Buffer (20%)**: 3 days
- **Available**: 11 days

---

## Tasks

### Must Have (Critical Path)

| ID | Story | Epic | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 1-1 | TileMapLayer Node Structure | tilemap-world | 2 | None | 5 TileMapLayer nodes, collision configured, z_index hierarchy |
| 1-2 | Cell Coordinate System | tilemap-world | 1 | 1-1 | world_to_cell, cell_to_world_center pass tests |
| 1-3 | Chunk Loading System | tilemap-world | 2 | 1-2 | load_chunks_around works, <50ms per chunk |
| 1-4 | TileSet Resource Loading | block-type-database | 1 | None | BlockTypeDB loads from entities.yaml, O(1) lookup |
| 1-5 | Query API Implementation | block-type-database | 1 | 1-4 | get_tile_data, get_hardness pass tests |
| 1-6 | Time System Autoload | time-system | 1 | None | TIME_SCALE=60, get_phase(), GlobalSignals emit |
| 1-7 | GlobalSignals Registration | implicit | 1 | None | GlobalSignals autoload, all 20+ signals defined |

### Should Have

| ID | Story | Epic | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 2-1 | Procedural Terrain Generation | tilemap-world | 2 | 1-3 | Same seed → same terrain |
| 2-2 | Resource Definition Loading | resource-database | 1 | None | ResourceDB loads from entities.yaml |
| 2-3 | Enemy Definition Loading | enemy-type-database | 1 | None | EnemyTypeDB with 8 behavior_hint types |
| 2-4 | Input Manager Autoload | input-control-system | 2 | None ⚠️ HIGH RISK | Dual-focus tested on Godot 4.6 |

### Nice to Have

| ID | Story | Epic | Est. Days | Dependencies | Acceptance Criteria |
|----|-------|------|-----------|-------------|---------------------|
| 3-1 | Tile Damage State Machine | tilemap-world | 2 | 1-3 | INTACT → DAMAGED → CRITICAL → DESTROYED |
| 3-2 | Vehicle Definition Loading | vehicle-type-database | 1 | None | VehicleTypeDB, state machine |
| 3-3 | Build Item Definition Loading | build-item-database | 1 | None | BuildItemDB, 12 MVP items |

---

## HIGH RISK Stories

| Story | Risk | Action |
|-------|------|--------|
| input-control-system/story-001 | ADR-003 Dual-focus (Godot 4.6) | Test on target engine before marking Done |
| enemy-ai-system/story-001 (future sprint) | ADR-010 NavigationAgent2D (Godot 4.5+) | Deferred to Sprint 2 |

---

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Dual-focus API differs from docs | Medium | High | Early testing on Godot 4.6 |
| entities.yaml parse errors | Low | Medium | Validate YAML before load |
| Chunk load exceeds 50ms budget | Low | Medium | Profile on target hardware |

---

## Dependencies on External Factors

- None for Foundation layer

---

## Definition of Done for this Sprint

- [ ] All Must Have stories completed (7 stories)
- [ ] All stories pass acceptance criteria
- [ ] QA plan exists (`production/qa/qa-plan-sprint-1.md`)
- [ ] All Logic stories have passing unit tests in `tests/unit/`
- [ ] Integration stories verified in `tests/integration/`
- [ ] Smoke check passed (`/smoke-check sprint`)
- [ ] QA sign-off report: APPROVED or APPROVED WITH CONDITIONS
- [ ] No S1 or S2 bugs in delivered features
- [ ] Code reviewed and merged

---

> ⚠️ **No QA Plan**: Run `/qa-plan sprint` before implementation begins.

---

## Next Steps

1. `/qa-plan sprint` — define test cases per story
2. `/story-readiness production/epics/tilemap-world/story-001-tilemaplayer-structure.md`
3. `/dev-story [story-path]` — begin first story implementation