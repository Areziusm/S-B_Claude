# Même chose pour UIAnimationController.gd :
extends Node
class_name UIAnimationController
func initialize(_main_container, _settings): pass
signal animation_completed
func play_transition_out(_state): return
func play_transition_in(_state): return
func set_speed_multiplier(_v): pass