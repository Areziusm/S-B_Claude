#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
🔧 Godot Project Fixer - "Sortilèges & Bestioles" - VERSION CORRIGÉE
====================================================================
Script Python pour corriger automatiquement tous les problèmes du projet Godot.

Usage: python godot_project_fixer_fixed.py
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
            self.create_input_instructions()
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
            "data"
        ]
        
        for dir_path in directories:
            full_path = self.project_root / dir_path
            full_path.mkdir(parents=True, exist_ok=True)
            self.fixes_applied.append(f"📁 Dossier créé: {dir_path}")
    
    def create_stub_managers(self):
        """Crée les managers stub temporaires."""
        
        # UIManager Stub
        ui_content = self.get_ui_manager_stub()
        self.write_file("scripts/stubs/UIManager.gd", ui_content)
        
        # AudioManager Stub  
        audio_content = self.get_audio_manager_stub()
        self.write_file("scripts/stubs/AudioManager.gd", audio_content)
    
    def get_ui_manager_stub(self):
        """Retourne le contenu du UIManager stub."""
        return """# ============================================================================
# 📱 UIManager.gd - Gestionnaire Interface Utilisateur (STUB TEMPORAIRE)
# ============================================================================

class_name UIManager
extends CanvasLayer

signal ui_element_shown(element_name: String)
signal ui_element_hidden(element_name: String)
signal manager_initialized()

var is_initialized: bool = false

func _ready() -> void:
	print("📱 UIManager: Stub temporaire initialisé")
	is_initialized = true
	manager_initialized.emit()

func toggle_pause_menu() -> void:
	print("📱 UIManager: Menu pause toggled (stub)")

func show_panel(panel_name: String) -> void:
	print("📱 UIManager: Affichage panneau ", panel_name, " (stub)")
	ui_element_shown.emit(panel_name)

func hide_panel(panel_name: String) -> void:
	print("📱 UIManager: Masquage panneau ", panel_name, " (stub)")
	ui_element_hidden.emit(panel_name)

func show_notification(message: String, type: String = "info") -> void:
	print("📱 Notification [", type, "]: ", message)

func start_transition(transition_type) -> void:
	print("📱 UIManager: Transition démarrée (stub)")
	await get_tree().create_timer(0.3).timeout

func complete_transition() -> void:
	print("📱 UIManager: Transition terminée (stub)")
"""

    def get_audio_manager_stub(self):
        """Retourne le contenu du AudioManager stub."""
        return """# ============================================================================
# 🔊 AudioManager.gd - Gestionnaire Audio (STUB TEMPORAIRE)
# ============================================================================

class_name AudioManager
extends Node

signal audio_started(audio_type: String, track_name: String)
signal audio_stopped(audio_type: String)
signal manager_initialized()

var is_initialized: bool = false
var master_volume: float = 1.0
var music_volume: float = 0.8

func _ready() -> void:
	print("🔊 AudioManager: Stub temporaire initialisé")
	is_initialized = true
	manager_initialized.emit()

func play_music(track_name: String, fade_time: float = 1.0) -> void:
	print("🔊 AudioManager: Musique ", track_name, " (stub)")
	audio_started.emit("music", track_name)

func play_sfx(sfx_name: String, position: Vector2 = Vector2.ZERO) -> void:
	print("🔊 AudioManager: SFX ", sfx_name, " (stub)")
	audio_started.emit("sfx", sfx_name)

func update_volume_settings(settings: Dictionary) -> void:
	print("🔊 AudioManager: Volumes mis à jour (stub)")
"""
    
    def create_core_scripts(self):
        """Crée les scripts core corrigés."""
        
        # Player.gd corrigé
        player_content = self.get_player_script()
        self.write_file("scripts/core/Player.gd", player_content)
        
        # Creature.gd corrigé
        creature_content = self.get_creature_script() 
        self.write_file("scripts/core/Creature.gd", creature_content)
        
        # NPC.gd corrigé
        npc_content = self.get_npc_script()
        self.write_file("scripts/core/NPC.gd", npc_content)
    
    def get_player_script(self):
        """Retourne le script Player.gd corrigé."""
        return """# ============================================================================
# 🎮 Player.gd - Contrôleur Joueur Principal (CORRIGÉ)
# ============================================================================

class_name Player
extends CharacterBody2D

# ============================================================================
# SIGNAUX
# ============================================================================

signal movement_started()
signal movement_stopped()
signal interaction_started(target: Node, interaction_type: String)
signal observation_started(target: Node)
signal observation_ended(target: Node, duration: float)
signal player_state_changed(old_state: String, new_state: String)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export_group("Movement")
@export var base_speed: float = 200.0
@export var run_speed_multiplier: float = 1.8

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
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var observation_area: Area2D = $ObservationArea

# ============================================================================
# VARIABLES D'ÉTAT
# ============================================================================

enum PlayerState {
	IDLE,
	MOVING,
	INTERACTING,
	OBSERVING,
	IN_DIALOGUE,
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

# Références aux managers (CORRIGÉ: noms AutoLoad)
var game_manager: GameManager
var observation_manager: ObservationManager
var dialogue_manager: DialogueManager
var ui_manager: UIManager
var audio_manager: AudioManager

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	if debug_mode:
		print("🎮 Player: Initialisation...")
	
	await get_tree().process_frame
	connect_to_managers()
	setup_initial_state()
	setup_interaction_areas()
	
	if debug_mode:
		print("🎮 Player: Prêt! Position:", global_position)

func connect_to_managers() -> void:
	game_manager = get_node_or_null("/root/Game")
	observation_manager = get_node_or_null("/root/Observation")
	dialogue_manager = get_node_or_null("/root/Dialogue")
	ui_manager = get_node_or_null("/root/UI")
	audio_manager = get_node_or_null("/root/Audio")
	
	if dialogue_manager:
		if dialogue_manager.has_signal("dialogue_started"):
			dialogue_manager.dialogue_started.connect(_on_dialogue_started)
		if dialogue_manager.has_signal("dialogue_ended"):
			dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
	
	if debug_mode:
		print("🎮 Player: Connexions managers établies")

func setup_initial_state() -> void:
	current_state = PlayerState.IDLE
	set_physics_process(true)
	set_process_input(true)
	collision_layer = 1
	collision_mask = 2

func setup_interaction_areas() -> void:
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
	if can_move():
		handle_movement_input()
		process_movement(delta)
	else:
		stop_movement()
	
	update_observation(delta)

func _input(event: InputEvent) -> void:
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
	var target_speed = base_speed
	if is_running:
		target_speed *= run_speed_multiplier
	
	if input_vector != Vector2.ZERO:
		velocity = velocity.move_toward(input_vector * target_speed, 1000.0 * delta)
		if not is_moving:
			start_movement()
	else:
		velocity = velocity.move_toward(Vector2.ZERO, 1000.0 * delta)
		if velocity.length() < 5 and is_moving:
			stop_movement()
	
	move_and_slide()

func start_movement() -> void:
	is_moving = true
	change_state(PlayerState.MOVING)
	movement_started.emit()

func stop_movement() -> void:
	if is_moving:
		is_moving = false
		if current_state == PlayerState.MOVING:
			change_state(PlayerState.IDLE)
		movement_stopped.emit()

func can_move() -> bool:
	return current_state in [PlayerState.IDLE, PlayerState.MOVING, PlayerState.OBSERVING]

# ============================================================================
# SYSTÈME D'INTERACTION
# ============================================================================

func attempt_interaction() -> void:
	if current_state == PlayerState.IN_DIALOGUE:
		if dialogue_manager and dialogue_manager.has_method("advance_dialogue"):
			dialogue_manager.advance_dialogue()
		return
	
	var target = find_best_interaction_target()
	if target:
		start_interaction(target)

func find_best_interaction_target() -> Node:
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
	if not target:
		return
	
	current_interaction_target = target
	change_state(PlayerState.INTERACTING)
	interaction_started.emit(target, get_interaction_type(target))
	
	process_interaction(target)

func process_interaction(target: Node) -> void:
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
	if dialogue_manager:
		var npc_id = npc.npc_id if "npc_id" in npc else npc.name.to_lower()
		if dialogue_manager.has_method("start_dialogue"):
			dialogue_manager.start_dialogue(npc_id, "default")
	else:
		print("⚠️ DialogueManager non disponible")
		end_interaction()

func end_interaction() -> void:
	current_interaction_target = null
	if current_state == PlayerState.INTERACTING:
		change_state(PlayerState.IDLE)

# ============================================================================
# SYSTÈME D'OBSERVATION
# ============================================================================

func start_observation() -> void:
	if current_state in [PlayerState.IN_DIALOGUE]:
		return
	
	var target = find_best_observation_target()
	if target:
		start_observation_of_creature(target)
	else:
		change_state(PlayerState.OBSERVING)
		observation_started.emit(null)

func start_observation_of_creature(creature: Node) -> void:
	current_observation_target = creature
	is_observing = true
	observation_timer = 0.0
	
	change_state(PlayerState.OBSERVING)
	observation_started.emit(creature)

func stop_observation() -> void:
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
	if observation_manager:
		var creature_id = creature.creature_id if "creature_id" in creature else creature.name.to_lower()
		var intensity = min(duration / observation_min_time, 3.0)
		if observation_manager.has_method("observe_creature"):
			observation_manager.observe_creature(creature_id, intensity)
	
	if debug_mode:
		print("🔮 Observation:", creature.name, "durée:", duration, "s")

func find_best_observation_target() -> Node:
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
	if is_observing:
		observation_timer += delta

# ============================================================================
# GESTION DES ÉTATS
# ============================================================================

func change_state(new_state: PlayerState) -> void:
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
	if body == self:
		return
	
	if body.has_method("get_interaction_type") or body.is_in_group("interactables") or body.is_in_group("npcs"):
		interactable_objects.append(body)
		if debug_mode:
			print("🎮 Interaction disponible:", body.name)

func _on_interaction_area_exited(body: Node) -> void:
	if body in interactable_objects:
		interactable_objects.erase(body)
		if body == current_interaction_target:
			end_interaction()

func _on_observation_area_entered(body: Node) -> void:
	if body == self:
		return
	
	if body.has_method("observe") or body.is_in_group("creatures"):
		observable_creatures.append(body)
		if debug_mode:
			print("🔮 Créature observable:", body.name)

func _on_observation_area_exited(body: Node) -> void:
	if body in observable_creatures:
		observable_creatures.erase(body)
		if body == current_observation_target:
			stop_observation()

func _on_dialogue_started(npc_id: String, dialogue_id: String) -> void:
	change_state(PlayerState.IN_DIALOGUE)

func _on_dialogue_ended(npc_id: String, final_choice: String, relationship_change: float) -> void:
	end_interaction()

# ============================================================================
# UTILITAIRES
# ============================================================================

func get_interaction_type(target: Node) -> String:
	if target.has_method("get_interaction_type"):
		return target.get_interaction_type()
	elif target.is_in_group("npcs"):
		return "dialogue"
	elif target.is_in_group("creatures"):
		return "observation"
	else:
		return "generic"

# ============================================================================
# DEBUG
# ============================================================================

func _draw() -> void:
	if not debug_mode or not show_interaction_range:
		return
	
	draw_circle(Vector2.ZERO, interaction_range, Color.BLUE, false, 2)
	draw_circle(Vector2.ZERO, observation_range, Color.GREEN, false, 2)
"""
    
    def get_creature_script(self):
        """Retourne le script Creature.gd corrigé."""
        return """# ============================================================================
# 🐾 Creature.gd - Base pour Système d'Évolution (CORRIGÉ)
# ============================================================================

class_name Creature
extends CharacterBody2D

# ============================================================================
# CONFIGURATION
# ============================================================================

@export_group("Identity")
@export var creature_id: String = "unknown_creature"
@export var display_name: String = "Créature Mystérieuse"

@export_group("Evolution")
@export var current_evolution_stage: int = 0
@export var observation_count: int = 0
@export var magic_affinity: float = 1.0

@export_group("Behavior")
@export var base_speed: float = 50.0

@export_group("Debug")
@export var debug_mode: bool = false

# ============================================================================
# COMPOSANTS
# ============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# ============================================================================
# VARIABLES
# ============================================================================

enum CreatureBehavior {
	IDLE,
	ROAMING,
	CURIOUS,
	EVOLVING
}

var current_behavior: CreatureBehavior = CreatureBehavior.IDLE
var home_position: Vector2
var target_position: Vector2
var observers: Array[Node] = []
var current_observer: Node = null
var is_evolving: bool = false
var evolution_timer: float = 0.0
var behavior_timer: float = 0.0
var is_magical: bool = false
var magic_timer: float = 0.0

# Références managers (CORRIGÉ)
var observation_manager: ObservationManager

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	if debug_mode:
		print("🐾 Creature:", creature_id, "initialisation...")
	
	await get_tree().process_frame
	connect_to_managers()
	
	home_position = global_position
	target_position = home_position
	
	if debug_mode:
		print("🐾 Creature:", display_name, "prête! Stade:", current_evolution_stage)

func connect_to_managers() -> void:
	observation_manager = get_node_or_null("/root/Observation")
	if debug_mode:
		print("🐾 Creature: Connexions managers établies")

# ============================================================================
# BOUCLE PRINCIPALE
# ============================================================================

func _physics_process(delta: float) -> void:
	behavior_timer += delta
	magic_timer += delta
	
	if is_evolving:
		evolution_timer += delta
	
	process_behavior(delta)
	process_movement(delta)
	
	if is_magical:
		process_magic_effects(delta)

func process_behavior(delta: float) -> void:
	match current_behavior:
		CreatureBehavior.IDLE:
			if behavior_timer > 3.0 and randf() < 0.3:
				start_roaming()
		CreatureBehavior.CURIOUS:
			if current_observer:
				look_at_observer()
			else:
				change_behavior(CreatureBehavior.IDLE)
		CreatureBehavior.EVOLVING:
			if evolution_timer > 2.0:
				complete_evolution()

func process_movement(delta: float) -> void:
	if is_evolving:
		velocity = Vector2.ZERO
	else:
		var direction = Vector2.ZERO
		if current_behavior == CreatureBehavior.ROAMING:
			direction = (target_position - global_position).normalized()
		
		velocity = velocity.move_toward(direction * base_speed, 300.0 * delta)
	
	move_and_slide()

func process_magic_effects(delta: float) -> void:
	if not is_magical:
		return
	
	if magic_timer > 3.0:
		trigger_magic_event()
		magic_timer = 0.0

# ============================================================================
# COMPORTEMENTS
# ============================================================================

func start_roaming() -> void:
	change_behavior(CreatureBehavior.ROAMING)
	choose_new_target()

func choose_new_target() -> void:
	var angle = randf() * 2 * PI
	var distance = randf() * 150.0
	target_position = home_position + Vector2(cos(angle), sin(angle)) * distance

func look_at_observer() -> void:
	if current_observer and sprite:
		var direction = (current_observer.global_position - global_position).normalized()
		sprite.flip_h = direction.x < 0

func change_behavior(new_behavior: CreatureBehavior) -> void:
	if new_behavior == current_behavior:
		return
	
	current_behavior = new_behavior
	behavior_timer = 0.0
	
	if debug_mode:
		print("🐾 ", display_name, "comportement:", CreatureBehavior.keys()[current_behavior])

# ============================================================================
# SYSTÈME D'ÉVOLUTION
# ============================================================================

func trigger_evolution() -> void:
	if is_evolving or current_evolution_stage >= 4:
		return
	
	var old_stage = current_evolution_stage
	current_evolution_stage += 1
	
	is_evolving = true
	evolution_timer = 0.0
	change_behavior(CreatureBehavior.EVOLVING)
	
	if debug_mode:
		print("🎉 ", display_name, "évolue! Stade", old_stage, "→", current_evolution_stage)

func complete_evolution() -> void:
	is_evolving = false
	evolution_timer = 0.0
	
	update_visual_for_stage(current_evolution_stage)
	
	if current_evolution_stage >= 3:
		is_magical = true
	
	change_behavior(CreatureBehavior.IDLE)
	
	if debug_mode:
		print("✨ ", display_name, "évolution terminée!")

func update_visual_for_stage(stage: int) -> void:
	if not sprite:
		return
	
	match stage:
		0: sprite.modulate = Color.WHITE
		1: sprite.modulate = Color.WHITE.lerp(Color.YELLOW, 0.3)
		2: sprite.modulate = Color.WHITE.lerp(Color.CYAN, 0.5)
		3: sprite.modulate = Color.WHITE.lerp(Color.MAGENTA, 0.7)
		4: sprite.modulate = Color.GOLD

func trigger_magic_event() -> void:
	if debug_mode:
		print("✨ ", display_name, "événement magique!")

# ============================================================================
# INTERFACE PUBLIQUE
# ============================================================================

func observe(observer: Node, intensity: float = 1.0) -> void:
	observation_count += 1
	start_observation(observer, intensity)
	
	# Vérifier évolution
	var thresholds = [0, 3, 7, 12, 20]
	var next_threshold = thresholds[min(current_evolution_stage + 1, thresholds.size() - 1)]
	
	if observation_count >= next_threshold:
		trigger_evolution()

func start_observation(observer: Node, intensity: float) -> void:
	if observer in observers:
		return
	
	observers.append(observer)
	current_observer = observer
	
	change_behavior(CreatureBehavior.CURIOUS)
	
	if debug_mode:
		print("🔮 ", display_name, "observée par", observer.name)

func interact(player: Node) -> String:
	match current_evolution_stage:
		0: return display_name + " vous regarde curieusement."
		1: return display_name + " semble vous reconnaître."
		2: return display_name + " s'approche amicalement."
		3: return display_name + " brille d'une lueur magique."
		4: return display_name + " vous communique télépathiquement."
		_: return "Interaction mystérieuse..."

func get_interaction_type() -> String:
	return "observe"
"""
    
    def get_npc_script(self):
        """Retourne le script NPC.gd corrigé.""" 
        return """# ============================================================================
# 👥 NPC.gd - Personnages Non-Joueurs (CORRIGÉ)
# ============================================================================

class_name NPC
extends CharacterBody2D

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
@export var interaction_radius: float = 50.0
@export var movement_speed: float = 30.0

@export_group("Debug")
@export var debug_mode: bool = false

# ============================================================================
# COMPOSANTS
# ============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea

# ============================================================================
# VARIABLES
# ============================================================================

enum NPCState {
	IDLE,
	TALKING,
	WORKING
}

var current_state: NPCState = NPCState.IDLE
var current_interactor: Node = null
var is_in_conversation: bool = false
var relationship_level: float = 0.0

# Références managers (CORRIGÉ)
var dialogue_manager: DialogueManager

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	if debug_mode:
		print("👥 NPC:", npc_id, "initialisation...")
	
	await get_tree().process_frame
	connect_to_managers()
	setup_interaction_areas()
	
	if debug_mode:
		print("👥 NPC:", display_name, "prêt!")

func connect_to_managers() -> void:
	dialogue_manager = get_node_or_null("/root/Dialogue")
	if debug_mode:
		print("👥 NPC: Connexions managers établies")

func setup_interaction_areas() -> void:
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
	if current_state == NPCState.TALKING:
		if current_interactor:
			look_at_interactor()

func look_at_interactor() -> void:
	if current_interactor and sprite:
		var direction = (current_interactor.global_position - global_position).normalized()
		sprite.flip_h = direction.x < 0

# ============================================================================
# SYSTÈME D'INTERACTION
# ============================================================================

func start_interaction(player: Node) -> void:
	if is_in_conversation:
		return
	
	current_interactor = player
	is_in_conversation = true
	change_state(NPCState.TALKING)
	
	start_dialogue(player)

func start_dialogue(player: Node) -> void:
	if dialogue_manager and dialogue_manager.has_method("start_dialogue"):
		dialogue_manager.start_dialogue(npc_id, "generic_greeting")
	else:
		show_simple_message(get_greeting_message())
		end_interaction()

func end_interaction() -> void:
	current_interactor = null
	is_in_conversation = false
	change_state(NPCState.IDLE)

func get_greeting_message() -> String:
	var greetings = [
		"Bonjour ! Comment allez-vous ?",
		"Salutations, voyageur !",
		"Bien le bonjour !"
	]
	return greetings[randi() % greetings.size()]

func show_simple_message(message: String) -> void:
	print("💬 ", display_name, ":", message)

# ============================================================================
# ÉTATS
# ============================================================================

func change_state(new_state: NPCState) -> void:
	if new_state == current_state:
		return
	
	current_state = new_state
	
	if debug_mode:
		print("👥 ", display_name, "état:", NPCState.keys()[current_state])

# ============================================================================
# CALLBACKS
# ============================================================================

func _on_interaction_area_entered(body: Node) -> void:
	if body.is_in_group("player"):
		if debug_mode:
			print("👥 Joueur détecté:", body.name)

func _on_interaction_area_exited(body: Node) -> void:
	if body.is_in_group("player"):
		if is_in_conversation and body == current_interactor:
			end_interaction()

# ============================================================================
# INTERFACE PUBLIQUE
# ============================================================================

func interact(player: Node) -> String:
	start_interaction(player)
	return "Interaction démarrée avec " + display_name

func get_interaction_type() -> String:
	return "dialogue"
"""
    
    def create_test_scene(self):
        """Crée une scène de test simple."""
        # Créer un contenu de scène simple qui évite les problèmes de syntaxe
        scene_lines = [
            '[gd_scene load_steps=5 format=3 uid="uid://test_scene_sb"]',
            '',
            '[ext_resource type="Script" path="res://scripts/core/Player.gd" id="1_player"]',
            '[ext_resource type="Script" path="res://scripts/core/Creature.gd" id="2_creature"]', 
            '[ext_resource type="Script" path="res://scripts/core/NPC.gd" id="3_npc"]',
            '',
            '[sub_resource type="RectangleShape2D" id="player_shape"]',
            'size = Vector2(32, 48)',
            '',
            '[node name="TestScene" type="Node2D"]',
            '',
            '[node name="Background" type="ColorRect" parent="."]',
            'offset_right = 1000.0',
            'offset_bottom = 700.0',
            'color = Color(0.1, 0.2, 0.1, 1)',
            '',
            '[node name="Player" type="CharacterBody2D" parent="." groups=["player"]]',
            'position = Vector2(200, 350)',
            'script = ExtResource("1_player")',
            'debug_mode = true',
            'show_interaction_range = true',
            '',
            '[node name="Sprite2D" type="Sprite2D" parent="Player"]',
            'modulate = Color(0.3, 0.6, 1, 1)',
            '',
            '[node name="CollisionShape2D" type="CollisionShape2D" parent="Player"]',
            'shape = SubResource("player_shape")',
            '',
            '[node name="InteractionArea" type="Area2D" parent="Player"]',
            '',
            '[node name="CollisionShape2D" type="CollisionShape2D" parent="Player/InteractionArea"]',
            '',
            '[node name="ObservationArea" type="Area2D" parent="Player"]',
            '',
            '[node name="CollisionShape2D" type="CollisionShape2D" parent="Player/ObservationArea"]',
            '',
            '[node name="TestCreature" type="CharacterBody2D" parent="." groups=["creatures"]]',
            'position = Vector2(500, 250)',
            'script = ExtResource("2_creature")',
            'creature_id = "maurice_rat"',
            'display_name = "Maurice le Rat"',
            'debug_mode = true',
            '',
            '[node name="Sprite2D" type="Sprite2D" parent="TestCreature"]',
            'modulate = Color(0.8, 0.6, 0.4, 1)',
            '',
            '[node name="CollisionShape2D" type="CollisionShape2D" parent="TestCreature"]',
            'shape = SubResource("player_shape")',
            '',
            '[node name="TestNPC" type="CharacterBody2D" parent="." groups=["npcs"]]',
            'position = Vector2(800, 350)',
            'script = ExtResource("3_npc")',
            'npc_id = "madame_simnel"',
            'display_name = "Madame Simnel"',
            'debug_mode = true',
            '',
            '[node name="Sprite2D" type="Sprite2D" parent="TestNPC"]',
            'modulate = Color(1, 0.8, 0.6, 1)',
            '',
            '[node name="CollisionShape2D" type="CollisionShape2D" parent="TestNPC"]',
            'shape = SubResource("player_shape")',
            '',
            '[node name="InteractionArea" type="Area2D" parent="TestNPC"]',
            '',
            '[node name="CollisionShape2D" type="CollisionShape2D" parent="TestNPC/InteractionArea"]',
            '',
            '[node name="UI" type="CanvasLayer" parent="."]',
            '',
            '[node name="Controls" type="Label" parent="UI"]',
            'offset_right = 350.0',
            'offset_bottom = 150.0',
            'text = "WASD - Bouger\\nE - Interagir\\nSouris - Observer"',
            'theme_override_colors/font_color = Color(1, 1, 1, 1)',
            '',
            '[node name="Info" type="Label" parent="UI"]',
            'anchors_preset = 1',
            'anchor_left = 1.0',
            'anchor_right = 1.0',
            'offset_left = -300.0',
            'offset_bottom = 100.0',
            'text = "TEST SCENE\\nJoueur bleu\\nCreature brune\\nNPC jaune"',
            'theme_override_colors/font_color = Color(1, 1, 1, 1)'
        ]
        
        scene_content = '\n'.join(scene_lines)
        self.write_file("scenes/test/TestScene.tscn", scene_content)
    
    def create_input_instructions(self):
        """Crée les instructions pour configurer l'input map."""
        instructions = """# INPUT MAP CONFIGURATION
# ======================

Dans Godot, aller dans: Project > Project Settings > Input Map

Ajouter ces actions:

1. move_left
   - Touche: A  
   - Touche: Flèche Gauche

2. move_right
   - Touche: D
   - Touche: Flèche Droite

3. move_up
   - Touche: W
   - Touche: Flèche Haut

4. move_down
   - Touche: S
   - Touche: Flèche Bas

5. interact
   - Touche: E

6. observe  
   - Bouton: Clic Gauche Souris

7. run
   - Touche: Shift Gauche

Après configuration, sauvegarder le projet.
"""
        self.write_file("INPUT_MAP_INSTRUCTIONS.txt", instructions)
    
    def generate_autoload_instructions(self):
        """Génère les instructions pour configurer les AutoLoads."""
        instructions = """# CONFIGURATION AUTOLOADS
# ========================

Dans Godot: Project Settings > AutoLoad

SUPPRIMER tous les AutoLoads existants qui causent des erreurs.

AJOUTER ces AutoLoads dans l'ordre:

1. Name: Game
   Path: res://scripts/managers/GameManager.gd
   Enable: ✅

2. Name: Data  
   Path: res://scripts/managers/DataManager.gd
   Enable: ✅

3. Name: Observation
   Path: res://scripts/managers/ObservationManager.gd
   Enable: ✅

4. Name: Dialogue
   Path: res://scripts/managers/DialogueManager.gd
   Enable: ✅

5. Name: Quest
   Path: res://scripts/managers/QuestManager.gd
   Enable: ✅

6. Name: UI
   Path: res://scripts/stubs/UIManager.gd
   Enable: ✅

7. Name: Audio
   Path: res://scripts/stubs/AudioManager.gd
   Enable: ✅

IMPORTANT:
- Utilisez exactement ces noms courts
- PAS GameManager, DataManager, etc. (conflit avec class_name)

Après configuration:
1. Project > Reload Current Project
2. Run TestScene.tscn
3. Test gameplay!
"""
        self.write_file("AUTOLOAD_INSTRUCTIONS.txt", instructions)
    
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
        print("  2. ⚙️ Ajouter Input Map (voir INPUT_MAP_INSTRUCTIONS.txt)")
        print("  3. 🎮 Run TestScene.tscn")
        print("  4. 🎉 Gameplay fonctionnel!")
        
        print(f"\n📊 RÉSULTAT:")
        if len(self.errors) == 0:
            print("  ✅ TOUTES LES CORRECTIONS APPLIQUÉES AVEC SUCCÈS!")
            print("  🚀 Projet prêt pour les tests!")
        else:
            print(f"  ⚠️ {len(self.errors)} erreur(s) détectée(s)")

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