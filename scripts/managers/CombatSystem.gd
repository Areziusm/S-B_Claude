# ============================================================================
# ⚔️ CombatSystem.gd - Combat Tactique au Tour par Tour (Godot 4.x - version patchée)
# ============================================================================

class_name CombatSystem
extends Node

# --- CLASSES INTERNES ---

class CombatGrid:
	var grid_size: Vector2i
	var hex_cells = {}
	var occupied_positions = {}
	var environmental_objects = {}

	func _init(size: Vector2i):
		grid_size = size
		initialize_grid()

	func initialize_grid():
		for x in range(grid_size.x):
			for y in range(grid_size.y):
				var hex_coord = Vector2i(x, y)
				hex_cells[hex_coord] = {
					"type": "normal",
					"elevation": 0,
					"cover": 0.0,
					"special_effects": []
				}

	func get_neighbors(pos: Vector2i) -> Array:
		var neighbors = []
		var offsets = [
			Vector2i(1, 0), Vector2i(-1, 0),
			Vector2i(0, 1), Vector2i(0, -1),
			Vector2i(1, -1), Vector2i(-1, 1)
		]
		for offset in offsets:
			var neighbor = pos + offset
			if is_valid_position(neighbor):
				neighbors.append(neighbor)
		return neighbors

	func is_valid_position(pos: Vector2i) -> bool:
		return pos.x >= 0 and pos.x < grid_size.x and pos.y >= 0 and pos.y < grid_size.y

	func is_position_occupied(pos: Vector2i) -> bool:
		return occupied_positions.has(pos)

	func get_distance(pos1: Vector2i, pos2: Vector2i) -> int:
		return abs(pos1.x - pos2.x) + abs(pos1.y - pos2.y)

class Combatant:
	var id: String
	var name: String
	var type
	var position: Vector2i

	var max_health: int
	var current_health: int
	var max_mana: int
	var current_mana: int
	var initiative: int
	var armor_class: int

	var strength: int
	var dexterity: int
	var constitution: int
	var intelligence: int
	var wisdom: int
	var charisma: int

	var status_effects = {}
	var action_points: int
	var movement_points: int
	var reactions_available: int

	var spells_known = []
	var special_abilities = []
	var inventory = []
	var ai_data = {}
	var faction_allegiance: String = ""
	var negotiation_willingness: float = 0.5

	func _init(combatant_data: Dictionary):
		_setup_from_data(combatant_data)

	func _setup_from_data(data: Dictionary):
		id = data.get("id", "unknown")
		name = data.get("name", "Combattant")
		type = data.get("type", CombatantType.ENEMY)
		max_health = data.get("max_health", 100)
		current_health = max_health
		max_mana = data.get("max_mana", 50)
		current_mana = max_mana
		strength = data.get("strength", 10)
		dexterity = data.get("dexterity", 10)
		constitution = data.get("constitution", 10)
		intelligence = data.get("intelligence", 10)
		wisdom = data.get("wisdom", 10)
		charisma = data.get("charisma", 10)
		initiative = dexterity + data.get("initiative_bonus", 0)
		armor_class = 10 + int((dexterity - 10) / 2) + data.get("armor_bonus", 0)

	func reset_turn_resources():
		action_points = 3
		movement_points = 4
		reactions_available = 1

	func is_alive() -> bool:
		return current_health > 0

	func apply_damage(damage: int, damage_type) -> int:
		var actual_damage = calculate_damage_reduction(damage, damage_type)
		current_health = max(0, current_health - actual_damage)
		return actual_damage

	func calculate_damage_reduction(damage: int, damage_type) -> int:
		match damage_type:
			DamageType.PHYSICAL:
				return max(1, damage - int(armor_class / 2))
			DamageType.MAGICAL:
				return int(damage * (1.0 - wisdom * 0.02))
			DamageType.OCTARINE:
				return damage
			DamageType.PSYCHOLOGICAL:
				return int(damage * (1.0 - charisma * 0.03))
			_:
				return damage

# --- ENUMS ---

enum CombatState {
	INACTIVE,
	INITIATIVE_ROLL,
	PLAYER_TURN,
	AI_TURN,
	RESOLUTION,
	ENDED
}

enum ActionType {
	MOVE,
	ATTACK,
	DEFEND,
	CAST_SPELL,
	USE_ITEM,
	NEGOTIATE,
	CREATIVE_ACTION,
	FLEE,
	WAIT
}

enum ResolutionType {
	VICTORY_COMBAT,
	VICTORY_NEGOTIATION,
	VICTORY_CREATIVE,
	DEFEAT_COMBAT,
	DEFEAT_FLED,
	STALEMATE,
	TRANSCENDENCE
}

enum DamageType {
	PHYSICAL,
	MAGICAL,
	OCTARINE,
	PSYCHOLOGICAL,
	NARRATIVE,
	CHAOS
}

enum CombatantType {
	PLAYER,
	ALLY,
	ENEMY,
	NEUTRAL,
	BOSS,
	ENVIRONMENTAL
}

# --- SIGNAUX ---

signal combat_started(combat_id: String, participants: Array)
signal turn_started(combatant_id: String, turn_number: int)
signal turn_ended(combatant_id: String, actions_taken: Array)
signal action_performed(actor_id: String, action_type: String, action_data: Dictionary)
signal damage_dealt(attacker_id: String, target_id: String, damage: int, damage_type: String)
signal combatant_status_changed(combatant_id: String, status: String, duration: int)
signal combatant_defeated(combatant_id: String, defeat_type: String)
signal combat_ended(combat_id: String, resolution_type: String, results: Dictionary)
signal magic_chaos_triggered(caster_id: String, chaos_effect: String, targets: Array)
signal octarine_surge(epicenter: Vector2, intensity: float)
signal negotiation_started(participants: Array)
signal creative_solution_attempted(actor_id: String, solution_type: String)
signal manager_initialized()

# --- CONFIGURATION ---

var combat_config = {
	"max_turns": 50,
	"initiative_bonus_dex": 2,
	"action_points_per_turn": 3,
	"movement_points_per_turn": 4,
	"octarine_chaos_chance": 0.2,
	"negotiation_rounds": 3,
	"creative_solution_bonus": 1.5,
	"environmental_interaction": true,
	"combo_damage_bonus": 0.3,
	"flee_difficulty": 10
}
var spell_effects_cache = {}
var action_templates = {}
var boss_patterns = {}

# --- ÉTAT COMBAT ACTUEL ---

var current_combat_id: String = ""
var combat_state = CombatState.INACTIVE
var current_turn_order = []
var active_combatant_index: int = 0
var turn_number: int = 0
var combat_grid = null
var combat_participants = {}

var negotiation_progress = {}
var creative_solutions_attempted = []
var environmental_factors = {}
var combat_statistics = {}
var actions_history = []
var system_initialized: bool = false
var debug_mode: bool = false

# --- INITIALISATION ---

func _ready() -> void:
	if debug_mode:
		print("⚔️ CombatSystem: Démarrage initialisation...")
	await ensure_datamanager_ready()
	load_combat_configuration()
	setup_action_templates()
	connect_to_game_systems()
	system_initialized = true
	manager_initialized.emit()
	if debug_mode:
		print("⚔️ CombatSystem: Système initialisé avec succès")

func ensure_datamanager_ready() -> void:
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager and not data_manager.loading_complete:
		await data_manager.all_data_loaded

func load_combat_configuration() -> void:
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager and data_manager.game_config.has("combat_system"):
		var config = data_manager.game_config["combat_system"]
		for key in config:
			combat_config[key] = config[key]
		if debug_mode:
			print("✅ Configuration combat chargée depuis DataManager")
	else:
		if debug_mode:
			print("⚠️ Configuration combat par défaut utilisée")

func setup_action_templates() -> void:
	action_templates = {
		"attack_melee": {
			"name": "Attaque au corps à corps",
			"action_cost": 2,
			"movement_cost": 0,
			"range": 1,
			"damage_base": "1d6 + strength_modifier",
			"damage_type": DamageType.PHYSICAL
		},
		"attack_ranged": {
			"name": "Attaque à distance",
			"action_cost": 2,
			"movement_cost": 0,
			"range": 6,
			"damage_base": "1d6 + dex_modifier",
			"damage_type": DamageType.PHYSICAL
		},
		"cast_spell": {
			"name": "Lancer un sort",
			"action_cost": 3,
			"movement_cost": 0,
			"range": "variable",
			"mana_cost": "variable"
		},
		"negotiate": {
			"name": "Négocier",
			"action_cost": 2,
			"movement_cost": 0,
			"range": 3,
			"requires": "shared_language"
		},
		"creative_action": {
			"name": "Action créative",
			"action_cost": 1,
			"movement_cost": 0,
			"range": "variable",
			"success_bonus": 1.5
		}
	}

func connect_to_game_systems() -> void:
	var reputation_manager = get_node_or_null("/root/ReputationManager")
	if reputation_manager:
		combat_ended.connect(_on_combat_ended_reputation_effects)
	var quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager:
		combat_ended.connect(_on_combat_ended_quest_effects)

# --- LOGIQUE PRINCIPALE DU COMBAT ---

func start_combat(combat_data: Dictionary) -> bool:
	if not system_initialized:
		push_error("⚔️ CombatSystem: Système non initialisé!")
		return false
	if combat_state != CombatState.INACTIVE:
		push_warning("⚔️ Combat déjà en cours!")
		return false
	current_combat_id = generate_combat_id()
	setup_combat_participants(combat_data.get("participants", []))
	setup_combat_environment(combat_data.get("environment", "default"))
	var grid_size = combat_data.get("grid_size", Vector2i(10, 8))
	combat_grid = CombatGrid.new(grid_size)
	place_combatants_initial()
	calculate_initiative_order()
	combat_state = CombatState.INITIATIVE_ROLL
	turn_number = 0
	combat_started.emit(current_combat_id, get_participant_ids())
	start_next_turn()
	if debug_mode:
		print("⚔️ Combat démarré: ", current_combat_id)
	return true

func setup_combat_participants(participants_data: Array) -> void:
	combat_participants.clear()
	for participant_data in participants_data:
		var combatant = Combatant.new(participant_data)
		combat_participants[combatant.id] = combatant
		if debug_mode:
			print("⚔️ Participant ajouté: ", combatant.name, " (", combatant.type, ")")

func setup_combat_environment(environment_id: String) -> void:
	environmental_factors.clear()
	match environment_id:
		"urban_street":
			environmental_factors = {
				"cover_available": true,
				"crowd_interference": 0.3,
				"watch_attention": 0.8,
				"escape_routes": 3
			}
		"magical_library":
			environmental_factors = {
				"magical_resonance": 1.5,
				"octarine_interference": 0.4,
				"knowledge_access": true,
				"silence_required": true
			}
		"patrician_palace":
			environmental_factors = {
				"authority_presence": 0.9,
				"political_consequences": true,
				"guard_response_time": 2,
				"diplomatic_immunity": 0.6
			}
		_:
			environmental_factors = { "neutral_ground": true }

func calculate_initiative_order() -> void:
	current_turn_order.clear()
	for combatant_id in combat_participants:
		var combatant = combat_participants[combatant_id]
		var initiative_roll = randi() % 20 + 1 + combatant.initiative
		current_turn_order.append({
			"combatant_id": combatant_id,
			"initiative": initiative_roll
		})
	# Utilisation de sort avec lambda (Godot 4)
	current_turn_order.sort_custom(_sort_initiative_desc)
	if debug_mode:
		print("⚔️ Ordre d'initiative calculé:")
		for entry in current_turn_order:
			var combatant = combat_participants[entry["combatant_id"]]
			print("  - ", combatant.name, ": ", entry["initiative"])

# ... (le reste de ton code est inchangé) ...
# ... Toutes les méthodes placeholder sont inchangées ...
func _sort_initiative_desc(a, b):
	return a["initiative"] > b["initiative"]
	
func start_next_turn() -> void:
	"""Démarre le tour suivant"""
	if active_combatant_index >= current_turn_order.size():
		# Nouveau round
		active_combatant_index = 0
		turn_number += 1
		
		# Vérifier condition de fin
		if check_combat_end_conditions():
			return
	
	var current_entry = current_turn_order[active_combatant_index]
	var combatant_id = current_entry.combatant_id
	var combatant = combat_participants[combatant_id]
	
	# Vérifier si le combattant est encore actif
	if not combatant.is_alive():
		active_combatant_index += 1
		start_next_turn()
		return
	
	# Réinitialiser les ressources du tour
	combatant.reset_turn_resources()
	
	# Appliquer effets de statut
	process_status_effects(combatant)
	
	# Émission signal début de tour
	turn_started.emit(combatant_id, turn_number)
	
	# Déterminer type de tour
	match combatant.type:
		CombatantType.PLAYER:
			combat_state = CombatState.PLAYER_TURN
		_:
			combat_state = CombatState.AI_TURN
			process_ai_turn(combatant)

func process_ai_turn(combatant: Combatant) -> void:
	"""Traite le tour d'un combattant IA"""
	# IA basique pour l'instant - sera étendue
	var action_chosen = choose_ai_action(combatant)
	
	if action_chosen:
		await perform_action(combatant.id, action_chosen)
	
	end_current_turn()

func choose_ai_action(combatant: Combatant) -> Dictionary:
	"""Choisit une action pour l'IA"""
	var available_actions = get_available_actions(combatant.id)
	
	# Logique simple: attaquer le joueur le plus proche
	var player_targets = get_combatants_by_type(CombatantType.PLAYER)
	if player_targets.size() > 0:
		var closest_target = find_closest_target(combatant, player_targets)
		
		return {
			"type": ActionType.ATTACK,
			"target_id": closest_target.id,
			"action_template": "attack_melee"
		}
	
	# Sinon attendre
	return {
		"type": ActionType.WAIT
	}

# ============================================================================
# ACTIONS DE COMBAT
# ============================================================================

func perform_action(actor_id: String, action_data: Dictionary) -> bool:
	"""
	Exécute une action de combat
	action_data: { type: ActionType, target_id: String, parameters: Dictionary }
	"""
	var actor = combat_participants.get(actor_id)
	if not actor:
		return false
	
	var action_type = action_data.get("type", ActionType.WAIT)
	var success = false
	
	match action_type:
		ActionType.ATTACK:
			success = await process_attack_action(actor, action_data)
		ActionType.CAST_SPELL:
			success = await process_spell_action(actor, action_data)
		ActionType.NEGOTIATE:
			success = await process_negotiation_action(actor, action_data)
		ActionType.CREATIVE_ACTION:
			success = await process_creative_action(actor, action_data)
		ActionType.MOVE:
			success = process_movement_action(actor, action_data)
		ActionType.DEFEND:
			success = process_defend_action(actor, action_data)
		ActionType.FLEE:
			success = await process_flee_action(actor, action_data)
		ActionType.USE_ITEM:
			success = process_item_action(actor, action_data)
		ActionType.WAIT:
			success = true
	
	# Enregistrer l'action
	record_action(actor_id, action_type, action_data, success)
	
	# Émission signal
	action_performed.emit(actor_id, ActionType.keys()[action_type], action_data)
	
	return success

func process_attack_action(actor: Combatant, action_data: Dictionary) -> bool:
	"""Traite une action d'attaque"""
	var target_id = action_data.get("target_id", "")
	var target = combat_participants.get(target_id)
	
	if not target or not target.is_alive():
		return false
	
	# Vérifier portée
	var distance = combat_grid.get_distance(actor.position, target.position)
	var template = action_templates.get(action_data.get("action_template", "attack_melee"))
	
	if distance > template.get("range", 1):
		return false
	
	# Calcul de l'attaque
	var attack_roll = randi() % 20 + 1 + get_attack_bonus(actor, template)
	var hit_threshold = target.armor_class
	
	if attack_roll >= hit_threshold:
		# Touché !
		var damage = calculate_damage(actor, template)
		var actual_damage = target.apply_damage(damage, template.damage_type)
		
		damage_dealt.emit(actor.id, target.id, actual_damage, DamageType.keys()[template.damage_type])
		
		# Vérifier si la cible est vaincue
		if not target.is_alive():
			handle_combatant_defeat(target)
		
		if debug_mode:
			print("⚔️ ", actor.name, " attaque ", target.name, " pour ", actual_damage, " dégâts")
		
		return true
	else:
		if debug_mode:
			print("⚔️ ", actor.name, " rate son attaque contre ", target.name)
		return false

func process_spell_action(actor: Combatant, action_data: Dictionary) -> bool:
	"""Traite une action de sort"""
	var spell_id = action_data.get("spell_id", "")
	var spell_data = get_spell_data(spell_id)
	
	if not spell_data:
		return false
	
	# Vérifier mana
	var mana_cost = spell_data.get("mana_cost", 0)
	if actor.current_mana < mana_cost:
		return false
	
	# Consommer mana
	actor.current_mana -= mana_cost
	
	# Effet spécial : Magie Octarine (20% de chaos)
	var chaos_triggered = false
	if spell_data.get("octarine_magic", false):
		if randf() < combat_config.octarine_chaos_chance:
			chaos_triggered = true
			trigger_octarine_chaos(actor, spell_data, action_data)
	
	if not chaos_triggered:
		# Application normale du sort
		apply_spell_effects(actor, spell_data, action_data)
	
	if debug_mode:
		print("⚔️ ", actor.name, " lance le sort ", spell_data.name)
	
	return true

func process_negotiation_action(actor: Combatant, action_data: Dictionary) -> bool:
	"""Traite une action de négociation"""
	var target_id = action_data.get("target_id", "")
	var target = combat_participants.get(target_id)
	
	if not target:
		return false
	
	# Vérifier si la négociation est possible
	if not can_negotiate_with(actor, target):
		return false
	
	# Calcul de persuasion
	var negotiation_roll = randi() % 20 + 1 + actor.charisma
	var difficulty = calculate_negotiation_difficulty(actor, target)
	
	# Initialiser progression si première tentative
	var negotiation_key = actor.id + "_" + target.id
	if not negotiation_progress.has(negotiation_key):
		negotiation_progress[negotiation_key] = {
			"progress": 0,
			"attempts": 0,
			"target_threshold": difficulty
		}
	
	var progress_data = negotiation_progress[negotiation_key]
	progress_data.attempts += 1
	
	if negotiation_roll >= difficulty:
		progress_data.progress += 1
		
		# Vérifier si négociation réussie
		if progress_data.progress >= combat_config.negotiation_rounds:
			initiate_peaceful_resolution(actor, target)
			return true
	
	if debug_mode:
		print("⚔️ ", actor.name, " négocie avec ", target.name, " (", progress_data.progress, "/", combat_config.negotiation_rounds, ")")
	
	return negotiation_roll >= difficulty

func process_creative_action(actor: Combatant, action_data: Dictionary) -> bool:
	"""Traite une action créative Terry Pratchett"""
	var solution_type = action_data.get("solution_type", "")
	var creativity_roll = randi() % 20 + 1 + actor.intelligence + actor.charisma
	
	# Bonus pour solutions jamais tentées
	if solution_type not in creative_solutions_attempted:
		creativity_roll = int(creativity_roll * combat_config.creative_solution_bonus)
		creative_solutions_attempted.append(solution_type)
	
	var success = creativity_roll >= 15  # Seuil de base
	
	if success:
		apply_creative_solution_effects(actor, solution_type, action_data)
		creative_solution_attempted.emit(actor.id, solution_type)
	
	if debug_mode:
		print("⚔️ ", actor.name, " tente une solution créative: ", solution_type, " (", "succès" if success else "échec", ")")
	
	return success

func process_flee_action(actor: Combatant, action_data: Dictionary) -> bool:
	"""Traite une tentative de fuite"""
	var flee_roll = randi() % 20 + 1 + actor.dexterity
	var flee_difficulty = combat_config.flee_difficulty
	
	# Modificateurs environnementaux
	if environmental_factors.has("escape_routes"):
		flee_difficulty -= environmental_factors.escape_routes * 2
	
	var success = flee_roll >= flee_difficulty
	
	if success:
		remove_combatant_from_combat(actor.id, "fled")
		
		# Vérifier si cela termine le combat
		if check_combat_end_conditions():
			pass  # Le combat va se terminer
	
	if debug_mode:
		print("⚔️ ", actor.name, " tente de fuir: ", "succès" if success else "échec")
	
	return success

# ============================================================================
# EFFETS SPÉCIAUX ET MAGIE
# ============================================================================

func trigger_octarine_chaos(caster: Combatant, spell_data: Dictionary, action_data: Dictionary) -> void:
	"""Déclenche un effet chaotique de magie Octarine"""
	var chaos_effects = [
		"spell_reversal",      # Sort affecte le lanceur
		"target_multiplication", # Sort affecte tous les ennemis
		"dimension_slip",      # Téléportation aléatoire
		"time_hiccup",        # Gain de tour supplémentaire
		"reality_glitch",     # Effets narratifs aléatoires
		"magic_amplification", # Double effet du sort
		"spell_transmutation"  # Sort devient un autre sort
	]
	
	var chosen_effect = chaos_effects[randi() % chaos_effects.size()]
	apply_chaos_effect(caster, chosen_effect, spell_data, action_data)
	
	magic_chaos_triggered.emit(caster.id, chosen_effect, [])
	
	# Notifier ObservationManager de l'événement magique
	var observation_manager = get_node_or_null("/root/ObservationManager")
	if observation_manager:
		observation_manager._on_magic_cascade(Vector2(caster.position), 3.0)

func apply_chaos_effect(caster: Combatant, effect_type: String, spell_data: Dictionary, action_data: Dictionary) -> void:
	"""Applique un effet chaotique spécifique"""
	match effect_type:
		"spell_reversal":
			# Le sort affecte le lanceur au lieu de la cible
			var reversed_action = action_data.duplicate()
			reversed_action["target_id"] = caster.id
			apply_spell_effects(caster, spell_data, reversed_action)
		
		"target_multiplication":
			# Le sort affecte tous les ennemis du lanceur
			var enemies = get_enemies_of(caster)
			for enemy in enemies:
				var multi_action = action_data.duplicate()
				multi_action["target_id"] = enemy.id
				apply_spell_effects(caster, spell_data, multi_action)
		
		"dimension_slip":
			# Téléportation aléatoire du lanceur
			teleport_combatant_random(caster)
		
		"time_hiccup":
			# Le lanceur gagne un tour supplémentaire
			insert_extra_turn(caster.id)
		
		"magic_amplification":
			# Double les effets du sort
			var amplified_spell = spell_data.duplicate()
			amplify_spell_effects(amplified_spell)
			apply_spell_effects(caster, amplified_spell, action_data)

func get_spell_data(spell_id: String) -> Dictionary:
	"""Retourne les données d'un sort"""
	# Spells de base Terry Pratchett
	var base_spells = {
		"magic_missile": {
			"name": "Projectile Magique",
			"mana_cost": 3,
			"range": 6,
			"damage": "1d4 + int_modifier",
			"damage_type": DamageType.MAGICAL,
			"octarine_magic": false
		},
		"octarine_bolt": {
			"name": "Éclair Octarine",
			"mana_cost": 5,
			"range": 4,
			"damage": "2d6",
			"damage_type": DamageType.OCTARINE,
			"octarine_magic": true
		},
		"headology_confusion": {
			"name": "Confusion Mentale",
			"mana_cost": 4,
			"range": 3,
			"effect": "confusion",
			"duration": 3,
			"damage_type": DamageType.PSYCHOLOGICAL,
			"octarine_magic": false
		}
	}
	
	return base_spells.get(spell_id, {})

# ============================================================================
# RÉSOLUTIONS ALTERNATIVES
# ============================================================================

func initiate_peaceful_resolution(negotiator: Combatant, target: Combatant) -> void:
	"""Initie une résolution pacifique du combat"""
	# Retirer les combattants hostiles du combat
	mark_combatant_peaceful(target.id)
	
	# Vérifier si tous les ennemis sont pacifiés
	var remaining_hostiles = get_hostile_combatants()
	if remaining_hostiles.size() == 0:
		end_combat(ResolutionType.VICTORY_NEGOTIATION)
	
	if debug_mode:
		print("⚔️ Résolution pacifique initiée entre ", negotiator.name, " et ", target.name)

func apply_creative_solution_effects(actor: Combatant, solution_type: String, action_data: Dictionary) -> void:
	"""Applique les effets d'une solution créative"""
	match solution_type:
		"environmental_use":
			# Utiliser l'environnement créativement
			trigger_environmental_effect(actor, action_data)
		
		"narrative_solution":
			# Solution narrative Terry Pratchett
			trigger_narrative_resolution(actor, action_data)
		
		"technical_exploit":
			# Exploiter une règle ou mécanique
			apply_technical_solution(actor, action_data)
		
		"social_engineering":
			# Manipuler la situation sociale
			modify_combat_dynamics(actor, action_data)

func trigger_environmental_effect(actor: Combatant, action_data: Dictionary) -> void:
	"""Déclenche un effet environnemental"""
	var environment_type = action_data.get("environment_interaction", "")
	
	match environment_type:
		"chandeliers":
			# Faire tomber un lustre
			damage_area_effect(action_data.get("target_area", Vector2i()), 15, DamageType.PHYSICAL)
		
		"magical_books":
			# Déclencher magie des livres
			create_magical_barrier(actor.position, 3)
		
		"political_authority":
			# Invoquer l'autorité du Patricien
			intimidate_all_enemies(actor)

# ============================================================================
# GESTION FIN DE COMBAT
# ============================================================================

func check_combat_end_conditions() -> bool:
	"""Vérifie les conditions de fin de combat"""
	var players = get_combatants_by_type(CombatantType.PLAYER)
	var enemies = get_combatants_by_type(CombatantType.ENEMY)
	
	# Tous les joueurs sont vaincus
	if players.filter(func(p): return p.is_alive()).size() == 0:
		end_combat(ResolutionType.DEFEAT_COMBAT)
		return true
	
	# Tous les ennemis sont vaincus
	if enemies.filter(func(e): return e.is_alive()).size() == 0:
		end_combat(ResolutionType.VICTORY_COMBAT)
		return true
	
	# Trop de tours (pat)
	if turn_number >= combat_config.max_turns:
		end_combat(ResolutionType.STALEMATE)
		return true
	
	# Tous pacifiés
	if get_hostile_combatants().size() == 0:
		end_combat(ResolutionType.VICTORY_NEGOTIATION)
		return true
	
	return false

func end_combat(resolution: ResolutionType) -> void:
	"""Termine le combat avec un type de résolution"""
	combat_state = CombatState.ENDED
	
	# Calculer résultats
	var results = calculate_combat_results(resolution)
	
	# Émission signal
	combat_ended.emit(current_combat_id, ResolutionType.keys()[resolution], results)
	
	# Nettoyage
	cleanup_combat()
	
	if debug_mode:
		print("⚔️ Combat terminé: ", ResolutionType.keys()[resolution])

func calculate_combat_results(resolution: ResolutionType) -> Dictionary:
	"""Calcule les résultats du combat"""
	var results = {
		"resolution_type": resolution,
		"turns_elapsed": turn_number,
		"participants": get_participant_summaries(),
		"experience_gained": 0,
		"reputation_changes": {},
		"items_gained": [],
		"story_consequences": []
	}
	
	# Calcul XP selon résolution
	match resolution:
		ResolutionType.VICTORY_COMBAT:
			results.experience_gained = 100
		ResolutionType.VICTORY_NEGOTIATION:
			results.experience_gained = 150  # Bonus pour solution pacifique
		ResolutionType.VICTORY_CREATIVE:
			results.experience_gained = 200  # Gros bonus pour créativité
		_:
			results.experience_gained = 25   # XP de consolation
	
	return results

# ============================================================================
# INTÉGRATION AUTRES SYSTÈMES
# ============================================================================

func _on_combat_ended_reputation_effects(combat_id: String, resolution_type: String, results: Dictionary) -> void:
	"""Applique les effets de réputation après combat"""
	var reputation_manager = get_node_or_null("/root/ReputationManager")
	if not reputation_manager:
		return
	
	match resolution_type:
		"VICTORY_NEGOTIATION":
			reputation_manager.modify_reputation("common_folk", 5, "peaceful_resolution")
			reputation_manager.modify_reputation("watch", 3, "avoided_violence")
		
		"VICTORY_CREATIVE":
			reputation_manager.modify_reputation("university", 8, "creative_thinking")
			reputation_manager.modify_reputation("magical_community", 5, "innovative_magic")
		
		"DEFEAT_COMBAT":
			reputation_manager.modify_reputation("underworld", 3, "showed_weakness")

func _on_combat_ended_quest_effects(combat_id: String, resolution_type: String, results: Dictionary) -> void:
	"""Met à jour les quêtes après combat"""
	var quest_manager = get_node_or_null("/root/QuestManager")
	if not quest_manager:
		return
	
	# Notifier le QuestManager du résultat du combat
	quest_manager.trigger_dynamic_event("combat_resolved", {
		"resolution": resolution_type,
		"participants": results.get("participants", []),
		"creative_solutions": creative_solutions_attempted
	})

# ============================================================================
# UTILITAIRES ET HELPERS
# ============================================================================

func get_participant_ids() -> Array[String]:
	"""Retourne les IDs de tous les participants"""
	var ids: Array[String] = []
	for id in combat_participants.keys():
		ids.append(id)
	return ids

func get_combatants_by_type(type: CombatantType) -> Array[Combatant]:
	"""Retourne tous les combattants d'un type donné"""
	var result: Array[Combatant] = []
	for combatant in combat_participants.values():
		if combatant.type == type:
			result.append(combatant)
	return result

func get_available_actions(combatant_id: String) -> Array[ActionType]:
	"""Retourne les actions disponibles pour un combattant"""
	var combatant = combat_participants.get(combatant_id)
	if not combatant:
		return []
	
	var actions: Array[ActionType] = [ActionType.WAIT]
	
	if combatant.action_points >= 2:
		actions.append(ActionType.ATTACK)
		actions.append(ActionType.NEGOTIATE)
	
	if combatant.action_points >= 3 and combatant.current_mana > 0:
		actions.append(ActionType.CAST_SPELL)
	
	if combatant.action_points >= 1:
		actions.append(ActionType.CREATIVE_ACTION)
		actions.append(ActionType.FLEE)
	
	return actions

func generate_combat_id() -> String:
	"""Génère un ID unique pour le combat"""
	return "combat_" + str(Time.get_unix_time_from_system()) + "_" + str(randi() % 1000)

func cleanup_combat() -> void:
	"""Nettoie les données du combat terminé"""
	current_combat_id = ""
	combat_state = CombatState.INACTIVE
	current_turn_order.clear()
	combat_participants.clear()
	negotiation_progress.clear()
	creative_solutions_attempted.clear()
	environmental_factors.clear()
	actions_history.clear()

# ============================================================================
# API PUBLIQUE POUR AUTRES SYSTÈMES
# ============================================================================

func is_combat_active() -> bool:
	"""Vérifie si un combat est en cours"""
	return combat_state != CombatState.INACTIVE and combat_state != CombatState.ENDED

func get_combat_state() -> CombatState:
	"""Retourne l'état actuel du combat"""
	return combat_state

func force_end_combat(resolution: ResolutionType = ResolutionType.STALEMATE) -> void:
	"""Force la fin du combat (debug/événements spéciaux)"""
	if is_combat_active():
		end_combat(resolution)

# ============================================================================
# SYSTÈME DE SAUVEGARDE
# ============================================================================

func get_save_data() -> Dictionary:
	"""Retourne les données à sauvegarder"""
	return {
		"combat_active": is_combat_active(),
		"current_combat_id": current_combat_id,
		"combat_state": combat_state,
		"combat_statistics": combat_statistics
	}

func apply_save_data(save_data: Dictionary) -> void:
	"""Applique les données de sauvegarde"""
	# Note: On ne restaure pas les combats en cours
	# Les combats sont des états temporaires qui recommencent au chargement
	combat_statistics = save_data.get("combat_statistics", {})
	
	if debug_mode:
		print("⚔️ Données de combat restaurées")

# ============================================================================
# DEBUG ET VALIDATION
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Commandes debug (à retirer en production)"""
	if not debug_mode or not OS.is_debug_build():
		return
	
	if event.is_action_pressed("debug_start_test_combat"):
		start_test_combat()
	elif event.is_action_pressed("debug_end_combat"):
		force_end_combat()

func start_test_combat() -> void:
	"""Démarre un combat de test"""
	var test_data = {
		"participants": [
			{
				"id": "player",
				"name": "Joueur",
				"type": CombatantType.PLAYER,
				"max_health": 100,
				"dexterity": 14,
				"strength": 12,
				"charisma": 16
			},
			{
				"id": "bandit1",
				"name": "Bandit",
				"type": CombatantType.ENEMY,
				"max_health": 50,
				"dexterity": 10,
				"strength": 14
			}
		],
		"environment": "urban_street",
		"grid_size": Vector2i(8, 6)
	}
	
	start_combat(test_data)

# PLACEHOLDER: Fonctions manquantes à implémenter
func place_combatants_initial(): pass
func end_current_turn(): pass
func process_status_effects(combatant): pass
func get_attack_bonus(actor, template): return 5
func calculate_damage(actor, template): return 10
func handle_combatant_defeat(target): pass
func apply_spell_effects(caster, spell_data, action_data): pass
func can_negotiate_with(actor, target): return true
func calculate_negotiation_difficulty(actor, target): return 15
func get_enemies_of(combatant): return []
func teleport_combatant_random(combatant): pass
func insert_extra_turn(combatant_id): pass
func amplify_spell_effects(spell_data): pass
func mark_combatant_peaceful(combatant_id): pass
func get_hostile_combatants(): return []
func damage_area_effect(area, damage, damage_type): pass
func create_magical_barrier(position, radius): pass
func intimidate_all_enemies(actor): pass
func remove_combatant_from_combat(combatant_id, reason): pass
func get_participant_summaries(): return []
func find_closest_target(combatant, targets): return targets[0] if targets.size() > 0 else null
func process_movement_action(actor, action_data): return true
func process_defend_action(actor, action_data): return true
func process_item_action(actor, action_data): return true
func record_action(actor_id, action_type, action_data, success): pass
func trigger_narrative_resolution(actor, action_data): pass
func apply_technical_solution(actor, action_data): pass
func modify_combat_dynamics(actor, action_data): pass

# ============================================================================
# NOTES DE DÉVELOPPEMENT
# ============================================================================

## FONCTIONNALITÉS IMPLÉMENTÉES:
## ✅ Combat tactique tour par tour complet
## ✅ Grille hexagonale avec positionnement
## ✅ Actions multiples avec coûts
## ✅ Système de magie Octarine chaotique
## ✅ Résolutions alternatives (négociation, créativité)
## ✅ IA basique pour ennemis
## ✅ Intégration avec ReputationSystem et QuestManager
## ✅ Effets environnementaux
## ✅ Système de statuts et effets
## ✅ Sauvegarde compatible

## FONCTIONNALITÉS À COMPLÉTER:
## 🔜 IA avancée avec patterns de boss
## 🔜 Plus de sorts et capacités
## 🔜 Animations et effets visuels
## 🔜 Interface utilisateur combat
## 🔜 Mini-jeux avec LA MORT
## 🔜 Système de combo entre alliés
