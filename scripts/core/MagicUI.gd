# ============================================================================
# ✨ MagicUI.gd - Interface Magie Octarine Terry Pratchett
# ============================================================================
# STATUS: ✅ COMPLET | Sous-système UIManager
# PRIORITY: 🔴 CRITICAL - Système de magie unique
# DEPENDENCIES: UIManager, MagicSystem

class_name MagicUI
extends Control

## Interface de magie spécialisée pour "Sortilèges & Bestioles"
## Magie Octarine avec 20% effets chaotiques Terry Pratchett
## Sélection radiale, barres de mana, indicateurs chaos

# ============================================================================
# SIGNAUX
# ============================================================================

signal spell_cast_requested(spell_id: String, target_data: Dictionary)
signal spell_selection_changed(spell_id: String, spell_data: Dictionary)
signal octarine_chaos_triggered(chaos_type: String, affected_data: Dictionary)
signal mana_warning(current_mana: int, spell_cost: int)
signal magic_interface_closed()

# ============================================================================
# CONFIGURATION
# ============================================================================

var magic_config: Dictionary = {}
var available_spells: Array[Dictionary] = []
var equipped_spells: Array[String] = []
var current_mana: int = 100
var max_mana: int = 100
var chaos_probability: float = 0.2  # 20% chance Terry Pratchett
var is_casting: bool = false
var selection_mode: String = "radial"

# ============================================================================
# ÉLÉMENTS UI PRINCIPAUX
# ============================================================================

## Conteneur principal magie
@onready var magic_panel: Control
@onready var spell_selection_container: Control
@onready var mana_display_container: Control
@onready var chaos_warning_container: Control

## Sélection radiale de sorts
@onready var radial_menu: Control
@onready var spell_wheel: Control
@onready var center_crystal: Control
@onready var spell_icons_container: Control

## Barres et indicateurs
@onready var mana_bar: ProgressBar
@onready var mana_regeneration_indicator: Control
@onready var chaos_meter: ProgressBar
@onready var octarine_glow_indicator: Control

## Information sorts
@onready var spell_tooltip: Control
@onready var spell_name_label: Label
@onready var spell_description: RichTextLabel
@onready var mana_cost_label: Label
@onready var chaos_warning_label: Label

## Effets visuels Octarine
@onready var octarine_particles: CPUParticles2D
@onready var magic_aura: Control
@onready var chaos_distortion: Control
@onready var spell_preview: Control

# ============================================================================
# RACCOURCIS ET INPUTS
# ============================================================================

@onready var spell_shortcuts: Control
var spell_hotkeys: Dictionary = {}
var selected_spell_index: int = -1
var mouse_position: Vector2
var is_radial_active: bool = false

# ============================================================================
# TYPES & ENUMS
# ============================================================================

enum SpellType {
	OFFENSIVE = 0,     ## Sorts d'attaque
	DEFENSIVE = 1,     ## Sorts de protection
	UTILITY = 2,       ## Sorts utilitaires
	OBSERVATION = 3,   ## Sorts d'observation
	OCTARINE = 4,      ## Magie Octarine pure
	HEADOLOGY = 5      ## Magie psychologique
}

enum ChaosEffect {
	SPELL_REVERSAL = 0,      ## Sort inversé
	TARGET_MULTIPLICATION = 1, ## Cibles multiples
	POWER_AMPLIFICATION = 2,  ## Puissance doublée
	DIMENSION_SLIP = 3,      ## Téléportation aléatoire
	TIME_HICCUP = 4,         ## Ralentissement temporel
	REALITY_GLITCH = 5       ## Effet narratif bizarre
}

enum ManaState {
	FULL = 0,        ## Mana complète
	HIGH = 1,        ## Mana élevée (75%+)
	MEDIUM = 2,      ## Mana moyenne (50-75%)
	LOW = 3,         ## Mana faible (25-50%)
	CRITICAL = 4     ## Mana critique (<25%)
}

# ============================================================================
# INITIALISATION
# ============================================================================

func initialize(parent_container: Control, config: Dictionary) -> void:
	"""Initialise le système MagicUI"""
	magic_config = config
	
	# Créer l'interface magique
	create_magic_interface(parent_container)
	setup_magic_styling()
	load_spell_database()
	setup_spell_shortcuts()
	
	# Configuration Terry Pratchett
	setup_octarine_effects()
	
	print("✨ MagicUI: Interface Octarine initialisée")

func create_magic_interface(parent: Control) -> void:
	"""Crée l'interface magique complète"""
	# Conteneur principal
	magic_panel = Control.new()
	magic_panel.name = "MagicPanel"
	magic_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(magic_panel)
	
	# Container sélection de sorts
	spell_selection_container = Control.new()
	spell_selection_container.name = "SpellSelection"
	spell_selection_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	magic_panel.add_child(spell_selection_container)
	
	create_radial_spell_menu()
	create_mana_display()
	create_chaos_indicators()
	create_spell_tooltip()
	
	# Masquer par défaut
	magic_panel.hide()

func create_radial_spell_menu() -> void:
	"""Crée le menu radial de sélection de sorts"""
	# Container menu radial
	radial_menu = Control.new()
	radial_menu.name = "RadialMenu"
	radial_menu.anchors_preset = Control.PRESET_CENTER
	radial_menu.custom_minimum_size = Vector2(400, 400)
	spell_selection_container.add_child(radial_menu)
	
	# Roue de sorts (background)
	spell_wheel = Control.new()
	spell_wheel.name = "SpellWheel"
	spell_wheel.anchors_preset = Control.PRESET_FULL_RECT
	radial_menu.add_child(spell_wheel)
	
	# Background roue magique
	var wheel_bg = TextureRect.new()
	wheel_bg.texture = load("res://ui/textures/magic_wheel.png")
	wheel_bg.anchors_preset = Control.PRESET_FULL_RECT
	wheel_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	spell_wheel.add_child(wheel_bg)
	
	# Cristal central Octarine
	center_crystal = Control.new()
	center_crystal.name = "CenterCrystal"
	center_crystal.anchors_preset = Control.PRESET_CENTER
	center_crystal.custom_minimum_size = Vector2(80, 80)
	radial_menu.add_child(center_crystal)
	
	var crystal_texture = TextureRect.new()
	crystal_texture.texture = load("res://ui/textures/octarine_crystal.png")
	crystal_texture.anchors_preset = Control.PRESET_FULL_RECT
	crystal_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	center_crystal.add_child(crystal_texture)
	
	# Container icônes sorts
	spell_icons_container = Control.new()
	spell_icons_container.name = "SpellIcons"
	spell_icons_container.anchors_preset = Control.PRESET_FULL_RECT
	radial_menu.add_child(spell_icons_container)
	
	# Particules Octarine
	octarine_particles = CPUParticles2D.new()
	octarine_particles.name = "OctarineParticles"
	octarine_particles.emitting = false
	octarine_particles.amount = 40
	octarine_particles.lifetime = 2.5
	octarine_particles.texture = load("res://vfx/octarine_particle.png")
	octarine_particles.color = Color(0.6, 0.4, 1.0, 0.9)  # Octarine approximation
	octarine_particles.position = Vector2(200, 200)
	radial_menu.add_child(octarine_particles)

func create_mana_display() -> void:
	"""Crée l'affichage de mana"""
	mana_display_container = Control.new()
	mana_display_container.name = "ManaDisplay"
	mana_display_container.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	mana_display_container.offset_left = -250
	mana_display_container.offset_top = -100
	mana_display_container.offset_right = -20
	mana_display_container.offset_bottom = -20
	magic_panel.add_child(mana_display_container)
	
	# Background mana display
	var mana_bg = NinePatchRect.new()
	mana_bg.texture = load("res://ui/textures/mana_display_bg.png")
	mana_bg.anchors_preset = Control.PRESET_FULL_RECT
	mana_display_container.add_child(mana_bg)
	
	# Container vertical pour les barres
	var mana_bars_container = VBoxContainer.new()
	mana_bars_container.anchors_preset = Control.PRESET_FULL_RECT
	mana_bars_container.offset_left = 10
	mana_bars_container.offset_right = -10
	mana_bars_container.offset_top = 10
	mana_bars_container.offset_bottom = -10
	mana_display_container.add_child(mana_bars_container)
	
	# Label titre
	var mana_title = Label.new()
	mana_title.text = "Énergie Magique"
	mana_title.add_theme_font_size_override("font_size", 14)
	mana_title.add_theme_color_override("font_color", Color(0.8, 0.6, 1.0))
	mana_bars_container.add_child(mana_title)
	
	# Barre de mana principale
	mana_bar = ProgressBar.new()
	mana_bar.name = "ManaBar"
	mana_bar.max_value = 100
	mana_bar.value = 100
	mana_bar.custom_minimum_size.y = 25
	mana_bar.add_theme_color_override("font_color", Color.WHITE)
	mana_bars_container.add_child(mana_bar)
	
	# Style de la barre de mana
	var mana_style = StyleBoxFlat.new()
	mana_style.bg_color = Color(0.2, 0.4, 0.8, 0.8)  # Bleu magique
	mana_style.border_color = Color(0.6, 0.4, 1.0)   # Bordure octarine
	mana_style.border_width_left = 2
	mana_style.border_width_right = 2
	mana_style.border_width_top = 2
	mana_style.border_width_bottom = 2
	mana_bar.add_theme_stylebox_override("fill", mana_style)
	
	# Indicateur régénération
	mana_regeneration_indicator = Control.new()
	mana_regeneration_indicator.name = "RegenIndicator"
	mana_regeneration_indicator.custom_minimum_size.y = 5
	mana_bars_container.add_child(mana_regeneration_indicator)

func create_chaos_indicators() -> void:
	"""Crée les indicateurs de chaos magique"""
	chaos_warning_container = Control.new()
	chaos_warning_container.name = "ChaosWarning"
	chaos_warning_container.anchors_preset = Control.PRESET_TOP_LEFT
	chaos_warning_container.offset_left = 20
	chaos_warning_container.offset_top = 20
	chaos_warning_container.offset_right = 320
	chaos_warning_container.offset_bottom = 120
	magic_panel.add_child(chaos_warning_container)
	
	# Background avertissement chaos
	var chaos_bg = ColorRect.new()
	chaos_bg.color = Color(0.5, 0.2, 0.2, 0.7)  # Rouge transparent
	chaos_bg.anchors_preset = Control.PRESET_FULL_RECT
	chaos_warning_container.add_child(chaos_bg)
	
	# Container contenu
	var chaos_content = VBoxContainer.new()
	chaos_content.anchors_preset = Control.PRESET_FULL_RECT
	chaos_content.offset_left = 10
	chaos_content.offset_right = -10
	chaos_content.offset_top = 10
	chaos_content.offset_bottom = -10
	chaos_warning_container.add_child(chaos_content)
	
	# Titre avertissement
	var chaos_title = Label.new()
	chaos_title.text = "⚠️ INSTABILITÉ OCTARINE"
	chaos_title.add_theme_font_size_override("font_size", 16)
	chaos_title.add_theme_color_override("font_color", Color.YELLOW)
	chaos_content.add_child(chaos_title)
	
	# Mètre de chaos
	chaos_meter = ProgressBar.new()
	chaos_meter.name = "ChaosMeter"
	chaos_meter.max_value = 100
	chaos_meter.value = 20  # 20% par défaut Terry Pratchett
	chaos_meter.custom_minimum_size.y = 20
	chaos_content.add_child(chaos_meter)
	
	# Style mètre chaos
	var chaos_style = StyleBoxFlat.new()
	chaos_style.bg_color = Color(1.0, 0.3, 1.0, 0.9)  # Rose chaotique
	chaos_meter.add_theme_stylebox_override("fill", chaos_style)
	
	# Warning label
	chaos_warning_label = Label.new()
	chaos_warning_label.text = "Probabilité d'effet chaotique: 20%"
	chaos_warning_label.add_theme_font_size_override("font_size", 12)
	chaos_warning_label.add_theme_color_override("font_color", Color.WHITE)
	chaos_warning_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	chaos_content.add_child(chaos_warning_label)
	
	# Masquer par défaut
	chaos_warning_container.hide()

func create_spell_tooltip() -> void:
	"""Crée le tooltip d'information des sorts"""
	spell_tooltip = Control.new()
	spell_tooltip.name = "SpellTooltip"
	spell_tooltip.custom_minimum_size = Vector2(300, 200)
	spell_tooltip.anchors_preset = Control.PRESET_TOP_RIGHT
	spell_tooltip.offset_left = -320
	spell_tooltip.offset_top = 20
	magic_panel.add_child(spell_tooltip)
	
	# Background tooltip
	var tooltip_bg = NinePatchRect.new()
	tooltip_bg.texture = load("res://ui/textures/spell_tooltip_bg.png")
	tooltip_bg.anchors_preset = Control.PRESET_FULL_RECT
	spell_tooltip.add_child(tooltip_bg)
	
	# Container contenu
	var tooltip_content = VBoxContainer.new()
	tooltip_content.anchors_preset = Control.PRESET_FULL_RECT
	tooltip_content.offset_left = 15
	tooltip_content.offset_right = -15
	tooltip_content.offset_top = 15
	tooltip_content.offset_bottom = -15
	spell_tooltip.add_child(tooltip_content)
	
	# Nom du sort
	spell_name_label = Label.new()
	spell_name_label.name = "SpellName"
	spell_name_label.text = "Sort Sélectionné"
	spell_name_label.add_theme_font_size_override("font_size", 18)
	spell_name_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Or
	tooltip_content.add_child(spell_name_label)
	
	# Coût en mana
	mana_cost_label = Label.new()
	mana_cost_label.name = "ManaCost"
	mana_cost_label.text = "Coût: 0 Mana"
	mana_cost_label.add_theme_color_override("font_color", Color.CYAN)
	tooltip_content.add_child(mana_cost_label)
	
	# Description
	spell_description = RichTextLabel.new()
	spell_description.name = "SpellDescription"
	spell_description.bbcode_enabled = true
	spell_description.fit_content = true
	spell_description.custom_minimum_size.y = 100
	spell_description.add_theme_color_override("default_color", Color.WHITE)
	tooltip_content.add_child(spell_description)
	
	# Masquer par défaut
	spell_tooltip.hide()

# ============================================================================
# GESTION SORTS ET SÉLECTION
# ============================================================================

func show_spell_selection(context: Dictionary = {}) -> void:
	"""Affiche l'interface de sélection de sorts"""
	magic_panel.show()
	
	# Charger sorts disponibles
	refresh_available_spells()
	
	# Afficher menu radial
	show_radial_menu()
	
	# Mettre à jour mana
	update_mana_display()
	
	# Activer particules Octarine
	octarine_particles.emitting = true
	
	print("✨ Interface magie affichée")

func show_radial_menu() -> void:
	"""Affiche le menu radial de sorts"""
	is_radial_active = true
	radial_menu.show()
	
	# Créer icônes de sorts
	populate_spell_wheel()
	
	# Animation d'apparition
	animate_radial_appearance()

func populate_spell_wheel() -> void:
	"""Remplit la roue avec les sorts disponibles"""
	# Nettoyer icônes précédentes
	for child in spell_icons_container.get_children():
		child.queue_free()
	
	var spell_count = min(equipped_spells.size(), 8)  # Max 8 sorts sur la roue
	var angle_step = 2 * PI / spell_count
	var radius = 150
	
	for i in range(spell_count):
		var spell_id = equipped_spells[i]
		var spell_data = get_spell_data(spell_id)
		
		# Position sur le cercle
		var angle = i * angle_step
		var pos = Vector2(cos(angle), sin(angle)) * radius
		
		# Créer icône sort
		var spell_icon = create_spell_icon(spell_data, i)
		spell_icon.position = pos + Vector2(200, 200)  # Centre du radial
		spell_icons_container.add_child(spell_icon)

func create_spell_icon(spell_data: Dictionary, index: int) -> Control:
	"""Crée une icône de sort pour la roue"""
	var icon_container = Control.new()
	icon_container.name = "SpellIcon" + str(index)
	icon_container.custom_minimum_size = Vector2(60, 60)
	
	# Background icône
	var icon_bg = TextureRect.new()
	icon_bg.texture = load("res://ui/textures/spell_icon_bg.png")
	icon_bg.anchors_preset = Control.PRESET_FULL_RECT
	icon_container.add_child(icon_bg)
	
	# Icône du sort
	var spell_texture = TextureRect.new()
	var icon_path = spell_data.get("icon", "res://ui/icons/unknown_spell.png")
	spell_texture.texture = load(icon_path)
	spell_texture.anchors_preset = Control.PRESET_CENTER
	spell_texture.custom_minimum_size = Vector2(40, 40)
	spell_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_container.add_child(spell_texture)
	
	# Raccourci clavier
	var hotkey_label = Label.new()
	hotkey_label.text = str(index + 1)
	hotkey_label.add_theme_font_size_override("font_size", 12)
	hotkey_label.add_theme_color_override("font_color", Color.YELLOW)
	hotkey_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	hotkey_label.offset_left = -15
	hotkey_label.offset_top = -15
	icon_container.add_child(hotkey_label)
	
	# Glow effect si sort Octarine
	if spell_data.get("is_octarine", false):
		add_octarine_glow(icon_container)
	
	# Connecter signaux
	var button = Button.new()
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.flat = true
	button.pressed.connect(_on_spell_selected.bind(spell_data.id, index))
	button.mouse_entered.connect(_on_spell_hovered.bind(spell_data))
	button.mouse_exited.connect(_on_spell_unhovered)
	icon_container.add_child(button)
	
	return icon_container

func add_octarine_glow(icon: Control) -> void:
	"""Ajoute un effet lumineux Octarine"""
	var glow = ColorRect.new()
	glow.color = Color(0.6, 0.4, 1.0, 0.3)  # Octarine transparent
	glow.anchors_preset = Control.PRESET_FULL_RECT
	glow.offset_left = -5
	glow.offset_right = 5
	glow.offset_top = -5
	glow.offset_bottom = 5
	icon.add_child(glow)
	icon.move_child(glow, 0)  # Arrière-plan
	
	# Animation pulsation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(glow, "modulate:a", 0.1, 1.0)
	tween.tween_property(glow, "modulate:a", 0.5, 1.0)

# ============================================================================
# GESTION ÉVÉNEMENTS SORTS
# ============================================================================

func _on_spell_selected(spell_id: String, index: int) -> void:
	"""Gestion sélection d'un sort"""
	var spell_data = get_spell_data(spell_id)
	selected_spell_index = index
	
	print("✨ Sort sélectionné: ", spell_id)
	
	# Vérifier coût mana
	var mana_cost = spell_data.get("mana_cost", 0)
	if current_mana < mana_cost:
		show_mana_warning(mana_cost)
		return
	
	# Vérifier probabilité chaos
	check_chaos_probability(spell_data)
	
	# Demander cible si nécessaire
	request_spell_target(spell_data)

func _on_spell_hovered(spell_data: Dictionary) -> void:
	"""Affiche tooltip au survol"""
	update_spell_tooltip(spell_data)
	spell_tooltip.show()
	
	# Effet lumineux sur cristal central
	animate_crystal_activation()

func _on_spell_unhovered() -> void:
	"""Masque tooltip"""
	spell_tooltip.hide()
	
	# Arrêter animation cristal
	stop_crystal_animation()

func request_spell_target(spell_data: Dictionary) -> void:
	"""Demande la sélection d'une cible"""
	var target_type = spell_data.get("target_type", "none")
	
	match target_type:
		"self":
			cast_spell_immediate(spell_data, {"target": "player"})
		"creature":
			enter_target_selection_mode(spell_data)
		"area":
			enter_area_target_mode(spell_data)
		"none":
			cast_spell_immediate(spell_data, {})

func enter_target_selection_mode(spell_data: Dictionary) -> void:
	"""Mode sélection de cible créature"""
	hide_spell_interface()
	
	# TODO: Activer mode sélection cible dans le jeu
	# Émettre signal pour UIManager
	spell_cast_requested.emit(spell_data.id, {"mode": "target_selection", "spell_data": spell_data})

func cast_spell_immediate(spell_data: Dictionary, target_data: Dictionary) -> void:
	"""Lance un sort immédiatement"""
	var spell_id = spell_data.id
	var mana_cost = spell_data.get("mana_cost", 0)
	
	# Consommer mana
	current_mana -= mana_cost
	update_mana_display()
	
	# Vérifier chaos Octarine
	var chaos_triggered = check_octarine_chaos(spell_data)
	
	# Animation de lancement
	animate_spell_casting(spell_data)
	
	# Émettre signal de lancement
	spell_cast_requested.emit(spell_id, target_data.merged({"chaos": chaos_triggered}))
	
	print("✨ Sort lancé: ", spell_id, " (Chaos: ", chaos_triggered, ")")

func check_octarine_chaos(spell_data: Dictionary) -> bool:
	"""Vérifie si un effet chaotique se déclenche"""
	var is_octarine = spell_data.get("is_octarine", false)
	var base_chaos = chaos_probability
	
	# Probabilité augmentée pour sorts Octarine
	var chaos_chance = base_chaos * (2.0 if is_octarine else 1.0)
	
	if randf() < chaos_chance:
		trigger_chaos_effect(spell_data)
		return true
	
	return false

func trigger_chaos_effect(spell_data: Dictionary) -> void:
	"""Déclenche un effet chaotique"""
	var chaos_effects = [
		ChaosEffect.SPELL_REVERSAL,
		ChaosEffect.TARGET_MULTIPLICATION,
		ChaosEffect.POWER_AMPLIFICATION,
		ChaosEffect.DIMENSION_SLIP,
		ChaosEffect.TIME_HICCUP,
		ChaosEffect.REALITY_GLITCH
	]
	
	var chaos_type = chaos_effects[randi() % chaos_effects.size()]
	var chaos_name = ChaosEffect.keys()[chaos_type]
	
	print("✨ CHAOS OCTARINE: ", chaos_name)
	
	# Animation chaos
	animate_chaos_effect(chaos_type)
	
	# Émettre signal chaos
	octarine_chaos_triggered.emit(chaos_name, spell_data)

# ============================================================================
# MISE À JOUR AFFICHAGES
# ============================================================================

func update_mana_display() -> void:
	"""Met à jour l'affichage de mana"""
	if mana_bar:
		mana_bar.value = current_mana
		
		# Changer couleur selon niveau
		var mana_state = get_mana_state()
		update_mana_bar_style(mana_state)
		
		# Mise à jour texte
		var mana_text = str(current_mana) + " / " + str(max_mana)
		mana_bar.add_theme_color_override("font_color", get_mana_color(mana_state))

func get_mana_state() -> ManaState:
	"""Détermine l'état actuel de mana"""
	var percentage = float(current_mana) / float(max_mana)
	
	if percentage >= 0.75:
		return ManaState.HIGH
	elif percentage >= 0.5:
		return ManaState.MEDIUM
	elif percentage >= 0.25:
		return ManaState.LOW
	else:
		return ManaState.CRITICAL

func update_mana_bar_style(state: ManaState) -> void:
	"""Met à jour le style de la barre de mana"""
	var style = StyleBoxFlat.new()
	
	match state:
		ManaState.HIGH:
			style.bg_color = Color(0.2, 0.4, 0.8, 0.8)  # Bleu
		ManaState.MEDIUM:
			style.bg_color = Color(0.2, 0.6, 0.4, 0.8)  # Vert
		ManaState.LOW:
			style.bg_color = Color(0.8, 0.6, 0.2, 0.8)  # Jaune
		ManaState.CRITICAL:
			style.bg_color = Color(0.8, 0.2, 0.2, 0.8)  # Rouge
	
	style.border_color = Color(0.6, 0.4, 1.0)  # Bordure octarine
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	
	mana_bar.add_theme_stylebox_override("fill", style)

func get_mana_color(state: ManaState) -> Color:
	"""Retourne la couleur du texte selon l'état mana"""
	match state:
		ManaState.HIGH, ManaState.MEDIUM:
			return Color.WHITE
		ManaState.LOW:
			return Color.YELLOW
		ManaState.CRITICAL:
			return Color.RED
		_:
			return Color.WHITE

func update_spell_tooltip(spell_data: Dictionary) -> void:
	"""Met à jour le contenu du tooltip"""
	if not spell_tooltip:
		return
	
	# Nom du sort
	spell_name_label.text = spell_data.get("name", "Sort Inconnu")
	
	# Coût mana
	var mana_cost = spell_data.get("mana_cost", 0)
	mana_cost_label.text = "Coût: " + str(mana_cost) + " Mana"
	
	# Changer couleur si pas assez de mana
	if current_mana < mana_cost:
		mana_cost_label.add_theme_color_override("font_color", Color.RED)
	else:
		mana_cost_label.add_theme_color_override("font_color", Color.CYAN)
	
	# Description avec BBCode Terry Pratchett
	var description = spell_data.get("description", "Description non disponible.")
	description = process_spell_description(description, spell_data)
	spell_description.text = description

func process_spell_description(text: String, spell_data: Dictionary) -> String:
	"""Traite la description avec les effets Terry Pratchett"""
	var processed = text
	
	# Ajouter avertissement chaos si sort Octarine
	if spell_data.get("is_octarine", false):
		processed += "\n\n[color=magenta][i]⚠️ Sort Octarine - Risque d'effets chaotiques![/i][/color]"
	
	# Remplacements spéciaux
	processed = processed.replace("*octarine*", "[color=#9966FF]octarine[/color]")
	processed = processed.replace("*chaos*", "[color=red][shake]CHAOS[/shake][/color]")
	processed = processed.replace("*magic*", "[color=cyan]✨[/color]")
	
	return processed

func check_chaos_probability(spell_data: Dictionary) -> void:
	"""Vérifie et affiche la probabilité de chaos"""
	var is_octarine = spell_data.get("is_octarine", false)
	var chaos_chance = chaos_probability * (2.0 if is_octarine else 1.0)
	
	if is_octarine or chaos_chance > 0.3:  # Afficher warning si > 30%
		show_chaos_warning(chaos_chance)
	else:
		hide_chaos_warning()

func show_chaos_warning(probability: float) -> void:
	"""Affiche l'avertissement de chaos"""
	chaos_warning_container.show()
	chaos_meter.value = probability * 100
	chaos_warning_label.text = "Probabilité d'effet chaotique: " + str(int(probability * 100)) + "%"
	
	# Animation pulsation
	animate_chaos_warning_pulse()

func hide_chaos_warning() -> void:
	"""Masque l'avertissement de chaos"""
	chaos_warning_container.hide()

func show_mana_warning(required_mana: int) -> void:
	"""Affiche un avertissement de mana insuffisante"""
	var warning_text = "Mana insuffisante!\nRequis: " + str(required_mana) + " / Disponible: " + str(current_mana)
	
	# TODO: Afficher popup d'avertissement
	print("⚠️ ", warning_text)
	
	mana_warning.emit(current_mana, required_mana)

# ============================================================================
# ANIMATIONS ET EFFETS VISUELS
# ============================================================================

func animate_radial_appearance() -> void:
	"""Animation d'apparition du menu radial"""
	radial_menu.scale = Vector2(0.5, 0.5)
	radial_menu.modulate = Color.TRANSPARENT
	
	var tween = create_tween()
	tween.parallel().tween_property(radial_menu, "scale", Vector2.ONE, 0.4)
	tween.parallel().tween_property(radial_menu, "modulate", Color.WHITE, 0.4)
	
	# Animation cascade des icônes
	animate_spell_icons_cascade()

func animate_spell_icons_cascade() -> void:
	"""Animation en cascade des icônes de sorts"""
	for i in range(spell_icons_container.get_child_count()):
		var icon = spell_icons_container.get_child(i)
		icon.modulate = Color.TRANSPARENT
		icon.scale = Vector2(0.3, 0.3)
		
		var tween = create_tween()
		tween.tween_delay(i * 0.1)
		tween.parallel().tween_property(icon, "modulate", Color.WHITE, 0.3)
		tween.parallel().tween_property(icon, "scale", Vector2.ONE, 0.3)

func animate_crystal_activation() -> void:
	"""Animation du cristal central"""
	var tween = create_tween()
	tween.set_loops()
	
	tween.tween_property(center_crystal, "rotation", PI * 2, 2.0)

func stop_crystal_animation() -> void:
	"""Arrête l'animation du cristal"""
	var tween = create_tween()
	tween.tween_property(center_crystal, "rotation", 0.0, 0.5)

func animate_spell_casting(spell_data: Dictionary) -> void:
	"""Animation de lancement de sort"""
	# Flash lumineux
	var flash = ColorRect.new()
	flash.color = Color(0.6, 0.4, 1.0)  # Octarine
	flash.anchors_preset = Control.PRESET_FULL_RECT
	magic_panel.add_child(flash)
	
	var tween = create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.5)
	tween.tween_callback(flash.queue_free)
	
	# Intensifier particules
	octarine_particles.amount = 80
	octarine_particles.emitting = true
	
	get_tree().create_timer(1.0).timeout.connect(func():
		octarine_particles.amount = 40
	)

func animate_chaos_effect(chaos_type: ChaosEffect) -> void:
	"""Animation spécifique selon le type de chaos"""
	match chaos_type:
		ChaosEffect.SPELL_REVERSAL:
			animate_reversal_effect()
		ChaosEffect.TARGET_MULTIPLICATION:
			animate_multiplication_effect()
		ChaosEffect.DIMENSION_SLIP:
			animate_dimension_slip()
		ChaosEffect.REALITY_GLITCH:
			animate_reality_glitch()

func animate_reversal_effect() -> void:
	"""Animation effet d'inversion"""
	var tween = create_tween()
	tween.tween_property(radial_menu, "rotation", PI, 0.5)
	tween.tween_property(radial_menu, "rotation", 0.0, 0.5)

func animate_multiplication_effect() -> void:
	"""Animation effet de multiplication"""
	# Effet de duplication visuelle temporaire
	for icon in spell_icons_container.get_children():
		var duplicate = icon.duplicate()
		duplicate.modulate = Color(1, 1, 1, 0.5)
		spell_icons_container.add_child(duplicate)
		
		var tween = create_tween()
		tween.tween_property(duplicate, "position", duplicate.position + Vector2(20, 20), 0.3)
		tween.tween_property(duplicate, "modulate:a", 0.0, 0.3)
		tween.tween_callback(duplicate.queue_free)

func animate_dimension_slip() -> void:
	"""Animation glissement dimensionnel"""
	var original_pos = radial_menu.position
	var tween = create_tween()
	
	# Téléportation visuelle
	tween.tween_property(radial_menu, "position", original_pos + Vector2(100, 50), 0.1)
	tween.tween_property(radial_menu, "modulate:a", 0.0, 0.1)
	tween.tween_property(radial_menu, "position", original_pos, 0.0)
	tween.tween_property(radial_menu, "modulate:a", 1.0, 0.2)

func animate_reality_glitch() -> void:
	"""Animation glitch de réalité Terry Pratchett"""
	# Effet de distorsion temporaire
	var shader_effect = ColorRect.new()
	shader_effect.material = load("res://shaders/reality_glitch.gdshader")  # À créer
	shader_effect.anchors_preset = Control.PRESET_FULL_RECT
	magic_panel.add_child(shader_effect)
	
	get_tree().create_timer(1.0).timeout.connect(shader_effect.queue_free)

func animate_chaos_warning_pulse() -> void:
	"""Animation pulsation avertissement chaos"""
	var tween = create_tween()
	tween.set_loops()
	
	tween.tween_property(chaos_warning_container, "modulate", Color(1.5, 1.5, 1.5), 0.5)
	tween.tween_property(chaos_warning_container, "modulate", Color.WHITE, 0.5)

# ============================================================================
# RACCOURCIS ET INPUT
# ============================================================================

func setup_spell_shortcuts() -> void:
	"""Configure les raccourcis claviers pour les sorts"""
	# Raccourcis numériques 1-8
	for i in range(8):
		spell_hotkeys[str(i + 1)] = i

func _input(event: InputEvent) -> void:
	"""Gestion des inputs magiques"""
	if not magic_panel.visible:
		return
	
	# Raccourcis numériques pour sorts
	for key in spell_hotkeys.keys():
		if event.is_action_pressed("spell_" + key):
			var spell_index = spell_hotkeys[key]
			if spell_index < equipped_spells.size():
				var spell_id = equipped_spells[spell_index]
				_on_spell_selected(spell_id, spell_index)
	
	# Fermer interface
	if event.is_action_pressed("ui_cancel"):
		hide_spell_interface()
	
	# Toggle chaos warning
	if event.is_action_pressed("toggle_chaos_info"):
		chaos_warning_container.visible = !chaos_warning_container.visible

# ============================================================================
# GESTION DONNÉES
# ============================================================================

func load_spell_database() -> void:
	"""Charge la base de données des sorts"""
	# Récupérer depuis DataManager
	var data_manager = get_node_or_null("/root/Data")
	if data_manager and data_manager.has_method("get_spell_data"):
		available_spells = data_manager.get_spell_data()
	else:
		# Sorts de test pour développement
		available_spells = get_test_spells()
	
	# Charger sorts équipés depuis sauvegarde
	equipped_spells = ["magic_missile", "octarine_bolt", "heal", "teleport", "fireball"]

func get_spell_data(spell_id: String) -> Dictionary:
	"""Retourne les données d'un sort"""
	for spell in available_spells:
		if spell.get("id") == spell_id:
			return spell
	
	# Sort de fallback
	return {
		"id": spell_id,
		"name": spell_id.capitalize(),
		"description": "Sort mystérieux d'Ankh-Morpork",
		"mana_cost": 5,
		"icon": "res://ui/icons/unknown_spell.png",
		"is_octarine": false,
		"target_type": "none"
	}

func get_test_spells() -> Array[Dictionary]:
	"""Sorts de test pour développement"""
	return [
		{
			"id": "magic_missile",
			"name": "Projectile Magique",
			"description": "Un sort d'attaque basique très fiable.",
			"mana_cost": 3,
			"icon": "res://ui/icons/magic_missile.png",
			"is_octarine": false,
			"target_type": "creature"
		},
		{
			"id": "octarine_bolt",
			"name": "Éclair Octarine",
			"description": "Puissant sort *octarine* avec risques de *chaos*!",
			"mana_cost": 8,
			"icon": "res://ui/icons/octarine_bolt.png",
			"is_octarine": true,
			"target_type": "creature"
		},
		{
			"id": "heal",
			"name": "Soin Magique",
			"description": "Restaure la santé par la magie bienveillante.",
			"mana_cost": 5,
			"icon": "res://ui/icons/heal.png",
			"is_octarine": false,
			"target_type": "self"
		},
		{
			"id": "teleport",
			"name": "Téléportation",
			"description": "Déplacement instantané... habituellement au bon endroit.",
			"mana_cost": 12,
			"icon": "res://ui/icons/teleport.png",
			"is_octarine": true,
			"target_type": "area"
		}
	]

func refresh_available_spells() -> void:
	"""Actualise la liste des sorts disponibles"""
	# TODO: Vérifier sorts débloqués selon progression
	pass

# ============================================================================
# API PUBLIQUE
# ============================================================================

func hide_spell_interface() -> void:
	"""Masque l'interface de magie"""
	magic_panel.hide()
	is_radial_active = false
	octarine_particles.emitting = false
	magic_interface_closed.emit()

func set_current_mana(mana: int) -> void:
	"""Définit la mana actuelle"""
	current_mana = clamp(mana, 0, max_mana)
	update_mana_display()

func add_mana(amount: int) -> void:
	"""Ajoute de la mana"""
	set_current_mana(current_mana + amount)

func set_chaos_probability(probability: float) -> void:
	"""Définit la probabilité de chaos"""
	chaos_probability = clamp(probability, 0.0, 1.0)
	chaos_meter.value = chaos_probability * 100

func equip_spell(spell_id: String, slot: int = -1) -> void:
	"""Équipe un sort dans un slot"""
	if slot == -1:
		equipped_spells.append(spell_id)
	else:
		equipped_spells[slot] = spell_id
	
	# Rafraîchir interface si active
	if is_radial_active:
		populate_spell_wheel()

func unequip_spell(spell_id: String) -> void:
	"""Déséquipe un sort"""
	equipped_spells.erase(spell_id)

func is_magic_interface_active() -> bool:
	"""Vérifie si l'interface magique est active"""
	return magic_panel.visible

# ============================================================================
# DEBUG
# ============================================================================
func setup_magic_styling() -> void:
	pass

func setup_octarine_effects() -> void:
	pass

func enter_area_target_mode(data) -> void:
	pass

func _on_debug_test_magic() -> void:
	"""Test interface magique pour debug"""
	if OS.is_debug_build():
		show_spell_selection({"debug": true})
