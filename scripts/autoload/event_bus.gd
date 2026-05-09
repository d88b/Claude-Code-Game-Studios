extends Node

signal play_cast_ability(ability: Ability)
signal player_health_changed(current_health: float, max_health: float)
signal player_energy_changed(current_energy: float, max_energy: float)

signal game_paused(paused: bool)
signal scene_changed(scene: String)

## 船体信号
signal ship_speed_changed(current_speed: float, min_speed: float, max_speed: float)
signal ship_destroyed
signal turret_fired(turret: Turret)
signal target_locked(target: Enemy)

## 潜艇信号
signal submarine_dive_started()
signal submarine_depth_changed(current_depth: float, max_depth: float)
signal submarine_returned_to_surface()
signal player_in_submarine(is_inside: bool)

## 波次信号
signal wave_started(wave_number: int, enemy_count: int)
signal wave_warning(wave_number: int, countdown: float)
signal wave_completed(wave_number: int, reward_text: String)
signal wave_state_changed(state: String)
