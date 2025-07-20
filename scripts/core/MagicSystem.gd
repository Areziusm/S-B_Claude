# ============================================================================
# 🔮 MagicSystem.gd - Système de Magie Octarine Terry Pratchett
# ============================================================================
# STATUS: ✅ NOUVEAU SYSTÈME | ROADMAP: Mois 1, Semaine 3 - Core Architecture
# PRIORITY: 🔴 CRITICAL - Cœur de l'univers magique et gameplay unique
# DEPENDENCIES: GameManager, DataManager, ObservationManager, CombatSystem

class_name MagicSystem
extends Node

## Gestionnaire central de la magie dans l'univers Terry Pratchett
## Système Octarine avec 20% d'effets chaotiques et cascades d'observation
## Architecture extensible pour Headologie, L-Space et interactions divines

# ============================================================================
# SIGNAUX - Communication Event-Driven
# ============================================================================

## Émis quand un sort est lancé
signal spell_cast(caster_id: String, spell_data: Dictionary, target: Variant)

## Émis quand un effet magique chaotique se déclenche
signal chaos_effect_triggered(chaos_type: String, epicenter: Vector2, affected_entities: Array)

## Émis quand le niveau de magie ambiante change
signal ambient_magic_changed(old_level: float, new_level: float, zone: String)

## Émis pour les cascades magiques d'observation
signal magic_cascade_started(trigger_creature: String, cascade_intensity: float)

## Émis quand un enchantement est appliqué/retiré
signal enchantment_applied(target_id: String, enchantment_type: String, duration: float)
signal enchantment_removed(target_id: String, enchantment_type: String, reason: String)

## Émis pour les effets de Headologie (magie psychologique)
signal headology_effect(practitioner_id: String, target_id: String, effect_type: String)

## Émis pour les interactions L-Space
signal lspace_accessed(accessor_id: String, location: Vector2, knowledge_gained: String)

## Émis quand la magie Octarine atteint un seuil critique
signal octarine_surge(surge_level: int, global_effects: Dictionary)

## Signal pour communication avec autres managers
signal manager_initialized()

# ============================================================================
# ENUMS ET CONSTANTES
# ============================================================================

enum MagicSchool {
	ELEMENTAL = 0,        # Magie élémentaire classique
	HEADOLOGY = 1,        # Magie psychologique des sorcières
	WIZARDRY = 2,         # Magie académique universitaire
	DIVINE = 3,           # Magie divine/cléricale
	CHAOS = 4,            # Magie chaotique pure
	DEATH_MAGIC = 5,      # Magie liée à LA MORT
	LSPACE = 6,           # Magie bibliothécaire/dimensionnelle
	NARRATIVE = 7         # Magie narrative (métafiction)
}

enum ChaosType {
	MINOR_MISHAP = 0,     # Effet cosmétique amusant
	SPELL_REVERSAL = 1,   # Sort affecte le lanceur
	WILD_MAGIC = 2,       # Effet magique aléatoire
	REALITY_HICCUP = 3,   # Petite altération réalité
	NARRATIVE_TWIST = 4,  # Changement narratif inattendu
	OCTARINE_OVERFLOW = 5 # Surgissement de magie pure
}

enum SpellPower {
	CANTRIP = 1,         # Sorts mineurs
	MINOR = 2,           # Sorts basiques
	MODERATE = 3,        # Sorts intermédiaires
	MAJOR = 4,           # Sorts puissants
	LEGENDARY = 5,       # Sorts épiques
	NARRATIVE = 6        # Sorts qui changent l'histoire
}

enum EnchantmentType {
	TEMPORARY = 0,       # Enchantement temporaire
	CONDITIONAL = 1,     # Activé sous conditions
	PERMANENT = 2,       # Enchantement permanent
	CURSED = 3,          # Malédiction
	BLESSED = 4,         # Bénédiction
	NARRATIVE_BOUND = 5  # Lié au récit
}

# ============================================================================
# CONFIGURATION & DONNÉES
# ============================================================================

## Chemins vers les fichiers de données
@export var magic_config_path: String = "res://data/magic_system.json"
@export var spells_database_path: String = "res://data/spells_database.json"
@export var enchantments_path: String = "res://data/enchantments.json"

## Configuration système par défaut (fallback)
var default_config: Dictionary = {
	"chaos_base_chance": 0.20,        # 20% de chaos de base
	"octarine_amplification": 1.0,    # Multiplicateur Octarine
	"ambient_magic_decay": 0.01,      # Décroissance magie ambiante
	"cascade_threshold": 3,           # Seuil déclenchement cascade
	"max_ambient_level": 10.0,        # Niveau maximum magie ambiante
	"chaos_escalation": 1.5,          # Escalade du chaos
	"headology_effectiveness": 0.8,    # Efficacité Headologie
	"lspace_accessibility": 0.3,      # Accessibilité L-Space
	"divine_intervention_chance": 0.05 # Chance intervention divine
}

## Données chargées depuis DataManager et fichiers JSON
var magic_config: Dictionary = {}
var spells_database: Dictionary = {}
var enchantments_database: Dictionary = {}

## État système global
var ambient_magic_level: float = 1.0
var total_chaos_events: int = 0
var octarine_concentration: float = 1.0
var active_enchantments: Dictionary = {}
var magic_zones: Dictionary = {}

## État par entité
var entity_mana: Dictionary = {}
var entity_magic_affinity: Dictionary = {}
var entity_active_spells: Dictionary = {}

## Cache et optimisation
var spell_cache: Dictionary = {}
var chaos_history: Array[Dictionary] = []
var cascade_cooldowns: Dictionary = {}

## Flags système
var system_initialized: bool = false
var chaos_enabled: bool = true
var debug_mode: bool = false

# ============================================================================
# DONNÉES TERRY PRATCHETT AUTHENTIQUES
# ============================================================================

const OCTARINE_PROPERTIES = {
	"color_description": "La couleur de la magie - huitième couleur du spectre",
	"visibility": "Seuls les magiciens et créatures magiques peuvent la voir",
	"effects": ["Amplification magique", "Instabilité réalité", "Attraction créatures"],
	"concentration_effects": {
		1.0: "Normal",
		2.0: "Légère distorsion",
		3.0: "Effets visibles",
		5.0: "Instabilité magique",
		10.0: "Surgissement chaotique"
	}
}

const CHAOS_EFFECTS_PRATCHETT = {
	ChaosType.MINOR_MISHAP: [
		"Les cheveux du lanceur changent de couleur",
		"Une odeur de poisson apparaît brièvement",
		"Le sort produit des étincelles violettes",
		"Un petit nuage rose apparaît et pleut du sucre"
	],
	ChaosType.SPELL_REVERSAL: [
		"Le sort de guérison affecte le lanceur",
		"Le sort d'attaque se retourne contre l'attaquant",
		"Le sort de protection affecte l'ennemi"
	],
	ChaosType.WILD_MAGIC: [
		"Un sort aléatoire se déclenche",
		"Polymorphe temporaire en animal",
		"Téléportation courte distance",
		"Création d'objet aléatoire"
	],
	ChaosType.REALITY_HICCUP: [
		"Gravité inversée 10 secondes",
		"Tout devient temporairement 2D",
		"Les lois physiques s'assouplissent",
		"Le temps ralentit brièvement"
	],
	ChaosType.NARRATIVE_TWIST: [
		"Un personnage oublié réapparaît",
		"Une quête secondaire se déclenche",
		"Un indice important est révélé",
		"Une coïncidence narrative se produit"
	],
	ChaosType.OCTARINE_OVERFLOW: [
		"Surgissement de magie pure dans la zone",
		"Amplification temporaire de tous les sorts",
		"Apparition d'une créature magique",
		"Ouverture temporaire vers L-Space"
	]
}

const HEADOLOGY_TECHNIQUES = {
	"confidence_trick": "Faire croire que quelque chose est vrai",
	"psychology_reverse": "Psychologie inversée magique",
	"narrative_pressure": "Forcer les événements vers une conclusion",
	"reality_adjustment": "Ajuster la réalité par conviction",
	"common_sense_magic": "Magie du bon sens et de l'expérience",
	"stubborn_logic": "Logique têtue qui change la réalité"
}

# ============================================================================
# INITIALISATION SYSTÈME
# ============================================================================

func _ready() -> void:
	"""Initialisation du système de magie"""
	if debug_mode:
		print("🔮 MagicSystem: Démarrage initialisation...")
	
	# Attendre que DataManager soit prêt
	await ensure_datamanager_ready()
	
	# Charger configuration et données
	load_system_configuration()
	load_spells_database()
	load_enchantments_database()
	
	# Configuration initiale
	setup_ambient_magic()
	initialize_magic_zones()
	connect_to_game_systems()
	
	# Démarrer processus périodiques
	start_ambient_decay_timer()
	start_chaos_cleanup_timer()
	
	# Finalisation
	system_initialized = true
	manager_initialized.emit()
	
	if debug_mode:
		print("🔮 MagicSystem: Système initialisé avec succès")
		print("🔮 Niveau magie ambiante:", ambient_magic_level)
		print("🔮 Concentration Octarine:", octarine_concentration)

func ensure_datamanager_ready() -> void:
	"""S'assure que DataManager est prêt avant de continuer"""
	if not get_node_or_null("/root/DataManager"):
		if get_node_or_null("/root/GameManager"):
			await get_node("/root/GameManager").manager_ready
		else:
			await get_tree().process_frame
	
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager and not data_manager.loading_complete:
		await data_manager.all_data_loaded

func load_system_configuration() -> void:
	"""Charge la configuration depuis DataManager ou utilise les défauts"""
	var data_manager = get_node_or_null("/root/DataManager")
	
	if data_manager and data_manager.game_config.has("magic_system"):
		magic_config = data_manager.game_config["magic_system"]
		if debug_mode:
			print("✅ Configuration magie chargée depuis DataManager")
	else:
		magic_config = default_config.duplicate()
		if debug_mode:
			print("⚠️ Configuration par défaut utilisée pour magie")

func load_spells_database() -> void:
	"""Charge la base de données des sorts"""
	if FileAccess.file_exists(spells_database_path):
		var file_data = load_json_file(spells_database_path)
		if file_data:
			spells_database = file_data
			if debug_mode:
				print("✅ Base sorts chargée:", spells_database.size(), "sorts")
	else:
		setup_fallback_spells()
		if debug_mode:
			print("⚠️ Sorts fallback utilisés")

func load_enchantments_database() -> void:
	"""Charge la base de données des enchantements"""
	if FileAccess.file_exists(enchantments_path):
		var file_data = load_json_file(enchantments_path)
		if file_data:
			enchantments_database = file_data
			if debug_mode:
				print("✅ Base enchantements chargée:", enchantments_database.size(), "enchantements")
	else:
		setup_fallback_enchantments()
		if debug_mode:
			print("⚠️ Enchantements fallback utilisés")

func setup_fallback_spells() -> void:
	"""Configuration de sorts minimaux si JSON absent"""
	spells_database = {
		"minor_heal": {
			"name": "Soins Mineurs",
			"school": MagicSchool.DIVINE,
			"power": SpellPower.CANTRIP,
			"mana_cost": 5,
			"casting_time": 2.0,
			"range": 3.0,
			"effects": {
				"heal": 15,
				"remove_status": ["poisoned"]
			},
			"chaos_chance": 0.15,
			"description": "Guérison magique basique"
		},
		"octarine_missile": {
			"name": "Projectile Octarine",
			"school": MagicSchool.WIZARDRY,
			"power": SpellPower.MINOR,
			"mana_cost": 10,
			"casting_time": 1.5,
			"range": 8.0,
			"effects": {
				"damage": 25,
				"damage_type": "magical",
				"octarine_exposure": true
			},
			"chaos_chance": 0.25,
			"description": "Projectile de magie pure octarine"
		},
		"headology_convince": {
			"name": "Conviction Headologique",
			"school": MagicSchool.HEADOLOGY,
			"power": SpellPower.MODERATE,
			"mana_cost": 15,
			"casting_time": 3.0,
			"range": 5.0,
			"effects": {
				"charm": true,
				"duration": 30.0,
				"type": "convince"
			},
			"chaos_chance": 0.10,
			"description": "Convainc la cible par logique magique"
		}
	}

func setup_fallback_enchantments() -> void:
	"""Configuration d'enchantements minimaux si JSON absent"""
	enchantments_database = {
		"magic_weapon": {
			"name": "Arme Magique",
			"type": EnchantmentType.TEMPORARY,
			"duration": 300.0,
			"effects": {
				"damage_bonus": 10,
				"magical_damage": true,
				"octarine_glow": true
			},
			"description": "Enchante une arme avec de la magie octarine"
		},
		"protection_ward": {
			"name": "Protection Magique",
			"type": EnchantmentType.CONDITIONAL,
			"trigger": "attacked",
			"uses": 3,
			"effects": {
				"damage_reduction": 0.3,
				"magic_resistance": 0.5
			},
			"description": "Protection contre les attaques magiques"
		}
	}

# ============================================================================
# API PRINCIPALE - LANCEMENT DE SORTS
# ============================================================================

func cast_spell(caster_id: String, spell_id: String, target: Variant, spell_data: Dictionary = {}) -> Dictionary:
	"""
	Lance un sort avec gestion du chaos et des effets
	Retourne un dictionnaire avec les résultats
	"""
	if not system_initialized:
		push_error("🔮 MagicSystem: Système non initialisé!")
		return {"success": false, "error": "system_not_ready"}
	
	# Vérifier si le sort existe
	var spell = get_spell_data(spell_id)
	if not spell:
		if debug_mode:
			print("❌ Sort inconnu:", spell_id)
		return {"success": false, "error": "unknown_spell"}
	
	# Vérifier le mana du lanceur
	var mana_cost = spell.get("mana_cost", 0)
	if not has_sufficient_mana(caster_id, mana_cost):
		if debug_mode:
			print("❌ Mana insuffisant pour", caster_id, ":", mana_cost)
		return {"success": false, "error": "insufficient_mana"}
	
	# Consommer le mana
	consume_mana(caster_id, mana_cost)
	
	# Calculer la chance de chaos
	var chaos_chance = calculate_chaos_chance(caster_id, spell)
	var chaos_triggered = false
	
	# Test de chaos
	if chaos_enabled and randf() < chaos_chance:
		chaos_triggered = true
		var chaos_result = trigger_chaos_effect(caster_id, spell, target)
		
		# Émission du signal
		spell_cast.emit(caster_id, spell, target)
		
		return {
			"success": true,
			"chaos_triggered": true,
			"chaos_effect": chaos_result,
			"mana_consumed": mana_cost
		}
	
	# Application normale du sort
	var spell_result = apply_spell_effects(caster_id, spell, target, spell_data)
	
	# Mise à jour magie ambiante
	update_ambient_magic(spell.get("power", SpellPower.CANTRIP))
	
	# Émission du signal
	spell_cast.emit(caster_id, spell, target)
	
	if debug_mode:
		print("🔮 Sort lancé:", spell.name, "par", caster_id)
	
	return {
		"success": true,
		"chaos_triggered": false,
		"effects": spell_result,
		"mana_consumed": mana_cost
	}

func calculate_chaos_chance(caster_id: String, spell: Dictionary) -> float:
	"""Calcule la chance de chaos pour un sort donné"""
	var base_chance = spell.get("chaos_chance", magic_config.chaos_base_chance)
	
	# Modificateurs selon l'école de magie
	var school = spell.get("school", MagicSchool.ELEMENTAL)
	match school:
		MagicSchool.CHAOS:
			base_chance *= 2.0  # Magie chaotique = plus de chaos
		MagicSchool.HEADOLOGY:
			base_chance *= 0.5  # Headologie = plus stable
		MagicSchool.DIVINE:
			base_chance *= 0.7  # Magie divine = assez stable
		MagicSchool.DEATH_MAGIC:
			base_chance *= 1.5  # Magie de la mort = plus risquée
	
	# Modificateur concentration Octarine
	base_chance *= octarine_concentration
	
	# Modificateur niveau magie ambiante
	base_chance *= (1.0 + ambient_magic_level * 0.1)
	
	# Modificateur affinité magique du lanceur
	var affinity = entity_magic_affinity.get(caster_id, 1.0)
	base_chance *= (2.0 - affinity)  # Plus d'affinité = moins de chaos
	
	return clamp(base_chance, 0.0, 0.95)  # Maximum 95% de chaos

func trigger_chaos_effect(caster_id: String, spell: Dictionary, target: Variant) -> Dictionary:
	"""Déclenche un effet chaotique et retourne les détails"""
	var chaos_type = choose_chaos_type()
	var chaos_data = generate_chaos_effect(chaos_type, caster_id, spell, target)
	
	# Enregistrer l'événement
	record_chaos_event(caster_id, chaos_type, chaos_data)
	
	# Émission du signal
	chaos_effect_triggered.emit(
		ChaosType.keys()[chaos_type], 
		get_entity_position(caster_id), 
		chaos_data.get("affected_entities", [])
	)
	
	# Traitement spécial selon le type
	match chaos_type:
		ChaosType.OCTARINE_OVERFLOW:
			handle_octarine_overflow(chaos_data)
		ChaosType.NARRATIVE_TWIST:
			handle_narrative_twist(chaos_data)
		ChaosType.REALITY_HICCUP:
			handle_reality_hiccup(chaos_data)
	
	if debug_mode:
		print("🌀 Chaos déclenché:", ChaosType.keys()[chaos_type])
	
	return chaos_data

# ============================================================================
# API ENCHANTEMENTS ET EFFETS PERSISTANTS
# ============================================================================

func apply_enchantment(target_id: String, enchantment_id: String, duration: float = -1.0) -> bool:
	"""Applique un enchantement à une cible"""
	var enchantment = enchantments_database.get(enchantment_id)
	if not enchantment:
		return false
	
	# Déterminer la durée
	var actual_duration = duration
	if actual_duration < 0:
		actual_duration = enchantment.get("duration", 60.0)
	
	# Créer l'enchantement actif
	var active_enchant = {
		"id": enchantment_id,
		"target": target_id,
		"effects": enchantment.effects.duplicate(),
		"duration": actual_duration,
		"start_time": Time.get_unix_time_from_system(),
		"type": enchantment.get("type", EnchantmentType.TEMPORARY)
	}
	
	# Ajouter aux enchantements actifs
	if not active_enchantments.has(target_id):
		active_enchantments[target_id] = []
	
	active_enchantments[target_id].append(active_enchant)
	
	# Émission du signal
	enchantment_applied.emit(target_id, enchantment_id, actual_duration)
	
	if debug_mode:
		print("✨ Enchantement appliqué:", enchantment.name, "sur", target_id)
	
	return true

func remove_enchantment(target_id: String, enchantment_id: String, reason: String = "expired") -> bool:
	"""Retire un enchantement spécifique"""
	if not active_enchantments.has(target_id):
		return false
	
	var enchantments = active_enchantments[target_id]
	for i in range(enchantments.size() - 1, -1, -1):
		if enchantments[i].id == enchantment_id:
			enchantments.remove_at(i)
			enchantment_removed.emit(target_id, enchantment_id, reason)
			
			if debug_mode:
				print("✨ Enchantement retiré:", enchantment_id, "de", target_id)
			
			return true
	
	return false

# ============================================================================
# SYSTÈMES SPÉCIALISÉS TERRY PRATCHETT
# ============================================================================

func trigger_headology_effect(practitioner_id: String, target_id: String, technique: String) -> Dictionary:
	"""Déclenche un effet de Headologie (magie psychologique)"""
	if not HEADOLOGY_TECHNIQUES.has(technique):
		return {"success": false, "error": "unknown_technique"}
	
	var effectiveness = magic_config.get("headology_effectiveness", 0.8)
	var practitioner_skill = entity_magic_affinity.get(practitioner_id, 1.0)
	
	var success_chance = effectiveness * practitioner_skill
	var success = randf() < success_chance
	
	var result = {
		"success": success,
		"technique": technique,
		"practitioner": practitioner_id,
		"target": target_id,
		"effectiveness": effectiveness
	}
	
	if success:
		# Appliquer l'effet selon la technique
		match technique:
			"confidence_trick":
				result["effect"] = "Target believes something is true"
			"psychology_reverse":
				result["effect"] = "Target does opposite of intention"
			"narrative_pressure":
				result["effect"] = "Events forced toward resolution"
			"reality_adjustment":
				result["effect"] = "Minor reality alteration"
	
	# Émission du signal
	headology_effect.emit(practitioner_id, target_id, technique)
	
	return result

func access_lspace(accessor_id: String, location: Vector2) -> Dictionary:
	"""Accès au L-Space (espace bibliothécaire dimensionnel)"""
	var accessibility = magic_config.get("lspace_accessibility", 0.3)
	var entity_knowledge = entity_magic_affinity.get(accessor_id, 1.0)
	
	var access_chance = accessibility * entity_knowledge
	var success = randf() < access_chance
	
	var result = {
		"success": success,
		"accessor": accessor_id,
		"location": location
	}
	
	if success:
		var knowledge_types = [
			"ancient_spell", "historical_fact", "creature_lore", 
			"hidden_location", "future_event", "past_secret"
		]
		var knowledge = knowledge_types[randi() % knowledge_types.size()]
		result["knowledge_gained"] = knowledge
		
		# Émission du signal
		lspace_accessed.emit(accessor_id, location, knowledge)
	
	return result

# ============================================================================
# GESTION MAGIE AMBIANTE ET ZONES
# ============================================================================

func update_ambient_magic(power_level: int) -> void:
	"""Met à jour le niveau de magie ambiante"""
	var old_level = ambient_magic_level
	var increase = power_level * 0.1
	
	ambient_magic_level += increase
	ambient_magic_level = clamp(ambient_magic_level, 0.0, magic_config.max_ambient_level)
	
	# Vérifier les seuils de surgissement Octarine
	check_octarine_surge()
	
	# Émission du signal si changement significatif
	if abs(ambient_magic_level - old_level) > 0.5:
		ambient_magic_changed.emit(old_level, ambient_magic_level, "global")

func check_octarine_surge() -> void:
	"""Vérifie si un surgissement Octarine doit se produire"""
	if ambient_magic_level > 8.0 and randf() < 0.1:
		trigger_octarine_surge()

func trigger_octarine_surge() -> void:
	"""Déclenche un surgissement de magie Octarine"""
	var surge_level = int(ambient_magic_level / 2.0)
	var global_effects = {
		"magic_amplification": 2.0,
		"chaos_chance_multiplier": 1.5,
		"duration": 60.0,
		"visible_to_all": true
	}
	
	# Réduire la magie ambiante après le surgissement
	ambient_magic_level *= 0.6
	
	# Émission du signal
	octarine_surge.emit(surge_level, global_effects)
	
	if debug_mode:
		print("⚡ SURGISSEMENT OCTARINE! Niveau:", surge_level)

# ============================================================================
# UTILITAIRES ET HELPERS
# ============================================================================

func get_spell_data(spell_id: String) -> Dictionary:
	"""Récupère les données d'un sort"""
	return spells_database.get(spell_id, {})

func has_sufficient_mana(entity_id: String, required: int) -> bool:
	"""Vérifie si une entité a assez de mana"""
	var current_mana = entity_mana.get(entity_id, 100)
	return current_mana >= required

func consume_mana(entity_id: String, amount: int) -> void:
	"""Consomme du mana d'une entité"""
	var current = entity_mana.get(entity_id, 100)
	entity_mana[entity_id] = max(0, current - amount)

func get_entity_position(entity_id: String) -> Vector2:
	"""Récupère la position d'une entité (stub - à connecter au système d'entités)"""
	# TODO: Intégration avec le système de positionnement des entités
	return Vector2.ZERO

func load_json_file(file_path: String) -> Dictionary:
	"""Utilitaire pour charger un fichier JSON"""
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

# ============================================================================
# CONNEXIONS SYSTÈME ET CLEANUP
# ============================================================================

func connect_to_game_systems() -> void:
	"""Connecte le MagicSystem aux autres managers"""
	# Connexion avec ObservationManager pour cascades magiques
	var observation_manager = get_node_or_null("/root/ObservationManager")
	if observation_manager:
		observation_manager.creature_observed.connect(_on_creature_observed)
		observation_manager.magic_cascade_triggered.connect(_on_magic_cascade)
	
	# Connexion avec CombatSystem pour sorts de combat
	var combat_system = get_node_or_null("/root/CombatSystem")
	if combat_system:
		combat_system.action_performed.connect(_on_combat_action)
	
	if debug_mode:
		print("🔗 MagicSystem connecté aux autres systèmes")

func start_ambient_decay_timer() -> void:
	"""Démarre le timer de décroissance de la magie ambiante"""
	var decay_timer = Timer.new()
	decay_timer.wait_time = 10.0  # Toutes les 10 secondes
	decay_timer.timeout.connect(_process_ambient_decay)
	add_child(decay_timer)
	decay_timer.start()

func start_chaos_cleanup_timer() -> void:
	"""Démarre le nettoyage périodique des effets temporaires"""
	var cleanup_timer = Timer.new()
	cleanup_timer.wait_time = 5.0  # Toutes les 5 secondes
	cleanup_timer.timeout.connect(_cleanup_temporary_effects)
	add_child(cleanup_timer)
	cleanup_timer.start()

func _process_ambient_decay() -> void:
	"""Traite la décroissance naturelle de la magie ambiante"""
	var decay_rate = magic_config.get("ambient_magic_decay", 0.01)
	var old_level = ambient_magic_level
	
	ambient_magic_level = max(0.1, ambient_magic_level - decay_rate)
	
	if abs(old_level - ambient_magic_level) > 0.1:
		ambient_magic_changed.emit(old_level, ambient_magic_level, "decay")

func _cleanup_temporary_effects() -> void:
	"""Nettoie les enchantements expirés et effets temporaires"""
	var current_time = Time.get_unix_time_from_system()
	
	for target_id in active_enchantments.keys():
		var enchantments = active_enchantments[target_id]
		
		for i in range(enchantments.size() - 1, -1, -1):
			var enchant = enchantments[i]
			var elapsed = current_time - enchant.start_time
			
			if enchant.type == EnchantmentType.TEMPORARY and elapsed >= enchant.duration:
				enchantments.remove_at(i)
				enchantment_removed.emit(target_id, enchant.id, "expired")

# ============================================================================
# HANDLERS D'ÉVÉNEMENTS
# ============================================================================

func _on_creature_observed(creature_id: String, observation_data: Dictionary) -> void:
	"""Réagit à l'observation d'une créature"""
	# L'observation peut déclencher des cascades magiques
	var cascade_chance = observation_data.get("magic_potential", 0.1)
	
	if randf() < cascade_chance:
		var cascade_intensity = observation_data.get("evolution_stage", 1) * 0.5
		trigger_magic_cascade(creature_id, cascade_intensity)

func _on_magic_cascade(epicenter: Vector2, intensity: float) -> void:
	"""Réagit aux cascades magiques déclenchées par ObservationManager"""
	# Les cascades augmentent la magie ambiante
	update_ambient_magic(int(intensity))
	
	# Chance d'effets chaotiques secondaires
	if intensity > 3.0 and randf() < 0.3:
		var chaos_type = choose_chaos_type()
		var chaos_data = {
			"source": "cascade",
			"epicenter": epicenter,
			"intensity": intensity
		}
		record_chaos_event("cascade", chaos_type, chaos_data)

func _on_combat_action(actor_id: String, action_type: String, action_data: Dictionary) -> void:
	"""Réagit aux actions de combat pour gérer les sorts"""
	if action_type == "cast_spell":
		var spell_id = action_data.get("spell_id", "")
		var target = action_data.get("target")
		cast_spell(actor_id, spell_id, target, action_data)

# ============================================================================
# MÉTHODES INTERNES HELPERS
# ============================================================================

func choose_chaos_type() -> ChaosType:
	"""Choisit un type de chaos basé sur les probabilités"""
	var rand_val = randf()
	
	if rand_val < 0.4:
		return ChaosType.MINOR_MISHAP
	elif rand_val < 0.6:
		return ChaosType.SPELL_REVERSAL
	elif rand_val < 0.8:
		return ChaosType.WILD_MAGIC
	elif rand_val < 0.9:
		return ChaosType.REALITY_HICCUP
	elif rand_val < 0.97:
		return ChaosType.NARRATIVE_TWIST
	else:
		return ChaosType.OCTARINE_OVERFLOW

func generate_chaos_effect(chaos_type: ChaosType, caster_id: String, spell: Dictionary, target: Variant) -> Dictionary:
	"""Génère un effet chaotique spécifique"""
	var effect_list = CHAOS_EFFECTS_PRATCHETT.get(chaos_type, ["Generic chaos effect"])
	var chosen_effect = effect_list[randi() % effect_list.size()]
	
	return {
		"type": chaos_type,
		"effect_description": chosen_effect,
		"caster": caster_id,
		"original_spell": spell.get("name", "Unknown"),
		"affected_entities": [caster_id],  # Par défaut affecte le lanceur
		"duration": 10.0,
		"intensity": 1.0
	}

func record_chaos_event(caster_id: String, chaos_type: ChaosType, chaos_data: Dictionary) -> void:
	"""Enregistre un événement chaotique pour les statistiques"""
	total_chaos_events += 1
	
	var event_record = {
		"timestamp": Time.get_unix_time_from_system(),
		"caster": caster_id,
		"type": chaos_type,
		"data": chaos_data,
		"ambient_level": ambient_magic_level,
		"octarine_concentration": octarine_concentration
	}
	
	chaos_history.append(event_record)
	
	# Garder seulement les 100 derniers événements
	if chaos_history.size() > 100:
		chaos_history = chaos_history.slice(-100)

func apply_spell_effects(caster_id: String, spell: Dictionary, target: Variant, extra_data: Dictionary) -> Dictionary:
	"""Applique les effets normaux d'un sort (sans chaos)"""
	# TODO: Implémentation des effets de sorts
	# Cette méthode sera étendue selon les besoins spécifiques
	return {
		"type": "normal_effect",
		"spell": spell.name,
		"effects_applied": spell.get("effects", {})
	}

func trigger_magic_cascade(source_creature: String, intensity: float) -> void:
	"""Déclenche une cascade magique à partir d'une créature"""
	magic_cascade_started.emit(source_creature, intensity)
	
	# Augmentation de la magie ambiante
	update_ambient_magic(int(intensity) + 1)
	
	if debug_mode:
		print("🌊 Cascade magique:", source_creature, "intensité:", intensity)

func handle_octarine_overflow(chaos_data: Dictionary) -> void:
	"""Gère un débordement d'Octarine"""
	octarine_concentration += 0.5
	# Effets spéciaux du débordement
	pass

func handle_narrative_twist(chaos_data: Dictionary) -> void:
	"""Gère un retournement narratif"""
	# TODO: Intégration avec QuestManager pour événements narratifs
	pass

func handle_reality_hiccup(chaos_data: Dictionary) -> void:
	"""Gère un hoquet de réalité"""
	# Effets temporaires sur l'environnement
	pass

func setup_ambient_magic() -> void:
	"""Configure la magie ambiante initiale"""
	ambient_magic_level = 1.0
	octarine_concentration = 1.0

func initialize_magic_zones() -> void:
	"""Initialise les zones magiques spéciales"""
	magic_zones = {
		"unseen_university": {"amplification": 2.0, "stability": 0.8},
		"ankh_morpork_center": {"amplification": 1.0, "stability": 1.0},
		"shades": {"amplification": 0.5, "stability": 0.3},
		"patrician_palace": {"amplification": 1.2, "stability": 1.5}
	}

# ============================================================================
# API PUBLIQUE POUR AUTRES SYSTÈMES
# ============================================================================

func get_ambient_magic_level() -> float:
	"""Retourne le niveau actuel de magie ambiante"""
	return ambient_magic_level

func get_octarine_concentration() -> float:
	"""Retourne la concentration d'Octarine"""
	return octarine_concentration

func is_entity_under_enchantment(entity_id: String, enchantment_id: String = "") -> bool:
	"""Vérifie si une entité est sous un enchantement"""
	if not active_enchantments.has(entity_id):
		return false
	
	if enchantment_id.is_empty():
		return active_enchantments[entity_id].size() > 0
	
	for enchant in active_enchantments[entity_id]:
		if enchant.id == enchantment_id:
			return true
	
	return false

func get_entity_mana(entity_id: String) -> int:
	"""Retourne le mana actuel d'une entité"""
	return entity_mana.get(entity_id, 100)

func set_entity_mana(entity_id: String, mana: int) -> void:
	"""Définit le mana d'une entité"""
	entity_mana[entity_id] = max(0, mana)

func get_chaos_statistics() -> Dictionary:
	"""Retourne les statistiques des événements chaotiques"""
	return {
		"total_chaos_events": total_chaos_events,
		"recent_events": chaos_history.slice(-10),
		"ambient_level": ambient_magic_level,
		"octarine_concentration": octarine_concentration,
		"system_initialized": system_initialized
	}

# ============================================================================
# DEBUG ET DÉVELOPPEMENT
# ============================================================================

func _input(event: InputEvent) -> void:
	"""Commandes debug (à retirer en production)"""
	if OS.is_debug_build() and debug_mode:
		if event.is_action_pressed("debug_trigger_chaos"):
			var test_spell = {"name": "Test Spell", "chaos_chance": 1.0}
			trigger_chaos_effect("debug_player", test_spell, null)
		elif event.is_action_pressed("debug_octarine_surge"):
			trigger_octarine_surge()
		elif event.is_action_pressed("debug_magic_stats"):
			print_magic_debug_info()

func print_magic_debug_info() -> void:
	"""Affiche les informations de debug du système magique"""
	print("=== MAGIC SYSTEM DEBUG ===")
	print("Magie ambiante:", ambient_magic_level)
	print("Concentration Octarine:", octarine_concentration)
	print("Événements chaos total:", total_chaos_events)
	print("Enchantements actifs:", active_enchantments.size())
	print("Sorts en base:", spells_database.size())
	print("Zones magiques:", magic_zones.size())
	print("===========================")

# ============================================================================
# NOTES DE DÉVELOPPEMENT
# ============================================================================

## TODO PRIORITAIRES:
## 1. Intégration avec CombatSystem pour sorts de combat
## 2. Connexion avec ObservationManager pour cascades d'évolution
## 3. Implémentation complète des effets de sorts
## 4. Interface UI pour sélection et lancement de sorts
## 5. Système de sauvegarde pour état magique persistant
## 6. Optimisation performance pour grandes quantités d'enchantements
## 7. Équilibrage des chances de chaos et effets
## 8. Audio/visuel pour effets magiques Octarine
## 9. Intégration narrative avec QuestManager
## 10. Tests et validation de l'équilibrage magique