# 🔮 ObservationManager.gd - Système Unique du Jeu
# STATUS: 🔄 IN_PROGRESS | ROADMAP: Mois 1, Semaine 1-2 - Core Architecture
# PRIORITY: 🔴 CRITICAL - Cœur du gameplay unique
# DEPENDENCIES: GameManager (à venir)

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

# ============================================================================
# CONFIGURATION & DONNÉES
# ============================================================================

## Configuration système chargée depuis JSON
@export var config_file_path: String = "res://data/observation_config.json"
var observation_config: Dictionary = {}

## Base de données des créatures
var creature_database: Dictionary = {}
var observed_creatures: Dictionary = {}

## État global du système
var magic_amplification: float = 1.0
var total_observations: int = 0
var magic_disruption_level: float = 0.0

## Constantes d'équilibrage
const MAX_OBSERVATION_LEVEL: int = 5
const BASE_EVOLUTION_THRESHOLD: int = 3
const MAGIC_AMPLIFICATION_RATE: float = 0.1
const CASCADE_PROBABILITY_BASE: float = 0.15

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
	load_configuration()
	load_creature_database()
	setup_magic_amplification()
	connect_to_game_systems()
	
	print("🔮 ObservationManager: Système initialisé")

func load_configuration() -> void:
	"""Charge la configuration depuis le fichier JSON"""
	if FileAccess.file_exists(config_file_path):
		var file = FileAccess.open(config_file_path, FileAccess.READ)
		var json_text = file.get_as_text()
		file.close()
		
		var json = JSON.new()
		var parse_result = json.parse(json_text)
		
		if parse_result == OK:
			observation_config = json.data
			print("✅ Configuration chargée: ", observation_config.size(), " paramètres")
		else:
			print("❌ Erreur parsing config JSON:", json.get_error_message())
			load_default_configuration()
	else:
		print("⚠️ Fichier config non trouvé, chargement config par défaut")
		load_default_configuration()

func load_default_configuration() -> void:
	"""Configuration par défaut si fichier absent"""
	observation_config = {
		"evolution_thresholds": [0, 3, 7, 12, 20],
		"magic_amplification_max": 5.0,
		"cascade_base_chance": 0.15,
		"notebook_auto_entries": true,
		"evolution_animations": true
	}

func load_creature_database() -> void:
	"""Charge la base de données des créatures depuis JSON"""
	# TODO: Implémenter chargement depuis creature_database.json
	# Pour l'instant, données de test
	setup_test_creatures()

func setup_test_creatures() -> void:
	"""Données de test pour validation système"""
	creature_database = {
		"pigeon_ankh": {
			"name": "Pigeon d'Ankh-Morpork",
			"latin_name": "Columba ankhmorporkensis",
			"base_intelligence": 2,
			"evolution_stages": [
				{"name": "Pigeon Normal", "description": "Pigeon urbain standard"},
				{"name": "Pigeon Observateur", "description": "Regard plus intelligent"},
				{"name": "Pigeon Organisé", "description": "Vol en formation militaire"},
				{"name": "Pigeon Messager", "description": "Service postal efficace"},
				{"name": "Pigeon Stratège", "description": "Coordination urbaine complexe"}
			]
		},
		"cat_street": {
			"name": "Chat de Gouttière",
			"latin_name": "Felis streeticus",
			"base_intelligence": 4,
			"evolution_stages": [
				{"name": "Chat Standard", "description": "Félin urbain indépendant"},
				{"name": "Chat Attentif", "description": "Écoute les conversations"},
				{"name": "Chat Espion", "description": "Surveillance stratégique"},
				{"name": "Chat Réseau", "description": "Communication inter-féline"},
				{"name": "Chat Maître-Espion", "description": "Réseau de renseignement"}
			]
		},
		"rat_maurice": {
			"name": "Rat Intelligent",
			"latin_name": "Rattus sapiens",
			"base_intelligence": 6,
			"unique": true,
			"evolution_stages": [
				{"name": "Rat Parlant", "description": "Communication basique"},
				{"name": "Rat Éduqué", "description": "Monocle et vocabulaire"},
				{"name": "Rat Bureaucrate", "description": "Compréhension administrative"},
				{"name": "Rat Conseiller", "description": "Sagesse et diplomatie"},
				{"name": "Rat Philosophe", "description": "Insights métaphysiques"}
			]
		}
	}

# ============================================================================
# SYSTÈME D'OBSERVATION PRINCIPAL
# ============================================================================

func observe_creature(creature_id: String, observation_type: ObservationType = ObservationType.ACTIVE, observer_position: Vector2 = Vector2.ZERO) -> Dictionary:
	"""
	Fonction principale d'observation des créatures
	Retourne les données d'observation pour mise à jour UI
	"""
	
	# Validation de la créature
	if not creature_database.has(creature_id):
		print("❌ Créature inconnue: ", creature_id)
		return {}
	
	# Initialisation des données d'observation si première fois
	if not observed_creatures.has(creature_id):
		initialize_creature_observation(creature_id)
	
	# Augmentation du compteur d'observations
	var creature_data = observed_creatures[creature_id]
	creature_data.observation_count += 1
	creature_data.last_observation_time = Time.get_unix_time_from_system()
	creature_data.observation_types.append(observation_type)
	
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
	
	# Mise à jour du carnet si configuré
	if observation_config.get("notebook_auto_entries", true):
		update_notebook_entry(creature_id, observation_result)
	
	# Chance d'événement magique en cascade
	roll_magic_cascade(observer_position, observation_intensity)
	
	total_observations += 1
	
	print("🔍 Observation: ", creature_id, " (", observation_intensity, " intensité)")
	
	return observation_result

func initialize_creature_observation(creature_id: String) -> void:
	"""Initialise les données d'observation pour une nouvelle créature"""
	observed_creatures[creature_id] = {
		"observation_count": 0,
		"current_stage": EvolutionStage.STAGE_0_NORMAL,
		"evolution_progress": 0.0,
		"first_observation_time": Time.get_unix_time_from_system(),
		"last_observation_time": 0,
		"observation_types": [],
		"special_events": [],
		"magic_affinity": 0.0
	}

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
	
	# Bonus d'amplification magique globale
	base_intensity *= magic_amplification
	
	# Diminution si observation répétitive (évite le spam)
	if creature_data.observation_count > 5:
		var repetition_penalty = 1.0 / (1.0 + (creature_data.observation_count - 5) * 0.1)
		base_intensity *= repetition_penalty
	
	# Bonus pour créatures uniques (comme Maurice)
	var creature_info = creature_database.get(creature_data.get("creature_id", ""))
	if creature_info and creature_info.get("unique", false):
		base_intensity *= 1.5
	
	return base_intensity

# ============================================================================
# SYSTÈME D'ÉVOLUTION DES CRÉATURES
# ============================================================================

func check_evolution_threshold(creature_id: String, creature_data: Dictionary) -> void:
	"""Vérifie si la créature peut évoluer vers le stade suivant"""
	var current_stage = creature_data.current_stage
	
	if current_stage >= EvolutionStage.STAGE_4_LEGENDARY:
		return  # Déjà au maximum
	
	var evolution_thresholds = observation_config.get("evolution_thresholds", [0, 3, 7, 12, 20])
	var next_stage = current_stage + 1
	
	if next_stage < evolution_thresholds.size():
		var threshold = evolution_thresholds[next_stage]
		
		if creature_data.observation_count >= threshold:
			trigger_evolution(creature_id, creature_data, next_stage)

func trigger_evolution(creature_id: String, creature_data: Dictionary, new_stage: int) -> void:
	"""Déclenche l'évolution d'une créature vers un nouveau stade"""
	var old_stage = creature_data.current_stage
	creature_data.current_stage = new_stage
	creature_data.evolution_progress = 1.0
	
	# Ajout d'événement spécial
	creature_data.special_events.append({
		"type": "evolution",
		"from_stage": old_stage,
		"to_stage": new_stage,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Augmentation de l'affinité magique
	creature_data.magic_affinity += 0.2 * new_stage
	
	# Émission du signal d'évolution
	creature_evolved.emit(creature_id, old_stage, new_stage)
	
	# Animation si configurée
	if observation_config.get("evolution_animations", true):
		play_evolution_animation(creature_id, old_stage, new_stage)
	
	print("✨ ÉVOLUTION: ", creature_id, " → Stade ", new_stage)

func play_evolution_animation(creature_id: String, old_stage: int, new_stage: int) -> void:
	"""Joue l'animation d'évolution (placeholder pour l'instant)"""
	# TODO: Intégration avec système d'animation
	print("🎬 Animation évolution: ", creature_id, " (", old_stage, "→", new_stage, ")")

# ============================================================================
# SYSTÈME D'AMPLIFICATION MAGIQUE
# ============================================================================

func update_magic_amplification(observation_intensity: float) -> void:
	"""Met à jour l'amplification magique globale"""
	var old_amplification = magic_amplification
	var increment = observation_intensity * MAGIC_AMPLIFICATION_RATE
	
	# Augmentation avec plafond
	var max_amplification = observation_config.get("magic_amplification_max", 5.0)
	magic_amplification = min(magic_amplification + increment, max_amplification)
	
	# Mise à jour du niveau de perturbation
	var old_disruption = magic_disruption_level
	magic_disruption_level = (magic_amplification - 1.0) / (max_amplification - 1.0)
	
	# Émission signal si changement significatif
	if abs(old_disruption - magic_disruption_level) > 0.05:
		magic_disruption_changed.emit(old_disruption, magic_disruption_level)

func setup_magic_amplification() -> void:
	"""Configuration initiale de l'amplification magique"""
	magic_amplification = 1.0
	magic_disruption_level = 0.0

# ============================================================================
# SYSTÈME DE CASCADE MAGIQUE
# ============================================================================

func roll_magic_cascade(epicenter: Vector2, intensity: float) -> void:
	"""Calcule la probabilité et déclenche éventuellement une cascade magique"""
	var base_chance = observation_config.get("cascade_base_chance", CASCADE_PROBABILITY_BASE)
	var cascade_chance = base_chance * intensity * magic_amplification
	
	# Bonus selon le niveau de perturbation global
	cascade_chance *= (1.0 + magic_disruption_level)
	
	if randf() < cascade_chance:
		trigger_magic_cascade(epicenter, intensity)

func trigger_magic_cascade(epicenter: Vector2, intensity: float) -> void:
	"""Déclenche un événement de cascade magique"""
	print("💥 CASCADE MAGIQUE! Position: ", epicenter, " Intensité: ", intensity)
	
	# Émission du signal pour les autres systèmes
	magic_cascade_triggered.emit(epicenter, intensity)
	
	# Effets locaux (à implémenter avec les autres systèmes)
	apply_cascade_effects(epicenter, intensity)

func apply_cascade_effects(epicenter: Vector2, intensity: float) -> void:
	"""Applique les effets d'une cascade magique"""
	# TODO: Intégration avec systèmes météo, environnement, NPCs
	# Pour l'instant, log pour validation
	print("🌊 Effets cascade appliqués - Intensité: ", intensity)

# ============================================================================
# INTERFACE CARNET MAGIQUE
# ============================================================================

func update_notebook_entry(creature_id: String, observation_data: Dictionary) -> void:
	"""Met à jour le carnet magique avec nouvelles observations"""
	var entry_data = {
		"creature_id": creature_id,
		"observation_count": observation_data.get("observation_count", 0),
		"current_stage": observation_data.get("current_stage", 0),
		"timestamp": Time.get_unix_time_from_system(),
		"new_info": observation_data.get("discoveries", [])
	}
	
	notebook_entry_added.emit(creature_id, entry_data)

# ============================================================================
# GÉNÉRATION DONNÉES D'OBSERVATION
# ============================================================================

func generate_observation_data(creature_id: String, creature_data: Dictionary, intensity: float) -> Dictionary:
	"""Génère les données complètes d'observation pour l'interface"""
	var creature_info = creature_database.get(creature_id, {})
	var current_stage = creature_data.current_stage
	
	var observation_result = {
		"creature_id": creature_id,
		"creature_name": creature_info.get("name", "Créature Inconnue"),
		"latin_name": creature_info.get("latin_name", "Specialis unknownus"),
		"observation_count": creature_data.observation_count,
		"current_stage": current_stage,
		"stage_name": get_stage_name(creature_id, current_stage),
		"stage_description": get_stage_description(creature_id, current_stage),
		"magic_affinity": creature_data.magic_affinity,
		"evolution_progress": calculate_evolution_progress(creature_data),
		"discoveries": generate_discoveries(creature_id, creature_data, intensity),
		"special_abilities": get_current_abilities(creature_id, current_stage)
	}
	
	return observation_result

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

func generate_discoveries(creature_id: String, creature_data: Dictionary, intensity: float) -> Array:
	"""Génère les nouvelles découvertes basées sur l'observation"""
	var discoveries = []
	
	# Nouvelles découvertes selon l'intensité et le nombre d'observations
	if intensity > 2.0:
		discoveries.append("Comportement inhabituel détecté")
	
	if creature_data.observation_count == 1:
		discoveries.append("Première observation documentée")
	elif creature_data.observation_count == 5:
		discoveries.append("Patterns comportementaux établis")
	elif creature_data.observation_count == 10:
		discoveries.append("Adaptation évidente à l'observation")
	
	# Découvertes spéciales selon l'affinité magique
	if creature_data.magic_affinity > 1.0:
		discoveries.append("Aura magique détectable")
	
	return discoveries

func get_current_abilities(creature_id: String, stage: int) -> Array:
	"""Retourne les capacités spéciales actuelles de la créature"""
	# TODO: Système de capacités évolutives complet
	var abilities = []
	
	match stage:
		EvolutionStage.STAGE_1_AWARE:
			abilities.append("Conscience accrue")
		EvolutionStage.STAGE_2_ENHANCED:
			abilities.append("Capacités améliorées")
		EvolutionStage.STAGE_3_MAGICAL:
			abilities.append("Propriétés magiques")
		EvolutionStage.STAGE_4_LEGENDARY:
			abilities.append("Pouvoirs légendaires")
	
	return abilities

# ============================================================================
# CONNECTION AUX AUTRES SYSTÈMES
# ============================================================================

func connect_to_game_systems() -> void:
	"""Connecte l'ObservationManager aux autres systèmes du jeu"""
	# TODO: Connexions avec GameManager, UIManager, etc.
	print("🔗 Connexions systèmes à implémenter")

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
	print("🔄 Observations reset")

# ============================================================================
# DEBUG & VALIDATION
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Commandes debug (à retirer en production)"""
	if OS.is_debug_build():
		if event.is_action_pressed("debug_observe"):
			# Test observation sur Maurice
			observe_creature("rat_maurice", ObservationType.DETAILED, Vector2(100, 100))
		elif event.is_action_pressed("debug_reset"):
			reset_observations()

func print_debug_info() -> void:
	"""Affiche les informations de debug du système"""
	print("=== OBSERVATION MANAGER DEBUG ===")
	print("Total observations: ", total_observations)
	print("Magic amplification: ", magic_amplification)
	print("Disruption level: ", magic_disruption_level)
	print("Creatures observées: ", observed_creatures.size())
	
	for creature_id in observed_creatures:
		var data = observed_creatures[creature_id]
		print("- ", creature_id, ": Stade ", data.current_stage, " (", data.observation_count, " obs)")

# ============================================================================
# NOTES DE DÉVELOPPEMENT
# ============================================================================

## TODO PRIORITAIRES:
## 1. Intégration avec GameManager pour singleton
## 2. Chargement creature_database.json depuis fichier
## 3. Connexion avec NotebookUI pour interface
## 4. Système d'animations d'évolution
## 5. Tests unitaires complets

## EXTENSIONS FUTURES (DLC):
## - Nouvelles espèces et évolutions
## - Mécaniques d'observation régionales
## - Interactions inter-créatures
## - Système de breeding/hybridation
## - Pouvoirs d'observation du joueur

## OPTIMISATIONS:
## - Cache des calculs intensifs
## - Système de pooling pour créatures
## - Sauvegarde incrémentale des observations
## - Compression des données historiques