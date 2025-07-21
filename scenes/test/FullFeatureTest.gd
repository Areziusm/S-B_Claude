extends Node2D

@onready var obs_manager = get_node_or_null("/root/ObservationManager")
@onready var combat_manager = get_node_or_null("/root/CombatSystem")
@onready var data_manager = get_node_or_null("/root/DataManager")
@onready var quest_manager = get_node_or_null("/root/QuestManager")
@onready var dialogue_manager = get_node_or_null("/root/DialogueManager")

func _ready():
    # Observation test
    if $TestCreatureArea and obs_manager:
        $TestCreatureArea.body_entered.connect(_on_test_creature_observed)
        obs_manager.creature_observed.connect(_on_creature_observed)
        obs_manager.creature_evolved.connect(_on_creature_evolved)
        print("ObservationManager branché pour test.")

    # Combat test
    if $TestCombatTrigger and combat_manager:
        $TestCombatTrigger.pressed.connect(_on_combat_button_pressed)
        combat_manager.combat_started.connect(_on_combat_started)
        combat_manager.combat_ended.connect(_on_combat_ended)
        print("CombatSystem branché pour test.")

    # Dialogue test
    if $TestNPC and dialogue_manager:
        $TestNPC.connect("gui_input", _on_test_npc_clicked)
        dialogue_manager.dialogue_choice_made.connect(_on_dialogue_choice)
        dialogue_manager.conversation_ended.connect(_on_dialogue_end)
        print("DialogueManager branché pour test.")

    # Quest test (si voulu)
    if quest_manager:
        quest_manager.quest_completed.connect(_on_quest_completed)
        print("QuestManager branché pour test.")

    # Vérif DataManager
    if data_manager:
        print("DataManager summary : ", data_manager.get_data_summary())

func _on_test_creature_observed(body):
    if obs_manager and body.name == "Player":
        print("[TEST] Player a observé la créature !")
        obs_manager.observe_creature("rat_maurice", obs_manager.ObservationType.DETAILED, $Player.position)

func _on_creature_observed(creature_id, obs_data):
    print("[TEST] Signal creature_observed reçu : ", creature_id, obs_data)

func _on_creature_evolved(creature_id, old_stage, new_stage):
    print("[TEST] Signal creature_evolved : ", creature_id, old_stage, new_stage)

func _on_combat_button_pressed():
    if combat_manager:
        print("[TEST] Déclenchement combat test...")
        combat_manager.start_test_combat()

func _on_combat_started(combat_id, participants):
    print("[TEST] Combat démarré ! ID :", combat_id, "Participants :", participants)

func _on_combat_ended(combat_id, resolution_type, results):
    print("[TEST] Combat terminé :", combat_id, resolution_type, results)

func _on_test_npc_clicked(event):
    if event is InputEventMouseButton and event.pressed:
        if dialogue_manager:
            print("[TEST] Début dialogue test avec NPC.")
            dialogue_manager.start_dialogue("test_dialogue") # doit exister dans DataManager fallback/dialogues

func _on_dialogue_choice(choice_id):
    print("[TEST] Dialogue : choix sélectionné : ", choice_id)

func _on_dialogue_end():
    print("[TEST] Dialogue terminé.")

func _on_quest_completed(quest_id):
    print("[TEST] Quête complétée : ", quest_id)
