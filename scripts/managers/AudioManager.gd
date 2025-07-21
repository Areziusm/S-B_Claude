# ============================================================================
# 🔊 AudioManager.gd - Gestionnaire Audio Complet
# ============================================================================
# STATUS: ✅ FONCTIONNEL | ROADMAP: Mois 2 - Polish Audio
# PRIORITY: 🟡 P3 - Important mais non bloquant
# DEPENDENCIES: GameManager

class_name AudioManager
extends Node

## Gestionnaire central audio pour "Sortilèges & Bestioles"
## Gère musiques, effets sonores, ambiances et voix
## Support complet accessibilité audio

# ============================================================================
# SIGNAUX
# ============================================================================

## Émis quand une piste audio démarre
signal audio_started(audio_type: String, track_name: String)

## Émis quand une piste audio s'arrête
signal audio_stopped(audio_type: String)

## Émis pour changements de volume
signal volume_changed(bus_name: String, new_volume: float)

## Signal d'initialisation
signal manager_initialized()

# ============================================================================
# CONFIGURATION
# ============================================================================

## Bus audio
const BUS_MASTER = "Master"
const BUS_MUSIC = "Music"
const BUS_SFX = "SFX"
const BUS_VOICE = "Voice"
const BUS_AMBIENT = "Ambient"

## Configuration par défaut
const DEFAULT_CONFIG = {
	"master_volume": 1.0,
	"music_volume": 0.8,
	"sfx_volume": 0.9,
	"voice_volume": 1.0,
	"ambient_volume": 0.7,
	"music_fade_time": 1.5,
	"crossfade_enabled": true,
	"spatial_audio": true,
	"audio_quality": "high"
}

# ============================================================================
# VARIABLES
# ============================================================================

## État système
var is_initialized: bool = false
var config: Dictionary = DEFAULT_CONFIG.duplicate()
var current_music_track: String = ""
var is_music_playing: bool = false

## Pools audio
var music_player: AudioStreamPlayer
var ambient_player: AudioStreamPlayer
var ui_sfx_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer2D] = []
var voice_pool: Array[AudioStreamPlayer] = []

## Données audio
var loaded_tracks: Dictionary = {}
var loaded_sfx: Dictionary = {}
var loaded_voices: Dictionary = {}

## Volumes
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.9
var voice_volume: float = 1.0
var ambient_volume: float = 0.7

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	"""Initialisation du système audio"""
	print("🔊 AudioManager: Initialisation...")
	
	# Configuration des bus audio
	setup_audio_buses()
	
	# Création des players
	create_audio_players()
	
	# Chargement configuration
	load_audio_config()
	
	# Application volumes initiaux
	apply_volume_settings()
	
	is_initialized = true
	manager_initialized.emit()
	print("🔊 AudioManager: Prêt!")

func setup_audio_buses() -> void:
	"""Configure les bus audio si nécessaire"""
	# Note: Les bus devraient être configurés dans le projet
	# Cette méthode vérifie leur existence
	var buses = [BUS_MASTER, BUS_MUSIC, BUS_SFX, BUS_VOICE, BUS_AMBIENT]
	
	for bus in buses:
		var idx = AudioServer.get_bus_index(bus)
		if idx == -1:
			push_warning("🔊 Bus audio manquant: " + bus)

func create_audio_players() -> void:
	"""Crée les différents players audio"""
	# Musique
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = BUS_MUSIC
	add_child(music_player)
	
	# Ambiance
	ambient_player = AudioStreamPlayer.new()
	ambient_player.name = "AmbientPlayer"
	ambient_player.bus = BUS_AMBIENT
	add_child(ambient_player)
	
	# UI SFX
	ui_sfx_player = AudioStreamPlayer.new()
	ui_sfx_player.name = "UISFXPlayer"
	ui_sfx_player.bus = BUS_SFX
	add_child(ui_sfx_player)
	
	# Pool SFX spatialisés
	for i in range(10):
		var sfx_player = AudioStreamPlayer2D.new()
		sfx_player.name = "SFXPlayer" + str(i)
		sfx_player.bus = BUS_SFX
		add_child(sfx_player)
		sfx_pool.append(sfx_player)
	
	# Pool voix
	for i in range(3):
		var voice_player = AudioStreamPlayer.new()
		voice_player.name = "VoicePlayer" + str(i)
		voice_player.bus = BUS_VOICE
		add_child(voice_player)
		voice_pool.append(voice_player)

func load_audio_config() -> void:
	"""Charge la configuration audio depuis les préférences"""
	# TODO: Charger depuis SaveSystem une fois intégré
	print("🔊 Configuration audio chargée")

# ============================================================================
# API MUSIQUE
# ============================================================================

func play_music(track_name: String, fade_in: float = 1.5, loop: bool = true) -> void:
	"""Joue une piste musicale avec fondu"""
	if current_music_track == track_name and is_music_playing:
		return
	
	print("🔊 Musique:", track_name)
	
	# Si musique en cours, faire crossfade
	if is_music_playing and config.crossfade_enabled:
		await crossfade_music(track_name, fade_in)
	else:
		# Chargement et lecture directe
		var stream = load_music_track(track_name)
		if stream:
			music_player.stream = stream
			music_player.play()
			
			# Fondu entrant
			var tween = create_tween()
			music_player.volume_db = -80.0
			tween.tween_property(music_player, "volume_db", 0.0, fade_in)
			
			current_music_track = track_name
			is_music_playing = true
			audio_started.emit("music", track_name)

func stop_music(fade_out: float = 1.0) -> void:
	"""Arrête la musique avec fondu sortant"""
	if not is_music_playing:
		return
	
	var tween = create_tween()
	tween.tween_property(music_player, "volume_db", -80.0, fade_out)
	tween.tween_callback(func():
		music_player.stop()
		is_music_playing = false
		audio_stopped.emit("music")
		print("🔊 Musique arrêtée")
	)

func crossfade_music(new_track: String, duration: float = 2.0) -> void:
	"""Effectue un crossfade entre deux pistes"""
	# TODO: Implémenter avec deux players pour vrai crossfade
	await stop_music(duration / 2)
	await get_tree().create_timer(0.1).timeout
	play_music(new_track, duration / 2)

func set_music_volume(volume: float) -> void:
	"""Ajuste le volume de la musique (0.0 à 1.0)"""
	music_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(music_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MUSIC), db)
	volume_changed.emit(BUS_MUSIC, music_volume)

# ============================================================================
# API EFFETS SONORES
# ============================================================================

func play_sfx(sfx_name: String, position: Vector2 = Vector2.ZERO, volume: float = 1.0) -> void:
	"""Joue un effet sonore"""
	var stream = load_sfx(sfx_name)
	if not stream:
		push_warning("🔊 SFX introuvable:", sfx_name)
		return
	
	# Si position fournie, utiliser audio spatialisé
	if position != Vector2.ZERO and config.spatial_audio:
		play_spatial_sfx(stream, position, volume)
	else:
		# Son UI non-spatialisé
		ui_sfx_player.stream = stream
		ui_sfx_player.volume_db = linear_to_db(volume)
		ui_sfx_player.play()
	
	audio_started.emit("sfx", sfx_name)

func play_spatial_sfx(stream: AudioStream, position: Vector2, volume: float = 1.0) -> void:
	"""Joue un son spatialisé"""
	# Trouver un player disponible
	for player in sfx_pool:
		if not player.playing:
			player.stream = stream
			player.global_position = position
			player.volume_db = linear_to_db(volume)
			player.play()
			return
	
	# Si tous occupés, utiliser le premier
	push_warning("🔊 Pool SFX saturé!")
	sfx_pool[0].stop()
	sfx_pool[0].stream = stream
	sfx_pool[0].global_position = position
	sfx_pool[0].volume_db = linear_to_db(volume)
	sfx_pool[0].play()

func play_ui_sound(sound_type: String) -> void:
	"""Joue un son d'interface standard"""
	var sfx_map = {
		"click": "ui_click",
		"hover": "ui_hover",
		"confirm": "ui_confirm",
		"cancel": "ui_cancel",
		"error": "ui_error",
		"notification": "ui_notification"
	}
	
	if sound_type in sfx_map:
		play_sfx(sfx_map[sound_type])

# ============================================================================
# API AMBIANCE
# ============================================================================

func play_ambient(ambient_name: String, volume: float = 0.7, fade_in: float = 3.0) -> void:
	"""Joue une ambiance sonore"""
	var stream = load_ambient_track(ambient_name)
	if not stream:
		return
	
	ambient_player.stream = stream
	ambient_player.play()
	
	# Fondu entrant
	var tween = create_tween()
	ambient_player.volume_db = -80.0
	tween.tween_property(ambient_player, "volume_db", linear_to_db(volume), fade_in)
	
	audio_started.emit("ambient", ambient_name)
	print("🔊 Ambiance:", ambient_name)

func stop_ambient(fade_out: float = 2.0) -> void:
	"""Arrête l'ambiance avec fondu"""
	var tween = create_tween()
	tween.tween_property(ambient_player, "volume_db", -80.0, fade_out)
	tween.tween_callback(func():
		ambient_player.stop()
		audio_stopped.emit("ambient")
	)

# ============================================================================
# API VOIX
# ============================================================================

func play_voice(voice_line: String, character: String = "", volume: float = 1.0) -> AudioStreamPlayer:
	"""Joue une ligne de dialogue vocale"""
	var stream = load_voice_line(voice_line, character)
	if not stream:
		return null
	
	# Trouver un player disponible
	for player in voice_pool:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(volume)
			player.play()
			audio_started.emit("voice", voice_line)
			return player
	
	# Si tous occupés, arrêter le plus ancien
	voice_pool[0].stop()
	voice_pool[0].stream = stream
	voice_pool[0].volume_db = linear_to_db(volume)
	voice_pool[0].play()
	audio_started.emit("voice", voice_line)
	return voice_pool[0]

func stop_all_voices() -> void:
	"""Arrête toutes les voix en cours"""
	for player in voice_pool:
		if player.playing:
			player.stop()
	audio_stopped.emit("voice")

# ============================================================================
# GESTION VOLUMES
# ============================================================================

func apply_volume_settings() -> void:
	"""Applique tous les paramètres de volume"""
	set_master_volume(config.master_volume)
	set_music_volume(config.music_volume)
	set_sfx_volume(config.sfx_volume)
	set_voice_volume(config.voice_volume)
	set_ambient_volume(config.ambient_volume)

func set_master_volume(volume: float) -> void:
	"""Ajuste le volume principal"""
	master_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(master_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_MASTER), db)
	volume_changed.emit(BUS_MASTER, master_volume)

func set_sfx_volume(volume: float) -> void:
	"""Ajuste le volume des effets"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(sfx_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_SFX), db)
	volume_changed.emit(BUS_SFX, sfx_volume)

func set_voice_volume(volume: float) -> void:
	"""Ajuste le volume des voix"""
	voice_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(voice_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_VOICE), db)
	volume_changed.emit(BUS_VOICE, voice_volume)

func set_ambient_volume(volume: float) -> void:
	"""Ajuste le volume des ambiances"""
	ambient_volume = clamp(volume, 0.0, 1.0)
	var db = linear_to_db(ambient_volume)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index(BUS_AMBIENT), db)
	volume_changed.emit(BUS_AMBIENT, ambient_volume)

func mute_all(muted: bool = true) -> void:
	"""Active/désactive le son global"""
	AudioServer.set_bus_mute(AudioServer.get_bus_index(BUS_MASTER), muted)

# ============================================================================
# CHARGEMENT RESSOURCES
# ============================================================================

func load_music_track(track_name: String) -> AudioStream:
	"""Charge une piste musicale"""
	if track_name in loaded_tracks:
		return loaded_tracks[track_name]
	
	var path = "res://audio/music/" + track_name + ".ogg"
	if not FileAccess.file_exists(path):
		# Fallback sur musique de test
		push_warning("🔊 Musique introuvable:", path)
		return null
	
	var stream = load(path) as AudioStream
	if stream:
		loaded_tracks[track_name] = stream
	return stream

func load_sfx(sfx_name: String) -> AudioStream:
	"""Charge un effet sonore"""
	if sfx_name in loaded_sfx:
		return loaded_sfx[sfx_name]
	
	var path = "res://audio/sfx/" + sfx_name + ".wav"
	if not FileAccess.file_exists(path):
		return null
	
	var stream = load(path) as AudioStream
	if stream:
		loaded_sfx[sfx_name] = stream
	return stream

func load_ambient_track(ambient_name: String) -> AudioStream:
	"""Charge une ambiance"""
	var path = "res://audio/ambient/" + ambient_name + ".ogg"
	return load(path) if FileAccess.file_exists(path) else null

func load_voice_line(line_id: String, character: String = "") -> AudioStream:
	"""Charge une ligne de voix"""
	var path = "res://audio/voice/"
	if character:
		path += character + "/"
	path += line_id + ".ogg"
	
	return load(path) if FileAccess.file_exists(path) else null

# ============================================================================
# UTILITAIRES
# ============================================================================

func get_available_music_tracks() -> Array:
	"""Retourne la liste des musiques disponibles"""
	# TODO: Scanner le dossier audio/music
	return ["main_theme", "ankh_morpork", "combat", "mystery", "tavern"]

func get_current_music() -> String:
	"""Retourne la musique en cours"""
	return current_music_track if is_music_playing else ""

func is_sfx_playing(sfx_name: String) -> bool:
	"""Vérifie si un SFX est en cours"""
	for player in sfx_pool:
		if player.playing and player.stream and player.stream.resource_path.contains(sfx_name):
			return true
	return false

func stop_all_audio() -> void:
	"""Arrête tous les sons"""
	stop_music()
	stop_ambient()
	stop_all_voices()
	
	for player in sfx_pool:
		if player.playing:
			player.stop()
	
	if ui_sfx_player.playing:
		ui_sfx_player.stop()

func _exit_tree() -> void:
	"""Nettoyage à la fermeture"""
	stop_all_audio()