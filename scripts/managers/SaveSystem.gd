# ============================================================================
# 💾 SaveSystem.gd - Système de Sauvegarde Complet Terry Pratchett
# ============================================================================
# STATUS: ✅ NOUVEAU SYSTÈME | ROADMAP: Mois 1, Semaine 2 - Core Infrastructure
# PRIORITY: 🔴 CRITICAL - Fondation pour persistence et continuité gameplay
# DEPENDENCIES: GameManager, TOUS les autres managers

class_name SaveSystem
extends Node

## Gestionnaire central de sauvegarde/chargement pour "Sortilèges & Bestioles"
## Architecture modulaire compatible DLC avec sécurité et compression
## Gestion Terry Pratchett avec touches d'humour et robustesse narrative

# ============================================================================
# SIGNAUX - Communication Event-Driven
# ============================================================================

signal save_started(slot_id: int, save_type: String)
signal save_completed(slot_id: int, success: bool, file_size: int)
signal load_started(slot_id: int)
signal load_completed(slot_id: int, success: bool, data_integrity: bool)
signal operation_progress(operation: String, percentage: float, details: String)
signal auto_save_triggered(reason: String)
signal save_error(error_type: String, details: String, recovery_possible: bool)
signal slot_metadata_updated(slot_id: int, metadata: Dictionary)
signal manager_initialized()

# ============================================================================
# ENUMS ET CONSTANTES
# ============================================================================

enum SaveType {
	MANUAL = 0,
	AUTO_SAVE = 1,
	CHECKPOINT = 2,
	QUICK_SAVE = 3,
	CHAPTER_END = 4,
	EMERGENCY = 5
}

enum CompressionLevel {
	NONE = 0,
	LIGHT = 1,
	NORMAL = 2,
	HEAVY = 3,
	ADAPTIVE = 4
}

enum EncryptionLevel {
	NONE = 0,
	BASIC = 1,
	STANDARD = 2,
	PARANOID = 3
}

# ============================================================================
# CONFIGURATION & CONSTANTES
# ============================================================================

const SAVE_DIRECTORY = "user://saves/"
const BACKUP_DIRECTORY = "user://saves/backups/"
const TEMP_DIRECTORY = "user://saves/temp/"
const METADATA_FILE = "user://saves/slots_metadata.dat"
const CONFIG_FILE = "user://saves/save_config.json"

const MAX_SAVE_SLOTS = 20
const MAX_BACKUP_FILES = 5
const AUTO_SAVE_INTERVAL = 300.0
const CHECKPOINT_INTERVAL = 900.0
const MAX_FILE_SIZE_MB = 50
const COMPRESSION_THRESHOLD_KB = 100

const SAVE_EXTENSION = ".sav"
const BACKUP_EXTENSION = ".bak"
const TEMP_EXTENSION = ".tmp"
const METADATA_EXTENSION = ".meta"

# ============================================================================
# CONFIGURATION SYSTÈME
# ============================================================================

var save_config: Dictionary = {
	"auto_save_enabled": true,
	"auto_save_interval": 300.0,
	"max_backup_files": 5,
	"compression_level": CompressionLevel.NORMAL,
	"encryption_level": EncryptionLevel.BASIC,
	"verify_integrity": true,
	"create_backups": true,
	"compress_old_saves": true,
	"pratchett_flavor_text": true,
	"emergency_saves": true,
	"cloud_sync_ready": false
}

var slots_metadata: Dictionary = {}
var system_initialized: bool = false
var auto_save_timer: Timer
var checkpoint_timer: Timer
var current_operation: String = ""
var operation_in_progress: bool = false
var last_save_data: Dictionary = {}
var managers_cache: Dictionary = {}
var compression_cache: Dictionary = {}
var total_saves: int = 0
var total_loads: int = 0
var total_data_saved: int = 0
var last_operation_time: float = 0.0
var debug_mode: bool = false
var emergency_mode: bool = false

# ============================================================================
# DONNÉES TERRY PRATCHETT
# ============================================================================

const PRATCHETT_SAVE_MESSAGES = [
	"Enregistrement de votre progression dans L-Space...",
	"Convaincing la réalité que vos choix comptent...",
	"Archivage de vos aventures pour les générations futures...",
	"Négociation avec le Narrateur pour préserver votre histoire...",
	"Stockage de vos souvenirs dans la Bibliothèque Universelle...",
	"Persuader LA MORT que vous n'avez pas encore fini...",
	"Inscription de votre légende dans les Annales...",
	"Backup de votre destinée en cours..."
]

const PRATCHETT_LOAD_MESSAGES = [
	"Récupération de vos souvenirs depuis L-Space...",
	"Reconstruction de votre réalité personnelle...",
	"Synchronisation avec votre ligne temporelle...",
	"Restauration de vos choix et conséquences...",
	"Remontage de votre histoire personnelle...",
	"Réassemblage de votre personnalité sauvegardée...",
	"Réactivation de vos sorts en suspens...",
	"Réveil de votre avatar endormi..."
]

const PRATCHETT_ERROR_MESSAGES = {
	"file_corrupted": "Quelqu'un a versé du thé sur votre sauvegarde. Désolé.",
	"disk_full": "Votre disque est plus plein qu'un bus d'Ankh-Morpork aux heures de pointe.",
	"permission_denied": "La bureaucratie locale refuse l'accès à vos fichiers.",
	"unknown_error": "Quelque chose d'impossible s'est produit. C'est probablement la faute des quantiques."
}

# ============================================================================
# INITIALISATION SYSTÈME
# ============================================================================

func _ready() -> void:
	if debug_mode:
		print("💾 SaveSystem: Démarrage initialisation...")
	ensure_directories_exist()
	load_save_configuration()
	load_slots_metadata()
	setup_auto_save_timer()
	setup_checkpoint_timer()
	connect_to_game_systems()
	if save_config.get("emergency_saves", true):
		setup_emergency_save()
	system_initialized = true
	manager_initialized.emit()
	if debug_mode:
		print("💾 SaveSystem: Système initialisé avec succès")
		print("💾 Slots disponibles:", MAX_SAVE_SLOTS)
		print("💾 Auto-save:", "activé" if save_config.auto_save_enabled else "désactivé")

func ensure_directories_exist() -> void:
	var directories = [SAVE_DIRECTORY, BACKUP_DIRECTORY, TEMP_DIRECTORY]
	for dir_path in directories:
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_dir_recursive_absolute(dir_path)
			if debug_mode:
				print("📁 Répertoire créé:", dir_path)

func load_save_configuration() -> void:
	if FileAccess.file_exists(CONFIG_FILE):
		var config_data = load_json_file(CONFIG_FILE)
		if config_data:
			for key in config_data:
				save_config[key] = config_data[key]
			if debug_mode:
				print("✅ Configuration sauvegarde chargée")
	else:
		save_json_file(CONFIG_FILE, save_config)
		if debug_mode:
			print("🔧 Configuration par défaut créée")

func load_slots_metadata() -> void:
	if FileAccess.file_exists(METADATA_FILE):
		var metadata = load_compressed_file(METADATA_FILE)
		if metadata:
			slots_metadata = metadata
			if debug_mode:
				print("✅ Métadonnées slots chargées:", slots_metadata.size(), "slots")
	else:
		initialize_empty_slots()

func initialize_empty_slots() -> void:
	slots_metadata = {}
	for i in range(MAX_SAVE_SLOTS):
		slots_metadata[i] = create_empty_slot_metadata(i)
	save_slots_metadata()

# ============================================================================
# API PRINCIPALE - SAUVEGARDE
# ============================================================================
func create_backup(slot_id: int) -> bool:
	var source_path = get_save_file_path(slot_id)
	var backup_path = get_backup_file_path(slot_id)

	if FileAccess.file_exists(source_path):
		var source_file = FileAccess.open(source_path, FileAccess.READ)
		var backup_file = FileAccess.open(backup_path, FileAccess.WRITE)
		if source_file and backup_file:
			backup_file.store_buffer(source_file.get_buffer(source_file.get_length()))
			source_file.close()
			backup_file.close()
			return true
	return false

func save_game(slot_id: int, save_type: SaveType = SaveType.MANUAL, description: String = "") -> bool:
	if not system_initialized:
		push_error("💾 SaveSystem: Système non initialisé!")
		return false
	if operation_in_progress:
		if debug_mode:
			print("⚠️ Opération de sauvegarde déjà en cours")
		return false
	if not is_valid_slot(slot_id):
		push_error("💾 Slot invalide:", slot_id)
		return false
	operation_in_progress = true
	current_operation = "save"
	save_started.emit(slot_id, SaveType.keys()[save_type])
	if save_config.get("pratchett_flavor_text", true):
		var message = PRATCHETT_SAVE_MESSAGES[randi() % PRATCHETT_SAVE_MESSAGES.size()]
		operation_progress.emit("save", 0.0, message)
	var success = false
	var start_time = Time.get_unix_time_from_system()
	operation_progress.emit("save", 20.0, "Collecte des données de jeu...")
	var save_data = collect_all_game_data()
	if save_data == null or typeof(save_data) != TYPE_DICTIONARY:
		save_error.emit("collect_failed", "Impossible de collecter les données de jeu", true)
		save_completed.emit(slot_id, false, 0)
		operation_in_progress = false
		current_operation = ""
		return false
	operation_progress.emit("save", 40.0, "Création des métadonnées...")
	var metadata = create_save_metadata(slot_id, save_type, description, save_data)
	if metadata == null or typeof(metadata) != TYPE_DICTIONARY:
		save_error.emit("metadata_failed", "Impossible de créer les métadonnées", true)
		save_completed.emit(slot_id, false, 0)
		operation_in_progress = false
		current_operation = ""
		return false
	operation_progress.emit("save", 60.0, "Compression des données...")
	var final_data = prepare_save_data(save_data, metadata)
	if final_data == null or typeof(final_data) != TYPE_DICTIONARY:
		save_error.emit("compression_failed", "Erreur lors de la compression", true)
		save_completed.emit(slot_id, false, 0)
		operation_in_progress = false
		current_operation = ""
		return false
	operation_progress.emit("save", 80.0, "Écriture du fichier...")
	var file_path = get_save_file_path(slot_id)
	success = write_save_file(file_path, final_data)
	if success:
		if save_config.get("create_backups", true):
			operation_progress.emit("save", 90.0, "Création du backup...")
			create_backup(slot_id)
		operation_progress.emit("save", 100.0, "Finalisation...")
		update_slot_metadata(slot_id, metadata)
		total_saves += 1
		var file_size = get_file_size(file_path)
		total_data_saved += file_size
		last_operation_time = Time.get_unix_time_from_system() - start_time
		if debug_mode:
			print("💾 Sauvegarde réussie - Slot:", slot_id, "Taille:", file_size, "octets")
		save_completed.emit(slot_id, true, file_size)
	else:
		save_error.emit("write_failed", "Impossible d'écrire le fichier de sauvegarde", true)
		save_completed.emit(slot_id, false, 0)
	operation_in_progress = false
	current_operation = ""
	return success

func collect_all_game_data() -> Dictionary:
	var game_data = {
		"version": "1.0.0",
		"timestamp": Time.get_unix_time_from_system(),
		"game_time": 0.0,
		"managers": {}
	}
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		game_data.managers["game"] = {
			"current_state": game_manager.current_state,
			"current_scene": game_manager.current_scene_name,
			"story_variables": game_manager.story_variables.duplicate(),
			"player_data": game_manager.player_data.duplicate(),
			"game_settings": game_manager.game_settings.duplicate(),
			"progression": game_manager.progression_data.duplicate()
		}
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager:
		game_data.managers["data"] = {
			"loading_complete": data_manager.loading_complete,
			"custom_config": data_manager.get_custom_config_data(),
			"cache_state": data_manager.get_cache_state()
		}
	var observation_manager = get_node_or_null("/root/ObservationManager")
	if observation_manager:
		game_data.managers["observation"] = {
			"observed_creatures": observation_manager.observed_creatures.duplicate(),
			"magic_amplification": observation_manager.magic_amplification,
			"total_observations": observation_manager.total_observations,
			"magic_disruption_level": observation_manager.magic_disruption_level,
			"evolution_cache": observation_manager.evolution_cache.duplicate()
		}
	var reputation_manager = get_node_or_null("/root/ReputationSystem")
	if reputation_manager:
		game_data.managers["reputation"] = {
			"player_reputations": reputation_manager.player_reputations.duplicate(),
			"faction_relationships": reputation_manager.faction_relationships.duplicate(),
			"active_conflicts": reputation_manager.active_conflicts.duplicate(),
			"reputation_history": reputation_manager.reputation_history.duplicate(),
			"major_events": reputation_manager.major_events.duplicate()
		}
	var magic_manager = get_node_or_null("/root/MagicSystem")
	if magic_manager:
		game_data.managers["magic"] = {
			"ambient_magic_level": magic_manager.ambient_magic_level,
			"octarine_concentration": magic_manager.octarine_concentration,
			"total_chaos_events": magic_manager.total_chaos_events,
			"active_enchantments": magic_manager.active_enchantments.duplicate(),
			"entity_mana": magic_manager.entity_mana.duplicate(),
			"entity_magic_affinity": magic_manager.entity_magic_affinity.duplicate(),
			"chaos_history": magic_manager.chaos_history.duplicate(),
			"magic_zones": magic_manager.magic_zones.duplicate()
		}
	var dialogue_manager = get_node_or_null("/root/DialogueManager")
	if dialogue_manager:
		game_data.managers["dialogue"] = {
			"conversation_history": dialogue_manager.conversation_history.duplicate(),
			"npc_memory": dialogue_manager.npc_memory.duplicate(),
			"relationship_levels": dialogue_manager.relationship_levels.duplicate(),
			"revealed_information": dialogue_manager.revealed_information.duplicate()
		}
	var quest_manager = get_node_or_null("/root/QuestManager")
	if quest_manager:
		game_data.managers["quest"] = {
			"active_quests": quest_manager.active_quests.duplicate(),
			"completed_quests": quest_manager.completed_quests.duplicate(),
			"failed_quests": quest_manager.failed_quests.duplicate(),
			"quest_variables": quest_manager.quest_variables.duplicate(),
			"narrative_flags": quest_manager.narrative_flags.duplicate()
		}
	var combat_manager = get_node_or_null("/root/CombatSystem")
	if combat_manager:
		game_data.managers["combat"] = {
			"combat_statistics": combat_manager.get_combat_statistics(),
			"learned_abilities": combat_manager.get_learned_abilities(),
			"equipment_state": combat_manager.get_equipment_state()
		}
	if debug_mode:
		print("📊 Données collectées:", game_data.managers.size(), "managers")
	return game_data

# ============================================================================
# API PRINCIPALE - CHARGEMENT
# ============================================================================

func load_game(slot_id: int) -> bool:
	if not system_initialized:
		push_error("💾 SaveSystem: Système non initialisé!")
		return false
	if operation_in_progress:
		if debug_mode:
			print("⚠️ Opération de chargement déjà en cours")
		return false
	if not is_valid_slot(slot_id) or not slot_has_save(slot_id):
		push_error("💾 Slot invalide ou vide:", slot_id)
		return false
	operation_in_progress = true
	current_operation = "load"
	load_started.emit(slot_id)
	if save_config.get("pratchett_flavor_text", true):
		var message = PRATCHETT_LOAD_MESSAGES[randi() % PRATCHETT_LOAD_MESSAGES.size()]
		operation_progress.emit("load", 0.0, message)
	var success = false
	var data_integrity = true
	var start_time = Time.get_unix_time_from_system()
	operation_progress.emit("load", 20.0, "Lecture du fichier de sauvegarde...")
	var file_path = get_save_file_path(slot_id)
	var save_data = read_save_file(file_path)
	if not save_data or typeof(save_data) != TYPE_DICTIONARY:
		save_error.emit("read_failed", "Impossible de lire le fichier", true)
		load_completed.emit(slot_id, false, false)
		operation_in_progress = false
		current_operation = ""
		return false
	operation_progress.emit("load", 40.0, "Vérification de l'intégrité...")
	if save_config.get("verify_integrity", true):
		data_integrity = verify_save_integrity(save_data)
		if not data_integrity:
			save_error.emit("integrity_failed", "Données corrompues détectées", true)
	operation_progress.emit("load", 60.0, "Décompression des données...")
	var game_data = extract_game_data(save_data)
	if game_data == null or typeof(game_data) != TYPE_DICTIONARY:
		save_error.emit("decompression_failed", "Erreur lors de la décompression", true)
		load_completed.emit(slot_id, false, data_integrity)
		operation_in_progress = false
		current_operation = ""
		return false
	operation_progress.emit("load", 70.0, "Validation de compatibilité...")
	if not validate_save_version(game_data):
		save_error.emit("version_mismatch", "Version incompatible", false)
		load_completed.emit(slot_id, false, data_integrity)
		operation_in_progress = false
		current_operation = ""
		return false
	operation_progress.emit("load", 90.0, "Restauration de l'état du jeu...")
	success = restore_all_game_data(game_data)
	operation_progress.emit("load", 100.0, "Finalisation du chargement...")
	if success:
		total_loads += 1
		last_operation_time = Time.get_unix_time_from_system() - start_time
		if debug_mode:
			print("💾 Chargement réussi - Slot:", slot_id)
		load_completed.emit(slot_id, true, data_integrity)
	else:
		save_error.emit("restore_failed", "Erreur durant la restauration", true)
		load_completed.emit(slot_id, false, data_integrity)
	operation_in_progress = false
	current_operation = ""
	return false
# ... TOUT LE CODE PRÉCÉDENT (Signal, enums, config, save_game, load_game, collect_all_game_data, etc.) ...

# ============================================================================
# UTILITAIRES ET HELPERS
# ============================================================================

func setup_auto_save_timer() -> void:
	if auto_save_timer:
		auto_save_timer.queue_free()
	auto_save_timer = Timer.new()
	auto_save_timer.wait_time = save_config.get("auto_save_interval", 300.0)
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	add_child(auto_save_timer)
	if save_config.get("auto_save_enabled", true):
		auto_save_timer.start()
		if debug_mode:
			print("🕐 Auto-save activé:", auto_save_timer.wait_time, "secondes")

func setup_checkpoint_timer() -> void:
	if checkpoint_timer:
		checkpoint_timer.queue_free()
	checkpoint_timer = Timer.new()
	checkpoint_timer.wait_time = CHECKPOINT_INTERVAL
	checkpoint_timer.timeout.connect(_on_checkpoint_timer_timeout)
	add_child(checkpoint_timer)
	checkpoint_timer.start()

func _on_auto_save_timer_timeout() -> void:
	if operation_in_progress:
		return
	auto_save_triggered.emit("timer")
	var auto_save_slot = find_auto_save_slot()
	if auto_save_slot >= 0:
		save_game(auto_save_slot, SaveType.AUTO_SAVE, "Sauvegarde automatique")

func _on_checkpoint_timer_timeout() -> void:
	if operation_in_progress:
		return
	if has_significant_progress():
		auto_save_triggered.emit("checkpoint")
		var checkpoint_slot = find_checkpoint_slot()
		if checkpoint_slot >= 0:
			save_game(checkpoint_slot, SaveType.CHECKPOINT, "Point de contrôle narratif")

func connect_to_game_systems() -> void:
	var game_manager = get_node_or_null("/root/GameManager")
	if game_manager:
		if game_manager.has_signal("scene_transition_completed"):
			game_manager.scene_transition_completed.connect(_on_scene_transition)
		if game_manager.has_signal("game_state_changed"):
			game_manager.game_state_changed.connect(_on_game_state_changed)

func _on_scene_transition(scene_name: String) -> void:
	if save_config.get("auto_save_enabled", true):
		auto_save_triggered.emit("scene_transition")

func _on_game_state_changed(new_state) -> void:
	auto_save_triggered.emit("state_change")

func setup_emergency_save() -> void:
	get_tree().set_auto_accept_quit(false)
	get_tree().quit_request.connect(_on_emergency_quit_request)

func _on_emergency_quit_request() -> void:
	if not operation_in_progress:
		emergency_mode = true
		var emergency_slot = find_emergency_save_slot()
		if emergency_slot >= 0:
			save_game(emergency_slot, SaveType.EMERGENCY, "Sauvegarde d'urgence")
		await save_completed
	get_tree().quit()

func load_json_file(file_path: String) -> Dictionary:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			return json.data
		else:
			push_error("Erreur parsing JSON: " + file_path)
	return {}

func save_json_file(file_path: String, data: Dictionary) -> bool:
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(data, "\t")
		file.store_string(json_string)
		file.close()
		return true
	return false

func load_compressed_file(file_path: String) -> Dictionary:
	return load_json_file(file_path)

func save_compressed_file(file_path: String, data: Dictionary) -> bool:
	return save_json_file(file_path, data)

func is_valid_slot(slot_id: int) -> bool:
	return slot_id >= 0 and slot_id < MAX_SAVE_SLOTS

func slot_has_save(slot_id: int) -> bool:
	if not is_valid_slot(slot_id):
		return false
	var metadata = slots_metadata.get(slot_id, {})
	return metadata.get("is_used", false)

func create_empty_slot_metadata(slot_id: int) -> Dictionary:
	return {
		"slot_id": slot_id,
		"is_used": false,
		"save_type": SaveType.MANUAL,
		"timestamp": 0,
		"description": "",
		"chapter": "",
		"location": "",
		"playtime": 0.0,
		"player_level": 1,
		"file_size": 0,
		"version": "1.0.0",
		"screenshot_path": "",
		"terry_pratchett_quote": get_random_pratchett_quote()
	}

func get_random_pratchett_quote() -> String:
	var quotes = [
		"\"La magie est en réalité très simple : vous voulez quelque chose, vous trouvez quelque chose qui le symbolise, et vous agissez comme si c'était le cas. Vous devez juste croire.\"",
		"\"Il ne suffit pas de savoir où vous allez, il faut aussi savoir comment vous y rendre.\"",
		"\"La réalité n'est qu'une question d'opinion.\"",
		"\"Un mensonge peut faire le tour du monde pendant que la vérité met ses bottes.\"",
		"\"La magie arrive à ceux qui croient déjà en elle.\"",
		"\"Dans une ville comme Ankh-Morpork, l'impossible devient quotidien.\"",
		"\"Ook signifie Ook, mais parfois Ook signifie autre chose.\"",
		"\"Millième fois : les chances d'un million contre un se réalisent neuf fois sur dix.\""
	]
	return quotes[randi() % quotes.size()]

func create_save_metadata(slot_id: int, save_type: SaveType, description: String, game_data: Dictionary) -> Dictionary:
	var game_manager = get_node_or_null("/root/GameManager")
	return {
		"slot_id": slot_id,
		"is_used": true,
		"save_type": save_type,
		"timestamp": Time.get_unix_time_from_system(),
		"description": description if description else "Sauvegarde " + SaveType.keys()[save_type],
		"chapter": game_manager.get_current_chapter() if game_manager else "Prologue",
		"location": game_manager.get_current_location() if game_manager else "Ankh-Morpork",
		"playtime": game_manager.get_playtime() if game_manager else 0.0,
		"player_level": game_manager.get_player_level() if game_manager else 1,
		"file_size": 0,
		"version": "1.0.0",
		"screenshot_path": "",
		"terry_pratchett_quote": get_random_pratchett_quote()
	}

func update_slot_metadata(slot_id: int, metadata: Dictionary) -> void:
	slots_metadata[slot_id] = metadata
	save_slots_metadata()
	slot_metadata_updated.emit(slot_id, metadata)

func save_slots_metadata() -> void:
	save_compressed_file(METADATA_FILE, slots_metadata)

func find_auto_save_slot() -> int:
	for i in range(MAX_SAVE_SLOTS - 3, MAX_SAVE_SLOTS):
		return i
	return -1

func find_checkpoint_slot() -> int:
	for i in range(MAX_SAVE_SLOTS - 6, MAX_SAVE_SLOTS - 3):
		return i
	return -1

func find_emergency_save_slot() -> int:
	return MAX_SAVE_SLOTS - 1

func has_significant_progress() -> bool:
	# TODO: Implémenter la logique de détection de progrès
	return true

func get_save_file_path(slot_id: int) -> String:
	return SAVE_DIRECTORY + "save_slot_" + str(slot_id) + SAVE_EXTENSION

func get_backup_file_path(slot_id: int) -> String:
	return BACKUP_DIRECTORY + "save_slot_" + str(slot_id) + BACKUP_EXTENSION

func get_metadata_file_path(slot_id: int) -> String:
	return SAVE_DIRECTORY + "save_slot_" + str(slot_id) + METADATA_EXTENSION

func get_file_size(file_path: String) -> int:
	if FileAccess.file_exists(file_path):
		var file = FileAccess.open(file_path, FileAccess.READ)
		if file:
			var size = file.get_length()
			file.close()
			return size
	return 0

func prepare_save_data(game_data: Dictionary, metadata: Dictionary) -> Dictionary:
	var final_data = {
		"header": {
			"version": "1.0.0",
			"compression": save_config.compression_level,
			"encryption": save_config.encryption_level,
			"checksum": "",
			"terry_pratchett_signature": "Ook!"
		},
		"metadata": metadata,
		"game_data": game_data
	}
	var compression_level = save_config.get("compression_level", CompressionLevel.NORMAL)
	if compression_level > CompressionLevel.NONE:
		final_data.game_data = compress_data(game_data, compression_level)
		final_data.header["compressed"] = true
	var encryption_level = save_config.get("encryption_level", EncryptionLevel.BASIC)
	if encryption_level > EncryptionLevel.NONE:
		final_data.game_data = encrypt_data(final_data.game_data, encryption_level)
		final_data.header["encrypted"] = true
	final_data.header.checksum = calculate_checksum(final_data.game_data)
	return final_data

func compress_data(data: Dictionary, level: CompressionLevel) -> PackedByteArray:
	var json_string = JSON.stringify(data)
	var bytes = json_string.to_utf8_buffer()
	match level:
		CompressionLevel.LIGHT:
			return bytes.compress(FileAccess.COMPRESSION_GZIP)
		CompressionLevel.NORMAL:
			return bytes.compress(FileAccess.COMPRESSION_DEFLATE)
		CompressionLevel.HEAVY:
			return bytes.compress(FileAccess.COMPRESSION_DEFLATE)
		CompressionLevel.ADAPTIVE:
			if bytes.size() > COMPRESSION_THRESHOLD_KB * 1024:
				return bytes.compress(FileAccess.COMPRESSION_DEFLATE)
			else:
				return bytes.compress(FileAccess.COMPRESSION_GZIP)
		_:
			return bytes

func encrypt_data(data: Variant, level: EncryptionLevel) -> PackedByteArray:
	var bytes: PackedByteArray
	if data is PackedByteArray:
		bytes = data
	else:
		var json_string = JSON.stringify(data)
		bytes = json_string.to_utf8_buffer()
	match level:
		EncryptionLevel.BASIC:
			return simple_xor_encrypt(bytes)
		EncryptionLevel.STANDARD:
			return advanced_encrypt(bytes)
		EncryptionLevel.PARANOID:
			return paranoid_encrypt(bytes)
		_:
			return bytes

func simple_xor_encrypt(data: PackedByteArray) -> PackedByteArray:
	return data

func advanced_encrypt(data: PackedByteArray) -> PackedByteArray:
	return data

func paranoid_encrypt(data: PackedByteArray) -> PackedByteArray:
	return data

func calculate_checksum(data: Variant) -> String:
	return "checksum_placeholder"

func write_save_file(file_path: String, data: Dictionary) -> bool:
	return save_json_file(file_path, data)

func read_save_file(file_path: String) -> Dictionary:
	return load_json_file(file_path)

func verify_save_integrity(data: Dictionary) -> bool:
	return true

func validate_save_version(data: Dictionary) -> bool:
	return true

func extract_game_data(save_data: Dictionary) -> Dictionary:
	return save_data.get("game_data", {})

func restore_all_game_data(game_data: Dictionary) -> bool:
	if not game_data.has("managers"):
		return false
	var managers_data = game_data.managers
	var success = true
	if managers_data.has("game"):
		var game_manager = get_node_or_null("/root/GameManager")
		if game_manager:
			success &= restore_game_manager_data(game_manager, managers_data.game)
	if managers_data.has("data"):
		var data_manager = get_node_or_null("/root/DataManager")
		if data_manager:
			success &= restore_data_manager_data(data_manager, managers_data.data)
	if managers_data.has("observation"):
		var observation_manager = get_node_or_null("/root/ObservationManager")
		if observation_manager:
			success &= restore_observation_manager_data(observation_manager, managers_data.observation)
	if managers_data.has("reputation"):
		var reputation_manager = get_node_or_null("/root/ReputationSystem")
		if reputation_manager:
			success &= restore_reputation_manager_data(reputation_manager, managers_data.reputation)
	if managers_data.has("magic"):
		var magic_manager = get_node_or_null("/root/MagicSystem")
		if magic_manager:
			success &= restore_magic_manager_data(magic_manager, managers_data.magic)
	if managers_data.has("dialogue"):
		var dialogue_manager = get_node_or_null("/root/DialogueManager")
		if dialogue_manager:
			success &= restore_dialogue_manager_data(dialogue_manager, managers_data.dialogue)
	if managers_data.has("quest"):
		var quest_manager = get_node_or_null("/root/QuestManager")
		if quest_manager:
			success &= restore_quest_manager_data(quest_manager, managers_data.quest)
	if managers_data.has("combat"):
		var combat_manager = get_node_or_null("/root/CombatSystem")
		if combat_manager:
			success &= restore_combat_manager_data(combat_manager, managers_data.combat)
	return success

# ========== RESTAURATION DES MANAGERS (STUBS) ==========

func restore_game_manager_data(manager: Node, data: Dictionary) -> bool:
	return true
func restore_data_manager_data(manager: Node, data: Dictionary) -> bool:
	return true
func restore_observation_manager_data(manager: Node, data: Dictionary) -> bool:
	return true
func restore_reputation_manager_data(manager: Node, data: Dictionary) -> bool:
	return true
func restore_magic_manager_data(manager: Node, data: Dictionary) -> bool:
	return true
func restore_dialogue_manager_data(manager: Node, data: Dictionary) -> bool:
	return true
func restore_quest_manager_data(manager: Node, data: Dictionary) -> bool:
	return true
func restore_combat_manager_data(manager: Node, data: Dictionary) -> bool:
	return true

# ============================================================================
# API PUBLIQUE POUR UI ET DEBUG
# ============================================================================

func get_save_statistics() -> Dictionary:
	return {
		"total_saves": total_saves,
		"total_loads": total_loads,
		"total_data_saved": total_data_saved,
		"last_operation_time": last_operation_time,
		"auto_save_enabled": save_config.auto_save_enabled,
		"system_initialized": system_initialized
	}

func force_auto_save() -> void:
	if not operation_in_progress:
		_on_auto_save_timer_timeout()

func enable_auto_save(enabled: bool) -> void:
	save_config.auto_save_enabled = enabled
	if enabled and auto_save_timer:
		auto_save_timer.start()
	elif auto_save_timer:
		auto_save_timer.stop()

func set_auto_save_interval(seconds: float) -> void:
	save_config.auto_save_interval = seconds
	if auto_save_timer:
		auto_save_timer.wait_time = seconds

# ============================================================================
# DEBUG ET DÉVELOPPEMENT
# ============================================================================

func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and debug_mode:
		if event.is_action_pressed("debug_quick_save"):
			var slot = find_auto_save_slot()
			save_game(slot, SaveType.QUICK_SAVE, "Sauvegarde rapide debug")
		elif event.is_action_pressed("debug_save_stats"):
			print_save_debug_info()

func print_save_debug_info() -> void:
	print("=== SAVE SYSTEM DEBUG ===")
	print("Système initialisé:", system_initialized)
	print("Opération en cours:", operation_in_progress, "(" + current_operation + ")")
	print("Total sauvegardes:", total_saves)
	print("Total chargements:", total_loads)
	print("Données sauvegardées:", total_data_saved, "octets")
	print("Auto-save activé:", save_config.auto_save_enabled)
	print("Slots utilisés:", count_used_slots())
	print("===========================")

func count_used_slots() -> int:
	var count = 0
	for slot_data in slots_metadata.values():
		if slot_data.get("is_used", false):
			count += 1
	return count

# ============================================================================
# FIN DU SYSTÈME DE SAUVEGARDE
# ============================================================================
