# Story 004: Performance Optimization

> **Epic**: BlockTypeDB
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Manifest Version**: 2026-04-24

## Context

**GDD**: `design/gdd/block-type-database.md`
**Requirement**: Performance targets
*(Single query <0.1ms, TileSet load <500ms, memory <2MB)*

**ADR Governing Implementation**: ADR-002: Database Loading Strategy
**ADR Decision Summary**: O(1) Dictionary lookup, startup load <100ms total for all 6 databases.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Dictionary lookup is O(1) in GDScript. ResourceLoader caches loaded resources.

**Control Manifest Rules (this layer)**:
- Required: O(1) lookup via Dictionary
- Performance: Database load <100ms startup
- Performance: Single query latency <0.1ms

---

## Acceptance Criteria

*From GDD `design/gdd/block-type-database.md`, Performance Criteria:*

- [ ] Single query latency <0.1ms (1000 calls averaged)
- [ ] TileSet resource load time <500ms on startup
- [ ] BlockTypeDB memory footprint <2MB (TileSet + cache)
- [ ] Dictionary cache built at startup (no runtime parsing)
- [ ] Query does not trigger ResourceLoader async operations

---

## Implementation Notes

*Derived from ADR-002:*

Performance optimization strategies:
1. **Dictionary Cache**: Build complete cache at startup, not per-query
2. **RefCounted**: Use RefCounted (not Node) for minimal overhead
3. **No async**: All queries return immediately, no await
4. **Lazy Loading**: TileSet loaded once, reused for all queries

```gdscript
# Performance test benchmark
func benchmark_query() -> float:
    var start_time = Time.get_ticks_usec()
    for i in 1000:
        get_tile_data(100)
    var end_time = Time.get_ticks_usec()
    return (end_time - start_time) / 1000.0  # microseconds per query
```

---

## Out of Scope

*Handled by neighbouring stories:*

- Story 001: TileSet loading
- Story 003: Query API logic

---

## QA Test Cases

*For Logic stories — automated test specs:*

- **AC-1**: Query latency benchmark
  - Given: BlockTypeDB initialized
  - When: 1000 sequential get_tile_data(100) calls
  - Then: average latency <100 microseconds (<0.1ms)
  - Edge cases: Test worst-case (cache miss), best-case (hot cache)

- **AC-2**: TileSet load time
  - Given: game startup timing
  - When: BlockTypeDB._init() completes
  - Then: elapsed time <500ms
  - Edge cases: Test large TileSet (>100 tiles)

- **AC-3**: Memory footprint
  - Given: BlockTypeDB loaded
  - When: memory measured via performance monitor
  - Then: BlockTypeDB singleton <2MB
  - Edge cases: Test memory after all 6 databases loaded

- **AC-4**: No async operations
  - Given: query called during gameplay
  - When: get_tile_data() executes
  - Then: returns immediately (no ResourceLoader.load in query path)
  - Edge cases: Verify no yield/await in query implementation

---

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/blocktype/performance_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: Story 001, Story 003
- Unlocks: None (standalone performance validation)