# scripts/ui/NotebookUI.gd
extends Control
class_name NotebookUI

@onready var name_label: Label = $VBoxContainer/NameLabel
@onready var stars_label: Label = $VBoxContainer/StarsLabel
@onready var note_label: Label = $VBoxContainer/NoteLabel

func display_entry(creature_id: String, entry: Dictionary) -> void:
    name_label.text = "[%s]" % creature_id
    stars_label.text = "Observation : %d / %d" % [
        entry.get("observations", 0),
        entry.get("evolution_threshold", 1)
    ]
    note_label.text = entry.get("note", "Aucune note disponible.")