# ============================================================================
# 🔊 AudioManager.gd - Gestionnaire Audio Adaptatif
# ============================================================================
# STATUS: ✅ PRODUCTION | VERSION: 1.0
# PRIORITY: 🟡 P3 - Audio immersif et accessibilité complète
# DEPENDENCIES: GameManager, QuestManager, UIManager

class_name AudioManager
extends Node

## Gestionnaire centralisé de l'audio adaptatif
## Musique réactive, ambiances dynamiques, accessibilité complète
## Optimisé pour l'univers Terry Pratchett et Ankh-Morpork

# ============================================================================
# SIGNAUX
# ============================================================================
signal audio_track_started(track_type: String, track_name: String)
signal audio_track_stopped(track_type: String, track_name: String)
signal audio_track_faded(track_type: String, track_name: String, target_volume: float)
signal audio_system_muted(muted: bool)
signal voice_line_started(speaker: String, line_id: String)
signal voice_line_completed(speaker: String, line_id: String)
signal ambience_changed(old_ambience: String, new_ambience: String)
signal audio_accessibility_changed(feature: String, enabled: bool)

# ============================================================================
# ENUMS & CONSTANTS
# ============================================================================
enum AudioType {
	MUSIC_MAIN,        ## Musique principale
	MUSIC_AMBIENT,     ## Musique d'ambiance
	MUSIC_EMOTIONAL,   ## Musique émotionnelle
	SFX_UI,           ## Sons d'interface
	SFX_WORLD,        ## Sons du monde
	SFX_MAGIC,        ## Effets magiques
	VOICE_NARRATION,  ## Voix narrateur
	VOICE_DIALOGUE,   ## Voix dialogues
	AMBIENCE_ZONE,    ## Ambiance de zone
	AMBIENCE_WEATHER  ## Ambiance météo
}

enum MusicMood {
	NEUTRAL,      ## Ambiance normale
	MYSTERIOUS,   ## Mystérieux/intriguant
	COMEDIC,      ## Drôle/léger
	DRAMATIC,     ## Dramatique/intense
	PHILOSOPHICAL,## Réflexif/contemplatif
	CHAOTIC,      ## Chaotique/désorganisé
	MAGICAL,      ## Merveilleux/enchanteur
	DARK          ## Sombre/inquiétant
}

enum AmbienceZone {
	DOLLY_SISTERS,    ## Quartier résidentiel
	SHADES,           ## Quartier malfamé
	UNSEEN_UNIVERSITY,## Université des Mages
	PATRICIAN_PALACE, ## Palais du Patricien
	MERCHANT_QUARTER, ## Quartier marchand
	DOCKS,            ## Port d'Ankh
	COMMONS,          ## Centre-ville
	OUTSKIRTS         ## Périphérie
}

# Configuration système
const MAX_SIMULTANEOUS_TRACKS = 8
const FADE_DURATION_DEFAULT = 2.0
const VOICE_QUEUE_MAX_SIZE = 10
const CACHE_SIZE_MB = 100

# ============================================================================
# VARIABLES PRINCIPALES
# ============================================================================
@export var master_volume: float = 1.0
@export var music_volume: float = 0.8
@export var sfx_volume: float = 0.8
@export var voice_volume: float = 1.0
@export var ambience_volume: float = 0.6

# Configuration adaptative
@export var adaptive_music_enabled: bool = true
@export var dynamic_range_compression: bool = false
@export var audio_3d_enabled: bool = true
@export var accessibility_mode: bool = false

# État audio actuel
var current_music_track: String = ""
var current_music_mood: MusicMood = MusicMood.NEUTRAL
var current_ambience_zone: AmbienceZone = AmbienceZone.DOLLY_SISTERS
var is_system_muted: bool = false

# Lecteurs audio
var music_player: AudioStreamPlayer
var ambience_player: AudioStreamPlayer
var voice_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var ui_player: AudioStreamPlayer

# Système adaptatif
var music_transition_timer: Timer
var emotion_tracker: Dictionary = {}
var context_analyzer: Dictionary = {}
var weather_audio_mixer: AudioEffectBus

# Queue et cache
var voice_queue: Array[Dictionary] = []
var audio_cache: Dictionary = {}
var streaming_tracks: Dictionary = {}

# Références managers
var game_manager: GameManager
var quest_manager: QuestManager
var ui_manager: UIManager

# Configuration accessibilité
var accessibility_config: Dictionary = {
	"visual_audio_indicators": false,
	"audio_descriptions": false,
	"simplified_audio": false,
	"haptic_feedback": false,
	"subtitle_mode": false
}

# ============================================================================
# INITIALISATION
# ============================================================================
func _ready() -> void:
	"""Initialisation complète du AudioManager"""
	print("🔊 AudioManager: Initialisation démarrée...")
	
	# Configuration base
	setup_audio_system()
	
	# Création lecteurs audio
	create_audio_players()
	
	# Configuration système adaptatif
	setup_adaptive_system()
	
	# Récupération références managers
	await get_tree().process_frame
	get_manager_references()
	
	# Connexion aux signaux
	connect_to_managers()
	
	# Chargement configuration
	load_audio_configuration()
	
	# Configuration accessibilité
	setup_accessibility_features()
	
	# Démarrage musique par défaut
	start_default_audio()
	
	print("🔊 AudioManager: Initialisé avec succès")

func setup_audio_system() -> void:
	"""Configure le système audio de base"""
	# Configuration bus audio
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	
	# Création bus spécialisés si nécessaire
	if AudioServer.get_bus_index("Music") == -1:
		AudioServer.add_bus(1)
		AudioServer.set_bus_name(1, "Music")
		AudioServer.set_bus_send(1, "Master")
	
	if AudioServer.get_bus_index("SFX") == -1:
		AudioServer.add_bus(2)
		AudioServer.set_bus_name(2, "SFX")
		AudioServer.set_bus_send(2, "Master")
	
	if AudioServer.get_bus_index("Voice") == -1:
		AudioServer.add_bus(3)
		AudioServer.set_bus_name(3, "Voice")
		AudioServer.set_bus_send(3, "Master")

func create_audio_players() -> void:
	"""Crée tous les lecteurs audio nécessaires"""
	# Lecteur musique principal
	music_player = AudioStreamPlayer.new()
	music_player.name = "MusicPlayer"
	music_player.bus = "Music"
	music_player.volume_db = linear_to_db(music_volume)
	add_child(music_player)
	
	# Lecteur ambiance
	ambience_player = AudioStreamPlayer.new()
	ambience_player.name = "AmbiencePlayer"
	ambience_player.bus = "Music"
	ambience_player.volume_db = linear_to_db(ambience_volume)
	ambience_player.stream_paused = false
	add_child(ambience_player)
	
	# Lecteur voix
	voice_player = AudioStreamPlayer.new()
	voice_player.name = "VoicePlayer"
	voice_player.bus = "Voice"
	voice_player.volume_db = linear_to_db(voice_volume)
	voice_player.finished.connect(_on_voice_finished)
	add_child(voice_player)
	
	# Lecteur UI
	ui_player = AudioStreamPlayer.new()
	ui_player.name = "UIPlayer"
	ui_player.bus = "SFX"
	ui_player.volume_db = linear_to_db(sfx_volume)
	add_child(ui_player)
	
	# Pool de lecteurs SFX
	for i in range(8):
		var sfx_player = AudioStreamPlayer.new()
		sfx_player.name = "SFXPlayer" + str(i)
		sfx_player.bus = "SFX"
		sfx_player.volume_db = linear_to_db(sfx_volume)
		sfx_players.append(sfx_player)
		add_child(sfx_player)

func setup_adaptive_system() -> void:
	"""Configure le système adaptatif"""
	# Timer pour transitions musicales
	music_transition_timer = Timer.new()
	music_transition_timer.timeout.connect(_on_music_transition_timeout)
	music_transition_timer.one_shot = true
	add_child(music_transition_timer)
	
	# Initialisation analyseurs
	emotion_tracker = {
		"current_emotion": "neutral",
		"intensity": 0.5,
		"duration": 0.0,
		"trend": "stable"
	}
	
	context_analyzer = {
		"location": "dolly_sisters",
		"time_of_day": "day",
		"weather": "clear",
		"activity": "exploration",
		"social_context": "alone"
	}

func get_manager_references() -> void:
	"""Récupère les références vers les autres managers"""
	game_manager = get_node_or_null("/root/GameManager")
	quest_manager = get_node_or_null("/root/QuestManager")
	ui_manager = get_node_or_null("/root/UIManager")

func connect_to_managers() -> void:
	"""Connexion aux signaux des autres managers"""
	# GameManager
	if game_manager:
		game_manager.scene_changed.connect(_on_scene_changed)
		game_manager.game_state_changed.connect(_on_game_state_changed)
	
	# QuestManager
	if quest_manager:
		quest_manager.quest_started.connect(_on_quest_started)
		quest_manager.quest_completed.connect(_on_quest_completed)
		quest_manager.main_story_progressed.connect(_on_story_progressed)
	
	# UIManager
	if ui_manager:
		ui_manager.screen_changed.connect(_on_ui_screen_changed)
		ui_manager.notification_shown.connect(_on_notification_shown)

func start_default_audio() -> void:
	"""Démarre l'audio par défaut"""
	# Musique d'ambiance Dolly Sisters
	change_ambience(AmbienceZone.DOLLY_SISTERS)
	
	# Musique de base si aucune n'est jouée
	if current_music_track.is_empty():
		play_adaptive_music("ankh_morpork_morning", MusicMood.NEUTRAL)

# ============================================================================
# GESTION MUSIQUE ADAPTATIVE
# ============================================================================
func play_adaptive_music(base_track: String, mood: MusicMood = MusicMood.NEUTRAL, fade_time: float = FADE_DURATION_DEFAULT) -> void:
	"""Joue une musique adaptée au contexte"""
	if not adaptive_music_enabled:
		play_music(base_track, fade_time)
		return
	
	# Sélection de la variation selon le mood et contexte
	var track_name = select_adaptive_track(base_track, mood)
	
	# Transition musicale
	if current_music_track != track_name:
		transition_music(track_name, fade_time)
	
	current_music_mood = mood
	update_emotion_tracker(mood)

func select_adaptive_track(base_track: String, mood: MusicMood) -> String:
	"""Sélectionne la variation musicale appropriée"""
	var mood_suffix = MusicMood.keys()[mood].to_lower()
	var context_modifiers = analyze_current_context()
	
	# Construction du nom de piste
	var track_variations = [
		base_track + "_" + mood_suffix,
		base_track + "_" + context_modifiers.time_of_day,
		base_track + "_" + mood_suffix + "_" + context_modifiers.weather,
		base_track  # Fallback de base
	]
	
	# Recherche de la meilleure variation disponible
	for variation in track_variations:
		if has_audio_track(variation):
			return variation
	
	return base_track

func transition_music(new_track: String, fade_time: float) -> void:
	"""Effectue une transition musicale fluide"""
	if music_player.playing:
		# Fade out de la musique actuelle
		fade_audio_player(music_player, 0.0, fade_time / 2.0)
		await get_tree().create_timer(fade_time / 2.0).timeout
	
	# Changement de piste
	var audio_stream = load_audio_track(new_track)
	if audio_stream:
		music_player.stream = audio_stream
		music_player.play()
		current_music_track = new_track
		
		# Fade in de la nouvelle musique
		music_player.volume_db = -80.0  # Commence très bas
		fade_audio_player(music_player, music_volume, fade_time / 2.0)
		
		audio_track_started.emit("music", new_track)

func analyze_current_context() -> Dictionary:
	"""Analyse le contexte actuel pour l'adaptation musicale"""
	var context = {
		"time_of_day": get_time_of_day(),
		"weather": get_current_weather(),
		"location": get_current_location(),
		"activity": get_current_activity(),
		"emotional_state": emotion_tracker.current_emotion
	}
	
	context_analyzer = context
	return context

func update_emotion_tracker(mood: MusicMood) -> void:
	"""Met à jour le suivi émotionnel"""
	var mood_name = MusicMood.keys()[mood].to_lower()
	
	if emotion_tracker.current_emotion != mood_name:
		emotion_tracker.current_emotion = mood_name
		emotion_tracker.duration = 0.0
		emotion_tracker.intensity = calculate_mood_intensity(mood)
	else:
		emotion_tracker.duration += get_process_delta_time()

func calculate_mood_intensity(mood: MusicMood) -> float:
	"""Calcule l'intensité d'un mood"""
	match mood:
		MusicMood.DRAMATIC:
			return 0.9
		MusicMood.CHAOTIC:
			return 0.8
		MusicMood.DARK:
			return 0.7
		MusicMood.MAGICAL:
			return 0.6
		MusicMood.MYSTERIOUS:
			return 0.5
		MusicMood.PHILOSOPHICAL:
			return 0.4
		MusicMood.COMEDIC:
			return 0.3
		MusicMood.NEUTRAL:
			return 0.2
		_:
			return 0.5

# ============================================================================
# GESTION AMBIANCES
# ============================================================================
func change_ambience(zone: AmbienceZone, fade_time: float = FADE_DURATION_DEFAULT) -> void:
	"""Change l'ambiance selon la zone"""
	if current_ambience_zone == zone:
		return
	
	var old_zone = AmbienceZone.keys()[current_ambience_zone]
	var new_zone = AmbienceZone.keys()[zone]
	
	# Sélection de l'ambiance appropriée
	var ambience_track = get_zone_ambience_track(zone)
	
	# Transition d'ambiance
	if ambience_player.playing:
		fade_audio_player(ambience_player, 0.0, fade_time / 2.0)
		await get_tree().create_timer(fade_time / 2.0).timeout
	
	# Nouvelle ambiance
	var audio_stream = load_audio_track(ambience_track)
	if audio_stream:
		ambience_player.stream = audio_stream
		ambience_player.play()
		
		# Configuration loop
		if audio_stream is AudioStreamOggVorbis:
			audio_stream.loop = true
		
		# Fade in
		ambience_player.volume_db = -80.0
		fade_audio_player(ambience_player, ambience_volume, fade_time / 2.0)
	
	current_ambience_zone = zone
	ambience_changed.emit(old_zone, new_zone)

func get_zone_ambience_track(zone: AmbienceZone) -> String:
	"""Retourne la piste d'ambiance pour une zone"""
	var base_name = AmbienceZone.keys()[zone].to_lower()
	var time_modifier = "_" + get_time_of_day()
	var weather_modifier = "_" + get_current_weather()
	
	# Recherche de la variation la plus spécifique
	var variations = [
		"ambience_" + base_name + time_modifier + weather_modifier,
		"ambience_" + base_name + time_modifier,
		"ambience_" + base_name,
		"ambience_default"
	]
	
	for variation in variations:
		if has_audio_track(variation):
			return variation
	
	return "ambience_default"

# ============================================================================
# GESTION VOIX ET DIALOGUES
# ============================================================================
func play_voice_line(speaker: String, line_id: String, text: String = "", interrupt_current: bool = false) -> void:
	"""Joue une ligne de voix"""
	var voice_data = {
		"speaker": speaker,
		"line_id": line_id,
		"text": text,
		"timestamp": Time.get_ticks_msec()
	}
	
	if interrupt_current and voice_player.playing:
		voice_player.stop()
		voice_queue.clear()
	
	if voice_player.playing:
		# Ajouter à la queue
		if voice_queue.size() < VOICE_QUEUE_MAX_SIZE:
			voice_queue.append(voice_data)
	else:
		# Jouer immédiatement
		play_voice_immediate(voice_data)

func play_voice_immediate(voice_data: Dictionary) -> void:
	"""Joue immédiatement une ligne de voix"""
	var voice_file = get_voice_file_path(voice_data.speaker, voice_data.line_id)
	var audio_stream = load_audio_track(voice_file)
	
	if audio_stream:
		voice_player.stream = audio_stream
		voice_player.play()
		
		voice_line_started.emit(voice_data.speaker, voice_data.line_id)
		
		# Sous-titres si activés
		if accessibility_config.subtitle_mode:
			show_subtitle(voice_data.text, audio_stream.get_length())

func _on_voice_finished() -> void:
	"""Appelé quand une ligne de voix se termine"""
	voice_line_completed.emit("", "")  # TODO: Tracker current voice
	
	# Jouer la prochaine ligne en queue
	if not voice_queue.is_empty():
		var next_voice = voice_queue.pop_front()
		play_voice_immediate(next_voice)

func get_voice_file_path(speaker: String, line_id: String) -> String:
	"""Retourne le chemin vers un fichier de voix"""
	return "res://audio/voice/" + speaker.to_lower() + "/" + line_id + ".ogg"

# ============================================================================
# GESTION EFFETS SONORES
# ============================================================================
func play_sfx(sfx_name: String, volume_modifier: float = 1.0, position: Vector2 = Vector2.ZERO) -> void:
	"""Joue un effet sonore"""
	var available_player = get_available_sfx_player()
	if not available_player:
		return
	
	var audio_stream = load_audio_track("sfx_" + sfx_name)
	if not audio_stream:
		return
	
	available_player.stream = audio_stream
	available_player.volume_db = linear_to_db(sfx_volume * volume_modifier)
	
	# Audio 3D si position fournie et activé
	if audio_3d_enabled and position != Vector2.ZERO:
		apply_3d_audio_effect(available_player, position)
	
	available_player.play()
	audio_track_started.emit("sfx", sfx_name)

func play_ui_sfx(sfx_name: String, volume_modifier: float = 1.0) -> void:
	"""Joue un effet sonore d'interface"""
	var audio_stream = load_audio_track("ui_" + sfx_name)
	if not audio_stream:
		return
	
	ui_player.stream = audio_stream
	ui_player.volume_db = linear_to_db(sfx_volume * volume_modifier)
	ui_player.play()

func play_magic_sfx(spell_name: String, intensity: float = 1.0, position: Vector2 = Vector2.ZERO) -> void:
	"""Joue un effet sonore magique avec traitement spécial"""
	var sfx_name = "magic_" + spell_name
	
	# Effets magiques ont des variations selon l'intensité
	if intensity > 0.8:
		sfx_name += "_powerful"
	elif intensity < 0.3:
		sfx_name += "_weak"
	
	play_sfx(sfx_name, intensity, position)
	
	# Effets visuels audio pour accessibilité
	if accessibility_config.visual_audio_indicators:
		show_visual_audio_indicator("magic", position)

func get_available_sfx_player() -> AudioStreamPlayer:
	"""Trouve un lecteur SFX disponible"""
	for player in sfx_players:
		if not player.playing:
			return player
	
	# Tous occupés, utilise le premier (interruption)
	return sfx_players[0] if not sfx_players.is_empty() else null

func apply_3d_audio_effect(player: AudioStreamPlayer, position: Vector2) -> void:
	"""Applique un effet audio 3D basique"""
	# TODO: Implémentation plus sophistiquée avec AudioStreamPlayer2D
	var camera_pos = get_viewport().get_camera_2d().global_position if get_viewport().get_camera_2d() else Vector2.ZERO
	var distance = camera_pos.distance_to(position)
	
	# Atténuation par distance
	var distance_factor = clamp(1.0 - (distance / 1000.0), 0.1, 1.0)
	player.volume_db = linear_to_db(sfx_volume * distance_factor)

# ============================================================================
# GESTION VOLUMES ET CONFIGURATION
# ============================================================================
func set_master_volume(volume: float) -> void:
	"""Définit le volume maître"""
	master_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(master_volume))
	save_audio_configuration()

func set_music_volume(volume: float) -> void:
	"""Définit le volume de la musique"""
	music_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(music_volume))
	
	if music_player:
		music_player.volume_db = linear_to_db(music_volume)
	if ambience_player:
		ambience_player.volume_db = linear_to_db(ambience_volume)
	
	save_audio_configuration()

func set_sfx_volume(volume: float) -> void:
	"""Définit le volume des effets sonores"""
	sfx_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(sfx_volume))
	
	for player in sfx_players:
		player.volume_db = linear_to_db(sfx_volume)
	if ui_player:
		ui_player.volume_db = linear_to_db(sfx_volume)
	
	save_audio_configuration()

func set_voice_volume(volume: float) -> void:
	"""Définit le volume des voix"""
	voice_volume = clamp(volume, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Voice"), linear_to_db(voice_volume))
	
	if voice_player:
		voice_player.volume_db = linear_to_db(voice_volume)
	
	save_audio_configuration()

func mute_all_audio(muted: bool) -> void:
	"""Active/désactive le son globalement"""
	is_system_muted = muted
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), muted)
	audio_system_muted.emit(muted)

# ============================================================================
# ACCESSIBILITÉ AUDIO
# ============================================================================
func setup_accessibility_features() -> void:
	"""Configure les fonctionnalités d'accessibilité"""
	if accessibility_mode:
		enable_audio_accessibility()

func enable_audio_accessibility() -> void:
	"""Active les fonctionnalités d'accessibilité audio"""
	accessibility_config.visual_audio_indicators = true
	accessibility_config.audio_descriptions = true
	accessibility_config.subtitle_mode = true
	
	# Compression dynamique pour malentendants
	dynamic_range_compression = true
	apply_dynamic_range_compression()

func toggle_subtitle_mode(enabled: bool) -> void:
	"""Active/désactive le mode sous-titres"""
	accessibility_config.subtitle_mode = enabled
	audio_accessibility_changed.emit("subtitles", enabled)

func toggle_visual_audio_indicators(enabled: bool) -> void:
	"""Active/désactive les indicateurs visuels audio"""
	accessibility_config.visual_audio_indicators = enabled
	audio_accessibility_changed.emit("visual_indicators", enabled)

func show_subtitle(text: String, duration: float) -> void:
	"""Affiche un sous-titre"""
	if ui_manager:
		ui_manager.call("show_subtitle", text, duration)

func show_visual_audio_indicator(audio_type: String, position: Vector2) -> void:
	"""Affiche un indicateur visuel pour l'audio"""
	if ui_manager:
		ui_manager.call("show_audio_indicator", audio_type, position)

func apply_dynamic_range_compression() -> void:
	"""Applique la compression dynamique"""
	# TODO: Ajouter effet de compression sur le bus Master
	pass

# ============================================================================
# ÉVÉNEMENTS MANAGERS
# ============================================================================
func _on_scene_changed(old_scene: String, new_scene: String) -> void:
	"""Gestion changement de scène"""
	var zone = map_scene_to_ambience_zone(new_scene)
	if zone != current_ambience_zone:
		change_ambience(zone)
	
	# Adaptation musicale selon la nouvelle zone
	adapt_music_to_scene(new_scene)

func _on_game_state_changed(old_state: int, new_state: int) -> void:
	"""Gestion changement d'état de jeu"""
	match new_state:
		0:  # MAIN_MENU
			play_adaptive_music("main_menu_theme", MusicMood.NEUTRAL)
		1:  # PLAYING
			play_adaptive_music("exploration_theme", MusicMood.NEUTRAL)
		2:  # DIALOGUE
			play_adaptive_music("dialogue_theme", MusicMood.MYSTERIOUS)
		3:  # COMBAT
			play_adaptive_music("combat_theme", MusicMood.DRAMATIC)
		4:  # PAUSED
			fade_all_audio(0.3, 1.0)

func _on_quest_started(quest_id: String, quest_data: Dictionary) -> void:
	"""Gestion début de quête"""
	var quest_type = quest_data.get("quest_type", 0)
	
	# Musique spéciale pour quêtes principales
	if quest_type == 0:  # MAIN_STORY
		play_adaptive_music("main_quest_theme", MusicMood.DRAMATIC)
	
	# SFX de notification
	play_ui_sfx("quest_started")

func _on_quest_completed(quest_id: String, completion_type: String, rewards: Dictionary) -> void:
	"""Gestion fin de quête"""
	# Musique de victoire
	match completion_type:
		"SUCCESS":
			play_sfx("quest_success")
		"ALTERNATIVE":
			play_sfx("quest_clever")
		"PHILOSOPHY":
			play_sfx("quest_wisdom")
		_:
			play_sfx("quest_completed")

func _on_story_progressed(chapter: String, milestone: String) -> void:
	"""Gestion progression histoire"""
	# Musique thématique par chapitre
	var chapter_music = get_chapter_music(chapter)
	if chapter_music:
		play_adaptive_music(chapter_music, MusicMood.DRAMATIC, 4.0)

func _on_ui_screen_changed(from_screen: String, to_screen: String) -> void:
	"""Gestion changement d'écran UI"""
	play_ui_sfx("screen_transition")

func _on_notification_shown(message: String, type: String) -> void:
	"""Gestion notifications UI"""
	match type:
		"SUCCESS":
			play_ui_sfx("notification_success")
		"WARNING":
			play_ui_sfx("notification_warning")
		"ERROR":
			play_ui_sfx("notification_error")
		"MAGICAL":
			play_magic_sfx("notification", 0.8)
		_:
			play_ui_sfx("notification_info")

# ============================================================================
# UTILITAIRES AUDIO
# ============================================================================
func fade_audio_player(player: AudioStreamPlayer, target_volume: float, duration: float) -> void:
	"""Fait un fade sur un lecteur audio"""
	var tween = create_tween()
	tween.tween_property(player, "volume_db", linear_to_db(target_volume), duration)
	await tween.finished

func fade_all_audio(target_volume: float, duration: float) -> void:
	"""Fait un fade sur tout l'audio"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	if music_player:
		tween.tween_property(music_player, "volume_db", linear_to_db(target_volume), duration)
	if ambience_player:
		tween.tween_property(ambience_player, "volume_db", linear_to_db(target_volume), duration)
	if voice_player:
		tween.tween_property(voice_player, "volume_db", linear_to_db(target_volume), duration)

func load_audio_track(track_name: String) -> AudioStream:
	"""Charge une piste audio avec cache"""
	if audio_cache.has(track_name):
		return audio_cache[track_name]
	
	var audio_paths = [
		"res://audio/music/" + track_name + ".ogg",
		"res://audio/sfx/" + track_name + ".ogg",
		"res://audio/voice/" + track_name + ".ogg",
		"res://audio/ambient/" + track_name + ".ogg"
	]
	
	for path in audio_paths:
		if ResourceLoader.exists(path):
			var stream = load(path) as AudioStream
			if stream:
				# Cache si taille raisonnable
				if should_cache_audio(stream):
					audio_cache[track_name] = stream
				return stream
	
	print("🔊 AudioManager: Piste audio non trouvée: ", track_name)
	return null

func has_audio_track(track_name: String) -> bool:
	"""Vérifie si une piste audio existe"""
	return load_audio_track(track_name) != null

func should_cache_audio(stream: AudioStream) -> bool:
	"""Détermine si un audio doit être mis en cache"""
	# TODO: Calculer taille réelle du stream
	return audio_cache.size() < 50  # Limite simple

# ============================================================================
# MAPPING ET CONTEXTE
# ============================================================================
func map_scene_to_ambience_zone(scene_name: String) -> AmbienceZone:
	"""Mappe une scène vers une zone d'ambiance"""
	match scene_name.to_lower():
		"apartment", "dolly_sisters", "corridor":
			return AmbienceZone.DOLLY_SISTERS
		"shades", "thieves_guild":
			return AmbienceZone.SHADES
		"unseen_university", "library":
			return AmbienceZone.UNSEEN_UNIVERSITY
		"patrician_palace", "palace":
			return AmbienceZone.PATRICIAN_PALACE
		"market", "merchants":
			return AmbienceZone.MERCHANT_QUARTER
		"docks", "port":
			return AmbienceZone.DOCKS
		"commons", "center":
			return AmbienceZone.COMMONS
		_:
			return AmbienceZone.DOLLY_SISTERS

func get_time_of_day() -> String:
	"""Retourne l'heure du jour actuelle"""
	if game_manager and game_manager.has_method("get_time_of_day"):
		return game_manager.get_time_of_day()
	return "day"

func get_current_weather() -> String:
	"""Retourne la météo actuelle"""
	if game_manager and game_manager.has_method("get_current_weather"):
		return game_manager.get_current_weather()
	return "clear"

func get_current_location() -> String:
	"""Retourne la localisation actuelle"""
	if game_manager:
		return game_manager.get("current_scene_name", "unknown")
	return "unknown"

func get_current_activity() -> String:
	"""Retourne l'activité actuelle"""
	if quest_manager:
		var active_quests = quest_manager.get_active_quests()
		if not active_quests.is_empty():
			return "questing"
	return "exploration"

func get_chapter_music(chapter: String) -> String:
	"""Retourne la musique thématique d'un chapitre"""
	match chapter:
		"PROLOGUE":
			return "prologue_theme"
		"ACT1_DISCOVERY":
			return "discovery_theme"
		"ACT1_MENTORSHIP":
			return "mentorship_theme"
		"ACT2_INVESTIGATION":
			return "investigation_theme"
		"ACT2_FACTIONS":
			return "politics_theme"
		"ACT3_REVELATION":
			return "revelation_theme"
		"ACT3_CHOICE":
			return "climax_theme"
		"EPILOGUE":
			return "resolution_theme"
		_:
			return "default_theme"

func adapt_music_to_scene(scene_name: String) -> void:
	"""Adapte la musique à une scène spécifique"""
	var scene_mood = get_scene_mood(scene_name)
	var base_track = get_scene_base_track(scene_name)
	
	if base_track:
		play_adaptive_music(base_track, scene_mood)

func get_scene_mood(scene_name: String) -> MusicMood:
	"""Retourne le mood musical pour une scène"""
	match scene_name.to_lower():
		"shades", "thieves_guild":
			return MusicMood.DARK
		"unseen_university":
			return MusicMood.MAGICAL
		"patrician_palace":
			return MusicMood.DRAMATIC
		"death_domain":
			return MusicMood.PHILOSOPHICAL
		_:
			return MusicMood.NEUTRAL

func get_scene_base_track(scene_name: String) -> String:
	"""Retourne la piste de base pour une scène"""
	match scene_name.to_lower():
		"apartment":
			return "home_theme"
		"unseen_university":
			return "magic_theme"
		"patrician_palace":
			return "authority_theme"
		"shades":
			return "danger_theme"
		_:
			return "exploration_theme"

# ============================================================================
# CONFIGURATION ET SAUVEGARDE
# ============================================================================
func load_audio_configuration() -> void:
	"""Charge la configuration audio"""
	var config_path = "user://audio_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()
		
		if parse_result == OK:
			var config = json.data
			master_volume = config.get("master_volume", 1.0)
			music_volume = config.get("music_volume", 0.8)
			sfx_volume = config.get("sfx_volume", 0.8)
			voice_volume = config.get("voice_volume", 1.0)
			ambience_volume = config.get("ambience_volume", 0.6)
			adaptive_music_enabled = config.get("adaptive_music", true)
			accessibility_config.merge(config.get("accessibility", {}))

func save_audio_configuration() -> void:
	"""Sauvegarde la configuration audio"""
	var config = {
		"master_volume": master_volume,
		"music_volume": music_volume,
		"sfx_volume": sfx_volume,
		"voice_volume": voice_volume,
		"ambience_volume": ambience_volume,
		"adaptive_music": adaptive_music_enabled,
		"accessibility": accessibility_config
	}
	
	var config_path = "user://audio_config.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(config))
	file.close()

# ============================================================================
# API PUBLIQUE
# ============================================================================
func play_music(track_name: String, fade_time: float = FADE_DURATION_DEFAULT) -> void:
	"""Interface publique pour jouer de la musique"""
	transition_music(track_name, fade_time)

func stop_music(fade_time: float = FADE_DURATION_DEFAULT) -> void:
	"""Arrête la musique avec fade"""
	if music_player.playing:
		fade_audio_player(music_player, 0.0, fade_time)
		await get_tree().create_timer(fade_time).timeout
		music_player.stop()
		current_music_track = ""

func get_current_track() -> String:
	"""Retourne la piste musicale actuelle"""
	return current_music_track

func get_current_mood() -> MusicMood:
	"""Retourne le mood musical actuel"""
	return current_music_mood

func is_voice_playing() -> bool:
	"""Vérifie si une voix est en cours de lecture"""
	return voice_player.playing

func clear_voice_queue() -> void:
	"""Vide la queue des voix"""
	voice_queue.clear()

func get_audio_info() -> Dictionary:
	"""Retourne des informations sur l'état audio"""
	return {
		"current_music": current_music_track,
		"current_mood": MusicMood.keys()[current_music_mood],
		"current_zone": AmbienceZone.keys()[current_ambience_zone],
		"is_muted": is_system_muted,
		"voice_queue_size": voice_queue.size(),
		"volumes": {
			"master": master_volume,
			"music": music_volume,
			"sfx": sfx_volume,
			"voice": voice_volume,
			"ambience": ambience_volume
		}
	}

# ============================================================================
# SAVE/LOAD SUPPORT
# ============================================================================
func get_save_data() -> Dictionary:
	"""Retourne les données de sauvegarde audio"""
	return {
		"current_music_track": current_music_track,
		"current_music_mood": current_music_mood,
		"current_ambience_zone": current_ambience_zone,
		"volumes": {
			"master": master_volume,
			"music": music_volume,
			"sfx": sfx_volume,
			"voice": voice_volume,
			"ambience": ambience_volume
		},
		"settings": {
			"adaptive_music": adaptive_music_enabled,
			"audio_3d": audio_3d_enabled,
			"accessibility_mode": accessibility_mode
		},
		"accessibility_config": accessibility_config
	}

func apply_save_data(data: Dictionary) -> void:
	"""Applique les données de sauvegarde audio"""
	# Restoration état musical
	var saved_track = data.get("current_music_track", "")
	if saved_track:
		current_music_track = saved_track
		current_music_mood = data.get("current_music_mood", MusicMood.NEUTRAL)
		play_music(saved_track, 0.5)
	
	# Restoration ambiance
	var saved_zone = data.get("current_ambience_zone", AmbienceZone.DOLLY_SISTERS)
	change_ambience(saved_zone, 0.5)
	
	# Restoration volumes
	var volumes = data.get("volumes", {})
	if volumes:
		set_master_volume(volumes.get("master", 1.0))
		set_music_volume(volumes.get("music", 0.8))
		set_sfx_volume(volumes.get("sfx", 0.8))
		set_voice_volume(volumes.get("voice", 1.0))
		ambience_volume = volumes.get("ambience", 0.6)
	
	# Restoration settings
	var settings = data.get("settings", {})
	adaptive_music_enabled = settings.get("adaptive_music", true)
	audio_3d_enabled = settings.get("audio_3d", true)
	accessibility_mode = settings.get("accessibility_mode", false)
	
	# Restoration accessibilité
	accessibility_config.merge(data.get("accessibility_config", {}))

# Signal pour indiquer que le manager est prêt
signal manager_initialized()

func _on_music_transition_timeout() -> void:
	"""Timer de transition musicale"""
	# Logique de transition automatique si nécessaire
	pass

func initialize() -> void:
	"""Finalise l'initialisation et émet le signal"""
	manager_initialized.emit()