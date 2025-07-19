# ============================================================================
# 🔊 AudioManager.gd - Gestionnaire Audio (STUB TEMPORAIRE)
# ============================================================================
# STATUS: 🟡 STUB | ROADMAP: Mois 1, Semaine 3-4 - Audio Architecture
# PRIORITY: 🟡 P3 - Audio et ambiance
# DEPENDENCIES: GameManager

class_name AudioManager
extends Node

## Gestionnaire temporaire de l'audio
## Version minimale pour éviter les erreurs de compilation

signal audio_started(audio_type: String, track_name: String)
signal audio_stopped(audio_type: String)
signal manager_initialized()

var is_initialized: bool = false
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var voice_volume: float = 1.0

func _ready() -> void:
	"""Initialisation basique de l'AudioManager"""
	print("🔊 AudioManager: Stub temporaire initialisé")
	is_initialized = true
	manager_initialized.emit()

func play_music(track_name: String, fade_time: float = 1.0) -> void:
	"""Joue une musique (stub)"""
	print("🔊 AudioManager: Musique ", track_name, " (stub)")
	audio_started.emit("music", track_name)

func play_sfx(sfx_name: String, position: Vector2 = Vector2.ZERO) -> void:
	"""Joue un effet sonore (stub)"""
	print("🔊 AudioManager: SFX ", sfx_name, " à ", position, " (stub)")
	audio_started.emit("sfx", sfx_name)

func update_volume_settings(settings: Dictionary) -> void:
	"""Met à jour les paramètres de volume (stub)"""
	print("🔊 AudioManager: Volumes mis à jour (stub)")
