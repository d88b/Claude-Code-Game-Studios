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
