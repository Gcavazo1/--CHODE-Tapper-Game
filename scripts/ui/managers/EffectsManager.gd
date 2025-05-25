extends Node

# Manages visual effects, primarily floating numbers for now.

# Scene reference for floating numbers
var floating_number_scene = preload("res://scenes/ui/components/FloatingNumber.tscn")

# Parent node for spawning effects. This should be set by MainLayout.
@export var effects_parent_node : Node2D 

# Can be called by MainLayout during its _ready() or initialization sequence.
func initialize_effects_manager(parent_node: Node2D):
	if is_instance_valid(parent_node):
		effects_parent_node = parent_node
		print("EffectsManager: Initialized with effects parent: ", effects_parent_node.name)
	else:
		push_error("EffectsManager: Invalid parent node provided for initialization.")

# --- Core Functions ---

# Spawns a floating number at a given global position.
func spawn_floating_number(global_tap_pos: Vector2, value: String = "+1", duration: float = 1.5, color_override: Color = Color.WHITE, scale_modifier: float = 1.0) -> Node:
	if not is_instance_valid(effects_parent_node):
		push_error("EffectsManager: effects_parent_node is not set or is invalid. Cannot spawn floating number.")
		return null
	
	if not floating_number_scene:
		push_error("EffectsManager: FloatingNumber scene not loaded.")
		return null

	var instance = floating_number_scene.instantiate()
	effects_parent_node.add_child(instance)
	
	# Ensure the instance is a Node2D to set global_position
	if not instance is Node2D:
		push_error("EffectsManager: FloatingNumber instance is not a Node2D. Cannot set global_position.")
		instance.queue_free() # Clean up the incorrectly typed instance
		return null
		
	instance.global_position = global_tap_pos
	# Apply a random offset to avoid all numbers appearing in the exact same spot
	instance.position += Vector2(randf_range(-25, 25), randf_range(-50, -30)) 
	
	if instance.has_method("set_value"):
		instance.set_value(value)
	else:
		push_warning("EffectsManager: FloatingNumber instance does not have set_value method.")
		
	if instance.has_method("set_duration"):
		instance.set_duration(duration)
	else:
		push_warning("EffectsManager: FloatingNumber instance does not have set_duration method (using default).")

	if instance.has_method("set_color"):
		instance.set_color(color_override)
	else:
		push_warning("EffectsManager: FloatingNumber instance does not have set_color method.")

	if instance.has_method("set_scale_modifier"):
		instance.set_scale_modifier(scale_modifier)
	else:
		push_warning("EffectsManager: FloatingNumber instance does not have set_scale_modifier method.")
		
	return instance

# --- Signal Handlers ---

# Connected to signals that request a floating number (e.g., from TapperArea or other game events)
func _on_floating_number_requested(value: String, global_position: Vector2, duration: float = 1.5, color: Color = Color.WHITE, scale_mod: float = 1.0):
	print("EffectsManager: Floating number requested - Value: %s, Pos: %s, Duration: %s" % [value, global_position, duration])
	spawn_floating_number(global_position, value, duration, color, scale_mod) 