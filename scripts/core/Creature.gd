# ============================================================================
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
