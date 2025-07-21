extends Node

var test_creature_id := "SmallBoggart"
var observation_manager
var notebook_ui

func _ready():
    if not get_tree().root.has_node("UI"):
        var ui_scene = preload("res://scenes/GlobalUI.tscn").instantiate()
        get_tree().root.add_child(ui_scene)
        print("✅ UI globale ajoutée dynamiquement pour le test.")

    # Simule les composants principaux
    observation_manager = preload("res://scripts/managers/ObservationManager.gd").new()
    notebook_ui = preload("res://scripts/ui/NotebookUI.gd").new()
    observation_manager.NotebookUI = notebook_ui

    observation_manager.creature_data = {
        test_creature_id: {
            "observations": 0,
            "evolution_threshold": 3,
            "evolved": false,
            "note": "Test"
        }
    }

    for i in range(3):
        observation_manager.observe_creature(test_creature_id)

    var creature = observation_manager.creature_data[test_creature_id]
    assert(creature["evolved"] == true)
    print("✅ Test observation passed")