extends Control

# This script manages the TapperCenter scene, which contains:
# - The background (TapperBG)
# - The tappable object (TapperArea)
# - The rat spawning system (RatSpawner)

# Signal declarations - may need to expose signals from TapperArea
signal floating_number_requested(value, position)
signal achievement_unlocked(title, description, duration)

# Node references
@onready var tapper_area = $TapperArea
@onready var rat_spawner = $RatSpawner

func _ready():
	# Connect TapperArea signals if needed
	if tapper_area:
		if tapper_area.has_signal("floating_number_requested"):
			tapper_area.connect("floating_number_requested", _on_tapper_area_floating_number_requested)
		if tapper_area.has_signal("achievement_unlocked"):
			tapper_area.connect("achievement_unlocked", _on_tapper_area_achievement_unlocked)
	else:
		push_error("TapperCenter: TapperArea node not found!")
	
	# Configure RatSpawner
	if rat_spawner:
		# Assign the Rat scene (will need to be set in the editor)
		# rat_spawner.rat_scene = ... (this should be set in editor)
		pass
	else:
		push_error("TapperCenter: RatSpawner node not found!")

# Signal relay functions
func _on_tapper_area_floating_number_requested(value, position):
	emit_signal("floating_number_requested", value, position)

func _on_tapper_area_achievement_unlocked(title, description, duration):
	emit_signal("achievement_unlocked", title, description, duration)

# Public methods that might be called from MainLayout

# Provide access to TapperArea's trigger_girthquake_shake
func trigger_girthquake_shake(amplitude: float = 4.0, duration: float = 0.1):
	if tapper_area and tapper_area.has_method("trigger_girthquake_shake"):
		tapper_area.trigger_girthquake_shake(amplitude, duration)

# Adjust RatSpawner settings if needed
func set_rat_spawn_interval(min_time: float, max_time: float):
	if rat_spawner:
		rat_spawner.min_spawn_interval = min_time
		rat_spawner.max_spawn_interval = max_time

func set_max_rats(count: int):
	if rat_spawner:
		rat_spawner.max_active_rats = count 