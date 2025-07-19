extends Node
class_name GameManager

## ========================================================================
## GAMEMANAGER - SINGLETON CENTRAL
## Orchestre tous les systèmes du jeu "Sortilèges & Bestioles"
## ========================================================================

# ================================
# SIGNAUX GLOBAUX
# ================================
signal scene_transition_started(from_scene: String, to_scene: String)
signal scene_transition_completed(scene_name: String)
signal game_state_changed(new_state: GameState)
signal manager_ready(manager_name: String)
signal save_completed(save_slot: int)
signal load_completed(save_slot: int)

# ================================
# ENUMS ET CONSTANTES
# ================================
enum GameState {
	MAIN_MENU,
	LOADING,
	PROLOGUE,
	ACT_I,
	ACT_II,
	ACT_III,
	PAUSE_MENU,
	SETTINGS,
	CREDITS
}

enum TransitionType {
	FADE,
	SLIDE,
	MAGICAL_SPARKLE,
	INSTANT
}

const SCENE_PATHS = {
	"main_menu": "res://scenes/ui/MainMenu.tscn",
	"prologue_apartment": "res://scenes/prologue/Apartment.tscn",
	"prologue_street": "res://scenes/prologue/StreetDollySisters.tscn",
	"prologue_cake_shop": "res://scenes/prologue/MadameCakeShop.tscn",
	"ankh_morpork_hub": "res://scenes/act1/AnkhMorporkHub.tscn",
	"patrician_palace": "res://scenes/act1/PatricianPalace.tscn",
	"unseen_university": "res://scenes/act1/UnseenUniversity.tscn"
}

const SAVE_FILE_PATH = "user://savegame_%d.save"
const CONFIG_FILE_PATH = "user://game_config.cfg"
const MAX_SAVE_SLOTS = 10

# ================================
# VARIABLES ÉTAT GLOBAL
# ================================
var current_state: GameState = GameState.MAIN_MENU
var current_scene_name: String = ""
var is_transitioning: bool = false

# Références aux managers (initialisées au _ready)
var observation_manager: ObservationManager
var dialogue_manager: DialogueManager
var quest_manager: QuestManager
var ui_manager: UIManager
var audio_manager: AudioManager
var save_system: SaveSystem

# État du jeu persistant
var story_variables: Dictionary = {}
var player_data: Dictionary = {}
var world_state: Dictionary = {}
var settings: Dictionary = {}

# DLC et contenu modulaire
var loaded_dlcs: Array[String] = []
var dlc_content: Dictionary = {}

# Performance et debugging
var debug_mode: bool = false
var performance_stats: Dictionary = {}

# ================================
# INITIALISATION
# ================================
func _ready() -> void:
	"""Initialisation du GameManager au démarrage"""
	print("[GameManager] Initialisation du système central...")
	
	# Configuration initiale
	setup_process_settings()
	load_game_config()
	initialize_default_data()
	
	# Initialisation des managers dans l'ordre
	await initialize_managers()
	
	# Configuration des connexions
	setup_signal_connections()
	
	# Démarrage du jeu
	start_game()
	
	print("[GameManager] Système central initialisé avec succès")

func setup_process_settings() -> void:
	"""Configure les paramètres de processus Godot"""
	# Configuration pour une expérience stable
	Engine.max_fps = 60
	
	# Gestion automatique de la pause
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Configuration input
	set_process_input(true)

func initialize_default_data() -> void:
	"""Initialise les structures de données par défaut"""
	story_variables = {
		"prologue_completed": false,
		"letter_read": false,
		"maurice_met": false,
		"madame_cake_visited": false,
		"prologue_approach": "",
		"act1_alliance": "",
		"act2_strategy": "",
		"current_chapter": 0,
		"observation_count": 0,
		"magic_amplification": 1.0
	}
	
	player_data = {
		"name": "",
		"origin": "",
		"level": 1,
		"experience": 0,
		"health": 100,
		"mana": 50,
		"location": "prologue_apartment",
		"inventory": [],
		"skills": {},
		"relationships": {},
		"reputation": {}
	}
	
	world_state = {
		"current_time": 0.0,
		"day_night_cycle": 0.0,
		"weather": "clear",
		"season": "spring",
		"city_events": [],
		"creature_evolutions": {},
		"faction_states": {}
	}
	
	settings = {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 0.8,
		"voice_volume": 1.0,
		"language": "en",
		"accessibility_mode": false,
		"colorblind_support": false,
		"subtitle_size": 1.0,
		"auto_save": true
	}

# ================================
# GESTION DES MANAGERS
# ================================
func initialize_managers() -> void:
	"""Initialise tous les managers dans l'ordre de dépendance"""
	print("[GameManager] Initialisation des managers...")
	
	# Manager UI (doit être créé en premier pour les transitions)
	ui_manager = await create_or_get_manager("UIManager", "res://scripts/managers/UIManager.gd")
	
	# Manager Audio (indépendant)
	audio_manager = await create_or_get_manager("AudioManager", "res://scripts/managers/AudioManager.gd")
	
	# Save System (indépendant)
	save_system = await create_or_get_manager("SaveSystem", "res://scripts/managers/SaveSystem.gd")
	
	# Managers de gameplay (dépendent de l'UI)
	observation_manager = await create_or_get_manager("ObservationManager", "res://scripts/managers/ObservationManager.gd")
	dialogue_manager = await create_or_get_manager("DialogueManager", "res://scripts/managers/DialogueManager.gd")
	quest_manager = await create_or_get_manager("QuestManager", "res://scripts/managers/QuestManager.gd")
	
	print("[GameManager] Tous les managers initialisés")

func create_or_get_manager(manager_name: String, script_path: String) -> Node:
	"""Crée ou récupère un manager existant"""
	var existing_manager = get_node_or_null("/root/" + manager_name)
	if existing_manager:
		print("[GameManager] Manager existant trouvé: " + manager_name)
		return existing_manager
	
	# Création du manager s'il n'existe pas
	var manager_scene = load(script_path)
	if manager_scene:
		var manager_instance = manager_scene.new()
		manager_instance.name = manager_name
		get_tree().root.add_child(manager_instance)
		
		# Attendre que le manager soit prêt
		if manager_instance.has_signal("manager_initialized"):
			await manager_instance.manager_initialized
		else:
			await manager_instance.ready
		
		manager_ready.emit(manager_name)
		print("[GameManager] Manager créé: " + manager_name)
		return manager_instance
	else:
		push_error("[GameManager] Impossible de charger le manager: " + script_path)
		return null

func setup_signal_connections() -> void:
	"""Configure les connexions entre managers"""
	# Connexions de base pour communication inter-managers
	if observation_manager and dialogue_manager:
		observation_manager.creature_observed.connect(_on_creature_observed)
	
	if quest_manager:
		quest_manager.quest_completed.connect(_on_quest_completed)
		quest_manager.story_milestone_reached.connect(_on_story_milestone)
	
	# Connexions sauvegarde
	if save_system:
		save_system.save_completed.connect(func(slot): save_completed.emit(slot))
		save_system.load_completed.connect(func(slot): load_completed.emit(slot))

# ================================
# GESTION DES SCÈNES
# ================================
func change_scene(scene_key: String, transition: TransitionType = TransitionType.FADE, data: Dictionary = {}) -> void:
	"""Change de scène avec transition"""
	if is_transitioning:
		print("[GameManager] Transition déjà en cours, requête ignorée")
		return
	
	if not SCENE_PATHS.has(scene_key):
		push_error("[GameManager] Scène inconnue: " + scene_key)
		return
	
	is_transitioning = true
	var from_scene = current_scene_name
	var to_scene = scene_key
	
	print("[GameManager] Transition: " + from_scene + " -> " + to_scene)
	scene_transition_started.emit(from_scene, to_scene)
	
	# Démarrer transition UI
	if ui_manager:
		await ui_manager.start_transition(transition)
	
	# Changer la scène
	var scene_path = SCENE_PATHS[scene_key]
	var error = get_tree().change_scene_to_file(scene_path)
	
	if error == OK:
		current_scene_name = scene_key
		
		# Passer les données à la nouvelle scène si nécessaire
		if data.size() > 0:
			await get_tree().process_frame
			var current_scene = get_tree().current_scene
			if current_scene.has_method("receive_scene_data"):
				current_scene.receive_scene_data(data)
		
		# Terminer transition UI
		if ui_manager:
			await ui_manager.complete_transition()
		
		is_transitioning = false
		scene_transition_completed.emit(to_scene)
		print("[GameManager] Transition terminée vers: " + to_scene)
	else:
		push_error("[GameManager] Erreur lors du changement de scène: " + str(error))
		is_transitioning = false

func get_current_scene_controller() -> Node:
	"""Retourne le contrôleur de la scène actuelle"""
	var current_scene = get_tree().current_scene
	if current_scene and current_scene.has_method("get_scene_controller"):
		return current_scene.get_scene_controller()
	return current_scene

# ================================
# GESTION DE L'ÉTAT DU JEU
# ================================
func set_game_state(new_state: GameState) -> void:
	"""Change l'état global du jeu"""
	if current_state != new_state:
		var old_state = current_state
		current_state = new_state
		game_state_changed.emit(new_state)
		print("[GameManager] État changé: " + GameState.keys()[old_state] + " -> " + GameState.keys()[new_state])

func get_story_variable(key: String, default_value = null):
	"""Récupère une variable d'histoire"""
	return story_variables.get(key, default_value)

func set_story_variable(key: String, value) -> void:
	"""Définit une variable d'histoire"""
	story_variables[key] = value
	print("[GameManager] Variable d'histoire mise à jour: " + key + " = " + str(value))

func increment_story_variable(key: String, amount: int = 1) -> void:
	"""Incrémente une variable d'histoire numérique"""
	var current_value = story_variables.get(key, 0)
	story_variables[key] = current_value + amount

func get_player_data(key: String, default_value = null):
	"""Récupère une donnée joueur"""
	return player_data.get(key, default_value)

func set_player_data(key: String, value) -> void:
	"""Définit une donnée joueur"""
	player_data[key] = value

# ================================
# SYSTÈME DE SAUVEGARDE
# ================================
func save_game(slot: int = 0) -> bool:
	"""Sauvegarde l'état complet du jeu"""
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[GameManager] Slot de sauvegarde invalide: " + str(slot))
		return false
	
	var save_data = compile_save_data()
	var save_path = SAVE_FILE_PATH % slot
	
	var save_file = FileAccess.open(save_path, FileAccess.WRITE)
	if save_file == null:
		push_error("[GameManager] Impossible d'ouvrir le fichier de sauvegarde: " + save_path)
		return false
	
	save_file.store_string(JSON.stringify(save_data))
	save_file.close()
	
	print("[GameManager] Jeu sauvegardé dans le slot " + str(slot))
	return true

func load_game(slot: int = 0) -> bool:
	"""Charge l'état du jeu depuis un slot"""
	if slot < 0 or slot >= MAX_SAVE_SLOTS:
		push_error("[GameManager] Slot de chargement invalide: " + str(slot))
		return false
	
	var save_path = SAVE_FILE_PATH % slot
	
	if not FileAccess.file_exists(save_path):
		print("[GameManager] Aucune sauvegarde trouvée dans le slot " + str(slot))
		return false
	
	var save_file = FileAccess.open(save_path, FileAccess.READ)
	if save_file == null:
		push_error("[GameManager] Impossible d'ouvrir le fichier de sauvegarde: " + save_path)
		return false
	
	var json_string = save_file.get_as_text()
	save_file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("[GameManager] Erreur lors du parsing de la sauvegarde")
		return false
	
	var save_data = json.data
	apply_save_data(save_data)
	
	print("[GameManager] Jeu chargé depuis le slot " + str(slot))
	return true

func compile_save_data() -> Dictionary:
	"""Compile toutes les données de sauvegarde"""
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"story_variables": story_variables,
		"player_data": player_data,
		"world_state": world_state,
		"current_scene": current_scene_name,
		"current_state": current_state,
		"loaded_dlcs": loaded_dlcs
	}
	
	# Ajouter les données des managers
	if observation_manager and observation_manager.has_method("get_save_data"):
		save_data["observation_data"] = observation_manager.get_save_data()
	
	if quest_manager and quest_manager.has_method("get_save_data"):
		save_data["quest_data"] = quest_manager.get_save_data()
	
	if dialogue_manager and dialogue_manager.has_method("get_save_data"):
		save_data["dialogue_data"] = dialogue_manager.get_save_data()
	
	return save_data

func apply_save_data(save_data: Dictionary) -> void:
	"""Applique les données de sauvegarde chargées"""
	story_variables = save_data.get("story_variables", {})
	player_data = save_data.get("player_data", {})
	world_state = save_data.get("world_state", {})
	loaded_dlcs = save_data.get("loaded_dlcs", [])
	
	# Appliquer aux managers
	if observation_manager and observation_manager.has_method("apply_save_data"):
		observation_manager.apply_save_data(save_data.get("observation_data", {}))
	
	if quest_manager and quest_manager.has_method("apply_save_data"):
		quest_manager.apply_save_data(save_data.get("quest_data", {}))
	
	if dialogue_manager and dialogue_manager.has_method("apply_save_data"):
		dialogue_manager.apply_save_data(save_data.get("dialogue_data", {}))
	
	# Changer vers la scène sauvegardée
	var saved_scene = save_data.get("current_scene", "main_menu")
	if saved_scene != current_scene_name:
		change_scene(saved_scene)
	
	set_game_state(save_data.get("current_state", GameState.MAIN_MENU))

# ================================
# GESTION DLC
# ================================
func load_dlc(dlc_id: String) -> bool:
	"""Charge un DLC de manière modulaire"""
	if dlc_id in loaded_dlcs:
		print("[GameManager] DLC déjà chargé: " + dlc_id)
		return true
	
	var dlc_path = "res://dlc/" + dlc_id + "/dlc_manifest.json"
	
	if not FileAccess.file_exists(dlc_path):
		print("[GameManager] DLC non trouvé: " + dlc_id)
		return false
	
	var dlc_file = FileAccess.open(dlc_path, FileAccess.READ)
	var dlc_manifest = JSON.parse_string(dlc_file.get_as_text())
	dlc_file.close()
	
	# Charger le contenu du DLC
	dlc_content[dlc_id] = dlc_manifest
	loaded_dlcs.append(dlc_id)
	
	# Intégrer le contenu (nouvelles scènes, créatures, etc.)
	integrate_dlc_content(dlc_id, dlc_manifest)
	
	print("[GameManager] DLC chargé avec succès: " + dlc_id)
	return true

func integrate_dlc_content(dlc_id: String, manifest: Dictionary) -> void:
	"""Intègre le contenu d'un DLC dans le jeu"""
	# Ajouter nouvelles scènes
	if manifest.has("scenes"):
		for scene_key in manifest["scenes"]:
			SCENE_PATHS[scene_key] = manifest["scenes"][scene_key]
	
	# Notifier les managers du nouveau contenu
	if observation_manager and manifest.has("creatures"):
		observation_manager.add_dlc_creatures(dlc_id, manifest["creatures"])
	
	if quest_manager and manifest.has("quests"):
		quest_manager.add_dlc_quests(dlc_id, manifest["quests"])

# ================================
# ÉVÉNEMENTS ET CALLBACKS
# ================================
func _on_creature_observed(creature_id: String, observation_data: Dictionary) -> void:
	"""Callback quand une créature est observée"""
	increment_story_variable("observation_count")
	
	# Logique spéciale pour certaines observations
	if creature_id == "maurice" and not story_variables.get("maurice_met", false):
		set_story_variable("maurice_met", true)

func _on_quest_completed(quest_id: String) -> void:
	"""Callback quand une quête est terminée"""
	print("[GameManager] Quête terminée: " + quest_id)
	
	# Auto-save après quêtes importantes
	if settings.get("auto_save", true):
		save_game(0)

func _on_story_milestone(milestone: String) -> void:
	"""Callback pour les jalons narratifs importants"""
	print("[GameManager] Jalon narratif atteint: " + milestone)
	
	# Changer l'état du jeu selon les jalons
	match milestone:
		"prologue_completed":
			set_game_state(GameState.ACT_I)
		"act1_completed":
			set_game_state(GameState.ACT_II)
		"act2_completed":
			set_game_state(GameState.ACT_III)

# ================================
# CONFIGURATION ET PARAMÈTRES
# ================================
func load_game_config() -> void:
	"""Charge la configuration du jeu"""
	var config_file = ConfigFile.new()
	var err = config_file.load(CONFIG_FILE_PATH)
	
	if err == OK:
		# Charger les paramètres
		for setting_key in settings.keys():
			settings[setting_key] = config_file.get_value("settings", setting_key, settings[setting_key])
		
		print("[GameManager] Configuration chargée")
	else:
		print("[GameManager] Aucune configuration trouvée, utilisation des valeurs par défaut")

func save_game_config() -> void:
	"""Sauvegarde la configuration du jeu"""
	var config_file = ConfigFile.new()
	
	for setting_key in settings.keys():
		config_file.set_value("settings", setting_key, settings[setting_key])
	
	config_file.save(CONFIG_FILE_PATH)
	print("[GameManager] Configuration sauvegardée")

func set_setting(key: String, value) -> void:
	"""Modifie un paramètre et sauvegarde"""
	settings[key] = value
	save_game_config()
	
	# Appliquer immédiatement certains paramètres
	match key:
		"master_volume", "music_volume", "sfx_volume", "voice_volume":
			if audio_manager:
				audio_manager.update_volume_settings(settings)

# ================================
# UTILITAIRES ET DEBUG
# ================================
func start_game() -> void:
	"""Démarre le jeu (appelé après initialisation)"""
	set_game_state(GameState.MAIN_MENU)
	change_scene("main_menu")

func quit_game() -> void:
	"""Quitte le jeu proprement"""
	print("[GameManager] Fermeture du jeu...")
	
	# Sauvegarde automatique si activée
	if settings.get("auto_save", true):
		save_game(0)
	
	save_game_config()
	get_tree().quit()

func get_debug_info() -> Dictionary:
	"""Retourne des informations de debug"""
	return {
		"current_state": GameState.keys()[current_state],
		"current_scene": current_scene_name,
		"loaded_dlcs": loaded_dlcs,
		"observation_count": story_variables.get("observation_count", 0),
		"managers_loaded": {
			"observation": observation_manager != null,
			"dialogue": dialogue_manager != null,
			"quest": quest_manager != null,
			"ui": ui_manager != null,
			"audio": audio_manager != null,
			"save": save_system != null
		}
	}

# ================================
# INPUT HANDLING
# ================================
func _input(event: InputEvent) -> void:
	"""Gestion des inputs globaux"""
	# Menu de pause
	if event.is_action_pressed("ui_pause") and current_state not in [GameState.MAIN_MENU, GameState.PAUSE_MENU]:
		toggle_pause_menu()
	
	# Quick save/load (debug)
	if debug_mode:
		if event.is_action_pressed("quick_save"):
			save_game(9)  # Slot de sauvegarde rapide
		elif event.is_action_pressed("quick_load"):
			load_game(9)

func toggle_pause_menu() -> void:
	"""Bascule le menu de pause"""
	if current_state == GameState.PAUSE_MENU:
		set_game_state(GameState.ACT_I)  # Ou l'état précédent
		get_tree().paused = false
	else:
		set_game_state(GameState.PAUSE_MENU)
		get_tree().paused = true
	
	if ui_manager:
		ui_manager.toggle_pause_menu(current_state == GameState.PAUSE_MENU)