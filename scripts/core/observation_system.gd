extends Node
class_name ObservationSystem

"""
🔮 ObservationManager.gd - Système d'observation central
Permet l'observation, l'évolution de créatures et la mise à jour du carnet.
Communique avec MagicAmplification et NotebookUI.
"""

# ---- SIGNAUX ----
signal creature_observed(creature_id: String, data: Dictionary)
signal creature_evolved(creature_id: String)
signal magic_cascade_triggered(epicenter: Vector2, intensity: float)

# ---- VARIABLES ----
var creature_data: Dictionary = {}  # Chargé ou initialisé au démarrage
var observation_disruption_level: float = 0.0

# Pointer vers l’UI notebook (adapter le chemin si besoin !)
@onready var notebook_ui: Node = get_node_or_null("/root/UIManager/NotebookUI")

func _ready() -> void:
	# Exemple d'init si tu n'as pas encore de DataManager relié
	creature_data = {
		"rat_garou": {"observations": 0, "evolution_threshold": 3, "evolved": false, "note": "Très farouche, adore le fromage."},
		"crocodile_drain": {"observations": 1, "evolution_threshold": 5, "evolved": false, "note": "Se camoufle comme une gouttière."}
	}
	print("ObservationManager prêt. Créatures chargées : ", creature_data.keys())

func observe_creature(creature_id: String) -> void:
	if not creature_data.has(creature_id):
		push_warning("ObservationManager : Créature inconnue : %s" % creature_id)
		return
	var entry = creature_data[creature_id]
	entry["observations"] += 1
	emit_signal("creature_observed", creature_id, entry)
	if entry["observations"] >= entry["evolution_threshold"] and not entry.get("evolved", false):
		entry["evolved"] = true
		emit_signal("creature_evolved", creature_id)
		# Effet magique : cascade, amplification, etc.
		if Engine.has_singleton("MagicAmplification"):
			var magic_amp = Engine.get_singleton("MagicAmplification")
			if magic_amp.has_method("trigger_random_effect"):
				magic_amp.trigger_random_effect()
	roll_magic_cascade(Vector2.ZERO, 1.0)
	update_notebook_ui(creature_id)

func update_notebook_ui(creature_id: String) -> void:
	if notebook_ui and notebook_ui.has_method("display_entry"):
		notebook_ui.display_entry(creature_id, creature_data[creature_id])

func roll_magic_cascade(epicenter: Vector2, intensity: float) -> void:
	# Probabilité simple d'événement magique en chaîne
	var base_chance := 0.15
	var cascade_chance := base_chance * intensity * (1.0 + intensity * 0.1)
	if randf() < cascade_chance:
		var cascade_intensity = intensity * randf_range(0.5, 1.5)
		emit_signal("magic_cascade_triggered", epicenter, cascade_intensity)
		print("✨ Cascade magique déclenchée! Intensité:", cascade_intensity)
		observation_disruption_level = 0.0
	else:
		# Décroissance douce si pas de cascade
		observation_disruption_level = max(0.0, observation_disruption_level - 0.05)

# Optionnel : méthode pour brancher avec DataManager (non implémentée ici)
func load_creature_data_from_datamanager(data: Dictionary) -> void:
	creature_data = data.duplicate(true)
