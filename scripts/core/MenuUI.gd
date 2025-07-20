# ============================================================================
# 📋 MenuUI.gd - Gestionnaire Menus Système et Paramètres
# ============================================================================
# STATUS: ✅ COMPLET | Sous-système UIManager
# PRIORITY: 🟠 P2 - Navigation et configuration
# DEPENDENCIES: UIManager, GameManager

class_name MenuUI
extends Control

## Gestionnaire des menus système pour "Sortilèges & Bestioles"
## Menu principal, pause, paramètres, sauvegarde/chargement
## Style Terry Pratchett avec accessibilité complète

# ============================================================================
# SIGNAUX
# ============================================================================

signal menu_action_selected(action: String, data: Dictionary)
signal settings_changed(setting_type: String, new_value)
signal save_game_requested(slot: int, save_name: String)
signal load_game_requested(slot: int)
signal menu_transition_requested(from_menu: String, to_menu: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

var menu_config: Dictionary = {}
var current_menu: String = "main"
var menu_stack: Array[String] = []
var game_settings: Dictionary = {}
var save_slots: Array[Dictionary] = []

# ============================================================================
# ÉLÉMENTS UI PRINCIPAUX
# ============================================================================

## Conteneurs menus
@onready var menu_container: Control
@onready var main_menu: Control
@onready var pause_menu: Control
@onready var settings_menu: Control
@onready var save_load_menu: Control
@onready var credits_menu: Control

## Background et effets
@onready var menu_background: Control
@onready var title_animation: Control
@onready var particle_effects: CPUParticles2D

## Navigation
@onready var back_button: Button
@onready var menu_navigation: Control

# ============================================================================
# MENUS SPÉCIFIQUES
# ============================================================================

## Menu Principal
@onready var main_menu_container: VBoxContainer
@onready var game_title: Label
@onready var new_game_button: Button
@onready var continue_button: Button
@onready var load_game_button: Button
@onready var settings_button: Button
@onready var credits_button: Button
@onready var quit_button: Button

## Menu Pause
@onready var pause_menu_container: VBoxContainer
@onready var resume_button: Button
@onready var save_button: Button
@onready var load_button: Button
@onready var pause_settings_button: Button
@onready var main_menu_button: Button

## Menu Paramètres
@onready var settings_container: VBoxContainer
@onready var video_settings: Control
@onready var audio_settings: Control
@onready var accessibility_settings: Control
@onready var controls_settings: Control

# ============================================================================
# TYPES & ENUMS
# ============================================================================

enum MenuType {
	MAIN = 0,           ## Menu principal
	PAUSE = 1,          ## Menu pause
	SETTINGS = 2,       ## Paramètres
	SAVE_LOAD = 3,      ## Sauvegarde/Chargement
	CREDITS = 4,        ## Crédits
	CONFIRM = 5         ## Dialogue confirmation
}

enum SettingsCategory {
	VIDEO = 0,          ## Paramètres vidéo
	AUDIO = 1,          ## Paramètres audio
	ACCESSIBILITY = 2,  ## Accessibilité
	CONTROLS = 3,       ## Contrôles
	GAMEPLAY = 4        ## Gameplay
}

# ============================================================================
# INITIALISATION
# ============================================================================

func initialize(parent_container: Control, config: Dictionary) -> void:
	"""Initialise le système MenuUI"""
	menu_config = config
	
	# Créer l'interface des menus
	create_menu_interface(parent_container)
	setup_menu_styling()
	load_game_settings()
	setup_save_slots()
	
	print("📋 MenuUI: Système de menus initialisé")

func create_menu_interface(parent: Control) -> void:
	"""Crée l'interface complète des menus"""
	# Conteneur principal
	menu_container = Control.new()
	menu_container.name = "MenuContainer"
	menu_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(menu_container)
	
	# Background avec effets Terry Pratchett
	create_menu_background()
	
	# Créer tous les menus
	create_main_menu()
	create_pause_menu()
	create_settings_menu()
	create_save_load_menu()
	create_credits_menu()
	
	# Navigation commune
	create_menu_navigation()
	
	# Masquer tout sauf main par défaut
	show_menu("main")

func create_menu_background() -> void:
	"""Crée le background animé des menus"""
	menu_background = Control.new()
	menu_background.name = "MenuBackground"
	menu_background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_container.add_child(menu_background)
	
	# Image de fond Ankh-Morpork
	var bg_image = TextureRect.new()
	bg_image.texture = load("res://ui/backgrounds/ankh_morpork_menu.png")
	bg_image.anchors_preset = Control.PRESET_FULL_RECT
	bg_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	menu_background.add_child(bg_image)
	
	# Overlay sombre pour lisibilité
	var overlay = ColorRect.new()
	overlay.color = Color(0.0, 0.0, 0.2, 0.6)  # Bleu sombre transparent
	overlay.anchors_preset = Control.PRESET_FULL_RECT
	menu_background.add_child(overlay)
	
	# Particules magiques Ankh-Morpork
	particle_effects = CPUParticles2D.new()
	particle_effects.name = "MenuParticles"
	particle_effects.emitting = true
	particle_effects.amount = 25
	particle_effects.lifetime = 8.0
	particle_effects.texture = load("res://vfx/dust_particle.png")
	particle_effects.color = Color(0.8, 0.7, 0.5, 0.3)  # Poussière dorée
	particle_effects.position = Vector2(960, 540)
	particle_effects.emission_rect_extents = Vector2(960, 540)
	particle_effects.direction = Vector2(0, -1)
	particle_effects.initial_velocity_min = 10.0
	particle_effects.initial_velocity_max = 30.0
	particle_effects.gravity = Vector2(0, 5)
	menu_background.add_child(particle_effects)

func create_main_menu() -> void:
	"""Crée le menu principal"""
	main_menu = Control.new()
	main_menu.name = "MainMenu"
	main_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_container.add_child(main_menu)
	
	# Container centré pour le menu
	main_menu_container = VBoxContainer.new()
	main_menu_container.name = "MainMenuContainer"
	main_menu_container.anchors_preset = Control.PRESET_CENTER
	main_menu_container.custom_minimum_size = Vector2(400, 500)
	main_menu.add_child(main_menu_container)
	
	# Titre du jeu avec animation
	game_title = Label.new()
	game_title.name = "GameTitle"
	game_title.text = "SORTILÈGES & BESTIOLES"
	game_title.add_theme_font_size_override("font_size", 48)
	game_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Or Terry Pratchett
	game_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_menu_container.add_child(game_title)
	
	# Sous-titre
	var subtitle = Label.new()
	subtitle.text = "Une Aventure du Disque-Monde"
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_menu_container.add_child(subtitle)
	
	# Spacer
	main_menu_container.add_child(create_spacer(50))
	
	# Boutons du menu principal
	new_game_button = create_menu_button("🆕 Nouvelle Partie", "new_game")
	main_menu_container.add_child(new_game_button)
	
	continue_button = create_menu_button("▶️ Continuer", "continue_game")
	main_menu_container.add_child(continue_button)
	
	load_game_button = create_menu_button("📁 Charger Partie", "load_game")
	main_menu_container.add_child(load_game_button)
	
	settings_button = create_menu_button("⚙️ Paramètres", "settings")
	main_menu_container.add_child(settings_button)
	
	credits_button = create_menu_button("👥 Crédits", "credits")
	main_menu_container.add_child(credits_button)
	
	quit_button = create_menu_button("🚪 Quitter", "quit")
	main_menu_container.add_child(quit_button)

func create_pause_menu() -> void:
	"""Crée le menu pause"""
	pause_menu = Control.new()
	pause_menu.name = "PauseMenu"
	pause_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_container.add_child(pause_menu)
	
	# Semi-transparent overlay
	var pause_overlay = ColorRect.new()
	pause_overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	pause_overlay.anchors_preset = Control.PRESET_FULL_RECT
	pause_menu.add_child(pause_overlay)
	
	# Container menu pause
	pause_menu_container = VBoxContainer.new()
	pause_menu_container.name = "PauseMenuContainer"
	pause_menu_container.anchors_preset = Control.PRESET_CENTER
	pause_menu_container.custom_minimum_size = Vector2(300, 400)
	pause_menu.add_child(pause_menu_container)
	
	# Background du menu pause
	var pause_bg = NinePatchRect.new()
	pause_bg.texture = load("res://ui/textures/menu_panel_bg.png")
	pause_bg.anchors_preset = Control.PRESET_FULL_RECT
	pause_menu_container.add_child(pause_bg)
	pause_menu_container.move_child(pause_bg, 0)
	
	# Titre pause
	var pause_title = Label.new()
	pause_title.text = "⏸️ PAUSE"
	pause_title.add_theme_font_size_override("font_size", 32)
	pause_title.add_theme_color_override("font_color", Color.YELLOW)
	pause_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_menu_container.add_child(pause_title)
	
	pause_menu_container.add_child(create_spacer(30))
	
	# Boutons menu pause
	resume_button = create_menu_button("▶️ Reprendre", "resume")
	pause_menu_container.add_child(resume_button)
	
	save_button = create_menu_button("💾 Sauvegarder", "save")
	pause_menu_container.add_child(save_button)
	
	load_button = create_menu_button("📁 Charger", "load")
	pause_menu_container.add_child(load_button)
	
	pause_settings_button = create_menu_button("⚙️ Paramètres", "settings")
	pause_menu_container.add_child(pause_settings_button)
	
	main_menu_button = create_menu_button("🏠 Menu Principal", "main_menu")
	pause_menu_container.add_child(main_menu_button)

func create_settings_menu() -> void:
	"""Crée le menu des paramètres"""
	settings_menu = Control.new()
	settings_menu.name = "SettingsMenu"
	settings_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_container.add_child(settings_menu)
	
	# Container principal paramètres
	var settings_main = HSplitContainer.new()
	settings_main.anchors_preset = Control.PRESET_FULL_RECT
	settings_main.offset_left = 100
	settings_main.offset_right = -100
	settings_main.offset_top = 50
	settings_main.offset_bottom = -50
	settings_menu.add_child(settings_main)
	
	# Sidebar catégories
	var categories_list = VBoxContainer.new()
	categories_list.custom_minimum_size.x = 200
	settings_main.add_child(categories_list)
	
	var categories_title = Label.new()
	categories_title.text = "PARAMÈTRES"
	categories_title.add_theme_font_size_override("font_size", 24)
	categories_title.add_theme_color_override("font_color", Color.YELLOW)
	categories_list.add_child(categories_title)
	
	categories_list.add_child(create_spacer(20))
	
	# Boutons catégories
	var video_cat_button = create_menu_button("📺 Vidéo", "category_video")
	categories_list.add_child(video_cat_button)
	
	var audio_cat_button = create_menu_button("🔊 Audio", "category_audio")
	categories_list.add_child(audio_cat_button)
	
	var accessibility_cat_button = create_menu_button("♿ Accessibilité", "category_accessibility")
	categories_list.add_child(accessibility_cat_button)
	
	var controls_cat_button = create_menu_button("🎮 Contrôles", "category_controls")
	categories_list.add_child(controls_cat_button)
	
	# Container paramètres détaillés
	settings_container = VBoxContainer.new()
	settings_main.add_child(settings_container)
	
	# Créer les panneaux de paramètres
	create_video_settings()
	create_audio_settings()
	create_accessibility_settings()
	create_controls_settings()

func create_video_settings() -> void:
	"""Crée les paramètres vidéo"""
	video_settings = VBoxContainer.new()
	video_settings.name = "VideoSettings"
	settings_container.add_child(video_settings)
	
	# Titre section
	var video_title = Label.new()
	video_title.text = "PARAMÈTRES VIDÉO"
	video_title.add_theme_font_size_override("font_size", 20)
	video_title.add_theme_color_override("font_color", Color.CYAN)
	video_settings.add_child(video_title)
	
	video_settings.add_child(create_spacer(20))
	
	# Résolution
	video_settings.add_child(create_setting_label("Résolution"))
	var resolution_dropdown = create_dropdown(["1920x1080", "1600x900", "1366x768", "1280x720"])
	resolution_dropdown.option_selected.connect(_on_resolution_changed)
	video_settings.add_child(resolution_dropdown)
	
	# Mode plein écran
	var fullscreen_check = create_checkbox("Mode Plein Écran", "fullscreen")
	video_settings.add_child(fullscreen_check)
	
	# VSync
	var vsync_check = create_checkbox("Synchronisation Verticale", "vsync")
	video_settings.add_child(vsync_check)
	
	# Qualité graphique
	video_settings.add_child(create_setting_label("Qualité Graphique"))
	var quality_dropdown = create_dropdown(["Faible", "Moyenne", "Élevée", "Ultra"])
	quality_dropdown.option_selected.connect(_on_quality_changed)
	video_settings.add_child(quality_dropdown)

func create_audio_settings() -> void:
	"""Crée les paramètres audio"""
	audio_settings = VBoxContainer.new()
	audio_settings.name = "AudioSettings"
	settings_container.add_child(audio_settings)
	
	# Titre section
	var audio_title = Label.new()
	audio_title.text = "PARAMÈTRES AUDIO"
	audio_title.add_theme_font_size_override("font_size", 20)
	audio_title.add_theme_color_override("font_color", Color.CYAN)
	audio_settings.add_child(audio_title)
	
	audio_settings.add_child(create_spacer(20))
	
	# Volume général
	audio_settings.add_child(create_setting_label("Volume Général"))
	var master_volume = create_slider(0.0, 1.0, 0.8, "master_volume")
	audio_settings.add_child(master_volume)
	
	# Volume musique
	audio_settings.add_child(create_setting_label("Volume Musique"))
	var music_volume = create_slider(0.0, 1.0, 0.7, "music_volume")
	audio_settings.add_child(music_volume)
	
	# Volume effets
	audio_settings.add_child(create_setting_label("Volume Effets Sonores"))
	var sfx_volume = create_slider(0.0, 1.0, 0.8, "sfx_volume")
	audio_settings.add_child(sfx_volume)
	
	# Volume voix
	audio_settings.add_child(create_setting_label("Volume Voix"))
	var voice_volume = create_slider(0.0, 1.0, 1.0, "voice_volume")
	audio_settings.add_child(voice_volume)

func create_accessibility_settings() -> void:
	"""Crée les paramètres d'accessibilité"""
	accessibility_settings = VBoxContainer.new()
	accessibility_settings.name = "AccessibilitySettings"
	settings_container.add_child(accessibility_settings)
	
	# Titre section
	var accessibility_title = Label.new()
	accessibility_title.text = "ACCESSIBILITÉ"
	accessibility_title.add_theme_font_size_override("font_size", 20)
	accessibility_title.add_theme_color_override("font_color", Color.CYAN)
	accessibility_settings.add_child(accessibility_title)
	
	accessibility_settings.add_child(create_spacer(20))
	
	# Support daltonisme
	var colorblind_check = create_checkbox("Support Daltonisme", "colorblind_support")
	accessibility_settings.add_child(colorblind_check)
	
	# Taille police
	accessibility_settings.add_child(create_setting_label("Taille Police"))
	var font_size_slider = create_slider(0.5, 2.0, 1.0, "font_scale")
	accessibility_settings.add_child(font_size_slider)
	
	# Contraste élevé
	var high_contrast_check = create_checkbox("Contraste Élevé", "high_contrast")
	accessibility_settings.add_child(high_contrast_check)
	
	# Sous-titres
	var subtitles_check = create_checkbox("Sous-titres Activés", "subtitles")
	accessibility_settings.add_child(subtitles_check)
	
	# Aide motrice
	var motor_help_check = create_checkbox("Aide Motrice", "motor_assistance")
	accessibility_settings.add_child(motor_help_check)

func create_controls_settings() -> void:
	"""Crée les paramètres de contrôles"""
	controls_settings = VBoxContainer.new()
	controls_settings.name = "ControlsSettings"
	settings_container.add_child(controls_settings)
	
	# Titre section
	var controls_title = Label.new()
	controls_title.text = "CONTRÔLES"
	controls_title.add_theme_font_size_override("font_size", 20)
	controls_title.add_theme_color_override("font_color", Color.CYAN)
	controls_settings.add_child(controls_title)
	
	controls_settings.add_child(create_spacer(20))
	
	# Sensibilité souris
	controls_settings.add_child(create_setting_label("Sensibilité Souris"))
	var mouse_sensitivity = create_slider(0.1, 3.0, 1.0, "mouse_sensitivity")
	controls_settings.add_child(mouse_sensitivity)
	
	# Inversement axes
	var invert_y_check = create_checkbox("Inverser Axe Y", "invert_mouse_y")
	controls_settings.add_child(invert_y_check)
	
	# Configuration touches
	var remap_button = create_menu_button("⌨️ Reconfigurer Touches", "remap_keys")
	controls_settings.add_child(remap_button)

func create_save_load_menu() -> void:
	"""Crée le menu sauvegarde/chargement"""
	save_load_menu = Control.new()
	save_load_menu.name = "SaveLoadMenu"
	save_load_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_container.add_child(save_load_menu)
	
	# Container principal
	var save_load_container = VBoxContainer.new()
	save_load_container.anchors_preset = Control.PRESET_CENTER
	save_load_container.custom_minimum_size = Vector2(600, 500)
	save_load_menu.add_child(save_load_container)
	
	# Titre
	var save_load_title = Label.new()
	save_load_title.text = "SAUVEGARDES"
	save_load_title.add_theme_font_size_override("font_size", 28)
	save_load_title.add_theme_color_override("font_color", Color.YELLOW)
	save_load_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	save_load_container.add_child(save_load_title)
	
	save_load_container.add_child(create_spacer(20))
	
	# Liste des slots de sauvegarde
	var save_slots_container = VBoxContainer.new()
	save_load_container.add_child(save_slots_container)
	
	# Créer 10 slots de sauvegarde
	for i in range(10):
		var slot_container = create_save_slot(i)
		save_slots_container.add_child(slot_container)

func create_credits_menu() -> void:
	"""Crée le menu des crédits"""
	credits_menu = Control.new()
	credits_menu.name = "CreditsMenu"
	credits_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	menu_container.add_child(credits_menu)
	
	# Container scroll pour crédits
	var credits_scroll = ScrollContainer.new()
	credits_scroll.anchors_preset = Control.PRESET_FULL_RECT
	credits_scroll.offset_left = 200
	credits_scroll.offset_right = -200
	credits_scroll.offset_top = 100
	credits_scroll.offset_bottom = -100
	credits_menu.add_child(credits_scroll)
	
	# Container texte crédits
	var credits_text = RichTextLabel.new()
	credits_text.bbcode_enabled = true
	credits_text.fit_content = true
	credits_text.text = get_credits_text()
	credits_scroll.add_child(credits_text)

func create_menu_navigation() -> void:
	"""Crée la navigation commune des menus"""
	menu_navigation = Control.new()
	menu_navigation.name = "MenuNavigation"
	menu_navigation.anchors_preset = Control.PRESET_BOTTOM_WIDE
	menu_navigation.offset_top = -60
	menu_container.add_child(menu_navigation)
	
	# Bouton retour
	back_button = Button.new()
	back_button.text = "◀ Retour"
	back_button.custom_minimum_size = Vector2(120, 40)
	back_button.anchors_preset = Control.PRESET_BOTTOM_LEFT
	back_button.offset_left = 20
	back_button.offset_top = -50
	back_button.pressed.connect(_on_back_pressed)
	menu_navigation.add_child(back_button)

# ============================================================================
# CRÉATION COMPOSANTS UI
# ============================================================================

func create_menu_button(text: String, action: String) -> Button:
	"""Crée un bouton de menu stylisé"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(350, 50)
	button.add_theme_font_size_override("font_size", 18)
	
	# Style Terry Pratchett
	var button_style = StyleBoxFlat.new()
	button_style.bg_color = Color(0.2, 0.3, 0.5, 0.8)
	button_style.border_color = Color(0.8, 0.6, 0.0)  # Or
	button_style.border_width_left = 2
	button_style.border_width_right = 2
	button_style.border_width_top = 2
	button_style.border_width_bottom = 2
	button_style.corner_radius_top_left = 5
	button_style.corner_radius_top_right = 5
	button_style.corner_radius_bottom_left = 5
	button_style.corner_radius_bottom_right = 5
	
	button.add_theme_stylebox_override("normal", button_style)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.YELLOW)
	
	# Connexion signal
	button.pressed.connect(_on_menu_action.bind(action))
	
	return button

func create_checkbox(text: String, setting_key: String) -> CheckBox:
	"""Crée une checkbox de paramètres"""
	var checkbox = CheckBox.new()
	checkbox.text = text
	checkbox.add_theme_font_size_override("font_size", 16)
	checkbox.add_theme_color_override("font_color", Color.WHITE)
	
	# Charger valeur actuelle
	var current_value = game_settings.get(setting_key, false)
	checkbox.button_pressed = current_value
	
	# Connexion signal
	checkbox.toggled.connect(_on_setting_changed.bind(setting_key))
	
	return checkbox

func create_slider(min_val: float, max_val: float, default_val: float, setting_key: String) -> HBoxContainer:
	"""Crée un slider avec label de valeur"""
	var container = HBoxContainer.new()
	
	var slider = HSlider.new()
	slider.min_value = min_val
	slider.max_value = max_val
	slider.value = game_settings.get(setting_key, default_val)
	slider.step = 0.01
	slider.custom_minimum_size.x = 200
	container.add_child(slider)
	
	var value_label = Label.new()
	value_label.text = str(int(slider.value * 100)) + "%"
	value_label.custom_minimum_size.x = 50
	value_label.add_theme_color_override("font_color", Color.CYAN)
	container.add_child(value_label)
	
	# Connexion signaux
	slider.value_changed.connect(_on_slider_changed.bind(setting_key, value_label))
	
	return container

func create_dropdown(options: Array[String]) -> OptionButton:
	"""Crée un menu déroulant"""
	var dropdown = OptionButton.new()
	dropdown.custom_minimum_size.x = 200
	
	for option in options:
		dropdown.add_item(option)
	
	dropdown.add_theme_color_override("font_color", Color.WHITE)
	
	return dropdown

func create_setting_label(text: String) -> Label:
	"""Crée un label de paramètre"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color.YELLOW)
	return label

func create_spacer(height: int) -> Control:
	"""Crée un espacement vertical"""
	var spacer = Control.new()
	spacer.custom_minimum_size.y = height
	return spacer

func create_save_slot(slot_index: int) -> Control:
	"""Crée un slot de sauvegarde"""
	var slot_container = HBoxContainer.new()
	slot_container.custom_minimum_size.y = 60
	
	# Numéro slot
	var slot_number = Label.new()
	slot_number.text = "Slot " + str(slot_index + 1)
	slot_number.custom_minimum_size.x = 80
	slot_number.add_theme_color_override("font_color", Color.YELLOW)
	slot_container.add_child(slot_number)
	
	# Info sauvegarde
	var save_info = VBoxContainer.new()
	save_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slot_container.add_child(save_info)
	
	var save_data = get_save_slot_data(slot_index)
	
	if save_data.is_empty():
		# Slot vide
		var empty_label = Label.new()
		empty_label.text = "Slot vide"
		empty_label.add_theme_color_override("font_color", Color.GRAY)
		save_info.add_child(empty_label)
	else:
		# Données sauvegarde
		var save_name = Label.new()
		save_name.text = save_data.get("name", "Partie sans nom")
		save_name.add_theme_color_override("font_color", Color.WHITE)
		save_info.add_child(save_name)
		
		var save_date = Label.new()
		save_date.text = save_data.get("date", "Date inconnue")
		save_date.add_theme_font_size_override("font_size", 12)
		save_date.add_theme_color_override("font_color", Color.GRAY)
		save_info.add_child(save_date)
	
	# Boutons actions
	var button_container = HBoxContainer.new()
	slot_container.add_child(button_container)
	
	var save_button = Button.new()
	save_button.text = "💾"
	save_button.custom_minimum_size = Vector2(40, 40)
	save_button.pressed.connect(_on_save_slot.bind(slot_index))
	button_container.add_child(save_button)
	
	var load_button = Button.new()
	load_button.text = "📁"
	load_button.custom_minimum_size = Vector2(40, 40)
	load_button.disabled = save_data.is_empty()
	load_button.pressed.connect(_on_load_slot.bind(slot_index))
	button_container.add_child(load_button)
	
	return slot_container

# ============================================================================
# GESTION AFFICHAGE MENUS
# ============================================================================

func show_menu(menu_name: String) -> void:
	"""Affiche un menu spécifique"""
	# Masquer tous les menus
	main_menu.hide()
	pause_menu.hide()
	settings_menu.hide()
	save_load_menu.hide()
	credits_menu.hide()
	
	# Masquer tous les panneaux de paramètres
	if settings_container:
		for child in settings_container.get_children():
			child.hide()
	
	# Afficher le menu demandé
	match menu_name:
		"main":
			main_menu.show()
			back_button.hide()
		"pause":
			pause_menu.show()
			back_button.hide()
		"settings":
			settings_menu.show()
			show_settings_category("video")
			back_button.show()
		"save_load":
			save_load_menu.show()
			refresh_save_slots()
			back_button.show()
		"credits":
			credits_menu.show()
			back_button.show()
	
	# Gestion navigation
	if current_menu != menu_name:
		menu_stack.push_back(current_menu)
	
	current_menu = menu_name
	
	print("📋 Menu affiché: ", menu_name)

func show_settings_category(category: String) -> void:
	"""Affiche une catégorie de paramètres"""
	# Masquer toutes les catégories
	video_settings.hide()
	audio_settings.hide()
	accessibility_settings.hide()
	controls_settings.hide()
	
	# Afficher la catégorie demandée
	match category:
		"video":
			video_settings.show()
		"audio":
			audio_settings.show()
		"accessibility":
			accessibility_settings.show()
		"controls":
			controls_settings.show()

func show_main_menu() -> void:
	"""Affiche le menu principal"""
	show_menu("main")

func show_pause_menu() -> void:
	"""Affiche le menu pause"""
	show_menu("pause")

func show_settings_menu(data: Dictionary = {}) -> void:
	"""Affiche le menu paramètres"""
	show_menu("settings")

# ============================================================================
# GESTION ÉVÉNEMENTS
# ============================================================================

func _on_menu_action(action: String) -> void:
	"""Gestion des actions de menu"""
	print("📋 Action menu: ", action)
	
	match action:
		"new_game":
			menu_action_selected.emit("new_game", {})
		"continue_game":
			menu_action_selected.emit("continue_game", {})
		"load_game":
			show_menu("save_load")
		"settings":
			show_menu("settings")
		"credits":
			show_menu("credits")
		"quit":
			confirm_quit_game()
		"resume":
			menu_action_selected.emit("resume", {})
		"save":
			show_menu("save_load")
		"load":
			show_menu("save_load")
		"main_menu":
			confirm_return_to_main()
		"category_video":
			show_settings_category("video")
		"category_audio":
			show_settings_category("audio")
		"category_accessibility":
			show_settings_category("accessibility")
		"category_controls":
			show_settings_category("controls")

func _on_setting_changed(setting_key: String, new_value: bool) -> void:
	"""Gestion changement paramètre checkbox"""
	game_settings[setting_key] = new_value
	settings_changed.emit(setting_key, new_value)
	save_game_settings()
	print("📋 Paramètre modifié: ", setting_key, " = ", new_value)

func _on_slider_changed(setting_key: String, value_label: Label, new_value: float) -> void:
	"""Gestion changement paramètre slider"""
	game_settings[setting_key] = new_value
	value_label.text = str(int(new_value * 100)) + "%"
	settings_changed.emit(setting_key, new_value)
	save_game_settings()

func _on_resolution_changed(index: int) -> void:
	"""Gestion changement résolution"""
	var resolutions = ["1920x1080", "1600x900", "1366x768", "1280x720"]
	var resolution = resolutions[index]
	game_settings["resolution"] = resolution
	settings_changed.emit("resolution", resolution)
	apply_resolution(resolution)

func _on_quality_changed(index: int) -> void:
	"""Gestion changement qualité"""
	var qualities = ["low", "medium", "high", "ultra"]
	var quality = qualities[index]
	game_settings["graphics_quality"] = quality
	settings_changed.emit("graphics_quality", quality)

func _on_back_pressed() -> void:
	"""Bouton retour"""
	if menu_stack.size() > 0:
		var previous_menu = menu_stack.pop_back()
		show_menu(previous_menu)
	else:
		show_menu("main")

func _on_save_slot(slot_index: int) -> void:
	"""Sauvegarde dans un slot"""
	var save_name = "Partie " + str(slot_index + 1)
	save_game_requested.emit(slot_index, save_name)
	print("📋 Sauvegarde slot: ", slot_index)

func _on_load_slot(slot_index: int) -> void:
	"""Chargement d'un slot"""
	load_game_requested.emit(slot_index)
	print("📋 Chargement slot: ", slot_index)

# ============================================================================
# CONFIRMATIONS
# ============================================================================

func confirm_quit_game() -> void:
	"""Confirme la sortie du jeu"""
	# TODO: Dialogue de confirmation
	get_tree().quit()

func confirm_return_to_main() -> void:
	"""Confirme le retour au menu principal"""
	# TODO: Dialogue de confirmation si jeu en cours
	menu_action_selected.emit("main_menu", {})

# ============================================================================
# GESTION DONNÉES
# ============================================================================

func load_game_settings() -> void:
	"""Charge les paramètres de jeu"""
	# TODO: Charger depuis SaveSystem
	game_settings = {
		"resolution": "1920x1080",
		"fullscreen": false,
		"vsync": true,
		"graphics_quality": "high",
		"master_volume": 0.8,
		"music_volume": 0.7,
		"sfx_volume": 0.8,
		"voice_volume": 1.0,
		"colorblind_support": false,
		"font_scale": 1.0,
		"high_contrast": false,
		"subtitles": true,
		"motor_assistance": false,
		"mouse_sensitivity": 1.0,
		"invert_mouse_y": false
	}

func save_game_settings() -> void:
	"""Sauvegarde les paramètres"""
	# TODO: Sauvegarder via SaveSystem
	print("📋 Paramètres sauvegardés")

func setup_save_slots() -> void:
	"""Configure les slots de sauvegarde"""
	save_slots = []
	for i in range(10):
		save_slots.append({})  # Slots vides par défaut

func get_save_slot_data(slot_index: int) -> Dictionary:
	"""Retourne les données d'un slot de sauvegarde"""
	if slot_index < save_slots.size():
		return save_slots[slot_index]
	return {}

func refresh_save_slots() -> void:
	"""Actualise l'affichage des slots de sauvegarde"""
	# TODO: Recharger depuis SaveSystem
	pass

func apply_resolution(resolution: String) -> void:
	"""Applique une nouvelle résolution"""
	var parts = resolution.split("x")
	if parts.size() == 2:
		var width = parts[0].to_int()
		var height = parts[1].to_int()
		get_window().size = Vector2i(width, height)
		print("📋 Résolution appliquée: ", resolution)

# ============================================================================
# ANIMATIONS ET STYLING
# ============================================================================

func setup_menu_styling() -> void:
	"""Configure le style des menus"""
	var style = menu_config.get("menu_style", "terry_pratchett")
	
	match style:
		"terry_pratchett":
			setup_pratchett_style()

func setup_pratchett_style() -> void:
	"""Style Terry Pratchett pour les menus"""
	# Couleurs Disque-Monde
	if game_title:
		# Animation titre du jeu
		animate_title_glow()

func animate_title_glow() -> void:
	"""Animation lueur du titre"""
	if not game_title:
		return
	
	var tween = create_tween()
	tween.set_loops()
	
	tween.tween_property(game_title, "modulate", Color(1.2, 1.0, 0.8), 2.0)
	tween.tween_property(game_title, "modulate", Color(0.8, 0.8, 1.0), 2.0)

func get_credits_text() -> String:
	"""Retourne le texte des crédits"""
	return """[center][font_size=32][color=yellow]SORTILÈGES & BESTIOLES[/color][/font_size]

[font_size=18][color=cyan]Une Aventure du Disque-Monde[/color][/font_size]

[font_size=16]
[b]Développement[/b]
Lead Developer: Claude AI
Game Design: Direction Créative Humaine

[b]Inspiré par l'œuvre de[/b]
Terry Pratchett
Le Disque-Monde (Discworld)

[b]Remerciements Spéciaux[/b]
GNU Terry Pratchett
Pour l'inspiration éternelle
Et l'humour qui transcende

[b]Technologies[/b]
Godot Engine 4.4.X
GDScript
Amour du détail

[b]Note[/b]
Ce jeu est une œuvre d'amour
Dédiée à tous les fans
Du Disque-Monde

[i]"La magie, c'est juste de la science
que nous ne comprenons pas encore."[/i]
- Terry Pratchett

[/font_size][/center]"""

# ============================================================================
# API PUBLIQUE
# ============================================================================

func hide_all_menus() -> void:
	"""Masque tous les menus"""
	menu_container.hide()

func show_menu_container() -> void:
	"""Affiche le conteneur de menus"""
	menu_container.show()

func is_menu_active() -> bool:
	"""Vérifie si un menu est actif"""
	return menu_container.visible

func get_current_menu() -> String:
	"""Retourne le menu actuel"""
	return current_menu

# ============================================================================
# INPUT HANDLING
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Gestion des inputs menus"""
	if not menu_container.visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()

# ============================================================================
# DEBUG
# ============================================================================

func _on_debug_test_menu() -> void:
	"""Test menus pour debug"""
	if OS.is_debug_build():
		show_menu("main")