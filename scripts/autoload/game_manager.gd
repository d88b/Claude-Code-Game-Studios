extends Node

## 游戏管理器 — 全局游戏状态和阶段管理

enum GameState { MENU, LOADING, PLAYING, PAUSED }
enum GamePhase { NAVIGATION, EXPLORATION, DEFENSE, REWARD }

var current_state: GameState = GameState.MENU
var current_phase: GamePhase = GamePhase.NAVIGATION
var current_sea_area: int = 1

signal state_changed(new_state: GameState)
signal phase_changed(new_phase: GamePhase)
signal sea_area_changed(area: int)

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

func set_state(new_state: GameState):
	if current_state == new_state: return
	current_state = new_state
	state_changed.emit(new_state)

	if new_state == GameState.PAUSED:
		get_tree().paused = true
	elif new_state == GameState.PLAYING:
		get_tree().paused = false

func set_phase(new_phase: GamePhase):
	if current_phase == new_phase: return
	current_phase = new_phase
	phase_changed.emit(new_phase)
	print("[GameManager] 阶段切换: %s" % GamePhase.keys()[new_phase])

func next_sea_area():
	current_sea_area += 1
	sea_area_changed.emit(current_sea_area)
	print("[GameManager] 进入海域: %d" % current_sea_area)

func reset_game():
	current_sea_area = 1
	current_phase = GamePhase.NAVIGATION
