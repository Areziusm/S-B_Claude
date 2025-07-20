extends Node
class_name DataManager

## ========================================================================
## DATAMANAGER - GESTIONNAIRE CENTRALISÉ DES DONNÉES
## ========================================================================

# ================================
# SIGNAUX
# ================================
signal data_loaded(data_type: String)
signal all_data_loaded()
signal data_load_error(data_type: String, error: String)

# ================================
# CONSTANTES CHEMINS
# ================================
const DATA_PATHS = {
	"creatures": "res://data/creature_database.json",
	"dialogues": "res://data/dialogue_trees.json",
	"quests": "res://data/quest_templates.json",
	"characters": "res://data/character_data.json",
	"progression": "res://data/progression_tables.json",
	"economy": "res://data/economy_data.json",
	"factions": "res://data/faction_relationships.json",
	"localization": "res://data/localization/",
	"config": "res://data/game_config.json"
}

# DLC Data paths (dynamiquement ajoutés)
var dlc_data_paths: Dictionary = {}

# ================================
# DONNÉES CHARGÉES
# ================================
var creatures_db: Dictionary = {}
var dialogue_trees: Dictionary = {}
var quest_templates: Dictionary = {}
var characters_data: Dictionary = {}
var progression_tables: Dictionary = {}
var economy_data: Dictionary = {}
var faction_relationships: Dictionary = {}
var game_config: Dictionary = {}
var localization_data: Dictionary = {}

# État du chargement
var loading_complete: bool = false
var data_loaded_flags: Dictionary = {}

# Cache pour optimisation
var cached_lookups: Dictionary = {}

# ================================
# INITIALISATION
# ================================
func _ready() -> void:
	print("[DataManager] Démarrage du chargement des données...")
	await load_all_data()
	print("[DataManager] Toutes les données chargées avec succès")

func load_all_data() -> void:
	var load_order = ["config", "creatures", "characters", "dialogues", "quests", "progression", "economy", "factions"]

	for data_type in load_order:
		var success = await load_data_file(data_type)
		if not success:
			push_error("[DataManager] Échec du chargement: " + data_type)
		else:
			data_loaded.emit(data_type)

	await load_localization_data("en")  # Langue par défaut

	loading_complete = true
	all_data_loaded.emit()

func load_data_file(data_type: String) -> bool:
	if not DATA_PATHS.has(data_type):
		push_error("[DataManager] Type de données inconnu: " + data_type)
		return false

	var file_path = DATA_PATHS[data_type]

	if not FileAccess.file_exists(file_path):
		push_error("[DataManager] Fichier non trouvé: " + file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[DataManager] Impossible d'ouvrir: " + file_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("[DataManager] Erreur JSON dans: " + file_path + " - " + json.error_string)
		return false

	var data = json.data

	match data_type:
		"creatures":
			creatures_db = data
			post_process_creatures_data()
		"dialogues":
			dialogue_trees = data
		"quests":
			quest_templates = data
		"characters":
			characters_data = data
			post_process_characters_data()
		"progression":
			progression_tables = data
		"economy":
			economy_data = data
		"factions":
			faction_relationships = data
		"config":
			game_config = data

	data_loaded_flags[data_type] = true
	print("[DataManager] Chargé avec succès: " + data_type)
	return true

# ================================
# POST-PROCESSING DES DONNÉES
# ================================
func post_process_creatures_data() -> void:
	for creature_id in creatures_db.keys():
		var creature = creatures_db[creature_id]
		if creature.has("base_stats"):
			calculate_derived_stats(creature)
		if creature.has("evolutions"):
			validate_evolution_chain(creature_id, creature)

func post_process_characters_data() -> void:
	cached_lookups["characters_by_location"] = {}
	cached_lookups["characters_by_faction"] = {}

	for char_id in characters_data.keys():
		var character = characters_data[char_id]

		var location = character["location"] if character.has("location") else "unknown"
		if not cached_lookups["characters_by_location"].has(location):
			cached_lookups["characters_by_location"][location] = []
		cached_lookups["characters_by_location"][location].append(char_id)

		var faction = character["faction"] if character.has("faction") else "none"
		if not cached_lookups["characters_by_faction"].has(faction):
			cached_lookups["characters_by_faction"][faction] = []
		cached_lookups["characters_by_faction"][faction].append(char_id)

func calculate_derived_stats(creature: Dictionary) -> void:
	var base_stats = creature["base_stats"]
	if base_stats.has("constitution"):
		creature["derived_hp"] = base_stats["constitution"] * 10 + 50
	if base_stats.has("agility"):
		creature["movement_speed"] = base_stats["agility"] * 2 + 100

func validate_evolution_chain(creature_id: String, creature: Dictionary) -> void:
	if not creature.has("evolutions"):
		return
	var evolutions = creature["evolutions"]
	for stage in evolutions.keys():
		var evolution = evolutions[stage]
		if evolution.has("requirements"):
			for req_type in evolution["requirements"]:
				var req_value = evolution["requirements"][req_type]
				match req_type:
					"observation_count":
						if not (req_value is int and req_value > 0):
							push_error("[DataManager] Prérequis observation invalide pour " + creature_id)

# ================================
# LOCALISATION
# ================================
func load_localization_data(language: String) -> void:
	var loc_path = DATA_PATHS["localization"] + language + ".json"
	if not FileAccess.file_exists(loc_path):
		print("[DataManager] Pas de localisation pour: " + language + ", utilisation de 'en'")
		loc_path = DATA_PATHS["localization"] + "en.json"
	if FileAccess.file_exists(loc_path):
		var file = FileAccess.open(loc_path, FileAccess.READ)
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()
		if parse_result == OK:
			localization_data = json.data
			print("[DataManager] Localisation chargée: " + language)
		else:
			push_error("[DataManager] Erreur localisation: " + json.error_string)

func get_localized_text(key: String, default_text: String = "") -> String:
	return localization_data[key] if localization_data.has(key) else default_text

# ================================
# GETTERS POUR CRÉATURES
# ================================
func get_creature_data(creature_id: String) -> Dictionary:
	return creatures_db[creature_id] if creatures_db.has(creature_id) else {}

func get_creature_evolution_data(creature_id: String, stage: int) -> Dictionary:
	var creature = get_creature_data(creature_id)
	if creature.has("evolutions"):
		var stage_key = "stage_" + str(stage)
		return creature["evolutions"][stage_key] if creature["evolutions"].has(stage_key) else {}
	return {}

func get_creatures_by_habitat(habitat: String) -> Array:
	var result = []
	for creature_id in creatures_db.keys():
		var creature = creatures_db[creature_id]
		if creature.has("habitat") and creature["habitat"] == habitat:
			result.append(creature_id)
	return result

func get_creatures_by_rarity(rarity: String) -> Array:
	var result = []
	for creature_id in creatures_db.keys():
		var creature = creatures_db[creature_id]
		if creature.has("rarity") and creature["rarity"] == rarity:
			result.append(creature_id)
	return result

# ================================
# GETTERS POUR PERSONNAGES
# ================================
func get_character_data(character_id: String) -> Dictionary:
	return characters_data[character_id] if characters_data.has(character_id) else {}

func get_characters_in_location(location: String) -> Array:
	if cached_lookups.has("characters_by_location") and cached_lookups["characters_by_location"].has(location):
		return cached_lookups["characters_by_location"][location]
	return []

func get_characters_by_faction(faction: String) -> Array:
	if cached_lookups.has("characters_by_faction") and cached_lookups["characters_by_faction"].has(faction):
		return cached_lookups["characters_by_faction"][faction]
	return []

func get_character_dialogue_tree(character_id: String) -> Dictionary:
	var character = get_character_data(character_id)
	var dialogue_id = character["dialogue_tree"] if character.has("dialogue_tree") else ""
	if dialogue_id == "":
		return {}
	return dialogue_trees[dialogue_id] if dialogue_trees.has(dialogue_id) else {}

# ================================
# GETTERS POUR QUÊTES
# ================================
func get_quest_template(quest_id: String) -> Dictionary:
	return get_node("/root/DataManager").quest_templates[quest_id] if get_node("/root/DataManager").quest_templates.has(quest_id) else {}

func get_quest_templates_by_type(quest_type: String) -> Array:
	var result = []
	for quest_id in quest_templates.keys():
		var quest = quest_templates[quest_id]
		if quest.has("type") and quest["type"] == quest_type:
			result.append(quest)
	return result

func get_quest_requirements(quest_id: String) -> Dictionary:
	var quest = get_quest_template(quest_id)
	return quest["requirements"] if quest.has("requirements") else {}

# ================================
# GETTERS ÉCONOMIE
# ================================
func get_item_base_price(item_id: String) -> float:
	var items = economy_data["items"] if economy_data.has("items") else {}
	var item = items[item_id] if items.has(item_id) else {}
	return item["base_price"] if item.has("base_price") else 0.0

func get_merchant_data(merchant_id: String) -> Dictionary:
	var merchants = economy_data["merchants"] if economy_data.has("merchants") else {}
	return merchants[merchant_id] if merchants.has(merchant_id) else {}

func get_faction_trade_modifier(faction: String) -> float:
	var faction_data = faction_relationships[faction] if faction_relationships.has(faction) else {}
	return faction_data["trade_modifier"] if faction_data.has("trade_modifier") else 1.0

# ================================
# GETTERS PROGRESSION
# ================================
func get_xp_for_level(level: int) -> int:
	var xp_table = progression_tables["experience_table"] if progression_tables.has("experience_table") else []
	if level > 0 and level <= xp_table.size():
		return xp_table[level - 1]
	return 0

func get_skill_unlock_level(skill_id: String) -> int:
	var skills = progression_tables["skills"] if progression_tables.has("skills") else {}
	var skill = skills[skill_id] if skills.has(skill_id) else {}
	return skill["unlock_level"] if skill.has("unlock_level") else 1

func get_reputation_threshold(reputation_level: String) -> int:
	var rep_table = progression_tables["reputation_thresholds"] if progression_tables.has("reputation_thresholds") else {}
	return rep_table[reputation_level] if rep_table.has(reputation_level) else 0

# ================================
# GESTION DLC (non-statiques)
# ================================
func register_dlc_data(dlc_id: String, data_type: String, file_path: String) -> void:
	if not dlc_data_paths.has(dlc_id):
		dlc_data_paths[dlc_id] = {}
	dlc_data_paths[dlc_id][data_type] = file_path

func load_dlc_data(dlc_id: String) -> bool:
	if not dlc_data_paths.has(dlc_id):
		push_error("[DataManager] DLC non enregistré: " + dlc_id)
		return false

	var dlc_paths = dlc_data_paths[dlc_id]
	var success = true

	for data_type in dlc_paths.keys():
		var file_path = dlc_paths[data_type]
		var load_success = await load_dlc_data_file(dlc_id, data_type, file_path)
		if not load_success:
			success = false

	return success

func load_dlc_data_file(dlc_id: String, data_type: String, file_path: String) -> bool:
	if not FileAccess.file_exists(file_path):
		push_error("[DataManager] Fichier DLC non trouvé: " + file_path)
		return false

	var file = FileAccess.open(file_path, FileAccess.READ)
	var json = JSON.new()
	var parse_result = json.parse(file.get_as_text())
	file.close()

	if parse_result != OK:
		push_error("[DataManager] Erreur JSON DLC: " + file_path)
		return false

	var dlc_data = json.data

	match data_type:
		"creatures":
			for creature_id in dlc_data.keys():
				creatures_db[dlc_id + "_" + creature_id] = dlc_data[creature_id]
		"characters":
			for char_id in dlc_data.keys():
				characters_data[dlc_id + "_" + char_id] = dlc_data[char_id]
		"quests":
			for quest_id in dlc_data.keys():
				quest_templates[dlc_id + "_" + quest_id] = dlc_data[quest_id]

	print("[DataManager] Données DLC chargées: " + dlc_id + "/" + data_type)
	return true

# ================================
# UTILITAIRES ET VALIDATION
# ================================
func validate_all_data() -> bool:
	var is_valid = true
	is_valid = validate_character_references() and is_valid
	is_valid = validate_quest_references() and is_valid
	is_valid = validate_creature_references() and is_valid

	if is_valid:
		print("[DataManager] Validation des données réussie")
	else:
		push_error("[DataManager] Erreurs de validation détectées")

	return is_valid

func validate_character_references() -> bool:
	var is_valid = true
	for char_id in characters_data.keys():
		var character = characters_data[char_id]
		var dialogue_id = character["dialogue_tree"] if character.has("dialogue_tree") else ""
		if dialogue_id != "" and not dialogue_trees.has(dialogue_id):
			push_error("[DataManager] Dialogue tree manquant pour " + char_id + ": " + dialogue_id)
			is_valid = false
	return is_valid

func validate_quest_references() -> bool:
	var is_valid = true
	for quest_id in quest_templates.keys():
		var quest = quest_templates[quest_id]
		var requirements = quest["requirements"] if quest.has("requirements") else {}
		if requirements.has("character_met"):
			var char_list = requirements["character_met"]
			for char_id in char_list:
				if not characters_data.has(char_id):
					push_error("[DataManager] Personnage manquant pour quête " + quest_id + ": " + char_id)
					is_valid = false
	return is_valid

func validate_creature_references() -> bool:
	var is_valid = true
	for creature_id in creatures_db.keys():
		var creature = creatures_db[creature_id]
		if creature.has("evolutions"):
			var evolutions = creature["evolutions"]
			for stage_key in evolutions.keys():
				var evolution = evolutions[stage_key]
				if evolution.has("transforms_to"):
					var target_id = evolution["transforms_to"]
					if not creatures_db.has(target_id):
						push_error("[DataManager] Créature cible manquante pour " + creature_id + ": " + target_id)
						is_valid = false
	return is_valid

func reload_data() -> void:
	print("[DataManager] Rechargement de toutes les données...")
	loading_complete = false
	data_loaded_flags.clear()
	cached_lookups.clear()
	await load_all_data()
	print("[DataManager] Rechargement terminé")

func get_data_summary() -> Dictionary:
	return {
		"creatures_count": creatures_db.size(),
		"characters_count": characters_data.size(),
		"dialogue_trees_count": dialogue_trees.size(),
		"quest_templates_count": quest_templates.size(),
		"loading_complete": loading_complete,
		"loaded_flags": data_loaded_flags
	}

# ================================
# MÉTHODES STATIQUES (à la fin !)
# ================================
static func get_story_progression():
	return {}

static func get_procedural_quest_config():
	return {}
