# Block Collision System Review Log

---

## Review — 2026-04-23 — Verdict: MAJOR REVISION NEEDED → Revised

**Scope signal**: M (moderate complexity — 5 dependencies, 4 formulas, cross-cutting collision system)

**Specialists consulted**: game-designer, systems-designer, ai-programmer, godot-specialist, performance-analyst, creative-director

**Blocking items resolved**: 5 | **Recommended items applied**: 5

**Summary**: Design review found 4 P0 runtime-crash issues (DDA formula, set_cell order, raycast parameter, one_way_collision API) and 1 blocking interface gap (matches_collision_filter). All blockers resolved via revisions. Severity formula enhanced with vehicle context factors for Pillar 1 weight. Collision bit numbering and unit standardization corrected.

**Prior verdict resolved**: First review

---

### Blocking Issues Resolved

| # | Issue | Source | Resolution |
|---|-------|--------|------------|
| 1 | DDA formula `/2` factor computes midpoints, not boundaries | godot-specialist, systems-designer | Removed `/2` factor, corrected boundary calculation |
| 2 | `set_cell()` parameter order: `(cell, layer)` → should be `(layer, coords)` | godot-specialist | Fixed all 3 call sites to use correct signature |
| 3 | `PhysicsRayQueryParameters2D.create()` missing 4th parameter | godot-specialist | Added `collide_with_areas: bool` parameter (false) |
| 4 | `one_way_collision` on physics_layer is wrong API for Godot 4.6 | godot-specialist | Replaced with collision mask filtering approach |
| 5 | `matches_collision_filter()` interface undefined | ai-programmer | Added full definition with filter bitmask constants |

### Recommended Fixes Applied

| # | Issue | Source | Resolution |
|---|-------|--------|------------|
| 6 | Collision bit numbering wrong ("Bit 1 (value 1)") | systems-designer | Corrected to "Bit 0 (value 1)" format |
| 7 | MAX_VEHICLE_SPEED unit conflict (px/s vs cells/sec) | systems-designer | Standardized to 10.0 cells/sec |
| 8 | Severity formula ignores vehicle context | game-designer, creative-director | Added integrity_factor and obstacle_significance |
| 9 | Truncation ghost walls mitigation needed | game-designer | Added minimum wall thickness + fallback detection |
| 10 | `linear_velocity` vs `velocity` property mismatch | godot-specialist | Added body type handling for CharacterBody2D/RigidBody2D |

### Deferred Items (Post-MVP)

| # | Issue | Source | Resolution Path |
|---|-------|--------|-----------------|
| 1 | O(n²) WALL_BREAKER swarm performance | performance-analyst | Profile during Vertical Slice, adjust MAX_SEARCH_RADIUS_CELLS |
| 2 | 尸潮 frame budget exceeds 16.6ms | performance-analyst | Profiling task during Alpha phase |
| 3 | Nav mesh vs tile pathfinding (Q3) | ai-programmer | Resolve during 敌人AI系统 design |

---

### Creative Director Verdict

> "This GDD contained 4 P0 runtime-crash issues that would cause implementation failure. All blockers corrected. The severity formula now includes vehicle context factors for Pillar 1 weight. Collision bit numbering and unit standardization aligned with vehicle-type-database. Performance concerns scoped to 尸潮 (post-MVP) — tuning knobs exist. Recommend re-review in fresh session to verify revisions."

---

### Files Modified

- `design/gdd/block-collision-system.md` — Status: Revised (MAJOR REVISION → 2026-04-23)
- `design/registry/entities.yaml` — Collision bit descriptions corrected (Bit 0 format)

---

## Review — 2026-04-23 (Second) — Verdict: APPROVED

**Scope signal**: M (moderate complexity — 5 dependencies, 4 formulas, cross-cutting collision system)

**Specialists consulted**: game-designer, systems-designer, godot-specialist, ai-programmer, performance-analyst, creative-director

**Blocking items resolved**: 5 (new P0 blockers) | **Recommended items tracked**: 4 (P1 deferred to downstream systems)

**Summary**: Re-review found 5 new P0 blockers that prior review missed. All blockers resolved: DDA horizontal ray INF, ghost collision fallback removed, FILTER_REINFORCED completed, grazing severity baseline added, GDScript type error fixed. Added Q9 for 尸潮 collision budget strategy. All prior API fixes verified correct. GDD now approved for implementation.

**Prior verdict resolved**: Yes — First revision blockers verified + Second revision blockers resolved

---

### New P0 Blocking Issues Resolved (Second Revision)

| # | Issue | Source | Resolution |
|---|-------|--------|------------|
| 1 | DDA horizontal ray: `t_max.y` not set to INF when `dir_normalized.y==0` | systems-designer | Added `t_max.y = INF` else branch (line 386) |
| 2 | Ghost collision fallback creates vehicle stops in empty space | game-designer | Removed fallback detection; wall thickness recast as level design guidance |
| 3 | FILTER_REINFORCED never returned in `_get_block_flags()` placeholder | ai-programmer | Completed with ID ranges: 400-449 → DESTROYABLE, 450-499 → DESTROYABLE|REINFORCED |
| 4 | High-speed grazing produces severity=0 (no feedback) | game-designer | Added `grazing_baseline=0.15` when speed_ratio>0.5 and impact_angle<0.3 |
| 5 | GDScript type error: `maxi(..., 1.0)` | godot-specialist | Changed to `maxi(int(...), 1)` |

### P1 Recommendations Tracked (Deferred)

| # | Issue | Source | Resolution Path |
|---|-------|--------|-----------------|
| 1 | 尸潮 collision budget exceeds 16.6ms | performance-analyst | Q9 added — resolve in 尸潮规模预估 (#35) |
| 2 | WALL_BREAKER swarm 60% frame budget risk | ai-programmer | Throttle tuning knob — add in 敌人AI系统 (#36) |
| 3 | Severity ceiling compression | game-designer | Post-clamp multiplier approach — verify in playtest |
| 4 | Nav mesh interface incomplete | ai-programmer | Q3 already open — resolve in 敌人AI系统 (#36) |

### Prior Fixes Verified (First Revision)

All 4 prior P0 API fixes verified correct by godot-specialist:
- DDA `/2` factor removed ✓
- `set_cell()` parameter order corrected ✓
- `PhysicsRayQueryParameters2D.create()` 4th parameter added ✓
- `one_way_collision` API replaced with mask filtering ✓

---

### Creative Director Verdict (Second Review)

> "Prior revision claimed 5 blockers resolved — all verified correct. Second review found 5 new P0 blockers missed by prior review. All new blockers resolved via targeted edits. 尸潮 performance concern tracked in new Q9. GDD ready for implementation."

---

### Files Modified

- `design/gdd/block-collision-system.md` — Status: Approved (Second Revision)
- `design/gdd/systems-index.md` — Status: Approved, reviewed count updated
- `design/gdd/reviews/block-collision-system-review-log.md` — This entry appended

---

## Review — 2026-04-23 (Third) — Verdict: APPROVED

**Scope signal**: M

**Specialists**: N/A (lean mode — agent spawning failed, single-session analysis)

**Blocking items**: 0 | **Recommended**: 0

**Summary**: Third review triggered by consistency-check to verify bit numbering fix. block-collision-system.md internal bit notation correct (Bit 0-6). tilemap-world-system.md and block-type-database.md corrected. All prior 10 P0 fixes verified still correct. No new issues found. GDD remains Approved.

**Prior verdict resolved**: Yes — Second Revision APPROVED maintained

---

### Verification Summary

| Check | Result |
|-------|--------|
| Bit numbering (block-collision-system.md) | ✓ Bit 0-6 format correct |
| Bit numbering (entities.yaml) | ✓ COLLISION_TERRAIN=1 (Bit 0) correct |
| set_cell() API | ✓ (layer, coords, source_id...) |
| PhysicsRayQueryParameters2D.create | ✓ 4th param present |
| DDA formulas | ✓ boundary tests pass |
| Formula boundary tests | ✓ No division by zero, INF handled |

---

### Files Modified

- design/gdd/tilemap-world-system.md — Bit numbering corrected
- design/gdd/block-type-database.md — Bit numbering corrected

---

## Next Steps

Proceed to `/design-system 方块挖掘系统` (#12) or continue with `/consistency-check` for other systems.