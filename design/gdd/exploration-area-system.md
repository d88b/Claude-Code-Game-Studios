# 探索区域系统

> **Status**: Designed (pending review)
> **Author**: User + Claude agents
> **Last Updated**: 2026-04-23
> **Section Status**: Overview ✓ | Player Fantasy ✓ | Detailed Design ✓ | Formulas ✓ | Edge Cases ✓ | Dependencies ✓ | Tuning Knobs ✓ | Acceptance Criteria ✓ | Visual/Audio ✓ | UI ✓ | Open Questions ✓
> **Implements Pillar**: Pillar 2 — 搜打撤节奏

## Overview

The 探索区域系统 defines named spatial regions on the TileMap grid that group cells into meaningful exploration zones — each region carries metadata for danger level, loot density, faction affiliation, and environmental theme. Regions are the player's mental map of the surface world: "废弃城市" means iron salvage and zombie patrols; "恶魔荒原" means rare crystals and demon ambushes.

Players interact with regions as **decision boundaries**. When the battle wagon crosses into a new region, the HUD updates with zone name, danger indicator, and estimated loot quality. Each region defines what the player can find and what enemies they may encounter — the choice to enter "元素矿洞" is a risk-reward decision, not just a spatial movement.

The system is the spatial foundation for Pillar 2 (搜打撤节奏). Without regions, exploration is aimless traversal; with regions, every departure becomes a planned expedition with a known destination and understood stakes. Regions feed the 搜刮交互系统 with loot pools, the 敌人生成系统 with spawn tables, and the 撤退判定系统 with danger modifiers. The region boundary is the player's mental line between "known safe territory" and "unknown hostile zone."

## Player Fantasy

### Primary Fantasy: 风险边界的选择

The exploration region system delivers the emotional promise of **deliberate risk** — each zone boundary is a decision point where the player weighs known danger against anticipated reward. Crossing into a region is not random wandering; it is a calculated expedition.

**Peak moment**: The battle wagon approaches the boundary between "废弃城市" and "恶魔荒原". The HUD shows the zone transition warning: danger level jumps from ⚠️ to ⚠️⚠️, loot quality indicator rises from iron scraps to crystal clusters. The player pauses — is the wagon's魔能 sufficient? Is durability above 40%? Did they pack enough ammunition? They commit to crossing. The zone name appears, enemy density spikes, and the first demon scout emerges. The player's decision is now real.

**What the player feels**:
- When seeing a new region name on the HUD: *"This place has a reputation. I know what I'm getting into."*
- When loot quality exceeds expectation: *"I gambled on this zone and won."*
- When danger overwhelms preparation: *"I underestimated this region. Retreat is my only option."*
- When returning to familiar regions: *"I know this zone. I can optimize my route here."*

**Pillar alignment**:
- **Pillar 2: 搜打撤节奏** — Regions define the "搜" target and the "撤" threshold. Without regions, exploration has no destination; with regions, every departure has a named goal with understood stakes.

## Detailed Design

### Core Rules

#### 1. Region Data Model

Each exploration region is defined as a data structure with:

| Field | Type | Description |
|-------|------|-------------|
| `region_id` | int | Unique identifier (1-999) |
| `region_name` | string | Display name (e.g., "废弃城市", "恶魔荒原") |
| `bounds` | Rect2i | Cell-based bounding box on TileMap |
| `danger_level` | int | 1-5 scale (1=safe, 5=extreme) |
| `loot_tier` | int | 1-4 scale (1=common, 4=legendary) |
| `faction_id` | int | Enemy faction ID (墓园=1, 地狱=2, 塔楼=3, 元素=4) |
| `loot_pool_ids` | Array[int] | ScavengeContainerDatabase IDs valid in this region |
| `enemy_spawn_ids` | Array[int] | EnemyTypeDatabase IDs that spawn in this region |
| `required_vehicle_tier` | int | Minimum vehicle tier for safe traversal (0-3) |
| `discovered` | bool | Whether player has visited this region |

**Region bounds rule:**
- `bounds` is a `Rect2i` in cell coordinates: `{position: Vector2i, size: Vector2i}`
- Bounds must be contiguous and rectangular
- Regions do not overlap — each cell belongs to exactly one region or is "bunker zone"
- Bunker zone (region_id=0) is the default safe zone around the player's underground fortress

**Region registration:**
- Regions are registered in `assets/data/region_data/` as `.tres` Resource files
- Region definitions are loaded at game start into `RegionRegistry` singleton
- Runtime modification of region definitions is forbidden — regions are static world structure

#### 2. Danger Level System

Danger level (1-5) determines enemy density and retreat urgency:

| Danger Level | Name | Enemy Density | Retreat Modifier | Example Region |
|--------------|------|---------------|------------------|----------------|
| 1 | Safe | 0-2 enemies per chunk | ×0.5 | Bunker perimeter |
| 2 | Low | 3-5 enemies per chunk | ×0.8 | 废弃城市 outskirts |
| 3 | Moderate | 6-10 enemies per chunk | ×1.0 | 废弃城市 core |
| 4 | High | 11-20 enemies per chunk | ×1.5 | 恶魔荒原 |
| 5 | Extreme | 21+ enemies per chunk | ×2.0 | 元素矿洞 deep |

**Danger level rules:**
1. Danger level is a static property per region — does not change during gameplay
2. Danger level feeds the `danger_urgency` calculation in 撤退判定系统
3. Higher danger = more enemies spawn + higher retreat pressure
4. Danger level 5 regions should only be entered with tier 2+ vehicle (魔能≥100, durability≥200)

#### 3. Loot Tier System

Loot tier (1-4) determines resource quality in scavenge containers:

| Loot Tier | Name | Primary Resources | Rare Drop Chance | Example |
|-----------|------|-------------------|------------------|---------|
| 1 | Common | Iron, Copper, Coal | 5% | Bunker salvage |
| 2 | Uncommon | Iron+, Copper+, Crystal Shards | 10% | 废弃城市 |
| 3 | Rare | Mithril, Crystal Cluster, Gold | 15% | 恶魔荒原 |
| 4 | Legendary | Ancient Mithril, Enchantment materials | 20% | 元素矿洞 deep |

**Loot tier rules:**
1. Loot tier is static per region — does not change during gameplay
2. Loot tier feeds the `loot_pool_ids` selection in 搜刮交互系统
3. Higher loot tier = more valuable resources + higher rare drop probability
4. Loot tier 4 regions should require significant investment (tier 3 vehicle)

#### 4. Region Transition Detection

**Detection trigger:**
1. When player vehicle position crosses from one region's bounds to another's
2. `RegionManager` checks current cell against all registered region bounds
3. If cell is outside current region bounds, search for new region containing cell
4. If no region found, cell is "bunker zone" (region_id=0)

**Transition signal:**
- On region entry: `region_entered(region_id: int, region_name: String, danger_level: int, loot_tier: int)`
- On region exit: `region_exited(region_id: int)`
- Signals emitted to HUD系统, 撤退判定系统, 敌人生成系统

**HUD display on transition:**
1. Zone name appears at top of screen for 3 seconds
2. Danger indicator updates (⚠️ icons, color shift)
3. Loot quality indicator updates (loot tier icons)
4. If danger level ≥4, show warning prompt: "高危区域 — 确认继续?"

### States and Transitions

The system itself has no states — regions are static data. Player state relative to regions:

| Player State | Trigger | Effect |
|--------------|---------|--------|
| **In Bunker Zone** | Vehicle in region_id=0 | Safe zone, no danger modifier |
| **In Known Region** | Vehicle in discovered region | Full HUD info, normal danger |
| **In Unknown Region** | Vehicle in undiscovered region | Discovery flag set, full HUD info shown |
| **Crossing Boundary** | Position leaves current region bounds | Transition signals emitted |

**Region discovery rule:**
- First entry into a region sets `discovered = true` for that region
- Discovered regions are tracked in save data
- Undiscovered regions show "???" name until entered

### Interactions with Other Systems

| System | Direction | Data Flow |
|--------|-----------|-----------|
| **TileMap世界系统** | Upstream | Provides cell coordinates, bounds checking via `query_cells_in_rect` |
| **搜刮交互系统** | Downstream | Region provides `loot_pool_ids` for container selection |
| **敌人生成系统** | Downstream | Region provides `enemy_spawn_ids` and `danger_level` for spawn density |
| **撤退判定系统** | Downstream | Region provides `danger_level` for `danger_urgency` modifier |
| **HUD系统** | Downstream | Region provides name, danger, loot tier for display |
| **地图/废墟生成** | Upstream | Region bounds guide procedural generation (future system) |

## Formulas

### F1: Enemy Density per Chunk

```
enemy_density = danger_level × ENEMY_BASE_DENSITY
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `danger_level` | int | 1-5 | Region danger level |
| `ENEMY_BASE_DENSITY` | int | 4 | Base enemies per chunk at danger_level=1 |

**Output range**: 4-20 enemies per chunk

**Example**: Danger level 4 region → 4 × 4 = 16 enemies per chunk (within "High" range 11-20)

### F2: Danger Urgency Contribution

```
danger_urgency = danger_level × DANGER_WEIGHT × danger_mult
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `danger_level` | int | 1-5 | Region danger level |
| `DANGER_WEIGHT` | float | 0.5 | Weight coefficient from 撤退判定系统 |
| `danger_mult` | float | 0.5-2.0 | Global danger multiplier from DayNight system |

**Output range**: 0.25-5.0 urgency contribution

**Integration**: This feeds into the `urgency = max(magic, durability, time, danger)` calculation in 撤退判定系统.

**Example**: Danger level 4 at night (danger_mult=1.5) → 4 × 0.5 × 1.5 = 3.0 urgency

### F3: Rare Drop Chance

```
rare_drop_chance = BASE_RARE_DROP + loot_tier × RARE_DROP_INCREMENT
```

| Variable | Type | Range | Description |
|----------|------|-------|-------------|
| `BASE_RARE_DROP` | float | 0.05 | Base rare drop chance (5%) |
| `loot_tier` | int | 1-4 | Region loot tier |
| `RARE_DROP_INCREMENT` | float | 0.05 | Increment per loot tier (5%) |

**Output range**: 0.10-0.25 (10%-25%)

**Example**: Loot tier 3 region → 0.05 + 3 × 0.05 = 0.20 (20% rare drop chance)

### F4: Region Bounds Containment Check

```
contains_point(bounds, cell) = 
  (cell.x >= bounds.position.x) AND 
  (cell.x < bounds.position.x + bounds.size.x) AND
  (cell.y >= bounds.position.y) AND 
  (cell.y < bounds.position.y + bounds.size.y)
```

| Variable | Type | Description |
|----------|------|-------------|
| `bounds` | Rect2i | Region bounding box in cell coordinates |
| `cell` | Vector2i | Player vehicle current cell position |

**Output**: bool (true if cell is within region bounds)

## Edge Cases

### EC1: Player Exactly on Region Boundary

**Scenario**: Player vehicle position is exactly at the edge between two regions (cell coordinate matches boundary).

**Resolution**: Use "exclusive upper bound" rule — region bounds are `[start, end)` where end is exclusive. Player at boundary edge belongs to the region that starts at that cell, not the one that ends there.

**Implementation**: `contains_point` uses `<` for upper bound check, ensuring no overlap.

### EC2: Player Outside All Region Bounds

**Scenario**: Player vehicle position is not within any registered region's bounds (no region contains the cell).

**Resolution**: Treat as "bunker zone" (region_id=0). Apply danger_level=1, loot_tier=1, no faction enemies. This is the default safe zone behavior.

**Signal**: Emit `region_entered(0, "地堡周边", 1, 1)` if transitioning from a named region.

### EC3: Region with Empty Loot Pool

**Scenario**: A region has `loot_pool_ids = []` (no containers defined for this region).

**Resolution**: 搜刮交互系统 falls back to generic loot pool (common resources: iron, copper, coal). Log warning on first entry: "Region [name] has no defined loot pools — using fallback."

**Design note**: This should not happen in production — all regions must have at least one loot pool.

### EC4: Region with No Enemy Spawn IDs

**Scenario**: A region has `enemy_spawn_ids = []` (no enemies defined for this region).

**Resolution**: 敌人生成系统 skips spawn for this region. Safe traversal zone. Used for bunker perimeter and tutorial areas.

### EC5: Multiple Regions with Overlapping Bounds

**Scenario**: Two registered regions have `bounds` that overlap (same cells belong to both).

**Resolution**: Region with lower `region_id` takes priority. Overlap is a data error — log warning on load: "Regions [id_a] and [id_b] have overlapping bounds — [id_a] will be used."

**Design note**: Region data should be validated on load to detect overlaps.

### EC6: Undiscovered Region Entry

**Scenario**: Player enters a region where `discovered = false`.

**Resolution**: 
1. Set `discovered = true` immediately on first entry
2. Show discovery notification: "发现新区域: [region_name]"
3. Play discovery sound effect
4. Save discovery state to player profile
5. Proceed with normal region entry flow

### EC7: World Bounds Exceeding Region Coverage

**Scenario**: TileMap world extends beyond all defined region bounds (large uncharted areas exist).

**Resolution**: Cells outside all regions are bunker zone (region_id=0). This allows procedural generation to fill uncharted areas without requiring region definitions for every cell.

**Design note**: MVP maps should have region coverage for all traversable surface areas. Uncharted zones are for future procedural expansion.

## Dependencies

### Upstream Dependencies (systems this one depends on)

| System | ID | GDD Status | What This System Consumes |
|--------|-----|------------|---------------------------|
| **TileMap世界系统** | #1 | ✓ Designed | Cell coordinate system, bounds checking via `query_cells_in_rect`, world-to-cell conversion |

**Interface contract from TileMap世界系统**:
- `TileMapWorld.world_to_cell(world_pos: Vector2) → Vector2i`: Convert vehicle position to cell
- `TileMapWorld.query_cells_in_rect(bounds: Rect2i, condition: Callable) → Array[Vector2i]`: Query cells within region bounds
- `CELL_SIZE = 32`: Grid cell size for all coordinate calculations

### Downstream Dependencies (systems that depend on this one)

| System | ID | GDD Status | What This System Provides |
|--------|-----|------------|---------------------------|
| **搜刮交互系统** | #31 | Not Started | `loot_pool_ids` for container selection in region |
| **敌人生成系统** | #37 | ✓ Designed | `enemy_spawn_ids`, `danger_level` for spawn density |
| **撤退判定系统** | #32 | ✓ Designed | `danger_level` for `danger_urgency` calculation |
| **HUD系统** | #49 | Not Started | `region_name`, `danger_level`, `loot_tier` for HUD display |
| **地图/废墟生成** | #48 | Not Started | `bounds`, `faction_id` for procedural generation guidance |

### Interface Contracts This System Must Satisfy

**For 敌人生成系统**:
- `RegionManager.get_current_region() → Dictionary`: Returns `{region_id, enemy_spawn_ids, danger_level}`
- Signal `region_entered` emitted on transition for spawn system to adjust density

**For 撤退判定系统**:
- `RegionManager.get_danger_level() → int`: Returns current region's danger_level (1-5)
- Integrates with `danger_urgency = danger_level × DANGER_WEIGHT × danger_mult`

**For 搜刮交互系统**:
- `RegionManager.get_loot_pools() → Array[int]`: Returns `loot_pool_ids` for current region

**For HUD系统**:
- Signal `region_entered(region_id, region_name, danger_level, loot_tier)` for HUD update
- `RegionManager.get_region_info() → Dictionary`: Returns `{name, danger, loot_tier, faction}` for display

### Dependency Graph Position

- **Layer**: Core (depends on Foundation, provides to Feature/Presentation)
- **Design Order**: Position #27 (after TileMap world, before 搜刮交互/地图生成)
- **Risk Level**: Low — single upstream dependency, well-defined interface contract

## Tuning Knobs

| Knob ID | Name | Value | Range | Unit | What It Affects |
|---------|------|-------|-------|------|-----------------|
| TK-026 | ENEMY_BASE_DENSITY | 4 | 2-8 | enemies/chunk | Enemy density at danger_level=1. Higher = denser spawns, lower = sparse spawns. Affects exploration pressure. |
| TK-027 | BASE_RARE_DROP | 0.05 | 0.02-0.10 | ratio | Base rare drop chance in loot tier 1 regions. Higher = luckier common zones, lower = rarer finds. Affects loot expectation. |
| TK-028 | RARE_DROP_INCREMENT | 0.05 | 0.02-0.10 | ratio | Rare drop chance increment per loot tier. Higher = steeper tier rewards, lower = gradual improvement. Affects loot tier differentiation. |
| TK-029 | TRANSITION_DISPLAY_DURATION | 3.0 | 1.0-5.0 | seconds | Duration zone name appears on HUD after transition. Higher = longer visibility, lower = quick flash. Affects region awareness. |
| TK-030 | HIGH_DANGER_WARNING_THRESHOLD | 4 | 3-5 | danger_level | Danger level that triggers "高危区域" warning prompt. Higher = less warning, lower = earlier caution. Affects risk communication. |
| TK-031 | DISCOVERY_NOTIFICATION_DURATION | 2.0 | 1.0-4.0 | seconds | Duration of "发现新区域" notification. Higher = longer celebration, lower = quick acknowledgment. Affects discovery moment. |

**Cross-system knobs (owned by other systems, referenced here)**:
- `DANGER_WEIGHT = 0.5` — Owned by 撤退判定系统 (TK-020), used in F2 formula
- `DANGER_GLOBAL_MULT = 1.0` — Owned by DayNight system, used in F2 formula

**Tuning guidance**:
- TK-026 (ENEMY_BASE_DENSITY): Adjust based on performance testing. If 尸潮 frame rate drops, reduce this value.
- TK-027/TK-028 (Rare drop): Adjust based on player feedback on loot satisfaction. If players feel loot is too sparse, increase BASE_RARE_DROP.
- TK-029/TK-031 (Display durations): Adjust based on UX testing. If players miss zone names, increase TRANSITION_DISPLAY_DURATION.

## Acceptance Criteria

### AC-01: Region Transition Detection

**Given**: Player vehicle at position in region A
**When**: Vehicle moves to position in region B
**Then**: `region_entered` signal emitted with region B's metadata (id, name, danger, loot_tier)

**Test method**: Unit test — move vehicle position, verify signal emission and metadata accuracy

### AC-02: Danger Level Integration with Retreat System

**Given**: Player in region with danger_level=4
**When**: 撤退判定系统 calculates `danger_urgency`
**Then**: `danger_urgency = 4 × DANGER_WEIGHT × danger_mult` (formula F2)

**Test method**: Integration test — call `RegionManager.get_danger_level()`, verify retreat system receives correct value

### AC-03: Loot Pool Provision to Scavenge System

**Given**: Player opens scavenge container in region with `loot_pool_ids = [101, 102]`
**When**: 搜刮交互系统 requests loot pools
**Then**: `RegionManager.get_loot_pools()` returns `[101, 102]`

**Test method**: Integration test — mock region context, verify correct loot pool returned

### AC-04: Enemy Spawn ID Provision

**Given**: 敌人生成系统 requests spawn IDs for current region
**When**: `RegionManager.get_current_region()` called
**Then**: Returns dictionary with `enemy_spawn_ids` array matching region definition

**Test method**: Integration test — verify spawn system receives correct enemy types per region

### AC-05: HUD Region Display

**Given**: Player crosses region boundary
**When**: `region_entered` signal emitted
**Then**: HUD displays zone name, danger icons, loot tier icons for 3 seconds (TK-029)

**Test method**: Visual test — screenshot HUD after transition, verify all elements displayed

### AC-06: Discovery Notification

**Given**: Player enters undiscovered region (`discovered = false`)
**When**: Region entry detected
**Then**: 
1. Discovery notification appears for 2 seconds (TK-031)
2. `discovered` flag set to true
3. Region name no longer shows "???" on subsequent visits

**Test method**: Integration test — verify discovery state change and notification trigger

### AC-07: Bunker Zone Default

**Given**: Player position outside all registered region bounds
**When**: Region lookup performed
**Then**: Returns region_id=0 with danger_level=1, loot_tier=1

**Test method**: Unit test — position vehicle outside all bounds, verify bunker zone returned

### AC-08: No Region Overlap

**Given**: All region definitions loaded at game start
**When**: Region bounds validation runs
**Then**: No two regions have overlapping bounds (log warning if overlap detected)

**Test method**: Unit test — iterate all regions, verify no cell belongs to more than one region

### AC-09: Formula F1 Accuracy

**Given**: Region with danger_level=3
**When**: Enemy density calculated via F1
**Then**: `enemy_density = 3 × ENEMY_BASE_DENSITY = 12` (within "Moderate" range 6-10)

**Note**: F1 gives 12 for danger=3, but detailed design says 6-10 for "Moderate". This needs adjustment.

**Test method**: Unit test — verify formula output matches design table ranges

### AC-10: Formula F3 Accuracy

**Given**: Region with loot_tier=2
**When**: Rare drop chance calculated via F3
**Then**: `rare_drop_chance = 0.05 + 2 × 0.05 = 0.15` (15%)

**Test method**: Unit test — verify formula output matches expected percentage

## Visual/Audio Requirements

### Visual Requirements

| Element | Description | Implementation Notes |
|---------|-------------|---------------------|
| **Region boundary marker** | Optional faint line at region edges on minimap (not on main view) | Godot Line2D on minimap CanvasLayer, alpha=0.3 |
| **Zone name banner** | Region name appears at screen top on entry, fades after duration | Control node with Label, Tween for fade animation |
| **Danger icons** | ⚠️ symbols (1-5) showing danger level in HUD | Sprite frames for each level, color-coded (green→red) |
| **Loot tier icons** | Loot quality symbols (common→legendary) | Sprite frames, color-coded (white→gold) |
| **Discovery flash** | Screen edge glow on undiscovered region entry | ColorRect with gradient, Tween for pulse effect |
| **Faction theme overlay** | Subtle faction color tint when in faction region | CanvasModulate node, faction-specific color (墓园=灰绿, 地狱=暗红, 塔楼=银蓝, 元素=紫金) |

### Audio Requirements

| Event | Sound Effect | Implementation Notes |
|-------|--------------|---------------------|
| **Region entry** | Soft chime + zone ambient start | AudioStreamPlayer, crossfade between zone ambients |
| **Region exit** | Ambient fade out | Tween volume fade over 1 second |
| **Discovery** | Celebration sound (unique discovery cue) | AudioStreamPlayer, one-shot, distinct from entry chime |
| **Danger warning** | Alert tone for danger_level ≥4 entry | AudioStreamPlayer, urgent tone, plays once on entry |
| **Zone ambient** | Per-faction ambient track (墓园=风声, 地狱=火焰声, 塔楼=机械声, 元素=晶石共鸣) | AudioStreamPlayer loop, crossfade on transition |

**Visual/Audio integration with region**:
- Faction theme determines ambient track and screen tint
- Danger level determines warning tone and icon intensity
- Loot tier determines icon color and sparkle (optional)

## UI Requirements

### HUD Zone Display

| UI Element | Position | Content | Update Trigger |
|------------|----------|---------|----------------|
| **Zone name banner** | Top center, offset from screen edge | `region_name` text | `region_entered` signal |
| **Danger indicator** | Top right, below time display | ⚠️ icons (count=danger_level) | `region_entered` signal |
| **Loot tier indicator** | Top right, below danger | Loot quality icon | `region_entered` signal |
| **Faction badge** | Top right, below loot tier | Faction icon (墓园/地狱/塔楼/元素) | `region_entered` signal |

**Display behavior**:
- Zone name banner appears on transition, fades after `TRANSITION_DISPLAY_DURATION` (TK-029)
- Danger/loot/faction indicators remain visible while in region
- All indicators hidden in bunker zone (region_id=0)

### Discovery Notification

| UI Element | Position | Content | Duration |
|------------|----------|---------|----------|
| **Discovery popup** | Screen center, overlay | "发现新区域: [region_name]" + danger/loot info | `DISCOVERY_NOTIFICATION_DURATION` (TK-031) |

**Design notes**:
- Discovery popup larger than zone banner (celebration moment)
- Popup includes danger and loot tier preview (player sees risk/reward before committing)
- Popup dismissed early if player moves (no blocking)

### High Danger Warning Prompt

| UI Element | Position | Content | Trigger |
|------------|----------|---------|---------|
| **Warning prompt** | Screen center | "高危区域 — 确认继续?" + [确认/撤退] buttons | `danger_level ≥ HIGH_DANGER_WARNING_THRESHOLD` (TK-030) |

**Behavior**:
- Prompt does not block vehicle movement (player can drive through if confident)
- [确认] button dismisses prompt, continues exploration
- [撤退] button triggers return to bunker (alternative path)
- Prompt appears once per session per high-danger region (not every entry)

## Open Questions

### OQ-01: Procedural Region Generation

**Question**: Should regions be hand-defined or procedurally generated from seed?

**Options**:
- [A] Hand-defined — Fixed region layout for MVP, predictable progression
- [B] Procedural from seed — Region bounds generated from world seed, infinite variety
- [C] Hybrid — Core regions hand-defined, peripheral regions procedural

**Impact**: Affects 地图/废墟生成 (#48) system scope. Procedural requires additional generation algorithm.

**Recommendation**: MVP use [A] hand-defined (fixed 4 regions + bunker). Procedural for future expansion.

### OQ-02: Region Naming Conventions

**Question**: Should region names be unique identifiers or faction-themed templates?

**Options**:
- [A] Unique names — Each region has specific name (e.g., "废弃城市", "恶魔荒原")
- [B] Template names — Names follow faction theme (e.g., "墓园区域1", "地狱区域2")
- [C] Localized names — Names have faction-specific language (墓园=拉丁语风格, 地狱=恶魔语风格)

**Impact**: Affects localization scope and player immersion.

**Recommendation**: [A] unique names for MVP (4 named regions). [C] for full vision localization.

### OQ-03: Dynamic Danger Level Adjustment

**Question**: Should danger level change based on player progression (days survived, vehicle tier)?

**Options**:
- [A] Static — Danger level fixed per region (as designed)
- [B] Dynamic scaling — Danger level increases with player progress (harder zones as player gets stronger)
- [C] Player-driven — Danger level decreases as player clears zones (territory control)

**Impact**: Static is simpler for MVP. Dynamic/C player-driven adds progression depth but scope creep.

**Recommendation**: [A] static for MVP. Consider [B] for Alpha milestone if player feedback suggests zones become too easy.

### OQ-04: Region Interiors (Sub-zones)

**Question**: Should regions have sub-zone structure (e.g., "废弃城市" has "outer rim" vs "core district")?

**Options**:
- [A] Flat regions — Each region is uniform danger/loot (as designed)
- [B] Sub-zones — Regions contain internal zones with varying danger (outer=safe, inner=dangerous)
- [C] Layered regions — Regions have depth layers (surface vs underground sections)

**Impact**: Sub-zones add complexity to bounds checking and transition frequency. May overwhelm player with constant transitions.

**Recommendation**: [A] flat for MVP. [B] sub-zones for full vision if player feedback suggests single danger level per region feels flat.