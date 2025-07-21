"""
Système complet d'observation pour Sortilèges & Bestioles
Inclut :
- ObservationArea.gd (déclencheur d'observation)
- Connexion à ObservationManager.gd
- Affichage NotebookUI.gd
- Evolution de la créature
- Déclencheur d'effets magiques (MagicAmplification)
"""

# scripts/areas/ObservationArea.gd
extends Area2D
class_name ObservationArea

@export var creature_id: String = ""
@onready var player_detector: CollisionShape2D = $CollisionShape2D

signal creature_observed(id: String)

func _ready():
    connect("body_entered", Callable(self, "_on_body_entered"))

func _on_body_entered(body):
    if body.name == "Player":
        emit_signal("creature_observed", creature_id)
        queue_free()  # Une fois observée, la zone peut disparaître

# scripts/managers/ObservationManager.gd (ajout des fonctions)

func observe_creature(creature_id: String) -> void:
    if not creature_data.has(creature_id):
        return
    var entry = creature_data[creature_id]
    entry["observations"] += 1
    if entry["observations"] >= entry["evolution_threshold"]:
        entry["evolved"] = true
        emit_signal("creature_evolved", creature_id)
        MagicAmplification.trigger_random_effect()
    update_notebook_ui(creature_id)

func update_notebook_ui(creature_id: String) -> void:
    if NotebookUI:
        NotebookUI.display_entry(creature_id, creature_data[creature_id])

# scripts/ui/NotebookUI.gd (ajout affichage)
func display_entry(creature_id: String, entry: Dictionary):
    name_label.text = creature_id
    stars_label.text = str(entry["observations"]) + "/" + str(entry["evolution_threshold"])
    note_label.text = entry.get("note", "Observation en cours...")

# scripts/creatures/Creature.gd (squelette simplifié)
class_name Creature
extends Node2D

@export var id: String = ""
@export var stage: int = 0

func evolve():
    stage += 1
    print("[CREATURE] %s évolue au stade %d" % [id, stage])
    # TODO : changer sprite, déclencher effet visuel

# scripts/managers/MagicAmplification.gd
class_name MagicAmplification
extends Node

var chaos_level := 0

static func trigger_random_effect():
    chaos_level += 1
    var roll = randi() % 3
    match roll:
        0:
            get_tree().root.modulate = Color(1, 0.8, 1)  # teinte magique rose
        1:
            get_tree().root.get_camera_2d().shake(0.5)
        2:
            print("Un bruit étrange résonne...")

# JSON dans creature_database.json (extrait)
{
  "SmallBoggart": {
    "name": "Small Boggart",
    "observations": 0,
    "evolution_threshold": 3,
    "evolved": false,
    "note": "Timide, se cache dans les bottes."
  }
}

# Scène ObservationArea.tscn (résumé structure)
[Node2D name="ObservationArea"]
- Area2D (script: ObservationArea.gd)
  - CollisionShape2D (forme circulaire ou rectangle)
  - Sprite (icône œil magique ou halo discret)
