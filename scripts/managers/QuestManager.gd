# ============================================================================ # 🎯 QuestManager.gd - Gestionnaire de Quêtes Narratives # ============================================================================ # STATUS: 🔄 IN_PROGRESS | ROADMAP: Mois 1, Semaine 2-3 - Core Architecture # PRIORITY: 🔴 CRITICAL - Progression narrative du jeu # DEPENDENCIES: GameManager, DataManager, DialogueManager
class_name QuestManage
extends Node

#Gestionnaire central des quêtes et de la progression narrative
#Responsable de l'histoire principale, quêtes secondaires et génération procédurale
#Intégré avec système d'observation et univers Terry Pratchett
#============================================================================
#SIGNAUX - Communication Event-Driven
#============================================================================
#Émis quand une nouvelle quête devient disponible
signal quest_available(quest_id: String, quest_data: Dictionary)

#Émis quand une quête est acceptée par le joueur
signal quest_started(quest_id: String, quest_data: Dictionary)

#Émis quand un objectif de quête est complété
signal quest_objective_completed(quest_id: String, objective_id: String)

#Émis quand une quête entière est terminée
signal quest_completed(quest_id: String, completion_type: String, rewards: Dictionary)

# Émis quand une quête échoue ou expire
signal quest_failed(quest_id: String, failure_reason: String)

# Émis quand l'histoire principale progresse
signal main_story_progressed(chapter: String, milestone: String)

#Émis quand un événement procédural est généré
signal procedural_event_triggered(event_data: Dictionary)

#============================================================================
#ENUMS & CONSTANTES
#============================================================================
enum QuestType {
MAIN_STORY, ## Histoire principale linéaire
SIDE_QUEST, ## Quête secondaire classique
PROCEDURAL, ## Générée dynamiquement
OBSERVATION, ## Déclenchée par observation créatures
REPUTATION, ## Liée aux factions
DISCOVERY, ## Exploration et secrets
PHILOSOPHICAL, ## Mini-jeux avec LA MORT
EMERGENCY ## Événements urgents Ankh-Morpork
}

enum QuestStatus {
LOCKED, ## Pas encore disponible
AVAILABLE, ## Disponible pour acceptation
ACTIVE, ## En cours
COMPLETED, ## Terminée avec succès
FAILED, ## Échoué
ABANDONED, ## Abandonnée par joueur
EXPIRED ## Expirée (limite de temps)
}

enum CompletionType {
SUCCESS, ## Objectif principal accompli
ALTERNATIVE, ## Solution alternative trouvée
NEGOTIATION, ## Résolu par dialogue/diplomatie
OBSERVATION, ## Résolu par évolution de créature
PHILOSOPHY, ## Résolu par réflexion profonde
CHAOS, ## Résolu par événement chaotique
DEATH_INTERVENTION ## LA MORT a aidé à résoudre
}

#Chapitres de l'histoire principale
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
#Données de configuration chargées depuis JSON
@export var quest_data: Dictionary = {}
@export var story_progression: Dictionary = {}
@export var procedural_config: Dictionary = {}

#État actuel du système
var active_quests: Dictionary = {}
var completed_quests: Dictionary = {}
var failed_quests: Dictionary = {}
var available_quests: Dictionary = {}

#Progression histoire principale
var current_chapter: String = "PROLOGUE"
var story_milestones: Array[String] = []
var story_variables: Dictionary = {}

#Système procédural
var procedural_events_pool: Array[Dictionary] = []
var event_cooldowns: Dictionary = {}
var city_tension_level: float = 0.0

	#Cache et optimisation
var quest_templates: Dictionary = {}
var npc_quest_associations: Dictionary = {}

#Flags de debug
var debug_mode: bool = false
var force_all_quests_available: bool = false

#============================================================================
#  INITIALISATION
#============================================================================
func _ready() -> void:
	"""Initialisation du QuestManager au démarrage"""
	if debug_mode:
		print("🎯 QuestManager: Initialisation...")
	# Connexion aux autres gestionnaires
	_connect_to_managers()
	# Chargement des données
	await _load_quest_data()
	# Configuration initiale
	_setup_initial_state()
	if debug_mode:
		print("🎯 QuestManager: Prêt! Chapitre:", current_chapter)

func _connect_to_managers() -> void:
	"""Connexion aux signaux des autres managers"""
	# Connexion à DataManager pour chargement données
	if DataManager:
		DataManager.data_loaded.connect(_on_data_manager_loaded)
	# Connexion à ObservationManager pour quêtes d'observation
	if ObservationManager:
		ObservationManager.creature_evolved.connect(_on_creature_evolved)
		ObservationManager.magic_cascade_triggered.connect(_on_magic_cascade)
	# Connexion à DialogueManager pour déclenchement quêtes
	if DialogueManager:
		DialogueManager.dialogue_choice_made.connect(_on_dialogue_choice)
		DialogueManager.conversation_ended.connect(_on_conversation_ended)

#============================================================================
# CHARGEMENT DES DONNÉES
#============================================================================
func _load_quest_data() -> void:
	"""Charge les données de quêtes depuis les fichiers JSON"""

	if not DataManager:
		push_error("🎯 QuestManager: DataManager non disponible!")
		return

	# Chargement des templates de quêtes
	quest_templates = DataManager.get_quest_templates()

	if quest_templates.is_empty():
		push_warning("🎯 QuestManager: Aucun template de quête trouvé!")
		# Fallback vers données de test
		_create_test_quests()

	# Chargement progression histoire
	story_progression = DataManager.get_story_progression()

	# Configuration procédurale
	procedural_config = DataManager.get_procedural_quest_config()

	if debug_mode:
		print("🎯 Templates chargés:", quest_templates.keys())

func _create_test_quests() -> void:
	"""Crée des quêtes de test pour développement"""

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
	"""Démarre une quête si les conditions sont remplies"""

	if not quest_templates.has(quest_id):
		push_error("🎯 Quête inconnue: " + quest_id)
		return false

	var quest_template = quest_templates[quest_id]

	# Vérification des prérequis
	if not force_start and not _check_prerequisites(quest_template):
		if debug_mode:
			print("🎯 Prérequis non remplis pour:", quest_id)
		return false

	# Vérification si déjà active ou complétée
	if active_quests.has(quest_id):
		if debug_mode:
			print("🎯 Quête déjà active:", quest_id)
		return false

	if completed_quests.has(quest_id):
		if debug_mode:
			print("🎯 Quête déjà complétée:", quest_id)
		return false

	# Création de l'instance de quête
	var quest_instance = _create_quest_instance(quest_template)
	active_quests[quest_id] = quest_instance

	# Suppression des quêtes disponibles si présente
	if available_quests.has(quest_id):
		available_quests.erase(quest_id)

	# Signaler le démarrage
	quest_started.emit(quest_id, quest_instance)

	if debug_mode:
		print("🎯 Quête démarrée:", quest_instance.title)

	return true

func complete_objective(quest_id: String, objective_id: String, completion_data: Dictionary = {}) -> bool:
	"""Marque un objectif comme complété"""

	if not active_quests.has(quest_id):
		push_warning("🎯 Tentative de compléter objectif pour quête inactive: " + quest_id)
		return false

	var quest = active_quests[quest_id]
	var objective_found = false

	# Recherche et mise à jour de l'objectif
	for objective in quest.objectives:
		if objective.id == objective_id and not objective.completed:
			objective.completed = true
			objective.completion_data = completion_data
			objective_found = true
			break

	if not objective_found:
		push_warning("🎯 Objectif non trouvé ou déjà complété: " + objective_id)
		return false

	# Signaler la complétion de l'objectif
	quest_objective_completed.emit(quest_id, objective_id)

	# Vérifier si la quête est terminée
	if _is_quest_complete(quest):
		_complete_quest(quest_id, CompletionType.SUCCESS)

	if debug_mode:
		print("🎯 Objectif complété:", objective_id, "dans", quest.title)

	return true

func _complete_quest(quest_id: String, completion_type: CompletionType, custom_rewards: Dictionary = {}) -> void:
	"""Finalise une quête complétée"""

	if not active_quests.has(quest_id):
		return

	var quest = active_quests[quest_id]
	quest.completion_type = completion_type
	quest.completion_time = Time.get_unix_time_from_system()

	# Application des récompenses
	var final_rewards = quest.rewards.duplicate()
	if not custom_rewards.is_empty():
		final_rewards.merge(custom_rewards)

	_apply_quest_rewards(final_rewards)

	# Déplacement vers les quêtes complétées
	completed_quests[quest_id] = quest
	active_quests.erase(quest_id)

	# Déverrouillage de nouvelles quêtes
	_check_quest_unlocks(quest_id)

	# Progression de l'histoire si nécessaire
	if quest.type == QuestType.MAIN_STORY:
		_progress_main_story(quest.chapter, quest_id)

	# Signalement
	quest_completed.emit(quest_id, CompletionType.keys()[completion_type], final_rewards)

	if debug_mode:
		print("🎯 Quête complétée:", quest.title, "- Type:", CompletionType.keys()[completion_type])

#============================================================================
#SYSTÈME PROCÉDURAL
#============================================================================
func generate_procedural_quest(context: Dictionary = {}) -> Dictionary:
	"""Génère une quête procédurale basée sur le contexte"""

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
			return _generate_anomaly_quest(context)
		"npc_request":
			return _generate_npc_quest(context)
		"faction_task":
			return _generate_faction_quest(context)
		"discovery_opportunity":
			return _generate_discovery_quest(context)

	return {}

func _generate_creature_quest(context: Dictionary) -> Dictionary:
	"""Génère une quête d'observation de créature"""

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
		"time_limit": 3600, # 1 heure
		"location": location,
		"difficulty": randi_range(1, 3)
	}

#============================================================================
#ÉVÉNEMENTS DES AUTRES SYSTÈMES
#============================================================================
func _on_creature_evolved(creature_id: String, old_stage: int, new_stage: int) -> void:
	"""Réagit aux évolutions de créatures pour les quêtes d'observation"""

	# Vérification des objectifs d'évolution
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
	"""Réagit aux choix de dialogue pour progression des quêtes"""

	# Certains choix peuvent déclencher ou progresser des quêtes
	if choice_data.has("triggers_quest"):
		var quest_to_trigger = choice_data.triggers_quest
		start_quest(quest_to_trigger)

	# Mise à jour des objectifs de dialogue
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
	"""Vérifie si les prérequis d'une quête sont remplis"""

	if not quest_template.has("prerequisites"):
		return true

	for prerequisite in quest_template.prerequisites:
		if not completed_quests.has(prerequisite):
			return false

	return true

func _is_quest_complete(quest: Dictionary) -> bool:
	"""Vérifie si tous les objectifs d'une quête sont complétés"""

	for objective in quest.objectives:
		if not objective.completed:
			return false

	return true

func _create_quest_instance(template: Dictionary) -> Dictionary:
	"""Crée une instance de quête depuis un template"""

	var instance = template.duplicate(true)
	instance.start_time = Time.get_unix_time_from_system()
	instance.status = QuestStatus.ACTIVE

	return instance

func _apply_quest_rewards(rewards: Dictionary) -> void:
	"""Apply quest rewards to player progression"""

	if rewards.has("experience"):
		# TODO: Intégrer avec système de progression joueur
		if debug_mode:
			print("🎯 XP gagné:", rewards.experience)

	if rewards.has("reputation"):
		# TODO: Intégrer avec ReputationSystem  
		if debug_mode:
			print("🎯 Réputation:", rewards.reputation)

func _progress_main_story(chapter: String, completed_quest: String) -> void:
	"""Progresse l'histoire principale"""

	story_milestones.append(completed_quest)

	# Logic pour changement de chapitre
	match completed_quest:
		"prologue_maurice":
			if current_chapter == "PROLOGUE":
				current_chapter = "ACT1_DISCOVERY"
				_unlock_chapter_quests("ACT1_DISCOVERY")

	main_story_progressed.emit(current_chapter, completed_quest)

func _unlock_chapter_quests(chapter: String) -> void:
	"""Déverrouille les quêtes d'un chapitre"""

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
	"""Retourne toutes les quêtes actives"""
	return active_quests.duplicate()

func get_completed_quests() -> Dictionary:
	"""Retourne toutes les quêtes complétées"""
	return completed_quests.duplicate()

func get_available_quests() -> Dictionary:
	"""Retourne toutes les quêtes disponibles"""
	return available_quests.duplicate()

func get_quest_by_id(quest_id: String) -> Dictionary:
	"""Retourne une quête spécifique par son ID"""

	if active_quests.has(quest_id):
		return active_quests[quest_id]
	elif completed_quests.has(quest_id):
		return completed_quests[quest_id]
	elif available_quests.has(quest_id):
		return available_quests[quest_id]

	return {}

func get_current_chapter() -> String:
	"""Retourne le chapitre actuel de l'histoire"""
	return current_chapter

func get_story_progress() -> Dictionary:
	"""Retourne la progression complète de l'histoire"""
	return {
	"current_chapter": current_chapter,
	"milestones": story_milestones.duplicate(),
	"variables": story_variables.duplicate()
	}

#============================================================================
#SETUP INITIAL & CONFIGURATION
#============================================================================
func _setup_initial_state() -> void:
	"""Configure l'état initial du gestionnaire"""

	# Démarrage automatique du prologue
	if quest_templates.has("prologue_maurice"):
		start_quest("prologue_maurice", true)

	# Configuration des événements procéduraux
	_setup_procedural_events()

func _setup_procedural_events() -> void:
	"""Configure le système d'événements procéduraux"""

	# Timer pour génération d'événements
	var proc_timer = Timer.new()
	proc_timer.wait_time = 300.0  # 5 minutes
	proc_timer.timeout.connect(_generate_random_event)
	add_child(proc_timer)
	proc_timer.start()

func _generate_random_event() -> void:
	"""Génère un événement procédural aléatoire"""

	# Vérification de la charge de quêtes actives
	if active_quests.size() >= 5:  # Limite pour ne pas surcharger
		return

	# Génération basée sur le niveau de tension de la ville
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
	"""Callback quand DataManager charge de nouvelles données"""
	match data_type:
		"quest_templates":
			quest_templates = DataManager.get_quest_templates()
			_setup_initial_state()
		"story_progression":
			story_progression = DataManager.get_story_progression()

#============================================================================
#DEBUG & DÉVELOPPEMENT
#============================================================================
func _input(event: InputEvent) -> void:
	"""Commandes de debug pour développement"""

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
