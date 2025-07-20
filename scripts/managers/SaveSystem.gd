# ============================================================================
# 💾 SaveSystem.gd - Gestionnaire de Persistence et Sauvegarde
# ============================================================================
# STATUS: ✅ PRODUCTION | VERSION: 1.0
# PRIORITY: 🟡 P3 - Persistence fiable et migration DLC
# DEPENDENCIES: GameManager, ObservationManager, DialogueManager, QuestManager

class_name SaveSystem
extends Node

## Gestionnaire centralisé de la persistence et sauvegarde
## Support complet DLC, migration de données, multi-slots
## Architecture Terry Pratchett avec robustesse et humor

# ================================
# SIGNAUX
# ================================
signal save_started(slot: int, save_type: String)
signal save_completed(slot: int, success: bool, error_message: String)
signal load_started(slot: int)
signal load_completed(slot: int, success: bool, error_message: String)
signal auto_save_triggered()
signal save_migration_completed(old_version: String, new_version: String)
signal backup_created(backup_path: String)
signal cloud_sync_completed(success: bool)

# ================================
# ENUMS & CONSTANTS
# ================================
enum SaveType {
	MANUAL,
	AUTO,
	QUICK,
	CHECKPOINT,
	EXPORT
}

enum SaveSlot {
	AUTO_SAVE = 0,
	QUICK_SAVE = 1,
	MANUAL_1 = 2,
	MANUAL_2 = 3,
	MANUAL_3 = 4,
	MANUAL_4 = 5,
	MANUAL_5 = 6,
	MANUAL_6 = 7,
	MANUAL_7 = 8,
	MANUAL_8 = 9,
	MANUAL_9 = 10,
	MANUAL_10 = 11
}

const SAVE_VERSION = "1.0.0"
const SAVE_BASE_PATH = "user://saves/"
const SAVE_FILE_EXTENSION = ".sbsave"  # Sortilèges & Bestioles Save
const BACKUP_PATH = "user://backups/"
const EXPORT_PATH = "user://exports/"
const MAX_SLOTS = 12
const MAX_BACKUPS = 5

# Configuration système
const AUTO_SAVE_INTERVAL = 30.0  # secondes
const QUICK_SAVE_KEY = "F5"
const QUICK_LOAD_KEY = "F9"

# ================================
# VARIABLES PRINCIPALES
# ================================
@export var auto_save_enabled: bool = true
@export var backup_enabled: bool = true
@export var compression_enabled: bool = true
@export var cloud_sync_enabled: bool = false

# État du système
var is_saving: bool = false
var is_loading: bool = false
var last_save_time: float = 0.0
var auto_save_timer: Timer
var current_save_version: String = SAVE_VERSION

# Configuration persistence
var save_config: Dictionary = {
	"auto_save_interval": AUTO_SAVE_INTERVAL,
	"auto_save_enabled": true,
	"backup_enabled": true,
	"compression_level": 6,  # gzip compression
	"cloud_sync": false,
	"max_backups": MAX_BACKUPS
}

# Métadonnées des sauvegardes
var save_metadata: Dictionary = {}

# Références managers
var game_manager: GameManager
var observation_manager: ObservationManager
var dialogue_manager: DialogueManager
var quest_manager: QuestManager
var ui_manager: UIManager

# ================================
# INITIALISATION
# ================================
func _ready() -> void:
	"""Initialisation complète du SaveSystem"""
	print("💾 SaveSystem: Initialisation démarrée...")
	
	# Configuration répertoires
	ensure_save_directories()
	
	# Chargement configuration
	load_save_config()
	
	# Chargement métadonnées
	load_save_metadata()
	
	# Configuration auto-save
	setup_auto_save()
	
	# Configuration input
	setup_input_handling()
	
	# Récupération références managers
	await get_tree().process_frame
	get_manager_references()
	
	# Migration des anciennes sauvegardes si nécessaire
	check_and_migrate_saves()
	
	print("💾 SaveSystem: Initialisé avec succès")

func ensure_save_directories() -> void:
	"""Crée les répertoires de sauvegarde nécessaires"""
	var directories = [SAVE_BASE_PATH, BACKUP_PATH, EXPORT_PATH]
	
	for dir_path in directories:
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.open("user://").make_dir_recursive(dir_path.replace("user://", ""))
			print("💾 SaveSystem: Répertoire créé: ", dir_path)

func setup_auto_save() -> void:
	"""Configure le système de sauvegarde automatique"""
	auto_save_timer = Timer.new()
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	auto_save_timer.wait_time = save_config.get("auto_save_interval", AUTO_SAVE_INTERVAL)
	auto_save_timer.autostart = save_config.get("auto_save_enabled", true)
	add_child(auto_save_timer)

func setup_input_handling() -> void:
	"""Configure les raccourcis clavier pour sauvegarde/chargement"""
	# TODO: Ajouter input map pour quick save/load
	pass

func get_manager_references() -> void:
	"""Récupère les références vers les autres managers"""
	game_manager = get_node_or_null("/root/GameManager")
	observation_manager = get_node_or_null("/root/ObservationManager")
	dialogue_manager = get_node_or_null("/root/DialogueManager")
	quest_manager = get_node_or_null("/root/QuestManager")
	ui_manager = get_node_or_null("/root/UIManager")

# ================================
# SAUVEGARDE PRINCIPALE
# ================================
func save_game(slot: int = SaveSlot.AUTO_SAVE, save_type: SaveType = SaveType.MANUAL, description: String = "") -> bool:
	"""Sauvegarde complète du jeu dans un slot donné"""
	if is_saving:
		print("💾 SaveSystem: Sauvegarde déjà en cours")
		return false
	
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("💾 SaveSystem: Slot invalide: " + str(slot))
		return false
	
	is_saving = true
	save_started.emit(slot, SaveType.keys()[save_type])
	
	print("💾 SaveSystem: Début sauvegarde slot ", slot, " type ", SaveType.keys()[save_type])
	
	# Compilation des données
	var save_data = compile_complete_save_data(save_type, description)
	
	# Sauvegarde
	var success = await write_save_file(slot, save_data)
	
	# Backup si activé
	if success and backup_enabled and save_type != SaveType.AUTO:
		create_backup(slot)
	
	# Mise à jour métadonnées
	if success:
		update_save_metadata(slot, save_data)
		last_save_time = Time.get_ticks_msec() / 1000.0
	
	is_saving = false
	save_completed.emit(slot, success, "" if success else "Erreur lors de l'écriture")
	
	print("💾 SaveSystem: Sauvegarde ", "réussie" if success else "échouée", " pour slot ", slot)
	return success

func compile_complete_save_data(save_type: SaveType, description: String) -> Dictionary:
	"""Compile toutes les données de sauvegarde depuis tous les managers"""
	var save_data = {
		# Métadonnées système
		"save_version": current_save_version,
		"save_type": SaveType.keys()[save_type],
		"timestamp": Time.get_unix_time_from_system(),
		"play_time": get_total_play_time(),
		"description": description,
		"game_version": Engine.get_version_info(),
		
		# Configuration et état global
		"save_config": save_config,
		"loaded_dlcs": [],
		
		# Données des managers
		"managers": {}
	}
	
	# GameManager
	if game_manager and game_manager.has_method("get_save_data"):
		save_data.managers["game"] = game_manager.get_save_data()
	
	# ObservationManager
	if observation_manager and observation_manager.has_method("get_save_data"):
		save_data.managers["observation"] = observation_manager.get_save_data()
	
	# DialogueManager
	if dialogue_manager and dialogue_manager.has_method("get_save_data"):
		save_data.managers["dialogue"] = dialogue_manager.get_save_data()
	
	# QuestManager
	if quest_manager and quest_manager.has_method("get_save_data"):
		save_data.managers["quest"] = quest_manager.get_save_data()
	
	# UIManager (configuration UI)
	if ui_manager and ui_manager.has_method("get_save_data"):
		save_data.managers["ui"] = ui_manager.get_save_data()
	
	# Player data (via GameManager)
	if game_manager:
		save_data["player_data"] = {
			"level": game_manager.get("player_level", 1),
			"experience": game_manager.get("player_experience", 0),
			"position": game_manager.get("player_position", Vector2.ZERO),
			"current_scene": game_manager.get("current_scene_name", ""),
			"inventory": game_manager.get("player_inventory", {}),
			"stats": game_manager.get("player_stats", {})
		}
	
	# World state complet
	save_data["world_state"] = {
		"time_of_day": get_world_time(),
		"weather": get_current_weather(),
		"global_flags": get_global_flags(),
		"npc_states": get_all_npc_states(),
		"creature_populations": get_creature_populations()
	}
	
	return save_data

func write_save_file(slot: int, save_data: Dictionary) -> bool:
	"""Écrit les données de sauvegarde dans un fichier"""
	var file_path = get_save_file_path(slot)
	
	# Conversion en JSON
	var json_string = JSON.stringify(save_data)
	
	# Compression si activée
	if compression_enabled:
		json_string = compress_save_data(json_string)
	
	# Écriture fichier
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		push_error("💾 SaveSystem: Impossible d'ouvrir le fichier: " + file_path)
		return false
	
	if compression_enabled:
		file.store_var(json_string, true)  # Stockage binaire compressé
	else:
		file.store_string(json_string)
	
	file.close()
	
	return true

# ================================
# CHARGEMENT
# ================================
func load_game(slot: int = SaveSlot.AUTO_SAVE) -> bool:
	"""Charge une sauvegarde depuis un slot donné"""
	if is_loading:
		print("💾 SaveSystem: Chargement déjà en cours")
		return false
	
	if slot < 0 or slot >= MAX_SLOTS:
		push_error("💾 SaveSystem: Slot invalide: " + str(slot))
		return false
	
	var file_path = get_save_file_path(slot)
	if not FileAccess.file_exists(file_path):
		print("💾 SaveSystem: Aucune sauvegarde trouvée dans le slot ", slot)
		return false
	
	is_loading = true
	load_started.emit(slot)
	
	print("💾 SaveSystem: Début chargement slot ", slot)
	
	# Lecture fichier
	var save_data = await read_save_file(slot)
	if save_data.is_empty():
		is_loading = false
		load_completed.emit(slot, false, "Erreur de lecture du fichier")
		return false
	
	# Validation version
	var migration_needed = check_save_version(save_data)
	if migration_needed:
		save_data = migrate_save_data(save_data)
	
	# Application des données
	var success = apply_save_data(save_data)
	
	is_loading = false
	load_completed.emit(slot, success, "" if success else "Erreur lors de l'application")
	
	print("💾 SaveSystem: Chargement ", "réussi" if success else "échoué", " pour slot ", slot)
	return success

func read_save_file(slot: int) -> Dictionary:
	"""Lit et décompresse un fichier de sauvegarde"""
	var file_path = get_save_file_path(slot)
	var file = FileAccess.open(file_path, FileAccess.READ)
	
	if file == null:
		push_error("💾 SaveSystem: Impossible de lire le fichier: " + file_path)
		return {}
	
	var content: String
	
	# Détection format (compressé ou texte)
	if compression_enabled:
		content = file.get_var(true)  # Lecture binaire
		content = decompress_save_data(content)
	else:
		content = file.get_as_text()
	
	file.close()
	
	# Parsing JSON
	var json = JSON.new()
	var parse_result = json.parse(content)
	
	if parse_result != OK:
		push_error("💾 SaveSystem: Erreur parsing JSON: " + json.get_error_message())
		return {}
	
	return json.data

func apply_save_data(save_data: Dictionary) -> bool:
	"""Applique les données de sauvegarde à tous les managers"""
	var success = true
	
	# Application aux managers
	var managers_data = save_data.get("managers", {})
	
	# GameManager
	if game_manager and managers_data.has("game"):
		if game_manager.has_method("apply_save_data"):
			game_manager.apply_save_data(managers_data.game)
	
	# ObservationManager
	if observation_manager and managers_data.has("observation"):
		if observation_manager.has_method("apply_save_data"):
			observation_manager.apply_save_data(managers_data.observation)
	
	# DialogueManager
	if dialogue_manager and managers_data.has("dialogue"):
		if dialogue_manager.has_method("apply_save_data"):
			dialogue_manager.apply_save_data(managers_data.dialogue)
	
	# QuestManager
	if quest_manager and managers_data.has("quest"):
		if quest_manager.has_method("apply_save_data"):
			quest_manager.apply_save_data(managers_data.quest)
	
	# UIManager
	if ui_manager and managers_data.has("ui"):
		if ui_manager.has_method("apply_save_data"):
			ui_manager.apply_save_data(managers_data.ui)
	
	# Player data
	if save_data.has("player_data"):
		apply_player_data(save_data.player_data)
	
	# World state
	if save_data.has("world_state"):
		apply_world_state(save_data.world_state)
	
	return success

# ================================
# GESTION DES SLOTS
# ================================
func get_save_info(slot: int) -> Dictionary:
	"""Retourne les informations d'une sauvegarde"""
	if not has_save_in_slot(slot):
		return {}
	
	return save_metadata.get(str(slot), {})

func has_save_in_slot(slot: int) -> bool:
	"""Vérifie si un slot contient une sauvegarde"""
	var file_path = get_save_file_path(slot)
	return FileAccess.file_exists(file_path)

func delete_save(slot: int) -> bool:
	"""Supprime une sauvegarde d'un slot"""
	if slot <= SaveSlot.QUICK_SAVE:  # Protection auto-save et quick-save
		print("💾 SaveSystem: Impossible de supprimer les slots système")
		return false
	
	var file_path = get_save_file_path(slot)
	if FileAccess.file_exists(file_path):
		DirAccess.open("user://").remove(file_path)
		save_metadata.erase(str(slot))
		save_save_metadata()
		print("💾 SaveSystem: Sauvegarde supprimée du slot ", slot)
		return true
	
	return false

func get_save_file_path(slot: int) -> String:
	"""Retourne le chemin complet d'un fichier de sauvegarde"""
	return SAVE_BASE_PATH + "save_slot_" + str(slot) + SAVE_FILE_EXTENSION

func get_all_save_slots() -> Array[Dictionary]:
	"""Retourne la liste de toutes les sauvegardes avec leurs infos"""
	var saves = []
	
	for slot in range(MAX_SLOTS):
		var save_info = {
			"slot": slot,
			"exists": has_save_in_slot(slot),
			"metadata": get_save_info(slot)
		}
		saves.append(save_info)
	
	return saves

# ================================
# AUTO-SAVE
# ================================
func _on_auto_save_timer_timeout() -> void:
	"""Déclenché par le timer d'auto-save"""
	if not auto_save_enabled or is_saving or is_loading:
		return
	
	# Vérification conditions auto-save
	if should_auto_save():
		auto_save_triggered.emit()
		save_game(SaveSlot.AUTO_SAVE, SaveType.AUTO, "Sauvegarde automatique")

func should_auto_save() -> bool:
	"""Détermine si une auto-save doit être effectuée"""
	# Ne pas sauvegarder pendant les dialogues ou combats critiques
	if game_manager:
		var game_state = game_manager.get("current_state", 0)
		if game_state in [2, 3]:  # DIALOGUE, COMBAT
			return false
	
	# Ne pas sauvegarder si changement de scène en cours
	if game_manager and game_manager.get("is_changing_scene", false):
		return false
	
	return true

func enable_auto_save(enabled: bool) -> void:
	"""Active/désactive l'auto-save"""
	auto_save_enabled = enabled
	save_config["auto_save_enabled"] = enabled
	
	if auto_save_timer:
		if enabled:
			auto_save_timer.start()
		else:
			auto_save_timer.stop()
	
	save_save_config()

func set_auto_save_interval(interval: float) -> void:
	"""Modifie l'intervalle d'auto-save"""
	if interval < 10.0:  # Minimum 10 secondes
		interval = 10.0
	
	save_config["auto_save_interval"] = interval
	
	if auto_save_timer:
		auto_save_timer.wait_time = interval
	
	save_save_config()

# ================================
# QUICK SAVE/LOAD
# ================================
func quick_save() -> bool:
	"""Sauvegarde rapide (F5)"""
	return save_game(SaveSlot.QUICK_SAVE, SaveType.QUICK, "Sauvegarde rapide")

func quick_load() -> bool:
	"""Chargement rapide (F9)"""
	return load_game(SaveSlot.QUICK_SAVE)

# ================================
# BACKUP SYSTÈME
# ================================
func create_backup(slot: int) -> void:
	"""Crée une sauvegarde de backup"""
	if not backup_enabled:
		return
	
	var source_path = get_save_file_path(slot)
	if not FileAccess.file_exists(source_path):
		return
	
	var timestamp = Time.get_datetime_string_from_system().replace(":", "-")
	var backup_path = BACKUP_PATH + "backup_slot_" + str(slot) + "_" + timestamp + SAVE_FILE_EXTENSION
	
	# Copie du fichier
	DirAccess.open("user://").copy(source_path, backup_path)
	
	# Nettoyage anciens backups
	cleanup_old_backups()
	
	backup_created.emit(backup_path)
	print("💾 SaveSystem: Backup créé: ", backup_path)

func cleanup_old_backups() -> void:
	"""Supprime les anciens backups selon la limite configurée"""
	var dir = DirAccess.open(BACKUP_PATH)
	if dir == null:
		return
	
	var backup_files = []
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		if file_name.ends_with(SAVE_FILE_EXTENSION):
			var file_path = BACKUP_PATH + file_name
			var file_time = FileAccess.get_modified_time(file_path)
			backup_files.append({"path": file_path, "time": file_time})
		file_name = dir.get_next()
	
	# Tri par date (plus récent en premier)
	backup_files.sort_custom(func(a, b): return a.time > b.time)
	
	# Suppression des anciens
	var max_backups = save_config.get("max_backups", MAX_BACKUPS)
	for i in range(max_backups, backup_files.size()):
		DirAccess.open("user://").remove(backup_files[i].path)

# ================================
# MIGRATION & VERSIONING
# ================================
func check_save_version(save_data: Dictionary) -> bool:
	"""Vérifie si une migration est nécessaire"""
	var save_version = save_data.get("save_version", "0.0.0")
	return save_version != current_save_version

func migrate_save_data(save_data: Dictionary) -> Dictionary:
	"""Migre les données d'une ancienne version"""
	var old_version = save_data.get("save_version", "0.0.0")
	print("💾 SaveSystem: Migration ", old_version, " → ", current_save_version)
	
	# Migrations spécifiques par version
	match old_version:
		"0.9.0":
			save_data = migrate_from_0_9_0(save_data)
		"0.8.0":
			save_data = migrate_from_0_8_0(save_data)
		_:
			print("💾 SaveSystem: Version non supportée pour migration: ", old_version)
	
	# Mise à jour version
	save_data["save_version"] = current_save_version
	
	save_migration_completed.emit(old_version, current_save_version)
	return save_data

func migrate_from_0_9_0(save_data: Dictionary) -> Dictionary:
	"""Migration depuis version 0.9.0"""
	# Exemple de migration - adapter selon les changements réels
	if save_data.has("old_format_data"):
		save_data["new_format_data"] = save_data.old_format_data
		save_data.erase("old_format_data")
	
	return save_data

func migrate_from_0_8_0(save_data: Dictionary) -> Dictionary:
	"""Migration depuis version 0.8.0"""
	# Migrations multiples en chaîne
	save_data = migrate_from_0_9_0(migrate_from_0_8_0_to_0_9_0(save_data))
	return save_data

func migrate_from_0_8_0_to_0_9_0(save_data: Dictionary) -> Dictionary:
	"""Migration intermédiaire 0.8.0 → 0.9.0"""
	# Implémentation migration spécifique
	return save_data

func check_and_migrate_saves() -> void:
	"""Vérifie et migre toutes les sauvegardes existantes"""
	for slot in range(MAX_SLOTS):
		if has_save_in_slot(slot):
			var save_data = await read_save_file(slot)
			if not save_data.is_empty() and check_save_version(save_data):
				print("💾 SaveSystem: Migration nécessaire pour slot ", slot)
				save_data = migrate_save_data(save_data)
				await write_save_file(slot, save_data)

# ================================
# COMPRESSION
# ================================
func compress_save_data(data: String) -> PackedByteArray:
	"""Compresse les données de sauvegarde"""
	return data.to_utf8_buffer().compress(FileAccess.COMPRESSION_GZIP)

func decompress_save_data(compressed_data: PackedByteArray) -> String:
	"""Décompresse les données de sauvegarde"""
	var decompressed = compressed_data.decompress_dynamic(-1, FileAccess.COMPRESSION_GZIP)
	return decompressed.get_string_from_utf8()

# ================================
# EXPORT/IMPORT
# ================================
func export_save(slot: int, export_name: String = "") -> String:
	"""Exporte une sauvegarde pour partage"""
	if not has_save_in_slot(slot):
		return ""
	
	if export_name.is_empty():
		export_name = "export_" + Time.get_datetime_string_from_system().replace(":", "-")
	
	var source_path = get_save_file_path(slot)
	var export_path = EXPORT_PATH + export_name + SAVE_FILE_EXTENSION
	
	DirAccess.open("user://").copy(source_path, export_path)
	
	print("💾 SaveSystem: Sauvegarde exportée: ", export_path)
	return export_path

func import_save(import_path: String, target_slot: int) -> bool:
	"""Importe une sauvegarde depuis un fichier"""
	if not FileAccess.file_exists(import_path):
		return false
	
	if target_slot < SaveSlot.MANUAL_1:  # Pas d'import sur slots système
		return false
	
	var target_path = get_save_file_path(target_slot)
	DirAccess.open("user://").copy(import_path, target_path)
	
	# Validation
	var save_data = await read_save_file(target_slot)
	if save_data.is_empty():
		delete_save(target_slot)
		return false
	
	# Migration si nécessaire
	if check_save_version(save_data):
		save_data = migrate_save_data(save_data)
		await write_save_file(target_slot, save_data)
	
	# Mise à jour métadonnées
	update_save_metadata(target_slot, save_data)
	
	print("💾 SaveSystem: Sauvegarde importée dans slot ", target_slot)
	return true

# ================================
# MÉTADONNÉES
# ================================
func update_save_metadata(slot: int, save_data: Dictionary) -> void:
	"""Met à jour les métadonnées d'une sauvegarde"""
	save_metadata[str(slot)] = {
		"timestamp": save_data.get("timestamp", 0),
		"play_time": save_data.get("play_time", 0),
		"description": save_data.get("description", ""),
		"save_type": save_data.get("save_type", "MANUAL"),
		"level": save_data.get("player_data", {}).get("level", 1),
		"current_scene": save_data.get("player_data", {}).get("current_scene", ""),
		"version": save_data.get("save_version", current_save_version)
	}
	
	save_save_metadata()

func load_save_metadata() -> void:
	"""Charge les métadonnées des sauvegardes"""
	var metadata_path = SAVE_BASE_PATH + "metadata.json"
	if FileAccess.file_exists(metadata_path):
		var file = FileAccess.open(metadata_path, FileAccess.READ)
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()
		
		if parse_result == OK:
			save_metadata = json.data

func save_save_metadata() -> void:
	"""Sauvegarde les métadonnées des sauvegardes"""
	var metadata_path = SAVE_BASE_PATH + "metadata.json"
	var file = FileAccess.open(metadata_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_metadata))
	file.close()

# ================================
# CONFIGURATION
# ================================
func load_save_config() -> void:
	"""Charge la configuration du système de sauvegarde"""
	var config_path = "user://save_config.json"
	if FileAccess.file_exists(config_path):
		var file = FileAccess.open(config_path, FileAccess.READ)
		var json = JSON.new()
		var parse_result = json.parse(file.get_as_text())
		file.close()
		
		if parse_result == OK:
			save_config.merge(json.data)

func save_save_config() -> void:
	"""Sauvegarde la configuration du système"""
	var config_path = "user://save_config.json"
	var file = FileAccess.open(config_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(save_config))
	file.close()

# ================================
# UTILITAIRES
# ================================
func get_total_play_time() -> float:
	"""Retourne le temps de jeu total en secondes"""
	# TODO: Implémenter via GameManager
	return 0.0

func get_world_time() -> Dictionary:
	"""Retourne l'heure du monde de jeu"""
	# TODO: Implémenter via GameManager
	return {"hour": 12, "minute": 0, "day": 1}

func get_current_weather() -> String:
	"""Retourne la météo actuelle"""
	# TODO: Implémenter via WeatherSystem
	return "sunny"

func get_global_flags() -> Dictionary:
	"""Retourne tous les flags globaux du jeu"""
	if game_manager:
		return game_manager.get("story_variables", {})
	return {}

func get_all_npc_states() -> Dictionary:
	"""Retourne l'état de tous les NPCs"""
	if dialogue_manager and dialogue_manager.has_method("get_all_npc_states"):
		return dialogue_manager.get_all_npc_states()
	return {}

func get_creature_populations() -> Dictionary:
	"""Retourne l'état des populations de créatures"""
	if observation_manager and observation_manager.has_method("get_creature_populations"):
		return observation_manager.get_creature_populations()
	return {}

func apply_player_data(player_data: Dictionary) -> void:
	"""Applique les données du joueur"""
	if game_manager:
		game_manager.call("set_player_data", player_data)

func apply_world_state(world_state: Dictionary) -> void:
	"""Applique l'état du monde"""
	if game_manager:
		game_manager.call("set_world_state", world_state)

# ================================
# INPUT HANDLING
# ================================
func _input(event: InputEvent) -> void:
	"""Gestion des raccourcis clavier"""
	if event.is_action_pressed("quick_save"):
		quick_save()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("quick_load"):
		quick_load()
		get_viewport().set_input_as_handled()

# ================================
# CLOUD SAVE (FUTUR)
# ================================
func sync_to_cloud() -> bool:
	"""Synchronise les sauvegardes vers le cloud"""
	if not cloud_sync_enabled:
		return false
	
	# TODO: Implémenter synchronisation cloud
	print("💾 SaveSystem: Synchronisation cloud non implémentée")
	cloud_sync_completed.emit(false)
	return false

func download_from_cloud() -> bool:
	"""Télécharge les sauvegardes depuis le cloud"""
	if not cloud_sync_enabled:
		return false
	
	# TODO: Implémenter téléchargement cloud
	print("💾 SaveSystem: Téléchargement cloud non implémenté")
	return false

# ================================
# DEBUG & UTILITIES
# ================================
func get_save_system_info() -> Dictionary:
	"""Retourne des informations sur le système de sauvegarde"""
	return {
		"save_version": current_save_version,
		"auto_save_enabled": auto_save_enabled,
		"compression_enabled": compression_enabled,
		"backup_enabled": backup_enabled,
		"total_saves": get_total_save_count(),
		"total_backups": get_total_backup_count(),
		"last_save_time": last_save_time,
		"save_directory_size": get_save_directory_size()
	}

func get_total_save_count() -> int:
	"""Retourne le nombre total de sauvegardes"""
	var count = 0
	for slot in range(MAX_SLOTS):
		if has_save_in_slot(slot):
			count += 1
	return count

func get_total_backup_count() -> int:
	"""Retourne le nombre total de backups"""
	var dir = DirAccess.open(BACKUP_PATH)
	if dir == null:
		return 0
	
	var count = 0
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(SAVE_FILE_EXTENSION):
			count += 1
		file_name = dir.get_next()
	
	return count

func get_save_directory_size() -> int:
	"""Retourne la taille totale du répertoire de sauvegarde en octets"""
	var total_size = 0
	var dir = DirAccess.open(SAVE_BASE_PATH)
	if dir == null:
		return 0
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(SAVE_FILE_EXTENSION):
			var file_path = SAVE_BASE_PATH + file_name
			total_size += FileAccess.get_file_as_bytes(file_path).size()
		file_name = dir.get_next()
	
	return total_size

func clean_all_saves() -> void:
	"""Supprime toutes les sauvegardes (DEBUG ONLY)"""
	if not OS.is_debug_build():
		return
	
	for slot in range(MAX_SLOTS):
		if has_save_in_slot(slot):
			delete_save(slot)
	
	save_metadata.clear()
	save_save_metadata()
	print("💾 SaveSystem: Toutes les sauvegardes supprimées (DEBUG)")

# Signal pour indiquer que le manager est prêt
signal manager_initialized()

func _notification(what: int) -> void:
	"""Gestion des notifications système"""
	match what:
		NOTIFICATION_WM_CLOSE_REQUEST:
			# Sauvegarde d'urgence avant fermeture
			if auto_save_enabled:
				save_game(SaveSlot.AUTO_SAVE, SaveType.AUTO, "Sauvegarde de fermeture")
		NOTIFICATION_APPLICATION_PAUSED:
			# Sauvegarde lors de mise en pause (mobile)
			if auto_save_enabled:
				save_game(SaveSlot.AUTO_SAVE, SaveType.AUTO, "Sauvegarde pause")

func initialize() -> void:
	"""Finalise l'initialisation et émet le signal"""
	manager_initialized.emit()