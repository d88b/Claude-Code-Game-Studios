# Review Log: 魔能消耗计算 (Magic Energy Consumption)

---

## Review — 2026-04-23 — Verdict: APPROVED

**Scope signal**: M (moderate complexity — 6 formulas, 1 ADR likely, 3+ existing dependencies)
**Specialists consulted**: game-designer, systems-designer, qa-lead (direct analysis)
**Blocking items**: 3 (resolved) | **Recommended**: 5 (resolved)
**Summary**: Solid design foundation with comprehensive formula coverage and Player Fantasy alignment. Tuning values may undermine Pillar 2 (搜打撤节奏) tension — range too generous, shooting penalty mild. Playtest validation required before locking defaults. Edge cases and ACs revised for specificity.
**Prior verdict resolved**: First review

---

### Required Items (All Resolved)

1. **[systems-designer]** Add EC-021: negative distance input → clamp to 0.0, log warning
2. **[systems-designer]** Add EC-022: remaining_range output clamp to 0.0 minimum
3. **[qa-lead]** Rewrite vague ACs (AC-017, AC-018, AC-021, AC-032, AC-034) with specific assertions

**Resolution**: All items addressed in revision pass.

---

### Recommended Items (All Addressed)

4. **[game-designer]** MAX_LOAD_PENALTY_SHOOTING=0.15 may be too mild — tuning advisory added
5. **[game-designer]** Remaining range should use conservative estimate — noted in tuning advisory
6. **[systems-designer]** Consider MAX_BURST_COST cap — noted as future enhancement
7. **[qa-lead]** AC specificity rewrites — 5 ACs rewritten
8. **[main-review]** Weapon type database interface provisional — documented in Dependencies

---

### Tuning Advisory Added

Validation note appended to Tuning Knobs section recommending MVP playtest for:
- MAGIC_COST_PER_CELL range pressure (current 0.5 may be too generous)
- MAX_LOAD_PENALTY_SHOOTING shooting/driving competition
- Conservative rate for retreat anxiety

---

### Next Systems in Design Order

- #20: 战车武器系统 (Vehicle Weapon System)
- #21: 战车损坏系统 (Vehicle Damage System)
- #32: 撤退判定系统 (Retreat Decision System)