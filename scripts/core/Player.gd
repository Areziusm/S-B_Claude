# ============================================================================
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
