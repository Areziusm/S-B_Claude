# ============================================================================
# 📱 UIManager.gd - Gestionnaire Interface Utilisateur
# ============================================================================
# STATUS: ✅ PRODUCTION | VERSION: 1.0
# PRIORITY: 🟠 P2 - Interface cohérente et accessible
# DEPENDENCIES: GameManager, InputManager

class_name UIManager
extends CanvasLayer

## Gestionnaire centralisé de l'interface utilisateur
## Gère tous les écrans, panels, notifications et transitions
## Support complet accessibilité et thèmes Terry Pratchett

# ================================
# SIGNAUX
# ================================
signal ui_initialized()
signal screen_changed(from_screen: String, to_screen: String)
signal panel_opened(panel_name: String)
signal panel_closed(panel_name: String)
signal notification_shown(message: String, type: String)
signal theme_changed(theme_name: String)
signal accessibility_mode_toggled(enabled: bool)

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
	"""Initialisation complète du UIManager"""
	print("📱 UIManager: Initialisation démarrée...")
	
	# Configuration de base
	layer = 100  # UI au-dessus de tout
	name = "UIManager"
	
	# Chargement configuration
	load_ui_configuration()
	
	# Initialisation composants
	await initialize_ui_structure()
	await load_themes()
	await setup_input_handling()
	await setup_accessibility()
	
	# Application thème par défaut
	apply_theme(default_theme)
	
	print("📱 UIManager: Initialisé avec succès")
	ui_initialized.emit()

func initialize_ui_structure() -> void:
	"""Initialise la structure hiérarchique de l'UI"""
	# Container principal
	var main_container = Control.new()
	main_container.name = "MainContainer"
	main_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(main_container)
	
	# Overlay pour transitions
	overlay = ColorRect.new()
	overlay.name = "TransitionOverlay"
	overlay.color = Color.BLACK
	overlay.modulate.a = 0.0
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.add_child(overlay)
	
	# Container pour écrans
	var screen_container = Control.new()
	screen_container.name = "ScreenContainer"
	screen_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	main_container.add_child(screen_container)
	
	# Container pour panels coulissants
	var panel_container = Control.new()
	panel_container.name = "PanelContainer"
	panel_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	panel_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_container.add_child(panel_container)
	
	# Container pour notifications
	notification_container = VBoxContainer.new()
	notification_container.name = "NotificationContainer"
	notification_container.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	notification_container.offset_left = -300
	notification_container.offset_top = 20
	notification_container.custom_minimum_size = Vector2(280, 0)
	main_container.add_child(notification_container)
	
	# Système de tooltips
	tooltip_system = preload("res://scenes/ui/TooltipSystem.tscn").instantiate()
	main_container.add_child(tooltip_system)
	
	await get_tree().process_frame

# ================================
# GESTION D'ÉCRANS
# ================================
func change_screen(new_screen: UIScreen, transition_type: String = "fade") -> void:
	"""Change d'écran avec transition fluide"""
	if is_transitioning:
		print("📱 UIManager: Transition en cours, changement ignoré")
		return
	
	var old_screen = current_screen
	print("📱 UIManager: Changement d'écran ", UIScreen.keys()[old_screen], " → ", UIScreen.keys()[new_screen])
	
	is_transitioning = true
	
	# Transition de sortie
	await start_transition(transition_type)
	
	# Masquer ancien écran
	if old_screen != UIScreen.NONE:
		hide_screen(old_screen)
	
	# Afficher nouveau écran
	previous_screen = current_screen
	current_screen = new_screen
	
	if new_screen != UIScreen.NONE:
		show_screen(new_screen)
	
	# Transition d'entrée
	await complete_transition()
	
	is_transitioning = false
	screen_changed.emit(UIScreen.keys()[old_screen], UIScreen.keys()[new_screen])

func show_screen(screen: UIScreen) -> void:
	"""Affiche un écran spécifique"""
	var screen_name = UIScreen.keys()[screen].to_lower()
	
	# Chargement paresseux de l'écran
	if not screens.has(screen_name):
		load_screen(screen_name)
	
	if screens.has(screen_name):
		screens[screen_name].visible = true
		screens[screen_name].modulate.a = 0.0
		
		# Animation d'apparition
		var tween = create_tween()
		tween.tween_property(screens[screen_name], "modulate:a", 1.0, transition_speed)

func hide_screen(screen: UIScreen) -> void:
	"""Cache un écran spécifique"""
	var screen_name = UIScreen.keys()[screen].to_lower()
	
	if screens.has(screen_name) and screens[screen_name].visible:
		# Animation de disparition
		var tween = create_tween()
		tween.tween_property(screens[screen_name], "modulate:a", 0.0, transition_speed)
		await tween.finished
		screens[screen_name].visible = false

func load_screen(screen_name: String) -> void:
	"""Charge un écran depuis les ressources"""
	var screen_path = "res://scenes/ui/screens/" + screen_name + "_screen.tscn"
	
	if ResourceLoader.exists(screen_path):
		var screen_scene = load(screen_path)
		var screen_instance = screen_scene.instantiate()
		screen_instance.name = screen_name.capitalize() + "Screen"
		get_node("MainContainer/ScreenContainer").add_child(screen_instance)
		screens[screen_name] = screen_instance
		print("📱 UIManager: Écran chargé: ", screen_name)
	else:
		print("📱 UIManager: Écran non trouvé: ", screen_path)

# ================================
# GESTION PANELS
# ================================
func toggle_panel(panel_name: String) -> void:
	"""Affiche/Cache un panel coulissant"""
	if is_panel_open(panel_name):
		close_panel(panel_name)
	else:
		open_panel(panel_name)

func open_panel(panel_name: String) -> void:
	"""Ouvre un panel avec animation coulissante"""
	if is_panel_open(panel_name):
		return
	
	# Chargement paresseux du panel
	if not panels.has(panel_name):
		load_panel(panel_name)
	
	if panels.has(panel_name):
		var panel = panels[panel_name]
		panel.visible = true
		active_panels.append(panel_name)
		
		# Animation coulissante selon le type de panel
		animate_panel_open(panel, panel_name)
		
		panel_opened.emit(panel_name)
		print("📱 UIManager: Panel ouvert: ", panel_name)

func close_panel(panel_name: String) -> void:
	"""Ferme un panel avec animation"""
	if not is_panel_open(panel_name):
		return
	
	if panels.has(panel_name):
		var panel = panels[panel_name]
		
		# Animation de fermeture
		await animate_panel_close(panel, panel_name)
		
		panel.visible = false
		active_panels.erase(panel_name)
		
		panel_closed.emit(panel_name)
		print("📱 UIManager: Panel fermé: ", panel_name)

func is_panel_open(panel_name: String) -> bool:
	"""Vérifie si un panel est ouvert"""
	return panel_name in active_panels

func load_panel(panel_name: String) -> void:
	"""Charge un panel depuis les ressources"""
	var panel_path = "res://scenes/ui/panels/" + panel_name + "_panel.tscn"
	
	if ResourceLoader.exists(panel_path):
		var panel_scene = load(panel_path)
		var panel_instance = panel_scene.instantiate()
		panel_instance.name = panel_name.capitalize() + "Panel"
		get_node("MainContainer/PanelContainer").add_child(panel_instance)
		panels[panel_name] = panel_instance
		
		# Configuration initiale du panel
		setup_panel(panel_instance, panel_name)
		print("📱 UIManager: Panel chargé: ", panel_name)
	else:
		print("📱 UIManager: Panel non trouvé: ", panel_path)

func setup_panel(panel: Control, panel_name: String) -> void:
	"""Configure un panel après chargement"""
	panel.visible = false
	
	# Position initiale selon le type
	match panel_name:
		"inventory":
			panel.position.x = -panel.size.x
		"journal":
			panel.position.y = -panel.size.y
		"notebook":
			panel.position.x = get_viewport().size.x
		_:
			panel.modulate.a = 0.0

func animate_panel_open(panel: Control, panel_name: String) -> void:
	"""Anime l'ouverture d'un panel"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	match panel_name:
		"inventory":
			tween.tween_property(panel, "position:x", 0, transition_speed)
		"journal":
			tween.tween_property(panel, "position:y", 0, transition_speed)
		"notebook":
			tween.tween_property(panel, "position:x", get_viewport().size.x - panel.size.x, transition_speed)
		_:
			tween.tween_property(panel, "modulate:a", 1.0, transition_speed)

func animate_panel_close(panel: Control, panel_name: String) -> void:
	"""Anime la fermeture d'un panel"""
	var tween = create_tween()
	tween.set_parallel(true)
	
	match panel_name:
		"inventory":
			tween.tween_property(panel, "position:x", -panel.size.x, transition_speed)
		"journal":
			tween.tween_property(panel, "position:y", -panel.size.y, transition_speed)
		"notebook":
			tween.tween_property(panel, "position:x", get_viewport().size.x, transition_speed)
		_:
			tween.tween_property(panel, "modulate:a", 0.0, transition_speed)
	
	await tween.finished

# ================================
# SYSTÈME DE NOTIFICATIONS
# ================================
func show_notification(message: String, type: NotificationType = NotificationType.INFO, duration: float = -1) -> void:
	"""Affiche une notification contextuelle"""
	if duration < 0:
		duration = notification_duration
	
	var notification_data = {
		"message": message,
		"type": type,
		"duration": duration,
		"timestamp": Time.get_ticks_msec()
	}
	
	notification_queue.append(notification_data)
	process_notification_queue()
	
	notification_shown.emit(message, NotificationType.keys()[type])

func process_notification_queue() -> void:
	"""Traite la queue des notifications"""
	if notification_queue.is_empty():
		return
	
	var notification_data = notification_queue.pop_front()
	create_notification_ui(notification_data)

func create_notification_ui(data: Dictionary) -> void:
	"""Crée l'UI d'une notification"""
	var notification = preload("res://scenes/ui/components/NotificationBox.tscn").instantiate()
	
	# Configuration du message
	notification.get_node("MessageLabel").text = data.message
	
	# Style selon le type
	apply_notification_style(notification, data.type)
	
	# Ajout au container
	notification_container.add_child(notification)
	
	# Animation d'apparition
	notification.modulate.a = 0.0
	notification.position.x = 300
	
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(notification, "modulate:a", 1.0, 0.3)
	tween.tween_property(notification, "position:x", 0, 0.3)
	
	# Suppression automatique
	get_tree().create_timer(data.duration).timeout.connect(
		func(): remove_notification(notification)
	)

func apply_notification_style(notification: Control, type: NotificationType) -> void:
	"""Applique le style selon le type de notification"""
	var bg_panel = notification.get_node("Background")
	var icon = notification.get_node("Icon")
	
	match type:
		NotificationType.INFO:
			bg_panel.modulate = Color.BLUE * 0.8
			icon.texture = load("res://assets/ui/icons/info.png")
		NotificationType.SUCCESS:
			bg_panel.modulate = Color.GREEN * 0.8
			icon.texture = load("res://assets/ui/icons/success.png")
		NotificationType.WARNING:
			bg_panel.modulate = Color.ORANGE * 0.8
			icon.texture = load("res://assets/ui/icons/warning.png")
		NotificationType.ERROR:
			bg_panel.modulate = Color.RED * 0.8
			icon.texture = load("res://assets/ui/icons/error.png")
		NotificationType.MAGICAL:
			bg_panel.modulate = Color.MAGENTA * 0.8
			icon.texture = load("res://assets/ui/icons/magic.png")
			# Effet de particules pour notifications magiques
			add_magical_particles(notification)

func remove_notification(notification: Control) -> void:
	"""Supprime une notification avec animation"""
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(notification, "modulate:a", 0.0, 0.3)
	tween.tween_property(notification, "position:x", 300, 0.3)
	
	await tween.finished
	notification.queue_free()

func add_magical_particles(notification: Control) -> void:
	"""Ajoute des particules magiques à une notification"""
	var particles = preload("res://scenes/effects/MagicalParticles.tscn").instantiate()
	notification.add_child(particles)
	particles.emitting = true

# ================================
# GESTION THÈMES
# ================================
func load_themes() -> void:
	"""Charge tous les thèmes UI disponibles"""
	themes = {
		UITheme.DEFAULT: load("res://data/ui_themes/default_theme.tres"),
		UITheme.NIGHT: load("res://data/ui_themes/night_theme.tres"),
		UITheme.AUTUMN: load("res://data/ui_themes/autumn_theme.tres"),
		UITheme.WINTER: load("res://data/ui_themes/winter_theme.tres"),
		UITheme.SPRING: load("res://data/ui_themes/spring_theme.tres"),
		UITheme.SUMMER: load("res://data/ui_themes/summer_theme.tres"),
		UITheme.UNSEEN_UNIVERSITY: load("res://data/ui_themes/uu_theme.tres"),
		UITheme.PATRICIAN_PALACE: load("res://data/ui_themes/palace_theme.tres")
	}

func apply_theme(theme: UITheme) -> void:
	"""Applique un thème UI"""
	if not themes.has(theme):
		print("📱 UIManager: Thème non trouvé: ", UITheme.keys()[theme])
		return
	
	current_theme = theme
	var theme_resource = themes[theme]
	
	# Application du thème à tous les composants
	apply_theme_to_node(self, theme_resource)
	
	theme_changed.emit(UITheme.keys()[theme])
	print("📱 UIManager: Thème appliqué: ", UITheme.keys()[theme])

func apply_theme_to_node(node: Node, theme_resource: Theme) -> void:
	"""Applique récursivement un thème à un nœud et ses enfants"""
	if node is Control:
		node.theme = theme_resource
	
	for child in node.get_children():
		apply_theme_to_node(child, theme_resource)

# ================================
# ACCESSIBILITÉ
# ================================
func setup_accessibility() -> void:
	"""Configure les options d'accessibilité"""
	if accessibility_mode:
		enable_accessibility_features()

func toggle_accessibility_mode() -> void:
	"""Active/désactive le mode accessibilité"""
	accessibility_mode = !accessibility_mode
	
	if accessibility_mode:
		enable_accessibility_features()
	else:
		disable_accessibility_features()
	
	accessibility_mode_toggled.emit(accessibility_mode)

func enable_accessibility_features() -> void:
	"""Active les fonctionnalités d'accessibilité"""
	# Augmentation taille des textes
	ui_config.font_size = ui_config.font_size * 1.25
	
	# Contraste élevé
	ui_config.contrast_mode = true
	
	# Animations réduites
	ui_config.animation_speed = 0.5
	
	# Support daltonisme
	if ui_config.colorblind_mode:
		apply_colorblind_filters()
	
	print("📱 UIManager: Mode accessibilité activé")

func disable_accessibility_features() -> void:
	"""Désactive les fonctionnalités d'accessibilité"""
	# Restauration tailles normales
	ui_config.font_size = 16
	ui_config.contrast_mode = false
	ui_config.animation_speed = 1.0
	
	remove_colorblind_filters()
	
	print("📱 UIManager: Mode accessibilité désactivé")

func apply_colorblind_filters() -> void:
	"""Applique les filtres pour daltonisme"""
	# TODO: Implémenter filtres de couleur
	pass

func remove_colorblind_filters() -> void:
	"""Supprime les filtres pour daltonisme"""
	# TODO: Supprimer filtres de couleur
	pass

# ================================
# GESTION INPUT
# ================================
func setup_input_handling() -> void:
	"""Configure la gestion des inputs UI"""
	# Configuration des raccourcis par défaut
	var input_map = {
		"ui_inventory": "toggle_panel('inventory')",
		"ui_journal": "toggle_panel('journal')",
		"ui_notebook": "toggle_panel('notebook')",
		"ui_pause": "toggle_pause_menu()",
		"ui_settings": "change_screen(UIScreen.SETTINGS)"
	}
	
	# TODO: Implémenter système de raccourcis configurables

func _input(event: InputEvent) -> void:
	"""Gestion globale des inputs UI"""
	if event.is_action_pressed("ui_cancel") and not active_panels.is_empty():
		# Fermer le dernier panel ouvert
		close_panel(active_panels[-1])
		get_viewport().set_input_as_handled()

# ================================
# TRANSITIONS
# ================================
func start_transition(transition_type: String) -> void:
	"""Démarre une transition d'écran"""
	match transition_type:
		"fade":
			await fade_transition_in()
		"slide_left":
			await slide_transition("left")
		"slide_right":
			await slide_transition("right")
		"magical":
			await magical_transition_in()
		_:
			await fade_transition_in()

func complete_transition() -> void:
	"""Termine une transition d'écran"""
	await fade_transition_out()

func fade_transition_in() -> void:
	"""Transition de fondu entrant"""
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 1.0, transition_speed * 0.5)
	await tween.finished

func fade_transition_out() -> void:
	"""Transition de fondu sortant"""
	var tween = create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, transition_speed * 0.5)
	await tween.finished
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

func slide_transition(direction: String) -> void:
	"""Transition glissante"""
	# TODO: Implémenter transitions glissantes
	await fade_transition_in()

func magical_transition_in() -> void:
	"""Transition magique avec effets de particules"""
	# TODO: Implémenter transition magique
	await fade_transition_in()

# ================================
# CONFIGURATION
# ================================
func load_ui_configuration() -> void:
	"""Charge la configuration UI depuis le fichier"""
	var config_path = "user://ui_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		
		if parse_result == OK:
			ui_config.merge(json.data)
			print("📱 UIManager: Configuration chargée")

func save_ui_configuration() -> void:
	"""Sauvegarde la configuration UI"""
	var config_path = "user://ui_config.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	var json_text = JSON.stringify(ui_config)
	file.store_string(json_text)
	file.close()
	print("📱 UIManager: Configuration sauvegardée")

# ================================
# MÉTHODES PUBLIQUES UTILITAIRES
# ================================
func toggle_pause_menu() -> void:
	"""Active/désactive le menu pause"""
	if current_screen == UIScreen.PAUSE_MENU:
		change_screen(previous_screen)
	else:
		change_screen(UIScreen.PAUSE_MENU)

func show_loading_screen(message: String = "Chargement...") -> void:
	"""Affiche l'écran de chargement"""
	change_screen(UIScreen.LOADING)
	# TODO: Mettre à jour le message de chargement

func hide_loading_screen() -> void:
	"""Cache l'écran de chargement"""
	change_screen(UIScreen.GAME_HUD)

func show_tooltip(text: String, position: Vector2) -> void:
	"""Affiche un tooltip à la position donnée"""
	if tooltip_system:
		tooltip_system.call("show_tooltip", text, position)

func hide_tooltip() -> void:
	"""Cache le tooltip actuel"""
	if tooltip_system:
		tooltip_system.call("hide_tooltip")

func is_ui_blocking_input() -> bool:
	"""Vérifie si l'UI bloque les inputs du jeu"""
	return current_screen in [UIScreen.PAUSE_MENU, UIScreen.SETTINGS, UIScreen.DIALOGUE] or not active_panels.is_empty()

func get_current_screen_name() -> String:
	"""Retourne le nom de l'écran actuel"""
	return UIScreen.keys()[current_screen]

func force_close_all_panels() -> void:
	"""Force la fermeture de tous les panels"""
	for panel_name in active_panels.duplicate():
		close_panel(panel_name)

# ================================
# DÉBOGAGE
# ================================
func _on_debug_key_pressed() -> void:
	"""Fonction de débogage pour tester l'UI"""
	if OS.is_debug_build():
		print("📱 UIManager Debug:")
		print("  - Écran actuel: ", UIScreen.keys()[current_screen])
		print("  - Panels actifs: ", active_panels)
		print("  - Notifications en queue: ", notification_queue.size())
		print("  - Mode accessibilité: ", accessibility_mode)
