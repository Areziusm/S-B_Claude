# ============================================================================
# 📢 NotificationUI.gd - Système Notifications et Tutoriels
# ============================================================================
# STATUS: 🟢 NOUVEAU | ROADMAP: Mois 1, Semaine 3-4 - UI Architecture
# PRIORITY: 🟠 P2 - Feedback utilisateur et apprentissage progressif
# DEPENDENCIES: UIManager, GameManager

class_name NotificationUI
extends Control

## Système de notifications et tutoriels intégré
## Support pour messages temporaires, tutoriels interactifs, et feedback
## Design Terry Pratchett avec humour et accessibilité

# ============================================================================
# SIGNAUX
# ============================================================================

## Émis quand une notification est affichée
signal notification_shown(notification_id: String, type: String)

## Émis quand une notification est fermée
signal notification_closed(notification_id: String, user_dismissed: bool)

## Émis quand un tutoriel se termine
signal tutorial_completed(tutorial_id: String)

## Émis quand l'utilisateur demande à ignorer les tutoriels
signal tutorials_disabled()

# ============================================================================
# ÉNUMÉRATIONS
# ============================================================================

enum NotificationType {
	INFO,
	SUCCESS,
	WARNING,
	ERROR,
	TUTORIAL,
	ACHIEVEMENT,
	QUEST,
	MAGIC_EVENT,
	REPUTATION,
	PRATCHETT_HUMOR
}

enum NotificationPosition {
	TOP_LEFT,
	TOP_CENTER,
	TOP_RIGHT,
	CENTER,
	BOTTOM_LEFT,
	BOTTOM_CENTER,
	BOTTOM_RIGHT
}

# ============================================================================
# RÉFÉRENCES UI
# ============================================================================

## Container principal des notifications
@export var notifications_container: VBoxContainer

## Zone des tutoriels interactifs
@export var tutorial_panel: Panel
@export var tutorial_title: Label
@export var tutorial_content: RichTextLabel
@export var tutorial_image: TextureRect
@export var tutorial_next_button: Button
@export var tutorial_skip_button: Button
@export var tutorial_progress: ProgressBar

## Zone des achievements
@export var achievement_popup: Panel
@export var achievement_icon: TextureRect
@export var achievement_title: Label
@export var achievement_description: Label

## Zone messages système
@export var system_message_panel: Panel
@export var system_message_label: RichTextLabel

# ============================================================================
# CONFIGURATION
# ============================================================================

## Configuration par défaut des notifications
var notification_config: Dictionary = {
	"default_duration": 5.0,
	"max_notifications": 5,
	"fade_duration": 0.3,
	"slide_duration": 0.4,
	"achievements_enabled": true,
	"tutorials_enabled": true,
	"sound_enabled": true
}

## Templates des notifications Terry Pratchett
var pratchett_templates: Dictionary = {
	"magic_mishap": [
		"Le sort a quelque peu mal tourné. C'est tout à fait normal.",
		"La magie a décidé d'être créative aujourd'hui.",
		"Octarine + Logique = Résultats imprévisibles. Qui l'eût cru ?",
		"La Magie : Infiniment complexe, ridiculement simple."
	],
	"observation_success": [
		"L'observation attentive révèle des merveilles inattendues.",
		"Regarder vraiment, c'est voir l'invisible devenir évident.",
		"Une créature observée est une créature qui évolue.",
		"La patience de l'observateur fait la richesse du monde."
	],
	"death_encounter": [
		"LA MORT apprécie votre compagnie philosophique.",
		"Discuter avec LA MORT élargit considérablement les perspectives.",
		"LA MORT: Toujours ponctuel, rarement pressé.",
		"Une conversation avec LA MORT vaut tous les livres de philosophie."
	]
}

# ============================================================================
# ÉTAT SYSTÈME
# ============================================================================

## Queue des notifications en attente
var notification_queue: Array = []

## Notifications actuellement affichées
var active_notifications: Array = []

## Tutoriel actuel
var current_tutorial: Dictionary = {}

## Compteur pour IDs uniques
var notification_counter: int = 0

## Paramètres utilisateur
var user_preferences: Dictionary = {
	"notifications_enabled": true,
	"tutorials_enabled": true,
	"achievements_enabled": true,
	"sound_enabled": true,
	"humor_level": 1.0  # 0.0 = sérieux, 1.0 = full Pratchett
}

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	"""Initialisation du système de notifications"""
	print("📢 NotificationUI: Initialisation...")
	
	setup_ui_components()
	load_user_preferences()
	setup_default_styles()
	
	# Tester avec une notification de bienvenue
	if user_preferences.get("tutorials_enabled", true):
		call_deferred("show_welcome_notification")
	
	print("📢 NotificationUI: Système prêt")

func setup_ui_components() -> void:
	"""Configure les composants UI"""
	# Configuration container notifications
	if notifications_container:
		notifications_container.custom_minimum_size = Vector2(300, 0)
	
	# Configuration tutoriel
	if tutorial_panel:
		tutorial_panel.visible = false
	
	# Configuration achievement popup
	if achievement_popup:
		achievement_popup.visible = false
	
	# Connecter les signaux
	connect_tutorial_signals()

func connect_tutorial_signals() -> void:
	"""Connecte les signaux des tutoriels"""
	if tutorial_next_button:
		tutorial_next_button.pressed.connect(_on_tutorial_next_pressed)
	
	if tutorial_skip_button:
		tutorial_skip_button.pressed.connect(_on_tutorial_skip_pressed)

func load_user_preferences() -> void:
	"""Charge les préférences utilisateur"""
	var prefs_path = "user://notification_preferences.json"
	
	if FileAccess.file_exists(prefs_path):
		var file = FileAccess.open(prefs_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				user_preferences.merge(json.data, true)

func setup_default_styles() -> void:
	"""Configure les styles par défaut"""
	# Style Terry Pratchett pour les panneaux
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color.DARK_SLATE_GRAY.lightened(0.1)
	panel_style.border_color = Color.GOLDENROD
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	
	# Appliquer aux panneaux principaux
	for panel in [tutorial_panel, achievement_popup, system_message_panel]:
		if panel:
			panel.add_theme_stylebox_override("panel", panel_style)

# ============================================================================
# API PRINCIPALE NOTIFICATIONS
# ============================================================================

func show_notification(message: String, type: NotificationType = NotificationType.INFO, duration: float = -1.0, data: Dictionary = {}) -> String:
	"""Affiche une notification avec le type spécifié"""
	if not user_preferences.get("notifications_enabled", true):
		return ""
	
	# Générer ID unique
	notification_counter += 1
	var notification_id = "notification_" + str(notification_counter)
	
	# Durée par défaut selon le type
	if duration < 0:
		duration = get_default_duration_for_type(type)
	
	# Créer la notification
	var notification_data = {
		"id": notification_id,
		"message": message,
		"type": type,
		"duration": duration,
		"data": data,
		"created_at": Time.get_ticks_msec()
	}
	
	# Ajouter à la queue
	notification_queue.append(notification_data)
	process_notification_queue()
	
	return notification_id

func show_tutorial(tutorial_id: String, tutorial_data: Dictionary) -> void:
	"""Affiche un tutoriel interactif"""
	if not user_preferences.get("tutorials_enabled", true):
		return
	
	current_tutorial = tutorial_data.duplicate()
	current_tutorial["id"] = tutorial_id
	current_tutorial["current_step"] = 0
	
	display_tutorial_step()

func show_achievement(achievement_id: String, title: String, description: String, icon_path: String = "") -> void:
	"""Affiche un popup d'achievement"""
	if not user_preferences.get("achievements_enabled", true):
		return
	
	if achievement_popup:
		# Configurer le contenu
		if achievement_title:
			achievement_title.text = title
		if achievement_description:
			achievement_description.text = description
		if achievement_icon and icon_path != "" and ResourceLoader.exists(icon_path):
			achievement_icon.texture = load(icon_path)
		
		# Afficher avec animation
		achievement_popup.visible = true
		animate_achievement_popup()
		
		# Auto-masquer après 4 secondes
		await get_tree().create_timer(4.0).timeout
		hide_achievement_popup()

func show_system_message(message: String, is_important: bool = false) -> void:
	"""Affiche un message système persistant"""
	if system_message_panel and system_message_label:
		system_message_label.text = "[center]" + message + "[/center]"
		system_message_panel.visible = true
		
		if is_important:
			# Animation clignotante pour messages importants
			var tween = create_tween()
			tween.set_loops(3)
			tween.tween_property(system_message_panel, "modulate:a", 0.5, 0.5)
			tween.tween_property(system_message_panel, "modulate:a", 1.0, 0.5)

# ============================================================================
# NOTIFICATIONS SPÉCIALISÉES TERRY PRATCHETT
# ============================================================================

func show_pratchett_notification(category: String, custom_message: String = "") -> void:
	"""Affiche une notification avec humour Terry Pratchett"""
	var message = custom_message
	
	if message.is_empty() and pratchett_templates.has(category):
		var templates = pratchett_templates[category]
		message = templates[randi() % templates.size()]
	
	if message.is_empty():
		message = "Quelque chose d'intéressant vient de se produire."
	
	# Ajouter style Pratchett
	var formatted_message = "[color=goldenrod]🎭 " + message + "[/color]"
	show_notification(formatted_message, NotificationType.PRATCHETT_HUMOR, 6.0)

func show_magic_event_notification(event_type: String, details: Dictionary = {}) -> void:
	"""Notification pour événements magiques"""
	var message = ""
	
	match event_type:
		"spell_cast":
			message = "✨ Sort lancé: " + details.get("spell_name", "Inconnu")
		"chaos_triggered":
			message = "⚡ Chaos Octarine déclenché! Attendez-vous à l'inattendu..."
		"evolution_witnessed":
			message = "🔮 Une créature a évolué sous votre regard attentif!"
		"magic_cascade":
			message = "🌊 Cascade magique détectée! La réalité ondule légèrement..."
		_:
			message = "✨ Événement magique détecté"
	
	show_notification(message, NotificationType.MAGIC_EVENT, 4.0, details)

func show_reputation_notification(faction: String, change: int, new_level: String) -> void:
	"""Notification pour changements de réputation"""
	var change_text = "+" + str(change) if change > 0 else str(change)
	var message = "🏛️ Réputation " + faction + ": " + change_text + " (" + new_level + ")"
	
	var type = NotificationType.SUCCESS if change > 0 else NotificationType.WARNING
	show_notification(message, type, 4.0)

func show_quest_notification(quest_name: String, status: String) -> void:
	"""Notification pour quêtes"""
	var message = ""
	var type = NotificationType.QUEST
	
	match status:
		"started":
			message = "📜 Nouvelle quête: " + quest_name
		"completed":
			message = "✅ Quête terminée: " + quest_name
			type = NotificationType.SUCCESS
		"failed":
			message = "❌ Quête échouée: " + quest_name
			type = NotificationType.ERROR
		"updated":
			message = "📋 Quête mise à jour: " + quest_name
	
	show_notification(message, type, 5.0)

# ============================================================================
# TRAITEMENT DES NOTIFICATIONS
# ============================================================================

func process_notification_queue() -> void:
	"""Traite la queue des notifications"""
	# Limiter le nombre de notifications actives
	var max_notifications = notification_config.get("max_notifications", 5)
	
	while notification_queue.size() > 0 and active_notifications.size() < max_notifications:
		var notification_data = notification_queue.pop_front()
		display_notification(notification_data)

func display_notification(notification_data: Dictionary) -> void:
	"""Affiche une notification à l'écran"""
	if not notifications_container:
		return
	
	# Créer le widget de notification
	var notification_widget = create_notification_widget(notification_data)
	
	# Ajouter au container
	notifications_container.add_child(notification_widget)
	active_notifications.append(notification_data)
	
	# Animation d'entrée
	animate_notification_in(notification_widget)
	
	# Programmer la disparition automatique
	var duration = notification_data.get("duration", 5.0)
	if duration > 0:
		await get_tree().create_timer(duration).timeout
		remove_notification(notification_data["id"])
	
	# Émission du signal
	notification_shown.emit(notification_data["id"], NotificationType.keys()[notification_data["type"]])

func create_notification_widget(notification_data: Dictionary) -> Control:
	"""Crée le widget visuel d'une notification"""
	var container = PanelContainer.new()
	container.custom_minimum_size = Vector2(280, 60)
	
	# Style selon le type
	var style = create_notification_style(notification_data["type"])
	container.add_theme_stylebox_override("panel", style)
	
	# Layout principal
	var hbox = HBoxContainer.new()
	container.add_child(hbox)
	
	# Icône
	var icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(32, 32)
	icon.texture = get_notification_icon(notification_data["type"])
	hbox.add_child(icon)
	
	# Contenu texte
	var vbox = VBoxContainer.new()
	hbox.add_child(vbox)
	
	var message_label = RichTextLabel.new()
	message_label.custom_minimum_size = Vector2(200, 0)
	message_label.fit_content = true
	message_label.bbcode_enabled = true
	message_label.text = notification_data["message"]
	vbox.add_child(message_label)
	
	# Bouton fermeture
	var close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(24, 24)
	close_button.pressed.connect(remove_notification.bind(notification_data["id"]))
	hbox.add_child(close_button)
	
	# Stocker l'ID pour retrouver la notification
	container.set_meta("notification_id", notification_data["id"])
	
	return container

func create_notification_style(type: NotificationType) -> StyleBoxFlat:
	"""Crée le style visuel selon le type de notification"""
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	
	match type:
		NotificationType.INFO:
			style.bg_color = Color.STEEL_BLUE.darkened(0.3)
		NotificationType.SUCCESS:
			style.bg_color = Color.FOREST_GREEN.darkened(0.3)
		NotificationType.WARNING:
			style.bg_color = Color.ORANGE.darkened(0.3)
		NotificationType.ERROR:
			style.bg_color = Color.CRIMSON.darkened(0.3)
		NotificationType.ACHIEVEMENT:
			style.bg_color = Color.GOLDENROD.darkened(0.3)
		NotificationType.MAGIC_EVENT:
			style.bg_color = Color.MAGENTA.darkened(0.3)
		NotificationType.PRATCHETT_HUMOR:
			style.bg_color = Color.CHOCOLATE.darkened(0.3)
		_:
			style.bg_color = Color.DARK_GRAY
	
	return style

func get_notification_icon(type: NotificationType) -> Texture2D:
	"""Retourne l'icône selon le type de notification"""
	# TODO: Charger les vraies icônes depuis les ressources
	# Pour l'instant, retourner null - les icônes seront ajoutées plus tard
	return null

func animate_notification_in(widget: Control) -> void:
	"""Animation d'apparition de notification"""
	widget.modulate.a = 0.0
	widget.position.x = 300  # Hors écran à droite
	
	var tween = create_tween()
	tween.parallel().tween_property(widget, "modulate:a", 1.0, notification_config.get("fade_duration", 0.3))
	tween.parallel().tween_property(widget, "position:x", 0, notification_config.get("slide_duration", 0.4))

func remove_notification(notification_id: String, user_dismissed: bool = false) -> void:
	"""Retire une notification de l'affichage"""
	if not notifications_container:
		return
	
	# Trouver le widget correspondant
	var widget_to_remove = null
	for child in notifications_container.get_children():
		if child.has_meta("notification_id") and child.get_meta("notification_id") == notification_id:
			widget_to_remove = child
			break
	
	if not widget_to_remove:
		return
	
	# Animation de sortie
	var tween = create_tween()
	tween.parallel().tween_property(widget_to_remove, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(widget_to_remove, "position:x", 300, 0.3)
	await tween.finished
	
	# Supprimer le widget
	widget_to_remove.queue_free()
	
	# Retirer de la liste active
	active_notifications = active_notifications.filter(func(n): return n["id"] != notification_id)
	
	# Traiter la queue si nécessaire
	process_notification_queue()
	
	# Émission du signal
	notification_closed.emit(notification_id, user_dismissed)

# ============================================================================
# GESTION TUTORIELS
# ============================================================================

func display_tutorial_step() -> void:
	"""Affiche l'étape actuelle du tutoriel"""
	if current_tutorial.is_empty() or not tutorial_panel:
		return
	
	var steps = current_tutorial.get("steps", [])
	var current_step = current_tutorial.get("current_step", 0)
	
	if current_step >= steps.size():
		complete_tutorial()
		return
	
	var step_data = steps[current_step]
	
	# Afficher le panneau
	tutorial_panel.visible = true
	
	# Mettre à jour le contenu
	if tutorial_title:
		tutorial_title.text = current_tutorial.get("title", "Tutoriel")
	
	if tutorial_content:
		tutorial_content.text = step_data.get("content", "")
	
	if tutorial_progress:
		tutorial_progress.value = float(current_step + 1) / float(steps.size()) * 100.0
	
	# Charger l'image si présente
	if tutorial_image and step_data.has("image"):
		var image_path = step_data["image"]
		if ResourceLoader.exists(image_path):
			tutorial_image.texture = load(image_path)
	
	# Configurer les boutons
	if tutorial_next_button:
		tutorial_next_button.text = "Suivant" if current_step < steps.size() - 1 else "Terminer"

func _on_tutorial_next_pressed() -> void:
	"""Étape suivante du tutoriel"""
	current_tutorial["current_step"] = current_tutorial.get("current_step", 0) + 1
	display_tutorial_step()

func _on_tutorial_skip_pressed() -> void:
	"""Ignorer le tutoriel"""
	complete_tutorial()

func complete_tutorial() -> void:
	"""Termine le tutoriel actuel"""
	var tutorial_id = current_tutorial.get("id", "")
	
	if tutorial_panel:
		tutorial_panel.visible = false
	
	tutorial_completed.emit(tutorial_id)
	current_tutorial.clear()

# ============================================================================
# ANIMATIONS ET EFFETS
# ============================================================================

func animate_achievement_popup() -> void:
	"""Animation d'apparition de l'achievement"""
	if not achievement_popup:
		return
	
	achievement_popup.modulate.a = 0.0
	achievement_popup.scale = Vector2(0.5, 0.5)
	
	var tween = create_tween()
	tween.parallel().tween_property(achievement_popup, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(achievement_popup, "scale", Vector2.ONE, 0.3)

func hide_achievement_popup() -> void:
	"""Cache le popup d'achievement"""
	if not achievement_popup:
		return
	
	var tween = create_tween()
	tween.tween_property(achievement_popup, "modulate:a", 0.0, 0.2)
	await tween.finished
	achievement_popup.visible = false

# ============================================================================
# UTILITAIRES
# ============================================================================

func get_default_duration_for_type(type: NotificationType) -> float:
	"""Retourne la durée par défaut selon le type"""
	match type:
		NotificationType.INFO:
			return 3.0
		NotificationType.SUCCESS:
			return 4.0
		NotificationType.WARNING:
			return 5.0
		NotificationType.ERROR:
			return 7.0
		NotificationType.ACHIEVEMENT:
			return 6.0
		NotificationType.MAGIC_EVENT:
			return 4.0
		NotificationType.PRATCHETT_HUMOR:
			return 6.0
		_:
			return notification_config.get("default_duration", 5.0)

func show_welcome_notification() -> void:
	"""Affiche la notification de bienvenue"""
	var message = "🎭 Bienvenue dans Sortilèges & Bestioles!\nObservez les créatures pour les faire évoluer magiquement."
	show_notification(message, NotificationType.PRATCHETT_HUMOR, 8.0)

# ============================================================================
# API PUBLIQUE
# ============================================================================

func clear_all_notifications() -> void:
	"""Efface toutes les notifications"""
	notification_queue.clear()
	
	for notification in active_notifications:
		remove_notification(notification["id"])

func set_notifications_enabled(enabled: bool) -> void:
	"""Active/désactive les notifications"""
	user_preferences["notifications_enabled"] = enabled

func set_tutorials_enabled(enabled: bool) -> void:
	"""Active/désactive les tutoriels"""
	user_preferences["tutorials_enabled"] = enabled
	if not enabled:
		complete_tutorial()  # Fermer tutoriel actuel

func get_notification_count() -> int:
	"""Retourne le nombre de notifications actives"""
	return active_notifications.size()