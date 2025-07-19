# ============================================================================
# 🔮 ObservationManager.gd - Système Unique du Jeu
# ============================================================================
# STATUS: ✅ FINALISÉ | ROADMAP: Mois 1, Semaine 1-2 - Core Architecture
# PRIORITY: 🔴 CRITICAL - Cœur du gameplay unique
# DEPENDENCIES: GameManager, DataManager

class_name ObservationManager
extends Node

## Gestionnaire central du système d'observation magique
## Responsable de la mécanique unique : Observer → Évoluer
## Architecture extensible pour DLC et contenu procédural

# ============================================================================
# SIGNAUX - Communication Event-Driven
# ============================================================================

## Émis quand une créature est observée
signal creature_observed(creature_id: String, observation_data: Dictionary)

## Émis quand une créature évolue suite à observation
signal creature_evolved(creature_id: String, old_stage: int, new_stage: int)

## Émis quand un événement magique en cascade se déclenche
signal magic_cascade_triggered(epicenter: Vector2, intensity: float)

## Émis quand le niveau de perturbation magique change
signal magic_disruption_changed(old_level: float, new_level: float)

## Émis pour mise à jour du carnet magique
signal notebook_entry_added(creature_id: String, entry_data: Dictionary)

## Signal pour communication avec autres managers
signal manager_initialized()

# ============================================================================
# CONFIGURATION & DONNÉES
# ============================================================================

## Configuration système par défaut (fallback si JSON absent)
var default_config: Dictionary = {
	"evolution_thresholds": [0, 3, 7, 12, 20],
	"magic_amplification_max": 5.0,
	"cascade_base_chance": 0.15,
	"notebook_auto_entries": true,
	"evolution_animations": true,
	"disruption_decay_rate": 0.01
}

## Données chargées depuis DataManager
var observation_config: Dictionary = {}
var creature_database: Dictionary = {}
var observed_creatures: Dictionary = {}

## État global du système
var magic_amplification: float = 1.0
var total_observations: int = 0
var magic_disruption_level: float = 0.0

## Cache pour optimisation
var evolution_cache: Dictionary = {}
var ability_cache: Dictionary = {}

## Flags système
var system_initialized: bool = false
var debug_mode: bool = false

# ============================================================================
# ÉTATS D'ÉVOLUTION DES CRÉATURES
# ============================================================================

enum EvolutionStage {
	STAGE_0_NORMAL = 0,    ## État naturel de base
	STAGE_1_AWARE = 1,     ## Conscience accrue
	STAGE_2_ENHANCED = 2,  ## Capacités améliorées
	STAGE_3_MAGICAL = 3,   ## Propriétés magiques
	STAGE_4_LEGENDARY = 4  ## Forme légendaire
}

enum ObservationType {
	PASSIVE = 0,     ## Observation automatique en arrière-plan
	ACTIVE = 1,      ## Observation intentionnelle du joueur
	DETAILED = 2,    ## Analyse approfondie avec carnet
	SCIENTIFIC = 3   ## Étude prolongée avec équipement
}

# ============================================================================
# INITIALISATION SYSTÈME
# ============================================================================

func _ready() -> void:
	"""Initialisation du système d'observation"""
	if debug_mode:
		print("🔮 ObservationManager: Démarrage initialisation...")
	
	# Attendre que DataManager soit prêt
	await ensure_datamanager_ready()
	
	# Charger configuration et données
	load_system_configuration()
	load_creature_database()
	
	# Configuration initiale
	setup_magic_amplification()
	connect_to_game_systems()
	
	# Finalisation
	system_initialized = true
	manager_initialized.emit()
	
	if debug_mode:
		print("🔮 ObservationManager: Système initialisé avec succès")

func ensure_datamanager_ready() -> void:
	"""S'assure que DataManager est prêt avant de continuer"""
	# Attendre DataManager via GameManager
	if not get_node_or_null("/root/DataManager"):
		# Attendre que GameManager initialise DataManager
		if get_node_or_null("/root/GameManager"):
			await get_node("/root/GameManager").manager_ready
		else:
			await get_tree().process_frame
	
	# Attendre que toutes les données soient chargées
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager and not data_manager.loading_complete:
		await data_manager.all_data_loaded

func load_system_configuration() -> void:
	"""Charge la configuration depuis DataManager ou utilise les défauts"""
	var data_manager = get_node_or_null("/root/DataManager")
	
	if data_manager and data_manager.game_config.has("observation_system"):
		observation_config = data_manager.game_config["observation_system"]
		if debug_mode:
			print("✅ Configuration observation chargée depuis DataManager")
	else:
		observation_config = default_config.duplicate()
		if debug_mode:
			print("⚠️ Configuration par défaut utilisée pour observation")

func load_creature_database() -> void:
	"""Charge la base de données des créatures depuis DataManager"""
	var data_manager = get_node_or_null("/root/DataManager")
	
	if data_manager and not data_manager.creatures_db.is_empty():
		creature_database = data_manager.creatures_db
		if debug_mode:
			print("✅ Base créatures chargée:", creature_database.size(), "espèces")
	else:
		# Fallback avec données de test minimales
		setup_fallback_creatures()
		if debug_mode:
			print("⚠️ Données créatures fallback utilisées")

func setup_fallback_creatures() -> void:
	"""Données de test minimales si JSON absent"""
	creature_database = {
		"rat_maurice": {
			"name": "Maurice le Rat Parlant",
			"base_species": "rat",
			"evolution_stages": [
				{"name": "Rat Ordinaire", "description": "Un rat comme les autres"},
				{"name": "Rat Conscient", "description": "Commence à réfléchir..."},
				{"name": "Rat Éduqué", "description": "Lit des livres maintenant"},
				{"name": "Rat Magique", "description": "Maîtrise des sorts mineurs"},
				{"name": "Rat Légendaire", "description": "Maurice, Leader des Rats"}
			],
			"magic_affinity": 0.8,
			"observation_difficulty": 1.2
		},
		"pigeon_ankh": {
			"name": "Pigeon d'Ankh-Morpork",
			"base_species": "pigeon",
			"evolution_stages": [
				{"name": "Pigeon Urbain", "description": "Survit dans la grande ville"},
				{"name": "Pigeon Débrouillard", "description": "Évite habilement les dangers"},
				{"name": "Pigeon Navigateur", "description": "Connaît tous les raccourcis"},
				{"name": "Pigeon Messager", "description": "Transporte des messages magiques"},
				{"name": "Pigeon Impérial", "description": "Pigeon personnel du Patricien"}
			],
			"magic_affinity": 0.3,
			"observation_difficulty": 0.8
		}
	}

func setup_magic_amplification() -> void:
	"""Configure le système d'amplification magique"""
	magic_amplification = 1.0
	magic_disruption_level = 0.0
	
	# Timer pour décroissance naturelle de la perturbation
	var decay_timer = Timer.new()
	decay_timer.wait_time = 1.0
	decay_timer.timeout.connect(_decay_magic_disruption)
	add_child(decay_timer)
	decay_timer.start()

func connect_to_game_systems() -> void:
	"""Connecte l'ObservationManager aux autres systèmes"""
	# Connexion avec QuestManager pour quêtes d'observation
	var quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager:
		creature_evolved.connect(quest_manager._on_creature_evolved)
		magic_cascade_triggered.connect(quest_manager._on_magic_cascade)
	
	# Connexion avec GameManager pour événements globaux
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		magic_disruption_changed.connect(game_manager._on_magic_disruption_changed)

# ============================================================================
# API PRINCIPALE - OBSERVATION DES CRÉATURES
# ============================================================================

func observe_creature(creature_id: String, observation_type: ObservationType, observer_position: Vector2 = Vector2.ZERO) -> Dictionary:
	"""
	Fonction principale d'observation d'une créature
	Retourne un dictionnaire avec toutes les données d'observation
	"""
	if not system_initialized:
		push_error("🔮 ObservationManager: Système non initialisé!")
		return {}
	
	if not creature_database.has(creature_id):
		push_warning("🔮 Créature inconnue: " + creature_id)
		return {}
	
	# Initialiser les données de créature si première observation
	if not observed_creatures.has(creature_id):
		initialize_creature_observation(creature_id)
	
	# Traitement de l'observation
	var creature_data = observed_creatures[creature_id]
	var old_stage = creature_data.current_stage
	
	# Mise à jour des données d'observation
	update_observation_data(creature_id, observation_type, creature_data)
	
	# Calcul de l'intensité d'observation
	var observation_intensity = calculate_observation_intensity(observation_type, creature_data)
	
	# Mise à jour de l'amplification magique globale
	update_magic_amplification(observation_intensity)
	
	# Vérification d'évolution
	check_evolution_threshold(creature_id, creature_data)
	
	# Génération des données de retour
	var observation_result = generate_observation_data(creature_id, creature_data, observation_intensity)
	
	# Émission des signaux
	creature_observed.emit(creature_id, observation_result)
	
	# Vérification si évolution a eu lieu
	if creature_data.current_stage != old_stage:
		creature_evolved.emit(creature_id, old_stage, creature_data.current_stage)
		update_evolution_cache(creature_id, creature_data.current_stage)
	
	# Mise à jour du carnet si configuré
	if observation_config.get("notebook_auto_entries", true):
		update_notebook_entry(creature_id, observation_result)
	
	# Chance d'événement magique en cascade
	roll_magic_cascade(observer_position, observation_intensity)
	
	total_observations += 1
	
	if debug_mode:
		print("🔍 Observation: ", creature_id, " (intensité: ", observation_intensity, ")")
	
	return observation_result

func initialize_creature_observation(creature_id: String) -> void:
	"""Initialise les données d'observation pour une nouvelle créature"""
	var creature_info = creature_database.get(creature_id, {})
	
	observed_creatures[creature_id] = {
		"observation_count": 0,
		"current_stage": EvolutionStage.STAGE_0_NORMAL,
		"evolution_progress": 0.0,
		"first_observation_time": Time.get_unix_time_from_system(),
		"last_observation_time": 0,
		"observation_types": [],
		"special_events": [],
		"magic_affinity": creature_info.get("magic_affinity", 0.5),
		"observation_difficulty": creature_info.get("observation_difficulty", 1.0),
		"total_observation_intensity": 0.0
	}
	
	if debug_mode:
		print("🆕 Nouvelle créature initialisée: ", creature_id)

func update_observation_data(creature_id: String, observation_type: ObservationType, creature_data: Dictionary) -> void:
	"""Met à jour les données d'observation d'une créature"""
	creature_data.observation_count += 1
	creature_data.last_observation_time = Time.get_unix_time_from_system()
	creature_data.observation_types.append(observation_type)
	
	# Garder seulement les 10 derniers types d'observation
	if creature_data.observation_types.size() > 10:
		creature_data.observation_types = creature_data.observation_types.slice(-10)

func calculate_observation_intensity(obs_type: ObservationType, creature_data: Dictionary) -> float:
	"""Calcule l'intensité d'une observation selon le type et l'historique"""
	var base_intensity = 1.0
	
	# Multiplicateur selon le type d'observation
	match obs_type:
		ObservationType.PASSIVE:
			base_intensity = 0.5
		ObservationType.ACTIVE:
			base_intensity = 1.0
		ObservationType.DETAILED:
			base_intensity = 2.0
		ObservationType.SCIENTIFIC:
			base_intensity = 3.0
	
	# Bonus de familiarité (plus on observe, plus on découvre)
	var familiarity_bonus = min(creature_data.observation_count * 0.1, 1.0)
	
	# Facteur de difficulté de la créature
	var difficulty_factor = creature_data.get("observation_difficulty", 1.0)
	
	# Amplification magique globale
	var magic_factor = magic_amplification
	
	# Calcul final
	var final_intensity = base_intensity * (1.0 + familiarity_bonus) * difficulty_factor * magic_factor
	
	# Stockage pour historique
	creature_data.total_observation_intensity += final_intensity
	
	return final_intensity

func update_magic_amplification(observation_intensity: float) -> void:
	"""Met à jour l'amplification magique globale"""
	var amplification_rate = observation_config.get("magic_amplification_rate", 0.1)
	var max_amplification = observation_config.get("magic_amplification_max", 5.0)
	
	# Augmentation de l'amplification basée sur l'intensité
	var amplification_increase = observation_intensity * amplification_rate * 0.01
	magic_amplification = min(magic_amplification + amplification_increase, max_amplification)
	
	# Augmentation de la perturbation magique
	var old_disruption = magic_disruption_level
	var disruption_increase = observation_intensity * 0.02
	magic_disruption_level = min(magic_disruption_level + disruption_increase, 1.0)
	
	if abs(magic_disruption_level - old_disruption) > 0.01:
		magic_disruption_changed.emit(old_disruption, magic_disruption_level)

func check_evolution_threshold(creature_id: String, creature_data: Dictionary) -> void:
	"""Vérifie si une créature doit évoluer"""
	var current_stage = creature_data.current_stage
	
	if current_stage >= EvolutionStage.STAGE_4_LEGENDARY:
		return  # Déjà au maximum
	
	var evolution_thresholds = observation_config.get("evolution_thresholds", [0, 3, 7, 12, 20])
	var observation_count = creature_data.observation_count
	
	var next_stage = current_stage + 1
	if next_stage < evolution_thresholds.size():
		var required_observations = evolution_thresholds[next_stage]
		
		if observation_count >= required_observations:
			trigger_evolution(creature_id, creature_data, next_stage)

func trigger_evolution(creature_id: String, creature_data: Dictionary, new_stage: int) -> void:
	"""Déclenche l'évolution d'une créature"""
	var old_stage = creature_data.current_stage
	creature_data.current_stage = new_stage
	creature_data.evolution_progress = 0.0
	
	# Ajouter événement spécial dans l'historique
	var evolution_event = {
		"type": "evolution",
		"timestamp": Time.get_unix_time_from_system(),
		"old_stage": old_stage,
		"new_stage": new_stage,
		"observation_count": creature_data.observation_count
	}
	creature_data.special_events.append(evolution_event)
	
	if debug_mode:
		print("🎉 Évolution! ", creature_id, ": Stage ", old_stage, " → ", new_stage)

func generate_observation_data(creature_id: String, creature_data: Dictionary, intensity: float) -> Dictionary:
	"""Génère les données complètes d'observation pour retour"""
	var current_stage = creature_data.current_stage
	var creature_info = creature_database.get(creature_id, {})
	
	var observation_result = {
		"creature_id": creature_id,
		"creature_name": creature_info.get("name", "Créature Inconnue"),
		"observation_count": creature_data.observation_count,
		"current_stage": current_stage,
		"stage_name": get_stage_name(creature_id, current_stage),
		"stage_description": get_stage_description(creature_id, current_stage),
		"magic_affinity": creature_data.magic_affinity,
		"evolution_progress": calculate_evolution_progress(creature_data),
		"discoveries": generate_discoveries(creature_id, creature_data, intensity),
		"special_abilities": get_current_abilities(creature_id, current_stage),
		"observation_intensity": intensity,
		"global_magic_level": magic_amplification,
		"disruption_level": magic_disruption_level
	}
	
	return observation_result

# ============================================================================
# UTILITAIRES & GETTERS
# ============================================================================

func get_stage_name(creature_id: String, stage: int) -> String:
	"""Retourne le nom du stade d'évolution actuel"""
	var creature_info = creature_database.get(creature_id, {})
	var stages = creature_info.get("evolution_stages", [])
	
	if stage < stages.size():
		return stages[stage].get("name", "Stade " + str(stage))
	
	return "Stade Inconnu"

func get_stage_description(creature_id: String, stage: int) -> String:
	"""Retourne la description du stade d'évolution actuel"""
	var creature_info = creature_database.get(creature_id, {})
	var stages = creature_info.get("evolution_stages", [])
	
	if stage < stages.size():
		return stages[stage].get("description", "Description non disponible")
	
	return "État évolutif mystérieux"

func calculate_evolution_progress(creature_data: Dictionary) -> float:
	"""Calcule le progrès vers la prochaine évolution (0.0 - 1.0)"""
	var current_stage = creature_data.current_stage
	var observation_count = creature_data.observation_count
	
	if current_stage >= EvolutionStage.STAGE_4_LEGENDARY:
		return 1.0  # Déjà au maximum
	
	var evolution_thresholds = observation_config.get("evolution_thresholds", [0, 3, 7, 12, 20])
	var next_stage = current_stage + 1
	
	if next_stage < evolution_thresholds.size():
		var current_threshold = evolution_thresholds[current_stage]
		var next_threshold = evolution_thresholds[next_stage]
		var progress = float(observation_count - current_threshold) / float(next_threshold - current_threshold)
		return clamp(progress, 0.0, 1.0)
	
	return 1.0

func generate_discoveries(creature_id: String, creature_data: Dictionary, intensity: float) -> Array[String]:
	"""Génère des découvertes basées sur l'observation"""
	var discoveries = []
	var stage = creature_data.current_stage
	
	# Découvertes basiques selon le stade
	match stage:
		EvolutionStage.STAGE_0_NORMAL:
			discoveries.append("Comportement naturel observé")
		EvolutionStage.STAGE_1_AWARE:
			discoveries.append("Signes de conscience accrue")
		EvolutionStage.STAGE_2_ENHANCED:
			discoveries.append("Capacités améliorées détectées")
		EvolutionStage.STAGE_3_MAGICAL:
			discoveries.append("Propriétés magiques manifestes")
		EvolutionStage.STAGE_4_LEGENDARY:
			discoveries.append("Forme légendaire atteinte")
	
	# Découvertes bonus basées sur l'intensité
	if intensity > 2.0:
		discoveries.append("Détails fins perceptibles")
	if intensity > 3.0:
		discoveries.append("Patterns comportementaux uniques")
	
	return discoveries

func get_current_abilities(creature_id: String, stage: int) -> Array[String]:
	"""Retourne les capacités actuelles de la créature"""
	# Utiliser le cache si disponible
	var cache_key = creature_id + "_" + str(stage)
	if ability_cache.has(cache_key):
		return ability_cache[cache_key]
	
	var abilities = []
	var creature_info = creature_database.get(creature_id, {})
	
	# Capacités par stade (exemple générique)
	match stage:
		EvolutionStage.STAGE_0_NORMAL:
			abilities = ["Survie de base"]
		EvolutionStage.STAGE_1_AWARE:
			abilities = ["Survie de base", "Conscience élevée"]
		EvolutionStage.STAGE_2_ENHANCED:
			abilities = ["Survie de base", "Conscience élevée", "Capacités renforcées"]
		EvolutionStage.STAGE_3_MAGICAL:
			abilities = ["Survie de base", "Conscience élevée", "Capacités renforcées", "Magie mineure"]
		EvolutionStage.STAGE_4_LEGENDARY:
			abilities = ["Survie de base", "Conscience élevée", "Capacités renforcées", "Magie mineure", "Pouvoirs légendaires"]
	
	# Capacités spécifiques depuis la base de données
	if creature_info.has("abilities"):
		var creature_abilities = creature_info["abilities"]
		if creature_abilities.has(str(stage)):
			abilities.extend(creature_abilities[str(stage)])
	
	# Mettre en cache
	ability_cache[cache_key] = abilities
	
	return abilities

func update_notebook_entry(creature_id: String, observation_data: Dictionary) -> void:
	"""Met à jour une entrée du carnet magique"""
	var entry_data = {
		"creature_id": creature_id,
		"timestamp": Time.get_unix_time_from_system(),
		"stage": observation_data.current_stage,
		"discoveries": observation_data.discoveries,
		"observation_count": observation_data.observation_count
	}
	
	notebook_entry_added.emit(creature_id, entry_data)

func roll_magic_cascade(epicenter: Vector2, intensity: float) -> void:
	"""Lance les dés pour un événement magique en cascade"""
	var base_chance = observation_config.get("cascade_base_chance", 0.15)
	var cascade_chance = base_chance * intensity * magic_disruption_level
	
	if randf() < cascade_chance:
		var cascade_intensity = intensity * magic_amplification * randf_range(0.5, 1.5)
		magic_cascade_triggered.emit(epicenter, cascade_intensity)
		
		if debug_mode:
			print("✨ Cascade magique déclenchée! Intensité:", cascade_intensity)

func update_evolution_cache(creature_id: String, stage: int) -> void:
	"""Met à jour le cache d'évolution"""
	evolution_cache[creature_id] = stage

func _decay_magic_disruption() -> void:
	"""Décroissance naturelle de la perturbation magique"""
	if magic_disruption_level > 0.0:
		var old_level = magic_disruption_level
		var decay_rate = observation_config.get("disruption_decay_rate", 0.01)
		magic_disruption_level = max(0.0, magic_disruption_level - decay_rate)
		
		if abs(magic_disruption_level - old_level) > 0.001:
			magic_disruption_changed.emit(old_level, magic_disruption_level)

# ============================================================================
# API PUBLIQUE POUR AUTRES SYSTÈMES
# ============================================================================

func get_creature_stage(creature_id: String) -> int:
	"""Retourne le stade d'évolution actuel d'une créature"""
	if observed_creatures.has(creature_id):
		return observed_creatures[creature_id].current_stage
	return EvolutionStage.STAGE_0_NORMAL

func get_magic_disruption_level() -> float:
	"""Retourne le niveau actuel de perturbation magique (0.0 - 1.0)"""
	return magic_disruption_level

func get_total_observations() -> int:
	"""Retourne le nombre total d'observations effectuées"""
	return total_observations

func get_observed_creatures() -> Dictionary:
	"""Retourne la liste de toutes les créatures observées"""
	return observed_creatures.duplicate()

func force_evolution(creature_id: String, target_stage: int) -> bool:
	"""Force l'évolution d'une créature (pour debug/events spéciaux)"""
	if not observed_creatures.has(creature_id):
		initialize_creature_observation(creature_id)
	
	if target_stage <= EvolutionStage.STAGE_4_LEGENDARY:
		var creature_data = observed_creatures[creature_id]
		trigger_evolution(creature_id, creature_data, target_stage)
		return true
	
	return false

func reset_observations() -> void:
	"""Remet à zéro toutes les observations (pour testing)"""
	observed_creatures.clear()
	magic_amplification = 1.0
	magic_disruption_level = 0.0
	total_observations = 0
	evolution_cache.clear()
	ability_cache.clear()
	
	if debug_mode:
		print("🔄 Observations reset")

# ============================================================================
# SYSTÈME DE SAUVEGARDE
# ============================================================================

func get_save_data() -> Dictionary:
	"""Retourne les données à sauvegarder"""
	return {
		"observed_creatures": observed_creatures,
		"magic_amplification": magic_amplification,
		"magic_disruption_level": magic_disruption_level,
		"total_observations": total_observations,
		"evolution_cache": evolution_cache
	}

func apply_save_data(save_data: Dictionary) -> void:
	"""Applique les données de sauvegarde"""
	observed_creatures = save_data.get("observed_creatures", {})
	magic_amplification = save_data.get("magic_amplification", 1.0)
	magic_disruption_level = save_data.get("magic_disruption_level", 0.0)
	total_observations = save_data.get("total_observations", 0)
	evolution_cache = save_data.get("evolution_cache", {})
	
	if debug_mode:
		print("🔮 Données d'observation restaurées")

# ============================================================================
# DEBUG & VALIDATION
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Commandes debug (à retirer en production)"""
	if not debug_mode or not OS.is_debug_build():
		return
		
	if event.is_action_pressed("debug_observe_maurice"):
		observe_creature("rat_maurice", ObservationType.DETAILED, Vector2(100, 100))
	elif event.is_action_pressed("debug_force_evolution"):
		force_evolution("rat_maurice", EvolutionStage.STAGE_3_MAGICAL)
	elif event.is_action_pressed("debug_reset_observations"):
		reset_observations()
	elif event.is_action_pressed("debug_print_status"):
		print_debug_info()

func print_debug_info() -> void:
	"""Affiche les informations de debug du système"""
	print("=== OBSERVATION MANAGER DEBUG ===")
	print("Système initialisé: ", system_initialized)
	print("Total observations: ", total_observations)
	print("Magic amplification: ", magic_amplification)
	print("Disruption level: ", magic_disruption_level)
	print("Créatures observées: ", observed_creatures.size())
	print("Créatures en base: ", creature_database.size())
	
	for creature_id in observed_creatures:
		var data = observed_creatures[creature_id]
		print("- ", creature_id, ": Stage ", data.current_stage, " (", data.observation_count, " obs)")

func validate_system_integrity() -> bool:
	"""Valide l'intégrité du système d'observation"""
	var is_valid = true
	
	# Vérifier que les créatures observées existent dans la base
	for creature_id in observed_creatures:
		if not creature_database.has(creature_id):
			push_error("🔮 Créature observée absente de la base: " + creature_id)
			is_valid = false
	
	# Vérifier que les stades d'évolution sont valides
	for creature_id in observed_creatures:
		var creature_data = observed_creatures[creature_id]
		var stage = creature_data.current_stage
		if stage < 0 or stage > EvolutionStage.STAGE_4_LEGENDARY:
			push_error("🔮 Stade d'évolution invalide pour " + creature_id + ": " + str(stage))
			is_valid = false
	
	if is_valid and debug_mode:
		print("✅ Intégrité système observation validée")
	
	return is_valid

# ============================================================================
# NOTES DE DÉVELOPPEMENT
# ============================================================================

## FONCTIONNALITÉS COMPLÉTÉES:
## ✅ Architecture complète avec signaux event-driven
## ✅ Intégration DataManager pour chargement JSON
## ✅ Système d'évolution par observation
## ✅ Amplification magique globale
## ✅ Perturbation magique avec décroissance
## ✅ Cache d'optimisation pour performances
## ✅ Système de sauvegarde complet
## ✅ API publique pour autres managers
## ✅ Validation et debug intégrés

## PROCHAINES ÉTAPES POSSIBLES:
## 🔜 Interface UI pour carnet magique
## 🔜 Animations d'évolution
## 🔜 Effets visuels pour cascades magiques
## 🔜 Système de récompenses d'observation
## 🔜 Mécaniques avancées (observation en groupe, équipement)