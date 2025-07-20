# 💬 DialogueManager.gd - Système de Conversations Complexes
# STATUS: 🔄 IN_PROGRESS | ROADMAP: Mois 1, Semaine 1-2 - Core Architecture  
# PRIORITY: 🟠 P2 - Critical pour prologue et interactions NPCs
# DEPENDENCIES: GameManager, ObservationManager

class_name DialogueManager
extends Node

## Gestionnaire central des conversations et interactions NPCs
## Support pour arbres complexes, mémoire contextuelle, et réactions dynamiques
## Architecture Terry Pratchett-friendly avec humour et philosophie

# ============================================================================
# SIGNAUX - Communication Event-Driven
# ============================================================================

## Émis quand une conversation démarre
signal dialogue_started(npc_id: String, dialogue_id: String)

## Émis quand une conversation se termine
signal dialogue_ended(npc_id: String, final_choice: String, relationship_change: float)

## Émis quand une option de dialogue est sélectionnée
signal dialogue_choice_made(npc_id: String, choice_id: String, consequences: Dictionary)

## Émis quand un NPC révèle une nouvelle information
signal information_revealed(npc_id: String, info_type: String, data: Dictionary)

## Émis quand les relations avec un NPC changent
signal relationship_changed(npc_id: String, old_level: float, new_level: float)

## Émis pour mise à jour de quêtes via dialogue
signal quest_trigger_from_dialogue(quest_id: String, trigger_data: Dictionary)

# ============================================================================
# CONFIGURATION & DONNÉES
# ============================================================================

## Configuration système chargée depuis JSON
@export var dialogue_trees_path: String = "res://data/dialogue_trees.json"
@export var character_data_path: String = "res://data/character_data.json"
@export var dialogue_config_path: String = "res://data/dialogue_config.json"

## Bases de données chargées
var dialogue_trees: Dictionary = {}
var character_database: Dictionary = {}
var dialogue_config: Dictionary = {}

## État actuel du système
var current_dialogue: Dictionary = {}
var current_npc_id: String = ""
var conversation_history: Array = []
var active_conversation: bool = false

## Mémoire des NPCs et relations
var npc_memory: Dictionary = {}
var relationship_levels: Dictionary = {}
var revealed_information: Dictionary = {}

# ============================================================================
# TYPES & ENUMS
# ============================================================================

enum DialogueType {
	STANDARD = 0,      ## Conversation normale
	QUEST_CRITICAL = 1, ## Dialogue essentiel pour progression
	INFORMATION = 2,    ## Révélation d'informations
	TRADING = 3,        ## Commerce/négociation  
	PHILOSOPHICAL = 4,  ## Discussions profondes (style Pratchett)
	COMEDIC = 5,        ## Dialogues humoristiques
	DEATH_SPECIAL = 6   ## Conversations avec LA MORT
}

enum ChoiceType {
	NORMAL = 0,         ## Choix standard
	SKILL_CHECK = 1,    ## Requis compétence/stat
	RELATIONSHIP = 2,   ## Basé sur relation avec NPC
	OBSERVATION = 3,    ## Basé sur créatures observées
	KNOWLEDGE = 4,      ## Basé sur informations révélées
	UNIQUE = 5          ## Choix unique (une seule fois)
}

enum RelationshipLevel {
	HOSTILE = -2,       ## NPC hostile
	UNFRIENDLY = -1,    ## Relation négative
	NEUTRAL = 0,        ## Indifférent
	FRIENDLY = 1,       ## Relation positive
	ALLY = 2            ## Allié proche
}

# ============================================================================
# INITIALISATION SYSTÈME
# ============================================================================

func _ready() -> void:
	"""Initialisation du système de dialogue"""
	load_configuration()
	load_dialogue_trees()
	load_character_database()
	initialize_npc_memory()
	connect_to_game_systems()
	
	print("💬 DialogueManager: Système initialisé")

func load_configuration() -> void:
	"""Charge la configuration des dialogues"""
	if FileAccess.file_exists(dialogue_config_path):
		var config_data = load_json_file(dialogue_config_path)
		if config_data:
			dialogue_config = config_data
			print("✅ Config dialogue chargée:", dialogue_config.size(), " paramètres")
		else:
			load_default_dialogue_config()
	else:
		load_default_dialogue_config()

func load_default_dialogue_config() -> void:
	"""Configuration par défaut si fichier absent"""
	dialogue_config = {
		"typing_speed": 0.05,
		"auto_advance_time": 3.0,
		"relationship_decay_rate": 0.01,
		"memory_retention_days": 30,
		"humor_frequency": 0.3,
		"philosophy_depth": 0.6,
		"max_conversation_length": 50
	}

func load_dialogue_trees() -> void:
	"""Charge tous les arbres de dialogue depuis JSON"""
	if FileAccess.file_exists(dialogue_trees_path):
		var trees_data = load_json_file(dialogue_trees_path)
		if trees_data:
			dialogue_trees = trees_data
			print("✅ Arbres dialogue chargés:", dialogue_trees.size(), " conversations")
		else:
			setup_test_dialogues()
	else:
		print("⚠️ Fichier dialogue_trees.json non trouvé, chargement données test")
		setup_test_dialogues()

func load_character_database() -> void:
	"""Charge la base de données des personnages"""
	if FileAccess.file_exists(character_data_path):
		var char_data = load_json_file(character_data_path)
		if char_data:
			character_database = char_data
			print("✅ Base personnages chargée:", character_database.size(), " NPCs")
		else:
			setup_test_characters()
	else:
		print("⚠️ Fichier character_data.json non trouvé, chargement données test")
		setup_test_characters()

func load_json_file(file_path: String) -> Dictionary:
	"""Utilitaire de chargement JSON avec gestion d'erreurs"""
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("❌ Impossible d'ouvrir:", file_path)
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result == OK:
		return json.data
	else:
		print("❌ Erreur parsing JSON:", file_path, " - ", json.get_error_message())
		return {}

# ============================================================================
# DONNÉES DE TEST (À REMPLACER PAR JSON)
# ============================================================================

func setup_test_characters() -> void:
	"""Personnages de test pour validation système"""
	character_database = {
		"maurice": {
			"name": "Maurice",
			"title": "Rat Éduqué", 
			"description": "Un rat remarquablement intelligent avec un monocle",
			"personality": ["intelligent", "sarcastique", "pragmatique"],
			"base_relationship": 0,
			"dialogue_style": "witty",
			"special_abilities": ["parole", "lecture", "bureaucratie"],
			"location": "rue_dolly_sisters",
			"quest_giver": true
		},
		"madame_simnel": {
			"name": "Madame Simnel",
			"title": "Propriétaire d'Immeuble",
			"description": "Dame âgée énergique qui gère l'immeuble",
			"personality": ["énergique", "bavarde", "bienveillante"],
			"base_relationship": 1,
			"dialogue_style": "chatty",
			"special_abilities": ["potins", "conseils_pratiques"],
			"location": "couloir_immeuble",
			"quest_giver": false
		},
		"death": {
			"name": "LA MORT",
			"title": "Personnification Anthropomorphique",
			"description": "LA MORT en personne, avec sa faux et son sens de l'humour noir",
			"personality": ["philosophique", "littéral", "curieux"],
			"base_relationship": 0,
			"dialogue_style": "CAPS_LOCK",
			"special_abilities": ["omniscience", "philosophie", "timing_parfait"],
			"location": "variable",
			"quest_giver": true,
			"unique": true
		},
		"catalogueur_senior": {
			"name": "Maître Catalogueur Vhentz",
			"title": "Superviseur Académique",
			"description": "Catalogueur expérimenté, mentor potentiel",
			"personality": ["méticuleux", "patient", "savant"],
			"base_relationship": 0,
			"dialogue_style": "academic",
			"special_abilities": ["connaissance_créatures", "magie_théorique"],
			"location": "université_invisible",
			"quest_giver": true
		}
	}

func setup_test_dialogues() -> void:
	"""Arbres de dialogue de test pour validation"""
	dialogue_trees = {
		"maurice_first_encounter": {
			"type": DialogueType.QUEST_CRITICAL,
			"character": "maurice",
			"nodes": {
				"start": {
					"text": "Excusez-moi, vous semblez être le nouveau Catalogueur ? J'ai une proposition qui pourrait vous intéresser.",
					"speaker": "maurice",
					"choices": [
						{
							"id": "choice_1",
							"text": "Un rat qui parle ? Fascinant !",
							"next": "maurice_pleased",
							"type": ChoiceType.NORMAL,
							"relationship_change": 0.1
						},
						{
							"id": "choice_2", 
							"text": "Je dois rêver. Les rats ne parlent pas.",
							"next": "maurice_skeptical",
							"type": ChoiceType.NORMAL,
							"relationship_change": -0.1
						},
						{
							"id": "choice_3",
							"text": "Que voulez-vous ?",
							"next": "maurice_business",
							"type": ChoiceType.NORMAL
						}
					]
				},
				"maurice_pleased": {
					"text": "Excellent ! Quelqu'un qui apprécie l'extraordinaire. Je représente un... syndicat de créatures urbaines ayant des préoccupations légitimes.",
					"speaker": "maurice",
					"choices": [
						{
							"id": "more_info",
							"text": "Continuez, vous avez mon attention.",
							"next": "maurice_explains",
							"type": ChoiceType.NORMAL
						}
					]
				},
				"maurice_skeptical": {
					"text": "*ajuste son monocle* Mon cher, votre éducation semble avoir négligé la réalité du Disque-Monde. Ici, tout est possible.",
					"speaker": "maurice",
					"choices": [
						{
							"id": "accept_reality",
							"text": "Vous avez raison, pardonnez mon scepticisme.",
							"next": "maurice_forgiven",
							"type": ChoiceType.NORMAL,
							"relationship_change": 0.2
						}
					]
				},
				"maurice_business": {
					"text": "Direct et efficace, j'apprécie. Nous avons remarqué vos... observations des créatures locales. Cela nous intéresse.",
					"speaker": "maurice",
					"choices": [
						{
							"id": "how_do_you_know",
							"text": "Comment savez-vous cela ?",
							"next": "maurice_network",
							"type": ChoiceType.NORMAL
						}
					]
				}
			},
			"triggers": {
				"quest_start": "rat_investigation",
				"information_unlock": "rat_intelligence_network"
			}
		},
		
		"death_philosophy": {
			"type": DialogueType.PHILOSOPHICAL,
			"character": "death", 
			"nodes": {
				"start": {
					"text": "AH, LE NOUVEAU CATALOGUEUR. J'ESPÈRE QUE VOUS COMPRENEZ L'IRONIE DE VOTRE PROFESSION.",
					"speaker": "death",
					"choices": [
						{
							"id": "what_irony",
							"text": "Quelle ironie ?",
							"next": "death_explains_irony",
							"type": ChoiceType.NORMAL
						},
						{
							"id": "not_my_time",
							"text": "Ce n'est pas mon heure, j'espère ?",
							"next": "death_reassures",
							"type": ChoiceType.NORMAL
						}
					]
				},
				"death_explains_irony": {
					"text": "VOUS CATALOGUEZ LA VIE POUR LA COMPRENDRE, MAIS C'EST EN OBSERVANT QUE VOUS LA CHANGEZ. L'OBSERVATION EST UNE FORME DE CRÉATION.",
					"speaker": "death",
					"choices": [
						{
							"id": "deep_thought",
							"text": "C'est... profondément vrai.",
							"next": "death_pleased_wisdom",
							"type": ChoiceType.NORMAL,
							"relationship_change": 0.3
						}
					]
				}
			},
			"triggers": {
				"philosophy_point_gained": 1,
				"death_relationship_established": true
			}
		}
	}

# ============================================================================
# SYSTÈME PRINCIPAL DE DIALOGUE
# ============================================================================

func start_dialogue(npc_id: String, dialogue_id: String = "") -> bool:
	"""
	Démarre une conversation avec un NPC
	Si dialogue_id vide, utilise le dialogue par défaut du NPC
	"""
	
	# Validation NPC
	if not character_database.has(npc_id):
		print("❌ NPC inconnu:", npc_id)
		return false
	
	# Détermination du dialogue à utiliser
	var final_dialogue_id = dialogue_id
	if final_dialogue_id == "":
		final_dialogue_id = get_default_dialogue_for_npc(npc_id)
	
	# Validation dialogue
	if not dialogue_trees.has(final_dialogue_id):
		print("❌ Dialogue inexistant:", final_dialogue_id)
		return false
	
	# Vérification si dialogue déjà actif
	if active_conversation:
		print("⚠️ Conversation déjà en cours avec:", current_npc_id)
		end_dialogue("interrupted")
	
	# Initialisation de la conversation
	current_npc_id = npc_id
	current_dialogue = dialogue_trees[final_dialogue_id]
	active_conversation = true
	
	# Mise à jour mémoire NPC
	update_npc_memory(npc_id, "conversation_started", {
		"dialogue_id": final_dialogue_id,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Émission du signal
	dialogue_started.emit(npc_id, final_dialogue_id)
	
	print("💬 Dialogue démarré:", npc_id, "→", final_dialogue_id)
	
	return true

func get_current_dialogue_node() -> Dictionary:
	"""Retourne le nœud de dialogue actuel"""
	if not active_conversation:
		return {}
	
	var current_node_id = current_dialogue.get("current_node", "start")
	var nodes = current_dialogue.get("nodes", {})
	
	if nodes.has(current_node_id):
		var node = nodes[current_node_id].duplicate()
		
		# Processing contextuel du texte
		node.text = process_dialogue_text(node.text)
		
		# Filtrage des choix selon conditions
		if node.has("choices"):
			node.choices = filter_available_choices(node.choices)
		
		return node
	
	print("❌ Nœud dialogue inexistant:", current_node_id)
	return {}

func make_dialogue_choice(choice_id: String) -> bool:
	"""Traite un choix de dialogue du joueur"""
	if not active_conversation:
		print("❌ Aucune conversation active")
		return false
	
	var current_node = get_current_dialogue_node()
	if not current_node.has("choices"):
		print("❌ Pas de choix disponibles")
		return false
	
	# Recherche du choix sélectionné
	var selected_choice = null
	for choice in current_node.choices:
		if choice.id == choice_id:
			selected_choice = choice
			break
	
	if not selected_choice:
		print("❌ Choix inexistant:", choice_id)
		return false
	
	# Application des conséquences du choix
	apply_choice_consequences(selected_choice)
	
	# Transition vers le prochain nœud
	if selected_choice.has("next"):
		current_dialogue.current_node = selected_choice.next
	else:
		# Fin de conversation
		end_dialogue(choice_id)
		return true
	
	# Mise à jour mémoire
	update_npc_memory(current_npc_id, "choice_made", {
		"choice_id": choice_id,
		"choice_text": selected_choice.text,
		"timestamp": Time.get_unix_time_from_system()
	})
	
	# Émission signal
	var consequences = selected_choice.get("consequences", {})
	dialogue_choice_made.emit(current_npc_id, choice_id, consequences)
	
	return true

func end_dialogue(final_choice: String = "") -> void:
	"""Termine la conversation active"""
	if not active_conversation:
		return
	
	var npc_id = current_npc_id
	var relationship_change = 0.0
	
	# Calcul du changement de relation final
	if npc_memory.has(npc_id) and npc_memory[npc_id].has("session_relationship_change"):
		relationship_change = npc_memory[npc_id].session_relationship_change
	
	# Sauvegarde dans l'historique
	conversation_history.append({
		"npc_id": npc_id,
		"dialogue_id": current_dialogue.get("id", "unknown"),
		"final_choice": final_choice,
		"timestamp": Time.get_unix_time_from_system(),
		"relationship_change": relationship_change
	})
	
	# Reset de l'état
	active_conversation = false
	current_npc_id = ""
	current_dialogue = {}
	
	# Émission signal
	dialogue_ended.emit(npc_id, final_choice, relationship_change)
	
	print("💬 Dialogue terminé avec:", npc_id)

# ============================================================================
# SYSTÈME DE CHOIX ET CONDITIONS
# ============================================================================

func filter_available_choices(choices: Array) -> Array:
	"""Filtre les choix selon les conditions requises"""
	var available_choices = []
	
	for choice in choices:
		if is_choice_available(choice):
			available_choices.append(choice)
	
	return available_choices

func is_choice_available(choice: Dictionary) -> bool:
	"""Vérifie si un choix est disponible selon ses conditions"""
	var choice_type = choice.get("type", ChoiceType.NORMAL)
	
	match choice_type:
		ChoiceType.NORMAL:
			return true
			
		ChoiceType.SKILL_CHECK:
			return check_skill_requirement(choice)
			
		ChoiceType.RELATIONSHIP:
			return check_relationship_requirement(choice)
			
		ChoiceType.OBSERVATION:
			return check_observation_requirement(choice)
			
		ChoiceType.KNOWLEDGE:
			return check_knowledge_requirement(choice)
			
		ChoiceType.UNIQUE:
			return check_unique_choice_availability(choice)
	
	return false

func check_skill_requirement(choice: Dictionary) -> bool:
	"""Vérifie si le joueur a les compétences requises"""
	# TODO: Intégration avec système de compétences
	var required_skill = choice.get("required_skill", "")
	var required_level = choice.get("required_level", 1)
	
	# Pour l'instant, toujours vrai (placeholder)
	return true

func check_relationship_requirement(choice: Dictionary) -> bool:
	"""Vérifie le niveau de relation avec le NPC"""
	var required_level = choice.get("required_relationship", 0)
	var current_level = get_relationship_level(current_npc_id)
	
	return current_level >= required_level

func check_observation_requirement(choice: Dictionary) -> bool:
	"""Vérifie si certaines créatures ont été observées"""
	var required_observations = choice.get("required_observations", [])
	
	# Intégration avec ObservationManager
	# TODO REPAIR FONCTION
	if has_method("get_observed_creatures"):
		#var observed_creatures = get_observed_creatures()
		for required in required_observations:
		#	if not observed_creatures.has(required):
				return false
		return true
	
	# Fallback si ObservationManager pas connecté
	return true

func check_knowledge_requirement(choice: Dictionary) -> bool:
	"""Vérifie si certaines informations ont été révélées"""
	var required_info = choice.get("required_information", [])
	
	for info in required_info:
		if not revealed_information.has(info):
			return false
	
	return true

func check_unique_choice_availability(choice: Dictionary) -> bool:
	"""Vérifie si ce choix unique n'a pas déjà été utilisé"""
	var choice_id = choice.get("id", "")
	var npc_memory_data = npc_memory.get(current_npc_id, {})
	var used_unique_choices = npc_memory_data.get("used_unique_choices", [])
	
	return not (choice_id in used_unique_choices)

# ============================================================================
# SYSTÈME DE CONSÉQUENCES
# ============================================================================

func apply_choice_consequences(choice: Dictionary) -> void:
	"""Applique toutes les conséquences d'un choix de dialogue"""
	
	# Changement de relation
	if choice.has("relationship_change"):
		change_relationship(current_npc_id, choice.relationship_change)
	
	# Révélation d'informations
	if choice.has("reveals_information"):
		for info in choice.reveals_information:
			reveal_information(info, current_npc_id)
	
	# Déclenchement de quêtes
	if choice.has("triggers_quest"):
		var quest_data = {
			"source_npc": current_npc_id,
			"dialogue_choice": choice.id
		}
		quest_trigger_from_dialogue.emit(choice.triggers_quest, quest_data)
	
	# Effets spéciaux
	if choice.has("special_effects"):
		apply_special_effects(choice.special_effects)
	
	# Marquer choix unique comme utilisé
	if choice.get("type", ChoiceType.NORMAL) == ChoiceType.UNIQUE:
		mark_unique_choice_used(choice.id)

func change_relationship(npc_id: String, change: float) -> void:
	"""Modifie la relation avec un NPC"""
	var old_level = get_relationship_level(npc_id)
	var new_level = clamp(old_level + change, -2.0, 2.0)
	
	relationship_levels[npc_id] = new_level
	
	# Mise à jour mémoire session
	if not npc_memory.has(npc_id):
		npc_memory[npc_id] = {}
	if not npc_memory[npc_id].has("session_relationship_change"):
		npc_memory[npc_id].session_relationship_change = 0.0
	
	npc_memory[npc_id].session_relationship_change += change
	
	# Émission signal si changement significatif
	if abs(change) > 0.05:
		relationship_changed.emit(npc_id, old_level, new_level)
	
	print("❤️ Relation avec", npc_id, ":", old_level, "→", new_level)

func reveal_information(info_id: String, source_npc: String) -> void:
	"""Révèle une nouvelle information via dialogue"""
	if not revealed_information.has(info_id):
		revealed_information[info_id] = {
			"source": source_npc,
			"timestamp": Time.get_unix_time_from_system(),
			"dialogue_context": current_dialogue.get("id", "unknown")
		}
		
		var info_data = revealed_information[info_id]
		information_revealed.emit(source_npc, info_id, info_data)
		
		print("💡 Information révélée:", info_id, " par", source_npc)

func apply_special_effects(effects: Array) -> void:
	"""Applique des effets spéciaux du dialogue"""
	for effect in effects:
		match effect.type:
			"mood_change":
				# TODO: Intégration avec système d'ambiance
				print("🎭 Changement ambiance:", effect.mood)
			"item_gain":
				# TODO: Intégration avec inventaire
				print("🎒 Objet reçu:", effect.item)
			"magic_effect":
				# TODO: Intégration avec système magique
				print("✨ Effet magique:", effect.magic)

func mark_unique_choice_used(choice_id: String) -> void:
	"""Marque un choix unique comme utilisé pour ce NPC"""
	if not npc_memory.has(current_npc_id):
		npc_memory[current_npc_id] = {}
	if not npc_memory[current_npc_id].has("used_unique_choices"):
		npc_memory[current_npc_id].used_unique_choices = []
	
	npc_memory[current_npc_id].used_unique_choices.append(choice_id)

# ============================================================================
# SYSTÈME DE MÉMOIRE NPCs
# ============================================================================

func initialize_npc_memory() -> void:
	"""Initialise la mémoire pour tous les NPCs"""
	for npc_id in character_database:
		if not npc_memory.has(npc_id):
			npc_memory[npc_id] = {
				"first_meeting": false,
				"conversation_count": 0,
				"last_interaction": 0,
				"remembered_topics": [],
				"used_unique_choices": [],
				"session_relationship_change": 0.0
			}
		
		# Initialisation relations
		if not relationship_levels.has(npc_id):
			var char_data = character_database[npc_id]
			relationship_levels[npc_id] = char_data.get("base_relationship", 0)

func update_npc_memory(npc_id: String, event_type: String, event_data: Dictionary) -> void:
	"""Met à jour la mémoire d'un NPC avec un nouvel événement"""
	if not npc_memory.has(npc_id):
		npc_memory[npc_id] = {}
	
	var memory = npc_memory[npc_id]
	
	match event_type:
		"conversation_started":
			memory.conversation_count = memory.get("conversation_count", 0) + 1
			memory.last_interaction = event_data.timestamp
			if not memory.get("first_meeting", true):
				memory.first_meeting = true
		
		"choice_made":
			if not memory.has("remembered_topics"):
				memory.remembered_topics = []
			# Ajouter le sujet si pas déjà mémorisé
			var topic = extract_topic_from_choice(event_data.choice_text)
			if topic != "" and not (topic in memory.remembered_topics):
				memory.remembered_topics.append(topic)

func extract_topic_from_choice(choice_text: String) -> String:
	"""Extrait un sujet mémorable d'un texte de choix"""
	# Logique simple pour extraire des sujets clés
	choice_text = choice_text.to_lower()
	
	var key_topics = ["maurice", "rats", "observation", "magie", "catalogue", "université"]
	for topic in key_topics:
		if topic in choice_text:
			return topic
	
	return ""

# ============================================================================
# PROCESSING CONTEXTUEL
# ============================================================================

func process_dialogue_text(text: String) -> String:
	"""Traite le texte de dialogue avec variables contextuelles"""
	var processed_text = text
	
	# Remplacement variables de base
	processed_text = processed_text.replace("{player_name}", get_player_name())
	processed_text = processed_text.replace("{current_time}", get_current_time_string())
	
	# Variables relationnelles
	var relationship = get_relationship_level(current_npc_id)
	var relationship_text = get_relationship_text(relationship)
	processed_text = processed_text.replace("{relationship}", relationship_text)
	
	# Variables d'observation (si ObservationManager connecté)
	#TODO REPAIR FONCTION
	#if has_method("get_total_observations"):
		#var obs_count = get_total_observations()
		#processed_text = processed_text.replace("{observation_count}", str(obs_count))
	
	return processed_text

func get_player_name() -> String:
	"""Retourne le nom du joueur (placeholder)"""
	# TODO: Intégration avec système de personnage
	return "Catalogueur"

func get_current_time_string() -> String:
	"""Retourne l'heure actuelle du jeu"""
	# TODO: Intégration avec système de temps
	return "matin"

func get_relationship_text(level: float) -> String:
	"""Convertit un niveau de relation en texte"""
	if level >= 1.5:
		return "ami proche"
	elif level >= 0.5:
		return "ami"
	elif level >= -0.5:
		return "connaissance"
	elif level >= -1.5:
		return "méfiant"
	else:
		return "hostile"

# ============================================================================
# UTILITAIRES ET API PUBLIQUE
# ============================================================================

func get_default_dialogue_for_npc(npc_id: String) -> String:
	"""Détermine le dialogue par défaut pour un NPC"""
	var char_data = character_database.get(npc_id, {})
	var memory = npc_memory.get(npc_id, {})
	
	# Première rencontre
	if not memory.get("first_meeting", false):
		return npc_id + "_first_encounter"
	
	# Dialogue standard
	return npc_id + "_standard"

func get_relationship_level(npc_id: String) -> float:
	"""Retourne le niveau de relation avec un NPC"""
	return relationship_levels.get(npc_id, 0.0)

func is_information_revealed(info_id: String) -> bool:
	"""Vérifie si une information a été révélée"""
	return revealed_information.has(info_id)

func get_conversation_history_with_npc(npc_id: String) -> Array:
	"""Retourne l'historique des conversations avec un NPC"""
	var history = []
	for conversation in conversation_history:
		if conversation.npc_id == npc_id:
			history.append(conversation)
	return history

func force_reveal_information(info_id: String, source: String = "debug") -> void:
	"""Force la révélation d'une information (debug/événements spéciaux)"""
	reveal_information(info_id, source)

func reset_npc_relationship(npc_id: String) -> void:
	"""Remet à zéro la relation avec un NPC"""
	if character_database.has(npc_id):
		var base_rel = character_database[npc_id].get("base_relationship", 0)
		relationship_levels[npc_id] = base_rel
		print("🔄 Relation reset:", npc_id, "→", base_rel)

# ============================================================================
# CONNECTION AUX AUTRES SYSTÈMES
# ============================================================================

func connect_to_game_systems() -> void:
	"""Connecte le DialogueManager aux autres systèmes"""
	# TODO: Connexions avec GameManager, ObservationManager, QuestManager
	print("🔗 Connexions DialogueManager à implémenter")

# ============================================================================
# DEBUG & VALIDATION
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Commandes debug (à retirer en production)"""
	if OS.is_debug_build():
		if event.is_action_pressed("debug_dialogue_maurice"):
			start_dialogue("maurice", "maurice_first_encounter")
		elif event.is_action_pressed("debug_dialogue_death"):
			start_dialogue("death", "death_philosophy")

func print_dialogue_debug() -> void:
	"""Affiche les informations de debug"""
	print("=== DIALOGUE MANAGER DEBUG ===")
	print("Conversation active:", active_conversation)
	print("NPC actuel:", current_npc_id)
	print("Dialogues chargés:", dialogue_trees.size())
	print("NPCs en base:", character_database.size())
	print("Relations établies:", relationship_levels.size())
	print("Informations révélées:", revealed_information.size())

# ============================================================================
# NOTES DE DÉVELOPPEMENT
# ============================================================================

## TODO PRIORITAIRES:
## 1. Chargement des vrais fichiers JSON (dialogue_trees.json, character_data.json)
## 2. Intégration avec ObservationManager pour choix contextuels
## 3. Interface UI pour affichage dialogues
## 4. Système de sauvegarde des relations et mémoire
## 5. Expansion des données de test (plus de dialogues)

## INTÉGRATIONS FUTURES:
## - QuestManager pour déclenchement missions
## - Système de compétences pour skill checks
## - Inventaire pour échanges d'objets
## - Système de temps pour contextualisation
## - AudioManager pour voix et effets

## SPÉCIAL TERRY PRATCHETT:
## - Dialogues LA MORT en CAPS_LOCK
## - Humour britannique dans les réponses
## - Références philosophiques subtiles
## - Jeux de mots et ironie
## - Personnages mémorables et excentriques
