# ============================================================================
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
