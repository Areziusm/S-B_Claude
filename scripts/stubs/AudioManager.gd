# ============================================================================
# 🔊 AudioManager.gd - Gestionnaire Audio (STUB TEMPORAIRE)
# ============================================================================

class_name AudioManager
extends Node

signal audio_started(audio_type: String, track_name: String)
signal audio_stopped(audio_type: String)
signal manager_initialized()

var is_initialized: bool = false
var master_volume: float = 1.0
var music_volume: float = 0.8

func _ready() -> void:
	print("🔊 AudioManager: Stub temporaire initialisé")
	is_initialized = true
	manager_initialized.emit()

func play_music(track_name: String, fade_time: float = 1.0) -> void:
	print("🔊 AudioManager: Musique ", track_name, " (stub)")
	audio_started.emit("music", track_name)

func play_sfx(sfx_name: String, position: Vector2 = Vector2.ZERO) -> void:
	print("🔊 AudioManager: SFX ", sfx_name, " (stub)")
	audio_started.emit("sfx", sfx_name)

func update_volume_settings(settings: Dictionary) -> void:
	print("🔊 AudioManager: Volumes mis à jour (stub)")
