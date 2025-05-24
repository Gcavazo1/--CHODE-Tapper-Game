extends Node2D

# Neon light references and properties
@onready var neon_sign_right = $TapperPanelContainer/NeonLightsContainer/NeonSignRightSide
@onready var neon_sign_left = $TapperPanelContainer/NeonLightsContainer/NeonSignLeftSide

# TapperArea reference
@onready var tapper_area = $TapperPanelContainer/TapperCenterNode2D/TapperArea

# Signal declarations - relay signals from TapperArea
signal floating_number_requested(value, position)
signal achievement_unlocked(title, description, duration)

var neon_pulse_time: float = 0.0
var neon_pulse_speed: float = 0.6  # Seconds per complete pulse cycle
var neon_min_energy: float = 0.75
var neon_max_energy: float = 2.75

var neon_left_pulse_time: float = 0.0
var neon_left_pulse_speed: float = 0.8  # 2 seconds per cycle (1/2)
var neon_left_min_energy: float = 0.55
var neon_left_max_energy: float = 1.5

func _ready():
	# Neon light debug
	if not neon_sign_right:
		print("TapperCenter: neon_sign_right NOT FOUND in _ready. Path: TapperPanelContainer/NeonLightsContainer/NeonSignRightSide")
	else:
		print("TapperCenter: Found neon_sign_right in _ready. Initial energy: ", neon_sign_right.energy)
	if not neon_sign_left:
		print("TapperCenter: neon_sign_left NOT FOUND in _ready. Path: TapperPanelContainer/NeonLightsContainer/NeonSignLeftSide")
	else:
		print("TapperCenter: Found neon_sign_left in _ready. Initial energy: ", neon_sign_left.energy)
	print("TapperCenter.gd is ready.")

	# Connect TapperArea signals if needed
	if tapper_area:
		if tapper_area.has_signal("floating_number_requested"):
			tapper_area.connect("floating_number_requested", _on_tapper_area_floating_number_requested)
		if tapper_area.has_signal("achievement_unlocked"):
			tapper_area.connect("achievement_unlocked", _on_tapper_area_achievement_unlocked)
	else:
		push_error("TapperCenter: TapperArea node not found!")

func _process(delta):
	# Update neon pulse time
	neon_pulse_time += delta
	neon_left_pulse_time += delta

	# Animate neon light energy if reference exists
	if neon_sign_right:
		var pulse_factor = (sin(neon_pulse_time * PI * neon_pulse_speed) + 1) / 2
		neon_sign_right.energy = lerp(neon_min_energy, neon_max_energy, pulse_factor)
	else:
		# Attempt to re-acquire if null
		neon_sign_right = get_node_or_null("TapperPanelContainer/NeonLightsContainer/NeonSignRightSide")

	if neon_sign_left:
		var left_pulse_factor = (sin(neon_left_pulse_time * PI * neon_left_pulse_speed) + 1) / 2
		neon_sign_left.energy = lerp(neon_left_min_energy, neon_left_max_energy, left_pulse_factor)
	else:
		# Attempt to re-acquire if null
		neon_sign_left = get_node_or_null("TapperPanelContainer/NeonLightsContainer/NeonSignLeftSide")

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
