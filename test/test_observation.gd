# test/test_observation.gd
extends Node

var test_creature_id := "SmallBoggart"
var observation_manager
var notebook_ui

func _ready():
	# Simule les composants principaux
	observation_manager = preload("res://scripts/managers/ObservationManager.gd").new()
	notebook_ui = preload("res://scripts/ui/NotebookUI.gd").new()
	observation_manager.NotebookUI = notebook_ui

	# Créature de test
	observation_manager.creature_data = {
		test_creature_id: {
			"observations": 0,
			"evolution_threshold": 3,
			"evolved": false,
			"note": "Test"
		}
	}

	# Simule 3 observations
	for i in range(3):
		observation_manager.observe_creature(test_creature_id)

	# Vérifie si la créature a bien évolué
	var creature = observation_manager.creature_data[test_creature_id]
	assert(creature["evolved"] == true)
	print("✅ Test observation passed")
