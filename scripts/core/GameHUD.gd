# ============================================================================
# 🎮 GameHUD.gd - Interface Principale Permanente
# ============================================================================
# STATUS: 🟢 NOUVEAU | ROADMAP: Mois 1, Semaine 3-4 - UI Architecture
# PRIORITY: 🔴 CRITICAL - Interface principale du gameplay
# DEPENDENCIES: UIManager, Player, ObservationManager, MagicSystem

class_name GameHUD
extends Control

## Interface utilisateur principale du jeu
## Affichage permanent des informations vitales du joueur
## Design Terry Pratchett avec accessibilité et responsive design

# ============================================================================
# SIGNAUX
# ============================================================================

## Émis quand l'interface HUD est mise à jour
signal hud_updated()

## Émis quand le joueur clique sur un élément du HUD
signal hud_element_clicked(element_name: String)

## Émis pour demander l'ouverture d'une interface
signal interface_requested(interface_name: String)

## Émis quand la mini-carte est cliquée
signal minimap_clicked(world_position: Vector2)

# ============================================================================
# RÉFÉRENCES UI - SECTION JOUEUR
# ============================================================================

## Barres de statuts principaux
@export var player_stats_panel: Panel
@export var health_bar: ProgressBar
@export var health_label: Label
@export var mana_bar: ProgressBar
@export var mana_label: Label
@export var experience_bar: ProgressBar
@export var level_label: Label

## Portrait et informations joueur
@export var player_portrait: TextureRect
@export var player_name_label: Label
@export var player_title_label: Label

# ============================================================================
# RÉFÉRENCES UI - ZONE OBSERVATION
# ============================================================================

## Panneau d'observation des créatures
@export var observation_panel: Panel
@export var creature_icon: TextureRect
@export var creature_name_label: Label
@export var evolution_progress: ProgressBar
@export var observation_time_label: Label

## Carnet magique (accès rapide)
@export var notebook_button: Button
@export var observation_count_label: Label

# ============================================================================
# RÉFÉRENCES UI - ZONE MAGIQUE
# ============================================================================

## Panneau magie
@export var magic_panel: Panel
@export var quick_spell_slots: HBoxContainer
@export var octarine_indicator: Panel
@export var magic_disruption_meter: ProgressBar

## Enchantements actifs
@export var enchantments_panel: Panel
@export var enchantments_container: HBoxContainer

# ============================================================================
# RÉFÉRENCES UI - ZONE SOCIALE
# ============================================================================

## Panneau réputation
@export var reputation_panel: Panel
@export var faction_indicators: VBoxContainer
@export var social_status_label: Label

## Notifications de dialogue
@export var dialogue_indicator: Panel
@export var dialogue_preview_label: Label

# ============================================================================
# RÉFÉRENCES UI - ZONE NAVIGATION
# ============================================================================

## Mini-carte
@export var minimap_panel: Panel
@export var minimap_texture: TextureRect
@export var minimap_player_dot: Panel
@export var minimap_poi_container: Control

## Informations de localisation
@export var location_label: Label
@export var time_label: Label
@export var weather_icon: TextureRect

# ============================================================================
# RÉFÉRENCES UI - ZONE SYSTÈME
# ============================================================================

## Boutons d'accès rapide
@export var quick_access_panel: Panel
@export var inventory_button: Button
@export var magic_book_button: Button
@export var quest_log_button: Button
@export var menu_button: Button

## Indicateurs système
@export var save_indicator: Panel
@export var fps_counter: Label
@export var connection_status: Panel

# ============================================================================
# ÉTAT DU HUD
# ============================================================================

## Données du joueur
var player_data: Dictionary = {
	"health": 100,
	"max_health": 100,
	"mana": 50,
	"max_mana": 50,
	"experience": 0,
	"experience_to_next": 100,
	"level": 1,
	"name": "Naturaliste Débutant",
	"title": "Observateur de Créatures"
}

## État observation actuelle
var observation_state: Dictionary = {
	"creature_id": "",
	"creature_name": "",
	"progress": 0.0,
	"time_observing": 0.0,
	"total_observations": 0
}

## État magique
var magic_state: Dictionary = {
	"octarine_active": false,
	"disruption_level": 0.0,
	"active_enchantments": [],
	"quick_spells": []
}

## État social
var social_state: Dictionary = {
	"primary_faction": "",
	"reputation_level": "Neutre",
	"active_dialogue": false,
	"pending_conversations": 0
}

## État du monde
var world_state: Dictionary = {
	"current_location": "Ankh-Morpork",
	"current_time": "12:00",
	"weather": "normal",
	"minimap_scale": 1.0
}

## Configuration HUD
var hud_config: Dictionary = {
	"show_fps": false,
	"minimap_enabled": true,
	"quick_access_visible": true,
	"reputation_visible": true,
	"magic_panel_visible": true
}

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	"""Initialisation du HUD principal"""
	print("🎮 GameHUD: Initialisation...")
	
	setup_ui_components()
	load_hud_configuration()
	connect_ui_signals()
	apply_terry_pratchett_styling()
	
	# Mise à jour initiale
	update_all_displays()
	
	print("🎮 GameHUD: Interface principale prête")

func setup_ui_components() -> void:
	"""Configure les composants UI de base"""
	# Configuration des barres de progression
	setup_progress_bars()
	
	# Configuration des boutons d'accès rapide
	setup_quick_access_buttons()
	
	# Configuration de la mini-carte
	setup_minimap()
	
	# Configuration responsive
	setup_responsive_layout()

func setup_progress_bars() -> void:
	"""Configure toutes les barres de progression"""
	var bars_config = [
		[health_bar, Color.CRIMSON, Color.DARK_RED],
		[mana_bar, Color.ROYAL_BLUE, Color.NAVY],
		[experience_bar, Color.GOLDENROD, Color.DARK_GOLDENROD],
		[evolution_progress, Color.FOREST_GREEN, Color.DARK_GREEN],
		[magic_disruption_meter, Color.MAGENTA, Color.PURPLE]
	]
	
	for config in bars_config:
		var bar = config[0]
		if bar:
			bar.min_value = 0
			bar.max_value = 100
			bar.value = 0
			
			# Style personnalisé
			var fill_style = StyleBoxFlat.new()
			fill_style.bg_color = config[1]
			bar.add_theme_stylebox_override("fill", fill_style)
			
			var bg_style = StyleBoxFlat.new()
			bg_style.bg_color = config[2]
			bar.add_theme_stylebox_override("background", bg_style)

func setup_quick_access_buttons() -> void:
	"""Configure les boutons d'accès rapide"""
	var buttons_config = [
		[inventory_button, "🎒", "Inventaire"],
		[magic_book_button, "📚", "Grimoire"],
		[quest_log_button, "📜", "Journal de Quêtes"],
		[menu_button, "⚙️", "Menu"]
	]
	
	for config in buttons_config:
		var button = config[0]
		if button:
			button.text = config[1]
			button.tooltip_text = config[2]
			button.custom_minimum_size = Vector2(48, 48)

func setup_minimap() -> void:
	"""Configure la mini-carte"""
	if minimap_panel:
		minimap_panel.custom_minimum_size = Vector2(150, 150)
	
	if minimap_player_dot:
		minimap_player_dot.custom_minimum_size = Vector2(6, 6)
		minimap_player_dot.position = Vector2(72, 72)  # Centre de la minimap

func setup_responsive_layout() -> void:
	"""Configure la mise en page responsive"""
	# Ajuster selon la résolution
	var screen_size = DisplayServer.screen_get_size()
	var scale_factor = min(screen_size.x / 1920.0, screen_size.y / 1080.0)
	
	# Appliquer le facteur d'échelle aux éléments principaux
	if scale_factor < 1.0:
		scale = Vector2.ONE * max(scale_factor, 0.8)

func connect_ui_signals() -> void:
	"""Connecte tous les signaux UI"""
	# Boutons d'accès rapide
	if inventory_button:
		inventory_button.pressed.connect(_on_inventory_requested)
	if magic_book_button:
		magic_book_button.pressed.connect(_on_magic_book_requested)
	if quest_log_button:
		quest_log_button.pressed.connect(_on_quest_log_requested)
	if menu_button:
		menu_button.pressed.connect(_on_menu_requested)
	
	if notebook_button:
		notebook_button.pressed.connect(_on_notebook_requested)

func load_hud_configuration() -> void:
	"""Charge la configuration du HUD"""
	var config_path = "user://hud_config.json"
	
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		if file:
			var json_string = file.get_as_text()
			file.close()
			
			var json = JSON.new()
			var parse_result = json.parse(json_string)
			
			if parse_result == OK:
				hud_config.merge(json.data, true)
	
	apply_hud_configuration()

func apply_hud_configuration() -> void:
	"""Applique la configuration du HUD"""
	# Visibilité des panneaux
	if reputation_panel:
		reputation_panel.visible = hud_config.get("reputation_visible", true)
	if magic_panel:
		magic_panel.visible = hud_config.get("magic_panel_visible", true)
	if minimap_panel:
		minimap_panel.visible = hud_config.get("minimap_enabled", true)
	
	# FPS counter
	if fps_counter:
		fps_counter.visible = hud_config.get("show_fps", false)

func apply_terry_pratchett_styling() -> void:
	"""Applique le style visuel Terry Pratchett"""
	# Couleurs du Disque-Monde
	var primary_color = Color.DARK_SLATE_GRAY
	var accent_color = Color.GOLDENROD
	var magic_color = Color.MAGENTA.darkened(0.3)
	
	# Style des panneaux principaux
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = primary_color.lightened(0.1)
	panel_style.border_color = accent_color
	panel_style.border_width_left = 1
	panel_style.border_width_right = 1
	panel_style.border_width_top = 1
	panel_style.border_width_bottom = 1
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	
	# Appliquer aux panneaux
	for panel in [player_stats_panel, observation_panel, magic_panel, reputation_panel, minimap_panel]:
		if panel:
			panel.add_theme_stylebox_override("panel", panel_style)
	
	# Style spécial pour le panneau Octarine
	if octarine_indicator:
		var octarine_style = panel_style.duplicate()
		octarine_style.bg_color = magic_color
		octarine_indicator.add_theme_stylebox_override("panel", octarine_style)

# ============================================================================
# MISE À JOUR DES AFFICHAGES
# ============================================================================

func update_all_displays() -> void:
	"""Met à jour tous les affichages du HUD"""
	update_player_stats()
	update_observation_display()
	update_magic_display()
	update_social_display()
	update_world_display()
	update_system_indicators()
	
	hud_updated.emit()

func update_player_stats() -> void:
	"""Met à jour les statistiques du joueur"""
	# Santé
	if health_bar and health_label:
		var health_percent = float(player_data["health"]) / float(player_data["max_health"]) * 100.0
		health_bar.value = health_percent
		health_label.text = str(player_data["health"]) + "/" + str(player_data["max_health"])
	
	# Mana
	if mana_bar and mana_label:
		var mana_percent = float(player_data["mana"]) / float(player_data["max_mana"]) * 100.0
		mana_bar.value = mana_percent
		mana_label.text = str(player_data["mana"]) + "/" + str(player_data["max_mana"])
	
	# Expérience
	if experience_bar and level_label:
		var exp_percent = float(player_data["experience"]) / float(player_data["experience_to_next"]) * 100.0
		experience_bar.value = exp_percent
		level_label.text = "Niveau " + str(player_data["level"])
	
	# Nom et titre
	if player_name_label:
		player_name_label.text = player_data.get("name", "Joueur")
	if player_title_label:
		player_title_label.text = player_data.get("title", "Aventurier")

func update_observation_display() -> void:
	"""Met à jour l'affichage d'observation"""
	if observation_state.get("creature_id", "") != "":
		# Créature en cours d'observation
		if creature_name_label:
			creature_name_label.text = observation_state.get("creature_name", "Créature Inconnue")
		
		if evolution_progress:
			evolution_progress.value = observation_state.get("progress", 0.0) * 100.0
		
		if observation_time_label:
			var time = observation_state.get("time_observing", 0.0)
			observation_time_label.text = "Observé: " + format_time(time)
		
		if observation_panel:
			observation_panel.visible = true
	else:
		# Pas d'observation active
		if observation_panel:
			observation_panel.visible = false
	
	# Compteur total d'observations
	if observation_count_label:
		observation_count_label.text = str(observation_state.get("total_observations", 0))

func update_magic_display() -> void:
	"""Met à jour l'affichage magique"""
	# Indicateur Octarine
	if octarine_indicator:
		octarine_indicator.visible = magic_state.get("octarine_active", false)
		
		if magic_state.get("octarine_active", false):
			# Animation pulsante pour l'Octarine
			var tween = create_tween()
			tween.set_loops()
			tween.tween_property(octarine_indicator, "modulate:a", 0.5, 0.8)
			tween.tween_property(octarine_indicator, "modulate:a", 1.0, 0.8)
	
	# Niveau de perturbation magique
	if magic_disruption_meter:
		magic_disruption_meter.value = magic_state.get("disruption_level", 0.0) * 100.0
	
	# Sorts d'accès rapide
	update_quick_spells()
	
	# Enchantements actifs
	update_enchantments_display()

func update_quick_spells() -> void:
	"""Met à jour les sorts d'accès rapide"""
	if not quick_spell_slots:
		return
	
	# Nettoyer les slots actuels
	for child in quick_spell_slots.get_children():
		child.queue_free()
	
	# Créer les nouveaux slots
	var spells = magic_state.get("quick_spells", [])
	for i in range(4):  # 4 slots de sorts rapides
		var slot_button = Button.new()
		slot_button.custom_minimum_size = Vector2(40, 40)
		
		if i < spells.size():
			var spell_data = spells[i]
			slot_button.text = spell_data.get("icon", "✨")
			slot_button.tooltip_text = spell_data.get("name", "Sort")
			slot_button.pressed.connect(_on_quick_spell_used.bind(i))
		else:
			slot_button.text = "+"
			slot_button.tooltip_text = "Slot vide"
			slot_button.disabled = true
		
		quick_spell_slots.add_child(slot_button)

func update_enchantments_display() -> void:
	"""Met à jour l'affichage des enchantements"""
	if not enchantments_container:
		return
	
	# Nettoyer les enchantements actuels
	for child in enchantments_container.get_children():
		child.queue_free()
	
	# Afficher les enchantements actifs
	var enchantments = magic_state.get("active_enchantments", [])
	for enchantment in enchantments:
		var enchant_icon = TextureRect.new()
		enchant_icon.custom_minimum_size = Vector2(24, 24)
		enchant_icon.tooltip_text = enchantment.get("name", "Enchantement") + "\n" + enchantment.get("description", "")
		
		# TODO: Charger la vraie texture
		# enchant_icon.texture = load(enchantment.get("icon", "res://ui/icons/default_enchant.png"))
		
		enchantments_container.add_child(enchant_icon)

func update_social_display() -> void:
	"""Met à jour l'affichage social"""
	if social_status_label:
		var faction = social_state.get("primary_faction", "Aucune")
		var level = social_state.get("reputation_level", "Neutre")
		social_status_label.text = faction + " (" + level + ")"
	
	# Indicateur de dialogue
	if dialogue_indicator:
		dialogue_indicator.visible = social_state.get("active_dialogue", false)
	
	# Conversations en attente
	var pending = social_state.get("pending_conversations", 0)
	if dialogue_preview_label and pending > 0:
		dialogue_preview_label.text = str(pending) + " conversation(s) en attente"
		dialogue_preview_label.visible = true
	elif dialogue_preview_label:
		dialogue_preview_label.visible = false
	
	# Indicateurs de factions
	update_faction_indicators()

func update_faction_indicators() -> void:
	"""Met à jour les indicateurs de faction"""
	if not faction_indicators:
		return
	
	# TODO: Récupérer les données de réputation depuis ReputationSystem
	# Pour l'instant, affichage simplifié
	pass

func update_world_display() -> void:
	"""Met à jour l'affichage du monde"""
	# Localisation
	if location_label:
		location_label.text = world_state.get("current_location", "Lieu Inconnu")
	
	# Temps
	if time_label:
		time_label.text = world_state.get("current_time", "??:??")
	
	# Météo
	if weather_icon:
		# TODO: Charger l'icône météo appropriée
		pass
	
	# Mini-carte
	update_minimap()

func update_minimap() -> void:
	"""Met à jour la mini-carte"""
	if not minimap_texture:
		return
	
	# TODO: Générer/mettre à jour la texture de la mini-carte
	# Position du joueur, POI, etc.
	pass

func update_system_indicators() -> void:
	"""Met à jour les indicateurs système"""
	# FPS
	if fps_counter and hud_config.get("show_fps", false):
		fps_counter.text = str(Engine.get_frames_per_second()) + " FPS"
	
	# Indicateur de sauvegarde
	if save_indicator:
		# TODO: Connecter au système de sauvegarde
		pass

# ============================================================================
# API PUBLIQUE - DONNÉES JOUEUR
# ============================================================================

func set_player_health(current: int, maximum: int = -1) -> void:
	"""Met à jour la santé du joueur"""
	player_data["health"] = current
	if maximum > 0:
		player_data["max_health"] = maximum
	update_player_stats()

func set_player_mana(current: int, maximum: int = -1) -> void:
	"""Met à jour la mana du joueur"""
	player_data["mana"] = current
	if maximum > 0:
		player_data["max_mana"] = maximum
	update_player_stats()

func set_player_experience(current: int, to_next: int = -1, level: int = -1) -> void:
	"""Met à jour l'expérience du joueur"""
	player_data["experience"] = current
	if to_next > 0:
		player_data["experience_to_next"] = to_next
	if level > 0:
		player_data["level"] = level
	update_player_stats()

func set_player_info(name: String, title: String = "") -> void:
	"""Met à jour les informations du joueur"""
	player_data["name"] = name
	if title != "":
		player_data["title"] = title
	update_player_stats()

# ============================================================================
# API PUBLIQUE - OBSERVATION
# ============================================================================

func start_creature_observation(creature_id: String, creature_name: String) -> void:
	"""Démarre l'observation d'une créature"""
	observation_state["creature_id"] = creature_id
	observation_state["creature_name"] = creature_name
	observation_state["progress"] = 0.0
	observation_state["time_observing"] = 0.0
	update_observation_display()

func update_creature_observation(progress: float, time: float) -> void:
	"""Met à jour l'observation en cours"""
	observation_state["progress"] = progress
	observation_state["time_observing"] = time
	update_observation_display()

func stop_creature_observation() -> void:
	"""Arrête l'observation actuelle"""
	observation_state["creature_id"] = ""
	observation_state["total_observations"] += 1
	update_observation_display()

# ============================================================================
# API PUBLIQUE - MAGIE
# ============================================================================

func set_octarine_active(active: bool) -> void:
	"""Active/désactive l'indicateur Octarine"""
	magic_state["octarine_active"] = active
	update_magic_display()

func set_magic_disruption(level: float) -> void:
	"""Met à jour le niveau de perturbation magique"""
	magic_state["disruption_level"] = clamp(level, 0.0, 1.0)
	update_magic_display()

func set_quick_spells(spells: Array) -> void:
	"""Définit les sorts d'accès rapide"""
	magic_state["quick_spells"] = spells
	update_quick_spells()

func add_enchantment(enchantment_data: Dictionary) -> void:
	"""Ajoute un enchantement actif"""
	magic_state["active_enchantments"].append(enchantment_data)
	update_enchantments_display()

func remove_enchantment(enchantment_id: String) -> void:
	"""Retire un enchantement actif"""
	var enchantments = magic_state["active_enchantments"]
	for i in range(enchantments.size()):
		if enchantments[i].get("id", "") == enchantment_id:
			enchantments.remove_at(i)
			break
	update_enchantments_display()

# ============================================================================
# API PUBLIQUE - SOCIAL
# ============================================================================

func set_primary_faction(faction: String, level: String) -> void:
	"""Met à jour la faction principale"""
	social_state["primary_faction"] = faction
	social_state["reputation_level"] = level
	update_social_display()

func set_dialogue_active(active: bool, preview_text: String = "") -> void:
	"""Met à jour l'état de dialogue"""
	social_state["active_dialogue"] = active
	if preview_text != "":
		social_state["dialogue_preview"] = preview_text
	update_social_display()

func set_pending_conversations(count: int) -> void:
	"""Met à jour le nombre de conversations en attente"""
	social_state["pending_conversations"] = count
	update_social_display()

# ============================================================================
# API PUBLIQUE - MONDE
# ============================================================================

func set_current_location(location: String) -> void:
	"""Met à jour la localisation actuelle"""
	world_state["current_location"] = location
	update_world_display()

func set_current_time(time: String) -> void:
	"""Met à jour l'heure actuelle"""
	world_state["current_time"] = time
	update_world_display()

func set_weather(weather: String) -> void:
	"""Met à jour la météo"""
	world_state["weather"] = weather
	update_world_display()

# ============================================================================
# CALLBACKS UI
# ============================================================================

func _on_inventory_requested() -> void:
	interface_requested.emit("inventory")
	hud_element_clicked.emit("inventory")

func _on_magic_book_requested() -> void:
	interface_requested.emit("magic_book")
	hud_element_clicked.emit("magic_book")

func _on_quest_log_requested() -> void:
	interface_requested.emit("quest_log")
	hud_element_clicked.emit("quest_log")

func _on_menu_requested() -> void:
	interface_requested.emit("menu")
	hud_element_clicked.emit("menu")

func _on_notebook_requested() -> void:
	interface_requested.emit("notebook")
	hud_element_clicked.emit("notebook")

func _on_quick_spell_used(slot_index: int) -> void:
	var spells = magic_state.get("quick_spells", [])
	if slot_index < spells.size():
		var spell = spells[slot_index]
		interface_requested.emit("quick_spell:" + spell.get("id", ""))

# ============================================================================
# UTILITAIRES
# ============================================================================

func format_time(seconds: float) -> String:
	"""Formate un temps en secondes en format lisible"""
	var minutes = int(seconds) / 60
	var secs = int(seconds) % 60
	return str(minutes) + ":" + str(secs).pad_zeros(2)

func toggle_hud_element(element_name: String) -> void:
	"""Bascule la visibilité d'un élément du HUD"""
	match element_name:
		"reputation":
			hud_config["reputation_visible"] = not hud_config["reputation_visible"]
		"magic":
			hud_config["magic_panel_visible"] = not hud_config["magic_panel_visible"]
		"minimap":
			hud_config["minimap_enabled"] = not hud_config["minimap_enabled"]
		"fps":
			hud_config["show_fps"] = not hud_config["show_fps"]
	
	apply_hud_configuration()

func get_hud_visibility(element_name: String) -> bool:
	"""Retourne la visibilité d'un élément du HUD"""
	return hud_config.get(element_name + "_visible", true)

# ============================================================================
# MISE À JOUR TEMPS RÉEL
# ============================================================================

func _process(_delta: float) -> void:
	"""Mise à jour en temps réel"""
	# Mettre à jour le compteur FPS si activé
	if fps_counter and fps_counter.visible:
		fps_counter.text = str(Engine.get_frames_per_second()) + " FPS"
	
	# Mettre à jour le temps d'observation si en cours
	if observation_state.get("creature_id", "") != "":
		observation_state["time_observing"] += _delta
		if observation_time_label:
			observation_time_label.text = "Observé: " + format_time(observation_state["time_observing"])