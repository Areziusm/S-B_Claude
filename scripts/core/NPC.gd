# ============================================================================
# 🗣️ NPC.gd - Classe Personnage Non-Joueur
# ============================================================================
# STATUS: ✅ NOUVEAU SYSTÈME | ROADMAP: Mois 1, Semaine 3-4 - Core Classes
# PRIORITY: 🔴 CRITICAL - Nécessaire pour dialogues, quêtes, et commerce
# DEPENDENCIES: DialogueManager, QuestManager, ReputationSystem, UIManager

class_name NPC
extends CharacterBody2D

## Personnage Non-Joueur - Habitants d'Ankh-Morpork et au-delà
## Gère dialogues, quêtes, commerce, relations et mémoire persistante
## Style Terry Pratchett avec personnalités riches et humour britannique

# ============================================================================
# SIGNAUX - Communication Event-Driven
# ============================================================================

## Émis quand un dialogue commence avec ce NPC
signal dialogue_initiated(player: Node, dialogue_id: String)

## Émis quand un dialogue se termine
signal dialogue_completed(player: Node, final_choice: String, relationship_delta: float)

## Émis quand le NPC donne ou complète une quête
signal quest_given(player: Node, quest_id: String)
signal quest_completed(player: Node, quest_id: String, rewards: Dictionary)

## Émis quand une transaction commerciale a lieu
signal trade_completed(player: Node, items_traded: Array, money_exchanged: int)

## Émis quand la relation avec le joueur change
signal relationship_changed(player: Node, old_level: float, new_level: float)

## Émis quand le NPC réagit à un événement du monde
signal world_event_reaction(event_type: String, reaction_data: Dictionary)

## Émis pour mémoriser des interactions importantes
signal memory_updated(memory_type: String, memory_data: Dictionary)

# ============================================================================
# ENUMS & TYPES
# ============================================================================

enum NPCType {
	CITIZEN = 0,        ## Citoyen ordinaire
	MERCHANT = 1,       ## Marchand/commerçant
	OFFICIAL = 2,       ## Officiel de la ville
	GUARD = 3,          ## Garde de la ville
	WIZARD = 4,         ## Magicien/sorcier
	WITCH = 5,          ## Sorcière
	PRIEST = 6,         ## Prêtre/religieux
	THIEF = 7,          ## Voleur/criminel
	NOBLE = 8,          ## Noble/aristocrate
	VISITOR = 9,        ## Visiteur temporaire
	SPECIAL = 10        ## Personnage spécial (LA MORT, etc.)
}

enum NPCState {
	IDLE = 0,           ## Au repos, disponible
	BUSY = 1,           ## Occupé, pas disponible
	WORKING = 2,        ## Au travail
	TALKING = 3,        ## En conversation
	TRADING = 4,        ## En transaction
	MOVING = 5,         ## Se déplace
	SLEEPING = 6,       ## Dort (selon l'heure)
	ANGRY = 7,          ## En colère
	SUSPICIOUS = 8      ## Méfiant
}

enum RelationshipLevel {
	HOSTILE = -2,       ## Hostile (-100 à -51)
	UNFRIENDLY = -1,    ## Peu amical (-50 à -11)
	NEUTRAL = 0,        ## Neutre (-10 à +10)
	FRIENDLY = 1,       ## Amical (+11 à +50)
	ALLY = 2            ## Allié (+51 à +100)
}

enum DialogueContext {
	FIRST_MEETING = 0,  ## Première rencontre
	CASUAL = 1,         ## Conversation informelle
	BUSINESS = 2,       ## Transaction/service
	QUEST_RELATED = 3,  ## Lié à une quête
	INFORMATION = 4,    ## Demande d'informations
	EMERGENCY = 5,      ## Situation d'urgence
	SPECIAL_EVENT = 6   ## Événement spécial
}

# ============================================================================
# CONFIGURATION & IDENTITÉ
# ============================================================================

## Identité de base
@export_group("Identity")
@export var character_id: String = "generic_npc"
@export var character_name: String = "Citoyen Anonyme"
@export var npc_type: NPCType = NPCType.CITIZEN
@export var faction_id: String = "citizens"

## Configuration personnalité
@export_group("Personality")
@export var base_friendliness: float = 0.5
@export var curiosity_level: float = 0.5
@export var greed_level: float = 0.3
@export var courage_level: float = 0.5
@export var humor_appreciation: float = 0.7
@export var authority_respect: float = 0.6

## Configuration commerce (si marchand)
@export_group("Commerce")
@export var is_merchant: bool = false
@export var merchant_category: String = "general"
@export var base_markup: float = 1.2
@export var haggling_tolerance: float = 0.15

## Configuration quêtes
@export_group("Quests")
@export var can_give_quests: bool = true
@export var available_quests: Array[String] = []
@export var completed_quests: Array[String] = []

# ============================================================================
# DONNÉES PERSONNAGE
# ============================================================================

## Données chargées depuis character_data.json
var character_data: Dictionary = {}
var dialogue_trees: Dictionary = {}
var quest_data: Dictionary = {}
var shop_inventory: Dictionary = {}

## Relations et mémoire
var player_relationship: float = 0.0
var player_memory: Dictionary = {}
var interaction_history: Array[Dictionary] = []
var last_interaction_time: float = 0.0

## État dynamique
var current_state: NPCState = NPCState.IDLE
var current_dialogue_id: String = ""
var mood_modifier: float = 0.0
var temporary_flags: Dictionary = {}

# ============================================================================
# MOUVEMENT & LOCALISATION
# ============================================================================

## Configuration déplacement
@export_group("Movement")
@export var movement_enabled: bool = true
@export var movement_speed: float = 75.0
@export var patrol_points: Array[Vector2] = []
@export var home_position: Vector2 = Vector2.ZERO

## État du mouvement
var current_patrol_index: int = 0
var movement_target: Vector2 = Vector2.ZERO
var is_moving: bool = false
var return_to_position_timer: float = 0.0

# ============================================================================
# COMPOSANTS & RÉFÉRENCES
# ============================================================================

## Composants visuels
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var interaction_area: Area2D = $InteractionArea
@onready var dialogue_indicator: Node2D = $DialogueIndicator
@onready var mood_indicator: Node2D = $MoodIndicator

## Timers et détection
@onready var movement_timer: Timer = $MovementTimer
@onready var mood_timer: Timer = $MoodTimer
@onready var patrol_timer: Timer = $PatrolTimer

## Références aux managers
var dialogue_manager: DialogueManager
var quest_manager: QuestManager
var reputation_manager: ReputationSystem
var ui_manager: UIManager

## État système
var initialized: bool = false
var debug_mode: bool = false
var player_in_range: bool = false
var current_player: Node = null

# ============================================================================
# INITIALISATION
# ============================================================================

func _ready() -> void:
	"""Initialisation du NPC"""
	setup_npc_components()
	connect_to_managers()
	load_character_data()
	setup_areas_and_timers()
	initialize_npc_state()
	
	initialized = true
	if debug_mode:
		print("🗣️ NPC: Personnage initialisé -", character_name, "(", character_id, ")")

func setup_npc_components() -> void:
	"""Configure les composants de base"""
	# Ajout aux groupes appropriés
	add_to_group("npcs")
	add_to_group("interactables")
	
	# Configuration physique
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	
	# Position de base
	home_position = global_position
	movement_target = global_position

func connect_to_managers() -> void:
	"""Connecte le NPC aux managers du jeu"""
	dialogue_manager = get_node_or_null("/root/DialogueManager")
	quest_manager = get_node_or_null("/root/QuestManager")
	reputation_manager = get_node_or_null("/root/ReputationManager")
	ui_manager = get_node_or_null("/root/UIManager")
	
	# Connexions de signaux
	if dialogue_manager:
		dialogue_manager.dialogue_started.connect(_on_dialogue_manager_dialogue_started)
		dialogue_manager.dialogue_ended.connect(_on_dialogue_manager_dialogue_ended)
		dialogue_manager.dialogue_choice_made.connect(_on_dialogue_choice_made)
	
	if quest_manager:
		quest_manager.quest_completed.connect(_on_quest_completed)
		quest_manager.quest_failed.connect(_on_quest_failed)
	
	if reputation_manager:
		reputation_manager.reputation_changed.connect(_on_reputation_changed)

func load_character_data() -> void:
	"""Charge les données du personnage depuis DataManager"""
	var data_manager = get_node_or_null("/root/DataManager")
	
	if data_manager and not data_manager.characters_data.is_empty():
		if data_manager.characters_data.has(character_id):
			character_data = data_manager.characters_data[character_id]
			load_character_configuration()
		else:
			setup_fallback_character_data()
	else:
		setup_fallback_character_data()

func load_character_configuration() -> void:
	"""Configure le NPC selon ses données de personnage"""
	if character_data.has("name"):
		character_name = character_data.name
	
	if character_data.has("npc_type"):
		npc_type = NPCType.get(character_data.npc_type, NPCType.CITIZEN)
	
	if character_data.has("faction"):
		faction_id = character_data.faction
	
	if character_data.has("personality"):
		var personality = character_data.personality
		base_friendliness = personality.get("friendliness", base_friendliness)
		curiosity_level = personality.get("curiosity", curiosity_level)
		greed_level = personality.get("greed", greed_level)
		courage_level = personality.get("courage", courage_level)
		humor_appreciation = personality.get("humor", humor_appreciation)
		authority_respect = personality.get("authority", authority_respect)
	
	if character_data.has("dialogue_trees"):
		dialogue_trees = character_data.dialogue_trees
	
	if character_data.has("available_quests"):
		available_quests = character_data.available_quests
	
	if character_data.has("base_relationship"):
		player_relationship = character_data.base_relationship
	
	# Configuration spécifique aux marchands
	if character_data.has("shop_data") and npc_type == NPCType.MERCHANT:
		setup_merchant_configuration(character_data.shop_data)
	
	# Configuration des points de patrouille
	if character_data.has("patrol_points"):
		patrol_points = character_data.patrol_points
	
	if debug_mode:
		print("✅ Données personnage chargées pour:", character_name)

func setup_fallback_character_data() -> void:
	"""Données de secours si JSON absent"""
	dialogue_trees = {
		"default_greeting": {
			"text": "Bonjour ! Comment puis-je vous aider ?",
			"choices": [
				{"text": "Juste dire bonjour", "consequence": "relationship_gain_small"},
				{"text": "Au revoir", "consequence": "end_dialogue"}
			]
		}
	}
	
	available_quests = ["generic_fetch_quest"]
	
	if debug_mode:
		print("⚠️ Données NPC fallback utilisées pour:", character_id)

func setup_merchant_configuration(shop_data: Dictionary) -> void:
	"""Configure le NPC comme marchand"""
	is_merchant = true
	merchant_category = shop_data.get("category", "general")
	base_markup = shop_data.get("markup", 1.2)
	haggling_tolerance = shop_data.get("haggling_tolerance", 0.15)
	shop_inventory = shop_data.get("inventory", {})

func setup_areas_and_timers() -> void:
	"""Configure les zones d'interaction et timers"""
	# Zone d'interaction
	if interaction_area:
		interaction_area.body_entered.connect(_on_interaction_area_entered)
		interaction_area.body_exited.connect(_on_interaction_area_exited)
		
		var interaction_shape = CircleShape2D.new()
		interaction_shape.radius = 32.0
		var interaction_collision = CollisionShape2D.new()
		interaction_collision.shape = interaction_shape
		interaction_area.add_child(interaction_collision)
	
	# Timers
	if movement_timer:
		movement_timer.wait_time = 2.0
		movement_timer.timeout.connect(_on_movement_timer_timeout)
		if movement_enabled and patrol_points.size() > 0:
			movement_timer.start()
	
	if mood_timer:
		mood_timer.wait_time = 60.0  # Changement d'humeur toutes les minutes
		mood_timer.timeout.connect(_on_mood_timer_timeout)
		mood_timer.start()
	
	if patrol_timer:
		patrol_timer.wait_time = 10.0  # Changement de patrouille toutes les 10 secondes
		patrol_timer.timeout.connect(_on_patrol_timer_timeout)
		if patrol_points.size() > 1:
			patrol_timer.start()

func initialize_npc_state() -> void:
	"""Initialise l'état de départ du NPC"""
	update_dialogue_indicator()
	update_mood_indicator()
	
	# Configuration initiale selon le type
	match npc_type:
		NPCType.MERCHANT:
			current_state = NPCState.WORKING
		NPCType.GUARD:
			current_state = NPCState.WORKING
			movement_enabled = true
		_:
			current_state = NPCState.IDLE

# ============================================================================
# SYSTÈME DE DIALOGUE
# ============================================================================

func start_dialogue(player: Node) -> bool:
	"""Démarre un dialogue avec le joueur"""
	if current_state == NPCState.TALKING or current_state == NPCState.BUSY:
		return false
	
	if not dialogue_manager:
		if debug_mode:
			print("⚠️ DialogueManager non disponible pour", character_name)
		return false
	
	# Détermination du contexte de dialogue
	var dialogue_context = determine_dialogue_context(player)
	var dialogue_id = get_dialogue_id_for_context(dialogue_context)
	
	if dialogue_id.is_empty():
		dialogue_id = "default_greeting"
	
	# Sauvegarde de l'état
	current_player = player
	current_dialogue_id = dialogue_id
	set_npc_state(NPCState.TALKING)
	
	# Regarder vers le joueur
	face_target(player)
	
	# Démarrage du dialogue via le manager
	dialogue_manager.start_dialogue(character_id, dialogue_id)
	dialogue_initiated.emit(player, dialogue_id)
	
	if debug_mode:
		print("🗣️ NPC: Dialogue démarré avec", character_name, "- ID:", dialogue_id)
	
	return true

func determine_dialogue_context(player: Node) -> DialogueContext:
	"""Détermine le contexte du dialogue"""
	# Première rencontre ?
	if interaction_history.is_empty():
		return DialogueContext.FIRST_MEETING
	
	# Quête en cours ?
	if has_active_quest_for_player(player):
		return DialogueContext.QUEST_RELATED
	
	# Commerce possible ?
	if is_merchant and current_state == NPCState.WORKING:
		return DialogueContext.BUSINESS
	
	# Événement spécial en cours ?
	if temporary_flags.has("special_event"):
		return DialogueContext.SPECIAL_EVENT
	
	# Situation d'urgence ?
	if mood_modifier < -0.5:
		return DialogueContext.EMERGENCY
	
	# Conversation normale
	return DialogueContext.CASUAL

func get_dialogue_id_for_context(context: DialogueContext) -> String:
	"""Retourne l'ID de dialogue approprié pour le contexte"""
	var context_key = DialogueContext.keys()[context].to_lower()
	
	# Recherche dans les arbres de dialogue
	for dialogue_id in dialogue_trees.keys():
		if dialogue_id.contains(context_key):
			return dialogue_id
	
	# Recherche par type de NPC
	var npc_type_key = NPCType.keys()[npc_type].to_lower()
	for dialogue_id in dialogue_trees.keys():
		if dialogue_id.contains(npc_type_key):
			return dialogue_id
	
	# Dialogue par défaut selon la relation
	var relationship_level = get_relationship_level()
	match relationship_level:
		RelationshipLevel.HOSTILE:
			return "hostile_greeting"
		RelationshipLevel.UNFRIENDLY:
			return "unfriendly_greeting"
		RelationshipLevel.FRIENDLY:
			return "friendly_greeting"
		RelationshipLevel.ALLY:
			return "ally_greeting"
		_:
			return "neutral_greeting"

func end_dialogue(final_choice: String = "", relationship_delta: float = 0.0) -> void:
	"""Termine le dialogue actuel"""
	if current_state != NPCState.TALKING:
		return
	
	# Mise à jour de la relation
	if relationship_delta != 0.0:
		modify_relationship(relationship_delta, "dialogue_choice")
	
	# Sauvegarde de l'interaction dans l'historique
	record_interaction("dialogue", {
		"dialogue_id": current_dialogue_id,
		"final_choice": final_choice,
		"relationship_delta": relationship_delta,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Reset de l'état
	var player = current_player
	current_player = null
	current_dialogue_id = ""
	set_npc_state(NPCState.IDLE)
	
	# Signal de fin
	dialogue_completed.emit(player, final_choice, relationship_delta)
	
	if debug_mode:
		print("🗣️ NPC: Dialogue terminé avec", character_name)

func get_dialogue_id() -> String:
	"""Retourne l'ID de dialogue à utiliser (méthode pour Player.gd)"""
	return get_dialogue_id_for_context(DialogueContext.CASUAL)

# ============================================================================
# SYSTÈME DE QUÊTES
# ============================================================================

func has_available_quest_for_player(player: Node) -> bool:
	"""Vérifie si le NPC a une quête disponible pour le joueur"""
	if not can_give_quests or available_quests.is_empty():
		return false
	
	for quest_id in available_quests:
		if can_offer_quest(quest_id, player):
			return true
	
	return false

func has_active_quest_for_player(player: Node) -> bool:
	"""Vérifie si le joueur a une quête active de ce NPC"""
	if not quest_manager:
		return false
	
	var active_quests = quest_manager.get_active_quests()
	for quest_id in active_quests:
		var quest_data = active_quests[quest_id]
		if quest_data.get("quest_giver", "") == character_id:
			return true
	
	return false

func can_offer_quest(quest_id: String, player: Node) -> bool:
	"""Vérifie si une quête spécifique peut être offerte"""
	# Vérification des prérequis de base
	if quest_id in completed_quests:
		return false  # Quête déjà donnée/complétée
	
	# Vérification de la relation minimum
	if get_relationship_level() < RelationshipLevel.NEUTRAL:
		return false  # Relation trop mauvaise
	
	# Vérification des prérequis de quête via QuestManager
	if quest_manager:
		var quest_template = quest_manager.quest_templates.get(quest_id, {})
		if quest_template.has("relationship_requirements"):
			var req = quest_template.relationship_requirements
			if req.has(faction_id) and player_relationship < req[faction_id]:
				return false
	
	return true

func offer_quest(quest_id: String, player: Node) -> bool:
	"""Offre une quête au joueur"""
	if not can_offer_quest(quest_id, player):
		return false
	
	if not quest_manager:
		if debug_mode:
			print("⚠️ QuestManager non disponible pour offrir", quest_id)
		return false
	
	# Démarrage de la quête via le manager
	var success = quest_manager.start_quest(quest_id)
	if success:
		# Marquage comme donnée
		available_quests.erase(quest_id)
		completed_quests.append(quest_id)
		
		# Enregistrement
		record_interaction("quest_given", {
			"quest_id": quest_id,
			"timestamp": Time.get_unix_time_from_system()
		})
		
		# Signal
		quest_given.emit(player, quest_id)
		
		if debug_mode:
			print("🗣️ NPC:", character_name, "a donné la quête", quest_id)
		
		return true
	
	return false

func complete_quest_for_player(quest_id: String, player: Node, rewards: Dictionary = {}) -> bool:
	"""Complète une quête pour le joueur"""
	# Vérification que le joueur a bien cette quête active
	if not quest_manager:
		return false
	
	var active_quests = quest_manager.get_active_quests()
	if not active_quests.has(quest_id):
		return false
	
	var quest_data = active_quests[quest_id]
	if quest_data.get("quest_giver", "") != character_id:
		return false
	
	# Complétion via le manager
	quest_manager.complete_quest(quest_id, QuestManager.CompletionType.SUCCESS, rewards)
	
	# Bonus de relation pour avoir complété la quête
	var relationship_bonus = 0.2
	if npc_type == NPCType.MERCHANT:
		relationship_bonus = 0.1  # Marchands moins généreux
	elif npc_type == NPCType.OFFICIAL:
		relationship_bonus = 0.3  # Officiels très reconnaissants
	
	modify_relationship(relationship_bonus, "quest_completion")
	
	# Enregistrement
	record_interaction("quest_completed", {
		"quest_id": quest_id,
		"rewards": rewards,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Signal
	quest_completed.emit(player, quest_id, rewards)
	
	return true

# ============================================================================
# SYSTÈME DE COMMERCE
# ============================================================================

func can_trade() -> bool:
	"""Vérifie si le commerce est possible"""
	return is_merchant and current_state in [NPCState.IDLE, NPCState.WORKING] and not shop_inventory.is_empty()

func start_trade(player: Node) -> bool:
	"""Démarre une session de commerce"""
	if not can_trade():
		return false
	
	current_player = player
	set_npc_state(NPCState.TRADING)
	
	# TODO: Ouverture de l'interface de commerce via UIManager
	if ui_manager and ui_manager.has_method("open_shop_interface"):
		ui_manager.open_shop_interface(character_id, shop_inventory)
	
	if debug_mode:
		print("🗣️ NPC: Commerce démarré avec", character_name)
	
	return true

func end_trade() -> void:
	"""Termine la session de commerce"""
	if current_state != NPCState.TRADING:
		return
	
	current_player = null
	set_npc_state(NPCState.WORKING if is_merchant else NPCState.IDLE)

func calculate_price(item_id: String, base_price: int, is_selling: bool = true) -> int:
	"""Calcule le prix d'un objet selon la relation et les négociations"""
	var final_price = base_price
	
	if is_selling:
		# Le NPC vend au joueur
		final_price = int(base_price * base_markup)
		
		# Réduction selon la relation
		var relationship_level = get_relationship_level()
		match relationship_level:
			RelationshipLevel.FRIENDLY:
				final_price = int(final_price * 0.9)  # 10% de réduction
			RelationshipLevel.ALLY:
				final_price = int(final_price * 0.8)  # 20% de réduction
			RelationshipLevel.UNFRIENDLY:
				final_price = int(final_price * 1.1)  # 10% de majoration
			RelationshipLevel.HOSTILE:
				final_price = int(final_price * 1.3)  # 30% de majoration
	else:
		# Le NPC achète au joueur
		final_price = int(base_price / base_markup)
		
		# Ajustement selon la relation (inverse)
		var relationship_level = get_relationship_level()
		match relationship_level:
			RelationshipLevel.FRIENDLY:
				final_price = int(final_price * 1.1)
			RelationshipLevel.ALLY:
				final_price = int(final_price * 1.2)
			RelationshipLevel.UNFRIENDLY:
				final_price = int(final_price * 0.9)
			RelationshipLevel.HOSTILE:
				final_price = int(final_price * 0.7)
	
	return max(1, final_price)  # Prix minimum de 1

func attempt_haggling(item_id: String, proposed_price: int, base_price: int) -> bool:
	"""Tente de négocier un prix"""
	var price_difference = abs(proposed_price - base_price)
	var price_ratio = float(price_difference) / float(base_price)
	
	# Chances de succès selon la personnalité et la relation
	var success_chance = haggling_tolerance
	success_chance += player_relationship * 0.1  # Bonus relation
	success_chance += (1.0 - greed_level) * 0.2  # Moins avide = plus généreux
	
	# Malus si la proposition est trop éloignée
	success_chance -= price_ratio * 0.5
	
	var success = randf() < success_chance
	
	# Effet sur la relation selon le résultat
	if success:
		modify_relationship(0.05, "successful_haggling")
	else:
		modify_relationship(-0.02, "failed_haggling")
	
	return success

# ============================================================================
# SYSTÈME DE RELATIONS & MÉMOIRE
# ============================================================================

func modify_relationship(delta: float, reason: String = "unknown") -> void:
	"""Modifie la relation avec le joueur"""
	var old_relationship = player_relationship
	var old_level = get_relationship_level()
	
	# Application du changement avec limites
	player_relationship = clamp(player_relationship + delta, -100.0, 100.0)
	var new_level = get_relationship_level()
	
	# Enregistrement de la mémoire
	record_memory("relationship_change", {
		"old_value": old_relationship,
		"new_value": player_relationship,
		"delta": delta,
		"reason": reason,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Signal si le niveau a changé
	if new_level != old_level:
		relationship_changed.emit(current_player, old_level, new_level)
		
		# Mise à jour des indicateurs visuels
		update_mood_indicator()
		
		if debug_mode:
			print("🗣️ NPC:", character_name, "- Relation:", old_level, "→", new_level)

func get_relationship_level() -> RelationshipLevel:
	"""Retourne le niveau de relation actuel"""
	if player_relationship <= -51:
		return RelationshipLevel.HOSTILE
	elif player_relationship <= -11:
		return RelationshipLevel.UNFRIENDLY
	elif player_relationship <= 10:
		return RelationshipLevel.NEUTRAL
	elif player_relationship <= 50:
		return RelationshipLevel.FRIENDLY
	else:
		return RelationshipLevel.ALLY

func record_interaction(interaction_type: String, data: Dictionary) -> void:
	"""Enregistre une interaction dans l'historique"""
	var interaction_record = {
		"type": interaction_type,
		"timestamp": Time.get_unix_time_from_system(),
		"data": data.duplicate()
	}
	
	interaction_history.append(interaction_record)
	last_interaction_time = interaction_record.timestamp
	
	# Limitation de l'historique (garder les 50 dernières)
	if interaction_history.size() > 50:
		interaction_history = interaction_history.slice(-50)

func record_memory(memory_type: String, memory_data: Dictionary) -> void:
	"""Enregistre une mémoire spécifique"""
	if not player_memory.has(memory_type):
		player_memory[memory_type] = []
	
	var memory_entry = {
		"timestamp": Time.get_unix_time_from_system(),
		"data": memory_data.duplicate()
	}
	
	player_memory[memory_type].append(memory_entry)
	memory_updated.emit(memory_type, memory_data)

func get_memory(memory_type: String) -> Array:
	"""Récupère les mémoires d'un type spécifique"""
	return player_memory.get(memory_type, [])

func has_memory_of(memory_type: String, search_criteria: Dictionary = {}) -> bool:
	"""Vérifie si le NPC a une mémoire spécifique"""
	var memories = get_memory(memory_type)
	
	if search_criteria.is_empty():
		return not memories.is_empty()
	
	for memory in memories:
		var matches = true
		for criteria_key in search_criteria:
			if not memory.data.has(criteria_key) or memory.data[criteria_key] != search_criteria[criteria_key]:
				matches = false
				break
		if matches:
			return true
	
	return false

# ============================================================================
# SYSTÈME DE MOUVEMENT & PATROUILLE
# ============================================================================

func _physics_process(delta: float) -> void:
	"""Mise à jour physique du NPC"""
	if not initialized:
		return
	
	# Traitement du mouvement
	if movement_enabled and current_state != NPCState.TALKING:
		process_movement(delta)
	
	# Mise à jour des animations
	update_animations()

func process_movement(delta: float) -> void:
	"""Traite le mouvement du NPC"""
	if current_state == NPCState.TALKING or current_state == NPCState.SLEEPING:
		velocity = Vector2.ZERO
		return
	
	# Mouvement vers la cible
	if global_position.distance_to(movement_target) > 5.0:
		var direction = (movement_target - global_position).normalized()
		velocity = direction * movement_speed
		is_moving = true
	else:
		velocity = Vector2.ZERO
		is_moving = false
		
		# Arrivé à destination
		if patrol_points.size() > 1:
			# Patrouille automatique
			advance_patrol_point()
	
	# Application du mouvement
	move_and_slide()

func advance_patrol_point() -> void:
	"""Avance au prochain point de patrouille"""
	if patrol_points.is_empty():
		return
	
	current_patrol_index = (current_patrol_index + 1) % patrol_points.size()
	movement_target = patrol_points[current_patrol_index]

func return_to_home() -> void:
	"""Retourne à la position de base"""
	movement_target = home_position

func face_target(target: Node) -> void:
	"""Oriente le NPC vers une cible"""
	var direction = (target.global_position - global_position).normalized()
	
	# Mise à jour de l'orientation du sprite
	if sprite:
		sprite.flip_h = direction.x < 0

# ============================================================================
# GESTION DES ÉTATS
# ============================================================================

func set_npc_state(new_state: NPCState) -> void:
	"""Change l'état du NPC"""
	if new_state == current_state:
		return
	
	var old_state = current_state
	current_state = new_state
	
	# Actions spécifiques à l'entrée du nouvel état
	match new_state:
		NPCState.TALKING:
			movement_target = global_position  # Arrêter le mouvement
		NPCState.BUSY:
			# TODO: Logique spécifique à l'état occupé
			pass
		NPCState.ANGRY:
			mood_modifier = -0.5
			update_mood_indicator()
		NPCState.SUSPICIOUS:
			mood_modifier = -0.3
			update_mood_indicator()
		_:
			if old_state in [NPCState.ANGRY, NPCState.SUSPICIOUS]:
				mood_modifier = 0.0
				update_mood_indicator()
	
	if debug_mode:
		print("🗣️ NPC:", character_name, "- État:", NPCState.keys()[old_state], "→", NPCState.keys()[new_state])

# ============================================================================
# INTERFACE VISUELLE
# ============================================================================

func update_dialogue_indicator() -> void:
	"""Met à jour l'indicateur de dialogue disponible"""
	if not dialogue_indicator:
		return
	
	var has_dialogue = player_in_range and current_state in [NPCState.IDLE, NPCState.WORKING]
	var has_quest = has_available_quest_for_player(current_player) if current_player else false
	
	# TODO: Affichage d'icônes selon le contexte
	# - Point d'exclamation pour quête
	# - Bulle de dialogue pour conversation normale
	# - Point d'interrogation pour informations
	
	dialogue_indicator.visible = has_dialogue

func update_mood_indicator() -> void:
	"""Met à jour l'indicateur d'humeur"""
	if not mood_indicator:
		return
	
	var relationship_level = get_relationship_level()
	var color = Color.WHITE
	
	match relationship_level:
		RelationshipLevel.HOSTILE:
			color = Color.RED
		RelationshipLevel.UNFRIENDLY:
			color = Color.ORANGE
		RelationshipLevel.NEUTRAL:
			color = Color.YELLOW
		RelationshipLevel.FRIENDLY:
			color = Color.LIGHT_GREEN
		RelationshipLevel.ALLY:
			color = Color.GREEN
	
	# Application de la couleur (ou autre effet visuel)
	if mood_indicator.has_method("modulate"):
		mood_indicator.modulate = color

func update_animations() -> void:
	"""Met à jour les animations du NPC"""
	if not sprite:
		return
	
	var animation_name = "idle"
	
	# Choix de l'animation selon l'état et le mouvement
	if current_state == NPCState.TALKING:
		animation_name = "talk"
	elif current_state == NPCState.SLEEPING:
		animation_name = "sleep"
	elif is_moving:
		animation_name = "walk"
	else:
		match current_state:
			NPCState.WORKING:
				animation_name = "work"
			NPCState.ANGRY:
				animation_name = "angry"
			_:
				animation_name = "idle"
	
	# Application de l'animation
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(animation_name):
		if sprite.animation != animation_name:
			sprite.play(animation_name)

# ============================================================================
# GESTIONNAIRES D'ÉVÉNEMENTS
# ============================================================================

func _on_interaction_area_entered(body: Node2D) -> void:
	"""Gère l'entrée du joueur dans la zone d'interaction"""
	if body.is_in_group("players"):
		player_in_range = true
		current_player = body
		update_dialogue_indicator()
		
		# Réaction selon la personnalité
		if curiosity_level > 0.6 and current_state == NPCState.IDLE:
			face_target(body)

func _on_interaction_area_exited(body: Node2D) -> void:
	"""Gère la sortie du joueur de la zone d'interaction"""
	if body.is_in_group("players"):
		player_in_range = false
		if current_player == body:
			current_player = null
		update_dialogue_indicator()

func _on_movement_timer_timeout() -> void:
	"""Timer de mouvement - changements de direction occasionnels"""
	if current_state == NPCState.IDLE and movement_enabled:
		if randf() < 0.3:  # 30% de chance de bouger
			# Mouvement aléatoire local
			var angle = randf() * TAU
			var distance = randf_range(32.0, 64.0)
			movement_target = home_position + Vector2(cos(angle), sin(angle)) * distance

func _on_mood_timer_timeout() -> void:
	"""Timer d'humeur - variations d'humeur occasionnelles"""
	# Variation aléatoire légère de l'humeur
	mood_modifier += randf_range(-0.1, 0.1)
	mood_modifier = clamp(mood_modifier, -1.0, 1.0)
	
	# Retour progressif vers l'humeur normale
	if mood_modifier > 0.1:
		mood_modifier -= 0.05
	elif mood_modifier < -0.1:
		mood_modifier += 0.05

func _on_patrol_timer_timeout() -> void:
	"""Timer de patrouille - changement de point de patrouille"""
	if patrol_points.size() > 1 and current_state in [NPCState.IDLE, NPCState.WORKING]:
		advance_patrol_point()

func _on_dialogue_manager_dialogue_started(npc_id: String, dialogue_id: String) -> void:
	"""Réagit au démarrage d'un dialogue dans le système"""
	if npc_id == character_id:
		# Ce NPC est impliqué dans le dialogue
		pass

func _on_dialogue_manager_dialogue_ended(npc_id: String, final_choice: String, relationship_change: float) -> void:
	"""Réagit à la fin d'un dialogue dans le système"""
	if npc_id == character_id:
		end_dialogue(final_choice, relationship_change)

func _on_dialogue_choice_made(npc_id: String, choice_id: String, consequences: Dictionary) -> void:
	"""Réagit aux choix de dialogue"""
	if npc_id == character_id:
		# Traitement des conséquences spécifiques
		if consequences.has("relationship_change"):
			modify_relationship(consequences.relationship_change, "dialogue_choice")
		
		if consequences.has("give_quest"):
			var quest_id = consequences.give_quest
			offer_quest(quest_id, current_player)
		
		if consequences.has("start_trade"):
			start_trade(current_player)

func _on_quest_completed(quest_id: String, completion_type: String, rewards: Dictionary) -> void:
	"""Réagit à la complétion d'une quête"""
	# Vérifier si cette quête était donnée par ce NPC
	var quest_data = quest_manager.get_quest_by_id(quest_id) if quest_manager else {}
	if quest_data.get("quest_giver", "") == character_id:
		record_interaction("quest_completed", {
			"quest_id": quest_id,
			"completion_type": completion_type,
			"rewards": rewards
		})

func _on_quest_failed(quest_id: String, failure_reason: String) -> void:
	"""Réagit à l'échec d'une quête"""
	var quest_data = quest_manager.get_quest_by_id(quest_id) if quest_manager else {}
	if quest_data.get("quest_giver", "") == character_id:
		# Réaction négative à l'échec
		modify_relationship(-0.1, "quest_failure")

func _on_reputation_changed(faction_id: String, old_value: int, new_value: int, reason: String) -> void:
	"""Réagit aux changements de réputation"""
	if faction_id == self.faction_id:
		# Ajustement de la relation selon la réputation de faction
		var reputation_delta = new_value - old_value
		modify_relationship(reputation_delta * 0.05, "faction_reputation")

# ============================================================================
# API PUBLIQUE - GETTERS & SETTERS
# ============================================================================

func get_interaction_type() -> int:
	"""Retourne le type d'interaction (pour Player.gd)"""
	return 1  # InteractionType.NPC dans Player.gd

func get_character_data() -> Dictionary:
	"""Retourne les données complètes du personnage"""
	return {
		"character_id": character_id,
		"character_name": character_name,
		"npc_type": npc_type,
		"faction_id": faction_id,
		"current_state": current_state,
		"player_relationship": player_relationship,
		"relationship_level": get_relationship_level(),
		"interaction_count": interaction_history.size(),
		"last_interaction": last_interaction_time,
		"is_merchant": is_merchant,
		"can_give_quests": can_give_quests,
		"available_quests": available_quests.size(),
		"mood_modifier": mood_modifier
	}

func is_available_for_interaction() -> bool:
	"""Vérifie si le NPC est disponible pour interaction"""
	return current_state in [NPCState.IDLE, NPCState.WORKING] and player_in_range

func get_shop_inventory() -> Dictionary:
	"""Retourne l'inventaire du magasin (si marchand)"""
	return shop_inventory.duplicate() if is_merchant else {}

func force_state(new_state: NPCState) -> void:
	"""Force un état spécifique (debug)"""
	set_npc_state(new_state)

# ============================================================================
# DEBUG & VALIDATION
# ============================================================================

func print_npc_debug() -> void:
	"""Affiche les informations de debug"""
	print("=== NPC DEBUG ===")
	print("ID:", character_id, "- Nom:", character_name)
	print("Type:", NPCType.keys()[npc_type], "- Faction:", faction_id)
	print("État:", NPCState.keys()[current_state])
	print("Relation joueur:", player_relationship, "(", RelationshipLevel.keys()[get_relationship_level()], ")")
	print("Position:", global_position, "- Cible:", movement_target)
	print("Joueur dans portée:", player_in_range)
	print("Interactions:", interaction_history.size())
	print("Quêtes disponibles:", available_quests.size())
	print("Est marchand:", is_merchant)

# ============================================================================
# NOTES DE DÉVELOPPEMENT
# ============================================================================

## PROCHAINES ÉTAPES:
## 1. Interface de commerce complète (UI)
## 2. Système de dialogue conditionnel avancé
## 3. Animations et expressions faciales
## 4. Réactions aux événements du monde (weather, magic)
## 5. Système de rumeurs et propagation d'informations
## 6. Sauvegarde/chargement des relations et mémoires
## 7. Intégration avec économie dynamique