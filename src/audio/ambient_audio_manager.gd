extends Node
# AmbientAudioManager — 环境音效管理器 (Autoload)
## AmbientAudioManager — 环境音效管理器
## 管理 DayNight 阶段的环境音效播放
## Feature layer system (Sprint 4 audio-001)

# === 常量定义 ===
## 四个日夜阶段对应的音效配置
const PHASE_AUDIO_CONFIG: Dictionary = {
	0: {  # DAWN
		"ambient": "res://assets/audio/ambient/dawn_wind.wav",
		"volume": -10.0,
		"loop": true
	},
	1: {  # DAY
		"ambient": "res://assets/audio/ambient/day_breeze.wav",
		"volume": -12.0,
		"loop": true
	},
	2: {  # DUSK
		"ambient": "res://assets/audio/ambient/dusk_calm.wav",
		"volume": -8.0,
		"loop": true
	},
	3: {  # NIGHT
		"ambient": "res://assets/audio/ambient/night_wind.wav",
		"volume": -15.0,
		"loop": true
	}
}

# === 状态变量 ===
## 当前阶段 (DAWN=0, DAY=1, DUSK=2, NIGHT=3)
var current_phase: int = 1  # 默认 DAY
## 当前环境音效播放器
var _ambient_player: AudioStreamPlayer = null
## 是否已初始化
var is_initialized: bool = false

# === 依赖引用 ===
var _global_signals: Node = null

# === 初始化 ===

func _ready() -> void:
	_global_signals = get_node_or_null("/root/GlobalSignals")

	# 创建环境音效播放器
	_ambient_player = AudioStreamPlayer.new()
	_ambient_player.bus = "Ambient"
	add_child(_ambient_player)

	# 连接阶段变化信号
	if _global_signals != null:
		_global_signals.day_phase_changed.connect(_on_phase_changed)

	# 初始化为当前阶段音效
	_play_phase_ambient(current_phase)

	is_initialized = true
	print("[AmbientAudioManager] Initialized — phase=%d" % current_phase)

func _exit_tree() -> void:
	# 断开信号连接
	if _global_signals != null:
		if _global_signals.day_phase_changed.is_connected(_on_phase_changed):
			_global_signals.day_phase_changed.disconnect(_on_phase_changed)

	# 停止音效
	if _ambient_player != null:
		_ambient_player.stop()

# === 信号回调 ===

func _on_phase_changed(phase: int) -> void:
	if phase == current_phase:
		return

	current_phase = phase
	_play_phase_ambient(phase)

	print("[AmbientAudioManager] Phase changed — new_phase=%d" % phase)

# === 音效播放 ===

func _play_phase_ambient(phase: int) -> void:
	if _ambient_player == null:
		return

	# 检查配置是否有效
	if not PHASE_AUDIO_CONFIG.has(phase):
		push_warning("[AmbientAudioManager] No audio config for phase=%d" % phase)
		return

	var config: Dictionary = PHASE_AUDIO_CONFIG[phase]
	var audio_path: String = config.get("ambient", "")

	# TODO: 加载实际音效资源 — sound-designer 提供
	# 当前使用占位逻辑，等待资源
	if not ResourceLoader.exists(audio_path):
		# 音效资源未就绪，静默播放（无音效）
		_ambient_player.stop()
		print("[AmbientAudioManager] Audio asset pending: %s" % audio_path)
		return

	# 加载并播放音效
	var audio_stream: AudioStream = load(audio_path)
	if audio_stream == null:
		return

	_ambient_player.stream = audio_stream
	_ambient_player.volume_db = config.get("volume", -10.0)
	_ambient_player.loop = config.get("loop", true)
	_ambient_player.play()

# === 公共 API ===

## 设置音效音量
func set_ambient_volume(volume_db: float) -> void:
	if _ambient_player != null:
		_ambient_player.volume_db = volume_db

## 暂停环境音效
func pause_ambient() -> void:
	if _ambient_player != null and _ambient_player.playing:
		_ambient_player.stream_paused = true

## 继续播放环境音效
func resume_ambient() -> void:
	if _ambient_player != null and _ambient_player.stream_paused:
		_ambient_player.stream_paused = false

## 获取当前阶段
func get_current_phase() -> int:
	return current_phase