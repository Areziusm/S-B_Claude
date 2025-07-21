extends Node
class_name UIManager

func safe_get_node(path: String) -> Node:
    if has_node(path):
        return get_node(path)
    else:
        print("⚠️ [UIManager] Noeud introuvable :", path)
        return null

func _ready():
    var hud = safe_get_node("/root/UI/MainContainer/HUDContainer")
    var dialogue = safe_get_node("/root/UI/MainContainer/DialogueContainer")
    var notif = safe_get_node("/root/UI/MainContainer/NotificationContainer")