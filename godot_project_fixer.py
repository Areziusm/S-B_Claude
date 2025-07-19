#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🔧 Godot Project Fixer - "Sortilèges & Bestioles"
==================================================
Script Python pour corriger automatiquement tous les problèmes du projet Godot.

Usage:
    python godot_project_fixer.py

Actions:
- Crée la structure de dossiers nécessaire
- Génère tous les scripts corrigés
- Corrige les références AutoLoad
- Crée les stubs temporaires
- Génère une scène de test fonctionnelle

Auteur: Assistant IA
Date: Juillet 2025
"""

import os
import json
import shutil
from pathlib import Path
from typing import Dict, List, Tuple

class GodotProjectFixer:
    def __init__(self, project_root: str = "."):
        """Initialise le correcteur de projet Godot."""
        self.project_root = Path(project_root)
        self.scripts_path = self.project_root / "scripts"
        self.scenes_path = self.project_root / "scenes"
        self.data_path = self.project_root / "data"
        
        self.fixes_applied = []
        self.files_created = []
        self.errors = []
        
        print("🔧 Godot Project Fixer - Sortilèges & Bestioles")
        print("=" * 60)
    
    def run_all_fixes(self):
        """Exécute toutes les corrections."""
        try:
            self.create_directory_structure()
            self.create_stub_managers()
            self.create_core_scripts()
            self.create_test_scene()
            self.create_input_map()
            self.fix_existing_gamemanager()
            self.generate_autoload_instructions()
            self.print_summary()
            
        except Exception as e:
            self.errors.append(f"Erreur critique: {str(e)}")
            print(f"❌ Erreur: {e}")
            
    def create_directory_structure(self):
        """Crée la structure de dossiers nécessaire."""
        directories = [
            "scripts/core",
            "scripts/stubs", 
            "scripts/managers",
            "scenes/test",
            "data",
            "data/localization"
        ]
        
        for dir_path in directories:
            full_path = self.project_root / dir_path
            full_path.mkdir(parents=True, exist_ok=True)
            self.fixes_applied.append(f"📁 Dossier créé: {dir_path}")
    
    def create_stub_managers(self):
        """Crée les managers stub temporaires."""
        
        # UIManager Stub
        ui_manager_content = '''# ============================================================================
# 📱 UIManager.gd - Gestionnaire Interface Utilisateur (STUB TEMPORAIRE)
# ============================================================================
# STATUS: 🟡 STUB | ROADMAP: Mois 1, Semaine 3-4 - UI Architecture
# PRIORITY: 🟠 P2 - Interface cohérente
# DEPENDENCIES: GameManager

class_name UIManager
extends CanvasLayer

## Gestionnaire temporaire de l'interface utilisateur
## Version minimale pour éviter les erreurs de compilation

signal ui_element_shown(element_name: String)
signal ui_element_hidden(element_name: String)
signal manager_initialized()

var is_initialized: bool = false

func _ready() -> void:
	"""Initialisation basique du UIManager"""
	print("📱 UIManager: Stub temporaire initialisé")
	is_initialized = true
	manager_initialized.emit()

func toggle_pause_menu() -> void:
	"""Affiche/cache le menu pause (stub)"""
	print("📱 UIManager: Menu pause toggled (stub)")

func show_panel(panel_name: String) -> void:
	"""Affiche un panneau UI (stub)"""
	print("📱 UIManager: Affichage panneau ", panel_name, " (stub)")
	ui_element_shown.emit(panel_name)

func hide_panel(panel_name: String) -> void:
	"""Cache un panneau UI (stub)"""
	print("📱 UIManager: Masquage panneau ", panel_name, " (stub)")
	ui_element_hidden.emit(panel_name)

func show_notification(message: String, type: String = "info") -> void:
	"""Affiche une notification (stub)"""
	print("📱 Notification [", type, "]: ", message)

func start_transition(transition_type) -> void:
	"""Démarre une transition (stub)"""
	print("📱 UIManager: Transition démarrée (stub)")
	await get_tree().create_timer(0.3).timeout

func complete_transition() -> void:
	"""Termine une transition (stub)"""
	print("📱 UIManager: Transition terminée (stub)")
'''
        
        # AudioManager Stub
        audio_manager_content = '''# ============================================================================
# 🔊 AudioManager.gd - Gestionnaire Audio (STUB TEMPORAIRE)
# ============================================================================
# STATUS: 🟡 STUB | ROADMAP: Mois 1, Semaine 3-4 - Audio Architecture
# PRIORITY: 🟡 P3 - Audio et ambiance
# DEPENDENCIES: GameManager

class_name AudioManager
extends Node

## Gestionnaire temporaire de l'audio
## Version minimale pour éviter les erreurs de compilation

signal audio_started(audio_type: String, track_name: String)
signal audio_stopped(audio_type: String)
signal manager_initialized()

var is_initialized: bool = false
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 0.8
var voice_volume: float = 1.0

func _ready() -> void:
	"""Initialisation basique de l'AudioManager"""
	print("🔊 AudioManager: Stub temporaire initialisé")
	is_initialized = true
	manager_initialized.emit()

func play_music(track_name: String, fade_time: float = 1.0) -> void:
	"""Joue une musique (stub)"""
	print("🔊 AudioManager: Musique ", track_name, " (stub)")
	audio_started.emit("music", track_name)

func play_sfx(sfx_name: String, position: Vector2 = Vector2.ZERO) -> void:
	"""Joue un effet sonore (stub)"""
	print("🔊 AudioManager: SFX ", sfx_name, " à ", position, " (stub)")
	audio_started.emit("sfx", sfx_name)

func update_volume_settings(settings: Dictionary) -> void:
	"""Met à jour les paramètres de volume (stub)"""
	print("🔊 AudioManager: Volumes mis à jour (stub)")
'''
        
        self.write_file("scripts/stubs/UIManager.gd", ui_manager_content)
        self.write_file("scripts/stubs/AudioManager.gd", audio_manager_content)
    
    def create_core_scripts(self):
        """Crée les scripts core corrigés."""
        
        # Player.gd corrigé
        player_content = '''# ============================================================================
# 🎮 Player.gd - Contrôleur Joueur Principal (CORRIGÉ)
# ============================================================================
# STATUS: ✅ CORRIGÉ | ROADMAP: Mois 1, Semaine 3 - Core Gameplay
# PRIORITY: 🔴 CRITICAL - Débloquer tout le gameplay
# DEPENDENCIES: Game, Observation, Dialogue, UI

class_name Player
extends CharacterBody2D

## Contrôleur principal du joueur pour "Sortilèges & Bestioles"
## Version corrigée avec bonnes références AutoLoad

# ============================================================================
# SIGNAUX
# ============================================================================

signal movement_started()
signal movement_stopped()
signal interaction_started(target: Node, interaction_type: String)
signal interaction_ended(target: Node)
signal observation_started(target: Node)
signal observation_ended(target: Node, duration: float)
signal player_state_changed(old_state: String, new_state: String)
signal player_moved(new_position: Vector2, previous_position: Vector2)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export_group("Movement")
@export var base_speed: float = 200.0
@export var run_speed_multiplier: float = 1.8
@export var acceleration: float = 10.0
@export var friction: float = 10.0

@export_group("Interaction")
@export var interaction_range: float = 50.0
@export var observation_range: float = 80.0
@export var observation_min_time: float = 2.0

@export_group("Debug")
@export var debug_mode: bool = false
@export var show_interaction_range: bool = false

# ============================================================================
# COMPOSANTS
# ============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var observation_area: Area2D = $ObservationArea
@onready var observation_camera: Camera2D = $ObservationCamera

# ============================================================================
# VARIABLES D'ÉTAT
# ============================================================================

enum PlayerState {
	IDLE,
	MOVING,
	INTERACTING,
	OBSERVING,
	IN_DIALOGUE,
	IN_MENU,
	DISABLED
}

var current_state: PlayerState = PlayerState.IDLE
var input_vector: Vector2 = Vector2.ZERO
var is_running: bool = false
var is_moving: bool = false
var is_observing: bool = false

var interactable_objects: Array[Node] = []
var observable_creatures: Array[Node] = []
var current_interaction_target: Node = null
var current_observation_target: Node = null
var observation_timer: float = 0.0

# Références aux managers (CORRIGÉ: noms AutoLoad corrects)
var game_manager: GameManager
var observation_manager: ObservationManager
var dialogue_manager: DialogueManager
var ui_manager: UIManager
var audio_manager: AudioManager

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	"""Initialisation du joueur"""
	if debug_mode:
		print("🎮 Player: Initialisation...")
	
	await get_tree().process_frame
	connect_to_managers()
	setup_initial_state()
	setup_interaction_areas()
	
	if debug_mode:
		print("🎮 Player: Prêt! Position:", global_position)

func connect_to_managers() -> void:
	"""Connexion aux managers (CORRIGÉ: noms AutoLoad)"""
	game_manager = get_node_or_null("/root/Game")
	observation_manager = get_node_or_null("/root/Observation")
	dialogue_manager = get_node_or_null("/root/Dialogue")
	ui_manager = get_node_or_null("/root/UI")
	audio_manager = get_node_or_null("/root/Audio")
	
	# Connexions aux signaux
	if dialogue_manager:
		dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
	
	if debug_mode:
		print("🎮 Player: Connexions managers établies")

func setup_initial_state() -> void:
	"""Configuration de l'état initial"""
	current_state = PlayerState.IDLE
	set_physics_process(true)
	set_process_input(true)
	collision_layer = 1
	collision_mask = 2

func setup_interaction_areas() -> void:
	"""Configuration des zones d'interaction"""
	if interaction_area:
		var interaction_shape = CircleShape2D.new()
		interaction_shape.radius = interaction_range
		var collision = interaction_area.get_node("CollisionShape2D")
		if collision:
			collision.shape = interaction_shape
		
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)
	
	if observation_area:
		var observation_shape = CircleShape2D.new()
		observation_shape.radius = observation_range
		var collision = observation_area.get_node("CollisionShape2D")
		if collision:
			collision.shape = observation_shape
		
		observation_area.body_entered.connect(_on_observation_area_entered)
		observation_area.body_exited.connect(_on_observation_area_exited)

# ============================================================================
# BOUCLE PRINCIPALE
# ============================================================================

func _physics_process(delta: float) -> void:
	"""Boucle principale de physique"""
	if can_move():
		handle_movement_input()
		process_movement(delta)
	else:
		stop_movement()
	
	update_observation(delta)

func _input(event: InputEvent) -> void:
	"""Gestion des inputs principaux"""
	if event.is_action_pressed("observe"):
		start_observation()
	elif event.is_action_released("observe"):
		stop_observation()
	
	if event.is_action_pressed("interact"):
		attempt_interaction()
	
	if event.is_action_pressed("run"):
		is_running = true
	elif event.is_action_released("run"):
		is_running = false

# ============================================================================
# SYSTÈME DE MOUVEMENT
# ============================================================================

func handle_movement_input() -> void:
	"""Gestion des inputs de mouvement"""
	input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	if Input.is_action_pressed("move_down"):
		input_vector.y += 1
	if Input.is_action_pressed("move_up"):
		input_vector.y -= 1
	
	if input_vector.length() > 1:
		input_vector = input_vector.normalized()

func process_movement(delta: float) -> void:
	"""Traitement du mouvement physique"""
	var target_speed = calculate_movement_speed()
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(
			input_vector * target_speed, 
			acceleration * target_speed * delta
		)
		
		if not is_moving:
			start_movement()
	else:
		velocity = velocity.move_toward(
			Vector2.ZERO, 
			friction * target_speed * delta
		)
		
		if velocity.length() < 5 and is_moving:
			stop_movement()
	
	move_and_slide()

func calculate_movement_speed() -> float:
	"""Calcule la vitesse de mouvement selon le contexte"""
	var speed = base_speed
	if is_running:
		speed *= run_speed_multiplier
	return speed

func start_movement() -> void:
	"""Démarre le mouvement"""
	is_moving = true
	change_state(PlayerState.MOVING)
	movement_started.emit()

func stop_movement() -> void:
	"""Arrête le mouvement"""
	if is_moving:
		is_moving = false
		if current_state == PlayerState.MOVING:
			change_state(PlayerState.IDLE)
		movement_stopped.emit()

func can_move() -> bool:
	"""Vérifie si le mouvement est autorisé"""
	return current_state in [PlayerState.IDLE, PlayerState.MOVING, PlayerState.OBSERVING]

# ============================================================================
# SYSTÈME D'INTERACTION
# ============================================================================

func attempt_interaction() -> void:
	"""Tente une interaction avec l'objet le plus proche"""
	if current_state == PlayerState.IN_DIALOGUE:
		if dialogue_manager:
			dialogue_manager.advance_dialogue()
		return
	
	var target = find_best_interaction_target()
	if target:
		start_interaction(target)

func find_best_interaction_target() -> Node:
	"""Trouve la meilleure cible d'interaction"""
	if interactable_objects.is_empty():
		return null
	
	var best_target: Node = null
	var best_distance: float = INF
	
	for obj in interactable_objects:
		if obj and is_instance_valid(obj):
			var distance = global_position.distance_to(obj.global_position)
			if distance < best_distance:
				best_distance = distance
				best_target = obj
	
	return best_target

func start_interaction(target: Node) -> void:
	"""Démarre une interaction avec une cible"""
	if not target:
		return
	
	current_interaction_target = target
	change_state(PlayerState.INTERACTING)
	interaction_started.emit(target, get_interaction_type(target))
	
	process_interaction(target)

func process_interaction(target: Node) -> void:
	"""Traite l'interaction selon le type d'objet"""
	if target.has_method("start_dialogue") or target.is_in_group("npcs"):
		start_dialogue_with_npc(target)
	elif target.has_method("observe") or target.is_in_group("creatures"):
		start_observation_of_creature(target)
	elif target.has_method("interact"):
		target.interact(self)
		end_interaction()
	else:
		print("🎮 Interaction avec:", target.name)
		end_interaction()

func start_dialogue_with_npc(npc: Node) -> void:
	"""Démarre un dialogue avec un NPC"""
	if dialogue_manager:
		var npc_id = npc.npc_id if "npc_id" in npc else npc.name.to_lower()
		dialogue_manager.start_dialogue(npc_id, "default")
	else:
		print("⚠️ DialogueManager non disponible")
		end_interaction()

func end_interaction() -> void:
	"""Termine l'interaction actuelle"""
	if current_interaction_target:
		interaction_ended.emit(current_interaction_target)
		current_interaction_target = null
	
	if current_state == PlayerState.INTERACTING:
		change_state(PlayerState.IDLE)

# ============================================================================
# SYSTÈME D'OBSERVATION
# ============================================================================

func start_observation() -> void:
	"""Démarre le mode observation"""
	if current_state in [PlayerState.IN_DIALOGUE, PlayerState.IN_MENU]:
		return
	
	var target = find_best_observation_target()
	if target:
		start_observation_of_creature(target)
	else:
		change_state(PlayerState.OBSERVING)
		observation_started.emit(null)

func start_observation_of_creature(creature: Node) -> void:
	"""Démarre l'observation d'une créature spécifique"""
	current_observation_target = creature
	is_observing = true
	observation_timer = 0.0
	
	change_state(PlayerState.OBSERVING)
	observation_started.emit(creature)

func stop_observation() -> void:
	"""Arrête le mode observation"""
	if not is_observing:
		return
	
	var duration = observation_timer
	var target = current_observation_target
	
	if duration >= observation_min_time and target:
		process_creature_observation(target, duration)
	
	is_observing = false
	observation_timer = 0.0
	observation_ended.emit(target, duration)
	current_observation_target = null
	
	if current_state == PlayerState.OBSERVING:
		change_state(PlayerState.IDLE)

func process_creature_observation(creature: Node, duration: float) -> void:
	"""Traite l'observation d'une créature (CORRIGÉ)"""
	if observation_manager:
		var creature_id = creature.creature_id if "creature_id" in creature else creature.name.to_lower()
		var intensity = calculate_observation_intensity(duration)
		observation_manager.observe_creature(creature_id, intensity)
	
	if debug_mode:
		print("🔮 Observation:", creature.name, "durée:", duration, "s")

func calculate_observation_intensity(duration: float) -> float:
	"""Calcule l'intensité d'observation selon la durée"""
	return min(duration / observation_min_time, 3.0)

func find_best_observation_target() -> Node:
	"""Trouve la meilleure cible d'observation"""
	if observable_creatures.is_empty():
		return null
	
	var best_target: Node = null
	var best_score: float = 0.0
	
	for creature in observable_creatures:
		if creature and is_instance_valid(creature):
			var distance = global_position.distance_to(creature.global_position)
			var score = 1.0 / (1.0 + distance / observation_range)
			
			if score > best_score:
				best_score = score
				best_target = creature
	
	return best_target

func update_observation(delta: float) -> void:
	"""Mise à jour du système d'observation"""
	if is_observing:
		observation_timer += delta

# ============================================================================
# GESTION DES ÉTATS
# ============================================================================

func change_state(new_state: PlayerState) -> void:
	"""Change l'état du joueur"""
	if new_state == current_state:
		return
	
	var previous_state = current_state
	current_state = new_state
	
	player_state_changed.emit(
		PlayerState.keys()[previous_state], 
		PlayerState.keys()[current_state]
	)
	
	if debug_mode:
		print("🎮 État changé:", PlayerState.keys()[previous_state], "→", PlayerState.keys()[current_state])

# ============================================================================
# CALLBACKS
# ============================================================================

func _on_interaction_area_entered(body: Node) -> void:
	"""Objet entré dans la zone d'interaction"""
	if body == self:
		return
	
	if body.has_method("get_interaction_type") or body.is_in_group("interactables"):
		interactable_objects.append(body)
		if debug_mode:
			print("🎮 Interaction disponible:", body.name)

func _on_interaction_area_exited(body: Node) -> void:
	"""Objet sorti de la zone d'interaction"""
	if body in interactable_objects:
		interactable_objects.erase(body)
		if body == current_interaction_target:
			end_interaction()

func _on_observation_area_entered(body: Node) -> void:
	"""Créature entrée dans la zone d'observation"""
	if body == self:
		return
	
	if body.has_method("observe") or body.is_in_group("creatures"):
		observable_creatures.append(body)
		if debug_mode:
			print("🔮 Créature observable:", body.name)

func _on_observation_area_exited(body: Node) -> void:
	"""Créature sortie de la zone d'observation"""
	if body in observable_creatures:
		observable_creatures.erase(body)
		if body == current_observation_target:
			stop_observation()

func _on_dialogue_started(npc_id: String, dialogue_id: String) -> void:
	"""Callback: dialogue démarré"""
	change_state(PlayerState.IN_DIALOGUE)

func _on_dialogue_ended(npc_id: String, final_choice: String, relationship_change: float) -> void:
	"""Callback: dialogue terminé"""
	end_interaction()

# ============================================================================
# UTILITAIRES
# ============================================================================

func get_interaction_type(target: Node) -> String:
	"""Détermine le type d'interaction d'un objet"""
	if target.has_method("get_interaction_type"):
		return target.get_interaction_type()
	elif target.is_in_group("npcs"):
		return "dialogue"
	elif target.is_in_group("creatures"):
		return "observation"
	else:
		return "generic"

func get_player_data() -> Dictionary:
	"""Retourne les données du joueur pour sauvegarde"""
	return {
		"position": global_position,
		"state": PlayerState.keys()[current_state],
		"movement_speed": base_speed
	}

# ============================================================================
# DEBUG
# ============================================================================

func _draw() -> void:
	"""Debug visuel"""
	if not debug_mode or not show_interaction_range:
		return
	
	draw_circle(Vector2.ZERO, interaction_range, Color.BLUE, false, 2)
	draw_circle(Vector2.ZERO, observation_range, Color.GREEN, false, 2)
'''
        
        # Creature.gd corrigé (version plus courte)
        creature_content = '''# ============================================================================
# 🐾 Creature.gd - Base pour Système d'Évolution (CORRIGÉ)
# ============================================================================

class_name Creature
extends CharacterBody2D

## Classe de base pour toutes les créatures observables

# ============================================================================
# SIGNAUX
# ============================================================================

signal creature_observed(creature: Creature, observer: Node, intensity: float)
signal creature_evolved(creature: Creature, old_stage: int, new_stage: int)
signal behavior_changed(creature: Creature, old_behavior: String, new_behavior: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export_group("Identity")
@export var creature_id: String = "unknown_creature"
@export var display_name: String = "Créature Mystérieuse"
@export var species: String = "unknown"

@export_group("Evolution")
@export var current_evolution_stage: int = 0
@export var max_evolution_stage: int = 4
@export var observation_count: int = 0
@export var magic_affinity: float = 1.0

@export_group("Behavior")
@export var base_speed: float = 50.0
@export var awareness_radius: float = 100.0
@export var roaming_distance: float = 150.0

@export_group("Debug")
@export var debug_mode: bool = false

# ============================================================================
# COMPOSANTS
# ============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ============================================================================
# VARIABLES D'ÉTAT
# ============================================================================

enum CreatureBehavior {
	IDLE,
	ROAMING,
	CURIOUS,
	AWARE,
	FLEEING,
	EVOLVING,
	MAGICAL
}

var current_behavior: CreatureBehavior = CreatureBehavior.IDLE
var evolution_data: Dictionary = {}
var is_evolving: bool = false
var evolution_timer: float = 0.0

var home_position: Vector2
var target_position: Vector2
var behavior_timer: float = 0.0

var observers: Array[Node] = []
var current_observer: Node = null
var observation_intensity: float = 0.0
var is_magical: bool = false
var magic_level: float = 0.0
var magic_timer: float = 0.0

# Références aux managers (CORRIGÉ: noms AutoLoad)
var observation_manager: ObservationManager
var data_manager: DataManager

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	"""Initialisation de la créature"""
	if debug_mode:
		print("🐾 Creature:", creature_id, "initialisation...")
	
	await get_tree().process_frame
	connect_to_managers()
	setup_creature_data()
	setup_visual_appearance()
	
	home_position = global_position
	target_position = home_position
	
	if debug_mode:
		print("🐾 Creature:", display_name, "prête! Stade:", current_evolution_stage)

func connect_to_managers() -> void:
	"""Connexion aux managers (CORRIGÉ: noms AutoLoad)"""
	observation_manager = get_node_or_null("/root/Observation")
	data_manager = get_node_or_null("/root/Data")
	
	if debug_mode:
		print("🐾 Creature: Connexions managers établies")

func setup_creature_data() -> void:
	"""Charge les données spécifiques de la créature"""
	evolution_data = {
		"name": display_name,
		"species": species,
		"evolution_stages": [
			{"name": "Ordinaire", "description": "État naturel", "magic_level": 0.0},
			{"name": "Conscient", "description": "Prise de conscience", "magic_level": 0.2},
			{"name": "Éveillé", "description": "Intelligence accrue", "magic_level": 0.5},
			{"name": "Magique", "description": "Capacités magiques", "magic_level": 0.8},
			{"name": "Légendaire", "description": "Être transcendant", "magic_level": 1.0}
		],
		"magic_affinity": magic_affinity,
		"observation_thresholds": [0, 3, 7, 12, 20]
	}

func setup_visual_appearance() -> void:
	"""Configure l'apparence visuelle selon l'évolution"""
	update_visual_for_stage(current_evolution_stage)

# ============================================================================
# BOUCLE PRINCIPALE
# ============================================================================

func _physics_process(delta: float) -> void:
	"""Boucle principale de physique"""
	behavior_timer += delta
	magic_timer += delta
	
	if is_evolving:
		evolution_timer += delta
	
	process_behavior(delta)
	process_movement(delta)
	
	if is_magical:
		process_magic_effects(delta)

func process_behavior(delta: float) -> void:
	"""Traite le comportement actuel"""
	match current_behavior:
		CreatureBehavior.IDLE:
			if behavior_timer > 3.0 and randf() < 0.3:
				start_roaming()
		CreatureBehavior.ROAMING:
			if global_position.distance_to(target_position) < 20.0:
				choose_new_roaming_target()
		CreatureBehavior.CURIOUS:
			if current_observer:
				look_at_observer()
			else:
				change_behavior(CreatureBehavior.IDLE)
		CreatureBehavior.EVOLVING:
			if evolution_timer > 2.0:
				complete_evolution()

func process_movement(delta: float) -> void:
	"""Traite le mouvement physique"""
	if is_evolving:
		velocity = Vector2.ZERO
	else:
		calculate_movement_velocity()
	
	move_and_slide()

func calculate_movement_velocity() -> void:
	"""Calcule la vélocité de mouvement"""
	var direction = Vector2.ZERO
	var speed = base_speed
	
	match current_behavior:
		CreatureBehavior.ROAMING:
			direction = (target_position - global_position).normalized()
		CreatureBehavior.FLEEING:
			if current_observer:
				direction = (global_position - current_observer.global_position).normalized()
				speed *= 2.0
	
	velocity = velocity.move_toward(direction * speed, 300.0 * get_physics_process_delta_time())

func process_magic_effects(delta: float) -> void:
	"""Traite les effets magiques continus (CORRIGÉ: fonction ajoutée)"""
	if not is_magical:
		return
	
	# Effets magiques périodiques
	if magic_timer > 3.0:
		trigger_magic_event()
		magic_timer = 0.0

# ============================================================================
# SYSTÈME D'OBSERVATION
# ============================================================================

func start_observation(observer: Node, intensity: float = 1.0) -> void:
	"""Démarre l'observation par un joueur"""
	if observer in observers:
		return
	
	observers.append(observer)
	current_observer = observer
	observation_intensity = intensity
	
	if current_evolution_stage == 0:
		change_behavior(CreatureBehavior.CURIOUS)
	else:
		change_behavior(CreatureBehavior.AWARE)
	
	creature_observed.emit(self, observer, intensity)
	
	if debug_mode:
		print("🔮 ", display_name, "observée par", observer.name)

func stop_observation(observer: Node) -> void:
	"""Arrête l'observation"""
	if observer in observers:
		observers.erase(observer)
	
	if observer == current_observer:
		current_observer = null
		observation_intensity = 0.0
		
		if current_behavior in [CreatureBehavior.CURIOUS, CreatureBehavior.AWARE]:
			change_behavior(CreatureBehavior.IDLE)

# ============================================================================
# SYSTÈME D'ÉVOLUTION
# ============================================================================

func trigger_evolution() -> void:
	"""Déclenche l'évolution vers le stade suivant"""
	if is_evolving or current_evolution_stage >= max_evolution_stage:
		return
	
	var old_stage = current_evolution_stage
	current_evolution_stage += 1
	
	is_evolving = true
	evolution_timer = 0.0
	change_behavior(CreatureBehavior.EVOLVING)
	
	creature_evolved.emit(self, old_stage, current_evolution_stage)
	
	if debug_mode:
		print("🎉 ", display_name, "évolue! Stade", old_stage, "→", current_evolution_stage)

func complete_evolution() -> void:
	"""Termine le processus d'évolution"""
	is_evolving = false
	evolution_timer = 0.0
	
	update_stats_for_stage(current_evolution_stage)
	update_visual_for_stage(current_evolution_stage)
	
	change_behavior(CreatureBehavior.IDLE)
	
	if debug_mode:
		print("✨ ", display_name, "évolution terminée! Nouveau stade:", current_evolution_stage)

func update_stats_for_stage(stage: int) -> void:
	"""Met à jour les stats selon le stade d'évolution"""
	base_speed += stage * 10.0
	awareness_radius += stage * 20.0
	magic_affinity += stage * 0.3
	
	if stage >= 3:
		is_magical = true
		magic_level = 0.8 if stage == 3 else 1.0

func update_visual_for_stage(stage: int) -> void:
	"""Met à jour l'apparence selon l'évolution"""
	if not sprite:
		return
	
	match stage:
		0: sprite.modulate = Color.WHITE
		1: sprite.modulate = Color.WHITE.lerp(Color.YELLOW, 0.3)
		2: sprite.modulate = Color.WHITE.lerp(Color.CYAN, 0.5)
		3: sprite.modulate = Color.WHITE.lerp(Color.MAGENTA, 0.7)
		4: sprite.modulate = Color.GOLD
	
	var scale_factor = 1.0 + stage * 0.2
	sprite.scale = Vector2.ONE * scale_factor

# ============================================================================
# COMPORTEMENTS
# ============================================================================

func start_roaming() -> void:
	"""Commence l'exploration"""
	change_behavior(CreatureBehavior.ROAMING)
	choose_new_roaming_target()

func choose_new_roaming_target() -> void:
	"""Choisit un nouveau point d'exploration"""
	var angle = randf() * 2 * PI
	var distance = randf() * roaming_distance
	target_position = home_position + Vector2(cos(angle), sin(angle)) * distance

func look_at_observer() -> void:
	"""S'oriente vers l'observateur"""
	if current_observer and sprite:
		var direction = (current_observer.global_position - global_position).normalized()
		sprite.flip_h = direction.x < 0

func change_behavior(new_behavior: CreatureBehavior) -> void:
	"""Change le comportement de la créature"""
	if new_behavior == current_behavior:
		return
	
	var previous_behavior = current_behavior
	current_behavior = new_behavior
	behavior_timer = 0.0
	
	behavior_changed.emit(self, 
		CreatureBehavior.keys()[previous_behavior],
		CreatureBehavior.keys()[current_behavior]
	)

func trigger_magic_event() -> void:
	"""Déclenche un événement magique"""
	if not is_magical:
		return
	
	var events = ["sparkle", "glow", "teleport"]
	var event = events[randi() % events.size()]
	
	if debug_mode:
		print("✨ ", display_name, "événement magique:", event)

# ============================================================================
# INTERFACE PUBLIQUE
# ============================================================================

func observe(observer: Node, intensity: float = 1.0) -> void:
	"""Interface publique pour observation"""
	observation_count += 1
	start_observation(observer, intensity)
	
	# Vérifier évolution
	var thresholds = evolution_data.get("observation_thresholds", [0, 3, 7, 12, 20])
	var next_threshold = thresholds[min(current_evolution_stage + 1, thresholds.size() - 1)]
	
	if observation_count >= next_threshold:
		trigger_evolution()

func interact(player: Node) -> String:
	"""Interface publique pour interaction"""
	match current_evolution_stage:
		0: return display_name + " vous regarde curieusement."
		1: return display_name + " semble vous reconnaître."
		2: return display_name + " s'approche amicalement."
		3: return display_name + " brille d'une lueur magique."
		4: return display_name + " vous communique télépathiquement."
		_: return "Interaction mystérieuse..."

func get_interaction_type() -> String:
	"""Retourne le type d'interaction"""
	return "observe"
'''
        
        # NPC.gd corrigé (version plus courte)
        npc_content = '''# ============================================================================
# 👥 NPC.gd - Personnages Non-Joueurs (CORRIGÉ)
# ============================================================================

class_name NPC
extends CharacterBody2D

## Classe de base pour tous les personnages non-joueurs

# ============================================================================
# SIGNAUX
# ============================================================================

signal npc_interacted(npc: NPC, player: Node, interaction_type: String)
signal dialogue_requested(npc: NPC, player: Node, dialogue_id: String)
signal npc_state_changed(npc: NPC, old_state: String, new_state: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export_group("Identity")
@export var npc_id: String = "unknown_npc"
@export var display_name: String = "Personnage Mystérieux"
@export var profession: String = "citoyen"
@export var faction: String = "neutral"

@export_group("Behavior")
@export var is_stationary: bool = false
@export var patrol_points: Array[Vector2] = []
@export var interaction_radius: float = 50.0
@export var movement_speed: float = 30.0

@export_group("Content")
@export var can_give_quests: bool = false
@export var can_trade: bool = false

@export_group("Debug")
@export var debug_mode: bool = false

# ============================================================================
# COMPOSANTS
# ============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var animator: AnimationPlayer = $AnimationPlayer
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea

# ============================================================================
# VARIABLES D'ÉTAT
# ============================================================================

enum NPCState {
	IDLE,
	PATROLLING,
	TALKING,
	WORKING
}

enum NPCMood {
	HAPPY,
	NEUTRAL,
	SAD,
	ANGRY,
	FRIENDLY
}

var current_state: NPCState = NPCState.IDLE
var current_mood: NPCMood = NPCMood.NEUTRAL

var npc_data: Dictionary = {}
var relationship_level: float = 0.0
var current_interactor: Node = null
var is_in_conversation: bool = false

var current_patrol_index: int = 0
var target_position: Vector2
var home_position: Vector2
var is_moving: bool = false

# Références aux managers (CORRIGÉ: noms AutoLoad)
var dialogue_manager: DialogueManager
var data_manager: DataManager

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	"""Initialisation du NPC"""
	if debug_mode:
		print("👥 NPC:", npc_id, "initialisation...")
	
	await get_tree().process_frame
	connect_to_managers()
	setup_npc_data()
	setup_interaction_areas()
	
	home_position = global_position
	target_position = home_position
	
	if debug_mode:
		print("👥 NPC:", display_name, "prêt! Faction:", faction)

func connect_to_managers() -> void:
	"""Connexion aux managers (CORRIGÉ: noms AutoLoad)"""
	dialogue_manager = get_node_or_null("/root/Dialogue")
	data_manager = get_node_or_null("/root/Data")
	
	if debug_mode:
		print("👥 NPC: Connexions managers établies")

func setup_npc_data() -> void:
	"""Configure les données du NPC"""
	npc_data = {
		"name": display_name,
		"profession": profession,
		"faction": faction,
		"base_relationship": 0,
		"dialogue_tree": "generic_greeting"
	}

func setup_interaction_areas() -> void:
	"""Configure les zones d'interaction"""
	if interaction_area:
		var shape = CircleShape2D.new()
		shape.radius = interaction_radius
		var collision = interaction_area.get_node("CollisionShape2D")
		if collision:
			collision.shape = shape
		
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)

# ============================================================================
# BOUCLE PRINCIPALE
# ============================================================================

func _physics_process(delta: float) -> void:
	"""Boucle principale de physique"""
	process_current_state(delta)
	process_movement(delta)

func process_current_state(delta: float) -> void:
	"""Traite l'état actuel du NPC"""
	match current_state:
		NPCState.IDLE:
			if not is_stationary and patrol_points.size() > 0:
				if randf() < 0.1:  # 10% chance de commencer patrouille
					change_state(NPCState.PATROLLING)
		NPCState.PATROLLING:
			if global_position.distance_to(target_position) < 10.0:
				advance_patrol_point()
		NPCState.TALKING:
			if current_interactor:
				look_at_interactor()

func process_movement(delta: float) -> void:
	"""Traite le mouvement physique"""
	if current_state == NPCState.TALKING:
		velocity = Vector2.ZERO
	else:
		calculate_movement_velocity()
	
	move_and_slide()

func calculate_movement_velocity() -> void:
	"""Calcule la vélocité de mouvement"""
	var direction = Vector2.ZERO
	
	if current_state == NPCState.PATROLLING:
		direction = (target_position - global_position).normalized()
	
	velocity = velocity.move_toward(direction * movement_speed, 200.0 * get_physics_process_delta_time())
	is_moving = velocity.length() > 5.0

func advance_patrol_point() -> void:
	"""Avance au prochain point de patrouille"""
	if patrol_points.size() > 1:
		current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
		target_position = patrol_points[current_patrol_index]

# ============================================================================
# SYSTÈME D'INTERACTION
# ============================================================================

func start_interaction(player: Node) -> void:
	"""Démarre une interaction avec le joueur"""
	if is_in_conversation:
		return
	
	current_interactor = player
	is_in_conversation = true
	change_state(NPCState.TALKING)
	npc_interacted.emit(self, player, "talk")
	
	start_dialogue(player)

func start_dialogue(player: Node) -> void:
	"""Démarre un dialogue avec le joueur"""
	if dialogue_manager:
		var dialogue_id = "generic_greeting"
		dialogue_requested.emit(self, player, dialogue_id)
		dialogue_manager.start_dialogue(npc_id, dialogue_id)
	else:
		show_simple_message(get_greeting_message())
		end_interaction()

func end_interaction() -> void:
	"""Termine l'interaction actuelle"""
	if current_interactor:
		current_interactor = null
	
	is_in_conversation = false
	change_state(NPCState.IDLE)

func get_greeting_message() -> String:
	"""Retourne un message d'accueil approprié"""
	var greetings = [
		"Bonjour ! Comment allez-vous ?",
		"Salutations, voyageur !",
		"Bien le bonjour !"
	]
	
	match current_mood:
		NPCMood.HAPPY:
			greetings = ["Quelle magnifique journée !", "Je suis ravi de vous voir !"]
		NPCMood.ANGRY:
			greetings = ["Qu'est-ce que vous voulez ?", "*grogne*"]
	
	return greetings[randi() % greetings.size()]

func show_simple_message(message: String) -> void:
	"""Affiche un message simple"""
	print("💬 ", display_name, ":", message)

# ============================================================================
# ÉTATS ET HUMEURS
# ============================================================================

func change_state(new_state: NPCState) -> void:
	"""Change l'état du NPC"""
	if new_state == current_state:
		return
	
	var previous_state = current_state
	current_state = new_state
	
	npc_state_changed.emit(self, NPCState.keys()[previous_state], NPCState.keys()[current_state])
	
	if debug_mode:
		print("👥 ", display_name, "état:", NPCState.keys()[current_state])

func look_at_interactor() -> void:
	"""S'oriente vers l'interlocuteur"""
	if current_interactor and sprite:
		var direction = (current_interactor.global_position - global_position).normalized()
		sprite.flip_h = direction.x < 0

# ============================================================================
# CALLBACKS
# ============================================================================

func _on_interaction_area_entered(body: Node) -> void:
	"""Joueur entré dans la zone d'interaction"""
	if body.is_in_group("player"):
		if debug_mode:
			print("👥 Joueur détecté:", body.name)

func _on_interaction_area_exited(body: Node) -> void:
	"""Joueur sorti de la zone d'interaction"""
	if body.is_in_group("player"):
		if is_in_conversation and body == current_interactor:
			end_interaction()

# ============================================================================
# INTERFACE PUBLIQUE
# ============================================================================

func interact(player: Node) -> String:
	"""Interface publique pour interaction"""
	start_interaction(player)
	return "Interaction démarrée avec " + display_name

func get_interaction_type() -> String:
	"""Retourne le type d'interaction principal"""
	if can_give_quests:
		return "quest"
	elif can_trade:
		return "trade"
	else:
		return "dialogue"

func get_npc_data() -> Dictionary:
	"""Retourne les données du NPC pour sauvegarde"""
	return {
		"npc_id": npc_id,
		"position": global_position,
		"current_state": NPCState.keys()[current_state],
		"relationship_level": relationship_level
	}
'''
        
        self.write_file("scripts/core/Player.gd", player_content)
        self.write_file("scripts/core/Creature.gd", creature_content)
        self.write_file("scripts/core/NPC.gd", npc_content)
    
    def create_test_scene(self):
        """Crée une scène de test simple fonctionnelle."""
        
        test_scene_content = '''[gd_scene load_steps=5 format=3 uid="uid://test_scene_sb"]

[ext_resource type="Script" path="res://scripts/core/Player.gd" id="1_player"]
[ext_resource type="Script" path="res://scripts/core/Creature.gd" id="2_creature"]
[ext_resource type="Script" path="res://scripts/core/NPC.gd" id="3_npc"]

[sub_resource type="RectangleShape2D" id="player_shape"]
size = Vector2(32, 48)

[node name="TestScene" type="Node2D"]

[node name="Background" type="ColorRect" parent="."]
offset_right = 1000.0
offset_bottom = 700.0
color = Color(0.1, 0.2, 0.1, 1)

[node name="Player" type="CharacterBody2D" parent="." groups=["player"]]
position = Vector2(200, 350)
script = ExtResource("1_player")
debug_mode = true
show_interaction_range = true

[node name="Sprite2D" type="Sprite2D" parent="Player"]
modulate = Color(0.3, 0.6, 1, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="Player"]
shape = SubResource("player_shape")

[node name="InteractionArea" type="Area2D" parent="Player"]

[node name="CollisionShape2D" type="CollisionShape2D" parent="Player/InteractionArea"]

[node name="ObservationArea" type="Area2D" parent="Player"]

[node name="CollisionShape2D" type="CollisionShape2D" parent="Player/ObservationArea"]

[node name="InteractionDetector" type="RayCast2D" parent="Player"]

[node name="ObservationCamera" type="Camera2D" parent="Player"]
enabled = true

[node name="Audio" type="Node2D" parent="Player"]

[node name="Footsteps" type="AudioStreamPlayer2D" parent="Player/Audio"]

[node name="Interaction" type="AudioStreamPlayer2D" parent="Player/Audio"]

[node name="Effects" type="Node2D" parent="Player"]

[node name="MovementParticles" type="GPUParticles2D" parent="Player/Effects"]

[node name="AnimationPlayer" type="AnimationPlayer" parent="Player"]

[node name="TestCreature" type="CharacterBody2D" parent="." groups=["creatures"]]
position = Vector2(500, 250)
script = ExtResource("2_creature")
creature_id = "maurice_rat"
display_name = "Maurice le Rat"
debug_mode = true

[node name="Sprite2D" type="Sprite2D" parent="TestCreature"]
modulate = Color(0.8, 0.6, 0.4, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="TestCreature"]
shape = SubResource("player_shape")

[node name="AnimationPlayer" type="AnimationPlayer" parent="TestCreature"]

[node name="TestNPC" type="CharacterBody2D" parent="." groups=["npcs"]]
position = Vector2(800, 350)
script = ExtResource("3_npc")
npc_id = "madame_simnel"
display_name = "Madame Simnel"
debug_mode = true

[node name="Sprite2D" type="Sprite2D" parent="TestNPC"]
modulate = Color(1, 0.8, 0.6, 1)

[node name="CollisionShape2D" type="CollisionShape2D" parent="TestNPC"]
shape = SubResource("player_shape")

[node name="InteractionArea" type="Area2D" parent="TestNPC"]

[node name="CollisionShape2D" type="CollisionShape2D" parent="TestNPC/InteractionArea"]

[node name="AnimationPlayer" type="AnimationPlayer" parent="TestNPC"]

[node name="UI" type="CanvasLayer" parent="."]

[node name="Controls" type="Label" parent="UI"]
offset_right = 350.0
offset_bottom = 150.0
text = "🎮 CONTROLS:
WASD/Flèches - Bouger
Shift - Courir
E - Interagir
Souris maintenue - Observer
Échap - Quitter"
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 14

[node name="Info" type="Label" parent="UI"]
anchors_preset = 1
anchor_left = 1.0
anchor_right = 1.0
offset_left = -300.0
offset_bottom = 100.0
text = "🔧 TEST SCENE v1.0
🔵 Joueur (bleu)
🟤 Maurice le Rat
🟡 Madame Simnel

Tous les systèmes connectés!"
theme_override_colors/font_color = Color(1, 1, 1, 1)
theme_override_font_sizes/font_size = 12
'''
        
        self.write_file("scenes/test/TestScene.tscn", test_scene_content)
    
    def create_input_map(self):
        """Crée un input map par défaut."""
        
        input_map_content = '''; Project Input Map - Sortilèges & Bestioles
; Ajouter ces actions dans Project Settings > Input Map

[input]

move_left={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":65,"key_label":0,"unicode":97,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194319,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_right={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":68,"key_label":0,"unicode":100,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194321,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_up={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":87,"key_label":0,"unicode":119,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194320,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
move_down={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":83,"key_label":0,"unicode":115,"echo":false,"script":null)
, Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194322,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
interact={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":69,"key_label":0,"unicode":101,"echo":false,"script":null)
]
}
observe={
"deadzone": 0.5,
"events": [Object(InputEventMouseButton,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"button_mask":0,"position":Vector2(0, 0),"global_position":Vector2(0, 0),"factor":1.0,"button_index":1,"canceled":false,"pressed":false,"double_click":false,"script":null)
]
}
run={
"deadzone": 0.5,
"events": [Object(InputEventKey,"resource_local_to_scene":false,"resource_name":"","device":-1,"window_id":0,"alt_pressed":false,"shift_pressed":false,"ctrl_pressed":false,"meta_pressed":false,"pressed":false,"keycode":0,"physical_keycode":4194325,"key_label":0,"unicode":0,"echo":false,"script":null)
]
}
'''
        
        self.write_file("input_map_reference.txt", input_map_content)
    
    def fix_existing_gamemanager(self):
        """Corrige le GameManager existant s'il existe."""
        gamemanager_path = self.scripts_path / "managers" / "GameManager.gd"
        
        if gamemanager_path.exists():
            with open(gamemanager_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            # Corrections dans initialize_managers()
            old_ui_line = 'ui_manager = await create_or_get_manager("UIManager", "res://scripts/managers/UIManager.gd")'
            new_ui_line = 'ui_manager = get_node_or_null("/root/UI")  # Stub temporaire'
            
            old_audio_line = 'audio_manager = await create_or_get_manager("AudioManager", "res://scripts/managers/AudioManager.gd")'
            new_audio_line = 'audio_manager = get_node_or_null("/root/Audio")  # Stub temporaire'
            
            if old_ui_line in content:
                content = content.replace(old_ui_line, new_ui_line)
                self.fixes_applied.append("🔧 GameManager: Référence UIManager corrigée")
            
            if old_audio_line in content:
                content = content.replace(old_audio_line, new_audio_line)
                self.fixes_applied.append("🔧 GameManager: Référence AudioManager corrigée")
            
            # Commentaire optionnel pour save_system et reputation_manager
            save_line = 'save_system = await create_or_get_manager("SaveSystem"'
            reputation_line = 'reputation_manager = await create_or_get_manager("ReputationManager"'
            
            if save_line in content:
                content = content.replace(save_line, '# ' + save_line)
                self.fixes_applied.append("🔧 GameManager: SaveSystem commenté temporairement")
            
            if reputation_line in content:
                content = content.replace(reputation_line, '# ' + reputation_line)
                self.fixes_applied.append("🔧 GameManager: ReputationManager commenté temporairement")
            
            with open(gamemanager_path, 'w', encoding='utf-8') as f:
                f.write(content)
    
    def generate_autoload_instructions(self):
        """Génère les instructions pour configurer les AutoLoads."""
        
        autoload_instructions = '''# 🔧 CONFIGURATION AUTOLOADS - Instructions
# ========================================

Dans Godot, aller dans: Project Settings > AutoLoad

SUPPRIMER tous les AutoLoads existants qui causent des erreurs.

AJOUTER ces AutoLoads dans l'ordre:

1. Name: Game
   Path: res://scripts/managers/GameManager.gd
   ✅ Enable

2. Name: Data  
   Path: res://scripts/managers/DataManager.gd
   ✅ Enable

3. Name: Observation
   Path: res://scripts/managers/ObservationManager.gd
   ✅ Enable

4. Name: Dialogue
   Path: res://scripts/managers/DialogueManager.gd
   ✅ Enable

5. Name: Quest
   Path: res://scripts/managers/QuestManager.gd
   ✅ Enable

6. Name: UI
   Path: res://scripts/stubs/UIManager.gd
   ✅ Enable

7. Name: Audio
   Path: res://scripts/stubs/AudioManager.gd
   ✅ Enable

ATTENTION: 
- Utilisez exactement ces noms (Game, Data, etc.)
- PAS les noms complets (GameManager, DataManager, etc.)
- Cela évite les conflits avec les class_name

Après configuration, faire: Project > Reload Current Project

Puis tester: Run TestScene.tscn
'''
        
        self.write_file("AUTOLOAD_INSTRUCTIONS.txt", autoload_instructions)
    
    def write_file(self, relative_path: str, content: str):
        """Écrit un fichier avec gestion d'erreurs."""
        try:
            file_path = self.project_root / relative_path
            file_path.parent.mkdir(parents=True, exist_ok=True)
            
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            
            self.files_created.append(f"📄 {relative_path}")
            
        except Exception as e:
            self.errors.append(f"Erreur écriture {relative_path}: {str(e)}")
    
    def print_summary(self):
        """Affiche le résumé des corrections appliquées."""
        print("\n" + "="*60)
        print("🎉 CORRECTIONS TERMINÉES")
        print("="*60)
        
        if self.fixes_applied:
            print("\n✅ CORRECTIONS APPLIQUÉES:")
            for fix in self.fixes_applied:
                print(f"  {fix}")
        
        if self.files_created:
            print(f"\n📄 FICHIERS CRÉÉS ({len(self.files_created)}):")
            for file in self.files_created:
                print(f"  {file}")
        
        if self.errors:
            print(f"\n❌ ERREURS ({len(self.errors)}):")
            for error in self.errors:
                print(f"  {error}")
        
        print("\n🎯 PROCHAINES ÉTAPES:")
        print("  1. 🔧 Configurer AutoLoads (voir AUTOLOAD_INSTRUCTIONS.txt)")
        print("  2. ⚙️ Ajouter Input Map (voir input_map_reference.txt)")
        print("  3. 🎮 Run TestScene.tscn")
        print("  4. 🎉 Gameplay fonctionnel!")
        
        print(f"\n📊 RÉSULTAT:")
        if len(self.errors) == 0:
            print("  ✅ TOUTES LES CORRECTIONS APPLIQUÉES AVEC SUCCÈS!")
        else:
            print(f"  ⚠️ {len(self.errors)} erreur(s) détectée(s)")
        
        print("\n🚀 Projet prêt pour les tests!")

def main():
    """Fonction principale du script."""
    print("Démarrage du correcteur de projet Godot...")
    
    # Détecter le dossier racine du projet
    project_root = "."
    if not Path("project.godot").exists():
        print("⚠️ Fichier project.godot non trouvé dans le dossier actuel.")
        print("Assurez-vous d'exécuter le script depuis la racine du projet Godot.")
        project_root = input("Chemin vers le projet Godot (ou Enter pour dossier actuel): ").strip()
        if not project_root:
            project_root = "."
    
    # Créer et exécuter le correcteur
    fixer = GodotProjectFixer(project_root)
    fixer.run_all_fixes()

if __name__ == "__main__":
    main()