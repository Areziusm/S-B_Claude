extends Node2D

@onready var player = $Player
@onready var npc = $NPC
@onready var miroir = $Miroir
@onready var lettre = $Lettre
@onready var combat_trigger = $CombatTrigger
@onready var reputation_trigger = $ReputationTrigger
@onready var notification_ui = $NotificationUI

func _ready():
    # Connecter tous les objets interactifs
    miroir.body_entered.connect(_on_miroir_interact)
    lettre.body_entered.connect(_on_lettre_interact)
    combat_trigger.body_entered.connect(_on_combat_trigger)
    reputation_trigger.body_entered.connect(_on_reputation_trigger)

    # Connecter le NPC pour test de dialogue
    npc.connect("interacted", _on_npc_interacted)
    notification_ui.show_notification("Bienvenue dans la Sandbox : testez tous vos systèmes !")
    
    # Test automatique des managers (optionnel)
    if Engine.has_singleton("GameManager"):
        Engine.get_singleton("GameManager").start_game()

func _on_miroir_interact(body):
    if body == player:
        notification_ui.show_notification("Miroir : customisation de personnage à tester ici !")
        # Tu peux ouvrir une UI ou déclencher le MagicSystem

func _on_lettre_interact(body):
    if body == player:
        notification_ui.show_notification("Lettre : lancement d’un dialogue test !")
        if Engine.has_singleton("DialogueManager"):
            Engine.get_singleton("DialogueManager").start_dialogue("lettre_intro")

func _on_combat_trigger(body):
    if body == player:
        notification_ui.show_notification("Combat lancé !")
        if Engine.has_singleton("CombatSystem"):
            Engine.get_singleton("CombatSystem").start_combat("combat_test")

func _on_reputation_trigger(body):
    if body == player:
        notification_ui.show_notification("Réputation augmentée !")
        if Engine.has_singleton("ReputationSystem"):
            Engine.get_singleton("ReputationSystem").add_reputation("faction_test", 5)

func _on_npc_interacted():
    notification_ui.show_notification("Dialogue NPC lancé !")
    if Engine.has_singleton("DialogueManager"):
        Engine.get_singleton("DialogueManager").start_dialogue("npc_test")

# Touches pour save/load/menu rapide
func _input(event):
    if event.is_action_pressed("ui_save"):
        if Engine.has_singleton("SaveSystem"):
            Engine.get_singleton("SaveSystem").save_game()
        notification_ui.show_notification("Jeu sauvegardé !")
    elif event.is_action_pressed("ui_load"):
        if Engine.has_singleton("SaveSystem"):
            Engine.get_singleton("SaveSystem").load_game()
        notification_ui.show_notification("Jeu chargé !")
    elif event.is_action_pressed("ui_cancel"):
        $MenuUI.visible = !$MenuUI.visible
