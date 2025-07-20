# ============================================================================
# 🐾 Creature.gd - Base pour Système d'Évolution (CORRIGÉ)
# ============================================================================
# STATUS: ✅ CORE CLASS | ROADMAP: Mois 1, Semaine 2
# PRIORITY: 🔴 CRITICAL - Mécanique centrale du jeu
# DEPENDENCIES: ObservationManager, GameManager

class_name Creature
extends CharacterBody2D

## Classe de base pour toutes les créatures du jeu
## Gère évolution magique, comportements et interactions

# ============================================================================
# SIGNAUX
# ============================================================================

## Émis quand la créature est observée
signal creature_observed(observer: Node, duration: float)

## Émis quand la créature évolue
signal creature_evolved(old_stage: int, new_stage: int)

## Émis pour changements d'état
signal state_changed(old_state: String, new_state: String)

## Émis quand la créature interagit
signal creature_interacted(interaction_type: String, target: Node)

# ============================================================================
# CONFIGURATION
# ============================================================================

@export_group("Identity")
@export var creature_id: String = "unknown_creature"
@export var display_name: String = "Créature Mystérieuse"
@export var species_type: String = "generic"

@export_group("Evolution")
@export var current_evolution_stage: int = 0
@export var observation_count: int = 0
@export var magic_affinity: float = 1.0
@export var evolution_locked: bool = false

@export_group("Behavior")
@export var base_speed: float = 50.0
@export var roam_radius: float = 200.0
@export var flee_distance: float = 150.0
@export var behavior_type: String = "passive"

@export_group("Debug")
@export var debug_mode: bool = false
@export var show_evolution_info: bool = false

# ============================================================================
# ÉTATS ET VARIABLES
# ============================================================================

enum CreatureBehavior {
	IDLE,
	ROAMING,
	FLEEING,
	CURIOUS,
	INTERACTING,
	EVOLVING,
	SPECIAL
}

enum EvolutionStage {
	STAGE_0_NORMAL = 0,
	STAGE_1_AWARE = 1,
	STAGE_2_ENHANCED = 2,
	STAGE_3_MAGICAL = 3,
	STAGE_4_LEGENDARY = 4
}

## État actuel
var current_behavior: CreatureBehavior = CreatureBehavior.IDLE
var previous_behavior: CreatureBehavior = CreatureBehavior.IDLE

## Données de créature
var creature_data: Dictionary = {}
var abilities: Array[String] = []
var evolution_history: Array[Dictionary] = []

## Comportement
var home_position: Vector2
var target_position: Vector2
var behavior_timer: float = 0.0
var behavior_duration: float = 2.0

## Observation
var observers: Array[Node] = []
var current_observer: Node = null
var total_observation_time: float = 0.0
var last_observation_time: float = 0.0

## Évolution
var is_evolving: bool = false
var evolution_timer: float = 0.0
var evolution_particles: GPUParticles2D
var magic_accumulated: float = 0.0

## Interaction
var interaction_range: float = 100.0
var can_interact: bool = true
var nearby_creatures: Array[Node] = []

## Références managers
var game_manager: Node
var observation_manager: Node
var data_manager: Node

## Composants
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	"""Initialisation de la créature"""
	if debug_mode:
		print("🐾 Creature:", creature_id, "initialisation...")
	
	# Attendre et connecter aux managers
	await get_tree().process_frame
	connect_to_managers()
	
	# Chargement données
	load_creature_data()
	
	# Configuration initiale
	setup_creature()
	
	# Ajout aux groupes
	add_to_group("creatures")
	add_to_group("observable")
	
	if debug_mode:
		print("🐾 Creature:", display_name, "prête!")

func connect_to_managers() -> void:
	"""Se connecte aux managers nécessaires"""
	game_manager = get_node_or_null("/root/GameManager")
	
	if game_manager:
		observation_manager = game_manager.get_manager("ObservationManager")
		data_manager = game_manager.get_manager("DataManager")
		
		# Connexion aux signaux
		if observation_manager and observation_manager.has_signal("magic_cascade_triggered"):
			observation_manager.magic_cascade_triggered.connect(_on_magic_cascade)
		
		if observation_manager and observation_manager.has_signal("observation_ended"):
			observation_manager.observation_ended.connect(_on_observation_ended)
	else:
		push_warning("🐾 Creature: GameManager non trouvé!")

func load_creature_data() -> void:
	"""Charge les données de la créature depuis DataManager"""
	if not data_manager:
		push_warning("🐾 DataManager non disponible")
		return
	
	var creatures_db = data_manager.get("creatures_db", {})
	if creature_id in creatures_db:
		creature_data = creatures_db[creature_id].duplicate(true)
		apply_creature_data()
		
		if debug_mode:
			print("🐾 Données chargées pour:", creature_id)
	else:
		push_warning("🐾 Créature non trouvée dans la base:", creature_id)

func apply_creature_data() -> void:
	"""Applique les données chargées à la créature"""
	if creature_data.is_empty():
		return
	
	# Appliquer les propriétés de base
	display_name = creature_data.get("name", display_name)
	species_type = creature_data.get("base_species", species_type)
	magic_affinity = creature_data.get("magic_affinity", magic_affinity)
	behavior_type = creature_data.get("behavior_type", behavior_type)
	
	# Charger les capacités du stade actuel
	update_abilities_for_stage()

func setup_creature() -> void:
	"""Configure la créature selon son type"""
	home_position = global_position
	target_position = home_position
	
	# Configuration visuelle selon le stade
	update_visual_appearance()
	
	# Création des particules d'évolution
	setup_evolution_particles()
	
	# Configuration du comportement
	setup_behavior_ai()

# ============================================================================
# BOUCLE PRINCIPALE
# ============================================================================

func _physics_process(delta: float) -> void:
	"""Mise à jour physique"""
	# Mise à jour comportement
	update_behavior(delta)
	
	# Gestion évolution
	if is_evolving:
		update_evolution(delta)
	
	# Mise à jour observation
	if not observers.is_empty():
		update_observation(delta)
	
	# Mouvement
	handle_movement(delta)
	
	# Debug
	if debug_mode and show_evolution_info:
		queue_redraw()

# ============================================================================
# SYSTÈME D'OBSERVATION
# ============================================================================

func start_being_observed(observer: Node) -> void:
	"""Appelé quand un observateur commence à observer"""
	if observer not in observers:
		observers.append(observer)
		
		if observers.size() == 1:
			# Première observation
			current_observer = observer
			on_observation_started()
		
		if debug_mode:
			print("🐾", display_name, "observé par", observer.name)

func stop_being_observed(observer: Node) -> void:
	"""Appelé quand un observateur arrête d'observer"""
	if observer in observers:
		observers.erase(observer)
		
		if observers.is_empty():
			on_observation_ended()
			current_observer = null

func on_observation_started() -> void:
	"""Réaction au début de l'observation"""
	# Changement de comportement selon le type
	match behavior_type:
		"cautious":
			change_behavior(CreatureBehavior.FLEEING)
		"curious":
			change_behavior(CreatureBehavior.CURIOUS)
		"bold":
			# Continue normalement
			pass
	
	# Effets visuels
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", 0.9, 0.3)
		tween.tween_property(sprite, "modulate:a", 1.0, 0.3)

func on_observation_ended() -> void:
	"""Réaction à la fin de l'observation"""
	# Retour au comportement normal
	if current_behavior == CreatureBehavior.FLEEING or current_behavior == CreatureBehavior.CURIOUS:
		change_behavior(CreatureBehavior.IDLE)

func update_observation(delta: float) -> void:
	"""Met à jour les effets de l'observation"""
	total_observation_time += delta
	last_observation_time += delta
	
	# Accumulation de magie
	var magic_gain = delta * magic_affinity * observers.size()
	magic_accumulated += magic_gain
	
	# Vérifier si évolution possible
	if can_evolve() and magic_accumulated >= get_evolution_threshold():
		trigger_evolution()

func register_observation_complete(duration: float, intensity: float) -> void:
	"""Enregistre une observation complète"""
	observation_count += 1
	creature_observed.emit(current_observer, duration)
	
	# Notification à l'ObservationManager
	if observation_manager and observation_manager.has_method("register_creature_observation"):
		observation_manager.register_creature_observation(creature_id, {
			"observer": current_observer,
			"duration": duration,
			"intensity": intensity,
			"stage": current_evolution_stage,
			"location": global_position
		})
	
	if debug_mode:
		print("🐾 Observation complète:", display_name, 
			  "- Count:", observation_count, "- Duration:", duration)

# ============================================================================
# SYSTÈME D'ÉVOLUTION
# ============================================================================

func can_evolve() -> bool:
	"""Vérifie si la créature peut évoluer"""
	if evolution_locked or is_evolving:
		return false
	
	if current_evolution_stage >= EvolutionStage.STAGE_4_LEGENDARY:
		return false
	
	# Vérifier les conditions spécifiques
	return check_evolution_conditions()

func check_evolution_conditions() -> bool:
	"""Vérifie les conditions d'évolution spécifiques"""
	if creature_data.is_empty():
		return observation_count >= (current_evolution_stage + 1) * 3
	
	var stages = creature_data.get("evolution_stages", [])
	if current_evolution_stage + 1 >= stages.size():
		return false
	
	var next_stage = stages[current_evolution_stage + 1]
	var condition = next_stage.get("unlock_condition", "")
	
	# Parser les conditions
	# TODO: Système de conditions plus complexe
	return observation_count >= (current_evolution_stage + 1) * 3

func get_evolution_threshold() -> float:
	"""Retourne le seuil de magie pour évoluer"""
	return (current_evolution_stage + 1) * 10.0 * (2.0 - magic_affinity)

func trigger_evolution() -> void:
	"""Déclenche l'évolution de la créature"""
	if not can_evolve():
		return
	
	is_evolving = true
	var old_stage = current_evolution_stage
	
	# Effets visuels
	start_evolution_sequence()
	
	# Attendre la fin de l'animation
	await get_tree().create_timer(2.5).timeout
	
	# Appliquer l'évolution
	current_evolution_stage += 1
	apply_evolution()
	
	# Fin de l'évolution
	is_evolving = false
	magic_accumulated = 0.0
	
	# Signaux et notifications
	creature_evolved.emit(old_stage, current_evolution_stage)
	
	if observation_manager and observation_manager.has_method("notify_creature_evolution"):
		observation_manager.notify_creature_evolution(creature_id, old_stage, current_evolution_stage)
	
	if debug_mode:
		print("🐾 ÉVOLUTION!", display_name, "Stade", old_stage, "→", current_evolution_stage)

func apply_evolution() -> void:
	"""Applique les changements d'évolution"""
	# Mise à jour des capacités
	update_abilities_for_stage()
	
	# Mise à jour visuelle
	update_visual_appearance()
	
	# Mise à jour des stats
	update_evolution_stats()
	
	# Enregistrer dans l'historique
	evolution_history.append({
		"stage": current_evolution_stage,
		"timestamp": Time.get_unix_time_from_system(),
		"observation_count": observation_count,
		"location": global_position
	})

func update_abilities_for_stage() -> void:
	"""Met à jour les capacités selon le stade"""
	abilities.clear()
	
	if creature_data.is_empty():
		# Capacités par défaut
		abilities = ["basic_movement"]
		if current_evolution_stage >= 1:
			abilities.append("enhanced_senses")
		if current_evolution_stage >= 2:
			abilities.append("basic_magic")
		return
	
	var stages = creature_data.get("evolution_stages", [])
	if current_evolution_stage < stages.size():
		var stage_data = stages[current_evolution_stage]
		abilities = stage_data.get("abilities", []).duplicate()

func update_visual_appearance() -> void:
	"""Met à jour l'apparence selon le stade"""
	if not sprite:
		return
	
	# Échelle selon le stade
	var scale_factor = 1.0 + (current_evolution_stage * 0.2)
	sprite.scale = Vector2.ONE * scale_factor
	
	# Couleur selon le stade
	var evolution_colors = [
		Color.WHITE,                    # Stage 0
		Color(1.2, 1.2, 1.0),          # Stage 1 - Légère lueur
		Color(1.0, 1.3, 1.3),          # Stage 2 - Teinte magique
		Color(1.3, 1.0, 1.5),          # Stage 3 - Aura magique
		Color(1.5, 1.2, 2.0)           # Stage 4 - Légendaire
	]
	
	if current_evolution_stage < evolution_colors.size():
		sprite.modulate = evolution_colors[current_evolution_stage]

func update_evolution_stats() -> void:
	"""Met à jour les statistiques après évolution"""
	# Augmentation de la vitesse
	base_speed = base_speed * (1.0 + current_evolution_stage * 0.15)
	
	# Augmentation du rayon d'interaction
	interaction_range = interaction_range * (1.0 + current_evolution_stage * 0.2)
	
	# Amélioration de l'affinité magique
	magic_affinity = min(magic_affinity * 1.2, 2.0)

# ============================================================================
# COMPORTEMENT IA
# ============================================================================

func setup_behavior_ai() -> void:
	"""Configure l'IA de comportement"""
	# Configuration selon le type
	match behavior_type:
		"passive":
			behavior_duration = randf_range(2.0, 4.0)
		"aggressive":
			behavior_duration = randf_range(1.0, 2.0)
		"cautious":
			behavior_duration = randf_range(3.0, 5.0)
		"curious":
			behavior_duration = randf_range(1.5, 3.0)

func update_behavior(delta: float) -> void:
	"""Met à jour le comportement de la créature"""
	behavior_timer += delta
	
	if behavior_timer >= behavior_duration:
		behavior_timer = 0.0
		choose_new_behavior()
	
	# Exécuter le comportement actuel
	match current_behavior:
		CreatureBehavior.IDLE:
			# Rester immobile
			velocity = velocity.lerp(Vector2.ZERO, 10.0 * delta)
			
		CreatureBehavior.ROAMING:
			# Se déplacer vers la cible
			var direction = (target_position - global_position).normalized()
			velocity = direction * base_speed
			
			# Nouvelle cible si proche
			if global_position.distance_to(target_position) < 20.0:
				choose_new_roam_target()
		
		CreatureBehavior.FLEEING:
			# Fuir l'observateur
			if current_observer:
				var flee_direction = (global_position - current_observer.global_position).normalized()
				velocity = flee_direction * base_speed * 1.5
		
		CreatureBehavior.CURIOUS:
			# S'approcher prudemment
			if current_observer:
				var distance = global_position.distance_to(current_observer.global_position)
				if distance > 100:
					var approach_direction = (current_observer.global_position - global_position).normalized()
					velocity = approach_direction * base_speed * 0.5
				else:
					velocity = velocity.lerp(Vector2.ZERO, 5.0 * delta)
		
		CreatureBehavior.EVOLVING:
			# Immobile pendant l'évolution
			velocity = Vector2.ZERO

func choose_new_behavior() -> void:
	"""Choisit un nouveau comportement"""
	if is_evolving:
		return
	
	# Si observé, comportements spéciaux
	if not observers.is_empty():
		match behavior_type:
			"cautious":
				change_behavior(CreatureBehavior.FLEEING)
			"curious":
				change_behavior(CreatureBehavior.CURIOUS)
			_:
				change_behavior(CreatureBehavior.IDLE)
		return
	
	# Comportement normal
	var rand = randf()
	if rand < 0.3:
		change_behavior(CreatureBehavior.IDLE)
	else:
		change_behavior(CreatureBehavior.ROAMING)
		choose_new_roam_target()

func change_behavior(new_behavior: CreatureBehavior) -> void:
	"""Change le comportement de la créature"""
	if new_behavior == current_behavior:
		return
	
	previous_behavior = current_behavior
	current_behavior = new_behavior
	behavior_timer = 0.0
	
	state_changed.emit(
		CreatureBehavior.keys()[previous_behavior],
		CreatureBehavior.keys()[current_behavior]
	)

func choose_new_roam_target() -> void:
	"""Choisit une nouvelle cible de déplacement"""
	var angle = randf() * TAU
	var distance = randf_range(50, roam_radius)
	
	target_position = home_position + Vector2(
		cos(angle) * distance,
		sin(angle) * distance
	)

# ============================================================================
# MOUVEMENT
# ============================================================================

func handle_movement(delta: float) -> void:
	"""Gère le déplacement physique"""
	# Limiter la distance depuis home
	var distance_from_home = global_position.distance_to(home_position)
	if distance_from_home > roam_radius * 1.5:
		# Retourner vers home
		var return_direction = (home_position - global_position).normalized()
		velocity = velocity.lerp(return_direction * base_speed, 5.0 * delta)
	
	# Appliquer le mouvement
	move_and_slide()
	
	# Orientation du sprite
	if velocity.length() > 10:
		sprite.flip_h = velocity.x < 0

# ============================================================================
# EFFETS VISUELS
# ============================================================================

func setup_evolution_particles() -> void:
	"""Configure les particules d'évolution"""
	evolution_particles = GPUParticles2D.new()
	evolution_particles.emitting = false
	evolution_particles.amount = 50
	evolution_particles.lifetime = 2.0
	# TODO: Configurer le process material
	add_child(evolution_particles)

func start_evolution_sequence() -> void:
	"""Démarre la séquence visuelle d'évolution"""
	if evolution_particles:
		evolution_particles.emitting = true
	
	# Animation
	if animation_player and animation_player.has_animation("evolution"):
		animation_player.play("evolution")
	else:
		# Animation par défaut
		var tween = create_tween()
		tween.set_loops(5)
		tween.tween_property(sprite, "scale", sprite.scale * 1.2, 0.2)
		tween.tween_property(sprite, "scale", sprite.scale, 0.2)
	
	# Son d'évolution
	# TODO: Jouer son via AudioManager

func update_evolution(delta: float) -> void:
	"""Met à jour les effets d'évolution"""
	evolution_timer += delta
	
	# Effet de pulsation
	var pulse = sin(evolution_timer * 10.0) * 0.1 + 1.0
	if sprite:
		sprite.scale = Vector2.ONE * pulse * (1.0 + current_evolution_stage * 0.2)

# ============================================================================
# INTERACTION
# ============================================================================

func get_interaction_type() -> String:
	"""Retourne le type d'interaction possible"""
	if is_evolving:
		return "evolving"
	
	if not observers.is_empty():
		return "being_observed"
	
	return "observe"

func interact_with_creature(other_creature: Node) -> void:
	"""Interaction avec une autre créature"""
	if not can_interact:
		return
	
	creature_interacted.emit("creature", other_creature)
	
	# TODO: Comportements sociaux selon les espèces

# ============================================================================
# CALLBACKS
# ============================================================================

func _on_magic_cascade(epicenter: Vector2, intensity: float) -> void:
	"""Réagit aux cascades magiques"""
	var distance = global_position.distance_to(epicenter)
	if distance < 500:
		# Gain de magie bonus
		var magic_boost = (1.0 - distance / 500.0) * intensity * magic_affinity
		magic_accumulated += magic_boost
		
		if debug_mode:
			print("🐾 Cascade magique! Boost:", magic_boost)

func _on_observation_ended(creature_id: String, observation_data: Dictionary) -> void:
	"""Callback quand une observation se termine"""
	if creature_id == self.creature_id:
		var duration = observation_data.get("duration", 0.0)
		var intensity = observation_data.get("intensity", 1.0)
		
		if duration >= 2.0:  # Observation minimum
			register_observation_complete(duration, intensity)

# ============================================================================
# SAUVEGARDE
# ============================================================================

func get_save_data() -> Dictionary:
	"""Retourne les données à sauvegarder"""
	return {
		"creature_id": creature_id,
		"evolution_stage": current_evolution_stage,
		"observation_count": observation_count,
		"magic_accumulated": magic_accumulated,
		"position": var_to_str(global_position),
		"abilities": abilities,
		"evolution_history": evolution_history
	}

func load_save_data(data: Dictionary) -> void:
	"""Charge les données sauvegardées"""
	current_evolution_stage = data.get("evolution_stage", 0)
	observation_count = data.get("observation_count", 0)
	magic_accumulated = data.get("magic_accumulated", 0.0)
	abilities = data.get("abilities", [])
	evolution_history = data.get("evolution_history", [])
	
	var pos_str = data.get("position", "")
	if pos_str:
		global_position = str_to_var(pos_str)
	
	# Appliquer les changements visuels
	update_visual_appearance()
	update_abilities_for_stage()

# ============================================================================
# DEBUG
# ============================================================================

func _draw() -> void:
	"""Dessine les infos de debug"""
	if not debug_mode or not show_evolution_info:
		return
	
	# Barre de progression évolution
	var bar_width = 100
	var bar_height = 10
	var bar_pos = Vector2(-bar_width/2, -60)
	
	# Fond
	draw_rect(Rect2(bar_pos, Vector2(bar_width, bar_height)), Color.BLACK)
	
	# Progression
	var progress = magic_accumulated / get_evolution_threshold() if can_evolve() else 0.0
	var fill_width = bar_width * progress
	draw_rect(Rect2(bar_pos, Vector2(fill_width, bar_height)), Color.CYAN)
	
	# Texte
	var info_text = "Stage " + str(current_evolution_stage) + " | Obs: " + str(observation_count)
	draw_string(ThemeDB.fallback_font, bar_pos + Vector2(0, -5), info_text, 
		HORIZONTAL_ALIGNMENT_CENTER, bar_width, 12)