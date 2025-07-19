# ============================================================================
# 📱 UIManager.gd - Gestionnaire Interface Utilisateur (STUB TEMPORAIRE)
# ============================================================================
# STATUS: 🟡 STUB | ROADMAP: Mois 1, Semaine 3-4 - UI Architecture
# PRIORITY: 🟠 P2 - Interface cohérente
# DEPENDENCIES: GameManager

class_name UIManager
extends CanvasLayer

## Gestionnaire temporaire de l'interface utilisateur
## Version minimale pour éviter les erreurs de compilation

signal ui_element_shown(element_name: String)
signal ui_element_hidden(element_name: String)
signal manager_initialized()

var is_initialized: bool = false

func _ready() -> void:
	"""Initialisation basique du UIManager"""
	print("📱 UIManager: Stub temporaire initialisé")
	is_initialized = true
	manager_initialized.emit()

func toggle_pause_menu() -> void:
	"""Affiche/cache le menu pause (stub)"""
	print("📱 UIManager: Menu pause toggled (stub)")

func show_panel(panel_name: String) -> void:
	"""Affiche un panneau UI (stub)"""
	print("📱 UIManager: Affichage panneau ", panel_name, " (stub)")
	ui_element_shown.emit(panel_name)

func hide_panel(panel_name: String) -> void:
	"""Cache un panneau UI (stub)"""
	print("📱 UIManager: Masquage panneau ", panel_name, " (stub)")
	ui_element_hidden.emit(panel_name)

func show_notification(message: String, type: String = "info") -> void:
	"""Affiche une notification (stub)"""
	print("📱 Notification [", type, "]: ", message)

func start_transition(transition_type) -> void:
	"""Démarre une transition (stub)"""
	print("📱 UIManager: Transition démarrée (stub)")
	await get_tree().create_timer(0.3).timeout

func complete_transition() -> void:
	"""Termine une transition (stub)"""
	print("📱 UIManager: Transition terminée (stub)")
