# ============================================================================
# 📱 UIManager.gd - Gestionnaire Interface Utilisateur (STUB TEMPORAIRE)
# ============================================================================

class_name UIManager
extends CanvasLayer

signal ui_element_shown(element_name: String)
signal ui_element_hidden(element_name: String)
signal manager_initialized()

var is_initialized: bool = false

func _ready() -> void:
	print("📱 UIManager: Stub temporaire initialisé")
	is_initialized = true
	manager_initialized.emit()

func toggle_pause_menu() -> void:
	print("📱 UIManager: Menu pause toggled (stub)")

func show_panel(panel_name: String) -> void:
	print("📱 UIManager: Affichage panneau ", panel_name, " (stub)")
	ui_element_shown.emit(panel_name)

func hide_panel(panel_name: String) -> void:
	print("📱 UIManager: Masquage panneau ", panel_name, " (stub)")
	ui_element_hidden.emit(panel_name)

func show_notification(message: String, type: String = "info") -> void:
	print("📱 Notification [", type, "]: ", message)

func start_transition(transition_type) -> void:
	print("📱 UIManager: Transition démarrée (stub)")
	await get_tree().create_timer(0.3).timeout

func complete_transition() -> void:
	print("📱 UIManager: Transition terminée (stub)")
