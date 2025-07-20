# ============================================================================
# 🔮 ObservationUI.gd - Interface Carnet Magique d'Observation
# ============================================================================
# STATUS: ✅ COMPLET | Sous-système UIManager
# PRIORITY: 🔴 CRITICAL - Mécanique unique du jeu
# DEPENDENCIES: UIManager, ObservationManager

class_name ObservationUI
extends Control

## Interface d'observation et carnet magique pour "Sortilèges & Bestioles"
## Système unique : Observer les créatures pour les faire évoluer
## Style carnet manuscrit avec dessins procéduraux Terry Pratchett

# ============================================================================
# SIGNAUX
# ============================================================================

signal creature_observed(creature_id: String, observation_data: Dictionary)
signal notebook_page_changed(page_number: int, creature_id: String)
signal observation_level_increased(creature_id: String, new_level: int)
signal evolution_triggered(creature_id: String, evolution_stage: int)
signal sketch_completed(creature_id: String, sketch_data: Dictionary)

# ============================================================================
# CONFIGURATION
# ============================================================================

var observation_config: Dictionary = {}
var notebook_data: Dictionary = {}
var current_creature_id: String = ""
var current_observation_level: int = 0
var is_observing: bool = false
var zoom_level: float = 1.0
var max_zoom: float = 5.0

# ============================================================================
# ÉLÉMENTS UI PRINCIPAUX
# ============================================================================

## Conteneur principal de l'interface d'observation
@onready var observation_panel: Control
@onready var notebook_container: Control
@onready var observation_viewport: Control
@onready var creature_details_panel: Control

## Interface d'observation en temps réel
@onready var observation_overlay: Control
@onready var zoom_controls: Control
@onready var observation_progress: ProgressBar
@onready var observation_timer: Label
@onready var creature_info_popup: Control

## Carnet magique
@onready var notebook_background: NinePatchRect
@onready var notebook_pages: Control
@onready var creature_sketch: Control
@onready var observation_notes: RichTextLabel
@onready var page_navigation: Control

## Détails créature
@onready var creature_name_label: Label
@onready var creature_species_label: Label
@onready var evolution_stage_indicator: Control
@onready var behavior_notes: RichTextLabel
@onready var magic_aura_display: Control

## Effets visuels
@onready var magic_lens: Control
@onready var observation_particles: CPUParticles2D
@onready var evolution_flash: ColorRect
@onready var sketch_animation: AnimationPlayer

# ============================================================================
# NAVIGATION ET PAGINATION
# ============================================================================

@onready var page_counter: Label
@onready var previous_page_button: Button
@onready var next_page_button: Button
@onready var creature_index: ItemList
@onready var search_bar: LineEdit

var current_page: int = 0
var total_pages: int = 0
var creatures_per_page: int = 1
var discovered_creatures: Array[String] = []

# ============================================================================
# TYPES & ENUMS
# ============================================================================

enum ObservationMode {
	LIVE_OBSERVATION = 0,  ## Observation en temps réel
	NOTEBOOK_VIEWING = 1,  ## Consultation du carnet
	SKETCH_MODE = 2,       ## Mode dessin/annotation
	EVOLUTION_VIEWING = 3  ## Visualisation évolution
}

enum SketchQuality {
	ROUGH = 0,     ## Croquis basique
	DETAILED = 1,  ## Dessin détaillé
	MASTERWORK = 2 ## Chef-d'œuvre
}

enum CreatureCategory {
	MUNDANE = 0,      ## Créatures ordinaires
	MAGICAL = 1,      ## Créatures magiques
	EVOLVED = 2,      ## Créatures évoluées
	LEGENDARY = 3,    ## Créatures légendaires
	UNKNOWN = 4       ## Non identifiées
}

# ============================================================================
# INITIALISATION
# ============================================================================

func initialize(parent_container: Control, config: Dictionary) -> void:
	"""Initialise le système ObservationUI"""
	observation_config = config
	
	# Créer l'interface d'observation
	create_observation_interface(parent_container)
	setup_notebook_styling()
	setup_observation_controls()
	load_discovered_creatures()
	
	print("🔮 ObservationUI: Carnet magique initialisé")

func create_observation_interface(parent: Control) -> void:
	"""Crée l'interface complète d'observation"""
	# Conteneur principal
	observation_panel = Control.new()
	observation_panel.name = "ObservationPanel"
	observation_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(observation_panel)
	
	# Overlay d'observation temps réel
	observation_overlay = Control.new()
	observation_overlay.name = "ObservationOverlay"
	observation_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	observation_panel.add_child(observation_overlay)
	
	create_observation_overlay()
	
	# Carnet magique
	notebook_container = Control.new()
	notebook_container.name = "NotebookContainer"
	notebook_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	observation_panel.add_child(notebook_container)
	
	create_magical_notebook()
	
	# Masquer par défaut
	observation_panel.hide()

func create_observation_overlay() -> void:
	"""Crée l'overlay d'observation en temps réel"""
	# Lentille magique d'observation
	magic_lens = Control.new()
	magic_lens.name = "MagicLens"
	magic_lens.custom_minimum_size = Vector2(200, 200)
	magic_lens.anchors_preset = Control.PRESET_CENTER
	observation_overlay.add_child(magic_lens)
	
	# Cercle de lentille magique
	var lens_texture = TextureRect.new()
	lens_texture.texture = load("res://ui/textures/magic_lens.png")
	lens_texture.anchors_preset = Control.PRESET_FULL_RECT
	magic_lens.add_child(lens_texture)
	
	# Contrôles de zoom
	zoom_controls = VBoxContainer.new()
	zoom_controls.name = "ZoomControls"
	zoom_controls.anchors_preset = Control.PRESET_TOP_RIGHT
	zoom_controls.offset_left = -120
	zoom_controls.offset_top = 20
	observation_overlay.add_child(zoom_controls)
	
	var zoom_in_button = Button.new()
	zoom_in_button.text = "🔍+"
	zoom_in_button.custom_minimum_size = Vector2(40, 40)
	zoom_in_button.pressed.connect(_on_zoom_in)
	zoom_controls.add_child(zoom_in_button)
	
	var zoom_out_button = Button.new()
	zoom_out_button.text = "🔍-"
	zoom_out_button.custom_minimum_size = Vector2(40, 40)
	zoom_out_button.pressed.connect(_on_zoom_out)
	zoom_controls.add_child(zoom_out_button)
	
	# Barre de progression d'observation
	observation_progress = ProgressBar.new()
	observation_progress.name = "ObservationProgress"
	observation_progress.anchors_preset = Control.PRESET_BOTTOM_WIDE
	observation_progress.offset_left = 100
	observation_progress.offset_right = -100
	observation_progress.offset_top = -60
	observation_progress.offset_bottom = -40
	observation_progress.max_value = 100
	observation_progress.value = 0
	observation_overlay.add_child(observation_progress)
	
	# Label temps d'observation
	observation_timer = Label.new()
	observation_timer.name = "ObservationTimer"
	observation_timer.text = "Observation: 0s"
	observation_timer.anchors_preset = Control.PRESET_BOTTOM_LEFT
	observation_timer.offset_left = 20
	observation_timer.offset_top = -30
	observation_overlay.add_child(observation_timer)
	
	# Popup info créature
	creature_info_popup = Control.new()
	creature_info_popup.name = "CreatureInfoPopup"
	creature_info_popup.custom_minimum_size = Vector2(300, 150)
	creature_info_popup.anchors_preset = Control.PRESET_TOP_LEFT
	creature_info_popup.offset_left = 20
	creature_info_popup.offset_top = 20
	observation_overlay.add_child(creature_info_popup)
	
	create_creature_info_popup()
	
	# Particules magiques d'observation
	observation_particles = CPUParticles2D.new()
	observation_particles.name = "ObservationParticles"
	observation_particles.emitting = false
	observation_particles.amount = 30
	observation_particles.lifetime = 3.0
	observation_particles.texture = load("res://vfx/magic_particle.png")
	observation_particles.color = Color(0.6, 0.4, 1.0, 0.8)  # Octarine
	observation_particles.position = Vector2(100, 100)
	observation_overlay.add_child(observation_particles)

func create_creature_info_popup() -> void:
	"""Crée le popup d'information créature"""
	# Background du popup
	var popup_bg = NinePatchRect.new()
	popup_bg.texture = load("res://ui/textures/info_popup_bg.png")
	popup_bg.anchors_preset = Control.PRESET_FULL_RECT
	creature_info_popup.add_child(popup_bg)
	
	# Container info
	var info_container = VBoxContainer.new()
	info_container.anchors_preset = Control.PRESET_FULL_RECT
	info_container.offset_left = 10
	info_container.offset_right = -10
	info_container.offset_top = 10
	info_container.offset_bottom = -10
	creature_info_popup.add_child(info_container)
	
	# Nom de la créature
	creature_name_label = Label.new()
	creature_name_label.name = "CreatureName"
	creature_name_label.text = "Créature Inconnue"
	creature_name_label.add_theme_font_size_override("font_size", 16)
	creature_name_label.add_theme_color_override("font_color", Color.YELLOW)
	info_container.add_child(creature_name_label)
	
	# Espèce
	creature_species_label = Label.new()
	creature_species_label.name = "CreatureSpecies"
	creature_species_label.text = "Espèce: ???"
	creature_species_label.add_theme_color_override("font_color", Color.CYAN)
	info_container.add_child(creature_species_label)
	
	# Indicateur stade évolution
	evolution_stage_indicator = HBoxContainer.new()
	evolution_stage_indicator.name = "EvolutionIndicator"
	info_container.add_child(evolution_stage_indicator)
	
	# Créer 4 étoiles pour les stades d'évolution
	for i in range(4):
		var star = Label.new()
		star.text = "☆"
		star.add_theme_font_size_override("font_size", 20)
		star.add_theme_color_override("font_color", Color.GRAY)
		evolution_stage_indicator.add_child(star)
	
	# Masquer par défaut
	creature_info_popup.hide()

func create_magical_notebook() -> void:
	"""Crée l'interface du carnet magique"""
	# Background carnet (style manuscrit)
	notebook_background = NinePatchRect.new()
	notebook_background.name = "NotebookBackground"
	notebook_background.texture = load("res://ui/textures/notebook_page.png")
	notebook_background.anchors_preset = Control.PRESET_CENTER
	notebook_background.custom_minimum_size = Vector2(800, 600)
	notebook_container.add_child(notebook_background)
	
	# Container pages
	notebook_pages = Control.new()
	notebook_pages.name = "NotebookPages"
	notebook_pages.anchors_preset = Control.PRESET_FULL_RECT
	notebook_pages.offset_left = 50
	notebook_pages.offset_right = -50
	notebook_pages.offset_top = 50
	notebook_pages.offset_bottom = -100
	notebook_background.add_child(notebook_pages)
	
	create_notebook_content()
	create_page_navigation()
	
	# Animation carnet
	sketch_animation = AnimationPlayer.new()
	sketch_animation.name = "SketchAnimation"
	notebook_pages.add_child(sketch_animation)

func create_notebook_content() -> void:
	"""Crée le contenu des pages du carnet"""
	# Container principal du contenu
	var content_container = HSplitContainer.new()
	content_container.anchors_preset = Control.PRESET_FULL_RECT
	notebook_pages.add_child(content_container)
	
	# Zone de dessin/croquis
	creature_sketch = Control.new()
	creature_sketch.name = "CreatureSketch"
	creature_sketch.custom_minimum_size = Vector2(350, 400)
	content_container.add_child(creature_sketch)
	
	# Background croquis
	var sketch_bg = ColorRect.new()
	sketch_bg.color = Color(0.95, 0.95, 0.9, 1.0)  # Papier légèrement jauni
	sketch_bg.anchors_preset = Control.PRESET_FULL_RECT
	creature_sketch.add_child(sketch_bg)
	
	# Zone notes d'observation
	var notes_container = VBoxContainer.new()
	notes_container.custom_minimum_size = Vector2(350, 400)
	content_container.add_child(notes_container)
	
	# Titre section
	var notes_title = Label.new()
	notes_title.text = "Notes d'Observation"
	notes_title.add_theme_font_size_override("font_size", 18)
	notes_title.add_theme_color_override("font_color", Color(0.4, 0.2, 0.1))  # Encre brune
	notes_container.add_child(notes_title)
	
	# Zone de texte notes
	observation_notes = RichTextLabel.new()
	observation_notes.name = "ObservationNotes"
	observation_notes.bbcode_enabled = true
	observation_notes.custom_minimum_size.y = 300
	observation_notes.add_theme_color_override("default_color", Color(0.2, 0.1, 0.0))
	notes_container.add_child(observation_notes)
	
	# Détails comportement
	behavior_notes = RichTextLabel.new()
	behavior_notes.name = "BehaviorNotes"
	behavior_notes.bbcode_enabled = true
	behavior_notes.custom_minimum_size.y = 100
	behavior_notes.add_theme_color_override("default_color", Color(0.3, 0.2, 0.1))
	notes_container.add_child(behavior_notes)

func create_page_navigation() -> void:
	"""Crée la navigation entre les pages"""
	page_navigation = HBoxContainer.new()
	page_navigation.name = "PageNavigation"
	page_navigation.anchors_preset = Control.PRESET_BOTTOM_WIDE
	page_navigation.offset_top = -40
	page_navigation.offset_left = 20
	page_navigation.offset_right = -20
	notebook_background.add_child(page_navigation)
	
	# Bouton page précédente
	previous_page_button = Button.new()
	previous_page_button.text = "◀ Page Précédente"
	previous_page_button.pressed.connect(_on_previous_page)
	page_navigation.add_child(previous_page_button)
	
	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_navigation.add_child(spacer)
	
	# Compteur pages
	page_counter = Label.new()
	page_counter.text = "Page 1 / 1"
	page_counter.add_theme_color_override("font_color", Color(0.4, 0.2, 0.1))
	page_navigation.add_child(page_counter)
	
	# Spacer
	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	page_navigation.add_child(spacer2)
	
	# Bouton page suivante
	next_page_button = Button.new()
	next_page_button.text = "Page Suivante ▶"
	next_page_button.pressed.connect(_on_next_page)
	page_navigation.add_child(next_page_button)
	
	# Index des créatures (sidebar)
	create_creature_index()

func create_creature_index() -> void:
	"""Crée l'index des créatures découvertes"""
	var index_container = VBoxContainer.new()
	index_container.name = "CreatureIndex"
	index_container.anchors_preset = Control.PRESET_LEFT_WIDE
	index_container.offset_right = 200
	index_container.offset_left = -220
	index_container.offset_top = 20
	index_container.offset_bottom = -20
	notebook_background.add_child(index_container)
	
	# Titre index
	var index_title = Label.new()
	index_title.text = "Créatures Découvertes"
	index_title.add_theme_font_size_override("font_size", 14)
	index_title.add_theme_color_override("font_color", Color(0.4, 0.2, 0.1))
	index_container.add_child(index_title)
	
	# Barre de recherche
	search_bar = LineEdit.new()
	search_bar.placeholder_text = "Rechercher..."
	search_bar.text_changed.connect(_on_search_text_changed)
	index_container.add_child(search_bar)
	
	# Liste créatures
	creature_index = ItemList.new()
	creature_index.name = "CreatureList"
	creature_index.custom_minimum_size.y = 400
	creature_index.item_selected.connect(_on_creature_selected)
	index_container.add_child(creature_index)

func setup_notebook_styling() -> void:
	"""Configure le style visuel du carnet"""
	var style = observation_config.get("notebook_style", "magical")
	
	match style:
		"magical":
			setup_magical_notebook_style()
		"scientific":
			setup_scientific_notebook_style()
		"pratchett":
			setup_pratchett_notebook_style()

func setup_magical_notebook_style() -> void:
	"""Style carnet magique Terry Pratchett"""
	# Couleurs parchemin magique
	if notebook_background:
		notebook_background.modulate = Color(1.0, 0.95, 0.8)  # Parchemin légèrement doré
	
	# Effets lumineux magiques
	var magic_glow = ColorRect.new()
	magic_glow.color = Color(0.6, 0.4, 1.0, 0.1)  # Lueur octarine faible
	magic_glow.anchors_preset = Control.PRESET_FULL_RECT
	if notebook_background:
		notebook_background.add_child(magic_glow)
		notebook_background.move_child(magic_glow, 0)  # Arrière-plan

func setup_observation_controls() -> void:
	"""Configure les contrôles d'observation"""
	var zoom_sensitivity = observation_config.get("zoom_sensitivity", 1.0)
	max_zoom = observation_config.get("max_zoom", 5.0)

# ============================================================================
# GESTION OBSERVATION TEMPS RÉEL
# ============================================================================

func start_live_observation(creature_id: String) -> void:
	"""Démarre l'observation d'une créature en temps réel"""
	current_creature_id = creature_id
	is_observing = true
	
	# Charger les données de la créature
	load_creature_data(creature_id)
	
	# Afficher l'overlay d'observation
	observation_overlay.show()
	notebook_container.hide()
	
	# Démarrer particules magiques
	observation_particles.emitting = true
	
	# Animation lentille magique
	animate_magic_lens_activation()
	
	# Afficher info créature
	update_creature_info_display()
	
	print("🔮 Observation démarrée: ", creature_id)

func update_observation_progress(delta: float) -> void:
	"""Met à jour la progression de l'observation"""
	if not is_observing:
		return
	
	var observation_time = observation_progress.value + (delta * 10)  # 10 points par seconde
	observation_progress.value = min(observation_time, 100)
	
	# Mettre à jour timer
	observation_timer.text = "Observation: " + str(int(observation_time / 10)) + "s"
	
	# Vérifier paliers d'observation
	check_observation_milestones(observation_time)
	
	# Observation complète
	if observation_progress.value >= 100:
		complete_observation()

func check_observation_milestones(progress: float) -> void:
	"""Vérifie les paliers d'observation"""
	var new_level = int(progress / 20) + 1  # Niveau 1-5
	
	if new_level > current_observation_level:
		current_observation_level = new_level
		trigger_observation_milestone(new_level)

func trigger_observation_milestone(level: int) -> void:
	"""Déclenche les effets d'un palier d'observation"""
	print("🔮 Palier d'observation atteint: ", level)
	
	# Effets visuels selon le niveau
	match level:
		1:
			reveal_basic_info()
		2:
			reveal_species_info()
		3:
			reveal_behavior_patterns()
		4:
			reveal_magical_properties()
		5:
			reveal_evolution_potential()
	
	# Animation flash
	animate_discovery_flash()
	
	# Particules plus intenses
	intensify_observation_particles()
	
	observation_level_increased.emit(current_creature_id, level)

func complete_observation() -> void:
	"""Termine l'observation et met à jour le carnet"""
	print("🔮 Observation complète: ", current_creature_id)
	
	is_observing = false
	observation_particles.emitting = false
	
	# Ajouter/mettre à jour dans le carnet
	add_creature_to_notebook(current_creature_id)
	
	# Vérifier évolution possible
	check_evolution_trigger()
	
	# Transition vers le carnet
	transition_to_notebook_view()

func check_evolution_trigger() -> void:
	"""Vérifie si l'observation déclenche une évolution"""
	var observation_manager = get_node_or_null("/root/Observation")
	if observation_manager and observation_manager.has_method("can_creature_evolve"):
		if observation_manager.can_creature_evolve(current_creature_id):
			trigger_creature_evolution()

func trigger_creature_evolution() -> void:
	"""Déclenche l'évolution d'une créature"""
	print("🔮 Évolution déclenchée: ", current_creature_id)
	
	# Animation flash évolution
	animate_evolution_flash()
	
	# Particules spéciales évolution
	trigger_evolution_particles()
	
	evolution_triggered.emit(current_creature_id, current_observation_level)

# ============================================================================
# GESTION CARNET MAGIQUE
# ============================================================================

func show_observation_interface(data: Dictionary = {}) -> void:
	"""Affiche l'interface d'observation"""
	observation_panel.show()
	
	var mode = data.get("mode", "notebook")
	var creature_id = data.get("creature_id", "")
	
	if mode == "live" and creature_id != "":
		start_live_observation(creature_id)
	else:
		show_notebook_view()

func show_notebook_view() -> void:
	"""Affiche la vue carnet"""
	observation_overlay.hide()
	notebook_container.show()
	
	# Charger la première page ou la dernière consultée
	load_notebook_page(current_page)
	
	# Mettre à jour l'index
	update_creature_index()

func load_notebook_page(page_number: int) -> void:
	"""Charge une page du carnet"""
	if discovered_creatures.is_empty():
		show_empty_notebook()
		return
	
	current_page = clamp(page_number, 0, discovered_creatures.size() - 1)
	var creature_id = discovered_creatures[current_page]
	
	# Charger les données créature
	load_creature_data(creature_id)
	
	# Afficher croquis
	display_creature_sketch(creature_id)
	
	# Afficher notes
	display_observation_notes(creature_id)
	
	# Mettre à jour navigation
	update_page_navigation()
	
	notebook_page_changed.emit(current_page, creature_id)

func display_creature_sketch(creature_id: String) -> void:
	"""Affiche le croquis d'une créature"""
	# Nettoyer croquis précédent
	for child in creature_sketch.get_children():
		if child.name.begins_with("sketch_"):
			child.queue_free()
	
	# Charger données créature
	var creature_data = get_creature_display_data(creature_id)
	
	# Créer nouveau croquis
	var sketch_texture = TextureRect.new()
	sketch_texture.name = "sketch_" + creature_id
	sketch_texture.texture = load(creature_data.get("sketch_path", "res://ui/sketches/unknown.png"))
	sketch_texture.anchors_preset = Control.PRESET_CENTER
	sketch_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	creature_sketch.add_child(sketch_texture)
	
	# Animation d'apparition du croquis
	animate_sketch_appearance(sketch_texture)

func display_observation_notes(creature_id: String) -> void:
	"""Affiche les notes d'observation"""
	var creature_data = get_creature_display_data(creature_id)
	
	# Notes principales
	var notes_text = "[font_size=14][color=#3D2914]"
	notes_text += "[b]" + creature_data.get("name", "Créature Inconnue") + "[/b]\n\n"
	notes_text += "[i]Espèce:[/i] " + creature_data.get("species", "Non identifiée") + "\n"
	notes_text += "[i]Première observation:[/i] " + creature_data.get("discovery_date", "Inconnue") + "\n\n"
	notes_text += creature_data.get("description", "Aucune note disponible.")
	notes_text += "[/color][/font_size]"
	
	observation_notes.text = notes_text
	
	# Notes comportementales
	var behavior_text = "[font_size=12][color=#5D4A34]"
	behavior_text += "[b]Comportement observé:[/b]\n"
	behavior_text += creature_data.get("behavior", "Comportement non documenté.")
	behavior_text += "[/color][/font_size]"
	
	behavior_notes.text = behavior_text

func add_creature_to_notebook(creature_id: String) -> void:
	"""Ajoute une créature au carnet"""
	if creature_id in discovered_creatures:
		# Mettre à jour créature existante
		update_creature_entry(creature_id)
	else:
		# Nouvelle découverte
		discovered_creatures.append(creature_id)
		create_new_creature_entry(creature_id)
		
		# Animation nouvelle découverte
		animate_new_discovery()
	
	# Sauvegarder découvertes
	save_discovered_creatures()

func create_new_creature_entry(creature_id: String) -> void:
	"""Crée une nouvelle entrée de créature"""
	# Générer sketch procédural
	generate_procedural_sketch(creature_id)
	
	# Créer notes initiales
	create_initial_observation_notes(creature_id)
	
	print("🔮 Nouvelle créature ajoutée au carnet: ", creature_id)

func update_creature_entry(creature_id: String) -> void:
	"""Met à jour une entrée existante"""
	# Améliorer la qualité du sketch si observation approfondie
	improve_sketch_quality(creature_id)
	
	# Ajouter nouvelles notes comportementales
	add_behavior_observations(creature_id)

# ============================================================================
# NAVIGATION ET RECHERCHE
# ============================================================================

func _on_previous_page() -> void:
	"""Page précédente"""
	if current_page > 0:
		load_notebook_page(current_page - 1)

func _on_next_page() -> void:
	"""Page suivante"""
	if current_page < discovered_creatures.size() - 1:
		load_notebook_page(current_page + 1)

func _on_creature_selected(index: int) -> void:
	"""Sélection créature dans l'index"""
	if index < discovered_creatures.size():
		load_notebook_page(index)

func _on_search_text_changed(text: String) -> void:
	"""Recherche dans le carnet"""
	filter_creature_index(text)

func filter_creature_index(search_text: String) -> void:
	"""Filtre l'index selon le texte de recherche"""
	creature_index.clear()
	
	for creature_id in discovered_creatures:
		var creature_data = get_creature_display_data(creature_id)
		var name = creature_data.get("name", creature_id).to_lower()
		var species = creature_data.get("species", "").to_lower()
		
		if search_text.is_empty() or name.contains(search_text.to_lower()) or species.contains(search_text.to_lower()):
			creature_index.add_item(creature_data.get("name", creature_id))

func update_creature_index() -> void:
	"""Met à jour l'index des créatures"""
	creature_index.clear()
	
	for creature_id in discovered_creatures:
		var creature_data = get_creature_display_data(creature_id)
		var display_name = creature_data.get("name", creature_id)
		
		# Ajouter indicateur évolution
		var evolution_stage = creature_data.get("evolution_stage", 1)
		var evolution_stars = "★".repeat(evolution_stage) + "☆".repeat(4 - evolution_stage)
		
		creature_index.add_item(display_name + " " + evolution_stars)

func update_page_navigation() -> void:
	"""Met à jour la navigation des pages"""
	total_pages = max(1, discovered_creatures.size())
	page_counter.text = "Page " + str(current_page + 1) + " / " + str(total_pages)
	
	previous_page_button.disabled = (current_page <= 0)
	next_page_button.disabled = (current_page >= total_pages - 1)

# ============================================================================
# CONTRÔLES ZOOM ET INTERACTION
# ============================================================================

func _on_zoom_in() -> void:
	"""Zoom avant"""
	zoom_level = min(zoom_level * 1.2, max_zoom)
	apply_zoom_level()

func _on_zoom_out() -> void:
	"""Zoom arrière"""
	zoom_level = max(zoom_level / 1.2, 1.0)
	apply_zoom_level()

func apply_zoom_level() -> void:
	"""Applique le niveau de zoom"""
	if magic_lens:
		magic_lens.scale = Vector2.ONE * zoom_level
	
	# Ajuster particules selon zoom
	if observation_particles:
		observation_particles.amount = int(30 * zoom_level)

# ============================================================================
# ANIMATIONS ET EFFETS VISUELS
# ============================================================================

func animate_magic_lens_activation() -> void:
	"""Animation d'activation de la lentille magique"""
	var tween = create_tween()
	magic_lens.modulate = Color.TRANSPARENT
	magic_lens.scale = Vector2(2.0, 2.0)
	
	tween.parallel().tween_property(magic_lens, "modulate", Color.WHITE, 0.5)
	tween.parallel().tween_property(magic_lens, "scale", Vector2.ONE, 0.5)

func animate_discovery_flash() -> void:
	"""Animation flash de découverte"""
	var flash = ColorRect.new()
	flash.color = Color.YELLOW
	flash.anchors_preset = Control.PRESET_FULL_RECT
	observation_overlay.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)

func animate_evolution_flash() -> void:
	"""Animation flash d'évolution"""
	var flash = ColorRect.new()
	flash.color = Color(0.6, 0.4, 1.0)  # Octarine
	flash.anchors_preset = Control.PRESET_FULL_RECT
	observation_overlay.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.8)
	tween.tween_callback(flash.queue_free)

func animate_sketch_appearance(sketch_node: TextureRect) -> void:
	"""Animation d'apparition du croquis"""
	sketch_node.modulate = Color.TRANSPARENT
	sketch_node.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.parallel().tween_property(sketch_node, "modulate", Color.WHITE, 0.4)
	tween.parallel().tween_property(sketch_node, "scale", Vector2.ONE, 0.4)

func animate_new_discovery() -> void:
	"""Animation nouvelle découverte"""
	# Particules spéciales découverte
	trigger_discovery_particles()
	
	# Son de découverte
	play_discovery_sound()

func trigger_discovery_particles() -> void:
	"""Déclenche particules de découverte"""
	var discovery_particles = CPUParticles2D.new()
	discovery_particles.emitting = true
	discovery_particles.amount = 50
	discovery_particles.lifetime = 3.0
	discovery_particles.texture = load("res://vfx/star_particle.png")
	discovery_particles.color = Color.GOLD
	discovery_particles.position = Vector2(400, 300)
	notebook_container.add_child(discovery_particles)
	
	# Auto-suppression
	get_tree().create_timer(3.0).timeout.connect(discovery_particles.queue_free)

func trigger_evolution_particles() -> void:
	"""Particules spéciales évolution"""
	observation_particles.color = Color(1.0, 0.5, 1.0)  # Rose magique
	observation_particles.amount = 100
	observation_particles.emitting = true
	
	get_tree().create_timer(2.0).timeout.connect(func(): 
		observation_particles.color = Color(0.6, 0.4, 1.0)
		observation_particles.amount = 30
	)

func intensify_observation_particles() -> void:
	"""Intensifie les particules d'observation"""
	observation_particles.amount += 10
	observation_particles.initial_velocity_max += 20

# ============================================================================
# DONNÉES ET PERSISTENCE
# ============================================================================

func load_creature_data(creature_id: String) -> void:
	"""Charge les données d'une créature"""
	var observation_manager = get_node_or_null("/root/Observation")
	if observation_manager and observation_manager.has_method("get_creature_observation_data"):
		var data = observation_manager.get_creature_observation_data(creature_id)
		# Traiter données...
	
	current_creature_id = creature_id

func get_creature_display_data(creature_id: String) -> Dictionary:
	"""Retourne les données d'affichage d'une créature"""
	# TODO: Intégration avec DataManager pour données réelles
	return {
		"name": creature_id.capitalize(),
		"species": "Espèce magique",
		"discovery_date": "Aujourd'hui",
		"description": "Une créature fascinante observée dans les rues d'Ankh-Morpork.",
		"behavior": "Comportement curieux et imprévisible.",
		"evolution_stage": 1,
		"sketch_path": "res://ui/sketches/" + creature_id + ".png"
	}

func load_discovered_creatures() -> void:
	"""Charge la liste des créatures découvertes"""
	# TODO: Charger depuis SaveSystem
	discovered_creatures = ["rat_maurice", "pigeon_magique", "chat_grebo"]

func save_discovered_creatures() -> void:
	"""Sauvegarde la liste des créatures découvertes"""
	# TODO: Sauvegarder via SaveSystem
	pass

# ============================================================================
# GÉNÉRATION PROCÉDURALE
# ============================================================================

func generate_procedural_sketch(creature_id: String) -> void:
	"""Génère un croquis procédural pour une créature"""
	# TODO: Système de génération de croquis basé sur les caractéristiques
	print("🔮 Génération croquis pour: ", creature_id)

func improve_sketch_quality(creature_id: String) -> void:
	"""Améliore la qualité d'un croquis existant"""
	# TODO: Amélioration progressive des dessins avec l'observation
	pass

func create_initial_observation_notes(creature_id: String) -> void:
	"""Crée les notes d'observation initiales"""
	# TODO: Génération de notes basées sur les caractéristiques observées
	pass

func add_behavior_observations(creature_id: String) -> void:
	"""Ajoute des observations comportementales"""
	# TODO: Enrichissement des notes avec nouveaux comportements
	pass

# ============================================================================
# AUDIO
# ============================================================================

func play_discovery_sound() -> void:
	"""Joue le son de découverte"""
	# TODO: Son magique de découverte
	pass

# ============================================================================
# UTILITAIRES ET API
# ============================================================================

func hide_observation_interface() -> void:
	"""Masque l'interface d'observation"""
	observation_panel.hide()
	is_observing = false
	observation_particles.emitting = false

func highlight_evolved_creature(creature_id: String) -> void:
	"""Met en surbrillance une créature évoluée"""
	# TODO: Effet visuel pour créature récemment évoluée
	pass

func transition_to_notebook_view() -> void:
	"""Transition vers la vue carnet après observation"""
	var tween = create_tween()
	
	# Fondu sortie overlay
	tween.tween_property(observation_overlay, "modulate:a", 0.0, 0.3)
	tween.tween_callback(observation_overlay.hide)
	
	# Fondu entrée carnet
	notebook_container.show()
	notebook_container.modulate = Color.TRANSPARENT
	tween.tween_property(notebook_container, "modulate", Color.WHITE, 0.3)

func show_empty_notebook() -> void:
	"""Affiche un carnet vide"""
	observation_notes.text = "[center][font_size=18][color=gray]Aucune créature observée.\n\nCommencez à explorer Ankh-Morpork pour découvrir ses merveilles![/color][/font_size][/center]"
	behavior_notes.text = ""
	
	# Masquer navigation si vide
	page_navigation.hide()

# ============================================================================
# RÉVÉLATIONS PROGRESSIVES (PALIERS OBSERVATION)
# ============================================================================

func reveal_basic_info() -> void:
	"""Révèle les informations de base"""
	creature_name_label.text = current_creature_id.capitalize()
	creature_info_popup.show()

func reveal_species_info() -> void:
	"""Révèle l'espèce"""
	creature_species_label.text = "Espèce: Créature Magique"

func reveal_behavior_patterns() -> void:
	"""Révèle les motifs comportementaux"""
	# TODO: Mise à jour des notes comportementales
	pass

func reveal_magical_properties() -> void:
	"""Révèle les propriétés magiques"""
	# TODO: Affichage aura magique
	pass

func reveal_evolution_potential() -> void:
	"""Révèle le potentiel d'évolution"""
	# TODO: Mise à jour indicateur évolution
	update_evolution_indicator(4)

func update_evolution_indicator(stage: int) -> void:
	"""Met à jour l'indicateur de stade d'évolution"""
	for i in range(evolution_stage_indicator.get_child_count()):
		var star = evolution_stage_indicator.get_child(i)
		if i < stage:
			star.text = "★"
			star.add_theme_color_override("font_color", Color.GOLD)
		else:
			star.text = "☆"
			star.add_theme_color_override("font_color", Color.GRAY)

func update_creature_info_display() -> void:
	"""Met à jour l'affichage des informations créature"""
	if current_creature_id != "":
		creature_info_popup.show()
		reveal_basic_info()

# ============================================================================
# GESTION INPUT
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Gestion des inputs observation"""
	if not observation_panel.visible:
		return
	
	if event.is_action_pressed("ui_cancel"):
		if is_observing:
			# Arrêter observation
			complete_observation()
		else:
			# Fermer carnet
			hide_observation_interface()
	
	if event.is_action_pressed("zoom_in"):
		_on_zoom_in()
	elif event.is_action_pressed("zoom_out"):
		_on_zoom_out()
	
	# Navigation pages carnet
	if event.is_action_pressed("page_previous"):
		_on_previous_page()
	elif event.is_action_pressed("page_next"):
		_on_next_page()

# ============================================================================
# DEBUG
# ============================================================================
func setup_scientific_notebook_style() -> void:
	pass

func setup_pratchett_notebook_style() -> void:
	pass

func _on_debug_test_observation() -> void:
	"""Test observation pour debug"""
	if OS.is_debug_build():
		start_live_observation("debug_creature")
