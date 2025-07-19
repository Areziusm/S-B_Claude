# ============================================================================
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
