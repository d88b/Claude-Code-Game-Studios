# Accessibility Requirements

> **Status**: Approved
> **Last Updated**: 2026-04-24
> **Tier**: Standard

---

## Accessibility Tier Commitment

This project commits to **Standard** accessibility tier, providing:

- **Basic tier features**: Input remapping, subtitles/closed captions
- **Standard tier additions**: Colorblind modes, scalable UI elements
- **Motor accessibility**: Adjustable input timing where applicable

---

## Input Accessibility

### Remapping Support

- **Requirement**: All gameplay inputs must be remappable
- **Implementation**: Godot Input Map system allows key rebinding
- **Default Mappings**: WASD + Mouse, Gamepad A/B/X/Y
- **Remappable Actions**: move_up/down/left/right, fire, dig, place, menu_toggle, pause

### Input Timing

- **Hold Duration**: Adjustable for hold-to-activate actions (default 0.5s)
- **Double-Tap Window**: Configurable for double-tap actions (default 0.3s)

---

## Visual Accessibility

### Colorblind Modes

- **Deuteranopia (Green-weak)**: Alternative color palette for resource indicators
- **Protanopia (Red-weak)**: Shape-based differentiation alongside color
- **Tritanopia (Blue-weak)**: High contrast outlines for important elements

### UI Scaling

- **Text Scale**: 0.8x to 1.5x adjustable
- **HUD Scale**: 0.8x to 1.3x adjustable
- **Minimum Click Target**: 44x44 pixels (WCAG 2.1 AA)

### Contrast

- **Minimum Contrast Ratio**: 4.5:1 for text (WCAG 2.1 AA)
- **High Contrast Mode**: Optional black/white outlines on interactive elements

---

## Audio Accessibility

### Subtitles

- **Requirement**: All audio cues have visual equivalents
- **Implementation**: Text popups for sound events (dig complete, item pickup)
- **Subtitle Size**: Adjustable, minimum 24px equivalent

### Sound Cues

- **Visual Sound Indicators**: On-screen icons for key audio events
- **Directional Indicators**: Arrow showing sound source direction

---

## Motor Accessibility

### Timing Adjustments

- **Crafting Timer**: Pause option during crafting (not MVP)
- **Retreat Warning**: Extended warning duration option (default 2 min, adjustable to 5 min)

### One-Handed Mode

- **Not Supported MVP**: Full one-handed play requires additional input mapping work
- **Partial Support**: Gamepad allows single-stick movement with auto-targeting

---

## Cognitive Accessibility

### Tutorial

- **Requirement**: Interactive tutorial for core mechanics (driving, digging, placing)
- **Implementation**: Guided first-play sequence with visual prompts

### Difficulty Options

- **Enemy Speed**: Adjustable (0.7x to 1.3x)
- **Magic Consumption**: Adjustable (0.7x to 1.3x)
- **Not MVP**: Full difficulty presets deferred to Vertical Slice

---

## Platform-Specific Notes

### PC (Steam/Epic)

- **Steam Accessibility Features**: Steam overlay provides additional accessibility tools
- **Epic Accessibility**: Platform accessibility APIs available

### Console (Future)

- **Full motor accessibility required**: One-handed mode, timing adjustments
- **Platform certification**: Must meet platform accessibility guidelines

---

## Implementation Priority

| Feature | Tier | MVP | Vertical Slice | Alpha |
|---------|------|-----|----------------|-------|
| Input remapping | Basic | ✓ | — | — |
| Subtitles | Basic | ✓ | — | — |
| Colorblind modes | Standard | ✓ | — | — |
| UI scaling | Standard | ✓ | — | — |
| Timing adjustments | Motor | — | ✓ | — |
| One-handed mode | Motor | — | — | ✓ |
| Full difficulty presets | Cognitive | — | ✓ | — |

---

## Validation

- [x] Accessibility tier committed (Standard)
- [x] Input remapping planned
- [x] Colorblind modes planned
- [x] UI scaling planned
- [x] Subtitles planned