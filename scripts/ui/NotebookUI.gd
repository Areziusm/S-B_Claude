extends Control
class_name NotebookUI

@onready var name_label = $NameLabel
@onready var stars_label = $StarsLabel
@onready var note_label = $NoteLabel

func display_entry(creature_id: String, entry: Dictionary) -> void:
    name_label.text = creature_id
    stars_label.text = str(entry["observations"]) + "/" + str(entry["evolution_threshold"])
    note_label.text = entry.get("note", "Observation en cours…")
