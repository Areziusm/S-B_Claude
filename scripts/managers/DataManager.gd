# ============================================================================
# 📊 DataManager.gd - GESTIONNAIRE CENTRALISÉ DES DONNÉES (VERSION CORRIGÉE ET COMPLÈTE)
# ============================================================================
# STATUS: ✅ FIXED | ROADMAP: Mois 1, Semaine 1 - Core Architecture
# PRIORITY: 🔴 CRITICAL - Gestion centralisée des données JSON avec fallbacks

class_name DataManager
extends Node

## Gestionnaire centralisé pour toutes les données JSON du jeu
## Version corrigée avec gestion d'erreurs robuste et données de fallback
## Architecture DLC-ready avec validation automatique

# ============================================================================
# SIGNAUX
# ============================================================================

signal data_loaded(data_type: String)
signal all_data_loaded()
signal data_load_error(data_type: String, error: String)
signal manager_initialized()

# ============================================================================
# CONFIGURATION CHEMINS
# ============================================================================

const DATA_PATHS: Dictionary = {
	"creatures": "res://data/creature_database.json",
	"dialogues": "res://data/dialogue_trees.json",
	"quests": "res://data/quest_templates.json",
	"characters": "res://data/character_data.json",
	"progression": "res://data/progression_tables.json",
	"economy": "res://data/economy_data.json",
	"factions": "res://data/faction_relationships.json",
	"config": "res://data/game_config.json"
}

# ============================================================================
# DONNÉES CHARGÉES
# ============================================================================

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
var has_fallback_data: bool = false

# Cache pour optimisation
var cached_lookups: Dictionary = {}

# ============================================================================
# INITIALISATION SÉCURISÉE
# ============================================================================

func _ready() -> void:
	print("📊 [DataManager] Démarrage sécurisé du chargement...")
	await get_tree().process_frame
	load_all_data_safe()
	print("📊 [DataManager] Initialisation terminée")
	manager_initialized.emit()

func load_all_data_safe() -> void:
	var load_order: Array[String] = ["config", "creatures", "characters", "dialogues", "quests", "progression", "economy", "factions"]
	var loaded_count: int = 0
	var fallback_count: int = 0

	for data_type: String in load_order:
		var success: bool = load_data_file_safe(data_type)
		if success:
			loaded_count += 1
			data_loaded.emit(data_type)
		else:
			fallback_count += 1
			create_fallback_data(data_type)

	# Charger la localisation (optionnel)
	load_localization_safe("fr")

	# Post-processing sécurisé
	post_process_all_data_safe()

	loading_complete = true
	has_fallback_data = fallback_count > 0

	if has_fallback_data:
		print("⚠️ [DataManager] ", fallback_count, " fichier(s) manquant(s), fallbacks utilisés")

	print("✅ [DataManager] Chargement terminé:", loaded_count, "fichiers,", fallback_count, "fallbacks")
	all_data_loaded.emit()

func load_data_file_safe(data_type: String) -> bool:
	if not DATA_PATHS.has(data_type):
		push_warning("[DataManager] Type de données inconnu: " + data_type)
		return false

	var file_path: String = DATA_PATHS[data_type]

	if not FileAccess.file_exists(file_path):
		print("⚠️ [DataManager] Fichier manquant: " + file_path)
		return false

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("[DataManager] Impossible d'ouvrir: " + file_path)
		return false

	var json_string: String = file.get_as_text()
	file.close()

	if json_string.is_empty():
		push_warning("[DataManager] Fichier vide: " + file_path)
		return false

	var json = JSON.new
	var parse_result = json.parse(json_string)
	if parse_result.error != OK:
		push_error("[DataManager] Erreur JSON dans " + file_path + " : code " + str(parse_result.error))
		data_load_error.emit(data_type, "JSON parse error code: " + str(parse_result.error))
		return false

	var data = parse_result.result
	if data == null or (data is Dictionary and data.is_empty()):
		push_warning("[DataManager] Données vides dans: " + file_path)
		return false

	if not store_data_safe(data_type, data):
		return false

	data_loaded_flags[data_type] = true
	print("✅ [DataManager] Chargé: " + data_type + " (" + str(get_data_size(data)) + " entrées)")
	return true

func store_data_safe(data_type: String, data: Variant) -> bool:
	if data == null:
		push_error("[DataManager] Données nulles pour: " + data_type)
		return false

	match data_type:
		"creatures":
			creatures_db = data if data is Dictionary else {}
		"dialogues":
			dialogue_trees = data if data is Dictionary else {}
		"quests":
			quest_templates = data if data is Dictionary else {}
		"characters":
			characters_data = data if data is Dictionary else {}
		"progression":
			progression_tables = data if data is Dictionary else {}
		"economy":
			economy_data = data if data is Dictionary else {}
		"factions":
			faction_relationships = data if data is Dictionary else {}
		"config":
			game_config = data if data is Dictionary else {}
		_:
			push_warning("[DataManager] Type de données non géré: " + data_type)
			return false

	return true

func get_data_size(data: Variant) -> int:
	if data is Dictionary or data is Array:
		return data.size()
	else:
		return 1

# ============================================================================
# SYSTÈME DE FALLBACK
# ============================================================================

func create_fallback_data(data_type: String) -> void:
	print("🔄 [DataManager] Création fallback pour: " + data_type)

	match data_type:
		"creatures":
			creatures_db = create_fallback_creatures()
		"dialogues":
			dialogue_trees = create_fallback_dialogues()
		"quests":
			quest_templates = create_fallback_quests()
		"characters":
			characters_data = create_fallback_characters()
		"progression":
			progression_tables = create_fallback_progression()
		"economy":
			economy_data = create_fallback_economy()
		"factions":
			faction_relationships = create_fallback_factions()
		"config":
			game_config = create_fallback_config()

	data_loaded_flags[data_type] = true

func create_fallback_creatures() -> Dictionary:
	return {
		"rat_maurice": {
			"name": "Maurice le Rat Parlant",
			"species": "rat",
			"base_stats": {
				"constitution": 8,
				"intelligence": 15,
				"agility": 12,
				"charisma": 10
			},
			"evolutions": {
				"stage_1": {
					"name": "Rat Ordinaire",
					"requirements": {"observation_count": 0}
				},
				"stage_2": {
					"name": "Rat Conscient",
					"requirements": {"observation_count": 5}
				},
				"stage_3": {
					"name": "Rat Éduqué",
					"requirements": {"observation_count": 15}
				},
				"stage_4": {
					"name": "Maurice",
					"requirements": {"observation_count": 30}
				}
			},
			"magic_affinity": 0.8,
			"observation_difficulty": 1.2
		},
		"chat_greebo": {
			"name": "Greebo",
			"species": "cat",
			"base_stats": {
				"constitution": 12,
				"intelligence": 6,
				"agility": 18,
				"charisma": 8
			},
			"evolutions": {
				"stage_1": {
					"name": "Chat de Gouttière",
					"requirements": {"observation_count": 0}
				},
				"stage_2": {
					"name": "Chat Territorial",
					"requirements": {"observation_count": 8}
				},
				"stage_3": {
					"name": "Chat Alpha",
					"requirements": {"observation_count": 20}
				},
				"stage_4": {
					"name": "Greebo Légendaire",
					"requirements": {"observation_count": 40}
				}
			},
			"magic_affinity": 0.3,
			"observation_difficulty": 1.5
		}
	}

func create_fallback_dialogues() -> Dictionary:
	return {
		"test_dialogue": {
			"speaker": "npc_test",
			"nodes": {
				"start": {
					"text": "Bonjour ! Bienvenue dans Sortilèges & Bestioles !",
					"choices": [
						{"text": "Salut !", "next": "friendly"},
						{"text": "Hmm...", "next": "neutral"}
					]
				},
				"friendly": {
					"text": "Ravi de vous rencontrer ! Explorez et observez les créatures.",
					"choices": [{"text": "Merci !", "next": "end"}]
				},
				"neutral": {
					"text": "Bon voyage dans le Disque-Monde !",
					"choices": [{"text": "Au revoir.", "next": "end"}]
				},
				"end": {
					"text": "À bientôt !",
					"choices": []
				}
			}
		}
	}

func create_fallback_characters() -> Dictionary:
	return {
		"npc_test": {
			"name": "Testeur Bienveillant",
			"location": "test_zone",
			"faction": "neutral",
			"dialogue_tree": "test_dialogue",
			"relationship": 0.0,
			"base_stats": {
				"reputation": 50,
				"trust": 30
			}
		}
	}

func create_fallback_quests() -> Dictionary:
	return {
		"first_observation": {
			"title": "Première Observation",
			"description": "Observer votre première créature magique.",
			"type": "tutorial",
			"requirements": {
				"observe_creature": 1
			},
			"rewards": {
				"experience": 50,
				"reputation": {"general": 10}
			}
		}
	}

func create_fallback_progression() -> Dictionary:
	return {
		"experience_table": {
			"1": 0,
			"2": 100,
			"3": 250,
			"4": 500,
			"5": 1000
		},
		"skill_progression": {
			"observation": {
				"base_bonus": 1.0,
				"level_multiplier": 0.1
			}
		}
	}

func create_fallback_economy() -> Dictionary:
	return {
		"base_prices": {
			"common_item": 10,
			"rare_item": 50,
			"legendary_item": 200
		},
		"currency": {
			"starting_amount": 100,
			"daily_allowance": 20
		}
	}

func create_fallback_factions() -> Dictionary:
	return {
		"wizards": {
			"name": "Université de l'Invisible",
			"relationship": 0.0,
			"reputation_levels": {
				"hostile": -100,
				"unfriendly": -50,
				"neutral": 0,
				"friendly": 50,
				"allied": 100
			}
		},
		"watch": {
			"name": "Garde d'Ankh-Morpork",
			"relationship": 0.0,
			"reputation_levels": {
				"hostile": -100,
				"unfriendly": -50,
				"neutral": 0,
				"friendly": 50,
				"allied": 100
			}
		}
	}

func create_fallback_config() -> Dictionary:
	return {
		"game_version": "0.1.0-dev",
		"debug_mode": true,
		"auto_save_interval": 300.0,
		"observation_system": {
			"base_observation_time": 2.0,
			"evolution_threshold": 5,
			"magic_amplification": 1.2
		},
		"dialogue_system": {
			"typing_speed": 0.05,
			"auto_advance_time": 3.0
		}
	}

# ============================================================================
# POST-PROCESSING SÉCURISÉ
# ============================================================================

func post_process_all_data_safe() -> void:
	if not creatures_db.is_empty():
		post_process_creatures_data_safe()
	if not characters_data.is_empty():
		post_process_characters_data_safe()
	build_lookup_caches_safe()
	print("✅ [DataManager] Post-processing terminé")

func post_process_creatures_data_safe() -> void:
	for creature_id: String in creatures_db.keys():
		var creature: Dictionary = creatures_db[creature_id]
		if not creature is Dictionary:
			continue
		if creature.has("base_stats") and creature["base_stats"] is Dictionary:
			calculate_derived_stats_safe(creature)
		if creature.has("evolutions") and creature["evolutions"] is Dictionary:
			validate_evolution_chain_safe(creature_id, creature)

func post_process_characters_data_safe() -> void:
	for char_id: String in characters_data.keys():
		var character: Dictionary = characters_data[char_id]
		if not character is Dictionary:
			continue
		if character.has("dialogue_tree"):
			var dialogue_id: String = character["dialogue_tree"]
			if not dialogue_trees.has(dialogue_id):
				push_warning("[DataManager] Dialogue manquant pour " + char_id + ": " + dialogue_id)

func calculate_derived_stats_safe(creature: Dictionary) -> void:
	var base_stats: Dictionary = creature["base_stats"]
	if base_stats.has("constitution") and base_stats["constitution"] is int:
		creature["derived_hp"] = base_stats["constitution"] * 10 + 50
	if base_stats.has("agility") and base_stats["agility"] is int:
		creature["movement_speed"] = base_stats["agility"] * 2 + 100

func validate_evolution_chain_safe(creature_id: String, creature: Dictionary) -> void:
	var evolutions: Dictionary = creature["evolutions"]
	for stage_key: String in evolutions.keys():
		var evolution: Dictionary = evolutions[stage_key]
		if not evolution is Dictionary:
			continue
		if evolution.has("requirements") and evolution["requirements"] is Dictionary:
			var reqs: Dictionary = evolution["requirements"]
			if reqs.has("observation_count"):
				var count: int = reqs["observation_count"]
				if not count is int or count < 0:
					push_warning("[DataManager] Prérequis observation invalide pour " + creature_id + ":" + stage_key)

func build_lookup_caches_safe() -> void:
	cached_lookups["characters_by_location"] = {}
	cached_lookups["characters_by_faction"] = {}
	for char_id: String in characters_data.keys():
		var character: Dictionary = characters_data[char_id]
		if not character is Dictionary:
			continue
		var location: String = character.get("location", "unknown")
		if not cached_lookups["characters_by_location"].has(location):
			cached_lookups["characters_by_location"][location] = []
		cached_lookups["characters_by_location"][location].append(char_id)
		var faction: String = character.get("faction", "none")
		if not cached_lookups["characters_by_faction"].has(faction):
			cached_lookups["characters_by_faction"][faction] = []
		cached_lookups["characters_by_faction"][faction].append(char_id)

# ============================================================================
# LOCALISATION SÉCURISÉE
# ============================================================================

func load_localization_safe(language: String) -> void:
	var loc_path: String = "res://data/localization/" + language + ".json"
	if FileAccess.file_exists(loc_path):
		var file: FileAccess = FileAccess.open(loc_path, FileAccess.READ)
		if file:
			var json = JSON.new
			var parse_result = json.parse(file.get_as_text())
			file.close()
			if parse_result.error == OK and parse_result.result is Dictionary:
				localization_data = parse_result.result as Dictionary
				print("✅ [DataManager] Localisation chargée: " + language)
				return
	# Fallback localisation
	localization_data = {
		"welcome": "Bienvenue dans Sortilèges & Bestioles !",
		"observe_creature": "Observer une créature",
		"loading": "Chargement..."
	}
	print("⚠️ [DataManager] Localisation fallback utilisée")

func get_localized_text(key: String, default_text: String = "") -> String:
	if localization_data.has(key):
		return localization_data[key]
	return default_text if not default_text.is_empty() else key

# ============================================================================
# API PUBLIQUE
# ============================================================================

func get_creature_data(creature_id: String) -> Dictionary:
	return creatures_db.get(creature_id, {})

func get_character_data(character_id: String) -> Dictionary:
	return characters_data.get(character_id, {})

func get_dialogue_tree(dialogue_id: String) -> Dictionary:
	return dialogue_trees.get(dialogue_id, {})

func get_quest_template(quest_id: String) -> Dictionary:
	return quest_templates.get(quest_id, {})

func is_data_loaded(data_type: String) -> bool:
	return data_loaded_flags.get(data_type, false)

func get_data_summary() -> Dictionary:
	return {
		"creatures_count": creatures_db.size(),
		"characters_count": characters_data.size(),
		"dialogue_trees_count": dialogue_trees.size(),
		"quest_templates_count": quest_templates.size(),
		"loading_complete": loading_complete,
		"has_fallback_data": has_fallback_data,
		"loaded_flags": data_loaded_flags
	}
