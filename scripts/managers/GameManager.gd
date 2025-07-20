# ============================================================================
# 🎮 GameManager.gd - SINGLETON CENTRAL (CORRIGÉ)
# ============================================================================
# STATUS: ✅ CORE SYSTEM | ROADMAP: Mois 1, Semaine 1 - Core Architecture
# PRIORITY: 🔴 CRITICAL - Orchestrateur principal du jeu
# DEPENDENCIES: Aucune (c'est le manager racine)

extends Node

## Singleton central qui orchestre tous les systèmes de "Sortilèges & Bestioles"
## Architecture modulaire pour support DLC et extensions futures
## Gestion centralisée des états, scènes et configuration

# ============================================================================
# SIGNAUX GLOBAUX
# ============================================================================

## Émis quand tous les managers sont initialisés
signal game_initialized()

## Émis lors d'un changement de scène
signal scene_changing(from_scene: String, to_scene: String)
signal scene_changed(new_scene: String)

## Émis pour les changements d'état du jeu
signal game_state_changed(old_state: String, new_state: String)

## Émis pour les événements de sauvegarde
signal save_requested(save_slot: int)
signal save_completed(success: bool)
signal load_requested(save_slot: int)
signal load_completed(success: bool)

## Signal interne pour la synchronisation des managers
signal manager_ready(manager_name: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

## États possibles du jeu
enum GameState {
	BOOT,           ## Démarrage initial
	MAIN_MENU,      ## Menu principal
	LOADING,        ## Chargement en cours
	IN_GAME,        ## En jeu
	PAUSED,         ## Jeu en pause
	DIALOGUE,       ## En conversation
	COMBAT,         ## En combat
	CUTSCENE,       ## Cinématique
	GAME_OVER       ## Fin de partie
}

## Configuration des chemins de scènes
const SCENE_PATHS = {
	"main_menu": "res://scenes/ui/MainMenu.tscn",
	"game": "res://scenes/Game.tscn",
	"prologue": "res://scenes/levels/PrologueApartment.tscn",
	"ankh_morpork": "res://scenes/levels/AnkhMorpork.tscn",
	"test": "res://scenes/test/TestScene.tscn"
}

## Configuration par défaut
const DEFAULT_CONFIG = {
	"game_version": "0.1.0",
	"debug_mode": true,
	"auto_save_interval": 300.0,  # 5 minutes
	"target_fps": 60,
	"vsync_enabled": true
}

# ============================================================================
# VARIABLES
# ============================================================================

## État actuel du jeu
var current_game_state: GameState = GameState.BOOT
var previous_game_state: GameState = GameState.BOOT

## Références aux managers (initialisés dynamiquement)
var managers: Dictionary = {}
var managers_initialized: Dictionary = {}

# Références directes pour accès rapide
var data_manager: Node
var ui_manager: Node
var audio_manager: Node
var save_system: Node
var observation_manager: Node
var dialogue_manager: Node
var quest_manager: Node
var reputation_system: Node
var combat_system: Node

## Scène actuelle
var current_scene: Node = null
var current_scene_path: String = ""

## Configuration du jeu
var game_config: Dictionary = DEFAULT_CONFIG.duplicate()

## Données de session
var session_data: Dictionary = {
	"play_time": 0.0,
	"scenes_visited": [],
	"achievements_unlocked": [],
	"stats": {}
}

## Flags système
var is_initialized: bool = false
var is_loading: bool = false
var debug_mode: bool = false

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	"""Point d'entrée du GameManager"""
	process_mode = Node.PROCESS_MODE_ALWAYS  # Continue même en pause
	
	print("========================================")
	print("🎮 GameManager: Initialisation...")
	print("Version: ", game_config.game_version)
	print("========================================")
	
	# Configuration initiale
	setup_game_configuration()
	
	# Initialisation asynchrone des managers
	await initialize_all_managers()
	
	# Finalisation
	is_initialized = true
	game_initialized.emit()
	change_game_state(GameState.MAIN_MENU)
	
	print("🎮 GameManager: Initialisation complète!")

func setup_game_configuration() -> void:
	"""Configure les paramètres initiaux du jeu"""
	# Paramètres d'affichage
	Engine.max_fps = game_config.target_fps
	DisplayServer.window_set_vsync_mode(
		DisplayServer.VSYNC_ENABLED if game_config.vsync_enabled 
		else DisplayServer.VSYNC_DISABLED
	)
	
	# Mode debug
	debug_mode = game_config.debug_mode
	if debug_mode:
		print("🔧 Mode DEBUG activé")

# ============================================================================
# GESTION DES MANAGERS
# ============================================================================

func initialize_all_managers() -> void:
	"""Initialise tous les managers dans l'ordre correct"""
	print("[GameManager] Initialisation des managers...")
	
	# 1. DataManager (priorité absolue - charge les JSON)
	data_manager = await create_and_initialize_manager("DataManager", "res://scripts/managers/DataManager.gd")
	
	# 2. Managers indépendants
	ui_manager = await create_and_initialize_manager("UIManager", "res://scripts/stubs/UIManager.gd")
	audio_manager = await create_and_initialize_manager("AudioManager", "res://scripts/stubs/AudioManager.gd")
	save_system = await create_and_initialize_manager("SaveSystem", "res://scripts/managers/SaveSystem.gd")
	
	# 3. Managers de gameplay (dépendent de DataManager)
	observation_manager = await create_and_initialize_manager("ObservationManager", "res://scripts/managers/ObservationManager.gd")
	dialogue_manager = await create_and_initialize_manager("DialogueManager", "res://scripts/managers/DialogueManager.gd")
	quest_manager = await create_and_initialize_manager("QuestManager", "res://scripts/managers/QuestManager.gd")
	
	# 4. Managers dépendant des autres
	reputation_system = await create_and_initialize_manager("ReputationSystem", "res://scripts/managers/ReputationSystem.gd")
	combat_system = await create_and_initialize_manager("CombatSystem", "res://scripts/managers/CombatSystem.gd")
	
	print("[GameManager] Tous les managers initialisés")

func create_and_initialize_manager(manager_name: String, script_path: String) -> Node:
	"""Crée et initialise un manager spécifique"""
	# Vérifier si déjà chargé
	var existing = get_node_or_null("/root/" + manager_name)
	if existing:
		print("[GameManager] Manager existant trouvé: " + manager_name)
		return existing
	
	# Vérifier si le fichier existe
	if not FileAccess.file_exists(script_path):
		push_warning("[GameManager] Manager non trouvé: " + script_path)
		managers[manager_name] = null
		managers_initialized[manager_name] = false
		return null
	
	# Charger et instancier
	var manager_script = load(script_path)
	if not manager_script:
		push_error("[GameManager] Impossible de charger: " + script_path)
		return null
	
	var manager_instance = manager_script.new()
	manager_instance.name = manager_name
	add_child(manager_instance)
	
	# Stocker la référence
	managers[manager_name] = manager_instance
	
	# Attendre l'initialisation si le manager a le signal
	if manager_instance.has_signal("manager_initialized"):
		await manager_instance.manager_initialized
	else:
		await get_tree().process_frame
	
	managers_initialized[manager_name] = true
	manager_ready.emit(manager_name)
	print("[GameManager] ✅ Manager initialisé: " + manager_name)
	
	return manager_instance

func get_manager(manager_name: String) -> Node:
	"""Récupère un manager par son nom"""
	return managers.get(manager_name, null)

# ============================================================================
# GESTION DES ÉTATS
# ============================================================================

func change_game_state(new_state: GameState) -> void:
	"""Change l'état global du jeu"""
	if new_state == current_game_state:
		return
	
	previous_game_state = current_game_state
	current_game_state = new_state
	
	# Notifier du changement
	game_state_changed.emit(
		GameState.keys()[previous_game_state],
		GameState.keys()[current_game_state]
	)
	
	# Actions spécifiques selon l'état
	match new_state:
		GameState.PAUSED:
			get_tree().paused = true
		GameState.IN_GAME, GameState.MAIN_MENU:
			get_tree().paused = false
		GameState.DIALOGUE:
			# Le DialogueManager gère la pause locale
			pass
		GameState.COMBAT:
			# Le CombatSystem gère ses propres états
			pass
	
	if debug_mode:
		print("🎮 État changé: ", GameState.keys()[previous_game_state], 
			  " → ", GameState.keys()[current_game_state])

func is_in_game() -> bool:
	"""Vérifie si le jeu est dans un état jouable"""
	return current_game_state in [GameState.IN_GAME, GameState.DIALOGUE, GameState.COMBAT]

# ============================================================================
# GESTION DES SCÈNES
# ============================================================================

func change_scene(scene_key: String) -> void:
	"""Change de scène avec transition"""
	if not SCENE_PATHS.has(scene_key):
		push_error("Scène inconnue: " + scene_key)
		return
	
	if is_loading:
		push_warning("Changement de scène déjà en cours")
		return
	
	is_loading = true
	var target_scene = SCENE_PATHS[scene_key]
	
	# Notifier le début du changement
	scene_changing.emit(current_scene_path, target_scene)
	change_game_state(GameState.LOADING)
	
	# Effectuer la transition
	await _perform_scene_transition(target_scene)
	
	# Finaliser
	current_scene_path = target_scene
	session_data.scenes_visited.append(scene_key)
	is_loading = false
	
	# Notifier la fin du changement
	scene_changed.emit(target_scene)
	
	# Retourner à l'état approprié
	if scene_key == "main_menu":
		change_game_state(GameState.MAIN_MENU)
	else:
		change_game_state(GameState.IN_GAME)

func _perform_scene_transition(scene_path: String) -> void:
	"""Effectue la transition de scène avec fondu"""
	# TODO: Implémenter transition visuelle via UIManager
	
	# Charger la nouvelle scène
	var new_scene = load(scene_path)
	if not new_scene:
		push_error("Impossible de charger: " + scene_path)
		return
	
	# Remplacer la scène
	if current_scene:
		current_scene.queue_free()
		await current_scene.tree_exited
	
	current_scene = new_scene.instantiate()
	get_tree().root.add_child(current_scene)
	get_tree().current_scene = current_scene

# ============================================================================
# API PUBLIQUE
# ============================================================================

func save_game(slot: int = 0) -> void:
	"""Déclenche une sauvegarde"""
	save_requested.emit(slot)
	
	var save_system = get_manager("SaveSystem")
	if save_system and save_system.has_method("save_game"):
		var success = await save_system.save_game(slot)
		save_completed.emit(success)
	else:
		push_warning("SaveSystem non disponible")
		save_completed.emit(false)

func load_game(slot: int = 0) -> void:
	"""Charge une partie sauvegardée"""
	load_requested.emit(slot)
	
	var save_system = get_manager("SaveSystem")
	if save_system and save_system.has_method("load_game"):
		var success = await save_system.load_game(slot)
		load_completed.emit(success)
	else:
		push_warning("SaveSystem non disponible")
		load_completed.emit(false)

func pause_game() -> void:
	"""Met le jeu en pause"""
	if is_in_game():
		change_game_state(GameState.PAUSED)

func resume_game() -> void:
	"""Reprend le jeu"""
	if current_game_state == GameState.PAUSED:
		change_game_state(previous_game_state)

func quit_game() -> void:
	"""Quitte proprement le jeu"""
	# Sauvegarder les préférences
	# TODO: Implémenter sauvegarde config
	
	print("🎮 GameManager: Fermeture du jeu...")
	get_tree().quit()

# ============================================================================
# UTILITAIRES
# ============================================================================

func _process(delta: float) -> void:
	"""Mise à jour continue"""
	if is_in_game():
		session_data.play_time += delta

func get_play_time_formatted() -> String:
	"""Retourne le temps de jeu formaté"""
	var time = session_data.play_time
	var hours = int(time / 3600)
	var minutes = int((time % 3600) / 60)
	var seconds = int(time % 60)
	
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func _notification(what: int) -> void:
	"""Gestion des notifications système"""
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		quit_game()
