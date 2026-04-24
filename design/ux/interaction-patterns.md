# Interaction Pattern Library

> **Status**: Initialized
> **Last Updated**: 2026-04-24
> **Purpose**: Document reusable UI/UX patterns used across the game

---

## Core Gameplay Patterns

### Movement Input

**Pattern**: Continuous directional input
**Inputs**: WASD (keyboard), Left Stick (gamepad)
**Feedback**: Vehicle velocity and orientation change
**Accessibility**: Remappable, adjustable sensitivity

---

### Action Input

**Pattern**: Context-sensitive action button
**Inputs**: F (dig), G (place), Space (fire)
**Feedback**: Visual indicator at target position, audio cue on completion
**Accessibility**: Remappable, hold duration adjustable

---

### Mouse Interaction

**Pattern**: Point-and-click targeting
**Inputs**: Mouse position + Left Click (confirm), Right Click (alternate)
**Feedback**: Highlight on hoverable elements, cursor change
**Accessibility**: Click target minimum 44x44px

---

## UI Navigation Patterns

### Menu Navigation

**Pattern**: Tab/Arrow key navigation with focus indicator
**Inputs**: Tab (next), Shift+Tab (previous), Arrow keys (directional)
**Feedback**: Highlight border on focused element, audio cue on focus change
**Accessibility**: Focus indicator minimum 2px border, high contrast mode support

---

### Selection Confirmation

**Pattern**: Enter/Space to confirm, Escape to cancel
**Inputs**: Enter (confirm), Space (confirm), Escape (cancel/back)
**Feedback**: Button press animation, audio cue
**Accessibility**: Hold duration adjustable for Enter/Space

---

## HUD Patterns

### Resource Display

**Pattern**: Icon + numeric count display
**Elements**: Resource icon, current count, max capacity
**Feedback**: Flash on change, audio cue on pickup/consume
**Accessibility**: Colorblind mode uses shape differentiation, scalable icons

---

### Health/Magic Bars

**Pattern**: Horizontal progress bar
**Elements**: Current value, max value, critical threshold indicator
**Feedback**: Color change at thresholds (green → yellow → red), audio warning
**Accessibility**: Numeric display option, colorblind-safe palette

---

### Warning Indicators

**Pattern**: Pulsing overlay with text
**Elements**: Warning icon, reason text, countdown timer
**Feedback**: Audio alert, visual pulse effect
**Accessibility**: Extended duration option, text scale adjustable

---

## Inventory Patterns

### Grid Inventory

**Pattern**: Grid-based slot display
**Inputs**: Click to select, drag to reorder, double-click to quick-use
**Feedback**: Selection highlight, drag shadow, slot glow on valid placement
**Accessibility**: Minimum slot size 44x44px, keyboard navigation support

---

### Quick Stack

**Pattern**: Auto-sort to storage
**Inputs**: Single button press (quick_stack action)
**Feedback**: Visual transfer animation, audio cue
**Accessibility**: Optional manual confirmation for each item

---

## Facility Interaction Patterns

### Storage Box

**Pattern**: Open inventory panel
**Inputs**: Approach + interact button (E or F)
**Feedback**: Panel opens, cursor locked to panel, background dimmed
**Accessibility**: Panel scale adjustable, keyboard navigation within panel

---

### Workbench Crafting

**Pattern**: Recipe selection + confirm
**Inputs**: Recipe list navigation (arrows), confirm (Enter)
**Feedback**: Recipe ingredients display, craft progress bar, completion audio
**Accessibility**: Recipe list keyboard navigable, progress bar with text percentage

---

## Retreat/Warning Patterns

### Retreat Warning UI

**Pattern**: Full-screen overlay warning
**Elements**: Reason icon, countdown timer, action buttons (continue/retreat)
**Inputs**: Button navigation (Tab), confirm (Enter), dismiss (Escape)
**Feedback**: Audio alert on trigger, visual countdown
**Accessibility**: Extended duration, button scale adjustable, screen reader support

---

## Pattern Usage Tracking

| Pattern | Screens Used | Accessibility Level |
|---------|--------------|---------------------|
| Movement Input | Core gameplay | Basic (remappable) |
| Action Input | Core gameplay | Basic (remappable) |
| Menu Navigation | All menus | Standard (focus + audio) |
| Resource Display | HUD | Standard (colorblind-safe) |
| Health/Magic Bars | HUD | Standard (numeric option) |
| Warning Indicators | Retreat UI | Standard (extended duration) |
| Grid Inventory | Storage | Standard (keyboard nav) |
| Storage Box | Facility | Standard (panel scale) |
| Workbench Crafting | Facility | Standard (keyboard nav) |
| Retreat Warning UI | Exploration | Standard (screen reader) |

---

## Future Patterns (Vertical Slice+)

- **Pause Menu**: Full-screen overlay with navigation
- **Map Screen**: Scrollable area with markers
- **Settings Screen**: Category navigation + option toggles
- **Dialogue System**: Text display + response selection

---

## Animation Standards

| Animation Type | Duration | Easing | Use Case |
|----------------|----------|--------|----------|
| Button Hover | 150ms | ease-out | Menu button focus |
| Button Press | 100ms | ease-in | Click/confirm feedback |
| Panel Slide-in | 300ms | ease-out | Modal/overlay entry |
| Panel Fade-out | 200ms | ease-in | Modal/overlay exit |
| Warning Pulse | 500ms (cycle) | linear loop | Retreat warning |
| Bar Fill/Empty | 200ms | ease-out | Health/Magic change |
| Toast Notification | 300ms in, 2s hold, 200ms out | ease-out | Item pickup text |

---

## Sound Standards

| Sound Type | Volume | Duration | Use Case |
|------------|--------|----------|----------|
| Button Focus | 30% | 50ms | Menu navigation |
| Button Confirm | 50% | 100ms | Click/confirm |
| Panel Open | 40% | 150ms | Modal/overlay entry |
| Panel Close | 30% | 100ms | Modal/overlay exit |
| Warning Alert | 70% | 500ms (loop) | Retreat threshold |
| Pickup | 50% | 150ms | Resource collected |
| Damage | 60% | 200ms | Vehicle hit |
| Phase Change | 40% | 300ms | Day/Night transition |

---

## Validation

- [x] Core gameplay patterns documented
- [x] UI navigation patterns documented
- [x] HUD patterns documented
- [x] Facility patterns documented
- [x] Accessibility level noted per pattern