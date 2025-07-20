# ============================================================================
# 🎮 Player.gd - Contrôleur du Joueur (CORRIGÉ)
# ============================================================================
# STATUS: ✅ CORE CLASS | ROADMAP: Mois 1, Semaine 1-2
# PRIORITY: 🔴 CRITICAL - Personnage principal
# DEPENDENCIES: GameManager, ObservationManager, QuestManager

class_name Player
extends CharacterBody2D

## Contrôleur principal du personnage joueur
## Gère mouvement, interactions, observations et états

# ============================================================================
# SIGNAUX
# ============================================================================

## Mouvement et états
signal player_moved(new_position: Vector2)
signal player_state_changed(old_state: String, new_state: String)

## Interactions
signal interaction_started(target: Node)
signal interaction_ended(target: Node)
signal dialogue_triggered(npc: Node)

## Observation
signal observation_started(creature: Node)
signal observation_ended(creature: Node, duration: float)
signal creature_data_collected(creature_id: String, data: Dictionary)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export_group("Movement")
@export var base_speed: float = 200.0
@export var run_multiplier: float = 1.5
@export var acceleration: float = 10.0
@export var friction: float = 15.0

@export_group("Interaction")
@export var interaction_range: float = 50.0
@export var observation_range: float = 80.0
@export var observation_min_time: float = 2.0

@export_group("Debug")
@export var debug_mode: bool = false
@export var show_interaction_range: bool = false

# ============================================================================
# ÉTATS ET VARIABLES
# ============================================================================

enum PlayerState {
	IDLE,
	MOVING,
	INTERACTING,
	OBSERVING,
	IN_DIALOGUE,
	IN_COMBAT,
	DISABLED
}

## État actuel
var current_state: PlayerState = PlayerState.IDLE

## Mouvement
var input_vector: Vector2 = Vector2.ZERO
var last_direction: Vector2 = Vector2.DOWN
var is_running: bool = false

## Interaction
var interactable_objects: Array[Node] = []
var current_interaction_target: Node = null
var can_interact: bool = true

## Observation
var observable_creatures: Array[Node] = []
var current_observation_target: Node = null
var is_observing: bool = false
var observation_timer: float = 0.0

## Références aux managers via GameManager
var game_manager: Node
var observation_manager: Node
var dialogue_manager: Node
var quest_manager: Node

## Composants
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var observation_area: Area2D = $ObservationArea

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	"""Initialisation du joueur"""
	if debug_mode:
		print("🎮 Player: Initialisation...")
	
	# Attendre et connecter aux managers
	await get_tree().process_frame
	connect_to_managers()
	
	# Configuration des zones
	setup_areas()
	
	# Ajout aux groupes
	add_to_group("player")
	
	if debug_mode:
		print("🎮 Player: Prêt!")

func connect_to_managers() -> void:
	"""Se connecte aux managers via GameManager"""
	game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		# Récupérer les managers depuis GameManager
		observation_manager = game_manager.get_manager("ObservationManager")
		dialogue_manager = game_manager.get_manager("DialogueManager")
		quest_manager = game_manager.get_manager("QuestManager")
		
		# Connexions aux signaux si les managers existent
		if dialogue_manager and dialogue_manager.has_signal("dialogue_started"):
			dialogue_manager.dialogue_started.connect(_on_dialogue_started)
			dialogue_manager.dialogue_ended.connect(_on_dialogue_ended)
		
		if observation_manager and observation_manager.has_signal("creature_evolved"):
			observation_manager.creature_evolved.connect(_on_creature_evolved)
	else:
		push_warning("🎮 Player: GameManager non trouvé!")

func setup_areas() -> void:
	"""Configure les zones d'interaction et d'observation"""
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)
	
	if observation_area:
		observation_area.body_entered.connect(_on_observation_area_entered)
		observation_area.body_exited.connect(_on_observation_area_exited)
	
	# Visualisation debug
	if show_interaction_range and debug_mode:
		queue_redraw()

# ============================================================================
# BOUCLE PRINCIPALE
# ============================================================================

func _physics_process(delta: float) -> void:
	"""Mise à jour physique"""
	if current_state == PlayerState.DISABLED:
		return
	
	# Gestion des entrées
	if current_state not in [PlayerState.IN_DIALOGUE, PlayerState.IN_COMBAT]:
		handle_input()
	
	# Mise à jour selon l'état
	match current_state:
		PlayerState.IDLE, PlayerState.MOVING:
			handle_movement(delta)
		PlayerState.OBSERVING:
			update_observation(delta)
	
	# Mise à jour visuelle
	update_sprite_direction()

func _input(event: InputEvent) -> void:
	"""Gestion des événements d'entrée"""
	if current_state == PlayerState.DISABLED:
		return
	
	# Interaction
	if event.is_action_pressed("interact") and can_interact:
		attempt_interaction()
	
	# Observation
	if event.is_action_pressed("observe"):
		start_observation()
	elif event.is_action_released("observe"):
		stop_observation()
	
	# Course
	if event.is_action_pressed("run"):
		is_running = true
	elif event.is_action_released("run"):
		is_running = false

# ============================================================================
# MOUVEMENT
# ============================================================================

func handle_input() -> void:
	"""Récupère les entrées de mouvement"""
	input_vector = Vector2.ZERO
	
	# Directions cardinales
	input_vector.x = Input.get_axis("move_left", "move_right")
	input_vector.y = Input.get_axis("move_up", "move_down")
	
	# Normalisation pour mouvement diagonal
	if input_vector.length() > 1.0:
		input_vector = input_vector.normalized()
	
	# Mémoriser dernière direction
	if input_vector != Vector2.ZERO:
		last_direction = input_vector

func handle_movement(delta: float) -> void:
	"""Gère le déplacement du joueur"""
	var target_velocity = input_vector * base_speed
	
	# Modificateur de vitesse
	if is_running and input_vector != Vector2.ZERO:
		target_velocity *= run_multiplier
	
	# Application du mouvement avec accélération/friction
	if input_vector != Vector2.ZERO:
		velocity = velocity.lerp(target_velocity, acceleration * delta)
		change_state(PlayerState.MOVING)
		player_moved.emit(global_position)
	else:
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)
		if velocity.length() < 10:
			velocity = Vector2.ZERO
			change_state(PlayerState.IDLE)
	
	# Déplacement physique
	move_and_slide()

func update_sprite_direction() -> void:
	"""Met à jour l'orientation du sprite"""
	if abs(last_direction.x) > abs(last_direction.y):
		sprite.flip_h = last_direction.x < 0
	
	# TODO: Ajouter animations directionnelles

# ============================================================================
# INTERACTION
# ============================================================================

func attempt_interaction() -> void:
	"""Tente d'interagir avec l'objet le plus proche"""
	if interactable_objects.is_empty():
		return
	
	# Trouver l'objet le plus proche
	var closest_target = find_closest_interactable()
	
	if closest_target:
		start_interaction(closest_target)

func find_closest_interactable() -> Node:
	"""Trouve l'objet interactable le plus proche"""
	var closest: Node = null
	var min_distance: float = INF
	
	for obj in interactable_objects:
		if obj and is_instance_valid(obj):
			var distance = global_position.distance_to(obj.global_position)
			if distance < min_distance:
				min_distance = distance
				closest = obj
	
	return closest

func start_interaction(target: Node) -> void:
	"""Démarre une interaction avec une cible"""
	if current_state != PlayerState.IDLE and current_state != PlayerState.MOVING:
		return
	
	current_interaction_target = target
	change_state(PlayerState.INTERACTING)
	interaction_started.emit(target)
	
	# Gérer différents types d'interaction
	if target.has_method("interact_with_player"):
		target.interact_with_player(self)
	elif target.is_in_group("npcs"):
		trigger_dialogue(target)
	elif target.is_in_group("items"):
		collect_item(target)
	
	# Fin d'interaction rapide si pas de dialogue
	if current_state == PlayerState.INTERACTING:
		end_interaction()

func end_interaction() -> void:
	"""Termine l'interaction en cours"""
	if current_interaction_target:
		interaction_ended.emit(current_interaction_target)
		current_interaction_target = null
	
	if current_state == PlayerState.INTERACTING:
		change_state(PlayerState.IDLE)

func trigger_dialogue(npc: Node) -> void:
	"""Déclenche un dialogue avec un NPC"""
	if dialogue_manager and dialogue_manager.has_method("start_dialogue"):
		change_state(PlayerState.IN_DIALOGUE)
		dialogue_triggered.emit(npc)
		
		var npc_id = npc.character_id if "character_id" in npc else npc.name
		dialogue_manager.start_dialogue(npc_id, "default")

func collect_item(item: Node) -> void:
	"""Ramasse un objet"""
	# TODO: Implémenter système d'inventaire
	if debug_mode:
		print("🎮 Item collecté:", item.name)
	
	item.queue_free()

# ============================================================================
# OBSERVATION
# ============================================================================

func start_observation() -> void:
	"""Démarre l'observation de créatures"""
	if current_state != PlayerState.IDLE and current_state != PlayerState.MOVING:
		return
	
	var target = find_best_observation_target()
	if not target:
		return
	
	is_observing = true
	observation_timer = 0.0
	current_observation_target = target
	change_state(PlayerState.OBSERVING)
	observation_started.emit(target)

func stop_observation() -> void:
	"""Arrête l'observation en cours"""
	if not is_observing:
		return
	
	var duration = observation_timer
	var target = current_observation_target
	
	# Traiter l'observation si durée suffisante
	if duration >= observation_min_time and target:
		process_creature_observation(target, duration)
	
	# Réinitialiser
	is_observing = false
	observation_timer = 0.0
	observation_ended.emit(target, duration)
	current_observation_target = null
	
	if current_state == PlayerState.OBSERVING:
		change_state(PlayerState.IDLE)

func process_creature_observation(creature: Node, duration: float) -> void:
	"""Traite une observation de créature complétée"""
	if not observation_manager:
		return
	
	var creature_id = creature.creature_id if "creature_id" in creature else creature.name
	var observation_data = {
		"duration": duration,
		"intensity": min(duration / observation_min_time, 3.0),
		"position": creature.global_position,
		"evolution_stage": creature.current_evolution_stage if "current_evolution_stage" in creature else 0
	}
	
	# Notifier l'ObservationManager
	if observation_manager.has_method("observe_creature"):
		observation_manager.observe_creature(creature_id, observation_data.intensity)
	
	# Émettre signal pour autres systèmes
	creature_data_collected.emit(creature_id, observation_data)
	
	if debug_mode:
		print("🔮 Observation complétée:", creature_id, "- Durée:", duration, "s")

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
			
			# Bonus pour créatures non observées
			if "observation_count" in creature and creature.observation_count == 0:
				score *= 1.5
			
			if score > best_score:
				best_score = score
				best_target = creature
	
	return best_target

func update_observation(delta: float) -> void:
	"""Met à jour le timer d'observation"""
	if is_observing:
		observation_timer += delta
		
		# Feedback visuel progressif
		# TODO: Ajouter effet visuel d'observation

# ============================================================================
# GESTION DES ÉTATS
# ============================================================================

func change_state(new_state: PlayerState) -> void:
	"""Change l'état du joueur"""
	if new_state == current_state:
		return
	
	var old_state = current_state
	current_state = new_state
	
	player_state_changed.emit(
		PlayerState.keys()[old_state],
		PlayerState.keys()[new_state]
	)
	
	if debug_mode:
		print("🎮 État:", PlayerState.keys()[old_state], "→", PlayerState.keys()[new_state])

func disable_player() -> void:
	"""Désactive les contrôles du joueur"""
	change_state(PlayerState.DISABLED)
	velocity = Vector2.ZERO

func enable_player() -> void:
	"""Réactive les contrôles du joueur"""
	if current_state == PlayerState.DISABLED:
		change_state(PlayerState.IDLE)

# ============================================================================
# CALLBACKS ZONES
# ============================================================================

func _on_interaction_area_entered(body: Node) -> void:
	"""Quand un objet entre dans la zone d'interaction"""
	if body != self and body.has_method("get_interaction_type"):
		if body not in interactable_objects:
			interactable_objects.append(body)
			
			if debug_mode:
				print("🎮 Objet interactable détecté:", body.name)

func _on_interaction_area_exited(body: Node) -> void:
	"""Quand un objet sort de la zone d'interaction"""
	if body in interactable_objects:
		interactable_objects.erase(body)
		
		if body == current_interaction_target:
			end_interaction()

func _on_observation_area_entered(body: Node) -> void:
	"""Quand une créature entre dans la zone d'observation"""
	if body != self and body.is_in_group("creatures"):
		if body not in observable_creatures:
			observable_creatures.append(body)
			
			if debug_mode:
				print("🔮 Créature observable:", body.name)

func _on_observation_area_exited(body: Node) -> void:
	"""Quand une créature sort de la zone d'observation"""
	if body in observable_creatures:
		observable_creatures.erase(body)
		
		if body == current_observation_target:
			stop_observation()

# ============================================================================
# CALLBACKS MANAGERS
# ============================================================================

func _on_dialogue_started(npc_id: String, dialogue_id: String) -> void:
	"""Appelé quand un dialogue commence"""
	change_state(PlayerState.IN_DIALOGUE)
	disable_movement()

func _on_dialogue_ended(npc_id: String, choice: String, relationship_change: float) -> void:
	"""Appelé quand un dialogue se termine"""
	if current_state == PlayerState.IN_DIALOGUE:
		change_state(PlayerState.IDLE)
		enable_movement()

func _on_creature_evolved(creature_id: String, old_stage: int, new_stage: int) -> void:
	"""Appelé quand une créature observée évolue"""
	# TODO: Ajouter feedback visuel/sonore
	if debug_mode:
		print("🔮 Évolution observée:", creature_id, old_stage, "→", new_stage)

# ============================================================================
# UTILITAIRES
# ============================================================================

func disable_movement() -> void:
	"""Désactive temporairement le mouvement"""
	velocity = Vector2.ZERO
	input_vector = Vector2.ZERO

func enable_movement() -> void:
	"""Réactive le mouvement"""
	# Le mouvement se réactivera automatiquement via handle_input

func _draw() -> void:
	"""Dessine les zones de debug"""
	if not debug_mode or not show_interaction_range:
		return
	
	# Zone d'interaction en bleu
	draw_circle(Vector2.ZERO, interaction_range, Color(0, 0, 1, 0.2))
	
	# Zone d'observation en vert
	draw_circle(Vector2.ZERO, observation_range, Color(0, 1, 0, 0.1))