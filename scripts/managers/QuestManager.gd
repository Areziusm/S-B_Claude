# ============================================================================ 
# 🎯 QuestManager.gd - Gestionnaire de Quêtes Narratives 
# ============================================================================ 
# STATUS: 🔄 IN_PROGRESS | ROADMAP: Mois 1, Semaine 2-3 - Core Architecture 
# PRIORITY: 🔴 CRITICAL - Progression narrative du jeu 
# DEPENDENCIES: GameManager, DataManager, DialogueManager
class_name QuestManager
extends Node

#Gestionnaire central des quêtes et de la progression narrative
#Responsable de l'histoire principale, quêtes secondaires et génération procédurale
#Intégré avec système d'observation et univers Terry Pratchett
#============================================================================
#SIGNAUX - Communication Event-Driven
#============================================================================
signal quest_available(quest_id: String, quest_data: Dictionary)
signal quest_started(quest_id: String, quest_data: Dictionary)
signal quest_objective_completed(quest_id: String, objective_id: String)
signal quest_completed(quest_id: String, completion_type: String, rewards: Dictionary)
signal quest_failed(quest_id: String, failure_reason: String)
signal main_story_progressed(chapter: String, milestone: String)
signal procedural_event_triggered(event_data: Dictionary)

#============================================================================
#ENUMS & CONSTANTES
#============================================================================
enum QuestType {
	MAIN_STORY,
	SIDE_QUEST,
	PROCEDURAL,
	OBSERVATION,
	REPUTATION,
	DISCOVERY,
	PHILOSOPHICAL,
	EMERGENCY
}

enum QuestStatus {
	LOCKED,
	AVAILABLE,
	ACTIVE,
	COMPLETED,
	FAILED,
	ABANDONED,
	EXPIRED
}

enum CompletionType {
	SUCCESS,
	ALTERNATIVE,
	NEGOTIATION,
	OBSERVATION,
	PHILOSOPHY,
	CHAOS,
	DEATH_INTERVENTION
}

const MAIN_CHAPTERS = {
	"PROLOGUE": "L'Appartement et l'Événement Maurice",
	"ACT1_DISCOVERY": "Découverte du Don d'Observation",
	"ACT1_MENTORSHIP": "Rencontre avec Mémé Ciredutemps",
	"ACT2_INVESTIGATION": "L'Enquête sur la Perturbation Magique",
	"ACT2_FACTIONS": "Alliances et Conflits",
	"ACT3_REVELATION": "La Vérité sur les Évolutions",
	"ACT3_CHOICE": "Le Grand Choix Final",
	"EPILOGUE": "Conséquences et Nouveau Monde"
}

#============================================================================
#VARIABLES D'ÉTAT
#============================================================================
@export var quest_data: Dictionary = {}
@export var story_progression: Dictionary = {}
@export var procedural_config: Dictionary = {}

var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}
var failed_quests: Dictionary = {}
var available_quests: Dictionary = {}

var current_chapter: String = "PROLOGUE"
var story_milestones: Array[String] = []
var story_variables: Dictionary = {}

var procedural_events_pool: Array[Dictionary] = []
var event_cooldowns: Dictionary = {}
var city_tension_level: float = 0.0

var quest_templates: Dictionary = {}
var npc_quest_associations: Dictionary = {}

var debug_mode: bool = false
var force_all_quests_available: bool = false

#============================================================================
#  INITIALISATION
#============================================================================
func _ready() -> void:
	if debug_mode:
		print("🎯 QuestManager: Initialisation...")

	_connect_to_managers()
	await _load_quest_data()
	_setup_initial_state()

	if debug_mode:
		print("🎯 QuestManager: Prêt! Chapitre:", current_chapter)

func _connect_to_managers() -> void:
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager:
		data_manager.data_loaded.connect(_on_data_manager_loaded)

	var observation_manager = get_node_or_null("/root/ObservationManager")
	if observation_manager:
		observation_manager.creature_evolved.connect(_on_creature_evolved)
		observation_manager.magic_cascade_triggered.connect(_on_magic_cascade)

	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.dialogue_choice_made.connect(_on_dialogue_choice)
		dialogue_manager.conversation_ended.connect(_on_conversation_ended)

#============================================================================
# CHARGEMENT DES DONNÉES
#============================================================================
func _load_quest_data() -> void:
	var data_manager = get_node_or_null("/root/DataManager")
	if not data_manager:
		push_error("🎯 QuestManager: DataManager non disponible!")
		return

	# Chargement des templates de quêtes
	quest_templates = data_manager.quest_templates

	if quest_templates.is_empty():
		push_warning("🎯 QuestManager: Aucun template de quête trouvé!")
		_create_test_quests()

	story_progression = data_manager.get_story_progression()
	procedural_config = data_manager.get_procedural_quest_config()

	if debug_mode:
		print("🎯 Templates chargés:", quest_templates.keys())

func _create_test_quests() -> void:
	quest_templates = {
		"prologue_maurice": {
			"id": "prologue_maurice",
			"type": QuestType.MAIN_STORY,
			"title": "L'Événement Maurice",
			"description": "Votre chat Maurice a fait quelque chose d'impossible. Il faut comprendre ce qui se passe.",
			"chapter": "PROLOGUE",
			"objectives": [
				{
					"id": "examine_maurice",
					"description": "Examiner Maurice de plus près",
					"type": "observation",
					"target": "maurice_cat",
					"completed": false
				},
				{
					"id": "talk_to_landlord",
					"description": "Parler au propriétaire de l'immeuble",
					"type": "dialogue",
					"target": "landlord_npc",
					"completed": false
				}
			],
			"rewards": {
				"experience": 100,
				"reputation": {"general": 10},
				"unlocks": ["observation_tutorial"]
			},
			"prerequisites": [],
			"time_limit": 0,
			"auto_start": true
		},

		"first_evolution": {
			"id": "first_evolution",
			"type": QuestType.OBSERVATION,
			"title": "Première Évolution",
			"description": "Utilisez votre don pour faire évoluer une créature pour la première fois.",
			"chapter": "ACT1_DISCOVERY",
			"objectives": [
				{
					"id": "evolve_creature",
					"description": "Faire évoluer n'importe quelle créature",
					"type": "evolution",
					"target": "any_creature",
					"completed": false
				}
			],
			"rewards": {
				"experience": 200,
				"reputation": {"wizards": 15},
				"unlocks": ["advanced_observation"]
			},
			"prerequisites": ["prologue_maurice"],
			"time_limit": 0,
			"auto_start": false
		}
	}

#============================================================================
#GESTION DES QUÊTES
#============================================================================
func start_quest(quest_id: String, force_start: bool = false) -> bool:
	if not quest_templates.has(quest_id):
		push_error("🎯 Quête inconnue: " + quest_id)
		return false

	var quest_template = quest_templates[quest_id]

	if not force_start and not _check_prerequisites(quest_template):
		if debug_mode:
			print("🎯 Prérequis non remplis pour:", quest_id)
		return false

	if active_quests.has(quest_id):
		if debug_mode:
			print("🎯 Quête déjà active:", quest_id)
		return false

	if completed_quests.has(quest_id):
		if debug_mode:
			print("🎯 Quête déjà complétée:", quest_id)
		return false

	var quest_instance = _create_quest_instance(quest_template)
	active_quests[quest_id] = quest_instance

	if available_quests.has(quest_id):
		available_quests.erase(quest_id)

	quest_started.emit(quest_id, quest_instance)

	if debug_mode:
		print("🎯 Quête démarrée:", quest_instance.title)

	return true

func complete_objective(quest_id: String, objective_id: String, completion_data: Dictionary = {}) -> bool:
	if not active_quests.has(quest_id):
		push_warning("🎯 Tentative de compléter objectif pour quête inactive: " + quest_id)
		return false

	var quest = active_quests[quest_id]
	var objective_found = false

	for objective in quest.objectives:
		if objective.id == objective_id and not objective.completed:
			objective.completed = true
			objective.completion_data = completion_data
			objective_found = true
			break

	if not objective_found:
		push_warning("🎯 Objectif non trouvé ou déjà complété: " + objective_id)
		return false

	quest_objective_completed.emit(quest_id, objective_id)

	if _is_quest_complete(quest):
		_complete_quest(quest_id, CompletionType.SUCCESS)

	if debug_mode:
		print("🎯 Objectif complété:", objective_id, "dans", quest.title)

	return true

func _complete_quest(quest_id: String, completion_type: CompletionType, custom_rewards: Dictionary = {}) -> void:
	if not active_quests.has(quest_id):
		return

	var quest = active_quests[quest_id]
	quest.completion_type = completion_type
	quest.completion_time = Time.get_unix_time_from_system()

	var final_rewards = quest.rewards.duplicate()
	if not custom_rewards.is_empty():
		final_rewards.merge(custom_rewards)

	_apply_quest_rewards(final_rewards)

	completed_quests[quest_id] = quest
	active_quests.erase(quest_id)

	_check_quest_unlocks()
	if quest.type == QuestType.MAIN_STORY:
		_progress_main_story(quest.chapter, quest_id)

	quest_completed.emit(quest_id, CompletionType.keys()[completion_type], final_rewards)

	if debug_mode:
		print("🎯 Quête complétée:", quest.title, "- Type:", CompletionType.keys()[completion_type])

#============================================================================
#SYSTÈME PROCÉDURAL
#============================================================================
func generate_procedural_quest(context: Dictionary = {}) -> Dictionary:
	var quest_types = [
		"creature_sighting",
		"magical_anomaly",
		"npc_request",
		"faction_task",
		"discovery_opportunity"
	]

	var quest_type = quest_types[randi() % quest_types.size()]

	match quest_type:
		"creature_sighting":
			return _generate_creature_quest(context)
		"magical_anomaly":
			return _generate_anomaly_quest()
		"npc_request":
			return _generate_npc_quest()
		"faction_task":
			return _generate_faction_quest()
		"discovery_opportunity":
			return _generate_discovery_quest()

	return {}

func _generate_creature_quest(context: Dictionary) -> Dictionary:
	var creatures = ["pigeon", "rat", "chat", "chien", "corbeau"]
	var locations = ["Ramkin", "Ankh", "Morpork", "Université", "Shades"]

	var creature = creatures[randi() % creatures.size()]
	var location = locations[randi() % locations.size()]

	return {
		"id": "proc_creature_" + str(randi()),
		"type": QuestType.PROCEDURAL,
		"subtype": "creature_observation",
		"title": "Créature Inhabituelle à " + location,
		"description": "Un " + creature + " au comportement étrange a été signalé à " + location + ". L'observer pourrait révéler quelque chose d'intéressant.",
		"objectives": [
			{
				"id": "find_creature",
				"description": "Trouver le " + creature + " à " + location,
				"type": "location",
				"target": location.to_lower() + "_" + creature,
				"completed": false
			},
			{
				"id": "observe_creature",
				"description": "Observer le " + creature + " pendant au moins 30 secondes",
				"type": "observation",
				"target": creature,
				"completed": false
			}
		],
		"rewards": {
			"experience": randi_range(50, 150),
			"reputation": {"general": randi_range(5, 15)}
		},
		"time_limit": 3600,
		"location": location,
		"difficulty": randi_range(1, 3)
	}

#============================================================================
#ÉVÉNEMENTS DES AUTRES SYSTÈMES
#============================================================================
func _on_creature_evolved(creature_id: String, old_stage: int, new_stage: int) -> void:
	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		for objective in quest.objectives:
			if objective.type == "evolution":
				if objective.target == "any_creature" or objective.target == creature_id:
					complete_objective(quest_id, objective.id, {
						"creature_id": creature_id,
						"old_stage": old_stage,
						"new_stage": new_stage
					})

func _on_dialogue_choice(dialogue_id: String, choice_id: String, choice_data: Dictionary) -> void:
	if choice_data.has("triggers_quest"):
		var quest_to_trigger = choice_data.triggers_quest
		start_quest(quest_to_trigger)

	for quest_id in active_quests:
		var quest = active_quests[quest_id]
		for objective in quest.objectives:
			if objective.type == "dialogue" and objective.target == dialogue_id:
				complete_objective(quest_id, objective.id, {
					"dialogue_id": dialogue_id,
					"choice_id": choice_id
				})

#============================================================================
#UTILITAIRES & HELPERS
#============================================================================
func _check_prerequisites(quest_template: Dictionary) -> bool:
	if not quest_template.has("prerequisites"):
		return true

	for prerequisite in quest_template.prerequisites:
		if not completed_quests.has(prerequisite):
			return false

	return true

func _is_quest_complete(quest: Dictionary) -> bool:
	for objective in quest.objectives:
		if not objective.completed:
			return false
	return true

func _create_quest_instance(template: Dictionary) -> Dictionary:
	var instance = template.duplicate(true)
	instance.start_time = Time.get_unix_time_from_system()
	instance.status = QuestStatus.ACTIVE
	return instance

func _apply_quest_rewards(rewards: Dictionary) -> void:
	if rewards.has("experience"):
		if debug_mode:
			print("🎯 XP gagné:", rewards.experience)
	if rewards.has("reputation"):
		if debug_mode:
			print("🎯 Réputation:", rewards.reputation)

func _progress_main_story(chapter: String, completed_quest: String) -> void:
	story_milestones.append(completed_quest)
	match completed_quest:
		"prologue_maurice":
			if current_chapter == "PROLOGUE":
				current_chapter = "ACT1_DISCOVERY"
				_unlock_chapter_quests("ACT1_DISCOVERY")
	main_story_progressed.emit(current_chapter, completed_quest)

func _unlock_chapter_quests(chapter: String) -> void:
	for quest_id in quest_templates:
		var quest = quest_templates[quest_id]
		if quest.has("chapter") and quest.chapter == chapter:
			if _check_prerequisites(quest):
				available_quests[quest_id] = quest
				quest_available.emit(quest_id, quest)

#============================================================================
#API PUBLIQUE - GETTERS
#============================================================================
func get_active_quests() -> Dictionary:
	return active_quests.duplicate()

func get_completed_quests() -> Dictionary:
	return completed_quests.duplicate()

func get_available_quests() -> Dictionary:
	return available_quests.duplicate()

func get_quest_by_id(quest_id: String) -> Dictionary:
	if active_quests.has(quest_id):
		return active_quests[quest_id]
	elif completed_quests.has(quest_id):
		return completed_quests[quest_id]
	elif available_quests.has(quest_id):
		return available_quests[quest_id]
	return {}

func get_current_chapter() -> String:
	return current_chapter

func get_story_progress() -> Dictionary:
	return {
		"current_chapter": current_chapter,
		"milestones": story_milestones.duplicate(),
		"variables": story_variables.duplicate()
	}

#============================================================================
#SETUP INITIAL & CONFIGURATION
#============================================================================
func _setup_initial_state() -> void:
	if quest_templates.has("prologue_maurice"):
		start_quest("prologue_maurice", true)
	_setup_procedural_events()

func _setup_procedural_events() -> void:
	var proc_timer = Timer.new()
	proc_timer.wait_time = 300.0
	proc_timer.timeout.connect(_generate_random_event)
	add_child(proc_timer)
	proc_timer.start()

func _generate_random_event() -> void:
	if active_quests.size() >= 5:
		return
	var event_chance = city_tension_level * 0.3 + 0.1
	if randf() < event_chance:
		var event_quest = generate_procedural_quest()
		if not event_quest.is_empty():
			var event_id = event_quest.id
			quest_templates[event_id] = event_quest
			available_quests[event_id] = event_quest
			quest_available.emit(event_id, event_quest)
			if debug_mode:
				print("🎯 Événement procédural généré:", event_quest.title)

#============================================================================
#CALLBACKS DATA MANAGER
#============================================================================
func _on_data_manager_loaded(data_type: String) -> void:
	var data_manager = get_node_or_null("/root/DataManager")
	match data_type:
		"quest_templates":
			quest_templates = data_manager.quest_templates
			_setup_initial_state()
		"story_progression":
			story_progression = data_manager.get_story_progression()

#============================================================================
#DEBUG & DÉVELOPPEMENT
#============================================================================
func _input(event: InputEvent) -> void:
	if not debug_mode:
		return
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_F1:
				print("🎯 DEBUG - Quêtes actives:", active_quests.keys())
			KEY_F2:
				print("🎯 DEBUG - Quêtes disponibles:", available_quests.keys())
			KEY_F3:
				if not available_quests.is_empty():
					var first_quest = available_quests.keys()[0]
					start_quest(first_quest, true)
					print("🎯 DEBUG - Force start:", first_quest)

#============================================================================
#NOTES DE DÉVELOPPEMENT
#============================================================================
func _on_magic_cascade():
	pass

func _on_conversation_ended():
	pass

func _check_quest_unlocks():
	pass

func _generate_anomaly_quest():
	pass

func _generate_npc_quest():
	pass

func _generate_faction_quest():
	pass

func _generate_discovery_quest():
	pass
#============================================================================
#NOTES DE DÉVELOPPEMENT
#============================================================================
#TODO PRIORITAIRES:
#1. Intégration complète avec DataManager (vrais fichiers JSON)
#2. Interface UI pour journal des quêtes
#3. Système de sauvegarde des quêtes
#4. Équilibrage des récompenses et difficulté
#5. Expansion des quêtes procédurales
#INTÉGRATIONS FUTURES:
#- Player.gd pour application des récompenses
#- ReputationSystem pour conséquences factions
#- CombatSystem pour quêtes de combat
#- AudioManager pour sons de progression
#- UIManager pour notifications et interface
#SPÉCIAL TERRY PRATCHETT:
#- Quêtes avec humour britannique et références
#- Résolutions créatives et inattendues
#- Personnages excentriques et mémorables
#- Philosophie cachée dans la narrative
#- Mécaniques uniques liées à l'univers Disque-Monde
