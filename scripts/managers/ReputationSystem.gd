# ============================================================================
# 🏛️ ReputationSystem.gd - Système des 8 Factions Terry Pratchett
# ============================================================================
# STATUS: ✅ NOUVEAU SYSTÈME | ROADMAP: Mois 1, Semaine 3-4 - Gameplay Avancé
# PRIORITY: 🔴 CRITICAL - Immersion narrative et conséquences actions
# DEPENDENCIES: GameManager, DataManager, QuestManager, DialogueManager

class_name ReputationSystem
extends Node

## Gestionnaire des relations avec les 8 factions d'Ankh-Morpork
## Système dynamique avec conséquences narratives et gameplay
## Architecture Terry Pratchett authentique avec relations complexes

# ============================================================================
# SIGNAUX - Communication Event-Driven
# ============================================================================

## Émis quand la réputation avec une faction change
signal reputation_changed(faction_id: String, old_value: int, new_value: int, reason: String)

## Émis quand le niveau de relation change (hostile->unfriendly, etc.)
signal relationship_level_changed(faction_id: String, old_level: String, new_level: String)

## Émis quand un conflit entre factions se déclenche
signal faction_conflict_triggered(faction1: String, faction2: String, conflict_type: String)

## Émis quand un service devient disponible/indisponible
signal service_access_changed(faction_id: String, service_id: String, accessible: bool)

## Émis quand le joueur atteint la maîtrise d'une faction
signal faction_mastery_achieved(faction_id: String, mastery_level: String)

## Émis quand une réaction publique se produit
signal public_reaction_triggered(event_type: String, reputation_changes: Dictionary)

## Signal pour communication avec autres managers
signal manager_initialized()

# ============================================================================
# CONFIGURATION & DONNÉES
# ============================================================================

## Données chargées depuis DataManager
var faction_data: Dictionary = {}
var player_reputations: Dictionary = {}
var faction_relationships: Dictionary = {}
var active_conflicts: Dictionary = {}

## Configuration système
var reputation_config: Dictionary = {
	"max_reputation": 100,
	"min_reputation": -100,
	"decay_enabled": true,
	"decay_rate": 0.1,  # par jour
	"conflict_threshold": 60,  # différence déclenchant conflit
	"mastery_threshold": 80,
	"public_reaction_threshold": 30
}

## État système
var reputation_levels: Dictionary = {
	"hostile": [-100, -51],
	"unfriendly": [-50, -21], 
	"neutral": [-20, 20],
	"friendly": [21, 50],
	"allied": [51, 80],
	"devoted": [81, 100]
}

## Cache pour optimisation
var service_cache: Dictionary = {}
var conflict_cache: Dictionary = {}
var relationship_cache: Dictionary = {}

## Historique pour analytics
var reputation_history: Array[Dictionary] = []
var major_events: Array[Dictionary] = []

## Flags système
var system_initialized: bool = false
var debug_mode: bool = false

# ============================================================================
# LISTE DES 8 FACTIONS TERRY PRATCHETT
# ============================================================================

const MAIN_FACTIONS = [
	"patrician",        # Administration Patricienne (Lord Vetinari)
	"university",       # Université de l'Invisible
	"guilds",          # Guildes Professionnelles (Voleurs, Assassins, etc.)
	"common_folk",     # Citoyens Ordinaires
	"creatures",       # Communauté des Créatures Évoluées
	"watch",           # Guet d'Ankh-Morpork (Samuel Vimes)
	"magical_community", # Communauté Magique Traditionnelle
	"underworld"       # Pègre et Crime Organisé
]

# ============================================================================
# INITIALISATION SYSTÈME
# ============================================================================

func _ready() -> void:
	"""Initialisation du système de réputation"""
	if debug_mode:
		print("🏛️ ReputationSystem: Démarrage initialisation...")
	
	# Attendre que DataManager soit prêt
	await ensure_datamanager_ready()
	
	# Charger données et configuration
	load_faction_data()
	initialize_player_reputations()
	setup_faction_relationships()
	
	# Configuration système
	setup_reputation_decay()
	connect_to_game_systems()
	
	# Finalisation
	system_initialized = true
	manager_initialized.emit()
	
	if debug_mode:
		print("🏛️ ReputationSystem: Système initialisé avec succès")
		print_reputation_summary()

func ensure_datamanager_ready() -> void:
	"""S'assure que DataManager est prêt"""
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager and not data_manager.loading_complete:
		await data_manager.all_data_loaded

func load_faction_data() -> void:
	"""Charge les données des factions depuis DataManager"""
	var data_manager = get_node_or_null("/root/DataManager")
	
	if data_manager and not data_manager.faction_relationships.is_empty():
		faction_data = data_manager.faction_relationships
		
		# Charger la configuration spécifique du système
		if faction_data.has("faction_system"):
			var system_config = faction_data["faction_system"]
			if system_config.has("reputation_scale"):
				reputation_levels = system_config["reputation_scale"]
		
		if debug_mode:
			print("✅ Données factions chargées:", faction_data.get("metadata", {}).get("total_factions", 0), "factions")
	else:
		# Fallback avec données minimales
		setup_fallback_faction_data()
		if debug_mode:
			print("⚠️ Données factions fallback utilisées")

func setup_fallback_faction_data() -> void:
	"""Données de test minimales si JSON absent"""
	faction_data = {
		"factions": {},
		"inter_faction_relationships": {},
		"reputation_events": {}
	}
	
	# Créer des données minimales pour chaque faction
	for faction_id in MAIN_FACTIONS:
		faction_data["factions"][faction_id] = {
			"name": faction_id.capitalize(),
			"starting_reputation": 0,
			"services": {},
			"reputation_modifiers": {}
		}

func initialize_player_reputations() -> void:
	"""Initialise les réputations du joueur avec chaque faction"""
	player_reputations.clear()
	
	if faction_data.has("factions"):
		for faction_id in faction_data["factions"]:
			var faction_info = faction_data["factions"][faction_id]
			var starting_rep = faction_info.get("starting_reputation", 0)
			player_reputations[faction_id] = starting_rep
			
			if debug_mode:
				print("🎯 Réputation initiale:", faction_id, "=", starting_rep)

func setup_faction_relationships() -> void:
	"""Configure les relations entre factions"""
	if faction_data.has("inter_faction_relationships"):
		faction_relationships = faction_data["inter_faction_relationships"]
		
		# Précharger les conflits potentiels
		if faction_data.has("faction_conflicts"):
			for conflict_id in faction_data["faction_conflicts"]:
				var conflict = faction_data["faction_conflicts"][conflict_id]
				conflict_cache[conflict_id] = conflict

func setup_reputation_decay() -> void:
	"""Configure la décroissance naturelle de réputation"""
	if reputation_config.get("decay_enabled", true):
		var decay_timer = Timer.new()
		decay_timer.wait_time = 86400.0  # 24 heures en secondes
		decay_timer.timeout.connect(_process_daily_decay)
		add_child(decay_timer)
		decay_timer.start()

func connect_to_game_systems() -> void:
	"""Connecte le ReputationSystem aux autres managers"""
	# Connexion avec QuestManager pour réputation par quêtes
	var quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager:
		quest_manager.quest_completed.connect(_on_quest_completed)
		quest_manager.quest_failed.connect(_on_quest_failed)
	
	# Connexion avec DialogueManager pour choix de réputation
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		dialogue_manager.choice_made.connect(_on_dialogue_choice_made)
		dialogue_manager.conversation_ended.connect(_on_conversation_ended)
	
	# Connexion avec ObservationManager pour actions d'observation
	var observation_manager = get_node_or_null("/root/ObservationManager")
	if observation_manager:
		observation_manager.creature_evolved.connect(_on_creature_evolved)
		observation_manager.magic_cascade_triggered.connect(_on_magic_cascade)

# ============================================================================
# API PRINCIPALE - GESTION RÉPUTATION
# ============================================================================

func modify_reputation(faction_id: String, change: int, reason: String = "action") -> bool:
	"""
	Modifie la réputation avec une faction
	Retourne true si le changement a été appliqué
	"""
	if not system_initialized:
		push_error("🏛️ ReputationSystem: Système non initialisé!")
		return false
	
	if not player_reputations.has(faction_id):
		push_warning("🏛️ Faction inconnue: " + faction_id)
		return false
	
	var old_reputation = player_reputations[faction_id]
	var old_level = get_reputation_level(faction_id)
	
	# Appliquer le changement avec limites
	var new_reputation = clamp(
		old_reputation + change,
		reputation_config.min_reputation,
		reputation_config.max_reputation
	)
	
	# Vérifier si changement significatif
	if new_reputation == old_reputation:
		return false
	
	# Appliquer le changement
	player_reputations[faction_id] = new_reputation
	var new_level = get_reputation_level(faction_id)
	
	# Historique pour analytics
	record_reputation_change(faction_id, old_reputation, new_reputation, reason)
	
	# Émission des signaux
	reputation_changed.emit(faction_id, old_reputation, new_reputation, reason)
	
	if old_level != new_level:
		relationship_level_changed.emit(faction_id, old_level, new_level)
		update_service_cache(faction_id, new_level)
		
		# Vérifier maîtrise de faction
		check_faction_mastery(faction_id, new_reputation)
	
	# Effets en cascade sur autres factions
	process_reputation_cascade(faction_id, change, reason)
	
	# Vérifier déclenchement de conflits
	check_faction_conflicts(faction_id)
	
	# Événements publics si changement majeur
	if abs(change) >= reputation_config.public_reaction_threshold:
		trigger_public_reaction(faction_id, change, reason)
	
	if debug_mode:
		print("🔄 Réputation modifiée:", faction_id, old_reputation, "→", new_reputation, "(", reason, ")")
	
	return true

func get_reputation(faction_id: String) -> int:
	"""Retourne la réputation actuelle avec une faction"""
	return player_reputations.get(faction_id, 0)

func get_reputation_level(faction_id: String) -> String:
	"""Retourne le niveau de relation textuel avec une faction"""
	var reputation = get_reputation(faction_id)
	
	for level in reputation_levels:
		var range = reputation_levels[level]
		if reputation >= range[0] and reputation <= range[1]:
			return level
	
	return "neutral"

func get_all_reputations() -> Dictionary:
	"""Retourne toutes les réputations actuelles"""
	return player_reputations.duplicate()

func calculate_faction_influence(faction_id: String) -> float:
	"""Calcule l'influence relative d'une faction (0.0 - 1.0)"""
	var reputation = get_reputation(faction_id)
	var normalized = float(reputation - reputation_config.min_reputation) / float(reputation_config.max_reputation - reputation_config.min_reputation)
	return clamp(normalized, 0.0, 1.0)

# ============================================================================
# SYSTÈME DE SERVICES PAR FACTION
# ============================================================================

func is_service_available(faction_id: String, service_id: String) -> bool:
	"""Vérifie si un service est accessible au niveau de réputation actuel"""
	var cache_key = faction_id + "_" + service_id
	if service_cache.has(cache_key):
		return service_cache[cache_key]
	
	var faction_info = faction_data.get("factions", {}).get(faction_id, {})
	var services = faction_info.get("services", {})
	
	if not services.has(service_id):
		return false
	
	var service = services[service_id]
	var required_level = service.get("access_level", "neutral")
	var current_level = get_reputation_level(faction_id)
	
	var level_hierarchy = ["hostile", "unfriendly", "neutral", "friendly", "allied", "devoted"]
	var required_index = level_hierarchy.find(required_level)
	var current_index = level_hierarchy.find(current_level)
	
	var accessible = current_index >= required_index
	service_cache[cache_key] = accessible
	
	return accessible

func get_service_price_modifier(faction_id: String, service_id: String) -> float:
	"""Retourne le modificateur de prix pour un service"""
	var faction_info = faction_data.get("factions", {}).get(faction_id, {})
	var services = faction_info.get("services", {})
	
	if not services.has(service_id):
		return 1.0
	
	var service = services[service_id]
	return service.get("price_modifier", 1.0)

func get_available_services(faction_id: String) -> Array[String]:
	"""Retourne la liste des services accessibles pour une faction"""
	var available = []
	var faction_info = faction_data.get("factions", {}).get(faction_id, {})
	var services = faction_info.get("services", {})
	
	for service_id in services:
		if is_service_available(faction_id, service_id):
			available.append(service_id)
	
	return available

func update_service_cache(faction_id: String, new_level: String) -> void:
	"""Met à jour le cache des services après changement de niveau"""
	var keys_to_remove = []
	for cache_key in service_cache:
		if cache_key.begins_with(faction_id + "_"):
			keys_to_remove.append(cache_key)
	
	for key in keys_to_remove:
		service_cache.erase(key)

# ============================================================================
# ÉVÉNEMENTS ET RÉACTIONS
# ============================================================================

func process_reputation_cascade(source_faction: String, change: int, reason: String) -> void:
	"""Traite les effets en cascade sur les autres factions"""
	if not faction_relationships.has(source_faction):
		return
	
	var source_relations = faction_relationships[source_faction]
	
	for target_faction in source_relations:
		if target_faction == source_faction:
			continue
		
		var relationship_strength = source_relations[target_faction]
		var cascade_factor = 0.0
		
		# Calcul du facteur cascade basé sur la relation
		if relationship_strength > 50:
			cascade_factor = 0.3  # Alliés profitent des bonnes actions
		elif relationship_strength > 20:
			cascade_factor = 0.1  # Amis profitent un peu
		elif relationship_strength < -50:
			cascade_factor = -0.2  # Ennemis souffrent des bonnes actions
		elif relationship_strength < -20:
			cascade_factor = -0.1  # Rivaux souffrent un peu
		
		if cascade_factor != 0.0:
			var cascade_change = int(change * cascade_factor)
			if cascade_change != 0:
				modify_reputation(target_faction, cascade_change, "cascade_from_" + source_faction)

func check_faction_conflicts(changed_faction: String) -> void:
	"""Vérifie si des conflits entre factions doivent se déclencher"""
	var conflict_threshold = reputation_config.conflict_threshold
	
	for faction_id in player_reputations:
		if faction_id == changed_faction:
			continue
		
		var rep1 = get_reputation(changed_faction)
		var rep2 = get_reputation(faction_id)
		
		# Conflit si une faction très positive et l'autre très négative
		if abs(rep1 - rep2) >= conflict_threshold:
			if (rep1 > 60 and rep2 < -60) or (rep1 < -60 and rep2 > 60):
				trigger_faction_conflict(changed_faction, faction_id, "reputation_disparity")

func trigger_faction_conflict(faction1: String, faction2: String, conflict_type: String) -> void:
	"""Déclenche un conflit entre deux factions"""
	var conflict_id = faction1 + "_vs_" + faction2
	
	# Éviter conflits multiples
	if active_conflicts.has(conflict_id):
		return
	
	active_conflicts[conflict_id] = {
		"faction1": faction1,
		"faction2": faction2,
		"type": conflict_type,
		"start_time": Time.get_unix_time_from_system(),
		"intensity": 1,
		"escalation_stage": 0
	}
	
	# Événement majeur dans l'historique
	major_events.append({
		"type": "faction_conflict",
		"timestamp": Time.get_unix_time_from_system(),
		"faction1": faction1,
		"faction2": faction2,
		"conflict_type": conflict_type
	})
	
	faction_conflict_triggered.emit(faction1, faction2, conflict_type)
	
	if debug_mode:
		print("⚔️ Conflit déclenché:", faction1, "vs", faction2, "(", conflict_type, ")")

func trigger_public_reaction(faction_id: String, change: int, reason: String) -> void:
	"""Déclenche une réaction publique à une action majeure"""
	var event_type = ""
	var reputation_effects = {}
	
	if change > 0:
		event_type = "public_acclaim"
		# Action positive affecte positivement citoyens et watch
		reputation_effects["common_folk"] = int(change * 0.3)
		reputation_effects["watch"] = int(change * 0.2)
	else:
		event_type = "public_scandal"
		# Action négative affecte négativement la plupart des factions
		for other_faction in MAIN_FACTIONS:
			if other_faction != faction_id:
				reputation_effects[other_faction] = int(change * 0.1)
	
	# Appliquer les effets
	for target_faction in reputation_effects:
		modify_reputation(target_faction, reputation_effects[target_faction], "public_reaction")
	
	public_reaction_triggered.emit(event_type, reputation_effects)
	
	if debug_mode:
		print("📢 Réaction publique:", event_type, "pour action avec", faction_id)

func check_faction_mastery(faction_id: String, reputation: int) -> void:
	"""Vérifie si le joueur atteint la maîtrise d'une faction"""
	var mastery_threshold = reputation_config.mastery_threshold
	
	if reputation >= mastery_threshold:
		var mastery_level = ""
		if reputation >= 95:
			mastery_level = "legendary"
		elif reputation >= 85:
			mastery_level = "devoted"
		else:
			mastery_level = "master"
		
		# Vérifier si pas déjà atteint
		var faction_info = faction_data.get("factions", {}).get(faction_id, {})
		var current_mastery = faction_info.get("player_mastery", "none")
		
		if current_mastery != mastery_level:
			faction_data["factions"][faction_id]["player_mastery"] = mastery_level
			faction_mastery_achieved.emit(faction_id, mastery_level)
			
			# Événement majeur
			major_events.append({
				"type": "faction_mastery",
				"timestamp": Time.get_unix_time_from_system(),
				"faction": faction_id,
				"mastery_level": mastery_level,
				"reputation": reputation
			})
			
			if debug_mode:
				print("🏆 Maîtrise atteinte:", faction_id, "niveau", mastery_level)

# ============================================================================
# INTÉGRATION AVEC AUTRES SYSTÈMES
# ============================================================================

func _on_quest_completed(quest_id: String, completion_data: Dictionary) -> void:
	"""Réaction à la complétion d'une quête"""
	# Vérifier si la quête a des effets de réputation
	var quest_manager = get_node_or_null("/root/QuestManager")
	if not quest_manager:
		return
	
	var quest_data = quest_manager.get_quest_by_id(quest_id)
	if quest_data.has("reputation_effects"):
		var effects = quest_data["reputation_effects"]
		for faction_id in effects:
			var change = effects[faction_id]
			modify_reputation(faction_id, change, "quest_completion:" + quest_id)

func _on_quest_failed(quest_id: String, failure_reason: String) -> void:
	"""Réaction à l'échec d'une quête"""
	# Échec de quête peut avoir des conséquences négatives
	var quest_manager = get_node_or_null("/root/QuestManager")
	if not quest_manager:
		return
	
	var quest_data = quest_manager.get_quest_by_id(quest_id)
	if quest_data.has("failure_reputation_effects"):
		var effects = quest_data["failure_reputation_effects"]
		for faction_id in effects:
			var change = effects[faction_id]
			modify_reputation(faction_id, change, "quest_failure:" + quest_id)

func _on_dialogue_choice_made(npc_id: String, choice_data: Dictionary) -> void:
	"""Réaction aux choix de dialogue"""
	if choice_data.has("reputation_effects"):
		var effects = choice_data["reputation_effects"]
		for faction_id in effects:
			var change = effects[faction_id]
			modify_reputation(faction_id, change, "dialogue_choice:" + npc_id)

func _on_conversation_ended(npc_id: String, conversation_data: Dictionary) -> void:
	"""Réaction à la fin d'une conversation"""
	# Certaines conversations entières peuvent affecter la réputation
	if conversation_data.has("overall_reputation_effect"):
		var effects = conversation_data["overall_reputation_effect"]
		for faction_id in effects:
			var change = effects[faction_id]
			modify_reputation(faction_id, change, "conversation:" + npc_id)

func _on_creature_evolved(creature_id: String, old_stage: int, new_stage: int) -> void:
	"""Réaction à l'évolution des créatures"""
	# L'évolution des créatures affecte certaines factions
	var reputation_changes = {
		"creatures": 5,  # La communauté des créatures apprécie
		"university": 3,  # L'université est intriguée
		"common_folk": -2,  # Les citoyens sont inquiets
		"guilds": -3  # Les guildes voient une menace économique
	}
	
	for faction_id in reputation_changes:
		modify_reputation(faction_id, reputation_changes[faction_id], "creature_evolution:" + creature_id)

func _on_magic_cascade(epicenter: Vector2, intensity: float) -> void:
	"""Réaction aux cascades magiques"""
	# Les événements magiques majeurs affectent les factions
	if intensity > 5.0:
		var changes = {
			"magical_community": 8,  # Communauté magique fascinée
			"university": 6,  # Université intéressée
			"common_folk": -5,  # Citoyens effrayés
			"watch": -3  # Le guet inquiet pour l'ordre public
		}
		
		for faction_id in changes:
			modify_reputation(faction_id, changes[faction_id], "magic_cascade")

# ============================================================================
# DECAY ET ÉVÉNEMENTS PÉRIODIQUES
# ============================================================================

func _process_daily_decay() -> void:
	"""Traite la décroissance quotidienne naturelle des réputations"""
	if not reputation_config.get("decay_enabled", true):
		return
	
	var decay_rate = reputation_config.get("decay_rate", 0.1)
	
	for faction_id in player_reputations:
		var current_rep = player_reputations[faction_id]
		
		# Décroissance vers zéro (neutre)
		if current_rep > 0:
			var decay = max(1, int(current_rep * decay_rate))
			modify_reputation(faction_id, -decay, "natural_decay")
		elif current_rep < 0:
			var recovery = max(1, int(abs(current_rep) * decay_rate))
			modify_reputation(faction_id, recovery, "natural_recovery")

func record_reputation_change(faction_id: String, old_value: int, new_value: int, reason: String) -> void:
	"""Enregistre un changement de réputation dans l'historique"""
	var record = {
		"timestamp": Time.get_unix_time_from_system(),
		"faction": faction_id,
		"old_value": old_value,
		"new_value": new_value,
		"change": new_value - old_value,
		"reason": reason
	}
	
	reputation_history.append(record)
	
	# Garder seulement les 1000 derniers événements
	if reputation_history.size() > 1000:
		reputation_history = reputation_history.slice(-1000)

# ============================================================================
# API PUBLIQUE POUR AUTRES SYSTÈMES
# ============================================================================

func get_faction_opinion(faction_id: String) -> String:
	"""Retourne l'opinion textuelle d'une faction envers le joueur"""
	var level = get_reputation_level(faction_id)
	var faction_info = faction_data.get("factions", {}).get(faction_id, {})
	var faction_name = faction_info.get("name", faction_id)
	
	match level:
		"hostile":
			return faction_name + " vous considère comme un ennemi dangereux"
		"unfriendly":
			return faction_name + " vous regarde avec suspicion"
		"neutral":
			return faction_name + " ne vous connaît pas particulièrement"
		"friendly":
			return faction_name + " vous apprécie et vous fait confiance"
		"allied":
			return faction_name + " vous considère comme un allié précieux"
		"devoted":
			return faction_name + " vous vénère comme un héros légendaire"
		_:
			return faction_name + " a une opinion neutre"

func get_dominant_faction() -> String:
	"""Retourne la faction avec laquelle le joueur a la meilleure réputation"""
	var best_faction = ""
	var best_reputation = reputation_config.min_reputation - 1
	
	for faction_id in player_reputations:
		var reputation = player_reputations[faction_id]
		if reputation > best_reputation:
			best_reputation = reputation
			best_faction = faction_id
	
	return best_faction

func get_faction_conflicts() -> Dictionary:
	"""Retourne les conflits actifs entre factions"""
	return active_conflicts.duplicate()

func get_reputation_summary() -> Dictionary:
	"""Retourne un résumé complet des réputations"""
	var summary = {}
	
	for faction_id in player_reputations:
		var reputation = player_reputations[faction_id]
		var level = get_reputation_level(faction_id)
		var influence = calculate_faction_influence(faction_id)
		
		summary[faction_id] = {
			"reputation": reputation,
			"level": level,
			"influence": influence,
			"services_available": get_available_services(faction_id).size()
		}
	
	return summary

func force_reputation(faction_id: String, value: int) -> bool:
	"""Force une réputation spécifique (debug/événements spéciaux)"""
	if not player_reputations.has(faction_id):
		return false
	
	var old_value = player_reputations[faction_id]
	var change = value - old_value
	
	return modify_reputation(faction_id, change, "forced_change")

# ============================================================================
# SYSTÈME DE SAUVEGARDE
# ============================================================================

func get_save_data() -> Dictionary:
	"""Retourne les données à sauvegarder"""
	return {
		"player_reputations": player_reputations,
		"active_conflicts": active_conflicts,
		"reputation_history": reputation_history.slice(-100),  # Seulement les 100 derniers
		"major_events": major_events.slice(-50),  # Seulement les 50 derniers
		"faction_masteries": extract_faction_masteries()
	}

func apply_save_data(save_data: Dictionary) -> void:
	"""Applique les données de sauvegarde"""
	player_reputations = save_data.get("player_reputations", {})
	active_conflicts = save_data.get("active_conflicts", {})
	reputation_history = save_data.get("reputation_history", [])
	major_events = save_data.get("major_events", [])
	
	# Restaurer les maîtrises de faction
	var masteries = save_data.get("faction_masteries", {})
	for faction_id in masteries:
		if faction_data.has("factions") and faction_data["factions"].has(faction_id):
			faction_data["factions"][faction_id]["player_mastery"] = masteries[faction_id]
	
	# Invalider tous les caches
	service_cache.clear()
	relationship_cache.clear()
	
	if debug_mode:
		print("🏛️ Données de réputation restaurées")

func extract_faction_masteries() -> Dictionary:
	"""Extrait les maîtrises de faction pour sauvegarde"""
	var masteries = {}
	
	if faction_data.has("factions"):
		for faction_id in faction_data["factions"]:
			var faction_info = faction_data["factions"][faction_id]
			if faction_info.has("player_mastery"):
				masteries[faction_id] = faction_info["player_mastery"]
	
	return masteries

# ============================================================================
# DEBUG ET VALIDATION
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Commandes debug (à retirer en production)"""
	if not debug_mode or not OS.is_debug_build():
		return
	
	if event.is_action_pressed("debug_rep_increase"):
		modify_reputation("patrician", 10, "debug_increase")
	elif event.is_action_pressed("debug_rep_decrease"):
		modify_reputation("patrician", -10, "debug_decrease")
	elif event.is_action_pressed("debug_rep_summary"):
		print_reputation_summary()
	elif event.is_action_pressed("debug_trigger_conflict"):
		trigger_faction_conflict("patrician", "underworld", "debug_conflict")

func print_reputation_summary() -> void:
	"""Affiche un résumé des réputations (debug)"""
	print("=== REPUTATION SYSTEM SUMMARY ===")
	print("Système initialisé:", system_initialized)
	print("Factions suivies:", player_reputations.size())
	print("Conflits actifs:", active_conflicts.size())
	print("Événements historique:", reputation_history.size())
	
	print("\n--- RÉPUTATIONS ACTUELLES ---")
	for faction_id in player_reputations:
		var reputation = player_reputations[faction_id]
		var level = get_reputation_level(faction_id)
		var services = get_available_services(faction_id).size()
		print("- ", faction_id, ": ", reputation, " (", level, ") - ", services, " services")
	
	if active_conflicts.size() > 0:
		print("\n--- CONFLITS ACTIFS ---")
		for conflict_id in active_conflicts:
			var conflict = active_conflicts[conflict_id]
			print("- ", conflict.faction1, " vs ", conflict.faction2, " (", conflict.type, ")")

func validate_system_integrity() -> bool:
	"""Valide l'intégrité du système de réputation"""
	var is_valid = true
	
	# Vérifier que toutes les factions principales sont initialisées
	for faction_id in MAIN_FACTIONS:
		if not player_reputations.has(faction_id):
			push_error("🏛️ Faction principale manquante: " + faction_id)
			is_valid = false
	
	# Vérifier que les réputations sont dans les limites
	for faction_id in player_reputations:
		var reputation = player_reputations[faction_id]
		if reputation < reputation_config.min_reputation or reputation > reputation_config.max_reputation:
			push_error("🏛️ Réputation hors limites pour " + faction_id + ": " + str(reputation))
			is_valid = false
	
	if is_valid and debug_mode:
		print("✅ Intégrité système réputation validée")
	
	return is_valid

# ============================================================================
# NOTES DE DÉVELOPPEMENT
# ============================================================================

## FONCTIONNALITÉS COMPLÉTÉES:
## ✅ 8 factions Terry Pratchett authentiques
## ✅ Système de réputation dynamique avec conséquences
## ✅ Services par niveau de réputation
## ✅ Conflits inter-factions automatiques
## ✅ Effets en cascade entre factions
## ✅ Intégration complète avec autres managers
## ✅ Événements publics pour actions majeures
## ✅ Système de maîtrise des factions
## ✅ Décroissance naturelle configurable
## ✅ Sauvegarde complète et restauration
## ✅ Cache d'optimisation pour performances
## ✅ API publique extensive
## ✅ Debug et validation intégrés

## PROCHAINES ÉTAPES POSSIBLES:
## 🔜 Interface UI pour visualiser réputations
## 🔜 Système de quêtes de réconciliation
## 🔜 Événements spéciaux de faction
## 🔜 Négociation entre factions
## 🔜 Système d'ambassadeurs et diplomatie
## 🔜 Récompenses uniques par maîtrise de faction