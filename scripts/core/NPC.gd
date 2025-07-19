# ============================================================================
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
