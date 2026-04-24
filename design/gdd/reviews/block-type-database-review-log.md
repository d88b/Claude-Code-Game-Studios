# Block Type Database — Design Review Log

> Tracks review history for `design/gdd/block-type-database.md`

---

## Review — 2026-04-22 — Verdict: APPROVED (Revised)

Scope signal: M
Specialists: game-designer, systems-designer, godot-specialist, qa-lead, creative-director
Blocking items: 5 | Recommended: 4
Summary: Initial review identified 5 P0 Godot API errors (TileData external files, singleton extends Resource, custom_data_layers format, physics_layers empty, collision_shape=3 unusable) and 4 P1 design issues (hardness tier calibration, untestable ACs). All P0/P1 issues were revised. Hardness tier recalibrated to 40%+ jumps (Surface=60→Cave=100→Deep=150→Abyss=210). 14 problematic ACs rewritten with concrete thresholds and exact counts.
Prior verdict resolved: First review

### Blocking Items Resolved (P0)

| # | Issue | Fix Applied |
|---|-------|-------------|
| 1 | TileData cannot be stored as external .tres files in Godot 4.x | Removed file structure references to external TileData; noted all TileData embedded in TileSet |
| 2 | Autoload singleton must extend Node, not Resource | Changed BlockTypeDatabase to `extends Node` |
| 3 | custom_data_layers requires name and type properties | Added proper structure: `custom_data_layers/0/name = "hardness"` with `type = 2` (INT) |
| 4 | physics_layers requires collision_layer and collision_mask | Added bit values: `physics_layers/0/collision_layer = 1` etc. |
| 5 | collision_shape=3 (CUSTOM) unusable — no layer accepts custom collision | Removed enum value 3, limited to 0-2 for MVP |

### Recommended Items Resolved (P1)

| # | Issue | Fix Applied |
|---|-------|-------------|
| 6 | hardness=0 causes division by zero in dig progress formula | Added HARDNESS_ZERO_INSTANT_DESTRUCTION rule with special handling |
| 7 | resource_multiplier=0.0 with resource_type_id>0 is contradictory | Added contradiction validation rule |
| 8 | Hardness tier ratios below 40% perceptibility threshold | Recalibrated: Surface=60, Cave=100 (67%), Deep=150 (50%), Abyss=210 (40%) |
| 9 | 14 Acceptance Criteria not independently testable | Rewritten AC-001, AC-017-022, AC-023-025, AC-028, AC-032-036, AC-037 with concrete thresholds |

### Remaining Advisory Items (P2)

| # | Item | Notes |
|---|------|-------|
| 1 | TileData physics polygon format | Verify exact Godot 4.6 polygon format during implementation |
| 2 | Damage variant selection ownership | Clarify with TileMap system whether BlockTypes or TileMap manages damage state → variant mapping |
| 3 | LocalizationManager integration | Verify LocalizationManager exists before implementing get_display_name delegation |

---

**Next Review**: Not required — approved for implementation. Run `/consistency-check` when 资源数据库 GDD is complete to verify resource_type_id alignment.