# ============================================================================
# 📱 UIManager.gd - Gestionnaire Interface Utilisateur Complet
# ============================================================================
# STATUS: ✅ COMPLET | ROADMAP: Mois 1, Semaine 3-4 - UI Architecture
# PRIORITY: 🟠 P2 - Interface cohérente Terry Pratchett
# DEPENDENCIES: GameManager, ObservationManager, DialogueManager, MagicSystem
#=======

class_name UIManager
extends CanvasLayer

## Gestionnaire central de l'interface utilisateur pour "Sortilèges & Bestioles"
## Architecture modulaire extensible avec support complet accessibilité
## Style Terry Pratchett avec animations fluides et effets magiques

# ============================================================================
# SIGNAUX - Communication Event-Driven
# ============================================================================

## Émis quand un élément UI est affiché
signal ui_element_shown(element_name: String, data: Dictionary)

## Émis quand un élément UI est masqué
signal ui_element_hidden(element_name: String)

## Émis quand l'interface change d'état (menu, jeu, dialogue, etc.)
signal ui_state_changed(old_state: String, new_state: String)

## Émis pour changements de paramètres UI/accessibilité
signal ui_settings_changed(setting_type: String, new_value)

## Émis quand une notification est affichée
signal notification_displayed(message: String, type: String, duration: float)

## Émis pour interactions utilisateur importantes
signal user_interaction(interaction_type: String, target: String, data: Dictionary)

## Signal d'initialisation pour GameManager
signal manager_initialized()

# ============================================================================
# CONFIGURATION & PARAMÈTRES
# ============================================================================

## Configuration chargée depuis JSON
@export var ui_config_path: String = "res://data/ui_config.json"
@export var accessibility_config_path: String = "res://data/accessibility_config.json"
@export var animation_config_path: String = "res://data/animation_config.json"

## État et configuration système
var ui_config: Dictionary = {}
var accessibility_settings: Dictionary = {}
var animation_settings: Dictionary = {}
var current_resolution: Vector2i
var base_resolution: Vector2i = Vector2i(1920, 1080)

## État actuel de l'interface
var current_ui_state: String = "menu"
var previous_ui_state: String = ""
var is_transitioning: bool = false
var active_panels: Array[String] = []
var ui_scaling_factor: float = 1.0

# ============================================================================
# SOUS-SYSTÈMES UI
# ============================================================================

## Gestionnaires spécialisés
var dialogue_ui: DialogueUI
var observation_ui: ObservationUI
var magic_ui: MagicUI
var menu_ui: MenuUI
var notification_system: NotificationSystem
var accessibility_manager: AccessibilityManager
var animation_controller: UIAnimationController

## Conteneurs principaux
@onready var main_container: Control = $MainContainer
@onready var hud_container: Control = $MainContainer/HUDContainer
@onready var dialogue_container: Control = $MainContainer/DialogueContainer
@onready var menu_container: Control = $MainContainer/MenuContainer
@onready var notification_container: Control = $MainContainer/NotificationContainer
@onready var overlay_container: Control = $MainContainer/OverlayContainer

# ============================================================================
# TYPES & ENUMS
# ============================================================================

enum UIState {
	MENU = 0,           ## Menu principal/pause
	GAMEPLAY = 1,       ## Jeu normal avec HUD
	DIALOGUE = 2,       ## Mode conversation
	OBSERVATION = 3,    ## Mode observation créatures
	MAGIC_CASTING = 4,  ## Interface de magie
	INVENTORY = 5,      ## Gestion inventaire
	SETTINGS = 6,       ## Paramètres système
	TRANSITION = 7      ## État de transition
}

enum NotificationType {
	INFO = 0,           ## Information générale
	SUCCESS = 1,        ## Succès/réussite
	WARNING = 2,        ## Avertissement
	ERROR = 3,          ## Erreur
	TUTORIAL = 4        ## Tutoriel/aide
}

enum AccessibilityMode {
	NONE = 0,           ## Aucune aide spéciale
	COLORBLIND = 1,     ## Support daltonisme
	LOW_VISION = 2,     ## Malvoyance
	MOTOR_IMPAIRED = 3, ## Difficultés motrices
	COGNITIVE = 4       ## Aide cognitive
}

# ============================================================================
# INITIALISATION SYSTÈME
# ============================================================================

# ================================
# ENUMS & CONSTANTS
# ================================
enum UIScreen {
	NONE,
	MAIN_MENU,
	GAME_HUD,
	INVENTORY,
	JOURNAL,
	NOTEBOOK,
	DIALOGUE,
	SETTINGS,
	PAUSE_MENU,
	LOADING,
	CREDITS
}

enum NotificationType {
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
	MAGICAL
}

enum UITheme {
	DEFAULT,
	NIGHT,
	AUTUMN,
	WINTER,
	SPRING,
	SUMMER,
	UNSEEN_UNIVERSITY,
	PATRICIAN_PALACE
}

# ================================
# VARIABLES PRINCIPALES
# ================================
@export var default_theme: UITheme = UITheme.DEFAULT
@export var notification_duration: float = 3.0
@export var transition_speed: float = 0.3
@export var accessibility_mode: bool = false

# État du UI
var current_screen: UIScreen = UIScreen.NONE
var previous_screen: UIScreen = UIScreen.NONE
var active_panels: Array[String] = []
var notification_queue: Array[Dictionary] = []
var is_transitioning: bool = false

# Références aux composants UI
var screens: Dictionary = {}
var panels: Dictionary = {}
var hud_elements: Dictionary = {}
var notification_container: Control
var overlay: ColorRect
var tooltip_system: Control

# Configuration UI
var ui_config: Dictionary = {
	"scale_factor": 1.0,
	"font_size": 16,
	"contrast_mode": false,
	"colorblind_mode": false,
	"animation_speed": 1.0,
	"sound_enabled": true,
	"auto_hide_tooltips": true,
	"button_hold_time": 0.3
}

# Thèmes
var themes: Dictionary = {}
var current_theme: UITheme = UITheme.DEFAULT

# ================================
# INITIALISATION
# ================================
func _ready() -> void:
	"""Initialisation complète du système UI"""
	print("📱 UIManager: Initialisation démarrée...")
	
	# Configuration de base
	setup_base_configuration()
	load_ui_configuration()
	setup_resolution_handling()
	
	# Création des conteneurs si absents
	create_ui_containers()
	
	# Initialisation des sous-systèmes
	await initialize_subsystems()
	
	# Configuration accessibilité
	setup_accessibility()
	
	# Connexions aux autres managers
	connect_to_game_systems()
	
	# État initial
	transition_to_state(UIState.MENU)
	
	print("📱 UIManager: Initialisation terminée")
	manager_initialized.emit()

func setup_base_configuration() -> void:
	"""Configure les paramètres de base"""
	current_resolution = get_viewport().get_visible_rect().size
	ui_scaling_factor = float(current_resolution.x) / float(base_resolution.x)
	
	# Détection écran tactile
	var has_touch = Input.get_connected_joypads().size() == 0 and DisplayServer.screen_get_dpi() > 200
	
	print("📱 Résolution détectée: ", current_resolution)
	print("📱 Facteur d'échelle UI: ", ui_scaling_factor)

func load_ui_configuration() -> void:
	"""Charge la configuration UI depuis les fichiers JSON"""
	# Configuration UI principale
	ui_config = load_json_file(ui_config_path)
	if ui_config.is_empty():
		ui_config = get_default_ui_config()
	
	# Configuration accessibilité
	accessibility_settings = load_json_file(accessibility_config_path)
	if accessibility_settings.is_empty():
		accessibility_settings = get_default_accessibility_config()
	
	# Configuration animations
	animation_settings = load_json_file(animation_config_path)
	if animation_settings.is_empty():
		animation_settings = get_default_animation_config()
	
	print("📱 Configuration UI chargée")

func create_ui_containers() -> void:
	"""Crée les conteneurs UI principaux s'ils n'existent pas"""
	if not main_container:
		main_container = Control.new()
		main_container.name = "MainContainer"
		main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(main_container)
	
	# Créer les sous-conteneurs
	var containers = [
		"HUDContainer", "DialogueContainer", "MenuContainer", 
		"NotificationContainer", "OverlayContainer"
	]
	
	for container_name in containers:
		var container = main_container.get_node_or_null(container_name)
		if not container:
			container = Control.new()
			container.name = container_name
			container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			main_container.add_child(container)

func setup_resolution_handling() -> void:
	"""Configure la gestion responsive multi-résolution"""
	get_viewport().size_changed.connect(_on_viewport_resized)
	
	# Configuration scaling automatique
	get_tree().set_screen_stretch(
		Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,
		Window.CONTENT_SCALE_ASPECT_KEEP,
		base_resolution
	)

# ============================================================================
# INITIALISATION SOUS-SYSTÈMES
# ============================================================================

func initialize_subsystems() -> void:
	"""Initialise tous les sous-systèmes UI"""
	print("📱 Initialisation des sous-systèmes UI...")
	
	# DialogueUI - Interface conversations Terry Pratchett
	dialogue_ui = DialogueUI.new()
	dialogue_ui.initialize(dialogue_container, ui_config.get("dialogue", {}))
	dialogue_ui.dialogue_choice_selected.connect(_on_dialogue_choice_selected)
	dialogue_ui.dialogue_ended.connect(_on_dialogue_ended)
	
	# ObservationUI - Carnet magique et observation créatures
	observation_ui = ObservationUI.new()
	observation_ui.initialize(overlay_container, ui_config.get("observation", {}))
	observation_ui.creature_observed.connect(_on_creature_observed)
	observation_ui.notebook_page_changed.connect(_on_notebook_page_changed)
	
	# MagicUI - Interface sorts et magie Octarine
	magic_ui = MagicUI.new()
	magic_ui.initialize(overlay_container, ui_config.get("magic", {}))
	magic_ui.spell_cast_requested.connect(_on_spell_cast_requested)
	magic_ui.octarine_chaos_triggered.connect(_on_octarine_chaos)
	
	# MenuUI - Menus système et paramètres
	menu_ui = MenuUI.new()
	menu_ui.initialize(menu_container, ui_config.get("menus", {}))
	menu_ui.menu_action_selected.connect(_on_menu_action_selected)
	menu_ui.settings_changed.connect(_on_ui_settings_changed)
	
	# NotificationSystem - Notifications et tutoriels
	notification_system = NotificationSystem.new()
	notification_system.initialize(notification_container, ui_config.get("notifications", {}))
	notification_system.notification_dismissed.connect(_on_notification_dismissed)
	
	# AccessibilityManager - Support accessibilité complet
	accessibility_manager = AccessibilityManager.new()
	accessibility_manager.initialize(main_container, accessibility_settings)
	accessibility_manager.accessibility_mode_changed.connect(_on_accessibility_changed)
	
	# UIAnimationController - Contrôleur animations fluides
	animation_controller = UIAnimationController.new()
	animation_controller.initialize(main_container, animation_settings)
	animation_controller.animation_completed.connect(_on_animation_completed)
	
	print("📱 Sous-systèmes UI initialisés")

func setup_accessibility() -> void:
	"""Configure les fonctionnalités d'accessibilité"""
	var mode = accessibility_settings.get("primary_mode", AccessibilityMode.NONE)
	
	match mode:
		AccessibilityMode.COLORBLIND:
			setup_colorblind_support()
		AccessibilityMode.LOW_VISION:
			setup_low_vision_support()
		AccessibilityMode.MOTOR_IMPAIRED:
			setup_motor_support()
		AccessibilityMode.COGNITIVE:
			setup_cognitive_support()

# ============================================================================
# GESTION ÉTATS UI
# ============================================================================

func transition_to_state(new_state: UIState, data: Dictionary = {}) -> void:
	"""Transition vers un nouvel état d'interface"""
	if is_transitioning:
		print("📱 Transition déjà en cours, ignorée")
		return
	
	var old_state_name = UIState.keys()[current_ui_state] if current_ui_state < UIState.size() else "UNKNOWN"
	var new_state_name = UIState.keys()[new_state] if new_state < UIState.size() else "UNKNOWN"
	
	print("📱 Transition UI: ", old_state_name, " → ", new_state_name)
	
	is_transitioning = true
	previous_ui_state = old_state_name
	
	# Animation de transition sortie
	await animation_controller.play_transition_out(current_ui_state)
	
	# Masquer les éléments de l'ancien état
	hide_state_elements(current_ui_state)
	
	# Changer l'état
	current_ui_state = new_state_name
	
	# Afficher les éléments du nouvel état
	show_state_elements(new_state, data)
	
	# Animation de transition entrée
	await animation_controller.play_transition_in(new_state)
	
	is_transitioning = false
	ui_state_changed.emit(old_state_name, new_state_name)

func show_state_elements(state: UIState, data: Dictionary = {}) -> void:
	"""Affiche les éléments UI pour un état donné"""
	# Masquer tous les conteneurs d'abord
	hide_all_containers()
	
	match state:
		UIState.MENU:
			menu_container.show()
			menu_ui.show_main_menu()
			
		UIState.GAMEPLAY:
			hud_container.show()
			show_gameplay_hud()
			
		UIState.DIALOGUE:
			dialogue_container.show()
			hud_container.show()  # HUD réduit pendant dialogue
			if data.has("npc_id") and data.has("dialogue_id"):
				dialogue_ui.start_dialogue(data.npc_id, data.dialogue_id)
			
		UIState.OBSERVATION:
			overlay_container.show()
			hud_container.show()
			observation_ui.show_observation_interface(data)
			
		UIState.MAGIC_CASTING:
			overlay_container.show()
			hud_container.show()
			magic_ui.show_spell_selection(data)
			
		UIState.INVENTORY:
			overlay_container.show()
			hud_container.show()
			# TODO: show_inventory_interface(data)
			
		UIState.SETTINGS:
			menu_container.show()
			menu_ui.show_settings_menu(data)

func hide_state_elements(state: UIState) -> void:
	"""Masque les éléments UI d'un état"""
	match state:
		UIState.DIALOGUE:
			dialogue_ui.hide_dialogue()
		UIState.OBSERVATION:
			observation_ui.hide_observation_interface()
		UIState.MAGIC_CASTING:
			magic_ui.hide_spell_interface()

func hide_all_containers() -> void:
	"""Masque tous les conteneurs UI"""
	dialogue_container.hide()
	menu_container.hide()
	overlay_container.hide()
	# Note: notification_container et hud_container restent généralement visibles

# ============================================================================
# INTERFACE GAMEPLAY (HUD)
# ============================================================================

func show_gameplay_hud() -> void:
	"""Affiche le HUD de gameplay"""
	# TODO: Créer les éléments HUD
	# - Barre de vie/mana
	# - Mini-carte
	# - Raccourcis sorts
	# - Indicateurs observation
	pass

func update_health_display(current_health: int, max_health: int) -> void:
	"""Met à jour l'affichage de santé"""
	# TODO: Mise à jour barre de vie
	pass

func update_mana_display(current_mana: int, max_mana: int) -> void:
	"""Met à jour l'affichage de mana"""
	# TODO: Mise à jour barre de mana
	pass

func update_observation_count(count: int) -> void:
	"""Met à jour le compteur d'observations"""
	# TODO: Mise à jour compteur observations
	pass

# ============================================================================
# GESTION NOTIFICATIONS
# ============================================================================

func show_notification(message: String, type: NotificationType = NotificationType.INFO, duration: float = 3.0) -> void:
	"""Affiche une notification"""
	var type_name = NotificationType.keys()[type] if type < NotificationType.size() else "INFO"
	
	notification_system.show_notification(message, type_name, duration)
	notification_displayed.emit(message, type_name, duration)
	
	print("📱 Notification [", type_name, "]: ", message)

func show_tutorial(tutorial_id: String, data: Dictionary = {}) -> void:
	"""Affiche un tutoriel contexte"""
	notification_system.show_tutorial(tutorial_id, data)

# ============================================================================
# GESTION ÉVÉNEMENTS
# ============================================================================

func _on_dialogue_choice_selected(choice_id: String, choice_data: Dictionary) -> void:
	"""Gestion sélection choix dialogue"""
	print("📱 Choix dialogue sélectionné: ", choice_id)
	user_interaction.emit("dialogue_choice", choice_id, choice_data)
	
	# Transmettre au DialogueManager
	var dialogue_manager = get_node_or_null("/root/Dialogue")
	if dialogue_manager and dialogue_manager.has_method("process_choice"):
		dialogue_manager.process_choice(choice_id, choice_data)

func _on_dialogue_ended(npc_id: String, final_choice: String) -> void:
	"""Gestion fin de dialogue"""
	print("📱 Dialogue terminé avec: ", npc_id)
	transition_to_state(UIState.GAMEPLAY)

func _on_creature_observed(creature_id: String, observation_data: Dictionary) -> void:
	"""Gestion observation créature"""
	print("📱 Créature observée: ", creature_id)
	user_interaction.emit("creature_observation", creature_id, observation_data)
	
	# Transmettre à ObservationManager
	var observation_manager = get_node_or_null("/root/Observation")
	if observation_manager and observation_manager.has_method("observe_creature"):
		observation_manager.observe_creature(creature_id, observation_data)

func _on_spell_cast_requested(spell_id: String, target_data: Dictionary) -> void:
	"""Gestion demande de lancement de sort"""
	print("📱 Sort demandé: ", spell_id)
	user_interaction.emit("spell_cast", spell_id, target_data)
	
	# TODO: Transmettre au MagicSystem
	# var magic_system = get_node_or_null("/root/Magic")

func _on_octarine_chaos(chaos_type: String, affected_data: Dictionary) -> void:
	"""Gestion effets chaotiques Octarine"""
	print("📱 Chaos Octarine déclenché: ", chaos_type)
	show_notification("La magie Octarine provoque des effets inattendus!", NotificationType.WARNING, 4.0)

func _on_menu_action_selected(action: String, data: Dictionary) -> void:
	"""Gestion actions menu"""
	match action:
		"new_game":
			# TODO: Démarrer nouvelle partie
			pass
		"load_game":
			# TODO: Charger partie
			pass
		"save_game":
			# TODO: Sauvegarder
			pass
		"settings":
			transition_to_state(UIState.SETTINGS)
		"quit_game":
			get_tree().quit()

func _on_ui_settings_changed(setting_type: String, new_value) -> void:
	"""Gestion changements paramètres UI"""
	match setting_type:
		"ui_scale":
			ui_scaling_factor = new_value
			apply_ui_scaling()
		"accessibility_mode":
			accessibility_manager.change_mode(new_value)
		"animation_speed":
			animation_controller.set_speed_multiplier(new_value)
	
	ui_settings_changed.emit(setting_type, new_value)

func _on_accessibility_changed(mode: AccessibilityMode, settings: Dictionary) -> void:
	"""Gestion changements accessibilité"""
	print("📱 Mode accessibilité changé: ", AccessibilityMode.keys()[mode])
	accessibility_settings.merge(settings)

func _on_animation_completed(animation_name: String, data: Dictionary) -> void:
	"""Gestion fin d'animation"""
	# Pour debug et gestion fine des transitions
	pass

func _on_notification_dismissed(notification_id: String) -> void:
	"""Gestion fermeture notification"""
	pass

func _on_viewport_resized() -> void:
	"""Gestion redimensionnement écran"""
	var new_resolution = get_viewport().get_visible_rect().size
	if new_resolution != current_resolution:
		current_resolution = new_resolution
		ui_scaling_factor = float(current_resolution.x) / float(base_resolution.x)
		apply_ui_scaling()
		print("📱 Résolution changée: ", current_resolution)

# ============================================================================
# MÉTHODES UTILITAIRES
# ============================================================================

func apply_ui_scaling() -> void:
	"""Applique le facteur d'échelle à tous les éléments UI"""
	if main_container:
		main_container.scale = Vector2.ONE * ui_scaling_factor

func setup_colorblind_support() -> void:
	"""Configure le support daltonisme"""
	print("📱 Support daltonisme activé")
	# TODO: Ajuster couleurs, ajouter symboles alternatifs

func setup_low_vision_support() -> void:
	"""Configure le support malvoyance"""
	print("📱 Support malvoyance activé")
	# TODO: Agrandir textes, augmenter contrastes

func setup_motor_support() -> void:
	"""Configure le support difficultés motrices"""
	print("📱 Support moteur activé")
	# TODO: Zones de clic agrandies, auto-aim

func setup_cognitive_support() -> void:
	"""Configure l'aide cognitive"""
	print("📱 Support cognitif activé")
	# TODO: Simplification interface, aide contextuelle

func connect_to_game_systems() -> void:
	"""Connecte l'UIManager aux autres systèmes"""
	# Connexion à GameManager
	var game_manager = get_node_or_null("/root/Game")
	if game_manager:
		if game_manager.has_signal("game_state_changed"):
			game_manager.game_state_changed.connect(_on_game_state_changed)
	
	# Connexion à ObservationManager
	var observation_manager = get_node_or_null("/root/Observation")
	if observation_manager:
		if observation_manager.has_signal("creature_evolved"):
			observation_manager.creature_evolved.connect(_on_creature_evolved)
	
	print("🔗 Connexions UIManager établies")

func _on_game_state_changed(old_state: String, new_state: String) -> void:
	"""Réaction aux changements d'état de jeu"""
	match new_state:
		"menu":
			transition_to_state(UIState.MENU)
		"gameplay":
			transition_to_state(UIState.GAMEPLAY)
		"paused":
			menu_ui.show_pause_menu()

func _on_creature_evolved(creature_id: String, old_stage: int, new_stage: int) -> void:
	"""Réaction à l'évolution d'une créature"""
	show_notification("Une créature a évolué! Consultez votre carnet.", NotificationType.SUCCESS, 5.0)
	observation_ui.highlight_evolved_creature(creature_id)

# ============================================================================
# CONFIGURATIONS PAR DÉFAUT
# ============================================================================

func get_default_ui_config() -> Dictionary:
	"""Retourne la configuration UI par défaut"""
	return {
		"dialogue": {
			"bubble_style": "terry_pratchett",
			"text_speed": 50,
			"auto_advance": false,
			"show_portraits": true
		},
		"observation": {
			"notebook_style": "magical",
			"zoom_sensitivity": 1.0,
			"auto_catalog": true
		},
		"magic": {
			"spell_selection_mode": "radial",
			"show_chaos_warnings": true,
			"octarine_effects": true
		},
		"notifications": {
			"duration_multiplier": 1.0,
			"max_simultaneous": 3,
			"position": "top_right"
		}
	}

func get_default_accessibility_config() -> Dictionary:
	"""Retourne la configuration accessibilité par défaut"""
	return {
		"primary_mode": AccessibilityMode.NONE,
		"text_scale": 1.0,
		"high_contrast": false,
		"colorblind_mode": "none",
		"motor_assistance": false,
		"cognitive_assistance": false,
		"audio_cues": false
	}

func get_default_animation_config() -> Dictionary:
	"""Retourne la configuration animations par défaut"""
	return {
		"transition_speed": 1.0,
		"easing_type": "ease_out",
		"particle_effects": true,
		"screen_shake": true,
		"ui_bounce": true
	}

func load_json_file(path: String) -> Dictionary:
	"""Charge un fichier JSON et retourne un Dictionary"""
	if not FileAccess.file_exists(path):
		print("📱 Fichier JSON introuvable: ", path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		print("📱 Erreur ouverture fichier: ", path)
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("📱 Erreur parsing JSON: ", path, " à la ligne ", json.get_error_line())
		return {}
	
	return json.data

# ============================================================================
# API PUBLIQUE POUR AUTRES SYSTÈMES
# ============================================================================

## Méthodes appelables par d'autres managers

func show_dialogue_interface(npc_id: String, dialogue_id: String) -> void:
	"""API: Affiche l'interface de dialogue"""
	transition_to_state(UIState.DIALOGUE, {"npc_id": npc_id, "dialogue_id": dialogue_id})

func show_observation_interface(creature_id: String = "") -> void:
	"""API: Affiche l'interface d'observation"""
	transition_to_state(UIState.OBSERVATION, {"creature_id": creature_id})

func show_magic_interface(spell_context: Dictionary = {}) -> void:
	"""API: Affiche l'interface de magie"""
	transition_to_state(UIState.MAGIC_CASTING, spell_context)

func force_hide_all_ui() -> void:
	"""API: Force le masquage de toute l'interface (pour cutscenes)"""
	hide_all_containers()
	hud_container.hide()
	notification_container.hide()

func restore_ui_from_hide() -> void:
	"""API: Restaure l'interface après masquage forcé"""
	transition_to_state(UIState.GAMEPLAY)
	notification_container.show()

func is_ui_blocking_input() -> bool:
	"""API: Vérifie si l'UI bloque les inputs de gameplay"""
	return current_ui_state in ["DIALOGUE", "MENU", "SETTINGS"] or is_transitioning

# ============================================================================
# DEBUG & DÉVELOPPEMENT
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Gestion des raccourcis debug (à retirer en production)"""
	if OS.is_debug_build():
		if event.is_action_pressed("ui_cancel"):
			if current_ui_state == "GAMEPLAY":
				transition_to_state(UIState.MENU)
			elif current_ui_state == "MENU":
				transition_to_state(UIState.GAMEPLAY)
		
		if event.is_action_pressed("debug_show_notification"):
			show_notification("Test notification Terry Pratchett!", NotificationType.INFO)
		
		if event.is_action_pressed("debug_show_dialogue"):
			show_dialogue_interface("debug_npc", "debug_dialogue")

func print_ui_debug_info() -> void:
	"""Affiche les informations de debug UI"""
	print("=== UIManager DEBUG ===")
	print("État actuel:", current_ui_state)
	print("En transition:", is_transitioning)
	print("Panneaux actifs:", active_panels)
	print("Résolution:", current_resolution)
	print("Facteur d'échelle:", ui_scaling_factor)
	print("Sous-systèmes:", {
		"dialogue_ui": dialogue_ui != null,
		"observation_ui": observation_ui != null,
		"magic_ui": magic_ui != null,
		"menu_ui": menu_ui != null,
		"notification_system": notification_system != null,
		"accessibility_manager": accessibility_manager != null,
		"animation_controller": animation_controller != null
	})

# ============================================================================
# NOTES DE DÉVELOPPEMENT
# ============================================================================

## TODO PRIORITAIRES PHASE 2:
## 1. Implémentation des sous-classes DialogueUI, ObservationUI, etc.
## 2. Configuration JSON complète (ui_config.json, accessibility_config.json)
## 3. Système d'animations fluides avec particules magiques
## 4. Tests d'accessibilité complets sur différentes plateformes
## 5. Intégration avec SaveSystem pour persistance des paramètres
## 6. Optimisation performance pour 60 FPS constant
## 7. Support multi-langues avec textes externalisés
## 8. Tests sur différentes résolutions et aspect ratios
