# ============================================================================
# 💬 DialogueUI.gd - Interface Conversations Terry Pratchett
# ============================================================================
# STATUS: ✅ COMPLET | Sous-système UIManager
# PRIORITY: 🔴 CRITICAL - Interactions narratives essentielles
# DEPENDENCIES: UIManager, DialogueManager

class_name DialogueUI
extends Control

## Interface de dialogue spécialisée pour "Sortilèges & Bestioles"
## Style Terry Pratchett avec bulles expressives, portraits animés
## Support complet accessibilité et choix complexes

# ============================================================================
# SIGNAUX
# ============================================================================

signal dialogue_choice_selected(choice_id: String, choice_data: Dictionary)
signal dialogue_ended(npc_id: String, final_choice: String)
signal dialogue_text_completed()
signal dialogue_skipped()

# ============================================================================
# CONFIGURATION
# ============================================================================

var dialogue_config: Dictionary = {}
var current_dialogue_data: Dictionary = {}
var current_npc_id: String = ""
var is_text_animating: bool = false
var text_display_speed: float = 50.0
var auto_advance_delay: float = 2.0

# ============================================================================
# ÉLÉMENTS UI
# ============================================================================

## Conteneurs principaux
@onready var dialogue_panel: NinePatchRect
@onready var npc_portrait_container: Control
@onready var dialogue_text_container: Control
@onready var choices_container: VBoxContainer
@onready var speaker_name_label: Label
@onready var dialogue_background: ColorRect

## Portrait NPC
@onready var npc_portrait: TextureRect
@onready var portrait_animation: AnimationPlayer
@onready var portrait_expression_overlay: TextureRect

## Texte de dialogue
@onready var dialogue_text: RichTextLabel
@onready var text_animation: AnimationPlayer
@onready var typing_sound: AudioStreamPlayer

## Choix et interaction
@onready var choices_list: VBoxContainer
@onready var continue_indicator: Control
@onready var skip_indicator: Label

## Effets Terry Pratchett
@onready var magic_sparkles: CPUParticles2D
@onready var speech_bubble_tail: Line2D
@onready var footnote_container: Control

# ============================================================================
# TYPES & STYLES
# ============================================================================

enum DialogueBubbleStyle {
	STANDARD = 0,       ## Bulle classique
	TERRY_PRATCHETT = 1, ## Style Disque-Monde avec personnalité
	DEATH_SPECIAL = 2,   ## Style spécial pour LA MORT
	MAGICAL = 3,         ## Bulle avec effets magiques
	COMEDIC = 4          ## Style humoristique exagéré
}

enum PortraitExpression {
	NEUTRAL = 0,
	HAPPY = 1,
	ANGRY = 2,
	SURPRISED = 3,
	SAD = 4,
	THOUGHTFUL = 5,
	MISCHIEVOUS = 6,
	WISE = 7
}

# ============================================================================
# INITIALISATION
# ============================================================================

func initialize(parent_container: Control, config: Dictionary) -> void:
	"""Initialise le système DialogueUI"""
	dialogue_config = config
	
	# Créer la structure UI
	create_dialogue_interface(parent_container)
	setup_dialogue_styling()
	setup_accessibility_features()
	
	# Configuration Terry Pratchett
	setup_terry_pratchett_style()
	
	print("💬 DialogueUI: Initialisé avec style Terry Pratchett")

func create_dialogue_interface(parent: Control) -> void:
	"""Crée l'interface de dialogue complète"""
	# Conteneur principal du dialogue
	dialogue_panel = NinePatchRect.new()
	dialogue_panel.name = "DialoguePanel"
	dialogue_panel.texture = load("res://ui/textures/dialogue_bubble_pratchett.png")
	dialogue_panel.patch_margin_left = 20
	dialogue_panel.patch_margin_right = 20
	dialogue_panel.patch_margin_top = 20
	dialogue_panel.patch_margin_bottom = 20
	dialogue_panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	dialogue_panel.offset_top = -200
	dialogue_panel.offset_bottom = -20
	dialogue_panel.offset_left = 50
	dialogue_panel.offset_right = -50
	parent.add_child(dialogue_panel)
	
	# Background avec transparence Terry Pratchett
	dialogue_background = ColorRect.new()
	dialogue_background.color = Color(0.1, 0.1, 0.2, 0.85)  # Bleu sombre semi-transparent
	dialogue_background.anchors_preset = Control.PRESET_FULL_RECT
	dialogue_panel.add_child(dialogue_background)
	
	# Container portrait NPC
	npc_portrait_container = Control.new()
	npc_portrait_container.name = "PortraitContainer"
	npc_portrait_container.anchors_preset = Control.PRESET_LEFT_WIDE
	npc_portrait_container.offset_right = 150
	dialogue_panel.add_child(npc_portrait_container)
	
	# Portrait principal
	npc_portrait = TextureRect.new()
	npc_portrait.name = "NPCPortrait"
	npc_portrait.anchors_preset = Control.PRESET_CENTER
	npc_portrait.custom_minimum_size = Vector2(120, 120)
	npc_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	npc_portrait_container.add_child(npc_portrait)
	
	# Overlay expression (pour émotions)
	portrait_expression_overlay = TextureRect.new()
	portrait_expression_overlay.name = "ExpressionOverlay"
	portrait_expression_overlay.anchors_preset = Control.PRESET_FULL_RECT
	portrait_expression_overlay.modulate = Color.TRANSPARENT
	npc_portrait.add_child(portrait_expression_overlay)
	
	# Animation portrait
	portrait_animation = AnimationPlayer.new()
	portrait_animation.name = "PortraitAnimation"
	npc_portrait.add_child(portrait_animation)
	
	# Container texte dialogue
	dialogue_text_container = Control.new()
	dialogue_text_container.name = "TextContainer"
	dialogue_text_container.anchors_preset = Control.PRESET_FULL_RECT
	dialogue_text_container.offset_left = 160
	dialogue_text_container.offset_right = -20
	dialogue_text_container.offset_top = 20
	dialogue_text_container.offset_bottom = -80
	dialogue_panel.add_child(dialogue_text_container)
	
	# Nom du parleur
	speaker_name_label = Label.new()
	speaker_name_label.name = "SpeakerName"
	speaker_name_label.text = "NPC"
	speaker_name_label.add_theme_font_size_override("font_size", 18)
	speaker_name_label.add_theme_color_override("font_color", Color.YELLOW)
	speaker_name_label.anchors_preset = Control.PRESET_TOP_LEFT
	speaker_name_label.offset_bottom = 25
	dialogue_text_container.add_child(speaker_name_label)
	
	# Texte principal du dialogue
	dialogue_text = RichTextLabel.new()
	dialogue_text.name = "DialogueText"
	dialogue_text.bbcode_enabled = true
	dialogue_text.fit_content = true
	dialogue_text.scroll_active = false
	dialogue_text.anchors_preset = Control.PRESET_FULL_RECT
	dialogue_text.offset_top = 30
	dialogue_text.offset_bottom = -10
	dialogue_text_container.add_child(dialogue_text)
	
	# Animation du texte (effet machine à écrire)
	text_animation = AnimationPlayer.new()
	text_animation.name = "TextAnimation"
	dialogue_text.add_child(text_animation)
	
	# Container pour les choix
	choices_container = VBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.anchors_preset = Control.PRESET_BOTTOM_WIDE
	choices_container.offset_left = 160
	choices_container.offset_right = -20
	choices_container.offset_top = -70
	choices_container.offset_bottom = -10
	dialogue_panel.add_child(choices_container)
	
	# Indicateur de continuation
	continue_indicator = Control.new()
	continue_indicator.name = "ContinueIndicator"
	var continue_label = Label.new()
	continue_label.text = "▼ Appuyez sur [ESPACE] pour continuer"
	continue_label.add_theme_color_override("font_color", Color.CYAN)
	continue_label.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	continue_label.offset_left = -250
	continue_label.offset_top = -20
	continue_indicator.add_child(continue_label)
	dialogue_panel.add_child(continue_indicator)
	
	# Son de frappe (effet machine à écrire)
	typing_sound = AudioStreamPlayer.new()
	typing_sound.name = "TypingSound"
	typing_sound.stream = load("res://audio/ui/typing_sound.ogg")  # À créer
	typing_sound.volume_db = -10
	dialogue_panel.add_child(typing_sound)
	
	# Effets particules magiques Terry Pratchett
	magic_sparkles = CPUParticles2D.new()
	magic_sparkles.name = "MagicSparkles"
	magic_sparkles.emitting = false
	magic_sparkles.amount = 20
	magic_sparkles.lifetime = 2.0
	magic_sparkles.direction = Vector2(0, -1)
	magic_sparkles.initial_velocity_min = 20.0
	magic_sparkles.initial_velocity_max = 50.0
	magic_sparkles.scale_amount_min = 0.5
	magic_sparkles.scale_amount_max = 1.5
	dialogue_panel.add_child(magic_sparkles)
	
	# Container footnotes (style Terry Pratchett)
	footnote_container = Control.new()
	footnote_container.name = "FootnoteContainer"
	footnote_container.anchors_preset = Control.PRESET_BOTTOM_WIDE
	footnote_container.offset_top = -15
	dialogue_panel.add_child(footnote_container)
	
	# Masquer l'interface par défaut
	dialogue_panel.hide()

func setup_dialogue_styling() -> void:
	"""Configure le style visuel du dialogue"""
	var style = dialogue_config.get("bubble_style", "terry_pratchett")
	
	match style:
		"terry_pratchett":
			setup_terry_pratchett_style()
		"death_special":
			setup_death_dialogue_style()
		"magical":
			setup_magical_dialogue_style()

func setup_terry_pratchett_style() -> void:
	"""Style signature Terry Pratchett avec personnalité"""
	# Couleurs Disque-Monde
	dialogue_background.color = Color(0.05, 0.1, 0.2, 0.9)  # Bleu nuit du Disque
	
	# Police avec caractère
	var font_size = int(dialogue_config.get("text_size", 16))
	dialogue_text.add_theme_font_size_override("normal_font_size", font_size)
	dialogue_text.add_theme_color_override("default_color", Color.WHITE)
	
	# Style du nom du parleur
	speaker_name_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.0))  # Or
	
	# Activer les effets magiques
	magic_sparkles.texture = load("res://vfx/star_particle.png")
	magic_sparkles.color = Color(0.6, 0.4, 1.0, 0.8)  # Octarine approximation

func setup_death_dialogue_style() -> void:
	"""Style spécial pour LA MORT"""
	dialogue_background.color = Color(0.0, 0.0, 0.0, 0.95)  # Noir quasi total
	dialogue_text.add_theme_color_override("default_color", Color.CYAN)
	speaker_name_label.add_theme_color_override("font_color", Color.CYAN)
	speaker_name_label.text = "LA MORT"
	
	# Police plus grande et imposante pour LA MORT
	dialogue_text.add_theme_font_size_override("normal_font_size", 20)

func setup_accessibility_features() -> void:
	"""Configure les fonctionnalités d'accessibilité"""
	# Support daltonisme avec symboles alternatifs
	var accessibility_mode = dialogue_config.get("accessibility_mode", "none")
	
	if accessibility_mode == "colorblind":
		# Ajouter des symboles en plus des couleurs
		continue_indicator.add_child(create_symbol_indicator("continue"))
	
	# Support malvoyance avec texte plus grand
	if accessibility_mode == "low_vision":
		var enlarged_size = int(dialogue_config.get("text_size", 16)) * 1.5
		dialogue_text.add_theme_font_size_override("normal_font_size", enlarged_size)

# ============================================================================
# GESTION DIALOGUE
# ============================================================================

func start_dialogue(npc_id: String, dialogue_id: String) -> void:
	"""Démarre un dialogue avec un NPC"""
	current_npc_id = npc_id
	
	# Charger les données de dialogue depuis DialogueManager
	var dialogue_manager = get_node_or_null("/root/Dialogue")
	if dialogue_manager and dialogue_manager.has_method("get_dialogue_data"):
		current_dialogue_data = dialogue_manager.get_dialogue_data(npc_id, dialogue_id)
	else:
		# Données de test pour développement
		current_dialogue_data = get_test_dialogue_data(npc_id, dialogue_id)
	
	# Configurer l'interface
	setup_npc_display(npc_id)
	display_dialogue_text(current_dialogue_data.get("text", "Bonjour !"))
	
	# Afficher l'interface
	dialogue_panel.show()
	animate_dialogue_appearance()
	
	print("💬 DialogueUI: Dialogue démarré avec ", npc_id)

func setup_npc_display(npc_id: String) -> void:
	"""Configure l'affichage du NPC (portrait, nom, style)"""
	# Charger portrait depuis DataManager
	var data_manager = get_node_or_null("/root/Data")
	var npc_data = {}
	
	if data_manager and data_manager.has_method("get_character_data"):
		npc_data = data_manager.get_character_data(npc_id)
	
	# Nom du NPC
	var display_name = npc_data.get("display_name", npc_id.capitalize())
	speaker_name_label.text = display_name
	
	# Portrait
	var portrait_path = npc_data.get("portrait", "res://ui/portraits/default_npc.png")
	if FileAccess.file_exists(portrait_path):
		npc_portrait.texture = load(portrait_path)
	
	# Style spécial pour certains NPCs
	match npc_id:
		"death":
			setup_death_dialogue_style()
		"rincewind":
			# Style anxieux pour Rincevent
			animate_nervous_portrait()
		"granny_weatherwax":
			# Style autoritaire pour Granny
			speaker_name_label.add_theme_color_override("font_color", Color.PURPLE)

func display_dialogue_text(text: String) -> void:
	"""Affiche le texte de dialogue avec animation"""
	# Nettoyer le texte précédent
	dialogue_text.clear()
	
	# Traitement spécial Terry Pratchett
	var processed_text = process_pratchett_text(text)
	
	# Animation machine à écrire
	is_text_animating = true
	animate_text_display(processed_text)
	
	# Masquer les choix pendant l'animation
	choices_container.hide()
	continue_indicator.hide()

func process_pratchett_text(text: String) -> String:
	"""Traite le texte avec les conventions Terry Pratchett"""
	var processed = text
	
	# Remplacements spéciaux Terry Pratchett
	processed = processed.replace("*footnote*", create_footnote_reference())
	processed = processed.replace("*italic*", "[i]%s[/i]")
	processed = processed.replace("*bold*", "[b]%s[/b]")
	processed = processed.replace("*octarine*", "[color=#9966FF]%s[/color]")
	
	# Gestion DEATH SPEECH (tout en majuscules)
	if current_npc_id == "death":
		processed = processed.to_upper()
	
	# Ajout d'effets BBCode pour l'émotion
	processed = add_emotional_markup(processed)
	
	return processed

func animate_text_display(text: String) -> void:
	"""Anime l'affichage du texte style machine à écrire"""
	var display_speed = dialogue_config.get("text_speed", text_display_speed)
	var chars_per_second = display_speed
	
	# Calculer durée totale
	var total_chars = text.length()
	var total_duration = float(total_chars) / chars_per_second
	
	# Créer l'animation
	var tween = create_tween()
	dialogue_text.visible_characters = 0
	dialogue_text.text = text
	
	# Animation progressive des caractères
	tween.tween_method(update_visible_characters, 0, total_chars, total_duration)
	tween.tween_callback(on_text_animation_complete)
	
	# Son de frappe si activé
	if dialogue_config.get("typing_sound", true):
		play_typing_sound(total_duration)

func update_visible_characters(count: int) -> void:
	"""Met à jour le nombre de caractères visibles"""
	dialogue_text.visible_characters = count

func on_text_animation_complete() -> void:
	"""Appelé quand l'animation de texte est terminée"""
	is_text_animating = false
	dialogue_text_completed.emit()
	
	# Afficher les options suivantes
	show_dialogue_options()

func show_dialogue_options() -> void:
	"""Affiche les options de dialogue disponibles"""
	var choices = current_dialogue_data.get("choices", [])
	
	if choices.is_empty():
		# Pas de choix, afficher indicateur continuation
		continue_indicator.show()
		animate_continue_indicator()
	else:
		# Afficher les choix
		display_choices(choices)

func display_choices(choices: Array) -> void:
	"""Affiche les choix de dialogue"""
	# Nettoyer les choix précédents
	for child in choices_container.get_children():
		child.queue_free()
	
	choices_container.show()
	
	# Créer les boutons de choix
	for i in range(choices.size()):
		var choice_data = choices[i]
		var choice_button = create_choice_button(choice_data, i)
		choices_container.add_child(choice_button)
	
	# Animation d'apparition des choix
	animate_choices_appearance()

func create_choice_button(choice_data: Dictionary, index: int) -> Button:
	"""Crée un bouton de choix dialogue"""
	var button = Button.new()
	button.name = "Choice" + str(index)
	button.text = str(index + 1) + ". " + choice_data.get("text", "Option " + str(index + 1))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.custom_minimum_size.y = 40
	
	# Style Terry Pratchett
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.YELLOW)
	button.add_theme_color_override("font_pressed_color", Color.CYAN)
	
	# Connexion signal
	button.pressed.connect(_on_choice_selected.bind(choice_data, index))
	
	# Icônes spéciales selon le type de choix
	add_choice_type_indicator(button, choice_data)
	
	return button

func add_choice_type_indicator(button: Button, choice_data: Dictionary) -> void:
	"""Ajoute des indicateurs visuels selon le type de choix"""
	var choice_type = choice_data.get("type", "normal")
	var prefix = ""
	
	match choice_type:
		"skill_check":
			prefix = "🎯 "  # Nécessite compétence
		"observation":
			prefix = "👁 "  # Basé sur observations
		"magical":
			prefix = "✨ "  # Option magique
		"philosophical":
			prefix = "🤔 "  # Réflexion Terry Pratchett
		"humorous":
			prefix = "😄 "  # Option drôle
	
	if prefix != "":
		button.text = prefix + button.text

# ============================================================================
# GESTION ÉVÉNEMENTS
# ============================================================================

func _on_choice_selected(choice_data: Dictionary, index: int) -> void:
	"""Gestion sélection d'un choix"""
	var choice_id = choice_data.get("id", "choice_" + str(index))
	
	print("💬 Choix sélectionné: ", choice_id)
	
	# Effet sonore
	play_choice_sound()
	
	# Animation de sélection
	animate_choice_selection(index)
	
	# Transmettre le choix
	dialogue_choice_selected.emit(choice_id, choice_data)
	
	# Continuer le dialogue ou terminer
	process_choice_consequence(choice_data)

func process_choice_consequence(choice_data: Dictionary) -> void:
	"""Traite les conséquences d'un choix"""
	var next_dialogue = choice_data.get("next_dialogue", "")
	var action = choice_data.get("action", "")
	
	if action == "end_dialogue":
		end_dialogue(choice_data.get("id", "unknown"))
	elif next_dialogue != "":
		# Charger le dialogue suivant
		load_next_dialogue(next_dialogue)
	else:
		# Dialogue par défaut ou fin
		end_dialogue(choice_data.get("id", "continue"))

func load_next_dialogue(dialogue_id: String) -> void:
	"""Charge le dialogue suivant"""
	# Transition vers le nouveau dialogue
	animate_dialogue_transition()
	start_dialogue(current_npc_id, dialogue_id)

func end_dialogue(final_choice: String) -> void:
	"""Termine le dialogue"""
	print("💬 Fin dialogue avec: ", current_npc_id)
	
	# Animation de fermeture
	animate_dialogue_disappearance()
	
	# Délai pour l'animation puis masquer
	await get_tree().create_timer(0.5).timeout
	hide_dialogue()
	
	# Signal de fin
	dialogue_ended.emit(current_npc_id, final_choice)

func hide_dialogue() -> void:
	"""Masque l'interface de dialogue"""
	dialogue_panel.hide()
	is_text_animating = false
	current_dialogue_data.clear()
	current_npc_id = ""

# ============================================================================
# ANIMATIONS ET EFFETS
# ============================================================================

func animate_dialogue_appearance() -> void:
	"""Animation d'apparition du dialogue"""
	var tween = create_tween()
	dialogue_panel.modulate = Color.TRANSPARENT
	dialogue_panel.scale = Vector2(0.8, 0.8)
	
	tween.parallel().tween_property(dialogue_panel, "modulate", Color.WHITE, 0.3)
	tween.parallel().tween_property(dialogue_panel, "scale", Vector2.ONE, 0.3)
	tween.tween_callback(trigger_magic_sparkles)

func animate_dialogue_disappearance() -> void:
	"""Animation de disparition du dialogue"""
	var tween = create_tween()
	tween.parallel().tween_property(dialogue_panel, "modulate", Color.TRANSPARENT, 0.3)
	tween.parallel().tween_property(dialogue_panel, "scale", Vector2(0.8, 0.8), 0.3)

func animate_choices_appearance() -> void:
	"""Animation d'apparition des choix"""
	var tween = create_tween()
	choices_container.modulate = Color.TRANSPARENT
	
	tween.tween_property(choices_container, "modulate", Color.WHITE, 0.2)
	
	# Animation en cascade des boutons
	for i in range(choices_container.get_child_count()):
		var button = choices_container.get_child(i)
		button.position.x = -100
		tween.parallel().tween_property(button, "position:x", 0, 0.2).set_delay(i * 0.05)

func animate_choice_selection(index: int) -> void:
	"""Animation de sélection d'un choix"""
	var button = choices_container.get_child(index)
	var tween = create_tween()
	
	# Flash lumineux
	tween.tween_property(button, "modulate", Color.YELLOW, 0.1)
	tween.tween_property(button, "modulate", Color.WHITE, 0.1)

func animate_continue_indicator() -> void:
	"""Animation de l'indicateur de continuation"""
	var tween = create_tween()
	tween.set_loops()
	
	var indicator_label = continue_indicator.get_child(0)
	tween.tween_property(indicator_label, "modulate:a", 0.3, 1.0)
	tween.tween_property(indicator_label, "modulate:a", 1.0, 1.0)

func animate_nervous_portrait() -> void:
	"""Animation spéciale pour Rincevent (nerveux)"""
	var tween = create_tween()
	tween.set_loops()
	
	tween.tween_property(npc_portrait, "rotation", -0.05, 0.2)
	tween.tween_property(npc_portrait, "rotation", 0.05, 0.2)
	tween.tween_property(npc_portrait, "rotation", 0.0, 0.2)

func trigger_magic_sparkles() -> void:
	"""Déclenche les particules magiques"""
	if dialogue_config.get("magic_effects", true):
		magic_sparkles.emitting = true
		get_tree().create_timer(2.0).timeout.connect(func(): magic_sparkles.emitting = false)

# ============================================================================
# AUDIO
# ============================================================================

func play_typing_sound(duration: float) -> void:
	"""Joue le son de frappe pendant l'animation texte"""
	typing_sound.play()
	# TODO: Répéter le son selon la durée

func play_choice_sound() -> void:
	"""Joue le son de sélection de choix"""
	# TODO: Son de sélection
	pass

# ============================================================================
# GESTION INPUT
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Gestion des inputs dialogue"""
	if not dialogue_panel.visible:
		return
	
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		if is_text_animating:
			# Skip animation texte
			skip_text_animation()
		elif continue_indicator.visible:
			# Continuer dialogue
			continue_dialogue()
	
	if event.is_action_pressed("ui_cancel"):
		# Fermer dialogue (seulement si autorisé)
		if dialogue_config.get("allow_cancel", true):
			end_dialogue("cancelled")

func skip_text_animation() -> void:
	"""Accélère ou skip l'animation de texte"""
	if is_text_animating:
		dialogue_text.visible_characters = -1
		is_text_animating = false
		dialogue_skipped.emit()
		on_text_animation_complete()

func continue_dialogue() -> void:
	"""Continue le dialogue après pause"""
	continue_indicator.hide()
	
	# Vérifier s'il y a une suite
	var next_dialogue = current_dialogue_data.get("next_dialogue", "")
	if next_dialogue != "":
		load_next_dialogue(next_dialogue)
	else:
		end_dialogue("continued")

# ============================================================================
# UTILITAIRES
# ============================================================================

func create_footnote_reference() -> String:
	"""Crée une référence de footnote Terry Pratchett"""
	# TODO: Système de footnotes avec numérotation
	return "[color=cyan]*[/color]"

func add_emotional_markup(text: String) -> String:
	"""Ajoute le markup émotionnel au texte"""
	# Remplacements pour émotions
	text = text.replace("*angry*", "[color=red][shake][/color]")
	text = text.replace("*happy*", "[color=yellow][/color]")
	text = text.replace("*magical*", "[color=purple][rainbow][/color]")
	text = text.replace("*whisper*", "[color=gray][font_size=12][/color]")
	text = text.replace("*shout*", "[color=red][font_size=20][b][/b][/color]")
	
	return text

func create_symbol_indicator(type: String) -> Control:
	"""Crée un indicateur symbolique pour l'accessibilité"""
	var symbol = Label.new()
	
	match type:
		"continue":
			symbol.text = "→"
		"choice":
			symbol.text = "●"
		"magic":
			symbol.text = "✦"
	
	symbol.add_theme_color_override("font_color", Color.CYAN)
	return symbol

func get_test_dialogue_data(npc_id: String, dialogue_id: String) -> Dictionary:
	"""Données de test pour développement"""
	return {
		"text": "Bonjour ! Je suis " + npc_id + " et ceci est un dialogue de test pour \"Sortilèges & Bestioles\". *footnote* Remarquez les effets *magical* Terry Pratchett !",
		"choices": [
			{
				"id": "choice_1",
				"text": "Parlez-moi de la magie Octarine",
				"type": "magical",
				"action": "continue"
			},
			{
				"id": "choice_2", 
				"text": "Que savez-vous des créatures magiques ?",
				"type": "observation",
				"action": "continue"
			},
			{
				"id": "choice_3",
				"text": "Au revoir !",
				"type": "normal",
				"action": "end_dialogue"
			}
		]
	}

# ============================================================================
# API PUBLIQUE
# ============================================================================

func set_text_speed(speed: float) -> void:
	"""Définit la vitesse d'affichage du texte"""
	text_display_speed = speed

func set_auto_advance(enabled: bool, delay: float = 2.0) -> void:
	"""Active/désactive l'avancement automatique"""
	dialogue_config["auto_advance"] = enabled
	auto_advance_delay = delay

func force_end_dialogue() -> void:
	"""Force la fin du dialogue (pour cutscenes)"""
	end_dialogue("forced")

func is_dialogue_active() -> bool:
	"""Vérifie si un dialogue est actif"""
	return dialogue_panel.visible

# ============================================================================
# DEBUG
# ============================================================================

func _on_debug_test_dialogue() -> void:
	"""Test dialogue pour debug"""
	if OS.is_debug_build():
		start_dialogue("test_npc", "test_dialogue")