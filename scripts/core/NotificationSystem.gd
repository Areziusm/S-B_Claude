# ============================================================================
# 📢 NotificationSystem.gd - Système Notifications et Tutoriels
# ============================================================================
# STATUS: ✅ COMPLET | Sous-système UIManager
# PRIORITY: 🟠 P2 - Feedback utilisateur et guidage
# DEPENDENCIES: UIManager

class_name NotificationSystem
extends Control

## Système de notifications et tutoriels pour "Sortilèges & Bestioles"
## Feedback utilisateur Terry Pratchett avec style et humour
## Support accessibilité et guidage progressif

# ============================================================================
# SIGNAUX
# ============================================================================

signal notification_displayed(notification_id: String, message: String, type: String)
signal notification_dismissed(notification_id: String, duration: float)
signal tutorial_started(tutorial_id: String)
signal tutorial_completed(tutorial_id: String, steps_completed: int)
signal help_context_requested(context: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

var notification_config: Dictionary = {}
var active_notifications: Array[Dictionary] = []
var notification_queue: Array[Dictionary] = []
var tutorial_progress: Dictionary = {}
var max_simultaneous: int = 3
var notification_counter: int = 0

# ============================================================================
# ÉLÉMENTS UI PRINCIPAUX
# ============================================================================

## Conteneur principal notifications
@onready var notification_container: Control
@onready var notification_stack: VBoxContainer
@onready var tutorial_overlay: Control
@onready var help_tooltip: Control

## Styles de notifications
@onready var notification_templates: Dictionary = {}

## Tutoriels interactifs
@onready var tutorial_panel: Control
@onready var tutorial_content: RichTextLabel
@onready var tutorial_navigation: Control
@onready var tutorial_pointer: Control

# ============================================================================
# TYPES & ENUMS
# ============================================================================

enum NotificationType {
	INFO = 0,           ## Information générale
	SUCCESS = 1,        ## Succès/réussite
	WARNING = 2,        ## Avertissement
	ERROR = 3,          ## Erreur système
	TUTORIAL = 4,       ## Conseil/tutoriel
	ACHIEVEMENT = 5,    ## Réussite débloquée
	LORE = 6,          ## Information Terry Pratchett
	MAGIC = 7           ## Événement magique
}

enum NotificationPosition {
	TOP_LEFT = 0,
	TOP_CENTER = 1,
	TOP_RIGHT = 2,
	BOTTOM_LEFT = 3,
	BOTTOM_CENTER = 4,
	BOTTOM_RIGHT = 5,
	CENTER = 6
}

enum TutorialStepType {
	TEXT_ONLY = 0,      ## Texte simple
	POINTER = 1,        ## Pointeur vers élément
	INTERACTION = 2,    ## Attendre interaction
	OVERLAY = 3,        ## Overlay explicatif
	MINI_GAME = 4       ## Mini-jeu tutoriel
}

# ============================================================================
# INITIALISATION
# ============================================================================

func initialize(parent_container: Control, config: Dictionary) -> void:
	"""Initialise le système de notifications"""
	notification_config = config
	
	# Créer l'interface notifications
	create_notification_interface(parent_container)
	setup_notification_templates()
	load_tutorial_data()
	
	print("📢 NotificationSystem: Système initialisé")

func create_notification_interface(parent: Control) -> void:
	"""Crée l'interface complète des notifications"""
	# Conteneur principal
	notification_container = Control.new()
	notification_container.name = "NotificationContainer"
	notification_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	notification_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Passer les clics
	parent.add_child(notification_container)
	
	# Stack des notifications
	var position = notification_config.get("position", "top_right")
	create_notification_stack(position)
	
	# Overlay tutoriels
	create_tutorial_overlay()
	
	# Tooltip aide contextuelle
	create_help_tooltip()

func create_notification_stack(position: String) -> void:
	"""Crée la pile de notifications"""
	notification_stack = VBoxContainer.new()
	notification_stack.name = "NotificationStack"
	notification_stack.custom_minimum_size = Vector2(350, 0)
	
	# Position selon configuration
	match position:
		"top_right":
			notification_stack.anchors_preset = Control.PRESET_TOP_RIGHT
			notification_stack.offset_left = -370
			notification_stack.offset_top = 20
		"top_left":
			notification_stack.anchors_preset = Control.PRESET_TOP_LEFT
			notification_stack.offset_left = 20
			notification_stack.offset_top = 20
		"bottom_right":
			notification_stack.anchors_preset = Control.PRESET_BOTTOM_RIGHT
			notification_stack.offset_left = -370
			notification_stack.offset_bottom = -20
		"bottom_left":
			notification_stack.anchors_preset = Control.PRESET_BOTTOM_LEFT
			notification_stack.offset_left = 20
			notification_stack.offset_bottom = -20
	
	notification_container.add_child(notification_stack)

func create_tutorial_overlay() -> void:
	"""Crée l'overlay des tutoriels"""
	tutorial_overlay = Control.new()
	tutorial_overlay.name = "TutorialOverlay"
	tutorial_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	tutorial_overlay.hide()
	notification_container.add_child(tutorial_overlay)
	
	# Background semi-transparent
	var tutorial_bg = ColorRect.new()
	tutorial_bg.color = Color(0.0, 0.0, 0.0, 0.6)
	tutorial_bg.anchors_preset = Control.PRESET_FULL_RECT
	tutorial_overlay.add_child(tutorial_bg)
	
	# Panel tutoriel principal
	tutorial_panel = Control.new()
	tutorial_panel.name = "TutorialPanel"
	tutorial_panel.anchors_preset = Control.PRESET_CENTER
	tutorial_panel.custom_minimum_size = Vector2(600, 400)
	tutorial_overlay.add_child(tutorial_panel)
	
	# Background panel tutoriel
	var panel_bg = NinePatchRect.new()
	panel_bg.texture = load("res://ui/textures/tutorial_panel_bg.png")
	panel_bg.anchors_preset = Control.PRESET_FULL_RECT
	tutorial_panel.add_child(panel_bg)
	
	# Container contenu tutoriel
	var tutorial_container = VBoxContainer.new()
	tutorial_container.anchors_preset = Control.PRESET_FULL_RECT
	tutorial_container.offset_left = 20
	tutorial_container.offset_right = -20
	tutorial_container.offset_top = 20
	tutorial_container.offset_bottom = -20
	tutorial_panel.add_child(tutorial_container)
	
	# Titre tutoriel
	var tutorial_title = Label.new()
	tutorial_title.name = "TutorialTitle"
	tutorial_title.text = "TUTORIEL"
	tutorial_title.add_theme_font_size_override("font_size", 24)
	tutorial_title.add_theme_color_override("font_color", Color.YELLOW)
	tutorial_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tutorial_container.add_child(tutorial_title)
	
	# Contenu tutoriel
	tutorial_content = RichTextLabel.new()
	tutorial_content.name = "TutorialContent"
	tutorial_content.bbcode_enabled = true
	tutorial_content.fit_content = true
	tutorial_content.custom_minimum_size.y = 250
	tutorial_content.add_theme_color_override("default_color", Color.WHITE)
	tutorial_container.add_child(tutorial_content)
	
	# Navigation tutoriel
	tutorial_navigation = HBoxContainer.new()
	tutorial_navigation.name = "TutorialNavigation"
	tutorial_container.add_child(tutorial_navigation)
	
	var prev_button = Button.new()
	prev_button.text = "◀ Précédent"
	prev_button.pressed.connect(_on_tutorial_previous)
	tutorial_navigation.add_child(prev_button)
	
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tutorial_navigation.add_child(spacer)
	
	var skip_button = Button.new()
	skip_button.text = "Ignorer"
	skip_button.pressed.connect(_on_tutorial_skip)
	tutorial_navigation.add_child(skip_button)
	
	var next_button = Button.new()
	next_button.text = "Suivant ▶"
	next_button.pressed.connect(_on_tutorial_next)
	tutorial_navigation.add_child(next_button)
	
	# Pointeur interactif
	tutorial_pointer = Control.new()
	tutorial_pointer.name = "TutorialPointer"
	tutorial_pointer.custom_minimum_size = Vector2(50, 50)
	tutorial_pointer.hide()
	tutorial_overlay.add_child(tutorial_pointer)
	
	var pointer_texture = TextureRect.new()
	pointer_texture.texture = load("res://ui/textures/tutorial_pointer.png")
	pointer_texture.anchors_preset = Control.PRESET_FULL_RECT
	tutorial_pointer.add_child(pointer_texture)

func create_help_tooltip() -> void:
	"""Crée le tooltip d'aide contextuelle"""
	help_tooltip = Control.new()
	help_tooltip.name = "HelpTooltip"
	help_tooltip.custom_minimum_size = Vector2(250, 100)
	help_tooltip.hide()
	notification_container.add_child(help_tooltip)
	
	# Background tooltip
	var tooltip_bg = NinePatchRect.new()
	tooltip_bg.texture = load("res://ui/textures/help_tooltip_bg.png")
	tooltip_bg.anchors_preset = Control.PRESET_FULL_RECT
	help_tooltip.add_child(tooltip_bg)
	
	# Texte aide
	var help_text = RichTextLabel.new()
	help_text.name = "HelpText"
	help_text.bbcode_enabled = true
	help_text.fit_content = true
	help_text.anchors_preset = Control.PRESET_FULL_RECT
	help_text.offset_left = 10
	help_text.offset_right = -10
	help_text.offset_top = 10
	help_text.offset_bottom = -10
	help_tooltip.add_child(help_text)

func setup_notification_templates() -> void:
	"""Configure les templates de notifications"""
	max_simultaneous = notification_config.get("max_simultaneous", 3)
	
	# Templates par type
	notification_templates = {
		"info": {
			"color": Color(0.2, 0.4, 0.8),
			"icon": "ℹ️",
			"duration": 3.0,
			"sound": "notification_info"
		},
		"success": {
			"color": Color(0.2, 0.8, 0.2),
			"icon": "✅",
			"duration": 4.0,
			"sound": "notification_success"
		},
		"warning": {
			"color": Color(0.8, 0.6, 0.2),
			"icon": "⚠️",
			"duration": 5.0,
			"sound": "notification_warning"
		},
		"error": {
			"color": Color(0.8, 0.2, 0.2),
			"icon": "❌",
			"duration": 6.0,
			"sound": "notification_error"
		},
		"tutorial": {
			"color": Color(0.4, 0.2, 0.8),
			"icon": "💡",
			"duration": 7.0,
			"sound": "notification_tutorial"
		},
		"achievement": {
			"color": Color(0.8, 0.6, 0.0),
			"icon": "🏆",
			"duration": 6.0,
			"sound": "notification_achievement"
		},
		"lore": {
			"color": Color(0.6, 0.4, 0.8),
			"icon": "📜",
			"duration": 8.0,
			"sound": "notification_lore"
		},
		"magic": {
			"color": Color(0.8, 0.4, 1.0),
			"icon": "✨",
			"duration": 5.0,
			"sound": "notification_magic"
		}
	}

# ============================================================================
# GESTION NOTIFICATIONS
# ============================================================================

func show_notification(message: String, type: String = "info", duration: float = 0.0) -> String:
	"""Affiche une notification"""
	var notification_id = "notif_" + str(notification_counter)
	notification_counter += 1
	
	var template = notification_templates.get(type, notification_templates["info"])
	var final_duration = duration if duration > 0.0 else template.duration
	
	var notification_data = {
		"id": notification_id,
		"message": message,
		"type": type,
		"duration": final_duration,
		"template": template,
		"timestamp": Time.get_ticks_msec()
	}
	
	# Ajouter à la queue ou afficher directement
	if active_notifications.size() < max_simultaneous:
		display_notification(notification_data)
	else:
		notification_queue.append(notification_data)
	
	print("📢 Notification: [", type, "] ", message)
	return notification_id

func display_notification(notification_data: Dictionary) -> void:
	"""Affiche une notification à l'écran"""
	var notification_panel = create_notification_panel(notification_data)
	notification_stack.add_child(notification_panel)
	active_notifications.append(notification_data)
	
	# Animation d'apparition
	animate_notification_appearance(notification_panel)
	
	# Programme la suppression automatique
	var duration = notification_data.duration
	get_tree().create_timer(duration).timeout.connect(
		dismiss_notification.bind(notification_data.id)
	)
	
	# Signal d'affichage
	notification_displayed.emit(notification_data.id, notification_data.message, notification_data.type)

func create_notification_panel(notification_data: Dictionary) -> Control:
	"""Crée le panel visuel d'une notification"""
	var panel = Control.new()
	panel.name = "Notification_" + notification_data.id
	panel.custom_minimum_size = Vector2(340, 80)
	
	# Background avec couleur selon type
	var bg = NinePatchRect.new()
	bg.texture = load("res://ui/textures/notification_bg.png")
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.self_modulate = notification_data.template.color
	panel.add_child(bg)
	
	# Container contenu
	var content_container = HBoxContainer.new()
	content_container.anchors_preset = Control.PRESET_FULL_RECT
	content_container.offset_left = 15
	content_container.offset_right = -15
	content_container.offset_top = 10
	content_container.offset_bottom = -10
	panel.add_child(content_container)
	
	# Icône notification
	var icon_label = Label.new()
	icon_label.text = notification_data.template.icon
	icon_label.add_theme_font_size_override("font_size", 24)
	icon_label.custom_minimum_size.x = 40
	icon_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	content_container.add_child(icon_label)
	
	# Container texte
	var text_container = VBoxContainer.new()
	text_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_container.add_child(text_container)
	
	# Message principal
	var message_label = RichTextLabel.new()
	message_label.bbcode_enabled = true
	message_label.fit_content = true
	message_label.text = process_notification_text(notification_data.message, notification_data.type)
	message_label.add_theme_color_override("default_color", Color.WHITE)
	message_label.custom_minimum_size.y = 40
	text_container.add_child(message_label)
	
	# Timestamp ou info supplémentaire
	if notification_data.type in ["achievement", "lore"]:
		var info_label = Label.new()
		info_label.text = get_notification_info(notification_data)
		info_label.add_theme_font_size_override("font_size", 10)
		info_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
		text_container.add_child(info_label)
	
	# Bouton fermeture
	var close_button = Button.new()
	close_button.text = "✕"
	close_button.custom_minimum_size = Vector2(30, 30)
	close_button.flat = true
	close_button.pressed.connect(dismiss_notification.bind(notification_data.id))
	content_container.add_child(close_button)
	
	# Barre de progression temps
	if notification_data.type != "error":  # Pas de timeout pour erreurs
		create_progress_bar(panel, notification_data.duration)
	
	return panel

func create_progress_bar(panel: Control, duration: float) -> void:
	"""Crée la barre de progression de timeout"""
	var progress_bar = ProgressBar.new()
	progress_bar.name = "TimeoutProgress"
	progress_bar.anchors_preset = Control.PRESET_BOTTOM_WIDE
	progress_bar.offset_top = -8
	progress_bar.custom_minimum_size.y = 4
	progress_bar.max_value = 100
	progress_bar.value = 100
	progress_bar.show_percentage = false
	panel.add_child(progress_bar)
	
	# Style barre progression
	var progress_style = StyleBoxFlat.new()
	progress_style.bg_color = Color(1.0, 1.0, 1.0, 0.6)
	progress_bar.add_theme_stylebox_override("fill", progress_style)
	
	# Animation décompte
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 0, duration)

func dismiss_notification(notification_id: String) -> void:
	"""Supprime une notification"""
	var notification_panel = notification_stack.get_node_or_null("Notification_" + notification_id)
	if not notification_panel:
		return
	
	# Animation de sortie
	animate_notification_dismissal(notification_panel)
	
	# Supprimer des actifs
	for i in range(active_notifications.size()):
		if active_notifications[i].id == notification_id:
			var duration = (Time.get_ticks_msec() - active_notifications[i].timestamp) / 1000.0
			notification_dismissed.emit(notification_id, duration)
			active_notifications.remove_at(i)
			break
	
	# Traiter la queue
	process_notification_queue()

func process_notification_queue() -> void:
	"""Traite la queue des notifications en attente"""
	if notification_queue.size() > 0 and active_notifications.size() < max_simultaneous:
		var next_notification = notification_queue.pop_front()
		display_notification(next_notification)

func clear_all_notifications() -> void:
	"""Supprime toutes les notifications"""
	for child in notification_stack.get_children():
		child.queue_free()
	
	active_notifications.clear()
	notification_queue.clear()

# ============================================================================
# SYSTÈME TUTORIELS
# ============================================================================

func show_tutorial(tutorial_id: String, data: Dictionary = {}) -> void:
	"""Affiche un tutoriel interactif"""
	var tutorial_data = get_tutorial_data(tutorial_id)
	if tutorial_data.is_empty():
		print("📢 Tutoriel introuvable: ", tutorial_id)
		return
	
	# Afficher overlay tutoriel
	tutorial_overlay.show()
	
	# Charger contenu
	load_tutorial_content(tutorial_data, data)
	
	# Marquer comme démarré
	tutorial_progress[tutorial_id] = {
		"started": true,
		"current_step": 0,
		"completed": false,
		"start_time": Time.get_ticks_msec()
	}
	
	tutorial_started.emit(tutorial_id)
	print("📢 Tutoriel démarré: ", tutorial_id)

func load_tutorial_content(tutorial_data: Dictionary, context_data: Dictionary) -> void:
	"""Charge le contenu d'un tutoriel"""
	var title = tutorial_data.get("title", "Tutoriel")
	var steps = tutorial_data.get("steps", [])
	
	# Titre
	var title_label = tutorial_panel.get_node("VBoxContainer/TutorialTitle")
	title_label.text = title
	
	# Premier step
	if steps.size() > 0:
		display_tutorial_step(steps[0], context_data)

func display_tutorial_step(step_data: Dictionary, context_data: Dictionary) -> void:
	"""Affiche une étape de tutoriel"""
	var step_type = step_data.get("type", TutorialStepType.TEXT_ONLY)
	var content = step_data.get("content", "Contenu manquant")
	
	# Traitement texte Terry Pratchett
	var processed_content = process_tutorial_text(content, context_data)
	tutorial_content.text = processed_content
	
	# Gestion selon type d'étape
	match step_type:
		TutorialStepType.POINTER:
			show_tutorial_pointer(step_data.get("target", ""))
		TutorialStepType.INTERACTION:
			setup_interaction_tutorial(step_data)
		TutorialStepType.OVERLAY:
			setup_overlay_tutorial(step_data)

func show_tutorial_pointer(target_path: String) -> void:
	"""Affiche un pointeur vers un élément UI"""
	if target_path.is_empty():
		return
	
	var target = get_node_or_null(target_path)
	if not target:
		return
	
	# Position pointeur
	var target_pos = target.global_position + target.size * 0.5
	tutorial_pointer.position = target_pos + Vector2(-25, -60)
	tutorial_pointer.show()
	
	# Animation pulsation
	animate_tutorial_pointer()

func animate_tutorial_pointer() -> void:
	"""Animation du pointeur tutoriel"""
	var tween = create_tween()
	tween.set_loops()
	
	tween.tween_property(tutorial_pointer, "scale", Vector2(1.2, 1.2), 0.5)
	tween.tween_property(tutorial_pointer, "scale", Vector2.ONE, 0.5)

func hide_tutorial() -> void:
	"""Masque le tutoriel"""
	tutorial_overlay.hide()
	tutorial_pointer.hide()

func _on_tutorial_previous() -> void:
	"""Étape précédente du tutoriel"""
	# TODO: Navigation tutoriel
	pass

func _on_tutorial_next() -> void:
	"""Étape suivante du tutoriel"""
	# TODO: Navigation tutoriel
	pass

func _on_tutorial_skip() -> void:
	"""Ignorer le tutoriel"""
	hide_tutorial()

# ============================================================================
# AIDE CONTEXTUELLE
# ============================================================================

func show_context_help(context: String, position: Vector2 = Vector2.ZERO) -> void:
	"""Affiche l'aide contextuelle"""
	var help_text = get_context_help_text(context)
	if help_text.is_empty():
		return
	
	# Position tooltip
	if position == Vector2.ZERO:
		position = get_global_mouse_position()
	
	help_tooltip.position = position + Vector2(10, 10)
	
	# Contenu
	var help_label = help_tooltip.get_node("HelpText")
	help_label.text = help_text
	
	# Afficher
	help_tooltip.show()
	
	# Auto-masquage après délai
	get_tree().create_timer(5.0).timeout.connect(hide_context_help)

func hide_context_help() -> void:
	"""Masque l'aide contextuelle"""
	help_tooltip.hide()

func get_context_help_text(context: String) -> String:
	"""Retourne le texte d'aide selon le contexte"""
	var help_texts = {
		"magic_interface": "[b]Interface Magique[/b]\nUtilisez la molette pour zoomer.\nMaintenez [color=yellow]Shift[/color] pour lancer rapidement.",
		"observation": "[b]Observation[/b]\nRestez immobile près d'une créature.\nPlus vous observez, plus vous découvrez!",
		"dialogue": "[b]Dialogue[/b]\nVos choix ont des conséquences.\n[color=cyan]Bleu[/color] = sorts, [color=yellow]Jaune[/color] = observations.",
		"inventory": "[b]Inventaire[/b]\nGlissez-déposez pour organiser.\nClic droit pour utiliser un objet."
	}
	
	return help_texts.get(context, "[i]Aucune aide disponible pour ce contexte.[/i]")

# ... (tout le reste de ton fichier reste identique)

# ============================================================================  
# TYPES SPÉCIALISÉS NOTIFICATIONS  
# ============================================================================  

func load_tutorial_data() -> void:
	# À compléter : charger les tutoriels depuis un fichier ou ressource
	pass

func animate_notification_appearance(notification_panel: Control) -> void:
	# Animation d'apparition (fade-in, scale, etc.)
	# À compléter plus tard si tu veux une animation personnalisée
	pass

func process_notification_text(message: String, type: String) -> String:
	# Peut ajouter couleur, bbcode, icônes…  
	return message

func get_notification_info(notification_data: Dictionary) -> String:
	# Affiche un timestamp, source, ou info additionnelle pour "achievement"/"lore"
	if notification_data.has("timestamp"):
		var time_str = Time.get_datetime_string_from_unix_time(int(notification_data.timestamp / 1000))
		return "[i]Reçu le %s[/i]" % time_str
	return ""

func animate_notification_dismissal(notification_panel: Control) -> void:
	# Animation de disparition (fade-out, scale, etc.)
	# Tu peux compléter ça plus tard pour l’effet voulu
	notification_panel.queue_free()

func get_tutorial_data(tutorial_id: String) -> Dictionary:
	# À remplacer par ta vraie logique de chargement de tutoriels !
	# Exemple de stub :
	if tutorial_id == "sample":
		return {
			"title": "Tutoriel d'exemple",
			"steps": [
				{ "type": TutorialStepType.TEXT_ONLY, "content": "Bienvenue dans le jeu !" }
			]
		}
	return {}

func process_tutorial_text(content: String, context_data: Dictionary) -> String:
	# Pour appliquer BBCode, remplacer des variables…  
	return content

func setup_interaction_tutorial(step_data: Dictionary) -> void:
	# Prépare l’attente d’une interaction utilisateur
	pass

func setup_overlay_tutorial(step_data: Dictionary) -> void:
	# Affiche un overlay d’explication  
	pass
