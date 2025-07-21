# ============================================================================
# 📱 UIManager.gd - Gestionnaire Interface Utilisateur Complet
# ============================================================================

class_name UIManager
extends CanvasLayer

# ============================================================================
# SIGNAUX - Communication Event-Driven
# ============================================================================
signal ui_element_shown(element_name: String, data: Dictionary)
signal ui_element_hidden(element_name: String)
signal ui_state_changed(old_state: String, new_state: String)
signal ui_settings_changed(setting_type: String, new_value)
signal notification_displayed(message: String, type: String, duration: float)
signal user_interaction(interaction_type: String, target: String, data: Dictionary)
signal manager_initialized()

# ============================================================================
# CONFIGURATION & PARAMÈTRES
# ============================================================================
@export var ui_config_path: String = "res://data/ui_config.json"
@export var accessibility_config_path: String = "res://data/accessibility_config.json"
@export var animation_config_path: String = "res://data/animation_config.json"

var ui_config: Dictionary = {}
var accessibility_settings: Dictionary = {}
var animation_settings: Dictionary = {}
var current_resolution: Vector2i
var base_resolution: Vector2i = Vector2i(1920, 1080)
var ui_scaling_factor: float = 1.0

# État UI général
var current_ui_state: UIState = UIState.MENU
var previous_ui_state: UIState = UIState.MENU
var is_transitioning: bool = false
var active_panels: Array[String] = []

# Sous-systèmes UI
var dialogue_ui
var observation_ui
var magic_ui
var menu_ui
var notification_system
var accessibility_manager
var animation_controller

# Conteneurs principaux
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
	MENU = 0,
	GAMEPLAY = 1,
	DIALOGUE = 2,
	OBSERVATION = 3,
	MAGIC_CASTING = 4,
	INVENTORY = 5,
	SETTINGS = 6,
	TRANSITION = 7
}
enum NotificationType {
	INFO = 0,
	SUCCESS = 1,
	WARNING = 2,
	ERROR = 3,
	TUTORIAL = 4
}
enum AccessibilityMode {
	NONE = 0,
	COLORBLIND = 1,
	LOW_VISION = 2,
	MOTOR_IMPAIRED = 3,
	COGNITIVE = 4
}
enum UIScreen {
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

@export var default_theme: UITheme = UITheme.DEFAULT
@export var notification_duration: float = 3.0
@export var transition_speed: float = 0.3
@export var accessibility_mode: bool = false

# État du UI avancé
var current_screen: UIScreen = UIScreen.MAIN_MENU
var previous_screen: UIScreen = UIScreen.MAIN_MENU
var notification_queue: Array[Dictionary] = []

# Références aux composants UI avancé
var screens: Dictionary = {}
var panels: Dictionary = {}
var hud_elements: Dictionary = {}
var overlay: ColorRect
var tooltip_system: Control

# Thèmes
var themes: Dictionary = {}
var current_theme: UITheme = UITheme.DEFAULT

# ============================================================================
# INITIALISATION
# ============================================================================
func _ready() -> void:
	print("📱 UIManager: Initialisation démarrée...")
	setup_base_configuration()
	load_ui_configuration()
	setup_resolution_handling()
	create_ui_containers()
	await initialize_subsystems()
	setup_accessibility()
	connect_to_game_systems()
	transition_to_state(UIState.MENU)
	print("📱 UIManager: Initialisation terminée")
	manager_initialized.emit()

func setup_base_configuration() -> void:
	current_resolution = get_viewport().get_visible_rect().size
	ui_scaling_factor = float(current_resolution.x) / float(base_resolution.x)
	var has_touch = Input.get_connected_joypads().size() == 0 and DisplayServer.screen_get_dpi() > 200
	print("📱 Résolution détectée: ", current_resolution)
	print("📱 Facteur d'échelle UI: ", ui_scaling_factor)

func load_ui_configuration() -> void:
	ui_config = load_json_file(ui_config_path)
	if ui_config.is_empty():
		ui_config = get_default_ui_config()
	accessibility_settings = load_json_file(accessibility_config_path)
	if accessibility_settings.is_empty():
		accessibility_settings = get_default_accessibility_config()
	animation_settings = load_json_file(animation_config_path)
	if animation_settings.is_empty():
		animation_settings = get_default_animation_config()
	print("📱 Configuration UI chargée")

func create_ui_containers() -> void:
	if not main_container:
		main_container = Control.new()
		main_container.name = "MainContainer"
		main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(main_container)
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
	get_viewport().size_changed.connect(_on_viewport_resized)
	get_tree().set_screen_stretch(
		Window.CONTENT_SCALE_MODE_CANVAS_ITEMS,
		Window.CONTENT_SCALE_ASPECT_KEEP,
		base_resolution
	)

# ============================================================================
# INITIALISATION SOUS-SYSTÈMES
# ============================================================================
func initialize_subsystems() -> void:
	print("📱 Initialisation des sous-systèmes UI...")
	dialogue_ui = DialogueUI.new()
	dialogue_ui.initialize(dialogue_container, ui_config.get("dialogue", {}))
	dialogue_ui.dialogue_choice_selected.connect(_on_dialogue_choice_selected)
	dialogue_ui.dialogue_ended.connect(_on_dialogue_ended)
	observation_ui = ObservationUI.new()
	observation_ui.initialize(overlay_container, ui_config.get("observation", {}))
	observation_ui.creature_observed.connect(_on_creature_observed)
	observation_ui.notebook_page_changed.connect(_on_notebook_page_changed)
	magic_ui = MagicUI.new()
	magic_ui.initialize(overlay_container, ui_config.get("magic", {}))
	magic_ui.spell_cast_requested.connect(_on_spell_cast_requested)
	magic_ui.octarine_chaos_triggered.connect(_on_octarine_chaos)
	menu_ui = MenuUI.new()
	menu_ui.initialize(menu_container, ui_config.get("menus", {}))
	menu_ui.menu_action_selected.connect(_on_menu_action_selected)
	menu_ui.settings_changed.connect(_on_ui_settings_changed)
	notification_system = NotificationSystem.new()
	notification_system.initialize(notification_container, ui_config.get("notifications", {}))
	notification_system.notification_dismissed.connect(_on_notification_dismissed)
	accessibility_manager = AccessibilityManager.new()
	accessibility_manager.initialize(main_container, accessibility_settings)
	accessibility_manager.accessibility_mode_changed.connect(_on_accessibility_changed)
	animation_controller = UIAnimationController.new()
	animation_controller.initialize(main_container, animation_settings)
	animation_controller.animation_completed.connect(_on_animation_completed)
	print("📱 Sous-systèmes UI initialisés")

func _on_notebook_page_changed(page_id: String, data: Dictionary = {}) -> void:
	pass

func setup_accessibility() -> void:
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
# GESTION ÉTATS UI (FONCTIONS MANQUANTES)
# ============================================================================
func transition_to_state(new_state: UIState, data: Dictionary = {}) -> void:
	if is_transitioning:
		print("📱 Transition déjà en cours, ignorée")
		return
	var old_state_name = UIState.keys()[int(current_ui_state)] if int(current_ui_state) < UIState.size() else "UNKNOWN"
	var new_state_name = UIState.keys()[int(new_state)] if int(new_state) < UIState.size() else "UNKNOWN"
	print("📱 Transition UI: ", old_state_name, " → ", new_state_name)
	is_transitioning = true
	previous_ui_state = current_ui_state
	if animation_controller and animation_controller.has_method("play_transition_out"):
		await animation_controller.play_transition_out(current_ui_state)
	hide_state_elements(current_ui_state)
	current_ui_state = new_state
	show_state_elements(new_state, data)
	if animation_controller and animation_controller.has_method("play_transition_in"):
		await animation_controller.play_transition_in(new_state)
	is_transitioning = false
	ui_state_changed.emit(old_state_name, new_state_name)

func show_state_elements(state: UIState, data: Dictionary = {}) -> void:
	hide_all_containers()
	match state:
		UIState.MENU:
			menu_container.show()
			if menu_ui and menu_ui.has_method("show_main_menu"):
				menu_ui.show_main_menu()
		UIState.GAMEPLAY:
			hud_container.show()
			show_gameplay_hud()
		UIState.DIALOGUE:
			dialogue_container.show()
			hud_container.show()
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
		UIState.SETTINGS:
			menu_container.show()
			if menu_ui and menu_ui.has_method("show_settings_menu"):
				menu_ui.show_settings_menu(data)

func hide_state_elements(state: UIState) -> void:
	match state:
		UIState.DIALOGUE:
			if dialogue_ui and dialogue_ui.has_method("hide_dialogue"):
				dialogue_ui.hide_dialogue()
		UIState.OBSERVATION:
			if observation_ui and observation_ui.has_method("hide_observation_interface"):
				observation_ui.hide_observation_interface()
		UIState.MAGIC_CASTING:
			if magic_ui and magic_ui.has_method("hide_spell_interface"):
				magic_ui.hide_spell_interface()

func hide_all_containers() -> void:
	if dialogue_container:
		dialogue_container.hide()
	if menu_container:
		menu_container.hide()
	if overlay_container:
		overlay_container.hide()
	# notification_container et hud_container restent généralement visibles

# ============================================================================
# INTERFACE GAMEPLAY (HUD)
# ============================================================================
func show_gameplay_hud() -> void:
	pass

func update_health_display(current_health: int, max_health: int) -> void:
	pass

func update_mana_display(current_mana: int, max_mana: int) -> void:
	pass

func update_observation_count(count: int) -> void:
	pass

# ============================================================================
# GESTION NOTIFICATIONS
# ============================================================================
func show_notification(message: String, type: NotificationType = NotificationType.INFO, duration: float = 3.0) -> void:
	var type_name = NotificationType.keys()[int(type)] if int(type) < NotificationType.size() else "INFO"
	notification_system.show_notification(message, type_name, duration)
	notification_displayed.emit(message, type_name, duration)
	print("📱 Notification [", type_name, "]: ", message)

func show_tutorial(tutorial_id: String, data: Dictionary = {}) -> void:
	notification_system.show_tutorial(tutorial_id, data)

# ============================================================================
# GESTION ÉVÉNEMENTS
# ============================================================================
func _on_dialogue_choice_selected(choice_id: String, choice_data: Dictionary) -> void:
	print("📱 Choix dialogue sélectionné: ", choice_id)
	user_interaction.emit("dialogue_choice", choice_id, choice_data)
	var dialogue_manager = get_node_or_null("/root/Dialogue")
	if dialogue_manager and dialogue_manager.has_method("process_choice"):
		dialogue_manager.process_choice(choice_id, choice_data)

func _on_dialogue_ended(npc_id: String, final_choice: String) -> void:
	print("📱 Dialogue terminé avec: ", npc_id)
	transition_to_state(UIState.GAMEPLAY)

func _on_creature_observed(creature_id: String, observation_data: Dictionary) -> void:
	print("📱 Créature observée: ", creature_id)
	user_interaction.emit("creature_observation", creature_id, observation_data)
	var observation_manager = get_node_or_null("/root/Observation")
	if observation_manager and observation_manager.has_method("observe_creature"):
		observation_manager.observe_creature(creature_id, observation_data)

func _on_spell_cast_requested(spell_id: String, target_data: Dictionary) -> void:
	print("📱 Sort demandé: ", spell_id)
	user_interaction.emit("spell_cast", spell_id, target_data)
	# TODO: Transmettre au MagicSystem

func _on_octarine_chaos(chaos_type: String, affected_data: Dictionary) -> void:
	print("📱 Chaos Octarine déclenché: ", chaos_type)
	show_notification("La magie Octarine provoque des effets inattendus!", NotificationType.WARNING, 4.0)

func _on_menu_action_selected(action: String, data: Dictionary) -> void:
	match action:
		"new_game":
			pass
		"load_game":
			pass
		"save_game":
			pass
		"settings":
			transition_to_state(UIState.SETTINGS)
		"quit_game":
			get_tree().quit()

func _on_ui_settings_changed(setting_type: String, new_value) -> void:
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
	print("📱 Mode accessibilité changé: ", AccessibilityMode.keys()[int(mode)])
	accessibility_settings.merge(settings)

func _on_animation_completed(animation_name: String, data: Dictionary) -> void:
	pass

func _on_notification_dismissed(notification_id: String) -> void:
	pass

func _on_viewport_resized() -> void:
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
	if main_container:
		main_container.scale = Vector2.ONE * ui_scaling_factor

func setup_colorblind_support() -> void:
	print("📱 Support daltonisme activé")

func setup_low_vision_support() -> void:
	print("📱 Support malvoyance activé")

func setup_motor_support() -> void:
	print("📱 Support moteur activé")

func setup_cognitive_support() -> void:
	print("📱 Support cognitif activé")

func connect_to_game_systems() -> void:
	var game_manager = get_node_or_null("/root/Game")
	if game_manager:
		if game_manager.has_signal("game_state_changed"):
			game_manager.game_state_changed.connect(_on_game_state_changed)
	var observation_manager = get_node_or_null("/root/Observation")
	if observation_manager:
		if observation_manager.has_signal("creature_evolved"):
			observation_manager.creature_evolved.connect(_on_creature_evolved)
	print("🔗 Connexions UIManager établies")

func _on_game_state_changed(old_state: String, new_state: String) -> void:
	match new_state:
		"menu":
			transition_to_state(UIState.MENU)
		"gameplay":
			transition_to_state(UIState.GAMEPLAY)
		"paused":
			if menu_ui and menu_ui.has_method("show_pause_menu"):
				menu_ui.show_pause_menu()

func _on_creature_evolved(creature_id: String, old_stage: int, new_stage: int) -> void:
	show_notification("Une créature a évolué! Consultez votre carnet.", NotificationType.SUCCESS, 5.0)
	observation_ui.highlight_evolved_creature(creature_id)

# ============================================================================
# CONFIGURATIONS PAR DÉFAUT
# ============================================================================
func get_default_ui_config() -> Dictionary:
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
	return {
		"transition_speed": 1.0,
		"easing_type": "ease_out",
		"particle_effects": true,
		"screen_shake": true,
			"ui_bounce": true
	}

func load_json_file(path: String) -> Dictionary:
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
func show_dialogue_interface(npc_id: String, dialogue_id: String) -> void:
	transition_to_state(UIState.DIALOGUE, {"npc_id": npc_id, "dialogue_id": dialogue_id})

func show_observation_interface(creature_id: String = "") -> void:
	transition_to_state(UIState.OBSERVATION, {"creature_id": creature_id})

func show_magic_interface(spell_context: Dictionary = {}) -> void:
	transition_to_state(UIState.MAGIC_CASTING, spell_context)

func force_hide_all_ui() -> void:
	hide_all_containers()
	hud_container.hide()
	notification_container.hide()

func restore_ui_from_hide() -> void:
	transition_to_state(UIState.GAMEPLAY)
	notification_container.show()

func is_ui_blocking_input() -> bool:
	return (
		current_ui_state == UIState.DIALOGUE
		or current_ui_state == UIState.MENU
		or current_ui_state == UIState.SETTINGS
		or is_transitioning
	)

# ============================================================================
# DEBUG & DÉVELOPPEMENT
# ============================================================================
func _input(event: InputEvent) -> void:
	if OS.is_debug_build():
		if event.is_action_pressed("ui_cancel"):
			if current_ui_state == UIState.GAMEPLAY:
				transition_to_state(UIState.MENU)
			elif current_ui_state == UIState.MENU:
				transition_to_state(UIState.GAMEPLAY)
		if event.is_action_pressed("debug_show_notification"):
			show_notification("Test notification Terry Pratchett!", NotificationType.INFO)
		if event.is_action_pressed("debug_show_dialogue"):
			show_dialogue_interface("debug_npc", "debug_dialogue")

func print_ui_debug_info() -> void:
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
# TODO PHASE 2: Implémentation sous-classes, configurations JSON, animations, accessibilité, sauvegarde, optimisation.

# 1. Implémentation des sous-classes DialogueUI, ObservationUI, etc.
# 2. Configuration JSON complète (ui_config.json, accessibility_config.json)
# 3. Système d'animations fluides avec particules magiques
# 4. Tests d'accessibilité complets sur différentes plateformes
# 5. Intégration avec SaveSystem pour persistance des paramètres
# 6. Optimisation performance pour 60 FPS constant
# 7. Support multi-langues avec textes externalisés
# 8. Tests sur différentes résolutions et aspect ratios
