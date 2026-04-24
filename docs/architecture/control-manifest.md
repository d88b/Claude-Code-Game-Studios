# Control Manifest

> **Engine**: Godot 4.6
> **Last Updated**: 2026-04-24
> **Manifest Version**: 2026-04-24
> **ADRs Covered**: ADR-001, ADR-002, ADR-003, ADR-004, ADR-005, ADR-006, ADR-007, ADR-008, ADR-009, ADR-010, ADR-011, ADR-012, ADR-013, ADR-014, ADR-015, ADR-016
> **Status**: Active — regenerate with `/create-control-manifest update` when ADRs change

This manifest is a programmer's quick-reference extracted from all Accepted ADRs,
technical preferences, and engine reference docs. For the reasoning behind each
rule, see the referenced ADR.

---

## Foundation Layer Rules

*Applies to: scene management, event architecture, save/load, engine initialisation, databases, time, input, world*

### Required Patterns

- **Use GlobalSignals autoload for cross-module communication** — emit global events (time_hour_changed, vehicle_damaged, enemy_spawned, etc.) — source: ADR-005
- **Use direct Signal for same-scene communication** — modules in same scene tree connect directly without GlobalSignals — source: ADR-005
- **Signal naming: snake_case past tense or state change** — e.g., `vehicle_damaged`, `time_hour_changed` — source: ADR-005
- **All Signal parameters must have type annotations** — e.g., `signal vehicle_damaged(amount: float)` — source: ADR-005
- **Subscribe GlobalSignals in _ready(), disconnect in _exit_tree()** — prevent signal connection leaks — source: ADR-005
- **Use TileMapLayer API (not deprecated TileMap)** — one TileMapLayer node per layer (5 layers: background/terrain_base/structures/platforms/overlay) — source: ADR-001
- **Cell coordinate system: grid_pos = world_pos / CELL_SIZE** — CELL_SIZE = 32 from entities.yaml — source: ADR-001
- **Chunk-based loading: 32x32 cells per chunk** — CHUNK_SIZE = 32, LOAD_RADIUS = 3 chunks around vehicle — source: ADR-001
- **Modified cells tracking for persistence** — modified_cells Dictionary persists changes for save/load — source: ADR-001
- **All static data from entities.yaml** — BlockTypeDB, ResourceDB, EnemyTypeDB, BuildItemDB, VehicleTypeDB, ScavengeContainerDB load from YAML — source: ADR-002
- **Database pattern: RefCounted Autoload** — databases are Autoload singletons, not Node-based — source: ADR-002
- **O(1) lookup via Dictionary** — all database queries use internal Dictionary for fast access — source: ADR-002
- **TimeSystem Autoload manages game clock** — current_time, day_count, time_scale as global state — source: ADR-004
- **Time scale: 1 real second = 60 game seconds** — TIME_SCALE_DEFAULT = 60.0 — source: ADR-004
- **Day phase boundaries: DAWN(5h), DAY(7h), DUSK(17h), NIGHT(19h)** — emit GlobalSignals.day_phase_changed on transition — source: ADR-004
- **InputManager Autoload provides state snapshot** — action_map, mouse_position, joystick_direction updated per frame — source: ADR-003
- **Dual-focus handling: KB/gamepad ≠ mouse/touch** — track current_focus (KEYBOARD_GAMEPAD, MOUSE_TOUCH, BOTH) — source: ADR-003
- **All input actions defined in Input Map** — move_up/down/left/right, fire, dig, place, menu_toggle, pause — source: ADR-003

### Forbidden Approaches

- **Never use deprecated TileMap API** — replaced by TileMapLayer since Godot 4.3 — source: ADR-001
- **Never hardcode game values** — all constants must reference entities.yaml TK-IDs — source: ADR-002
- **Never use direct Input singleton in Core systems** — use InputManager.is_action_pressed() for consistent state — source: ADR-003
- **Never assume mouse hover = keyboard focus** — dual-focus system separates them in Godot 4.6 — source: ADR-003
- **Never use hover-only UI interactions** — all UI must support gamepad navigation — source: ADR-003

### Performance Guardrails

- **Signal dispatch: <0.1ms/frame** — estimate <50 signals per frame — source: ADR-005
- **Database load: <100ms startup** — one-time YAML parse on game start — source: ADR-002
- **Input snapshot update: <0.1ms/frame** — 9 actions × Input.is_action_pressed() — source: ADR-003
- **TileMap chunk load: <50ms per chunk** — 32x32 cells procedural generation — source: ADR-001

---

## Core Layer Rules

*Applies to: core gameplay loop, vehicle systems, collision, movement, magic, combat, enemy AI, spawn*

### Required Patterns

- **Swept collision via DDA traversal** — use CollisionManager.swept_collision_check() to prevent tunneling — source: ADR-006
- **MAX_SWEPT_STEPS = 64** — maximum traversal steps per collision check — source: ADR-006
- **Severity formula: velocity.magnitude * friction / SEVERITY_BASE(100)** — calculate collision damage multiplier — source: ADR-006
- **Collision correction: velocity *= 0.5 bounce factor** — apply remaining_velocity with bounce on collision — source: ADR-006
- **Movement loop: Input → velocity → collision → magic → apply** — VehicleController._physics_process() sequence — source: ADR-008
- **Acceleration formula: velocity += acceleration_rate * input * delta** — from VehicleTypeDB stats — source: ADR-008
- **Speed clamp: |velocity| <= max_speed** — from VehicleTypeDB.get_vehicle_stats() — source: ADR-008
- **Magic consumption: cells * MAGIC_COST_PER_CELL(0.5)** — TK-013 constant — source: ADR-009
- **Magic depletion threshold: 10% of max_pool** — TK-014 triggers warning and slowdown — source: ADR-009
- **Depletion behavior: velocity *= 0.5** — slow vehicle when magic depleted — source: ADR-009
- **Vehicle state machine: GARAGE_IDLE → DEPLOYABLE → DEPLOYED → DISABLED → DESTROYED** — source: ADR-007
- **DISABLED threshold: health < 20%** — state transition on critical damage — source: ADR-007
- **DESTROYED threshold: health <= 0** — emit GlobalSignals.vehicle_destroyed — source: ADR-007
- **NavigationAgent2D for enemy pathfinding** — set_target() and get_next_path_position() — source: ADR-010
- **Enemy state machine: IDLE → PATROL → CHASE → ATTACK → FLEE → DEAD** — source: ADR-010
- **Boids separation: SEPARATION_FORCE = 0.3** — TK-064, prevent enemy overlap — source: ADR-010
- **Target acquisition: VehicleController.position** — for CHASE state enemies — source: ADR-010
- **Spawn wave timing: GlobalSignals.time_hour_changed** — night triggers spawn waves — source: ADR-012
- **Spawn position validation: within area bounds, not overlapping** — source: ADR-012
- **Weapon cooldown per shot** — prevent rapid fire, cooldown_timer tracked — source: ADR-011
- **Turret targeting: nearest enemy in detection_radius** — source: ADR-011
- **Damage formula: effective_damage = incoming - armor (min 0)** — source: ADR-011
- **Damage triggers GlobalSignals.vehicle_damaged** — emit on health change — source: ADR-011

### Forbidden Approaches

- **Never use CharacterBody2D.move_and_slide() for high-speed collision** — has tunneling risk, use swept collision — source: ADR-006
- **Never use per-module time tracking** — all systems must use TimeSystem singleton — source: ADR-004
- **Never use OS time APIs** — game time must be controllable via TimeSystem — source: ADR-004
- **Never spawn enemies without position validation** — check bounds and entity overlap — source: ADR-012
- **Never use frame-count based movement** — use delta-based velocity for stability — source: ADR-008

### Performance Guardrails

- **Swept collision: <1ms/frame** — 64 steps × 5 collision points — source: ADR-006
- **Enemy pathfinding: NavigationAgent2D built-in** — Godot optimized, no custom pathfinding — source: ADR-010
- **Movement loop: <2ms/frame** — Input + collision + magic + apply sequence — source: ADR-008
- **Spawn wave: batch instantiation** — spawn all wave enemies in single operation — source: ADR-012

---

## Feature Layer Rules

*Applies to: build system, facilities, drops, exploration areas, retreat judgment*

### Required Patterns

- **Dig progress: accumulated_damage >= block.difficulty** — then block destroyed — source: ADR-013
- **Placement validation: BuildValidator.validate_placement()** — check terrain support and entity collision — source: ADR-013
- **Placement cost: deduct from VehicleAttribute.cargo_contents** — source: ADR-013
- **Storage capacity: 100 slots per box** — TK-032 STORAGE_CAPACITY — source: ADR-014
- **Magic link distance: ≤10 cells from vehicle** — TK-047 for facility power — source: ADR-014
- **Workbench crafting: 4 MVP recipes** — iron/copper ingots, basic parts — source: ADR-014
- **Demolition refund: 50% of build cost** — TK-048 DEMOLITION_REFUND_RATE — source: ADR-014
- **Drop lifetime: 30 seconds** — ResourceDropEntity.lifetime — source: ADR-015
- **Drop pickup radius: 2 cells** — distance check per frame — source: ADR-015
- **Drop spawn: random offset from destroyed position** — source: ADR-015
- **Area bounds: Rect2 definition** — AreaManager.area_definitions — source: ADR-016
- **Area entry: GlobalSignals.area_entered.emit()** — on vehicle position crosses boundary — source: ADR-016
- **Retreat thresholds: health<20%, magic<10%, night** — emit GlobalSignals.retreat_threshold_reached — source: ADR-016

### Forbidden Approaches

- **Never place block without BuildValidator** — must pass terrain and collision checks — source: ADR-013
- **Never exceed storage capacity** — STORAGE_CAPACITY = 100 hard limit — source: ADR-014
- **Never allow facility operation without magic link** — check distance ≤10 cells — source: ADR-014
- **Never expire drops without visual/audio cue** — fade out effect before queue_free — source: ADR-015

---

## Presentation Layer Rules

*Applies to: rendering, audio, UI, VFX (no MVP systems — Full Vision tier)*

### Required Patterns

- **Day/night ambient lighting: CanvasModulate.color** — driven by TimeSystem.get_phase() — source: ADR-004
- **Overlay visibility: TileMapWorld.overlay_layer** — night darkness overlay — source: ADR-004
- **UI must support gamepad navigation** — Tab/Arrow focus, Enter confirm — source: ADR-003, accessibility-requirements.md

### Forbidden Approaches

- **No hover-only interactions** — all clickable elements must have gamepad/KB alternative — source: ADR-003

---

## Global Rules (All Layers)

### Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Classes | PascalCase | `VehicleController`, `CollisionManager` |
| Variables/functions | snake_case | `move_speed`, `take_damage()` |
| Signals | snake_case past tense | `vehicle_damaged`, `time_hour_changed` |
| Files | snake_case matching class | `vehicle_controller.gd` |
| Scenes | PascalCase matching root node | `VehicleController.tscn` |
| Constants | UPPER_SNAKE_CASE | `MAX_SWEPT_STEPS`, `CELL_SIZE` |

Source: `.claude/docs/technical-preferences.md`

### Performance Budgets

| Target | Value |
|--------|-------|
| Target framerate | 60 fps |
| Frame budget | 16.6 ms/frame |
| Draw calls | <100 (2D pixel art) |
| Memory ceiling | 512 MB |

Source: `.claude/docs/technical-preferences.md`

### Approved Libraries / Addons

- **GUT (Godot Unit Testing)** — GDScript-native test framework — source: technical-preferences.md
- **YAML Parser** — for entities.yaml loading (addon or custom) — source: ADR-002

### Forbidden APIs (Godot 4.6)

These APIs are deprecated or must be replaced:

- **`TileMap` node** — deprecated since 4.3, use `TileMapLayer` — source: `docs/engine-reference/godot/deprecated-apis.md`
- **`yield()`** — deprecated since 4.0, use `await signal` — source: `docs/engine-reference/godot/deprecated-apis.md`
- **String-based `connect()`** — deprecated since 4.0, use `signal.connect(callable)` — source: `docs/engine-reference/godot/deprecated-apis.md`
- **`instance()`** — deprecated since 4.0, use `instantiate()` — source: `docs/engine-reference/godot/deprecated-apis.md`

### HIGH RISK Engine APIs (Verify Before Use)

These APIs are post-cutoff (Godot 4.4+) and require testing:

- **Dual-focus Input (Godot 4.6)** — KB/gamepad focus separate from mouse/touch — verify in ADR-003
- **NavigationAgent2D (Godot 4.5+)** — dedicated 2D navigation server — verify in ADR-010
- **FileAccess return type (Godot 4.4)** — returns FileAccess not File — verify before save/load implementation

Source: `docs/engine-reference/godot/VERSION.md`, ADR-003, ADR-010

### Cross-Cutting Constraints

- **All game values reference TK-IDs** — no hardcoded numbers, use GameConfig.get_tuning_knob(tk_id)
- **All data definitions include Chinese display_name** — entities.yaml entries must have 中文名称
- **All systems emit appropriate GlobalSignals** — cross-module communication via event bus
- **All collision checks use swept algorithm** — prevent tunneling at high velocity
- **All time-dependent systems use TimeSystem** — no direct OS time or per-module clocks

---

## Verification Checklist

Before starting implementation, verify:

- [ ] All ADRs referenced in this manifest are Accepted status
- [ ] Manifest Version matches date in production/stage.txt
- [ ] HIGH RISK APIs tested on target engine version
- [ ] Forbidden APIs not used in any code
- [ ] Performance budgets understood and documented